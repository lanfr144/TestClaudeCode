# Modèle de données

Ce document décrit les tables de LuxRH, par domaine, avec leurs relations et leurs clés
d'isolation. Il s'adresse aux développeurs qui écrivent des requêtes ou des migrations.

**État vérifié le 10 septembre 2026.** La base déployée porte **85 tables** (vérifié par requête
sur `pg_class`/`pg_namespace`, schéma `public`, hors extension). Les migrations 46 à 56 sont
**appliquées** ; elles ont ajouté six tables au fil de la série — `journal_acces` (migration 49),
`parametres_attendus` (migration 50), `sites_client` et `distances_trajet` (migration 52),
`zones_adresse` et `controles_adresse` (migration 56) — aux 47 qui existaient depuis la migration 39.
La migration 55 n'ajoute aucune table : elle pose une contrainte, une fonction et des index sur des
tables existantes (§ Domaine 5 et § Types énumérés plus bas).

Le schéma de référence est PostgreSQL. Il est extrait dans `schema/catalogue.json` — 47 tables et
20 types énumérés à la date de sa dernière régénération, donc **antérieur aux migrations 47 à 56**
et à recalculer pour refléter les 53 tables actuelles — d'où `tools/emit_portable_schema.py` dérive
les schémas Oracle et MySQL. Voir [bases-de-donnees.md](bases-de-donnees.md).

---

## Les deux clés d'isolation

Toute l'architecture de sécurité repose sur deux colonnes.

| Colonne | Portée | Vérifiée par |
|---|---|---|
| `organisation_id` | L'**espace de travail** : une fiduciaire, ou une entreprise unique | `auth_org_id()` |
| `societe_id` | Le **dossier** : une société cliente à l'intérieur de cet espace | `has_company_access()`, `can_manage_company()` |

Les tables portant des données de salarié dénormalisent volontairement `societe_id` **en plus** de
`salarie_id`. Ce n'est pas une redondance accidentelle : elle permet à une politique RLS de trancher
sans jointure, ce qui compte pour les performances autant que pour la lisibilité de la politique.

**Migration 48 — l'isolation devient aussi structurelle.** Jusqu'ici, rien n'empêchait *au niveau
du schéma* qu'un contrat désigne une société et un salarié d'une autre société : RLS interdisait de
le lire, mais la ligne pouvait exister. La migration pose des clés étrangères composites —
`salaries (id, societe_id)` unique, puis `foreign key (salarie_id, societe_id) references
salaries (id, societe_id)` sur `contrats`, `absences`, `releves_temps`, `creneaux`,
`enfants_salarie`, `handicaps_salarie`, `statuts_salarie`, `primes`,
`attributions_titres_repas`, `demandes_heures_sup` — qui rendent la paire incohérente impossible à écrire,
avec `on update cascade` pour un salarié déplacé d'une société à l'autre. Elle ajoute aussi une
série de contraintes `check` **structurelles seulement** — une fin qui ne précède pas un début, une
part qui ne dépasse pas son tout — en prenant soin de n'y inscrire **aucun seuil légal** : ceux-ci
restent dans `parametres_legaux`, conformément à la règle 1 du CLAUDE.md. Un seul candidat de
contrainte a été écarté à la revue : « un contrat actif porte une date de signature », que 305
lignes du jeu de démonstration violent déjà — voir le commentaire de fin de la migration 48. La
migration 48 avait porté la base à **70 contraintes `check`** et **12 clés étrangères composites**
sur le schéma `public` ; la migration 56 en ajoute trois de plus sur `zones_adresse` et
`controles_adresse` (§ Domaine 10) — **73 contraintes `check`** aujourd'hui, vérifié sur la base
déployée.

Migration 47, appliquée séparément, commente le schéma : les **51 tables** vivantes à cette date et
**242 colonnes** portent un commentaire SQL (`comment on table` / `comment on column`), visible dans
tout client qui interroge `pg_description`. Les deux tables ajoutées ensuite par la migration 56,
`zones_adresse` et `controles_adresse`, portent elles aussi leur commentaire, posé dans leur propre
migration plutôt que reporté sur la 47.

**Migration 53 — une régression attrapée par les tests, corrigée dans la foulée.** Les clés
composites de la migration 48 coexistaient avec les clés simples `(salarie_id)` déjà en place :
PostgREST y voyait **deux relations distinctes** entre les mêmes tables, et une requête imbriquée
du type `salaries?select=*,contrats(...)` échouait en `PGRST201` (relation ambiguë). La clé
composite subsumant strictement la simple, la migration 53 retire les onze clés simples devenues
redondantes. Aucune intégrité perdue — c'est un rappel qu'**une clé étrangère est aussi une arête du
graphe de relations que PostgREST expose** : en ajouter une change le contrat d'API, même sans
toucher une ligne de front.

Les 85 tables déployées ont RLS active — vérifié sur la base déployée, aucune exception. 184
politiques y sont installées (52 `select`, 44 `insert`, 45 `update`, 43 `delete`). `secrets_application`
est le seul cas où RLS est active **sans aucune politique** : la table est donc inaccessible depuis
l'API, et sa clé n'est lue que par une fonction `security definer`. Les quatre tables ajoutées par
les migrations 49, 50 et 52 portent RLS dès leur création — `parametres_attendus` en lecture seule
pour tout authentifié, `sites_client` avec les quatre politiques habituelles, `journal_acces` et
`distances_trajet` en **lecture seule** : aucune politique d'écriture n'y est créée pour un rôle
applicatif, seules des fonctions `security definer` y insèrent. Les deux tables de la migration 56,
`zones_adresse` et `controles_adresse`, suivent le même principe : chacune ne porte qu'**une politique
de lecture**, aucune politique d'écriture pour un rôle applicatif — seules `fn_check_address` et les
lignes semées par la migration y insèrent, `security definer` oblige.

---

## Vue d'ensemble des relations principales

```mermaid
erDiagram
    organisations ||--o{ societes : "héberge"
    organisations ||--o{ profils : ""
    organisations ||--o{ roles_compte : ""
    organisations ||--o{ conventions_collectives : "propres à l'espace"
    societes ||--o{ services : ""
    societes ||--o{ salaries : ""
    societes ||--o{ periodes_taux_societe : "taux datés"
    societes ||--o{ conventions_de_la_societe : ""
    conventions_collectives ||--o{ regles_convention : "7 blocs"
    conventions_collectives ||--o{ grilles_salaires_convention : ""
    conventions_collectives ||--o{ conventions_de_la_societe : ""
    salaries ||--o{ contrats : ""
    salaries ||--o{ statuts_salarie : "statuts protégés"
    salaries ||--o{ handicaps_salarie : ""
    salaries ||--o{ enfants_salarie : ""
    salaries ||--o{ fiches_retenue_impot : ""
    salaries ||--o{ absences : ""
    salaries ||--o{ creneaux : ""
    salaries ||--o{ documents : ""
    contrats ||--o{ avenants_contrat : ""
    contrats ||--o{ elements_remuneration : ""
    contrats ||--o{ conventions_du_contrat : ""
    contrats ||--o{ prolongations_essai : ""
    contrats ||--o| ruptures_contrat : ""
    societes ||--o{ plannings : ""
    plannings ||--o{ creneaux : ""
    societes ||--o{ releves_temps : ""
    types_absence ||--o{ absences : ""
    types_absence ||--o{ droits_absence : "droits datés"
    parametres_legaux }o--|| parametres_legaux : "derive_de_cle"
```

Le référentiel (`parametres_legaux`, `jours_feries`, `tranches_impot`, `credits_impot`,
`types_document`, `types_avantage`, `types_absence`) est volontairement **hors de ce graphe** : il
n'appartient à personne. Il est lisible par tout utilisateur connecté, et modifiable par les seuls
administrateurs d'espace.

---

## Domaine 1 — Socle et identité

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `organisations` | racine | L'espace de travail : nom, type (`fiduciary` / `company`) |
| `profils` | `organisation_id` | Le profil applicatif, adossé à `auth.users` |
| `roles_compte` | `organisation_id`, `societe_id` | Quatre rôles (`role_application`) : administrateur, gestionnaire, manager de service, salarié. `societe_id` nul = sur tout l'espace |
| `societes` | `organisation_id` | Le dossier : raison sociale, forme juridique, RCS, matricule CCSS, adresse, NACE |
| `services` | `societe_id` | Les services |
| `journal_ecritures` | `societe_id` | Journal **en insertion seule** sur contrats, temps de travail et absences. La migration 49 y ajoute `ip_source`/`agent_client`/`identifiant_requete` et étend les déclencheurs à `salaries`, `documents`, `fiches_retenue_impot`, `attributions_titres_repas` |
| `journal_acces` | `societe_id`, `salarie_concerne_id` (l'un ou l'autre nullable) | **Migration 49.** Journal des **lectures** de données personnelles — consultation, déchiffrement, export, téléchargement — complémentaire d'`journal_ecritures`, qui ne voit que les écritures. Colonne `est_autonome` (migration 51) : vrai si la trace a été écrite hors de la transaction appelante, via `dblink`. Contient déjà deux lignes `DECRYPT`, écrites pendant l'exécution de la suite de tests elle-même, toutes deux `est_autonome = false` faute de `dblink_conninfo` chargée |
| `secrets_application` | — | La clé de chiffrement. RLS active, **aucune politique** — c'est voulu : la table est inaccessible depuis l'API. Porte aussi la clé `dblink_conninfo` nécessaire à la trace autonome (migration 51) — absente tant que personne ne l'a chargée |

Une inscription déclenche `handle_new_user` (déclencheur, non exposé), qui crée l'organisation et le
profil à partir des métadonnées du compte.

## Domaine 2 — Référentiel légal

| Table | Ce qu'elle porte |
|---|---|
| `parametres_legaux` | **Le cœur.** Une ligne par version datée : valeur, unité, `debut_validite`/`fin_validite`, `source`, `reference_legale`, dérivation, saisie et double lecture. Contrainte d'exclusion GiST sur `(cle_parametre, daterange)` |
| `jours_feries` | Jours fériés générés par algorithme, jamais saisis. `convention_id` non nul = férié d'usage propre à une CCT |
| `tranches_impot` | Barème de retenue d'impôt, par classe et par période. **Vide aujourd'hui** |
| `credits_impot` | Crédits d'impôt — 5 lignes chargées |
| `types_avantage` | Neuf types d'avantages en nature et leur méthode de valorisation |
| `types_document` | Type de document, étape (`etape_document`), durée de validité, obligation de remise |
| `types_absence` | Le catalogue des absences — dix-sept types |
| `droits_absence` | Le **droit daté** attaché à un type : mariage 6 jours avant 2018, 3 jours après |
| `parametres_attendus` | **Migration 50.** Clé primaire `cle_parametre` : la liste des clés que le moteur lit réellement, relevées dans le code des migrations, avec la ou les fonctions qui les lisent (`lu_par`). Ne porte **aucune valeur légale** — sert de base à `fn_referential_gaps` pour signaler une clé jamais chargée. 76 clés y sont déclarées, dont `mileage_allowance_eur_per_km` et `accident_class_rates`, déclarées et **toujours vides** : aucune valeur légale n'a été inventée pour les combler |

`tax_scales`, créée par la migration 02, a été **supprimée** par la migration 37 et remplacée par
`tranches_impot`. En comptant les quatre tables ajoutées par les migrations 49, 50 et 52 puis les deux
ajoutées par la migration 56, **54 tables ont été créées au total sur l'ensemble de la série de
migrations, 53 vivent aujourd'hui** sur la base déployée.

## Domaine 3 — Conventions collectives

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `conventions_collectives` | `organisation_id` **nullable** | La CCT. `organisation_id` nul = convention partagée, en lecture seule pour tous les espaces (HORECA, aides et soins, gardiennage, US9) |
| `regles_convention` | via la CCT | Les sept blocs (`bloc_convention`), chacun avec son JSON de règles et son drapeau `complet` |
| `grilles_salaires_convention` | via la CCT | Les grilles de salaire |
| `conventions_de_la_societe` | `societe_id` | Rattachement société ↔ CCT, avec période et portée (`portee_convention`) |
| `conventions_du_contrat` | via le contrat | Rattachement contrat ↔ CCT, même principe |

Le fait que `organisation_id` soit **nullable** est un point à connaître : une requête d'export qui
filtrerait sur la seule organisation du demandeur ferait disparaître les CCT sectorielles. La suite
`portability` le vérifie explicitement.

## Domaine 4 — Salariés

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `salaries` | `societe_id` | Identité, qualification, résidence, et les colonnes **chiffrées** du matricule national et de l'IBAN |
| `fiches_retenue_impot` | `salarie_id`, `societe_id` | Fiche de retenue d'impôt |
| `statuts_salarie` | `salarie_id`, `societe_id` | Statuts protégés (`genre_statut_salarie`) : grossesse, allaitement, mandat de délégué, prime de réemploi, gérance |
| `handicaps_salarie` | `salarie_id`, `societe_id` | Taux de handicap reconnu, autorité, **par période sans chevauchement** |
| `enfants_salarie` | `salarie_id`, `societe_id` | Enfants. Le refus des attentions (`refus_partage`) déclenche `fn_child_privacy`, qui **efface** nom et sexe en base : seule la date de naissance subsiste, pour établir les droits à congé |
| `documents` | `salarie_id`, `societe_id` | Métadonnées et chemin de stockage. Contrainte d'unicité sur l'emplacement, pour permettre l'upsert lors d'une régénération |

**Migration 55 — recherche par nom.** `salaries.nom` et `salaries.prenom` portent
chacun deux index : un index fonctionnel sur `upper(...)` (égalité et préfixe), et un index
trigramme GIN (`pg_trgm`) qui sert la recherche **infixe** `ilike '%…%'` que `fn_employee_rows`
effectue réellement. `societes.raison_sociale` et `sites_client.name` ne portent, eux, que l'index
fonctionnel — aucun écran n'y fait de recherche infixe aujourd'hui. Voir
[architecture.md](architecture.md) pour l'explication de ce choix, posé comme cas d'école.

## Domaine 5 — Contrats

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `contrats` | `societe_id`, `salarie_id` | 37 colonnes : type (`genre_contrat` — CDI, CDD, saisonnier, apprentissage, intérim), statut, poste, dates, essai, heures, salaire, motif et bornes du CDD. **Migration 55** : contrainte d'exclusion GiST `one_active_contract_at_a_time` — un salarié n'a qu'un seul contrat au statut `active` dont la période recouvre celle d'un autre. Voir [moteur-de-regles.md](moteur-de-regles.md) |
| `avenants_contrat` | `contrat_id` | Avenants, journalisés par `fn_amend_contract` (migration 55) : motif, ce qui a changé (`changes`), qui a signé |
| `elements_remuneration` | `contrat_id` | Rémunération à partie variable (`genre_element_remuneration`). Reportée automatiquement sur le contrat suivant par un avenant |
| `prolongations_essai` | `contrat_id` | Prolongations d'essai par incapacité |
| `ruptures_contrat` | `contrat_id` | Rupture : motif, dates, indemnités |
| `agences_interim` | `organisation_id` | Agences d'intérim |

**Migration 55 — le cycle de vie du contrat devient une règle de schéma.** Jusqu'ici, rien
n'empêchait qu'un salarié se voie attribuer deux contrats `active` en même temps : seule la
discipline de saisie l'évitait. La contrainte d'exclusion interdit désormais qu'un `daterange`
`(date_debut, date_fin, '[]')` recouvre celui d'un autre contrat actif du même salarié — vérifié
avant pose sur les 319 contrats actifs de la base (zéro chevauchement), vérifié après pose par une
insertion volontairement en conflit, rejetée. `fn_amend_contract(p_contract, p_effective_date,
p_changes, p_reason)` est la seule voie de modification d'un contrat en cours : elle clôt l'ancien
la veille de la prise d'effet, reconstruit le nouveau depuis `to_jsonb(ancien)` — pour qu'une
colonne ajoutée plus tard soit reportée sans énumération manuelle —, reporte les lignes de
`elements_remuneration` et `conventions_du_contrat` encore en vigueur, et journalise dans
`avenants_contrat`. Le contrat qui en résulte part **non signé**. Détail dans
[api-serveur.md](api-serveur.md) et [moteur-de-regles.md](moteur-de-regles.md).

## Domaine 6 — Temps de travail

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `plannings` | `societe_id` | Le planning d'une semaine, avec son statut (`statut_planning` : `draft` / `published`) |
| `creneaux` | `planning_id`, `societe_id`, `salarie_id` | Les services |
| `modeles_creneau` | `societe_id` | Modèles réutilisables |
| `releves_temps` | `societe_id`, `salarie_id` | Le registre du temps réellement travaillé |
| `periodes_reference` | `societe_id` | La période de référence pour la moyenne hebdomadaire |
| `demandes_heures_sup` | `societe_id`, `salarie_id`, `planning_id` | Demande d'heures supplémentaires, avec son statut : `requested` → `hr_approved` → `approved` |
| `sites_client` | `societe_id` | **Migration 52.** Lieu d'intervention hors siège (chantier, site client, antenne) : adresse ou coordonnées, exigées à la saisie. `creneaux.site_client_id` (nul = au siège) y renvoie par clé composite `(id, societe_id)` |
| `distances_trajet` | via `reference_origine`/`reference_destination` (`employee:<uuid>`, `company:<uuid>`, `site:<uuid>`) | **Migration 52.** Cache de distances routières : une adresse n'est transmise au service externe qu'au premier calcul d'un couple. Porte sa `source` et sa date de calcul, jamais l'adresse elle-même |

Un salarié ne voit ses `creneaux` **que si le planning est publié**. C'est une politique RLS, pas un
filtre d'interface : `tests/rls.test.mjs` et `tests/publication.test.mjs` le vérifient tous deux.

## Domaine 7 — Absences

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `absences` | `societe_id`, `salarie_id` | Demandes et incapacités : type, dates, jours décomptés, statut (`statut_absence`), certificat |
| `alertes_conformite` | `societe_id`, `salarie_id` | Alertes persistées, avec leur gravité (`genre_severite`) et leur état (`etat_alerte`) |

## Domaine 8 — Rémunération et charges société

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `periodes_taux_societe` | `societe_id` | Classe d'activité, classe Mutualité, facteur accident, **par période sans chevauchement** |
| `donnees_financieres_societe` | `societe_id` | Bénéfice par exercice — base de l'enveloppe de primes participatives |
| `sinistres_accident_societe` | `societe_id` | Sinistralité |
| `primes` | `societe_id`, `salarie_id`, `contrat_id` | Primes : nature, montant, traitement fiscal, exercice |
| `attributions_titres_repas` | `societe_id`, `salarie_id` | Chèques-repas : nombre, valeur faciale, participation du salarié |

## Domaine 9 — Effectifs et portabilité

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `releves_effectif` | `societe_id` | Photographies d'effectif, pour la moyenne sur 12 mois |
| `journal_exports` | `organisation_id` | Registre des demandes d'export : genre du sujet, nombre d'objets, taille |

## Domaine 10 — Adresses et zones autorisées

**Migration 56.** Deux tables, hors du graphe de relations principal comme le reste du référentiel :
elles n'appartiennent à aucune société en particulier, mais qualifient les adresses saisies sur
`salaries`, `societes` et `sites_client`.

| Table | Isolation | Ce qu'elle porte |
|---|---|---|
| `zones_adresse` | — (lecture ouverte à tout authentifié) | Les zones où une adresse est acceptée : Luxembourg entier ; provinces de Liège, Namur, Luxembourg (BE) ; départements 54 et 57 (FR) ; Rhénanie-Palatinat et Sarre (DE). **8 lignes** sur la base déployée. Chaque zone porte sa `source`. Les deux zones allemandes ont `code_postal_du`/`code_postal_au` **nuls** et `verifie = false` — une contrainte (`address_zone_verified_needs_range`) interdit de se déclarer vérifié sans bornes |
| `controles_adresse` | `societe_id` (nullable) | Le **dernier verdict** de validation par objet (`entite_table`, `entite_id`), unique par paire. Une adresse `unknown` y reste visible — ce n'est pas un refus, c'est un signalement à reprendre |

`fn_validate_address(country, postal, city)` répond `ok`, `outside` ou `unknown` — jamais un
booléen : « on ne sait pas » n'est pas « non ». Le déclencheur `check_address`, posé sur les trois
tables citées plus haut, n'appelle cette fonction **que si l'adresse a changé** (comparaison à
`old`), et **refuse l'écriture** sur un verdict `outside`. Un verdict `unknown` est accepté et
enregistré : le moteur ne bloque que ce qu'il sait situer hors zone, jamais ce qu'il ignore. Détail
des fonctions dans [api-serveur.md](api-serveur.md), principe dans
[moteur-de-regles.md](moteur-de-regles.md).

Pourquoi les bornes allemandes sont vides plutôt qu'approximatives : les codes postaux allemands ne
se rattachent pas proprement à un Land — la Rhénanie-Palatinat partage des préfixes avec la Hesse,
la Sarre et le Bade-Wurtemberg. Écrire un intervalle plausible aurait accepté ou refusé des adresses
à tort. La règle 7 du CLAUDE.md — pas de valeur légale ou administrative inventée — s'applique donc
aussi à un intervalle postal.

---

## Types énumérés

20 types au total. Les principaux :

| Type | Valeurs |
|---|---|
| `role_application` | administrateur, gestionnaire, manager de service, salarié |
| `genre_organisation` | `fiduciary`, `company` |
| `genre_contrat` | `cdi`, `cdd`, `seasonal`, `apprenticeship`, `interim` |
| `statut_contrat` · `statut_planning` · `statut_absence` | cycles de vie |
| `famille_parametre` | `social`, `ccss`, `fiscal`, `worktime`, `leave`, `contract`, `headcount` |
| `bloc_convention` | `salary_grid`, `worktime`, `leave`, `primes`, `surcharges`, `notice_probation`, `custom_holidays` |
| `portee_convention` | `sector`, `harassment`, `categorie_professionnelle`, `department`, `company` |
| `genre_severite` | `blocking`, `warning`, `info`, `ok` |
| `genre_sexe` | `male`, `female`, `unspecified` |
| `genre_qualification` · `genre_residence` · `classe_impot` · `periodicite_impot` · `categorie_absence` · `genre_statut_salarie` · `etape_document` · `genre_element_remuneration` · `etat_alerte` | — |

Ajouter une valeur à un type énuméré **doit se faire dans sa propre migration** : PostgreSQL
interdit d'utiliser une valeur d'enum dans la transaction qui l'ajoute. Les migrations 20 et 28
existent uniquement pour cela.

---

## Ce que la traduction vers Oracle et MySQL ne porte pas

Les fichiers `schema/oracle.sql` et `schema/mysql.sql` listent en clair, à la fin, **43 points**
non traduits : contraintes `CHECK` reposant sur des expressions PostgreSQL, références à
`auth.users` propres à Supabase Auth, et surtout les **contraintes d'exclusion** — remplacées par
un déclencheur généré table par table. Le détail est dans [bases-de-donnees.md](bases-de-donnees.md).

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [architecture.md](architecture.md) — la place de la base dans l'ensemble
- [moteur-de-regles.md](moteur-de-regles.md) — comment `parametres_legaux` est lu
- [api-serveur.md](api-serveur.md) — les fonctions qui lisent ces tables
- [bases-de-donnees.md](bases-de-donnees.md) — le même schéma sur Oracle et MySQL
- [couverture-droit-du-travail.md](couverture-droit-du-travail.md) — les notions qu'aucune table ne représente
