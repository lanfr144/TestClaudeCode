# Le moteur de règles

Ce document explique **comment LuxRH décide** : où vivent les valeurs légales, comment elles sont
datées, comment la loi, la convention collective et le contrat s'arbitrent, comment les scans de
conformité fonctionnent, et pourquoi le moteur refuse parfois de répondre. Il s'adresse aux
développeurs base de données et aux personnes chargées de la conformité.

Le moteur est écrit en PL/pgSQL, dans `luxrh/supabase/migrations/`. Il compte **111 fonctions**
(110 noms distincts — `fn_make_national_id` est surchargée), définies par environ 139 instructions
`create [or replace] function` cumulées — une fonction corrigée plus tard est redéfinie dans une
migration ultérieure, jamais réécrite dans sa migration d'origine.

---

## 1. Le référentiel daté

### La table `parametres_legaux`

Tout ce qui pourrait être « écrit en dur » vit ici, une ligne par version.

| Colonne | Rôle |
|---|---|
| `family` | `social`, `ccss`, `fiscal`, `worktime`, `leave`, `contract`, `headcount` |
| `cle_parametre` | La clé stable, par exemple `min_daily_rest_hours` |
| `label` | Le libellé affiché |
| `valeur_num` · `valeur_texte` · `valeur_json` | **Une seule** des trois est renseignée (contrainte `one_value`) — un barème complexe passe par `valeur_json` |
| `unit` | Unité affichée |
| `debut_validite` · `fin_validite` | La plage de validité. `fin_validite` nul = toujours en vigueur |
| `indice_reference` | L'indice appliqué, quand la valeur en dépend |
| `source` | CCSS, ACD, Legilux, STATEC, calculé… **obligatoire** |
| `reference_legale` | L'article, par exemple `art. L.211-12` |
| `derive_de_cle` · `facteur_derive` · `tolerance_derivation` | Dérivation et contrôle de cohérence (§ 1.4) |
| `saisi_par` · `saisi_le` | Qui a saisi, et **quand** — ce n'est pas la même chose que `debut_validite` |
| `valide_par` · `valide_le` | La double lecture |

### La contrainte qui rend l'historique fiable

```sql
exclude using gist (
  cle_parametre with =,
  daterange(debut_validite, fin_validite, '[)') with &&
)
```

Deux versions d'une même clé **ne peuvent pas** se recouvrir. Ce n'est pas une convention à
respecter : la base refuse l'insertion. C'est ce qui permet à `fn_param` de faire un `limit 1` sans
ambiguïté, et à un recalcul de décembre 2025 de lire la valeur de décembre 2025.

L'extension `btree_gist` est requise pour cela et vit dans le schéma `public` — la déplacer
imposerait de recréer toutes les contraintes d'exclusion. C'est une advisory Supabase assumée.

### La lecture datée

```
fn_param_num(clé, date) → numeric      -- la valeur
fn_param(clé, date)     → parametres_legaux  -- la ligne entière, source et article compris
```

Ce sont les deux fonctions les plus appelées du moteur : tout le reste s'appuie dessus. Elles
prennent une **date** et retournent la version en vigueur **à cette date**, jamais la dernière
connue.

L'historique est réel, et vérifiable : le taux de pension salarié figure à 8,00 % jusqu'au
31.12.2025 et à 8,50 % depuis le 01.01.2026. Une paie de décembre 2025 recalculée aujourd'hui
utilise 8,00 %.

Les migrations chargent **98 clés de paramètres distinctes**. La migration 43 y a ajouté
l'historique officiel du salaire social minimum et de l'indice, repris du jeu STATEC `DF_C1201`
publié sur data.public.lu — 26 versions, de décembre 2006 à juin 2026.

### 1.4 Paramètres dérivés — et pourquoi la dérivation ne remplace pas la valeur publiée

Certaines valeurs découlent d'une autre : le maximum cotisable CCSS vaut cinq fois le salaire
social minimum non qualifié. La tentation est de le calculer.

La migration 21 l'a fait, la migration 22 l'a corrigé, et la raison mérite d'être connue :
5 × 2 771,33 = 13 856,65, alors que le maximum cotisable publié est 13 856,63. **Le SSM affiché est
lui-même un arrondi.** Dériver depuis l'arrondi introduirait deux centimes d'écart.

La règle retenue :

- si `valeur_num` est renseigné, **la valeur officielle fait foi** ;
- `derive_de_cle` × `facteur_derive` sert alors de **contrôle de cohérence** ;
- `fn_referential_inconsistencies(date)` liste les écarts qui dépassent `tolerance_derivation` —
  typiquement une indexation saisie sur le SSM mais oubliée sur le plafond ;
- si `valeur_num` est nul et `derive_de_cle` renseigné, la valeur est bien calculée, récursivement
  et **à la même date**.

`ccss_max_monthly` porte une tolérance de 0,05 €, documentée dans la migration.

### 1.5 Saisie et double lecture

```
fn_add_parameter_version(clé, debut_validite, valeur_num, valeur_texte, valeur_json, source, indice_reference, note)
```

Réservée à l'administrateur de l'espace. Elle **clôture la version en cours à la date d'effet** et
ouvre la nouvelle, en reprenant famille, libellé, unité et base légale de la précédente. Elle refuse
une clé inconnue — un paramètre se crée d'abord avec sa famille et son article — et refuse une
seconde version à la même date.

```
fn_validate_parameter_version(id)
```

Impose la **double lecture** : la fonction lève une exception si l'appelant est celui qui a saisi.

### 1.6 Les deux dates, et le recalcul qui n'existe pas encore

Les paramètres sociaux sont publiés par le CCSS et l'ACD **après** les changements. Deux dates
coexistent donc, et sont conservées séparément :

| Date | Signification |
|---|---|
| `debut_validite` | La date d'**application** de la valeur |
| `saisi_le` | La date de **chargement** dans le référentiel |

Un paramètre chargé aujourd'hui mais applicable à une période déjà traitée impose de reprendre les
calculs de cette période.

> **Reste à faire.** La structure permet cette détection — les deux dates sont là — mais la règle
> de déclenchement n'est pas écrite. Aucune reprise automatique n'a lieu aujourd'hui.

---

## 2. La hiérarchie des normes : loi → CCT → contrat

### `fn_arbitrate`

```
fn_arbitrate(libellé, valeur_loi, réf_loi, valeur_cct, réf_cct, valeur_contrat, plus_haut_est_mieux)
  → jsonb
```

Elle retient toujours la disposition **la plus favorable au salarié** et retourne l'ensemble du
raisonnement, pas seulement le résultat :

| Champ retourné | Contenu |
|---|---|
| `law_value` · `law_ref` | Ce que dit la loi, et son article |
| `cba_value` · `cba_ref` | Ce que dit la convention |
| `contract_value` | Ce que dit le contrat |
| `retained_value` | La valeur retenue |
| `retained_source` | `Code du travail`, `CCT` ou `Contrat individuel` |
| `retained_ref` | La référence de la norme qui a gagné |

Le drapeau `p_higher_is_better` traite les cas où le plus favorable est le **plus petit** : un délai
de carence, une durée de travail maximale.

Les deux interfaces affichent ce bloc tel quel — `ds.arbitration()` côté Streamlit,
`ContractPreview.tsx` côté React. Le raisonnement est visible par l'utilisateur, pas seulement par
le développeur.

### Conventions collectives multiples

Une société, un service ou un contrat peuvent relever de **plusieurs conventions simultanément** :
sectorielle, harcèlement, catégorie d'emploi, accord de service. Chacune a sa propre période.

| Fonction | Rôle |
|---|---|
| `fn_applicable_cbas(contrat, date)` | Toutes les conventions applicables à cette date, avec leur portée |
| `fn_cba_best_num(contrat, bloc, chemin, date, plus_haut_est_mieux)` | La meilleure valeur parmi toutes les conventions applicables, pour un chemin JSON donné |
| `fn_cba_value(cct, bloc, chemin)` | Lecture brute d'une clause |

Une CCT s'exprime en sept blocs (`bloc_convention`) : `salary_grid`, `worktime`, `leave`, `primes`,
`surcharges`, `notice_probation`, `custom_holidays`.

### Le garde-fou

`fn_check_cba_not_worse` est un **déclencheur**, pas une fonction appelable : il refuse
l'enregistrement d'une CCT moins favorable que la loi. Il n'est pas exposé en RPC.

### La limite à connaître

`regles_convention.rules` est du JSON libre par bloc. **Une clause que le moteur ne sait pas lire est
stockée sans être appliquée.** Le drapeau `complet` signale un bloc incomplet, mais il est
déclaratif : personne ne vérifie qu'il dit vrai. Le détail est dans
[couverture-droit-du-travail.md](couverture-droit-du-travail.md).

---

## 3. Les scans de conformité

Trois fonctions produisent un verdict structuré, sur trois objets différents.

### `fn_contract_compliance(contrat, date)`

Contrôle un contrat. Retourne des `ComplianceCheck` — `code`, `label`, `severity`, `detail`,
`reference_legale` — la liste des **mentions obligatoires** avec leur état, les arbitrages retenus, et
deux compteurs : `blocking_count` et `can_validate`. Elle couvre notamment le salaire minimum
applicable, la période d'essai, les bornes du CDD, les conventions applicables et les règles
propres aux mineurs.

### `fn_validate_schedule(planning)`

Contrôle un planning hebdomadaire. Retourne la liste des `Violation` — chacune avec sa gravité, son
code, son titre, son détail, son article, le salarié et la date de service concernés — un résumé par
salarié (heures, heures supplémentaires, dimanches, plus long repos) et trois indicateurs :
`blocking_count`, `warning_count`, `can_publish`.

`fn_publish_schedule(planning)` **refuse la publication** tant qu'une violation bloquante subsiste.
Ce n'est pas une confirmation que l'utilisateur peut écarter : c'est une exception côté serveur, et
`tests/publication.test.mjs` la vérifie.

Deux subtilités du calcul, corrigées en cours de route et documentées dans les migrations :

- **Le repos journalier de 11 heures s'apprécie entre deux journées de travail, pas entre deux
  vacations** (migration 11). Un service coupé 11:00–15:00 puis 17:00–23:00 ne crée pas de
  violation. La comparaison porte sur la fin de la dernière prestation d'un jour et le début de la
  première prestation du jour suivant.
- **La pause obligatoire s'apprécie service par service** (migration 13), et non sur la journée.

### `fn_compliance_scan(société, date)` — le centre de vigilance

Elle agrège **tout** ce qui concerne une société à une date donnée, et range chaque élément dans
trois paniers :

| Panier | Signification |
|---|---|
| `overdue` | En retard — l'échéance est passée |
| `due_soon` | Dans les 30 jours (horizon lu dans `vigilance_horizon_days`, pas écrit en dur) |
| `watch` | À surveiller |

Chaque `VigilanceItem` porte : `code_regle`, le salarié ou le contrat concerné, `title`, `detail`,
**`consequence`** (ce qui arrive si rien n'est fait), `date_echeance`, `days_left`, `severity`,
`reference_legale` et une `category` (`contract`, `absence`, `headcount`, `worktime`).

Le retour inclut aussi `headcount` (les obligations liées à la taille) et `dismissal_counters`
(les compteurs glissants de licenciement collectif), pour que l'écran n'ait pas à faire trois
appels.

La gravité est un type partagé : `blocking`, `warning`, `info`, `ok`.

---

## 4. Ce que le référentiel ne couvre pas — et qui le dit

Trois fonctions exposent les manques du référentiel. Elles ne servent pas au calcul : elles servent
à savoir sur quoi on calcule.

| Fonction | Question à laquelle elle répond |
|---|---|
| `fn_referential_gaps(depuis)` | Quels paramètres n'ont pas d'historique remontant assez loin ? Retourne, par clé : `couvert_depuis`, `couvert_jusqua`, `versions`, `couvre_depuis`, `jours_manquants`. La profondeur exigée par défaut est le **31.12.2019** |
| `fn_referential_holes()` | Quels paramètres ont un **trou** dans leur historique — une version close le 1er mars, la suivante ouverte le 1er juin ? Un calcul daté dans l'intervalle n'aurait aucune valeur applicable |
| `fn_referential_inconsistencies(date)` | Quelles valeurs publiées s'écartent de leur dérivation au-delà de la tolérance ? |

L'écran *Référentiel*, dans les deux applications, affiche ces trois listes. C'est délibéré : la
couverture du référentiel est une information de premier plan, pas une page d'administration
cachée.

### 4.1 Le trou que `fn_referential_gaps` ne pouvait pas voir — migration 50

Trois versions de `fn_referential_gaps` se sont succédé (migrations 21, 22), toutes construites en
groupant `parametres_legaux` par `cle_parametre`. Une clé que le moteur lit mais dont **aucune ligne**
n'a jamais été chargée n'apparaissait dans aucun groupe : elle était structurellement invisible,
quelle que soit la profondeur demandée. C'est exactement ainsi que le manque de `accident_class_rates`
(§ 5 ci-dessous) a pu passer inaperçu jusqu'à la revue du 10 septembre 2026.

La migration 50 introduit la table `parametres_attendus` : une ligne par clé que le moteur lit
réellement — relevée dans le code des migrations —, avec la ou les fonctions qui la lisent
(`lu_par`). **Elle ne porte aucune valeur légale**, seulement des clés et leurs lecteurs — 76 clés
y sont déclarées sur la base déployée. `fn_referential_gaps` part désormais de cette liste et fait
un `full outer join` vers `parametres_legaux` : une clé attendue sans aucune version sort avec
`versions = 0`, **en tête de la liste retournée**. Une clé chargée mais dont `lu_par` ressort nul
est le signe inverse : elle est lue autrement que par `fn_param`, ou elle est devenue inutile.

La migration 52 illustre l'usage prévu : `mileage_allowance_eur_per_km` y est insérée dans
`parametres_attendus` dès l'introduction de `fn_shift_travel`, **avant même qu'un tarif n'existe**
— la clé attendue et le manque sont déclarés ensemble, au lieu que le manque ne se découvre qu'au
premier appel raté. Elle reste **déclarée et vide** aujourd'hui, comme `accident_class_rates` :
aucune valeur légale n'a été inventée pour l'une ou l'autre.

---

## 5. Aucune erreur silencieuse

C'est la règle qui structure le comportement du moteur en cas de manque.

**Un calcul qui ne peut pas aboutir le dit, et explique pourquoi.** Il n'existe pas de valeur par
défaut destinée à masquer une donnée manquante.

L'exemple canonique est la retenue d'impôt. La table `tranches_impot` existe, elle a exactement la
forme attendue, `fn_income_tax` sait la lire — et elle est **vide**, parce que le barème publié par
l'Administration des contributions directes n'a pas été chargé et qu'aucun chiffre n'a été inventé
pour la remplir.

```
fn_income_tax(3400, '1', '2026-09-09')
  → { found: false,
      message: "Aucun barème chargé pour la classe 1 … Le calcul est suspendu plutôt que faux." }
```

Le même principe s'applique ailleurs :

- `fn_premium_caps(société, 2024)` retourne `found: false` : les plafonds de primes ne sont chargés
  qu'à partir du 01.01.2025. `tests/domain.test.mjs` vérifie explicitement qu'aucun plafond n'est
  inventé pour 2024 ;
- sur Oracle ou MySQL, `EngineUnavailable` nomme la fonction demandée et explique pourquoi elle
  n'est pas évaluable, plutôt que de rendre une valeur vraisemblable ;
- côté Streamlit, `app.py` enveloppe chaque vue dans un `try/except` qui affiche l'exception ;
- côté React, `callEngine()` transforme toute erreur PostgREST en exception, remontée par TanStack
  Query et affichée par le composant `ErrorNote`.

> Un chiffre plausible mais faux est pire qu'un trou déclaré. Un délai de préavis approximatif ne
> reste pas à l'écran : il se recopie dans un contrat.

### Le cas d'école : `fn_company_rates`, corrigée en migration 50

`fn_company_rates` (migration 23) devait lire le taux d'accident **propre à la classe de risque**
de la société. Sa ligne d'origine :

```sql
accident_rate := coalesce(accident_rate, accident_base) * rp.facteur_accident;
```

`accident_class_rates` n'a jamais été chargée dans le référentiel. `accident_rate` restait donc
toujours nul, le `coalesce` retombait systématiquement sur le taux de base — et la fonction
renvoyait `found: true`. Rien ne distinguait, dans la réponse, une société pour laquelle le taux de
classe avait été trouvé d'une société pour laquelle il ne l'avait jamais été : l'appelant croyait
lire un taux propre à sa classe de risque alors qu'il lisait toujours le taux générique. C'est très
exactement ce que la règle 5 interdit — une valeur qui a l'air complète et qui ne l'est pas.

Le trou n'a été visible qu'après la correction de `fn_referential_gaps` (§ 4.1) : sans la table
`parametres_attendus`, une clé jamais chargée ne remontait nulle part, et le repli silencieux de
`fn_company_rates` n'avait aucune chance d'être détecté par un contrôle automatique.

La version corrigée ne change ni le contrôle d'accès ni le calcul : elle **nomme la source retenue**.

```
fn_company_rates(société, date)
  → { found: true,
      accident_rate: 1.10,
      accident_rate_source: "base",       -- au lieu de "classe"
      complete: false,
      missing_parameters: ["accident_class_rates[classe 3]"],
      message: "Le taux de la classe de risque accident n'est pas disponible : le taux de base
                a été utilisé à sa place. Ce résultat ne doit pas servir de base à une déclaration.
                Paramètres manquants : accident_class_rates[classe 3]." }
```

Le repli existe toujours — il n'y a pas d'autre valeur à proposer tant que le référentiel n'est pas
chargé — mais il est désormais **nommé et daté**, avec `complete: false` pour qu'un appelant qui ne
lit pas le message puisse quand même détecter le manque par un simple test booléen.

---

## 6. Le contrôle d'accès, dans chaque fonction

Toutes les fonctions du moteur vérifient l'accès de l'appelant **avant** de calculer, par
`has_company_access(société)` ou `can_manage_company(société)`. Elles sont marquées `security
definer` — nécessaire pour lire à travers RLS — et portent toutes un `search_path` figé.

C'est ce qui rend acceptable qu'elles soient exécutables par tout utilisateur `authenticated` :
`tests/rls.test.mjs` interroge chacune avec le jeton d'un autre espace de travail et vérifie
qu'elles refusent.

Les primitives de chiffrement (`fn_encrypt_field`, `fn_decrypt_field`), les fonctions de
déclencheur et `fn_generate_public_holidays` sont **révoquées** pour tous les rôles.

---

## 7. Historisation — rien n'est figé sur la ligne qu'il décrit

| Ce qui évolue | Où vit l'historique |
|---|---|
| Classe d'activité, classe Mutualité, facteur accident | `periodes_taux_societe`, par période sans chevauchement |
| Conventions collectives | `conventions_de_la_societe`, `conventions_du_contrat`, chacune avec sa période |
| Droits à congé extraordinaire | `droits_absence` — le congé de mariage vaut 6 jours avant 2018, 3 jours après |
| Paramètres légaux et taux | `parametres_legaux`, contrainte d'exclusion GiST |
| Barèmes d'impôt | `tranches_impot`, par classe et par période |
| Droits du travailleur handicapé | `handicaps_salarie`, par période sans chevauchement |

C'est la même idée partout : figer une valeur mouvante sur la ligne qu'elle décrit rend tout
recalcul daté faux. La migration 23 le dit explicitement, en sortant les taux de la table
`societes`.

---

## 8. Le cycle de vie du contrat — migration 55

Deux règles, l'une posée en base, l'autre appliquée par une fonction unique.

### Un seul contrat en cours, imposé par une exclusion de périodes

Un salarié ne peut avoir qu'**un seul contrat au statut `active` à la fois** — mais ce n'est pas
« un seul contrat actif » au sens d'un compteur. Un contrat clos le 31 mars et un nouveau qui
commence le 1er avril sont tous deux légitimes ; un chevauchement d'un seul jour ne l'est pas. La
règle porte donc sur des **périodes**, pas sur un nombre de lignes.

```sql
alter table contrats
  add constraint one_active_contract_at_a_time
  exclude using gist (
    salarie_id with =,
    daterange(date_debut, date_fin, '[]') with &&
  ) where (status = 'active');
```

**Pourquoi une exclusion plutôt qu'un compteur.** Un compteur (`check (nombre_de_contrats_actifs <=
1)`) ne peut se maintenir qu'en recomptant à chaque écriture, et ne dit rien de la période :
il faudrait une colonne dérivée ou un déclencheur pour la même garantie. L'exclusion GiST fait les
deux choses à la fois — elle compare des `daterange` avec l'opérateur de recouvrement `&&`, la même
mécanique que la contrainte qui protège `parametres_legaux` (§ 1) — et elle refuse **en base**,
avant même qu'un déclencheur applicatif ait à s'en soucier. `date_fin` nul donne une borne haute
infinie : un CDI en cours bloque donc tout autre contrat actif à partir de sa date de début.

Vérifié avant la pose de la contrainte : 319 contrats actifs, zéro chevauchement — la contrainte n'a
cassé aucune donnée existante. Vérifié après : une insertion volontairement en conflit est rejetée.

### L'avenant, seule voie de modification d'un contrat en cours

Le droit du travail luxembourgeois ne connaît pas la modification unilatérale d'un élément
essentiel du contrat : il faut un avenant. Techniquement, cela veut dire que le contrat en cours se
clôt et qu'un nouveau prend sa suite — et que rien ne doit se perdre au passage.

```
fn_amend_contract(p_contract uuid, p_effective_date date, p_changes jsonb, p_reason text) → jsonb
```

1. Clôture le contrat en cours, `date_fin = p_effective_date - 1`.
2. Construit le nouveau contrat par `to_jsonb(ancien) || changements`, plutôt que par une
   énumération de colonnes : une colonne ajoutée demain sera reportée sans que personne ait à y
   penser, alors qu'une énumération manuelle oublie silencieusement — et un droit oublié dans un
   avenant est un droit perdu.
3. Reporte les lignes encore en vigueur de `elements_remuneration` et
   `conventions_du_contrat`.
4. Chaîne `contrat_precedent_id`, incrémente `version`, journalise dans `avenants_contrat` avec
   le motif fourni — un avenant sans motif est refusé.
5. Le nouveau contrat part **non signé** : un avenant se signe, et le moteur de vigilance le
   rappellera comme n'importe quelle autre mention manquante.

`fn_amend_contract` est la **seule** fonction du moteur qui écrit dans `contrats` pour un contrat
déjà en cours. Un `update` direct sur `contrats` reste possible pour une donnée qui n'a pas de
portée juridique (une faute de frappe dans le poste, par exemple), mais toute modification d'un
élément essentiel — rémunération, temps de travail, durée — doit passer par cette fonction. Elle
n'a aujourd'hui **aucun écran** dans les deux applications — voir
[personnel-et-horaires.md](personnel-et-horaires.md), lot 2.2.

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [api-serveur.md](api-serveur.md) — la signature de chaque fonction et qui l'appelle
- [architecture.md](architecture.md) — où se situe le moteur dans l'ensemble
- [modele-de-donnees.md](modele-de-donnees.md) — les tables que le moteur lit
- [couverture-droit-du-travail.md](couverture-droit-du-travail.md) — ce qui manque, nommé un par un
- [guide-utilisateur.md](guide-utilisateur.md) — comment ces verdicts apparaissent à l'écran
