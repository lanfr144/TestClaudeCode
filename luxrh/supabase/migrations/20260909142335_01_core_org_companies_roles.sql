
create extension if not exists btree_gist;
create extension if not exists pgcrypto;

-- ============ ENUMS ============
create type app_role as enum ('fiduciary_admin','manager','service_manager','employee');
create type org_kind as enum ('fiduciary','company');
create type contract_kind as enum ('cdi','cdd');
create type contract_status as enum ('draft','active','ended','cancelled');
create type qualification_kind as enum ('qualified','unqualified');
create type residency_kind as enum ('resident','frontalier_fr','frontalier_be','frontalier_de');
create type tax_class as enum ('1','1a','2');
create type schedule_status as enum ('draft','published');
create type absence_status as enum ('pending','approved','refused','cancelled');
create type severity_kind as enum ('blocking','warning','info');
create type alert_state as enum ('open','handled','dismissed');

-- ============ ORGANIZATIONS ============
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind org_kind not null default 'fiduciary',
  created_at timestamptz not null default now()
);

-- profiles mirrors auth.users
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete restrict,
  full_name text not null default '',
  email text not null default '',
  is_org_admin boolean not null default false,
  created_at timestamptz not null default now()
);
create index on profiles(organization_id);

-- ============ COMPANIES ============
create table companies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  legal_name text not null,
  legal_form text,
  rcs_number text,
  ccss_matricule text,
  address_line text,
  postal_code text,
  city text,
  country text not null default 'LU',
  nace_code text,
  sector text,
  mutuality_class smallint check (mutuality_class between 1 and 4),
  accident_factor numeric(5,2) not null default 1.00,
  collective_agreement_id uuid,          -- FK added in migration 02
  reference_period_months smallint not null default 4 check (reference_period_months between 1 and 4),
  created_at timestamptz not null default now(),
  constraint ccss_matricule_format check (ccss_matricule is null or ccss_matricule ~ '^[0-9]{13}$')
);
create index on companies(organization_id);

create table departments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  name text not null,
  min_evening_coverage smallint
);
create index on departments(company_id);

-- ============ ROLES ============
-- company_id null => role applies to every company of the organization
create table user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  company_id uuid references companies(id) on delete cascade,
  role app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, company_id, role)
);
create index on user_roles(user_id);
create index on user_roles(company_id);

-- ============ AUTH HELPERS (security definer, bypass RLS) ============
create or replace function auth_org_id()
returns uuid language sql stable security definer set search_path = public as $$
  select organization_id from profiles where id = auth.uid();
$$;

create or replace function is_org_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_org_admin from profiles where id = auth.uid()), false);
$$;

create or replace function has_role(p_role app_role, p_company uuid default null)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from user_roles ur
    where ur.user_id = auth.uid()
      and ur.role = p_role
      and (ur.company_id is null or p_company is null or ur.company_id = p_company)
  );
$$;

-- true when the caller may read/act on a company
create or replace function has_company_access(p_company uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from companies c
    join profiles p on p.id = auth.uid() and p.organization_id = c.organization_id
    where c.id = p_company
      and (
        p.is_org_admin
        or exists (
          select 1 from user_roles ur
          where ur.user_id = auth.uid()
            and ur.role in ('fiduciary_admin','manager','service_manager')
            and (ur.company_id is null or ur.company_id = c.id)
        )
      )
  );
$$;

-- true when the caller may write on a company (employees are read-only self-service)
create or replace function can_manage_company(p_company uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from companies c
    join profiles p on p.id = auth.uid() and p.organization_id = c.organization_id
    where c.id = p_company
      and (
        p.is_org_admin
        or exists (
          select 1 from user_roles ur
          where ur.user_id = auth.uid()
            and ur.role in ('fiduciary_admin','manager')
            and (ur.company_id is null or ur.company_id = c.id)
        )
      )
  );
$$;

-- ============ AUDIT LOG (append only) ============
create table audit_log (
  id bigserial primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid,
  actor_label text,
  company_id uuid,
  entity_table text not null,
  entity_id uuid,
  action text not null,
  old_value jsonb,
  new_value jsonb
);
create index on audit_log(company_id, occurred_at desc);
create index on audit_log(entity_table, entity_id);

revoke update, delete on audit_log from anon, authenticated;

create or replace function fn_audit()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_company uuid; v_row jsonb;
begin
  v_row := to_jsonb(coalesce(new, old));
  v_company := nullif(v_row ->> 'company_id','')::uuid;
  insert into audit_log(actor_id, actor_label, company_id, entity_table, entity_id, action, old_value, new_value)
  values (
    auth.uid(),
    (select full_name from profiles where id = auth.uid()),
    v_company,
    tg_table_name,
    nullif(v_row ->> 'id','')::uuid,
    tg_op,
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when tg_op in ('UPDATE','INSERT') then to_jsonb(new) end
  );
  return coalesce(new, old);
end $$;
