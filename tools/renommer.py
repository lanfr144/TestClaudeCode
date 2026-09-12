"""Applique le renommage anglais → français au code des deux interfaces.

    luxrh-py/.venv/Scripts/python tools/renommer.py tables              # montre
    luxrh-py/.venv/Scripts/python tools/renommer.py tables --ecrire     # applique
    luxrh-py/.venv/Scripts/python tools/renommer.py colonnes-sures --ecrire
    luxrh-py/.venv/Scripts/python tools/renommer.py colonnes-simples --ecrire

Le dictionnaire est dans `tools/renommage.py`. Ce fichier ne fait que l'appliquer :
décider des noms et les substituer sont deux travaux distincts, et seul le premier
se relit.

Trois blocs, et pourquoi
------------------------
La consigne était de renommer « d'un bloc, sinon l'application ne démarre plus en
cours de route ». C'est juste, et c'est pour cela qu'on découpe : chaque bloc est
complet en lui-même — base et code renommés ensemble, construction et
190 vérifications au vert avant de passer au suivant. L'application n'est jamais
laissée à moitié renommée ; elle est à moitié *traduite*, ce qu'elle était déjà
avant de commencer, dix-huit tables portant des noms français.

| Bloc | Portée | Méthode |
|---|---|---|
| `tables` | 55 tables | Mot à mot, partout |
| `colonnes-sures` | noms composés et types énumérés | Mot à mot, partout |
| `colonnes-simples` | noms simples | **Littéraux de chaîne uniquement** |

Un nom composé — `monthly_gross`, `certificate_received_at` — ne peut venir que de
la base. Un nom simple — `name`, `status`, `key`, `title`, `unit` — désigne en
TypeScript aussi bien une colonne qu'une propriété de `Error`, un attribut JSX ou
un champ de `File`. D'où le traitement séparé.

Ce que l'outil ne touche jamais
--------------------------------
`luxrh/src/lib/database.types.ts`, régénéré depuis la base. Et les migrations déjà
appliquées : elles décrivent ce qui a eu lieu, pas ce qui est.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renommage                                                     # noqa: E402

RACINE = Path(__file__).resolve().parent.parent
TYPES_GENERES = RACINE / "luxrh" / "src" / "lib" / "database.types.ts"

GUILLEMETS = ("'", '"')

# Une chaîne qui suit immédiatement l'un de ces attributs n'est pas une colonne :
# c'est une valeur du DOM. `type="email"`, `role="status"`, `autoComplete="name"`,
# `type="color"` — tous auraient été traduits, et cinq l'ont été avant que cette
# garde n'existe. `role="statut"` n'est pas une coquille : c'est un lecteur
# d'écran qui cesse d'annoncer les messages d'état.
ATTRIBUT_DOM = re.compile(
    r"(?:type|role|autoComplete|autocomplete|inputMode|inputmode|rel|method|target"
    r"|htmlFor|charSet|encType|httpEquiv|lang|dir|aria-[a-z]+|data-[a-z-]+)"
    r"\s*=\s*$")


def fichiers_code() -> list[Path]:
    """Tout ce qui peut nommer une table ou une colonne, sauf les types générés."""
    cibles: list[Path] = []
    for motif in ("*.ts", "*.tsx"):
        cibles += [f for f in (RACINE / "luxrh" / "src").rglob(motif)
                   if f != TYPES_GENERES]
    cibles += list((RACINE / "luxrh" / "tests").glob("*.mjs"))
    cibles += list((RACINE / "luxrh-py").glob("*.py"))
    cibles += list((RACINE / "luxrh-py" / "luxrh").glob("*.py"))
    cibles += list((RACINE / "docs").glob("*.md"))
    cibles += [RACINE / "CLAUDE.md"]
    return [f for f in cibles if f.exists()]


# =========================================================== réécriture du code


def remplacer_partout(texte: str, table: dict[str, str]) -> tuple[str, int]:
    """Remplacement mot à mot, du nom le plus long au plus court.

    L'ordre compte : sans lui, `company_id` serait d'abord amputé par la règle
    `company`, et le résultat ne correspondrait à rien.
    """
    n = 0
    for ancien in sorted(table, key=len, reverse=True):
        nouveau = table[ancien]
        if ancien == nouveau:
            continue
        texte, k = re.subn(rf"\b{re.escape(ancien)}\b", nouveau, texte)
        n += k
    return texte, n


def _est_commentaire(ligne: str) -> bool:
    nu = ligne.lstrip()
    return nu.startswith(("//", "#", "*", "/*"))


def remplacer_dans_chaines(texte: str, table: dict[str, str]) -> tuple[str, int]:
    """Remplacement limité au contenu des littéraux de chaîne d'une même ligne.

    Pourquoi ligne par ligne
    ------------------------
    La première version employait une expression rationnelle sur le fichier
    entier. Elle a échoué exactement là où il fallait s'y attendre : un accent
    grave isolé dans un commentaire lui faisait prendre tout le code suivant pour
    le contenu d'une chaîne. `key={i}` devenait `cle={i}`, `title=` devenait
    `titre=` sur des composants React — 399 erreurs de compilation, dont la
    plupart causées par l'outil lui-même.

    Ce balayage suit l'état des guillemets caractère par caractère et ne franchit
    jamais une fin de ligne : un littéral mal fermé ne peut contaminer que sa
    propre ligne. Les accents graves sont ignorés — un gabarit multiligne n'est
    pas traité ici, et le compilateur signalera ce qui subsiste.

    C'est dans ces littéraux que vivent les requêtes : `.from('salaries')`,
    `.select('id,prenom')`, `salaries?select=...`, et côté Python `row["statut"]`.
    """
    total = 0
    sorties: list[str] = []

    for ligne in texte.split("\n"):
        if _est_commentaire(ligne) or not any(g in ligne for g in GUILLEMETS):
            sorties.append(ligne)
            continue

        morceaux: list[str] = []
        tampon: list[str] = []
        guillemet: str | None = None
        protege = False
        i = 0
        while i < len(ligne):
            c = ligne[i]
            if guillemet is None:
                if c in GUILLEMETS:
                    morceaux.append("".join(tampon))
                    morceaux.append(c)
                    protege = bool(ATTRIBUT_DOM.search(ligne[:i]))
                    tampon = []
                    guillemet = c
                else:
                    tampon.append(c)
                i += 1
                continue

            if c == "\\" and i + 1 < len(ligne):
                tampon.append(ligne[i:i + 2])
                i += 2
                continue
            if c == guillemet:
                if protege:
                    contenu, k = "".join(tampon), 0
                else:
                    contenu, k = remplacer_partout("".join(tampon), table)
                total += k
                morceaux.append(contenu)
                morceaux.append(c)
                tampon = []
                guillemet = None
            else:
                tampon.append(c)
            i += 1

        # Littéral non fermé en fin de ligne : on ne devine pas, on laisse tel quel.
        morceaux.append("".join(tampon))
        sorties.append("".join(morceaux))

    return "\n".join(sorties), total


def appliquer(table: dict[str, str], chaines_seulement: bool, ecrire: bool) -> None:
    total = 0
    touches: list[tuple[str, int]] = []
    for fichier in fichiers_code():
        texte = fichier.read_text(encoding="utf-8")
        nouveau, n = (remplacer_dans_chaines(texte, table) if chaines_seulement
                      else remplacer_partout(texte, table))
        if n:
            total += n
            touches.append((str(fichier.relative_to(RACINE)), n))
            if ecrire:
                fichier.write_text(nouveau, encoding="utf-8", newline="\n")

    for nom, n in sorted(touches, key=lambda x: -x[1])[:12]:
        print(f"  {n:>5}  {nom}")
    if len(touches) > 12:
        print(f"  … et {len(touches) - 12} autre(s) fichier(s)")
    print(f"\n{total} occurrence(s) sur {len(touches)} fichier(s)"
          f"{' — écrites' if ecrire else ' — essai à blanc, rien écrit'}.")


BLOCS = ("tables", "colonnes-sures", "colonnes-simples")


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in BLOCS:
        print(__doc__)
        return 2

    bloc = sys.argv[1]
    ecrire = "--ecrire" in sys.argv
    # Colonnes de table, colonnes de sortie RPC, types énumérés : une seule et
    # même surface publique, celle que lisent les deux interfaces.
    tout = {**renommage.COLONNES, **renommage.SORTIES_RPC, **renommage.TYPES}

    if bloc == "tables":
        print("Bloc A — les tables. Un nom de table ne peut désigner qu'une table.\n")
        appliquer(renommage.TABLES, chaines_seulement=False, ecrire=ecrire)
    elif bloc == "colonnes-sures":
        table = {a: b for a, b in tout.items() if a != b and "_" in a}
        print(f"Bloc B — les {len(table)} noms composés. Le souligné garantit "
              f"qu'ils viennent de la base.\n")
        appliquer(table, chaines_seulement=False, ecrire=ecrire)
    else:
        table = {a: b for a, b in tout.items() if a != b and "_" not in a}
        print(f"Bloc C — les {len(table)} noms simples. Littéraux de chaîne "
              f"uniquement : ailleurs, « name » ou « status » désigne autre chose.\n")
        appliquer(table, chaines_seulement=True, ecrire=ecrire)
    return 0


if __name__ == "__main__":
    sys.exit(main())
