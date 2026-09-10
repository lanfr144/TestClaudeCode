# LuxRH — Assistant RH & Paie pour le droit du travail luxembourgeois

Implémentation du périmètre **MVP (V1)** du PRD v1.0 : sociétés & employés, référentiel légal daté,
CCT paramétrable, contrats, planning & registre du temps, congés & maladies, moteur de vigilance,
espace salarié.

> **L'application ne se contente pas de calculer, elle avertit et explique.**
> Chaque alerte, chaque blocage et chaque valeur retenue porte sa base légale.

---

## Démarrer

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # tsc --noEmit && vite build — 0 erreur
```

Node 20+ requis. Une **seconde application, en Python avec Streamlit**, couvre les mêmes écrans
et le même moteur : voir [`../luxrh-py`](../luxrh-py/README.md).

`.env.local` contient déjà l'URL et la clé publiable du projet Supabase. Pour un autre projet,
copiez `.env.example` et renseignez `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`.

### Comptes de démonstration

| Rôle | Adresse | Ce qu'il montre |
|---|---|---|
| Gestionnaire de fiduciaire | `demo@luxrh.lu` | 4 dossiers clients, 323 salariés, tous les écrans |
| Salarié (Marta Ferreira) | `marta@luxrh.lu` | L'espace salarié mobile, cloisonné |
| Autre espace de travail | `autre@luxrh.lu` | Ne voit rien du premier — l'isolation en action |

Les mots de passe ne sont **pas dans le dépôt** : ce dépôt est public. Ils vivent dans
`.env.local`, ignoré par Git, sous les clés `LUXRH_MANAGER_PASSWORD`,
`LUXRH_EMPLOYEE_PASSWORD` et `LUXRH_OTHER_PASSWORD` — voir `.env.example`. Les tests les
lisent depuis là et refusent de démarrer si elles manquent.

Ce sont des **comptes de démonstration, à supprimer avant toute mise en production**.

Depuis un espace vide, le bouton **« Charger le jeu de démonstration »** (écran *Sociétés*) appelle
`fn_seed_demo()` et crée le même jeu de données.

### Tests

```bash
npm test
```

128 vérifications sans dépendance de test, exécutées contre l'API réelle :

| Suite | Couvre |
|---|---|
| `tests/api.test.mjs` | Chaque requête et chaque RPC utilisées par le front, avec leurs jointures |
| `tests/rls.test.mjs` | Cloisonnement entre espaces, espace salarié, fonctions internes non exposées |
| `tests/publication.test.mjs` | Refus de publication sur violation bloquante, puis publication après correction |
| `tests/domain.test.mjs` | Handicap, confidentialité des enfants, accord préalable sur les heures supplémentaires, chèques-repas, protections de fin de contrat, plafonds de primes |

La suite `publication` modifie puis **restaure** le jeu de démonstration.

## Ce qui reste à faire

Ces points de la révision v1.1 sont **spécifiés et non implémentés** :

| Sujet | État |
|---|---|
| Calcul de paie brut → net | Le socle est posé (barèmes d'impôt, crédits, avantages, cotisations et taux société datés) ; le moteur de calcul reste à écrire — c'est la V2 du PRD |
| Recalcul après chargement rétroactif d'un paramètre | Les deux dates sont conservées ; la détection des périodes à reprendre reste à écrire |
| Facturation de la fiduciaire | Non commencé : temps passé par dossier et prix fixe indexé par prestation |
| Import CSV de l'existant | Non commencé : tables de staging et rapprochement |
| Exports comptables BOB / Sage / Odoo | Non commencé, comme signalé dans la révision |
| Barèmes officiels manquants | Structure prête, valeurs à charger depuis les sources officielles (voir *Couverture du référentiel*) |

Les écrans dédiés aux nouvelles capacités sont partiels : la fiche employé expose les statuts et
protections, la fiche société l'historique des taux, le référentiel sa couverture. Les avantages en
nature, la sinistralité et les barèmes fiscaux sont accessibles par le moteur mais n'ont pas encore
d'écran de saisie.

---

## Architecture

| Couche | Choix |
|---|---|
| Front | React 18 + TypeScript, Vite |
| État serveur | TanStack Query |
| UI | Tailwind, tokens du Design System LuxRH |
| Base de données | Supabase / PostgreSQL 17 (`eu-west-1`) |
| Authentification | Supabase Auth |
| Autorisation | Row Level Security, par société et par rôle |
| Logique métier | Fonctions PostgreSQL — jamais dans le navigateur |
| Documents | Supabase Storage, bucket privé `documents` |
| PDF | Edge Function `contract-pdf` |

### Le principe qui structure tout le code

Le front **affiche et saisit** ; le serveur **calcule, valide et décide**. Aucun seuil, aucun taux,
aucune durée légale n'est écrit dans le code TypeScript : le front lit ce que le moteur lui renvoie,
y compris le texte des messages et les références d'articles.

```
src/lib/engine.ts     ← formes de retour du moteur (types uniquement, aucune règle)
src/lib/queries.ts    ← hooks TanStack Query, un par fonction du moteur
supabase/migrations/  ← le moteur lui-même
```

---

## Le moteur de règles

Toutes les fonctions vérifient l'accès de l'appelant (`has_company_access` / `can_manage_company`)
avant de calculer, et prennent une **date de référence** : un calcul daté du 15 mai 2026 lit les
paramètres en vigueur au 15 mai 2026, pas les actuels.

| Fonction | Rôle |
|---|---|
| `fn_param(key, date)` · `fn_param_num` | Lecture datée du référentiel — le socle |
| `fn_arbitrate(...)` | Loi → CCT → contrat, retient la plus favorable et dit laquelle a gagné |
| `fn_min_salary(contract, date)` | SSM selon qualification et temps de travail, grille CCT |
| `fn_probation(contract, date)` | Fin d'essai, prolongation par maladie, **dernier jour utile pour notifier** |
| `fn_notice_period(...)` | Préavis selon l'ancienneté, règle du 15 du mois |
| `fn_contract_compliance(contract, date)` | Contrôles bloquants et avertissements, mentions obligatoires |
| `fn_validate_schedule(schedule)` | Durées, repos journalier et hebdomadaire, dimanche, férié, absences |
| `fn_publish_schedule(schedule)` | **Refuse la publication** tant qu'une violation bloquante subsiste |
| `fn_reference_period_status(company, date)` | Compteur d'heures moyen sur la PRL |
| `fn_leave_balance(employee, date)` | Solde de congés, détail ligne à ligne |
| `fn_sick_counters(employee, date)` | 77 jours / 18 mois, protection de 26 semaines, certificats |
| `fn_leave_request_impact(...)` | Impact d'une demande avant envoi |
| `fn_headcount` · `fn_headcount_obligations` | Effectif sur 12 mois, seuils 15/100/150/250 |
| `fn_collective_dismissal_counters` | Compteurs glissants 30 / 90 jours, date de libération |
| `fn_simulate_collective_dismissal(...)` | Verdict, alternatives, chronologie complète de la procédure |
| `fn_compliance_scan(company, date)` | Agrège tout en « En retard » / « Dans les 30 jours » / « À surveiller » |
| `fn_generate_public_holidays(year)` | 11 jours fériés, fêtes mobiles, collisions et récupérations |
| `fn_company_rates(company, date)` | Classe d'activité, classe Mutualité et facteur accident **à la date** |
| `fn_applicable_cbas(contract, date)` | Toutes les conventions applicables : société, service, contrat |
| `fn_is_qualified(employee, date)` | Qualification déclarée **ou** acquise par l'ancienneté de carrière |
| `fn_dismissal_protections(employee, date)` | Maladie, grossesse, mandat de délégué — réunies |
| `fn_overtime_eligibility(employee, date)` | Mineur, grossesse, prime de réemploi : heures supplémentaires interdites |
| `fn_delegation_eligibility(employee, date)` | Ancienneté, âge, exclusion du personnel de direction |
| `fn_absence_entitlement(type, date)` | Droit à congé extraordinaire **en vigueur à la date** |
| `fn_end_of_contract_documents(contract)` | Ce qui reste à remettre au salarié |
| `fn_check_national_id(id, date, sexe)` | Date encodée, parité du sexe, clés de Luhn et de Verhoeff |
| `fn_referential_gaps` · `fn_referential_holes` · `fn_referential_inconsistencies` | Ce que le référentiel ne couvre pas encore, dit explicitement |
| `fn_income_tax(base, classe, date)` | Tranche applicable, impôt de base, taux sur le dépassement |
| `fn_company_absenteeism(company, année)` | Taux d'absentéisme, classe Mutualité suggérée |
| `fn_salary_reference(contract, date)` | Fixe + part variable retenue comme référence salariale |
| `fn_disability_extra_leave(employee, date)` | Congé supplémentaire du travailleur handicapé, selon son taux |
| `fn_employee_children(employee, date)` | Enfants, droits associés, et liste des attentions de fin d'année |
| `fn_overtime_approve` · `fn_overtime_approved_hours` | Accord **préalable** des RH *et* du salarié |
| `fn_meal_voucher_check(grant)` | Valeur faciale et participation du salarié face aux plafonds |
| `fn_can_terminate(contract, motif, date)` | Protections en cours ; un délégué n'est licenciable que pour faute grave |
| `fn_premium_caps(company, exercice)` | Plafond individuel de 30 % du brut annuel et enveloppe de 7,5 % du bénéfice N-1 |

### Chargement des paramètres et recalculs

Les paramètres sociaux sont publiés par le CCSS et l'ACD **après** les changements. Deux dates
coexistent donc et sont conservées séparément : la **date d'application** (`valid_from`) et la
**date de chargement** (`entered_at`). Un paramètre chargé aujourd'hui mais applicable à une
période déjà traitée impose de reprendre les calculs de cette période.

`fn_add_parameter_version` clôture la version en cours à la date d'effet et ouvre la nouvelle ;
`fn_validate_parameter_version` impose la double lecture par une autre personne que celle qui a
saisi. L'écran *Référentiel* expose la couverture et la saisie.

> **Reste à faire sur ce point :** la détection automatique des périodes de paie à recalculer
> lorsqu'un paramètre est chargé rétroactivement. La structure le permet (les deux dates sont là),
> la règle de déclenchement n'est pas encore écrite.

### Historisation

Rien de ce qui évolue n'est figé sur la ligne qu'il décrit :

| Ce qui évolue | Où vit l'historique |
|---|---|
| Classe d'activité, classe Mutualité, facteur accident | `company_rate_periods`, par période sans chevauchement |
| Conventions collectives | `company_collective_agreements` et `contract_collective_agreements`, chacune avec sa période |
| Droits à congé extraordinaire | `absence_entitlements` — le congé de mariage vaut 6 j avant 2018, 3 j après |
| Paramètres légaux et taux | `legal_parameters`, contrainte d'exclusion GiST sur la plage de validité |
| Barèmes d'impôt | `tax_brackets`, par classe et par période |
| Droits du travailleur handicapé | `employee_disabilities`, par période sans chevauchement |
| Plafonds de primes | `legal_parameters`, chargés à partir du 01.01.2025 seulement |

### Ce que le référentiel ne couvre pas encore

`fn_referential_gaps` liste, paramètre par paramètre, ceux dont l'historique ne remonte pas au
31.12.2019 — **27 sur 73** à ce jour. Aucune valeur n'a été inventée pour combler ces trous : les
barèmes de frais de déplacement, de bonus-malus accident, de seuils Mutualité et de retenue d'impôt
sont déclarés dans le référentiel mais **vides**, et les fonctions qui en dépendent refusent de
produire un chiffre plutôt que d'en produire un faux :

```
fn_income_tax(3400, '1', '2026-09-09')
  → { found: false, message: "Aucun barème chargé pour la classe 1 … Le calcul est suspendu plutôt que faux." }
```

L'écran *Référentiel* affiche cette couverture et permet la saisie d'une nouvelle version datée,
avec double lecture par une autre personne que celle qui a saisi.

### Ce qui n'est jamais en dur

`legal_parameters` porte chaque valeur avec sa plage de validité, sa source et son article, sous
contrainte d'exclusion GiST qui interdit tout chevauchement de périodes pour une même clé.

L'historique est réel : le taux de pension salarié y figure à 8,00 % jusqu'au 31.12.2025 et à 8,50 %
depuis le 01.01.2026. Une paie de décembre 2025 recalculée aujourd'hui utilise 8,00 %.

---

## Sécurité

- **RLS sur toutes les tables** portant des données de société ou de salarié. Un salarié ne lit que
  ses propres lignes, et ne voit un planning que s'il est publié.
- **Chiffrement au repos** du matricule national et de l'IBAN (`pgcrypto`, clé hors de portée du
  client). Lecture uniquement par `fn_employee_sensitive`, qui vérifie les droits de l'appelant ;
  les primitives `fn_encrypt_field` / `fn_decrypt_field` ne sont pas exposées en RPC.
- **Matricule CCSS validé** intégralement : les 8 premiers chiffres doivent former une date réelle,
  le 2ᵉ chiffre du numéro d'ordre doit s'accorder au sexe (impair pour un homme, pair pour une femme),
  et les deux clés de contrôle doivent tomber juste (Luhn sur le 12ᵉ chiffre, Verhoeff sur le 13ᵉ).
  Chaque échec est nommé précisément plutôt que renvoyé comme « invalide ».
- **Journal d'audit** en insertion seule sur les contrats, le temps de travail et les absences.
- **Bucket privé** : le premier segment du chemin est l'identifiant de société, l'isolation vaut donc
  aussi pour les fichiers.
- `anon` ne peut exécuter aucune fonction du schéma public.

Les advisories Supabase restantes sont assumées :

| Advisory | Pourquoi elle reste |
|---|---|
| `app_secrets` : RLS active sans policy | C'est le but — la table est inaccessible depuis l'API, la clé n'est lue que par une fonction `security definer` |
| `btree_gist` dans le schéma `public` | Requis par les contraintes d'exclusion temporelles ; le déplacer imposerait de les recréer |
| 23 fonctions `security definer` exécutables par `authenticated` | Ce sont les RPC du moteur. Chacune contrôle l'accès de l'appelant, et `tests/rls.test.mjs` vérifie qu'un utilisateur d'un autre espace est refusé sur toutes |
| Protection contre les mots de passe compromis | Réglage du tableau de bord Auth, à activer avant production |

### Avant mise en production

- [ ] Supprimer les comptes de démonstration (`demo@`, `marta@`, `autre@luxrh.lu`).
- [ ] Activer la protection contre les mots de passe compromis (Auth → Passwords).
- [ ] Re-valider tous les paramètres du chapitre 7 du PRD sur les sources officielles.
- [ ] Trancher les six points juridiques ouverts du PRD (bornes de l'essai, tranches de délégués
      au-delà de 400, seuil de représentation au conseil d'administration, délai de déclaration de
      sortie CCSS, barèmes CIM/CISSM 2026, règles de nuit sectorielles).

---

## Écarts assumés par rapport aux maquettes

- **Dernier jour pour notifier une rupture d'essai.** La maquette affiche le 15.09.2026 pour Aïcha
  Diallo, en partant de la fin d'essai *avant* prolongation. Le moteur applique la prolongation de
  4 jours due à l'incapacité (essai jusqu'au 04.10) et affiche donc le **19.09.2026**. La formule
  reste celle des deux exemples de la maquette : `fin d'essai − préavis d'essai`.
- **Repos journalier et services coupés.** Le contrôle des 11 heures s'apprécie entre deux journées
  de travail, pas entre deux vacations : un service 11:00–15:00 puis 17:00–23:00 ne déclenche pas de
  violation. La pause obligatoire s'apprécie, elle, service par service.
- **Effectif de la Brasserie du Glacis.** 14 salariés présents aujourd'hui pour une moyenne de 13,17
  sur les 12 mois de référence (Aïcha Diallo est entrée le 01.07.2026). C'est la moyenne — 13, à 2
  du seuil de 15 — qui compte juridiquement, conformément à la maquette.

---

## Structure

```
src/
  lib/          supabase.ts · queries.ts · engine.ts · format.ts · database.types.ts
  components/   ui.tsx (design system) · AppShell.tsx · VigilanceItem.tsx
  context/      AppContext.tsx (session, dossier actif, date de référence)
  pages/        20 écrans, dont SelfService.tsx pour l'espace salarié mobile
supabase/
  migrations/   42 migrations, du socle au moteur de règles
  functions/    contract-pdf (génération PDF + dépôt dans le dossier du salarié)
tests/          3 suites exécutées contre l'API réelle, sans dépendance
```

Les migrations sont déjà appliquées sur le projet. Pour repartir d'une base neuve :

```bash
supabase link --project-ref <ref> && supabase db push
```

---

## Hors périmètre

La **paie brut → net** est en V2, volontairement : elle dépend entièrement de la qualité des données
de temps, d'absence et de contrat produites en V1. Les tables `tax_scales` et les paramètres de
cotisation sont déjà en place et datés ; le calcul viendra s'y brancher.

LuxRH est un outil d'aide à la décision. Il ne rend pas d'avis juridique et ne prend aucune décision
automatisée à effet juridique sur une personne, au sens de l'article 22 du RGPD.
