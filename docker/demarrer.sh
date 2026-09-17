#!/usr/bin/env bash
#
# Démarrage de la pile LuxRH — à exécuter DANS la distribution WSL « luxrh ».
#
#     wsl -d luxrh
#     cd ~/luxrh && ./docker/demarrer.sh
#
# Ce script refuse de s'exécuter plutôt que de laisser un défaut se manifester
# trois heures plus tard. Chaque contrôle porte sur une erreur réellement
# rencontrée, et dit comment la corriger.

set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE"

rouge() { printf '\033[31m%s\033[0m\n' "$*" >&2; }
vert()  { printf '\033[32m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }

echec() { rouge "ARRÊT — $1"; shift; for l in "$@"; do printf '  %s\n' "$l" >&2; done; exit 1; }

# --------------------------------------------------------------- 1. le contexte
#
# La pile est prévue pour une distribution WSL nommée « luxrh », et pour elle
# seule. Sous Windows ou dans une autre distribution, les chemins et les droits
# diffèrent, et Oracle ne démarre pas.

[ -f /proc/version ] && grep -qi microsoft /proc/version \
  || echec "ce script doit s'exécuter dans WSL." \
           "Sous Windows :  wsl -d luxrh" \
           "Si la distribution n'existe pas, voir docs/infrastructure-docker-wsl.md"

DISTRO="${WSL_DISTRO_NAME:-inconnue}"
if [ "$DISTRO" != "luxrh" ]; then
  echec "distribution WSL « $DISTRO », attendue « luxrh »." \
        "La pile est prévue pour une distribution dédiée : une base Oracle" \
        "partagée avec un autre projet finit par entrer en conflit de ports," \
        "de volumes et de mémoire partagée." \
        "" \
        "Créer la distribution :  voir docs/infrastructure-docker-wsl.md"
fi

# --------------------------------------------------------- 2. le système de fichiers
#
# Oracle exige des verrous que le pilote 9p de Windows ne rend pas correctement.
# Une base posée sur /mnt/c se corrompt ou refuse de démarrer — le diagnostic
# prend des heures, le contrôle prend une ligne.

case "$RACINE" in
  /mnt/*) echec "le dépôt est sur le système de fichiers Windows ($RACINE)." \
                "Oracle y échoue : le pilote 9p ne rend pas les verrous de" \
                "fichiers, et les entrées-sorties y sont dix fois plus lentes." \
                "" \
                "Cloner le dépôt DANS la distribution :" \
                "    cd ~ && git clone <url> luxrh && cd luxrh" ;;
esac

# ------------------------------------------------------------------ 3. Docker
command -v docker >/dev/null \
  || echec "Docker n'est pas installé dans cette distribution." \
           "    curl -fsSL https://get.docker.com | sh" \
           "    sudo usermod -aG docker \$USER   # puis rouvrir le shell"

docker compose version >/dev/null 2>&1 \
  || echec "le module « docker compose » est absent." \
           "    sudo apt-get install -y docker-compose-plugin"

docker info >/dev/null 2>&1 \
  || echec "le démon Docker ne répond pas." \
           "    sudo service docker start" \
           "Et pour qu'il démarre avec la distribution, voir la documentation."

# ------------------------------------------------------------------- 4. .env
[ -f .env ] || echec "aucun fichier .env à la racine." \
                     "    cp .env.example .env" \
                     "puis renseigner ORACLE_PWD et LUXRH_DB_PASSWORD."

set -a; . ./.env; set +a

for v in ORACLE_PORT ORACLE_EM_PORT STREAMLIT_PORT API_PORT ORACLE_PWD; do
  [ -n "${!v:-}" ] || echec "la variable $v n'est pas renseignée dans .env."
done

case "${ORACLE_PWD}" in
  *'<'*|*'>'*) echo "ORACLE_PWD porte encore une valeur de remplacement." >&2; exit 1 ;;
esac

# ------------------------------------------------- 5. les ports sont-ils libres
#
# Vérifié avant de lancer : un « port is already allocated » au milieu d'un
# `compose up` laisse une pile à moitié démarrée.

occupe() { ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$"; }

CONFLITS=()
for couple in "ORACLE_PORT:$ORACLE_PORT" "ORACLE_EM_PORT:$ORACLE_EM_PORT" \
              "STREAMLIT_PORT:$STREAMLIT_PORT" "API_PORT:$API_PORT"; do
  nom="${couple%%:*}"; port="${couple##*:}"
  occupe "$port" && CONFLITS+=("$nom=$port")
done

if [ ${#CONFLITS[@]} -gt 0 ]; then
  echec "port(s) déjà occupé(s) : ${CONFLITS[*]}" \
        "Changer la ou les valeurs dans .env — et rien d'autre." \
        "Ni le docker-compose.yml ni un Dockerfile n'a besoin d'être touché." \
        "" \
        "Pour voir ce qui écoute :  ss -ltnp"
fi

# ----------------------------------------------------- 6. le schéma pour Oracle
#
# `schema/oracle.sql` est régénéré depuis PostgreSQL par emit_portable_schema.py.
# On le dépose là où l'image Oracle joue ses scripts d'initialisation, à la
# création de la base et une seule fois.

# Les données d'Oracle vivent dans un volume nommé : rien à créer ici.
mkdir -p docker/oracle-init

# Le mot de passe applicatif est transmis à SQL*Plus par un fichier de
# définitions écrit à la volée. Il est exclu du dépôt et réécrit à chaque
# démarrage : aucun mot de passe ne transite par un fichier versionné.
umask 077
cat > docker/oracle-init/00_variables.sql <<SQL
-- Généré par docker/demarrer.sh — ne pas versionner, ne pas modifier.
define LUXRH_DB_PASSWORD = "${LUXRH_DB_PASSWORD:-changez-moi}"
SQL
umask 022

if [ -f schema/oracle.sql ]; then
  cp schema/oracle.sql docker/oracle-init/02_schema.sql
  info "schéma Oracle déposé ($(wc -l < schema/oracle.sql) lignes)"
else
  rouge "schema/oracle.sql absent — la base démarrera vide."
  info  "Le régénérer :  python tools/emit_portable_schema.py schema/catalogue.json schema/"
fi

# ------------------------------------------------------------------ 7. en route
vert "Démarrage de la pile « ${COMPOSE_PROJECT_NAME:-luxrh} »"
info "Oracle      : localhost:${ORACLE_PORT}  (service ${ORACLE_PDB:-LUXRHPDB})"
info "Oracle EM   : https://localhost:${ORACLE_EM_PORT}/em"
info "Streamlit   : http://localhost:${STREAMLIT_PORT}"
info "React       : http://localhost:${API_PORT}"
echo

docker compose up -d --build

# ------------------------------------------------- 8. la pile est-elle saine
#
# Sans ce contrôle, `compose up` rend la main dès que les conteneurs existent.
# Un service mort passerait inaperçu et les autres tourneraient avec une
# dépendance absente — c'est précisément ce que les `healthcheck` évitent, mais
# encore faut-il les lire.

echo
info "Attente de l'état « healthy » — la première initialisation d'Oracle"
info "dépasse dix minutes."
echo

SERVICES=$(docker compose config --services)
LIMITE=$(( $(date +%s) + ${ATTENTE_SANTE:-900} ))

while :; do
  RESTE=""
  for s in $SERVICES; do
    cid=$(docker compose ps -q "$s" 2>/dev/null || true)
    if [ -z "$cid" ]; then RESTE="$RESTE $s(absent)"; continue; fi
    etat=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid" 2>/dev/null || echo inconnu)
    case "$etat" in
      healthy) ;;
      *)       RESTE="$RESTE $s($etat)" ;;
    esac
  done

  [ -z "$RESTE" ] && { vert "Tous les services sont sains."; break; }

  if [ "$(date +%s)" -ge "$LIMITE" ]; then
    rouge "DÉLAI DÉPASSÉ — services non sains :$RESTE"
    for s in $SERVICES; do
      cid=$(docker compose ps -q "$s" 2>/dev/null || true)
      [ -n "$cid" ] || continue
      etat=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")
      [ "$etat" = healthy ] && continue
      echo >&2
      rouge "--- $s ($etat) : vingt dernières lignes ---"
      docker compose logs --tail=20 "$s" >&2 || true
      # Le dernier contrôle de santé dit souvent tout : on ne le cache pas.
      docker inspect -f '{{if .State.Health}}{{range .State.Health.Log}}{{.Output}}{{end}}{{end}}' "$cid" 2>/dev/null | tail -5 >&2 || true
    done
    echo >&2
    rouge "La pile est INCOMPLÈTE. Ne pas s'en servir en l'état."
    info  "Diagnostic réseau :  ./docker/diagnostic.sh"
    exit 1
  fi

  printf '
  en attente :%-60s' "$RESTE"
  sleep 10
done

echo
info "Oracle      : localhost:${ORACLE_PORT}  (service ${ORACLE_PDB:-LUXRHPDB})"
info "Streamlit   : http://localhost:${STREAMLIT_PORT}"
info "React       : http://localhost:${API_PORT}"
info "État        : docker compose ps"
info "Diagnostic  : ./docker/diagnostic.sh"
