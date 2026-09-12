# Choix de la base de données

    streamlit run app.py -- --db supabase
    streamlit run app.py -- --db oracle --dsn hote:1521/XEPDB1 --user luxrh
    streamlit run app.py -- --db mysql  --dsn hote:3306/luxrh  --user luxrh

À défaut d'argument, `LUXRH_DB` fait foi, puis `supabase`. Le mot de passe se lit
dans `LUXRH_DB_PASSWORD` — jamais en ligne de commande, où il resterait dans
l'historique du shell.

Un nom de base inconnu, un DSN manquant : la connexion échoue immédiatement en
nommant ce qui manque. Rien n'est deviné, parce qu'une connexion approximative
échoue plus tard et plus mal.

---

## Ce que le choix change, et ce qu'il ne change pas

|  | Supabase / PostgreSQL | Oracle | MySQL |
|---|---|---|---|
| Schéma | référence | `schema/oracle.sql` | `schema/mysql.sql` |
| Lecture, écriture | oui | oui | oui |
| Export et import de portabilité | oui | oui | oui |
| **Moteur de règles** | **oui** | **non** | **non** |
| Isolation par ligne | RLS, en base | VPD, à écrire | **aucune** |

### Le moteur ne se déplace pas

Le moteur de règles est écrit en PL/pgSQL : **111 fonctions, environ 204 Ko de
source** (`sum(octet_length(prosrc))`, vérifié sur la base déployée) — 102 fonctions `fn_*` et 9 fonctions de contrôle d'accès ou déclencheurs
techniques (`auth_org_id`, `has_company_access`, `has_role`, `handle_new_user`…)
utilisées par les politiques RLS — qui portent l'intégralité du droit du travail
luxembourgeois appliqué par l'outil. Oracle et MySQL ne l'exécutent pas.

> Un décompte brut de `pg_proc` sur le schéma `public` compte aussi les fonctions
> de l'extension `btree_gist`, qui n'appartiennent pas au projet — c'est l'erreur
> corrigée dans [ecarts-a-corriger.md](ecarts-a-corriger.md). Le chiffre à retenir
> est celui des fonctions hors extension. Ces 111 fonctions installées portent 110
> noms distincts — `fn_make_national_id` est surchargée.

Sur ces deux bases, toute évaluation de règle lève `EngineUnavailable` avec le
motif, plutôt que de rendre une valeur vraisemblable. C'est délibéré : un délai
de préavis approximatif ne reste pas à l'écran, il se recopie dans un contrat.

On pourrait porter le moteur en PL/SQL et en procédures MySQL. **C'est
déconseillé.** Il en résulterait trois copies de la loi luxembourgeoise, à
modifier trois fois à l'identique à chaque changement légal. La divergence est
alors une question de temps, et elle se lit sur une fiche de paie.

Trois usages honnêtes d'une base Oracle ou MySQL :

- **reprendre ou archiver** les données — le cas visé ici ;
- **héberger le dossier** pendant que le moteur reste sur PostgreSQL ;
- porter le moteur, en acceptant ce qui précède.

### L'isolation entre organisations, sur MySQL

C'est le point le plus sérieux. L'un des invariants du projet est que
l'isolation entre organisations est **imposée en base, jamais dans l'interface** :
une requête directe d'un locataire ne peut pas atteindre les données d'un autre.

- PostgreSQL : Row Level Security, en place sur les 53 tables.
- Oracle : Virtual Private Database offre l'équivalent, mais les politiques
  restent à écrire — le schéma émis ne les contient pas.
- **MySQL : il n'existe pas d'équivalent.** L'isolation devrait remonter dans
  l'application, ce qui contredit l'invariant.

Une implantation MySQL multi-locataires n'est donc pas défendable en l'état.
Mono-locataire, ou en reprise de données, elle l'est.

### Le navigateur ne se connecte pas à Oracle

L'application React parle à PostgREST. Un navigateur ne peut pas ouvrir une
connexion Oracle ou MySQL : pour ces bases, il lui faudrait une passerelle
serveur qui n'existe pas aujourd'hui. Le choix par argument porte donc sur
l'application Python, qui s'exécute côté serveur.

---

## `schema/oracle_audit_pipeline.sql` — écrit à la main, non généré

Ce fichier n'est **pas** produit par `tools/emit_portable_schema.py`. L'émetteur dérive des
**tables** depuis `schema/catalogue.json` ; il ne dérive pas de code procédural, qui n'a pas
d'équivalent mécanique d'un dialecte SQL à l'autre. `schema/oracle_audit_pipeline.sql` est donc
maintenu à la main, comme le reste du moteur le serait sur Oracle si ce portage était un jour
entrepris (voir « Le moteur ne se déplace pas » ci-dessus).

C'est le pendant Oracle de la migration
[`20260910190000_51_read_audit_pipeline.sql`](../luxrh/supabase/migrations/20260910181626_51_read_audit_pipeline.sql),
**appliquée** à la base déployée. Il reprend la même logique de lecture auditée
ligne à ligne avec les constructions natives d'Oracle : `PIPELINED` / `PIPE ROW` pour l'émission,
`TABLE(f(x))` pour la jointure latérale, et un vrai `PRAGMA AUTONOMOUS_TRANSACTION` là où PostgreSQL
doit passer par `dblink`, faute d'équivalent natif. Le détail du patron et la table de
correspondance sont dans [architecture.md](architecture.md).

Une différence à connaître : sur PostgreSQL l'identité de l'appelant vient de `auth.uid()` et
l'isolation est imposée par RLS ; Oracle ne porte pas le moteur LuxRH et n'a pas de RLS active dans
ce projet. Le fichier pose donc un contexte applicatif (`luxrh_ctx.set_identity`) que l'application
doit renseigner explicitement avant tout appel — sans quoi la fonction refuse de produire la moindre
ligne, en position fermée. Les données chiffrées (matricule national, IBAN) ne sont, elles,
volontairement pas portées par ce fichier : `pgcrypto` n'a pas d'équivalent porté sur Oracle dans ce
projet, et `luxrh-py/luxrh/backends.py` lève `EngineUnavailable` plutôt que de les exposer autrement.

---

## Créer le schéma sur une base neuve

    python tools/emit_portable_schema.py schema/catalogue.json schema/

Le catalogue se régénère depuis la base PostgreSQL de référence — la requête est
en bas de `tools/emit_portable_schema.py`. Rien n'est saisi à la main : le schéma
dérivé suit la base qui fait foi, sinon il diverge au premier changement.

Puis, pour repeupler le référentiel : exporter depuis l'implantation existante
(page **Portabilité**), et charger le fichier sur la nouvelle.

### Ce que la traduction ne porte pas

Les fichiers produits **listent en clair, à la fin, tout ce qui n'a pas été
traduit** — quarante-trois points aujourd'hui. Rien n'est omis en silence : une
contrainte perdue est un invariant perdu, et l'on ne s'en aperçoit qu'au moment
où elle aurait dû protéger.

Écarts assumés :

| PostgreSQL | Oracle | MySQL |
|---|---|---|
| `uuid` | `VARCHAR2(36)` | `CHAR(36)` |
| `boolean` | `NUMBER(1)` + contrainte | `TINYINT(1)` |
| `time` | `VARCHAR2(8)`, `'HH24:MI:SS'` | `TIME` |
| `timestamptz` | `TIMESTAMP WITH TIME ZONE` | `DATETIME(6)`, **en UTC** |
| énumérations | `VARCHAR2` + `CHECK` | `ENUM` |
| tableaux | `CLOB` JSON | `JSON` |

Les **contraintes d'exclusion** — celles qui interdisent à deux périodes de
validité de se recouvrir, et donc à un paramètre légal d'avoir deux valeurs le
même jour, ou depuis la migration 55 à un salarié d'avoir deux contrats actifs
qui se chevauchent — n'ont d'équivalent ni sur Oracle ni sur MySQL. Un
déclencheur les remplace, généré table par table par `tools/emit_portable_schema.py`.

### Les déclencheurs générés ne balayaient plus toute la table — correction indépendante du catalogue

La première version du générateur revérifiait **toute la table** à chaque écriture : un `count(*)`
sur l'auto-jointure complète `a join b on a.id <> b.id`. Correct, mais quadratique — et faux comme
principe, un déclencheur n'a pas à contrôler des lignes que personne n'a touchées. Deux corrections,
indépendantes l'une de l'autre :

- **Le déclencheur ne compare plus que les lignes écrites.** Sur MySQL, le déclencheur de niveau
  ligne compare directement `new` aux lignes existantes — il n'a jamais eu besoin d'énumérer la
  table entière, la version précédente le faisait quand même. Sur Oracle, un déclencheur **composé**
  remplace le déclencheur simple : la section `after each row` **collecte** les identifiants
  écrits par l'instruction en cours, la section `after statement` les **vérifie** une fois la table
  sortie de son état mutant. C'est ce qui évite `ORA-04091` (mutating table) sans recourir à un
  contournement fragile de type table temporaire globale.
- **`exists` remplace `count(*)`.** Un `count(*)` compte tous les conflits avant de conclure qu'il y
  en a au moins un ; `exists` s'arrête au premier. Sur Oracle, cela rend `rownum <= 1` superflu :
  la condition d'arrêt est désormais dans l'opérateur lui-même, pas dans une clause ajoutée après
  coup pour limiter les lignes lues.

**Ce que cela change concrètement** : sur une table de plusieurs centaines de milliers de lignes, la
version précédente du déclencheur coûtait un balayage complet à *chaque* insertion ou mise à jour,
sur *chaque* base cible ; la version corrigée ne compare que ce qui vient d'être écrit à ses
conflits potentiels. Le comportement observable — refuser un recouvrement de périodes — est
identique ; le coût ne l'est pas.

`schema/oracle.sql` et `schema/mysql.sql` ont été régénérés avec ce code corrigé, à partir d'un
catalogue lui aussi rafraîchi : **les deux portent les 75 tables de la base déployée**, 95
créations d'objets et **836 `comment on column`**. La liste « ce qui n'a pas été traduit » est
vide.

À noter, en miroir : le moteur PL/pgSQL déployé sur PostgreSQL n'a **jamais** utilisé de `count(*)`
comme test d'existence — ses comptages (effectifs, compteurs de licenciement collectif) sont de
vrais comptages, pas des vérifications de présence déguisées. L'anti-patron ne vivait que dans les
déclencheurs générés pour Oracle et MySQL, jamais dans le moteur lui-même.

Les contraintes `CHECK` qui s'appuient sur des expressions PostgreSQL
(`daterange`, opérateurs JSON, expressions régulières, appels au moteur) ne sont
pas traduites, et figurent dans la liste finale.

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [modele-de-donnees.md](modele-de-donnees.md) — les 75 tables de la base déployée, domaine par domaine (le schéma traduit ici, `schema/catalogue.json`, n'en porte encore que 47 : voir « Le schéma portable » dans [architecture.md](architecture.md))
- [moteur-de-regles.md](moteur-de-regles.md) — le moteur PL/pgSQL qui ne se déplace pas
- [demarrage.md](demarrage.md) — lancer l'application Python sur une autre base
- [architecture.md](architecture.md) — pourquoi le navigateur ne se connecte pas à Oracle
