
-- Le repos journalier s'apprécie entre deux journées de travail, pas entre deux
-- services : un service coupé (11:00-15:00 puis 17:00-23:00) ne crée pas de
-- violation du repos de 11 h. On compare la fin de la dernière prestation d'un
-- jour au début de la première prestation du jour suivant.
create or replace function fn_validate_schedule(p_schedule uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s record; d date; v jsonb := '[]'::jsonb; summary jsonb := '[]'::jsonb;
  emp record; sh record;
  max_daily numeric; max_weekly numeric; normal_weekly numeric;
  min_daily_rest numeric; min_weekly_rest numeric; break_threshold numeric;
  sunday_rate numeric; holiday_rate numeric;
  ref_daily text; ref_weekly text; ref_rest text; ref_wrest text;
  day_hours numeric; week_hours numeric; sundays int; longest_rest numeric;
  gap numeric; win_start timestamp; win_end timestamp; cursor_ts timestamp;
  prev_day date; prev_day_end timestamp;
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
  ref_daily  := (fn_param('max_daily_hours', s.week_start)).legal_ref;
  ref_weekly := (fn_param('max_weekly_hours', s.week_start)).legal_ref;
  ref_rest   := (fn_param('min_daily_rest_hours', s.week_start)).legal_ref;
  ref_wrest  := (fn_param('min_weekly_rest_hours', s.week_start)).legal_ref;

  win_start := s.week_start::timestamp;
  win_end   := (s.week_start + 7)::timestamp;

  for emp in
    select distinct e.id, e.first_name || ' ' || e.last_name as name,
           ct.job_title, ct.weekly_hours
    from shifts sf
    join employees e on e.id = sf.employee_id
    left join lateral (
      select c.job_title, c.weekly_hours from contracts c
      where c.employee_id = e.id and c.status <> 'cancelled'
        and c.start_date <= s.week_start
        and (c.end_date is null or c.end_date >= s.week_start)
      order by c.start_date desc limit 1
    ) ct on true
    where sf.schedule_id = p_schedule
  loop
    week_hours := 0; sundays := 0;

    for d in select generate_series(s.week_start, s.week_start + 6, '1 day')::date loop
      select coalesce(sum(fn_shift_hours(start_time, end_time, break_minutes)), 0)
        into day_hours
      from shifts where schedule_id = p_schedule and employee_id = emp.id and shift_date = d;

      week_hours := week_hours + day_hours;

      if day_hours > max_daily then
        v := v || jsonb_build_object(
          'severity','warning','code','max_daily_hours',
          'title','Journée de ' || trim(to_char(day_hours,'FM990D0')) || ' h — ' || emp.name,
          'detail','Dépasse le maximum de ' || max_daily || ' h/jour. Dérogation ITM à justifier.',
          'legal_ref', ref_daily,'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if day_hours > break_threshold and not exists (
        select 1 from shifts where schedule_id = p_schedule and employee_id = emp.id
          and shift_date = d and break_minutes > 0) then
        v := v || jsonb_build_object(
          'severity','info','code','missing_break',
          'title','Pause non planifiée — ' || emp.name,
          'detail','Au-delà de ' || break_threshold || ' h de travail journalier, une pause est obligatoire.',
          'legal_ref',(fn_param('break_threshold_hours', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if extract(dow from d) = 0 and day_hours > 0 then
        sundays := sundays + 1;
        v := v || jsonb_build_object(
          'severity','info','code','sunday_work',
          'title','Dimanche travaillé — ' || emp.name,
          'detail', trim(to_char(day_hours,'FM990D0')) || ' h majorées à ' || (100 + sunday_rate)
                    || ' %. Repos compensatoire dû.',
          'legal_ref',(fn_param('sunday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if day_hours > 0 and fn_is_public_holiday(d) then
        v := v || jsonb_build_object(
          'severity','info','code','holiday_work',
          'title','Jour férié travaillé — ' || emp.name,
          'detail','Rémunération portée à ' || holiday_rate || ' % au total.',
          'legal_ref',(fn_param('holiday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;

      if day_hours > 0 and exists (
        select 1 from absences a where a.employee_id = emp.id and a.status = 'approved'
          and d between a.start_date and a.end_date) then
        v := v || jsonb_build_object(
          'severity','blocking','code','planned_while_absent',
          'title','Salarié absent mais planifié — ' || emp.name,
          'detail','Une absence validée couvre le ' || to_char(d,'DD.MM.YYYY') || '.',
          'legal_ref', null,'employee_id', emp.id,'employee_name', emp.name,'shift_date', d);
      end if;
    end loop;

    if week_hours > max_weekly then
      v := v || jsonb_build_object(
        'severity','blocking','code','max_weekly_hours',
        'title','Semaine de ' || trim(to_char(week_hours,'FM990D0')) || ' h — ' || emp.name,
        'detail','Dépasse le maximum de ' || max_weekly || ' h par semaine.',
        'legal_ref', ref_weekly,'employee_id', emp.id,'employee_name', emp.name,'shift_date', null);
    end if;

    -- ---- repos journalier : entre la fin d'une journée et le début de la suivante ----
    prev_day := null; prev_day_end := null;
    for sh in
      select sf.shift_date,
             min(fn_shift_start_ts(sf.shift_date, sf.start_time)) as day_start,
             max(fn_shift_end_ts(sf.shift_date, sf.start_time, sf.end_time)) as day_end
      from shifts sf
      where sf.employee_id = emp.id
        and sf.shift_date between s.week_start - 1 and s.week_start + 7
      group by sf.shift_date
      order by sf.shift_date
    loop
      if prev_day_end is not null then
        gap := extract(epoch from (sh.day_start - prev_day_end)) / 3600.0;
        if gap < min_daily_rest
           and sh.shift_date between s.week_start and s.week_start + 6 then
          v := v || jsonb_build_object(
            'severity','blocking','code','daily_rest',
            'title','Repos journalier de ' || min_daily_rest || ' h non respecté — ' || emp.name,
            'detail','Fin de service ' || to_char(prev_day_end,'DD.MM à HH24:MI') || ', reprise '
                     || to_char(sh.day_start,'DD.MM à HH24:MI') || ' : '
                     || trim(to_char(gap,'FM990D0')) || ' h de repos. Bloquant.',
            'legal_ref', ref_rest,'employee_id', emp.id,'employee_name', emp.name,
            'shift_date', sh.shift_date);
        end if;
      end if;
      prev_day := sh.shift_date; prev_day_end := sh.day_end;
    end loop;

    -- ---- repos hebdomadaire de 44 h consécutives ----
    longest_rest := 0; cursor_ts := win_start;
    for sh in
      select fn_shift_start_ts(sf.shift_date, sf.start_time) as sts,
             fn_shift_end_ts(sf.shift_date, sf.start_time, sf.end_time) as ets
      from shifts sf
      where sf.employee_id = emp.id and sf.schedule_id = p_schedule
      order by 1
    loop
      gap := extract(epoch from (sh.sts - cursor_ts)) / 3600.0;
      if gap > longest_rest then longest_rest := gap; end if;
      if sh.ets > cursor_ts then cursor_ts := sh.ets; end if;
    end loop;
    gap := extract(epoch from (win_end - cursor_ts)) / 3600.0;
    if gap > longest_rest then longest_rest := gap; end if;

    if longest_rest < min_weekly_rest then
      v := v || jsonb_build_object(
        'severity','blocking','code','weekly_rest',
        'title','Repos hebdomadaire de ' || min_weekly_rest || ' h non respecté — ' || emp.name,
        'detail','Plus long repos continu de la semaine : ' || trim(to_char(longest_rest,'FM990D0')) || ' h.',
        'legal_ref', ref_wrest,'employee_id', emp.id,'employee_name', emp.name,'shift_date', null);
    end if;

    summary := summary || jsonb_build_object(
      'employee_id', emp.id,'employee_name', emp.name,'job_title', emp.job_title,
      'contract_weekly_hours', emp.weekly_hours,
      'total_hours', round(week_hours, 2),
      'overtime_hours', greatest(0, round(week_hours - coalesce(emp.weekly_hours, normal_weekly), 2)),
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

-- Fabrique un matricule national valide (11 chiffres + clé Luhn + clé Verhoeff)
create or replace function fn_make_national_id(p_birth date, p_serial int)
returns text language sql immutable set search_path = public as $$
  select b || fn_luhn_check_digit(b)::text || fn_verhoeff_check_digit(b)::text
  from (select to_char(p_birth,'YYYYMMDD') || lpad((p_serial % 1000)::text, 3, '0') as b) t;
$$;
