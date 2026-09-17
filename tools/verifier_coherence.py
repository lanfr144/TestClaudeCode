"""Vérifie que le dépôt, la base et la documentation racontent la même histoire.

    luxrh-py/.venv/Scripts/python tools/verifier_coherence.py

Pourquoi cet outil existe
-------------------------
LuxRH tient en quatre morceaux qui peuvent dériver l'un de l'autre sans que rien
ne proteste : les migrations du dépôt, le schéma réellement déployé, les deux
interfaces qui appellent le moteur, et la documentation qui décrit le tout.

Chaque dérive rencontrée jusqu'ici l'a été par hasard, et tard :

- un front qui appelait `fn_set_employee_sensitive` en direct au lieu de passer
  par `callEngine`, donc sans la journalisation d'accès ;
- six écrans qui reconnaissaient la version en vigueur par `!row.valid_to`, test
  devenu toujours faux dès que la colonne est passée non nulle — sans erreur,
  juste des valeurs disparues ;
- quarante migrations que le dépôt croyait absentes parce qu'il les cherchait par
  horodatage alors que la plateforme en attribue un autre ;
- une documentation annonçant « 265 colonnes commentées sur 714 » longtemps après
  que le nombre de colonnes eut changé.

Aucune de ces dérives n'était difficile à détecter. Elles étaient difficiles à
*remarquer*. C'est exactement ce qu'une vérification mécanique sait faire.

Ce qu'il vérifie
----------------
1. Toute fonction du moteur appelée par un front existe en base.
2. Aucune table n'est laissée sans RLS.
3. Aucune fonction n'est exécutable par `anon`.
4. Toutes les tables et colonnes portent un commentaire.
5. Les liens relatifs de la documentation pointent sur des fichiers existants.
6. Les nombres annoncés dans la documentation correspondent au réel.
7. Aucune colonne « not null » n'est traitée comme nullable, et il n'existe
   qu'une seule date sentinelle dans tout le schéma.
8. Le dépôt et la base portent les mêmes migrations (délégué à dump_migrations).

Ce qu'il ne fait pas
--------------------
Corriger. Un écart de cohérence demande une décision : c'est parfois la base qui
a raison, parfois la documentation. L'outil dit ce qui diverge et s'arrête là.
Code de sortie non nul s'il trouve quelque chose — utilisable en intégration.
"""

from __future__ import annotations

import io


import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

# La console Windows est en cp1252. Un caractère venu de la documentation
# citée — une coche, un tiret cadratin — faisait tomber le rapport au moment
# de l'afficher : l'outil de contrôle échouait sur sa propre sortie.
# Envelopper stdout une seule fois : deux modules qui le font à l'import se
# marchent dessus, le second détachant le tampon du premier — d'où un
# « I/O operation on closed file » au premier print du module appelant.
if (sys.stdout.encoding or "").lower().replace("-", "") != "utf8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
ENV = RACINE / "luxrh" / ".env.local"
SRC = RACINE / "luxrh" / "src"
PY = RACINE / "luxrh-py"
DOCS = RACINE / "docs"

ecarts: list[tuple[str, str]] = []


def signaler(rubrique: str, message: str) -> None:
    ecarts.append((rubrique, message))


def lire_env() -> dict[str, str]:
    valeurs: dict[str, str] = {}
    if ENV.exists():
        for ligne in ENV.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^\s*([A-Z0-9_]+)\s*=\s*(.*)$", ligne)
            if m:
                valeurs[m.group(1)] = m.group(2).strip()
    return valeurs


def poster(url: str, entetes: dict[str, str], corps: dict):
    requete = urllib.request.Request(
        url,
        data=json.dumps(corps).encode("utf-8"),
        headers={**entetes, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(requete, timeout=90) as reponse:
        return json.loads(reponse.read().decode("utf-8"))


# =========================================================== ce que le code appelle


def fonctions_appelees() -> dict[str, set[str]]:
    """Les fonctions du moteur que chaque front appelle, par leur nom."""
    appels: dict[str, set[str]] = {"React": set(), "Streamlit": set()}

    for fichier in list(SRC.rglob("*.ts")) + list(SRC.rglob("*.tsx")):
        texte = fichier.read_text(encoding="utf-8")
        for m in re.finditer(r"(?:rpc|callEngine)(?:<[^>]*>)?\(\s*'(fn_[a-z0-9_]+)'", texte):
            appels["React"].add(m.group(1))

    for fichier in PY.glob("*.py"):
        appels["Streamlit"] |= _appels_python(fichier)
    for fichier in (PY / "luxrh").glob("*.py"):
        appels["Streamlit"] |= _appels_python(fichier)

    return appels


def _appels_python(fichier: Path) -> set[str]:
    texte = fichier.read_text(encoding="utf-8")
    return set(re.findall(r'engine\(\s*"(fn_[a-z0-9_]+)"', texte)) | set(
        re.findall(r"engine\(\s*'(fn_[a-z0-9_]+)'", texte))


# =========================================================== contrôles


def controler_fonctions(entetes, base: str, existantes: set[str]) -> None:
    """Une fonction appelée qui n'existe pas est une erreur 404 à l'exécution."""
    for front, appelees in fonctions_appelees().items():
        manquantes = sorted(appelees - existantes)
        for nom in manquantes:
            signaler("Moteur", f"{front} appelle {nom}(), absente de la base")
        if appelees:
            print(f"  {front} : {len(appelees)} fonction(s) du moteur appelée(s), "
                  f"{len(manquantes)} introuvable(s)")


def controler_liens() -> None:
    """Un lien cassé dans la documentation se remarque quand quelqu'un le suit."""
    total = casses = 0
    for md in sorted(DOCS.glob("*.md")) + [RACINE / "CLAUDE.md"]:
        if not md.exists():
            continue
        for m in re.finditer(r"\[[^\]]*\]\(([^)]+)\)", md.read_text(encoding="utf-8")):
            cible = m.group(1).split("#")[0]
            if not cible or cible.startswith(("http", "mailto")):
                continue
            total += 1
            if not (md.parent / cible).exists():
                casses += 1
                signaler("Documentation", f"{md.name} → lien mort vers {cible}")
    print(f"  Documentation : {total} lien(s) relatif(s), {casses} cassé(s)")


def controler_chiffres_documentes(reel: dict[str, int]) -> None:
    """Les nombres annoncés dans la documentation vieillissent en silence.

    Le piège est de ratisser trop large. Une première version signalait « les 13
    tables héritées » et « 16 tables neuves » comme faux parce qu'ils ne valaient
    pas le total — vingt faux signaux qui auraient fait ignorer les vrais, la même
    erreur que le rapport noyé sous les routines de btree_gist.

    On ne retient donc que les tournures qui **prétendent compter l'ensemble** :
    « la base porte N tables », « RLS sur les N tables », « N migrations
    appliquées », « N / N colonnes ». Un compte de sous-ensemble est légitime et
    n'est pas regardé.
    """
    motifs = [
        ("tables", r"(?:porte|portent|décrit|décrivent|compte|comprend)\s+"
                   r"(?:encore\s+|toujours\s+|désormais\s+)?\*{0,2}(\d+)\*{0,2}\s+tables"),
        ("tables", r"RLS\s+sur\s+(?:les\s+)?\*{0,2}(\d+)\*{0,2}\s+tables"),
        ("tables", r"[Ll]es\s+(\d+)\s+tables\s+(?:de la base|par domaine|la portent|déployée)"),
        ("tables", r"(\d+)\s+tables\s+(?:au total|en tout)"),
        ("migrations", r"(\d+)\s+migrations\s+appliquées"),
        ("colonnes", r"(\d+)\s*/\s*\d+\s+colonnes"),
        ("colonnes", r"(\d+)\s+colonnes\s+(?:au total|en tout|de la base)"),
    ]
    for md in sorted(DOCS.glob("*.md")):
        texte = md.read_text(encoding="utf-8")
        for quoi, motif in motifs:
            for m in re.finditer(motif, texte):
                annonce = int(m.group(1))
                if quoi in reel and annonce != reel[quoi]:
                    extrait = texte[max(0, m.start() - 30):m.end() + 15]
                    extrait = " ".join(extrait.split())
                    signaler("Documentation",
                             f"{md.name} annonce {annonce} {quoi}, la base en a "
                             f"{reel[quoi]} — « …{extrait}… »")


def controler_migrations() -> None:
    """Délégué à l'outil qui en a la charge, pour n'avoir qu'une seule vérité."""
    outil = RACINE / "tools" / "dump_migrations.py"
    resultat = subprocess.run(
        [sys.executable, str(outil)], capture_output=True, text=True,
        encoding="utf-8", errors="replace",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"})
    sortie = resultat.stdout
    for cle, rubrique in (("sans fichier", "migration appliquée sans fichier dans le dépôt"),
                          ("horodatage à corriger", "fichier dont la version diffère de la base"),
                          ("fichier non appliqué", "fichier que db push appliquerait")):
        m = re.search(rf"{re.escape(cle)}\s*:\s*(\d+)", sortie)
        if m and int(m.group(1)) > 0:
            signaler("Migrations", f"{m.group(1)} {rubrique}")
    m = re.search(r"(\d+) migration\(s\) appliquée\(s\)", sortie)
    print(f"  Migrations : {m.group(1) if m else '?'} appliquée(s), dépôt aligné"
          if not any(r == "Migrations" for r, _ in ecarts)
          else "  Migrations : dépôt et base divergent")


def main() -> int:
    env = lire_env()
    base = os.environ.get("VITE_SUPABASE_URL") or env.get("VITE_SUPABASE_URL")
    cle = os.environ.get("VITE_SUPABASE_ANON_KEY") or env.get("VITE_SUPABASE_ANON_KEY")
    courriel = env.get("LUXRH_ADMIN_EMAIL") or "demo@luxrh.lu"
    motdepasse = env.get("LUXRH_ADMIN_PASSWORD") or env.get("LUXRH_MANAGER_PASSWORD")

    if not (base and cle and motdepasse):
        print("Configuration incomplète : VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY et "
              "LUXRH_ADMIN_PASSWORD (ou LUXRH_MANAGER_PASSWORD).", file=sys.stderr)
        return 2

    print("Vérification de cohérence — dépôt, base, documentation\n")

    try:
        jeton = poster(f"{base}/auth/v1/token?grant_type=password", {"apikey": cle},
                       {"email": courriel, "password": motdepasse})["access_token"]
        entetes = {"apikey": cle, "Authorization": f"Bearer {jeton}"}
        catalogue = poster(f"{base}/rest/v1/rpc/fn_coherence_report", entetes, {})
    except urllib.error.HTTPError as erreur:
        corps = erreur.read().decode("utf-8", "replace")[:200]
        print(f"Lecture refusée ({erreur.code}) : {corps}", file=sys.stderr)
        print("Le compte doit être administrateur d'organisation.", file=sys.stderr)
        return 2
    except Exception as erreur:                      # noqa: BLE001
        print(f"Échec : {erreur}", file=sys.stderr)
        return 2

    existantes = set(catalogue["fonctions"])
    reel = {"tables": catalogue["tables"], "colonnes": catalogue["colonnes"],
            "migrations": catalogue["migrations"]}

    controler_fonctions(entetes, base, existantes)

    for nom in catalogue["tables_sans_rls"]:
        signaler("Sécurité", f"table {nom} sans RLS — l'isolation est imposée en base")
    print(f"  Sécurité : {len(catalogue['tables_sans_rls'])} table(s) sans RLS, "
          f"{len(catalogue['fonctions_anon'])} fonction(s) applicative(s) ouverte(s) à anon")
    for nom in catalogue["fonctions_anon"]:
        signaler("Sécurité", f"fonction {nom} exécutable par anon")
    for nom in catalogue.get("non_nul_traite_comme_nullable", []):
        signaler("Code mort",
                 f"{nom} : la colonne est « not null » dans toutes les tables où elle "
                 f"apparaît, et la fonction la teste ou l'enrobe comme si elle pouvait "
                 f"être nulle. Le test ne peut plus être vrai ; le laisser fait croire "
                 f"au lecteur que la colonne admet des nuls.")
    for nom in catalogue.get("sentinelles_concurrentes", []):
        signaler("Code mort",
                 f"{nom} emploie une date lointaine autre que 2037-12-31. Le projet n'a "
                 f"qu'une sentinelle ; deux se compareront un jour l'une à l'autre.")

    for nom in catalogue.get("extensions_dans_public", []):
        signaler("Sécurité",
                 f"extension {nom} installée dans le schéma public — ses routines de "
                 f"support y sont exposées et exécutables par PUBLIC. Sa place est "
                 f"dans le schéma extensions, comme pgcrypto et dblink.")

    if catalogue["tables_sans_commentaire"]:
        for nom in catalogue["tables_sans_commentaire"]:
            signaler("Commentaires", f"table {nom} sans commentaire")
    if catalogue["colonnes_sans_commentaire"]:
        for nom in catalogue["colonnes_sans_commentaire"][:20]:
            signaler("Commentaires", f"colonne {nom} sans commentaire")
    print(f"  Commentaires : {catalogue['tables']} table(s), {catalogue['colonnes']} colonne(s), "
          f"{len(catalogue['tables_sans_commentaire'])} + "
          f"{len(catalogue['colonnes_sans_commentaire'])} sans commentaire")

    controler_liens()
    controler_chiffres_documentes(reel)
    controler_migrations()

    print()
    if not ecarts:
        print("Aucun écart. Le dépôt, la base et la documentation concordent.")
        return 0

    par_rubrique: dict[str, list[str]] = {}
    for rubrique, message in ecarts:
        par_rubrique.setdefault(rubrique, []).append(message)
    print(f"{len(ecarts)} écart(s) :\n")
    for rubrique, messages in par_rubrique.items():
        print(f"{rubrique}")
        for message in messages:
            print(f"  - {message}")
        print()
    return 1


if __name__ == "__main__":
    sys.exit(main())
