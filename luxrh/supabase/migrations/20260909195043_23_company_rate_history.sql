
-- =========================================================================
--  La classe Mutualité, la classe d'activité et le facteur accident évoluent
--  dans le temps. Les figer sur `companies` rendait tout recalcul daté faux.
-- =========================================================================
create table company_rate_periods (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  activity_class text,                -- classe d'activité CCSS, détermine la classe de risque accident
  accident_risk_class text,           -- classe de risque retenue pour la période
  accident_factor numeric(5,2) not null default 1.00,
  mutuality_class smallint check (mutuality_class between 1 and 4),
  valid_from date not null,
  valid_to date,
  source text not null default 'CCSS',
  note text,
  created_at timestamptz not null default now(),
  constraint rate_period_range check (valid_to is null or valid_to > valid_from),
  exclude using gist (company_id with =, daterange(valid_from, valid_to, '[)') with &&)
);
create index on company_rate_periods(company_id, valid_from desc);

alter table company_rate_periods enable row level security;
create policy company_rates_read on company_rate_periods for select to authenticated
  using (has_company_access(company_id));
create policy company_rates_ins on company_rate_periods for insert to authenticated
  with check (can_manage_company(company_id));
create policy company_rates_upd on company_rate_periods for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy company_rates_del on company_rate_periods for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_company_rates after insert or update or delete on company_rate_periods
  for each row execute function fn_audit();

-- Reprise des valeurs actuelles en première période, ouverte depuis la plus
-- ancienne date utile du dossier.
insert into company_rate_periods (company_id, mutuality_class, accident_factor, valid_from, note)
select c.id, c.mutuality_class, c.accident_factor,
       least(
         coalesce((select min(ct.start_date) from contracts ct where ct.company_id = c.id), date '2019-01-01'),
         date '2019-01-01'),
       'Reprise des valeurs figées sur la fiche société lors de l''historisation.'
from companies c;

alter table companies drop column mutuality_class;
alter table companies drop column accident_factor;

-- Taux applicables à une date : le socle de tout calcul patronal.
create or replace function fn_company_rates(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare rp company_rate_periods; mut_rates jsonb; mut_rate numeric;
        accident_base numeric; class_rates jsonb; accident_rate numeric;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;

  select * into rp from company_rate_periods
  where company_id = p_company and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;

  if rp.id is null then
    return jsonb_build_object('found', false, 'evaluated_on', p_on,
      'message', 'Aucune période de taux déclarée pour cette société à cette date.');
  end if;

  mut_rates := (fn_param('mutuality_class_rates', p_on)).value_json;
  select (e->>'rate')::numeric into mut_rate
  from jsonb_array_elements(mut_rates) e
  where (e->>'class')::int = rp.mutuality_class;

  accident_base := fn_param_num('ccss_accident_base_employer', p_on);
  class_rates := (fn_param('accident_class_rates', p_on)).value_json;
  if class_rates is not null and rp.accident_risk_class is not null then
    select (e->>'rate')::numeric into accident_rate
    from jsonb_array_elements(class_rates) e
    where e->>'class' = rp.accident_risk_class;
  end if;
  accident_rate := coalesce(accident_rate, accident_base) * rp.accident_factor;

  return jsonb_build_object(
    'found', true,
    'evaluated_on', p_on,
    'period_from', rp.valid_from, 'period_to', rp.valid_to,
    'activity_class', rp.activity_class,
    'accident_risk_class', rp.accident_risk_class,
    'accident_factor', rp.accident_factor,
    'accident_base_rate', accident_base,
    'accident_rate', round(accident_rate, 4),
    'mutuality_class', rp.mutuality_class,
    'mutuality_rate', mut_rate,
    'employer_total_pct', round(
        fn_param_num('ccss_sickness_kind_employer', p_on)
      + fn_param_num('ccss_sickness_cash_employer', p_on)
      + fn_param_num('ccss_pension_employer', p_on)
      + fn_param_num('ccss_family_employer', p_on)
      + fn_param_num('ccss_health_work_employer', p_on)
      + accident_rate + coalesce(mut_rate, 0), 4),
    'legal_ref', (fn_param('ccss_accident_base_employer', p_on)).legal_ref);
end $$;

-- Ouvre une nouvelle période et clôt la précédente à la date d'effet.
create or replace function fn_set_company_rates(
  p_company uuid, p_from date, p_mutuality_class smallint,
  p_accident_factor numeric, p_activity_class text default null,
  p_accident_risk_class text default null, p_note text default null)
returns company_rate_periods language plpgsql volatile security definer set search_path = public as $$
declare prev company_rate_periods; created company_rate_periods;
begin
  if not can_manage_company(p_company) then raise exception 'Accès refusé'; end if;

  select * into prev from company_rate_periods
  where company_id = p_company and valid_from <= p_from and (valid_to is null or valid_to > p_from)
  limit 1;

  if prev.id is not null then
    if prev.valid_from = p_from then
      raise exception 'Une période démarre déjà au % pour cette société', p_from;
    end if;
    update company_rate_periods set valid_to = p_from where id = prev.id;
  end if;

  insert into company_rate_periods(
    company_id, activity_class, accident_risk_class, accident_factor,
    mutuality_class, valid_from, valid_to, note)
  values (p_company, p_activity_class, p_accident_risk_class, p_accident_factor,
          p_mutuality_class, p_from, prev.valid_to, p_note)
  returning * into created;

  return created;
end $$;

revoke execute on function fn_company_rates(uuid, date) from anon, public;
revoke execute on function fn_set_company_rates(uuid, date, smallint, numeric, text, text, text) from anon, public;
grant execute on function fn_company_rates(uuid, date) to authenticated;
grant execute on function fn_set_company_rates(uuid, date, smallint, numeric, text, text, text) to authenticated;
