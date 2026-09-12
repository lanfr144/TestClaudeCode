# LuxRH — Assistant RH & Paie pour le droit du travail luxembourgeois

Deux interfaces, **un seul moteur de règles**. Contrats conformes, plannings validés en temps réel
contre le Code du travail, et un tableau de bord permanent des échéances et des seuils.

> L'application ne se contente pas de calculer : elle avertit et explique.
> Chaque alerte cite l'article qui la motive.

**📚 La documentation complète est dans [`docs/index.md`](docs/index.md)** — présentation, démarrage,
architecture, moteur de règles, inventaire des fonctions RPC, guide utilisateur, modèle de données,
tests et conventions de contribution. C'est le point d'entrée à donner à toute nouvelle personne
sur le projet.

---

## Ce que contient ce dépôt

| Dossier | Contenu |
|---|---|
| [`luxrh/`](luxrh/) | Application **React + TypeScript** (Vite) — l'outil opérationnel |
| [`luxrh-py/`](luxrh-py/) | Application **Python + Streamlit** — mêmes écrans, même moteur |
| `luxrh/supabase/migrations/` | Le **moteur de règles** : 60 fichiers de migration, 107 fonctions sur la base déployée. Les migrations 46 à 54 sont **appliquées** ; l'historique de la base a divergé du dépôt sur les migrations 43-45 (numérotation et contenu à réconcilier) — détail dans [`docs/ecarts-a-corriger.md`](docs/ecarts-a-corriger.md) |
| `luxrh/supabase/functions/` | Edge Functions de génération des contrats en PDF (`contract-pdf`) et de calcul de distance (`travel-distance`, migration 52) |
| `luxrh/tests/` | 6 suites, 190 vérifications exécutées contre l'API réelle |
| [**`docs/`**](docs/index.md) | **Toute la documentation du projet** — sommaire dans [`docs/index.md`](docs/index.md) |
| `schema/` | Schémas Oracle et MySQL, dérivés du catalogue PostgreSQL — sauf `oracle_audit_pipeline.sql`, écrit et maintenu à la main |
| `tools/` | Émetteur de schéma portable |
| `PRD_LuxRH.md` | Le cahier des charges d'origine |
| `Design System LuxRH.dc.html` · `Maquettes LuxRH.dc.html` | Design system et 14 maquettes hi-fi |

---

## Le principe qui structure tout

Le front **affiche et saisit** ; le serveur **calcule, valide et décide**.

Aucun seuil, aucun taux, aucune durée légale n'est écrit dans le code applicatif — ni en
TypeScript, ni en Python. Les deux interfaces lisent ce que le moteur PostgreSQL leur renvoie, y
compris le texte des messages et les références d'articles. Tout paramètre légal vit en base avec
sa plage de validité, sa source et son article, sous contrainte d'exclusion qui interdit tout
chevauchement de périodes.

C'est aussi ce qui rend les deux applications réellement équivalentes : elles ne partagent pas du
code, elles partagent des **règles**.

---

## Démarrer

```bash
# Front React
cd luxrh && npm install && npm run dev        # http://localhost:5173

# Application Streamlit
cd luxrh-py && .venv/Scripts/python -m streamlit run app.py   # http://localhost:8501
```

L'application Python accepte le choix de la base par argument :

```bash
.venv/Scripts/python -m streamlit run app.py -- --db oracle --dsn hote:1521/XEPDB1 --user luxrh
```

Supabase, Oracle et MySQL portent les données ; **seul PostgreSQL porte le moteur de règles**,
qui est écrit en PL/pgSQL. Sur les deux autres, une évaluation de règle échoue en le disant
plutôt que de rendre une valeur vraisemblable. Le détail, et les limites à connaître — dont
l'absence d'isolation par ligne sur MySQL — sont dans [`docs/bases-de-données.md`](docs/bases-de-donnees.md).

Chaque application a son README : [React](luxrh/README.md) · [Streamlit](luxrh-py/README.md). Le
détail de l'installation, des commandes et du dépannage est dans
[`docs/demarrage.md`](docs/demarrage.md).

### Configuration

`luxrh/.env.local` (ignoré par Git) porte l'URL du projet Supabase, sa clé publiable et les mots de
passe des comptes de démonstration. Partez de `luxrh/.env.example`.

**Ce dépôt est public : aucun identifiant ne doit y être écrit.** Les suites de tests lisent les
mots de passe depuis l'environnement et refusent de démarrer s'ils manquent.

---

## État

Le **périmètre MVP du PRD** est couvert : sociétés & employés, référentiel légal daté, conventions
collectives multiples, contrats, planning & registre du temps, congés & maladies, moteur de
vigilance, espace salarié.

Deux révisions fonctionnelles ont été intégrées depuis : historisation des taux société, validation
complète du matricule CCSS, typologie de contrats étendue, statuts protégés, catalogue de congés
extraordinaires daté, documents à validité, travailleurs handicapés, enfants avec option de
confidentialité, accord préalable sur les heures supplémentaires, chèques-repas, primes et leurs
plafonds légaux.

S'y ajoutent la **portabilité** — export et rechargement des données personnelles, du dossier
d'une société, de la fiduciaire entière et du référentiel — et le **choix de la base par
argument**.

**Reste ouvert** : le calcul de paie brut → net (V2 du PRD, dont le socle est posé), la détection
des recalculs après chargement rétroactif d'un paramètre, la facturation de la fiduciaire, l'import
CSV de l'existant et les exports comptables.

**Appliquées le 10 septembre 2026** : les migrations 46 à 54 durcissent les droits d'exécution,
commentent le schéma, posent des contraintes structurelles, ajoutent un journal des accès RGPD
(`data_access_log`, `fn_person_access_report`), corrigent un repli silencieux de `fn_company_rates`,
introduisent une lecture auditée pipelinée (`fn_employee_rows`, `fn_time_entry_rows`) et posent les
lieux d'intervention avec l'indemnisation des dépassements kilométriques. Deux régressions
introduites par cette série (une ambiguïté de relation PostgREST, un littéral de tableau mal typé)
ont été attrapées par la suite de tests et corrigées par les migrations 53 et 54. Après application :
154 tests passent, 0 échec ; `npm run build` reste à 0 erreur TypeScript ; voir
[`docs/ecarts-a-corriger.md`](docs/ecarts-a-corriger.md).

Ce que l'outil couvre du droit du travail et des conventions collectives, et **ce qu'il ne couvre
pas**, est établi table par table dans
[`docs/couverture-droit-du-travail.md`](docs/couverture-droit-du-travail.md). En bref : le cœur
calculable est là ; manquent le barème d'impôt (la table existe, elle est vide), l'historique des
taux CCSS, le reclassement professionnel, six congés légaux et huit clauses conventionnelles
courantes.

---

## Pour aller plus loin

| Question | Document |
|---|---|
| Que fait l'application, et que ne fait-elle pas ? | [`docs/presentation.md`](docs/presentation.md) |
| Comment l'installer et la lancer ? | [`docs/demarrage.md`](docs/demarrage.md) |
| Comment est-elle construite ? | [`docs/architecture.md`](docs/architecture.md) |
| Comment décide-t-elle ? | [`docs/moteur-de-regles.md`](docs/moteur-de-regles.md) |
| Quelles fonctions puis-je appeler ? | [`docs/api-serveur.md`](docs/api-serveur.md) |
| Comment s'en sert-on, écran par écran ? | [`docs/guide-utilisateur.md`](docs/guide-utilisateur.md) |
| Quelles tables, quelles relations ? | [`docs/modele-de-donnees.md`](docs/modele-de-donnees.md) |
| Que vérifient les tests ? | [`docs/tests-et-qualite.md`](docs/tests-et-qualite.md) |
| Quelles conventions avant de coder ? | [`docs/contribuer.md`](docs/contribuer.md) |

---

<sub>Dépôt initialement créé pour un test de Claude sur un système RH (`TestClaudeCode`).</sub>
