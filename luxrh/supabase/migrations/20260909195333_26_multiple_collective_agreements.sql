
-- =========================================================================
--  Une société, un service ou un contrat peuvent relever de plusieurs
--  conventions simultanément : sectorielle, harcèlement, catégorie d'emploi,
--  accord de service. Chacune a sa période, et se renégocie.
-- =========================================================================
create type cba_scope as enum ('sector', 'harassment', 'employee_category', 'department', 'company');

alter table collective_agreements
  add column if not exists scope cba_scope not null default 'sector',
  add column if not exists supersedes_id uuid references collective_agreements(id) on delete set null,
  add column if not exists employee_category text;

comment on column collective_agreements.supersedes_id is
  'Version précédente que celle-ci remplace après renégociation.';

-- Rattachement au niveau société ou service, avec période propre.
create table company_collective_agreements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  collective_agreement_id uuid not null references collective_agreements(id) on delete restrict,
  department_id uuid references departments(id) on delete cascade,
  valid_from date not null,
  valid_to date,
  note text,
  created_at timestamptz not null default now(),
  constraint company_cba_range check (valid_to is null or valid_to > valid_from)
);
create index on company_collective_agreements(company_id, valid_from desc);
create index on company_collective_agreements(collective_agreement_id);

-- Rattachement au niveau du contrat individuel : une convention peut suivre le
-- salarié plutôt que la société.
create table contract_collective_agreements (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  collective_agreement_id uuid not null references collective_agreements(id) on delete restrict,
  valid_from date not null,
  valid_to date,
  note text,
  created_at timestamptz not null default now(),
  constraint contract_cba_range check (valid_to is null or valid_to > valid_from)
);
create index on contract_collective_agreements(contract_id, valid_from desc);

alter table company_collective_agreements enable row level security;
alter table contract_collective_agreements enable row level security;

create policy company_cba_read on company_collective_agreements for select to authenticated
  using (has_company_access(company_id));
create policy company_cba_ins on company_collective_agreements for insert to authenticated
  with check (can_manage_company(company_id));
create policy company_cba_upd on company_collective_agreements for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy company_cba_del on company_collective_agreements for delete to authenticated
  using (can_manage_company(company_id));

create policy contract_cba_read on contract_collective_agreements for select to authenticated
  using (exists (select 1 from contracts c where c.id = contract_id
                 and (has_company_access(c.company_id) or is_self_employee(c.employee_id))));
create policy contract_cba_ins on contract_collective_agreements for insert to authenticated
  with check (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)));
create policy contract_cba_upd on contract_collective_agreements for update to authenticated
  using (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)))
  with check (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)));
create policy contract_cba_del on contract_collective_agreements for delete to authenticated
  using (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)));

-- Reprise du rattachement unique existant en première période.
insert into company_collective_agreements (company_id, collective_agreement_id, valid_from, note)
select c.id, c.collective_agreement_id,
       greatest(ca.valid_from, date '2019-01-01'),
       'Reprise du rattachement unique lors du passage aux conventions multiples.'
from companies c
join collective_agreements ca on ca.id = c.collective_agreement_id
where c.collective_agreement_id is not null;

alter table companies drop column collective_agreement_id;

-- Conventions applicables à un contrat, tous niveaux confondus.
create or replace function fn_applicable_cbas(p_contract uuid, p_on date default current_date)
returns table (
  collective_agreement_id uuid, code text, name text, scope cba_scope,
  origin text, valid_from date, valid_to date
) language sql stable set search_path = public as $$
  with ct as (
    select c.id, c.company_id, c.employee_id, c.category,
           (select e.department_id from employees e where e.id = c.employee_id) as department_id
    from contracts c where c.id = p_contract
  )
  -- Niveau société et service
  select ca.id, ca.code, ca.name, ca.scope,
         case when cca.department_id is null then 'société' else 'service' end,
         cca.valid_from, cca.valid_to
  from ct
  join company_collective_agreements cca on cca.company_id = ct.company_id
  join collective_agreements ca on ca.id = cca.collective_agreement_id
  where cca.valid_from <= p_on and (cca.valid_to is null or cca.valid_to > p_on)
    and (cca.department_id is null or cca.department_id = ct.department_id)
    and (ca.employee_category is null or ca.employee_category = ct.category)
  union all
  -- Niveau contrat individuel
  select ca.id, ca.code, ca.name, ca.scope, 'contrat', cta.valid_from, cta.valid_to
  from ct
  join contract_collective_agreements cta on cta.contract_id = ct.id
  join collective_agreements ca on ca.id = cta.collective_agreement_id
  where cta.valid_from <= p_on and (cta.valid_to is null or cta.valid_to > p_on);
$$;

-- Meilleure valeur conventionnelle, toutes conventions applicables confondues.
create or replace function fn_cba_best_num(
  p_contract uuid, p_block cba_block, p_path text, p_on date default current_date,
  p_higher_is_better boolean default true)
returns jsonb language plpgsql stable set search_path = public as $$
declare rec record; v numeric; best numeric; best_name text; considered jsonb := '[]'::jsonb;
begin
  for rec in select * from fn_applicable_cbas(p_contract, p_on) loop
    v := (fn_cba_value(rec.collective_agreement_id, p_block, p_path) #>> '{}')::numeric;
    if v is not null then
      considered := considered || jsonb_build_object(
        'cba', rec.name, 'code', rec.code, 'origin', rec.origin, 'value', v);
      if best is null
         or (p_higher_is_better and v > best)
         or (not p_higher_is_better and v < best) then
        best := v; best_name := rec.name;
      end if;
    end if;
  end loop;
  return jsonb_build_object('value', best, 'cba_name', best_name, 'considered', considered);
end $$;

revoke execute on function fn_applicable_cbas(uuid, date) from anon, public;
revoke execute on function fn_cba_best_num(uuid, cba_block, text, date, boolean) from anon, public;
grant execute on function fn_applicable_cbas(uuid, date) to authenticated;
grant execute on function fn_cba_best_num(uuid, cba_block, text, date, boolean) to authenticated;
