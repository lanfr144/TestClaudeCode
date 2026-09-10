
-- =========================================================================
--  Statuts protégés : grossesse, allaitement, mandat de délégué, prime de
--  réemploi, gérance. Chacun ouvre des protections ou des interdictions.
-- =========================================================================
create type employee_status_kind as enum (
  'pregnancy', 'maternity_leave', 'breastfeeding', 'parental_leave',
  'delegate', 'safety_delegate', 'equality_delegate',
  'reemployment_bonus', 'company_manager', 'protected_other');

create table employee_statuses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  kind employee_status_kind not null,
  declared_on date not null default current_date,
  start_date date not null,
  end_date date,
  expected_birth_date date,
  actual_birth_date date,
  evidence_document_id uuid references documents(id) on delete set null,
  hours_credit_monthly numeric(5,1),        -- crédit d'heures du délégué
  note text,
  created_at timestamptz not null default now(),
  constraint status_range check (end_date is null or end_date >= start_date)
);
create index on employee_statuses(employee_id, kind);
create index on employee_statuses(company_id, start_date);

alter table employees add column if not exists is_management boolean not null default false;
comment on column employees.is_management is
  'Personnel de direction : exclu de l''éligibilité à la délégation du personnel.';

alter table employee_statuses enable row level security;
create policy emp_status_read on employee_statuses for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy emp_status_ins on employee_statuses for insert to authenticated
  with check (can_manage_company(company_id));
create policy emp_status_upd on employee_statuses for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy emp_status_del on employee_statuses for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_employee_statuses after insert or update or delete on employee_statuses
  for each row execute function fn_audit();

insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, legal_ref, note)
values
('leave','maternity_leave_weeks_before','Congé de maternité — avant l''accouchement',
 8,'semaines','2019-01-01','Legilux','art. L.332-1', null),
('leave','maternity_leave_weeks_after','Congé de maternité — après l''accouchement',
 12,'semaines','2019-01-01','Legilux','art. L.332-1', null),
('leave','pregnancy_protection_weeks_after_birth','Protection contre le licenciement après l''accouchement',
 12,'semaines','2019-01-01','Legilux','art. L.337-1',
 'Le licenciement est nul de la constatation médicale de la grossesse jusqu''à 12 semaines après l''accouchement.'),
('worktime','breastfeeding_break_minutes','Pause d''allaitement',
 45,'minutes','2019-01-01','Legilux','art. L.336-3',
 'Deux pauses de 45 minutes, ou une seule de 90 minutes si la journée est continue.'),
('worktime','breastfeeding_breaks_per_day','Nombre de pauses d''allaitement par jour',
 2,'pauses','2019-01-01','Legilux','art. L.336-3', null),
('headcount','delegate_eligibility_seniority_months','Ancienneté requise pour être éligible délégué',
 6,'mois','2019-01-01','Legilux','art. L.413-2', null),
('headcount','delegate_eligibility_min_age','Âge minimum pour être éligible délégué',
 18,'ans','2019-01-01','Legilux','art. L.413-2', null),
('headcount','delegate_voter_seniority_months','Ancienneté requise pour être électeur',
 0,'mois','2019-01-01','Legilux','art. L.413-1', null);

-- ---------------------------------------------------------------------------
-- Protections contre le licenciement, toutes causes réunies.
-- ---------------------------------------------------------------------------
create or replace function fn_dismissal_protections(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; out_j jsonb := '[]'::jsonb; st record; sick jsonb; ends date;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé';
  end if;

  -- Incapacité de travail
  sick := fn_sick_counters(p_employee, p_on);
  if (sick->>'protection_end') is not null and (sick->>'protection_end')::date >= p_on then
    out_j := out_j || jsonb_build_object(
      'kind','sick_leave', 'label','Incapacité de travail',
      'until', (sick->>'protection_end')::date,
      'days_left', (sick->>'protection_end')::date - p_on,
      'consequence','Toute notification de licenciement pendant cette période est nulle.',
      'legal_ref', sick->>'protection_ref');
  end if;

  -- Grossesse et suites de couches
  for st in
    select * from employee_statuses
    where employee_id = p_employee and kind in ('pregnancy','maternity_leave')
      and start_date <= p_on and (end_date is null or end_date >= p_on)
  loop
    ends := coalesce(
      st.actual_birth_date + (fn_param_num('pregnancy_protection_weeks_after_birth', p_on) * 7)::int,
      st.expected_birth_date + (fn_param_num('pregnancy_protection_weeks_after_birth', p_on) * 7)::int,
      st.end_date);
    out_j := out_j || jsonb_build_object(
      'kind','pregnancy', 'label','Grossesse et suites de couches',
      'until', ends, 'days_left', ends - p_on,
      'declared_on', st.declared_on,
      'expected_birth_date', st.expected_birth_date,
      'actual_birth_date', st.actual_birth_date,
      'consequence','Le licenciement est nul de la constatation médicale de la grossesse jusqu''à '
        || fn_fmt(fn_param_num('pregnancy_protection_weeks_after_birth', p_on))
        || ' semaines après l''accouchement.',
      'legal_ref', (fn_param('pregnancy_protection_weeks_after_birth', p_on)).legal_ref);
  end loop;

  -- Mandat de délégué
  for st in
    select * from employee_statuses
    where employee_id = p_employee
      and kind in ('delegate','safety_delegate','equality_delegate')
      and start_date <= p_on and (end_date is null or end_date >= p_on)
  loop
    out_j := out_j || jsonb_build_object(
      'kind', st.kind, 'label','Mandat de représentation du personnel',
      'until', st.end_date, 'days_left', st.end_date - p_on,
      'consequence','Le licenciement d''un délégué requiert la procédure spéciale applicable aux '
        || 'salariés protégés ; un licenciement ordinaire est nul.',
      'legal_ref','art. L.415-11');
  end loop;

  return jsonb_build_object(
    'employee_id', p_employee, 'evaluated_on', p_on,
    'protected', jsonb_array_length(out_j) > 0,
    'protections', out_j);
end $$;

-- ---------------------------------------------------------------------------
-- Interdiction d'heures supplémentaires.
-- ---------------------------------------------------------------------------
create or replace function fn_overtime_eligibility(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; reasons jsonb := '[]'::jsonb; age numeric;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé';
  end if;

  age := fn_employee_age(p_employee, p_on);
  if age is not null and age < 18 then
    reasons := reasons || jsonb_build_object(
      'code','minor', 'label','Salarié mineur',
      'detail','Un salarié de moins de 18 ans ne peut effectuer d''heures supplémentaires.',
      'legal_ref','art. L.344-3');
  end if;

  if exists (select 1 from employee_statuses s
             where s.employee_id = p_employee and s.kind in ('pregnancy','breastfeeding')
               and s.start_date <= p_on and (s.end_date is null or s.end_date >= p_on)) then
    reasons := reasons || jsonb_build_object(
      'code','pregnancy', 'label','Grossesse ou allaitement',
      'detail','Aucune heure supplémentaire ne peut être imposée à une salariée enceinte ou allaitante.',
      'legal_ref','art. L.333-3');
  end if;

  -- La prime de réemploi suppose une rémunération fixe : des heures
  -- supplémentaires en fausseraient le calcul.
  if exists (select 1 from employee_statuses s
             where s.employee_id = p_employee and s.kind = 'reemployment_bonus'
               and s.start_date <= p_on and (s.end_date is null or s.end_date >= p_on)) then
    reasons := reasons || jsonb_build_object(
      'code','reemployment_bonus', 'label','Bénéficiaire d''une prime de réemploi',
      'detail','La rémunération de référence est fixe : les heures supplémentaires sont exclues.',
      'legal_ref','art. L.541-1');
  end if;

  return jsonb_build_object(
    'employee_id', p_employee, 'evaluated_on', p_on,
    'allowed', jsonb_array_length(reasons) = 0,
    'reasons', reasons);
end $$;

-- ---------------------------------------------------------------------------
-- Éligibilité à la délégation du personnel.
-- ---------------------------------------------------------------------------
create or replace function fn_delegation_eligibility(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; c contracts; seniority_months numeric; required numeric;
        min_age numeric; age numeric; reasons jsonb := '[]'::jsonb; eligible boolean;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not has_company_access(e.company_id) then raise exception 'Accès refusé'; end if;

  select ct.* into c from contracts ct
  where ct.employee_id = p_employee and ct.status = 'active'
  order by ct.start_date limit 1;

  required := fn_param_num('delegate_eligibility_seniority_months', p_on);
  min_age  := fn_param_num('delegate_eligibility_min_age', p_on);
  age      := fn_employee_age(p_employee, p_on);

  if c.id is null then
    reasons := reasons || jsonb_build_object('code','no_contract',
      'detail','Aucun contrat actif à cette date.');
  else
    seniority_months := extract(year from age(p_on, c.start_date)) * 12
                      + extract(month from age(p_on, c.start_date));
    if seniority_months < required then
      reasons := reasons || jsonb_build_object('code','seniority',
        'detail', fn_fmt(seniority_months) || ' mois d''ancienneté sur les '
          || fn_fmt(required) || ' requis.');
    end if;
  end if;

  if age is not null and age < min_age then
    reasons := reasons || jsonb_build_object('code','age',
      'detail', age || ' ans, minimum de ' || fn_fmt(min_age) || ' ans.');
  end if;

  if e.is_management then
    reasons := reasons || jsonb_build_object('code','management',
      'detail','Le personnel de direction est exclu de la délégation du personnel.');
  end if;

  if exists (select 1 from employee_statuses s
             where s.employee_id = p_employee and s.kind = 'company_manager'
               and s.start_date <= p_on and (s.end_date is null or s.end_date >= p_on)) then
    reasons := reasons || jsonb_build_object('code','company_manager',
      'detail','Un gérant de la société ne peut siéger à la délégation du personnel.');
  end if;

  eligible := jsonb_array_length(reasons) = 0;
  return jsonb_build_object(
    'employee_id', p_employee, 'evaluated_on', p_on,
    'eligible', eligible,
    'seniority_months', seniority_months,
    'required_months', required,
    'reasons', reasons,
    'legal_ref', (fn_param('delegate_eligibility_seniority_months', p_on)).legal_ref);
end $$;

revoke execute on function fn_dismissal_protections(uuid, date) from anon, public;
revoke execute on function fn_overtime_eligibility(uuid, date) from anon, public;
revoke execute on function fn_delegation_eligibility(uuid, date) from anon, public;
grant execute on function fn_dismissal_protections(uuid, date) to authenticated;
grant execute on function fn_overtime_eligibility(uuid, date) to authenticated;
grant execute on function fn_delegation_eligibility(uuid, date) to authenticated;
