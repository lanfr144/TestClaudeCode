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
  DONNEES="${ORACLE_DATA:-./docker/volumes/oracle}"
  echo "Cette opération supprime définitivement la base Oracle de $DONNEES."
  echo "La réinitialisation qui suivra dépasse dix minutes."
  printf 'Confirmer en écrivant « effacer » : '
  read -r reponse
  if [ "$reponse" != "effacer" ]; then
    echo "Abandon — rien n'a été touché."
    exit 0
  fi
  docker compose down -v
  rm -rf "${DONNEES:?}"/*
  echo "Pile arrêtée, données supprimées."
else
  docker compose down
  echo "Pile arrêtée. Les données Oracle sont conservées."
  echo "Pour les supprimer :  ./docker/arreter.sh --effacer"
fi
