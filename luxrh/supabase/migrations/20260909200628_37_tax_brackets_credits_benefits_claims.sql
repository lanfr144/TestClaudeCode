
-- =========================================================================
--  Barème de retenue d'impôt, tranche par tranche et daté.
-- =========================================================================
drop table if exists tax_scales;

create type tax_periodicity as enum ('monthly', 'daily', 'annual');

create table tax_brackets (
  id uuid primary key default gen_random_uuid(),
  tax_class tax_class not null,
  periodicity tax_periodicity not null default 'monthly',
  valid_from date not null,
  valid_to date,
  bracket_min numeric(12,2) not null,
  bracket_max numeric(12,2),                  -- null = dernière tranche
  base_tax numeric(12,2) not null default 0,  -- impôt dû à l'entrée de la tranche
  rate_over_min numeric(7,4) not null,        -- % appliqué au dépassement
  source text not null default 'ACD',
  legal_ref text,
  note text,
  constraint bracket_range check (bracket_max is null or bracket_max > bracket_min),
  constraint bracket_validity check (valid_to is null or valid_to > valid_from)
);
create index on tax_brackets(tax_class, periodicity, valid_from desc, bracket_min);

alter table tax_brackets enable row level security;
create policy brackets_read on tax_brackets for select to authenticated using (true);
create policy brackets_ins on tax_brackets for insert to authenticated with check (is_org_admin());
create policy brackets_upd on tax_brackets for update to authenticated
  using (is_org_admin()) with check (is_org_admin());
create policy brackets_del on tax_brackets for delete to authenticated using (is_org_admin());

-- Retenue d'impôt : tranche applicable, impôt de base, taux sur le dépassement.
create or replace function fn_income_tax(
  p_taxable numeric, p_class tax_class, p_on date default current_date,
  p_periodicity tax_periodicity default 'monthly')
returns jsonb language plpgsql stable set search_path = public as $$
declare b tax_brackets; tax numeric;
begin
  select * into b from tax_brackets
  where tax_class = p_class and periodicity = p_periodicity
    and valid_from <= p_on and (valid_to is null or valid_to > p_on)
    and p_taxable >= bracket_min and (bracket_max is null or p_taxable < bracket_max)
  order by bracket_min desc limit 1;

  if b.id is null then
    return jsonb_build_object('found', false, 'taxable', p_taxable, 'tax', null,
      'message', 'Aucun barème chargé pour la classe ' || p_class || ' au ' || to_char(p_on,'DD.MM.YYYY')
        || '. Le calcul est suspendu plutôt que faux.');
  end if;

  tax := b.base_tax + (p_taxable - b.bracket_min) * b.rate_over_min / 100.0;

  return jsonb_build_object(
    'found', true, 'taxable', p_taxable, 'tax', round(greatest(tax, 0), 2),
    'tax_class', p_class, 'periodicity', p_periodicity,
    'bracket_min', b.bracket_min, 'bracket_max', b.bracket_max,
    'base_tax', b.base_tax, 'rate_over_min', b.rate_over_min,
    'valid_from', b.valid_from, 'source', b.source, 'legal_ref', b.legal_ref);
end $$;

-- =========================================================================
--  Crédits d'impôt et mentions de la fiche de retenue.
-- =========================================================================
create table tax_credits (
  id uuid primary key default gen_random_uuid(),
  code text not null,                     -- CIS, CIM, CISSM, CI-CO2, CIHS
  label text not null,
  applies_to_classes tax_class[],         -- null = toutes
  income_min numeric(12,2),
  income_max numeric(12,2),
  monthly_amount numeric(10,2),
  prorated_on_hours boolean not null default false,
  valid_from date not null,
  valid_to date,
  source text not null default 'ACD',
  legal_ref text,
  note text,
  constraint credit_validity check (valid_to is null or valid_to > valid_from)
);
create index on tax_credits(code, valid_from desc);

alter table tax_credits enable row level security;
create policy credits_read on tax_credits for select to authenticated using (true);
create policy credits_ins on tax_credits for insert to authenticated with check (is_org_admin());
create policy credits_upd on tax_credits for update to authenticated
  using (is_org_admin()) with check (is_org_admin());
create policy credits_del on tax_credits for delete to authenticated using (is_org_admin());

insert into tax_credits (code, label, applies_to_classes, valid_from, legal_ref, note) values
('CIS','Crédit d''impôt salarié', null, '2019-01-01','art. 139bis LIR',
 'Barème à charger depuis le fichier « Formules du calcul automatisé de l''impôt » de l''ACD.'),
('CIM','Crédit d''impôt monoparental', array['1a']::tax_class[], '2019-01-01','art. 154ter LIR', null),
('CISSM','Crédit d''impôt salaire social minimum', null, '2019-01-01','art. 139quater LIR',
 'Proratisé sur les heures prestées.'),
('CI-CO2','Crédit d''impôt CO2', null, '2023-01-01','art. 154quinquies LIR', null),
('CIHS','Crédit d''impôt heures supplémentaires', null, '2019-01-01','art. 139sexies LIR', null);

update tax_credits set prorated_on_hours = true where code = 'CISSM';

-- Mentions portées par la fiche de retenue.
alter table employee_tax_cards
  add column if not exists credits jsonb not null default '[]'::jsonb,
  add column if not exists commute_distance_km numeric(6,1),
  add column if not exists professional_expenses_monthly numeric(10,2),
  add column if not exists other_deductions_monthly numeric(10,2) not null default 0,
  add column if not exists card_reference text,
  add column if not exists issued_on date;

comment on column employee_tax_cards.credits is
  'Codes des crédits d''impôt mentionnés sur la fiche (CIS, CIM, CISSM, CI-CO2, CIHS).';
comment on column employee_tax_cards.commute_distance_km is
  'Distance domicile-travail retenue pour le forfait de frais de déplacement.';

insert into legal_parameters
  (family, param_key, label, value_json, unit, valid_from, source, legal_ref, note)
values
('fiscal','commute_allowance_scale','Forfait de frais de déplacement par tranche de distance',
 '[]'::jsonb,'EUR/an','2019-01-01','ACD','art. 105bis LIR',
 'Barème à charger depuis la source officielle : le forfait dépend de la distance en unités '
 'd''éloignement. Laissé vide tant qu''il n''est pas sourcé, pour ne produire aucun montant faux.');

-- Frais de déplacement : forfait annuel selon la distance.
create or replace function fn_commute_allowance(p_km numeric, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare scale jsonb; item jsonb; amount numeric;
begin
  scale := (fn_param('commute_allowance_scale', p_on)).value_json;
  if scale is null or jsonb_array_length(scale) = 0 then
    return jsonb_build_object('found', false, 'km', p_km,
      'message','Le barème des frais de déplacement n''est pas encore chargé dans le référentiel.',
      'legal_ref', (fn_param('commute_allowance_scale', p_on)).legal_ref);
  end if;
  for item in select value from jsonb_array_elements(scale) order by (value->>'from_km')::numeric loop
    if p_km >= (item->>'from_km')::numeric then amount := (item->>'annual_amount')::numeric; end if;
  end loop;
  return jsonb_build_object('found', true, 'km', p_km, 'annual_amount', amount,
    'monthly_amount', round(coalesce(amount,0) / 12.0, 2),
    'legal_ref', (fn_param('commute_allowance_scale', p_on)).legal_ref);
end $$;

-- =========================================================================
--  Avantages en nature.
-- =========================================================================
create table benefit_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  label text not null,
  valuation_method text not null,        -- forfait, valeur réelle, barème
  is_taxable boolean not null default true,
  is_contributory boolean not null default true,
  valuation_params jsonb not null default '{}'::jsonb,
  legal_ref text,
  note text
);

alter table benefit_types enable row level security;
create policy benefit_types_read on benefit_types for select to authenticated using (true);
create policy benefit_types_ins on benefit_types for insert to authenticated with check (is_org_admin());
create policy benefit_types_upd on benefit_types for update to authenticated
  using (is_org_admin()) with check (is_org_admin());
create policy benefit_types_del on benefit_types for delete to authenticated using (is_org_admin());

insert into benefit_types (code, label, valuation_method, is_taxable, is_contributory, legal_ref, note) values
('company_car','Voiture de fonction','barème', true, true,'art. 104 LIR',
 'Évaluation forfaitaire mensuelle en pourcentage de la valeur du véhicule, modulée par les émissions.'),
('meal_vouchers','Chèques-repas','forfait', true, true, null,
 'Part patronale exonérée jusqu''au plafond réglementaire.'),
('housing','Logement de fonction','valeur réelle', true, true,'art. 104 LIR', null),
('fuel_card','Carte carburant','valeur réelle', true, true, null, null),
('phone','Téléphone et forfait','forfait', true, true, null, null),
('meals','Repas fournis','barème', true, true, null, null),
('interest_free_loan','Prêt sans intérêt','barème', true, true, null, null),
('training','Formation professionnelle','valeur réelle', false, false, null,
 'Non imposable lorsqu''elle relève de l''intérêt de l''entreprise.'),
('supplementary_pension','Régime complémentaire de pension','barème', true, false,'art. 115 LIR', null);

alter table contract_pay_components
  add column if not exists benefit_type_id uuid references benefit_types(id) on delete set null;

-- =========================================================================
--  Sinistralité et classes dynamiques.
-- =========================================================================
create table company_accident_claims (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  year smallint not null,
  claim_count int not null default 0,
  days_lost int not null default 0,
  cost numeric(12,2),
  note text,
  unique (company_id, year)
);

alter table company_accident_claims enable row level security;
create policy claims_read on company_accident_claims for select to authenticated
  using (has_company_access(company_id));
create policy claims_ins on company_accident_claims for insert to authenticated
  with check (can_manage_company(company_id));
create policy claims_upd on company_accident_claims for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy claims_del on company_accident_claims for delete to authenticated
  using (can_manage_company(company_id));

insert into legal_parameters
  (family, param_key, label, value_json, unit, valid_from, source, legal_ref, note)
values
('ccss','accident_bonus_malus_scale','Barème bonus-malus accident',
 '[]'::jsonb,'facteur','2019-01-01','CCSS',null,
 'Barème à charger depuis l''avis annuel du CCSS. Tant qu''il est vide, l''application '
 'affiche la sinistralité constatée sans en déduire de facteur.'),
('ccss','mutuality_class_thresholds','Seuils d''absentéisme des classes de Mutualité',
 '[]'::jsonb,'%','2019-01-01','CCSS',null,
 'Barème à charger depuis l''avis annuel du CCSS : le taux d''absentéisme financier de '
 'l''entreprise détermine sa classe.');

-- Taux d'absentéisme financier de l'entreprise, base du classement Mutualité.
create or replace function fn_company_absenteeism(p_company uuid, p_year int)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare sick_days numeric; worked_days numeric; headcount numeric; rate numeric; thresholds jsonb;
        item jsonb; suggested smallint;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;

  select coalesce(sum(a.days_count), 0) into sick_days
  from absences a join absence_types t on t.id = a.absence_type_id
  where a.company_id = p_company and t.category = 'sick' and a.status <> 'refused'
    and extract(year from a.start_date) = p_year;

  select coalesce(avg(hs.headcount), 0) into headcount
  from headcount_snapshots hs
  where hs.company_id = p_company and extract(year from hs.month) = p_year;

  if headcount = 0 then
    select count(*) into headcount from contracts c
    where c.company_id = p_company and c.status = 'active'
      and c.start_date <= make_date(p_year, 12, 31);
  end if;

  worked_days := headcount * 220;   -- jours ouvrables théoriques annuels
  rate := case when worked_days > 0 then round(sick_days / worked_days * 100, 2) else null end;

  thresholds := (fn_param('mutuality_class_thresholds', make_date(p_year,1,1))).value_json;
  if thresholds is not null and jsonb_array_length(thresholds) > 0 and rate is not null then
    for item in select value from jsonb_array_elements(thresholds) order by (value->>'from_rate')::numeric loop
      if rate >= (item->>'from_rate')::numeric then suggested := (item->>'class')::smallint; end if;
    end loop;
  end if;

  return jsonb_build_object(
    'company_id', p_company, 'year', p_year,
    'sick_days', sick_days, 'average_headcount', round(headcount, 2),
    'theoretical_working_days', worked_days,
    'absenteeism_rate_pct', rate,
    'suggested_mutuality_class', suggested,
    'message', case when suggested is null
      then 'Le barème des seuils de Mutualité n''est pas chargé : le taux est affiché, la classe reste déclarative.'
      else 'Classe suggérée par le taux constaté. Le classement officiel du CCSS fait foi.' end);
end $$;

revoke execute on function fn_income_tax(numeric, tax_class, date, tax_periodicity) from anon, public;
revoke execute on function fn_commute_allowance(numeric, date) from anon, public;
revoke execute on function fn_company_absenteeism(uuid, int) from anon, public;
grant execute on function fn_income_tax(numeric, tax_class, date, tax_periodicity) to authenticated;
grant execute on function fn_commute_allowance(numeric, date) to authenticated;
grant execute on function fn_company_absenteeism(uuid, int) to authenticated;
