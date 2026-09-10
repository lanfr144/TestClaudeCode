
-- ============ PARAMÈTRES LÉGAUX DATÉS ============
-- Aucune valeur légale n'est écrite dans le code : tout vit ici, avec sa plage de validité et sa source.
create type param_family as enum ('social','fiscal','worktime','leave','contract','headcount');

create table legal_parameters (
  id uuid primary key default gen_random_uuid(),
  family param_family not null,
  param_key text not null,
  label text not null,
  value_num numeric(14,4),
  value_text text,
  value_json jsonb,
  unit text,
  valid_from date not null,
  valid_to date,                                   -- null = toujours en vigueur
  index_ref numeric(8,2),                          -- indice appliqué (ex. 992,24)
  source text not null,                            -- CCSS, ACD, Legilux, calculé
  legal_ref text,                                  -- art. L.211-12
  note text,
  entered_by uuid references auth.users(id),
  entered_at timestamptz not null default now(),
  validated_by uuid references auth.users(id),     -- double lecture
  validated_at timestamptz,
  constraint valid_range check (valid_to is null or valid_to > valid_from),
  constraint one_value check (num_nonnulls(value_num, value_text, value_json) = 1),
  exclude using gist (
    param_key with =,
    daterange(valid_from, valid_to, '[)') with &&
  )
);
create index on legal_parameters(param_key, valid_from desc);
create index on legal_parameters(family);

-- Lecture datée : le socle de tout le moteur.
create or replace function fn_param_num(p_key text, p_on date default current_date)
returns numeric language sql stable set search_path = public as $$
  select lp.value_num from legal_parameters lp
  where lp.param_key = p_key
    and lp.valid_from <= p_on
    and (lp.valid_to is null or lp.valid_to > p_on)
  limit 1;
$$;

create or replace function fn_param(p_key text, p_on date default current_date)
returns legal_parameters language sql stable set search_path = public as $$
  select lp.* from legal_parameters lp
  where lp.param_key = p_key
    and lp.valid_from <= p_on
    and (lp.valid_to is null or lp.valid_to > p_on)
  limit 1;
$$;

-- Barèmes fiscaux datés (V2, structure posée dès maintenant)
create table tax_scales (
  id uuid primary key default gen_random_uuid(),
  periodicity text not null check (periodicity in ('monthly','daily')),
  tax_class tax_class not null,
  bracket_from numeric(12,2) not null,
  bracket_to numeric(12,2),
  rate numeric(6,4) not null,
  deduction numeric(12,2) not null default 0,
  valid_from date not null,
  valid_to date,
  source text not null default 'ACD'
);
create index on tax_scales(periodicity, tax_class, valid_from desc);

-- ============ JOURS FÉRIÉS ============
-- Générés par algorithme (calcul de Pâques), jamais saisis à la main.
create table public_holidays (
  id uuid primary key default gen_random_uuid(),
  year smallint not null,
  holiday_date date not null,
  name text not null,
  is_mobile boolean not null default false,
  collective_agreement_id uuid,       -- non null = jour férié d'usage propre à une CCT
  unique (holiday_date, collective_agreement_id)
);
create index on public_holidays(year);

-- Comput ecclésiastique de Gauss/Meeus — dimanche de Pâques grégorien
create or replace function fn_easter_sunday(p_year int)
returns date language plpgsql immutable as $$
declare a int; b int; c int; d int; e int; f int; g int; h int;
        i int; k int; l int; m int; mo int; da int;
begin
  a := p_year % 19;
  b := p_year / 100;
  c := p_year % 100;
  d := b / 4;
  e := b % 4;
  f := (b + 8) / 25;
  g := (b - f + 1) / 3;
  h := (19 * a + b - d - g + 15) % 30;
  i := c / 4;
  k := c % 4;
  l := (32 + 2 * e + 2 * i - h - k) % 7;
  m := (a + 11 * h + 22 * l) / 451;
  mo := (h + l - 7 * m + 114) / 31;
  da := ((h + l - 7 * m + 114) % 31) + 1;
  return make_date(p_year, mo, da);
end $$;

-- Les 11 jours fériés légaux luxembourgeois, Journée de l'Europe incluse.
create or replace function fn_generate_public_holidays(p_year int)
returns setof public_holidays language plpgsql security definer set search_path = public as $$
declare easter date := fn_easter_sunday(p_year);
begin
  insert into public_holidays(year, holiday_date, name, is_mobile) values
    (p_year, make_date(p_year,1,1),   'Jour de l''An', false),
    (p_year, easter + 1,              'Lundi de Pâques', true),
    (p_year, make_date(p_year,5,1),   'Fête du Travail', false),
    (p_year, make_date(p_year,5,9),   'Journée de l''Europe', false),
    (p_year, easter + 39,             'Ascension', true),
    (p_year, easter + 50,             'Lundi de Pentecôte', true),
    (p_year, make_date(p_year,6,23),  'Fête nationale', false),
    (p_year, make_date(p_year,8,15),  'Assomption', false),
    (p_year, make_date(p_year,11,1),  'Toussaint', false),
    (p_year, make_date(p_year,12,25), 'Noël', false),
    (p_year, make_date(p_year,12,26), 'Saint-Étienne', false)
  on conflict (holiday_date, collective_agreement_id) do nothing;

  return query select * from public_holidays
    where year = p_year and collective_agreement_id is null
    order by holiday_date;
end $$;

create or replace function fn_is_public_holiday(p_date date, p_cba uuid default null)
returns boolean language sql stable set search_path = public as $$
  select exists (
    select 1 from public_holidays h
    where h.holiday_date = p_date
      and (h.collective_agreement_id is null or h.collective_agreement_id = p_cba)
  );
$$;

-- ============ CONVENTIONS COLLECTIVES ============
create table collective_agreements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,  -- null = CCT pré-chargée, partagée
  code text not null,
  name text not null,
  sector text not null,
  valid_from date not null,
  valid_to date,
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);
create index on collective_agreements(organization_id);

alter table companies
  add constraint companies_cba_fk
  foreign key (collective_agreement_id) references collective_agreements(id) on delete set null;

-- Les blocs de règles : un formulaire alimente ce JSONB, aucune règle n'est écrite en code.
create type cba_block as enum
  ('salary_grid','worktime','leave','premiums','surcharges','notice_probation','custom_holidays');

create table cba_rules (
  id uuid primary key default gen_random_uuid(),
  collective_agreement_id uuid not null references collective_agreements(id) on delete cascade,
  block cba_block not null,
  rules jsonb not null default '{}'::jsonb,
  is_complete boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (collective_agreement_id, block)
);

create table cba_salary_grids (
  id uuid primary key default gen_random_uuid(),
  collective_agreement_id uuid not null references collective_agreements(id) on delete cascade,
  category text not null,
  seniority_from_years numeric(4,1) not null default 0,
  seniority_to_years numeric(4,1),
  monthly_amount numeric(10,2) not null,
  index_ref numeric(8,2)
);
create index on cba_salary_grids(collective_agreement_id, category);

-- Valeur d'une règle de CCT, avec repli sur null si la CCT ne dit rien
create or replace function fn_cba_value(p_cba uuid, p_block cba_block, p_path text)
returns jsonb language sql stable set search_path = public as $$
  select r.rules #> string_to_array(p_path, '.')
  from cba_rules r
  where r.collective_agreement_id = p_cba and r.block = p_block;
$$;
