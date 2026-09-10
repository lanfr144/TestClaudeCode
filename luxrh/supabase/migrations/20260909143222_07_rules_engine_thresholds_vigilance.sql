
-- =========================================================================
--  MOTEUR DE RÈGLES — seuils d'effectif, licenciement collectif, vigilance
-- =========================================================================

-- ---------- Effectif sur les 12 mois de référence ----------
create or replace function fn_headcount(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare months int; m date; total numeric := 0; n int := 0; cnt int; detail jsonb := '[]'::jsonb;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;
  months := fn_param_num('delegation_reference_months', p_on)::int;

  for m in select generate_series(
      (date_trunc('month', p_on) - (months || ' months')::interval)::date,
      (date_trunc('month', p_on) - interval '1 month')::date,
      '1 month')::date
  loop
    select count(*) into cnt from contracts c
    where c.company_id = p_company and c.status = 'active'
      and c.start_date <= m and (c.end_date is null or c.end_date >= m);
    total := total + cnt; n := n + 1;
    detail := detail || jsonb_build_object('month', m, 'headcount', cnt);
  end loop;

  return jsonb_build_object(
    'company_id', p_company,
    'reference_months', months,
    'period_start', (date_trunc('month', p_on) - (months || ' months')::interval)::date,
    'period_end', (date_trunc('month', p_on) - interval '1 day')::date,
    'average', round(total / greatest(n,1), 2),
    'rounded', round(total / greatest(n,1))::int,
    'current', (select count(*) from contracts c
                where c.company_id = p_company and c.status = 'active'
                  and c.start_date <= p_on and (c.end_date is null or c.end_date >= p_on)),
    'monthly', detail,
    'legal_ref', (fn_param('delegation_threshold', p_on)).legal_ref);
end $$;

-- ---------- Obligations déclenchées par l'effectif ----------
create or replace function fn_headcount_obligations(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare hc jsonb; eff int; out_j jsonb := '[]'::jsonb; scale jsonb; item jsonb;
        delegation numeric; proportional numeric; interview numeric; released numeric;
        approach numeric; delegates jsonb := null;
begin
  hc := fn_headcount(p_company, p_on);
  eff := (hc->>'rounded')::int;

  delegation   := fn_param_num('delegation_threshold', p_on);
  proportional := fn_param_num('proportional_vote_threshold', p_on);
  interview    := fn_param_num('prior_interview_threshold', p_on);
  released     := fn_param_num('released_delegate_threshold', p_on);
  approach     := fn_param_num('delegation_approach_threshold', p_on);

  scale := (fn_param('delegation_delegates_scale', p_on)).value_json;
  for item in select * from jsonb_array_elements(scale) loop
    if eff >= (item->>'from')::int and (item->>'to' is null or eff <= (item->>'to')::int) then
      delegates := item;
    end if;
  end loop;

  out_j := out_j || jsonb_build_object(
    'threshold', delegation, 'label','Délégation du personnel',
    'reached', eff >= delegation,
    'gap', delegation - eff,
    'status', case when eff >= delegation then 'franchi'
                   when eff >= approach then 'à ' || (delegation - eff)::text || ' près'
                   else 'non atteint' end,
    'consequence','Mise en place obligatoire d''une délégation du personnel, élections tous les 5 ans. '
      || case when delegates is not null
              then (delegates->>'effective') || ' délégué(s) effectif(s) et ' ||
                   (delegates->>'substitute') || ' suppléant(s) pour la tranche ' ||
                   (delegates->>'from') || '-' || coalesce(delegates->>'to','+') || '.'
              else '' end
      || ' Défaut de mise en place sanctionné pénalement.',
    'legal_ref', (fn_param('delegation_threshold', p_on)).legal_ref);

  out_j := out_j || jsonb_build_object(
    'threshold', proportional, 'label','Scrutin proportionnel',
    'reached', eff >= proportional, 'gap', proportional - eff,
    'status', case when eff >= proportional then 'franchi' else 'non atteint' end,
    'consequence','Passage du scrutin majoritaire à la représentation proportionnelle.',
    'legal_ref', (fn_param('proportional_vote_threshold', p_on)).legal_ref);

  out_j := out_j || jsonb_build_object(
    'threshold', interview, 'label','Entretien préalable obligatoire',
    'reached', eff >= interview, 'gap', interview - eff,
    'status', case when eff >= interview then 'franchi' else 'non atteint' end,
    'consequence','Tout licenciement doit être précédé d''un entretien préalable.',
    'legal_ref', (fn_param('prior_interview_threshold', p_on)).legal_ref);

  out_j := out_j || jsonb_build_object(
    'threshold', released, 'label','Délégué libéré à temps plein',
    'reached', eff >= released, 'gap', released - eff,
    'status', case when eff >= released then 'franchi' else 'non atteint' end,
    'consequence','Un premier délégué est libéré à temps plein de ses obligations de service.',
    'legal_ref', (fn_param('released_delegate_threshold', p_on)).legal_ref);

  return jsonb_build_object(
    'headcount', hc, 'thresholds', out_j, 'delegates_due', delegates,
    'vote_mode', case when eff >= proportional then 'proportionnel' else 'majoritaire' end);
end $$;

-- ---------- Licenciement collectif : compteurs glissants 30 / 90 jours ----------
create or replace function fn_collective_dismissal_counters(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare t30 numeric; t90 numeric; c30 int; c90 int; oldest30 date; oldest90 date;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;
  t30 := fn_param_num('collective_dismissal_30d', p_on);
  t90 := fn_param_num('collective_dismissal_90d', p_on);

  select count(*), min(notified_on) into c30, oldest30 from contract_terminations
  where company_id = p_company and not is_personal_ground and notified_on > p_on - 30;

  select count(*), min(notified_on) into c90, oldest90 from contract_terminations
  where company_id = p_company and not is_personal_ground and notified_on > p_on - 90;

  return jsonb_build_object(
    'evaluated_on', p_on,
    'window_30', jsonb_build_object(
      'count', c30, 'threshold', t30, 'remaining', greatest(0, t30 - c30)::int,
      'releases_on', case when oldest30 is not null then oldest30 + 30 end),
    'window_90', jsonb_build_object(
      'count', c90, 'threshold', t90, 'remaining', greatest(0, t90 - c90)::int,
      'releases_on', case when oldest90 is not null then oldest90 + 90 end),
    'legal_ref', (fn_param('collective_dismissal_30d', p_on)).legal_ref);
end $$;

-- ---------- Simulation d'un scénario de licenciement ----------
create or replace function fn_simulate_collective_dismissal(
  p_company uuid, p_count int, p_date date, p_personal_ground boolean default false)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare ctr jsonb; c30 int; c90 int; t30 numeric; t90 numeric;
        triggers boolean; total30 int; total90 int; timeline jsonb := '[]'::jsonb;
        neg_days int; onc_days int; onc_seize int; first_notice date;
        alt_max int; alt_date date;
begin
  ctr := fn_collective_dismissal_counters(p_company, p_date);
  c30 := (ctr#>>'{window_30,count}')::int;  t30 := (ctr#>>'{window_30,threshold}')::numeric;
  c90 := (ctr#>>'{window_90,count}')::int;  t90 := (ctr#>>'{window_90,threshold}')::numeric;

  if p_personal_ground then
    return jsonb_build_object('triggers', false, 'counters', ctr,
      'verdict','Motif inhérent à la personne : ces licenciements n''entrent pas dans les compteurs du licenciement collectif.',
      'timeline', '[]'::jsonb);
  end if;

  total30 := c30 + p_count;
  total90 := c90 + p_count;
  triggers := total30 > t30 or total90 > t90;

  neg_days   := fn_param_num('collective_negotiation_days', p_date)::int;
  onc_seize  := fn_param_num('collective_onc_seizure_days', p_date)::int;
  onc_days   := fn_param_num('collective_onc_days', p_date)::int;

  if triggers then
    first_notice := p_date + neg_days + onc_seize + onc_days;
    timeline := jsonb_build_array(
      jsonb_build_object('when','J — ' || to_char(p_date,'DD.MM'),
        'title','Information écrite de la délégation du personnel et de l''ADEM',
        'detail','Motifs, nombre et catégories de salariés concernés, critères de sélection, calendrier.',
        'date', p_date),
      jsonb_build_object('when','J+1 → J+' || neg_days,
        'title','Négociation du plan social — ' || neg_days || ' jours',
        'detail','Mesures d''accompagnement, reclassement, indemnités. Accord ou constat de désaccord.',
        'date', p_date + neg_days),
      jsonb_build_object('when','J+' || neg_days || ' → J+' || (neg_days + onc_seize),
        'title','En cas de désaccord : saisine de l''ONC dans les ' || onc_seize || ' jours',
        'detail','Office national de conciliation. Le constat de désaccord doit être signé par les parties.',
        'date', p_date + neg_days + onc_seize),
      jsonb_build_object('when','J+' || (neg_days + onc_seize) || ' → J+' || (neg_days + onc_seize + onc_days),
        'title','Conciliation devant l''ONC — ' || onc_days || ' jours',
        'detail','Interdiction absolue de notifier pendant toute la durée de la procédure.',
        'date', first_notice),
      jsonb_build_object('when','≈ ' || to_char(first_notice,'DD.MM'),
        'title','Première date de notification possible',
        'detail','Sous réserve de la signature du plan social ou du procès-verbal de non-conciliation.',
        'date', first_notice));
  end if;

  alt_max := greatest(0, least(t30 - c30, t90 - c90))::int;
  alt_date := (ctr#>>'{window_30,releases_on}')::date;

  return jsonb_build_object(
    'triggers', triggers,
    'counters', ctr,
    'requested_count', p_count,
    'requested_date', p_date,
    'total_30', total30, 'total_90', total90,
    'verdict', case when triggers then
        'La procédure de licenciement collectif se déclenche : ' || c30 ||
        ' licenciement(s) déjà notifié(s) sur la fenêtre de 30 jours + ' || p_count ||
        ' envisagé(s) = ' || total30 || ', au-delà du seuil de ' || t30 ||
        '. Aucune notification ne peut intervenir avant l''issue de la procédure.'
      else
        'La procédure ne se déclenche pas : ' || total30 || ' licenciement(s) sur 30 jours (seuil ' ||
        t30 || ') et ' || total90 || ' sur 90 jours (seuil ' || t90 || ').' end,
    'alternatives', case when triggers then jsonb_build_array(
        jsonb_build_object('label','Notifier au maximum ' || alt_max || ' licenciement(s) le ' || to_char(p_date,'DD.MM')),
        jsonb_build_object('label', case when alt_date is not null
          then 'Ou reporter au ' || to_char(alt_date,'DD.MM.YYYY') || ' — le compteur de 30 jours se libère'
          else 'Ou étaler les notifications au-delà de la fenêtre de 30 jours' end))
      else '[]'::jsonb end,
    'timeline', timeline,
    'legal_refs', jsonb_build_array('art. L.166-1','art. L.166-2'),
    'disclaimer','LuxRH est un outil d''aide à la décision. Il ne se substitue pas à un conseil juridique. '
      || 'Vérifiez les délais applicables à votre situation avant toute démarche.');
end $$;

-- ---------- Tableau de bord de vigilance ----------
-- Recalcule toutes les obligations à la date demandée et les range en
-- « En retard » / « Dans les 30 jours » / « À surveiller ».
create or replace function fn_compliance_scan(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare items jsonb := '[]'::jsonb; r record; prob jsonb; sick jsonb; obl jsonb;
        horizon int; warn1 int; warn2 int; th jsonb; cnt jsonb;
        cdd_alert1 int; cdd_alert2 int; comp jsonb;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;
  horizon    := fn_param_num('vigilance_horizon_days', p_on)::int;
  warn1      := fn_param_num('probation_alert_days_1', p_on)::int;
  warn2      := fn_param_num('probation_alert_days_2', p_on)::int;
  cdd_alert1 := fn_param_num('cdd_alert_days_1', p_on)::int;
  cdd_alert2 := fn_param_num('cdd_alert_days_2', p_on)::int;

  -- 1. Essais en cours : dernier jour utile pour notifier une résiliation
  for r in
    select c.id, c.employee_id, e.first_name || ' ' || e.last_name as name
    from contracts c join employees e on e.id = c.employee_id
    where c.company_id = p_company and c.status = 'active' and c.probation_length is not null
  loop
    prob := fn_probation(r.id, p_on);
    if prob is not null and (prob->>'is_running')::boolean then
      items := items || jsonb_build_object(
        'rule_code','probation_deadline', 'employee_id', r.employee_id, 'employee_name', r.name,
        'contract_id', r.id,
        'title','Dernier jour pour notifier la rupture d''essai — ' || r.name,
        'detail','Essai jusqu''au ' || to_char((prob->>'end')::date,'DD.MM.YYYY')
          || case when (prob->>'extension_days')::int > 0
                  then ', prolongé de ' || (prob->>'extension_days') || ' jour(s) par une incapacité' else '' end
          || '. Préavis d''essai de ' || (prob->>'notice_days')
          || ' jours devant expirer au plus tard le dernier jour de l''essai.',
        'consequence','Passé cette date, le contrat devient définitif.',
        'due_date', (prob->>'last_day_to_notify')::date,
        'days_left', (prob->>'days_until_deadline')::int,
        'severity', case when (prob->>'days_until_deadline')::int < 0 then 'blocking'
                         when (prob->>'days_until_deadline')::int <= warn2 then 'blocking'
                         when (prob->>'days_until_deadline')::int <= warn1 then 'warning'
                         else 'info' end,
        'legal_ref', prob->>'legal_ref', 'category','contract');
    end if;
  end loop;

  -- 2. CDD arrivant à terme
  for r in
    select c.*, e.first_name || ' ' || e.last_name as name
    from contracts c join employees e on e.id = c.employee_id
    where c.company_id = p_company and c.status = 'active' and c.kind = 'cdd' and c.end_date is not null
  loop
    comp := null;
    items := items || jsonb_build_object(
      'rule_code','cdd_term', 'employee_id', r.employee_id, 'employee_name', r.name,
      'contract_id', r.id,
      'title','CDD arrivant à terme — ' || r.name,
      'detail', r.renewal_count || ' renouvellement(s) consommé(s), '
        || round(extract(epoch from age(r.end_date, r.start_date)) / (30.44*86400), 0)
        || ' mois cumulés sur ' || fn_param_num('cdd_max_months', p_on) || ' maximum. Délai de carence de '
        || round(extract(epoch from age(r.end_date, r.start_date)) / (30.44*86400)
                 * fn_param_num('cdd_carence_ratio', p_on), 0)
        || ' mois avant un nouveau CDD sur le même poste.',
      'consequence','Un renouvellement au-delà de la limite entraîne la requalification en CDI.',
      'due_date', r.end_date, 'days_left', r.end_date - p_on,
      'severity', case when r.end_date - p_on <= cdd_alert2 then 'blocking'
                       when r.end_date - p_on <= cdd_alert1 then 'warning' else 'info' end,
      'legal_ref', (fn_param('cdd_max_renewals', p_on)).legal_ref, 'category','contract');
  end loop;

  -- 3. Certificats médicaux manquants et fin de continuation de salaire
  for r in
    select e.id, e.first_name || ' ' || e.last_name as name from employees e
    where e.company_id = p_company
  loop
    sick := fn_sick_counters(r.id, p_on);
    if jsonb_array_length(sick->'missing_certificates') > 0 then
      items := items || jsonb_build_object(
        'rule_code','missing_certificate', 'employee_id', r.id, 'employee_name', r.name,
        'title','Certificat médical manquant — ' || r.name,
        'detail','L''absence débutée le '
          || to_char((sick#>>'{missing_certificates,0,start_date}')::date,'DD.MM.YYYY')
          || ' n''est pas couverte par un certificat au-delà du '
          || (sick->>'certificate_deadline_days') || 'e jour.',
        'consequence','Absence injustifiée, perte du droit à la continuation de salaire et motif disciplinaire possible.',
        'due_date', ((sick#>>'{missing_certificates,0,start_date}')::date
                     + (sick->>'certificate_deadline_days')::int),
        'days_left', -((sick#>>'{missing_certificates,0,days_late}')::int),
        'severity','blocking', 'legal_ref','art. L.121-6 (3)', 'category','absence');
    end if;

    if (sick->>'continuation_end') is not null then
      items := items || jsonb_build_object(
        'rule_code','sick_continuation_end', 'employee_id', r.id, 'employee_name', r.name,
        'title','Fin de la continuation de salaire — ' || r.name,
        'detail', (sick->>'days_in_window') || ' jours d''incapacité sur ' || (sick->>'window_months')
          || ' mois de référence, limite de ' || (sick->>'limit_days') || ' jours atteinte.',
        'consequence','La CNS prend le relais. Demander le remboursement à la Mutualité des employeurs ('
          || (sick->>'mutuality_refund_pct') || ' % de la charge salariale globale).',
        'due_date', (sick->>'continuation_end')::date,
        'days_left', (sick->>'continuation_end')::date - p_on,
        'severity','warning', 'legal_ref', sick->>'legal_ref', 'category','absence');
    end if;
  end loop;

  -- 4. Seuils d'effectif
  obl := fn_headcount_obligations(p_company, p_on);
  for r in select * from jsonb_array_elements(obl->'thresholds') as t(v) loop
    th := r.v;
    if (th->>'reached')::boolean then
      items := items || jsonb_build_object(
        'rule_code','headcount_' || (th->>'threshold'),
        'title','Seuil de ' || (th->>'threshold') || ' salariés franchi — ' || (th->>'label'),
        'detail','Effectif moyen de ' || (obl#>>'{headcount,rounded}') || ' sur les '
          || (obl#>>'{headcount,reference_months}') || ' mois précédents. Scrutin '
          || (obl->>'vote_mode') || '.',
        'consequence', th->>'consequence', 'due_date', null, 'days_left', null,
        'severity','warning', 'legal_ref', th->>'legal_ref', 'category','headcount');
    elsif (th->>'gap')::numeric <= ((th->>'threshold')::numeric
            - fn_param_num('delegation_approach_threshold', p_on))
          and (th->>'threshold')::numeric = fn_param_num('delegation_threshold', p_on) then
      items := items || jsonb_build_object(
        'rule_code','headcount_approach',
        'title','Seuil de ' || (th->>'threshold') || ' salariés — ' || (th->>'label') || ' proche',
        'detail','Effectif moyen de ' || (obl#>>'{headcount,rounded}') || ' sur les '
          || (obl#>>'{headcount,reference_months}') || ' mois précédents, à '
          || (th->>'gap') || ' près du seuil.',
        'consequence', th->>'consequence', 'due_date', null, 'days_left', null,
        'severity','info', 'legal_ref', th->>'legal_ref', 'category','headcount');
    end if;
  end loop;

  -- 5. Plannings non publiés comportant un blocage
  for r in
    select sc.id, sc.week_start from schedules sc
    where sc.company_id = p_company and sc.status = 'draft'
      and sc.week_start between p_on - 7 and p_on + horizon
  loop
    comp := fn_validate_schedule(r.id);
    if (comp->>'blocking_count')::int > 0 then
      items := items || jsonb_build_object(
        'rule_code','schedule_blocking', 'schedule_id', r.id,
        'title','Planning de la semaine du ' || to_char(r.week_start,'DD.MM') || ' non publiable',
        'detail', (comp->>'blocking_count') || ' violation(s) bloquante(s) du droit du travail subsistent.',
        'consequence','Le planning ne peut pas être publié tant que la violation subsiste.',
        'due_date', r.week_start, 'days_left', r.week_start - p_on,
        'severity','blocking', 'legal_ref','art. L.211-16', 'category','worktime');
    end if;
  end loop;

  cnt := fn_collective_dismissal_counters(p_company, p_on);

  return jsonb_build_object(
    'company_id', p_company, 'evaluated_on', p_on, 'horizon_days', horizon,
    'items', items,
    'overdue', (select coalesce(jsonb_agg(x), '[]'::jsonb) from jsonb_array_elements(items) x
                where (x->>'days_left') is not null and (x->>'days_left')::int < 0),
    'due_soon', (select coalesce(jsonb_agg(x), '[]'::jsonb) from jsonb_array_elements(items) x
                 where (x->>'days_left') is not null and (x->>'days_left')::int between 0 and horizon),
    'watch', (select coalesce(jsonb_agg(x), '[]'::jsonb) from jsonb_array_elements(items) x
              where (x->>'days_left') is null or (x->>'days_left')::int > horizon),
    'headcount', obl,
    'dismissal_counters', cnt,
    'disclaimer','LuxRH est un outil d''aide à la décision. Il ne se substitue pas à un conseil juridique.');
end $$;
