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
| `luxrh/supabase/migrations/` | Le **moteur de règles** : 42 migrations PostgreSQL |
| `luxrh/supabase/functions/` | Edge Function de génération des contrats en PDF |
| `luxrh/tests/` | 128 vérifications exécutées contre l'API réelle |
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

**Reste ouvert** : le calcul de paie brut → net (V2 du PRD, dont le socle est posé), la détection
des recalculs après chargement rétroactif d'un paramètre, la facturation de la fiduciaire, l'import
CSV de l'existant et les exports comptables.

Le détail — y compris ce que le référentiel ne couvre pas encore et pourquoi aucune valeur n'a été
inventée — est dans le [README de l'application React](luxrh/README.md).

---

<sub>Dépôt initialement créé pour un test de Claude sur un système RH (`TestClaudeCode`).</sub>
