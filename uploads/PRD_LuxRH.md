# Product Requirement Document

**LuxRH — Assistant RH & Paie pour le droit du travail luxembourgeois**

| | |
|---|---|
| Version | 1.0 — 9 septembre 2026 |
| Stack | React (front) + Supabase (base de données, auth, storage, edge functions) |
| Périmètre MVP | Contrats + Planning + Moteur de vigilance légale |
| Périmètre V2 | Paie brut → net, fiches de salaire, simulations d'engagement |

---

## 1. Vision & Objectifs

### Problème

La gestion RH au Luxembourg est un champ de mines réglementaire. Un employeur doit simultanément respecter le Code du travail, la convention collective de son secteur, les paramètres CCSS et fiscaux indexés plusieurs fois par an, et une série de seuils d'effectif qui déclenchent des obligations lourdes (délégation du personnel, entretien préalable, plan social).

Trois douleurs concrètes :

1. **Le contrat.** Rédigé à partir d'un modèle Word périmé, il oublie une mention obligatoire ou contredit la convention collective applicable — et devient contestable devant le tribunal du travail.
2. **Le planning.** En HORECA, en santé ou en gardiennage, un planning viole facilement le repos de 11 h, le repos hebdomadaire de 44 h ou le plafond de 10 h/jour. L'infraction n'est visible qu'après coup, lors d'un contrôle ITM.
3. **Les dates qui coûtent cher.** Le dernier jour utile pour résilier une période d'essai, la fin des 26 semaines de protection maladie, le passage du 15e salarié, le 7e licenciement en 30 jours : ces échéances ne sont écrites nulle part et se ratent en silence.

Les logiciels existants sont soit des outils de paie étrangers mal adaptés au Luxembourg, soit des tableurs maison. Aucun ne dit à l'utilisateur **ce qu'il doit faire, quand, et pourquoi**.

### Solution

LuxRH est une application web qui couvre le cycle de vie du salarié luxembourgeois, avec un **moteur de règles daté** au centre :

- **Contrats** — génération de contrats CDI/CDD conformes, alimentés par le Code du travail et par la convention collective sélectionnée, avec contrôle des minima (salaire, congés, préavis, essai).
- **Planning** — construction d'horaires validés en temps réel contre le droit du travail (durées maximales, repos, dimanches, jours fériés), intégrant congés, maladies et jours fériés.
- **Paie (V2)** — calcul brut → net complet : cotisations CCSS, retenue d'impôt, crédits d'impôt, primes, majorations, préavis presté ou non presté, indemnité de départ. Plus un simulateur de négociation d'engagement (« que coûte cette offre, que touche le candidat »).
- **Vigilance** — un tableau de bord permanent qui affiche les échéances, les seuils franchis ou proches, et les conséquences juridiques associées.

Le principe directeur : **l'application ne se contente pas de calculer, elle avertit et explique.** Chaque alerte cite l'article du Code du travail ou de la CCT qui la motive.

### Public cible

| Persona | Rôle dans l'app | Besoin principal |
|---|---|---|
| **Gestionnaire de paie en fiduciaire** | Utilisateur principal, multi-sociétés | Traiter 20 à 200 dossiers clients sans erreur, changer de société en un clic, produire les décomptes et déclarations |
| **Responsable d'exploitation** (HORECA, santé, sécurité) | Construit les plannings | Couvrir les postes en équipes/nuits/week-ends sans franchir une limite légale, gérer les remplacements |
| **Dirigeant / RH de PME cliente** | Consultation + validation | Comprendre ses obligations, valider les contrats, voir venir les échéances |
| **Salarié** | Self-service, lecture seule | Voir son planning, poser un congé, déclarer une maladie, télécharger sa fiche de salaire |

### Objectifs mesurables

| Objectif | Cible |
|---|---|
| Générer un contrat conforme | < 5 minutes, 0 mention obligatoire manquante |
| Détection d'infraction planning | 100 % des violations de durée/repos signalées **avant** publication |
| Écart de calcul de paie vs. référence CCSS/ACD | 0 centime sur un jeu de 50 cas de test |
| Anticipation des échéances | Toute échéance légale signalée **≥ 30 jours** avant son terme |
| Multi-sociétés | Changement de dossier client en < 2 secondes |

---

## 2. Périmètre par phase

| Phase | Contenu |
|---|---|
| **MVP (V1)** | Sociétés & employés · Référentiel légal daté · CCT paramétrable · Contrats · Planning & pointage · Congés & maladies · Moteur de vigilance · Self-service salarié (lecture) |
| **V2** | Paie brut → net · Fiche de salaire PDF · Primes & majorations valorisées · Fin de contrat (préavis, indemnité) · Simulateur d'engagement · Exports comptables |
| **V3** | Déclaration RTS (XML/XSD MyGuichet) · Déclarations d'entrée/sortie CCSS · Badgeuse physique · Rapports ITM · Compte épargne-temps |

La paie est en V2 volontairement : elle dépend entièrement de la qualité des données de temps, d'absence et de contrat produites en V1. Une paie construite sur un planning approximatif est fausse.

---

## 3. User Stories

> Format : « En tant que X, je veux Y pour Z ». Chaque story = un écran ou une action.
> `[MVP]` = version 1 · `[V2]` = version 2

### A. Socle — comptes, sociétés, employés

**US1. Inscription & espace de travail** `[MVP]`
En tant que gestionnaire, je veux créer mon espace de travail (fiduciaire ou entreprise) pour commencer à saisir mes dossiers.

**US2. Gestion multi-sociétés** `[MVP]`
En tant que gestionnaire de fiduciaire, je veux créer et basculer entre plusieurs sociétés clientes pour traiter mes dossiers sans mélanger les données.

**US3. Fiche société** `[MVP]`
En tant que gestionnaire, je veux renseigner une société (raison sociale, matricule CCSS, RCS, adresse, secteur, CCT applicable, classe de cotisation Mutualité, facteur bonus-malus accident) pour que tous les calculs partent des bons paramètres.

**US4. Fiche employé** `[MVP]`
En tant que gestionnaire, je veux créer un employé (identité, matricule national, adresse, résident/frontalier, qualification, classe d'impôt, fiche de retenue, coordonnées bancaires) pour l'attacher à un contrat.

**US5. Rôles et permissions** `[MVP]`
En tant qu'administrateur, je veux attribuer un rôle (admin fiduciaire, gestionnaire, manager de service, salarié) pour que chacun ne voie que ce qui le concerne.

### B. Référentiel légal & conventions collectives

**US6. Référentiel légal daté** `[MVP]`
En tant qu'administrateur, je veux consulter et mettre à jour les paramètres légaux (SSM, taux CCSS, plafond cotisable, barème fiscal, crédits d'impôt) avec leur date d'entrée en vigueur pour que les calculs restent justes après chaque indexation.

**US7. Calendrier des jours fériés** `[MVP]`
En tant que gestionnaire, je veux que les 11 jours fériés légaux luxembourgeois soient calculés automatiquement pour chaque année, y compris les fêtes mobiles, pour qu'ils apparaissent dans les plannings.

**US8. Moteur de CCT paramétrable** `[MVP]`
En tant qu'administrateur, je veux créer une convention collective en remplissant un formulaire de règles (grille de salaires, durée de travail, congés supplémentaires, majorations, primes, préavis, ancienneté) pour l'appliquer aux sociétés du secteur.

**US9. CCT pré-chargées** `[MVP]`
En tant que gestionnaire, je veux partir d'une CCT déjà remplie (HORECA, secteur d'aides et de soins, gardiennage) pour ne pas tout saisir moi-même.

**US10. Arbitrage loi / CCT / contrat** `[MVP]`
En tant que gestionnaire, je veux que l'application applique toujours la règle la plus favorable au salarié entre la loi, la CCT et le contrat, et m'affiche laquelle a gagné, pour comprendre le résultat.

### C. Contrats d'engagement

**US11. Assistant de création de contrat** `[MVP]`
En tant que gestionnaire, je veux générer un contrat CDI ou CDD par un assistant guidé pour produire un document conforme sans rien oublier.

**US12. Contrôle de conformité du contrat** `[MVP]`
En tant que gestionnaire, je veux être alerté quand une clause viole la loi ou la CCT (salaire sous le minimum, essai trop long, congés inférieurs au minimum) pour corriger avant signature.

**US13. Période d'essai** `[MVP]`
En tant que gestionnaire, je veux saisir une période d'essai et voir immédiatement sa date de fin, le préavis applicable et **le dernier jour utile pour notifier une résiliation**, pour ne pas transformer le contrat en CDI par inadvertance.

**US14. Avenants** `[MVP]`
En tant que gestionnaire, je veux créer un avenant (changement de salaire, d'horaire, de fonction) qui conserve l'historique du contrat pour tracer l'évolution.

**US15. Export et signature** `[MVP]`
En tant que gestionnaire, je veux exporter le contrat en PDF et le stocker dans le dossier du salarié pour l'envoyer à la signature.

**US16. Fin de contrat** `[V2]`
En tant que gestionnaire, je veux enregistrer une fin de contrat (démission, licenciement avec/sans préavis, fin de CDD, rupture d'essai) et obtenir les dates de préavis, le solde de tout compte et l'indemnité de départ calculés.

### D. Planning & temps de travail

**US17. Création d'un planning** `[MVP]`
En tant que responsable, je veux construire un planning hebdomadaire ou mensuel par glisser-déposer de shifts pour organiser mon équipe.

**US18. Validation légale temps réel** `[MVP]`
En tant que responsable, je veux voir immédiatement en rouge toute violation du droit du travail dans mon planning pour la corriger avant publication.

**US19. Modèles de shifts** `[MVP]`
En tant que responsable, je veux enregistrer des shifts types (matin, soir, nuit, garde) et les réutiliser pour aller plus vite.

**US20. Période de référence (PRL)** `[MVP]`
En tant que responsable, je veux déclarer une période de référence allant jusqu'à 4 mois et suivre le compteur d'heures moyen pour lisser l'activité sans générer d'heures supplémentaires.

**US21. Absences dans le planning** `[MVP]`
En tant que responsable, je veux que les congés, maladies, jours fériés et congés extraordinaires apparaissent automatiquement dans le planning pour ne pas planifier quelqu'un d'absent.

**US22. Publication et notification** `[MVP]`
En tant que responsable, je veux publier un planning et notifier les salariés concernés pour qu'ils connaissent leurs horaires.

**US23. Registre du temps de travail** `[MVP]`
En tant que gestionnaire, je veux saisir ou importer les heures réellement prestées et les comparer au prévisionnel pour tenir le registre exigé par l'art. L.211-29 et alimenter la paie.

**US24. Compteurs individuels** `[MVP]`
En tant que salarié ou responsable, je veux voir mes compteurs (heures supplémentaires, solde de congés, dimanches travaillés, jours de repos compensatoire dus) pour suivre ma situation.

### E. Congés, maladies et absences

**US25. Demande de congé** `[MVP]`
En tant que salarié, je veux demander un congé depuis mon espace pour ne pas passer par un e-mail.

**US26. Validation de congé** `[MVP]`
En tant que responsable, je veux valider ou refuser une demande en voyant l'impact sur le planning et le solde pour décider en connaissance de cause.

**US27. Calcul du solde de congés** `[MVP]`
En tant que gestionnaire, je veux que le solde de congés se calcule automatiquement (acquisition mensuelle, prorata temps partiel, jours CCT supplémentaires, report) pour éviter les litiges.

**US28. Congés extraordinaires** `[MVP]`
En tant que salarié, je veux poser un congé extraordinaire (mariage, naissance, décès, déménagement) et que l'application vérifie mon droit pour le nombre de jours correct.

**US29. Déclaration de maladie** `[MVP]`
En tant que gestionnaire, je veux enregistrer une incapacité de travail avec sa date de début, son certificat et sa durée pour déclencher les compteurs et protections associés.

**US30. Compteur de continuation de salaire** `[MVP]`
En tant que gestionnaire, je veux suivre le compteur des jours d'incapacité sur la période de référence de 18 mois pour savoir quand la CNS prend le relais et quand demander le remboursement à la Mutualité.

**US31. Protection contre le licenciement** `[MVP]`
En tant que gestionnaire, je veux voir la date de fin de la protection de 26 semaines liée à une maladie pour ne pas notifier un licenciement nul.

### F. Moteur de vigilance — seuils, échéances, conséquences

**US32. Tableau de bord de conformité** `[MVP]`
En tant que dirigeant ou gestionnaire, je veux un tableau de bord listant mes obligations en cours, à venir et dépassées pour piloter mes risques.

**US33. Seuil de la délégation du personnel** `[MVP]`
En tant que dirigeant, je veux être averti quand mon effectif approche ou franchit 15 salariés (calculé sur les 12 mois de référence) pour organiser les élections sociales à temps.

**US34. Autres seuils d'effectif** `[MVP]`
En tant que dirigeant, je veux connaître les obligations déclenchées par mon effectif (nombre de délégués, délégué à la sécurité, délégué à l'égalité et son crédit d'heures, entretien préalable obligatoire à 150 salariés, délégués libérés) pour anticiper.

**US35. Échéances de préavis d'essai** `[MVP]`
En tant que gestionnaire, je veux voir la liste des essais en cours avec **le dernier jour pour notifier une résiliation**, en tenant compte de la prolongation par maladie, pour agir avant qu'il ne soit trop tard.

**US36. Compteur de licenciement collectif** `[MVP]`
En tant que dirigeant, je veux voir combien de licenciements pour motif non inhérent à la personne j'ai notifiés sur les 30 et 90 derniers jours, **combien je peux encore en notifier avant de basculer en procédure de licenciement collectif, et à quelle date le compteur se libère**, pour piloter une restructuration.

**US37. Simulation de scénario de licenciement** `[MVP]`
En tant que dirigeant, je veux simuler « je licencie N personnes à telle date » et voir si la procédure de licenciement collectif se déclenche, avec la chronologie complète (information ADEM et délégation, 15 jours de négociation, ONC, délai de 75 jours), pour choisir mon calendrier.

**US38. Échéances de contrat** `[MVP]`
En tant que gestionnaire, je veux être alerté avant la fin d'un CDD, avant le 2e renouvellement, avant les 24 mois et sur le délai de carence pour éviter une requalification en CDI.

**US39. Explication de chaque alerte** `[MVP]`
En tant qu'utilisateur, je veux que chaque alerte cite sa base légale (article du Code du travail, de la CCT ou avis CCSS) et explique la conséquence du non-respect pour comprendre et pouvoir vérifier.

### G. Paie `[V2]`

**US40. Préparation de la période de paie** `[V2]`
En tant que gestionnaire, je veux ouvrir un mois de paie et voir les données consolidées (heures prestées, absences, primes, événements de contrat) pour vérifier avant de calculer.

**US41. Calcul brut → net** `[V2]`
En tant que gestionnaire, je veux calculer le net à payer d'un employé (cotisations CCSS, retenue d'impôt selon classe et fiche, crédits d'impôt CIS, CI-CO2, CISSM, CIM, CIHS) pour établir sa rémunération.

**US42. Majorations et heures supplémentaires** `[V2]`
En tant que gestionnaire, je veux que les majorations issues du planning (heures supplémentaires, dimanche, jour férié, nuit selon CCT) soient valorisées avec leur régime fiscal et social propre pour un net exact.

**US43. Primes et avantages** `[V2]`
En tant que gestionnaire, je veux saisir des primes (13e mois, prime de performance, prime participative, chèques-repas, avantage voiture) avec leur traitement fiscal et social pour les intégrer au calcul.

**US44. Préavis presté ou non presté** `[V2]`
En tant que gestionnaire, je veux calculer un préavis presté, dispensé ou indemnisé, ainsi que l'indemnité de départ, avec leur traitement fiscal, pour établir le solde de tout compte.

**US45. Fiche de salaire** `[V2]`
En tant que gestionnaire, je veux générer la fiche de salaire PDF conforme et la mettre à disposition du salarié pour respecter mon obligation de remise du décompte.

**US46. Simulateur d'engagement** `[V2]`
En tant que dirigeant ou recruteur, je veux simuler une offre d'embauche dans les deux sens — « ce candidat veut X net, combien cela me coûte » et « je peux mettre Y en coût total, quel net cela donne » — en variant la classe d'impôt, le statut résident/frontalier, les primes et les avantages, pour négocier avec des chiffres justes.

**US47. Bulletin de contrôle et écarts** `[V2]`
En tant que gestionnaire, je veux comparer la paie du mois avec celle du mois précédent et voir les écarts expliqués pour détecter une erreur avant de payer.

**US48. Journal de paie et export comptable** `[V2]`
En tant que gestionnaire, je veux exporter le journal de paie et les écritures comptables pour les intégrer dans le logiciel comptable.

### H. Espace salarié

**US49. Mon planning** `[MVP]`
En tant que salarié, je veux consulter mon planning publié sur mobile pour connaître mes horaires.

**US50. Mes documents** `[MVP]`
En tant que salarié, je veux accéder à mon contrat, mes avenants et mes fiches de salaire pour les consulter et les télécharger.

**US51. Mes droits RGPD** `[MVP]`
En tant que salarié, je veux exporter mes données personnelles et connaître les traitements qui me concernent pour exercer mes droits.

---

## 4. Critères d'acceptation

> Conditions pour qu'une user story soit considérée comme terminée. Sert de checklist.

### US3 — Fiche société
- [ ] Champs obligatoires : raison sociale, matricule CCSS (13 chiffres, format validé), adresse, forme juridique, secteur NACE
- [ ] Sélection d'une CCT applicable ou « aucune CCT »
- [ ] Classe de cotisation Mutualité (1 à 4) et facteur bonus-malus accident paramétrables
- [ ] L'effectif est calculé automatiquement et affiché avec sa période de référence
- [ ] Une société ne peut pas être supprimée si elle porte des contrats actifs

### US4 — Fiche employé
- [ ] Matricule national luxembourgeois (13 chiffres) validé par sa clé de contrôle
- [ ] Statut résident / frontalier (FR, BE, DE) obligatoire
- [ ] Classe d'impôt (1, 1a, 2) avec taux et abattements issus de la fiche de retenue
- [ ] Qualification (qualifié / non qualifié) car elle détermine le salaire social minimum applicable
- [ ] Les données bancaires et le matricule sont chiffrés au repos

### US6 — Référentiel légal daté
- [ ] Chaque paramètre porte une date de début et une date de fin de validité
- [ ] Un calcul daté du 15 mai 2026 utilise les paramètres en vigueur au 15 mai 2026, pas les actuels
- [ ] L'indice appliqué (ex. 992,24 depuis le 1er juin 2026) est stocké et affiché
- [ ] Un écran d'administration permet d'ajouter une nouvelle version de paramètres sans toucher au code
- [ ] Deux calendriers distincts sont gérés : fiscal (1er janvier) et social (date d'indexation variable)
- [ ] Un changement de paramètre ne modifie jamais rétroactivement une paie déjà clôturée

### US7 — Jours fériés
- [ ] Les 11 jours fériés légaux sont générés pour toute année demandée
- [ ] Les fêtes mobiles (Lundi de Pâques, Ascension, Lundi de Pentecôte) sont calculées à partir de la date de Pâques
- [ ] La Journée de l'Europe du 9 mai est incluse
- [ ] Un jour férié tombant un jour non travaillé génère un jour de compensation
- [ ] Des jours fériés d'usage propres à une CCT peuvent être ajoutés

### US8 — Moteur de CCT
- [ ] Une CCT se définit sans écrire de code, par formulaire
- [ ] Blocs paramétrables : grille de salaires (par catégorie et ancienneté), durée de travail, congés supplémentaires, majorations (nuit, dimanche, férié), primes, préavis, période d'essai, jours fériés d'usage
- [ ] Chaque CCT porte une période de validité et un secteur
- [ ] Une CCT peut être dupliquée pour créer sa version suivante
- [ ] Au moins 3 CCT pré-chargées sont livrées avec l'application

### US10 — Arbitrage loi / CCT / contrat
- [ ] Pour chaque règle applicable, l'application affiche la valeur légale, la valeur CCT, la valeur contractuelle et la valeur retenue
- [ ] La règle retenue est la plus favorable au salarié
- [ ] Un clic sur la valeur retenue affiche la source (article de loi ou clause de CCT)

### US11 — Assistant de création de contrat
- [ ] L'assistant tient en 5 étapes maximum : employé, poste et rémunération, temps de travail, essai et durée, relecture
- [ ] Le type de contrat (CDI, CDD, temps partiel) conditionne les champs affichés
- [ ] Toutes les mentions obligatoires sont présentes dans le document généré
- [ ] Un CDD exige un motif de recours parmi la liste légale
- [ ] Le document généré est disponible en PDF et en version modifiable

### US12 — Contrôle de conformité du contrat
- [ ] Le salaire est comparé au salaire social minimum applicable selon la qualification et le temps de travail
- [ ] Le salaire est comparé à la grille de la CCT si une CCT est applicable
- [ ] Les congés annuels ne peuvent être inférieurs au minimum légal ni à celui de la CCT
- [ ] Un blocage empêche de valider un contrat portant une non-conformité bloquante
- [ ] Un avertissement non bloquant signale les points d'attention (clause de non-concurrence, clause d'exclusivité)

### US13 — Période d'essai
- [ ] La date de fin d'essai est calculée et affichée
- [ ] Le préavis d'essai est calculé selon la règle applicable (essai en semaines ou en mois)
- [ ] **Le dernier jour utile pour notifier une résiliation est affiché en évidence**, avec la mention que le préavis doit expirer au plus tard le dernier jour de l'essai
- [ ] Une incapacité de travail pendant l'essai prolonge l'essai de la durée de l'absence, plafonnée à un mois, et la date recalculée est affichée
- [ ] Une alerte est levée 15 jours et 5 jours avant la date limite de notification

### US16 — Fin de contrat `[V2]`
- [ ] Le motif de fin est choisi dans une liste (démission, licenciement avec préavis, faute grave, fin de CDD, rupture d'essai, commun accord)
- [ ] Le préavis est calculé selon l'ancienneté et le sens de la résiliation
- [ ] Le point de départ du préavis suit la règle du 15 du mois
- [ ] L'indemnité de départ est calculée selon l'ancienneté à l'expiration du préavis, sur la base des 12 derniers mois
- [ ] Si une protection contre le licenciement est active (maladie, maternité, délégué), la notification est **bloquée** avec explication
- [ ] Le solde de tout compte reprend congés non pris, heures supplémentaires, primes au prorata

### US17 / US18 — Planning et validation légale
- [ ] Vue semaine et vue mois, par employé et par service
- [ ] Création d'un shift par glisser-déposer, duplication d'une semaine
- [ ] Contrôles bloquants ou avertissants, évalués à chaque modification :
  - durée journalière > 10 h
  - durée hebdomadaire > 48 h
  - moyenne > 40 h sur la période de référence
  - repos journalier < 11 h consécutives
  - repos hebdomadaire < 44 h consécutives
  - salarié déjà absent (congé, maladie, férié)
  - travail d'un mineur en dehors du cadre autorisé
  - contraintes propres à la CCT
- [ ] Chaque violation affiche la règle violée et sa base légale
- [ ] Un planning contenant une violation bloquante ne peut pas être publié
- [ ] Les heures supplémentaires prévisionnelles et les majorations (dimanche, férié, nuit) sont comptabilisées et affichées

### US20 — Période de référence
- [ ] Une PRL de 1 à 4 mois peut être déclarée pour une société ou un service
- [ ] Le compteur d'heures moyen est affiché en continu avec l'écart à combler
- [ ] En présence d'une PRL, les heures excédentaires se compensent dans la période sans majoration ; hors PRL, chaque heure au-delà des seuils ouvre droit à majoration
- [ ] Une alerte est levée si la moyenne ne pourra plus être atteinte avant la fin de la période

### US23 — Registre du temps de travail
- [ ] Le registre enregistre pour chaque jour : début, fin, durée, pauses, heures au-delà de la durée normale, heures de dimanche, de jour férié et de nuit
- [ ] Le réel peut différer du prévisionnel ; l'écart est visible
- [ ] Le registre est exportable en PDF et en CSV sur une période choisie, présentable à l'ITM
- [ ] Toute modification d'une entrée validée est tracée (auteur, date, ancienne valeur)
- [ ] Les données sont conservées 10 ans

### US27 — Solde de congés
- [ ] Acquisition d'un douzième par mois travaillé, dès la première année
- [ ] Une fraction de mois supérieure à 15 jours compte pour un mois complet
- [ ] Proratisation pour un temps partiel
- [ ] Ajout automatique des jours supplémentaires prévus par la CCT et des jours de repos hebdomadaire non accordés
- [ ] Gestion du report avec les dates limites applicables selon le motif
- [ ] Le détail du calcul est consultable ligne à ligne

### US30 / US31 — Maladie
- [ ] Le compteur des jours d'incapacité sur la période de référence de 18 mois est affiché
- [ ] La date de fin de la continuation de salaire par l'employeur est calculée et signalée 15 jours avant
- [ ] Le montant remboursable par la Mutualité des employeurs est estimé, avec distinction des cas remboursés intégralement
- [ ] La date de fin de la protection de 26 semaines contre le licenciement est affichée sur la fiche employé
- [ ] Une alerte signale l'absence de certificat médical au-delà du délai

### US32 — Tableau de bord de conformité
- [ ] Trois blocs : « En retard », « Dans les 30 jours », « À surveiller »
- [ ] Chaque élément affiche : l'obligation, la date limite, le salarié ou la société concerné, la base légale, la conséquence du non-respect
- [ ] Filtrage par société pour un utilisateur multi-dossiers
- [ ] Un élément peut être marqué comme traité, avec traçabilité

### US33 / US34 — Seuils d'effectif
- [ ] L'effectif est calculé sur les 12 mois précédant le premier jour du mois de référence
- [ ] Une alerte est levée à 13 salariés (approche) et au franchissement des 15 salariés
- [ ] L'obligation de mettre en place une délégation du personnel est expliquée avec sa procédure et son calendrier d'élections
- [ ] Le nombre de délégués effectifs et suppléants dus est affiché selon la tranche d'effectif
- [ ] Le mode de scrutin applicable (majoritaire ou proportionnel selon le seuil de 100) est indiqué
- [ ] Les obligations de délégué à la sécurité et de délégué à l'égalité, avec son crédit d'heures, sont affichées
- [ ] Le seuil de 150 salariés rendant l'entretien préalable obligatoire est signalé
- [ ] Chaque seuil affiché est lu depuis le référentiel, jamais codé en dur

### US36 / US37 — Licenciement collectif
- [ ] Deux compteurs glissants sont affichés : licenciements pour motif non inhérent à la personne sur 30 jours et sur 90 jours
- [ ] **Le nombre de licenciements encore possibles avant déclenchement de la procédure est affiché**, pour chacune des deux fenêtres
- [ ] **La prochaine date à laquelle le compteur se libère est affichée** (date de sortie du plus ancien licenciement de la fenêtre)
- [ ] Un simulateur permet de saisir un nombre de licenciements et une date, et indique si la procédure se déclenche
- [ ] En cas de déclenchement, la chronologie complète est générée : information écrite de la délégation et de l'ADEM, 15 jours de négociation, constat de désaccord, saisine de l'ONC dans les 3 jours, 15 jours de conciliation, interdiction de notifier avant le terme de la procédure
- [ ] L'écran rappelle qu'aucune notification ne peut intervenir avant l'issue de la procédure
- [ ] Un avertissement précise que l'outil est une aide à la décision et ne remplace pas un conseil juridique

### US38 — Échéances de contrat
- [ ] Alerte 60 et 30 jours avant l'échéance d'un CDD
- [ ] Blocage au-delà de 2 renouvellements ou de 24 mois cumulés, avec explication du risque de requalification en CDI
- [ ] Le délai de carence avant un nouveau CDD sur le même poste est calculé et affiché
- [ ] Les cas de recours exclus de ces limites sont paramétrables

### US41 / US42 — Calcul de paie `[V2]`
- [ ] Cotisations salariales calculées : maladie prestations en nature, majoration prestations en espèces, pension, dépendance avec son abattement
- [ ] Cotisations patronales calculées : maladie, pension, prestations familiales, santé au travail, accident selon le facteur bonus-malus, Mutualité selon la classe
- [ ] Le plafond cotisable et le minimum cotisable sont appliqués, avec proratisation en temps partiel
- [ ] L'abattement dépendance est appliqué avant le taux, et réduit proportionnellement sous le seuil d'heures
- [ ] La retenue d'impôt suit le barème mensuel ou journalier selon la périodicité, la classe d'impôt et les mentions de la fiche de retenue
- [ ] Crédits d'impôt appliqués : CIS, CI-CO2, CISSM avec proratisation sur les heures prestées, CIM pour la classe 1a, CIHS
- [ ] Le régime propre des heures supplémentaires est respecté : la majoration est exonérée d'impôt et de cotisations, le principal est exonéré d'impôt et de cotisations hors maladie et dépendance
- [ ] Le détail du calcul est consultable ligne à ligne, avec le paramètre utilisé et sa source
- [ ] Un jeu de 50 cas de test de référence passe au centime près

### US45 — Fiche de salaire `[V2]`
- [ ] Mentions présentes : identité employeur et salarié, matricules, période, brut détaillé par rubrique, cotisations détaillées, base imposable, retenue, crédits d'impôt, net à payer, compteurs de congés et d'heures
- [ ] Génération PDF, stockage sécurisé, mise à disposition du salarié dans son espace
- [ ] Génération en lot pour toute une société
- [ ] Conservation 10 ans
- [ ] Une fiche clôturée est immuable ; une correction passe par une régularisation tracée

### US46 — Simulateur d'engagement `[V2]`
- [ ] Simulation dans les deux sens : du brut vers le net et du net souhaité vers le coût employeur total
- [ ] Variables ajustables : classe d'impôt, résident ou frontalier, qualification, temps de travail, primes, avantages en nature, CCT applicable
- [ ] Le coût employeur total (brut + charges patronales + Mutualité + accident) est affiché
- [ ] Comparaison de plusieurs scénarios côte à côte
- [ ] Export PDF de la simulation pour l'entretien de négociation
- [ ] La simulation ne crée aucun engagement et est identifiée comme estimation

### US51 — Droits RGPD
- [ ] Le salarié peut exporter ses données personnelles dans un format lisible
- [ ] Un registre des traitements est consultable par l'administrateur
- [ ] Les durées de conservation sont documentées par catégorie de données
- [ ] Une donnée dont la durée de conservation est échue est signalée pour purge

---

## 5. Écrans de l'application

| Écran | Description | Phase |
|---|---|---|
| Connexion | Authentification e-mail + mot de passe, 2FA optionnelle | MVP |
| Sélecteur de société | Liste des dossiers, recherche, bascule rapide | MVP |
| Tableau de bord | Vigilance légale, échéances, effectif, alertes | MVP |
| Liste des sociétés | Tableau, recherche, création | MVP |
| Fiche société | Identité, paramètres CCSS, CCT, effectif, obligations | MVP |
| Liste des employés | Tableau filtrable, statut du contrat | MVP |
| Fiche employé | Identité, contrats, planning, absences, compteurs, documents | MVP |
| Référentiel légal | Paramètres datés, historique des versions | MVP |
| Éditeur de CCT | Formulaire de règles par bloc | MVP |
| Assistant contrat | Parcours guidé en 5 étapes | MVP |
| Aperçu du contrat | Document + panneau de conformité | MVP |
| Liste des contrats | Actifs, en essai, échus, avec alertes | MVP |
| Planning | Grille semaine/mois, glisser-déposer, panneau de violations | MVP |
| Modèles de shifts | Bibliothèque de shifts réutilisables | MVP |
| Registre du temps | Saisie du réel, écarts, export ITM | MVP |
| Congés | Calendrier d'équipe, demandes, validations, soldes | MVP |
| Absences & maladies | Saisie, certificats, compteurs, protections | MVP |
| Centre de vigilance | Liste complète des obligations et échéances | MVP |
| Simulateur de licenciement collectif | Saisie du scénario, verdict, chronologie | MVP |
| Espace salarié — planning | Vue mobile de ses horaires | MVP |
| Espace salarié — demandes | Congés, maladies, documents | MVP |
| Paramètres & utilisateurs | Rôles, permissions, journal d'audit | MVP |
| Préparation de paie | Consolidation du mois, contrôles pré-calcul | V2 |
| Calcul de paie | Détail par employé, ligne à ligne | V2 |
| Fiche de salaire | Aperçu, génération, envoi | V2 |
| Journal de paie | Récapitulatif société, exports | V2 |
| Fin de contrat | Motif, préavis, indemnité, solde de tout compte | V2 |
| Simulateur d'engagement | Scénarios de rémunération comparés | V2 |

---

## 6. Moteur de règles — architecture fonctionnelle

Le cœur du produit n'est pas l'interface, c'est le moteur de règles. Trois principes non négociables.

### 6.1 Aucune valeur légale n'est écrite dans le code

Tout paramètre (montant, taux, seuil, durée) vit en base avec une **plage de validité** et une **source citable**. Un calcul reçoit toujours une date et va chercher les paramètres en vigueur à cette date.

Ce n'est pas de la sur-ingénierie : au Luxembourg, l'indexation modifie simultanément le SSM, les minima et maxima cotisables et l'abattement dépendance, à une date imprévisible, tandis que les paramètres fiscaux changent au 1er janvier. Les deux calendriers doivent coexister.

### 6.2 Hiérarchie des normes explicite

Pour chaque règle, le moteur évalue dans l'ordre : **Code du travail → CCT applicable → contrat individuel**, et retient la disposition la plus favorable au salarié. Le résultat conserve la trace de la norme retenue, affichée à l'utilisateur.

### 6.3 Toute décision est explicable

Chaque alerte, chaque blocage, chaque ligne de calcul porte : la règle appliquée, sa source, la valeur utilisée et sa date de validité. Un gestionnaire de fiduciaire doit pouvoir justifier un chiffre devant un client ou un contrôleur.

### 6.4 Familles de règles

| Famille | Contenu |
|---|---|
| **Paramètres sociaux** | SSM par catégorie, plafond et minimum cotisables, abattement dépendance, taux de cotisation salariaux et patronaux, classes Mutualité, facteurs accident, indice applicable |
| **Paramètres fiscaux** | Barème mensuel et journalier de retenue, classes d'impôt, crédits d'impôt et leurs formules par tranche |
| **Temps de travail** | Durées normales et maximales, repos journalier et hebdomadaire, seuil de pause, période de référence, majorations et leur régime fiscal et social |
| **Congés & absences** | Congé annuel minimum et acquisition, congés extraordinaires par motif, jours fériés, règles de report, compteurs maladie et protections |
| **Cycle de vie du contrat** | Période d'essai et son préavis, préavis de licenciement et de démission, point de départ, indemnité de départ, règles CDD |
| **Seuils d'effectif** | Délégation du personnel, nombre de délégués, mode de scrutin, délégués libérés, délégué à l'égalité, entretien préalable, licenciement collectif |
| **CCT** | Grilles de salaires, majorations conventionnelles, congés et primes supplémentaires, règles de temps de travail sectorielles |

### 6.5 Mise à jour du référentiel

Il n'existe **aucune API officielle** publiant les paramètres sociaux, les barèmes fiscaux ou les conventions collectives luxembourgeoises. La mise à jour est donc un **processus manuel supervisé**, à traiter comme une fonctionnalité produit :

- un écran d'administration de saisie de nouvelles versions de paramètres, avec date d'effet ;
- une validation en double lecture avant activation ;
- un journal des modifications ;
- une alerte de veille au 1er janvier (fiscal) et à chaque publication d'indexation (social) ;
- un jeu de tests de non-régression rejoué après chaque mise à jour.

Sources de référence à surveiller : avis annuel aux employeurs du CCSS, page « Paramètres sociaux » du CCSS, fichier « Formules du calcul automatisé de l'impôt » de l'ACD, publications ITM des conventions collectives, Legilux pour le texte faisant foi.

---

## 7. Paramètres de référence au 9 septembre 2026

> Ces valeurs constituent le **jeu de données initial** du référentiel. Elles doivent être vérifiées et re-validées avant toute mise en production, et ne doivent jamais être codées en dur.

### Paramètres sociaux — indice 992,24, en vigueur depuis le 1er juin 2026

| Paramètre | Valeur |
|---|---|
| SSM mensuel non qualifié, 18 ans et + | 2 771,33 € |
| SSM mensuel qualifié, 18 ans et + | 3 325,59 € |
| Maximum cotisable mensuel | 13 856,63 € |
| Abattement dépendance mensuel | 692,83 € |
| Base horaire de référence | 173 h/mois |

### Cotisations CCSS au 1er janvier 2026

| Risque | Salarié | Employeur |
|---|---|---|
| Maladie — prestations en nature | 2,80 % | 2,80 % |
| Maladie — majoration prestations en espèces | 0,25 % | 0,25 % |
| Pension | 8,50 % | 8,50 % |
| Dépendance | 1,40 % | — |
| Prestations familiales | — | 1,70 % |
| Santé au travail | — | 0,14 % |
| Accident (taux de base, facteur 1,00) | — | 0,65 % |
| Mutualité des employeurs | — | 0,23 % à 2,66 % selon la classe 1 à 4 |

Total part salariale : **12,95 %**.

> Le taux de pension est passé de 8,00 % à 8,50 % de chaque côté en 2026 — illustration parfaite de pourquoi aucun taux ne doit être en dur.

### Temps de travail

| Paramètre | Valeur |
|---|---|
| Durée normale | 8 h/jour, 40 h/semaine |
| Maximum légal | 10 h/jour, 48 h/semaine |
| Période de référence maximale | 4 mois |
| Repos journalier minimum | 11 h consécutives par 24 h |
| Repos hebdomadaire minimum | 44 h consécutives |
| Pause | obligatoire au-delà de 6 h de travail journalier (durée renvoyée à la CCT ou au contrat) |
| Heure supplémentaire — compensation en repos | 1 h 30 par heure |
| Heure supplémentaire — compensation en argent | 140 % |
| Travail du dimanche | + 70 % |
| Jour férié travaillé | 300 % au total |
| Travail de nuit | pas de majoration légale générale ; minimum 15 % si une CCT en prévoit une |

### Congés et absences

| Paramètre | Valeur |
|---|---|
| Congé annuel légal minimum | 26 jours ouvrables |
| Acquisition | 1/12e par mois (≈ 2,167 j) |
| Jours fériés légaux | 11 |
| Mariage / décès du conjoint / parent 1er degré | 3 jours |
| Naissance ou adoption | 10 jours |
| Décès d'un enfant mineur | 5 jours |
| Déménagement | 2 jours (1 fois par 3 ans) |
| Continuation de salaire par l'employeur | jusqu'à la fin du mois du 77e jour d'incapacité, sur 18 mois de référence |
| Remboursement Mutualité | 80 % de la charge salariale globale (100 % pour les 3 premiers mois d'essai, congé pour raisons familiales, congé d'accompagnement) |
| Protection contre le licenciement pendant la maladie | 26 semaines |

### Cycle de vie du contrat

| Paramètre | Valeur |
|---|---|
| Préavis d'essai — essai en semaines | autant de jours que de semaines d'essai |
| Préavis d'essai — essai en mois | 4 jours par mois, minimum 15 jours, maximum 1 mois |
| Prolongation d'essai par maladie | durée de l'absence, plafonnée à 1 mois |
| Préavis de licenciement | 2 mois (< 5 ans), 4 mois (5 à 10 ans), 6 mois (≥ 10 ans) |
| Préavis de démission | moitié du préavis de licenciement |
| Point de départ | 15 du mois si notifié avant le 15, 1er du mois suivant sinon |
| Indemnité de départ | 1 mois (5-10 ans), 2 (10-15), 3 (15-20), 6 (20-25), 9 (25-30), 12 (≥ 30) |
| CDD | 24 mois maximum, 2 renouvellements, carence d'1/3 de la durée précédente |

### Seuils d'effectif

| Seuil | Conséquence |
|---|---|
| **15 salariés** | Délégation du personnel obligatoire, effectif apprécié sur les 12 mois précédents, élections tous les 5 ans |
| **100 salariés** | Passage du scrutin majoritaire à la représentation proportionnelle |
| **150 salariés** | Entretien préalable au licenciement obligatoire |
| **250 salariés** | Premier délégué libéré à temps plein |
| **7 licenciements sur 30 jours** ou **15 sur 90 jours** | Procédure de licenciement collectif et négociation d'un plan social |

### Conservation

| Donnée | Durée |
|---|---|
| Fiches de salaire, décomptes, pièces comptables | 10 ans à partir de la clôture de l'exercice |
| Registre du temps de travail | 10 ans |
| Dossier du salarié | jusqu'à l'expiration des délais de contestation, et pendant toute procédure en cours |

---

## 8. Contraintes

| Contrainte | Exigence |
|---|---|
| **Exactitude** | Un calcul faux est pire qu'un calcul absent. Tout écart avec les références officielles est un défaut bloquant. |
| **Traçabilité** | Toute donnée calculée est reconstituable : paramètre utilisé, version, date, règle appliquée, auteur de la saisie. |
| **Immutabilité** | Une période de paie clôturée, un contrat signé, un planning publié ne se modifient pas ; ils se corrigent par un acte nouveau et tracé. |
| **Datation** | Aucun calcul ne s'exécute sans date de référence. Les paramètres sont toujours lus à cette date. |
| **Multi-sociétés** | Isolation stricte des données entre sociétés clientes, imposée au niveau de la base (RLS) et non de l'interface. |
| **Rôles** | Quatre rôles : admin fiduciaire, gestionnaire, manager de service, salarié. Un salarié ne voit que ses propres données. |
| **RGPD** | Minimisation, durées de conservation documentées, registre des traitements, droit d'accès et d'export, chiffrement des données sensibles au repos. |
| **Surveillance des salariés** | Tout module de suivi du temps ou de géolocalisation embarque le workflow d'information de l'art. L.261-1 : information collective de la délégation avec finalité, modalités, durée de conservation et engagement de non-détournement ; information individuelle ; fenêtre de saisine de la CNPD de 15 jours. |
| **Hébergement** | Données hébergées dans l'Union européenne. |
| **Langue** | Interface en français en V1 ; architecture i18n prête pour l'allemand, l'anglais et le luxembourgeois. |
| **Responsive** | Interface de gestion optimisée desktop ; espace salarié et consultation de planning optimisés mobile. |
| **Performance** | Un planning mensuel de 50 salariés se charge en moins de 2 secondes ; la validation légale d'un shift est instantanée. |
| **Accessibilité** | Contraste suffisant, cibles tactiles de 44 × 44 px minimum, navigation au clavier. |
| **Feedback** | Chaque action montre son état : chargement, succès, erreur explicite. Aucune erreur silencieuse. |
| **Audit** | Journal d'audit inaltérable sur les données de contrat, de temps et de paie. |
| **Avertissement juridique** | L'application est un outil d'aide à la décision. Chaque écran à conséquence juridique (licenciement collectif, fin de contrat, conformité) porte une mention rappelant qu'elle ne se substitue pas à un conseil juridique. |

---

## 9. Architecture technique

### Stack

| Couche | Choix |
|---|---|
| Front | React + TypeScript, Vite |
| État serveur | TanStack Query |
| Formulaires | React Hook Form + Zod (schémas partagés front/back) |
| UI | Tailwind + composants accessibles |
| Base de données | Supabase / PostgreSQL |
| Authentification | Supabase Auth, rôles portés par des claims JWT |
| Autorisation | Row Level Security PostgreSQL, par société et par rôle |
| Logique métier sensible | Fonctions PostgreSQL et Edge Functions Supabase — jamais dans le navigateur |
| Documents | Supabase Storage, buckets privés, URLs signées à durée courte |
| Génération PDF | Edge Function dédiée (contrats, fiches de salaire, registres) |

### Principe d'implantation de la logique

Les calculs de paie, les validations légales et les contrôles de seuils **ne s'exécutent jamais côté client**. Le front affiche et saisit ; le serveur calcule, valide et décide. Cela garantit qu'un calcul ne peut être contourné, et qu'une même version de règle produit le même résultat quel que soit le navigateur.

### Modèle de données — entités principales

```
organizations            fiduciaire ou entreprise propriétaire de l'espace
users                    utilisateurs, rattachés à une organisation
user_roles               rôle par utilisateur et par société

companies                sociétés (clientes ou propres)
company_settings         matricule CCSS, classe Mutualité, facteur accident, CCT

employees                salariés (identité, matricule, résidence, qualification)
employee_tax_cards       classe d'impôt, taux, abattements, période de validité

contracts                contrats (type, dates, poste, salaire, temps de travail)
contract_amendments      avenants, historisés
probation_periods        essai, date de fin, prolongations, date limite de notification
contract_terminations    fins de contrat, préavis, indemnités

legal_parameters         paramètres légaux datés (clé, valeur, valid_from, valid_to, source)
tax_scales               barèmes de retenue datés
public_holidays          jours fériés générés par année
collective_agreements    CCT (secteur, validité)
cba_rules                règles de CCT par bloc, en JSONB validé par schéma
cba_salary_grids         grilles de salaires par catégorie et ancienneté

shift_templates          modèles de shifts
schedules                plannings (période, statut, service)
shifts                   shifts planifiés
time_entries             temps réellement presté (registre L.211-29)
reference_periods        périodes de référence et compteurs

absence_types            types d'absence (congé, maladie, extraordinaire, férié)
absences                 absences (dates, statut, justificatif)
leave_balances           soldes de congés calculés
sick_leave_counters      compteurs 77 jours / 18 mois et protection 26 semaines

compliance_rules         règles de vigilance (seuils, échéances)
compliance_alerts        alertes générées, statut, base légale
headcount_snapshots      effectif mensuel pour le calcul des seuils
collective_dismissals    licenciements pour motif non inhérent, pour les compteurs 30/90 jours

payroll_periods          périodes de paie (V2)
payroll_runs             exécutions de calcul (V2)
payslips                 fiches de salaire (V2)
payslip_lines            lignes de calcul détaillées et explicables (V2)
salary_simulations       simulations d'engagement (V2)

audit_log                journal d'audit inaltérable
documents                documents stockés, liés à une entité
```

### Points d'attention techniques

- **Row Level Security sur toutes les tables** portant des données de société ou de salarié. L'isolation multi-sociétés est une exigence de conformité, pas de confort.
- **Colonnes temporelles systématiques** (`valid_from`, `valid_to`) sur tout ce qui est réglementaire, avec contrainte d'exclusion pour empêcher les chevauchements.
- **Chiffrement au repos** du matricule national, des coordonnées bancaires et des certificats médicaux.
- **Recalcul idempotent** : rejouer un calcul de paie sur une période donnée produit exactement le même résultat, tant que les paramètres n'ont pas changé.
- **Jeu de tests de référence** : 50 cas de paie couvrant résidents et frontaliers, temps plein et partiel, classes 1/1a/2, heures supplémentaires, dimanche, férié, maladie, entrée et sortie en cours de mois, préavis indemnisé.
- **Génération des jours fériés** par algorithme (calcul de Pâques) et non par table saisie à la main.

---

## 10. Ce qu'on ne fait PAS

### Hors périmètre MVP (V1)

- Pas de calcul de paie ni de fiche de salaire — c'est la V2
- Pas de télédéclaration RTS ni de déclaration d'entrée/sortie CCSS automatisée — c'est la V3
- Pas de badgeuse physique ni de pointage biométrique
- Pas de recrutement, d'entretiens annuels ni de gestion de formation
- Pas de notes de frais
- Pas d'application mobile native (le web responsive suffit pour l'espace salarié)
- Pas de signature électronique qualifiée intégrée (export PDF vers un outil tiers)
- Pas de gestion des travailleurs détachés ni de la mobilité internationale
- Pas de calcul de pension ou de préretraite
- Pas d'import automatisé des conventions collectives — aucune source machine n'existe
- Pas de multilingue en V1 (français seulement)
- Pas de mode sombre

### Hors périmètre produit, définitivement

- **Pas de conseil juridique automatisé.** L'application signale, calcule et cite ses sources. Elle ne rend pas d'avis et ne se substitue à aucun professionnel du droit.
- **Pas de décision automatisée à effet juridique** sur une personne, au sens de l'art. 22 RGPD. Un licenciement, un refus de congé, une sanction restent des décisions humaines ; l'application les prépare et les documente.

---

## 11. Questions ouvertes

Points à trancher ou à vérifier avant le développement.

### À vérifier juridiquement avant implémentation

1. **Bornes de la période d'essai** — durées minimale et maximale selon la qualification et le niveau de rémunération (art. L.121-5 du Code du travail). À confirmer sur Legilux.
2. **Tranches complètes du nombre de délégués** — les tranches 401-500, 601-1000 et 1101-5500 sont à compléter depuis l'art. L.412-1.
3. **Représentation des salariés au conseil d'administration** — seuil applicable, à confirmer (art. L.426-1 et suivants).
4. **Délai de la déclaration de sortie CCSS** — non confirmé par les sources consultées.
5. **Barèmes 2026 des crédits d'impôt CIM et CISSM** — l'administration n'a pas publié de page millésimée 2026 ; les barèmes « à partir de 2025 » sont réputés applicables, à re-vérifier.
6. **Règles de nuit sectorielles** — à préciser CCT par CCT, aucune règle légale générale.

### À décider avec vous

1. **Quelles trois CCT pré-charger ?** Ma proposition, cohérente avec les secteurs à horaires complexes que vous visez : **HORECA**, **secteur d'aides et de soins (SAS)**, **gardiennage/sécurité**. À confirmer ou remplacer.
2. **La fiduciaire facture-t-elle ses clients depuis l'outil ?** Le cas échéant, un module de facturation et de suivi du temps passé par dossier serait à ajouter à la roadmap.
3. **Le salarié peut-il déclarer sa maladie lui-même** et déposer son certificat, ou cela reste-t-il une saisie gestionnaire ?
4. **Faut-il gérer l'intérim** (contrats de mission, entreprises utilisatrices) ? Le régime est distinct et alourdirait significativement le modèle.
5. **Frontaliers** : quelle proportion de l'effectif visé ? Cela conditionne la priorité des règles fiscales propres aux non-résidents.
6. **Volume cible** : combien de sociétés et de salariés par espace de travail au démarrage, et à 12 mois ? Cela oriente les choix d'index et de pagination.
7. **Import de l'existant** : les fiduciaires devront-elles reprendre un historique (contrats, congés, cumuls de paie) depuis un autre logiciel ? Un module d'import est un chantier à part entière.
8. **Y a-t-il un logiciel de comptabilité cible** vers lequel exporter les écritures (BOB, Sage, Odoo, autre) ?

---

*Ce PRD décrit le QUOI. Les chiffres du chapitre 7 sont un point de départ daté au 9 septembre 2026 et doivent être re-validés sur les sources officielles avant mise en production.*
