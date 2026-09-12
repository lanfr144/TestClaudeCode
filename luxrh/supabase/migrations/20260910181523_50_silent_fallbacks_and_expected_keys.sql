-- 50 — Erreurs silencieuses, seuils légaux en dur, clés attendues
--
-- Trois corrections, toutes issues de la revue du 10 septembre 2026.
--
--   1. `fn_company_rates` retombait en silence sur le taux d'accident de base
--      quand le taux de classe n'était pas trouvé — et renvoyait `found: true`.
--   2. Trois contraintes `check` inscrivaient un seuil légal en dur.
--   3. `fn_referential_gaps` ne pouvait pas signaler une clé entièrement absente :
--      elle ne voyait que les clés déjà présentes. Une clé que le moteur lit et
--      que personne n'a chargée restait invisible — c'est ainsi que le point 1
--      a pu passer inaperçu.

-- ===========================================================================
-- 1. Les clés que le moteur attend
-- ===========================================================================
-- Le référentiel dit ce qu'il contient ; il ne disait pas ce qu'il devrait
-- contenir. Cette table porte la liste des clés que le moteur lit réellement,
-- relevée dans le code des migrations, avec la ou les fonctions qui les lisent.
--
-- Elle ne contient AUCUNE valeur : une clé attendue sans version chargée est
-- exactement ce que la règle 7 du CLAUDE.md demande de signaler plutôt que
-- d'inventer.

create table if not exists expected_parameters (
  param_key   text primary key,
  read_by     text not null,
  note        text
);

alter table expected_parameters enable row level security;

create policy expected_parameters_read on expected_parameters
  for select to authenticated using (true);

comment on table expected_parameters is
  'Clés de legal_parameters que le moteur lit. Sert à fn_referential_gaps pour signaler une clé attendue dont aucune version n''est chargée. Ne porte aucune valeur légale.';
comment on column expected_parameters.read_by is
  'Fonction(s) du moteur qui lisent la clé, relevées dans le code des migrations.';

insert into expected_parameters (param_key, read_by) values
  ('accident_class_rates', 'fn_company_rates'),
  ('annual_leave_min_days', 'fn_annual_leave_rule, fn_check_cba_not_worse'),
  ('break_threshold_hours', 'fn_validate_schedule'),
  ('breastfeeding_break_minutes', 'fn_validate_schedule'),
  ('breastfeeding_breaks_per_day', 'fn_validate_schedule'),
  ('ccss_accident_base_employer', 'fn_company_rates'),
  ('ccss_family_employer', 'fn_company_rates'),
  ('ccss_health_work_employer', 'fn_company_rates'),
  ('ccss_pension_employer', 'fn_company_rates'),
  ('ccss_sickness_cash_employer', 'fn_company_rates'),
  ('ccss_sickness_kind_employer', 'fn_company_rates'),
  ('cdd_alert_days_1', 'fn_compliance_scan'),
  ('cdd_alert_days_2', 'fn_compliance_scan'),
  ('cdd_carence_ratio', 'fn_compliance_scan'),
  ('cdd_max_months', 'fn_compliance_scan, fn_contract_compliance'),
  ('cdd_max_renewals', 'fn_compliance_scan, fn_contract_compliance'),
  ('collective_dismissal_30d', 'fn_collective_dismissal_counters'),
  ('collective_dismissal_90d', 'fn_collective_dismissal_counters'),
  ('collective_negotiation_days', 'fn_simulate_collective_dismissal'),
  ('collective_onc_days', 'fn_simulate_collective_dismissal'),
  ('collective_onc_seizure_days', 'fn_simulate_collective_dismissal'),
  ('commute_allowance_scale', 'fn_commute_allowance'),
  ('delegate_eligibility_min_age', 'fn_delegation_eligibility'),
  ('delegate_eligibility_seniority_months', 'fn_delegation_eligibility'),
  ('delegation_approach_threshold', 'fn_compliance_scan, fn_headcount_obligations'),
  ('delegation_delegates_scale', 'fn_headcount_obligations'),
  ('delegation_reference_months', 'fn_headcount'),
  ('delegation_threshold', 'fn_compliance_scan, fn_headcount, fn_headcount_obligations'),
  ('disabled_extra_leave_scale', 'fn_disability_extra_leave'),
  ('dismissal_protection_weeks', 'fn_sick_counters'),
  ('holiday_surcharge_pct', 'fn_check_cba_not_worse, fn_validate_schedule'),
  ('leave_accrual_per_month', 'fn_leave_balance'),
  ('leave_month_fraction_days', 'fn_leave_balance'),
  ('max_daily_hours', 'fn_validate_schedule'),
  ('max_reference_period_months', 'fn_check_cba_not_worse, fn_contract_compliance, fn_reference_period_status'),
  ('max_weekly_hours', 'fn_contract_compliance, fn_validate_schedule'),
  ('meal_voucher_employee_min_share', 'fn_meal_voucher_check'),
  ('meal_voucher_max_face_value', 'fn_meal_voucher_check'),
  ('min_daily_rest_hours', 'fn_validate_schedule'),
  ('min_weekly_rest_hours', 'fn_validate_schedule'),
  ('minor_max_daily_hours', 'fn_contract_compliance, fn_validate_schedule'),
  ('minor_night_work_end', 'fn_contract_compliance, fn_validate_schedule'),
  ('minor_night_work_start', 'fn_contract_compliance, fn_validate_schedule'),
  ('mutuality_class_rates', 'fn_company_rates'),
  ('mutuality_class_thresholds', 'fn_company_absenteeism'),
  ('mutuality_refund_pct', 'fn_sick_counters'),
  ('normal_weekly_hours', 'fn_contract_compliance, fn_leave_balance, fn_min_salary, fn_reference_period_status, fn_sync_part_time, fn_validate_schedule'),
  ('notice_dismissal_months', 'fn_notice_period'),
  ('notice_resignation_ratio', 'fn_notice_period'),
  ('notice_start_day', 'fn_notice_period'),
  ('overtime_money_pct', 'fn_check_cba_not_worse'),
  ('participative_premium_company_cap_pct', 'fn_premium_caps'),
  ('participative_premium_exempt_pct', 'fn_premium_caps, fn_premium_check'),
  ('participative_premium_individual_cap_pct', 'fn_premium_caps'),
  ('pregnancy_protection_weeks_after_birth', 'fn_dismissal_protections'),
  ('prior_interview_threshold', 'fn_headcount_obligations'),
  ('probation_alert_days_1', 'fn_compliance_scan'),
  ('probation_alert_days_2', 'fn_compliance_scan'),
  ('probation_extension_max_days', 'fn_probation'),
  ('probation_notice_days_per_month', 'fn_probation'),
  ('probation_notice_days_per_week', 'fn_probation'),
  ('probation_notice_max_days', 'fn_probation'),
  ('probation_notice_min_days', 'fn_probation'),
  ('proportional_vote_threshold', 'fn_headcount_obligations'),
  ('qualification_experience_years', 'fn_is_qualified'),
  ('released_delegate_threshold', 'fn_headcount_obligations'),
  ('saint_nicolas_age_max', 'fn_employee_children'),
  ('sick_certificate_deadline_days', 'fn_sick_counters'),
  ('sick_continuation_days', 'fn_sick_counters'),
  ('sick_excessive_days_threshold', 'fn_compliance_scan'),
  ('sick_excessive_window_months', 'fn_compliance_scan'),
  ('sick_reference_months', 'fn_sick_counters'),
  ('ssm_age_scale', 'fn_min_salary'),
  ('sunday_surcharge_pct', 'fn_check_cba_not_worse, fn_validate_schedule'),
  ('vigilance_horizon_days', 'fn_compliance_scan')
on conflict (param_key) do update set read_by = excluded.read_by;

-- ===========================================================================
-- 2. fn_referential_gaps voit désormais les clés absentes
-- ===========================================================================
-- L'ancienne version groupait `legal_parameters` : une clé sans aucune version
-- n'y apparaissait pas, faute de ligne à grouper. La nouvelle part de la liste
-- des clés attendues et joint le référentiel — une clé jamais chargée sort donc
-- avec zéro version, en tête de liste.

drop function if exists fn_referential_gaps(date);

create or replace function fn_referential_gaps(p_since date default date '2019-12-31')
returns table (
  family param_family,
  param_key text,
  label text,
  earliest_covered date,
  latest_covered date,
  versions int,
  covers_since boolean,
  gap_days int,
  read_by text
) language sql stable set search_path = public as $$
  select lp.family,
         coalesce(ep.param_key, lp.param_key)              as param_key,
         min(lp.label)                                     as label,
         min(lp.valid_from)                                as earliest_covered,
         max(coalesce(lp.valid_to, date '9999-12-31'))     as latest_covered,
         count(lp.id)::int                                 as versions,
         coalesce(min(lp.valid_from) <= p_since, false)    as covers_since,
         case when count(lp.id) = 0 then null
              else greatest(0, (min(lp.valid_from) - p_since))::int end as gap_days,
         min(ep.read_by)                                   as read_by
  from expected_parameters ep
  full outer join legal_parameters lp on lp.param_key = ep.param_key
  group by lp.family, coalesce(ep.param_key, lp.param_key)
  order by count(lp.id) = 0 desc,                 -- les clés absentes d'abord
           coalesce(min(lp.valid_from) <= p_since, false),
           lp.family, 2;
$$;

comment on function fn_referential_gaps(date) is
  'Trous du référentiel. Une clé attendue par le moteur mais jamais chargée sort avec versions = 0, en tête. Une clé chargée dont read_by est nul est soit lue autrement qu''par fn_param, soit devenue inutile.';

revoke execute on function fn_referential_gaps(date) from anon, public;
grant  execute on function fn_referential_gaps(date) to authenticated;

-- ===========================================================================
-- 3. fn_company_rates ne se rabat plus en silence
-- ===========================================================================
-- Ligne d'origine, migration 23 :
--     accident_rate := coalesce(accident_rate, accident_base) * rp.accident_factor;
--
-- `accident_class_rates` n'est chargée nulle part dans le référentiel. Le taux de
-- classe restait donc toujours nul, la fonction retombait sur le taux de base, et
-- renvoyait `found: true` — l'appelant croyait lire le taux de la classe de risque
-- de la société alors qu'il lisait le taux générique. C'est exactement ce que la
-- règle 5 du CLAUDE.md interdit : une erreur silencieuse.
--
-- La fonction dit désormais quelle source a servi et ce qui manque. Elle n'invente
-- aucune valeur : le repli demeure, mais il est nommé et daté.

create or replace function fn_company_rates(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  rp            company_rate_periods%rowtype;
  mut_rates     jsonb;
  mut_rate      numeric;
  class_rates   jsonb;
  accident_rate numeric;
  accident_base numeric;
  source_taux   text;
  manques       text[] := '{}';
begin
  if not has_company_access(p_company) then
    raise exception 'Accès refusé à cette société.';
  end if;

  select * into rp
  from company_rate_periods
  where company_id = p_company
    and valid_from <= p_on
    and (valid_to is null or valid_to > p_on)
  order by valid_from desc
  limit 1;

  if rp.id is null then
    return jsonb_build_object(
      'found', false,
      'evaluated_on', p_on,
      'message', 'Aucun taux n''est enregistré pour cette société à cette date. '
                 'Renseignez la classe de mutualité et le facteur accident avant tout calcul.');
  end if;

  mut_rates := (fn_param('mutuality_class_rates', p_on)).value_json;
  if mut_rates is null then
    manques := manques || 'mutuality_class_rates';
  else
    select (e->>'rate')::numeric into mut_rate
    from jsonb_array_elements(mut_rates) e
    where (e->>'class')::int = rp.mutuality_class;
    if mut_rate is null then
      manques := manques || format('mutuality_class_rates[classe %s]', rp.mutuality_class);
    end if;
  end if;

  accident_base := fn_param_num('ccss_accident_base_employer', p_on);
  if accident_base is null then
    manques := manques || 'ccss_accident_base_employer';
  end if;

  class_rates := (fn_param('accident_class_rates', p_on)).value_json;
  if class_rates is null then
    manques     := manques || 'accident_class_rates';
    source_taux := 'base';
  elsif rp.accident_risk_class is null then
    source_taux := 'base';
  else
    select (e->>'rate')::numeric into accident_rate
    from jsonb_array_elements(class_rates) e
    where e->>'class' = rp.accident_risk_class;
    if accident_rate is null then
      manques     := manques || format('accident_class_rates[classe %s]', rp.accident_risk_class);
      source_taux := 'base';
    else
      source_taux := 'classe';
    end if;
  end if;

  accident_rate := coalesce(accident_rate, accident_base);
  if accident_rate is not null then
    accident_rate := accident_rate * rp.accident_factor;
  end if;

  return jsonb_build_object(
    'found', true,
    'evaluated_on', p_on,
    'period_from', rp.valid_from,
    'period_to', rp.valid_to,
    'activity_class', rp.activity_class,
    'accident_risk_class', rp.accident_risk_class,
    'accident_factor', rp.accident_factor,
    'mutuality_class', rp.mutuality_class,
    'mutuality_rate', mut_rate,
    'accident_rate', accident_rate,
    -- Ce que l'ancienne version taisait :
    'accident_rate_source', source_taux,
    'complete', (manques = '{}'::text[]) and accident_rate is not null and mut_rate is not null,
    'missing_parameters', to_jsonb(manques),
    'message', case
      when manques = '{}'::text[] then null
      when source_taux = 'base' then
        'Le taux de la classe de risque accident n''est pas disponible : le taux de base '
        'a été utilisé à sa place. Ce résultat ne doit pas servir de base à une déclaration. '
        'Paramètres manquants : ' || array_to_string(manques, ', ') || '.'
      else 'Paramètres manquants : ' || array_to_string(manques, ', ') || '.'
    end);
end $$;

revoke execute on function fn_company_rates(uuid, date) from anon, public;
grant  execute on function fn_company_rates(uuid, date) to authenticated;

-- ===========================================================================
-- 4. Les seuils légaux quittent le schéma
-- ===========================================================================
-- Trois contraintes `check` inscrivaient une valeur de loi. Elles sont exactes
-- aujourd'hui — et c'est justement ce que la règle 1 refuse comme justification :
-- une contrainte est figée dans le schéma, une loi ne l'est pas. Le plafond de la
-- période de référence vit déjà dans le référentiel sous la clé
-- `max_reference_period_months`, que `fn_validate_schedule` lit. Il n'a rien à
-- faire ici en double, où il contredirait le référentiel le jour d'une réforme.

alter table companies drop constraint if exists companies_reference_period_months_check;
alter table companies
  add constraint companies_reference_period_positive check (reference_period_months >= 1);

alter table reference_periods drop constraint if exists reference_periods_months_check;
alter table reference_periods
  add constraint reference_periods_months_positive check (months >= 1);

alter table company_rate_periods drop constraint if exists company_rate_periods_mutuality_class_check;
alter table company_rate_periods
  add constraint company_rate_periods_mutuality_class_positive check (mutuality_class >= 1);

comment on constraint companies_reference_period_positive on companies is
  'Borne structurelle seulement. Le plafond légal vit dans legal_parameters sous max_reference_period_months, et le moteur le contrôle.';
comment on constraint company_rate_periods_mutuality_class_positive on company_rate_periods is
  'Borne structurelle seulement. Le nombre de classes de mutualité vit dans legal_parameters sous mutuality_class_rates.';
