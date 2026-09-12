# Documentation LuxRH

LuxRH est un assistant RH et paie pour le droit du travail luxembourgeois. Deux interfaces —
une application React et une application Streamlit — s'appuient sur **un seul moteur de règles**
écrit en PL/pgSQL. Cette page est le point d'entrée unique de la documentation : chaque document
ci-dessous y renvoie, et aucun n'existe hors de cette liste.

Le dépôt est public. Aucun identifiant, aucune clé, aucune référence de projet ne figure dans
cette documentation.

---

## Par où commencer

| Vous êtes… | Lisez dans cet ordre |
|---|---|
| Qui reprend le travail en cours | [Feuille de route](feuille-de-route.md) → [Écarts à corriger](ecarts-a-corriger.md) |
| Nouveau sur le projet | [Présentation](presentation.md) → [Démarrage](demarrage.md) → [Guide utilisateur](guide-utilisateur.md) |
| Développeur front | [Architecture](architecture.md) → [API serveur](api-serveur.md) → [Contribuer](contribuer.md) |
| Développeur base de données | [Modèle de données](modele-de-donnees.md) → [Moteur de règles](moteur-de-regles.md) → [Contribuer](contribuer.md) |
| Chargé de conformité / juriste | [Couverture du droit du travail](couverture-droit-du-travail.md) → [Sécurité et conformité](securite-et-conformite.md) → [Moteur de règles](moteur-de-regles.md) |
| Exploitant / intégrateur | [Bases de données](bases-de-donnees.md) → [Démarrage](demarrage.md) |

---

## Les documents

| Document | Ce qu'on y trouve | Pour qui |
|---|---|---|
| [presentation.md](presentation.md) | Le problème métier, les capacités de l'outil, ce qu'il ne fait pas | Tout le monde, en premier |
| [demarrage.md](demarrage.md) | Prérequis, installation des deux applications, `.env.local`, build, tests, choix de la base, dépannage | Toute personne qui doit faire tourner le projet |
| [architecture.md](architecture.md) | Les deux fronts, le moteur PL/pgSQL, le flux complet d'une requête, le raisonnement derrière les choix | Développeurs, architectes |
| [moteur-de-regles.md](moteur-de-regles.md) | Le référentiel daté, la hiérarchie loi → CCT → contrat, les scans de conformité, `fn_referential_gaps` | Développeurs base de données, conformité |
| [api-serveur.md](api-serveur.md) | Inventaire des fonctions RPC : nom, arguments, retour, appelants, migration d'origine | Développeurs des deux fronts |
| [guide-utilisateur.md](guide-utilisateur.md) | Parcours écran par écran, de la connexion à la portabilité | Utilisateurs, formateurs, testeurs |
| [modele-de-donnees.md](modele-de-donnees.md) | Les 75 tables par domaine, leurs relations, les clés d'isolation | Développeurs base de données |
| [tests-et-qualite.md](tests-et-qualite.md) | Les six suites de tests, comment les lancer, ce qu'elles vérifient et ce qui n'est pas couvert | Développeurs, relecteurs |
| [contribuer.md](contribuer.md) | Conventions du dépôt : migrations, français, pièges `supabase-js`, valeurs en dur, dépôt public | Toute personne qui écrit du code ici |
| [bases-de-donnees.md](bases-de-donnees.md) | Choix de la base par argument, ce qu'Oracle et MySQL portent — et ce qu'ils ne portent pas | Exploitants, intégrateurs |
| [couverture-droit-du-travail.md](couverture-droit-du-travail.md) | Ce que l'outil couvre du droit du travail et des CCT, et ce qu'il ne couvre pas, table par table | Conformité, juristes, direction produit |
| [securite-et-conformite.md](securite-et-conformite.md) | Revue de sécurité, RGPD (dont la journalisation des accès) et position au regard de l'AI Act | Sécurité, conformité, direction |
| [personnel-et-horaires.md](personnel-et-horaires.md) | Ce qui manque aux deux domaines pour être terminés, et le plan chiffré pour les finir | Direction produit, développeurs |
| [feuille-de-route.md](feuille-de-route.md) | Les douze chantiers en cours : ce qui est fait, ce qui attend, dans quel ordre. **Le point de reprise** | Direction, développeurs |
| [ecarts-a-corriger.md](ecarts-a-corriger.md) | Fiche de passation : ce qui a été trouvé de faux ou d'irrégulier dans le dépôt, corrigé ou non | Qui reprend le code après une relecture |

---

## Ailleurs dans le dépôt

| Fichier | Rôle |
|---|---|
| [`../README.md`](../README.md) | Vue d'ensemble du dépôt |
| [`../luxrh/README.md`](../luxrh/README.md) | Application React : démarrage, comptes de démonstration, sécurité |
| [`../luxrh-py/README.md`](../luxrh-py/README.md) | Application Streamlit : démarrage, écrans, environnement Python |
| `../PRD_LuxRH.md` | Cahier des charges d'origine. **C'est une intention, pas un état réel** : là où il diverge du code, le code fait foi et la présente documentation le suit |
| `../CLAUDE.md` | Règles de travail non négociables du projet |
| `../Design System LuxRH.dc.html` · `../Maquettes LuxRH.dc.html` | Références visuelles |

---

## Repères chiffrés

Tous relevés sur la base déployée à la date du 10 septembre 2026 (migrations 46 à 56 comprises),
jamais estimés.

| | |
|---|---|
| Migrations PostgreSQL | 60 fichiers dans le dépôt ; migrations 46 à 56 **appliquées** |
| Fonctions du moteur | 110 noms distincts, 111 fonctions installées (`fn_make_national_id` est surchargée) : 102 `fn_*` et 9 fonctions de contrôle d'accès ou déclencheurs techniques. 65 `security definer`, dont 54 exécutables par `authenticated` ; 0 exécutable par `anon` |
| Tables vivantes | 53, toutes sous Row Level Security ; 184 politiques (52 lecture, 44 insertion, 45 mise à jour, 43 suppression) |
| Types énumérés | 20 |
| Clés de paramètres légaux chargées (`parametres_legaux`) | 100 clés distinctes |
| Clés de paramètres attendues (`parametres_attendus`, migration 50) | 76, dont `mileage_allowance_eur_per_km` et `accident_class_rates` déclarées et **vides** |
| Écrans React | 22 composants de page |
| Écrans Streamlit | 16 vues |
| Suites de tests | 6, soit 190 vérifications, 0 échec |

---

## Voir aussi

- [presentation.md](presentation.md) — ce que fait l'application
- [demarrage.md](demarrage.md) — la faire tourner
- [architecture.md](architecture.md) — comment elle est construite

- [`donnees-de-reference.md`](donnees-de-reference.md) — où trouver les valeurs légales, quand et comment les charger, comment tester
