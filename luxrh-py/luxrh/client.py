"""Accès aux données et au moteur de règles.

Le principe est le même que côté React : l'application Python affiche et saisit,
le serveur calcule, valide et décide. Aucune règle légale n'est évaluée ici.
"""

from __future__ import annotations

import os
from datetime import date
from pathlib import Path
from typing import Any

import streamlit as st
from supabase import Client, create_client

from . import backends
# Le client synchrone exige SyncClientOptions : la classe de base ClientOptions
# ne porte pas l'attribut `storage` qu'il attend.
from supabase.lib.client_options import SyncClientOptions

ROOT = Path(__file__).resolve().parent.parent


def _load_env() -> dict[str, str]:
    """Variables d'environnement, sinon le .env.local de l'application React."""
    env: dict[str, str] = {}
    for candidate in (ROOT / ".env", ROOT.parent / "luxrh" / ".env.local"):
        if candidate.exists():
            for line in candidate.read_text(encoding="utf-8").splitlines():
                if "=" in line and not line.strip().startswith("#"):
                    key, _, value = line.partition("=")
                    env.setdefault(key.strip(), value.strip())
    for key in ("VITE_SUPABASE_URL", "VITE_SUPABASE_ANON_KEY"):
        if os.environ.get(key):
            env[key] = os.environ[key]
    return env


@st.cache_resource
def _base_client() -> Client:
    env = _load_env()
    url = env.get("VITE_SUPABASE_URL")
    key = env.get("VITE_SUPABASE_ANON_KEY")
    if not url or not key:
        raise RuntimeError(
            "Configuration Supabase manquante : renseignez VITE_SUPABASE_URL et "
            "VITE_SUPABASE_ANON_KEY dans luxrh-py/.env ou dans luxrh/.env.local."
        )
    # PKCE renvoie le jeton de confirmation en paramètre de requête (`?code=`).
    # Streamlit ne peut pas lire un fragment d'URL (`#...`) : le navigateur ne le
    # transmet jamais au serveur. Sans PKCE, aucun lien de confirmation n'est
    # exploitable ici.
    return create_client(url, key, options=SyncClientOptions(flow_type="pkce"))


def app_url() -> str:
    """URL de retour des liens de confirmation, à autoriser côté Supabase."""
    env = _load_env()
    return os.environ.get("LUXRH_APP_URL") or env.get("LUXRH_APP_URL") or "http://localhost:8501"


def client() -> Client:
    """Client porteur de la session de l'utilisateur connecté.

    La session est réappliquée à chaque rerun : Streamlit reconstruit la page à
    chaque interaction, et le client mis en cache est partagé par le processus.
    """
    sb = _base_client()
    session = st.session_state.get("session")
    if session:
        sb.auth.set_session(session["access_token"], session["refresh_token"])
    return sb


# --------------------------------------------------------------------- session


def sign_in(email: str, password: str) -> None:
    result = _base_client().auth.sign_in_with_password({"courriel": email, "password": password})
    _store_session(result)


def _store_session(result) -> None:
    st.session_state["session"] = {
        "access_token": result.session.access_token,
        "refresh_token": result.session.refresh_token,
        "compte_id": result.user.id,
        "courriel": result.user.email,
    }
    st.cache_data.clear()


class EmailAlreadyRegistered(Exception):
    """L'adresse existe déjà : Supabase répond « succès » sans envoyer de courriel."""


def sign_up(email: str, password: str, nom_complet: str, org_name: str, genre_organisation: str) -> bool:
    """Ouvre un espace. Retourne True si une session est ouverte immédiatement.

    Lève EmailAlreadyRegistered lorsque l'adresse est déjà prise. Supabase ne le
    dit pas explicitement, pour ne pas révéler quels comptes existent, mais
    renvoie alors un utilisateur dépourvu d'identité.
    """
    result = _base_client().auth.sign_up(
        {
            "courriel": email,
            "password": password,
            "options": {
                "email_redirect_to": app_url(),
                "data": {
                    "nom_complet": nom_complet,
                    "organization_name": org_name,
                    "organization_kind": genre_organisation,
                },
            },
        }
    )

    if result.user and not (result.user.identities or []):
        raise EmailAlreadyRegistered(email)

    if result.session:
        _store_session(result)
        return True
    return False


def consume_confirmation_code() -> bool:
    """Ouvre la session à partir du `?code=` déposé par le lien de confirmation."""
    code = st.query_params.get("code")
    if not code or st.session_state.get("session"):
        return False
    try:
        result = _base_client().auth.exchange_code_for_session({"auth_code": code})
        if result.session:
            _store_session(result)
            st.query_params.clear()
            return True
    except Exception as error:  # lien expiré, déjà consommé, ou autre navigateur
        st.session_state["confirmation_error"] = str(error)
    st.query_params.clear()
    return False


def sign_out() -> None:
    try:
        client().auth.sign_out()
    except Exception:  # la session peut déjà être expirée côté serveur
        pass
    st.session_state.clear()
    st.cache_data.clear()


def is_signed_in() -> bool:
    return bool(st.session_state.get("session"))


# ---------------------------------------------------------------------- moteur


@st.cache_resource
def backend() -> backends.Backend:
    """Base choisie par argument (--db), sinon LUXRH_DB, sinon Supabase."""
    import sys as _sys
    return backends.construire(backends.lire_choix(_sys.argv), _sys.modules[__name__])


def engine_supabase(fn: str, **params: Any) -> Any:
    """Appelle une fonction du moteur de règles PostgreSQL."""
    clean = {k: (v.isoformat() if isinstance(v, date) else v) for k, v in params.items()}
    return client().rpc(fn, clean).execute().data


def engine(fn: str, **params: Any) -> Any:
    """Évalue une règle côté serveur.

    Sur une base qui ne porte pas le moteur, lève EngineUnavailable plutôt que
    de rendre une valeur vraisemblable : un délai de préavis approximatif se
    recopie dans un contrat.
    """
    return backend().engine(fn, **params)


@st.cache_data(ttl=60, show_spinner=False)
def engine_cached(_token: str, fn: str, **params: Any) -> Any:
    """Version mise en cache. `_token` isole le cache par session."""
    return engine(fn, **params)


def call(fn: str, **params: Any) -> Any:
    """Appel mis en cache pour la durée d'affichage d'une page."""
    token = st.session_state.get("session", {}).get("access_token", "")
    return engine_cached(token, fn, **params)


def table(name: str, columns: str = "*") -> Any:
    return client().table(name).select(columns)


def rows(name: str, columns: str = "*", **filters: Any) -> list[dict]:
    return backend().rows(name, columns, **filters)


def rows_supabase(name: str, columns: str = "*", **filters: Any) -> list[dict]:
    query = client().table(name).select(columns)
    order = filters.pop("_order", None)
    desc = filters.pop("_desc", False)
    limit = filters.pop("_limit", None)
    for key, value in filters.items():
        query = query.eq(key, value)
    if order:
        query = query.order(order, desc=desc)
    if limit:
        query = query.limit(limit)
    return query.execute().data or []


def invalidate() -> None:
    """À appeler après toute écriture : les lectures suivantes repartent du serveur."""
    st.cache_data.clear()


# ------------------------------------------------------------------ contexte


def profile() -> dict | None:
    session = st.session_state.get("session")
    if not session:
        return None
    if "profile" not in st.session_state:
        data = (
            client()
            .table("profils")
            .select("*, organisations(*)")
            .eq("id", session["compte_id"])
            .maybe_single()
            .execute()
        )
        st.session_state["profile"] = data.data if data else None
    return st.session_state.get("profile")


def societes() -> list[dict]:
    if "societes" not in st.session_state:
        st.session_state["societes"] = (
            client()
            .table("societes")
            .select(
                "*, conventions_de_la_societe(debut_validite, fin_validite, "
                "conventions_collectives(nom, code, secteur, portee))"
            )
            .order("raison_sociale")
            .execute()
            .data
            or []
        )
    return st.session_state["societes"]


def refresh_companies() -> None:
    st.session_state.pop("societes", None)


def active_company() -> dict | None:
    all_companies = societes()
    if not all_companies:
        return None
    active_id = st.session_state.get("societe_id")
    for company in all_companies:
        if company["id"] == active_id:
            return company
    st.session_state["societe_id"] = all_companies[0]["id"]
    return all_companies[0]


def reference_date() -> date:
    return st.session_state.setdefault("reference_date", date.today())
