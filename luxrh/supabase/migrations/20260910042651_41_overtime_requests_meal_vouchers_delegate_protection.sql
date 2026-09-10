
-- =========================================================================
--  Heures supplémentaires : demande formelle aux RH et accord mutuel
--  PRÉALABLE. Une heure supplémentaire planifiée sans accord bloque la
--  publication du planning.
-- =========================================================================
create table overtime_requests (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  schedule_id uuid references schedules(id) on delete set null,
  period_start date not null,
  period_end date not null,
  hours numeric(6,2) not null check (hours > 0),
  reason text not null,
  status text not null default 'requested'
    check (status in ('requested','hr_approved','approved','rejected','cancelled')),
  requested_by uuid references auth.users(id),
  requested_at timestamptz not null default now(),
  hr_validated_by uuid references auth.users(id),
  hr_validated_at timestamptz,
  employee_accepted_at timestamptz,
  rejected_reason text,
  compensation text not null default 'money'
    check (compensation in ('money','rest')),
  note text,
  constraint overtime_period check (period_end >= period_start)
);
create index on overtime_requests(company_id, period_start);
create index on overtime_requests(employee_id, period_start);

alter table overtime_requests enable row level security;
create policy overtime_read on overtime_requests for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy overtime_ins on overtime_requests for insert to authenticated
  with check (can_manage_company(company_id) or is_self_employee(employee_id));
create policy overtime_upd on overtime_requests for update to authenticated
  using (can_manage_company(company_id) or is_self_employee(employee_id))
  with check (can_manage_company(company_id) or is_self_employee(employee_id));
create policy overtime_del on overtime_requests for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_overtime after insert or update or delete on overtime_requests
  for each row execute function fn_audit();

insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, legal_ref, note)
values
('worktime','overtime_requires_prior_approval','Accord préalable obligatoire pour les heures supplémentaires',
 1,'booléen','2019-01-01','produit','art. L.211-22',
 'Règle d''entreprise : la demande doit être formulée auprès des RH et acceptée par les deux '
 'parties avant que les heures ne soient prestées.');

-- L'accord n'est acquis que lorsque les RH ET le salarié ont validé.
create or replace function fn_overtime_approve(p_request uuid, p_as_hr boolean)
returns overtime_requests language plpgsql volatile security definer set search_path = public as $$
declare r overtime_requests;
begin
  select * into r from overtime_requests where id = p_request;
  if r.id is null then raise exception 'Demande introuvable'; end if;

  if p_as_hr then
    if not can_manage_company(r.company_id) then raise exception 'Accès refusé'; end if;
    update overtime_requests
       set hr_validated_by = auth.uid(), hr_validated_at = now(),
           status = case when employee_accepted_at is not null then 'approved' else 'hr_approved' end
     where id = p_request returning * into r;
  else
    if not (is_self_employee(r.employee_id) or can_manage_company(r.company_id)) then
      raise exception 'Accès refusé';
    end if;
    update overtime_requests
       set employee_accepted_at = now(),
           status = case when hr_validated_at is not null then 'approved' else status end
     where id = p_request returning * into r;
  end if;

  return r;
end $$;

-- Heures couvertes par un accord complet sur une période.
create or replace function fn_overtime_approved_hours(
  p_employee uuid, p_from date, p_to date)
returns numeric language sql stable set search_path = public as $$
  select coalesce(sum(hours), 0) from overtime_requests
  where employee_id = p_employee and status = 'approved'
    and period_start <= p_to and period_end >= p_from;
$$;

-- =========================================================================
--  Chèques-repas : attribution et périodes d'octroi.
-- =========================================================================
create table meal_voucher_grants (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  voucher_count int not null check (voucher_count >= 0),
  face_value numeric(6,2) not null,
  employee_share numeric(6,2) not null default 0,
  granted_on date,
  note text,
  created_at timestamptz not null default now(),
  constraint voucher_period check (period_end >= period_start),
  exclude using gist (employee_id with =, daterange(period_start, period_end, '[]') with &&)
);
create index on meal_voucher_grants(company_id, period_start);

alter table meal_voucher_grants enable row level security;
create policy vouchers_read on meal_voucher_grants for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy vouchers_ins on meal_voucher_grants for insert to authenticated
  with check (can_manage_company(company_id));
create policy vouchers_upd on meal_voucher_grants for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy vouchers_del on meal_voucher_grants for delete to authenticated
  using (can_manage_company(company_id));

insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, legal_ref, note)
values
('fiscal','meal_voucher_max_face_value','Chèque-repas — valeur faciale maximale exonérée',
 15.00,'EUR','2023-01-01','ACD','art. 104 LIR',
 'Valeur à re-vérifier sur la source officielle avant mise en production.'),
('fiscal','meal_voucher_employee_min_share','Chèque-repas — participation minimale du salarié',
 2.80,'EUR','2023-01-01','ACD','art. 104 LIR',
 'Valeur à re-vérifier sur la source officielle avant mise en production.');

-- Contrôle de conformité d'une attribution.
create or replace function fn_meal_voucher_check(p_grant uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare g meal_voucher_grants; max_face numeric; min_share numeric; checks jsonb := '[]'::jsonb;
begin
  select * into g from meal_voucher_grants where id = p_grant;
  if g.id is null then raise exception 'Attribution introuvable'; end if;
  if not has_company_access(g.company_id) then raise exception 'Accès refusé'; end if;

  max_face  := fn_param_num('meal_voucher_max_face_value', g.period_start);
  min_share := fn_param_num('meal_voucher_employee_min_share', g.period_start);

  checks := checks || jsonb_build_object(
    'code','face_value','label','Valeur faciale dans la limite exonérée',
    'severity', case when g.face_value <= max_face then 'ok' else 'warning' end,
    'detail', fn_fmt(g.face_value) || ' € · plafond exonéré ' || fn_fmt(max_face) || ' €'
      || case when g.face_value > max_face
              then '. L''excédent constitue un avantage imposable.' else '' end,
    'legal_ref', (fn_param('meal_voucher_max_face_value', g.period_start)).legal_ref);

  checks := checks || jsonb_build_object(
    'code','employee_share','label','Participation du salarié',
    'severity', case when g.employee_share >= min_share then 'ok' else 'warning' end,
    'detail', fn_fmt(g.employee_share) || ' € · minimum ' || fn_fmt(min_share) || ' €',
    'legal_ref', (fn_param('meal_voucher_employee_min_share', g.period_start)).legal_ref);

  return jsonb_build_object(
    'grant_id', p_grant,
    'period', to_char(g.period_start,'DD.MM.YYYY') || ' → ' || to_char(g.period_end,'DD.MM.YYYY'),
    'voucher_count', g.voucher_count,
    'employer_cost', round(g.voucher_count * (g.face_value - g.employee_share), 2),
    'employee_cost', round(g.voucher_count * g.employee_share, 2),
    'checks', checks,
    'warning_count', (select count(*) from jsonb_array_elements(checks) x where x->>'severity' <> 'ok'));
end $$;

-- =========================================================================
--  Fin de contrat : dispense de préavis et protection des délégués.
-- =========================================================================
alter table contract_terminations
  add column if not exists notice_waived boolean not null default false,
  add column if not exists waiver_agreed_on date,
  add column if not exists waiver_compensation numeric(12,2),
  add column if not exists waiver_note text,
  add column if not exists is_gross_misconduct boolean not null default false;

comment on column contract_terminations.notice_waived is
  'Dispense de préavis d''un commun accord, assortie le cas échéant d''une prime compensatoire.';

-- Un délégué ne peut être licencié que pour faute grave : le moteur le dit
-- avant la notification, pas après.
create or replace function fn_can_terminate(
  p_contract uuid, p_reason text, p_on date default current_date,
  p_gross_misconduct boolean default false)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c contracts; prot jsonb; blockers jsonb := '[]'::jsonb; p jsonb;
begin
  select * into c from contracts where id = p_contract;
  if c.id is null then raise exception 'Contrat introuvable'; end if;
  if not has_company_access(c.company_id) then raise exception 'Accès refusé'; end if;

  prot := fn_dismissal_protections(c.employee_id, p_on);

  for p in select value from jsonb_array_elements(prot->'protections') loop
    if p->>'kind' in ('delegate','safety_delegate','equality_delegate') then
      if not p_gross_misconduct then
        blockers := blockers || jsonb_build_object(
          'kind', p->>'kind',
          'detail','Le salarié exerce un mandat de représentation du personnel. Seule la faute '
            || 'grave permet de mettre fin au contrat, et la procédure spéciale doit être suivie.',
          'legal_ref', p->>'legal_ref');
      end if;
    elsif p_reason <> 'faute_grave' then
      blockers := blockers || jsonb_build_object(
        'kind', p->>'kind',
        'detail', (p->>'label') || ' — protection en cours'
          || coalesce(' jusqu''au ' || to_char((p->>'until')::date,'DD.MM.YYYY'), '')
          || '. ' || (p->>'consequence'),
        'legal_ref', p->>'legal_ref');
    end if;
  end loop;

  return jsonb_build_object(
    'contract_id', p_contract, 'evaluated_on', p_on,
    'reason', p_reason, 'gross_misconduct', p_gross_misconduct,
    'allowed', jsonb_array_length(blockers) = 0,
    'blockers', blockers,
    'disclaimer','L''application signale les protections connues. Elle ne rend pas d''avis '
      || 'juridique et ne décide pas à la place de l''employeur.');
end $$;

revoke execute on function fn_overtime_approve(uuid, boolean) from anon, public;
revoke execute on function fn_overtime_approved_hours(uuid, date, date) from anon, public;
revoke execute on function fn_meal_voucher_check(uuid) from anon, public;
revoke execute on function fn_can_terminate(uuid, text, date, boolean) from anon, public;
grant execute on function fn_overtime_approve(uuid, boolean) to authenticated;
grant execute on function fn_overtime_approved_hours(uuid, date, date) to authenticated;
grant execute on function fn_meal_voucher_check(uuid) to authenticated;
grant execute on function fn_can_terminate(uuid, text, date, boolean) to authenticated;
