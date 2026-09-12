-- 70 — `valid_to` cesse d'être nullable sur les treize tables héritées
--
-- Pourquoi un NULL ne convient pas pour dire « toujours en vigueur »
-- ------------------------------------------------------------------
-- Toute la bitemporalité du moteur repose sur un couple `valid_from` / `valid_to`.
-- Les tables écrites récemment portent `fin_validite date not null default
-- '2037-12-31'` ; les treize plus anciennes portaient `valid_to date` nullable,
-- où NULL signifiait « pas de fin connue ».
--
-- Trois raisons de ne pas garder ce NULL.
--
-- 1. **Il oblige chaque lecture à le prévoir.** Toute condition devient
--    `valid_to is null or valid_to > la_date`. Celui qui oublie la première
--    moitié n'obtient pas une erreur : il obtient la ligne en vigueur en moins,
--    silencieusement. C'est la règle 5 du CLAUDE.md prise à revers.
--
-- 2. **Il ne s'indexe pas comme une borne.** Un `daterange(valid_from, valid_to)`
--    non borné à droite se compare, mais la sélectivité que le planificateur en
--    tire est mauvaise.
--
-- 3. **Il ne se porte pas.** Oracle ne distingue pas la chaîne vide du NULL ;
--    un modèle qui fait porter du sens au NULL se traduit mal.
--
-- La date sentinelle est **2037-12-31**, demandée et retenue pour tout le projet :
-- elle tient dans un `time_t` 32 bits signé, ce que 9999-12-31 ne fait pas.
--
-- Ce que cette migration ne change pas
-- -------------------------------------
-- La **sémantique des comparaisons**. `valid_to` reste une borne haute exclusive :
-- une ligne est en vigueur le jour J si `valid_from <= J and valid_to > J`. Les
-- conditions existantes de la forme `valid_to is null or valid_to > J` continuent
-- de fonctionner telles quelles — la première moitié devient simplement toujours
-- fausse. Aucune fonction du moteur n'est donc à reprendre.
--
-- Le front React, lui, l'est : six endroits sélectionnaient la version en vigueur
-- par `!p.valid_to` **seul**, sans la comparaison de repli. Ce test devient
-- toujours faux. Corrigé dans le même lot (`estEnVigueur` de `src/lib/format.ts`).

set search_path = public;

do $$
declare
  t          text;
  v_tables   text[] := array[
    'absence_entitlements', 'collective_agreements', 'company_collective_agreements',
    'company_rate_periods', 'contract_collective_agreements', 'contract_pay_components',
    'employee_disabilities', 'employee_tax_cards', 'legal_parameters',
    'sanction_categories', 'sanction_types', 'tax_brackets', 'tax_credits'];
  v_apres    bigint;
  v_comblees bigint;
  v_total    bigint := 0;
begin
  -- Garde-fou. Remplacer NULL par 2037-12-31 **rétrécit** l'intervalle de validité.
  -- Un rétrécissement ne peut pas créer de chevauchement — les contraintes GiST
  -- restent donc satisfaites. Mais si une ligne commençait après la sentinelle,
  -- elle deviendrait vide, et la contrainte `valid_to > valid_from` la rejetterait.
  -- Mieux vaut s'arrêter ici que laisser passer une ligne invalide.
  foreach t in array v_tables loop
    execute format('select count(*) from %I where valid_from >= date ''2037-12-31''', t)
      into v_apres;
    if v_apres > 0 then
      raise exception 'La table % porte % ligne(s) dont la validité commence après la '
                      'date sentinelle 2037-12-31. Les traiter avant de poser not null : '
                      'elles deviendraient des intervalles vides.', t, v_apres;
    end if;
  end loop;

  foreach t in array v_tables loop
    execute format('update %I set valid_to = date ''2037-12-31'' where valid_to is null', t);
    get diagnostics v_comblees = row_count;
    v_total := v_total + v_comblees;

    execute format('alter table %I alter column valid_to set default date ''2037-12-31''', t);
    execute format('alter table %I alter column valid_to set not null', t);

    -- `valid_from` était déjà not null partout ; seul le défaut manquait. Deux
    -- tables portaient 1900-01-01 comme sentinelle de début : même intention,
    -- autre valeur. On aligne sur 1970-01-01 pour tout le projet.
    execute format('alter table %I alter column valid_from set default date ''1970-01-01''', t);
    execute format('update %I set valid_from = date ''1970-01-01'' '
                   'where valid_from = date ''1900-01-01''', t);

    -- Défense de troisième niveau : un intervalle vide ou inversé n'a pas de sens.
    -- La contrainte porte sur une borne, pas sur un ensemble de valeurs — ce n'est
    -- donc pas le check-liste que le projet remplace par des tables de domaine.
    execute format('alter table %I drop constraint if exists %I', t, t || '_periode_valide');
    execute format('alter table %I add constraint %I check (valid_to > valid_from)',
                   t, t || '_periode_valide');
  end loop;

  raise notice '% ligne(s) sans fin de validité comblée(s) sur % table(s).',
               v_total, cardinality(v_tables);
end $$;

-- Le commentaire dit la convention, pour qui lit la colonne sans lire cette migration.
do $$
declare t text;
begin
  foreach t in array array[
    'absence_entitlements', 'collective_agreements', 'company_collective_agreements',
    'company_rate_periods', 'contract_collective_agreements', 'contract_pay_components',
    'employee_disabilities', 'employee_tax_cards', 'legal_parameters',
    'sanction_categories', 'sanction_types', 'tax_brackets', 'tax_credits'] loop
    execute format(
      'comment on column %I.valid_to is %L', t,
      'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. '
      'Jamais nulle — une validité sans fin connue porte la date sentinelle '
      '2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour '
      'où la ligne ne vaut plus, puis insérer la suivante à cette même date.');
    execute format(
      'comment on column %I.valid_from is %L', t,
      'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. '
      'Une validité de toujours porte la date sentinelle 1970-01-01.');
  end loop;
end $$;
