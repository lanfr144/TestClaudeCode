-- 59b — Le moteur de contrôle des sanctions
--
-- Une table de sanctions sans contrôle ne vaut rien : elle enregistre aussi bien
-- une sanction régulière qu'une sanction annulable. `fn_sanction_check` dit ce
-- qui cloche, avec le motif — jamais un simple oui/non.
--
-- Ce qu'elle vérifie, et pourquoi
-- --------------------------------
--   type hors validité       un catalogue daté ne sert à rien si l'on ne
--                            vérifie pas la date ;
--   textes internes          une sanction lourde sans règlement interne est
--                            susceptible d'être annulée ;
--   textes postérieurs       un règlement adopté après les faits ne peut pas
--                            les fonder ;
--   délai de notification    compté depuis la CONNAISSANCE des faits, et non
--                            depuis les faits eux-mêmes ;
--   durée déterminée         une sanction qui prive de salaire doit dire de
--                            quand à quand ;
--   avenant manquant         une rétrogradation ou une mutation modifie le
--                            contrat : elle passe par fn_amend_contract ;
--   rupture manquante        un licenciement est aussi une rupture : les deux
--                            enregistrements vont ensemble ;
--   entretien préalable      requis au-delà du seuil d'effectif que porte le
--                            référentiel ;
--   salarié protégé          grossesse, mandat de délégué, maladie.
--
-- Le paramètre `sanction_notification_deadline_days` n'étant pas chargé, la
-- fonction répond aujourd'hui « délai non vérifiable » plutôt que de supposer
-- une durée. C'est un constat, pas un silence.

create or replace function fn_sanction_check(p_sanction uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s          employee_sanctions%rowtype;
  t          sanction_types%rowtype;
  cie        companies%rowtype;
  checks     jsonb := '[]'::jsonb;
  v_delai    numeric;
  v_seuil    numeric;
  v_effectif jsonb;
  v_prot     jsonb;
begin
  select * into s from employee_sanctions where id = p_sanction and deleted_at is null;
  if s.id is null then
    raise exception 'Sanction introuvable : %', p_sanction;
  end if;
  if not (can_manage_company(s.company_id) or is_self_employee(s.employee_id)) then
    raise exception 'Accès refusé à cette sanction.';
  end if;

  select * into t   from sanction_types where code = s.sanction_type;
  select * into cie from companies      where id = s.company_id;

  if t.valid_from > s.facts_on or (t.valid_to is not null and t.valid_to <= s.facts_on) then
    checks := checks || jsonb_build_object(
      'severity', 'blocking', 'code', 'type_hors_validite',
      'title', 'Type de sanction hors de sa période de validité',
      'detail', format('« %s » s''applique du %s au %s ; les faits datent du %s.',
                       t.label, t.valid_from, coalesce(t.valid_to::text, 'indéterminé'), s.facts_on));
  end if;

  if t.requires_internal_rules then
    if cie.internal_rules_adopted_on is null then
      checks := checks || jsonb_build_object(
        'severity', 'blocking', 'code', 'textes_internes_absents',
        'title', 'Aucun texte interne enregistré pour cette société',
        'detail', format('« %s » est une sanction lourde : elle doit figurer dans les textes internes de l''entreprise pour être valable. Aucune date d''adoption n''est enregistrée.', t.label),
        'consequence', 'Sanction susceptible d''être annulée.');
    elsif cie.internal_rules_adopted_on > s.facts_on then
      checks := checks || jsonb_build_object(
        'severity', 'blocking', 'code', 'textes_internes_posterieurs',
        'title', 'Textes internes postérieurs aux faits',
        'detail', format('Les textes internes datent du %s, les faits du %s : ils ne peuvent pas fonder cette sanction.', cie.internal_rules_adopted_on, s.facts_on));
    end if;
  end if;

  v_delai := fn_param_num('sanction_notification_deadline_days', s.facts_known_on);
  if s.notified_on is null then
    checks := checks || jsonb_build_object(
      'severity', 'warning', 'code', 'non_notifiee',
      'title', 'Sanction non notifiée',
      'detail', 'Une sanction non notifiée n''existe pas à l''égard du salarié.');
  elsif v_delai is null then
    checks := checks || jsonb_build_object(
      'severity', 'warning', 'code', 'delai_non_verifiable',
      'title', 'Délai de notification non vérifiable',
      'detail', 'Le paramètre sanction_notification_deadline_days n''est pas chargé dans le référentiel : le délai ne peut être ni confirmé ni écarté. Aucune durée n''est supposée à sa place.',
      'legal_ref', null);
  elsif (s.notified_on - s.facts_known_on) > v_delai then
    checks := checks || jsonb_build_object(
      'severity', 'blocking', 'code', 'delai_depasse',
      'title', 'Délai de notification dépassé',
      'detail', format('%s jours entre la connaissance des faits et la notification, pour un maximum de %s.', s.notified_on - s.facts_known_on, v_delai));
  end if;

  if t.affects_pay and not t.ends_contract
     and (s.effective_from is null or s.effective_to is null) then
    checks := checks || jsonb_build_object(
      'severity', 'blocking', 'code', 'duree_absente',
      'title', 'Durée non déterminée',
      'detail', format('« %s » prive le salarié de rémunération : sa durée doit être déterminée, donc bornée par une date de début et de fin.', t.label));
  end if;

  if t.is_contract_change and s.amendment_contract_id is null then
    checks := checks || jsonb_build_object(
      'severity', 'blocking', 'code', 'avenant_manquant',
      'title', 'Avenant non établi',
      'detail', format('« %s » modifie le contrat. Établissez l''avenant par fn_amend_contract et rattachez-le ici. %s', t.label, coalesce(t.note, '')));
  end if;

  if t.ends_contract and s.termination_id is null then
    checks := checks || jsonb_build_object(
      'severity', 'blocking', 'code', 'rupture_manquante',
      'title', 'Rupture non enregistrée',
      'detail', format('« %s » met fin au contrat : la rupture correspondante doit être enregistrée et rattachée.', t.label));
  end if;

  v_seuil := fn_param_num('prior_interview_threshold', s.facts_known_on);
  if t.ends_contract and v_seuil is not null then
    v_effectif := fn_headcount(s.company_id, s.facts_known_on);
    if (v_effectif ->> 'headcount')::numeric >= v_seuil and s.employee_heard_on is null then
      checks := checks || jsonb_build_object(
        'severity', 'blocking', 'code', 'entretien_prealable',
        'title', 'Entretien préalable non tenu',
        'detail', format('L''effectif (%s) atteint le seuil de %s : l''entretien préalable est requis avant notification.',
                         round((v_effectif ->> 'headcount')::numeric, 1), v_seuil));
    end if;
  end if;

  if t.ends_contract then
    v_prot := fn_dismissal_protections(s.employee_id, coalesce(s.notified_on, s.facts_known_on));
    if (v_prot ->> 'protected')::boolean then
      checks := checks || jsonb_build_object(
        'severity', 'blocking', 'code', 'salarie_protege',
        'title', 'Le salarié est protégé contre le licenciement',
        'detail', v_prot ->> 'message',
        'source', v_prot);
    end if;
  end if;

  return jsonb_build_object(
    'sanction_id', p_sanction,
    'type', t.code, 'type_label', t.label,
    'category', t.category_code,
    'checks', checks,
    'blocking_count', (select count(*) from jsonb_array_elements(checks) x
                        where x->>'severity' = 'blocking'),
    'warning_count',  (select count(*) from jsonb_array_elements(checks) x
                        where x->>'severity' = 'warning'),
    'can_apply', not exists (select 1 from jsonb_array_elements(checks) x
                              where x->>'severity' = 'blocking'));
end $$;

comment on function fn_sanction_check(uuid) is
  'Contrôle la régularité d''une sanction : validité du type à la date des faits, textes internes exigés pour une sanction lourde, délai de notification, durée déterminée, avenant pour une modification de contrat, rupture rattachée, entretien préalable, protections en cours. Renvoie les constats, jamais un simple oui/non.';

revoke execute on function fn_sanction_check(uuid) from public, anon;
grant  execute on function fn_sanction_check(uuid) to authenticated;

-- NOTE : la version appliquée le 11 septembre 2026 portait en outre une
-- variable `procedure_noop boolean;` déclarée et jamais utilisée, retirée par la
-- migration 59c. Le corps ci-dessus est celui qui est en vigueur.
