
-- =========================================================================
--  MOTEUR DE RÈGLES — hiérarchie des normes et cycle de vie du contrat
--  Aucun seuil, taux ou durée n'est écrit ici : tout est lu dans
--  legal_parameters à la date du calcul.
-- =========================================================================

-- ---------- 1. Arbitrage loi / CCT / contrat ----------
-- Retient toujours la disposition la plus favorable au salarié et dit laquelle a gagné.
create or replace function fn_arbitrate(
  p_label text,
  p_law numeric, p_law_ref text,
  p_cba numeric, p_cba_ref text,
  p_contract numeric,
  p_higher_is_better boolean default true
) returns jsonb language plpgsql immutable as $$
declare best numeric; src text; ref text;
begin
  best := p_law; src := 'Code du travail'; ref := p_law_ref;

  if p_cba is not null and (
       (p_higher_is_better and p_cba > coalesce(best, -1e12))
    or (not p_higher_is_better and p_cba < coalesce(best, 1e12))) then
    best := p_cba; src := 'CCT'; ref := p_cba_ref;
  end if;

  if p_contract is not null and (
       (p_higher_is_better and p_contract > coalesce(best, -1e12))
    or (not p_higher_is_better and p_contract < coalesce(best, 1e12))) then
    best := p_contract; src := 'Contrat individuel'; ref := 'clause contractuelle';
  end if;

  return jsonb_build_object(
    'label', p_label,
    'law_value', p_law, 'law_ref', p_law_ref,
    'cba_value', p_cba, 'cba_ref', p_cba_ref,
    'contract_value', p_contract,
    'retained_value', best, 'retained_source', src, 'retained_ref', ref
  );
end $$;

-- ---------- 2. Salaire minimum applicable ----------
create or replace function fn_min_salary(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; p legal_parameters; ssm numeric; ssm_ref text; ssm_idx numeric;
        grid numeric; grid_cat text; normal_weekly numeric; prorata numeric;
        seniority numeric;
begin
  select ct.*, e.qualification, co.collective_agreement_id
    into c
  from contracts ct
  join employees e on e.id = ct.employee_id
  join companies co on co.id = ct.company_id
  where ct.id = p_contract;
  if not found then return null; end if;

  p := fn_param(case when c.qualification = 'qualified'
                     then 'ssm_monthly_qualified' else 'ssm_monthly_unqualified' end, p_on);
  ssm := p.value_num; ssm_ref := p.legal_ref; ssm_idx := p.index_ref;

  normal_weekly := fn_param_num('normal_weekly_hours', p_on);
  prorata := least(1.0, c.weekly_hours / nullif(normal_weekly, 0));

  seniority := extract(epoch from (age(p_on, c.start_date))) / (365.25 * 86400);
  select g.monthly_amount, g.category into grid, grid_cat
  from cba_salary_grids g
  where g.collective_agreement_id = c.collective_agreement_id
    and (c.category is null or g.category = c.category)
    and seniority >= g.seniority_from_years
    and (g.seniority_to_years is null or seniority < g.seniority_to_years)
  order by g.monthly_amount desc
  limit 1;

  return jsonb_build_object(
    'ssm', round(ssm * prorata, 2),
    'ssm_full', ssm,
    'ssm_ref', ssm_ref,
    'ssm_index', ssm_idx,
    'qualification', c.qualification,
    'prorata', round(prorata, 4),
    'cba_grid', case when grid is null then null else round(grid * prorata, 2) end,
    'cba_category', grid_cat,
    'floor', greatest(round(ssm * prorata, 2), coalesce(round(grid * prorata, 2), 0)),
    'contract_gross', c.monthly_gross
  );
end $$;

-- ---------- 3. Congé annuel retenu (arbitrage) ----------
create or replace function fn_annual_leave_rule(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; law numeric; law_ref text; cba numeric; cba_days jsonb;
begin
  select ct.annual_leave_days, ct.company_id, co.collective_agreement_id, ca.name as cba_name
    into c
  from contracts ct
  join companies co on co.id = ct.company_id
  left join collective_agreements ca on ca.id = co.collective_agreement_id
  where ct.id = p_contract;
  if not found then return null; end if;

  law := fn_param_num('annual_leave_min_days', p_on);
  law_ref := (fn_param('annual_leave_min_days', p_on)).legal_ref;
  cba_days := fn_cba_value(c.collective_agreement_id, 'leave', 'annual_days');
  cba := case when cba_days is null then null else (cba_days #>> '{}')::numeric end;

  return fn_arbitrate('Congé annuel', law, law_ref, cba,
                      coalesce(c.cba_name, 'CCT'), c.annual_leave_days, true);
end $$;

-- ---------- 4. Période d'essai ----------
-- Fin d'essai, préavis d'essai et DERNIER JOUR UTILE POUR NOTIFIER.
create or replace function fn_probation(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; base_end date; ext_days int; ext_cap int; final_end date;
        notice_days int; last_notify date; ref text;
begin
  select * into c from contracts where id = p_contract;
  if not found or c.probation_length is null then return null; end if;

  base_end := case
    when c.probation_unit = 'months' then (c.start_date + (c.probation_length || ' months')::interval)::date - 1
    else (c.start_date + (c.probation_length * 7))::date - 1
  end;

  ext_cap := coalesce(fn_param_num('probation_extension_max_days', p_on)::int, 30);
  select least(coalesce(sum(days_added), 0), ext_cap) into ext_days
  from probation_extensions where contract_id = p_contract;
  final_end := base_end + coalesce(ext_days, 0);

  if c.probation_unit = 'months' then
    notice_days := greatest(
      fn_param_num('probation_notice_min_days', p_on)::int,
      least(fn_param_num('probation_notice_max_days', p_on)::int,
            (fn_param_num('probation_notice_days_per_month', p_on) * c.probation_length)::int));
    ref := (fn_param('probation_notice_days_per_month', p_on)).legal_ref;
  else
    notice_days := (fn_param_num('probation_notice_days_per_week', p_on) * c.probation_length)::int;
    ref := (fn_param('probation_notice_days_per_week', p_on)).legal_ref;
  end if;

  -- Le préavis doit expirer au plus tard le dernier jour de l'essai.
  last_notify := final_end - notice_days;

  return jsonb_build_object(
    'start', c.start_date,
    'base_end', base_end,
    'extension_days', coalesce(ext_days, 0),
    'extension_cap_days', ext_cap,
    'end', final_end,
    'notice_days', notice_days,
    'last_day_to_notify', last_notify,
    'days_until_deadline', last_notify - p_on,
    'is_running', p_on <= final_end,
    'legal_ref', ref
  );
end $$;

-- ---------- 5. Préavis et indemnité de départ ----------
create or replace function fn_notice_period(p_contract uuid, p_notified_on date, p_by_employer boolean)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; seniority numeric; scale jsonb; months numeric := null;
        item jsonb; start_day int; notice_start date; notice_end date; ref text;
begin
  select * into c from contracts where id = p_contract;
  if not found then return null; end if;

  seniority := extract(epoch from age(p_notified_on, c.start_date)) / (365.25 * 86400);
  scale := (fn_param('notice_dismissal_months', p_notified_on)).value_json;
  ref := (fn_param('notice_dismissal_months', p_notified_on)).legal_ref;

  for item in select * from jsonb_array_elements(scale) loop
    if seniority >= (item->>'from_years')::numeric
       and (item->>'to_years' is null or seniority < (item->>'to_years')::numeric) then
      months := (item->>'months')::numeric;
    end if;
  end loop;

  if not p_by_employer then
    months := months * fn_param_num('notice_resignation_ratio', p_notified_on);
  end if;

  -- Point de départ : le 15 du mois si notifié avant le 15, le 1er du mois suivant sinon.
  start_day := fn_param_num('notice_start_day', p_notified_on)::int;
  notice_start := case
    when extract(day from p_notified_on) < start_day
      then date_trunc('month', p_notified_on)::date + (start_day - 1)
    else (date_trunc('month', p_notified_on) + interval '1 month')::date
  end;
  notice_end := (notice_start + (months || ' months')::interval)::date - 1;

  return jsonb_build_object(
    'seniority_years', round(seniority, 2),
    'notice_months', months,
    'notified_on', p_notified_on,
    'notice_start', notice_start,
    'notice_end', notice_end,
    'by_employer', p_by_employer,
    'legal_ref', ref
  );
end $$;

-- ---------- 6. Conformité d'un contrat ----------
create or replace function fn_contract_compliance(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c record; sal jsonb; leave_rule jsonb; prob jsonb;
        checks jsonb := '[]'::jsonb; mandatory jsonb := '[]'::jsonb;
        max_months numeric; max_renew numeric; cumulative_months numeric;
begin
  select ct.*, co.collective_agreement_id into c
  from contracts ct join companies co on co.id = ct.company_id where ct.id = p_contract;
  if not found then raise exception 'Contrat introuvable'; end if;
  if not has_company_access(c.company_id) then raise exception 'Accès refusé'; end if;

  sal := fn_min_salary(p_contract, p_on);
  leave_rule := fn_annual_leave_rule(p_contract, p_on);
  prob := fn_probation(p_contract, p_on);

  -- Salaire vs SSM
  checks := checks || jsonb_build_object(
    'code','salary_ssm',
    'label','Salaire ≥ salaire social minimum',
    'severity', case when c.monthly_gross >= (sal->>'ssm')::numeric then 'ok' else 'blocking' end,
    'detail', to_char((sal->>'contract_gross')::numeric,'FM999G999D00') || ' € vs ' ||
              to_char((sal->>'ssm')::numeric,'FM999G999D00') || ' € · indice ' ||
              coalesce((sal->>'ssm_index'), '—'),
    'legal_ref', sal->>'ssm_ref');

  -- Salaire vs grille CCT
  if sal->>'cba_grid' is not null then
    checks := checks || jsonb_build_object(
      'code','salary_cba',
      'label','Salaire ≥ grille de la convention collective',
      'severity', case when c.monthly_gross >= (sal->>'cba_grid')::numeric then 'ok' else 'blocking' end,
      'detail','Catégorie ' || coalesce(sal->>'cba_category','—') || ' : ' ||
               to_char((sal->>'cba_grid')::numeric,'FM999G999D00') || ' €',
      'legal_ref','grille CCT');
  end if;

  -- Congé annuel
  checks := checks || jsonb_build_object(
    'code','annual_leave',
    'label','Congé annuel conforme',
    'severity', case when coalesce(c.annual_leave_days, 0) >= (leave_rule->>'retained_value')::numeric
                     then 'ok' else 'blocking' end,
    'detail', coalesce(c.annual_leave_days::text,'—') || ' j au contrat · minimum retenu ' ||
              (leave_rule->>'retained_value') || ' j (' || (leave_rule->>'retained_source') || ')',
    'legal_ref', leave_rule->>'retained_ref');

  -- Durée de travail
  checks := checks || jsonb_build_object(
    'code','weekly_hours',
    'label','Durée hebdomadaire dans les limites légales',
    'severity', case when c.weekly_hours <= fn_param_num('max_weekly_hours', p_on) then 'ok' else 'blocking' end,
    'detail', c.weekly_hours || ' h/semaine · maximum légal ' || fn_param_num('max_weekly_hours', p_on) || ' h',
    'legal_ref', (fn_param('max_weekly_hours', p_on)).legal_ref);

  -- Période de référence
  checks := checks || jsonb_build_object(
    'code','reference_period',
    'label','Période de référence dans la limite légale',
    'severity', case when c.reference_period_months <= fn_param_num('max_reference_period_months', p_on)
                     then 'ok' else 'blocking' end,
    'detail', c.reference_period_months || ' mois · maximum ' ||
              fn_param_num('max_reference_period_months', p_on) || ' mois',
    'legal_ref', (fn_param('max_reference_period_months', p_on)).legal_ref);

  -- CDD : renouvellements et durée cumulée
  if c.kind = 'cdd' then
    max_months := fn_param_num('cdd_max_months', p_on);
    max_renew  := fn_param_num('cdd_max_renewals', p_on);
    cumulative_months := round(extract(epoch from age(c.end_date, c.start_date)) / (30.44 * 86400), 1);

    checks := checks || jsonb_build_object(
      'code','cdd_renewals',
      'label','Renouvellements de CDD',
      'severity', case when c.renewal_count > max_renew then 'blocking'
                       when c.renewal_count = max_renew then 'warning' else 'ok' end,
      'detail', c.renewal_count || ' renouvellement(s) sur ' || max_renew ||
                ' · un renouvellement de plus entraîne la requalification en CDI',
      'legal_ref', (fn_param('cdd_max_renewals', p_on)).legal_ref);

    checks := checks || jsonb_build_object(
      'code','cdd_duration',
      'label','Durée cumulée du CDD',
      'severity', case when cumulative_months > max_months then 'blocking'
                       when cumulative_months > max_months * 0.8 then 'warning' else 'ok' end,
      'detail', cumulative_months || ' mois cumulés sur ' || max_months || ' maximum',
      'legal_ref', (fn_param('cdd_max_months', p_on)).legal_ref);
  end if;

  -- Clauses à vérifier — avertissements non bloquants
  if c.non_compete_clause then
    checks := checks || jsonb_build_object(
      'code','non_compete', 'label','Clause de non-concurrence à vérifier', 'severity','warning',
      'detail','Non bloquant. Elle doit être limitée dans le temps, dans l''espace et quant à l''activité visée.',
      'legal_ref','art. L.125-8');
  end if;
  if c.exclusivity_clause then
    checks := checks || jsonb_build_object(
      'code','exclusivity','label','Clause d''exclusivité à vérifier','severity','warning',
      'detail','Non bloquant. Vérifier sa proportionnalité au regard de la fonction.','legal_ref',null);
  end if;

  -- Mentions obligatoires du contrat
  mandatory := jsonb_build_array(
    jsonb_build_object('label','Identité des parties', 'ok', c.employee_id is not null),
    jsonb_build_object('label','Date de début et lieu de travail', 'ok', c.start_date is not null and c.work_place is not null),
    jsonb_build_object('label','Nature de l''emploi et description', 'ok', c.job_title is not null and c.job_description is not null),
    jsonb_build_object('label','Durée de travail et horaire', 'ok', c.weekly_hours is not null and c.work_distribution is not null),
    jsonb_build_object('label','Rémunération et accessoires', 'ok', c.monthly_gross is not null),
    jsonb_build_object('label','Période d''essai', 'ok', c.probation_length is not null),
    jsonb_build_object('label','Congé annuel', 'ok', c.annual_leave_days is not null),
    jsonb_build_object('label','Convention collective applicable', 'ok', c.collective_agreement_id is not null),
    jsonb_build_object('label','Motif de recours (CDD)', 'ok', c.kind <> 'cdd' or c.cdd_reason is not null)
  );

  return jsonb_build_object(
    'contract_id', p_contract,
    'evaluated_on', p_on,
    'checks', checks,
    'mandatory_mentions', mandatory,
    'salary', sal,
    'annual_leave', leave_rule,
    'probation', prob,
    'blocking_count', (select count(*) from jsonb_array_elements(checks) x where x->>'severity' = 'blocking'),
    'warning_count',  (select count(*) from jsonb_array_elements(checks) x where x->>'severity' = 'warning'),
    'can_validate', not exists (select 1 from jsonb_array_elements(checks) x where x->>'severity' = 'blocking')
  );
end $$;
