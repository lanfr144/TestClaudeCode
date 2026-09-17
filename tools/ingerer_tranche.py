# -*- coding: utf-8 -*-
"""Détecte une nouvelle tranche indiciaire dans le classeur et l'intègre.

    python tools/ingerer_tranche.py                    # que manque-t-il en base ?
    python tools/ingerer_tranche.py --ecrire           # écrit la migration du delta
    python tools/ingerer_tranche.py --ecrire --appliquer-avec-supabase

À chaque indexation, le classeur reçoit une colonne datée de plus. Ce script
compare les dates du classeur à celles déjà chargées et ne s'occupe que de
l'écart. Il ne devine rien : il interroge la base.

Pourquoi un script plutôt qu'une procédure notée quelque part : une indexation
arrive tous les huit à dix-huit mois. Personne ne se souvient, dix-huit mois
plus tard, des quatre commandes à enchaîner ni de l'ordre. Un geste oublié ici
se traduit par des salaires minimaux périmés que rien ne signale.

Le chargement lui-même reste l'affaire de `charger_parametres.py` : un seul
endroit sait lire le classeur, et c'est déjà beaucoup.
"""
from __future__ import annotations

import argparse
import datetime as dt
import io
import subprocess
import sys
from pathlib import Path

# Envelopper stdout une seule fois : deux modules qui le font à l'import se
# marchent dessus, le second détachant le tampon du premier — d'où un
# « I/O operation on closed file » au premier print du module appelant.
if (sys.stdout.encoding or "").lower().replace("-", "") != "utf8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "tools"))


def dates_du_classeur() -> list[dt.date]:
    from charger_parametres import CLASSEUR, COLONNES_DE_TRAVAIL, lire_classeur
    dates, _ = lire_classeur(CLASSEUR)
    return sorted({d for col, d in dates.items() if col not in COLONNES_DE_TRAVAIL})


def dates_en_base() -> set[dt.date]:
    """Les dates d'effet déjà chargées depuis le classeur."""
    from exporter_donnees_reference import lire_env, jeton, lire_table
    env = lire_env()
    token = jeton(env)
    lignes = lire_table(env, token, "parametres_legaux")
    return {dt.date.fromisoformat(l["debut_validite"])
            for l in lignes if l.get("source") == "paramètres.xlsx"}


def main() -> int:
    p = argparse.ArgumentParser(description="Ingère une nouvelle tranche indiciaire.")
    p.add_argument("--ecrire", action="store_true",
                   help="écrit la migration couvrant les dates manquantes")
    p.add_argument("--horizon", help="force l'horizon plutôt que de le déduire")
    args = p.parse_args()

    classeur = dates_du_classeur()
    print("=" * 74)
    print("TRANCHES INDICIAIRES")
    print("=" * 74)
    print(f"\nLe classeur porte {len(classeur)} date(s) d'effet :")
    print("  " + ", ".join(str(d) for d in classeur))

    try:
        base = dates_en_base()
    except Exception as e:
        print(f"\nLa base n'a pas répondu ({type(e).__name__}) — comparaison impossible.")
        print("Renseigner luxrh/.env.local, ou forcer l'horizon avec --horizon.")
        return 1

    print(f"\nLa base porte {len(base)} date(s) issue(s) du classeur :")
    print("  " + (", ".join(str(d) for d in sorted(base)) or "aucune"))

    manquantes = [d for d in classeur if d not in base]
    if not manquantes:
        print("\nRien à ingérer : toutes les tranches du classeur sont chargées.")
        return 0

    print(f"\n--- {len(manquantes)} tranche(s) absente(s) de la base ---")
    for d in manquantes:
        print(f"  {d}")

    horizon = args.horizon or str(max(manquantes))
    print(f"\nHorizon retenu : {horizon}")
    print("  Le chargeur reprend tout le lot jusqu'à cette date — le rechargement")
    print("  est idempotent, et reprendre l'ensemble évite qu'une correction")
    print("  apportée à une tranche ancienne reste ignorée.")

    if not args.ecrire:
        print(f"\nPour écrire la migration :")
        print(f"  python tools/charger_parametres.py --horizon {horizon} --ecrire")
        print("\nPuis appliquer la migration, et enfin :")
        print("  python tools/dump_migrations.py --ecrire")
        print("  python tools/verifier_coherence.py")
        return 0

    commande = [sys.executable, str(RACINE / "tools" / "charger_parametres.py"),
                "--horizon", horizon, "--ecrire"]
    print(f"\n--- {' '.join(commande[1:])} ---")
    resultat = subprocess.run(commande, cwd=RACINE)
    if resultat.returncode != 0:
        return resultat.returncode

    print("\nMigration écrite. Il reste à :")
    print("  1. la relire — surtout les valeurs de la nouvelle tranche ;")
    print("  2. l'appliquer ;")
    print("  3. python tools/dump_migrations.py --ecrire")
    print("  4. python tools/verifier_coherence.py")
    print("  5. cd luxrh && npm test")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
