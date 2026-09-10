"""Émet le schéma LuxRH pour Oracle et MySQL à partir du catalogue PostgreSQL.

    python tools/emit_portable_schema.py catalogue.json schema/

Le catalogue se régénère depuis la base de référence (voir `CATALOGUE_SQL` en
bas de ce fichier). Rien n'est saisi à la main : le schéma dérivé suit la base
qui fait foi, sinon il diverge au premier changement.

Ce que la traduction ne peut pas porter est **écrit en clair dans le fichier
produit**, jamais omis en silence : une contrainte perdue est un invariant
perdu, et on ne s'en aperçoit qu'au moment où elle aurait dû protéger.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# --------------------------------------------------------------------- types

NUMERIC = re.compile(r'^numeric\((\d+),(\d+)\)$')


def oracle_type(col: dict, enums: dict, indexed: bool) -> str:
    t, udt = col['type'], col['udt']
    if t == 'uuid':
        return 'VARCHAR2(36)'
    if t == 'text':
        return 'VARCHAR2(4000)'
    if t == 'boolean':
        return 'NUMBER(1)'
    if t == 'date':
        return 'DATE'
    if t == 'time without time zone':
        # Oracle n'a pas de type TIME. L'heure est stockée en 'HH24:MI:SS' :
        # les comparaisons lexicographiques restent justes sur ce format.
        return 'VARCHAR2(8)'
    if t == 'timestamp with time zone':
        return 'TIMESTAMP(6) WITH TIME ZONE'
    if t == 'jsonb' or t.endswith('[]'):
        return 'CLOB'
    if t == 'bytea':
        return 'BLOB'
    if t == 'integer':
        return 'NUMBER(10)'
    if t == 'smallint':
        return 'NUMBER(5)'
    if t == 'bigint':
        return 'NUMBER(19)'
    if t == 'numeric':
        return 'NUMBER'
    m = NUMERIC.match(t)
    if m:
        return f'NUMBER({m.group(1)},{m.group(2)})'
    if udt in enums:
        longest = max(len(v) for v in enums[udt])
        return f'VARCHAR2({max(longest, 8)})'
    raise SystemExit(f'Type non traduit vers Oracle : {t} ({col["name"]})')


def mysql_type(col: dict, enums: dict, indexed: bool) -> str:
    t, udt = col['type'], col['udt']
    if t == 'uuid':
        return 'CHAR(36)'
    if t == 'text':
        # Une colonne TEXT ne peut pas porter une clé entière sous utf8mb4
        # (767 caractères au plus) : celles qui entrent dans une clé sont
        # bornées, les autres restent libres.
        return 'VARCHAR(255)' if indexed else 'TEXT'
    if t == 'boolean':
        return 'TINYINT(1)'
    if t == 'date':
        return 'DATE'
    if t == 'time without time zone':
        return 'TIME'
    if t == 'timestamp with time zone':
        # MySQL ne conserve pas le fuseau : tout est écrit en UTC.
        return 'DATETIME(6)'
    if t == 'jsonb' or t.endswith('[]'):
        return 'JSON'
    if t == 'bytea':
        return 'LONGBLOB'
    if t == 'integer':
        return 'INT'
    if t == 'smallint':
        return 'SMALLINT'
    if t == 'bigint':
        return 'BIGINT'
    if t == 'numeric':
        return 'DECIMAL(30,10)'
    m = NUMERIC.match(t)
    if m:
        return f'DECIMAL({m.group(1)},{m.group(2)})'
    if udt in enums:
        valeurs = ', '.join(f"'{v}'" for v in enums[udt])
        return f'ENUM({valeurs})'
    raise SystemExit(f'Type non traduit vers MySQL : {t} ({col["name"]})')


# ------------------------------------------------------------------ défauts

UUID_ORACLE = ("LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), "
               "'(.{8})(.{4})(.{4})(.{4})(.{12})', '\\1-\\2-\\3-\\4-\\5'))")


def default_for(expr: str | None, dialect: str) -> str | None:
    if not expr:
        return None
    e = expr.strip()
    if 'gen_random_uuid' in e or 'uuid_generate' in e:
        return UUID_ORACLE if dialect == 'oracle' else '(UUID())'
    if e.startswith('now()') or 'CURRENT_TIMESTAMP' in e:
        return 'SYSTIMESTAMP' if dialect == 'oracle' else 'CURRENT_TIMESTAMP(6)'
    if e in ('true', 'false'):
        return '1' if e == 'true' else '0'
    if e.startswith('nextval') or 'auth.uid' in e or '(' in e.split('::')[0][:-1]:
        return None                      # dépend du serveur : laissé à l'appelant
    litteral = e.split('::')[0].strip()  # 'x'::text → 'x'
    return litteral or None


# ------------------------------------------------------------- contraintes

# Ce qui, dans une contrainte CHECK, trahit une dépendance à PostgreSQL.
POSTGRES_ONLY = re.compile(
    r'\b(daterange|tstzrange|jsonb|~|@>|<@|\|\||array_|unnest|'
    r'regexp_|::|any\s*\(|char_length|fn_[a-z_]+)\b', re.I)


def translate_check(defn: str, dialect: str) -> tuple[str | None, str | None]:
    """Rend (contrainte traduite, motif du refus). L'une des deux est nulle."""
    corps = defn[len('CHECK '):].strip() if defn.upper().startswith('CHECK') else defn
    if POSTGRES_ONLY.search(corps):
        return None, 'expression propre à PostgreSQL'
    # Les booléens deviennent 0/1 : une contrainte qui les compare doit suivre.
    if re.search(r'\b(is true|is false)\b', corps, re.I):
        return None, 'comparaison booléenne à retranscrire en 0/1'
    return f'CHECK {corps}', None


def emit(cat: dict, dialect: str) -> str:
    enums = cat['enums']
    out: list[str] = []
    reportes: list[str] = []

    q = (lambda n: f'"{n.upper()}"') if dialect == 'oracle' else (lambda n: f'`{n}`')
    fin = ';' if dialect == 'mysql' else ';'

    out.append(f"-- Schéma LuxRH pour {dialect.upper()}, dérivé du catalogue PostgreSQL.")
    out.append("-- Généré par tools/emit_portable_schema.py — ne pas modifier à la main :")
    out.append("-- la base PostgreSQL fait foi, ce fichier la suit.")
    out.append("--")
    if dialect == 'oracle':
        out.append("-- Écarts assumés : pas de type TIME (heures en VARCHAR2 'HH24:MI:SS'),")
        out.append("-- booléens en NUMBER(1), énumérations en VARCHAR2 + CHECK, tableaux en JSON.")
    else:
        out.append("-- Écarts assumés : DATETIME ne conserve pas le fuseau (tout est écrit en UTC),")
        out.append("-- booléens en TINYINT(1), tableaux en JSON.")
    out.append("")

    # Les tables sont créées avant les clés étrangères : l'ordre de création
    # n'a alors plus d'importance, et un cycle de références ne bloque rien.
    for table in cat['tables']:
        nom = table['name']
        contraintes = table['constraints'] or []
        indexes = set()
        for co in contraintes:
            if co['type'] in ('p', 'u'):
                for c in re.findall(r'\(([^)]*)\)', co['def'])[:1]:
                    indexes.update(x.strip().strip('"') for x in c.split(','))

        out.append(f"create table {q(nom)} (")
        lignes = []
        for col in table['columns']:
            typ = (oracle_type if dialect == 'oracle' else mysql_type)(
                col, enums, col['name'] in indexes)
            morceau = f"  {q(col['name'])} {typ}"
            d = default_for(col.get('default'), dialect)
            if d:
                morceau += f" default {d}"
            if col['notnull']:
                morceau += " not null"
            if dialect == 'oracle' and col['udt'] in enums:
                valeurs = ', '.join(f"'{v}'" for v in enums[col['udt']])
                morceau += f"\n    constraint {nom[:20]}_{col['name'][:20]}_enum".lower()
                morceau += f" check ({q(col['name'])} in ({valeurs}))"
            if dialect == 'oracle' and col['type'] == 'boolean':
                morceau += f" constraint {nom[:20]}_{col['name'][:18]}_bool".lower()
                morceau += f" check ({q(col['name'])} in (0, 1))"
            if dialect == 'oracle' and col['type'] == 'jsonb':
                morceau += f" constraint {nom[:20]}_{col['name'][:18]}_json".lower()
                morceau += f" check ({q(col['name'])} is json)"
            lignes.append(morceau)

        for co in contraintes:
            if co['type'] == 'p':
                cols = re.findall(r'PRIMARY KEY \(([^)]*)\)', co['def'])
                if cols:
                    liste = ', '.join(q(c.strip().strip('"')) for c in cols[0].split(','))
                    lignes.append(f"  constraint {co['name'][:28]} primary key ({liste})")
            elif co['type'] == 'u':
                cols = re.findall(r'UNIQUE \(([^)]*)\)', co['def'])
                if cols:
                    liste = ', '.join(q(c.strip().strip('"')) for c in cols[0].split(','))
                    lignes.append(f"  constraint {co['name'][:28]} unique ({liste})")

        out.append(',\n'.join(lignes))
        out.append(f"){' engine=InnoDB default charset=utf8mb4' if dialect == 'mysql' else ''}{fin}")
        out.append("")

    # ------------------------------------------------------- clés étrangères
    out.append("-- Clés étrangères, posées après toutes les tables.")
    for table in cat['tables']:
        for co in table['constraints'] or []:
            if co['type'] != 'f':
                continue
            d = co['def']
            m = re.match(r'FOREIGN KEY \(([^)]*)\) REFERENCES ([\w."]+)\(([^)]*)\)(.*)', d)
            if not m:
                reportes.append(f"{table['name']}.{co['name']} : clé étrangère illisible — {d}")
                continue
            source, cible, colonnes, suite = m.groups()
            if '.' in cible and not cible.startswith('public'):
                # auth.users n'existe pas hors Supabase : la référence est notée,
                # pas inventée.
                reportes.append(
                    f"{table['name']}.{co['name']} : référence {cible}, propre à Supabase Auth. "
                    f"À rattacher à la table des comptes de la cible.")
                continue
            cible = cible.split('.')[-1].strip('"')
            action = ''
            if 'ON DELETE CASCADE' in suite:
                action = ' on delete cascade'
            elif 'ON DELETE SET NULL' in suite:
                action = ' on delete set null'
            sc = ', '.join(q(c.strip().strip('"')) for c in source.split(','))
            cc = ', '.join(q(c.strip().strip('"')) for c in colonnes.split(','))
            out.append(f"alter table {q(table['name'])} add constraint {co['name'][:28]} "
                       f"foreign key ({sc}) references {q(cible)} ({cc}){action}{fin}")
    out.append("")

    # -------------------------------------------------------------- CHECK
    out.append("-- Contraintes de validation.")
    for table in cat['tables']:
        for co in table['constraints'] or []:
            if co['type'] != 'c':
                continue
            traduite, motif = translate_check(co['def'], dialect)
            if traduite:
                out.append(f"alter table {q(table['name'])} add constraint "
                           f"{co['name'][:28]} {traduite}{fin}")
            else:
                reportes.append(f"{table['name']}.{co['name']} : {motif} — {co['def']}")
    out.append("")

    # ------------------------------------------------- contraintes d'exclusion
    exclusions = [(t['name'], co) for t in cat['tables']
                  for co in (t['constraints'] or []) if co['type'] == 'x']
    if exclusions:
        out.append("-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.")
        out.append("--")
        out.append("-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce")
        out.append("-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;")
        out.append("-- sans elles, un calcul de paie peut lire deux taux pour le même jour.")
        out.append("-- Un déclencheur les remplace ci-dessous, table par table.")
        out.append("")
        for nom, co in exclusions:
            out.extend(exclusion_trigger(nom, co, dialect, q, enums))
        out.append("")

    if reportes:
        out.append("-- ------------------------------------------------------------------")
        out.append("-- CE QUI N'A PAS ÉTÉ TRADUIT — à reprendre à la main.")
        out.append("-- Rien n'est omis en silence : une contrainte perdue est un invariant")
        out.append("-- perdu, et l'on ne s'en aperçoit qu'au moment où elle aurait servi.")
        out.append("-- ------------------------------------------------------------------")
        for r in sorted(set(reportes)):
            for ligne in re.findall(r'.{1,96}(?:\s|$)', r):
                out.append(f"--   {ligne.rstrip()}")
    return '\n'.join(out) + '\n'


def exclusion_trigger(table: str, co: dict, dialect: str, q, enums) -> list[str]:
    """Reproduit une contrainte d'exclusion de p\u00e9riodes par un d\u00e9clencheur.

    C\u00f4t\u00e9 Oracle, le d\u00e9clencheur est de niveau instruction et non ligne : un
    d\u00e9clencheur ligne qui interroge sa propre table l\u00e8ve ORA-04091 (mutating
    table). Il rev\u00e9rifie donc toute la table \u00e0 chaque \u00e9criture -- co\u00fbteux, mais
    ces tables de r\u00e9f\u00e9rentiel sont petites et rarement \u00e9crites, et une garantie
    approximative sur l'unicit\u00e9 d'un taux \u00e0 une date ne vaut rien.
    """
    d = co['def']
    egalites = re.findall(r'(\w+)\s+WITH\s+=', d)
    plage = re.search(r'daterange\((\w+),\s*(\w+)', d)
    if not plage:
        return [f"-- {table}.{co['name']} : forme non reconnue -- {d}", ""]
    debut, fin_col = plage.groups()
    nom = f"{table[:24]}_no_overlap".lower()
    INFINI = "date '9999-12-31'" if dialect == 'oracle' else "'9999-12-31'"

    # Les cl\u00e9s d'\u00e9galit\u00e9 peuvent \u00eatre nulles : deux lignes sans CCT partagent
    # bien la m\u00eame port\u00e9e, et doivent donc \u00eatre compar\u00e9es entre elles.
    if dialect == 'oracle':
        cles = ' and '.join(
            f'(a.{q(c)} = b.{q(c)} or (a.{q(c)} is null and b.{q(c)} is null))'
            for c in egalites) or '1=1'
        return [
            f"create or replace trigger {nom}",
            f"  after insert or update on {q(table)}",
            "declare",
            "  n number;",
            "begin",
            "  select count(*) into n",
            f"    from {q(table)} a join {q(table)} b on a.{q('id')} <> b.{q('id')}",
            f"   where {cles}",
            f"     and a.{q(debut)} < nvl(b.{q(fin_col)}, {INFINI})",
            f"     and nvl(a.{q(fin_col)}, {INFINI}) > b.{q(debut)};",
            "  if n > 0 then",
            f"    raise_application_error(-20001,",
            f"      'Deux periodes se recouvrent sur {table} : une date ne peut avoir qu''une valeur');",
            "  end if;",
            "end;",
            "/",
            "",
        ]

    cles = ' and '.join(f'a.{q(c)} <=> b.{q(c)}' for c in egalites) or '1=1'
    lignes = ["delimiter $$"]
    for moment in ('insert', 'update'):
        lignes += [
            f"create trigger {nom}_{moment} after {moment} on {q(table)}",
            "for each row begin",
            "  declare n int;",
            "  select count(*) into n",
            f"    from {q(table)} a join {q(table)} b on a.{q('id')} <> b.{q('id')}",
            f"   where {cles}",
            f"     and a.{q(debut)} < ifnull(b.{q(fin_col)}, {INFINI})",
            f"     and ifnull(a.{q(fin_col)}, {INFINI}) > b.{q(debut)};",
            "  if n > 0 then",
            "    signal sqlstate '45000'",
            f"      set message_text = 'Deux periodes se recouvrent sur {table}';",
            "  end if;",
            "end$$",
        ]
    lignes += ["delimiter ;", ""]
    return lignes


CATALOGUE_SQL = """
-- Régénérer le catalogue depuis la base PostgreSQL de référence :
select jsonb_build_object(
  'enums', (select jsonb_object_agg(t.typname, vals) from (
      select t.typname, jsonb_agg(e.enumlabel order by e.enumsortorder) as vals
        from pg_type t join pg_enum e on e.enumtypid = t.oid
        join pg_namespace n on n.oid = t.typnamespace where n.nspname='public'
       group by t.typname) t),
  'tables', (select jsonb_agg(x order by x->>'name') from (
      select jsonb_build_object(
        'name', c.relname,
        'columns', (select jsonb_agg(jsonb_build_object(
              'name', a.attname, 'type', format_type(a.atttypid, a.atttypmod),
              'udt', tt.typname, 'notnull', a.attnotnull,
              'default', pg_get_expr(d.adbin, d.adrelid)) order by a.attnum)
            from pg_attribute a
            join pg_type tt on tt.oid = a.atttypid
            left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
           where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped),
        'constraints', (select jsonb_agg(jsonb_build_object(
              'name', co.conname, 'type', co.contype,
              'def', pg_get_constraintdef(co.oid)) order by co.contype, co.conname)
            from pg_constraint co where co.conrelid = c.oid)
      ) as x
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname='public' and c.relkind='r') s));
"""


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__ + CATALOGUE_SQL)
    catalogue = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
    dossier = Path(sys.argv[2])
    dossier.mkdir(parents=True, exist_ok=True)
    for dialecte in ('oracle', 'mysql'):
        cible = dossier / f'{dialecte}.sql'
        texte = emit(catalogue, dialecte)
        cible.write_text(texte, encoding='utf-8', newline='\n')
        reportes = texte.count('\n--   ')
        print(f'{cible} : {len(catalogue["tables"])} tables, '
              f'{texte.count("create table")} créations, {reportes} point(s) à reprendre')
