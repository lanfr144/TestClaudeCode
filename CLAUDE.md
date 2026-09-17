# LuxRH — contexte de travail

Assistant RH & paie pour le droit du travail luxembourgeois : contrats, plannings,
absences, conformité. Cahier des charges : `PRD_LuxRH.md`. Références visuelles :
`Design System LuxRH.dc.html`, `Maquettes LuxRH.dc.html`.

## Deux applications, un seul moteur

| | Chemin | Pile |
|---|---|---|
| Front web | `luxrh/` | React 18, TypeScript, Vite, Tailwind, TanStack Query |
| Front Python | `luxrh-py/` | Streamlit |
| Moteur & données | `luxrh/supabase/migrations/` | PostgreSQL, PL/pgSQL |

Les deux interfaces appellent **les mêmes fonctions serveur**. Elles ne sont pas
l'une la maquette de l'autre : ce qui est corrigé dans le moteur vaut pour les deux.

## Règles qui ne se négocient pas

1. **Aucun seuil, taux ou durée légale écrit en dur dans le code applicatif.**
   Ni en TypeScript, ni en Python. Tout vient de `parametres_legaux`, daté, sourcé.
   Une valeur écrite en dur est un bug, même si elle est juste aujourd'hui.

2. **Le serveur calcule, valide et décide ; le front affiche et saisit.**
   Une règle évaluée côté client serait fausse dès qu'un paramètre change, et
   invisible depuis l'autre application.

3. **Le référentiel est daté, jamais écrasé.** Chaque paramètre porte
   `debut_validite`/`fin_validite`, une `source` et une `reference_legale`. Une contrainte
   d'exclusion GiST interdit les périodes qui se chevauchent. Un recalcul de
   paie lit la valeur en vigueur *à la date du calcul*, pas la dernière connue.

4. **Hiérarchie des normes : loi → CCT → contrat.** La disposition la plus
   favorable au salarié l'emporte, et le moteur dit laquelle a gagné.

5. **Aucune erreur silencieuse.** Un calcul qui ne peut pas aboutir le dit et
   explique pourquoi. Pas de valeur par défaut qui masque une donnée manquante.

6. **RLS sur toutes les tables.** L'isolation entre organisations est imposée en
   base, jamais dans l'interface.

7. **Aucune valeur légale inventée.** Si une source publique fait défaut, le
   paramètre reste absent et signalé par `fn_referential_gaps` — un chiffre
   plausible mais faux est pire qu'un trou déclaré.

8. **Un salarié n'a qu'un seul contrat en cours.** Imposé en base par la
   contrainte d'exclusion `one_active_contract_at_a_time`. Toute modification —
   augmentation, passage à temps partiel, changement de poste — passe par
   `fn_amend_contract`, qui clôt le contrat courant et en crée un nouveau
   reprenant **toutes** ses clauses. Jamais d'`update` direct sur un contrat
   actif : un droit oublié dans un avenant est un droit perdu.

9. **Une adresse est vérifiée, ou déclarée invérifiée.** Le Luxembourg par le
   registre BD-Adresses (API geocode du geoportail, ou `addresses.csv` en vrac).
   Les frontaliers sont restreints aux zones de `zones_adresse` : Liège, Namur,
   Luxembourg (BE) ; départements 54 et 57 (FR) ; Rhénanie-Palatinat et Sarre
   (DE). `fn_validate_address` répond `ok`, `outside` ou `unknown` — jamais un
   booléen, parce qu'« on ne sait pas » n'est pas « non ».

10. **Jamais de `count(*)` pour tester une existence.** `exists` s'arrête au
    premier résultat ; `count(*)` les compte tous avant de conclure. Sur Oracle,
    `and rownum <= 1` là où un comptage doit malgré tout rester.

11. **Un déclencheur ne vérifie que les lignes écrites.** Jamais la table
    entière. Sur Oracle, déclencheur composé : `after each row` collecte les
    identifiants, `after statement` les vérifie — c'est aussi ce qui lève
    ORA-04091 proprement.

12. **Un index posé doit servir une requête réelle.** Un index fonctionnel sur
    `upper(nom)` sert l'égalité et le préfixe, pas la recherche infixe `%x%` —
    celle-ci demande un index trigramme. Poser le premier en croyant servir la
    seconde donne l'illusion de la performance. Les index de recherche plein
    texte attendent un besoin métier avéré.

## Ce dépôt est public

`github.com/lanfr144/TestClaudeCode`. Aucun identifiant, aucune clé, aucune
référence de projet ne doit y être commitée. Les secrets vivent dans
`luxrh/.env.local` (ignoré par git) et sont lus par les deux applications.

## Commandes

```bash
cd luxrh && npm run dev          # front React        (5173)
cd luxrh && npm run build        # doit rester à 0 erreur TypeScript
cd luxrh && npm test             # 154 vérifications, portabilité comprise
cd luxrh-py && .venv/Scripts/python -m streamlit run app.py   # front Streamlit (8501)
python tools/emit_portable_schema.py schema/catalogue.json schema/   # schemas Oracle / MySQL
```

L'application Python accepte `-- --db supabase|oracle|mysql`. Seul PostgreSQL
porte le moteur ; sur les autres, une evaluation de regle leve `EngineUnavailable`.
Voir `docs/bases-de-donnees.md` et `docs/couverture-droit-du-travail.md`.

Le `.venv` de `luxrh-py` est créé avec `--system-site-packages` : l'environnement
Python global héberge l'installation Airflow de l'utilisateur et **ne doit pas
être modifié**. Avant d'installer un programme (et non un paquet), demander.

## Conventions rencontrées

- **Écriture de fichiers** : passer par l'outil Write ou un script Python. Les
  heredocs Bash mangent les antislashs et échouent sur les gros contenus.
- **`supabase-js`** : au-delà de deux niveaux de jointure l'inférence sature et
  retombe sur `never`. Les requêtes de détail portent un type de ligne explicite
  (`unwrap<CompanyDetailRow>(...)`), et `.select()` prend un littéral, jamais une
  concaténation — sinon le typage est perdu.
- **Les extensions vivent dans `extensions`**, jamais dans `public` : `pgcrypto`, `dblink`
  et, depuis la migration 75, `btree_gist`. Une extension dans le schéma applicatif y expose
  ses routines de support, exécutables par `PUBLIC`. Qualifier les appels à `pgcrypto`.
- **Migrations** : numérotées et jamais réécrites une fois appliquées.
- Commentaires en français, comme le reste du code.
- **Toute table et toute colonne portent un commentaire.** 85 tables, 958 colonnes, 100 %.
  Une colonne ajoutée sans commentaire est signalée par `verifier_coherence.py`.
- **`fin_validite` n'est jamais nulle, et le code ne doit pas faire semblant du contraire.**
  Une validité ouverte porte la sentinelle **`2037-12-31`**, un début de toujours
  `1970-01-01`. Borne basse incluse, borne haute exclue.

  Il n'existe **qu'une seule date sentinelle dans tout le projet**, schémas Oracle et MySQL
  dérivés compris. Pas de `9999-12-31` : 2037-12-31 tient dans un `time_t` 32 bits signé, et
  deux sentinelles concurrentes finissent toujours par être comparées l'une à l'autre.

  Proscrits, partout : `fin_validite is null`, `coalesce(fin_validite, …)`,
  `nvl(FIN_VALIDITE, …)`, `!row.fin_validite ||`. Ces formes sont mortes depuis la
  migration 70 — elles ne protègent de rien, elles font croire au lecteur que la colonne
  admet des nuls, et elles privent le planificateur d'un parcours d'index. Une colonne
  `not null` dont tout le code se méfie n'est pas un invariant : c'est une convention à
  laquelle personne ne croit. `verifier_coherence.py` les signale désormais.

  Côté React, `estEnVigueur()` et `sansFin()` de `src/lib/format.ts` — leurs signatures
  **exigent** les deux bornes, pour que le compilateur impose l'invariant à l'appelant.
  Côté Streamlit, `sans_fin()` de `luxrh/design.py`.

  Restent légitimement nullables, et doivent le rester : `contrats.date_fin`,
  `statuts_salarie.date_fin`, `sanctions_salarie.effet_au`. Un contrat à durée indéterminée
  n'a pas de fin ; lui en inventer une reviendrait à dire que tout CDI s'arrête en 2037.
- **Les horodatages de migration ne se choisissent pas.** La plateforme attribue le sien à
  l'application ; c'est le **nom** qui identifie une migration. `dump_migrations.py` renomme
  les fichiers sur la version appliquée — il ne les réécrit jamais.
