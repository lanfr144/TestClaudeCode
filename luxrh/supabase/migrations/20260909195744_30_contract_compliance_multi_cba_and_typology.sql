
-- =========================================================================
--  Conformité du contrat : conventions multiples, typologie, mineurs.
-- =========================================================================
create or replace function fn_contract_compliance(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c record; sal jsonb; leave_rule jsonb; prob jsonb; cbas jsonb;
        checks jsonb := '[]'::jsonb; mandatory jsonb := '[]'::jsonb;
        max_months numeric; max_renew numeric; cumulative_months numeric;
        age numeric; normal_weekly numeric;
begin
  select ct.*, e.birth_date, e.sex into c
  from contracts ct join employees e on e.id = ct.employee_id
  where ct.id = p_contract;
  if not found then raise exception 'Contrat introuvable'; end if;
  if not has_company_access(c.company_id) then raise exception 'Accès refusé'; end if;

  sal        := fn_min_salary(p_contract, p_on);
  leave_rule := fn_annual_leave_rule(p_contract, p_on);
  prob       := fn_probation(p_contract, p_on);
  age        := fn_employee_age(c.employee_id, p_on);
  normal_weekly := fn_param_num('normal_weekly_hours', p_on);

  select coalesce(jsonb_agg(jsonb_build_object(
           'name', name, 'code', code, 'scope', scope, 'origin', origin)), '[]'::jsonb)
    into cbas from fn_applicable_cbas(p_contract, p_on);

  -- ---- salaire minimum, âge et qualification compris ----
  checks := checks || jsonb_build_object(
    'code','salary_ssm',
    'label','Salaire ≥ salaire social minimum',
    'severity', case when c.monthly_gross >= (sal->>'ssm')::numeric then 'ok' else 'blocking' end,
    'detail', to_char((sal->>'contract_gross')::numeric,'FM999G999D00') || ' € vs '
              || to_char((sal->>'ssm')::numeric,'FM999G999D00') || ' € — SSM '
              || case when (sal->>'is_qualified')::boolean then 'qualifié' else 'non qualifié' end
              || ', ' || (sal->>'age_band')
              || case when (sal->>'age_ratio')::numeric < 1
                      then ' (' || fn_fmt((sal->>'age_ratio')::numeric * 100) || ' % du barème)' else '' end
              || ', indice ' || coalesce(sal->>'ssm_index','—'),
    'legal_ref', sal->>'ssm_ref');

  -- La qualification acquise par l'ancienneté mérite d'être signalée : elle
  -- relève le plancher salarial sans que rien n'ait été saisi.
  if (sal#>>'{qualification,qualified}')::boolean and c.qualification = 'unqualified' then
    checks := checks || jsonb_build_object(
      'code','qualification_by_seniority',
      'label','Qualification acquise par l''ancienneté',
      'severity','warning',
      'detail', (sal#>>'{qualification,source}') || '. Le salaire social minimum qualifié s''applique.',
      'legal_ref', sal#>>'{qualification,legal_ref}');
  end if;

  -- ---- grilles conventionnelles ----
  if sal->>'cba_grid' is not null then
    checks := checks || jsonb_build_object(
      'code','salary_cba',
      'label','Salaire ≥ grille conventionnelle',
      'severity', case when c.monthly_gross >= (sal->>'cba_grid')::numeric then 'ok' else 'blocking' end,
      'detail', coalesce(sal->>'cba_name','CCT') || ' · catégorie ' || coalesce(sal->>'cba_category','—')
                || ' : ' || to_char((sal->>'cba_grid')::numeric,'FM999G999D00') || ' €'
                || case when jsonb_array_length(sal->'cba_grids_considered') > 1
                        then ' (la plus favorable de ' || jsonb_array_length(sal->'cba_grids_considered')
                             || ' grilles applicables)' else '' end,
      'legal_ref','grille conventionnelle');
  end if;

  -- ---- congé annuel ----
  checks := checks || jsonb_build_object(
    'code','annual_leave',
    'label','Congé annuel conforme',
    'severity', case when coalesce(c.annual_leave_days, 0) >= (leave_rule->>'retained_value')::numeric
                     then 'ok' else 'blocking' end,
    'detail', coalesce(c.annual_leave_days::text,'—') || ' j au contrat · minimum retenu '
              || (leave_rule->>'retained_value') || ' j (' || (leave_rule->>'retained_source') || ')',
    'legal_ref', leave_rule->>'retained_ref');

  -- ---- durée de travail ----
  checks := checks || jsonb_build_object(
    'code','weekly_hours',
    'label','Durée hebdomadaire dans les limites légales',
    'severity', case when c.weekly_hours <= fn_param_num('max_weekly_hours', p_on) then 'ok' else 'blocking' end,
    'detail', fn_fmt(c.weekly_hours) || ' h/semaine · maximum légal '
              || fn_fmt(fn_param_num('max_weekly_hours', p_on)) || ' h',
    'legal_ref', (fn_param('max_weekly_hours', p_on)).legal_ref);

  -- ---- temps partiel ----
  if c.is_part_time then
    checks := checks || jsonb_build_object(
      'code','part_time_distribution',
      'label','Temps partiel : répartition écrite obligatoire',
      'severity', case when c.work_distribution is not null then 'ok' else 'blocking' end,
      'detail', case when c.work_distribution is not null
                     then 'Répartition stipulée : ' || c.work_distribution
                     else 'Le contrat à temps partiel doit préciser la répartition de la durée de travail.' end
                || ' · ' || fn_fmt(c.weekly_hours) || ' h sur ' || fn_fmt(normal_weekly) || ' h',
      'legal_ref','art. L.123-1');
  end if;

  -- ---- période de référence ----
  checks := checks || jsonb_build_object(
    'code','reference_period',
    'label','Période de référence dans la limite légale',
    'severity', case when c.reference_period_months <= fn_param_num('max_reference_period_months', p_on)
                     then 'ok' else 'blocking' end,
    'detail', c.reference_period_months || ' mois · maximum '
              || fn_fmt(fn_param_num('max_reference_period_months', p_on)) || ' mois',
    'legal_ref', (fn_param('max_reference_period_months', p_on)).legal_ref);

  -- ---- salariés mineurs ----
  if age is not null and age < 18 then
    checks := checks || jsonb_build_object(
      'code','minor_daily_hours',
      'label','Durée journalière d''un salarié mineur',
      'severity', case when c.weekly_hours / nullif(c.days_per_week, 0)
                            <= fn_param_num('minor_max_daily_hours', p_on) then 'ok' else 'blocking' end,
      'detail', 'Salarié de ' || age || ' ans : maximum '
                || fn_fmt(fn_param_num('minor_max_daily_hours', p_on)) || ' h par jour.',
      'legal_ref', (fn_param('minor_max_daily_hours', p_on)).legal_ref);

    checks := checks || jsonb_build_object(
      'code','minor_night_work',
      'label','Travail de nuit interdit aux mineurs',
      'severity', case when c.night_work then 'blocking' else 'ok' end,
      'detail', 'Aucune occupation entre ' || fn_fmt(fn_param_num('minor_night_work_start', p_on))
                || ' h et ' || fn_fmt(fn_param_num('minor_night_work_end', p_on)) || ' h avant 18 ans.',
      'legal_ref', (fn_param('minor_night_work_start', p_on)).legal_ref);
  end if;

  -- ---- CDD : renouvellements et durée cumulée (le saisonnier y échappe) ----
  if c.kind = 'cdd' then
    max_months := fn_param_num('cdd_max_months', p_on);
    max_renew  := fn_param_num('cdd_max_renewals', p_on);
    cumulative_months := round(extract(epoch from age(c.end_date, c.start_date)) / (30.44 * 86400), 1);

    checks := checks || jsonb_build_object(
      'code','cdd_renewals','label','Renouvellements de CDD',
      'severity', case when c.renewal_count > max_renew then 'blocking'
                       when c.renewal_count = max_renew then 'warning' else 'ok' end,
      'detail', c.renewal_count || ' renouvellement(s) sur ' || fn_fmt(max_renew)
                || ' · un renouvellement de plus entraîne la requalification en CDI',
      'legal_ref', (fn_param('cdd_max_renewals', p_on)).legal_ref);

    checks := checks || jsonb_build_object(
      'code','cdd_duration','label','Durée cumulée du CDD',
      'severity', case when cumulative_months > max_months then 'blocking'
                       when cumulative_months > max_months * 0.8 then 'warning' else 'ok' end,
      'detail', fn_fmt(cumulative_months) || ' mois cumulés sur ' || fn_fmt(max_months) || ' maximum',
      'legal_ref', (fn_param('cdd_max_months', p_on)).legal_ref);

  elsif c.kind = 'seasonal' then
    checks := checks || jsonb_build_object(
      'code','seasonal_scope','label','Contrat saisonnier',
      'severity', case when c.season_label is not null then 'ok' else 'warning' end,
      'detail', coalesce('Saison : ' || c.season_label,
                'Préciser la saison couverte. Le contrat saisonnier échappe aux limites de '
                || 'renouvellement du CDD ordinaire, mais son motif doit rester saisonnier.'),
      'legal_ref','art. L.122-1');

  elsif c.kind = 'apprenticeship' then
    checks := checks || jsonb_build_object(
      'code','apprenticeship','label','Contrat d''apprentissage',
      'severity', case when c.apprenticeship_level is not null and c.apprenticeship_year is not null
                       then 'ok' else 'warning' end,
      'detail', 'Niveau ' || coalesce(c.apprenticeship_level,'non précisé')
                || ', année ' || coalesce(c.apprenticeship_year::text,'non précisée')
                || '. L''indemnité d''apprentissage suit un barème propre, distinct du SSM.',
      'legal_ref','art. L.111-1');

  elsif c.kind = 'interim' then
    checks := checks || jsonb_build_object(
      'code','interim_mission','label','Contrat de mission',
      'severity', case when c.user_company_name is not null and c.mission_reason is not null
                       then 'ok' else 'blocking' end,
      'detail', 'Entreprise utilisatrice : ' || coalesce(c.user_company_name,'non renseignée')
                || ' · motif : ' || coalesce(c.mission_reason,'non renseigné'),
      'legal_ref','art. L.131-1');
  end if;

  -- ---- convention collective applicable ----
  checks := checks || jsonb_build_object(
    'code','cba_coverage','label','Conventions collectives applicables',
    'severity', case when jsonb_array_length(cbas) = 0 then 'info' else 'ok' end,
    'detail', case when jsonb_array_length(cbas) = 0
                   then 'Aucune convention applicable : seul le Code du travail régit ce contrat.'
                   else (select string_agg((x->>'name') || ' (' || (x->>'origin') || ')', ' · ')
                         from jsonb_array_elements(cbas) x) end,
    'legal_ref', null);

  -- ---- clauses ----
  if c.non_compete_clause then
    checks := checks || jsonb_build_object(
      'code','non_compete','label','Clause de non-concurrence à vérifier','severity','warning',
      'detail','Non bloquant. Elle doit être limitée dans le temps, dans l''espace et quant à l''activité visée.',
      'legal_ref','art. L.125-8');
  end if;
  if c.exclusivity_clause then
    checks := checks || jsonb_build_object(
      'code','exclusivity','label','Clause d''exclusivité à vérifier','severity','warning',
      'detail','Non bloquant. Vérifier sa proportionnalité au regard de la fonction.','legal_ref',null);
  end if;

  mandatory := jsonb_build_array(
    jsonb_build_object('label','Identité des parties', 'ok', c.employee_id is not null),
    jsonb_build_object('label','Date de début et lieu de travail', 'ok', c.start_date is not null and c.work_place is not null),
    jsonb_build_object('label','Nature de l''emploi et description', 'ok', c.job_title is not null and c.job_description is not null),
    jsonb_build_object('label','Durée de travail et horaire', 'ok', c.weekly_hours is not null and c.work_distribution is not null),
    jsonb_build_object('label','Rémunération et accessoires', 'ok', c.monthly_gross is not null),
    jsonb_build_object('label','Période d''essai', 'ok', c.probation_length is not null),
    jsonb_build_object('label','Congé et préavis', 'ok', c.annual_leave_days is not null),
    jsonb_build_object('label','Convention collective applicable', 'ok', jsonb_array_length(cbas) > 0),
    jsonb_build_object('label','Terme du contrat', 'ok',
      c.kind not in ('cdd','seasonal','interim','apprenticeship') or c.end_date is not null),
    jsonb_build_object('label','Motif de recours (CDD)', 'ok', c.kind <> 'cdd' or c.cdd_reason is not null),
    jsonb_build_object('label','Entreprise utilisatrice (mission)', 'ok',
      c.kind <> 'interim' or c.user_company_name is not null)
  );

  return jsonb_build_object(
    'contract_id', p_contract, 'evaluated_on', p_on,
    'kind', c.kind, 'is_part_time', c.is_part_time,
    'checks', checks, 'mandatory_mentions', mandatory,
    'salary', sal, 'annual_leave', leave_rule, 'probation', prob,
    'collective_agreements', cbas,
    'blocking_count', (select count(*) from jsonb_array_elements(checks) x where x->>'severity' = 'blocking'),
    'warning_count',  (select count(*) from jsonb_array_elements(checks) x where x->>'severity' = 'warning'),
    'can_validate', not exists (select 1 from jsonb_array_elements(checks) x where x->>'severity' = 'blocking'));
end $$;

-- Le solde de congés lit désormais l'arbitrage plutôt qu'une CCT unique.
create or replace function fn_leave_balance(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; c contracts; rule jsonb; entitlement numeric; prorata numeric;
        year_start date; accrual_start date; months numeric; frac_days int;
        accrued numeric; taken numeric; lines jsonb := '[]'::jsonb;
        normal_weekly numeric; per_month numeric;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé';
  end if;

  select ct.* into c from contracts ct
  where ct.employee_id = p_employee and ct.status = 'active'
  order by ct.start_date desc limit 1;
  if c.id is null then
    return jsonb_build_object('balance', 0, 'lines', lines, 'no_contract', true);
  end if;

  rule := fn_annual_leave_rule(c.id, p_on);
  entitlement := (rule->>'retained_value')::numeric;
  normal_weekly := fn_param_num('normal_weekly_hours', p_on);
  prorata := least(1.0, c.weekly_hours / nullif(normal_weekly, 0));

  year_start := date_trunc('year', p_on)::date;
  accrual_start := greatest(year_start, c.start_date);

  frac_days := fn_param_num('leave_month_fraction_days', p_on)::int;
  months := (extract(year from age(p_on, accrual_start)) * 12
             + extract(month from age(p_on, accrual_start)));
  if extract(day from age(p_on, accrual_start)) > frac_days then months := months + 1; end if;
  months := least(12, greatest(0, months));

  per_month := round(entitlement / 12.0, 4);
  accrued := round(per_month * months * prorata, 2);

  select coalesce(sum(a.days_count), 0) into taken
  from absences a join absence_types t on t.id = a.absence_type_id
  where a.employee_id = p_employee and a.status = 'approved'
    and t.counts_against_leave
    and a.start_date >= year_start and a.start_date <= p_on;

  lines := lines
    || jsonb_build_object(
         'label','Acquisition 1/12e × ' || fn_fmt(months) || ' mois — ' || fn_fmt(entitlement)
                 || ' j/an (' || (rule->>'retained_source') || ')',
         'value', accrued, 'sign','+')
    || case when prorata < 1 then jsonb_build_array(jsonb_build_object(
         'label','Prorata temps partiel (' || fn_fmt(c.weekly_hours) || ' h / '
                 || fn_fmt(normal_weekly) || ' h)',
         'value', round(per_month * months * (1 - prorata), 2), 'sign','-')) else '[]'::jsonb end
    || jsonb_build_object('label','Congés pris sur l''année', 'value', taken, 'sign','-')
    || jsonb_build_object('label','Solde disponible', 'value', round(accrued - taken, 2), 'sign','=');

  return jsonb_build_object(
    'employee_id', p_employee, 'evaluated_on', p_on,
    'entitlement_days', entitlement,
    'entitlement_source', rule->>'retained_source',
    'arbitration', rule,
    'accrued', accrued, 'taken', taken,
    'balance', round(accrued - taken, 2),
    'months_counted', months, 'prorata', round(prorata, 4),
    'lines', lines,
    'legal_ref', (fn_param('leave_accrual_per_month', p_on)).legal_ref);
end $$;
