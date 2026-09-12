# Démarrage

Ce document s'adresse à qui doit faire tourner LuxRH sur son poste : installation des deux
applications, configuration, build, tests, et les erreurs de démarrage les plus fréquentes.

---

## Prérequis

| Outil | Version | Pour |
|---|---|---|
| Node.js | 20 ou plus | Application React et suites de tests |
| Python | 3.10 ou plus | Application Streamlit |
| Un projet Supabase | PostgreSQL 17 | Base de données et moteur de règles |
| Supabase CLI | — | Uniquement pour appliquer les migrations sur une base neuve |

Les migrations sont déjà appliquées sur le projet de développement. Le CLI n'est nécessaire que
pour repartir d'une base vierge.

---

## Configuration

Les deux applications lisent **le même fichier** : `luxrh/.env.local`. Il est ignoré par Git et
n'existe pas dans le dépôt — partez de `luxrh/.env.example`.

```
VITE_SUPABASE_URL=https://<reference-du-projet>.supabase.co
VITE_SUPABASE_ANON_KEY=<cle-publiable>

# Comptes de démonstration, utilisés par les suites de tests.
LUXRH_MANAGER_PASSWORD=
LUXRH_EMPLOYEE_PASSWORD=
LUXRH_OTHER_PASSWORD=
```

> **Le dépôt est public.** Aucune de ces valeurs ne doit être commitée. Les suites de tests lisent
> les mots de passe depuis l'environnement ou depuis `.env.local`, et **refusent de démarrer**
> s'ils manquent, plutôt que d'échouer à mi-parcours sur un message obscur.

Côté Python, `luxrh-py/luxrh/client.py` cherche la configuration dans cet ordre :

1. les variables d'environnement `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY` ;
2. `luxrh-py/.env` ;
3. `luxrh/.env.local` — le fichier de l'application React.

Si le front React est déjà configuré, il n'y a rien à faire de plus. `luxrh-py/.env.example` ajoute
une clé propre à Streamlit, `LUXRH_APP_URL`, qui porte l'URL de retour des liens de confirmation
d'inscription (par défaut `http://localhost:8501`).

---

## Application React

```bash
cd luxrh
npm install
npm run dev          # http://localhost:5173
```

Autres commandes :

| Commande | Effet |
|---|---|
| `npm run build` | `tsc --noEmit` puis `vite build`. **Doit rester à zéro erreur TypeScript** |
| `npm run typecheck` | Vérification de types seule |
| `npm run preview` | Sert le build de production |
| `npm test` | Les six suites, dans l'ordre — voir [tests-et-qualite.md](tests-et-qualite.md) |

---

## Application Streamlit

Un environnement virtuel est déjà en place dans `luxrh-py/.venv`, créé avec
`--system-site-packages`.

```bash
cd luxrh-py
.venv/Scripts/python -m streamlit run app.py     # http://localhost:8501
```

> **L'environnement Python global héberge l'installation Airflow de l'utilisateur et ne doit pas
> être modifié.** Le `.venv` s'appuie dessus pour Streamlit, pandas et plotly ; seul le client
> `supabase` y a été ajouté. Avant d'installer un programme — et non un simple paquet —
> demandez.

Pour repartir d'un environnement propre ailleurs :

```bash
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt
```

`requirements.txt` demande `streamlit>=1.40`, `supabase>=2.10` et `pandas>=2.0`.

### Choix de la base par argument

L'application Python accepte le choix de la base sur la ligne de commande. Les arguments viennent
**après `--`**, que Streamlit utilise pour séparer ses propres options de celles du script.

```bash
.venv/Scripts/python -m streamlit run app.py -- --db supabase
.venv/Scripts/python -m streamlit run app.py -- --db oracle --dsn hote:1521/XEPDB1 --user luxrh
.venv/Scripts/python -m streamlit run app.py -- --db mysql  --dsn hote:3306/luxrh  --user luxrh
```

À défaut d'argument, la variable d'environnement `LUXRH_DB` fait foi, puis `supabase`. Le mot de
passe se lit dans `LUXRH_DB_PASSWORD` — **jamais en ligne de commande**, où il resterait dans
l'historique du shell.

Sur Oracle et MySQL, LuxRH lit, écrit, exporte et importe, mais **n'évalue aucune règle** : le
moteur est écrit en PL/pgSQL. Toute évaluation lève `EngineUnavailable` en nommant la fonction
concernée. Les limites, dont l'absence d'isolation par ligne sur MySQL, sont dans
[bases-de-donnees.md](bases-de-donnees.md).

---

## Base de données neuve

```bash
cd luxrh
supabase link --project-ref <reference-du-projet>
supabase db push
```

Les 58 migrations de `luxrh/supabase/migrations/` s'appliquent dans l'ordre de leur numéro. Elles
créent le schéma, le moteur, les politiques de sécurité et le référentiel initial.

Pour Oracle ou MySQL, le schéma se dérive du catalogue PostgreSQL :

```bash
python tools/emit_portable_schema.py schema/catalogue.json schema/
```

Puis le référentiel se repeuple par la page **Portabilité** : exporter depuis l'implantation
existante, charger sur la nouvelle.

---

## Jeu de démonstration

Depuis un espace vide, le bouton **« Charger le jeu de démonstration »** (écran *Sociétés* côté
React, barre latérale côté Streamlit) appelle `fn_seed_demo()` : une fiduciaire, ses dossiers
clients, leurs salariés, contrats, plannings et absences.

Les comptes de démonstration (`demo@`, `marta@`, `autre@luxrh.lu`) existent sur le projet de
développement. Leurs mots de passe vivent dans `.env.local` et **ne sont pas dans le dépôt**. Ce
sont des comptes de démonstration, **à supprimer avant toute mise en production**.

---

## Inscription et courriel de confirmation

Deux réglages appartiennent au projet Supabase et ne peuvent donc pas être versionnés.

**1. Où le lien de confirmation renvoie** — *Authentication → URL Configuration*

| Champ | Valeur |
|---|---|
| Site URL | `http://localhost:5173` |
| Redirect URLs | `http://localhost:5173/**`, `http://localhost:5174/**`, `http://localhost:8501/**` |

Le port 5174 est celui que Vite choisit quand 5173 est déjà pris.

**2. Envoi des courriels** — *Authentication → Emails*. Le service intégré est limité à quelques
messages par heure. Pour le développement local, le plus simple est de **désactiver la confirmation
par courriel** : l'inscription ouvre alors la session immédiatement.

Les deux applications utilisent le **flux PKCE** : le jeton revient en paramètre de requête
(`?code=`) et non en fragment (`#…`). C'est indispensable côté Streamlit, où un fragment d'URL
n'est jamais transmis au serveur.

---

## Dépannage

| Symptôme | Cause et remède |
|---|---|
| `Configuration Supabase manquante : renseignez VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY` | `.env.local` absent ou incomplet. Copiez `luxrh/.env.example`. Le message est le même côté React et côté Python |
| `Mot de passe du compte « manager » absent` au lancement des tests | `LUXRH_MANAGER_PASSWORD` (ou `EMPLOYEE`, ou `OTHER`) n'est pas renseigné dans `.env.local` |
| Le lien de confirmation aboutit sur une page morte | La Site URL du projet Supabase pointe encore sur `http://localhost:3000`. Voir le réglage 1 ci-dessus |
| Le lien de confirmation est refusé | Un lien PKCE n'est valable **qu'une fois**, et **depuis le navigateur qui a servi à l'inscription**, qui seul conserve le vérificateur. L'application le dit explicitement |
| L'inscription annonce un succès mais aucun courriel n'arrive | L'adresse est déjà enregistrée. Supabase répond HTTP 200 sans envoyer de message, délibérément, pour ne pas révéler quels comptes existent. Les deux applications détectent ce cas et l'annoncent |
| `La base « … » ne porte pas le moteur de règles` | Vous êtes connecté à Oracle ou MySQL. C'est le comportement attendu : voir [bases-de-donnees.md](bases-de-donnees.md) |
| `La base « oracle » demande --dsn et --user` | Rien n'est deviné. Fournissez le DSN et l'utilisateur ; le mot de passe passe par `LUXRH_DB_PASSWORD` |
| `Le pilote oracle n'est pas installé` | Installez `oracledb` (ou `mysql-connector-python` pour MySQL) **dans le `.venv`**, pas dans l'environnement global |
| Streamlit redémarre en boucle après une connexion | La session est réappliquée à chaque *rerun*. Si le problème persiste, videz le cache : bouton *Se déconnecter*, qui appelle `st.session_state.clear()` |
| Vite écoute sur 5174 au lieu de 5173 | Une autre instance tourne déjà. Autorisez `http://localhost:5174/**` côté Supabase, ou arrêtez l'instance concurrente |

---

## Voir aussi

- [index.md](index.md) — sommaire de la documentation
- [architecture.md](architecture.md) — ce que fait chaque couche
- [tests-et-qualite.md](tests-et-qualite.md) — lancer et lire les suites de tests
- [bases-de-donnees.md](bases-de-donnees.md) — Oracle, MySQL, et leurs limites
- [contribuer.md](contribuer.md) — les conventions à respecter avant de coder
