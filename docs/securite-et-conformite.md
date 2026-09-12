# Sécurité, RGPD et AI Act

Revue de l'ensemble du dépôt et de la base déployée, menée le 10 septembre 2026. Elle
s'adresse à qui doit décider quoi corriger, et dans quel ordre. Chaque constat porte sa
preuve — une requête, un fichier, une ligne — et son état : corrigé, migration écrite, ou
ouvert.

Deux revues distinctes sont réunies ici parce qu'elles se recoupent : la protection des
données personnelles est d'abord une question de sécurité, et la question de l'AI Act se
tranche par un fait technique.

---

## Ce qui a été examiné

| Périmètre | Méthode |
|---|---|
| Base déployée | Interrogation du catalogue : droits d'exécution, RLS, politiques, déclencheurs, contraintes |
| Analyseur Supabase | `get_advisors` sécurité — 55 signalements dépouillés |
| Front React | Lecture de `src/`, recherche d'injection HTML, de secrets, d'appels non contrôlés |
| Front Streamlit | Idem, plus l'usage de `unsafe_allow_html` |
| Edge Function | `contract-pdf` : contrôle d'authentification |
| Migrations | Les 51 migrations d'alors, en particulier les octrois de droits |

---

## Constats de sécurité

| # | Constat | Gravité | État |
|---|---|---|---|
| 1 | Six fonctions de portabilité exécutables par le rôle `anon` | **Élevée** | **Corrigé** — migration 46 appliquée |
| 2 | Injection HTML possible dans le front Streamlit | **Élevée** | **Corrigé** |
| 3 | Trois fonctions de déclencheur et un utilitaire interne exposés en RPC | Moyenne | **Corrigé** — migration 46 |
| 4 | `alter default privileges` inopérant : le trou se rouvre à chaque migration | Moyenne | **Corrigé** — migration 46 |
| 5 | Aucune journalisation des accès en lecture | Moyenne | **Corrigé** — migrations 49 et 51 |
| 6 | `salaries`, `documents`, `fiches_retenue_impot` non auditées en écriture | Moyenne | **Corrigé** — migration 49 |
| 7 | La clé de chiffrement vit dans la base qu'elle protège | Moyenne | **Ouvert** |
| 8 | `search_path` mutable sur `fn_payload_rows` | Faible | **Corrigé** — migration 46 |
| 9 | Protection contre les mots de passe compromis désactivée | Faible | **Ouvert** — réglage Supabase |
| 10 | `btree_gist` installée dans le schéma `public` | Faible | **Ouvert** |
| 11 | `fn_company_rates` retombait en silence sur le taux de base | Moyenne | **Corrigé** — migrations 50 et 54 |
| 12 | Le détecteur de trous du référentiel était aveugle aux clés absentes | Moyenne | **Corrigé** — migration 50 |
| 13 | Transmission de l'adresse d'un salarié à un service tiers de distance | Moyenne | Encadré par conception — voir RGPD |

> **État après application, vérifié le 10 septembre 2026.** Les migrations 46 à 54 sont
> appliquées, ainsi que les migrations 55 à 57. L'analyseur ne signale plus **aucune** fonction exécutable par `anon`
> — il en signalait seize, dont les six points d'entrée de la portabilité — ni de `search_path`
> mutable. Les 190 vérifications des six suites passent, le build reste à zéro erreur.
>
> Restent, par conception : `secrets_application` sous RLS sans politique (c'est la protection), et
> 53 fonctions `security definer` appelables par un compte authentifié — le principe même du
> moteur, chacune contrôlant l'accès dans son corps.

### 1. Six fonctions de portabilité exécutables sans être connecté

Les six points d'entrée de la portabilité — `fn_export_self`, `fn_export_employee`,
`fn_export_company`, `fn_export_organization`, `fn_export_referential`,
`fn_import_referential` — sont en `security definer` et portaient `=X/postgres` dans leur
ACL, c'est-à-dire **`execute` accordé à PUBLIC**, dont `anon` hérite. Elles étaient donc
appelables sur `/rest/v1/rpc/…` sans authentification.

**La porte n'était pas ouverte.** Chacune contrôle l'accès dans son corps — `auth.uid()`,
`has_company_access`, `est_admin_organisation` — et échoue en position fermée pour un appelant
anonyme. Le risque n'est pas l'exfiltration immédiate : c'est qu'un seul verrou tenait là où
l'architecture en suppose deux. Une régression dans un de ces corps devenait une fuite de
données personnelles non authentifiée, sans autre barrière.

**Cause.** `create function` accorde `execute` à PUBLIC par défaut. La migration 16 avait
révoqué ce droit sur les fonctions existant alors, puis posé un `alter default privileges` —
mais celui-ci ne vaut que pour le rôle qui l'émet, et les fonctions appartiennent à
`postgres`. Les migrations 40 à 44 ont donc recréé le trou sans que rien ne le signale.

Seize fonctions étaient concernées au total.

### 2. Injection HTML dans le front Streamlit — corrigé

`luxrh-py/luxrh/design.py` produisait tout son balisage par interpolation de chaînes, rendu
avec `unsafe_allow_html=True`, **sans aucun échappement**. Or les textes affichés viennent du
moteur, qui compose ses messages avec des données saisies : un nom de salarié, un intitulé de
poste, une note, un motif de demande.

Un salarié dont le nom contient du balisage voyait donc ce balisage inséré dans la page de la
personne qui consulte son dossier — une injection stockée, déclenchée par le gestionnaire RH
lui-même. Le chemin le plus direct passait par `alert_card`, qui affiche les titres d'alerte
du moteur de vigilance, lesquels citent nommément les salariés concernés.

**Correction appliquée** : une fonction `esc()` a été ajoutée à `design.py` et appliquée aux
vingt-et-une interpolations de données des composants, ainsi qu'aux six interpolations
directes des vues (`views_time.py`, `views_compliance.py`, `views_core.py`) qui affichaient
des noms de salariés, des noms de conventions, des motifs de demande et des détails de
procédure. Le balisage produit par les composants eux-mêmes — `badge`, `severity_mark`,
`legal_ref_chip` — n'est pas échappé, sans quoi il s'afficherait en toutes lettres.

Le front React n'était pas concerné : JSX échappe par construction, et le dépôt ne contient
aucun `dangerouslySetInnerHTML`.

### 3. Fonctions internes exposées en RPC

`fn_child_privacy`, `fn_document_expiry` et `fn_sync_part_time` sont des fonctions de
déclencheur — appelées par PostgreSQL, jamais par l'API. Elles étaient pourtant appelables.
Même chose pour `fn_payload_rows`, utilitaire interne de l'import. La migration 44 avait
pensé à révoquer `fn_rows_json` et `fn_cba_by_code`, mais pas ce troisième.

### 5 et 6. La journalisation

Traitée en détail dans la [section RGPD](#journalisation-des-accès--qui-quoi-quand-doù).

### 7. La clé de chiffrement vit dans la base qu'elle protège

Le matricule national et l'IBAN sont chiffrés par `pgcrypto`, et la clé est lue dans la table
`secrets_application` — c'est-à-dire dans la même base que les données qu'elle protège. Quiconque
obtient une copie de la base obtient aussi la clé, et le chiffrement ne protège alors plus
rien.

Ce n'est pas une faute de conception : c'est le compromis habituel d'un déploiement Supabase
sans service de gestion de clés. Mais il faut le savoir et l'écrire — le chiffrement protège
contre une fuite de *table*, pas contre une fuite de *base*.

**Recommandation** : externaliser la clé (Supabase Vault, ou un KMS) et prévoir sa rotation.
La table `secrets_application` est correctement verrouillée par ailleurs — RLS active sans aucune
politique, et les deux fonctions de chiffrement révoquées pour tous les rôles applicatifs.

### 9 et 10. Réglages

L'analyseur signale que la vérification des mots de passe compromis (HaveIBeenPwned) est
désactivée dans Supabase Auth : c'est une case à cocher, sans effet sur le code. Et
`btree_gist` est installée dans `public` plutôt que dans un schéma dédié — hygiène, sans
conséquence pratique ici, mais c'est aussi ce qui fausse tout décompte brut de `pg_proc`.

### 11 et 12. Une erreur silencieuse, et l'aveuglement qui l'a permise

Ce n'est pas une faille de sécurité au sens strict, mais c'est un défaut de la même famille :
le système affirmait quelque chose de faux sans le savoir.

`fn_company_rates` lit `accident_class_rates`, une clé qui **n'existe dans aucune version du
référentiel**. Le taux de classe restait donc toujours nul, la fonction retombait sur le taux
de base — et renvoyait `found: true`. Un gestionnaire lisait le taux générique en croyant lire
celui de la classe de risque de sa société.

Et si personne ne l'avait vu, c'est que `fn_referential_gaps` **ne pouvait pas voir une clé
entièrement absente** : elle groupait `parametres_legaux`, où la clé n'a aucune ligne. Le
détecteur de trous était aveugle au trou le plus béant.

La migration 50 corrige les deux : la fonction dit désormais quelle source a servi et ce qui
manque, et la table `parametres_attendus` déclare les 75 clés que le moteur lit réellement, de
sorte qu'une clé jamais chargée remonte en tête des trous.

### 13. L'adresse du salarié transmise à un tiers

Le calcul de distance pour les plannings (migration 52) suppose de transmettre une adresse de
domicile à un service externe. C'est un traitement par sous-traitant, qui appelle une base
légale, une mention au registre, un contrat au sens de l'article 28, et l'information du
salarié — aucune de ces quatre pièces n'existe aujourd'hui.

La conception en limite la portée autant que la technique le permet :

- la distance est **calculée une fois puis mise en cache** : une adresse n'est transmise qu'au
  premier calcul d'un couple, pas à chaque planning ;
- le cache conserve un kilométrage et deux références, **jamais une adresse** ;
- chaque transmission laisse une trace dans `journal_acces`, action `DOWNLOAD`, avec le nom
  du service consulté : on peut donc dire quelles adresses sont sorties, et quand ;
- l'appel part d'une Edge Function : **la clé d'API ne touche ni le navigateur ni la base**, et
  le contrôle d'accès de `fn_address_of` s'applique avant tout envoi ;
- si le site porte des coordonnées, ce sont elles qui partent, pas l'adresse postale.

Ce qui reste entièrement à décider, et qui n'est pas technique : le choix du fournisseur, son
encadrement contractuel, et l'information des personnes.

### Ce qui est bien tenu

Il faut le dire aussi, parce que la suite en dépend.

- **RLS sur toutes les tables**, sans exception, vérifié sur le déploiement : 53 tables, 184 politiques après application des migrations 46 à 57.
- **Aucune clé de service côté client** : les deux fronts n'utilisent que la clé publiable.
- **Les données sensibles sont chiffrées** et ne transitent que par une fonction qui contrôle
  l'accès avant de déchiffrer.
- **L'Edge Function `contract-pdf`** exige l'en-tête `Authorization` et le transmet au client
  Supabase : la RLS s'applique au PDF comme au reste.
- **`.env.local` est ignoré par Git**, `.env.example` ne contient que des marqueurs, et les
  suites de tests refusent de démarrer sans mots de passe fournis par l'environnement.
- **Minimisation effective** : la contrainte `privacy_minimises_data` sur `enfants_salarie`
  impose que le refus d'usage efface réellement prénom, nom, sexe et note. Une règle de
  minimisation appliquée par le schéma, et non par une promesse.

---

## RGPD

### Qui est responsable de quoi

Le modèle distingue deux natures d'organisation. Pour une **fiduciaire** gérant des sociétés
clientes, la fiduciaire est **sous-traitant** et chaque société cliente **responsable du
traitement** — ce qui appelle un contrat de sous-traitance au sens de l'article 28, et son
absence est un manque juridique, pas technique. Pour une **entreprise** gérant son seul
personnel, elle est responsable du traitement.

Cette distinction existe en base (`organisations.kind`) mais n'a aucune traduction
documentaire. C'est le premier point à combler.

### Bases légales et catégories de données

| Donnée | Base légale probable | Remarque |
|---|---|---|
| Identité, contrat, rémunération | Exécution du contrat, obligation légale | Sans difficulté |
| Matricule national, IBAN | Obligation légale (CCSS, paiement) | Chiffrés |
| Absences maladie, certificats | Obligation légale (art. 9.2.b) | **Donnée de santé** |
| Reconnaissance de handicap | Obligation légale (art. 9.2.b) | **Donnée de santé** |
| Grossesse, suites de couches | Obligation légale (art. 9.2.b) | **Donnée de santé** |
| Enfants | Droits dérivés | Refus d'usage possible |
| Mandat de délégué | Obligation légale | **Donnée sensible** — engagement syndical |
| Planning, registre du temps | Obligation légale, intérêt légitime | **Surveillance** — voir AIPD |

Quatre catégories relèvent de l'article 9. Elles sont correctement isolées dans des tables
dédiées, sous RLS, avec un drapeau `sensible` sur les pièces justificatives — mais leur
existence appelle des obligations documentaires qui, elles, manquent.

### Droits des personnes

| Droit | État |
|---|---|
| Accès (art. 15) | **Couvert** — `fn_export_self`, testé, refuse l'accès au dossier d'un collègue |
| Portabilité (art. 20) | **Couvert** — export structuré, format versionné |
| Rectification (art. 16) | Couvert par les écrans de saisie |
| Opposition (art. 21) | Partiellement — `refus_partage` sur les enfants |
| **Effacement (art. 17)** | **Absent** — aucune fonction d'effacement ni d'anonymisation |
| Limitation (art. 18) | Absent |

L'effacement est le manque le plus net. Le dépôt ne contient aucune fonction d'anonymisation :
un salarié parti reste en base indéfiniment, avec son matricule chiffré. Or l'effacement se
heurte ici à l'obligation légale de conservation des pièces sociales — la bonne réponse n'est
donc pas un `delete`, mais une **anonymisation différée** : effacer l'identité, garder les
agrégats. Cela se conçoit, cela ne s'improvise pas.

### Conservation

`documents.conservation_jusquau` existe et porte la bonne intention. Mais **rien ne purge** : aucune
tâche, aucune fonction, aucune politique. Une durée de conservation qui n'est jamais appliquée
n'est pas une durée de conservation.

### Journalisation des accès — qui, quoi, quand, d'où

C'était la question posée. Voici l'état exact avant correction.

| Question | Écritures | Lectures | Exports |
|---|---|---|---|
| **Qui** | Oui — `journal_ecritures.auteur_id` et `auteur_libelle` | **Non** | Oui |
| **Quoi** | Oui — table, identifiant, avant/après | **Non** | Partiellement — nature et volume |
| **Quand** | Oui | **Non** | Oui |
| **D'où** | **Non** | **Non** | **Non** |

Et l'audit des écritures ne couvrait que **13 tables sur 47** : ni `salaries`, ni
`documents`, ni `fiches_retenue_impot` — les trois plus chargées en données personnelles.
Le déchiffrement du matricule national et de l'IBAN ne laissait **aucune trace**.

Autrement dit : à la question « qui a consulté le dossier de cette personne, et depuis où ? »,
l'application ne savait pas répondre.

**La migration 49** apporte les quatre réponses :

- `fn_request_source()` lit les en-têtes HTTP exposés par PostgREST — adresse d'origine, agent
  utilisateur, identifiant de requête. C'est la seule provenance disponible en base :
  `inet_client_addr()` ne voit que le pooler.
- Trois colonnes de provenance sur `journal_ecritures` et `journal_exports`, remplies par un déclencheur —
  aucune fonction du moteur n'a eu à être réécrite.
- Une table `journal_acces` pour les **consultations** : lecture, déchiffrement, export,
  téléchargement. Sous RLS, lisible par les gestionnaires de la société **et par la personne
  concernée** — contrepartie du droit d'accès. Aucune politique d'écriture ni de suppression :
  un journal que son sujet peut effacer ne prouve rien.
- `fn_employee_sensitive` trace désormais chaque déchiffrement, **y compris les tentatives
  refusées** — une tentative repoussée est un signal.
- Quatre tables de plus sous audit d'écriture.
- `fn_audit` ne recopie plus les colonnes chiffrées dans le journal : il dit qu'une donnée
  chiffrée a changé, sans en conserver une copie de plus à protéger.
- `fn_person_access_report(employee, du, au)` réunit les trois journaux et répond
  littéralement : quand, qui, quoi, de quelle nature, d'où, avec quel agent.

Restent à instrumenter, et la migration le dit explicitement : la consultation d'un dossier
depuis l'écran salarié, le téléchargement d'une pièce, et la ligne de lecture correspondant à
chaque export. Ainsi que la **durée de conservation de ces journaux**, qui est une décision
juridique et non un paramètre technique.

### La lecture auditée : le patron pipeline

La migration 51 pose le mécanisme qui manquait pour tracer une lecture **sans étouffer le
système sous le volume**. Le modèle est la fonction pipelinée d'Oracle :

```sql
SELECT c.name, Book.name, Book.author FROM Catalogs c, TABLE(GetBooks(c.cat)) Book;
```

Trois propriétés en font le bon outil ici :

1. **Les lignes sortent une à une.** Le contrôle d'accès et la trace se font par ligne, pas
   sur un ensemble supposé homogène. Une ligne hors droit n'est pas émise, et son refus est
   consigné.
2. **La clause `where` passe en paramètres.** Aucune lecture sans périmètre : `fn_employee_rows`
   refuse d'être appelée sans société ni salarié, et `fn_time_entry_rows` sans bornes de dates.
   La minimisation devient une condition d'exécution, pas une bonne intention.
3. **La projection passe en paramètre.** `p_fields` dit quelles colonnes sont réellement
   voulues ; les autres sortent à nul. Demander le matricule national ou l'IBAN exige en outre
   un droit plus étroit que la simple lecture, et produit une trace de type `DECRYPT`.

La trace est écrite **avant** l'émission de la ligne, et hors de la transaction appelante — de
sorte qu'une lecture interrompue, ou annulée par un `rollback`, reste consignée. C'est ce que
fait `PRAGMA AUTONOMOUS_TRANSACTION` en Oracle ; PostgreSQL n'a pas d'équivalent natif et
passe par une seconde connexion `dblink`.

| Oracle | PostgreSQL |
|---|---|
| `PIPELINED` + `PIPE ROW(out_rec)` | `returns setof <type>` + `return next` |
| `TABLE(f(x))` dans le `FROM` | `cross join lateral f(x)` |
| `PRAGMA AUTONOMOUS_TRANSACTION` | `dblink` sur une seconde connexion |

Tant que la chaîne de connexion `dblink` n'est pas déposée dans `secrets_application`, la trace est
écrite dans la transaction courante et porte `est_autonome = false` : **le journal déclare sa
propre fragilité** plutôt que de la taire.

La version Oracle littérale — avec le vrai `PIPELINED`, le vrai `PIPE ROW` et le vrai
`PRAGMA` — est dans `schema/oracle_audit_pipeline.sql`. Elle ne rend pas les colonnes
sensibles : le chiffrement n'a pas d'équivalent porté sur Oracle, et les rendre supposerait de
les avoir déchiffrées ailleurs.

### Analyse d'impact (art. 35)

L'outil traite des données de santé, à grande échelle, sur des personnes en situation de
subordination, et comporte un **suivi systématique du temps de travail**. Ces trois facteurs
réunis rendent une AIPD très probablement obligatoire. Elle n'existe pas. Ce n'est pas un
défaut de code, mais c'est un préalable à toute mise en production réelle.

Manquent également le **registre des traitements** (art. 30) et une **procédure de
notification de violation** (art. 33) — cette dernière devenant réaliste maintenant que la
journalisation permet de déterminer l'étendue d'un accès indu.

### Hébergement

Le projet est hébergé en `eu-west-1` (Irlande) : dans l'Union, sans transfert hors UE à
documenter. C'est un fait de configuration, à vérifier avant tout déploiement client.

---

## AI Act

### LuxRH n'est pas un système d'IA

Le règlement (UE) 2024/1689 définit un système d'IA par sa capacité à **inférer**, à partir
d'entrées, des sorties telles que des prédictions, recommandations ou décisions, avec un degré
d'autonomie.

Le moteur de LuxRH est **entièrement déterministe** : 111 fonctions PL/pgSQL qui lisent des
paramètres datés et appliquent des règles écrites. Aucun apprentissage, aucun modèle, aucune
inférence statistique. Une recherche sur l'ensemble du dépôt ne trouve **aucune dépendance**
d'apprentissage automatique, aucun appel à un modèle de langage, aucun composant prédictif.

Une même entrée donne toujours la même sortie, et le chemin qui y mène est lisible dans le
SQL. C'est l'opposé exact de ce que le règlement encadre.

**Conclusion : le règlement ne s'applique pas au produit dans son état actuel.** Cette
conclusion mérite d'être écrite noir sur blanc, parce qu'elle est un atout commercial — et
parce qu'elle est fragile.

### Ce qui la ferait basculer

Les ressources humaines figurent à l'**annexe III** du règlement : un système d'IA utilisé pour
le recrutement, l'affectation des tâches, l'évaluation ou les décisions de rupture est
**à haut risque**. Un outil RH est donc à une fonctionnalité près du régime le plus lourd.

Les fonctionnalités qui feraient basculer LuxRH :

| Fonctionnalité envisageable | Conséquence |
|---|---|
| Tri ou classement de candidatures | Haut risque, annexe III.4.a |
| Optimisation automatique des plannings affectant les personnes | Haut risque, annexe III.4.b |
| Score d'absentéisme ou de « risque » individuel | Haut risque, annexe III.4.b — et surveillance au sens du RGPD |
| Suggestion de licenciement | Haut risque, annexe III.4.b |
| Assistant conversationnel sur le droit du travail | Obligation de transparence (art. 50) ; haut risque s'il oriente une décision individuelle |
| Détection d'anomalies dans le registre du temps | Haut risque si elle produit un jugement sur une personne |

Le régime haut risque impose un système de gestion des risques, une gouvernance des données,
une documentation technique, une journalisation, une transparence, un **contrôle humain
effectif** et une évaluation de conformité. C'est un projet en soi, pas une option à activer.

Deux obligations s'appliqueraient par ailleurs immédiatement : l'article 50 (informer une
personne qu'elle interagit avec une IA) et l'article 4 (**littératie en IA** du personnel qui
l'exploite), déjà en vigueur.

### Recommandation

1. **Écrire la position** : LuxRH est un moteur de règles déterministe, pas un système d'IA.
   Une page, sourcée, opposable à un client qui pose la question.
2. **Poser un garde-fou dans les conventions du dépôt** : toute fonctionnalité comportant une
   inférence, un score ou un classement de personnes déclenche une analyse AI Act *avant* d'être
   développée. Un ajout d'apparence anodine — « suggérer le meilleur planning » — change le
   régime juridique du produit entier.
3. **Ne pas confondre automatisation et IA** : le moteur décide déjà beaucoup de choses. Ce
   qui le tient hors du règlement, c'est que ses décisions sont écrites, datées, sourcées et
   explicables. C'est aussi ce qui fait sa valeur — il n'y a rien à gagner à s'en écarter.

---

## Dans quel ordre corriger

| Ordre | Action | Effort |
|---|---|---|
| ✅ | ~~Appliquer les migrations 46 à 54~~ — fait le 10 septembre 2026 | — |
| 1 | Déposer `dblink_conninfo` dans `secrets_application` — sans quoi la trace n'est pas autonome | Minute |
| 2 | Poser `DISTANCE_API_KEY` pour l'Edge Function `travel-distance` | Minute |
| 3 | Activer la protection contre les mots de passe compromis | Minute |
| 4 | Externaliser la clé de chiffrement, prévoir sa rotation | Jours |
| 5 | Décider la durée de conservation des journaux et l'appliquer | Jours |
| 6 | Concevoir l'anonymisation différée (effacement, art. 17) | Semaines |
| 7 | Rédiger AIPD, registre des traitements, contrat de sous-traitance — y compris avec le fournisseur de distances | Semaines, hors code |
| 8 | Écrire et publier la position AI Act | Jour |

Les deux premières lignes ferment ce que la revue a trouvé de plus sérieux, et ne coûtent
qu'une commande.

---

## Voir aussi

- [`index.md`](index.md) — sommaire de la documentation
- [`ecarts-a-corriger.md`](ecarts-a-corriger.md) — la fiche de passation, où ces constats sont suivis
- [`architecture.md`](architecture.md) — RLS, moteur, et le raisonnement derrière l'isolation
- [`moteur-de-regles.md`](moteur-de-regles.md) — pourquoi le moteur est déterministe
- [`modele-de-donnees.md`](modele-de-donnees.md) — les tables citées ici
- [`contribuer.md`](contribuer.md) — les conventions qu'une correction doit respecter
