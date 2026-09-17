#!/usr/bin/env bash
#
# Arrêt de la pile LuxRH.
#
#     ./docker/arreter.sh              # arrête, conserve la base
#     ./docker/arreter.sh --effacer    # arrête ET supprime les données Oracle
#
# Par défaut les volumes sont conservés : une base Oracle met plus de dix
# minutes à se réinitialiser, et l'effacer par mégarde coûte une demi-journée.

set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

[ -f .env ] || { echo "Aucun .env à la racine." >&2; exit 1; }
set -a; . ./.env; set +a

if [ "${1:-}" = "--effacer" ]; then
  echo "Cette opération supprime définitivement la base Oracle."
  echo "La réinitialisation qui suivra dépasse dix minutes."
  printf 'Confirmer en écrivant « effacer » : '
  read -r reponse
  if [ "$reponse" != "effacer" ]; then
    echo "Abandon — rien n'a été touché."
    exit 0
  fi
  # `down -v` suffit : les données vivent dans le volume nommé `oracle_data`,
  # plus dans un répertoire de l'hôte. Le `rm -rf` d'avant ne servait plus à
  # rien et pointait vers un chemin qui n'existe pas.
  docker compose down -v
  echo "Pile arrêtée, données supprimées."
else
  docker compose down
  echo "Pile arrêtée. Les données Oracle sont conservées."
  echo "Pour les supprimer :  ./docker/arreter.sh --effacer"
fi
