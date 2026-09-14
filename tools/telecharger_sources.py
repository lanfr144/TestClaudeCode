"""Reconstitue le répertoire des sources légales à partir du manifeste versionné.

    luxrh-py/.venv/Scripts/python tools/telecharger_sources.py            # montre
    luxrh-py/.venv/Scripts/python tools/telecharger_sources.py --telecharger

Pourquoi cet outil existe
-------------------------
Les textes de loi et les conventions collectives ne sont pas versionnés : ils
portent une licence et exigent une attribution. Le dépôt garde la **référence** —
`docs/sources-legales.md` — et cet outil reconstitue le répertoire local à partir
d'elle.

Qui clone le dépôt retrouve donc les documents en une commande, **depuis la source
officielle**, ce qui vaut mieux qu'une copie figée : si un texte a été modifié
depuis, on obtient la version en vigueur, et l'empreinte enregistrée le signale.

Ce qu'il vérifie
----------------
Chaque fichier téléchargé est comparé à l'empreinte SHA-256 notée au manifeste.
Trois issues, et aucune n'est silencieuse :

  identique  — le document n'a pas bougé ;
  DIFFÉRENT  — le texte a été republié depuis l'inventaire. Ce n'est pas une
               erreur, c'est une information : une convention a peut-être été
               modifiée, et les valeurs qu'on en a tirées sont à revérifier ;
  absent     — le document n'était pas présent lors de l'inventaire.

Ce qu'il ne fait pas
--------------------
Il ne télécharge que ce que le manifeste référence. Les fichiers listés en
« source à documenter » n'ont ni URL ni licence établie : les récupérer supposerait
de deviner leur origine, et une provenance inventée est pire qu'un fichier absent.
"""

from __future__ import annotations

import hashlib
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
MANIFESTE = RACINE / "docs" / "sources-legales.md"
CIBLE = RACINE / "lois_et_règlements"

# Les lignes de téléchargement du manifeste : « - [`nom`](url) — … SHA-256 `xxx…` »
LIGNE = re.compile(
    r"^- \[`(?P<nom>[^`]+)`\]\((?P<url>[^)]+)\)"
    r"(?:.*?SHA-256 `(?P<empreinte>[0-9a-f]+)…`)?", re.M)


def empreinte(chemin: Path) -> str:
    h = hashlib.sha256()
    with chemin.open("rb") as f:
        for bloc in iter(lambda: f.read(1 << 16), b""):
            h.update(bloc)
    return h.hexdigest()


def entrees() -> list[dict]:
    if not MANIFESTE.exists():
        return []
    texte = MANIFESTE.read_text(encoding="utf-8")
    # On s'arrête avant la section des fichiers sans source : ils n'ont pas d'URL.
    coupure = texte.find("## Fichiers sans source établie")
    if coupure > 0:
        texte = texte[:coupure]
    vues, sortie = set(), []
    for m in LIGNE.finditer(texte):
        if m.group("nom") in vues:
            continue
        vues.add(m.group("nom"))
        sortie.append({"nom": m.group("nom"), "url": m.group("url"),
                       "empreinte": m.group("empreinte")})
    return sortie


def main() -> int:
    telecharger = "--telecharger" in sys.argv
    liste = entrees()

    if not liste:
        print(f"Aucune entrée dans {MANIFESTE.relative_to(RACINE)}.", file=sys.stderr)
        print("Lancer d'abord : tools/inventaire_sources.py --ecrire", file=sys.stderr)
        return 1

    CIBLE.mkdir(parents=True, exist_ok=True)
    print(f"{len(liste)} document(s) référencé(s) au manifeste.\n")

    a_prendre, identiques, differents = [], 0, []
    for e in liste:
        local = CIBLE / e["nom"]
        if not local.exists():
            a_prendre.append(e)
            continue
        if e["empreinte"] and not empreinte(local).startswith(e["empreinte"]):
            differents.append(e["nom"])
        else:
            identiques += 1

    print(f"  déjà présents et identiques : {identiques}")
    print(f"  absents localement          : {len(a_prendre)}")
    print(f"  présents mais DIFFÉRENTS    : {len(differents)}")
    for nom in differents:
        print(f"      {nom}")
    if differents:
        print("      (le texte a été republié depuis l'inventaire — les valeurs")
        print("       qui en ont été tirées sont à revérifier)")

    if not a_prendre:
        print("\nRien à télécharger.")
        return 0

    if not telecharger:
        print("\nÀ télécharger :")
        for e in a_prendre[:15]:
            print(f"    {e['nom']}")
        if len(a_prendre) > 15:
            print(f"    … et {len(a_prendre) - 15} autre(s)")
        print("\nRelancer avec --telecharger.")
        return 0

    print()
    pris, echecs = 0, []
    for e in a_prendre:
        cible = CIBLE / e["nom"]
        try:
            requete = urllib.request.Request(
                e["url"], headers={"User-Agent": "LuxRH/1.0 (inventaire de sources)"})
            with urllib.request.urlopen(requete, timeout=120) as r:
                cible.write_bytes(r.read())
            marque = ""
            if e["empreinte"] and not empreinte(cible).startswith(e["empreinte"]):
                marque = "  ← empreinte différente de l'inventaire"
            print(f"    pris  {e['nom']}{marque}")
            pris += 1
        except (urllib.error.URLError, OSError) as erreur:
            echecs.append((e["nom"], str(erreur)[:90]))
            print(f"    ÉCHEC {e['nom']} — {str(erreur)[:90]}")

    print(f"\n{pris} téléchargé(s), {len(echecs)} en échec.")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
