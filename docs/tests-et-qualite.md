# Tests et qualité

Ce document décrit ce que les suites de tests vérifient, comment les lancer, et — tout aussi
utile — **ce qu'elles ne couvrent pas**. Il s'adresse aux développeurs et aux relecteurs.

---

## Le parti pris : tester contre l'API réelle

Il n'y a **aucune dépendance de test** dans le projet : ni Vitest, ni Jest, ni bibliothèque
d'assertion. Six scripts Node exécutent des requêtes HTTP contre le projet Supabase réel, comptent
les succès, et sortent avec un code non nul au premier échec.

C'est un choix, avec ses raisons et son coût.

**La raison.** L'essentiel de la logique de LuxRH vit en PL/pgSQL et derrière des politiques RLS.
Un test unitaire sur un composant React ne dirait rien de ce qui compte : ni qu'une règle est juste,
ni qu'un utilisateur d'un autre espace est bien refusé. Le seul endroit où ces deux propriétés se
vérifient est l'API, telle qu'un client la voit.

**Le coût.** Les suites ont besoin d'un réseau, d'un projet Supabase joignable et du jeu de
démonstration en place. Elles ne s'exécutent pas hors ligne.

---

## Lancer les suites

```bash
cd luxrh
npm test              # les six suites, dans l'ordre
```

| Commande | Suite |
|---|---|
| `npm run test:api` | `tests/api.test.mjs` |
| `npm run test:rls` | `tests/rls.test.mjs` |
| `npm run test:domain` | `tests/domain.test.mjs` |
| `npm run test:portability` | `tests/portability.test.mjs` |
| `npm run test:lifecycle` | `tests/lifecycle.test.mjs` |
| `node tests/publication.test.mjs` | `tests/publication.test.mjs` |

Chaque suite affiche `N succès, M échec(s)` et sort avec le code 1 dès qu'un échec est constaté.

### Configuration

`tests/config.mjs` lit `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`, puis les trois mots de
passe des comptes de démonstration, depuis l'environnement ou depuis `luxrh/.env.local`.

**Aucun identifiant n'est écrit en dur : le dépôt est public.** Si un mot de passe manque, la suite
lève une exception nommant précisément la clé attendue, plutôt que d'échouer plus tard sur une
connexion refusée.

Trois comptes sont utilisés :

| Compte | Rôle dans les tests |
|---|---|
| `demo@luxrh.lu` | Gestionnaire de fiduciaire — le cas nominal |
| `marta@luxrh.lu` | Salariée — l'espace cloisonné |
| `autre@luxrh.lu` | Un **autre espace de travail** — l'isolation en action |

---

## Ce que couvre chaque suite

**190 vérifications** au total, réparties ainsi, et toutes exécutées : les nombres viennent d'un
`npm test` réel, plus d'un décompte de points de décision.

| Suite | Vérif. | Ce qu'elle établit |
|---|---|---|
| `api.test.mjs` | 80 | Chaque requête et chaque RPC utilisées par le front, avec leurs jointures |
| `rls.test.mjs` | 22 | Le cloisonnement est bien imposé en base, pas dans l'interface |
| `publication.test.mjs` | 10 | Un planning en violation ne se publie pas ; corrigé, il se publie |
| `domain.test.mjs` | 16 | Handicap, enfants, heures supplémentaires, chèques-repas, protections, plafonds |
| `portability.test.mjs` | 26 | Export RGPD, réversibilité, aller-retour du référentiel |
| `lifecycle.test.mjs` | 36 | Cycle de vie du contrat, lecture auditée, validation d'adresse |

### `api.test.mjs` — le test de fumée

Rejoue **chaque requête du front** telle qu'elle est écrite dans `queries.ts`, jointures comprises :
28 lectures REST, puis 26 appels au moteur.

Il vérifie aussi trois refus, qui valent autant que les succès :

- `fn_decrypt_field` est inaccessible ;
- `fn_encrypt_field` est inaccessible ;
- un appel **sans jeton** à `fn_compliance_scan` est rejeté.

Les valeurs renvoyées sont affichées, pas seulement validées : la sortie de la suite se lit comme
un état des lieux du moteur — solde de congés, compteurs maladie, nombre d'étapes de la chronologie
de licenciement, paramètres sans historique 2019, et **si le barème d'impôt est chargé ou non**.

### `rls.test.mjs` — le cloisonnement

Deux séries de contrôles depuis un **autre espace de travail** : huit tables (sociétés, salariés,
contrats, plannings, shifts, absences, journal d'audit, documents) doivent renvoyer **zéro ligne** —
pas une erreur, zéro ligne — et cinq fonctions du moteur (`fn_compliance_scan`,
`fn_validate_schedule`, `fn_employee_sensitive`, `fn_headcount`, `fn_leave_balance`) doivent
**refuser**.

Elle vérifie aussi que le référentiel légal, lui, **reste lisible** par tout utilisateur connecté :
cloisonner ce qui ne doit pas l'être serait un défaut symétrique.

Puis huit contrôles sur l'espace salarié : une seule fiche visible, ses seuls contrats, ses seules
absences, **aucun shift tant que le planning est en brouillon**, son propre solde de congés
accessible, celui d'un collègue refusé, le centre de vigilance refusé, et l'impossibilité de valider
soi-même une absence.

### `publication.test.mjs` — le refus, puis l'accord

La suite la plus démonstrative. Elle :

1. constate une violation bloquante de repos journalier, **avec sa base légale** ;
2. tente la publication — elle doit échouer ;
3. corrige le service fautif (reprise du jeudi à 07:00 après une fin le mercredi à 23:30, soit
   7 h 30 de repos ; le début est repoussé à 11:00) ;
4. republie — elle doit réussir ;
5. vérifie que la salariée **voit alors** ses horaires, et son planning ;
6. **restaure** le jeu de démonstration : service d'origine, planning remis en brouillon, et
   contrôle que la salariée ne voit à nouveau plus rien.

Cette suite **modifie des données**, puis les remet en état. C'est la seule dans ce cas avec
`domain.test.mjs`.

### `domain.test.mjs` — les règles métier récentes

Handicap et congé supplémentaire associé ; enfants et **minimisation effective** — le refus des
attentions doit avoir effacé le nom et le sexe en base ; heures supplémentaires et **accord
préalable en deux temps** (la validation RH seule laisse la demande à `hr_approved`) ; chèques-repas
et dépassements de plafond ; protections de fin de contrat, dont le blocage lié à une grossesse ;
primes participatives, enveloppe de 7,5 % du bénéfice N-1 et plafond individuel.

Un contrôle mérite d'être signalé : la suite demande les plafonds de primes pour **2024**, et
vérifie que la fonction répond `found: false`. Les plafonds ne sont chargés qu'à partir du
01.01.2025 ; obtenir un chiffre serait un échec, pas un succès.

Toutes les données créées sont supprimées en fin de suite.

### `portability.test.mjs` — surtout les refus

Comme le dit son en-tête : *le point sensible n'est pas que l'export fonctionne, c'est qu'il
refuse.*

Côté droit d'accès : l'export personnel doit produire une enveloppe versionnée `luxrh.export/1`, le
matricule national **déchiffré** (un export illisible ne satisfait pas le droit d'accès) et le champ
chiffré brut **retiré** de la sortie.

Côté refus : un salarié ne peut pas exporter un collègue, ni la fiduciaire, ni charger un
référentiel.

Côté aller-retour : recharger un référentiel déjà en place ne doit **rien ajouter, rien rejeter** ;
les CCT partagées (`organization_id` nul) doivent bien être dans l'export ; les lignes doivent
porter des **clés naturelles** sans identifiant technique, sinon l'import dupliquerait ; un format
étranger ou un genre incorrect doivent être refusés **et nommés**.

Enfin, le registre des exports doit avoir enregistré la demande, avec son volume.

---

## Vérification du typage

```bash
cd luxrh
npm run build      # tsc --noEmit && vite build
```

Le build **doit rester à zéro erreur TypeScript**. C'est la seule barrière automatique côté front,
et elle attrape la classe d'erreurs la plus fréquente du projet : une requête `supabase-js` dont
l'inférence a saturé et retombe sur `never`. Voir [contribuer.md](contribuer.md).

---

## Ce qui n'est pas couvert

Cette liste est aussi utile que la précédente. Elle est établie depuis le dépôt, pas depuis une
intention.

| Non couvert | Conséquence |
|---|---|
| **Aucun test de composant React** | Un rendu cassé, un état de formulaire incorrect, une erreur d'affichage ne sont attrapés par rien. Seul `tsc` protège |
| **Aucun test de l'application Streamlit** | Les vues Python ne sont exécutées par aucune suite. Une exception dans une vue s'affiche à l'écran, mais n'est pas détectée en amont |
| **Aucun test des backends Oracle et MySQL** | `backends.py` n'est vérifié sur aucune de ces bases. Le refus `EngineUnavailable` est garanti par construction, pas par un test |
| **Aucun test de l'Edge Function `contract-pdf`** | La génération PDF n'est pas exercée |
| **Aucun test hors ligne** | Sans réseau ni projet Supabase joignable, aucune suite ne démarre |
| **Aucune couverture mesurée** | Les 111 fonctions du moteur ne sont pas toutes appelées : celles listées en fin de [api-serveur.md](api-serveur.md) comme sans écran sont, pour la plupart, appelées par `api.test.mjs` — mais pas toutes |
| **Aucun test de charge** | L'exigence de performance du cahier des charges (un planning mensuel de 50 salariés en moins de 2 secondes) a motivé la migration 19 — 17 index et six politiques réécrites — mais n'est vérifiée par aucune mesure automatique |
| **Aucune intégration continue** | Les suites se lancent à la main. Rien n'empêche un commit de casser le build |
| **Le jeu de démonstration est un prérequis implicite** | Les suites cherchent « Brasserie », « Ferreira », « Diallo », « Rocha », « Weber ». Sur une base sans jeu de démonstration, elles échouent — et pas sur ce qu'elles testent |
| **Les fonctions nées des migrations 49 à 52 n'ont aucune couverture dédiée** | `fn_employee_rows`, `fn_time_entry_rows`, `fn_person_access_report`, `fn_shift_travel`, `fn_schedule_travel` sont exposées, appliquées, et fonctionnelles — mais aucune assertion de `tests/` ne porte spécifiquement sur elles aujourd'hui. Voir ci-dessous ce qu'il faudrait vérifier |

---

## Migrations 46 à 54 — appliquées et vérifiées, deux régressions attrapées par les tests

Les neuf migrations les plus récentes du dépôt
(`20260910180957_46_harden_grants_portability.sql` à `20260910220000_54_fix_company_rates_array_append.sql`)
sont **appliquées** à la base contre laquelle `npm test` s'exécute. Après application, **190
vérifications passent, 0 échec**, et `npm run build` reste à 0 erreur TypeScript.

**C'est un argument en faveur de la suite, pas contre elle** : deux régressions ont été introduites
par ces migrations puis immédiatement **attrapées par les tests**, avant toute mise en service.

- La migration 48 ajoutait des clés étrangères composites *à côté* des clés simples existantes.
  PostgREST y voyait alors deux relations entre les mêmes tables, et une requête imbriquée du type
  `employees?select=*,contracts(...)` échouait en `PGRST201`. Sur les 154 vérifications d'alors, 4 ont
  échoué à ce moment précis. La migration 53 retire les clés simples devenues redondantes.
- La migration 50 écrivait `manques := manques || 'accident_class_rates'` — un littéral sans type,
  résolu comme `anyarray || anyarray`, et rejeté en « malformed array literal ». La migration 54
  corrige par `array_append`.

Le détail des deux régressions et de leur correction est dans
[ecarts-a-corriger.md](ecarts-a-corriger.md).

### `lifecycle.test.mjs` — les fonctions nouvelles, enfin couvertes

Le manque était réel : les migrations 46 à 57 avaient ajouté quatorze fonctions qu'aucune
assertion ne touchait. La sixième suite le comble — 36 vérifications, contre l'API réelle comme
les autres.

| Domaine | Ce qu'elle établit |
|---|---|
| Validation d'adresse | Les sept cas : Luxembourg, Arlon, Metz `ok` ; Bruxelles, Paris `outside` ; Trèves, Amsterdam `unknown`. Et que « L-1424 » et « 1424 » donnent le même verdict |
| Lecture pipelinée | Refus d'un appel sans périmètre, refus d'un champ inconnu, **colonnes non demandées rendues à `null`**, et qu'un salarié n'y voit que son propre dossier |
| Registre des accès | Que le déchiffrement qui précède y figure, que `quand / qui / quoi / d_ou` sont tous rendus, et qu'un salarié ne lit pas le registre d'un collègue |
| Contrat unique | Qu'un second contrat actif chevauchant est **rejeté par la base**, pas par l'interface |
| Avenant | Refus sans motif, refus sans modification ; puis le cas complet : clôture la veille de la prise d'effet, version incrémentée, chaînage conservé, modification appliquée, temps partiel recalculé par le déclencheur, contrat non signé, clauses non modifiées reprises, avenant journalisé |

**Elle défait sa propre écriture.** Un avenant coupe un contrat en deux : la suite supprime
l'avenant de test et rétablit le contrat d'origine, puis vérifie qu'il ne reste qu'un seul contrat
actif. Le premier essai ne le faisait pas — et le second a échoué sur les résidus du premier. La
contrainte d'unicité a même rejeté un nettoyage écrit trop vite, en une seule instruction : la
suppression et la remise en service ne voyaient pas le même instantané.

Les dates y sont **déduites du contrat**, jamais figées : une date en dur rendait la suite non
rejouable dès que le jeu de démonstration changeait.

### Ce qui reste sans assertion dédiée

| Fonction / migration | À vérifier |
|---|---|
| `fn_time_entry_rows` (51) | Qu'un appel sans `p_from`/`p_to` est refusé, et que la projection est bornée à la période |
| `fn_log_access_autonomous` (51) | Que la trace porte `is_autonomous = false` tant que `app_secrets.dblink_conninfo` est absent, et `true` une fois la clé chargée — ce second cas suppose une base de test avec `dblink` configurée |
| `fn_shift_travel` / `fn_schedule_travel` (52) | Qu'ils renvoient `found: false` tant que `mileage_allowance_eur_per_km` n'est pas chargé ; qu'une distance n'est transmise qu'une fois par couple ; que la transmission d'une adresse est tracée en `DOWNLOAD` |
| Clés composites (48) et clés simples retirées (53) | Qu'une écriture violant une clé composite d'isolation est rejetée ; qu'une requête imbriquée `employees?select=*,contracts(...)` ne lève plus `PGRST201` — la régression de 53 mérite une assertion qui empêche son retour |
| Déclencheur `check_address` (56) | Qu'une adresse hors zone est refusée **à l'écriture**, et non seulement par `fn_validate_address` appelée à part |

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [demarrage.md](demarrage.md) — configurer `.env.local` avant de lancer les suites
- [api-serveur.md](api-serveur.md) — les fonctions que `api.test.mjs` exerce
- [contribuer.md](contribuer.md) — ce qu'il faut vérifier avant de proposer un changement
- [moteur-de-regles.md](moteur-de-regles.md) — la règle « aucune erreur silencieuse », que plusieurs suites vérifient
- [ecarts-a-corriger.md](ecarts-a-corriger.md) — l'historique de migrations à réparer et le détail des deux régressions corrigées
