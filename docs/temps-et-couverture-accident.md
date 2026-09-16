# Le temps de travail en segments, et la couverture accident

Ce document décrit `segments_temps`, pourquoi ce modèle remplace les totaux
journaliers, et **ce qui n'est pas encore tranché**.

---

## Pourquoi des segments plutôt que des totaux

`releves_temps` porte quatre totaux par journée : `heures_nuit`,
`heures_dimanche`, `heures_ferie`, `heures_supplementaires`. Ces totaux suffisent
à établir une paie, et à rien d'autre.

Un total ne dit pas **quand**. On ne peut donc pas répondre, après coup, à la
question qui décide d'un dossier d'accident du travail :

> à 14 h 37, ce salarié était-il sous la responsabilité de l'employeur ?

Un segment est une plage sur laquelle **rien ne change** : même classe de paie,
mêmes qualifications, même lieu. Dès qu'une caractéristique change, un nouveau
segment commence. Les totaux restent calculables par somme ; l'inverse est faux.

---

## Ce qu'un segment porte

| Colonne | Ce qu'elle dit |
|---|---|
| `debut_le`, `fin_le` | Horodatages **avec fuseau**. Une vacation de nuit franchit minuit, et un changement d'heure ne doit pas décaler le décompte |
| `minutes` | Calculée, arrondie au supérieur — une minute entamée est due |
| `classe_paie` | Nature du temps : travail, interruption, déplacement |
| `couverture_aaa` | Couvert, hors couverture, ou **à déterminer** |
| `est_nuit`, `est_dimanche`, `est_ferie` | Trois drapeaux, pas une classe unique |
| `origine` | `planifie` ou `constate` — les deux coexistent pour être comparés |

### Trois drapeaux, et non une classe exclusive

L'article L. 232-7, paragraphe (3), le commande :

> « Si l'un des jours fériés énumérés à l'article L. 232-2 tombe un dimanche, le
> salarié occupé ce jour a droit au cumul des indemnités. »

Une classe unique aurait écrasé l'une des deux qualifications. Le cas est réel :
le 1er novembre 2026, la Toussaint tombe un dimanche.

---

## Le découpage

`fn_decouper_creneau(creneau)` rassemble tous les instants où une qualification
change, les trie, et crée un segment entre chaque paire consécutive. Chaque
segment est alors homogène **par construction**, sans qu'il faille énumérer les
cas.

Les instants de rupture :

- le début et la fin de la vacation ;
- le début et la fin de la pause ;
- chaque **minuit** traversé — le jour change, donc le dimanche et le jour férié
  peuvent changer ;
- chaque passage de `H_NUIT` et de `H_MATIN`, les bornes de la fenêtre de nuit,
  lues dans le référentiel et jamais écrites en dur.

Les qualifications s'évaluent **au milieu** de chaque sous-intervalle. Les
évaluer sur une borne ferait dépendre le résultat du fait que la borne est
incluse ou exclue, et un segment de 22 h 00 à 23 h 00 serait tantôt de nuit,
tantôt non.

### Ce que cela donne

Vacation du samedi 31 octobre 2026, 22 h 00 → 06 h 00, trente minutes de pause :

| Début | Fin | Minutes | Classe | Nuit | Dimanche | Férié |
|---|---|---|---|---|---|---|
| Sam 31/10 22:00 | Dim 01/11 00:00 | 120 | normal | ✔ | | |
| Dim 01/11 00:00 | Dim 01/11 01:45 | 105 | normal | ✔ | ✔ | ✔ |
| Dim 01/11 01:45 | Dim 01/11 02:15 | 30 | pause_repas | ✔ | ✔ | ✔ |
| Dim 01/11 02:15 | Dim 01/11 06:00 | 225 | normal | ✔ | ✔ | ✔ |

450 minutes de travail effectif, soit huit heures moins la pause.

### La pause est posée au milieu

Le créneau ne dit pas quand la pause est prise. La poser au milieu est une
**convention**, énoncée plutôt que tue. Un relevé de temps réel, lui, la situera
exactement.

---

## Les heures supplémentaires ne naissent pas d'un segment

Aucun segment ne reçoit la classe `heure_sup` au découpage, et c'est délibéré :
l'heure supplémentaire se constate sur la **période de référence**, pas sur une
vacation isolée. Un salarié qui fait neuf heures un mardi et six le mercredi n'a
pas fait d'heure supplémentaire si sa période de référence est mensuelle.

La requalification est donc une seconde passe, à écrire — voir les réserves
ci-dessous.

---

## La couverture accident : ce qui est posé, ce qui ne l'est pas

`ref_couverture_aaa` porte **trois** états et non un booléen, pour la même raison
que `fn_validate_address` répond `ok` / `outside` / `unknown` : « on ne sait
pas » n'est pas « non ».

| État | Quand |
|---|---|
| `couvert` | Temps de travail effectif, sous subordination de l'employeur |
| `non_couvert` | Établi comme hors couverture. **Aucun segment ne le reçoit par défaut** : cela se constate, cela ne se présume pas |
| `a_determiner` | Qualification non tranchée |

### Pourquoi tant de « à déterminer »

La couverture du trajet domicile-travail, de la pause repas prise hors de
l'entreprise et du déplacement entre deux sites relève du **Code de la sécurité
sociale**, qui ne figure pas au corpus documentaire du projet.

Tant que la source manque, l'état reste `a_determiner`. C'est la règle 7 du
projet : un chiffre plausible mais faux est pire qu'un trou déclaré. Ici, une
qualification inventée se traduirait par un refus de prise en charge découvert au
pire moment.

**Ce qu'il faut pour trancher** : verser au corpus le Code de la sécurité
sociale, livre II (assurance accident), et en tirer les règles de qualification
du trajet et de la pause.

---

## Ce qui reste à faire

| Point | État |
|---|---|
| Découpage d'une vacation planifiée | ✅ éprouvé, y compris nuit / minuit / dimanche / férié / pause |
| Segments issus d'un relevé **réel** | ❌ `fn_decouper_creneau` ne traite que le planifié |
| Requalification des heures supplémentaires sur la période de référence | ❌ à écrire |
| Segments de trajet — domicile, inter-sites | ❌ la table les accueille, rien ne les produit |
| Qualification AAA du trajet et de la pause | ❌ source légale absente du corpus |
| Reprise de `releves_temps` vers les segments | ❌ les deux modèles coexistent |

Les deux modèles coexistent volontairement : `releves_temps` reste la source des
totaux de paie tant que la requalification des heures supplémentaires n'est pas
écrite. Les faire cohabiter sans les réconcilier serait le prochain défaut à
éviter — deux comptes du même temps finissent toujours par diverger.

---

## Voir aussi

- [`modele-de-donnees.md`](modele-de-donnees.md) — les tables par domaine
- [`donnees-de-reference.md`](donnees-de-reference.md) — charger le référentiel
- [`../CLAUDE.md`](../CLAUDE.md) — les règles du projet
