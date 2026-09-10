"""LuxRH — application Streamlit.

Parallèle au front React : mêmes écrans, même moteur de règles. Le serveur
calcule, valide et décide ; cette interface affiche et saisit.
"""

from __future__ import annotations

from datetime import date

import streamlit as st

from luxrh import client as db
from luxrh import design as ds
from luxrh import views_compliance as compliance
from luxrh import views_core as core
from luxrh import views_time as timekeeping

st.set_page_config(page_title="LuxRH — Assistant RH & Paie", page_icon="⚖️", layout="wide")
ds.inject_css()


# ==================================================================== connexion

def login_screen() -> None:
    left, right = st.columns([1.2, 1])
    with left:
        st.markdown(
            f"""
            <div style="background:{ds.VIOLET};color:#fff;border-radius:10px;padding:34px 30px;
                        min-height:420px;display:flex;flex-direction:column;justify-content:space-between">
              <div style="font-size:11px;letter-spacing:.14em;text-transform:uppercase;opacity:.8">
                LuxRH · Assistant RH &amp; Paie
              </div>
              <div>
                <div style="font-size:27px;font-weight:700;line-height:1.15;letter-spacing:-.8px">
                  L’application ne se contente pas de calculer : elle avertit et explique.
                </div>
                <p style="opacity:.85;line-height:1.6;margin-top:14px">
                  Contrats conformes, plannings validés en temps réel contre le droit du travail
                  luxembourgeois, et un tableau de bord permanent des échéances et des seuils.
                  Chaque alerte cite l’article qui la motive.
                </p>
                <ul style="opacity:.8;font-size:13px;line-height:1.9;padding-left:18px">
                  <li>Référentiel légal daté — aucun taux, aucun seuil écrit en dur</li>
                  <li>Loi → CCT → contrat, la disposition la plus favorable l’emporte</li>
                  <li>Isolation multi-sociétés imposée en base, pas dans l’interface</li>
                </ul>
              </div>
              <div style="font-size:11px;opacity:.6">Données hébergées dans l’Union européenne.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

    with right:
        tab_signin, tab_signup = st.tabs(["Connexion", "Créer un espace"])

        with tab_signin:
            with st.form("signin"):
                email = st.text_input("Adresse e-mail")
                password = st.text_input("Mot de passe", type="password")
                if st.form_submit_button("Se connecter", type="primary", use_container_width=True):
                    try:
                        db.sign_in(email, password)
                        st.rerun()
                    except Exception as error:
                        st.error(f"Connexion refusée : {error}")

        with tab_signup:
            with st.form("signup"):
                full_name = st.text_input("Nom complet")
                org_name = st.text_input("Nom de l’espace de travail")
                org_kind = st.selectbox("Type d’espace", ["fiduciary", "company"],
                                        format_func=lambda k: "Fiduciaire" if k == "fiduciary" else "Entreprise")
                email = st.text_input("Adresse e-mail ", key="su_email")
                password = st.text_input("Mot de passe ", type="password", key="su_password")
                if st.form_submit_button("Créer l’espace", type="primary", use_container_width=True):
                    try:
                        if db.sign_up(email, password, full_name, org_name, org_kind):
                            st.rerun()
                        else:
                            st.info(
                                "Compte créé. Un courriel de confirmation vient de partir : "
                                f"le lien vous ramènera sur {db.app_url()}."
                            )
                    except db.EmailAlreadyRegistered:
                        st.error(
                            "Cette adresse est déjà enregistrée. Aucun courriel n’a été envoyé — "
                            "Supabase ne le signale pas, pour ne pas révéler quels comptes "
                            "existent. Connectez-vous avec l’onglet précédent."
                        )
                    except Exception as error:
                        st.error(str(error))


# ======================================================================= shell

PAGES: dict[str, tuple[str, callable]] = {
    "dashboard": ("Tableau de bord", core.dashboard),
    "planning": ("Planning", timekeeping.planning),
    "overtime": ("Heures supplémentaires", timekeeping.overtime),
    "employees": ("Employés", core.employees_view),
    "employee_detail": ("Fiche salarié", core.employee_detail),
    "contracts": ("Contrats", compliance.contracts),
    "leave": ("Congés", timekeeping.leave),
    "sick": ("Maladies", timekeeping.sick_leave),
    "vouchers": ("Chèques-repas", timekeeping.meal_vouchers),
    "vigilance": ("Vigilance", compliance.vigilance),
    "dismissal": ("Licenciement collectif", compliance.dismissal_simulator),
    "premiums": ("Primes", compliance.premiums),
    "companies": ("Sociétés", core.companies_view),
    "company_detail": ("Fiche société", core.company_detail),
    "referential": ("Référentiel", compliance.referential),
}

GROUPS = [
    ("Pilotage", ["dashboard", "vigilance", "dismissal"]),
    ("Exploitation", ["planning", "overtime", "leave", "sick", "vouchers"]),
    ("Dossiers", ["employees", "employee_detail", "contracts", "premiums"]),
    ("Administration", ["companies", "company_detail", "referential"]),
]


def sidebar() -> str:
    profile = db.profile() or {}
    organization = (profile.get("organizations") or {}).get("name", "")

    with st.sidebar:
        st.markdown(
            f"<div style='font-weight:700;font-size:19px'>LuxRH</div>"
            f"<div style='font-size:11px;opacity:.75'>{organization}</div>",
            unsafe_allow_html=True)
        st.divider()

        all_companies = db.companies()
        if all_companies:
            labels = {c["legal_name"]: c["id"] for c in all_companies}
            current = db.active_company()
            index = list(labels.values()).index(current["id"]) if current else 0
            chosen = st.selectbox("Dossier client", list(labels), index=index)
            if labels[chosen] != st.session_state.get("company_id"):
                st.session_state["company_id"] = labels[chosen]
                st.session_state.pop("simulation", None)
                db.invalidate()
                st.rerun()
        else:
            st.caption("Aucun dossier.")
            if profile.get("is_org_admin") and st.button("Charger le jeu de démonstration"):
                try:
                    result = db.engine("fn_seed_demo")
                    db.refresh_companies()
                    db.invalidate()
                    st.success(result["message"])
                    st.rerun()
                except Exception as error:
                    st.error(str(error))

        reference = st.date_input("Date de référence", db.reference_date(),
                                  help="Tout calcul lit les paramètres en vigueur à cette date.")
        if reference != st.session_state.get("reference_date"):
            st.session_state["reference_date"] = reference
            db.invalidate()
            st.rerun()

        st.divider()
        target = st.session_state.get("goto", "dashboard")
        st.session_state.pop("goto", None)
        for group, keys in GROUPS:
            st.markdown(f"<div style='font-size:10px;letter-spacing:.1em;text-transform:uppercase;"
                        f"opacity:.6;margin-top:8px'>{group}</div>", unsafe_allow_html=True)
            for key in keys:
                label = PAGES[key][0]
                if st.button(label, key=f"nav_{key}", use_container_width=True):
                    st.session_state["page"] = key
                    st.rerun()

        st.divider()
        st.caption(profile.get("email", ""))
        if st.button("Se déconnecter", use_container_width=True):
            db.sign_out()
            st.rerun()

    return st.session_state.get("page", target)


def main() -> None:
    # Le lien de confirmation renvoie ici avec un `?code=` : l'échanger contre
    # une session ouvre directement l'espace, sans repasser par la connexion.
    if db.consume_confirmation_code():
        st.rerun()

    if not db.is_signed_in():
        if st.session_state.get("confirmation_error"):
            st.error(
                "Le lien de confirmation n’a pas pu être utilisé : "
                f"{st.session_state.pop('confirmation_error')}. "
                "Un lien n’est valable qu’une fois, et depuis le navigateur qui a servi à "
                "l’inscription."
            )
        login_screen()
        return

    if st.session_state.get("goto"):
        st.session_state["page"] = st.session_state.pop("goto")

    page = sidebar()
    title, view = PAGES.get(page, PAGES["dashboard"])

    company = db.active_company()
    st.markdown(
        f"<div style='font-size:12px;color:{ds.INK_MUTED};margin-bottom:2px'>"
        f"{company['legal_name'] if company else 'Aucun dossier'} › {title}</div>",
        unsafe_allow_html=True)

    try:
        view()
    except Exception as error:  # aucune erreur silencieuse
        st.error(f"Erreur : {error}")
        st.exception(error)


if __name__ == "__main__":
    main()
else:
    main()
