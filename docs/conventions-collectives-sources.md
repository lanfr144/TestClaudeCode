# Conventions collectives : ce que le corpus contient, et ce qui le remplace

Ce document répond à une question précise : **quelle norme applique le moteur
quand aucune convention collective sectorielle n'existe ?**

La réponse n'est jamais « rien ». Elle est toujours « le Code du travail », et
c'est une différence de taille : un secteur sans convention n'est pas un secteur
sans règles.

---

## Ce que le corpus contient

Vingt-quatre secteurs, tous issus du registre de l'Inspection du travail et des
mines. Le schéma d'URL est visible dans chaque document :

```
https://itm.public.lu/fr/accords-collectifs/convention-collectives/<secteur>.html
```

### Deux rectifications

| Ce qu'on croyait | Ce que le document dit |
|---|---|
| `traiteur-restauration/` = HORESCA | **« Restauration collective »**, valable du 1<sup>er</sup> mai 2024 au 30 avril 2027 |
| CCT du secteur d'aide et de soins absente | `secteur-social/` **est** la CCT SAS, applicable du 1<sup>er</sup> janvier 2025 au 31 décembre 2027 |

La seconde est la plus utile : la convention du secteur d'aide et de soins n'est
pas à récupérer, elle est là.

---

## Les secteurs sans convention sectorielle

Pour chacun, le moteur ne cherche pas une convention qui n'existe pas : il
applique la norme de substitution, et le dit.

### HORESCA — hôtellerie, restauration, cafés

**Il n'existe pas de convention sectorielle générale déclarée d'obligation
générale** pour l'ensemble de la branche. S'appliquent :

- le **Code du travail**, livre II — durée du travail, travail dominical, jours
  fériés ;
- le **règlement grand-ducal** organisant le temps de travail dans
  l'hôtellerie et la restauration ;
- des **conventions d'entreprise** : concessions aéroportuaires, chaînes
  hôtelières.

Sources : fiche de branche HORESCA, publications du ministère du Travail,
guichet.lu.

> Conséquence pour le moteur : un contrat rattaché à ce secteur ne doit **pas**
> être bloqué faute de convention. C'est le socle légal qui s'applique, et les
> conventions d'entreprise se saisissent une par une.

### Commerce et alimentation

Pas de convention sectorielle unifiée pour le commerce de détail. S'appliquent :

- le **Code du travail**, art. L. 211-1 et suivants ;
- les **arrêtés grand-ducaux** sur les heures d'ouverture des commerces ;
- des **conventions d'entreprise** majeures — Cactus, Auchan, Match — et des
  conventions de gros.

### Coiffure

**Convention collective des maîtres-coiffeurs du Grand-Duché**, négociée par la
Fédération des patrons coiffeurs avec l'OGBL et le LCGB.

Sources : Chambre des Métiers (`chambre-des-metiers.lu`), avis au Mémorial B /
Recueil administratif.

### Boulangerie-pâtisserie

**Accord de branche** de la Fédération patronale des boulangers-pâtissiers.

Sources : Chambre des Métiers, archives contractuelles de la Fédération des
artisans (`fda.lu`).

### Agriculture et viticulture

Pas de convention générale étendue. S'appliquent le **Code du travail** avec ses
régimes d'exception pour travaux saisonniers et urgences climatiques — livre II,
titre I<sup>er</sup>, chapitre I<sup>er</sup> — et les référentiels de la Chambre
d'agriculture (`chambre-agriculture.lu`).

> Les régimes d'exception saisonniers sont à modéliser : ils dérogent aux durées
> maximales que `fn_validate_schedule` contrôle aujourd'hui sans nuance.

### Aides et soins à domicile

**Déjà au corpus** — voir plus haut. Également sur Legilux et auprès de la COPAS
(`copas.lu`).

---

## Ce que cela change pour le moteur

Trois conséquences, dont deux ne sont pas encore traitées.

1. **Un secteur sans convention reste régi.** Le garde-fou d'embauche ne doit pas
   exiger une convention là où il n'en existe pas : il doit constater que le
   socle légal s'applique, et le nommer.

2. **Les conventions d'entreprise sont la règle, pas l'exception**, dans
   l'HORESCA et le commerce. Le modèle les accueille déjà —
   `conventions_collectives.organisation_id` distingue le sectoriel partagé du
   propre à une organisation — mais rien ne signale à l'utilisateur que son
   secteur en relève.

3. **Les régimes d'exception saisonniers** de l'agriculture dérogent aux durées
   maximales. `fn_validate_schedule` les ignore : un planning de vendanges y
   serait déclaré non conforme à tort.

---

## Ce qui n'entre pas dans le dépôt

Aucun de ces textes. La règle d'or du projet vaut ici comme ailleurs : on stocke
la **référence**, jamais le fichier. `docs/sources-legales.md` porte le manifeste,
et `tools/telecharger_sources.py` reconstitue le répertoire local.

---

## Voir aussi

- [`couverture-droit-du-travail.md`](couverture-droit-du-travail.md) — ce que le moteur contrôle
- [`sources-legales.md`](sources-legales.md) — le manifeste des sources
- [`../CLAUDE.md`](../CLAUDE.md) — la hiérarchie des normes
