
-- La variable « a » masquait l'alias de table « absences a ».
create or replace function fn_sick_counters(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare emp record; window_months int; limit_days numeric; protect_weeks numeric;
        days numeric; ongoing record; continuation_end date; protection_end date;
        refund_rate numeric; cert_deadline int; missing_cert jsonb := '[]'::jsonb; cert_rec record;
begin
  select * into emp from employees where id = p_employee;
  if not found then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(emp.company_id)
          or exists (select 1 from employees x where x.id = p_employee and x.user_id = auth.uid())) then
    raise exception 'Accès refusé';
  end if;

  window_months := fn_param_num('sick_reference_months', p_on)::int;
  limit_days    := fn_param_num('sick_continuation_days', p_on);
  protect_weeks := fn_param_num('dismissal_protection_weeks', p_on);
  refund_rate   := fn_param_num('mutuality_refund_pct', p_on);
  cert_deadline := fn_param_num('sick_certificate_deadline_days', p_on)::int;

  select coalesce(sum(ab.days_count), 0) into days
  from absences ab join absence_types t on t.id = ab.absence_type_id
  where ab.employee_id = p_employee and t.category = 'sick' and ab.status <> 'refused'
    and ab.start_date > (p_on - (window_months || ' months')::interval)::date;

  select ab.* into ongoing
  from absences ab join absence_types t on t.id = ab.absence_type_id
  where ab.employee_id = p_employee and t.category = 'sick' and ab.status <> 'refused'
    and p_on between ab.start_date and ab.end_date
  order by ab.start_date desc limit 1;

  if ongoing.id is not null then
    protection_end := ongoing.start_date + (protect_weeks * 7)::int;
  end if;

  if days >= limit_days then
    continuation_end := (date_trunc('month', p_on) + interval '1 month - 1 day')::date;
  end if;

  for cert_rec in
    select ab.id, ab.start_date from absences ab
    join absence_types t on t.id = ab.absence_type_id
    where ab.employee_id = p_employee and t.category = 'sick'
      and t.requires_certificate and not ab.certificate_received
      and ab.start_date + cert_deadline < p_on
    order by ab.start_date
  loop
    missing_cert := missing_cert || jsonb_build_object(
      'absence_id', cert_rec.id, 'start_date', cert_rec.start_date,
      'days_late', p_on - (cert_rec.start_date + cert_deadline));
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
