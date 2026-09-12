-- 86 — Les codes des catalogues passent au français
--
-- La migration 85 a traduit les énumérations et les tables de domaine `ref_*`.
-- Restaient les catalogues métier, dont le `code` est une donnée texte et non
-- une énumération : types d'absence, types de document, types d'avantage.
--
-- CE QUI N'EST PAS TRADUIT, ET POURQUOI
-- ======================================
--   `credits_impot.code` — CIS, CIM, CIHS, CI-CO2, CISSM sont les sigles
--     officiels de l'administration des contributions. Les traduire les rendrait
--     introuvables dans les textes qui les fondent.
--   `conventions_collectives.code` — HORECA-2025, SAS-2025 : identifiants
--     sectoriels, pas des libellés.
--   `zones_adresse.code` — LU, FR-57, BE-WLG : codes de région normalisés.
--   `parametres_legaux.cle_parametre` — cent clés techniques, citées telles
--     quelles dans les appels `fn_param_num('...')` du moteur et dans
--     `parametres_attendus`. Leur traduction est un lot à part entière, qui
--     demande de reprendre chaque appel : elle n'est pas faite ici plutôt que
--     d'être faite à moitié.
--
-- Aucune clé étrangère ne porte sur ces colonnes `code` — les rattachements se
-- font par UUID. La mise à jour est donc directe.

set search_path = public;

do $codes$
declare
  r record;
  n int := 0;
begin
  for r in
    select * from (values
      ('types_absence','accompaniment','accompagnement'),
      ('types_absence','annual_leave','conge_annuel'),
      ('types_absence','birth','naissance'),
      ('types_absence','compensatory','recuperation'),
      ('types_absence','death_child','deces_enfant'),
      ('types_absence','death_first_degree','deces_premier_degre'),
      ('types_absence','death_second_degree','deces_second_degre'),
      ('types_absence','death_spouse','deces_conjoint'),
      ('types_absence','family_reasons','raisons_familiales'),
      ('types_absence','marriage','mariage'),
      ('types_absence','maternity','maternite'),
      ('types_absence','moving','demenagement'),
      ('types_absence','parental','conge_parental'),
      ('types_absence','paternity','paternite'),
      ('types_absence','sick','maladie'),
      ('types_absence','unpaid','sans_solde'),
      ('types_absence','youth_leave','conge_jeunesse'),
      ('types_document','adem_declaration','declaration_adem'),
      ('types_document','criminal_record','casier_judiciaire'),
      ('types_document','final_settlement','solde_tout_compte'),
      ('types_document','leave_balance_statement','releve_solde_conges'),
      ('types_document','medical_certificate','certificat_medical'),
      ('types_document','medical_hiring','visite_medicale_embauche'),
      ('types_document','medical_periodic','visite_medicale_periodique'),
      ('types_document','signed_contract','contrat_signe'),
      ('types_document','tax_card','fiche_retenue_impot'),
      ('types_document','work_certificate','certificat_travail'),
      ('types_document','work_permit','autorisation_travail'),
      ('types_avantage','company_car','voiture_societe'),
      ('types_avantage','fuel_card','carte_carburant'),
      ('types_avantage','housing','logement'),
      ('types_avantage','interest_free_loan','pret_sans_interet'),
      ('types_avantage','meal_vouchers','titres_repas'),
      ('types_avantage','meals','repas'),
      ('types_avantage','phone','telephone'),
      ('types_avantage','supplementary_pension','pension_complementaire'),
      ('types_avantage','training','formation')
    ) as x(tbl, ancien, nouveau)
  loop
    execute format('update public.%I set code = %L where code = %L',
                   r.tbl, r.nouveau, r.ancien);
    if found then n := n + 1; end if;
  end loop;
  raise notice '% code(s) de catalogue traduit(s).', n;
end $codes$;

-- Les corps de fonctions qui citent ces codes en littéral.
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
    for r in select * from (values
      ('accompaniment','accompagnement'),('annual_leave','conge_annuel'),
      ('birth','naissance'),('death_child','deces_enfant'),
      ('death_first_degree','deces_premier_degre'),('death_second_degree','deces_second_degre'),
      ('death_spouse','deces_conjoint'),('family_reasons','raisons_familiales'),
      ('marriage','mariage'),('maternity','maternite'),('moving','demenagement'),
      ('parental','conge_parental'),('paternity','paternite'),('youth_leave','conge_jeunesse'),
      ('adem_declaration','declaration_adem'),('criminal_record','casier_judiciaire'),
      ('final_settlement','solde_tout_compte'),('leave_balance_statement','releve_solde_conges'),
      ('medical_certificate','certificat_medical'),('medical_hiring','visite_medicale_embauche'),
      ('medical_periodic','visite_medicale_periodique'),('signed_contract','contrat_signe'),
      ('tax_card','fiche_retenue_impot'),('work_certificate','certificat_travail'),
      ('work_permit','autorisation_travail'),('company_car','voiture_societe'),
      ('fuel_card','carte_carburant'),('housing','logement'),
      ('interest_free_loan','pret_sans_interet'),('meal_vouchers','titres_repas'),
      ('meals','repas'),('phone','telephone'),
      ('supplementary_pension','pension_complementaire'),('training','formation')
    ) as x(ancien, nouveau)
    loop
      v_def := replace(v_def, '''' || r.ancien || '''', '''' || r.nouveau || '''');
    end loop;
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% fonction(s) reconstruite(s).', v_n;
end $fonctions$;
