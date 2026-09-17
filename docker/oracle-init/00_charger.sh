#!/bin/bash
#
# Chargement du schéma LuxRH dans Oracle — joué à CHAQUE démarrage, une seule
# fois utile.
#
# Pourquoi `startup` et non `setup`
# ==================================
# L'image `container-registry.oracle.com/database/free` embarque une base DÉJÀ
# CRÉÉE. Elle ne passe donc jamais par `createDB.sh`, et les scripts déposés
# dans `/opt/oracle/scripts/setup` ne sont **jamais** joués. Le schéma restait
# vide, la base démarrait sans erreur, et rien ne le signalait.
#
# `startup` est joué à chaque démarrage. D'où la sentinelle ci-dessous : on
# regarde si le schéma existe avant de le créer. `02_schema.sql` porte
# quatre-vingt-quinze `create table` qui ne sont pas idempotents ; le rejouer
# échouerait bruyamment à chaque redémarrage.
#
# Le mot de passe vient de l'environnement du conteneur, pas d'un fichier
# `define`. Un fichier écrit par l'hôte appartient à l'UID de l'hôte, et Oracle
# tourne sous l'UID 54321 : il ne pouvait pas le lire.

set -uo pipefail

REPERTOIRE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDB="${ORACLE_PDB:-FREEPDB1}"
MOT_DE_PASSE="${LUXRH_DB_PASSWORD:-}"

dire() { printf '[LuxRH] %s\n' "$*"; }

if [ -z "$MOT_DE_PASSE" ]; then
  dire "ARRÊT — LUXRH_DB_PASSWORD absent de l'environnement du conteneur."
  dire "        Le renseigner dans .env ; docker-compose.yml le transmet."
  exit 1
fi

connexion="system/${ORACLE_PWD}@localhost:1521/${PDB}"

# ------------------------------------------------------------- la sentinelle
#
# Compter les objets du schéma plutôt que tester l'existence de l'utilisateur :
# un utilisateur créé mais dont le schéma a échoué doit pouvoir être repris.
objets=$(sqlplus -S -L "$connexion" <<'SQL' 2>/dev/null | tr -d '[:space:]'
set pagesize 0 feedback off heading off
select count(*) from all_objects where owner = 'LUXRH';
exit
SQL
)

if ! [[ "$objets" =~ ^[0-9]+$ ]]; then
  dire "ARRÊT — la base ne répond pas sur ${PDB}. Réponse : ${objets:-vide}"
  exit 1
fi

if [ "$objets" -gt 0 ]; then
  dire "Schéma LUXRH déjà en place — $objets objet(s). Rien à faire."
  exit 0
fi

dire "Schéma LUXRH absent. Création."

# ----------------------------------------------------------- l'utilisateur
dire "1/2 — utilisateur et droits"
sortie=$(sqlplus -S -L "$connexion" <<SQL 2>&1
whenever sqlerror exit 1
define LUXRH_DB_PASSWORD = "${MOT_DE_PASSE}"
@${REPERTOIRE}/01_utilisateur.sql
exit
SQL
)
if [ $? -ne 0 ]; then
  # Un échec sans son message est un échec qu'on ne corrige pas.
  dire "ÉCHEC à la création de l'utilisateur :"
  echo "$sortie" | sed 's/^/    /'
  exit 1
fi
echo "$sortie" | grep -E 'LUXRH' | sed 's/^/    /'

# --------------------------------------------------------------- le schéma
if [ ! -f "${REPERTOIRE}/02_schema.sql" ]; then
  dire "02_schema.sql absent — la base reste sans schéma."
  dire "Il est déposé par docker/demarrer.sh depuis schema/oracle.sql."
  exit 1
fi

dire "2/2 — tables, contraintes, commentaires et données de référence"
# `whenever sqlerror continue` : le schéma porte des objets dérivés de
# PostgreSQL dont certains peuvent ne pas passer tels quels. On veut **toutes**
# les erreurs en un seul passage, pas la première — et le décompte final dira
# ce qui est réellement entré.
sqlplus -S -L "LUXRH/${MOT_DE_PASSE}@localhost:1521/${PDB}" <<SQL > /tmp/luxrh_schema.log 2>&1
whenever sqlerror continue
set echo off feedback off
@${REPERTOIRE}/02_schema.sql
exit
SQL

erreurs=$(grep -cE '^(ORA|PLS|SP2)-[0-9]+' /tmp/luxrh_schema.log 2>/dev/null || echo 0)

objets=$(sqlplus -S -L "$connexion" <<'SQL' 2>/dev/null | tr -d '[:space:]'
set pagesize 0 feedback off heading off
select count(*) from all_objects where owner = 'LUXRH';
exit
SQL
)

dire "Terminé — ${objets:-0} objet(s) créé(s), ${erreurs} erreur(s) SQL."
if [ "${erreurs:-0}" -gt 0 ]; then
  dire "Les vingt premières :"
  grep -E '^(ORA|PLS|SP2)-[0-9]+' /tmp/luxrh_schema.log | sort | uniq -c | sort -rn | head -20
  dire "Journal complet dans le conteneur : /tmp/luxrh_schema.log"
fi

# Le chargement ne fait pas échouer le démarrage de la base : un schéma
# incomplet se corrige, une base qui refuse de monter bloque tout.
exit 0
