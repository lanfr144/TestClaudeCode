# Audit de `paramètres.xlsx`

Relevé du 17 September 2026. Généré par `tools/auditer_classeur.py` — ce document se régénère, il ne se tient pas à la main.

Feuille : `Paramêtres`. 15 colonnes datées.

| Gravité | Ce que cela signifie | Nombre |
|---|---|---|
| **BLOQUANT** | empêche de charger la clé, ou la chargerait fausse | 19 |
| **À VÉRIFIER** | charge quelque chose, mais peut-être pas ce qui était voulu | 8 |
| **HYGIÈNE** | n'empêche rien aujourd'hui, prépare une erreur demain | 4 |

## BLOQUANT — 19

### clé

- **ligne 9** — « SSM » apparaît 2 fois (lignes 9, 15) : un identifiant pour plusieurs grandeurs
- **ligne 92** — « REVISE » apparaît 2 fois (lignes 92, 101) : un identifiant pour plusieurs grandeurs
### valeur

- **ligne 3** — « Enfant_Jours_5 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 4** — « Enfant_Jours_13 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 5** — « Enfant_Jours_18 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 6** — « Enfant_Handicape » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 7** — « Adulte_Handicap » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 31** — « MICP » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 33** — « MACP » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 126** — « ASS_ASS_MAL_MAT » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 142** — « ASS_ACC_TAUX_BASE » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 143** — « ASS_ACC_TAUX_085 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 144** — « ASS_ACC_TAUX_100 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 145** — « ASS_ACC_TAUX_110 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 146** — « ASS_ACC_TAUX_130 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 147** — « ASS_ACC_TAUX_150 » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 214** — « Bail » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 222** — « Ménages » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule
- **ligne 223** — « Impôts forfétaire » n'a aucune valeur dans aucune colonne historique et ne porte pas de formule

## À VÉRIFIER — 8

### clé

- **ligne 35** — « 'IF » commence par une apostrophe — Excel échappe ainsi ce qu'il prendrait pour une formule. La clé réelle est « IF »
### colonnes

- **ligne 1** — la colonne H (2026-06-01) n'est renseignée que pour 3 clé(s) sur 169 : relevé partiel. Les clés absentes de cette colonne ne sont pas signalées comme trouées
- **ligne 1** — la colonne I (2025-05-01) n'est renseignée que pour 3 clé(s) sur 169 : relevé partiel. Les clés absentes de cette colonne ne sont pas signalées comme trouées
- **ligne 1** — la colonne J (2025-01-01) n'est renseignée que pour 5 clé(s) sur 169 : relevé partiel. Les clés absentes de cette colonne ne sont pas signalées comme trouées
- **ligne 1** — la colonne Q (2022-01-01) n'est renseignée que pour 5 clé(s) sur 169 : relevé partiel. Les clés absentes de cette colonne ne sont pas signalées comme trouées
### formule

- **ligne 88** — « CPMa » : la colonne C se calcule mais la colonne F porte '1.666665433806505'
### orphelin

- **ligne 216** — ligne sans clé mais avec des valeurs : « Maison ». Un titre de section ne porte pas de valeurs — cette ligne ne sera pas chargée
### série

- **ligne 167** — 26 clé(s) sans valeur au relevé du 2023-04-01, entre deux relevés renseignés et sans formule : CR_NB, CONGE_MIN, CONGE_HANDICAP, JOUR_H, JOUR_MAX_H, SEMAINE_H, SEMAINE_MAX, HS_3M …

## HYGIÈNE — 4

### formule

- **ligne 10** — 11 formule(s) du second jeu (colonne G) référencent des cellules là où le premier jeu (colonne D) nomme ses opérandes : PARAMÈTRES SOCIAUX, SSM, MSNQ18H, MSNQ18H100, MSNQ18, IF, CPMiH, CPMi … et 3 autres. Insérer une ligne casse le second jeu en silence
### libellé

- **ligne 3** — 73 clé(s) sans description — le référentiel affichera la clé brute : Enfant_Jours_5, Enfant_Jours_13, Enfant_Jours_18, Enfant_Handicape, Adulte_Handicap, SSM, PARAMÈTRES SOCIAUX, ssm_100, MSNQ18, MSNQ17 … et 63 autres
### nommage

- **classeur** — trois conventions de nommage coexistent (MAJUSCULES : 140 ; minuscules : 7 ; mixte : 22). Exemples mixtes : Adulte_Handicap, Bail, Bail_charge, Bail_employeur, CPMa, CPMaH
- **classeur** — 8 clé(s) portent un accent : Impôts forfétaire, Maladie_espèce, Ménages, PARAMÈTRES SOCIAUX, bail_meublé, bail_salarié, dépendance, dépendance_moins. Une clé sert d'identifiant technique — elle traverse SQL, JSON et URL

