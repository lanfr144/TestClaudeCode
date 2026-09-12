"""Écrit dans le dépôt les migrations appliquées qui n'y ont pas de fichier.

    luxrh-py/.venv/Scripts/python tools/dump_migrations.py            # liste seulement
    luxrh-py/.venv/Scripts/python tools/dump_migrations.py --ecrire   # écrit les manquantes

Pourquoi cet outil existe
-------------------------
Le dépôt et la base ont divergé une fois : cinq migrations (45 à 45e) étaient
appliquées sans fichier, et il a fallu les reconstituer à la main en vérifiant
les empreintes MD5. Rien n'empêchait que cela se reproduise, puisque remettre
une migration dans le dépôt supposait de la retaper.

Cet outil rend l'opération mécanique. Il ne remplace jamais un fichier existant :
une migration appliquée ne se réécrit pas, c'est la convention du projet. Il
n'écrit que ce qui manque, et signale ce qui diffère.

Ce qu'il vérifie
----------------
Pour chaque migration ayant déjà un fichier, il compare le SQL appliqué au
contenu du fichier et signale les écarts — sans y toucher. Un écart n'est pas
forcément un défaut : un fichier peut porter un en-tête de commentaires absent
du SQL appliqué. Mais il doit être vu.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
ENV = RACINE / "luxrh" / ".env.local"
MIGRATIONS = RACINE / "luxrh" / "supabase" / "migrations"


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


def poster(url: str, entetes: dict[str, str], corps: dict):
    requete = urllib.request.Request(
        url,
        data=json.dumps(corps).encode("utf-8"),
        headers={**entetes, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(requete, timeout=60) as reponse:
        return json.loads(reponse.read().decode("utf-8"))


def index_du_depot() -> tuple[dict[str, Path], dict[str, Path]]:
    """Les fichiers du dépôt, indexés par horodatage **et** par nom de migration.

    L'appariement par horodatage seul ne suffit pas : quand une migration est
    appliquée par le connecteur, la plateforme lui attribue l'horodatage de
    l'application, qui n'est pas celui choisi pour le nom du fichier. La
    migration `64d_premium_unit_as_reference_table` porte ainsi `20260912070000`
    dans le dépôt et `20260912045836` en base. Comparer les horodatages faisait
    donc passer pour « absentes » quarante migrations qui étaient là.

    C'est le nom qui identifie une migration, pas la date à laquelle elle a été
    jouée. L'horodatage reste consulté en premier — il est plus sûr quand il
    concorde — mais le nom tranche ensuite.
    """
    par_version: dict[str, Path] = {}
    par_nom: dict[str, Path] = {}
    for chemin in MIGRATIONS.glob("*.sql"):
        m = re.match(r"^(\d{14})_(.+)\.sql$", chemin.name)
        if m:
            par_version[m.group(1)] = chemin
            par_nom[m.group(2).lower()] = chemin
        else:
            # Fichier écrit avant application, sans horodatage : on ne connaît pas
            # encore la version que la plateforme lui donnera. Il s'indexe par son
            # seul nom, et le renommage lui attribuera la version appliquée.
            par_nom.setdefault(chemin.stem.lower(), chemin)
    return par_version, par_nom


def reparer_liens(renommes: dict[str, str]) -> int:
    """Fait suivre à la documentation les fichiers qu'on vient de renommer.

    Plusieurs documents citent une migration par son chemin complet, horodatage
    compris. Renommer le fichier casse le lien — et un lien cassé dans une
    documentation se remarque tard, quand quelqu'un le suit. L'outil qui provoque
    la casse est le mieux placé pour la réparer dans le même geste.
    """
    corriges = 0
    cibles = list((RACINE / "docs").glob("*.md")) + [RACINE / "CLAUDE.md"]
    for md in cibles:
        if not md.exists():
            continue
        texte = md.read_text(encoding="utf-8")
        avant = texte
        for ancien, nouveau in renommes.items():
            if ancien in texte:
                texte = texte.replace(ancien, nouveau)
                corriges += 1
        if texte != avant:
            md.write_text(texte, encoding="utf-8", newline="\n")
    return corriges


def main() -> int:
    ecrire = "--ecrire" in sys.argv
    env = lire_env()
    base = parametre("VITE_SUPABASE_URL", env)
    cle = parametre("VITE_SUPABASE_ANON_KEY", env)
    courriel = parametre("LUXRH_ADMIN_EMAIL", env) or "demo@luxrh.lu"
    motdepasse = (parametre("LUXRH_ADMIN_PASSWORD", env)
                  or parametre("LUXRH_MANAGER_PASSWORD", env))

    if not (base and cle and motdepasse):
        print("Configuration incomplète : VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY et "
              "LUXRH_ADMIN_PASSWORD (ou LUXRH_MANAGER_PASSWORD).", file=sys.stderr)
        return 1

    try:
        jeton = poster(f"{base}/auth/v1/token?grant_type=password", {"apikey": cle},
                       {"email": courriel, "password": motdepasse})["access_token"]
        entetes = {"apikey": cle, "Authorization": f"Bearer {jeton}"}
        # Lister d'abord — léger. Le SQL ne sera demandé que pour ce qui manque :
        # tout renvoyer d'un bloc faisait expirer la passerelle en 504.
        migrations = poster(f"{base}/rest/v1/rpc/fn_migrations_list", entetes, {})
    except urllib.error.HTTPError as erreur:
        print(f"Lecture refusée ({erreur.code}) : "
              f"{erreur.read().decode('utf-8', 'replace')[:200]}", file=sys.stderr)
        print("Le compte doit être administrateur d'organisation.", file=sys.stderr)
        return 1
    except Exception as erreur:                      # noqa: BLE001
        print(f"Échec : {erreur}", file=sys.stderr)
        return 1

    par_version, par_nom = index_du_depot()
    manquantes, ecarts, alignees = [], [], 0

    def source(version: str) -> str:
        return poster(f"{base}/rest/v1/rpc/fn_migration_source", entetes,
                      {"p_version": version}) or ""

    for m in migrations:
        version, nom = m["version"], m["name"]
        chemin = par_version.get(version) or par_nom.get(nom.lower())
        if chemin is None:
            manquantes.append((version, nom, source(version)))
            continue
        contenu = chemin.read_text(encoding="utf-8")
        sql = source(version)
        # Le fichier peut porter un en-tête de commentaires absent du SQL appliqué :
        # on compare le SQL utile, lignes de commentaire retirées de part et d'autre.
        def utile(t: str) -> str:
            return "\n".join(l for l in t.splitlines()
                             if l.strip() and not l.lstrip().startswith("--")).strip()
        if utile(contenu) == utile(sql):
            alignees += 1
        else:
            ecarts.append((version, nom, chemin))

    # Un fichier dont le nom concorde mais dont l'horodatage diffère de la version
    # appliquée est le défaut le plus dangereux du lot : `supabase db push` compare
    # les versions, pas les noms. Il verrait une migration inconnue et la rejouerait
    # sur une base qui l'a déjà. Le fichier n'est pas à réécrire — il est à renommer
    # sur la version que la base a enregistrée.
    mal_datees = []
    for m in migrations:
        chemin = par_nom.get(m["name"].lower())
        if chemin and not chemin.name.startswith(m["version"]):
            mal_datees.append((m["version"], m["name"], chemin))

    print(f"{len(migrations)} migration(s) appliquée(s)")
    print(f"  alignées avec le dépôt : {alignees}")
    print(f"  sans fichier           : {len(manquantes)}")
    print(f"  fichier divergent      : {len(ecarts)}")
    print(f"  horodatage à corriger  : {len(mal_datees)}")

    for version, nom, chemin in mal_datees:
        print(f"    ! {chemin.name} -> {version}_{nom}.sql")
    if mal_datees:
        print("      (db push rejouerait ces migrations : leur version est absente de")
        print("       schema_migrations. Renommer, jamais réécrire.)")
        if ecrire:
            renommes = {}
            for version, nom, chemin in mal_datees:
                cible = chemin.with_name(f"{version}_{nom}.sql")
                chemin.rename(cible)
                renommes[chemin.name] = cible.name
            print(f"      {len(mal_datees)} fichier(s) renommé(s).")
            n = reparer_liens(renommes)
            if n:
                print(f"      {n} lien(s) de documentation suivi(s).")

    for version, nom, chemin in ecarts:
        print(f"    ~ {version}_{nom} -> {chemin.name}")
    if ecarts:
        print("      (un écart n'est pas forcément un défaut : un fichier peut porter")
        print("       des commentaires absents du SQL appliqué. À regarder, pas à corriger")
        print("       automatiquement — une migration appliquée ne se réécrit pas.)")

    # Le contrôle inverse : un fichier que la base ne connaît pas. `db push`
    # l'appliquerait. C'est légitime pour une migration en attente, et c'est un
    # piège pour un fichier récapitulatif écrit après coup — la 44 consolidée
    # rejouerait ce que 44a et 44b ont déjà fait.
    connus = {m["version"] for m in migrations}
    orphelins = sorted(c.name for v, c in par_version.items() if v not in connus)
    print(f"  fichier non appliqué   : {len(orphelins)}")
    for nom in orphelins:
        print(f"    ? {nom}")
    if orphelins:
        print("      (db push les appliquerait. Vérifier que ce sont bien des migrations")
        print("       en attente, et non un doublon de ce qui est déjà en base.)")

    if not manquantes:
        print("\nRien à écrire : le dépôt porte toutes les migrations appliquées.")
        return 0

    for version, nom, sql in manquantes:
        cible = MIGRATIONS / f"{version}_{nom}.sql"
        print(f"    + {cible.name}")
        if ecrire:
            cible.write_text(sql.rstrip() + "\n", encoding="utf-8", newline="\n")

    if not ecrire:
        print("\nRelancer avec --ecrire pour créer ces fichiers.")
    else:
        print(f"\n{len(manquantes)} fichier(s) écrit(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
