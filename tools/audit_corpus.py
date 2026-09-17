# -*- coding: utf-8 -*-
"""Audit du corpus juridique : classement, doublons, rebuts, lacunes.

    python tools/audit_corpus.py              # constate, ne touche à rien
    python tools/audit_corpus.py --appliquer  # déplace

La taxonomie cible est fixée par le cahier des charges. Cinq répertoires, et
rien d'autre :

    convention-collectives/     conventions collectives de travail
    autres-accords-collectifs/  accords sectoriels et d'entreprise
    congés/                     congés légaux, collectifs, jours fériés
    salaires impôts/            barèmes, SSM, retenues d'impôt
    pension/                    régimes de pension

Un document qui n'entre dans aucune n'est pas supprimé : il part en quarantaine
dans `inconnu/`, à la racine du projet et hors de git. La quarantaine est
réversible ; la suppression ne l'est pas.

Restent à la racine de `lois_et_règlements/` les textes **transversaux** — le
Code du travail, le classeur des paramètres, les barèmes de préavis. Ils ne
relèvent d'aucune des cinq catégories parce que la taxonomie n'en prévoit pas
pour le socle légal : c'est une lacune, signalée en fin de rapport, et non un
classement à forcer.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

# Envelopper stdout une seule fois : deux modules qui le font à l'import se
# marchent dessus, le second détachant le tampon du premier — d'où un
# « I/O operation on closed file » au premier print du module appelant.
if (sys.stdout.encoding or "").lower().replace("-", "") != "utf8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
CORPUS = RACINE / "lois_et_règlements"
QUARANTAINE = RACINE / "inconnu"

CATEGORIES = (
    "convention-collectives",
    "autres-accords-collectifs",
    "congés",
    "salaires impôts",
    "pension",
)

# Rebuts d'éditeurs : ni documents ni sources, ils encombrent. Règle globale.
REBUTS = ("*.wbk", "~$*", "*.tmp", "*.bak", "*.old", "*.orig", "*.rej", "*.swp", "*~")

# Re-téléchargements du navigateur : « nom(1).ext » à côté de « nom.ext ».
RETELECHARGEMENTS = re.compile(r"\(\d+\)(?=\.[^.]+$)")

# Déplacements établis en lisant le contenu, jamais le seul nom de fichier.
# Chaque entrée porte sa raison : une reclassification sans motif ne se relit pas.
DEPLACEMENTS = {
    "Elements rémunération.xlsx": ("salaires impôts", "assiette cotisable par élément de paie"),
    "ccss.xlsx": ("salaires impôts", "taux de cotisation CCSS par année"),
    "voiture.xlsx": ("salaires impôts", "avantage en nature voiture, barème d'émission"),
    "salaires.docx": ("salaires impôts", "notion de salaire — page ITM"),
    # Exemplaire égaré : copie exacte de celui du dossier findel, dont il relève
    # (RGD du 15.11.2015, assistance en escale dans les aéroports).
    "eli-etat-leg-memorial-2015-a218-fr-pdf.pdf":
        ("convention-collectives/findel", "copie exacte de l'exemplaire du dossier findel"),
}

# Répertoires entiers à replacer.
DEPLACEMENTS_REP = {
    "pensions": ("pension", "la taxonomie cible dit « pension » au singulier"),
    "transport": ("convention-collectives/transport",
                  "transport.docx vient de itm.public.lu/accords-collectifs/convention-collectives"),
}

# Transversaux : aucune des cinq catégories ne les accueille. Ils restent à la
# racine du corpus, et la lacune est signalée en fin de rapport.
TRANSVERSAUX = {
    "eli-etat-leg-code-travail-20260726-fr-xml.xml":
        "Code du travail consolidé (XML — la seule version navigable par article)",
    "eli-etat-leg-code-travail-20260726-fr-html.html": "Code du travail consolidé (HTML)",
    "eli-etat-leg-code-travail-20260726-fr-pdf.pdf": "Code du travail consolidé (PDF)",
    "eli-etat-leg-code-travail-20260726-fr-docx.docx": "Code du travail consolidé (DOCX)",
    "paramètres.xlsx": "classeur des paramètres sociaux — source du moteur de calcul",
    "preavis.xlsx": "barèmes de préavis de démission et de licenciement",
}


def empreinte(f: Path) -> str | None:
    """SHA-256, ou None si le fichier est verrouillé par une application."""
    try:
        return hashlib.sha256(f.read_bytes()).hexdigest()
    except OSError:
        return None


def est_rebut(f: Path) -> bool:
    return any(f.match(motif) for motif in REBUTS)


def collecter(corpus: Path) -> tuple[list, list]:
    """Les actions à mener, et ce qui reste inexpliqué."""
    actions: list[tuple[str, Path, Path, str]] = []
    anomalies: list[str] = []

    for f in sorted(corpus.rglob("*")):
        if f.is_file() and est_rebut(f):
            actions.append(("quarantaine", f,
                            QUARANTAINE / "rebuts-editeur" / f.name,
                            "rebut d'éditeur — ni document ni source"))

    for f in sorted(corpus.rglob("*")):
        if f.is_file() and RETELECHARGEMENTS.search(f.name):
            original = f.with_name(RETELECHARGEMENTS.sub("", f.name))
            if original.exists() and empreinte(original) == empreinte(f):
                actions.append(("doublon", f, original,
                                "re-téléchargement du navigateur, identique à l'original"))

    for nom, (cible, raison) in DEPLACEMENTS_REP.items():
        src = corpus / nom
        if not src.is_dir():
            continue
        for f in sorted(src.rglob("*")):
            if f.is_file() and not est_rebut(f):
                actions.append(("répertoire", f,
                                corpus / cible / f.relative_to(src), raison))
        actions.append(("vestige", src, src, "répertoire d'origine, une fois vidé"))

    for f in sorted(corpus.glob("*")):
        if not f.is_file() or est_rebut(f):
            continue
        if f.name in DEPLACEMENTS:
            cible, raison = DEPLACEMENTS[f.name]
            actions.append(("classement", f, corpus / cible / f.name, raison))
        elif f.name not in TRANSVERSAUX:
            anomalies.append(f"racine non classée : {f.name}")

    return actions, anomalies


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit du corpus juridique.")
    parser.add_argument("--appliquer", action="store_true",
                        help="déplace réellement les fichiers")
    args = parser.parse_args()

    if not CORPUS.is_dir():
        print(f"ARRÊT — {CORPUS} est introuvable.")
        return 1

    actions, anomalies = collecter(CORPUS)

    par_somme: dict[str, list[Path]] = defaultdict(list)
    illisibles: list[Path] = []
    for f in CORPUS.rglob("*"):
        if not f.is_file() or est_rebut(f):
            continue
        s = empreinte(f)
        illisibles.append(f) if s is None else par_somme[s].append(f)
    doublons = {s: fs for s, fs in par_somme.items() if len(fs) > 1}

    print("=" * 74)
    print("AUDIT DU CORPUS JURIDIQUE")
    print("=" * 74)

    total = sum(1 for f in CORPUS.rglob("*") if f.is_file())
    print(f"\n{total} fichiers sous {CORPUS.name}/")

    print("\n--- Répartition par catégorie ---")
    for cat in CATEGORIES:
        d = CORPUS / cat
        n = sum(1 for f in d.rglob("*") if f.is_file()) if d.is_dir() else 0
        etat = "" if d.is_dir() else "   (absente)"
        print(f"  {cat:28} {n:4} fichiers{etat}")

    print(f"\n--- Actions ({len(actions)}) ---")
    if not actions:
        print("  aucune — le corpus est conforme à la taxonomie")
    for genre, src, dst, raison in actions:
        print(f"  [{genre:11}] {src.relative_to(RACINE)}")
        print(f"  {'':14}-> {dst.relative_to(RACINE)}")
        print(f"  {'':14}   {raison}")

    print(f"\n--- Transversaux, sans catégorie dans la taxonomie ({len(TRANSVERSAUX)}) ---")
    for nom, quoi in TRANSVERSAUX.items():
        present = "" if (CORPUS / nom).exists() else "  [ABSENT]"
        print(f"  {nom}{present}")
        print(f"      {quoi}")

    if doublons:
        print(f"\n--- Doublons exacts ({len(doublons)} groupes) ---")
        for fs in doublons.values():
            print(f"  {fs[0].stat().st_size // 1024} Ko :")
            for f in fs:
                print(f"      {f.relative_to(RACINE)}")

    if illisibles:
        print(f"\n--- Illisibles ({len(illisibles)}) ---")
        for f in illisibles:
            print(f"  {f.relative_to(RACINE)} — verrouillé par une application ?")

    if anomalies:
        print(f"\n--- À examiner ({len(anomalies)}) ---")
        for a in anomalies:
            print(f"  {a}")

    if not args.appliquer:
        print("\nConstat seul. Pour appliquer :  python tools/audit_corpus.py --appliquer")
        return 0

    print("\n--- Application ---")
    faits = 0
    for genre, src, dst, _raison in actions:
        if not src.exists():
            continue
        if genre == "vestige":
            restants = [f for f in src.rglob("*") if f.is_file()]
            if restants:
                print(f"  vestige conservé : {src.relative_to(RACINE)} "
                      f"— {len(restants)} fichier(s) n'ont pas pu être déplacés")
            else:
                try:
                    shutil.rmtree(src)
                    print(f"  vestige vide supprimé : {src.relative_to(RACINE)}")
                    faits += 1
                except OSError as e:
                    print(f"  vestige verrouillé : {src.relative_to(RACINE)} — {e.strerror}")
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists() and dst.is_file() and src.is_file():
            if empreinte(src) is not None and empreinte(src) == empreinte(dst):
                try:
                    src.unlink()
                    print(f"  doublon supprimé : {src.relative_to(RACINE)}")
                    faits += 1
                except OSError as e:
                    print(f"  doublon verrouillé : {src.relative_to(RACINE)} — {e.strerror}")
            else:
                print(f"  CONFLIT, ignoré : {dst.relative_to(RACINE)} existe et diffère")
            continue
        try:
            shutil.move(str(src), str(dst))
            print(f"  {src.relative_to(RACINE)} -> {dst.relative_to(RACINE)}")
            faits += 1
        except OSError as e:
            print(f"  ÉCHEC : {src.relative_to(RACINE)} — {e.strerror}")
    print(f"\n{faits} action(s) effectuée(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
