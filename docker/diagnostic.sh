#!/usr/bin/env bash
#
# Diagnostic de la pile LuxRH — à exécuter dans la distribution WSL « luxrh ».
#
#     ./docker/diagnostic.sh
#
# À lancer quand un service est `unhealthy`, qu'un conteneur ne joint pas son
# voisin, ou qu'un port ne répond pas depuis l'hôte. Ne modifie rien : il
# observe et rend compte.
#
# Les images embarquent à dessein `ss`, `netstat`, `ip`, `ifconfig`, `ping` et
# `dig` : sans eux, un défaut réseau ne s'observe pas de l'intérieur du
# conteneur et l'on en est réduit à deviner.

set -uo pipefail            # pas de `-e` : un diagnostic va jusqu'au bout
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

titre() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
rouge() { printf '\033[31m%s\033[0m\n' "$*"; }
vert()  { printf '\033[32m%s\033[0m\n' "$*"; }

[ -f .env ] || { rouge "Aucun .env à la racine."; exit 1; }
set -a; . ./.env; set +a

# --------------------------------------------------------------- 1. contexte
titre "Contexte"
printf '  distribution WSL : %s\n' "${WSL_DISTRO_NAME:-hors WSL}"
printf '  répertoire       : %s\n' "$PWD"
printf '  docker           : %s\n' "$(docker --version 2>/dev/null || echo absent)"
printf '  compose          : %s\n' "$(docker compose version --short 2>/dev/null || echo absent)"

# ------------------------------------------------------ 2. état des services
titre "État des services"
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null \
  || rouge "  compose ne répond pas"

titre "Santé détaillée"
for s in $(docker compose config --services 2>/dev/null); do
  cid=$(docker compose ps -q "$s" 2>/dev/null)
  if [ -z "$cid" ]; then
    rouge "  $s : conteneur absent"
    continue
  fi
  etat=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid")
  case "$etat" in
    healthy) vert  "  $s : $etat" ;;
    *)       rouge "  $s : $etat"
             # La sortie du dernier contrôle dit presque toujours pourquoi.
             docker inspect -f '{{if .State.Health}}{{range .State.Health.Log}}      {{.Output}}{{end}}{{end}}' \
               "$cid" 2>/dev/null | tail -3 ;;
  esac
done

# ------------------------------------------------ 3. les ports côté hôte
titre "Ports attendus sur l'hôte"
for couple in "Oracle:${ORACLE_PORT}" "Oracle EM:${ORACLE_EM_PORT}" \
              "Streamlit:${STREAMLIT_PORT}" "React:${API_PORT}"; do
  nom="${couple%%:*}"; port="${couple##*:}"
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}\$"; then
    vert "  $nom ($port) : en écoute"
  else
    rouge "  $nom ($port) : personne n'écoute"
  fi
done

# --------------------------------------- 4. le réseau vu depuis l'intérieur
titre "Résolution et joignabilité entre conteneurs"
for s in streamlit api; do
  cid=$(docker compose ps -q "$s" 2>/dev/null)
  [ -n "$cid" ] || { rouge "  $s : absent"; continue; }
  printf '  %s → oracle : ' "$s"
  if docker compose exec -T "$s" sh -c \
       "getent hosts oracle >/dev/null 2>&1"; then
    if docker compose exec -T "$s" sh -c \
         "curl -s --connect-timeout 3 -o /dev/null telnet://oracle:${ORACLE_CONTAINER_PORT}" 2>/dev/null \
       || docker compose exec -T "$s" sh -c \
         "(exec 3<>/dev/tcp/oracle/${ORACLE_CONTAINER_PORT}) 2>/dev/null"; then
      vert "nom résolu, port ${ORACLE_CONTAINER_PORT} ouvert"
    else
      rouge "nom résolu, mais port ${ORACLE_CONTAINER_PORT} FERMÉ"
    fi
  else
    rouge "nom « oracle » NON RÉSOLU — le service est-il démarré ?"
  fi
done

titre "Interfaces et écoutes dans les conteneurs"
for s in $(docker compose config --services 2>/dev/null); do
  cid=$(docker compose ps -q "$s" 2>/dev/null)
  [ -n "$cid" ] || continue
  printf '\n  --- %s ---\n' "$s"
  docker compose exec -T "$s" sh -c \
    'ip -brief addr 2>/dev/null || ifconfig 2>/dev/null | head -8' 2>/dev/null \
    | sed 's/^/      /' || echo "      (inaccessible)"
  docker compose exec -T "$s" sh -c \
    'ss -ltn 2>/dev/null || netstat -ltn 2>/dev/null' 2>/dev/null \
    | sed 's/^/      /' | head -6 || true
done

# ------------------------------------------------------- 5. place disponible
titre "Espace disque et volumes"
df -h . 2>/dev/null | sed 's/^/  /'
printf '  données Oracle : %s\n' "$(du -sh "${ORACLE_DATA:-./docker/volumes/oracle}" 2>/dev/null | cut -f1 || echo '—')"

titre "Fin du diagnostic"
echo "  Journaux détaillés :  docker compose logs -f <service>"
echo "  Entrer dans un conteneur :  docker compose exec <service> sh"
