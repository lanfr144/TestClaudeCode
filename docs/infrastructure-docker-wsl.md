# Infrastructure : Docker dans la distribution WSL « luxrh »

La pile conteneurisée — Oracle, Streamlit, React — s'exécute **strictement dans une
distribution WSL nommée `luxrh`**. Ce document dit comment la créer, comment la
lancer, et **ce qui n'a pas pu être vérifié**.

---

## Ce qui est vérifié, et ce qui ne l'est pas

Distinction faite d'emblée, plutôt que laissée à découvrir au premier lancement.

| | État |
|---|---|
| Syntaxe des scripts (`bash -n`) | ✅ vérifiée |
| Refus hors WSL | ✅ éprouvé — le script s'arrête et dit quoi faire |
| Choix des ports contre l'occupation réelle du poste | ✅ relevé le 14/09/2026 |
| Cohérence `.env` ⇄ `docker-compose.yml` ⇄ Dockerfiles | ✅ vérifiée par script — 0 variable sans valeur |
| Un `healthcheck` sur chacun des trois services | ✅ vérifié par script |
| `logging`, `init`, `mem_limit`, `stop_grace_period`, `security_opt` | ✅ vérifiés par script sur les trois |
| Dépendances exprimées sur `service_healthy` | ✅ vérifié |
| `.dockerignore` | ✅ présent — 111 Mo + 29 Mo écartés du contexte |
| **Construction des images** | ❌ **non vérifiée** |
| **Démarrage effectif d'Oracle** | ❌ **non vérifié** |
| **Jeu du schéma `oracle.sql` sur une base réelle** | ❌ **non vérifié** |

La raison est simple et sans détour : **la distribution `luxrh` n'existe pas, et
Docker n'est pas installé sur ce poste.** Relevé le 14 septembre 2026 :

```
wsl -l -v   →  AI-P02 (par défaut, arrêtée) · Mlops1 (arrêtée)
docker      →  introuvable
```

Créer une distribution WSL et y installer Docker relève de votre décision, pas de
la mienne : ce sont des programmes, pas des paquets. Les commandes sont ci-dessous.

---

## 1. Créer la distribution

```powershell
# Depuis PowerShell, sur Windows
wsl --install -d Ubuntu-24.04 --name luxrh
```

Si votre version de WSL ne connaît pas `--name`, passer par une exportation :

```powershell
wsl --install -d Ubuntu-24.04
wsl --export Ubuntu-24.04 "$env:TEMP\ubuntu.tar"
wsl --import luxrh "$env:LOCALAPPDATA\WSL\luxrh" "$env:TEMP\ubuntu.tar"
wsl --unregister Ubuntu-24.04     # facultatif, libère l'original
```

Vérifier :

```powershell
wsl -l -v          # « luxrh » doit apparaître
wsl -d luxrh       # ouvre un shell dedans
```

### Mémoire

Oracle a besoin de mémoire. Créer `%USERPROFILE%\.wslconfig` :

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

Puis `wsl --shutdown` pour appliquer.

---

## 2. Installer Docker **dans** la distribution

Docker Desktop pour Windows fonctionnerait aussi, mais place le démon hors de la
distribution : les chemins et les droits se compliquent, et l'intérêt d'une
distribution dédiée disparaît.

```bash
# Dans « wsl -d luxrh »
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
```

Refermer puis rouvrir le shell pour que l'appartenance au groupe prenne effet.

WSL n'ayant pas de `systemd` par défaut, démarrer le démon à l'ouverture — ajouter
à `~/.bashrc` :

```bash
service docker status >/dev/null 2>&1 || sudo service docker start
```

ou activer `systemd` dans `/etc/wsl.conf` :

```ini
[boot]
systemd=true
```

---

## 3. Cloner le dépôt **dans** la distribution

**Pas sous `/mnt/c/`.** Oracle exige des verrous de fichiers que le pilote 9p de
Windows ne rend pas correctement : la base se corrompt ou refuse de démarrer, et
les entrées-sorties y sont environ dix fois plus lentes. `docker/demarrer.sh`
refuse de s'exécuter depuis un chemin `/mnt/`.

```bash
cd ~ && git clone https://github.com/lanfr144/TestClaudeCode luxrh && cd luxrh
cp .env.example .env
```

Renseigner dans `.env` au minimum `ORACLE_PWD` et `LUXRH_DB_PASSWORD`.

---

## 4. Lancer

```bash
./docker/demarrer.sh
```

Le script contrôle **avant** de lancer : l'exécution sous WSL, le nom de la
distribution, l'emplacement du dépôt, la présence de Docker, celle du `.env`, les
variables obligatoires, **la disponibilité de chaque port**. Chaque refus indique
la correction.

Puis il contrôle **après** : il attend que chaque service passe `healthy` et,
au-delà du délai, affiche les journaux et la sortie du dernier contrôle de santé
des services fautifs, **et sort en erreur**. Sans cela, `compose up` rendrait la
main dès que les conteneurs existent — un service mort passerait inaperçu et les
autres tourneraient avec une dépendance absente.

### Diagnostic

```bash
./docker/diagnostic.sh
```

Observe sans rien modifier : état et santé de chaque service, sortie du dernier
contrôle, ports en écoute côté hôte, résolution du nom `oracle` et ouverture de
son port **depuis l'intérieur** des autres conteneurs, interfaces et écoutes de
chacun, espace disque. C'est pour cela que les images embarquent `ss`, `netstat`,
`ip`, `ifconfig`, `ping` et `dig` : sans eux, un défaut réseau ne s'observe pas de
l'intérieur.

Arrêt :

```bash
./docker/arreter.sh              # conserve la base
./docker/arreter.sh --effacer    # supprime les données, avec confirmation
```

---

## 5. Les ports — tous dans `.env`, nulle part ailleurs

**Aucun port n'est écrit dans `docker-compose.yml` ni dans un Dockerfile.** Un
conflit sur l'hôte se règle en changeant une ligne de `.env`.

| Variable | Défaut | Port usuel évité | Pourquoi |
|---|---|---|---|
| `ORACLE_PORT` | `25521` | 1521 | Écoute SQL*Net |
| `ORACLE_EM_PORT` | `25500` | 5500 | Enterprise Manager Express |
| `STREAMLIT_PORT` | `25501` | 8501 | **8501 occupé sur ce poste** |
| `API_PORT` | `25173` | 5173 | **5173 occupé sur ce poste** |

Relevé des ports en écoute sur le poste le 14 septembre 2026 :

```
135  139  445  2179  3000  3240  5040  5173  6463  7680  8501  24642
```

**3000, 5173 et 8501 — les trois valeurs par défaut habituelles — étaient déjà
prises.** D'où le bloc 25xxx, dont les deux derniers chiffres rappellent le port
usuel du service.

Les ports *dans* le conteneur sont eux aussi paramétrables
(`ORACLE_CONTAINER_PORT`, `STREAMLIT_CONTAINER_PORT`…), pour le cas où une image
changerait les siens.

Vérifier qu'un port est libre :

```bash
ss -ltn | grep 25521                     # dans WSL
```
```powershell
Get-NetTCPConnection -State Listen | ? LocalPort -eq 25521   # sous Windows
```

---

## 6. Les trois services

### Oracle

Image `container-registry.oracle.com/database/free`. Le projet vise **Oracle
26ai** ; l'édition Free publiquement disponible est la **23ai**, qui partage la
syntaxe employée par `schema/oracle.sql` : `BOOLEAN` natif, `INTERVAL DAY TO
SECOND`, déclencheurs composés, `VARCHAR2(n CHAR)`.

À la création de la base, deux scripts sont joués **une seule fois** :

1. `docker/oracle-init/01_utilisateur.sql` — crée l'utilisateur `LUXRH`, ses
   droits et son quota. Écrit de façon idempotente.
2. `02_schema.sql` — copie de `schema/oracle.sql`, déposée par `demarrer.sh`.

Le mot de passe applicatif passe par `00_variables.sql`, **généré au démarrage et
exclu du dépôt**.

La première initialisation dépasse dix minutes. Le contrôle de santé de Compose
en tient compte : `start_period` de 180 s, puis quarante tentatives.

### Streamlit et React

Le code est monté en volume : une modification est prise en compte sans
reconstruire l'image. Les dépendances Node restent dans un volume nommé — celles
installées sous Windows portent des binaires incompatibles avec Linux.

Les deux services lisent `luxrh/.env.local` s'il existe. Absent, ils démarrent et
l'application signale l'absence de configuration au lieu d'afficher un écran vide.

---

## 7. Ce qu'il restera à éprouver

Une fois la distribution créée, dans cet ordre :

1. `docker compose build` — les deux images applicatives ;
2. `docker compose up -d oracle` puis `docker compose logs -f oracle` — guetter
   `DATABASE IS READY TO USE` ;
3. le jeu de `02_schema.sql` : `schema/oracle.sql` fait 95 créations d'objets et
   n'a **jamais été exécuté sur une base réelle**. Des écarts sont probables sur
   les déclencheurs composés et les types composites ;
4. la connexion depuis Streamlit :
   `.venv/Scripts/python -m streamlit run app.py -- --db oracle`.

Le point 3 est celui qui demandera du travail. Le générateur signale ce qu'il ne
sait pas traduire — actuellement **0 point** —, mais « traduit » ne veut pas dire
« accepté par Oracle ».

---

## Voir aussi

- [`bases-de-donnees.md`](bases-de-donnees.md) — la portabilité multi-SGBD
- [`donnees-de-reference.md`](donnees-de-reference.md) — charger le référentiel
- [`../CLAUDE.md`](../CLAUDE.md) — les règles du projet
