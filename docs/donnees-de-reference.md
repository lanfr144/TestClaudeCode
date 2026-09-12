# Données de référence : où elles viennent, quand et comment les charger

Ce document répond à quatre questions précises : **où sont les informations**,
**quand** charger le référentiel, **comment** le charger, et **comment tester**.

Il complète [`feuille-de-route.md`](feuille-de-route.md), qui suit l'avancement, et
[`bases-de-donnees.md`](bases-de-donnees.md), qui décrit la portabilité.

---

## 1. Où en est le chargement

| Catégorie | État | Détail |
|---|---|---|
| Pays | ✅ 248 | ISO 3166-1 alpha-3 et alpha-2, noms français, trois frontaliers marqués |
| Jours fériés | ✅ 77 | 2024 à 2030, les onze jours légaux luxembourgeois |
| Tables de domaine `ref_*` | ✅ 12 | Codes et libellés en français |
| Catalogues métier | ✅ 5 | Absences (17), documents (11), avantages (9), sanctions (3 + 8) |
| Paramètres légaux | ◐ 100 clés | 97 couvertes, **3 sans source** |
| Barème d'impôt | ○ vide | `tranches_impot` : structure prête, valeurs absentes |

Le décompte exact, à tout moment :

```sql
select * from fn_referential_gaps() where versions = 0;
```

### Les trois clés qui manquent, et pourquoi elles manquent

| Clé | Lue par | Ce qu'il faut |
|---|---|---|
| `accident_class_rates` | `fn_company_rates` | Barème des classes de risque de l'**Association d'assurance accident** (AAA) |
| `mileage_allowance_eur_per_km` | `fn_shift_travel` | Barème kilométrique — 0,30 €/km par défaut, 0,25 € pour la convention du nettoyage |
| `sanction_notification_deadline_days` | `fn_sanction_check` | Délai légal de notification d'une sanction disciplinaire |

Ces trois valeurs **ne sont pas inventées**, et ne le seront pas : c'est la règle 7
du [`CLAUDE.md`](../CLAUDE.md). Un chiffre plausible mais faux se recopie dans une
paie et ne se retrouve plus. Tant qu'elles manquent, les fonctions qui les lisent
**refusent de conclure** et le disent — elles ne se rabattent sur rien.

À l'inverse, trois autres clés ont été chargées (migration 89) parce qu'elles ne
sont **pas** des valeurs légales : les deux seuils d'alerte CCSS (7 jours et
2 jours, spécifiés le 12 septembre 2026) et le nombre de contre-propositions
d'absence admises. Leur source est le projet lui-même, et elle est inscrite dans
la colonne `source`.

---

## 2. Où trouver les informations

### Sources officielles luxembourgeoises

| Donnée | Source |
|---|---|
| Textes du Code du travail | **Legilux** — `legilux.public.lu`, recueil « Droit du travail » |
| Conventions collectives déposées | **ITM** — `itm.public.lu`, registre des CCT |
| Barème de l'impôt sur les salaires | **Administration des contributions directes** (ACD) |
| Classes de risque accident | **Association d'assurance accident** (AAA) |
| Taux de cotisation, matricules | **CCSS** — `ccss.public.lu` |
| Index et salaire social minimum | **STATEC** |
| Adresses et localités | **Registre national des localités et des rues**, via le géoportail |
| Jeux de données ouverts | **`data.public.lu`** |

### Ce que le dépôt contient déjà

- `parametres_attendus` — les 100 clés que le moteur lit, avec pour chacune la
  fonction qui la consomme. C'est la liste de courses.
- `docs/couverture-droit-du-travail.md` — ce qui est couvert et ce qui ne l'est pas.
- La colonne `reference_legale` de chaque paramètre chargé cite l'article qui le fonde.

**Aucune valeur légale n'est écrite en dur dans le code applicatif** — ni en
TypeScript, ni en Python, ni dans une fonction. Tout vient de `parametres_legaux`,
daté et sourcé.

---

## 3. Quand charger le référentiel

**À tout moment, sans interruption de service.** Le référentiel est daté : une
nouvelle version d'un paramètre s'ajoute, elle n'écrase pas la précédente.

La règle est stricte et tenue en base par une contrainte d'exclusion GiST : deux
versions d'une même clé ne peuvent pas se chevaucher. Pour introduire une valeur
au 1er janvier :

1. la version en cours est close au 1er janvier (borne haute **exclue**) ;
2. la nouvelle commence au 1er janvier, fin de validité `2037-12-31`.

`fn_add_parameter_version` fait les deux en une fois, et refuse le chevauchement
plutôt que de l'arbitrer.

Un recalcul de paie lit la valeur **en vigueur à la date du calcul**, pas la
dernière connue : charger une valeur 2027 ne change rien aux bulletins de 2026.

---

## 4. Comment charger

### a. Un paramètre, par la fonction dédiée — recommandé

```sql
select fn_add_parameter_version(
  p_key         => 'mileage_allowance_eur_per_km',
  p_valid_from  => date '2026-01-01',
  p_value_num   => 0.30,
  p_source      => 'Règlement grand-ducal du ...',
  p_legal_ref   => 'RGD art. ...');
```

Elle clôt la version précédente, insère la nouvelle, et refuse si la période
recouvre une autre.

### b. Un référentiel complet, par l'import

`fn_import_referential` charge un document produit par `fn_export_referential`.
Les lignes sont reconnues par **clés naturelles** — `cle_parametre`,
`debut_validite`, `code` — jamais par identifiant technique : recharger un
référentiel déjà en place ne duplique rien.

```bash
# Depuis l'interface : Réglages > Portabilité > Importer un référentiel
```

Trois modes : `skip_existing` (par défaut), `replace`, `dry_run`.

### c. Une table de domaine

Un `insert` suffit — c'est l'intérêt d'avoir remplacé les contraintes `CHECK`
par des tables. Ajouter un motif d'absence ne demande **aucune migration** :

```sql
insert into types_absence (code, libelle, categorie, remunere)
values ('conge_sportif', 'Congé sportif', 'conge_extraordinaire', true);
```

### d. Ce qu'il ne faut pas faire

Ne jamais écrire un `update` direct sur une ligne de `parametres_legaux` en
vigueur. L'historique est la garantie qu'un recalcul rétroactif reste juste ;
l'écraser rend tout calcul passé irreproductible.

---

## 5. Comment tester

### Les six suites

```bash
cd luxrh && npm test          # 190 vérifications
```

| Suite | Vérifie |
|---|---|
| `api` | 80 — lectures du front, moteur de règles, cohérence du référentiel |
| `rls` | 22 — cloisonnement entre organisations, entre sociétés, et du salarié |
| `publication` | 10 — un planning en violation ne se publie pas |
| `domain` | 16 — sanctions, enfants, primes, plafonds |
| `portability` | 26 — export RGPD, réversibilité, aller-retour du référentiel |
| `lifecycle` | 36 — adresses, lecture auditée, avenant de contrat |

Les suites **défont leurs propres écritures** : elles peuvent être relancées.

### Les trois outils de vérification

```bash
luxrh-py/.venv/Scripts/python tools/dump_migrations.py --ecrire   # dépôt ⇄ base
luxrh-py/.venv/Scripts/python tools/fetch_catalogue.py            # relit le schéma
luxrh-py/.venv/Scripts/python tools/emit_portable_schema.py schema/catalogue.json schema/
luxrh-py/.venv/Scripts/python tools/verifier_coherence.py         # 8 contrôles
```

`verifier_coherence.py` doit répondre **« Aucun écart »**. Il vérifie que toute
fonction appelée existe, que la RLS est partout, qu'aucune fonction n'est ouverte
à `anon`, que toute colonne est commentée, que les liens de la documentation
tiennent, que les chiffres annoncés correspondent, qu'aucune colonne `not null`
n'est traitée comme nullable, et que le dépôt porte bien les migrations appliquées.

### Tester une valeur légale avant de la charger

```sql
-- Ce que le moteur répond aujourd'hui, sans la valeur :
select fn_company_rates('<uuid societe>', current_date);
-- → { "complete": false, "missing_parameters": ["accident_class_rates"], ... }
```

La fonction dit ce qu'elle n'a pas pu calculer. Après chargement, `complete`
passe à `true` et `missing_parameters` se vide. C'est le test le plus direct :
**le moteur déclare ses trous**.

---

## 6. Environnement local

Relevé le 12 septembre 2026 sur ce poste :

| | État |
|---|---|
| WSL | ✅ version 2, distributions `AI-P02` (par défaut) et `Mlops1`, **arrêtées** |
| Distribution `luxrh` | ❌ n'existe pas |
| Docker | ❌ non installé |
| Node.js | ✅ `C:\Program Files\nodejs\node.exe` — **absent du PATH**, à préfixer |
| Python | ✅ `luxrh-py/.venv/Scripts/python` |

La base de développement est **Supabase hébergé** : aucun conteneur n'est
nécessaire pour lancer l'application ou les tests. Un environnement Oracle
conteneurisé ne sert qu'à éprouver `schema/oracle.sql` — il reste à monter, et
demande d'installer Docker Desktop avec l'intégration WSL.

---

## Voir aussi

- [`feuille-de-route.md`](feuille-de-route.md) — l'avancement, chantier par chantier
- [`ecarts-a-corriger.md`](ecarts-a-corriger.md) — les défauts relevés et leur état
- [`moteur-de-regles.md`](moteur-de-regles.md) — ce que chaque fonction calcule
- [`../CLAUDE.md`](../CLAUDE.md) — les règles qui ne se négocient pas
