"""Récupère le catalogue du schéma depuis la base et l'écrit dans schema/catalogue.json.

    luxrh-py/.venv/Scripts/python tools/fetch_catalogue.py

Pourquoi ce script existe
-------------------------
Le catalogue se régénérait en collant une requête dans l'éditeur SQL puis en
enregistrant le résultat à la main. Deux conséquences : personne ne le faisait, et
la requête **n'extrayait pas les commentaires** — c'est ainsi que les 300
commentaires de table et de colonne posés en migration 47 ne sont jamais arrivés
dans les schémas Oracle et MySQL.

La migration 58 expose `fn_schema_catalogue_for_admin()`, réservée aux
administrateurs d'organisation et qui rend les commentaires. Ce script l'appelle
et écrit le fichier. Plus de copier-coller, donc plus d'oubli.

Ce qu'il lit, et ce qu'il n'écrit pas
-------------------------------------
Les identifiants viennent de `luxrh/.env.local` ou de l'environnement, comme pour
les suites de tests. **Rien n'est écrit en dur** : ce dépôt est public. Le compte
utilisé doit être administrateur d'organisation ; à défaut, la fonction refuse et
le script le dit au lieu d'écrire un catalogue partiel.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
ENV = RACINE / "luxrh" / ".env.local"
CIBLE = RACINE / "schema" / "catalogue.json"


def lire_env() -> dict[str, str]:
    valeurs: dict[str, str] = {}
    if ENV.exists():
        for ligne in ENV.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^\s*([A-Z0-9_]+)\s*=\s*(.*)$", ligne)
            if m:
                valeurs[m.group(1)] = m.group(2).strip()
    return valeurs


def parametre(nom: str, env: dict[str, str]) -> str | None:
    return os.environ.get(nom) or env.get(nom)


def poster(url: str, entetes: dict[str, str], corps: dict) -> dict:
    requete = urllib.request.Request(
        url,
        data=json.dumps(corps).encode("utf-8"),
        headers={**entetes, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(requete, timeout=60) as reponse:
        return json.loads(reponse.read().decode("utf-8"))


def main() -> int:
    env = lire_env()
    base = parametre("VITE_SUPABASE_URL", env)
    cle = parametre("VITE_SUPABASE_ANON_KEY", env)
    if not base or not cle:
        print("VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY sont requis "
              "(environnement ou luxrh/.env.local).", file=sys.stderr)
        return 1

    courriel = parametre("LUXRH_ADMIN_EMAIL", env) or "demo@luxrh.lu"
    motdepasse = (parametre("LUXRH_ADMIN_PASSWORD", env)
                  or parametre("LUXRH_MANAGER_PASSWORD", env))
    if not motdepasse:
        print("Mot de passe absent : renseignez LUXRH_ADMIN_PASSWORD (ou "
              "LUXRH_MANAGER_PASSWORD) dans l'environnement ou luxrh/.env.local.",
              file=sys.stderr)
        return 1

    try:
        jeton = poster(
            f"{base}/auth/v1/token?grant_type=password",
            {"apikey": cle},
            {"email": courriel, "password": motdepasse},
        )["access_token"]
    except Exception as erreur:                     # noqa: BLE001
        print(f"Connexion refusée pour {courriel} : {erreur}", file=sys.stderr)
        return 1

    try:
        catalogue = poster(
            f"{base}/rest/v1/rpc/fn_schema_catalogue_for_admin",
            {"apikey": cle, "Authorization": f"Bearer {jeton}"},
            {},
        )
    except urllib.error.HTTPError as erreur:        # noqa: PERF203
        detail = erreur.read().decode("utf-8", "replace")[:300]
        print(f"Lecture du catalogue refusée ({erreur.code}) : {detail}", file=sys.stderr)
        print("Le compte doit être administrateur d'organisation.", file=sys.stderr)
        return 1

    tables = catalogue.get("tables") or []
    enums = catalogue.get("enums") or {}
    # Le catalogue nomme ses clés en français depuis le renommage : la fonction
    # `fn_schema_catalogue` émet « commentaire », non « comment ».
    commentes = sum(1 for t in tables if t.get("commentaire"))
    colonnes = sum(len(t.get("columns") or []) for t in tables)
    col_commentees = sum(1 for t in tables for c in (t.get("columns") or []) if c.get("commentaire"))

    if not tables:
        print("Catalogue vide : rien n'est écrit, pour ne pas détruire l'existant.",
              file=sys.stderr)
        return 1

    CIBLE.parent.mkdir(parents=True, exist_ok=True)
    CIBLE.write_text(json.dumps(catalogue, ensure_ascii=False, indent=1, sort_keys=True),
                     encoding="utf-8", newline="\n")

    print(f"{CIBLE.relative_to(RACINE)} écrit")
    print(f"  {len(tables)} tables, dont {commentes} commentées")
    print(f"  {colonnes} colonnes, dont {col_commentees} commentées")
    print(f"  {len(enums)} types énumérés")
    if commentes < len(tables):
        print(f"  ATTENTION : {len(tables) - commentes} table(s) sans commentaire.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
