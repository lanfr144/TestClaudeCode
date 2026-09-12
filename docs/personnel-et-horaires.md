# Gestion du personnel et gestion des horaires — état et plan d'achèvement

Ces deux domaines devraient être terminés. Ils ne le sont pas tout à fait, et ce document dit
précisément à quoi cela tient. Il s'adresse à qui doit décider ce qui reste à faire et
combien cela coûte.

**Le constat en une phrase** : le moteur est plus complet que les écrans. Presque tout ce qui
manque existe déjà en base et en PL/pgSQL, testé, mais n'est atteignable par aucune interface.
Le travail restant est majoritairement de l'écran, pas de la règle.

---

## Ce qui est terminé

| Domaine | Couverture |
|---|---|
| Salariés | Fiche, résidence, qualification, ancienneté de carrière, données sensibles chiffrées |
| Contrats | Six types, assistant en cinq étapes, contrôle de conformité continu, PDF, unicité du contrat en cours imposée en base (migration 55) |
| Conventions collectives | Rattachement multiple, arbitrage loi → CCT → contrat, l'application dit laquelle gagne |
| Statuts protégés | Grossesse, suites de couches, mandat de délégué, avec effet sur le licenciement |
| Enfants | Avec refus d'usage imposé par le schéma |
| Planning | Saisie, modèles de vacation, validation contre repos et durées, publication contrôlée |
| Registre du temps | Heures réelles, dimanche, férié, nuit, heures supplémentaires |
| Congés | Solde, impact d'une demande, catalogue de congés extraordinaires daté |
| Maladies | Compteurs, délai de certificat, original papier, alerte d'absentéisme |
| Heures supplémentaires | Demande, double accord RH puis salarié, compensation |
| Chèques-repas | Attribution, contrôle de la valeur faciale et de la participation |
| Jours fériés | Génération annuelle, fériés mobiles, collisions, récupération |

C'est substantiel, et vérifié par 154 tests qui passent.

---

## Gestion du personnel — ce qui manque

### 1. On ne peut pas créer un salarié sans lui créer un contrat

L'unique point de création d'un salarié dans tout le dépôt est
[`ContractWizard.tsx`](../luxrh/src/pages/ContractWizard.tsx), à l'étape 1. L'écran
`Employees` liste, il ne crée pas. Côté Streamlit, aucune création n'est possible du tout.

C'est une impasse fonctionnelle : un candidat retenu, un salarié repris d'une autre société,
un dossier préparé avant signature — tous ces cas exigent d'ouvrir un assistant de contrat
qu'on n'a pas l'intention de terminer.

**À faire** : un écran de création et d'édition de la fiche salarié, indépendant du contrat.

### 2. La fin de contrat individuelle n'a aucun écran

Trois fonctions du moteur portent tout le raisonnement — `fn_can_terminate` (licéité du
motif, protections en cours), `fn_notice_period` (durée du préavis), `fn_salary_reference`
(assiette des indemnités). Elles sont écrites, testées, typées dans
`database.types.ts`… et **appelées par aucune interface**, ni React ni Streamlit.

L'écran `DismissalSimulator` traite le licenciement **collectif**. Le licenciement individuel,
la démission, la rupture d'un commun accord, la fin de CDD : rien.

C'est le manque le plus important des deux domaines. La table `contract_terminations` existe,
avec la dispense de préavis, la faute grave et l'indemnité de départ.

**À faire** : un écran de rupture, qui interroge `fn_can_terminate` avant de laisser
enregistrer, affiche le préavis calculé et les pièces de fin de contrat dues
(`fn_end_of_contract_documents`, elle aussi sans écran).

### 3. Quatre domaines sans aucune interface

Vérifié par recherche sur `luxrh/src` : ces tables ne sont mentionnées nulle part dans le
front.

| Table | Ce qu'on ne peut donc pas faire |
|---|---|
| `employee_disabilities` | Enregistrer une reconnaissance de travailleur handicapé — alors que `fn_disability_extra_leave` calcule le congé supplémentaire |
| `probation_extensions` | Prolonger une période d'essai suspendue par une absence |
| `reference_periods` | Définir une période de référence par service |
| `company_accident_claims` | Saisir la sinistralité qui nourrit le facteur bonus-malus |

### 4. Trois domaines à peine effleurés

`employee_tax_cards` et `interim_agencies` n'apparaissent que dans un seul fichier chacun — les
types générés. Donc : pas de fiche de retenue d'impôt, pas de gestion des agences d'intérim, alors
que le type de contrat « intérim » existe et exige une agence.

`contract_amendments` change de statut avec la migration 55 : le moteur sait désormais établir un
avenant (`fn_amend_contract`), testée manuellement sur la base — clôture du contrat en cours,
reprise de toutes ses clauses par `to_jsonb`, report de la rémunération et des conventions encore en
vigueur, journalisation du motif. **Ce n'est plus une table à peine effleurée côté moteur** ; c'est
toujours une table sans écran. Voir le lot 2.2 ci-dessous, revu en conséquence.

### 5. Le reclassement professionnel est absent du modèle

Livre III du Code du travail. Aucune table ne sait le représenter. C'est le seul manque de
cette liste qui exige de la conception avant du code, et
[`couverture-droit-du-travail.md`](couverture-droit-du-travail.md) le désigne déjà comme le
manque fonctionnel le plus important du produit.

---

## Gestion des horaires — ce qui manque

### 1. Deux fonctions sans écran

`fn_holiday_summary` — la synthèse des jours fériés d'une année pour une convention donnée —
et `fn_overtime_approved_hours` — les heures effectivement couvertes par un accord — sont
écrites et testées, appelées par personne. La seconde est celle qui répond à la question
« ces heures supplémentaires sont-elles couvertes ? », qui est tout l'objet du double accord.

### 2. La période de référence ne se pilote pas

`reference_periods` et `fn_reference_period_status` existent : la période de référence est ce
sur quoi la durée moyenne du travail se calcule, et son dépassement est un manquement. Aucun
écran ne permet de la définir, ni de voir où l'on en est dans la période courante.

### 3. Le compte épargne-temps et le chômage partiel sont absents

Deux notions absentes du modèle, l'une et l'autre relevant du temps de travail. Le chômage
partiel et les intempéries supposent en outre une interface avec l'ADEM, donc une décision de
périmètre avant toute conception.

### 4. Lieux d'intervention et indemnisation des dépassements kilométriques — migration 52

La migration
[`20260910200000_52_client_sites_and_travel.sql`](../luxrh/supabase/migrations/20260910181724_52_client_sites_and_travel.sql),
**appliquée**, apporte ce que le modèle n'avait pas pour une vacation exécutée hors du siège :
`client_sites` (le lieu, avec son adresse), `travel_distances` (un cache de distances, alimenté une
fois par couple), et les fonctions `fn_shift_travel`, `fn_schedule_travel`, `fn_set_travel_distance`,
`fn_address_of`, `fn_travel_distance` qui transforment un dépassement de trajet en montant.
`shifts.client_site_id` (nul = au siège, le cas courant) désigne le lieu d'une vacation.

**Les tables et les fonctions existent sur la base déployée, mais rien n'est encore utilisable
depuis un écran**, pour deux raisons cumulatives :

1. **Le tarif kilométrique n'existe pas.** `fn_shift_travel` lit `mileage_allowance_eur_per_km`
   dans `legal_parameters` ; la clé est déclarée dans `expected_parameters` (migration 52) mais
   **aucune valeur n'y est chargée**, faute de source publique établie — légale, conventionnelle ou
   contractuelle selon le cas. Conformément à la règle 7 du CLAUDE.md, aucun chiffre n'a été inventé
   pour la remplir : tant qu'elle manque, `fn_shift_travel` et `fn_schedule_travel` répondent
   `found: false` en le nommant, plutôt que de proposer un montant approximatif.
2. **Aucun écran ne l'expose.** Ni React ni Streamlit ne référencent ces tables ou ces fonctions —
   vérifié par recherche sur `luxrh/src` et `luxrh-py`. Il n'existe donc aucun moyen de saisir un
   lieu d'intervention, de déclencher un calcul de distance, ni d'afficher un dépassement, même le
   tarif une fois chargé. Aucun test ne les couvre non plus spécifiquement aujourd'hui — voir
   [tests-et-qualite.md](tests-et-qualite.md).

Le calcul de distance suppose de transmettre l'adresse du domicile d'un salarié à un service tiers
(Edge Function `luxrh/supabase/functions/travel-distance/index.ts`, présente dans le dépôt ; son
état de déploiement effectif n'est pas vérifié ici) : c'est un traitement de donnée personnelle par
un sous-traitant, avec ce que cela implique en base légale et en registre des traitements. Cette
Edge Function attend une variable d'environnement `DISTANCE_API_KEY` — **absente**, à configurer
côté serveur avant tout premier appel ; sans elle, la fonction répond qu'elle ne peut pas conclure
plutôt que d'inventer une distance. Voir [architecture.md](architecture.md) pour le patron de
traçabilité qui accompagne ces appels et [securite-et-conformite.md](securite-et-conformite.md)
pour l'encadrement du sous-traitant.

### 5. Six écrans manquent côté Streamlit

L'application Streamlit compte 16 vues contre 22 écrans React. Manquent notamment l'assistant
de contrat, l'aperçu de contrat, l'éditeur de CCT, les modèles de vacation, le registre du
temps et l'espace salarié. Ce n'est pas un défaut en soi — les deux fronts partagent les
règles, pas les écrans — mais c'est un écart à assumer explicitement plutôt qu'à subir.

---

## Plan d'achèvement

Ordonné par valeur rendue, en tenant compte du fait que le moteur est déjà écrit.

### Lot 1 — Fermer les impasses (le plus rentable)

| # | Travail | Moteur | Effort |
|---|---|---|---|
| 1.1 | Écran de création et d'édition d'un salarié, indépendant du contrat | Rien à écrire | 2–3 j |
| 1.2 | Écran de rupture de contrat individuelle | `fn_can_terminate`, `fn_notice_period`, `fn_salary_reference`, `fn_end_of_contract_documents` — **toutes prêtes** | 4–5 j |
| 1.3 | Pièces de fin de contrat dans l'écran de rupture | `fn_end_of_contract_documents` prête | inclus |

**Ce lot ne demande aucune nouvelle règle.** Il rend atteignables quatre fonctions déjà
testées et supprime la seule impasse fonctionnelle du produit.

### Lot 2 — Compléter les dossiers

| # | Travail | Moteur | Effort |
|---|---|---|---|
| 2.1 | Reconnaissance de travailleur handicapé | `fn_disability_extra_leave` prête | 1–2 j |
| 2.2 | Avenants au contrat | **Moteur prêt** (migration 55) : `fn_amend_contract` clôt, recrée et journalise ; reste à écrire l'écran qui l'appelle et affiche l'historique par `previous_contract_id` | 1–2 j |
| 2.3 | Prolongation de période d'essai | Table prête | 1 j |
| 2.4 | Agences d'intérim | Table prête, exigée par le type « intérim » | 1 j |
| 2.5 | Sinistralité accident | Table prête | 1 j |

### Lot 3 — Piloter le temps

| # | Travail | Moteur | Effort |
|---|---|---|---|
| 3.1 | Périodes de référence : définition et suivi | `fn_reference_period_status` prête | 2–3 j |
| 3.2 | Synthèse annuelle des jours fériés | `fn_holiday_summary` prête | 1 j |
| 3.3 | Heures couvertes par accord, dans l'écran des heures supplémentaires | `fn_overtime_approved_hours` prête | 1 j |

### Lot 4 — Ce qui demande de la conception avant du code

| # | Travail | Nature |
|---|---|---|
| 4.1 | Reclassement professionnel | Modélisation complète — Livre III |
| 4.2 | Fiche de retenue d'impôt et calcul brut → net | V2 du PRD ; le barème `tax_brackets` est vide, faute de source publique chargée |
| 4.3 | Compte épargne-temps | Modélisation |
| 4.4 | Chômage partiel et intempéries | Modélisation + périmètre d'interface ADEM |

### Lot 5 — Parité des deux fronts

Décider, écart par écart, ce que Streamlit doit porter. Le tableau des écarts est en fin
d'[`api-serveur.md`](api-serveur.md). Une décision produit, pas une tâche technique.

---

## Ce que ce plan ne dit pas

Les efforts indiqués valent pour un développeur qui connaît le dépôt, et supposent que les
règles existantes sont justes — ce que les 154 tests suggèrent sans le prouver pour tous les
cas de droit. Ils n'incluent ni la recette métier, ni la relecture juridique des écrans
produits, qui est indispensable dès qu'un écran affiche une durée de préavis à un utilisateur.

---

## Voir aussi

- [`index.md`](index.md) — sommaire de la documentation
- [`couverture-droit-du-travail.md`](couverture-droit-du-travail.md) — ce que l'outil couvre du droit, table par table
- [`api-serveur.md`](api-serveur.md) — les fonctions citées ici, avec leurs appelants
- [`guide-utilisateur.md`](guide-utilisateur.md) — les écrans qui existent aujourd'hui
- [`architecture.md`](architecture.md) — le patron de traçabilité des lectures auditées
- [`securite-et-conformite.md`](securite-et-conformite.md) — l'encadrement du service de distance et de ses sous-traitants
- [`ecarts-a-corriger.md`](ecarts-a-corriger.md) — la fiche de passation
