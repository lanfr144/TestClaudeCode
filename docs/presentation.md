# Présentation de LuxRH

Ce document s'adresse à toute personne qui découvre le projet : nouveau développeur, utilisateur
métier, relecteur. Il explique le problème traité, ce que l'outil sait faire, et — tout aussi
important — ce qu'il ne sait pas faire.

---

## Le problème

Au Luxembourg, la gestion du personnel se heurte à trois difficultés qui ne se résolvent pas avec
un tableur.

**Les valeurs légales bougent, et pas au même rythme.** Le salaire social minimum suit l'indice,
qui se déclenche sur l'inflation. Les taux de cotisation CCSS changent en cours d'année. Le barème
d'impôt est publié par l'Administration des contributions directes. Un calcul de mai 2026 doit
utiliser les valeurs de mai 2026, même s'il est refait en septembre.

**Trois niveaux de normes se superposent.** La loi fixe un plancher, la convention collective peut
faire mieux, le contrat individuel encore mieux. C'est la disposition la plus favorable au salarié
qui s'applique — et il faut pouvoir dire laquelle a gagné, et pourquoi.

**Les échéances sont nombreuses et silencieuses.** Fin de période d'essai, dernier jour utile pour
notifier une rupture, échéance d'un CDD, délai de dépôt d'un certificat médical, franchissement
d'un seuil d'effectif qui déclenche une obligation de délégation du personnel. Aucune de ces dates
ne se rappelle d'elle-même, et chacune se paie cher si elle est manquée.

LuxRH répond aux trois : un référentiel daté, un arbitrage explicite des normes, et un centre de
vigilance permanent.

> L'application ne se contente pas de calculer : elle avertit et explique. Chaque alerte cite
> l'article qui la motive.

---

## À qui elle s'adresse

| Profil | Usage |
|---|---|
| **Fiduciaire** gérant plusieurs dossiers clients | Bascule d'une société à l'autre, vigilance par dossier, référentiel commun |
| **Service RH** d'une entreprise unique | Le même outil, un seul dossier |
| **Salarié** | Un espace mobile cloisonné : son planning publié, ses soldes, ses demandes, ses documents |

Les rôles sont au nombre de quatre : administrateur de l'espace, gestionnaire, manager de service,
salarié. Ce qu'un rôle peut voir n'est pas décidé par l'interface mais par des politiques de
sécurité en base — voir [architecture.md](architecture.md).

---

## Les grandes capacités

### Référentiel légal daté

Chaque seuil, taux et durée vit en base avec sa plage de validité, sa source et son article. Une
contrainte d'exclusion interdit à un paramètre d'avoir deux valeurs le même jour. Le référentiel
expose lui-même sa couverture : ce qui manque est nommé, jamais comblé par une valeur plausible.
Voir [moteur-de-regles.md](moteur-de-regles.md).

### Sociétés, salariés, contrats

Fiche société avec historique daté des taux CCSS (classe d'activité, classe Mutualité, facteur
accident). Fiche salarié avec statuts protégés, handicap, enfants, qualification. Assistant de
création de contrat qui contrôle les mentions obligatoires et refuse de valider tant qu'un blocage
subsiste. Génération du contrat en PDF côté serveur.

Cinq types de contrat sont modélisés : CDI, CDD, saisonnier, apprentissage, intérim, avec pour le
CDD ses motifs, sa durée maximale, ses renouvellements et sa carence.

### Planning et registre du temps

Grille hebdomadaire validée **à chaque modification** contre les durées maximales, le repos
journalier de 11 heures, le repos hebdomadaire, les pauses, le travail du dimanche et des jours
fériés, et les absences en cours. Une violation bloquante **empêche la publication** : ce n'est pas
un avertissement que l'on peut ignorer.

### Congés et maladies

Solde de congés reconstituable ligne à ligne, catalogue daté des congés extraordinaires, impact
d'une demande calculé avant envoi. Côté maladie : compteurs sur la fenêtre glissante, délai de
dépôt du certificat, protection contre le licenciement, alerte d'absentéisme au niveau société.

### Centre de vigilance

Un scan unique agrège toutes les échéances d'une société en trois paniers : *en retard*, *dans les
30 jours*, *à surveiller*. Chaque ligne porte sa base légale et sa conséquence. Le simulateur de
licenciement collectif donne le verdict, les alternatives et la chronologie complète de la
procédure.

### Espace salarié

Interface mobile distincte : planning une fois publié, soldes, demandes de congé, déclaration
d'incapacité avec dépôt du justificatif, documents, profil. Un salarié ne voit que ses propres
lignes, et ne voit un planning que s'il est publié.

### Portabilité

Export et rechargement au format `luxrh.export/1` : les données personnelles d'un salarié (droit
d'accès RGPD), le dossier d'une société, la fiduciaire entière, ou le référentiel légal seul. Le
serveur produit le document, vérifie qui a le droit de le demander, et journalise la demande.

### Choix de la base

L'application Python peut se connecter à PostgreSQL/Supabase, Oracle ou MySQL. Attention : **seul
PostgreSQL porte le moteur de règles.** Sur les deux autres, une évaluation de règle échoue en le
disant. Voir [bases-de-donnees.md](bases-de-donnees.md).

---

## Le principe qui structure tout

Le front **affiche et saisit** ; le serveur **calcule, valide et décide**.

Aucun seuil, aucun taux, aucune durée légale n'est écrit dans le code applicatif — ni en
TypeScript, ni en Python. Les deux interfaces lisent ce que le moteur PostgreSQL leur renvoie, y
compris le texte des messages et les références d'articles.

C'est ce qui rend les deux applications réellement équivalentes : elles ne partagent pas du code,
elles partagent des **règles**. Une correction apportée au moteur vaut immédiatement pour les deux.

---

## Ce que LuxRH ne fait pas

Cette liste est aussi importante que la précédente. Elle est tenue à jour depuis le code, pas
depuis le cahier des charges.

| Non couvert | Précision |
|---|---|
| **Calcul de paie brut → net** | Le socle est posé — cotisations, taux société datés, crédits d'impôt, avantages en nature — mais le moteur de calcul reste à écrire. C'est la V2 du cahier des charges |
| **Retenue d'impôt** | La table `tranches_impot` existe et `fn_income_tax` sait la lire ; elle est **vide**. Le calcul se suspend en le disant plutôt que d'inventer un barème |
| **Recalcul rétroactif automatique** | Les deux dates nécessaires sont conservées (date d'application et date de chargement) ; la détection des périodes à reprendre n'est pas écrite |
| **Reclassement professionnel** | Aucune table ne sait le représenter. C'est le manque fonctionnel le plus lourd |
| **Six congés légaux** | Formation, linguistique, sportif, culturel, mandat social, accueil |
| **Préretraite, chômage partiel, épargne-temps, égalité salariale** | Absents du modèle |
| **Facturation de la fiduciaire** | Non commencé |
| **Import CSV de l'existant** | Non commencé |
| **Exports comptables** (BOB, Sage, Odoo) | Non commencés |
| **Isolation par ligne sur MySQL** | Il n'existe pas d'équivalent de Row Level Security. Une implantation MySQL multi-locataires n'est pas défendable en l'état |

Le détail — valeur absente, notion absente du modèle, ou limite assumée — est établi table par
table dans [couverture-droit-du-travail.md](couverture-droit-du-travail.md).

### Ce que l'outil n'est pas

LuxRH est un outil d'aide à la décision. Il ne rend pas d'avis juridique et ne prend aucune
décision automatisée à effet juridique sur une personne, au sens de l'article 22 du RGPD. Il
prépare et documente ; la décision reste humaine.

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [demarrage.md](demarrage.md) — installer et lancer les deux applications
- [guide-utilisateur.md](guide-utilisateur.md) — le parcours écran par écran
- [couverture-droit-du-travail.md](couverture-droit-du-travail.md) — les manques, nommés un par un
- [architecture.md](architecture.md) — comment tout cela est construit
