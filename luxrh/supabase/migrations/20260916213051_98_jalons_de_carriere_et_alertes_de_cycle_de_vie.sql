-- 98 — Jalons de carrière : retraite, congés longs, reprises
--
-- Trois échéances que l'employeur doit anticiper et que rien ne signalait :
--
--   1. l'approche de l'âge de la retraite, et celle de la préretraite ;
--   2. l'entrée dans un congé long — parental, maladie prolongée, sans solde ;
--   3. le retour d'un congé long, qui déclenche l'examen médical de reprise et
--      la remise en conformité du dossier.
--
-- **Aucune valeur d'âge n'est écrite ici.** L'âge de la retraite et les
-- conditions de préretraite relèvent du Code de la sécurité sociale, qui ne
-- figure pas au corpus documentaire du projet. Les clés sont déclarées comme
-- attendues ; `fn_referential_gaps` les signalera tant qu'elles ne sont pas
-- chargées, et la fonction ci-dessous refuse de conclure en leur absence plutôt
-- que de retenir soixante-cinq ans parce que « c'est ce qu'on croit savoir ».
--
-- C'est la règle 7 du projet : un trou déclaré se comble, une valeur fausse ne se
-- détecte qu'au moment où elle a déjà nui — ici, un salarié prévenu trop tard.

insert into parametres_attendus (cle_parametre, lu_par, note) values
  ('AGE_RETRAITE', 'fn_jalons_carriere',
   'Âge légal d''ouverture du droit à pension de vieillesse. Code de la sécurité sociale — à charger, la source n''est pas au corpus.'),
  ('AGE_PRERETRAITE', 'fn_jalons_carriere',
   'Âge d''ouverture des régimes de préretraite. Code de la sécurité sociale et Code du travail, livre V — à charger.'),
  ('PREAVIS_RETRAITE_MOIS', 'fn_jalons_carriere',
   'Combien de mois avant l''échéance l''alerte de retraite est levée. Paramètre applicatif, sans source légale.'),
  ('ABSENCE_LONGUE_JOURS', 'fn_jalons_carriere',
   'Durée à partir de laquelle une absence est tenue pour longue et déclenche le suivi de reprise. Paramètre applicatif.'),
  ('PREAVIS_REPRISE_JOURS', 'fn_jalons_carriere',
   'Combien de jours avant le retour l''alerte de reprise est levée. Paramètre applicatif.')
on conflict (cle_parametre) do nothing;

-- Les trois paramètres purement applicatifs n'attendent aucune publication
-- officielle : ils relèvent d'un choix d'outil, et sont posés comme tels.
insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, note)
values
  ('contrat', 'PREAVIS_RETRAITE_MOIS', 'Préavis d''alerte avant l''âge de la retraite',
   12, 'mois', date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH',
   'Choix d''outil, sans source légale : douze mois laissent le temps d''organiser la succession.'),
  ('conges', 'ABSENCE_LONGUE_JOURS', 'Seuil au-delà duquel une absence est tenue pour longue',
   30, 'jours', date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH',
   'Choix d''outil. Ne préjuge pas du seuil de 77 jours de conservation de rémunération, qui est légal et porté par sick_continuation_days.'),
  ('conges', 'PREAVIS_REPRISE_JOURS', 'Préavis d''alerte avant un retour de congé long',
   15, 'jours', date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH',
   'Choix d''outil : quinze jours pour convoquer l''examen de reprise.')
on conflict do nothing;

-- ------------------------------------------------------------------ la routine
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
  poses           integer := 0;
begin
  if not has_company_access(p_societe) then
    raise exception 'Accès refusé à la société %.', p_societe;
  end if;

  age_retraite    := fn_param_num('AGE_RETRAITE', p_on);
  preavis_mois    := fn_param_num('PREAVIS_RETRAITE_MOIS', p_on);
  seuil_long      := fn_param_num('ABSENCE_LONGUE_JOURS', p_on);
  preavis_reprise := fn_param_num('PREAVIS_REPRISE_JOURS', p_on);

  -- Les alertes de ce moteur sont reconstruites à chaque passage : une échéance
  -- traitée puis redevenue d'actualité doit ressortir.
  delete from alertes_conformite
   where societe_id = p_societe
     and code_regle in ('retraite_approche', 'absence_longue_debut',
                        'absence_longue_reprise', 'referentiel_retraite_absent')
     and etat = 'ouverte';

  -- ------------------------------------------------- 1. l'approche de la retraite
  if age_retraite is null then
    -- Pas de valeur, pas de calcul. Mais le silence serait pire : on dit
    -- pourquoi l'outil ne peut pas répondre.
    insert into alertes_conformite
      (societe_id, salarie_id, code_regle, titre, detail, consequence,
       reference_legale, severite, etat)
    values
      (p_societe, null, 'referentiel_retraite_absent',
       'Âge de la retraite absent du référentiel',
       'La clé AGE_RETRAITE n''a aucune version chargée. Les échéances de retraite '
       || 'et de préretraite ne peuvent donc pas être calculées.',
       'Aucun salarié ne sera prévenu de l''approche de son départ en retraite.',
       'Code de la sécurité sociale — à verser au corpus', 'probleme', 'ouverte');
    poses := poses + 1;
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
    poses := poses + coalesce((select count(*) from alertes_conformite
                                where societe_id = p_societe
                                  and code_regle = 'retraite_approche'
                                  and etat = 'ouverte'), 0);
  end if;

  -- --------------------------------------------- 2. entrée dans un congé long
  insert into alertes_conformite
    (societe_id, salarie_id, code_regle, titre, detail, consequence,
     reference_legale, severite, date_echeance, etat)
  select
    p_societe, a.salarie_id, 'absence_longue_debut',
    'Absence longue en cours — ' || ta.libelle,
    s.prenom || ' ' || s.nom || ' est absent du '
      || to_char(a.date_debut, 'DD/MM/YYYY') || ' au '
      || to_char(a.date_fin, 'DD/MM/YYYY') || ', soit '
      || (a.date_fin - a.date_debut + 1) || ' jours.',
    'Le poste est à pourvoir pendant l''absence, et le dossier à tenir à jour '
      || 'pour la reprise.',
    ta.reference_legale, 'info', a.date_fin, 'ouverte'
  from absences a
  join types_absence ta on ta.id = a.type_absence_id
  join salaries s on s.id = a.salarie_id
  where a.societe_id = p_societe
    and a.statut = 'approuvee'
    and (a.date_fin - a.date_debut + 1) >= seuil_long
    and p_on between a.date_debut and a.date_fin;
  get diagnostics poses = row_count;

  -- --------------------------------------------- 3. retour d'un congé long
  insert into alertes_conformite
    (societe_id, salarie_id, code_regle, titre, detail, consequence,
     reference_legale, severite, date_echeance, etat)
  select
    p_societe, a.salarie_id, 'absence_longue_reprise',
    'Reprise après absence longue le ' || to_char(a.date_fin + 1, 'DD/MM/YYYY'),
    s.prenom || ' ' || s.nom || ' reprend après ' || (a.date_fin - a.date_debut + 1)
      || ' jours d''absence (' || ta.libelle || ').',
    'Un examen médical de reprise est à organiser, et les habilitations comme '
      || 'les pièces du dossier sont à vérifier avant le retour au poste.',
    ta.reference_legale, 'avertissement', (a.date_fin + 1)::date, 'ouverte'
  from absences a
  join types_absence ta on ta.id = a.type_absence_id
  join salaries s on s.id = a.salarie_id
  where a.societe_id = p_societe
    and a.statut = 'approuvee'
    and (a.date_fin - a.date_debut + 1) >= seuil_long
    and (a.date_fin + 1) between p_on and (p_on + make_interval(days => preavis_reprise::int))::date;

  return (select count(*) from alertes_conformite
           where societe_id = p_societe
             and code_regle in ('retraite_approche', 'absence_longue_debut',
                                'absence_longue_reprise', 'referentiel_retraite_absent')
             and etat = 'ouverte');
end;
$$;

comment on function fn_jalons_carriere(uuid, date) is
  'Lève les alertes de cycle de vie d''une société : approche de la retraite, absences longues en cours et reprises à venir. Rend le nombre d''alertes ouvertes. Si l''âge de la retraite manque au référentiel, la fonction le dit par une alerte au lieu de retenir une valeur plausible.';

revoke execute on function fn_jalons_carriere(uuid, date) from public;
grant execute on function fn_jalons_carriere(uuid, date) to authenticated;
