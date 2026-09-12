-- 76 — Les tables passent au français
--
-- Le dernier chantier structurel du projet. 55 tables renommées ; 18 l'étaient
-- déjà (`adresses_salarie`, `fiche_sante`, `ref_*`, `cct_regle_prime`…).
-- Les noms viennent de `tools/renommage.py`, qui est la pièce à relire : ce
-- fichier ne fait que les appliquer.
--
-- LE PIÈGE, ET POURQUOI TOUT TIENT DANS UNE SEULE MIGRATION
-- ==========================================================
-- PostgreSQL stocke le corps d'une fonction PL/pgSQL comme du **texte**. Il ne
-- suit donc pas un renommage de table. Les vues et les politiques RLS, elles,
-- sont conservées sous forme analysée et suivent automatiquement — ce qui rend
-- le piège d'autant plus traître : on renomme, tout semble tenir, et les cent
-- cinquante fonctions du moteur tombent au premier appel.
--
-- Les trois étapes sont donc indissociables :
--   1. renommer les tables ;
--   2. reconstruire chaque fonction depuis sa propre définition, noms substitués ;
--   3. renommer index, séquences et contraintes qui portent l'ancien nom.
--
-- POURQUOI LA SUBSTITUTION TEXTUELLE EST SÛRE ICI
-- ================================================
-- `\m` et `\M` sont les bornes de mot de PostgreSQL, et le souligné y compte
-- comme une lettre. `\mcontracts\M` ne peut donc pas mordre à l'intérieur de
-- `fn_contract_compliance` ni de `contract_id` : seul le mot entier correspond.
-- C'est exactement la propriété qu'il faut pour substituer des identifiants.
--
-- CE QU'ELLE NE TOUCHE PAS
-- =========================
-- Les noms de fonctions. Les deux interfaces les appellent par leur nom ; les
-- renommer casserait tout sans bénéfice. Elles restent `fn_*`, préfixe qui n'est
-- ni anglais ni français.
--
-- RÉVERSIBLE
-- ==========
-- Un renommage s'annule par le renommage inverse. En cas de doute, inverser les
-- deux colonnes de `renommage_en_cours` et rejouer le même bloc.
--
-- À FAIRE DANS LE MÊME MOUVEMENT
-- ===============================
-- Le code des deux interfaces doit être réécrit avec les mêmes noms, sans quoi
-- l'application ne répond plus. C'est ce que fait :
--
--     luxrh-py/.venv/Scripts/python tools/renommer.py tables --ecrire
--
-- puis la régénération des types TypeScript et les 190 vérifications.

set search_path = public;

-- La correspondance, écrite une seule fois.
create table if not exists renommage_en_cours (ancien text primary key, nouveau text not null);
truncate renommage_en_cours;
insert into renommage_en_cours (ancien, nouveau) values
  ('organizations', 'organisations'),
  ('companies', 'societes'),
  ('departments', 'services'),
  ('profiles', 'profils'),
  ('app_users', 'comptes'),
  ('user_roles', 'roles_compte'),
  ('app_secrets', 'secrets_application'),
  ('employees', 'salaries'),
  ('employee_children', 'enfants_salarie'),
  ('employee_disabilities', 'handicaps_salarie'),
  ('employee_statuses', 'statuts_salarie'),
  ('employee_tax_cards', 'fiches_retenue_impot'),
  ('employee_sanctions', 'sanctions_salarie'),
  ('sanction_categories', 'categories_sanction'),
  ('sanction_types', 'types_sanction'),
  ('contracts', 'contrats'),
  ('contract_amendments', 'avenants_contrat'),
  ('contract_pay_components', 'elements_remuneration'),
  ('contract_terminations', 'ruptures_contrat'),
  ('contract_collective_agreements', 'conventions_du_contrat'),
  ('probation_extensions', 'prolongations_essai'),
  ('interim_agencies', 'agences_interim'),
  ('collective_agreements', 'conventions_collectives'),
  ('company_collective_agreements', 'conventions_de_la_societe'),
  ('cba_rules', 'regles_convention'),
  ('cba_salary_grids', 'grilles_salaires_convention'),
  ('schedules', 'plannings'),
  ('shifts', 'creneaux'),
  ('shift_templates', 'modeles_creneau'),
  ('time_entries', 'releves_temps'),
  ('reference_periods', 'periodes_reference'),
  ('overtime_requests', 'demandes_heures_sup'),
  ('public_holidays', 'jours_feries'),
  ('absence_types', 'types_absence'),
  ('absence_entitlements', 'droits_absence'),
  ('premiums', 'primes'),
  ('benefit_types', 'types_avantage'),
  ('meal_voucher_grants', 'attributions_titres_repas'),
  ('legal_parameters', 'parametres_legaux'),
  ('expected_parameters', 'parametres_attendus'),
  ('tax_brackets', 'tranches_impot'),
  ('tax_credits', 'credits_impot'),
  ('company_rate_periods', 'periodes_taux_societe'),
  ('company_accident_claims', 'sinistres_accident_societe'),
  ('company_financials', 'donnees_financieres_societe'),
  ('headcount_snapshots', 'releves_effectif'),
  ('compliance_alerts', 'alertes_conformite'),
  ('document_types', 'types_document'),
  ('address_zones', 'zones_adresse'),
  ('address_checks', 'controles_adresse'),
  ('client_sites', 'sites_client'),
  ('travel_distances', 'distances_trajet'),
  ('audit_log', 'journal_ecritures'),
  ('data_access_log', 'journal_acces'),
  ('export_log', 'journal_exports');

-- 1. Les tables.
do $tables$
declare r record;
begin
  for r in select * from renommage_en_cours order by ancien loop
    if exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
                where n.nspname = 'public' and c.relkind = 'r' and c.relname = r.ancien) then
      execute format('alter table public.%I rename to %I', r.ancien, r.nouveau);
    end if;
  end loop;
end $tables$;

-- 2. Les corps de fonctions. Voir l'en-tête : c'est l'étape sans laquelle tout casse.
do $renommage$
declare
  f          record;
  p          record;
  v_def      text;
  v_avant    text;
  v_touchees int := 0;
begin
  for f in
    select p2.oid from pg_proc p2
    join pg_namespace n on n.oid = p2.pronamespace and n.nspname = 'public'
    where p2.prokind = 'f'
      and not exists (select 1 from pg_depend d where d.objid = p2.oid and d.deptype = 'e')
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    for p in select * from renommage_en_cours loop
      v_def := regexp_replace(v_def, '\m' || p.ancien || '\M', p.nouveau, 'g');
    end loop;
    if v_def is distinct from v_avant then
      execute v_def;
      v_touchees := v_touchees + 1;
    end if;
  end loop;
  raise notice '% fonction(s) reconstruite(s).', v_touchees;
end $renommage$;

-- 3. Index, séquences et contraintes portant encore l'ancien nom.
--    Sans ce passage, une violation de clé primaire sur `salaries` annoncerait
--    « employees_pkey » : le message que voit l'utilisateur resterait en anglais.
do $objets$
declare
  r         record;
  v_nouveau text;
begin
  for r in
    select p.ancien, p.nouveau, c.relname as objet, c.relkind
    from renommage_en_cours p
    join pg_class c on c.relname like p.ancien || '\_%'
    join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
    where c.relkind in ('i', 'S')
  loop
    v_nouveau := r.nouveau || substr(r.objet, length(r.ancien) + 1);
    execute format('alter %s public.%I rename to %I',
                   case r.relkind when 'S' then 'sequence' else 'index' end,
                   r.objet, v_nouveau);
  end loop;

  for r in
    select p.ancien, p.nouveau, co.conname as objet, t.relname as tbl
    from renommage_en_cours p
    join pg_class t on t.relname = p.nouveau
    join pg_namespace n on n.oid = t.relnamespace and n.nspname = 'public'
    join pg_constraint co on co.conrelid = t.oid
   where co.conname like p.ancien || '\_%'
     and co.contype in ('c', 'f')
  loop
    v_nouveau := r.nouveau || substr(r.objet, length(r.ancien) + 1);
    execute format('alter table public.%I rename constraint %I to %I',
                   r.tbl, r.objet, v_nouveau);
  end loop;
end $objets$;

drop table renommage_en_cours;
