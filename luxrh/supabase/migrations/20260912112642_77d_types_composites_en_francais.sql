-- 77d — Les types composites avaient été oubliés
--
-- La boucle de renommage des colonnes de la migration 77 filtrait sur
-- `relkind = 'r'`, c'est-à-dire les tables ordinaires. Les **types composites**
-- portent eux aussi des attributs, sous `relkind = 'c'`, et ils ont donc été
-- ignorés — alors que les corps de fonctions qui les remplissent, eux, ont bien
-- été réécrits en français.
--
-- Résultat : `record "sortie" has no field "nom"`. La fonction pipelinée
-- `fn_employee_rows` affectait `sortie.nom` à un type qui déclarait encore
-- `last_name`.
--
-- Ce sont les 190 vérifications qui l'ont montré. Ni le renommage, ni la
-- compilation TypeScript ne pouvaient le voir : le type composite n'existe que
-- côté serveur, et l'erreur n'apparaît qu'à l'exécution de la fonction.
--
-- Seuls les attributs à nom composé sont traités ici. `email`, `phone`,
-- `residency`, `qualification` et `iban` restent en anglais : ce sont des noms
-- simples, qui relèvent du troisième bloc du renommage.

set search_path = public;

-- 1. Les attributs des deux types composites.
alter type employee_row rename attribute employee_id    to salarie_id cascade;
alter type employee_row rename attribute company_id     to societe_id cascade;
alter type employee_row rename attribute department_id  to service_id cascade;
alter type employee_row rename attribute first_name     to prenom cascade;
alter type employee_row rename attribute last_name      to nom cascade;
alter type employee_row rename attribute birth_date     to date_naissance cascade;
alter type employee_row rename attribute job_title      to intitule_poste cascade;
alter type employee_row rename attribute contract_kind  to genre_contrat cascade;
alter type employee_row rename attribute start_date     to date_debut cascade;
alter type employee_row rename attribute end_date       to date_fin cascade;
alter type employee_row rename attribute monthly_gross  to brut_mensuel cascade;
alter type employee_row rename attribute weekly_hours   to heures_hebdomadaires cascade;
alter type employee_row rename attribute national_id    to matricule_national cascade;

alter type time_entry_row rename attribute employee_id     to salarie_id cascade;
alter type time_entry_row rename attribute entry_date      to date_releve cascade;
alter type time_entry_row rename attribute worked_hours    to heures_travaillees cascade;
alter type time_entry_row rename attribute overtime_hours  to heures_supplementaires cascade;
alter type time_entry_row rename attribute night_hours     to heures_nuit cascade;
alter type time_entry_row rename attribute sunday_hours    to heures_dimanche cascade;
alter type time_entry_row rename attribute holiday_hours   to heures_ferie cascade;
alter type time_entry_row rename attribute is_validated    to valide cascade;

-- 2. Les types eux-mêmes. Un renommage de type conserve l'identifiant interne :
--    les fonctions qui le déclarent comme type de retour suivent sans être
--    touchées. Seuls les corps qui le nomment en clair sont à reprendre.
alter type employee_row    rename to ligne_salarie;
alter type time_entry_row  rename to ligne_releve_temps;

-- 3. Les corps qui nommaient l'ancien type.
do $corps$
declare
  f        record;
  v_def    text;
  v_avant  text;
  v_n      int := 0;
begin
  for f in
    select p.oid from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f'
      and (p.prosrc like '%employee_row%' or p.prosrc like '%time_entry_row%')
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    v_def := regexp_replace(v_def, '\memployee_row\M',   'ligne_salarie', 'g');
    v_def := regexp_replace(v_def, '\mtime_entry_row\M', 'ligne_releve_temps', 'g');
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% corps de fonction repris.', v_n;
end $corps$;
