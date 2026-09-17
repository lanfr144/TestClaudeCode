# -*- coding: utf-8 -*-
"""Exporte les données obligatoires des tables de référence, en SQL portable.

    python tools/exporter_donnees_reference.py             # constate
    python tools/exporter_donnees_reference.py --ecrire    # écrit les fichiers
    python tools/exporter_donnees_reference.py --integrer  # les ajoute aux DDL

Un schéma vide n'est pas un schéma utilisable : sans ses tables de référence
peuplées, le moteur ne connaît ni les pays, ni les motifs d'absence, ni le
moindre seuil légal. `fn_min_salary` rend NULL, `fn_validate_schedule` ne
contrôle rien, et rien ne le signale. Les DDL portent donc leurs DML.

Ne sont exportées que les tables **sans** `societe_id` ni `organisation_id` :
le référentiel est commun, les données clientes ne sortent jamais d'ici.

La lecture passe par l'API REST, avec le compte de démonstration, exactement
comme les tests. Aucun identifiant n'est écrit ici : ils viennent de
`luxrh/.env.local`, ignoré par git.
"""
from __future__ import annotations

import argparse
import datetime as dt
import io
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
ENV_LOCAL = RACINE / "luxrh" / ".env.local"
SCHEMA = RACINE / "schema"

# Le référentiel commun, dans l'ordre où il doit être inséré : une table citée
# par une clé étrangère vient avant celle qui la cite.
TABLES = [
    "ref_pays",
    "ref_type_adresse",
    "ref_lien_enfant",
    "ref_action_acces",
    "ref_compensation_heures_sup",
    "ref_statut_heures_sup",
    "ref_statut_verification_adresse",
    "ref_sujet_export",
    "ref_unite_essai",
    "ref_unite_prime",
    "ref_nature_prime",
    "ref_condition_travail",
    "ref_indicateur_secours",
    "ref_classe_paie",
    "ref_couverture_aaa",
    "zones_adresse",
    "categories_sanction",
    "types_absence",
    "droits_absence",
    "types_document",
    "types_avantage",
    "parametres_attendus",
    "parametres_legaux",
    "tranches_impot",
    "credits_impot",
    "jours_feries",
]

# Colonnes techniques : une date de création n'a pas à être rejouée.
COLONNES_ECARTEES = {"cree_le", "saisi_le", "valide_le", "saisi_par", "valide_par",
                     "supprime_le", "supprime_par"}


def lire_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if ENV_LOCAL.exists():
        for ligne in ENV_LOCAL.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^\s*([A-Z0-9_]+)\s*=\s*(.*)$", ligne)
            if m:
                env[m.group(1)] = m.group(2).strip()
    for cle in ("VITE_SUPABASE_URL", "VITE_SUPABASE_ANON_KEY", "LUXRH_MANAGER_PASSWORD"):
        if os.environ.get(cle):
            env[cle] = os.environ[cle]
    return env


def appel(url: str, entetes: dict, corps=None):
    donnees = json.dumps(corps).encode() if corps is not None else None
    requete = urllib.request.Request(url, data=donnees, headers=entetes,
                                     method="POST" if corps is not None else "GET")
    with urllib.request.urlopen(requete, timeout=60) as reponse:
        return json.loads(reponse.read().decode("utf-8"))


def jeton(env: dict) -> str:
    resultat = appel(
        f"{env['VITE_SUPABASE_URL']}/auth/v1/token?grant_type=password",
        {"apikey": env["VITE_SUPABASE_ANON_KEY"], "Content-Type": "application/json"},
        {"email": "demo@luxrh.lu", "password": env["LUXRH_MANAGER_PASSWORD"]},
    )
    if "access_token" not in resultat:
        raise SystemExit(f"Authentification refusée : {resultat}")
    return resultat["access_token"]


def lire_table(env: dict, token: str, table: str) -> list[dict]:
    """Toutes les lignes, par pages : PostgREST en rend mille au plus."""
    entetes = {"apikey": env["VITE_SUPABASE_ANON_KEY"],
               "Authorization": f"Bearer {token}"}
    lignes: list[dict] = []
    while True:
        url = (f"{env['VITE_SUPABASE_URL']}/rest/v1/{table}"
               f"?select=*&limit=1000&offset={len(lignes)}")
        lot = appel(url, entetes)
        if not isinstance(lot, list):
            raise SystemExit(f"{table} : réponse inattendue — {lot}")
        lignes.extend(lot)
        if len(lot) < 1000:
            return lignes


def litteral(valeur, dialecte: str) -> str:
    """Une valeur Python rendue dans la syntaxe du dialecte."""
    if valeur is None:
        return "null"
    if isinstance(valeur, bool):
        # Oracle 23ai porte un BOOLEAN natif ; MySQL n'a que 0 et 1.
        return ("true" if valeur else "false") if dialecte in ("postgres", "oracle") \
               else ("1" if valeur else "0")
    if isinstance(valeur, (int, float)):
        return repr(valeur)
    if isinstance(valeur, (dict, list)):
        return "'" + json.dumps(valeur, ensure_ascii=False).replace("'", "''") + "'"

    texte = str(valeur)
    # Une date ISO se cite explicitement : Oracle refuse une chaîne nue là où il
    # attend une DATE, et la conversion implicite dépend du NLS du client.
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", texte):
        return f"date '{texte}'" if dialecte in ("postgres", "oracle") else f"'{texte}'"
    return "'" + texte.replace("'", "''") + "'"


def sql_table(table: str, lignes: list[dict], dialecte: str) -> list[str]:
    if not lignes:
        return [f"-- {table} : aucune donnée de référence.", ""]

    colonnes = [c for c in lignes[0].keys() if c not in COLONNES_ECARTEES]
    guillemet = '"' if dialecte in ("postgres", "oracle") else "`"
    q = lambda n: f"{guillemet}{n.upper() if dialecte == 'oracle' else n}{guillemet}"
    fin = ";" if dialecte != "oracle" else ";"

    out = [f"-- {table} — {len(lignes)} ligne(s)"]
    entete = f"insert into {q(table)} ({', '.join(q(c) for c in colonnes)}) values"
    for ligne in lignes:
        valeurs = ", ".join(litteral(ligne.get(c), dialecte) for c in colonnes)
        out.append(f"{entete} ({valeurs}){fin}")
    out.append("")
    return out


def main() -> int:
    p = argparse.ArgumentParser(description="Exporte les données de référence.")
    p.add_argument("--ecrire", action="store_true", help="écrit schema/donnees-reference.*.sql")
    p.add_argument("--integrer", action="store_true",
                   help="ajoute les DML à la fin de schema/oracle.sql et schema/mysql.sql")
    args = p.parse_args()

    env = lire_env()
    manquantes = [c for c in ("VITE_SUPABASE_URL", "VITE_SUPABASE_ANON_KEY",
                              "LUXRH_MANAGER_PASSWORD") if not env.get(c)]
    if manquantes:
        print(f"ARRÊT — variables absentes de luxrh/.env.local : {', '.join(manquantes)}")
        return 1

    try:
        token = jeton(env)
    except urllib.error.URLError as e:
        print(f"ARRÊT — la base ne répond pas : {e}")
        return 1

    print("=" * 74)
    print("DONNÉES DE RÉFÉRENCE")
    print("=" * 74)
    print()

    contenu: dict[str, list[dict]] = {}
    total = 0
    for table in TABLES:
        try:
            lignes = lire_table(env, token, table)
        except urllib.error.HTTPError as e:
            print(f"  {table:34} ABSENTE OU REFUSÉE ({e.code})")
            continue
        contenu[table] = lignes
        total += len(lignes)
        print(f"  {table:34} {len(lignes):5} ligne(s)")

    print(f"\n{total} ligne(s) de référence, {len(contenu)} table(s).")

    if not (args.ecrire or args.integrer):
        print("\nConstat seul. Pour écrire :  --ecrire   |   pour intégrer aux DDL :  --integrer")
        return 0

    entete = [
        "-- Données obligatoires des tables de référence.",
        "--",
        "-- Généré par `tools/exporter_donnees_reference.py` depuis la base de",
        f"-- référence, le {dt.date.today():%d/%m/%Y}. Ne pas modifier à la main.",
        "--",
        "-- Un schéma sans ces lignes se crée sans erreur et ne calcule rien : le",
        "-- moteur ne connaîtrait ni les pays, ni les motifs d'absence, ni le moindre",
        "-- seuil légal, et `fn_param_num` rendrait NULL en silence.",
        "--",
        "-- Seules les tables sans `societe_id` ni `organisation_id` figurent ici :",
        "-- le référentiel est commun, les données clientes ne sortent jamais.",
        "",
    ]

    for dialecte in ("oracle", "mysql", "postgres"):
        lignes_sql = list(entete)
        for table, donnees in contenu.items():
            lignes_sql += sql_table(table, donnees, dialecte)
        texte = "\n".join(lignes_sql) + "\n"

        if args.ecrire or args.integrer:
            cible = SCHEMA / f"donnees-reference.{dialecte}.sql"
            cible.write_text(texte, encoding="utf-8")
            print(f"  écrit : {cible.relative_to(RACINE)}  ({len(texte) // 1024} Ko)")

        if args.integrer and dialecte in ("oracle", "mysql"):
            ddl = SCHEMA / f"{dialecte}.sql"
            if not ddl.exists():
                print(f"  {ddl.name} absent — régénérer d'abord emit_portable_schema.py")
                continue
            base = ddl.read_text(encoding="utf-8")
            marque = "-- >>> DONNÉES DE RÉFÉRENCE >>>"
            if marque in base:
                base = base[:base.index(marque)]
            ddl.write_text(base.rstrip() + f"\n\n{marque}\n\n" + texte, encoding="utf-8")
            print(f"  intégré : {ddl.relative_to(RACINE)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
