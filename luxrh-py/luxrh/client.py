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
    return create_client(url, key)


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
    result = _base_client().auth.sign_in_with_password({"email": email, "password": password})
    st.session_state["session"] = {
        "access_token": result.session.access_token,
        "refresh_token": result.session.refresh_token,
        "user_id": result.user.id,
        "email": result.user.email,
    }
    st.cache_data.clear()


def sign_up(email: str, password: str, full_name: str, org_name: str, org_kind: str) -> bool:
    """Retourne True si une session est ouverte immédiatement."""
    result = _base_client().auth.sign_up(
        {
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "full_name": full_name,
                    "organization_name": org_name,
                    "organization_kind": org_kind,
                }
            },
        }
    )
    if result.session:
        st.session_state["session"] = {
            "access_token": result.session.access_token,
            "refresh_token": result.session.refresh_token,
            "user_id": result.user.id,
            "email": result.user.email,
        }
        return True
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


def engine(fn: str, **params: Any) -> Any:
    """Appelle une fonction du moteur de règles PostgreSQL."""
    clean = {k: (v.isoformat() if isinstance(v, date) else v) for k, v in params.items()}
    return client().rpc(fn, clean).execute().data


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
            .table("profiles")
            .select("*, organizations(*)")
            .eq("id", session["user_id"])
            .maybe_single()
            .execute()
        )
        st.session_state["profile"] = data.data if data else None
    return st.session_state.get("profile")


def companies() -> list[dict]:
    if "companies" not in st.session_state:
        st.session_state["companies"] = (
            client()
            .table("companies")
            .select(
                "*, company_collective_agreements(valid_from, valid_to, "
                "collective_agreements(name, code, sector, scope))"
            )
            .order("legal_name")
            .execute()
            .data
            or []
        )
    return st.session_state["companies"]


def refresh_companies() -> None:
    st.session_state.pop("companies", None)


def active_company() -> dict | None:
    all_companies = companies()
    if not all_companies:
        return None
    active_id = st.session_state.get("company_id")
    for company in all_companies:
        if company["id"] == active_id:
            return company
    st.session_state["company_id"] = all_companies[0]["id"]
    return all_companies[0]


def reference_date() -> date:
    return st.session_state.setdefault("reference_date", date.today())
