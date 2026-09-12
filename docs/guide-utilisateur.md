# Guide utilisateur

Ce document suit un parcours réel, de la connexion à la portabilité, écran par écran. Il s'adresse
aux utilisateurs, aux formateurs et à toute personne qui doit tester l'application sans en connaître
le code.

Les deux interfaces couvrent le même moteur mais pas exactement le même périmètre d'écrans : le
front React compte **22 écrans**, l'application Streamlit **16 vues**. Les différences sont
signalées au fil du texte.

---

## Deux repères qui valent partout

**Le dossier actif.** En haut à droite côté React, dans la barre latérale côté Streamlit. Tout ce
qui s'affiche concerne cette société. Le choix est mémorisé d'un écran à l'autre.

**La date de référence.** Tout calcul lit les paramètres **en vigueur à cette date**, jamais les
actuels. La changer permet de reconstituer une situation passée — un solde de congés au 31 décembre,
une conformité de contrat au jour de sa signature. Côté React elle est portée par le contexte
applicatif et modifiable depuis les écrans datés ; côté Streamlit elle est un champ permanent de la
barre latérale.

Et un principe : **rien n'est calculé dans l'interface.** Chaque valeur, chaque message, chaque
référence d'article affichés viennent du serveur. Si une valeur manque, l'écran le dit au lieu de
la remplacer par une valeur plausible.

---

## 1. Connexion

L'écran d'accueil propose deux onglets.

**Connexion** — adresse et mot de passe.

**Créer un espace** — nom complet, nom de l'espace de travail, type (*Fiduciaire* ou *Entreprise*),
adresse et mot de passe. L'espace est créé avec le compte comme administrateur.

Selon le réglage du projet Supabase, l'inscription ouvre la session immédiatement ou envoie un
courriel de confirmation. Trois choses à savoir dans ce second cas :

- le lien n'est valable **qu'une fois** ;
- il doit être ouvert **depuis le navigateur qui a servi à l'inscription** ;
- si l'adresse est **déjà enregistrée**, aucun courriel n'est envoyé. Supabase répond malgré tout
  « succès », délibérément, pour ne pas révéler quels comptes existent. Les deux applications
  détectent ce cas et l'annoncent : annoncer une création qui n'a pas eu lieu serait une erreur
  silencieuse.

Un salarié qui n'a que le rôle *salarié* est redirigé d'office vers son espace mobile (§ 11).

---

## 2. Choix de la société

Écran **Vos dossiers** (React, `/dossiers`). La liste des sociétés de l'espace, avec pour chacune
ses conventions collectives applicables.

Sur un espace vide, le bouton **« Charger le jeu de démonstration »** crée une fiduciaire complète :
dossiers clients, salariés, contrats, plannings, absences. C'est le point de départ le plus rapide
pour découvrir l'outil.

---

## 3. Tableau de bord

Quatre indicateurs en haut : **en retard**, **dans les N jours** (N est lu dans le référentiel, pas
écrit en dur), **effectif sur la période de référence**, **plannings à publier**.

En dessous : les échéances en retard, celles à surveiller, le compteur de licenciement collectif,
les absences en cours, et l'état du référentiel.

Tout provient d'un appel unique à `fn_compliance_scan` : ce que le tableau de bord montre est
exactement ce que le centre de vigilance détaille.

---

## 4. Employés

**Liste** — recherche, service, contrat en cours. L'en-tête annonce l'effectif. Les alertes du scan
de conformité sont rapprochées de chaque salarié.

**Fiche salarié** — une page par sections :

| Section | Ce qu'elle montre |
|---|---|
| Identité | Nom, naissance, résidence, qualification. Le **matricule national et l'IBAN sont chiffrés en base** : leur affichage passe par une fonction serveur qui contrôle les droits de l'appelant |
| Solde de congés | Le solde, puis son **détail ligne à ligne** — le calcul est reconstituable, pas un simple total |
| Incapacité | Compteurs sur la fenêtre glissante, protection en cours, certificats attendus |
| Statuts déclarés | Grossesse, allaitement, mandat de délégué, prime de réemploi, gérance — chacun avec sa période |
| Qualification | Déclarée, **ou acquise par l'ancienneté de carrière**. La source est affichée |
| Heures supplémentaires | Éligibilité : un mineur, une salariée enceinte, un bénéficiaire de la prime de réemploi n'y ont pas droit |
| Éligibilité à la délégation | Ancienneté, âge, exclusion du personnel de direction |
| Handicap | Taux reconnu et jours de congé supplémentaires ouverts |
| Enfants | Nombre et droits associés. Voir ci-dessous |

**Le refus des attentions**, sur la fiche enfant, n'est pas un simple masquage : la base **efface**
le prénom, le nom et le sexe. Seule la date de naissance subsiste, parce qu'elle seule est
nécessaire pour établir les droits à congé. C'est de la minimisation effective, pas déclarative.

---

## 5. Contrats

**Liste des contrats** — par société, avec type, statut et dates.

**Assistant de création** — cinq étapes : *Employé*, *Poste & rémunération*, *Temps de travail*,
*Essai & durée*, *Relecture*. Le brouillon est enregistré à chaque passage à l'étape suivante.

À la relecture, le moteur rend son verdict : contrôles avec leur gravité, **mentions obligatoires**
avec leur état, et les arbitrages retenus. **Tant qu'un contrôle bloquant subsiste, le contrat ne
peut pas être validé.**

**Aperçu du contrat** — la version lisible, avec deux blocs caractéristiques :

- **Arbitrage loi / CCT / contrat** : les trois valeurs côte à côte, celle qui a été retenue, et la
  norme qui a gagné ;
- **Dates calculées** : fin d'essai, prolongation éventuelle par incapacité, **dernier jour utile
  pour notifier** une rupture d'essai, échéance du CDD.

Le contrat se génère en PDF côté serveur (Edge Function `contract-pdf`), avec le jeton de
l'utilisateur : les droits d'accès s'appliquent à la génération comme à la lecture. Le document est
déposé dans le dossier du salarié.

**L'avenant** — le moteur sait établir un avenant (`fn_amend_contract`, migration 55) : il clôt le
contrat en cours la veille de la prise d'effet, crée le suivant en reprenant toutes ses clauses, sa
rémunération et ses conventions applicables, et journalise le motif. **Aucun écran ne l'expose
encore, ni en React ni en Streamlit** — voir [personnel-et-horaires.md](personnel-et-horaires.md),
lot 2.2. Une modification qui doit se documenter comme un avenant se saisit aujourd'hui par un appel
direct à la fonction, en dehors des deux applications.

---

## 6. Planning

**Grille hebdomadaire** — navigation semaine par semaine, services par salarié.

À **chaque modification**, le moteur revalide. Le panneau de contrôle affiche les violations —
chacune avec son titre, son détail, le salarié et le jour concernés, et **son article** — plus les
compteurs de la semaine par salarié : heures, heures supplémentaires, dimanches, plus long repos.

**Une violation bloquante empêche la publication.** Ce n'est pas un avertissement à confirmer : le
serveur refuse, en disant laquelle.

Deux comportements qui surprennent parfois, et qui sont voulus :

- le repos de 11 heures s'apprécie **entre deux journées de travail, pas entre deux vacations** :
  un service coupé 11:00–15:00 puis 17:00–23:00 ne déclenche rien ;
- la pause obligatoire s'apprécie, elle, **service par service**.

**Modèles de creneaux** — vacations réutilisables : nom, début, fin, pause, service, couleur.

**Registre du temps de travail** — le temps réellement travaillé, par période, saisi jour par jour.
C'est ce registre, et non le planning prévisionnel, qui alimente la moyenne de la période de
référence.

**Heures supplémentaires** (Streamlit) — une demande formelle passe par trois états :
`requested` → `hr_approved` → `approved`. **La validation RH seule ne suffit pas** : le salarié doit
accepter. L'accord doit être **préalable**.

---

## 7. Congés

**Calendrier et demandes** — les absences du mois, à valider ou refuser.

Avant l'envoi d'une demande, le moteur en calcule **l'impact** : jours décomptés, solde après
opération, et le droit applicable **à la date de la demande** — pas le droit d'aujourd'hui. Le
congé de mariage vaut 6 jours avant 2018 et 3 jours après ; l'outil applique celui qui correspond.

**Soldes de l'équipe** — le solde de chaque salarié à la date de référence.

---

## 8. Maladies

**Absences et maladies** — déclaration d'une incapacité : salarié, dates, jours décomptés, dépôt du
certificat.

**Compteurs par salarié** — jours dans la fenêtre glissante, limite, date de fin de protection
contre le licenciement, certificats attendus et leur délai.

Côté salarié, l'espace mobile permet de **déclarer soi-même son incapacité** et de déposer son
justificatif ; l'original reste dû par voie postale.

---

## 9. Vigilance

**Centre de vigilance** — l'écran le plus dense, et le plus utile.

Toutes les échéances de la société, rangées en trois paniers : **en retard**, **dans les 30 jours**,
**à surveiller**. Un filtre par domaine : contrats, temps de travail, absences, effectif, documents,
protections.

Chaque ligne porte quatre choses : ce qui se passe, **quand**, **ce qui arrive si rien n'est fait**,
et **l'article qui le prévoit**. La date d'évaluation est modifiable directement depuis l'écran.

Deux blocs complètent la page : **seuils d'effectif** (15, 100, 150, 250 — délégation du personnel,
mode de scrutin) et **licenciement collectif** (compteurs glissants sur 30 et 90 jours).

**Simulateur de licenciement collectif** — on saisit un nombre de licenciements, une date de
notification envisagée et un motif. Le moteur répond : le seuil est-il déclenché, quelles sont les
alternatives, et la **chronologie complète de la procédure** — saisine de l'Office national de
conciliation, délais de négociation, dates butoirs. Un encadré « Ce que dit la loi » accompagne le
verdict.

---

## 10. Sociétés

**Liste des sociétés** — et création : raison sociale, forme juridique, RCS, matricule CCSS,
adresse, secteur NACE, convention collective, et les taux applicables à compter d'une date.

**Fiche société** :

| Bloc | Contenu |
|---|---|
| Paramètres CCSS | Classe d'activité, classe Mutualité, facteur accident **à la date de référence** |
| Historique des taux | Toutes les périodes. Ces valeurs évoluent ; les figer sur la société rendrait tout recalcul daté faux |
| Conventions applicables | Toutes les CCT rattachées, avec leur portée et leur période |
| Services | Les départements |
| Effectif et obligations | Effectif présent, moyenne sur la période de référence, seuils franchis |

Une remarque utile : c'est la **moyenne** sur douze mois qui compte juridiquement, pas l'effectif du
jour. Une société peut compter 14 salariés aujourd'hui pour une moyenne de 13,17 — et c'est 13 qui
détermine l'obligation.

**La saisie d'une adresse** — sur la fiche société, la fiche salarié et un lieu d'intervention —
est vérifiée en base à l'écriture (migration 56), pas seulement affichée telle quelle :

- une adresse dont le code postal tombe **hors des zones couvertes** est **refusée**, avec le
  message qui nomme la zone attendue. LuxRH couvre le Luxembourg entier, et côté frontalier les
  provinces de Liège, Namur et Luxembourg en Belgique, les départements 54 et 57 en France ;
- une adresse dont le pays n'est **pas couvert du tout**, ou dont la correspondance postale n'est
  **pas chargée** — c'est le cas aujourd'hui de l'Allemagne, faute de découpage postal fiable par
  Land — est **acceptée mais signalée** : le statut « indéterminé » reste visible, il n'est ni
  confirmé ni écarté. Ce n'est pas un défaut de saisie, c'est un manque de référentiel assumé plutôt
  que masqué par une zone approximative.

---

## 11. Espace salarié

Interface distincte, pensée pour le téléphone (cibles tactiles de 56 px). Quatre onglets :

| Onglet | Contenu |
|---|---|
| **Planning** | Ses services de la semaine — **uniquement si le planning est publié**. Un planning en brouillon est invisible, et pas seulement masqué : la base refuse de le renvoyer |
| **Congés** | Ses droits, et le formulaire de demande : type, dates, commentaire |
| **Documents** | Ses documents |
| **Profil** | Ses informations |

Un salarié ne voit que ses propres lignes, ne peut pas valider sa propre demande d'absence, et ne
peut consulter ni le solde d'un collègue ni le centre de vigilance de la société. Ces restrictions
sont imposées en base, pas par l'interface, et chacune est vérifiée par `tests/rls.test.mjs`.

---

## 12. Référentiel

**Paramètres légaux datés** — la liste par famille, avec pour chaque clé son historique de versions :
valeur, plage de validité, source, article, indice appliqué.

**Couverture du référentiel** — la partie la plus importante de l'écran, et volontairement mise en
avant :

- quels paramètres **n'ont pas d'historique** remontant au 31.12.2019 ;
- quels paramètres ont un **trou** dans leur historique — une version close le 1er mars, la suivante
  ouverte le 1er juin, et rien entre les deux ;
- quelles valeurs publiées **s'écartent de leur dérivation** au-delà de la tolérance, ce qui trahit
  une indexation saisie à moitié.

**Nouvelle version datée** — clé, date d'effet, nouvelle valeur, source, note. La version en cours
est automatiquement clôturée à la date d'effet. La saisie est réservée à l'administrateur de
l'espace, et la **double lecture** doit être faite par une autre personne que celle qui a saisi.

**Conventions collectives** (React) — édition bloc par bloc : congé annuel, durée hebdomadaire,
période de référence, pause, plage de nuit, et le JSON du bloc pour les clauses non structurées.
Un bloc affiche l'arbitrage face à la loi.

> À savoir : une clause écrite dans le JSON libre mais que le moteur ne sait pas lire est **stockée
> sans être appliquée**. Le drapeau « bloc complet » est déclaratif.

**Jours fériés** (React) — les 11 jours fériés légaux, les fêtes mobiles calculées, les collisions
(deux fériés le même jour) et les récupérations qui en découlent.

---

## 13. Paramètres

**Utilisateurs et rôles** — quatre rôles : administrateur de l'espace, gestionnaire, manager de
service, salarié, chacun avec sa portée (une société ou toutes).

**RGPD** — durées de conservation lues dans le référentiel, chiffrement au repos, droit d'accès et
d'export. Données hébergées dans l'Union européenne. Aucune décision automatisée à effet juridique
n'est prise sur une personne : l'application prépare et documente, la décision reste humaine.

**Journal d'audit** — contrats, temps de travail et absences, en insertion seule. Horodatage,
auteur, table, action, entité.

---

## 14. Portabilité

Carte **Portabilité et reprise**, dans les Paramètres côté React, écran dédié côté Streamlit.

Quatre exports, tous produits **par le serveur**, qui vérifie qui a le droit de les demander et
journalise la demande :

| Export | Contenu |
|---|---|
| **Mes données** | Le dossier personnel du salarié. Matricule national et IBAN y figurent **en clair** — un export illisible ne satisferait pas le droit d'accès |
| **Une société** | Le dossier complet : salariés, contrats, services, temps, absences |
| **La fiduciaire** | L'ensemble de l'espace. Réservé à l'administrateur |
| **Le référentiel** | Paramètres datés, barèmes, catalogues et CCT, en **clés naturelles** — sans identifiant technique, pour qu'un rechargement ne duplique pas |

Le fichier est au format `luxrh.export/1`, daté dans son nom. Les documents déposés dans le stockage
ne sont pas inclus en binaire : l'export en porte le descriptif et le chemin.

**Import du référentiel** — deux modes : *ignorer l'existant* ou *remplacer*. Le rapport indique
combien de lignes ont été ajoutées, remplacées, ignorées, et **lesquelles ont été rejetées**. Un
fichier d'un autre outil, ou un export de société pris pour un référentiel, est refusé — et le motif
est nommé.

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [presentation.md](presentation.md) — ce que l'application fait, et ne fait pas
- [demarrage.md](demarrage.md) — lancer l'application et charger le jeu de démonstration
- [moteur-de-regles.md](moteur-de-regles.md) — d'où viennent les verdicts affichés
- [couverture-droit-du-travail.md](couverture-droit-du-travail.md) — ce qui n'est pas encore couvert
