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

Le moteur de règles est écrit en PL/pgSQL : **272 fonctions, environ 147 Ko de
source**, qui portent l'intégralité du droit du travail luxembourgeois appliqué
par l'outil. Oracle et MySQL ne l'exécutent pas.

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

- PostgreSQL : Row Level Security, en place sur les 47 tables.
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
même jour — n'ont d'équivalent ni sur Oracle ni sur MySQL. Un déclencheur les
remplace, généré table par table. Côté Oracle il est de niveau instruction et
non de niveau ligne : un déclencheur ligne qui interroge sa propre table lève
ORA-04091.

Les contraintes `CHECK` qui s'appuient sur des expressions PostgreSQL
(`daterange`, opérateurs JSON, expressions régulières, appels au moteur) ne sont
pas traduites, et figurent dans la liste finale.
