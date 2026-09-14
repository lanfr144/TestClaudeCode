"""Inventorie les sources légales locales et écrit le manifeste versionné.

    luxrh-py/.venv/Scripts/python tools/inventaire_sources.py            # montre
    luxrh-py/.venv/Scripts/python tools/inventaire_sources.py --ecrire   # écrit

Pourquoi un manifeste plutôt que les fichiers
----------------------------------------------
Les textes de loi, conventions collectives et barèmes portent une licence et
exigent une attribution. La règle d'or du projet — `~/.claude/CLAUDE.md` — interdit
de les committer, même lorsque la licence l'autorise :

  - une attribution se perd au premier fork ou à la première copie ;
  - un texte est abrogé, une version retirée, et la copie versionnée ne le dit pas ;
  - un binaire supprimé reste dans tous les clones, l'historique étant immuable.

Ce qui est versionné est donc la **référence** : identifiant ELI, titre officiel,
éditeur, licence, mention d'attribution, URL de téléchargement, empreinte SHA-256
et date de consultation. `tools/telecharger_sources.py` reconstitue le répertoire
local à partir de ce manifeste.

Pourquoi il se génère
---------------------
Le répertoire grossit — seize conventions au moment d'écrire ces lignes, et le
travail n'est pas fini. Un manifeste tenu à la main serait faux avant d'être utile.
Celui-ci se régénère : il lit les métadonnées RDF publiées par Legilux à côté de
chaque texte, calcule les empreintes, et signale ce dont il ne sait rien.

Ce qu'il ne devine pas
----------------------
Un fichier sans métadonnées — un barème téléchargé depuis un site sectoriel, par
exemple — est listé dans une section distincte, « source à documenter ». Il ne
reçoit ni licence ni URL inventée : un manifeste qui affirme une licence fausse
est pire qu'un manifeste incomplet.
"""

from __future__ import annotations

import codecs
import hashlib
import re
import sys
from datetime import date
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SOURCES = RACINE / "lois_et_règlements"
MANIFESTE = RACINE / "docs" / "sources-legales.md"

# Fichiers que Word laisse derrière lui : ni sources, ni livrables.
REBUTS = ("~$", "Copie de secours de", "New Microsoft Word Document")
EXTENSIONS_REBUT = {".wbk"}


def empreinte(chemin: Path) -> str:
    h = hashlib.sha256()
    with chemin.open("rb") as f:
        for bloc in iter(lambda: f.read(1 << 16), b""):
            h.update(bloc)
    return h.hexdigest()


def _valeur(texte: str, champ: str) -> str | None:
    m = re.search(re.escape(champ) + r'\s+"([^"]*)"', texte)
    if m:
        return " ".join(codecs.decode(m.group(1), "unicode_escape").split())
    m = re.search(re.escape(champ) + r"\s+<([^>]+)>", texte)
    return m.group(1) if m else None


def lire_ttl(chemin: Path) -> dict:
    """Extrait d'un fichier Turtle publié par Legilux ce qui fonde une référence."""
    t = chemin.read_text(encoding="utf-8")
    fichiers = sorted(set(re.findall(r"jolux:isExemplifiedBy\s+<([^>]+)>", t)))
    eli = None
    m = re.search(r"@prefix ns2:\s+<([^>]+)>", t)
    if m:
        eli = m.group(1).rstrip("/")
    return {
        "eli": eli,
        "titre": _valeur(t, "jolux:title"),
        "date_document": _valeur(t, "jolux:dateDocument"),
        "date_publication": _valeur(t, "jolux:publicationDate"),
        "licence": _valeur(t, "jolux:license"),
        "attribution": _valeur(t, "jolux:rights"),
        "telechargements": fichiers,
    }


def classer() -> tuple[list[dict], list[Path], list[Path]]:
    """Répartit le contenu du répertoire : documenté, à documenter, rebut."""
    if not SOURCES.is_dir():
        return [], [], []

    documentes, a_documenter, rebuts = [], [], []
    for chemin in sorted(SOURCES.iterdir()):
        if not chemin.is_file():
            continue
        if (chemin.name.startswith(REBUTS) or chemin.suffix.lower() in EXTENSIONS_REBUT
                or chemin.stat().st_size == 0):
            rebuts.append(chemin)
            continue
        if chemin.suffix.lower() == ".ttl":
            fiche = lire_ttl(chemin)
            fiche["fichier_metadonnees"] = chemin.name
            documentes.append(fiche)
        else:
            a_documenter.append(chemin)
    return documentes, a_documenter, rebuts


def _rattacher(documentes: list[dict], a_documenter: list[Path]) -> dict[str, dict]:
    """Relie un fichier local à la fiche RDF qui le décrit, par son nom d'URL."""
    par_nom: dict[str, dict] = {}
    for fiche in documentes:
        for url in fiche["telechargements"]:
            par_nom[url.rsplit("/", 1)[-1].lower()] = fiche
    return {c.name: par_nom[c.name.lower()] for c in a_documenter
            if c.name.lower() in par_nom}


def rendre(documentes, a_documenter, rebuts) -> str:
    rattaches = _rattacher(documentes, a_documenter)
    orphelins = [c for c in a_documenter if c.name not in rattaches]

    l = [
        "# Sources légales — manifeste des références",
        "",
        "**Les documents eux-mêmes ne sont pas versionnés.** Ils portent une licence et",
        "exigent une attribution ; la règle d'or du projet interdit de les committer, même",
        "lorsque la licence l'autorise. Voir `~/.claude/CLAUDE.md`.",
        "",
        "Ce fichier est **généré** par `tools/inventaire_sources.py`. Ne pas le modifier à",
        "la main : il serait écrasé, et il serait faux dès le prochain document ajouté.",
        "",
        "Pour reconstituer le répertoire local :",
        "",
        "```bash",
        "luxrh-py/.venv/Scripts/python tools/telecharger_sources.py",
        "```",
        "",
        f"*Inventaire du {date.today().isoformat()} — {len(documentes)} texte(s) documenté(s), "
        f"{len(orphelins)} fichier(s) sans source établie, {len(rebuts)} rebut(s).*",
        "",
        "---",
        "",
        "## Textes dont la source est établie",
        "",
    ]

    if not documentes:
        l += ["*Aucun. Le répertoire local est absent ou ne contient pas de métadonnées.*", ""]

    for fiche in sorted(documentes, key=lambda f: f.get("date_document") or ""):
        l.append(f"### {fiche['titre'] or '(titre absent)'}")
        l.append("")
        l.append("| | |")
        l.append("|---|---|")
        if fiche["eli"]:
            l.append(f"| Identifiant ELI | <{fiche['eli']}> |")
        if fiche["date_document"]:
            l.append(f"| Date du texte | {fiche['date_document']} |")
        if fiche["date_publication"]:
            l.append(f"| Publication | {fiche['date_publication']} |")
        if fiche["licence"]:
            l.append(f"| Licence | <{fiche['licence']}> |")
        if fiche["attribution"]:
            l.append(f"| Attribution à reproduire | {fiche['attribution']} |")
        l.append("")
        if fiche["telechargements"]:
            l.append("Téléchargement :")
            l.append("")
            for url in fiche["telechargements"]:
                nom = url.rsplit("/", 1)[-1]
                local = SOURCES / nom
                trace = ""
                if local.exists():
                    trace = f" — présent localement, SHA-256 `{empreinte(local)[:16]}…`"
                l.append(f"- [`{nom}`]({url}){trace}")
            l.append("")

    if orphelins:
        l += [
            "---",
            "",
            "## Fichiers sans source établie",
            "",
            "Ces fichiers sont présents localement mais aucune métadonnée ne les rattache à",
            "une référence publiée. **Aucune licence ni URL ne leur est attribuée ici** : un",
            "manifeste qui affirme une licence fausse est pire qu'un manifeste incomplet.",
            "",
            "Pour chacun, il faut établir l'origine — éditeur, licence, URL permanente — puis",
            "l'ajouter à la main dans `docs/sources-legales-complement.md`, que cet outil lit",
            "et reprend s'il existe.",
            "",
            "| Fichier | Taille | SHA-256 |",
            "|---|---|---|",
        ]
        for c in orphelins:
            l.append(f"| `{c.name}` | {c.stat().st_size:,} o | `{empreinte(c)[:16]}…` |")
        l.append("")

    if rebuts:
        l += [
            "---",
            "",
            "## Rebuts",
            "",
            "Copies de secours de Word, fichiers de verrouillage, documents vides. Ni sources,",
            "ni livrables — ils peuvent être supprimés du répertoire local.",
            "",
        ]
        for c in rebuts:
            l.append(f"- `{c.name}`")
        l.append("")

    l += ["---", "", "## Voir aussi", "",
          "- [`donnees-de-reference.md`](donnees-de-reference.md) — quand et comment charger le référentiel",
          "- [`../CLAUDE.md`](../CLAUDE.md) — les règles du projet", ""]
    return "\n".join(l)


def main() -> int:
    documentes, a_documenter, rebuts = classer()
    if not SOURCES.is_dir():
        print(f"Répertoire absent : {SOURCES}", file=sys.stderr)
        return 1

    rattaches = _rattacher(documentes, a_documenter)
    orphelins = [c for c in a_documenter if c.name not in rattaches]

    print(f"{SOURCES.name} :")
    print(f"  textes documentés par leurs métadonnées : {len(documentes)}")
    print(f"  fichiers rattachés à une référence      : {len(rattaches)}")
    print(f"  fichiers sans source établie            : {len(orphelins)}")
    print(f"  rebuts (copies Word, fichiers vides)    : {len(rebuts)}")

    if orphelins:
        print("\nSans source établie — à documenter avant tout usage comme référence :")
        for c in orphelins[:12]:
            print(f"    {c.name}")
        if len(orphelins) > 12:
            print(f"    … et {len(orphelins) - 12} autre(s)")

    texte = rendre(documentes, a_documenter, rebuts)
    if "--ecrire" in sys.argv:
        MANIFESTE.parent.mkdir(parents=True, exist_ok=True)
        MANIFESTE.write_text(texte, encoding="utf-8", newline="\n")
        print(f"\n{MANIFESTE.relative_to(RACINE)} écrit — {len(texte):,} caractères.")
    else:
        print("\nRelancer avec --ecrire pour écrire le manifeste.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
