# Ce que LuxRH couvre, et ce qu'il ne couvre pas

État au 10 septembre 2026, établi en interrogeant la base plutôt qu'en relisant
le cahier des charges : 47 tables, 272 fonctions de moteur, 100 paramètres
légaux suivis, 128 vérifications automatiques plus 26 sur la portabilité.

La question posée était : *la partie RH a-t-elle toutes les informations pour
toutes les conventions collectives et pour tout le droit du travail ?*

La réponse courte est **non, et les manques se nomment**. Ils sont peu nombreux
et ils sont ci-dessous. Ce qui suit distingue trois choses très différentes :
une **valeur absente** (le moteur attend un chiffre et ne le trouve pas), une
**notion absente du modèle** (aucune table ne sait la représenter), et une
**limite assumée** (on a choisi de ne pas la traiter).

---

## 1. Valeurs absentes — le moteur attend et ne trouve rien

### 1.1 Le barème d'impôt est vide

`tax_brackets` contient **zéro ligne**. La table existe, avec exactement la forme
demandée — classe d'impôt, période d'application, minimum et maximum de tranche,
impôt initial, taux sur le dépassement — et `fn_income_tax` sait la lire. Elle
n'a rien à lire.

Toute retenue d'impôt calculée aujourd'hui est donc impossible, et c'est
volontaire : aucune valeur n'a été inventée. Il manque le barème publié par
l'Administration des contributions directes. Les crédits d'impôt, eux, sont
présents (5 lignes).

**Conséquence** : la fiche de paie n'est pas calculable de bout en bout.

### 1.2 Vingt-neuf paramètres sur cent n'ont pas d'histoire avant 2020

Le référentiel est daté, mais vingt-neuf clés ne portent qu'une seule version.
Un recalcul portant sur une période antérieure lit alors la valeur d'aujourd'hui
— c'est-à-dire une valeur fausse, sans que rien ne le signale au calcul.

Deux d'entre elles **ont changé** dans la période :

| Paramètre | Ce qui s'est passé |
|---|---|
| `annual_leave_min_days` | Le congé légal est passé de 25 à 26 jours au 1er janvier 2019 |
| `public_holidays_count` | La Journée de l'Europe est devenue jour férié en 2019 |

Les taux de cotisation CCSS (`ccss_*`, onze clés) n'ont pas non plus d'historique :
**aucune régularisation rétroactive n'est possible**.

Le reste des vingt-neuf sont des réglages applicatifs — horizon de vigilance,
délais d'alerte, durées de conservation — dont l'absence d'historique est sans
conséquence sur un calcul.

*Réparé depuis* : le salaire social minimum et l'indice ont reçu leurs 26
versions officielles, de décembre 2006 à juin 2026, reprises du jeu STATEC
`DF_C1201` publié sur data.public.lu. La valeur STATEC au 1er juin 2026 coïncide
exactement avec la publication CCSS déjà en base — les deux sources se recoupent.

### 1.3 Ce que les sources publiques ne donnent pas

Recherche faite sur data.public.lu : le portail **ne publie ni les conventions
collectives, ni les tables de paramètres CCSS**. Seul le STATEC y expose des
séries exploitables (salaire social minimum, indice). Les CCT restent à saisir
depuis les textes déposés à l'ITM, et les paramètres CCSS depuis les
publications de la Caisse.

C'est précisément pourquoi l'export du référentiel existe : ce qui est saisi à
la main une fois ne doit plus jamais l'être.

---

## 2. Notions absentes du modèle

Aucune table ne sait aujourd'hui représenter ce qui suit. Classé par
conséquence, la plus lourde d'abord.

### 2.1 Le reclassement professionnel — Livre III

Le handicap est modélisé (`employee_disabilities`, taux, congé supplémentaire).
Le **reclassement**, interne ou externe, ne l'est pas — et c'est un régime
distinct : décision de la Commission mixte, protection contre le licenciement,
indemnité compensatoire, statut de salarié en reclassement externe.

C'est, en droit luxembourgeois, une institution majeure et fréquente. Son
absence est le manque le plus important de cette liste.

### 2.2 Des congés légaux hors catalogue

`absence_types` en porte dix-sept : congé annuel, maladie, maternité, paternité,
parental, décès par degré, mariage, déménagement, accompagnement, raisons
familiales, congé jeunesse, compensatoire, sans solde.

Manquent, alors qu'ils sont de droit :

- congé individuel de formation ;
- congé linguistique ;
- congé sportif ;
- congé culturel ;
- congé pour mandat social ;
- congé d'accueil (adoption).

La formation figure bien dans `benefit_types`, mais comme **avantage en nature**
— c'est-à-dire comme quelque chose que l'employeur accorde, pas comme un droit
que le salarié exerce. Les deux ne se calculent pas de la même façon.

### 2.3 Préretraite

Aucun des trois régimes — ajustement, progressive, travail posté — n'est
représenté.

### 2.4 Chômage partiel et intempéries

Absent. Le licenciement collectif est modélisé, avec ses seuils et ses délais
(`fn_simulate_collective_dismissal`), mais le **plan de maintien dans l'emploi**,
qui en est l'alternative, ne l'est pas.

### 2.5 Égalité salariale

Aucune structure pour mesurer ni déclarer un écart de rémunération. Le sexe est
enregistré, la rémunération aussi : la mesure est possible, elle n'est pas faite.

### 2.6 Compte épargne-temps

Absent.

---

## 3. Les conventions collectives

### 3.1 Ce que le modèle sait arbitrer

Une CCT s'exprime en sept blocs (`cba_block`) : `salary_grid`, `worktime`,
`leave`, `premiums`, `surcharges`, `notice_probation`, `custom_holidays`. Le
champ d'application est modélisé (portée, secteur, catégorie de personnel), les
périodes de validité aussi, et une société comme un contrat peuvent en relever
de plusieurs.

L'arbitrage loi → CCT → contrat fonctionne et **dit quelle norme l'a emporté**
(`fn_arbitrate`), avec un garde-fou qui refuse une CCT moins favorable que la loi
(`fn_check_cba_not_worse`).

C'est le cœur calculable d'une CCT, et il est couvert.

### 3.2 Ce qu'une CCT contient et que le modèle ne structure pas

- **Régime complémentaire de pension.** Présent comme avantage en nature, absent
  comme régime : affiliation, taux patronal et salarial, acquisition des droits.
- **Droits à la formation** conventionnels.
- **Facilités syndicales** au-delà du crédit d'heures légal (celui-ci est bien
  modélisé : `delegation_delegates_scale`, `released_delegate_threshold`).
- **Clauses de sécurité d'emploi** et de restructuration.
- **Procédure disciplinaire et de réclamation.**
- **Treizième mois et gratification.** Rangeables dans `premiums`, mais sans
  règle propre : prorata d'entrée et de sortie, condition de présence à une date,
  exclusion pendant certaines absences — rien de tout cela n'est exprimable.
- **Prime d'ancienneté** à progression automatique.
- **Astreinte.**

### 3.3 Une limite à connaître

`cba_rules.rules` est du JSON libre par bloc. Une clause que le moteur ne sait
pas lire **est stockée sans être appliquée**. Le drapeau `is_complete` signale
un bloc incomplet, mais il est déclaratif : personne ne vérifie qu'il dit vrai.

Autrement dit : le modèle accepte n'importe quelle CCT, il n'en applique que les
sept blocs. C'est un choix défendable — il vaut mieux stocker que perdre — mais
il ne faut pas le confondre avec une couverture complète.

---

## 4. Ce qui est solidement couvert

Pour ne pas donner une image faussement sombre, voici ce qui l'est.

| Domaine | État |
|---|---|
| Typologie des contrats | CDI, CDD, saisonnier, apprentissage, intérim |
| CDD | motifs, durée maximale, renouvellements, carence, alertes |
| Période d'essai | durée, prolongation, préavis propre, échéances |
| Préavis et licenciement | ancienneté, indemnité de départ, entretien préalable |
| Licenciement collectif | seuils 30 et 90 jours, ONC, délais de négociation |
| Statuts protégés | grossesse, maternité, allaitement, parental, délégués, dirigeants |
| Temps de travail | période de référence, repos journalier et hebdomadaire, pauses |
| Heures supplémentaires | demande formelle, validation préalable, éligibilité, plafonds |
| Travail de nuit, dimanche, férié | majorations, interdictions selon le statut |
| Congés | acquisition mensuelle, fractions, solde, congé jeunesse, handicap |
| Maladie | compteurs, délai de certificat, continuation, alerte d'absentéisme |
| Jours fériés | génération, collisions, récupération, fériés conventionnels |
| Salaire minimum | qualifié, non qualifié, barème d'âge, historique 2006-2026 |
| Effectifs | seuils de délégation, éligibilité, obligations liées à la taille |
| Documents | embauche, périodiques, fin de contrat, validité, alertes |
| Primes | participative, plafonds individuels et d'entreprise 2025 |
| Chèques-repas | valeur faciale, part salariale |
| Avantages en nature | neuf types, méthodes de valorisation |
| Matricule CCSS | somme de contrôle, date, parité de sexe |
| RGPD | chiffrement au repos, durées de conservation, export, registre |

---

## 5. Dans quel ordre combler

1. **Charger le barème d'impôt.** C'est ce qui bloque le calcul complet d'une
   paie, et la table n'attend que ses lignes.
2. **Historiser les taux CCSS** et les deux paramètres qui ont changé en 2019.
   Sans cela, aucune régularisation rétroactive n'est juste.
3. **Modéliser le reclassement professionnel.** Le manque fonctionnel le plus
   lourd.
4. **Compléter le catalogue des congés légaux.**
5. **Ajouter les blocs CCT manquants**, en commençant par le treizième mois et
   la prime d'ancienneté : ce sont les clauses que l'on rencontre partout.
6. Le reste — préretraite, chômage partiel, épargne-temps, égalité salariale —
   selon les besoins réels des dossiers traités.

Aucun de ces points ne demande de reprendre l'architecture : le référentiel daté
et l'arbitrage des normes les accueillent tels quels.
