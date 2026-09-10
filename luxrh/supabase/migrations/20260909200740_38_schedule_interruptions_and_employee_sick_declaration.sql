
-- Le salarié déclare lui-même son incapacité et dépose son justificatif ;
-- l'original reste dû par voie postale.
alter table absences
  add column if not exists declared_by_employee boolean not null default false,
  add column if not exists certificate_uploaded_at timestamptz,
  add column if not exists certificate_original_received boolean not null default false,
  add column if not exists certificate_original_received_at date;

comment on column absences.certificate_original_received is
  'Le dépôt numérique ne dispense pas de l''envoi de l''original par la poste.';

-- =========================================================================
--  Validation du planning : ajoute les interruptions obligatoires, le travail
--  de nuit des mineurs et les interdictions d'heures supplémentaires.
-- =========================================================================
create or replace function fn_validate_schedule(p_schedule uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s record; d date; v jsonb := '[]'::jsonb; summary jsonb := '[]'::jsonb;
  emp record; sh record;
  max_daily numeric; max_weekly numeric; normal_weekly numeric;
  min_daily_rest numeric; min_weekly_rest numeric; break_threshold numeric;
  sunday_rate numeric; holiday_rate numeric;
  minor_night_start numeric; minor_night_end numeric; minor_max_daily numeric;
  bf_minutes numeric; bf_count numeric;
  ref_daily text; ref_weekly text; ref_rest text; ref_wrest text;
  day_hours numeric; week_hours numeric; sundays int; longest_rest numeric;
  gap numeric; win_start timestamp; win_end timestamp; cursor_ts timestamp;
  prev_day_end timestamp; age numeric; ot jsonb; breastfeeding boolean; day_breaks numeric;
begin
  select * into s from schedules where id = p_schedule;
  if not found then raise exception 'Planning introuvable'; end if;
  if not has_company_access(s.company_id) then raise exception 'Accès refusé'; end if;

  max_daily       := fn_param_num('max_daily_hours', s.week_start);
  max_weekly      := fn_param_num('max_weekly_hours', s.week_start);
  normal_weekly   := fn_param_num('normal_weekly_hours', s.week_start);
  min_daily_rest  := fn_param_num('min_daily_rest_hours', s.week_start);
  min_weekly_rest := fn_param_num('min_weekly_rest_hours', s.week_start);
  break_threshold := fn_param_num('break_threshold_hours', s.week_start);
  sunday_rate     := fn_param_num('sunday_surcharge_pct', s.week_start);
  holiday_rate    := fn_param_num('holiday_surcharge_pct', s.week_start);
  minor_night_start := fn_param_num('minor_night_work_start', s.week_start);
  minor_night_end   := fn_param_num('minor_night_work_end', s.week_start);
  minor_max_daily   := fn_param_num('minor_max_daily_hours', s.week_start);
  bf_minutes := fn_param_num('breastfeeding_break_minutes', s.week_start);
  bf_count   := fn_param_num('breastfeeding_breaks_per_day', s.week_start);
  ref_daily  := (fn_param('max_daily_hours', s.week_start)).legal_ref;
  ref_weekly := (fn_param('max_weekly_hours', s.week_start)).legal_ref;
  ref_rest   := (fn_param('min_daily_rest_hours', s.week_start)).legal_ref;
  ref_wrest  := (fn_param('min_weekly_rest_hours', s.week_start)).legal_ref;

  win_start := s.week_start::timestamp;
  win_end   := (s.week_start + 7)::timestamp;

  for emp in
    select distinct e.id, e.first_name || ' ' || e.last_name as name, ct.job_title, ct.weekly_hours
    from shifts sf
    join employees e on e.id = sf.employee_id
    left join lateral (
      select c.job_title, c.weekly_hours from contracts c
      where c.employee_id = e.id and c.status <> 'cancelled'
        and c.start_date <= s.week_start and (c.end_date is null or c.end_date >= s.week_start)
      order by c.start_date desc limit 1
    ) ct on true
    where sf.schedule_id = p_schedule
  loop
    week_hours := 0; sundays := 0;
    age := fn_employee_age(emp.id, s.week_start);
    ot  := fn_overtime_eligibility(emp.id, s.week_start);
    breastfeeding := exists (
      select 1 from employee_statuses st
      where st.employee_id = emp.id and st.kind = 'breastfeeding'
        and st.start_date <= s.week_start + 6 and (st.end_date is null or st.end_date >= s.week_start));

    for d in select generate_series(s.week_start, s.week_start + 6, '1 day')::date loop
      select coalesce(sum(fn_shift_hours(start_time, end_time, break_minutes)), 0),
             coalesce(sum(break_minutes), 0)
        into day_hours, day_breaks
      from shifts where schedule_id = p_schedule and employee_id = emp.id and shift_date = d;

      week_hours := week_hours + day_hours;

      if day_hours > max_daily then
        v := v || jsonb_build_object('severity','warning','code','max_daily_hours',
          'title','Journée de ' || fn_fmt(day_hours) || ' h — ' || emp.name,
          'detail','Dépasse le maximum de ' || fn_fmt(max_daily) || ' h/jour. Dérogation ITM à justifier.',
          'legal_ref', ref_daily,'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      -- Mineur : durée journalière et interdiction de nuit.
      if age is not null and age < 18 and day_hours > 0 then
        if day_hours > minor_max_daily then
          v := v || jsonb_build_object('severity','blocking','code','minor_daily_hours',
            'title','Mineur : journée de ' || fn_fmt(day_hours) || ' h — ' || emp.name,
            'detail','Maximum de ' || fn_fmt(minor_max_daily) || ' h par jour avant 18 ans.',
            'legal_ref',(fn_param('minor_max_daily_hours', s.week_start)).legal_ref,
            'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
        end if;
        if exists (
          select 1 from shifts sf where sf.schedule_id = p_schedule and sf.employee_id = emp.id
            and sf.shift_date = d
            and (extract(hour from sf.end_time) >= minor_night_start
                 or extract(hour from sf.start_time) < minor_night_end
                 or sf.end_time <= sf.start_time)) then
          v := v || jsonb_build_object('severity','blocking','code','minor_night_work',
            'title','Mineur occupé de nuit — ' || emp.name,
            'detail','Aucune occupation entre ' || fn_fmt(minor_night_start) || ' h et '
              || fn_fmt(minor_night_end) || ' h avant 18 ans.',
            'legal_ref',(fn_param('minor_night_work_start', s.week_start)).legal_ref,
            'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
        end if;
      end if;

      -- Pause de service.
      for sh in
        select sf.id, fn_shift_hours(sf.start_time, sf.end_time, 0) as h, sf.break_minutes
        from shifts sf
        where sf.schedule_id = p_schedule and sf.employee_id = emp.id and sf.shift_date = d
      loop
        if sh.h > break_threshold and sh.break_minutes = 0 then
          v := v || jsonb_build_object('severity','info','code','missing_break',
            'title','Pause non planifiée — ' || emp.name,
            'detail','Service de ' || fn_fmt(sh.h) || ' h le ' || to_char(d,'DD.MM')
                     || ' : au-delà de ' || fn_fmt(break_threshold) || ' h, une pause est obligatoire.',
            'legal_ref',(fn_param('break_threshold_hours', s.week_start)).legal_ref,
            'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
        end if;
      end loop;

      -- Interruptions d'allaitement, en plus de la pause ordinaire.
      if breastfeeding and day_hours > 0 and day_breaks < bf_minutes * bf_count then
        v := v || jsonb_build_object('severity','warning','code','breastfeeding_breaks',
          'title','Interruptions d''allaitement à prévoir — ' || emp.name,
          'detail', fn_fmt(bf_count) || ' interruptions de ' || fn_fmt(bf_minutes)
            || ' minutes sont dues, ou une seule de ' || fn_fmt(bf_minutes * bf_count)
            || ' minutes si la journée est continue. '
            || fn_fmt(day_breaks) || ' minutes planifiées le ' || to_char(d,'DD.MM') || '.',
          'legal_ref',(fn_param('breastfeeding_break_minutes', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if extract(dow from d) = 0 and day_hours > 0 then
        sundays := sundays + 1;
        v := v || jsonb_build_object('severity','info','code','sunday_work',
          'title','Dimanche travaillé — ' || emp.name,
          'detail', fn_fmt(day_hours) || ' h majorées à ' || fn_fmt(100 + sunday_rate)
                    || ' %. Repos compensatoire dû.',
          'legal_ref',(fn_param('sunday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if day_hours > 0 and fn_is_public_holiday(d) then
        v := v || jsonb_build_object('severity','info','code','holiday_work',
          'title','Jour férié travaillé — ' || emp.name,
          'detail','Rémunération portée à ' || fn_fmt(holiday_rate) || ' % au total.',
          'legal_ref',(fn_param('holiday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if day_hours > 0 and exists (
        select 1 from absences a where a.employee_id = emp.id and a.status = 'approved'
          and d between a.start_date and a.end_date) then
        v := v || jsonb_build_object('severity','blocking','code','planned_while_absent',
          'title','Salarié absent mais planifié — ' || emp.name,
          'detail','Une absence validée couvre le ' || to_char(d,'DD.MM.YYYY') || '.',
          'legal_ref', null,'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;
    end loop;

    if week_hours > max_weekly then
      v := v || jsonb_build_object('severity','blocking','code','max_weekly_hours',
        'title','Semaine de ' || fn_fmt(week_hours) || ' h — ' || emp.name,
        'detail','Dépasse le maximum de ' || fn_fmt(max_weekly) || ' h par semaine.',
        'legal_ref', ref_weekly,'employee_id', emp.id,'employee_name', emp.name,'shift_date', null);
    end if;

    -- Heures supplémentaires interdites pour certains salariés.
    if not (ot->>'allowed')::boolean and week_hours > coalesce(emp.weekly_hours, normal_weekly) then
      v := v || jsonb_build_object('severity','blocking','code','overtime_forbidden',
        'title','Heures supplémentaires interdites — ' || emp.name,
        'detail', fn_fmt(week_hours - coalesce(emp.weekly_hours, normal_weekly))
          || ' h au-delà de la durée contractuelle. '
          || (select string_agg(x->>'detail', ' ') from jsonb_array_elements(ot->'reasons') x),
        'legal_ref', (ot#>>'{reasons,0,legal_ref}'),
        'employee_id', emp.id,'employee_name', emp.name,'shift_date', null);
    end if;

    prev_day_end := null;
    for sh in
      select sf.shift_date,
             min(fn_shift_start_ts(sf.shift_date, sf.start_time)) as day_start,
             max(fn_shift_end_ts(sf.shift_date, sf.start_time, sf.end_time)) as day_end
      from shifts sf
      where sf.employee_id = emp.id and sf.shift_date between s.week_start - 1 and s.week_start + 7
      group by sf.shift_date order by sf.shift_date
    loop
      if prev_day_end is not null then
        gap := extract(epoch from (sh.day_start - prev_day_end)) / 3600.0;
        if gap < min_daily_rest and sh.shift_date between s.week_start and s.week_start + 6 then
          v := v || jsonb_build_object('severity','blocking','code','daily_rest',
            'title','Repos journalier de ' || fn_fmt(min_daily_rest) || ' h non respecté — ' || emp.name,
            'detail','Fin de service ' || to_char(prev_day_end,'DD.MM à HH24:MI') || ', reprise '
                     || to_char(sh.day_start,'DD.MM à HH24:MI') || ' : ' || fn_fmt(round(gap,2))
                     || ' h de repos. Le planning ne peut pas être publié tant que la violation subsiste.',
            'legal_ref', ref_rest,'employee_id', emp.id,'employee_name', emp.name,
            'shift_date', sh.shift_date);
        end if;
      end if;
      prev_day_end := sh.day_end;
    end loop;

    longest_rest := 0; cursor_ts := win_start;
    for sh in
      select fn_shift_start_ts(sf.shift_date, sf.start_time) as sts,
             fn_shift_end_ts(sf.shift_date, sf.start_time, sf.end_time) as ets
      from shifts sf where sf.employee_id = emp.id and sf.schedule_id = p_schedule order by 1
    loop
      gap := extract(epoch from (sh.sts - cursor_ts)) / 3600.0;
      if gap > longest_rest then longest_rest := gap; end if;
      if sh.ets > cursor_ts then cursor_ts := sh.ets; end if;
    end loop;
    gap := extract(epoch from (win_end - cursor_ts)) / 3600.0;
    if gap > longest_rest then longest_rest := gap; end if;

    if longest_rest < min_weekly_rest then
      v := v || jsonb_build_object('severity','blocking','code','weekly_rest',
        'title','Repos hebdomadaire de ' || fn_fmt(min_weekly_rest) || ' h non respecté — ' || emp.name,
        'detail','Plus long repos continu de la semaine : ' || fn_fmt(round(longest_rest,1)) || ' h.',
        'legal_ref', ref_wrest,'employee_id', emp.id,'employee_name', emp.name,'shift_date', null);
    end if;

    summary := summary || jsonb_build_object(
      'employee_id', emp.id,'employee_name', emp.name,'job_title', emp.job_title,
      'contract_weekly_hours', emp.weekly_hours,
      'total_hours', round(week_hours, 2),
      'overtime_hours', greatest(0, round(week_hours - coalesce(emp.weekly_hours, normal_weekly), 2)),
      'overtime_allowed', (ot->>'allowed')::boolean,
      'is_minor', age is not null and age < 18,
      'sundays', sundays,
      'longest_rest_hours', round(longest_rest, 1));
  end loop;

  return jsonb_build_object(
    'schedule_id', p_schedule,'week_start', s.week_start,'status', s.status,
    'violations', v,'employees', summary,
    'blocking_count', (select count(*) from jsonb_array_elements(v) x where x->>'severity'='blocking'),
    'warning_count',  (select count(*) from jsonb_array_elements(v) x where x->>'severity'='warning'),
    'can_publish', not exists (select 1 from jsonb_array_elements(v) x where x->>'severity'='blocking'));
end $$;
