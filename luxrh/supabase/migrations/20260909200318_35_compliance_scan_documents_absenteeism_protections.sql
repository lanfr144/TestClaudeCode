
create or replace function fn_compliance_scan(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare items jsonb := '[]'::jsonb; r record; prob jsonb; sick jsonb; obl jsonb;
        horizon int; warn1 int; warn2 int; th jsonb; cnt jsonb; comp jsonb;
        cdd_alert1 int; cdd_alert2 int; prot jsonb; eoc jsonb;
        excess_days numeric; excess_window int;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;
  horizon    := fn_param_num('vigilance_horizon_days', p_on)::int;
  warn1      := fn_param_num('probation_alert_days_1', p_on)::int;
  warn2      := fn_param_num('probation_alert_days_2', p_on)::int;
  cdd_alert1 := fn_param_num('cdd_alert_days_1', p_on)::int;
  cdd_alert2 := fn_param_num('cdd_alert_days_2', p_on)::int;
  excess_days   := fn_param_num('sick_excessive_days_threshold', p_on);
  excess_window := fn_param_num('sick_excessive_window_months', p_on)::int;

  -- 1. Essais en cours
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
        'severity', case when (prob->>'days_until_deadline')::int <= warn2 then 'blocking'
                         when (prob->>'days_until_deadline')::int <= warn1 then 'warning'
                         else 'info' end,
        'legal_ref', prob->>'legal_ref', 'category','contract');
    end if;
  end loop;

  -- 2. Contrats à terme
  for r in
    select c.*, e.first_name || ' ' || e.last_name as name
    from contracts c join employees e on e.id = c.employee_id
    where c.company_id = p_company and c.status = 'active'
      and c.kind in ('cdd','seasonal','interim','apprenticeship') and c.end_date is not null
  loop
    items := items || jsonb_build_object(
      'rule_code','cdd_term', 'employee_id', r.employee_id, 'employee_name', r.name,
      'contract_id', r.id,
      'title','Contrat à terme — ' || r.name || ' (' || upper(r.kind::text) || ')',
      'detail', case when r.kind = 'cdd' then
          r.renewal_count || ' renouvellement(s) consommé(s), '
          || fn_fmt(round(extract(epoch from age(r.end_date, r.start_date)) / (30.44*86400), 0))
          || ' mois cumulés sur ' || fn_fmt(fn_param_num('cdd_max_months', p_on))
          || ' maximum. Délai de carence de '
          || fn_fmt(round(extract(epoch from age(r.end_date, r.start_date)) / (30.44*86400)
                   * fn_param_num('cdd_carence_ratio', p_on), 0))
          || ' mois avant un nouveau CDD sur le même poste.'
        else 'Terme fixé au ' || to_char(r.end_date,'DD.MM.YYYY') || '.' end,
      'consequence', case when r.kind = 'cdd'
        then 'Un renouvellement au-delà de la limite entraîne la requalification en CDI.'
        else 'Anticiper la sortie ou le renouvellement.' end,
      'due_date', r.end_date, 'days_left', r.end_date - p_on,
      'severity', case when r.end_date - p_on <= cdd_alert2 then 'blocking'
                       when r.end_date - p_on <= cdd_alert1 then 'warning' else 'info' end,
      'legal_ref', (fn_param('cdd_max_renewals', p_on)).legal_ref, 'category','contract');
  end loop;

  -- 3. Maladie : certificats, continuation de salaire, absentéisme excessif
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
          || (sick->>'certificate_deadline_days') || 'e jour. '
          || 'L''original doit parvenir par voie postale même si un dépôt numérique a eu lieu.',
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

    -- Absentéisme durable : la protection ayant cessé, la situation devient
    -- juridiquement examinable. L'outil signale, il ne décide pas.
    if (sick->>'days_in_window')::numeric >= excess_days
       and ((sick->>'protection_end') is null or (sick->>'protection_end')::date < p_on) then
      items := items || jsonb_build_object(
        'rule_code','excessive_absenteeism', 'employee_id', r.id, 'employee_name', r.name,
        'title','Absentéisme durable à examiner — ' || r.name,
        'detail', fn_fmt((sick->>'days_in_window')::numeric) || ' jours d''incapacité sur '
          || excess_window || ' mois, au-delà du seuil d''examen de ' || fn_fmt(excess_days)
          || ' jours, et la protection de ' || (sick->>'protection_weeks')
          || ' semaines a pris fin.',
        'consequence','Un licenciement devient juridiquement envisageable, sous réserve de la '
          || 'désorganisation démontrée du service et du respect de la procédure. '
          || 'La décision reste humaine et doit être examinée avec un conseil.',
        'due_date', null, 'days_left', null,
        'severity','warning', 'legal_ref','art. L.121-6', 'category','absence');
    end if;

    -- Protections en cours : elles interdisent toute notification.
    prot := fn_dismissal_protections(r.id, p_on);
    if (prot->>'protected')::boolean then
      items := items || jsonb_build_object(
        'rule_code','dismissal_protection', 'employee_id', r.id, 'employee_name', r.name,
        'title','Protection contre le licenciement — ' || r.name,
        'detail', (select string_agg((x->>'label') || ' jusqu''au '
                     || coalesce(to_char((x->>'until')::date,'DD.MM.YYYY'), 'terme du mandat'), ' · ')
                   from jsonb_array_elements(prot->'protections') x),
        'consequence','Toute notification de licenciement pendant cette période serait nulle.',
        'due_date', (select max((x->>'until')::date) from jsonb_array_elements(prot->'protections') x),
        'days_left', null,
        'severity','info',
        'legal_ref', (prot#>>'{protections,0,legal_ref}'), 'category','protection');
    end if;
  end loop;

  -- 4. Documents périmés ou proches de l'échéance
  for r in
    select d.id, d.name, d.expires_on, d.employee_id, dt.label as type_label,
           dt.alert_days_before, dt.legal_ref,
           e.first_name || ' ' || e.last_name as employee_name
    from documents d
    join document_types dt on dt.id = d.document_type_id
    left join employees e on e.id = d.employee_id
    where d.company_id = p_company and d.expires_on is not null
      and d.expires_on <= p_on + greatest(dt.alert_days_before, horizon)
  loop
    items := items || jsonb_build_object(
      'rule_code','document_expiry', 'employee_id', r.employee_id, 'employee_name', r.employee_name,
      'document_id', r.id,
      'title', r.type_label || ' — ' || coalesce(r.employee_name, 'société'),
      'detail', case when r.expires_on < p_on
                     then 'Périmé depuis le ' || to_char(r.expires_on,'DD.MM.YYYY') || '.'
                     else 'Expire le ' || to_char(r.expires_on,'DD.MM.YYYY') || '.' end,
      'consequence','Un document expiré ne couvre plus l''obligation qui s''y rattache.',
      'due_date', r.expires_on, 'days_left', r.expires_on - p_on,
      'severity', case when r.expires_on < p_on then 'blocking' else 'warning' end,
      'legal_ref', r.legal_ref, 'category','document');
  end loop;

  -- 5. Documents de fin de contrat non remis
  for r in
    select ct.id, ct.notice_end, c.employee_id, e.first_name || ' ' || e.last_name as name
    from contract_terminations ct
    join contracts c on c.id = ct.contract_id
    join employees e on e.id = c.employee_id
    where ct.company_id = p_company
  loop
    eoc := fn_end_of_contract_documents(r.id);
    if (eoc->>'outstanding')::int > 0 then
      items := items || jsonb_build_object(
        'rule_code','end_of_contract_documents', 'employee_id', r.employee_id, 'employee_name', r.name,
        'contract_id', r.id,
        'title','Documents de fin de contrat à remettre — ' || r.name,
        'detail', (eoc->>'outstanding') || ' document(s) manquant(s) : '
          || (select string_agg(x->>'label', ', ') from jsonb_array_elements(eoc->'documents') x
              where not (x->>'delivered')::boolean),
        'consequence','La remise du certificat de travail et du reçu pour solde de tout compte est obligatoire.',
        'due_date', r.notice_end, 'days_left', r.notice_end - p_on,
        'severity', case when r.notice_end is not null and r.notice_end < p_on then 'blocking' else 'warning' end,
        'legal_ref','art. L.125-9', 'category','document');
    end if;
  end loop;

  -- 6. Seuils d'effectif
  obl := fn_headcount_obligations(p_company, p_on);
  for r in select * from jsonb_array_elements(obl->'thresholds') as t(v) loop
    th := r.v;
    if (th->>'reached')::boolean then
      items := items || jsonb_build_object(
        'rule_code','headcount_' || (th->>'threshold'),
        'title','Seuil de ' || fn_fmt((th->>'threshold')::numeric) || ' salariés franchi — ' || (th->>'label'),
        'detail','Effectif moyen de ' || (obl#>>'{headcount,rounded}') || ' sur les '
          || (obl#>>'{headcount,reference_months}') || ' mois précédents. Scrutin '
          || (obl->>'vote_mode') || '.',
        'consequence', th->>'consequence', 'due_date', null, 'days_left', null,
        'severity','warning', 'legal_ref', th->>'legal_ref', 'category','headcount');
    elsif (th->>'threshold')::numeric = fn_param_num('delegation_threshold', p_on)
          and (th->>'gap')::numeric <= ((th->>'threshold')::numeric
               - fn_param_num('delegation_approach_threshold', p_on)) then
      items := items || jsonb_build_object(
        'rule_code','headcount_approach',
        'title','Seuil de ' || fn_fmt((th->>'threshold')::numeric) || ' salariés — '
          || (th->>'label') || ' proche',
        'detail','Effectif moyen de ' || (obl#>>'{headcount,rounded}') || ' sur les '
          || (obl#>>'{headcount,reference_months}') || ' mois précédents, à '
          || (th->>'gap') || ' près du seuil.',
        'consequence', th->>'consequence', 'due_date', null, 'days_left', null,
        'severity','info', 'legal_ref', th->>'legal_ref', 'category','headcount');
    end if;
  end loop;

  -- 7. Plannings non publiables
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
