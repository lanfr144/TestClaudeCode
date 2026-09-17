# -*- coding: utf-8 -*-
"""Tout le projet en UTF-8, sans marque d'ordre d'octets.

    python tools/normaliser_encodage.py              # constate
    python tools/normaliser_encodage.py --appliquer  # convertit

Pourquoi cela compte ici plus qu'ailleurs : ce projet est écrit en français, et
ses données le sont aussi. « Indemnité funéraire », « séjour à l'hôpital »,
« dépendance » traversent le code, les migrations, le SQL portable et la
documentation. Un fichier en CP1252 au milieu d'un dépôt en UTF-8 ne se voit pas
tant qu'on le lit sous Windows ; il se voit dans le conteneur Linux, dans la
base, ou dans le diff — au moment le moins commode.

La détection ne devine pas : elle **essaie**, dans l'ordre du plus strict au plus
permissif. UTF-8 est très contraint — une séquence d'octets qui s'y décode
proprement n'est presque jamais du CP1252 déguisé. L'inverse est faux : CP1252
accepte n'importe quel octet, et déclarerait valide un fichier UTF-8 abîmé. C'est
pourquoi UTF-8 passe en premier, et pourquoi un fichier qui ne s'y décode pas est
converti plutôt que laissé tel quel.
"""
from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

# Envelopper stdout une seule fois : deux modules qui le font à l'import se
# marchent dessus, le second détachant le tampon du premier — d'où un
# « I/O operation on closed file » au premier print du module appelant.
if (sys.stdout.encoding or "").lower().replace("-", "") != "utf8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent

# Ce qui est du texte, et que le dépôt versionne.
EXTENSIONS = {
    ".py", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".json", ".sql",
    ".md", ".txt", ".yml", ".yaml", ".toml", ".ini", ".cfg", ".env", ".example",
    ".sh", ".bash", ".html", ".css", ".xml", ".csv", ".ttl", ".gitignore",
    ".dockerignore", ".editorconfig",
}
SANS_EXTENSION = {"Dockerfile", ".gitignore", ".dockerignore", ".gitattributes",
                  ".editorconfig", "Makefile"}

# Ce qu'on ne touche pas : dépendances, binaires, corpus sous licence.
EXCLUS = {
    "node_modules", ".venv", "__pycache__", ".git", "dist", "build", ".vite",
    "lois_et_règlements", "inconnu", "video", "discussion", ".pytest_cache",
    "docker/volumes", ".thumbnail",
}

# Essayés dans cet ordre. `utf-8-sig` avant `utf-8` pour repérer la marque.
CANDIDATS = ("utf-8-sig", "utf-8", "cp1252", "latin-1")


def concerne(f: Path) -> bool:
    if any(part in EXCLUS for part in f.parts):
        return False
    return f.suffix.lower() in EXTENSIONS or f.name in SANS_EXTENSION


def detecter(octets: bytes) -> tuple[str | None, str | None]:
    """Rend (encodage retenu, raison du rejet des précédents)."""
    if octets.startswith(b"\xef\xbb\xbf"):
        return "utf-8-sig", None
    for enc in ("utf-8", "cp1252", "latin-1"):
        try:
            octets.decode(enc)
            return enc, None
        except UnicodeDecodeError:
            continue
    return None, "aucun encodage candidat ne décode ce fichier"


def main() -> int:
    p = argparse.ArgumentParser(description="Normalise l'encodage en UTF-8.")
    p.add_argument("--appliquer", action="store_true", help="réécrit les fichiers")
    args = p.parse_args()

    a_convertir: list[tuple[Path, str]] = []
    deja: list[Path] = []
    illisibles: list[Path] = []
    non_ascii_pur: list[Path] = []

    for f in sorted(RACINE.rglob("*")):
        if not f.is_file() or not concerne(f):
            continue
        try:
            octets = f.read_bytes()
        except OSError:
            illisibles.append(f)
            continue

        if not octets:
            continue

        enc, _ = detecter(octets)
        if enc is None:
            illisibles.append(f)
        elif enc == "utf-8":
            # Un fichier purement ASCII est déjà de l'UTF-8 valide ; rien à faire.
            deja.append(f)
            try:
                octets.decode("ascii")
            except UnicodeDecodeError:
                non_ascii_pur.append(f)
        else:
            a_convertir.append((f, enc))

    print("=" * 74)
    print("ENCODAGE DU PROJET")
    print("=" * 74)
    print(f"\n{len(deja) + len(a_convertir)} fichier(s) texte examinés.")
    print(f"  déjà en UTF-8        : {len(deja)}"
          f"  (dont {len(non_ascii_pur)} portant des caractères accentués)")
    print(f"  à convertir          : {len(a_convertir)}")
    print(f"  illisibles           : {len(illisibles)}")

    if a_convertir:
        print(f"\n--- À convertir ({len(a_convertir)}) ---")
        for f, enc in a_convertir:
            motif = "marque d'ordre d'octets à retirer" if enc == "utf-8-sig" else f"décodé en {enc}"
            print(f"  {f.relative_to(RACINE)}  —  {motif}")

    if illisibles:
        print(f"\n--- Illisibles ({len(illisibles)}) ---")
        for f in illisibles:
            print(f"  {f.relative_to(RACINE)}")

    if not args.appliquer:
        if a_convertir:
            print("\nConstat seul. Pour convertir :  --appliquer")
        else:
            print("\nTout le projet est déjà en UTF-8 sans marque d'ordre d'octets.")
        return 0

    print(f"\n--- Conversion ---")
    faits = 0
    for f, enc in a_convertir:
        try:
            texte = f.read_bytes().decode(enc)
            # `newline=""` : on ne touche pas aux fins de ligne. Git s'en charge,
            # et les convertir ici ferait un diff illisible mêlant deux sujets.
            with open(f, "w", encoding="utf-8", newline="") as sortie:
                sortie.write(texte)
            print(f"  {f.relative_to(RACINE)}  ({enc} -> utf-8)")
            faits += 1
        except OSError as e:
            print(f"  ÉCHEC : {f.relative_to(RACINE)} — {e.strerror}")

    print(f"\n{faits} fichier(s) converti(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
