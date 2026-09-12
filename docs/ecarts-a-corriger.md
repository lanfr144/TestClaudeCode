# Écarts relevés entre le code et la documentation

Fiche de passation. Elle liste ce qu'une relecture documentaire du 10 septembre 2026 a
trouvé de faux, d'incohérent ou d'irrégulier dans le dépôt, **avec l'état de chaque point**.
Une session chargée de corriger le code lit ce document en premier : il dit ce qui a déjà
été corrigé et ce qui reste à faire, sans qu'il faille refaire l'enquête.

Toute correction apportée se répercute ici : on coche, on date, on nomme le commit. Un point
retiré de cette liste sans être corrigé est une régression de la documentation.

---

## Reste à faire

### 0. ~~Le dépôt et la base avaient divergé~~ — **corrigé le 12 septembre 2026**

L'historique de migrations de la base ne correspondait plus aux fichiers du dépôt, à quatre
titres. Tout est réglé, et outillé pour ne pas se reproduire.

| Défaut | Nombre | Correction |
|---|---|---|
| Migration appliquée sans fichier | 13 | Fichier écrit depuis le SQL appliqué |
| Fichier daté autrement que la version en base | 27 | Fichier **renommé** sur la version appliquée |
| Fichier qu'aucune migration appliquée ne réclame | 1 | La « 44 » récapitulative, supprimée |
| Caractères illisibles dans un fichier | 1 | `12_demo_dataset_rpc`, tiret restauré |

**Le piège des horodatages.** Quand une migration est appliquée par le connecteur, la
plateforme lui attribue l'horodatage de l'application — pas celui choisi pour le nom du
fichier. La `64d` portait ainsi `20260912070000` dans le dépôt et `20260912045836` en base.
Or `supabase db push` compare les **versions**, pas les noms : il voyait vingt-sept migrations
inconnues et les aurait rejouées sur une base qui les avait déjà. C'est le nom qui identifie
une migration ; la date dit seulement quand elle a été jouée. Les fichiers ont été renommés,
jamais réécrits.

**La « 44 » récapitulative.** Un fichier `20260910130000_44_portability_export_import.sql`
fondait `44a` et `44b` en un seul bloc, écrit après leur application. Aucune version en base
ne lui correspondait : `db push` l'aurait appliqué, **écrasant les correctifs 45 à 45e** que
les migrations suivantes avaient apportés. Il est supprimé ; son en-tête documentaire a été
reporté sur `44a` et `44b`, qui sont le SQL réellement appliqué.

**L'outil qui rend l'opération mécanique.** [`tools/dump_migrations.py`](../tools/dump_migrations.py)
compare l'historique de la base aux fichiers du dépôt et rend compte de cinq états : aligné,
sans fichier, contenu divergent, horodatage à corriger, fichier non appliqué. Sans `--ecrire`
il ne fait que dire ; avec, il écrit les manquants et renomme les mal datés. **Il ne réécrit
jamais un fichier existant** — une migration appliquée ne se réécrit pas.

```bash
luxrh-py/.venv/Scripts/python tools/dump_migrations.py            # état des lieux
luxrh-py/.venv/Scripts/python tools/dump_migrations.py --ecrire   # écrit et renomme
```

À lancer **avant tout `db push`**, et après toute migration appliquée par le connecteur.

**Les quinze écarts de contenu qui subsistent sont normaux.** Le fichier du dépôt est la
version lisible — chaînes de caractères repliées sur plusieurs lignes, commentaires
explicatifs, `drop policy if exists` — et la base porte ce qui a été exécuté. L'outil les
liste pour qu'ils soient vus, pas pour qu'ils soient corrigés. Un seul mérite une lecture :
`64b_working_condition_premium_engine`, dont le fichier est **volontairement** documentaire et
ne contient pas le SQL appliqué ; il porte son propre avertissement en tête et explique
pourquoi (la `64c` redéfinit la fonction quelques minutes plus tard, l'état final d'un rejeu
est donc identique).

**Numérotation.** Les migrations écrites après la reconstitution commencent à **46** : les
numéros 45 à 45e étaient déjà pris sur le déploiement.

---

### 1. ~~Les schémas portables Oracle et MySQL sont périmés~~ — **corrigé le 12 septembre 2026**

`schema/catalogue.json`, `schema/oracle.sql` et `schema/mysql.sql` décrivaient **47 tables**,
produits avant les migrations 49, 50 et 52. Une reprise vers Oracle ou MySQL faite sur ces
fichiers aurait perdu quatre tables, dont `data_access_log` — c'est-à-dire la pièce de
conformité RGPD.

**Ce qui bloquait** : la régénération lit le catalogue depuis PostgreSQL, et l'environnement
n'a ni pilote direct ni mot de passe de base. La clé publiable ne donne pas accès à
`pg_catalog`.

**Ce qui a débloqué** : une fonction serveur, `fn_schema_catalogue_for_admin()`, qui expose le
catalogue système — et lui seul, jamais une donnée métier — aux administrateurs
d'organisation. `tools/fetch_catalogue.py` s'y connecte comme n'importe quel client et écrit
le JSON. Plus de copier-coller dans un éditeur SQL, donc plus de dérive.

**État actuel** : 75 tables, 836 colonnes toutes commentées, 95 créations d'objets par schéma,
et la liste « ce qui n'a pas été traduit » **vide** — 0 point, contre 43 au départ.

```bash
luxrh-py/.venv/Scripts/python tools/fetch_catalogue.py                          # relit la base
luxrh-py/.venv/Scripts/python tools/emit_portable_schema.py schema/catalogue.json schema/
```

Le générateur écrit toujours en clair, à la fin de chaque fichier, ce que la traduction n'a pas
pu porter. C'est ce mécanisme qui a permis de repérer que la migration 64 avait recréé une
contrainte `check` de liste de valeurs, l'anti-patron que la migration 61 venait de supprimer
partout : une règle mécanique qui attrape celui qui l'a écrite.

À faire aussi tant qu'on y est : `schema/oracle_audit_pipeline.sql` est écrit à la main et ne
suit pas l'émetteur — il faudra le relire si le schéma des tables qu'il interroge change.

---

### 2. Neuf salariés sur 317 portent une adresse

La reprise de validation (migration 57) a soumis toutes les adresses existantes à
`fn_validate_address`. Verdict :

| Statut | Nombre | Détail |
|---|---|---|
| `ok` | 17 | Luxembourg 13, Moselle 3, province de Luxembourg 1 |
| `unknown` | 309 | dont **308 salariés sans aucun code postal**, et 1 adresse allemande |

Sur 317 salariés, **neuf seulement ont un code postal**. Ce n'est pas un défaut de la
validation : c'est ce qu'elle est faite pour rendre visible, et c'est le jeu de démonstration qui
est incomplet.

Deux conséquences concrètes :

- **Le calcul de distance des plannings ne peut pas fonctionner** pour ces salariés :
  `fn_shift_travel` a besoin d'une adresse de domicile. Il répondra `found: false` en le
  nommant — mais la cause première est ici.
- **`fn_commute_allowance`** repose sur `employee_tax_cards.commute_distance_km`, saisie à la
  main : elle n'est pas affectée, mais rien ne la recoupe avec l'adresse réelle.

**À faire** : compléter le jeu de démonstration (`fn_seed_demo`), ou accepter que ces salariés
restent sans adresse et le documenter comme tel. Contrôle :

```sql
select status, zone_code, count(*) from address_checks group by 1, 2 order by 3 desc;
```

---

### 3. Les bornes postales allemandes ne sont pas chargées

`address_zones` déclare la Rhénanie-Palatinat et la Sarre, **sans intervalle de codes postaux** :
les codes allemands ne se rattachent pas proprement à un Land — la Rhénanie-Palatinat partage des
préfixes avec la Hesse, la Sarre et le Bade-Wurtemberg. Écrire un intervalle plausible aurait été
inventer, ce que la règle 7 du [`CLAUDE.md`](../CLAUDE.md) interdit.

Conséquence : une adresse allemande ressort `unknown` — ni acceptée ni refusée, mais **visible**.
Une contrainte de la table interdit d'ailleurs de se déclarer vérifié sans bornes.

**À faire** : charger une correspondance code postal → Land depuis une source officielle
(Deutsche Post, ou les données ouvertes du Bund), puis passer `is_verified` à vrai pour les deux
zones. Tant que ce n'est pas fait, la vérification d'une adresse allemande reste manuelle.

---

### 4. Deux réglages qui ne sont pas du SQL

- **La trace autonome exige une chaîne de connexion `dblink`**, à déposer dans `app_secrets`
  sous la clé `dblink_conninfo`. Tant qu'elle manque, les traces sont écrites dans la
  transaction appelante et portent `is_autonomous = false` — elles existent, mais disparaissent
  avec un `rollback`. Contrôle : `select is_autonomous, count(*) from data_access_log group by 1;`
- **Le calcul de distance exige `DISTANCE_API_KEY`** dans l'environnement de l'Edge Function
  `travel-distance`. Sans elle, la fonction répond qu'elle ne peut pas conclure — elle
  n'estime rien.

---

### 5. Treize fonctions du moteur n'ont aucun écran

Exposées et testées, mais appelées par aucune interface :

`fn_notice_period` · `fn_salary_reference` · `fn_can_terminate` · `fn_income_tax` ·
`fn_commute_allowance` · `fn_holiday_summary` · `fn_check_national_id` ·
`fn_overtime_approved_hours` · `fn_premium_check` · `fn_validate_parameter_version` ·
`fn_absence_entitlement` · `fn_cba_best_num` · `fn_cba_value`

Ce n'est pas un défaut en soi — plusieurs sont des briques appelées par d'autres fonctions
SQL, et `fn_income_tax` attend la V2 « brut → net » du PRD. Mais la liste mérite un arbitrage
produit : chacune est soit une brique interne (à documenter comme telle), soit un écran
manquant.

**État** : documenté dans [`api-serveur.md`](api-serveur.md), aucune décision prise.

---

### 6. Onze fonctions ne sont appelées que d'un seul côté

Six par React seulement, cinq par Streamlit seulement. Le détail par fonction est dans le
tableau des écarts en fin d'[`api-serveur.md`](api-serveur.md).

**Pourquoi ça compte** : les deux fronts ne sont pas l'un la maquette de l'autre. Un écart
d'appel est soit une fonctionnalité qui manque d'un côté, soit une duplication à retirer.

**État** : documenté, aucune décision prise.

---

## Corrigé

> **Tout ce qui suit est appliqué sur la base déployée**, et vérifié : 154 tests passent,
> `npm run build` reste à 0 erreur, et l'analyseur de sécurité ne signale plus les deux
> constats sérieux. Les dates de correction sont celles du 10 septembre 2026.

### ✅ Une sixième suite de tests couvre les fonctions nouvelles — 10 septembre 2026

Le manque était réel : les migrations 46 à 57 avaient ajouté quatorze fonctions qu'aucun test ne
touchait. `luxrh/tests/lifecycle.test.mjs` en couvre **36 vérifications**, exécutées contre l'API
réelle comme les cinq autres suites :

| Domaine | Ce qui est vérifié |
|---|---|
| Validation d'adresse | Les sept cas : Luxembourg, Arlon, Metz `ok` ; Bruxelles, Paris `outside` ; Trèves, Amsterdam `unknown`. Et que « L-1424 » vaut « 1424 » |
| Lecture pipelinée | Refus sans périmètre, refus d'un champ inconnu, **colonnes non demandées à nul**, et qu'un salarié n'y voit que son propre dossier |
| Registre des accès | Que le déchiffrement qui précède y figure, que les colonnes qui/quoi/quand/d'où sont rendues, et qu'un salarié ne lit pas le registre d'un collègue |
| Contrat unique | Qu'un second contrat actif chevauchant est refusé par la base |
| Avenant | Refus sans motif, refus sans modification, puis le cas complet : clôture la veille, version incrémentée, chaînage conservé, modification appliquée, temps partiel recalculé par le déclencheur, contrat non signé, clauses reprises, avenant journalisé |

La suite **défait sa propre écriture** en fin de parcours : elle supprime l'avenant de test et
rétablit le contrat d'origine. Le premier essai ne le faisait pas, et le second a échoué sur les
résidus du premier — la contrainte d'unicité a d'ailleurs attrapé mon propre nettoyage bâclé.
Les dates sont désormais déduites du contrat, jamais figées.

**Total : 190 vérifications réparties en six suites, 0 échec.** `npm run test:lifecycle` pour
cette suite seule.

### ✅ Cycle de vie du contrat, index, adresses — migrations 55 et 56, appliquées

**Un seul contrat en cours par salarié**, imposé par une contrainte d'exclusion GiST plutôt que
par un compteur : deux contrats actifs qui ne se recouvrent pas restent licites, un recouvrement
d'un jour ne l'est pas. Vérifié avant pose — 319 contrats actifs, zéro chevauchement — et après :
une insertion chevauchante est rejetée.

**`fn_amend_contract`** établit l'avenant : clôture la veille de la prise d'effet, nouveau
contrat construit depuis `to_jsonb(ancien)` pour qu'aucune colonne ne soit oubliée, report des
éléments de rémunération et des conventions en vigueur, chaînage `previous_contract_id`. Le
nouveau contrat part non signé — un avenant se signe.

**Index de recherche par nom** : le fonctionnel `upper(last_name)` sert l'égalité et le préfixe,
un index trigramme GIN sert la recherche infixe que `fn_employee_rows` effectue réellement. Les
deux vérifiés par `explain`. Poser le seul index fonctionnel aurait laissé la requête réelle sans
index tout en donnant l'impression du contraire. **Aucun index plein texte** : aucun écran n'en
a l'usage aujourd'hui.

**Adresses** : `address_zones` restreint la saisie au Luxembourg et aux zones frontalières
déclarées ; `fn_validate_address` répond `ok`, `outside` ou `unknown` ; le déclencheur
`check_address` refuse un `outside` et consigne le reste dans `address_checks`. L'Edge Function
`address-validate` interroge le registre officiel BD-Adresses pour le Luxembourg — API essayée,
forme de réponse vérifiée.

> **Les bornes postales allemandes sont délibérément vides.** Les codes postaux allemands ne se
> rattachent pas proprement à un Land : la Rhénanie-Palatinat partage des préfixes avec la Hesse,
> la Sarre et le Bade-Wurtemberg. Écrire un intervalle plausible aurait été inventer. Une adresse
> allemande ressort donc `unknown`, et reste visible dans `address_checks`. À charger :
> `select * from address_checks where status = 'unknown';`

**Déclencheurs générés pour Oracle et MySQL** : ils ne balaient plus la table entière. Oracle
passe par un déclencheur composé — `after each row` collecte les identifiants écrits,
`after statement` les vérifie, ce qui lève ORA-04091 proprement — et `exists` remplace
`count(*)`, ce qui rend `rownum <= 1` superflu. `schema/oracle.sql` et `schema/mysql.sql` ont été
régénérés avec ce code et à partir d'un catalogue rafraîchi : **ils portent les 75 tables de la
base déployée**, et la liste « ce qui n'a pas été traduit » est désormais vide.

*Constat au passage* : le moteur PL/pgSQL n'utilise **aucun** `count(*)` comme test d'existence.
Ses comptages sont de vrais comptages — effectifs, compteurs de licenciement collectif.
L'anti-patron ne vivait que dans les déclencheurs générés.

Ces règles sont désormais inscrites au [`CLAUDE.md`](../CLAUDE.md), points 8 à 12, pour qu'elles
survivent à cette session.

### ✅ Les migrations 46 à 54 sont appliquées — 10 septembre 2026

Appliquées une à une par le connecteur Supabase, avec vérification après chacune.

| Migration | Effet vérifié sur la base |
|---|---|
| `46_harden_grants_portability` | **0 fonction** exécutable par `anon` (16 auparavant), 80 pour `authenticated` |
| `47_comments_tables_columns` | 47 tables et 224 colonnes commentées à l'époque ; portées depuis à 75 et 836 par les migrations 71 à 72c |
| `48_business_constraints` | 66 contraintes `check` (34 avant), 11 clés composites d'isolation |
| `49_access_log_rgpd` | `data_access_log` créée, sous RLS ; provenance sur les trois journaux |
| `50_silent_fallbacks_and_expected_keys` | 76 clés attendues déclarées ; `fn_referential_gaps` remonte `accident_class_rates` en tête |
| `51_read_audit_pipeline` | `dblink` installée, `fn_employee_rows` et `fn_time_entry_rows` en place |
| `52_client_sites_and_travel` | 4 tables nouvelles, 9 fonctions nouvelles |
| `53_drop_redundant_single_column_fks` | correction d'une régression — voir ci-dessous |
| `54_fix_company_rates_array_append` | correction d'une régression — voir ci-dessous |

**Contrôles après application** : `npm test` → **154 vérifications, 0 échec**. `npm run build`
→ **0 erreur TypeScript**. L'analyseur de sécurité ne signale plus ni fonction exécutable par
`anon` ni `search_path` mutable.

**La journalisation fonctionne** : `data_access_log` portait déjà deux traces `DECRYPT` écrites
pendant la suite de tests elle-même, sans qu'aucun code applicatif ait été modifié pour cela.

Restent signalés par l'analyseur, connus et assumés : `app_secrets` sous RLS sans politique
(c'est la protection, voir son commentaire), `btree_gist` dans `public`, la protection contre
les mots de passe compromis désactivée, et 53 fonctions `security definer` appelables par un
compte authentifié — ce qui est le principe même du moteur, chacune contrôlant l'accès dans son
corps.

### ✅ Deux régressions introduites, puis corrigées — 10 septembre 2026

Les deux ont été **attrapées par la suite de tests**, immédiatement après application. C'est
l'argument le plus concret en faveur de ces 154 vérifications.

**a) PGRST201 — l'imbrication PostgREST devenue ambiguë.** La migration 48 ajoutait des clés
composites `(employee_id, company_id)` *à côté* des clés simples `(employee_id)` existantes.
PostgREST voyait alors **deux relations** entre les mêmes tables, et
`employees?select=*,contracts(...)` échouait. Sur 154 vérifications, **4 passaient**.

La clé composite subsumant strictement la simple — mêmes colonnes plus `company_id`, même
`on delete cascade` —, la migration 53 retire les onze clés simples redondantes. Aucune
intégrité perdue, une seule relation par couple, l'ambiguïté disparaît.

*L'enseignement mérite d'être retenu* : sur PostgREST, une clé étrangère n'est pas seulement
une contrainte d'intégrité, c'est une **arête du graphe de relations exposé par l'API**. En
ajouter une change le contrat d'interface sans qu'une ligne de front soit touchée.

**b) « malformed array literal ».** La migration 50 écrivait
`manques := manques || 'accident_class_rates';`. Le littéral n'ayant pas de type déclaré,
PostgreSQL résolvait la surcharge `anyarray || anyarray` et tentait de lire la chaîne comme un
tableau. Corrigé par `array_append` en migration 54. Ironie : le bug était dans la fonction
même qui corrigeait une erreur silencieuse — celui-là, au moins, était bruyant.

### ✅ `fn_company_rates` retombait en silence sur le taux de base — migration 50

**Le bug le plus intéressant de la revue**, parce qu'il ne se voyait pas.

`accident_class_rates` est lue par `fn_company_rates` et **n'existe dans aucune version du
référentiel**. Le taux de classe restait donc toujours nul, et la ligne

```sql
accident_rate := coalesce(accident_rate, accident_base) * rp.accident_factor;
```

retombait sur le taux de base — puis la fonction renvoyait `'found', true`. L'appelant croyait
lire le taux de la classe de risque de sa société ; il lisait le taux générique. Violation
directe de la règle 5 du [`CLAUDE.md`](../CLAUDE.md) : aucune erreur silencieuse.

La fonction renvoie désormais `accident_rate_source` (`classe` ou `base`), `complete`,
`missing_parameters` et un message qui dit que le résultat ne doit pas servir de base à une
déclaration. **Le repli demeure — il est simplement nommé.** Aucune valeur n'a été inventée
pour combler la clé manquante.

### ✅ `fn_referential_gaps` ne voyait pas les clés absentes — migration 50

C'est ce qui a permis au bug ci-dessus de passer inaperçu. L'ancienne version groupait
`legal_parameters` : une clé sans aucune version n'y apparaissait pas, faute de ligne à
grouper. Le détecteur de trous était aveugle au trou le plus béant — la clé jamais chargée.

La nouvelle table `expected_parameters` porte les **75 clés que le moteur lit réellement**,
relevées dans le code des migrations avec leur fonction lectrice. `fn_referential_gaps` part
désormais de cette liste : une clé attendue et jamais chargée sort avec `versions = 0`, en
tête. Elle ne porte aucune valeur légale — c'est le mécanisme que réclame la règle 7.

### ✅ Trois seuils légaux inscrits en dur dans le schéma — migration 50

`companies_reference_period_months_check` et `reference_periods_months_check` bornaient la
période de référence à 4 mois ; `company_rate_periods_mutuality_class_check` fixait 4 classes
de mutualité. Ces bornes sont exactes aujourd'hui — et c'est précisément ce que la règle 1
refuse comme justification : une contrainte est figée dans le schéma, une loi ne l'est pas.
Le plafond vit déjà dans le référentiel sous `max_reference_period_months`, que
`fn_validate_schedule` lit.

Remplacées par des bornes structurelles (`>= 1`), avec un commentaire qui renvoie au
référentiel.

### ✅ Injection HTML dans le front Streamlit — corrigé le 10 septembre 2026

`luxrh-py/luxrh/design.py` interpolait toutes ses données dans du HTML rendu avec
`unsafe_allow_html=True`, **sans échappement**. Les titres d'alerte du moteur citant nommément
les salariés, un nom contenant du balisage s'exécutait dans la page du gestionnaire RH qui
consulte le dossier — injection stockée.

Corrigé : fonction `esc()` ajoutée à `design.py`, appliquée aux 21 interpolations de données
des composants et aux 6 interpolations directes des vues (`views_time.py`,
`views_compliance.py`, `views_core.py`) qui affichaient noms de salariés, noms de conventions,
motifs de demande et détails de procédure. Le HTML produit par les composants eux-mêmes n'est
pas échappé, sans quoi il s'afficherait en clair.

Le front React n'était pas concerné : JSX échappe par construction, et le dépôt ne contient
aucun `dangerouslySetInnerHTML`.

### ✅ Le décompte des fonctions du moteur — corrigé le 10 septembre 2026

`docs/bases-de-donnees.md`, `docs/couverture-droit-du-travail.md` et l'en-tête de
[`luxrh-py/luxrh/backends.py`](../luxrh-py/luxrh/backends.py) annonçaient **272 fonctions,
environ 147 Ko de source**. Le chiffre venait d'un décompte brut de `pg_proc` sur le schéma
`public`, où vit aussi l'extension `btree_gist`.

Relevé sur la base :

| Mesure | Valeur |
|---|---|
| Fonctions dans le schéma `public` | 281 |
| dont appartenant à l'extension `btree_gist` | 188 |
| **Fonctions du projet** | **93** |
| dont fonctions `fn_*` appelables | 84 |
| dont prédicats d'accès pour les politiques RLS | 9 |
| Noms distincts | 92 — `fn_make_national_id` est surchargée |
| Taille cumulée des corps | 169 Ko |

Les 92 noms distincts recoupaient exactement le décompte des migrations d'alors. Les trois
emplacements ont porté 93 fonctions et 169 Ko jusqu'aux migrations 46 à 54, qui en ajoutent
quatorze : la documentation en compte aujourd'hui **107**, pour environ 192 Ko.

**Requête de contrôle**, à rejouer si le chiffre doit être revérifié :

```sql
select count(*) as fonctions_projet,
       pg_size_pretty(sum(octet_length(p.prosrc))::bigint) as taille_corps
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
left join pg_depend d
  on d.objid = p.oid and d.classid = 'pg_proc'::regclass and d.deptype = 'e'
where d.objid is null;
```

### ✅ `ContractWizard.tsx` passe désormais par `callEngine()` — corrigé le 10 septembre 2026

L'écran appelait `supabase.rpc('fn_set_employee_sensitive', …)` directement, seule irrégularité
de ce type dans le front React. L'appel passe maintenant par `callEngine()`
([`luxrh/src/lib/supabase.ts`](../luxrh/src/lib/supabase.ts)), le point unique où toute erreur
du moteur remonte comme exception nommée — condition de la règle « aucune erreur silencieuse »
du [`CLAUDE.md`](../CLAUDE.md).

Contrôle : `grep -rn "supabase.rpc(" luxrh/src/` ne renvoie plus que la définition de
`callEngine` elle-même. `npm run build` reste à zéro erreur TypeScript.

### ✅ Les suites de tests ont été exécutées — 10 septembre 2026

Node est installé — `C:\Program Files\nodejs\node.exe` — mais **absent du `PATH`**, ce qui
avait fait conclure à tort à son absence. Avec le chemin ajouté, `npm test` passe :

| Suite | Vérifications | Échecs |
|---|---|---|
| `api` | 80 | 0 |
| `rls` | 22 | 0 |
| `publication` | 10 | 0 |
| `domain` | 16 | 0 |
| `portability` | 26 | 0 |
| **Total** | **154** | **0** |

Le compte annoncé par les README est donc confirmé par exécution, et non plus par décompte
statique.

### ✅ Le décompte des politiques RLS — corrigé le 10 septembre 2026

[`architecture.md`](architecture.md) et [`modele-de-donnees.md`](modele-de-donnees.md)
annonçaient **141 politiques**, chiffre issu d'un décompte statique des instructions
`create policy` dans les migrations. La base déployée en porte **175** : la migration 19
(`19_rls_and_index_performance.sql`) en crée une partie dans un bloc `do $$` qui boucle sur les
tables, invisible à un `grep`.

| Mesure | Valeur |
|---|---|
| Tables du schéma `public`, hors extension | 47 |
| **dont sous Row Level Security** | **47 — aucune exception** |
| Politiques installées | 175 : 46 `select`, 43 `insert`, 44 `update`, 42 `delete` |

La règle 6 du [`CLAUDE.md`](../CLAUDE.md) — « RLS sur toutes les tables » — est donc tenue sur
le déploiement, et pas seulement dans l'intention des migrations.

**Requête de contrôle** :

```sql
with t as (
  select c.oid, c.relname, c.relrowsecurity
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
  left join pg_depend d
    on d.objid = c.oid and d.classid = 'pg_class'::regclass and d.deptype = 'e'
  where c.relkind = 'r' and d.objid is null
)
select (select count(*) from t)                                       as tables,
       (select count(*) from t where relrowsecurity)                  as avec_rls,
       (select string_agg(relname, ', ') from t where not relrowsecurity) as sans_rls,
       (select count(*) from pg_policies where schemaname = 'public') as politiques;
```

### ✅ Les compteurs de `luxrh/README.md` — corrigés le 10 septembre 2026

Le README de l'application React annonçait 42 migrations, 20 écrans, 3 suites de tests et
128 vérifications. Le dépôt en porte **44**, **22**, **5** et **154** : la suite `portability`
et ses 26 vérifications n'y figuraient pas. Le README racine, lui, était déjà juste.

### ✅ « Mêmes écrans » entre les deux fronts — corrigé le 10 septembre 2026

Les deux README affirmaient que les applications React et Streamlit offrent les mêmes écrans.
Il y en a **22 côté React** et **16 côté Streamlit**. Les formulations sont corrigées et le
tableau des écarts est en fin d'[`api-serveur.md`](api-serveur.md). Ce que les deux fronts
partagent, ce sont les **règles**, pas les écrans.

---

## Voir aussi

- [`index.md`](index.md) — sommaire de la documentation
- [`contribuer.md`](contribuer.md) — les conventions que ces corrections doivent respecter
- [`api-serveur.md`](api-serveur.md) — l'inventaire des fonctions et de leurs appelants
- [`tests-et-qualite.md`](tests-et-qualite.md) — les cinq suites et ce qu'elles couvrent
