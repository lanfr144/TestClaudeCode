"""Choix de la base de données par argument.

    streamlit run app.py -- --db supabase
    streamlit run app.py -- --db oracle --dsn hote:1521/XEPDB1 --user luxrh
    streamlit run app.py -- --db mysql  --dsn hote:3306/luxrh   --user luxrh

À défaut d'argument, la variable d'environnement ``LUXRH_DB`` fait foi, puis
``supabase``.

Ce que cette couche ne peut pas faire, et le dit
-----------------------------------------------

Le moteur de règles est écrit en PL/pgSQL : 272 fonctions, quelque 147 Ko de
source, qui portent l'intégralité du droit du travail luxembourgeois appliqué
par l'outil. Oracle et MySQL ne l'exécutent pas.

Sur ces deux bases, ce module transporte donc les **données** — schéma, lecture,
écriture, export et import de portabilité — mais toute évaluation de règle lève
``EngineUnavailable`` plutôt que de rendre une valeur vraisemblable. Une réponse
approximative sur un délai de préavis ou un salaire minimum est pire qu'un refus
net : elle se recopie dans un contrat.

Trois façons d'utiliser une base Oracle ou MySQL en pratique :

* pour **reprendre ou archiver** les données (le cas visé ici) ;
* pour **héberger le dossier** tandis que le moteur reste sur PostgreSQL ;
* après un **portage du moteur**, qui reste à faire et qu'il faudrait alors
  maintenir en trois exemplaires — ce que l'on déconseille : trois copies de la
  loi divergent, et la divergence se lit sur une fiche de paie.
"""

from __future__ import annotations

import os
import sys
from datetime import date, datetime
from typing import Any

CHOIX = ('supabase', 'oracle', 'mysql')


class EngineUnavailable(RuntimeError):
    """Le moteur de règles n'est pas disponible sur la base choisie."""


class ConfigurationManquante(RuntimeError):
    """Il manque un paramètre de connexion, et on ne l'invente pas."""


# --------------------------------------------------------------- arguments


def _argument(nom: str, argv: list[str]) -> str | None:
    """Lit ``--nom valeur`` ou ``--nom=valeur``."""
    prefixe = f'--{nom}'
    for i, a in enumerate(argv):
        if a == prefixe and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith(prefixe + '='):
            return a.split('=', 1)[1]
    return None


def lire_choix(argv: list[str] | None = None) -> dict[str, str | None]:
    """Résout le choix de base : argument, puis environnement, puis défaut."""
    argv = list(sys.argv if argv is None else argv)
    nom = (_argument('db', argv) or os.environ.get('LUXRH_DB') or 'supabase').lower()
    if nom not in CHOIX:
        raise ConfigurationManquante(
            f'Base « {nom} » inconnue. Valeurs acceptées : {", ".join(CHOIX)}.')
    return {
        'db': nom,
        'dsn': _argument('dsn', argv) or os.environ.get('LUXRH_DSN'),
        'user': _argument('user', argv) or os.environ.get('LUXRH_DB_USER'),
        'password': os.environ.get('LUXRH_DB_PASSWORD'),
    }


# ------------------------------------------------------------------ socle


class Backend:
    """Ce que toute base doit savoir faire."""

    nom: str = ''
    porte_le_moteur: bool = False

    def rows(self, table: str, columns: str = '*', **filtres: Any) -> list[dict]:
        raise NotImplementedError

    def insert(self, table: str, valeurs: dict) -> dict:
        raise NotImplementedError

    def update(self, table: str, identifiant: str, valeurs: dict) -> None:
        raise NotImplementedError

    def delete(self, table: str, identifiant: str) -> None:
        raise NotImplementedError

    def engine(self, fn: str, **params: Any) -> Any:
        raise EngineUnavailable(
            f'La base « {self.nom} » ne porte pas le moteur de règles : « {fn} » '
            'ne peut pas y être évaluée.\n'
            'Le moteur est écrit en PL/pgSQL et ne s\'exécute que sur PostgreSQL. '
            'Sur cette base, LuxRH lit et écrit les données, exporte et importe, '
            'mais ne décide rien — plutôt que de rendre une valeur vraisemblable '
            'sur un délai de préavis ou un salaire minimum.')


class SupabaseBackend(Backend):
    """PostgreSQL via Supabase : la seule base qui porte le moteur."""

    nom = 'supabase'
    porte_le_moteur = True

    def __init__(self, client_module):
        # Le module client garde la session de l'utilisateur : on ne la duplique
        # pas ici, sinon deux chemins d'authentification cohabitent.
        self._c = client_module

    def rows(self, table, columns='*', **filtres):
        return self._c.rows_supabase(table, columns, **filtres)

    def insert(self, table, valeurs):
        return self._c.client().table(table).insert(valeurs).execute().data[0]

    def update(self, table, identifiant, valeurs):
        self._c.client().table(table).update(valeurs).eq('id', identifiant).execute()

    def delete(self, table, identifiant):
        self._c.client().table(table).delete().eq('id', identifiant).execute()

    def engine(self, fn, **params):
        return self._c.engine_supabase(fn, **params)


# ------------------------------------------------------------ bases SQL


class SqlBackend(Backend):
    """Socle commun aux bases pilotées en SQL direct (DB-API 2.0)."""

    marque = '?'      # forme des paramètres liés
    guillemet = '"'   # délimiteur d'identifiant

    def __init__(self, connexion):
        self.connexion = connexion

    def _id(self, nom: str) -> str:
        g = self.guillemet
        return f'{g}{nom}{g}'

    def _lier(self, i: int, nom: str) -> str:
        return self.marque if self.marque == '%s' else f':{nom}'

    def _executer(self, sql: str, params: Any = ()) -> list[dict]:
        curseur = self.connexion.cursor()
        try:
            curseur.execute(sql, params)
            if curseur.description is None:
                self.connexion.commit()
                return []
            colonnes = [c[0].lower() for c in curseur.description]
            return [dict(zip(colonnes, ligne)) for ligne in curseur.fetchall()]
        finally:
            curseur.close()

    def rows(self, table, columns='*', **filtres):
        order = filtres.pop('_order', None)
        desc = filtres.pop('_desc', False)
        limit = filtres.pop('_limit', None)

        colonnes = '*' if columns == '*' else ', '.join(
            self._id(c.strip()) for c in columns.split(',') if '(' not in c)
        sql = f'select {colonnes} from {self._id(table)}'
        params: dict[str, Any] = {}
        if filtres:
            clauses = []
            for i, (cle, valeur) in enumerate(filtres.items()):
                clauses.append(f'{self._id(cle)} = {self._lier(i, cle)}')
                params[cle] = valeur
            sql += ' where ' + ' and '.join(clauses)
        if order:
            sql += f' order by {self._id(order)}' + (' desc' if desc else '')
        if limit:
            sql += self._limite(limit)
        return self._executer(sql, self._params(params))

    def _limite(self, n: int) -> str:
        return f' fetch first {int(n)} rows only'

    def _params(self, params: dict) -> Any:
        return params if self.marque != '%s' else tuple(params.values())

    def insert(self, table, valeurs):
        valeurs = {k: _serialiser(v) for k, v in valeurs.items()}
        colonnes = ', '.join(self._id(k) for k in valeurs)
        marques = ', '.join(self._lier(i, k) for i, k in enumerate(valeurs))
        self._executer(
            f'insert into {self._id(table)} ({colonnes}) values ({marques})',
            self._params(valeurs))
        self.connexion.commit()
        return valeurs

    def update(self, table, identifiant, valeurs):
        valeurs = {k: _serialiser(v) for k, v in valeurs.items()}
        affectations = ', '.join(
            f'{self._id(k)} = {self._lier(i, k)}' for i, k in enumerate(valeurs))
        params = {**valeurs, 'id_cible': identifiant}
        self._executer(
            f'update {self._id(table)} set {affectations} '
            f'where {self._id("id")} = {self._lier(99, "id_cible")}',
            self._params(params))
        self.connexion.commit()

    def delete(self, table, identifiant):
        self._executer(
            f'delete from {self._id(table)} where {self._id("id")} = '
            f'{self._lier(0, "id_cible")}',
            self._params({'id_cible': identifiant}))
        self.connexion.commit()


class OracleBackend(SqlBackend):
    nom = 'oracle'
    marque = ':n'
    guillemet = '"'

    def _id(self, nom: str) -> str:
        # Le schéma émis pour Oracle met les identifiants en majuscules.
        return f'"{nom.upper()}"'

    @staticmethod
    def connecter(dsn: str, user: str, password: str):
        import oracledb
        return oracledb.connect(user=user, password=password, dsn=dsn)


class MySqlBackend(SqlBackend):
    nom = 'mysql'
    marque = '%s'
    guillemet = '`'

    def _limite(self, n: int) -> str:
        return f' limit {int(n)}'

    @staticmethod
    def connecter(dsn: str, user: str, password: str):
        import mysql.connector
        hote, _, reste = dsn.partition(':')
        port, _, base = reste.partition('/')
        return mysql.connector.connect(
            host=hote, port=int(port or 3306), database=base,
            user=user, password=password)


def _serialiser(valeur: Any) -> Any:
    """Les dates partent en type natif ; le reste passe tel quel."""
    if isinstance(valeur, (date, datetime)):
        return valeur
    if isinstance(valeur, (dict, list)):
        import json
        return json.dumps(valeur, ensure_ascii=False)
    return valeur


# ------------------------------------------------------------ construction


def construire(choix: dict, client_module) -> Backend:
    """Fabrique le backend correspondant au choix résolu."""
    nom = choix['db']
    if nom == 'supabase':
        return SupabaseBackend(client_module)

    if not choix.get('dsn') or not choix.get('user'):
        raise ConfigurationManquante(
            f'La base « {nom} » demande --dsn et --user (mot de passe dans '
            'LUXRH_DB_PASSWORD). Rien n\'est deviné : une connexion approximative '
            'échoue plus tard et plus mal.')

    classe = OracleBackend if nom == 'oracle' else MySqlBackend
    try:
        connexion = classe.connecter(choix['dsn'], choix['user'],
                                     choix.get('password') or '')
    except ImportError as manquant:
        raise ConfigurationManquante(
            f'Le pilote {nom} n\'est pas installé : {manquant}. '
            f'Installez « {"oracledb" if nom == "oracle" else "mysql-connector-python"} ».'
        ) from manquant
    return classe(connexion)
