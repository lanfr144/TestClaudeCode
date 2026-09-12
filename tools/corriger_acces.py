"""Corrige les accès de propriété devenus faux après le renommage, guidé par tsc.

    luxrh-py/.venv/Scripts/python tools/corriger_acces.py          # montre
    luxrh-py/.venv/Scripts/python tools/corriger_acces.py --ecrire # corrige

Pourquoi le compilateur plutôt qu'une expression rationnelle
-------------------------------------------------------------
Le troisième bloc du renommage ne touche que les littéraux de chaîne, parce qu'en
TypeScript `name`, `status` ou `key` désignent aussi bien une colonne qu'autre
chose. Restent donc les **accès de propriété** — `cba.name`, `regle.block`,
`grille.category` — qu'aucune règle textuelle ne sait distinguer d'un
`error.name` ou d'un `file.name`.

Le compilateur, lui, les distingue parfaitement : il connaît le type de chaque
expression. Une fois les types régénérés depuis la base, il désigne chaque accès
devenu faux avec sa ligne, sa colonne, et souvent le nom correct.

Cet outil ne devine donc rien. Il lit la sortie de `tsc`, et n'applique une
correction que si l'une des deux conditions est remplie :

  - le compilateur propose lui-même le nom (« Did you mean 'bloc'? ») ;
  - ou le nom fautif figure dans le dictionnaire de `tools/renommage.py`.

Tout le reste est laissé en l'état et signalé. Une correction devinée serait pire
qu'une erreur restante : l'erreur, au moins, se voit.

La boucle
---------
Corriger un accès en révèle d'autres, que le compilateur ne voyait pas tant que
le type de l'expression englobante restait indéterminé. L'outil relance donc `tsc`
jusqu'à ce que le nombre d'erreurs cesse de diminuer.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renommage                                                     # noqa: E402

RACINE = Path(__file__).resolve().parent.parent
FRONT = RACINE / "luxrh"
NODE = Path(r"C:\Program Files\nodejs\node.exe")
TSC = FRONT / "node_modules" / "typescript" / "bin" / "tsc"

# Property 'X' does not exist ... (avec ou sans suggestion)
ERREUR = re.compile(
    r"^(?P<fichier>[^(]+)\((?P<ligne>\d+),(?P<col>\d+)\): error TS\d+: "
    r"(?:Property '(?P<prop>[^']+)' does not exist"
    r"|Object literal may only specify known properties, and '(?P<prop2>[^']+)' "
    r"does not exist"
    r"|Object literal may only specify known properties, but '(?P<prop3>[^']+)' "
    r"does not exist)"
    r"(?P<suite>.*)$")
SUGGESTION = re.compile(r"Did you mean '([^']+)'\?")


def dictionnaire() -> dict[str, str]:
    return {**renommage.COLONNES, **renommage.SORTIES_RPC,
            **renommage.TYPES, **renommage.TABLES}


def lancer_tsc() -> list[str]:
    resultat = subprocess.run(
        [str(NODE), str(TSC), "--noEmit", "-p", "tsconfig.json"],
        cwd=str(FRONT), capture_output=True, text=True,
        encoding="utf-8", errors="replace",
        env={**os.environ, "PYTHONIOENCODING": "utf-8"})
    return resultat.stdout.splitlines()


def corriger(lignes: list[str], table: dict[str, str], ecrire: bool) -> tuple[int, int]:
    """Applique une passe de corrections. Renvoie (corrigées, laissées)."""
    # On regroupe par fichier et on applique de la dernière ligne à la première :
    # une correction ne décale ainsi jamais la position des suivantes.
    par_fichier: dict[Path, list[tuple[int, int, str]]] = {}
    laissees = 0

    for ligne in lignes:
        m = ERREUR.match(ligne)
        if not m:
            continue
        prop = m.group("prop") or m.group("prop2") or m.group("prop3")
        if not prop:
            continue

        suggestion = SUGGESTION.search(m.group("suite") or "")
        if suggestion:
            nouveau = suggestion.group(1)
        elif prop in table and table[prop] != prop:
            nouveau = table[prop]
        else:
            laissees += 1
            continue

        chemin = (FRONT / m.group("fichier")).resolve()
        par_fichier.setdefault(chemin, []).append(
            (int(m.group("ligne")), int(m.group("col")), nouveau))

    corrigees = 0
    for chemin, points in par_fichier.items():
        if not chemin.exists():
            continue
        contenu = chemin.read_text(encoding="utf-8").split("\n")
        for no_ligne, col, nouveau in sorted(points, reverse=True):
            i = no_ligne - 1
            if i >= len(contenu):
                continue
            ligne = contenu[i]
            debut = col - 1
            m = re.compile(r"[A-Za-z_][A-Za-z0-9_]*").match(ligne, debut)
            if not m:
                laissees += 1
                continue
            contenu[i] = ligne[:m.start()] + nouveau + ligne[m.end():]
            corrigees += 1
        if ecrire:
            chemin.write_text("\n".join(contenu), encoding="utf-8", newline="\n")

    return corrigees, laissees


def main() -> int:
    ecrire = "--ecrire" in sys.argv
    table = dictionnaire()

    precedent = None
    for passe in range(1, 9):
        lignes = lancer_tsc()
        erreurs = [l for l in lignes if ") error TS" in l or "): error TS" in l]
        print(f"Passe {passe} : {len(erreurs)} erreur(s) de compilation")

        if not erreurs:
            print("\nAucune erreur. Le renommage est complet côté TypeScript.")
            return 0
        if precedent is not None and len(erreurs) >= precedent:
            print("\nLe nombre d'erreurs ne diminue plus : les suivantes demandent "
                  "une décision, pas une substitution.")
            for l in erreurs[:15]:
                print("  " + l[:170])
            return 1
        precedent = len(erreurs)

        corrigees, laissees = corriger(lignes, table, ecrire)
        print(f"  {corrigees} accès corrigé(s), {laissees} laissé(s) au jugement")
        if not ecrire:
            print("\nEssai à blanc : relancer avec --ecrire.")
            return 0
        if corrigees == 0:
            print("\nPlus rien de mécanique à corriger.")
            for l in erreurs[:15]:
                print("  " + l[:170])
            return 1

    return 1


if __name__ == "__main__":
    sys.exit(main())
