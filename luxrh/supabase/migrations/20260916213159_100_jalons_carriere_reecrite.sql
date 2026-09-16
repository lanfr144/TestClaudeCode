-- 100 — `fn_jalons_carriere`, réécrite au propre
--
-- La version des migrations 98 et 99 portait un compteur qui mentait : `poses`
-- était incrémenté, puis écrasé par un `get diagnostics`, puis ignoré au profit
-- d'un recomptage final. Trois écritures pour une valeur jamais lue. Un lecteur
-- y aurait cherché un sens qui n'existait pas.
--
-- La fonction est réécrite d'un bloc : un seul comptage, à la fin, sur ce qui a
-- réellement été inséré.

create or replace function fn_jalons_carriere(p_societe uuid, p_on date default current_date)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  age_retraite    numeric;
  preavis_mois    numeric;
  seuil_long      numeric;
  preavis_reprise numeric;
  codes constant text[] := array['retraite_approche', 'absence_longue_debut',
                                 'absence_longue_reprise', 'referentiel_retraite_absent'];
begin
  if not has_company_access(p_societe) then
    raise exception 'Accès refusé à la société %.', p_societe;
  end if;

  age_retraite    := fn_param_num('AGE_RETRAITE', p_on);
  preavis_mois    := fn_param_num('PREAVIS_RETRAITE_MOIS', p_on);
  seuil_long      := fn_param_num('ABSENCE_LONGUE_JOURS', p_on);
  preavis_reprise := fn_param_num('PREAVIS_REPRISE_JOURS', p_on);

  if preavis_mois is null or seuil_long is null or preavis_reprise is null then
    raise exception 'Paramètres applicatifs absents : PREAVIS_RETRAITE_MOIS, ABSENCE_LONGUE_JOURS ou PREAVIS_REPRISE_JOURS.';
  end if;

  -- Reconstruction à chaque passage : une échéance écartée puis redevenue
  -- d'actualité doit ressortir.
  delete from alertes_conformite
   where societe_id = p_societe and code_regle = any(codes) and etat = 'ouverte';

  -- ------------------------------------------------- 1. approche de la retraite
  if age_retraite is null then
    -- Pas de valeur, pas de calcul — mais surtout pas de silence.
    insert into alertes_conformite
      (societe_id, salarie_id, code_regle, titre, detail, consequence,
       reference_legale, severite, etat)
    values
      (p_societe, null, 'referentiel_retraite_absent',
       'Âge de la retraite absent du référentiel',
       'La clé AGE_RETRAITE n''a aucune version chargée ; les échéances de retraite '
       || 'et de préretraite ne peuvent pas être calculées.',
       'Aucun salarié ne sera prévenu de l''approche de son départ en retraite.',
       'Code de la sécurité sociale — à verser au corpus', 'probleme', 'ouverte');
  else
    insert into alertes_conformite
      (societe_id, salarie_id, code_regle, titre, detail, consequence,
       reference_legale, severite, date_echeance, etat)
    select
      p_societe, s.id, 'retraite_approche',
      'Départ en retraite dans moins de ' || preavis_mois || ' mois',
      s.prenom || ' ' || s.nom || ' atteindra ' || age_retraite || ' ans le '
        || to_char(s.date_naissance + make_interval(years => age_retraite::int), 'DD/MM/YYYY') || '.',
      'La succession et la liquidation des droits demandent d''être préparées.',
      'Code de la sécurité sociale', 'info',
      (s.date_naissance + make_interval(years => age_retraite::int))::date,
      'ouverte'
    from salaries s
    where s.societe_id = p_societe
      and s.date_naissance is not null
      and (s.date_naissance + make_interval(years => age_retraite::int))::date
          between p_on and (p_on + make_interval(months => preavis_mois::int))::date
      and exists (select 1 from contrats c
                   where c.salarie_id = s.id and c.statut = 'en_cours');
  end if;

  -- --------------------------------------------- 2. absence longue en cours
  insert into alertes_conformite
    (societe_id, salarie_id, code_regle, titre, detail, consequence,
     reference_legale, severite, date_echeance, etat)
  select
    p_societe, a.salarie_id, 'absence_longue_debut',
    'Absence longue en cours — ' || ta.libelle,
    s.prenom || ' ' || s.nom || ' est absent du ' || to_char(a.date_debut, 'DD/MM/YYYY')
      || ' au ' || to_char(a.date_fin, 'DD/MM/YYYY') || ', soit '
      || (a.date_fin - a.date_debut + 1) || ' jours.',
    'Le poste est à pourvoir pendant l''absence, et le dossier à tenir à jour pour la reprise.',
    ta.reference_legale, 'info', a.date_fin, 'ouverte'
  from absences a
  join types_absence ta on ta.id = a.type_absence_id
  join salaries s on s.id = a.salarie_id
  where a.societe_id = p_societe
    and a.statut = 'valide'
    and a.date_fin is not null
    and (a.date_fin - a.date_debut + 1) >= seuil_long
    and p_on between a.date_debut and a.date_fin;

  -- --------------------------------------------- 3. reprise après absence longue
  insert into alertes_conformite
    (societe_id, salarie_id, code_regle, titre, detail, consequence,
     reference_legale, severite, date_echeance, etat)
  select
    p_societe, a.salarie_id, 'absence_longue_reprise',
    'Reprise après absence longue le ' || to_char(a.date_fin + 1, 'DD/MM/YYYY'),
    s.prenom || ' ' || s.nom || ' reprend après ' || (a.date_fin - a.date_debut + 1)
      || ' jours d''absence (' || ta.libelle || ').',
    'Un examen médical de reprise est à organiser, et les habilitations comme les '
      || 'pièces du dossier sont à vérifier avant le retour au poste.',
    ta.reference_legale, 'avertissement', (a.date_fin + 1)::date, 'ouverte'
  from absences a
  join types_absence ta on ta.id = a.type_absence_id
  join salaries s on s.id = a.salarie_id
  where a.societe_id = p_societe
    and a.statut = 'valide'
    and a.date_fin is not null
    and (a.date_fin - a.date_debut + 1) >= seuil_long
    and (a.date_fin + 1) between p_on and (p_on + make_interval(days => preavis_reprise::int))::date;

  return (select count(*)::integer from alertes_conformite
           where societe_id = p_societe and code_regle = any(codes) and etat = 'ouverte');
end;
$$;

comment on function fn_jalons_carriere(uuid, date) is
  'Lève les alertes de cycle de vie d''une société : approche de la retraite, absences longues en cours, reprises à venir. Rend le nombre d''alertes ouvertes. Si l''âge de la retraite manque au référentiel, la fonction le dit par une alerte plutôt que de retenir une valeur plausible.';

revoke execute on function fn_jalons_carriere(uuid, date) from public;
grant execute on function fn_jalons_carriere(uuid, date) to authenticated;
