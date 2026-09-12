-- 85 — Les valeurs d'énumération et les codes de domaine passent au français
--
-- Le renommage s'était arrêté aux noms d'objets. Les valeurs restaient anglaises
-- — et pire, trois avaient été traduites en chemin par les migrations 78 et 78b,
-- laissant des énumérations mi-anglaises :
--
--     statut_planning   = (draft, publie)
--     portee_convention = (secteur, harassment, employee_category, ...)
--     famille_parametre = (social, fiscal, worktime, leave, contract, effectif, ccss)
--
-- Un mélange est plus mauvais que l'anglais intégral : on ne peut plus deviner
-- la langue d'une valeur, il faut la lire.
--
-- POURQUOI C'EST SÛR
-- ==================
-- `alter type ... rename value` conserve l'identifiant interne de l'étiquette :
-- les lignes stockées suivent d'elles-mêmes, sans réécriture ni verrou long.
--
-- Les tables de domaine, elles, sont protégées par des clés étrangères : il faut
-- insérer le nouveau code, basculer les lignes qui référencent l'ancien, puis le
-- retirer. Les tables référençantes sont découvertes dans `pg_constraint`, jamais
-- énumérées à la main — une clé étrangère ajoutée plus tard sera suivie
-- automatiquement.
--
-- Les corps de fonctions sont réécrits par substitution de **littéraux exacts
-- entre apostrophes**, jamais de mots : `'leave'` devient `'conges'`, mais le mot
-- `leave` dans un identifiant ou une phrase n'est pas touché.
--
-- CE QUI N'EST PAS TRADUIT, ET POURQUOI
-- ======================================
--   `ok`    — sert aussi de jeton de style pour les badges de l'interface.
--             Le traduire renommerait une classe CSS sans que rien ne le
--             signale : aucun test ne regarde le rendu.
--   `info`  — identique en français.
--   `cdi`, `cdd`, `ccss`, `interim`, `social`, `fiscal`, `variable`,
--   `performance`, `danger`, `penibilite`, `insalubrite` — déjà français ou
--             sigles consacrés.
--   `1`, `1a`, `2` — désignations officielles des classes d'impôt.
--
-- COLLISIONS RÉSOLUES
-- ===================
-- `cancelled` existe dans trois énumérations, `approved` dans deux. Toutes
-- reçoivent la même traduction au masculin singulier — `annule`, `valide` — pour
-- qu'une substitution de littéral reste non ambiguë. Un code n'est pas une
-- phrase : l'accord grammatical y coûterait plus qu'il ne rapporte.

set search_path = public;

create table if not exists renommage_valeurs (
  objet text, ancien text, nouveau text, genre text);
truncate renommage_valeurs;

insert into renommage_valeurs (objet, ancien, nouveau, genre) values
 ('bloc_convention','salary_grid','grille_salaires','enum'),
 ('bloc_convention','worktime','temps_travail','enum'),
 ('bloc_convention','leave','conges','enum'),
 ('bloc_convention','premiums','primes','enum'),
 ('bloc_convention','surcharges','majorations','enum'),
 ('bloc_convention','notice_probation','preavis_essai','enum'),
 ('bloc_convention','custom_holidays','feries_usage','enum'),
 ('categorie_absence','annual_leave','conge_annuel','enum'),
 ('categorie_absence','sick','maladie','enum'),
 ('categorie_absence','extraordinary','conge_extraordinaire','enum'),
 ('categorie_absence','public_holiday','jour_ferie','enum'),
 ('categorie_absence','unpaid','sans_solde','enum'),
 ('categorie_absence','compensatory','recuperation','enum'),
 ('etape_document','pre_hire','avant_embauche','enum'),
 ('etape_document','during_contract','pendant_contrat','enum'),
 ('etape_document','end_of_contract','fin_contrat','enum'),
 ('etat_alerte','open','ouverte','enum'),
 ('etat_alerte','handled','traitee','enum'),
 ('etat_alerte','dismissed','ecartee','enum'),
 ('famille_parametre','worktime','temps_travail','enum'),
 ('famille_parametre','leave','conges','enum'),
 ('famille_parametre','contract','contrat','enum'),
 ('genre_contrat','seasonal','saisonnier','enum'),
 ('genre_contrat','apprenticeship','apprentissage','enum'),
 ('genre_element_remuneration','fixed','fixe','enum'),
 ('genre_element_remuneration','benefit_in_kind','avantage_nature','enum'),
 ('genre_element_remuneration','premium','prime','enum'),
 ('genre_element_remuneration','expense','frais','enum'),
 ('genre_organisation','fiduciary','fiduciaire','enum'),
 ('genre_organisation','company','societe','enum'),
 ('genre_qualification','qualified','qualifie','enum'),
 ('genre_qualification','unqualified','non_qualifie','enum'),
 ('genre_severite','blocking','bloquant','enum'),
 ('genre_severite','warning','avertissement','enum'),
 ('genre_severite','problem','probleme','enum'),
 ('genre_sexe','male','masculin','enum'),
 ('genre_sexe','female','feminin','enum'),
 ('genre_sexe','unspecified','non_precise','enum'),
 ('genre_statut_salarie','pregnancy','grossesse','enum'),
 ('genre_statut_salarie','maternity_leave','conge_maternite','enum'),
 ('genre_statut_salarie','breastfeeding','allaitement','enum'),
 ('genre_statut_salarie','parental_leave','conge_parental','enum'),
 ('genre_statut_salarie','delegate','delegue_personnel','enum'),
 ('genre_statut_salarie','safety_delegate','delegue_securite','enum'),
 ('genre_statut_salarie','equality_delegate','delegue_egalite','enum'),
 ('genre_statut_salarie','reemployment_bonus','prime_reemploi','enum'),
 ('genre_statut_salarie','company_manager','gerant','enum'),
 ('genre_statut_salarie','protected_other','autre_protege','enum'),
 ('periodicite_impot','monthly','mensuel','enum'),
 ('periodicite_impot','daily','journalier','enum'),
 ('periodicite_impot','annual','annuel','enum'),
 ('portee_convention','harassment','harcelement','enum'),
 ('portee_convention','employee_category','categorie_professionnelle','enum'),
 ('portee_convention','department','service','enum'),
 ('portee_convention','company','societe','enum'),
 ('role_application','fiduciary_admin','admin_fiduciaire','enum'),
 ('role_application','manager','gestionnaire','enum'),
 ('role_application','service_manager','chef_service','enum'),
 ('role_application','employee','salarie','enum'),
 ('statut_absence','pending','en_attente','enum'),
 ('statut_absence','approved','valide','enum'),
 ('statut_absence','refused','refuse','enum'),
 ('statut_absence','cancelled','annule','enum'),
 ('statut_absence','proposed','propose','enum'),
 ('statut_contrat','draft','brouillon','enum'),
 ('statut_contrat','active','en_cours','enum'),
 ('statut_contrat','ended','termine','enum'),
 ('statut_contrat','cancelled','annule','enum'),
 ('statut_planning','draft','brouillon','enum'),
 ('ref_action_acces','READ','LECTURE','ref'),
 ('ref_action_acces','DECRYPT','DECHIFFREMENT','ref'),
 ('ref_action_acces','DOWNLOAD','TELECHARGEMENT','ref'),
 ('ref_compensation_heures_sup','money','argent','ref'),
 ('ref_compensation_heures_sup','rest','repos','ref'),
 ('ref_lien_enfant','child','enfant','ref'),
 ('ref_lien_enfant','adopted','adopte','ref'),
 ('ref_lien_enfant','foster','recueilli','ref'),
 ('ref_lien_enfant','stepchild','enfant_conjoint','ref'),
 ('ref_nature_prime','thirteenth_month','treizieme_mois','ref'),
 ('ref_nature_prime','seniority','anciennete','ref'),
 ('ref_nature_prime','exceptional','exceptionnelle','ref'),
 ('ref_nature_prime','notice_waiver','renonciation_preavis','ref'),
 ('ref_nature_prime','other','autre','ref'),
 ('ref_statut_heures_sup','requested','demande','ref'),
 ('ref_statut_heures_sup','hr_approved','valide_rh','ref'),
 ('ref_statut_heures_sup','approved','valide','ref'),
 ('ref_statut_heures_sup','rejected','refuse','ref'),
 ('ref_statut_heures_sup','cancelled','annule','ref'),
 ('ref_statut_verification_adresse','outside','hors_perimetre','ref'),
 ('ref_statut_verification_adresse','unknown','indeterminee','ref'),
 ('ref_sujet_export','employee','salarie','ref'),
 ('ref_sujet_export','company','societe','ref'),
 ('ref_sujet_export','organization','organisation','ref'),
 ('ref_sujet_export','referential','referentiel','ref'),
 ('categories_sanction','minor','mineure','ref'),
 ('categories_sanction','heavy','lourde','ref'),
 ('categories_sanction','termination','rupture','ref'),
 ('types_sanction','written_warning','avertissement_ecrit','ref'),
 ('types_sanction','reprimand','blame','ref'),
 ('types_sanction','suspension_disciplinary','mise_a_pied_disciplinaire','ref'),
 ('types_sanction','transfer','mutation','ref'),
 ('types_sanction','demotion','retrogradation','ref'),
 ('types_sanction','suspension_precautionary','mise_a_pied_conservatoire','ref'),
 ('types_sanction','dismissal_notice','licenciement_avec_preavis','ref'),
 ('types_sanction','dismissal_gross_misconduct','licenciement_faute_grave','ref');

-- 1. Les énumérations.
do $enums$
declare r record; n int := 0;
begin
  for r in select * from renommage_valeurs where genre = 'enum' loop
    if exists (select 1 from pg_enum e join pg_type t on t.oid = e.enumtypid
               join pg_namespace ns on ns.oid = t.typnamespace and ns.nspname = 'public'
               where t.typname = r.objet and e.enumlabel = r.ancien) then
      execute format('alter type public.%I rename value %L to %L',
                     r.objet, r.ancien, r.nouveau);
      n := n + 1;
    end if;
  end loop;
  raise notice '% valeur(s) d''enumeration traduite(s).', n;
end $enums$;

-- 2. Les codes de domaine.
do $refs$
declare
  r  record;
  fk record;
  n  int := 0;
begin
  for r in select * from renommage_valeurs where genre = 'ref' loop
    -- Le code existe-t-il encore ?
    execute format('select 1 from public.%I where code = %L', r.objet, r.ancien);
    if not found then
      continue;
    end if;

    -- a. Dupliquer la ligne sous le nouveau code.
    execute format(
      'insert into public.%I select (x).* from (
         select (public.%I.*)::public.%I #= hstore(''code'', %L) as x
         from public.%I where code = %L) t
       on conflict (code) do nothing',
      r.objet, r.objet, r.objet, r.nouveau, r.objet, r.ancien);

    -- b. Basculer toutes les tables qui référencent ce code. Les clés étrangères
    --    sont lues dans le catalogue : aucune liste tenue à la main.
    for fk in
      select tc.relname as tbl, att.attname as col
      from pg_constraint co
      join pg_class tc on tc.oid = co.conrelid
      join pg_class rc on rc.oid = co.confrelid
      join pg_namespace ns on ns.oid = tc.relnamespace and ns.nspname = 'public'
      join pg_attribute att on att.attrelid = tc.oid and att.attnum = co.conkey[1]
      where co.contype = 'f' and rc.relname = r.objet
    loop
      execute format('update public.%I set %I = %L where %I = %L',
                     fk.tbl, fk.col, r.nouveau, fk.col, r.ancien);
    end loop;

    -- c. Retirer l'ancien.
    execute format('delete from public.%I where code = %L', r.objet, r.ancien);
    n := n + 1;
  end loop;
  raise notice '% code(s) de domaine traduit(s).', n;
end $refs$;

-- 3. Les corps de fonctions.
do $fonctions$
declare
  f       record;
  r       record;
  v_def   text;
  v_avant text;
  v_n     int := 0;
begin
  for f in
    select p.oid from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f'
      and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    for r in select distinct ancien, nouveau from renommage_valeurs loop
      v_def := replace(v_def, '''' || r.ancien || '''', '''' || r.nouveau || '''');
    end loop;
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% fonction(s) reconstruite(s).', v_n;
end $fonctions$;

drop table renommage_valeurs;
