# LuxRH — Assistant RH & Paie pour le droit du travail luxembourgeois

Deux interfaces, **un seul moteur de règles**. Contrats conformes, plannings validés en temps réel
contre le Code du travail, et un tableau de bord permanent des échéances et des seuils.

> L'application ne se contente pas de calculer : elle avertit et explique.
> Chaque alerte cite l'article qui la motive.

---

## Ce que contient ce dépôt

| Dossier | Contenu |
|---|---|
| [`luxrh/`](luxrh/) | Application **React + TypeScript** (Vite) — l'outil opérationnel |
| [`luxrh-py/`](luxrh-py/) | Application **Python + Streamlit** — mêmes écrans, même moteur |
| `luxrh/supabase/migrations/` | Le **moteur de règles** : 44 migrations PostgreSQL |
| `luxrh/supabase/functions/` | Edge Function de génération des contrats en PDF |
| `luxrh/tests/` | 154 vérifications exécutées contre l'API réelle |
| [`docs/`](docs/) | Couverture du droit du travail, choix de la base de données |
| `schema/` | Schémas Oracle et MySQL, dérivés du catalogue PostgreSQL |
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

Chaque application a son README : [React](luxrh/README.md) · [Streamlit](luxrh-py/README.md).

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

Ce que l'outil couvre du droit du travail et des conventions collectives, et **ce qu'il ne couvre
pas**, est établi table par table dans
[`docs/couverture-droit-du-travail.md`](docs/couverture-droit-du-travail.md). En bref : le cœur
calculable est là ; manquent le barème d'impôt (la table existe, elle est vide), l'historique des
taux CCSS, le reclassement professionnel, six congés légaux et huit clauses conventionnelles
courantes.

---

<sub>Dépôt initialement créé pour un test de Claude sur un système RH (`TestClaudeCode`).</sub>
