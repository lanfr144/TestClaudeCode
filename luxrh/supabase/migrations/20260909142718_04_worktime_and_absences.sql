
-- ============ TEMPS DE TRAVAIL ============
create table shift_templates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  name text not null,
  start_time time not null,
  end_time time not null,
  break_minutes smallint not null default 0,
  color text not null default '#017E84',
  department_id uuid references departments(id) on delete set null
);
create index on shift_templates(company_id);

create table reference_periods (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  department_id uuid references departments(id) on delete set null,
  label text not null,
  start_date date not null,
  end_date date not null,
  months smallint not null check (months between 1 and 4),
  constraint prl_range check (end_date > start_date)
);
create index on reference_periods(company_id);

create table schedules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  department_id uuid references departments(id) on delete set null,
  week_start date not null,
  label text,
  status schedule_status not null default 'draft',
  published_at timestamptz,
  published_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (company_id, department_id, week_start)
);
create index on schedules(company_id, week_start);

create table shifts (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references schedules(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  shift_date date not null,
  start_time time not null,
  end_time time not null,
  break_minutes smallint not null default 0,
  label text,
  template_id uuid references shift_templates(id) on delete set null,
  created_at timestamptz not null default now()
);
create index on shifts(schedule_id);
create index on shifts(employee_id, shift_date);

-- Horodatage d'un shift, minuit franchi compris
create or replace function fn_shift_start_ts(p_date date, p_start time)
returns timestamp language sql immutable as $$ select p_date + p_start; $$;

create or replace function fn_shift_end_ts(p_date date, p_start time, p_end time)
returns timestamp language sql immutable as $$
  select case when p_end <= p_start then (p_date + 1) + p_end else p_date + p_end end;
$$;

create or replace function fn_shift_hours(p_start time, p_end time, p_break int default 0)
returns numeric language sql immutable as $$
  select round(
    (extract(epoch from (
        fn_shift_end_ts(date '2000-01-01', p_start, p_end)
      - fn_shift_start_ts(date '2000-01-01', p_start)
    )) / 3600.0)::numeric - (coalesce(p_break, 0) / 60.0), 2);
$$;

-- Registre du temps de travail — art. L.211-29, conservé 10 ans, modifications tracées
create table time_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  entry_date date not null,
  start_time time,
  end_time time,
  break_minutes smallint not null default 0,
  worked_hours numeric(5,2),
  planned_hours numeric(5,2),
  sunday_hours numeric(5,2) not null default 0,
  holiday_hours numeric(5,2) not null default 0,
  night_hours numeric(5,2) not null default 0,
  overtime_hours numeric(5,2) not null default 0,
  is_validated boolean not null default false,
  source text not null default 'manual',
  note text,
  created_at timestamptz not null default now(),
  unique (employee_id, entry_date)
);
create index on time_entries(company_id, entry_date);

create trigger audit_time_entries after insert or update or delete on time_entries
  for each row execute function fn_audit();
create trigger audit_shifts after insert or update or delete on shifts
  for each row execute function fn_audit();
create trigger audit_schedules after insert or update or delete on schedules
  for each row execute function fn_audit();

-- ============ ABSENCES ============
create type absence_category as enum ('annual_leave','sick','extraordinary','public_holiday','unpaid','compensatory');

create table absence_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  label text not null,
  category absence_category not null,
  entitlement_days numeric(4,1),
  legal_ref text,
  frequency_note text,
  requires_certificate boolean not null default false,
  is_paid boolean not null default true,
  counts_against_leave boolean not null default false
);

create table absences (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  absence_type_id uuid not null references absence_types(id) on delete restrict,
  start_date date not null,
  end_date date not null,
  days_count numeric(5,2) not null default 0,
  status absence_status not null default 'pending',
  comment text,
  certificate_received boolean not null default false,
  certificate_received_at date,
  certificate_document_id uuid,
  requested_by uuid references auth.users(id),
  decided_by uuid references auth.users(id),
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  constraint absence_range check (end_date >= start_date)
);
create index on absences(company_id, start_date);
create index on absences(employee_id, start_date);

create trigger audit_absences after insert or update or delete on absences
  for each row execute function fn_audit();

-- ============ DOCUMENTS ============
create table documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid references employees(id) on delete cascade,
  entity_table text,
  entity_id uuid,
  name text not null,
  storage_path text not null,
  mime_type text,
  size_bytes bigint,
  retention_until date,
  is_sensitive boolean not null default false,
  uploaded_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index on documents(company_id);
create index on documents(employee_id);

-- ============ VIGILANCE ============
create table compliance_alerts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid references employees(id) on delete set null,
  rule_code text not null,
  title text not null,
  detail text not null,
  consequence text,
  legal_ref text,
  severity severity_kind not null,
  due_date date,
  state alert_state not null default 'open',
  handled_by uuid references auth.users(id),
  handled_at timestamptz,
  handled_note text,
  first_seen_at timestamptz not null default now()
);
create unique index compliance_alerts_key
  on compliance_alerts(company_id, rule_code, coalesce(employee_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index on compliance_alerts(company_id, state, due_date);

create table headcount_snapshots (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  month date not null,
  headcount numeric(8,2) not null,
  unique (company_id, month)
);
