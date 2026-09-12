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
CARACTERES = re.compile(r'^(character|character varying)\((\d+)\)$')


def oracle_type(col: dict, enums: dict, indexed: bool) -> str:
    t, udt = col['type'], col['udt']
    if t == 'uuid':
        return 'VARCHAR2(36 CHAR)'
    if t == 'text':
        return 'VARCHAR2(4000 CHAR)'
    if t == 'boolean':
        # Type natif depuis Oracle 23ai. La cible étant 26ai, plus besoin du
        # NUMBER(1) + contrainte de l'ancienne version : un booléen se déclare.
        return 'BOOLEAN'
    if t == 'date':
        return 'DATE'
    if t == 'time without time zone':
        # Une heure du jour n'est pas une DATE : la stocker en DATE traîne une
        # date fantôme au 1er janvier de l'an zéro, et la stocker en VARCHAR2
        # interdit toute arithmétique. INTERVAL DAY TO SECOND dit exactement ce
        # qu'on veut — une durée depuis minuit — et s'additionne.
        return 'INTERVAL DAY(0) TO SECOND(0)'
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
    m = CARACTERES.match(t)
    if m:
        # `character(n)` est à longueur fixe et complété par des espaces : CHAR
        # se comporte de même sur Oracle, la sémantique est préservée.
        return (f'CHAR({m.group(2)} CHAR)' if m.group(1) == 'character'
                else f'VARCHAR2({m.group(2)})')
    if udt in enums:
        longest = max(len(v) for v in enums[udt])
        return f'VARCHAR2({max(longest, 8)} CHAR)'
    raise SystemExit(f'Type non traduit vers Oracle : {t} ({col["nom"]})')


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
    m = CARACTERES.match(t)
    if m:
        return (f'CHAR({m.group(2)})' if m.group(1) == 'character'
                else f'VARCHAR({m.group(2)})')
    if udt in enums:
        # Pas de type ENUM : une colonne ENUM ne peut pas porter de clé
        # étrangère vers sa table de référence, et c'est cette clé qui remplace
        # désormais la liste de valeurs figée.
        return 'VARCHAR(64)'
    raise SystemExit(f'Type non traduit vers MySQL : {t} ({col["nom"]})')


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
        out.append("-- Cible : Oracle 26ai. VARCHAR2 en sémantique CHAR (un « é » compte pour")
        out.append("-- un caractère, non pour deux octets). BOOLEAN natif, heures en INTERVAL DAY TO")
        out.append("-- SECOND, énumérations en tables de référence, tableaux et jsonb en CLOB.")
        out.append("-- Les clés étrangères d'auteur pointent vers APP_USERS.")
    else:
        out.append("-- Écarts assumés : DATETIME ne conserve pas le fuseau (tout est écrit en UTC),")
        out.append("-- booléens en TINYINT(1), énumérations en tables de référence,")
        out.append("-- tableaux et jsonb en JSON. Les clés d'auteur pointent vers app_users.")
    out.append("")

    # ------------------------------------------------- tables de référence
    # Les énumérations PostgreSQL deviennent des tables : un ensemble de valeurs
    # se maintient alors par DML, sans migration ni indisponibilité, et porte ses
    # propres dates de validité. Une valeur retirée du catalogue reste lisible
    # dans les lignes qui la référencent — ce qu'un `check` ne permet pas.
    if enums:
        out.append("-- ------------------------------------------------------------------")
        out.append("-- TABLES DE RÉFÉRENCE — à la place des types énumérés de PostgreSQL.")
        out.append("-- Chaque valeur porte sa période d'usage : on retire une valeur en la")
        out.append("-- datant, jamais en la supprimant, sinon l'historique devient illisible.")
        out.append("-- ------------------------------------------------------------------")
        out.append("")
        for nom_enum in sorted(enums):
            tref = f"ref_{nom_enum}"
            out.append(f"create table {q(tref)} (")
            code_type = 'VARCHAR2(64 CHAR)' if dialect == 'oracle' else 'VARCHAR(64)'
            texte = 'VARCHAR2(200 CHAR)' if dialect == 'oracle' else 'VARCHAR(200)'
            out.append(f"  {q('code')} {code_type} not null,")
            out.append(f"  {q('label')} {texte},")
            out.append(f"  {q('sort_order')} NUMBER(5)," if dialect == 'oracle'
                       else f"  {q('sort_order')} SMALLINT,")
            out.append(f"  {q('valid_from')} DATE default "
                       + ("date '1900-01-01'," if dialect == 'oracle' else "'1900-01-01',"))
            out.append(f"  {q('valid_to')} DATE,")
            out.append(f"  constraint {tref[:24]}_pk primary key ({q('code')})")
            out.append(f"){' engine=InnoDB default charset=utf8mb4' if dialect == 'mysql' else ''}{fin}")
            for rang, valeur in enumerate(enums[nom_enum], start=1):
                out.append(f"insert into {q(tref)} ({q('code')}, {q('label')}, {q('sort_order')}) "
                           f"values ('{valeur}', '{valeur.replace(chr(39), chr(39) * 2)}', {rang}){fin}")
            out.append("")
        out.append("")

    # Les tables sont créées avant les clés étrangères : l'ordre de création
    # n'a alors plus d'importance, et un cycle de références ne bloque rien.
    for table in cat['tables']:
        nom = table['nom']
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
                col, enums, col['nom'] in indexes)
            morceau = f"  {q(col['nom'])} {typ}"
            d = default_for(col.get('default'), dialect)
            if d:
                morceau += f" default {d}"
            if col['notnull']:
                morceau += " not null"
            # Plus de contrainte `check` sur une énumération : la valeur est
            # contrôlée par une clé étrangère vers sa table de référence, posée
            # plus bas. Un ensemble de valeurs se maintient par DML, pas par
            # migration — c'est tout l'intérêt.
            #
            # Plus de contrainte sur un booléen non plus : le type BOOLEAN natif
            # d'Oracle 23ai s'en charge.
            if dialect == 'oracle' and col['type'] == 'jsonb':
                morceau += f" constraint {nom[:20]}_{col['nom'][:18]}_json".lower()
                morceau += f" check ({q(col['nom'])} is json)"
            lignes.append(morceau)

        for co in contraintes:
            if co['type'] == 'p':
                cols = re.findall(r'PRIMARY KEY \(([^)]*)\)', co['def'])
                if cols:
                    liste = ', '.join(q(c.strip().strip('"')) for c in cols[0].split(','))
                    lignes.append(f"  constraint {co['nom'][:28]} primary key ({liste})")
            elif co['type'] == 'u':
                cols = re.findall(r'UNIQUE \(([^)]*)\)', co['def'])
                if cols:
                    liste = ', '.join(q(c.strip().strip('"')) for c in cols[0].split(','))
                    lignes.append(f"  constraint {co['nom'][:28]} unique ({liste})")

        out.append(',\n'.join(lignes))
        out.append(f"){' engine=InnoDB default charset=utf8mb4' if dialect == 'mysql' else ''}{fin}")
        out.append("")

    # ------------------------------------------------------- clés étrangères
    out.append("-- Clés étrangères, posées après toutes les tables.")

    # Chaque colonne qui portait une énumération pointe vers sa table de
    # référence. C'est ce qui remplace la contrainte `check` : même garantie,
    # mais l'ensemble des valeurs se modifie par DML.
    for table in cat['tables']:
        for col in table['columns']:
            if col['udt'] not in enums:
                continue
            contrainte = f"{table['nom'][:18]}_{col['nom'][:16]}_ref".lower()
            out.append(f"alter table {q(table['nom'])} add constraint {contrainte[:28]} "
                       f"foreign key ({q(col['nom'])}) "
                       f"references {q('ref_' + col['udt'])} ({q('code')}){fin}")
    out.append("")

    for table in cat['tables']:
        for co in table['constraints'] or []:
            if co['type'] != 'f':
                continue
            d = co['def']
            m = re.match(r'FOREIGN KEY \(([^)]*)\) REFERENCES ([\w."]+)\(([^)]*)\)(.*)', d)
            if not m:
                reportes.append(f"{table['nom']}.{co['nom']} : clé étrangère illisible — {d}")
                continue
            source, cible, colonnes, suite = m.groups()
            if '.' in cible and not cible.startswith('public'):
                # `auth.users` n'existe pas hors Supabase. Signaler la référence
                # sans la rebrancher revenait à livrer un schéma sans intégrité
                # sur « qui a fait quoi » : quatorze clés étrangères d'auteur
                # étaient purement abandonnées. Elles pointent désormais vers
                # `app_users`, qui porte les mêmes UUID d'un moteur à l'autre.
                if cible.split('.')[-1].strip('"').lower() == 'users':
                    cible = 'app_users'
                else:
                    reportes.append(
                        f"{table['nom']}.{co['nom']} : référence {cible}, hors du schéma "
                        f"applicatif. À rattacher à la table correspondante de la cible.")
                    continue
            cible = cible.split('.')[-1].strip('"')
            action = ''
            if 'ON DELETE CASCADE' in suite:
                action = ' on delete cascade'
            elif 'ON DELETE SET NULL' in suite:
                action = ' on delete set null'
            sc = ', '.join(q(c.strip().strip('"')) for c in source.split(','))
            cc = ', '.join(q(c.strip().strip('"')) for c in colonnes.split(','))
            out.append(f"alter table {q(table['nom'])} add constraint {co['nom'][:28]} "
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
                out.append(f"alter table {q(table['nom'])} add constraint "
                           f"{co['nom'][:28]} {traduite}{fin}")
            else:
                reportes.append(f"{table['nom']}.{co['nom']} : {motif} — {co['def']}")
    out.append("")

    # ------------------------------------------------------------ commentaires
    # Le catalogue ne les portait pas et l'émetteur ne les écrivait pas : les
    # commentaires posés côté PostgreSQL ne sont jamais arrivés dans les schémas
    # dérivés. Un schéma sans commentaire oblige chaque lecteur à redécouvrir ce
    # que la colonne signifie — et c'est ce que la documentation coûte le plus
    # cher à refaire.
    def litteral(texte: str) -> str:
        return "'" + texte.replace("'", "''") + "'"

    commentes_t = commentes_c = 0
    lignes_com: list[str] = []
    for table in cat['tables']:
        if table.get('commentaire'):
            commentes_t += 1
            lignes_com.append(
                f"comment on table {q(table['nom'])} is {litteral(table['commentaire'])}{fin}")
        for col in table['columns']:
            if col.get('commentaire'):
                commentes_c += 1
                lignes_com.append(
                    f"comment on column {q(table['nom'])}.{q(col['nom'])} "
                    f"is {litteral(col['commentaire'])}{fin}")
    for nom_enum in sorted(enums):
        lignes_com.append(
            f"comment on table {q('ref_' + nom_enum)} is "
            f"{litteral('Table de référence issue du type énuméré PostgreSQL ' + nom_enum + '.')}{fin}")

    if lignes_com:
        out.append("-- ------------------------------------------------------------------")
        out.append(f"-- COMMENTAIRES — {commentes_t} table(s) et {commentes_c} colonne(s).")
        out.append("-- Repris tels quels du schéma PostgreSQL, qui fait foi.")
        out.append("-- ------------------------------------------------------------------")
        out.extend(lignes_com)
        out.append("")

    # Les colonnes sans commentaire sont dites, pas tues : c'est une dette
    # visible, et elle se comble une colonne à la fois.
    sans = [f"{t['nom']}.{c['nom']}" for t in cat['tables']
            for c in t['columns'] if not c.get('commentaire')]
    if sans:
        reportes.append(
            f"{len(sans)} colonne(s) sans commentaire dans le schéma PostgreSQL source — "
            f"elles en manquent donc ici aussi. À commenter côté PostgreSQL, "
            f"jamais directement ici. Premières : " + ', '.join(sans[:6]) + '…')

    # ------------------------------------------------- contraintes d'exclusion
    exclusions = [(t, co) for t in cat['tables']
                  for co in (t['constraints'] or []) if co['type'] == 'x']
    if exclusions:
        out.append("-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.")
        out.append("--")
        out.append("-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce")
        out.append("-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;")
        out.append("-- sans elles, un calcul de paie peut lire deux taux pour le même jour.")
        out.append("-- Un déclencheur les remplace ci-dessous, table par table.")
        out.append("")
        for table, co in exclusions:
            out.extend(exclusion_trigger(table, co, dialect, q, enums))
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


def exclusion_trigger(table_def: dict, co: dict, dialect: str, q, enums) -> list[str]:
    """Reproduit une contrainte d'exclusion de p\u00e9riodes par un d\u00e9clencheur.

    Ne v\u00e9rifie que les lignes \u00e9crites
    ---------------------------------
    La premi\u00e8re version de ce g\u00e9n\u00e9rateur rev\u00e9rifiait **toute la table** \u00e0 chaque
    \u00e9criture : un `count(*)` sur l'auto-jointure compl\u00e8te `a join b on a.id <> b.id`.
    Correct, mais quadratique -- et faux comme principe : un d\u00e9clencheur n'a pas
    \u00e0 contr\u00f4ler des lignes que personne n'a touch\u00e9es.

    Il ne compare d\u00e9sormais que les lignes ins\u00e9r\u00e9es ou modifi\u00e9es aux seules
    lignes avec lesquelles elles peuvent entrer en conflit -- celles qui
    partagent leurs cl\u00e9s d'\u00e9galit\u00e9 et dont la p\u00e9riode recoupe la leur.

    `exists` plut\u00f4t que `count(*)`
    ------------------------------
    Un `count(*)` compte tous les conflits avant de conclure qu'il y en a au
    moins un. `exists` s'arr\u00eate au premier. Sur Oracle, cela rend `rownum <= 1`
    superflu : la condition d'arr\u00eat est dans l'op\u00e9rateur lui-m\u00eame.

    Oracle : d\u00e9clencheur compos\u00e9
    ----------------------------
    Un d\u00e9clencheur ligne qui interroge sa propre table l\u00e8ve ORA-04091 (mutating
    table). Le d\u00e9clencheur compos\u00e9 l\u00e8ve l'obstacle proprement : la section
    `after each row` **collecte** les identifiants \u00e9crits, la section
    `after statement` les v\u00e9rifie -- la table n'est alors plus en mutation.
    """
    table = table_def['nom']
    d = co['def']
    egalites = re.findall(r'(\w+)\s+WITH\s+=', d)
    plage = re.search(r'daterange\((\w+),\s*(\w+)', d)
    if not plage:
        return [f"-- {table}.{co['nom']} : forme non reconnue -- {d}", ""]
    debut, fin_col = plage.groups()
    nom = f"{table[:24]}_no_overlap".lower()

    # Pas de sentinelle sur une colonne qui ne peut pas être nulle
    # -------------------------------------------------------------
    # Ce générateur enrobait autrefois les deux bornes dans `nvl(..., date
    # '9999-12-31')`. C'était faux à deux titres depuis la migration 70.
    #
    # D'abord, `fin_validite` et `valid_to` sont `not null` : l'enrobage ne
    # protégeait de rien et masquait l'invariant au lecteur, qui pouvait croire
    # que la colonne admet des nuls.
    #
    # Ensuite, la sentinelle du projet est **2037-12-31**, pas 9999-12-31 —
    # choisie pour tenir dans un `time_t` 32 bits signé. Deux sentinelles
    # concurrentes dans un même schéma, c'est la garantie qu'un jour l'une sera
    # comparée à l'autre.
    #
    # On ne pose donc un `coalesce` que là où la colonne est réellement nullable :
    # `contrats.date_fin` l'est, et doit le rester — un contrat à durée
    # indéterminée n'a pas de fin, et lui en inventer une dirait que tout CDI
    # s'arrête en 2037.
    colonnes = {c['nom']: c for c in (table_def.get('columns') or [])}
    fin_nullable = not colonnes.get(fin_col, {}).get('notnull', False)
    SENTINELLE = "date '2037-12-31'" if dialect == 'oracle' else "'2037-12-31'"
    enrobe_ora = (lambda expr: f"nvl({expr}, {SENTINELLE})") if fin_nullable else (lambda expr: expr)
    enrobe_my = (lambda expr: f"ifnull({expr}, {SENTINELLE})") if fin_nullable else (lambda expr: expr)

    # Les cl\u00e9s d'\u00e9galit\u00e9 peuvent \u00eatre nulles : deux lignes sans CCT partagent
    # bien la m\u00eame port\u00e9e, et doivent donc \u00eatre compar\u00e9es entre elles.
    if dialect == 'oracle':
        # Les clés d'égalité peuvent être nulles : deux lignes sans CCT partagent
        # bien la même portée, et doivent donc être comparées entre elles.
        cles = ' and '.join(
            f'(a.{q(c)} = b.{q(c)} or (a.{q(c)} is null and b.{q(c)} is null))'
            for c in egalites) or '1=1'
        return [
            f"create or replace trigger {nom}",
            f"  for insert or update on {q(table)}",
            "  compound trigger",
            "",
            "  -- Les identifiants écrits par l'instruction en cours, et eux seuls.",
            f"  type t_ids is table of {q(table)}.{q('id')}%type index by pls_integer;",
            "  g_ids t_ids;",
            "",
            "  after each row is",
            "  begin",
            f"    g_ids(g_ids.count + 1) := :new.{q('id')};",
            "  end after each row;",
            "",
            "  after statement is",
            "    v_conflit number;",
            "  begin",
            "    -- La table n'est plus en mutation ici : on peut l'interroger.",
            "    for i in 1 .. g_ids.count loop",
            "      begin",
            "        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en",
            "        -- compter davantage pour savoir qu'il y en a un.",
            "        select 1 into v_conflit from dual",
            "         where exists (",
            "           select 1",
            f"             from {q(table)} a",
            f"             join {q(table)} b on b.{q('id')} <> a.{q('id')}",
            f"            where a.{q('id')} = g_ids(i)",
            f"              and {cles}",
            f"              and a.{q(debut)} < {enrobe_ora(f'b.{q(fin_col)}')}",
            f"              and {enrobe_ora(f'a.{q(fin_col)}')} > b.{q(debut)});",
            "        raise_application_error(-20001,",
            f"          'Deux periodes se recouvrent sur {table} : une date ne peut avoir qu''une valeur');",
            "      exception",
            "        when no_data_found then null;   -- aucun conflit sur cette ligne",
            "      end;",
            "    end loop;",
            "  end after statement;",
            "",
            f"end {nom};",
            "/",
            "",
        ]

    # MySQL : déclencheur ligne. `new` est la ligne écrite -- on ne compare
    # qu'elle, jamais la table à elle-même. `<=>` est l'égalité sûre aux nuls.
    cles = ' and '.join(f'new.{q(c)} <=> b.{q(c)}' for c in egalites) or '1=1'
    lignes = ["delimiter $$"]
    for moment in ('insert', 'update'):
        lignes += [
            f"create trigger {nom}_{moment} after {moment} on {q(table)}",
            "for each row begin",
            "  declare v_conflit int;",
            "  select exists (",
            "    select 1",
            f"      from {q(table)} b",
            f"     where b.{q('id')} <> new.{q('id')}",
            f"       and {cles}",
            f"       and new.{q(debut)} < {enrobe_my(f'b.{q(fin_col)}')}",
            f"       and {enrobe_my(f'new.{q(fin_col)}')} > b.{q(debut)}",
            "  ) into v_conflit;",
            "  if v_conflit then",
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
