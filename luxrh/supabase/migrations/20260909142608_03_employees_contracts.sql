
-- ============ CLÉ DE CONTRÔLE DU MATRICULE NATIONAL LUXEMBOURGEOIS ============
-- 13 chiffres : 11 chiffres signifiants + clé Luhn (12e) + clé Verhoeff (13e).
create or replace function fn_luhn_check_digit(p_digits text)
returns int language plpgsql immutable as $$
declare s int := 0; d int; i int; pos int := 0;
begin
  for i in reverse length(p_digits)..1 loop
    d := substr(p_digits, i, 1)::int;
    if pos % 2 = 0 then
      d := d * 2;
      if d > 9 then d := d - 9; end if;
    end if;
    s := s + d;
    pos := pos + 1;
  end loop;
  return (10 - (s % 10)) % 10;
end $$;

create or replace function fn_verhoeff_check_digit(p_digits text)
returns int language plpgsql immutable as $$
declare
  dt int[][] := array[
    array[0,1,2,3,4,5,6,7,8,9],
    array[1,2,3,4,0,6,7,8,9,5],
    array[2,3,4,0,1,7,8,9,5,6],
    array[3,4,0,1,2,8,9,5,6,7],
    array[4,0,1,2,3,9,5,6,7,8],
    array[5,9,8,7,6,0,4,3,2,1],
    array[6,5,9,8,7,1,0,4,3,2],
    array[7,6,5,9,8,2,1,0,4,3],
    array[8,7,6,5,9,3,2,1,0,4],
    array[9,8,7,6,5,4,3,2,1,0]];
  pt int[][] := array[
    array[0,1,2,3,4,5,6,7,8,9],
    array[1,5,7,6,2,8,3,0,9,4],
    array[5,8,0,3,7,9,6,1,4,2],
    array[8,9,1,6,0,4,3,5,2,7],
    array[9,4,5,3,1,2,6,8,7,0],
    array[4,2,8,6,5,7,3,9,0,1],
    array[2,7,9,3,8,0,6,4,1,5],
    array[7,0,4,6,9,1,3,2,5,8]];
  inv int[] := array[0,4,3,2,1,5,6,7,8,9];
  c int := 0; i int; k int := 0; d int;
begin
  for i in reverse length(p_digits)..1 loop
    k := k + 1;
    d := substr(p_digits, i, 1)::int;
    c := dt[c + 1][ pt[((k % 8)) + 1][d + 1] + 1 ];
  end loop;
  return inv[c + 1];
end $$;

create or replace function fn_valid_national_id(p_id text)
returns boolean language plpgsql immutable as $$
declare base text; clean text;
begin
  if p_id is null then return true; end if;
  clean := regexp_replace(p_id, '\D', '', 'g');
  if length(clean) <> 13 then return false; end if;
  base := substr(clean, 1, 11);
  return fn_luhn_check_digit(base) = substr(clean,12,1)::int
     and fn_verhoeff_check_digit(base) = substr(clean,13,1)::int;
end $$;

-- ============ CHIFFREMENT AU REPOS DES DONNÉES SENSIBLES ============
create table app_secrets (
  key text primary key,
  secret text not null
);
revoke all on app_secrets from anon, authenticated;
insert into app_secrets(key, secret)
  values ('field_key', encode(extensions.gen_random_bytes(32), 'hex'));

create or replace function fn_encrypt_field(p_plain text)
returns bytea language sql volatile security definer set search_path = public, extensions as $$
  select case when p_plain is null or p_plain = '' then null
    else extensions.pgp_sym_encrypt(p_plain, (select secret from app_secrets where key='field_key')) end;
$$;

create or replace function fn_decrypt_field(p_cipher bytea)
returns text language sql stable security definer set search_path = public, extensions as $$
  select case when p_cipher is null then null
    else extensions.pgp_sym_decrypt(p_cipher, (select secret from app_secrets where key='field_key')) end;
$$;

-- ============ EMPLOYÉS ============
create table employees (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  department_id uuid references departments(id) on delete set null,
  first_name text not null,
  last_name text not null,
  birth_date date,
  residency residency_kind not null,
  qualification qualification_kind not null default 'unqualified',
  address_line text,
  postal_code text,
  city text,
  country text not null default 'LU',
  email text,
  phone text,
  national_id_enc bytea,
  iban_enc bytea,
  national_id_hint text,
  created_at timestamptz not null default now()
);
create index on employees(company_id);
create index on employees(user_id);

create table employee_tax_cards (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references employees(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  tax_class tax_class not null,
  rate numeric(6,4),
  monthly_allowance numeric(10,2) not null default 0,
  valid_from date not null,
  valid_to date,
  exclude using gist (employee_id with =, daterange(valid_from, valid_to, '[)') with &&)
);

create or replace function fn_employee_sensitive(p_employee uuid)
returns table (national_id text, iban text)
language plpgsql stable security definer set search_path = public as $$
declare v_company uuid;
begin
  select company_id into v_company from employees where id = p_employee;
  if v_company is null then raise exception 'Employé introuvable'; end if;
  if not (can_manage_company(v_company)
          or exists (select 1 from employees e where e.id = p_employee and e.user_id = auth.uid())) then
    raise exception 'Accès refusé aux données sensibles';
  end if;
  return query
    select fn_decrypt_field(e.national_id_enc), fn_decrypt_field(e.iban_enc)
    from employees e where e.id = p_employee;
end $$;

create or replace function fn_set_employee_sensitive(p_employee uuid, p_national_id text, p_iban text)
returns void language plpgsql volatile security definer set search_path = public as $$
declare v_company uuid;
begin
  select company_id into v_company from employees where id = p_employee;
  if not can_manage_company(v_company) then raise exception 'Accès refusé'; end if;
  if p_national_id is not null and not fn_valid_national_id(p_national_id) then
    raise exception 'Matricule national invalide : la clé de contrôle ne correspond pas';
  end if;
  update employees set
    national_id_enc = case when p_national_id is null then national_id_enc
                           else fn_encrypt_field(regexp_replace(p_national_id,'\D','','g')) end,
    national_id_hint = case when p_national_id is null then national_id_hint
                            else right(regexp_replace(p_national_id,'\D','','g'), 4) end,
    iban_enc = case when p_iban is null then iban_enc
                    else fn_encrypt_field(replace(upper(p_iban),' ','')) end
  where id = p_employee;
end $$;

-- ============ CONTRATS ============
create table contracts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  kind contract_kind not null,
  status contract_status not null default 'draft',
  job_title text not null,
  job_description text,
  work_place text,
  category text,
  start_date date not null,
  end_date date,
  cdd_reason text,
  renewal_count smallint not null default 0,
  previous_contract_id uuid references contracts(id) on delete set null,
  monthly_gross numeric(10,2) not null,
  index_ref numeric(8,2),
  weekly_hours numeric(5,2) not null default 40,
  days_per_week numeric(3,1) not null default 5,
  work_distribution text,
  reference_period_months smallint not null default 4,
  night_work boolean not null default false,
  annual_leave_days numeric(5,2),
  break_minutes smallint,
  non_compete_clause boolean not null default false,
  exclusivity_clause boolean not null default false,
  probation_length int,
  probation_unit text check (probation_unit in ('weeks','months')),
  version smallint not null default 1,
  signed_at date,
  created_at timestamptz not null default now(),
  constraint cdd_needs_end check (kind <> 'cdd' or end_date is not null),
  constraint cdd_needs_reason check (kind <> 'cdd' or cdd_reason is not null)
);
create index on contracts(company_id);
create index on contracts(employee_id);

create table contract_amendments (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  effective_date date not null,
  reason text not null,
  changes jsonb not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index on contract_amendments(contract_id);

create table probation_extensions (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  from_date date not null,
  to_date date not null,
  days_added int not null,
  reason text not null default 'incapacité de travail'
);

create table contract_terminations (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  reason text not null,
  is_personal_ground boolean not null default true,
  notified_on date not null,
  notice_start date,
  notice_end date,
  severance_months numeric(4,1),
  created_at timestamptz not null default now()
);
create index on contract_terminations(company_id, notified_on);

create trigger audit_contracts after insert or update or delete on contracts
  for each row execute function fn_audit();
create trigger audit_terminations after insert or update or delete on contract_terminations
  for each row execute function fn_audit();
