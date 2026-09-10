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
   Ni en TypeScript, ni en Python. Tout vient de `legal_parameters`, daté, sourcé.
   Une valeur écrite en dur est un bug, même si elle est juste aujourd'hui.

2. **Le serveur calcule, valide et décide ; le front affiche et saisit.**
   Une règle évaluée côté client serait fausse dès qu'un paramètre change, et
   invisible depuis l'autre application.

3. **Le référentiel est daté, jamais écrasé.** Chaque paramètre porte
   `valid_from`/`valid_to`, une `source` et une `legal_ref`. Une contrainte
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
- **pgcrypto** vit dans le schéma `extensions` : qualifier les appels.
- **Migrations** : numérotées et jamais réécrites une fois appliquées.
- Commentaires en français, comme le reste du code.
