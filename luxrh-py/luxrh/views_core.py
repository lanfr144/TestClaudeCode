"""Tableau de bord, sociétés et employés."""

from __future__ import annotations

import pandas as pd
import streamlit as st

from . import client as db
from . import design as ds


# ============================================================= tableau de bord

def dashboard() -> None:
    company = db.active_company()
    if not company:
        st.warning("Aucun dossier dans cet espace. Ouvrez l’écran *Sociétés* pour en créer un.")
        return

    on = db.reference_date()
    scan = db.call("fn_compliance_scan", p_company=company["id"], p_on=on)
    profile = db.profile() or {}
    first_name = (profile.get("full_name") or "").split(" ")[0]

    attention = len(scan["overdue"]) + len(scan["due_soon"])
    headcount = scan["headcount"]["headcount"]

    st.markdown(
        f"## Bonjour {first_name} — "
        + ("aucun point ne demande votre attention"
           if attention == 0
           else f"{attention} point{'s' if attention > 1 else ''} "
                f"demande{'nt' if attention > 1 else ''} votre attention")
    )
    st.caption(
        f"{on.strftime('%A %d %B %Y')} · {company['legal_name']} · "
        f"{headcount['current']} salariés"
    )

    columns = st.columns(4)
    with columns[0]:
        ds.stat("En retard", len(scan["overdue"]),
                scan["overdue"][0]["title"].split("—")[0] if scan["overdue"] else "Rien en retard",
                "blocking" if scan["overdue"] else "ok")
    with columns[1]:
        ds.stat(f"Dans les {scan['horizon_days']} jours", len(scan["due_soon"]),
                "Essai, CDD, documents", "warning" if scan["due_soon"] else "ok")
    with columns[2]:
        threshold = scan["headcount"]["thresholds"][0]
        ds.stat(f"Effectif · {headcount['reference_months']} mois",
                f"{headcount['rounded']} / {ds.fmt_num(threshold['threshold'], 0)}",
                f"moyenne {ds.fmt_num(headcount['average'])} · {threshold['status']}",
                "warning" if threshold["reached"] else "neutral")
    with columns[3]:
        blocking = sum(1 for i in scan["items"] if i["rule_code"] == "schedule_blocking")
        ds.stat("Plannings à publier", blocking,
                "avec blocage" if blocking else "aucun blocage",
                "blocking" if blocking else "neutral")

    left, right = st.columns([2, 1])

    with left:
        ds.section("Obligations en cours")
        for title, tone, items in (
            ("En retard", "blocking", scan["overdue"]),
            (f"Dans les {scan['horizon_days']} jours", "warning", scan["due_soon"]),
            ("À surveiller", "info", scan["watch"]),
        ):
            st.markdown(f"**{title} · {len(items)}**")
            if not items:
                st.caption("Rien à signaler dans ce bloc.")
            for item in items:
                ds.alert_card(
                    item["severity"], item["title"], item["detail"],
                    item.get("consequence"), item.get("legal_ref"),
                    _deadline(item),
                )

    with right:
        counters = scan["dismissal_counters"]
        ds.section("Compteur licenciement collectif")
        for label, window in (("30 jours glissants", counters["window_30"]),
                              ("90 jours glissants", counters["window_90"])):
            st.markdown(
                f'<div class="lux-card"><div class="lux-label">{label}</div>'
                f'<div style="font-size:20px;font-weight:700">{window["count"]} / '
                f'{ds.fmt_num(window["threshold"], 0)}</div>'
                f'<div class="lux-muted">encore {window["remaining"]} notification(s) · '
                f'se libère le {ds.fmt_date(window["releases_on"])}</div></div>',
                unsafe_allow_html=True,
            )

        ds.section("Référentiel")
        index = _param("wage_index")
        if index:
            st.markdown(
                f'<div class="lux-card"><span class="lux-muted">Paramètres sociaux à l’indice '
                f'<b>{ds.fmt_num(index["value_num"])}</b>, en vigueur depuis le '
                f'<b>{ds.fmt_date(index["valid_from"])}</b>.</span></div>',
                unsafe_allow_html=True,
            )

    ds.disclaimer(scan.get("disclaimer"))


def _deadline(item: dict) -> str:
    days = item.get("days_left")
    if days is None:
        return "à surveiller"
    if days < 0:
        return f"échu depuis {abs(days)} j"
    return "aujourd’hui" if days == 0 else f"J-{days}"


@st.cache_data(ttl=300, show_spinner=False)
def _params_cached(_token: str) -> list[dict]:
    return db.rows("legal_parameters", "*", _order="param_key")


def _param(key: str) -> dict | None:
    token = st.session_state.get("session", {}).get("access_token", "")
    on = db.reference_date().isoformat()
    for row in _params_cached(token):
        if row["param_key"] == key and row["valid_from"] <= on and (
            not row["valid_to"] or row["valid_to"] > on
        ):
            return row
    return None


# =================================================================== sociétés

def companies_view() -> None:
    ds.section("Sociétés", "Chaque dossier client est cloisonné en base, pas dans l’interface.")
    on = db.reference_date().isoformat()
    all_companies = db.companies()

    table_rows = []
    for company in all_companies:
        active = [
            link for link in (company.get("company_collective_agreements") or [])
            if link["valid_from"] <= on and (not link["valid_to"] or link["valid_to"] > on)
        ]
        table_rows.append({
            "Société": company["legal_name"],
            "Secteur": company.get("sector") or "—",
            "Conventions": ", ".join(
                link["collective_agreements"]["code"] for link in active
                if link.get("collective_agreements")
            ) or "aucune",
            "Matricule CCSS": company.get("ccss_matricule") or "—",
        })
    st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True)

    with st.expander("Créer une société"):
        _company_form()


def _company_form() -> None:
    with st.form("new_company"):
        columns = st.columns(3)
        legal_name = columns[0].text_input("Raison sociale *")
        legal_form = columns[1].text_input("Forme juridique", "Sàrl")
        rcs = columns[2].text_input("RCS")
        ccss = columns[0].text_input("Matricule CCSS *", help="13 chiffres, vérifiés en base.")
        address = columns[1].text_input("Adresse")
        city = columns[2].text_input("Ville")
        postal = columns[0].text_input("Code postal")
        nace = columns[1].text_input("Secteur NACE")
        sector = columns[2].text_input("Secteur d’activité")
        rates_from = columns[0].date_input("Taux applicables à compter du", db.reference_date())
        mutuality = columns[1].selectbox("Classe Mutualité", [1, 2, 3, 4], index=1)
        accident = columns[2].number_input("Facteur accident", value=1.00, step=0.01, format="%.2f")
        activity = columns[0].text_input("Classe d’activité")

        agreements = db.rows("collective_agreements", "id, name, code, scope", _order="name")
        options = {"— aucune convention —": None} | {
            f"{a['name']} ({a['code']})": a["id"] for a in agreements
        }
        chosen = columns[1].selectbox("Convention collective", list(options))

        if st.form_submit_button("Créer la société", type="primary"):
            if not legal_name:
                st.error("La raison sociale est obligatoire.")
                return
            try:
                profile = db.profile()
                created = db.client().table("companies").insert({
                    "organization_id": profile["organization_id"],
                    "legal_name": legal_name,
                    "legal_form": legal_form or None,
                    "rcs_number": rcs or None,
                    "ccss_matricule": "".join(filter(str.isdigit, ccss)) or None,
                    "address_line": address or None,
                    "postal_code": postal or None,
                    "city": city or None,
                    "nace_code": nace or None,
                    "sector": sector or None,
                }).execute().data[0]

                db.engine("fn_set_company_rates",
                          p_company=created["id"], p_from=rates_from,
                          p_mutuality_class=int(mutuality), p_accident_factor=float(accident),
                          p_activity_class=activity or None, p_accident_risk_class=None,
                          p_note="Période ouverte à la création du dossier.")

                if options[chosen]:
                    db.client().table("company_collective_agreements").insert({
                        "company_id": created["id"],
                        "collective_agreement_id": options[chosen],
                        "valid_from": rates_from.isoformat(),
                    }).execute()

                db.refresh_companies()
                db.invalidate()
                st.success(f"{legal_name} créée.")
                st.rerun()
            except Exception as error:  # aucune erreur silencieuse
                st.error(str(error))


def company_detail() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    st.markdown(f"## {company['legal_name']}")
    st.caption(
        f"{('RCS ' + company['rcs_number'] + ' · ') if company.get('rcs_number') else ''}"
        f"{company.get('address_line') or ''}, {company.get('postal_code') or ''} "
        f"{company.get('city') or ''}"
    )

    rates = db.call("fn_company_rates", p_company=company["id"], p_on=on)
    obligations = db.call("fn_headcount_obligations", p_company=company["id"], p_on=on)

    left, middle, right = st.columns(3)
    with left:
        ds.section("Paramètres CCSS", f"en vigueur au {ds.fmt_date(on)}")
        if not rates.get("found"):
            st.caption(rates.get("message", ""))
        else:
            for label, value in (
                ("Matricule CCSS", company.get("ccss_matricule") or "—"),
                ("Classe d’activité", rates.get("activity_class") or "—"),
                ("Classe Mutualité", f"{rates.get('mutuality_class')} · {ds.fmt_pct(rates.get('mutuality_rate'))}"),
                ("Facteur accident", f"{ds.fmt_num(rates.get('accident_factor'))} · {ds.fmt_pct(rates.get('accident_rate'))}"),
                ("Total charges patronales", ds.fmt_pct(rates.get("employer_total_pct"))),
            ):
                st.markdown(f"<span class='lux-muted'>{label}</span><br><b>{value}</b>",
                            unsafe_allow_html=True)

    with middle:
        ds.section("Conventions applicables")
        links = company.get("company_collective_agreements") or []
        if not links:
            st.caption("Aucune convention rattachée. Seul le Code du travail s’applique.")
        for link in links:
            agreement = link.get("collective_agreements") or {}
            active = link["valid_from"] <= on.isoformat() and (
                not link["valid_to"] or link["valid_to"] > on.isoformat()
            )
            st.markdown(
                f"<div class='lux-card' style='margin-bottom:6px'>"
                f"<b>{agreement.get('name','')}</b> {ds.badge('en vigueur' if active else 'échue', 'violet' if active else 'neutral')}"
                f"<div class='lux-muted'>{ds.fmt_date(link['valid_from'])} → "
                f"{ds.fmt_date(link['valid_to']) if link['valid_to'] else '…'}</div></div>",
                unsafe_allow_html=True,
            )

    with right:
        ds.section("Effectif et obligations")
        headcount = obligations["headcount"]
        st.metric("Effectif moyen", headcount["rounded"],
                  help=f"moyenne exacte {ds.fmt_num(headcount['average'])}")
        for threshold in obligations["thresholds"]:
            st.markdown(
                f"{ds.badge(threshold['status'], 'warning' if threshold['reached'] else 'neutral')} "
                f"<span class='lux-muted'>{ds.fmt_num(threshold['threshold'],0)} — {threshold['label']}</span>",
                unsafe_allow_html=True,
            )

    ds.section("Historique des taux CCSS",
               "Classe d’activité, classe Mutualité et facteur accident évoluent dans le temps.")
    periods = db.rows("company_rate_periods", "*", company_id=company["id"],
                      _order="valid_from", _desc=True)
    if periods:
        st.dataframe(
            pd.DataFrame([{
                "Du": ds.fmt_date(p["valid_from"]),
                "Au": ds.fmt_date(p["valid_to"]) if p["valid_to"] else "…",
                "Classe d’activité": p.get("activity_class") or "—",
                "Mutualité": p.get("mutuality_class"),
                "Facteur accident": p.get("accident_factor"),
                "Note": p.get("note") or "",
            } for p in periods]),
            use_container_width=True, hide_index=True,
        )

    with st.expander("Ouvrir une nouvelle période de taux"):
        with st.form("rates"):
            columns = st.columns(4)
            start = columns[0].date_input("À compter du", on)
            mutuality = columns[1].selectbox("Classe Mutualité", [1, 2, 3, 4], index=1)
            accident = columns[2].number_input("Facteur accident", value=1.00, step=0.01, format="%.2f")
            activity = columns[3].text_input("Classe d’activité")
            if st.form_submit_button("Ouvrir la période", type="primary"):
                try:
                    db.engine("fn_set_company_rates", p_company=company["id"], p_from=start,
                              p_mutuality_class=int(mutuality), p_accident_factor=float(accident),
                              p_activity_class=activity or None, p_accident_risk_class=None,
                              p_note=None)
                    db.invalidate()
                    st.success("Période ouverte, la précédente est clôturée à cette date.")
                    st.rerun()
                except Exception as error:
                    st.error(str(error))


# =================================================================== employés

def employees_view() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    employees = db.rows(
        "employees",
        "*, departments(name), contracts(id, kind, status, job_title, weekly_hours, monthly_gross)",
        company_id=company["id"], _order="last_name",
    )
    scan = db.call("fn_compliance_scan", p_company=company["id"], p_on=on)
    alerts: dict[str, dict] = {}
    for item in scan["items"]:
        if item.get("employee_id"):
            alerts.setdefault(item["employee_id"], item)

    search = st.text_input("Rechercher", placeholder="Nom, prénom ou poste…")
    only_active = st.checkbox("Contrat actif seulement", value=True)

    table_rows = []
    for employee in employees:
        contract = next((c for c in employee.get("contracts", []) if c["status"] == "active"), None)
        if only_active and not contract:
            continue
        haystack = f"{employee['first_name']} {employee['last_name']} {contract['job_title'] if contract else ''}"
        if search and search.lower() not in haystack.lower():
            continue
        alert = alerts.get(employee["id"])
        table_rows.append({
            "Salarié": f"{employee['first_name']} {employee['last_name']}",
            "Poste": contract["job_title"] if contract else "—",
            "Contrat": contract["kind"].upper() if contract else "—",
            "Temps": f"{contract['weekly_hours']} h" if contract else "—",
            "Résidence": employee["residency"],
            "Conformité": alert["title"].split("—")[0].strip() if alert else "Conforme",
        })

    st.caption(f"{len(table_rows)} salarié(s) affiché(s) sur {len(employees)}.")
    st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True, height=420)

    names = {f"{e['last_name']} {e['first_name']}": e["id"] for e in employees}
    if names:
        chosen = st.selectbox("Ouvrir une fiche", list(names))
        if st.button("Ouvrir la fiche salarié"):
            st.session_state["employee_id"] = names[chosen]
            st.session_state["goto"] = "employee_detail"
            st.rerun()


def employee_detail() -> None:
    employee_id = st.session_state.get("employee_id")
    if not employee_id:
        st.info("Sélectionnez un salarié depuis la liste.")
        return
    on = db.reference_date()

    employee = db.client().table("employees").select(
        "*, departments(name), employee_tax_cards(*), contracts(*)"
    ).eq("id", employee_id).single().execute().data
    contract = next((c for c in employee.get("contracts", []) if c["status"] == "active"), None)

    st.markdown(f"## {employee['first_name']} {employee['last_name']}")
    st.caption(
        f"{contract['job_title'] if contract else 'Sans contrat actif'}"
        f"{' · entrée le ' + ds.fmt_date(contract['start_date']) if contract else ''}"
    )

    qualification = db.call("fn_is_qualified", p_employee=employee_id, p_on=on)
    protections = db.call("fn_dismissal_protections", p_employee=employee_id, p_on=on)
    overtime = db.call("fn_overtime_eligibility", p_employee=employee_id, p_on=on)
    delegation = db.call("fn_delegation_eligibility", p_employee=employee_id, p_on=on)
    balance = db.call("fn_leave_balance", p_employee=employee_id, p_on=on)
    sick = db.call("fn_sick_counters", p_employee=employee_id, p_on=on)
    disability = db.call("fn_disability_extra_leave", p_employee=employee_id, p_on=on)
    children = db.call("fn_employee_children", p_employee=employee_id, p_on=on)

    columns = st.columns(4)
    columns[0].markdown(
        f"<span class='lux-label'>Matricule</span><br>"
        f"<span class='lux-mono'>•••• {employee.get('national_id_hint') or '••••'}</span>",
        unsafe_allow_html=True)
    columns[1].markdown(f"<span class='lux-label'>Résidence</span><br>{employee['residency']}",
                        unsafe_allow_html=True)
    columns[2].markdown(f"<span class='lux-label'>Sexe</span><br>{employee['sex']}",
                        unsafe_allow_html=True)
    columns[3].markdown(
        f"<span class='lux-label'>Qualification</span><br>"
        f"{'Qualifié(e)' if qualification['qualified'] else 'Non qualifié(e)'}",
        unsafe_allow_html=True)

    if protections.get("protected"):
        details = " · ".join(
            f"{p['label']}" + (f" jusqu’au {ds.fmt_date(p['until'])}" if p.get("until") else "")
            for p in protections["protections"]
        )
        ds.alert_card("info", "Protection contre le licenciement en cours", details,
                      "Toute notification pendant cette période serait nulle.",
                      protections["protections"][0].get("legal_ref"))

    if st.button("Afficher le matricule complet"):
        try:
            sensitive = db.engine("fn_employee_sensitive", p_employee=employee_id)
            st.info(f"Matricule : {sensitive[0]['national_id']} · IBAN : {sensitive[0]['iban']}")
        except Exception as error:
            st.error(str(error))

    tabs = st.tabs(["Compteurs", "Statuts & protections", "Enfants", "Contrats"])

    with tabs[0]:
        columns = st.columns(3)
        with columns[0]:
            ds.stat("Solde de congés", f"{ds.fmt_num(balance.get('balance'))} j",
                    f"acquis {ds.fmt_num(balance.get('accrued'))} · pris {ds.fmt_num(balance.get('taken'))}")
        with columns[1]:
            ds.stat("Incapacité / période",
                    f"{ds.fmt_num(sick.get('days_in_window'), 0)} / {ds.fmt_num(sick.get('limit_days'), 0)} j",
                    f"sur {sick.get('window_months')} mois",
                    "warning" if sick.get("continuation_end") else "neutral")
        with columns[2]:
            ds.stat("Congé handicap",
                    f"{ds.fmt_num(disability.get('extra_days'), 0)} j" if disability.get("applies") else "—",
                    f"taux {ds.fmt_pct(disability.get('rate_pct'))}" if disability.get("applies") else "aucun statut")

        if balance.get("lines"):
            ds.section("Détail du solde", "Calcul reconstituable, ligne à ligne")
            st.dataframe(
                pd.DataFrame([{"Ligne": l["label"], "Signe": l["sign"], "Jours": l["value"]}
                              for l in balance["lines"]]),
                use_container_width=True, hide_index=True)
            ds.arbitration(balance.get("arbitration") or {}, "j")

    with tabs[1]:
        left, right = st.columns(2)
        with left:
            ds.section("Heures supplémentaires")
            if overtime["allowed"]:
                st.success("Aucune interdiction en vigueur.")
            for reason in overtime["reasons"]:
                ds.alert_card("blocking", reason["label"], reason["detail"],
                              None, reason.get("legal_ref"))
            statuses = db.rows("employee_statuses", "*", employee_id=employee_id,
                               _order="start_date", _desc=True)
            ds.section("Statuts déclarés")
            if not statuses:
                st.caption("Aucun statut particulier déclaré.")
            for status in statuses:
                st.markdown(
                    f"{ds.badge(status['kind'], 'violet')} "
                    f"<span class='lux-muted'>du {ds.fmt_date(status['start_date'])} "
                    f"{'au ' + ds.fmt_date(status['end_date']) if status['end_date'] else '(sans terme)'}</span>",
                    unsafe_allow_html=True)
        with right:
            ds.section("Éligibilité à la délégation")
            if delegation["eligible"]:
                st.success("Éligible.")
            else:
                for reason in delegation["reasons"]:
                    st.markdown(f"· {reason['detail']}")
            ds.legal_basis(delegation.get("legal_ref"),
                           "L’ancienneté requise et l’exclusion du personnel de direction "
                           "conditionnent l’éligibilité.")
            ds.section("Qualification")
            st.markdown(qualification["source"])

    with tabs[2]:
        ds.section("Enfants", children.get("privacy_note", ""))
        if children["count"] == 0:
            st.caption("Aucun enfant enregistré.")
        else:
            st.dataframe(
                pd.DataFrame([{
                    "Prénom": c.get("first_name") or "— (confidentiel)",
                    "Âge": c["age"],
                    "Né(e) le": ds.fmt_date(c["birth_date"]),
                    "Lien": c["relationship"],
                    "Attentions": "non" if c["privacy_opt_out"] else ("oui" if c["eligible_for_gift"] else "hors âge"),
                } for c in children["children"]]),
                use_container_width=True, hide_index=True)
        _child_form(employee)

    with tabs[3]:
        contracts = employee.get("contracts", [])
        if contracts:
            st.dataframe(
                pd.DataFrame([{
                    "Type": c["kind"].upper(),
                    "Poste": c["job_title"],
                    "Début": ds.fmt_date(c["start_date"]),
                    "Fin": ds.fmt_date(c["end_date"]) if c["end_date"] else "—",
                    "Brut": ds.fmt_eur(c["monthly_gross"]),
                    "Statut": c["status"],
                } for c in contracts]),
                use_container_width=True, hide_index=True)


def _child_form(employee: dict) -> None:
    with st.expander("Ajouter un enfant"):
        with st.form(f"child_{employee['id']}"):
            privacy = st.checkbox(
                "Le salarié refuse les attentions de la société",
                help="Seule la date de naissance est alors conservée, pour établir les droits à congé.",
            )
            columns = st.columns(4)
            first_name = columns[0].text_input("Prénom", disabled=privacy)
            last_name = columns[1].text_input("Nom", disabled=privacy)
            sex = columns[2].selectbox("Sexe", ["unspecified", "female", "male"], disabled=privacy)
            birth = columns[3].date_input("Date de naissance")
            relationship = st.selectbox("Lien", ["child", "adopted", "foster", "stepchild"])
            if st.form_submit_button("Enregistrer", type="primary"):
                try:
                    db.client().table("employee_children").insert({
                        "company_id": employee["company_id"],
                        "employee_id": employee["id"],
                        "first_name": None if privacy else (first_name or None),
                        "last_name": None if privacy else (last_name or None),
                        "sex": None if privacy else sex,
                        "birth_date": birth.isoformat(),
                        "relationship": relationship,
                        "privacy_opt_out": privacy,
                    }).execute()
                    db.invalidate()
                    st.success("Enfant enregistré.")
                    st.rerun()
                except Exception as error:
                    st.error(str(error))
