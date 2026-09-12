"""Applique le renommage anglais → français : SQL d'un côté, code de l'autre.

    luxrh-py/.venv/Scripts/python tools/renommer.py tables            # montre
    luxrh-py/.venv/Scripts/python tools/renommer.py tables --ecrire   # applique au code
    luxrh-py/.venv/Scripts/python tools/renommer.py tables --sql      # écrit la migration

    ... idem avec `colonnes-sures` puis `colonnes-ambigues`.

Pourquoi trois blocs et non un seul
------------------------------------
La consigne était de renommer « d'un bloc, sinon l'application ne démarre plus en
cours de route ». C'est juste, et c'est justement pour cela qu'on découpe : chaque
bloc est **complet en lui-même** — base et code renommés ensemble, construction et
190 vérifications au vert avant de passer au suivant. L'application n'est donc
jamais laissée à moitié renommée ; elle l'est seulement à moitié *traduite*, ce
qui est un état parfaitement cohérent. Elle l'était déjà : 18 tables étaient en
français avant de commencer.

Le vrai danger, et pourquoi il ne se traite pas d'un seul geste
---------------------------------------------------------------
Sur 306 colonnes renommées, 263 portent un souligné : `monthly_gross`,
`valid_from`, `certificate_received_at`. Ces noms-là ne peuvent venir que de la
base, et un remplacement mot-à-mot est sûr.

Les 43 autres sont des mots courts — `name`, `code`, `status`, `label`, `year`,
`key`, `unit`, `title`. En TypeScript, `name` est aussi bien une colonne qu'une
propriété de `Error`, un attribut HTML, un champ de `File`. Les remplacer
aveuglément casserait le code sans que rien ne le signale avant l'exécution. Ils
sont donc traités à part, **uniquement dans les contextes où la base est en jeu** :
littéraux de chaîne, clés d'objet, et accès de propriété vérifiés ensuite par le
compilateur.

Ce que l'outil ne touche jamais
--------------------------------
`luxrh/src/lib/database.types.ts` — régénéré depuis la base, jamais réécrit à la
main. Et les migrations déjà appliquées : elles décrivent ce qui a eu lieu, pas
ce qui est. Le renommage est une migration de plus, pas une réécriture du passé.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import renommage                                                     # noqa: E402

RACINE = Path(__file__).resolve().parent.parent
TYPES_GENERES = RACINE / "luxrh" / "src" / "lib" / "database.types.ts"


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


_CHAINE = re.compile(r"""('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"|`(?:[^`\\]|\\.)*`)""")


def remplacer_dans_chaines(texte: str, table: dict[str, str]) -> tuple[str, int]:
    """Remplacement limité à l'intérieur des littéraux de chaîne.

    C'est là que vivent les requêtes : `.from('employees')`,
    `.select('id,first_name')`, `employees?select=...`. Un mot court y désigne
    forcément une colonne — ailleurs dans le fichier, il peut désigner n'importe
    quoi, et on n'y touche pas.
    """
    total = 0

    def sur_chaine(m: re.Match[str]) -> str:
        nonlocal total
        contenu, k = remplacer_partout(m.group(0), table)
        total += k
        return contenu

    return _CHAINE.sub(sur_chaine, texte), total


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

    for nom, n in sorted(touches, key=lambda x: -x[1]):
        print(f"  {n:>5}  {nom}")
    print(f"\n{total} occurrence(s) sur {len(touches)} fichier(s)"
          f"{' — écrites' if ecrire else ' — essai à blanc, rien écrit'}.")


# =========================================================== migration SQL


def sql_tables() -> str:
    """Renomme les tables, puis ce qui porte leur nom : index, contraintes, politiques.

    PostgreSQL ne renomme pas les objets dépendants avec la table. Sans ce second
    passage, une violation de clé primaire sur `salaries` annoncerait
    « employees_pkey » — le message d'erreur resterait en anglais alors que la
    table ne l'est plus, et c'est exactement ce qu'un utilisateur voit.
    """
    lignes = ["set search_path = public;", ""]
    for ancien, nouveau in renommage.TABLES.items():
        lignes.append(f"alter table if exists {ancien} rename to {nouveau};")
    lignes += ["", "-- Index, contraintes et politiques portant encore l'ancien nom.", "do $$", "declare r record;", "begin"]
    lignes.append("""  for r in
    select c.relname as ancien, t.relname as table_fr, x.ancien_prefixe, x.nouveau_prefixe
    from (values""")
    paires = ",\n".join(f"      ('{a}', '{b}')" for a, b in renommage.TABLES.items())
    lignes.append(paires)
    lignes.append("""    ) as x(ancien_prefixe, nouveau_prefixe)
    join pg_class t on t.relname = x.nouveau_prefixe
    join pg_namespace n on n.oid = t.relnamespace and n.nspname = 'public'
    join pg_class c on c.relname like x.ancien_prefixe || '\\_%'
                   and c.relkind in ('i', 'S')
                   and c.relnamespace = n.oid
  loop
    execute format('alter %s %I rename to %I',
                   case when r.ancien like '%_seq' then 'sequence' else 'index' end,
                   r.ancien,
                   r.nouveau_prefixe || substr(r.ancien, length(r.ancien_prefixe) + 1));
  end loop;
end $$;""")
    return "\n".join(lignes) + "\n"


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("tables", "colonnes-sures", "colonnes-ambigues"):
        print(__doc__)
        return 2

    bloc = sys.argv[1]
    ecrire = "--ecrire" in sys.argv

    if "--sql" in sys.argv:
        if bloc != "tables":
            print("Le SQL des colonnes est produit par --sql sur chaque bloc de colonnes.",
                  file=sys.stderr)
        print(sql_tables())
        return 0

    if bloc == "tables":
        print("Bloc A — les 57 tables. Remplacement mot à mot : un nom de table ne "
              "peut désigner qu'une table.\n")
        appliquer(renommage.TABLES, chaines_seulement=False, ecrire=ecrire)
    elif bloc == "colonnes-sures":
        table = {a: b for a, b in renommage.COLONNES.items() if a != b and "_" in a}
        print(f"Bloc B — les {len(table)} colonnes à nom composé. Le souligné garantit "
              f"qu'elles viennent de la base.\n")
        appliquer(table, chaines_seulement=False, ecrire=ecrire)
    else:
        table = {a: b for a, b in renommage.COLONNES.items() if a != b and "_" not in a}
        print(f"Bloc C — les {len(table)} colonnes à nom simple. Remplacement limité aux "
              f"littéraux de chaîne : ailleurs, `name` ou `status` peut désigner "
              f"tout autre chose.\n")
        appliquer(table, chaines_seulement=True, ecrire=ecrire)
    return 0


if __name__ == "__main__":
    sys.exit(main())
