# Feuille de route — les douze chantiers

Ce document est le **point de reprise**. Il suit, section par section, la spécification du
12 septembre 2026 : ce qui est fait, ce qui est en cours, ce qui attend une décision, et dans
quel ordre la suite se déroule.

Il est tenu à jour à chaque étape. Si le travail s'interrompt, c'est ici qu'on reprend — pas
dans l'historique d'une conversation.

**État général au 12 septembre 2026** : 143 migrations appliquées, 85 tables, **958 colonnes
toutes commentées**, 190 vérifications en six suites, 0 échec, build à 0 erreur TypeScript,
schémas Oracle et MySQL régénérés à **0 point non traduit**, dépôt et base réconciliés.

---

## Tableau de bord

| § | Chantier | État | Bloqué par |
|---|---|---|---|
| 1 | Français intégral (code, tables, colonnes) | ◐ **Préparé** — dictionnaire, migration et outil prêts | **Votre autorisation** d'appliquer la migration 76 |
| 1b | Commentaires sur toutes les tables et colonnes | ✅ **Fait** — 85/85 tables, 958/958 colonnes | — |
| 2 | Congés : statut « proposé », contre-proposition | ✅ **Fait** — migration 65 | — |
| 3 | CHECK de liste → tables de domaine | ✅ **Fait** | — |
| 4 | Bi-temporalité, `fin_validite` non nul au 31/12/2037 | ✅ **Fait** — migration 70, les 13 tables héritées | — |
| 5 | Codes pays ISO-3, `frontalier_xxx` | ✅ **Fait** — migrations 67b et 67f | — |
| 6 | `VARCHAR2(n CHAR)` sur Oracle | ✅ **Fait** | — |
| 7 | Sévérité CCSS + ordonnanceur natif | ✅ **Fait** — `pg_cron` installé, tâche active | — |
| 8 | Sexe déclaré / sexe légal + RBAC médical | ◐ **Sexe fait**, RBAC médical à écrire | — |
| 9 | Quatre adresses + optimisation des tournées | ◐ Adresses faites (67, 67g) | `DISTANCE_API_KEY` |
| 10 | Primes de pénibilité, insalubrité, danger | ✅ **Fait** — trois niveaux + calcul | — |
| 11 | Self-service et consentements | ✅ **Fait** — migrations 68 et 68b | — |
| 12 | Santé, enfants, dispatching | ✅ **Fait** — migrations 68 et 68b | — |

✅ fait · ◐ commencé · ○ à faire

---

## 1. Français intégral ◐ — **préparé, en attente d'autorisation**

Le dernier chantier structurel. Tout est prêt ; l'application sur la base demande votre
autorisation, le connecteur ayant refusé une migration qui renomme 55 tables en service.

### Ce qui est fait

**Le dictionnaire** — [`tools/renommage.py`](../tools/renommage.py). C'est la pièce à relire :
il ne contient que des noms, séparé de l'outil qui les applique. **57 tables** et
**328 colonnes**, vérifiés contre le catalogue réel : rien d'oublié, rien d'inventé, aucune
collision — y compris le cas sournois de deux colonnes d'une *même* table qui aboutiraient au
même nom français (`date_debut` et `date_debut` deviennent tous deux `date_debut`).

La règle suivie est celle des tables que vous aviez déjà nommées : nom d'abord et qualificatif
ensuite (`date_debut`), pluriel pour les tables, **aucun accent dans un identifiant** — Oracle
et MySQL ne les traitent pas pareil —, et les sigles métier conservés (`cct`, `ccss`, `iban`,
`rcs`, `cdd`).

**La migration** — [`20260912110907_76_tables_en_francais.sql`](../luxrh/supabase/migrations/20260912110907_76_tables_en_francais.sql),
écrite, **non appliquée**.

**L'outil de réécriture du code** — [`tools/renommer.py`](../tools/renommer.py).

### Le piège qu'il fallait voir

PostgreSQL stocke le corps d'une fonction PL/pgSQL comme du **texte**. Il ne suit donc pas un
renommage de table. Les vues et les politiques RLS, elles, sont conservées sous forme analysée
et suivent automatiquement — ce qui rend le piège d'autant plus traître : on renomme, tout
paraît tenir, et les **cent cinquante fonctions du moteur tombent au premier appel**.

La migration reconstruit donc chaque fonction depuis sa propre définition, noms substitués,
dans le même bloc que le renommage. `\m` et `\M` sont les bornes de mot de PostgreSQL et le
souligné y compte comme lettre : `\mcontracts\M` ne peut pas mordre dans
`fn_contract_compliance` ni dans `contrat_id`. C'est cette propriété qui rend la substitution
textuelle sûre sur des identifiants.

### Trois blocs, et pourquoi

La consigne était « d'un bloc, sinon l'application ne démarre plus en cours de route ». C'est
juste — et c'est pour cela qu'on découpe. Chaque bloc est **complet en lui-même** : base et
code renommés ensemble, construction et 190 vérifications au vert avant le suivant.
L'application n'est jamais à moitié renommée ; elle est à moitié *traduite*, ce qu'elle était
déjà (18 tables l'étaient avant de commencer).

| Bloc | Portée | Méthode | Risque |
|---|---|---|---|
| **A** | 55 tables | Remplacement mot à mot partout | Nul : un nom de table ne désigne qu'une table |
| **B** | 263 colonnes à nom composé | Idem | Nul : `brut_mensuel` ne peut venir que de la base |
| **C** | 43 colonnes à nom simple | **Littéraux de chaîne uniquement** | Réel, d'où le traitement à part |

Le bloc C est le seul délicat. En TypeScript, `name` est aussi bien une colonne qu'une
propriété de `Error`, un attribut HTML, un champ de `File` ; `status`, `label`, `key`, `year`,
`unit` de même. Les remplacer partout casserait le code **sans que rien ne le signale avant
l'exécution**. Ils ne sont donc touchés que dans les chaînes — là où la base est forcément en
jeu — et le compilateur TypeScript sert de filet pour le reste : après régénération des types,
il désigne chaque accès de propriété devenu faux, fichier et ligne.

### Mesure de l'ampleur

| | Tables | Colonnes |
|---|---|---|
| React (hors types générés) | 310 occurrences / 25 fichiers | 2 300 / 33 |
| Streamlit | 136 / 6 | 844 / 8 |
| Tests | 203 / 6 | 570 / 7 |
| Documentation | 354 / 15 | 587 / 16 |

Vérifié avant d'écrire quoi que ce soit : **aucun nom français cible n'est déjà utilisé comme
identifiant** dans le code. Les `contrats`, `societes`, `salaries` qu'on y trouve sont du texte
d'interface, des commentaires et des chemins de route — jamais des variables.

### Pour lancer

```bash
# 1. la base — demande votre autorisation
#    (appliquer luxrh/supabase/migrations/20260912110907_76_tables_en_francais.sql)
# 2. le code, dans la foulée
luxrh-py/.venv/Scripts/python tools/renommer.py tables --ecrire
# 3. les types, la construction, les 190 vérifications
```

Un renommage s'annule par le renommage inverse : l'opération est réversible.

### 1b. Commentaires

| | Couverture |
|---|---|
| Tables | **75 / 75** |
| Colonnes | **836 / 836** |

Fait en trois temps, et le découpage a son intérêt.

**Migration 71 — les colonnes structurelles, par une boucle.** Environ 350 des 519 colonnes
non commentées étaient les mêmes d'une table à l'autre : `id`, `cree_le`, `organisation_id`,
`salarie_id`, `debut_validite`. Les écrire une par une aurait produit 350 variantes d'un même
texte, promises à diverger. Un texte unique par nom de colonne, posé par une boucle qui
**n'écrase jamais** un commentaire existant — celui-ci a été pensé pour sa table, il est
toujours meilleur.

**Migrations 72, 72b, 72c — les 273 colonnes métier, à la main.** Celles dont le sens dépend
de la table : le `code` d'un pays et le `code` d'une convention ne disent pas la même chose.
Un texte générique y aurait été faux, et un commentaire faux est pire que pas de commentaire.

**Le critère d'écriture** : dire ce que le nom ne dit pas. « Identifiant du salarié » sur
`salarie_id` n'apprend rien ; « la ligne suit le salarié et non son contrat, elle survit à
l'avenant » apprend quelque chose.

Conséquence : `schema/oracle.sql` et `schema/mysql.sql` portent désormais 836 `comment on
column`, et la liste « ce qui n'a pas été traduit » est **vide** — 0 point, contre 43 en début
de session et 1 encore hier.

---

## 2. Congés : proposition et contre-proposition

**Fait** : la valeur `proposed` existe dans `statut_absence` (migration 60, isolée à cause du
piège des énumérations).

**À écrire** :

- colonne `absence_parente_id` avec clé étrangère vers `absences`, pour chaîner demande et
  contre-propositions ;
- le refus seul devient impossible : refuser oblige à proposer une alternative, qui naît au
  statut `proposed` ;
- le salarié accepte ou refuse la contre-proposition — un refus rouvre le tour à l'employeur ;
- garde-fou contre la boucle infinie : profondeur de chaîne bornée, à fixer.

**Suivi CAE** : relance annuelle du salarié pour déclarer le solde de jours restants par enfant.
Suppose un ordonnanceur — voir § 7.

---

## 3. Tables de domaine ✅

Huit contraintes `CHECK (colonne IN (…))` converties en tables de référence datées, reliées par
clés étrangères :

`ref_statut_verification_adresse` · `ref_unite_essai` · `ref_action_acces` · `ref_lien_enfant` ·
`ref_sujet_export` · `ref_statut_heures_sup` · `ref_compensation_heures_sup` · `ref_nature_prime`

On ajoute une valeur par `insert`, on la retire en la datant. Une valeur échue reste lisible
dans les lignes qui la portent — ce qu'un `check` ne permet pas.

---

## 4. Bi-temporalité

**Fait partout** — migration 70. Les 16 tables neuves portaient déjà `debut_validite` au
01/01/1970 et `fin_validite` **non nul** au 31/12/2037 ; les 13 tables héritées les ont
rejointes : `droits_absence`, `conventions_collectives`, `conventions_de_la_societe`,
`periodes_taux_societe`, `conventions_du_contrat`, `elements_remuneration`,
`handicaps_salarie`, `fiches_retenue_impot`, `parametres_legaux`, `categories_sanction`,
`types_sanction`, `tranches_impot`, `credits_impot`.

**Le moteur n'a pas eu à être réécrit**, contrairement à ce qui était craint ici : les
conditions de la forme `fin_validite is null or fin_validite > J` continuent de fonctionner, la
première moitié devenant simplement toujours fausse. Remplacer NULL par une date **rétrécit**
l'intervalle, et un rétrécissement ne peut pas créer de chevauchement : les contraintes
d'exclusion GiST sont restées satisfaites.

**Le front, lui, a cassé — et c'est là qu'était le vrai risque.** Six écrans sélectionnaient la
version en vigueur par `!row.fin_validite` **seul**, sans comparaison de repli. Ce test devient
toujours faux : le tableau de bord aurait perdu l'indice, l'assistant contrat la durée légale
de travail, l'écran Réglages toutes ses valeurs — **silencieusement**, sans une seule erreur.
Corrigé par `estEnVigueur()` dans `src/lib/format.ts`, et `sansFin()` pour l'affichage, afin que
la question ne se repose pas. Le front Streamlit était sauf : il écrivait partout la condition
complète.

Une migration de base peut casser une interface sans qu'aucune des deux ne le signale. C'est
l'argument des trois niveaux de défense pris à l'envers : il faut vérifier les trois.

> **Note sur le motif.** La limite de 2038 vise le type `TIMESTAMP` de MySQL. Nos `fin_validite`
> sont des `DATE` (MySQL : jusqu'en 9999) et nos horodatages sont émis en `DATETIME(6)`, sans
> cette limite. La sentinelle reste un bon choix — pour une autre raison : elle supprime les
> tests de nullité disséminés dans le moteur. Convention retenue de bout en bout.

**Historisation stricte** : à l'écriture, la ligne courante est close à la veille et une
nouvelle est insérée. Indispensable pour un recalcul rétroactif — une prime de trajet sur la
première quinzaine avant un déménagement.

---

## 5. Codes pays ISO-3

**Fait** : `frontalier_fra`, `frontalier_bel`, `frontalier_deu` ajoutés à `genre_residence`.

**Reste** : dater les valeurs à deux lettres comme échues, une fois les deux fronts migrés. Les
retirer maintenant casserait les types TypeScript et Python. Et normaliser `zones_adresse.country`
et `salaries.country` de alpha-2 vers alpha-3.

---

## 6. `VARCHAR2(n CHAR)` ✅

451 déclarations en sémantique caractère, **zéro** en sémantique octet. Un « é » compte pour un
caractère, non pour deux — une colonne `VARCHAR2(4000)` en octets ne tenait que 2 000 caractères
accentués.

---

## 7. Sévérité CCSS et ordonnanceur

**Fait** : valeur `problem` ajoutée à `genre_severite`. `blocking` est conservé : les deux ne
disent pas la même chose — `problem` constate un retard, `blocking` empêche une opération.

**À écrire** — logique temporelle sur le délai d'envoi à la CCSS :

| Sévérité | Condition |
|---|---|
| `info` | 7 jours avant l'échéance |
| `warning` | 2 jours avant l'échéance |
| `problem` | délai dépassé |
| `blocking` | conservé pour ce qui empêche une opération |

**Écrit et appliqué** — migration 66 pour `fn_severite_pour_echeance` et
`fn_recalculer_severites(date)`, migration 73 pour la planification.

**`pg_cron` 1.6.4 est installé** (schéma `pg_catalog`) et la tâche est enregistrée :

| | |
|---|---|
| Tâche | `luxrh_severites_ccss` |
| Planification | `15 2 * * *` — 02h15, après la bascule de date, avant les utilisateurs |
| Commande | `select public.fn_recalculer_severites(current_date)` |

La commande d'installation, si la base est recréée ailleurs :

```sql
create extension if not exists pg_cron;   -- ou Database > Extensions sur Supabase
```

**Ordonnanceur de base, pas cron système** — pour trois raisons écrites en tête de la
migration 73 : la tâche suit la sauvegarde, elle ne dépend d'aucun hôte (les deux fronts
n'ont pas de serveur commun), et elle se porte. Les équivalents `DBMS_SCHEDULER` et
`EVENT SCHEDULER` sont écrits en fin de ce même fichier.

**Éprouvée sur données réelles, pas seulement appelée.** Un premier appel a renvoyé
« 0 alerte examinée » : la table `alertes_conformite` est vide sur ce déploiement, le zéro
était donc honnête — mais il ne prouvait rien. Cinq alertes d'essai ont été insérées avec une
sévérité **volontairement fausse**, pour que « ne rien changer » fasse échouer le test :

| Échéance | Sévérité posée | Obtenue |
|---|---|---|
| J+10 | `problem` | `info` |
| J+7 | `problem` | `info` |
| J+2 | `problem` | **`warning`** |
| J−1 | `info` | **`problem`** |
| J−1, `blocking` | `blocking` | `blocking` — **non touchée** |

4 examinées, 4 corrigées, `blocking` laissée intacte, lignes d'essai supprimées. C'est la leçon
de la migration 64c appliquée d'avance : essayer sur les données réelles, pas sur l'idée qu'on
s'en fait.

---

## 8. Sexe déclaré / sexe légal ◐

### Ce qui est fait, et pourquoi ça comptait

**Un défaut corrigé, de 50 % d'erreur.** `fn_national_id_sex` lisait la **position 10** du
matricule — le chiffre du milieu du numéro d'ordre. La parité d'un nombre à trois chiffres se lit
sur son dernier chiffre, la **position 11**. `fn_make_national_id` ajustait le même mauvais
chiffre, si bien que lecteur et générateur s'accordaient entre eux et s'écartaient tous deux de
la règle.

Mesuré : **160 matricules sur 322** contredisaient le sexe déclaré. Exactement la moitié — la
signature d'un tirage à pile ou face, donc d'une règle fausse.

| | Avant | Après |
|---|---|---|
| Position lue | 10 | **11** |
| Écarts sexe déclaré / dérivé | 160 / 322 | **0 / 322** |
| Matricules valides (Luhn + Verhoeff) | 322 | **322** |

`salaries.sexe_legal` est **recalculé à chaque écriture** par déclencheur : toute valeur soumise
est ignorée. La colonne est non saisissable **par construction**, pas par interdiction.

> **Le masquage au salarié a été écarté, et c'est délibéré.** L'article 15 du RGPD donne à la
> personne l'accès à ses données, y compris dérivées. Cacher au salarié ce que les RH voient
> fabriquerait le risque qu'on cherchait à écarter. Le salarié voit son sexe légal ; il ne peut
> pas le changer.

### Reste : le RBAC médical

Le dispatching ne doit **jamais** voir la donnée médicale brute — pathologies, allergies. Il ne
voit que des indicateurs booléens dérivés :

- `interdiction_lieu_chats` — dérivé d'une allergie aux chats ;
- `necessite_meche_cauterisation` — la personne requiert une mèche de cautérisation, médicament
  cutané externe qui coagule au contact du sang ;
- `diabetique_secours` — accessible aux secours, pour guider l'administration de sucre ou
  d'insuline.

Seuls les rôles « RH d'urgence » et « médecine du travail » atteignent la donnée brute.

---

## 9. Quatre adresses ○

**Décidé** : une table `adresses_salarie` avec un type d'adresse et des dates de validité.

Quatre types, **tous obligatoirement valides sur toute période** :

1. **Domicile légal** — l'adresse officielle. Seule base des distances et indemnisations fiscales.
2. **Résidence actuelle** — où la personne vit effectivement.
3. **Dernière étape pour venir** — l'arrêt juste avant le travail (crèche, école).
4. **Première étape pour repartir** — le premier arrêt après le travail.

**Règles retenues** :

- couverture **continue** depuis la candidature jusqu'après le départ — une erreur de salaire
  découverte plus tard exige de pouvoir informer la personne ;
- par défaut, le domicile légal est **copié dans les quatre** ;
- l'agencement des tournées client utilise les étapes 3 et 4, pour épouser le trajet réel.

Contrainte d'exclusion GiST par salarié et par type, pour interdire tout recouvrement ; et
contrôle de couverture continue, pour interdire tout trou.

---

## 10. Primes de conditions de travail ✅

**Le principe** : une prime de condition n'est pas une constante du contrat. Elle est due quand
la personne travaille *effectivement* dans la condition — sur ce chantier, entre telle et telle
heure. D'où trois niveaux, et non un.

| Niveau | Table | Ce qu'il porte |
|---|---|---|
| 1 | `ref_condition_travail` | Ce qu'est une condition : pénibilité, insalubrité, danger, et ce que chaque CCT ajoute |
| 2 | `cct_regle_prime` | Ce que la convention prévoit : taux **ou** montant, assiette, unité, seuil d'exposition, article, `url_source` |
| 3 | `creneau_condition` | Ce qui a été réellement fait : qui, quand, où, **de quelle heure à quelle heure** |

`fn_primes_conditions(salarié, du, au)` croise les trois. Le niveau 3 est le maillon qui
manquait : sans lui, on connaît le taux sans savoir qui y a droit ni combien de temps.

**Garanties posées par le schéma** :

- un taux **ou** un montant, jamais les deux — une règle ambiguë ne se calcule pas ;
- un taux exige une assiette ;
- `url_source` obligatoire et non vide : une règle conventionnelle sans source ne doit pas
  servir à payer ;
- `minutes` calculé par la base, minuit franchi compris ;
- un créneau se rattache au planning **ou** au registre du temps — flottant, il ne se
  rapporterait à aucune prestation.

**Ce que la fonction ne fait jamais** : deviner. Un créneau sans règle ressort dans `sans_regle`,
une assiette non résoluble dans `non_calculables`, et le total est toujours accompagné de ce
qu'il ne couvre pas.

**Un défaut trouvé au premier essai réel** (migrations 64b puis 64c) : la résolution de la
convention n'interrogeait que `conventions_du_contrat`, table **vide** sur le
déploiement — le rattachement se fait au niveau de la société. Tous les créneaux ressortaient
« sans règle ». `fn_applicable_cbas` faisait déjà le travail sur les trois niveaux. *Avant
d'écrire une résolution, vérifier que le moteur n'en a pas déjà une.*

**Reste** : la saisie des règles depuis les textes déposés à l'ITM — aucun taux n'est inventé —
et l'écran de planning qui associe les conditions aux créneaux.

---

## 11. Self-service et consentements ○

- le salarié modifie lui-même courriel, mot de passe, nom et prénom ;
- consentement : interdiction d'apparaître sur les photos de la société ;
- consentement : souhait de ne pas apparaître — droit à l'oubli.

---

## 12. Santé, enfants, dispatching ○

- le parent met à jour lui-même les fiches de ses enfants ;
- par enfant : interdiction photo aux événements, souhait d'invitation (Saint-Nicolas, journée
  des familles), situation de handicap et pourcentage ;
- fiche santé : allergies, pathologies, médecin traitant — pour les salariés et les enfants ;
- règle de dispatching : un salarié allergique aux chats ne peut pas être envoyé dans un lieu
  signalant des chats ;
- sécurité diabète : information immédiatement accessible aux secours.

---

## Ordre d'exécution retenu

1. ✅ Sexe déclaré / légal — migrations 62 et 63
2. ✅ Primes de conditions — migrations 64 à 64d
3. ✅ Absences : contre-proposition et chaînage — migration 65
4. ✅ Sévérité CCSS — migrations 66 et 73 ; `pg_cron` 1.6.4 installé, tâche nocturne active et éprouvée
5. ✅ Quatre adresses et ISO-3 — migrations 67, 67b, 67e, 67f, 67g
6. ✅ Consentements, santé, enfants — migrations 68 et 68b
7. ✅ `fin_validite` non nul sur les 13 tables héritées — migration 70
8. ✅ Les commentaires de colonne — migrations 71, 72, 72b, 72c : **836 sur 836**
9. ◐ Le français intégral — dictionnaire, migration 76 et outil de réécriture prêts ; **en attente d'autorisation**
10. ✅ Vérification de la cohérence du projet — outillée, `tools/verifier_coherence.py`, **0 écart**

**Fait en cours de route, hors liste** : la réconciliation du dépôt et de la base
(13 migrations sans fichier écrites, 27 fichiers mal datés renommés, un fichier
récapitulatif dangereux supprimé) et l'outil qui empêche la divergence de revenir —
voir [`ecarts-a-corriger.md`](ecarts-a-corriger.md) § 0.

---

## Ce qui attend une action de votre part

| Action | Pourquoi |
|---|---|
| Créer le compte administrateur | Jamais écrit dans le dépôt, qui est public. Voir `fn_create_app_user` |
| `dblink_conninfo` dans `secrets_application` | Sans quoi la trace d'accès n'est pas autonome |
| `DISTANCE_API_KEY` | L'Edge Function de distance est inerte sans elle |
| ~~Installer `pg_cron`~~ | ✅ Fait le 12 septembre — 1.6.4, tâche `luxrh_severites_ccss` active |
| ~~Réparer l'historique 43/44~~ | ✅ Fait le 12 septembre. Lancer `tools/dump_migrations.py` avant tout `db push` |
| Charger les valeurs légales manquantes | `accident_class_rates`, `mileage_allowance_eur_per_km`, `sanction_notification_deadline_days`, barème d'impôt |

---

## 13. Vérification de cohérence ✅

LuxRH tient en quatre morceaux qui peuvent dériver sans que rien ne proteste : les migrations du
dépôt, le schéma déployé, les deux interfaces, et la documentation. Chaque dérive rencontrée
jusqu'ici l'a été **par hasard, et tard**. Aucune n'était difficile à détecter ; toutes étaient
difficiles à *remarquer*.

[`tools/verifier_coherence.py`](../tools/verifier_coherence.py) fait les sept contrôles en un
appel, via PostgREST et avec les droits d'un administrateur ordinaire — pas ceux du
propriétaire de la base :

| Contrôle | Ce qu'il attrape |
|---|---|
| Fonctions appelées / fonctions existantes | Un front qui appelle une fonction absente : erreur visible seulement sur l'écran d'un utilisateur |
| RLS sur toutes les tables | La règle 6, vérifiée au lieu d'être supposée |
| Fonctions ouvertes à `anon` | Ce qu'un visiteur non authentifié peut exécuter |
| Commentaires de tables et de colonnes | La couverture, chiffrée |
| Liens relatifs de la documentation | Un lien mort ne se voit que quand on le suit |
| Nombres annoncés dans la documentation | « 53 tables » écrit quand la base en a 75 |
| Dépôt contre base | Délégué à `dump_migrations.py`, pour n'avoir qu'une seule vérité |

```bash
luxrh-py/.venv/Scripts/python tools/verifier_coherence.py     # sortie non nulle s'il trouve
```

**Il ne corrige rien.** Un écart demande une décision : c'est parfois la base qui a raison,
parfois la documentation. L'outil dit ce qui diverge et s'arrête là.

**Deux leçons de sa mise au point**, qui valent au-delà de lui. Le premier lancement a rendu
223 écarts, dont 188 « fonctions ouvertes à `anon` » : toutes des routines internes de
`btree_gist`. Le second en a rendu 35, dont vingt « la documentation annonce 13 tables » —
alors que la phrase parlait des treize tables *héritées*, pas du total. Dans les deux cas le
défaut était dans le contrôle, pas dans le projet : **un rapport qui noie un vrai signal sous
des faux ne sera pas lu, donc ne servira à rien.** Un contrôle trop bavard est un contrôle
mort.

Les deux vrais écarts qu'il restait ont été corrigés : les chiffres périmés de six documents,
et `btree_gist` déplacée de `public` vers `extensions` (migration 75) — le dernier point ouvert
de la revue de sécurité.

**État : 0 écart.**

---

## Voir aussi

- [`index.md`](index.md) — sommaire de la documentation
- [`ecarts-a-corriger.md`](ecarts-a-corriger.md) — la fiche de passation, défaut par défaut
- [`securite-et-conformite.md`](securite-et-conformite.md) — sécurité, RGPD, AI Act
- [`personnel-et-horaires.md`](personnel-et-horaires.md) — le plan d'achèvement des deux domaines
- [`../CLAUDE.md`](../CLAUDE.md) — les règles non négociables, points 1 à 12
