
-- =========================================================================
--  Typologie des contrats : saisonnier, apprentissage, temps partiel,
--  intérim, et rémunération à partie variable.
-- =========================================================================
alter table contracts
  add column if not exists is_part_time boolean not null default false,
  add column if not exists apprenticeship_level text,
  add column if not exists apprenticeship_year smallint,
  add column if not exists season_label text,
  add column if not exists interim_agency_id uuid,
  add column if not exists user_company_name text,        -- entreprise utilisatrice (intérim)
  add column if not exists mission_reason text;

comment on column contracts.user_company_name is
  'Entreprise utilisatrice pour un contrat de mission : le salarié est employé par '
  'l''agence mais mis à disposition de cette société.';

-- Le CDD saisonnier échappe aux limites de renouvellement du CDD ordinaire.
alter table contracts drop constraint if exists cdd_needs_end;
alter table contracts drop constraint if exists cdd_needs_reason;
alter table contracts add constraint fixed_term_needs_end check (
  kind not in ('cdd','seasonal','interim','apprenticeship') or end_date is not null);
alter table contracts add constraint cdd_needs_reason check (
  kind <> 'cdd' or cdd_reason is not null);
alter table contracts add constraint interim_needs_user_company check (
  kind <> 'interim' or user_company_name is not null);

-- Cohérence du temps partiel avec la durée déclarée.
create or replace function fn_sync_part_time()
returns trigger language plpgsql set search_path = public as $$
declare normal_weekly numeric;
begin
  normal_weekly := fn_param_num('normal_weekly_hours', new.start_date);
  if normal_weekly is not null then
    new.is_part_time := new.weekly_hours < normal_weekly;
  end if;
  return new;
end $$;

create trigger contracts_part_time before insert or update of weekly_hours, start_date on contracts
  for each row execute function fn_sync_part_time();

update contracts set weekly_hours = weekly_hours;   -- déclenche la synchronisation

-- ---------------------------------------------------------------- intérim
create table interim_agencies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  ccss_matricule text,
  rcs_number text,
  address_line text,
  postal_code text,
  city text,
  created_at timestamptz not null default now()
);
create index on interim_agencies(organization_id);

alter table contracts add constraint contracts_interim_agency_fk
  foreign key (interim_agency_id) references interim_agencies(id) on delete set null;
create index on contracts(interim_agency_id);

alter table interim_agencies enable row level security;
create policy interim_read on interim_agencies for select to authenticated
  using (organization_id = auth_org_id());
create policy interim_ins on interim_agencies for insert to authenticated
  with check (organization_id = auth_org_id() and is_org_admin());
create policy interim_upd on interim_agencies for update to authenticated
  using (organization_id = auth_org_id() and is_org_admin())
  with check (organization_id = auth_org_id() and is_org_admin());
create policy interim_del on interim_agencies for delete to authenticated
  using (organization_id = auth_org_id() and is_org_admin());

-- ------------------------------------------------- composantes de rémunération
create type pay_component_kind as enum ('fixed', 'variable', 'benefit_in_kind', 'premium', 'expense');

create table contract_pay_components (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  kind pay_component_kind not null,
  code text not null,
  label text not null,
  amount numeric(10,2),
  rate_pct numeric(6,3),
  basis text,                                   -- chiffre d'affaires, objectif, forfait…
  periodicity text not null default 'monthly',
  -- Une partie variable n'entre dans la référence salariale que si elle est
  -- régulière : c'est ce drapeau qui décide, pas une règle codée en dur.
  in_salary_reference boolean not null default false,
  is_taxable boolean not null default true,
  is_contributory boolean not null default true,
  valid_from date not null,
  valid_to date,
  note text,
  created_at timestamptz not null default now(),
  constraint pay_component_range check (valid_to is null or valid_to > valid_from)
);
create index on contract_pay_components(contract_id, valid_from desc);
create index on contract_pay_components(company_id);

alter table contract_pay_components enable row level security;
create policy pay_comp_read on contract_pay_components for select to authenticated
  using (has_company_access(company_id)
         or exists (select 1 from contracts c where c.id = contract_id and is_self_employee(c.employee_id)));
create policy pay_comp_ins on contract_pay_components for insert to authenticated
  with check (can_manage_company(company_id));
create policy pay_comp_upd on contract_pay_components for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy pay_comp_del on contract_pay_components for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_pay_components after insert or update or delete on contract_pay_components
  for each row execute function fn_audit();

-- Référence salariale : base des indemnités et du maintien de salaire.
create or replace function fn_salary_reference(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c contracts; fixed numeric; variable numeric; lines jsonb := '[]'::jsonb; rec record;
begin
  select * into c from contracts where id = p_contract;
  if c.id is null then raise exception 'Contrat introuvable'; end if;
  if not has_company_access(c.company_id) then raise exception 'Accès refusé'; end if;

  fixed := c.monthly_gross;
  lines := lines || jsonb_build_object('label','Rémunération de base', 'amount', fixed, 'kind','fixed');

  variable := 0;
  for rec in
    select * from contract_pay_components
    where contract_id = p_contract and in_salary_reference
      and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  loop
    variable := variable + coalesce(rec.amount, 0);
    lines := lines || jsonb_build_object(
      'label', rec.label, 'amount', rec.amount, 'kind', rec.kind, 'basis', rec.basis);
  end loop;

  return jsonb_build_object(
    'contract_id', p_contract, 'evaluated_on', p_on,
    'fixed', fixed, 'variable', variable,
    'reference_monthly', round(fixed + variable, 2),
    'lines', lines,
    'note', 'Seules les composantes marquées « entre dans la référence salariale » sont retenues.');
end $$;

revoke execute on function fn_salary_reference(uuid, date) from anon, public;
grant execute on function fn_salary_reference(uuid, date) to authenticated;
