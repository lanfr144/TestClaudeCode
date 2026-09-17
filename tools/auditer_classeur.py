# -*- coding: utf-8 -*-
"""Audit de `paramètres.xlsx` : ce qui empêcherait un chargement fidèle.

    python tools/auditer_classeur.py
    python tools/auditer_classeur.py --markdown docs/audit-parametres.md

Le classeur est la source du référentiel : une anomalie qui y passe inaperçue
devient un calcul de paie faux. Cet outil ne corrige rien — il constate, et il
range chaque constat par gravité.

    BLOQUANT      empêche de charger la clé, ou la chargerait fausse
    À VÉRIFIER    charge quelque chose, mais peut-être pas ce qui était voulu
    HYGIÈNE       n'empêche rien aujourd'hui, prépare une erreur demain

Chaque constat porte la ligne du classeur : un rapport qu'on ne peut pas
rapprocher de la source ne se corrige pas.
"""
from __future__ import annotations

import argparse
import datetime as dt
import io
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

RACINE = Path(__file__).resolve().parent.parent
CLASSEUR = RACINE / "lois_et_règlements" / "paramètres.xlsx"

BLOQUANT, VERIFIER, HYGIENE = "BLOQUANT", "À VÉRIFIER", "HYGIÈNE"

# Colonnes de travail : valeur courante, formule, ancrage — puis le second jeu.
COL_VALEUR_1, COL_FORMULE_1, COL_ANCRE = "C", "D", "E"
COL_VALEUR_2, COL_FORMULE_2 = "F", "G"

# Une formule recopiée en texte. `#N/A` signale « pas de formule ».
FORMULE = re.compile(r"^\s*=")
# Une référence de cellule nue : F12, $C$10, C$142. Fragile à l'insertion d'une ligne.
REF_CELLULE = re.compile(r"\$?[A-Z]{1,2}\$?\d+")


class Constat:
    def __init__(self, gravite: str, categorie: str, ligne, message: str):
        self.gravite, self.categorie, self.ligne, self.message = gravite, categorie, ligne, message

    def __lt__(self, autre):
        ordre = {BLOQUANT: 0, VERIFIER: 1, HYGIENE: 2}
        return (ordre[self.gravite], self.categorie, self.ligne or 0) < \
               (ordre[autre.gravite], autre.categorie, autre.ligne or 0)


def lire(chemin: Path):
    import openpyxl
    wb = openpyxl.load_workbook(chemin, data_only=True)
    ws = wb[wb.sheetnames[0]]

    dates: dict[str, dt.date] = {}
    for c in ws[1]:
        if isinstance(c.value, dt.datetime):
            dates[c.column_letter] = c.value.date()

    lignes = []
    for ligne in ws.iter_rows(min_row=1):
        par_colonne = {c.column_letter: c.value for c in ligne}
        lignes.append((ligne[0].row, par_colonne))
    feuilles = list(wb.sheetnames)
    wb.close()
    return feuilles, dates, lignes


def auditer(dates, lignes) -> list[Constat]:
    constats: list[Constat] = []
    trous_par_date: dict[dt.date, list[tuple[int, str]]] = defaultdict(list)
    sans_libelle: list[tuple[int, str]] = []
    formules_mixtes: list[tuple[int, str]] = []

    def dire(g, cat, ligne, msg):
        constats.append(Constat(g, cat, ligne, msg))

    # --------------------------------------------------- 1. les colonnes datées
    historiques = sorted(
        ((col, d) for col, d in dates.items()
         if col not in {COL_VALEUR_1, COL_FORMULE_1, COL_ANCRE, COL_VALEUR_2, COL_FORMULE_2}),
        key=lambda cd: cd[1], reverse=True)

    vues_dates = Counter(d for _, d in historiques)
    for d, n in vues_dates.items():
        if n > 1:
            dire(BLOQUANT, "colonnes", 1,
                 f"la date {d} apparaît dans {n} colonnes historiques : "
                 "le chargeur ne saurait laquelle fait foi")

    # Nombre de clés du classeur, pour situer le remplissage d'une colonne.
    par_cle_attendue = {str(cellules["A"]).strip()
                        for no, cellules in lignes
                        if no > 2 and cellules.get("A") and str(cellules["A"]).strip()}

    # ------------------------------------- 2. les colonnes globalement vides
    #
    # Une colonne datée que personne ne renseigne est un constat unique. La
    # signaler ligne par ligne produisait cent entrées pour un seul fait, et
    # noyait tout le reste du rapport — un rapport illisible n'est pas lu.
    # Une colonne peu renseignée n'est pas un relevé complet : les clés qu'elle
    # n'a pas ne sont pas « trouées », elles n'ont simplement jamais été saisies
    # là. Les compter comme des trous produisait cent constats pour un seul fait.
    SEUIL_COLONNE_PARTIELLE = 10
    colonnes_vides = set()
    for col, d in historiques:
        renseignees = sum(
            1 for no, cellules in lignes
            if no > 2 and cellules.get("A")
            and cellules.get(col) is not None
            and not (isinstance(cellules.get(col), str) and not cellules[col].strip()))
        if renseignees == 0:
            colonnes_vides.add(col)
            dire(VERIFIER, "colonnes", 1,
                 f"la colonne {col} ({d}) n'est renseignée pour aucune clé : "
                 "relevé jamais saisi, ou colonne ajoutée par anticipation")
        elif renseignees < SEUIL_COLONNE_PARTIELLE:
            colonnes_vides.add(col)
            dire(VERIFIER, "colonnes", 1,
                 f"la colonne {col} ({d}) n'est renseignée que pour {renseignees} clé(s) "
                 f"sur {len(par_cle_attendue)} : relevé partiel. Les clés absentes de cette "
                 "colonne ne sont pas signalées comme trouées")

    # ---------------------------------------------------------- 3. les clés
    par_cle: dict[str, list[int]] = defaultdict(list)
    section = None
    lignes_utiles = []

    for no, cellules in lignes:
        if no <= 2:
            continue
        brut = cellules.get("A")
        libelle = cellules.get("B")
        cle = None if brut is None else str(brut).strip()

        if not cle:
            if libelle and str(libelle).strip():
                section = str(libelle).strip()
            continue

        if cle.startswith("'"):
            dire(VERIFIER, "clé", no,
                 f"« {cle} » commence par une apostrophe — Excel échappe ainsi ce "
                 "qu'il prendrait pour une formule. La clé réelle est "
                 f"« {cle.lstrip(chr(39))} »")
            cle = cle.lstrip("'")

        par_cle[cle].append(no)
        lignes_utiles.append((no, cle, libelle, cellules, section))

    for cle, nos in par_cle.items():
        if len(nos) > 1:
            dire(BLOQUANT, "clé", nos[0],
                 f"« {cle} » apparaît {len(nos)} fois (lignes {', '.join(map(str, nos))}) : "
                 "un identifiant pour plusieurs grandeurs")

    # ------------------------------------------- 4. nommage et types de clés
    styles = defaultdict(list)
    for cle in par_cle:
        if re.fullmatch(r"[A-Z0-9_]+", cle):
            styles["MAJUSCULES"].append(cle)
        elif re.fullmatch(r"[a-z0-9_]+", cle):
            styles["minuscules"].append(cle)
        else:
            styles["mixte"].append(cle)

    if len(styles) > 1:
        detail = " ; ".join(f"{k} : {len(v)}" for k, v in sorted(styles.items()))
        dire(HYGIENE, "nommage", None,
             f"trois conventions de nommage coexistent ({detail}). "
             f"Exemples mixtes : {', '.join(sorted(styles['mixte'])[:6])}")

    accentuees = [c for c in par_cle if any(ord(ch) > 127 for ch in c)]
    if accentuees:
        dire(HYGIENE, "nommage", None,
             f"{len(accentuees)} clé(s) portent un accent : {', '.join(sorted(accentuees))}. "
             "Une clé sert d'identifiant technique — elle traverse SQL, JSON et URL")

    # ----------------------------------------------- 5. libellés et valeurs
    for no, cle, libelle, cellules, sect in lignes_utiles:
        if not libelle or not str(libelle).strip():
            sans_libelle.append((no, cle))

        valeurs = {col: cellules.get(col) for col, _ in historiques}
        renseignees = {c: v for c, v in valeurs.items()
                       if v is not None and not (isinstance(v, str) and not v.strip())}

        f1 = cellules.get(COL_FORMULE_1)
        calculee = isinstance(f1, str) and FORMULE.match(f1)

        if not renseignees:
            if calculee:
                dire(VERIFIER, "valeur", no,
                     f"« {cle} » n'a aucune valeur historique et se calcule ({str(f1).strip()}) : "
                     "le moteur doit savoir la dériver, sinon la clé restera vide")
            else:
                dire(BLOQUANT, "valeur", no,
                     f"« {cle} » n'a aucune valeur dans aucune colonne historique "
                     "et ne porte pas de formule")
            continue

        # Trous au milieu d'une série : une colonne vide entourée de valeurs.
        # Une colonne vide pour tout le monde n'est pas un trou propre à la clé.
        cols = [c for c, _ in sorted(historiques, key=lambda cd: cd[1])
                if c not in colonnes_vides]
        etat = [c in renseignees for c in cols]
        if True in etat:
            premier, dernier = etat.index(True), len(etat) - 1 - etat[::-1].index(True)
            trous = [cols[i] for i in range(premier, dernier + 1) if not etat[i]]
            if trous and not calculee:
                # Les trous se regroupent par date : vingt clés absentes du même
                # relevé, c'est une saisie oubliée, pas vingt anomalies.
                for c in trous:
                    trous_par_date[dict(historiques)[c]].append((no, cle))

        # Types mélangés sur une même ligne.
        # `int` et `float` sont tous deux des nombres : les opposer signalait
        # 591 contre 605,77 comme une anomalie. Seules les familles comptent.
        def famille(v):
            if isinstance(v, bool): return "booléen"
            if isinstance(v, (int, float)): return "nombre"
            if isinstance(v, (dt.datetime, dt.date, dt.time)): return "date ou heure"
            return "texte"

        familles = {famille(v) for v in renseignees.values()}
        if len(familles) > 1:
            dire(BLOQUANT, "type", no,
                 f"« {cle} » mélange {', '.join(sorted(familles))} sur la même ligne")

        # Un taux qui dépasse 1 dans une ligne de taux.
        if re.match(r"^(ASS_|EMP_|MUT_)", cle) or cle.endswith("_PCT"):
            hors = {c: v for c, v in renseignees.items()
                    if isinstance(v, (int, float)) and not isinstance(v, bool) and v > 1}
            if hors:
                dire(VERIFIER, "valeur", no,
                     f"« {cle} » ressemble à un taux mais vaut {max(hors.values())} : "
                     "taux et pourcentage mélangés ?")

        # Valeur textuelle là où un nombre est attendu.
        textes = {c: v for c, v in renseignees.items() if isinstance(v, str)}
        if textes:
            dire(BLOQUANT, "type", no,
                 f"« {cle} » porte du texte en colonne(s) {', '.join(sorted(textes))} : "
                 f"{list(textes.values())[0]!r}")

        # Erreur Excel propagée dans une colonne historique.
        erreurs = {c: v for c, v in renseignees.items()
                   if isinstance(v, str) and v.startswith("#")}
        if erreurs:
            dire(BLOQUANT, "formule", no,
                 f"« {cle} » porte une erreur Excel en colonne(s) {', '.join(sorted(erreurs))}")

    # --------------------------------------------- 6. les deux jeux de formules
    for no, cle, _, cellules, _ in lignes_utiles:
        f1, f2 = cellules.get(COL_FORMULE_1), cellules.get(COL_FORMULE_2)
        t1 = isinstance(f1, str) and FORMULE.match(f1)
        t2 = isinstance(f2, str) and FORMULE.match(f2)

        if t1 and not t2 and f2 is not None and str(f2).strip() not in ("", "#N/A"):
            dire(VERIFIER, "formule", no,
                 f"« {cle} » : la colonne {COL_VALEUR_1} se calcule mais la colonne "
                 f"{COL_VALEUR_2} porte {str(f2).strip()!r}")

        if t1 and t2:
            # Le premier jeu nomme ses opérandes, le second les référence par cellule.
            nomme = not REF_CELLULE.search(re.sub(r"^\s*=", "", str(f1)))
            reference = bool(REF_CELLULE.search(str(f2)))
            if nomme and reference:
                formules_mixtes.append((no, cle))

        if t1 and str(f1).strip().rstrip("=").endswith(("+", "-", "*", "/", "(")):
            dire(BLOQUANT, "formule", no, f"« {cle} » : formule tronquée — {str(f1).strip()!r}")

    # Les descriptions manquantes forment un seul fait, pas soixante-treize.
    if sans_libelle:
        cles = [c for _, c in sans_libelle]
        dire(HYGIENE, "libellé", min(no for no, _ in sans_libelle),
             f"{len(cles)} clé(s) sans description — le référentiel affichera la clé "
             f"brute : {', '.join(cles[:10])}"
             + (f" … et {len(cles) - 10} autres" if len(cles) > 10 else ""))

    # ----------------------------------- 6 bis. les trous, regroupés par relevé
    for d, items in sorted(trous_par_date.items()):
        cles = [c for _, c in items]
        premiere = min(no for no, _ in items)
        apercu = ", ".join(cles[:8]) + (" …" if len(cles) > 8 else "")
        dire(VERIFIER, "série", premiere,
             f"{len(cles)} clé(s) sans valeur au relevé du {d}, entre deux relevés "
             f"renseignés et sans formule : {apercu}")

    if formules_mixtes:
        cles = [c for _, c in formules_mixtes]
        dire(HYGIENE, "formule", min(no for no, _ in formules_mixtes),
             f"{len(cles)} formule(s) du second jeu (colonne {COL_FORMULE_2}) référencent "
             f"des cellules là où le premier jeu (colonne {COL_FORMULE_1}) nomme ses "
             f"opérandes : {', '.join(cles[:8])}"
             + (f" … et {len(cles) - 8} autres" if len(cles) > 8 else "")
             + ". Insérer une ligne casse le second jeu en silence")

    # ------------------------------------------------- 7. lignes orphelines
    for no, cellules in lignes:
        if no <= 2:
            continue
        if cellules.get("A") is None and cellules.get("B"):
            valeurs = [cellules.get(col) for col, _ in historiques]
            if any(v is not None for v in valeurs):
                dire(VERIFIER, "orphelin", no,
                     f"ligne sans clé mais avec des valeurs : « {str(cellules['B'])[:70]} ». "
                     "Un titre de section ne porte pas de valeurs — cette ligne ne sera pas chargée")

    return constats


def rapport(feuilles, dates, constats, markdown: bool) -> str:
    par_gravite = defaultdict(list)
    for c in constats:
        par_gravite[c.gravite].append(c)

    lignes = []
    titre = "# Audit de `paramètres.xlsx`" if markdown else "AUDIT DE paramètres.xlsx"
    lignes.append(titre)
    lignes.append("")
    if markdown:
        lignes.append(f"Relevé du {dt.date.today():%d %B %Y}. Généré par "
                      "`tools/auditer_classeur.py` — ce document se régénère, "
                      "il ne se tient pas à la main.")
        lignes.append("")
        lignes.append(f"Feuille : `{feuilles[0]}`. {len(dates)} colonnes datées.")
        lignes.append("")
        lignes.append("| Gravité | Ce que cela signifie | Nombre |")
        lignes.append("|---|---|---|")
        sens = {
            BLOQUANT: "empêche de charger la clé, ou la chargerait fausse",
            VERIFIER: "charge quelque chose, mais peut-être pas ce qui était voulu",
            HYGIENE: "n'empêche rien aujourd'hui, prépare une erreur demain",
        }
        for g in (BLOQUANT, VERIFIER, HYGIENE):
            lignes.append(f"| **{g}** | {sens[g]} | {len(par_gravite[g])} |")
        lignes.append("")

    for g in (BLOQUANT, VERIFIER, HYGIENE):
        items = sorted(par_gravite[g])
        if not items:
            continue
        lignes.append(f"## {g} — {len(items)}" if markdown else f"\n=== {g} ({len(items)}) ===")
        lignes.append("")
        categorie = None
        for c in items:
            if c.categorie != categorie:
                categorie = c.categorie
                lignes.append(f"### {categorie}" if markdown else f"  -- {categorie} --")
                lignes.append("")
            ou = f"ligne {c.ligne}" if c.ligne else "classeur"
            lignes.append(f"- **{ou}** — {c.message}" if markdown else f"  [{ou}] {c.message}")
        lignes.append("")

    if not constats:
        lignes.append("Aucune anomalie.")
    return "\n".join(lignes)


def main() -> int:
    p = argparse.ArgumentParser(description="Audit du classeur des paramètres.")
    p.add_argument("--markdown", metavar="CHEMIN", help="écrit le rapport en Markdown")
    args = p.parse_args()

    if not CLASSEUR.exists():
        print(f"ARRÊT — {CLASSEUR} est introuvable.")
        return 1

    feuilles, dates, lignes = lire(CLASSEUR)
    constats = auditer(dates, lignes)

    print(rapport(feuilles, dates, constats, markdown=False))

    if args.markdown:
        cible = RACINE / args.markdown
        cible.parent.mkdir(parents=True, exist_ok=True)
        cible.write_text(rapport(feuilles, dates, constats, markdown=True) + "\n",
                         encoding="utf-8")
        print(f"\nÉcrit : {cible.relative_to(RACINE)}")

    bloquants = sum(1 for c in constats if c.gravite == BLOQUANT)
    return 1 if bloquants else 0


if __name__ == "__main__":
    raise SystemExit(main())
