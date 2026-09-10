
-- =========================================================================
--  MOTEUR DE RÈGLES — planning, congés, maladie
-- =========================================================================

-- ---------- Validation légale d'un planning ----------
create or replace function fn_validate_schedule(p_schedule uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s record; d date; v jsonb := '[]'::jsonb; summary jsonb := '[]'::jsonb;
  emp record; sh record; prev_end timestamp; prev_label text;
  max_daily numeric; max_weekly numeric; normal_weekly numeric;
  min_daily_rest numeric; min_weekly_rest numeric; break_threshold numeric;
  sunday_rate numeric; holiday_rate numeric;
  ref_daily text; ref_weekly text; ref_rest text; ref_wrest text;
  day_hours numeric; week_hours numeric; sundays int; longest_rest numeric;
  gap numeric; win_start timestamp; win_end timestamp; cursor_ts timestamp;
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
           ct.job_title, ct.weekly_hours, ct.id as contract_id
    from shifts sf
    join employees e on e.id = sf.employee_id
    left join lateral (
      select * from contracts c
      where c.employee_id = e.id and c.status <> 'cancelled'
        and c.start_date <= s.week_start
        and (c.end_date is null or c.end_date >= s.week_start)
      order by c.start_date desc limit 1
    ) ct on true
    where sf.schedule_id = p_schedule
  loop
    week_hours := 0; sundays := 0;

    -- ---- contrôles journaliers ----
    for d in select generate_series(s.week_start, s.week_start + 6, '1 day')::date loop
      select coalesce(sum(fn_shift_hours(start_time, end_time, break_minutes)), 0)
        into day_hours
      from shifts where schedule_id = p_schedule and employee_id = emp.id and shift_date = d;

      week_hours := week_hours + day_hours;

      if day_hours > max_daily then
        v := v || jsonb_build_object(
          'severity','warning', 'code','max_daily_hours',
          'title','Journée de ' || trim(to_char(day_hours,'FM990D0')) || ' h — ' || emp.name,
          'detail','Dépasse le maximum de ' || max_daily || ' h/jour. Dérogation ITM à justifier.',
          'legal_ref', ref_daily, 'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', d);
      end if;

      if day_hours > break_threshold and not exists (
        select 1 from shifts where schedule_id = p_schedule and employee_id = emp.id
          and shift_date = d and break_minutes > 0) then
        v := v || jsonb_build_object(
          'severity','info','code','missing_break',
          'title','Pause non planifiée — ' || emp.name,
          'detail','Au-delà de ' || break_threshold || ' h de travail journalier, une pause est obligatoire.',
          'legal_ref',(fn_param('break_threshold_hours', s.week_start)).legal_ref,
          'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', d);
      end if;

      if extract(dow from d) = 0 and day_hours > 0 then
        sundays := sundays + 1;
        v := v || jsonb_build_object(
          'severity','info','code','sunday_work',
          'title','Dimanche travaillé — ' || emp.name,
          'detail', trim(to_char(day_hours,'FM990D0')) || ' h majorées à ' || (100 + sunday_rate) ||
                    ' %. Repos compensatoire dû.',
          'legal_ref',(fn_param('sunday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', d);
      end if;

      if day_hours > 0 and fn_is_public_holiday(d) then
        v := v || jsonb_build_object(
          'severity','info','code','holiday_work',
          'title','Jour férié travaillé — ' || emp.name,
          'detail','Rémunération portée à ' || holiday_rate || ' % au total.',
          'legal_ref',(fn_param('holiday_surcharge_pct', s.week_start)).legal_ref,
          'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', d);
      end if;

      -- salarié déjà absent
      if day_hours > 0 and exists (
        select 1 from absences a
        where a.employee_id = emp.id and a.status = 'approved'
          and d between a.start_date and a.end_date) then
        v := v || jsonb_build_object(
          'severity','blocking','code','planned_while_absent',
          'title','Salarié absent mais planifié — ' || emp.name,
          'detail','Une absence validée couvre le ' || to_char(d,'DD.MM.YYYY') || '.',
          'legal_ref', null, 'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', d);
      end if;
    end loop;

    -- ---- durée hebdomadaire ----
    if week_hours > max_weekly then
      v := v || jsonb_build_object(
        'severity','blocking','code','max_weekly_hours',
        'title','Semaine de ' || trim(to_char(week_hours,'FM990D0')) || ' h — ' || emp.name,
        'detail','Dépasse le maximum de ' || max_weekly || ' h par semaine.',
        'legal_ref', ref_weekly, 'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', null);
    end if;

    -- ---- repos journalier de 11 h ----
    prev_end := null; prev_label := null;
    for sh in
      select sf.*, fn_shift_start_ts(sf.shift_date, sf.start_time) as sts,
             fn_shift_end_ts(sf.shift_date, sf.start_time, sf.end_time) as ets
      from shifts sf
      where sf.employee_id = emp.id
        and sf.shift_date between s.week_start - 1 and s.week_start + 7
      order by 1 + 0, sf.shift_date, sf.start_time
    loop
      if prev_end is not null then
        gap := extract(epoch from (sh.sts - prev_end)) / 3600.0;
        if gap >= 0 and gap < min_daily_rest and sh.shift_date >= s.week_start
           and sh.shift_date <= s.week_start + 6 then
          v := v || jsonb_build_object(
            'severity','blocking','code','daily_rest',
            'title','Repos journalier de ' || min_daily_rest || ' h — ' || emp.name,
            'detail','Fin de service ' || to_char(prev_end,'DD.MM à HH24:MI') || ', reprise ' ||
                     to_char(sh.sts,'DD.MM à HH24:MI') || ' : ' ||
                     trim(to_char(gap,'FM990D0')) || ' h de repos. Bloquant.',
            'legal_ref', ref_rest, 'employee_id', emp.id, 'employee_name', emp.name,
            'shift_date', sh.shift_date);
        end if;
      end if;
      prev_end := sh.ets;
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
        'title','Repos hebdomadaire de ' || min_weekly_rest || ' h — ' || emp.name,
        'detail','Plus long repos continu de la semaine : ' || trim(to_char(longest_rest,'FM990D0')) || ' h.',
        'legal_ref', ref_wrest, 'employee_id', emp.id, 'employee_name', emp.name, 'shift_date', null);
    end if;

    summary := summary || jsonb_build_object(
      'employee_id', emp.id, 'employee_name', emp.name, 'job_title', emp.job_title,
      'contract_weekly_hours', emp.weekly_hours,
      'total_hours', round(week_hours, 2),
      'overtime_hours', greatest(0, round(week_hours - coalesce(emp.weekly_hours, normal_weekly), 2)),
      'sundays', sundays,
      'longest_rest_hours', round(longest_rest, 1));
  end loop;

  return jsonb_build_object(
    'schedule_id', p_schedule, 'week_start', s.week_start, 'status', s.status,
    'violations', v, 'employees', summary,
    'blocking_count', (select count(*) from jsonb_array_elements(v) x where x->>'severity'='blocking'),
    'warning_count',  (select count(*) from jsonb_array_elements(v) x where x->>'severity'='warning'),
    'can_publish', not exists (select 1 from jsonb_array_elements(v) x where x->>'severity'='blocking'));
end $$;

-- ---------- Publication d'un planning ----------
create or replace function fn_publish_schedule(p_schedule uuid)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare s record; val jsonb;
begin
  select * into s from schedules where id = p_schedule;
  if not found then raise exception 'Planning introuvable'; end if;
  if not can_manage_company(s.company_id) then raise exception 'Accès refusé'; end if;

  val := fn_validate_schedule(p_schedule);
  if not (val->>'can_publish')::boolean then
    raise exception 'Publication refusée : % violation(s) bloquante(s) subsistent.', val->>'blocking_count';
  end if;

  update schedules
     set status = 'published', published_at = now(), published_by = auth.uid()
   where id = p_schedule;

  return val || jsonb_build_object('published', true);
end $$;

-- ---------- Période de référence : compteur d'heures moyen ----------
create or replace function fn_reference_period_status(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare rp record; weeks numeric; total numeric; avg_h numeric; target numeric;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;

  select * into rp from reference_periods
  where company_id = p_company and p_on between start_date and end_date
  order by start_date desc limit 1;
  if not found then return null; end if;

  target := fn_param_num('normal_weekly_hours', p_on);

  select coalesce(sum(fn_shift_hours(sf.start_time, sf.end_time, sf.break_minutes)), 0),
         greatest(1, count(distinct date_trunc('week', sf.shift_date)))
    into total, weeks
  from shifts sf
  where sf.company_id = p_company and sf.shift_date between rp.start_date and least(p_on, rp.end_date);

  select coalesce(count(distinct e.id), 1) into avg_h from employees e where e.company_id = p_company;
  avg_h := round((total / weeks) / greatest(avg_h, 1), 1);

  return jsonb_build_object(
    'label', rp.label, 'months', rp.months,
    'start_date', rp.start_date, 'end_date', rp.end_date,
    'average_weekly_hours', avg_h,
    'target_weekly_hours', target,
    'margin_hours', round(target - avg_h, 1),
    'legal_ref', (fn_param('max_reference_period_months', p_on)).legal_ref);
end $$;

-- ---------- Solde de congés, détail ligne à ligne ----------
create or replace function fn_leave_balance(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e record; c record; rule jsonb; entitlement numeric; prorata numeric;
        year_start date; accrual_start date; months numeric; frac_days int;
        accrued numeric; taken numeric; lines jsonb := '[]'::jsonb;
        normal_weekly numeric; per_month numeric; cba_name text;
begin
  select * into e from employees where id = p_employee;
  if not found then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id)
          or exists (select 1 from employees x where x.id = p_employee and x.user_id = auth.uid())) then
    raise exception 'Accès refusé';
  end if;

  select ct.* into c from contracts ct
  where ct.employee_id = p_employee and ct.status = 'active'
  order by ct.start_date desc limit 1;
  if not found then return jsonb_build_object('balance', 0, 'lines', lines, 'no_contract', true); end if;

  select ca.name into cba_name from companies co
    left join collective_agreements ca on ca.id = co.collective_agreement_id
    where co.id = e.company_id;

  rule := fn_annual_leave_rule(c.id, p_on);
  entitlement := (rule->>'retained_value')::numeric;
  normal_weekly := fn_param_num('normal_weekly_hours', p_on);
  prorata := least(1.0, c.weekly_hours / nullif(normal_weekly, 0));

  year_start := date_trunc('year', p_on)::date;
  accrual_start := greatest(year_start, c.start_date);

  -- Une fraction de mois supérieure à 15 jours compte pour un mois complet.
  frac_days := fn_param_num('leave_month_fraction_days', p_on)::int;
  months := (extract(year from age(p_on, accrual_start)) * 12 + extract(month from age(p_on, accrual_start)));
  if extract(day from age(p_on, accrual_start)) > frac_days then months := months + 1; end if;
  months := least(12, greatest(0, months));

  per_month := round(entitlement / 12.0, 4);
  accrued := round(per_month * months * prorata, 2);

  select coalesce(sum(a.days_count), 0) into taken
  from absences a join absence_types t on t.id = a.absence_type_id
  where a.employee_id = p_employee and a.status = 'approved'
    and t.counts_against_leave
    and a.start_date >= year_start and a.start_date <= p_on;

  lines := lines
    || jsonb_build_object('label','Acquisition 1/12e × ' || trim(to_char(months,'FM990')) || ' mois'
         || case when cba_name is not null and (rule->>'retained_source') = 'CCT'
                 then ' (' || cba_name || ', ' || entitlement || ' j/an)' else '' end,
         'value', accrued, 'sign','+')
    || case when prorata < 1 then jsonb_build_array(jsonb_build_object(
         'label','Prorata temps partiel (' || c.weekly_hours || ' h / ' || normal_weekly || ' h)',
         'value', round(per_month * months * (1 - prorata), 2), 'sign','-')) else '[]'::jsonb end
    || jsonb_build_object('label','Congés pris sur l''année', 'value', taken, 'sign','-')
    || jsonb_build_object('label','Solde disponible', 'value', round(accrued - taken, 2), 'sign','=');

  return jsonb_build_object(
    'employee_id', p_employee,
    'evaluated_on', p_on,
    'entitlement_days', entitlement,
    'entitlement_source', rule->>'retained_source',
    'arbitration', rule,
    'accrued', accrued, 'taken', taken,
    'balance', round(accrued - taken, 2),
    'months_counted', months,
    'prorata', round(prorata, 4),
    'lines', lines,
    'legal_ref', (fn_param('leave_accrual_per_month', p_on)).legal_ref);
end $$;

-- ---------- Compteurs maladie : 77 jours / 18 mois, protection 26 semaines ----------
create or replace function fn_sick_counters(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e record; window_months int; limit_days numeric; protect_weeks numeric;
        days numeric; ongoing record; continuation_end date; protection_end date;
        refund_rate numeric; cert_deadline int; missing_cert jsonb := '[]'::jsonb; a record;
begin
  select * into e from employees where id = p_employee;
  if not found then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id)
          or exists (select 1 from employees x where x.id = p_employee and x.user_id = auth.uid())) then
    raise exception 'Accès refusé';
  end if;

  window_months := fn_param_num('sick_reference_months', p_on)::int;
  limit_days    := fn_param_num('sick_continuation_days', p_on);
  protect_weeks := fn_param_num('dismissal_protection_weeks', p_on);
  refund_rate   := fn_param_num('mutuality_refund_pct', p_on);
  cert_deadline := fn_param_num('sick_certificate_deadline_days', p_on)::int;

  select coalesce(sum(a.days_count), 0) into days
  from absences a join absence_types t on t.id = a.absence_type_id
  where a.employee_id = p_employee and t.category = 'sick' and a.status <> 'refused'
    and a.start_date > (p_on - (window_months || ' months')::interval)::date;

  select a.* into ongoing
  from absences a join absence_types t on t.id = a.absence_type_id
  where a.employee_id = p_employee and t.category = 'sick' and a.status <> 'refused'
    and p_on between a.start_date and a.end_date
  order by a.start_date desc limit 1;

  if found then
    protection_end := ongoing.start_date + (protect_weeks * 7)::int;
  end if;

  -- La continuation de salaire va jusqu'à la fin du mois du 77e jour d'incapacité.
  if days >= limit_days then
    continuation_end := (date_trunc('month', p_on) + interval '1 month - 1 day')::date;
  end if;

  for a in
    select a.*, t.requires_certificate from absences a
    join absence_types t on t.id = a.absence_type_id
    where a.employee_id = p_employee and t.category = 'sick'
      and t.requires_certificate and not a.certificate_received
      and a.start_date + cert_deadline < p_on
  loop
    missing_cert := missing_cert || jsonb_build_object(
      'absence_id', a.id, 'start_date', a.start_date,
      'days_late', p_on - (a.start_date + cert_deadline));
  end loop;

  return jsonb_build_object(
    'employee_id', p_employee,
    'window_months', window_months,
    'days_in_window', days,
    'limit_days', limit_days,
    'remaining_days', greatest(0, limit_days - days),
    'continuation_end', continuation_end,
    'protection_end', protection_end,
    'protection_weeks', protect_weeks,
    'mutuality_refund_pct', refund_rate,
    'certificate_deadline_days', cert_deadline,
    'missing_certificates', missing_cert,
    'legal_ref', (fn_param('sick_continuation_days', p_on)).legal_ref,
    'protection_ref', (fn_param('dismissal_protection_weeks', p_on)).legal_ref);
end $$;

-- ---------- Impact d'une demande de congé, avant envoi ----------
create or replace function fn_leave_request_impact(
  p_employee uuid, p_type uuid, p_start date, p_end date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e record; t record; days numeric := 0; d date; holidays int := 0;
        bal jsonb; entitlement numeric; used numeric;
begin
  select * into e from employees where id = p_employee;
  if not (has_company_access(e.company_id)
          or exists (select 1 from employees x where x.id = p_employee and x.user_id = auth.uid())) then
    raise exception 'Accès refusé';
  end if;
  select * into t from absence_types where id = p_type;

  -- Jours ouvrables, jours fériés exclus.
  for d in select generate_series(p_start, p_end, '1 day')::date loop
    if extract(dow from d) <> 0 then
      if fn_is_public_holiday(d) then holidays := holidays + 1;
      else days := days + 1; end if;
    end if;
  end loop;

  bal := fn_leave_balance(p_employee, p_start);

  if t.category = 'extraordinary' then
    select coalesce(sum(a.days_count), 0) into used from absences a
    where a.employee_id = p_employee and a.absence_type_id = p_type
      and a.status = 'approved' and a.start_date >= (p_start - interval '3 years')::date;
    entitlement := t.entitlement_days;
    return jsonb_build_object(
      'days_counted', days, 'holidays_excluded', holidays,
      'category', t.category, 'entitlement_days', entitlement,
      'already_used', used,
      'is_valid', days <= coalesce(entitlement, days),
      'message', case when days > coalesce(entitlement, days)
        then 'Le droit est de ' || entitlement || ' jour(s) pour ce motif.'
        else entitlement || ' jour(s) de droit — ' || coalesce(t.frequency_note, 'droit vérifié') || '.' end,
      'legal_ref', t.legal_ref);
  end if;

  return jsonb_build_object(
    'days_counted', days, 'holidays_excluded', holidays,
    'category', t.category,
    'balance_before', (bal->>'balance')::numeric,
    'balance_after', round((bal->>'balance')::numeric - days, 2),
    'is_valid', not t.counts_against_leave or (bal->>'balance')::numeric >= days,
    'message', case
      when t.counts_against_leave and (bal->>'balance')::numeric < days
        then 'Solde de ' || (bal->>'balance') || ' j. La demande dépasse de ' ||
             round(days - (bal->>'balance')::numeric, 1) || ' j le droit acquis à cette date.'
      when holidays > 0 then holidays || ' jour(s) férié(s) exclu(s) du décompte.'
      else 'Aucun jour férié sur la période.' end,
    'legal_ref', t.legal_ref);
end $$;
