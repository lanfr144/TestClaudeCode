"""Planning, congés, maladies, heures supplémentaires et chèques-repas."""

from __future__ import annotations

from datetime import date, timedelta

import pandas as pd
import streamlit as st

from . import client as db
from . import design as ds

DAYS = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]


def _monday(day: date) -> date:
    return day - timedelta(days=day.weekday())


# =================================================================== planning

def planning() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return

    week = st.session_state.setdefault("week_start", _monday(db.reference_date()))
    navigation = st.columns([1, 6, 1, 2])
    if navigation[0].button("← Semaine"):
        st.session_state["week_start"] = week - timedelta(days=7)
        st.rerun()
    if navigation[2].button("Semaine →"):
        st.session_state["week_start"] = week + timedelta(days=7)
        st.rerun()
    picked = navigation[3].date_input("Aller à la semaine du", week, label_visibility="collapsed")
    if _monday(picked) != week:
        st.session_state["week_start"] = _monday(picked)
        st.rerun()

    days = [week + timedelta(days=i) for i in range(7)]
    navigation[1].markdown(
        f"### Semaine {week.isocalendar().week} · {ds.fmt_date(days[0])} – {ds.fmt_date(days[6])}"
    )

    schedules = db.rows("schedules", "*", company_id=company["id"], week_start=week.isoformat())
    schedule = schedules[0] if schedules else None

    if not schedule:
        st.info("Aucun planning pour cette semaine.")
        if st.button("Créer le planning de la semaine", type="primary"):
            db.client().table("schedules").insert({
                "company_id": company["id"],
                "week_start": week.isoformat(),
                "label": f"Semaine {week.isocalendar().week}",
                "status": "draft",
            }).execute()
            db.invalidate()
            st.rerun()
        return

    validation = db.call("fn_validate_schedule", p_schedule=schedule["id"])
    shifts = db.rows("shifts", "*, employees(id, first_name, last_name)",
                     schedule_id=schedule["id"], _order="shift_date")
    absences = db.rows("absences", "*, absence_types(label, category)", company_id=company["id"])

    header = st.columns([3, 1, 2])
    header[1].markdown(
        ds.badge("Publié" if schedule["status"] == "published" else "Brouillon",
                 "ok" if schedule["status"] == "published" else "neutral"),
        unsafe_allow_html=True)
    publish_label = (
        "Publier et notifier" if validation["can_publish"]
        else f"Publier · {validation['blocking_count']} blocage(s)"
    )
    if header[2].button(publish_label, type="primary",
                        disabled=schedule["status"] == "published" or not validation["can_publish"]):
        try:
            db.engine("fn_publish_schedule", p_schedule=schedule["id"])
            db.invalidate()
            st.success("Planning publié.")
            st.rerun()
        except Exception as error:
            st.error(str(error))

    # --- grille ---
    grid: dict[str, dict[str, list[str]]] = {}
    for shift in shifts:
        employee = shift.get("employees") or {}
        name = f"{employee.get('first_name','')} {employee.get('last_name','')}".strip()
        column = DAYS[date.fromisoformat(shift["shift_date"]).weekday()]
        grid.setdefault(name, {}).setdefault(column, []).append(
            f"{shift['start_time'][:5]}–{shift['end_time'][:5]}"
        )
    for absence in absences:
        if absence["status"] == "refused":
            continue
        for i, day in enumerate(days):
            if absence["start_date"] <= day.isoformat() <= absence["end_date"]:
                employee = next(
                    (f"{s['employees']['first_name']} {s['employees']['last_name']}"
                     for s in shifts if s["employee_id"] == absence["employee_id"]), None)
                if employee:
                    label = (absence.get("absence_types") or {}).get("label", "Absence")
                    grid.setdefault(employee, {}).setdefault(DAYS[i], []).append(f"[{label}]")

    left, right = st.columns([2, 1])
    with left:
        if grid:
            table = pd.DataFrame([
                {"Salarié": name, **{d: " / ".join(cells.get(d, [])) or "—" for d in DAYS}}
                for name, cells in grid.items()
            ])
            st.dataframe(table, use_container_width=True, hide_index=True)
        else:
            st.caption("Aucun shift sur cette semaine.")

        if validation["employees"]:
            st.dataframe(
                pd.DataFrame([{
                    "Salarié": e["employee_name"],
                    "Heures": e["total_hours"],
                    "Heures sup.": e["overtime_hours"],
                    "Sup. autorisées": "oui" if e.get("overtime_allowed", True) else "NON",
                    "Dimanches": e["sundays"],
                    "Repos le plus long": f"{e['longest_rest_hours']} h",
                } for e in validation["employees"]]),
                use_container_width=True, hide_index=True)

    with right:
        ds.section("Contrôles légaux", "évalué à chaque modification")
        if not validation["violations"]:
            st.success("Aucune violation : le planning est publiable.")
        for violation in validation["violations"]:
            ds.alert_card(violation["severity"], violation["title"], violation["detail"],
                          None, violation.get("legal_ref"))

    with st.expander("Ajouter un shift"):
        _shift_form(company, schedule, days)


def _shift_form(company: dict, schedule: dict, days: list[date]) -> None:
    employees = db.rows("employees", "id, first_name, last_name",
                        company_id=company["id"], _order="last_name")
    templates = db.rows("shift_templates", "*", company_id=company["id"], _order="start_time")
    if not employees:
        st.caption("Aucun salarié dans ce dossier.")
        return

    with st.form("shift"):
        columns = st.columns(4)
        names = {f"{e['last_name']} {e['first_name']}": e["id"] for e in employees}
        who = columns[0].selectbox("Salarié", list(names))
        when = columns[1].selectbox("Jour", days, format_func=ds.fmt_date)
        template_names = {"— saisie libre —": None} | {t["name"]: t for t in templates}
        template = columns[2].selectbox("Modèle", list(template_names))
        break_minutes = columns[3].number_input("Pause (min)", 0, 240, 30, step=15)
        picked = template_names[template]
        start = columns[0].text_input("Début", picked["start_time"][:5] if picked else "09:00")
        end = columns[1].text_input("Fin", picked["end_time"][:5] if picked else "17:00")
        label = columns[2].text_input("Libellé", picked["name"] if picked else "Service")

        if st.form_submit_button("Ajouter", type="primary"):
            try:
                db.client().table("shifts").insert({
                    "schedule_id": schedule["id"],
                    "company_id": company["id"],
                    "employee_id": names[who],
                    "shift_date": when.isoformat(),
                    "start_time": start,
                    "end_time": end,
                    "break_minutes": int(break_minutes),
                    "label": label,
                    "template_id": picked["id"] if picked else None,
                }).execute()
                db.invalidate()
                st.rerun()
            except Exception as error:
                st.error(str(error))


# ===================================================================== congés

def leave() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    absences = db.rows(
        "absences",
        "*, employees(first_name, last_name), absence_types(label, category, counts_against_leave, legal_ref)",
        company_id=company["id"], _order="start_date", _desc=True,
    )
    pending = [a for a in absences if a["status"] == "pending"]

    ds.section("Demandes en attente", f"{len(pending)} à traiter")
    for absence in pending:
        employee = absence.get("employees") or {}
        kind = absence.get("absence_types") or {}
        impact = db.call("fn_leave_request_impact",
                         p_employee=absence["employee_id"],
                         p_type=absence["absence_type_id"],
                         p_start=absence["start_date"], p_end=absence["end_date"])

        with st.container(border=True):
            columns = st.columns([3, 2, 2])
            columns[0].markdown(
                f"**{employee.get('first_name','')} {employee.get('last_name','')}** — "
                f"{kind.get('label','')}<br>"
                f"<span class='lux-muted'>{ds.fmt_date(absence['start_date'])} – "
                f"{ds.fmt_date(absence['end_date'])} · {ds.fmt_num(absence['days_count'])} jour(s)</span>",
                unsafe_allow_html=True)
            columns[1].markdown(
                ds.badge("Conforme" if impact["is_valid"] else "Refus recommandé",
                         "ok" if impact["is_valid"] else "blocking"),
                unsafe_allow_html=True)
            columns[1].caption(impact["message"])
            if impact.get("balance_after") is not None:
                columns[2].metric("Solde après", f"{ds.fmt_num(impact['balance_after'])} j")
            if impact.get("legal_ref"):
                columns[2].markdown(ds.legal_ref_chip(impact["legal_ref"]), unsafe_allow_html=True)

            actions = st.columns([1, 1, 6])
            if actions[0].button("Valider", key=f"ok_{absence['id']}", type="primary"):
                _decide(absence["id"], "approved")
            if actions[1].button("Refuser", key=f"no_{absence['id']}"):
                _decide(absence["id"], "refused")

    ds.section("Toutes les absences")
    if absences:
        st.dataframe(
            pd.DataFrame([{
                "Salarié": f"{(a.get('employees') or {}).get('first_name','')} "
                           f"{(a.get('employees') or {}).get('last_name','')}".strip(),
                "Type": (a.get("absence_types") or {}).get("label", ""),
                "Du": ds.fmt_date(a["start_date"]),
                "Au": ds.fmt_date(a["end_date"]),
                "Jours": a["days_count"],
                "Statut": a["status"],
            } for a in absences]),
            use_container_width=True, hide_index=True, height=360)

    ds.section("Soldes de l’équipe")
    employees = db.rows("employees", "id, first_name, last_name",
                        company_id=company["id"], _order="last_name", _limit=25)
    balances = []
    for employee in employees:
        balance = db.call("fn_leave_balance", p_employee=employee["id"], p_on=on)
        if not balance.get("no_contract"):
            balances.append({
                "Salarié": f"{employee['first_name']} {employee['last_name']}",
                "Droit annuel": balance.get("entitlement_days"),
                "Source": balance.get("entitlement_source"),
                "Acquis": balance.get("accrued"),
                "Pris": balance.get("taken"),
                "Solde": balance.get("balance"),
            })
    if balances:
        st.dataframe(pd.DataFrame(balances), use_container_width=True, hide_index=True)


def _decide(absence_id: str, status: str) -> None:
    try:
        db.client().table("absences").update({
            "status": status,
            "decided_at": "now()",
            "decided_by": st.session_state["session"]["user_id"],
        }).eq("id", absence_id).execute()
        db.invalidate()
        st.rerun()
    except Exception as error:
        st.error(str(error))


# =================================================================== maladies

def sick_leave() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    ds.section("Compteurs de maladie",
               "77 jours sur 18 mois, protection de 26 semaines, suivi des certificats")
    employees = db.rows("employees", "id, first_name, last_name",
                        company_id=company["id"], _order="last_name")
    table_rows = []
    for employee in employees:
        counters = db.call("fn_sick_counters", p_employee=employee["id"], p_on=on)
        if counters["days_in_window"] == 0:
            continue
        table_rows.append({
            "Salarié": f"{employee['first_name']} {employee['last_name']}",
            "Incapacité / période": f"{ds.fmt_num(counters['days_in_window'],0)} / "
                                    f"{ds.fmt_num(counters['limit_days'],0)} j",
            "Fin de continuation": ds.fmt_date(counters["continuation_end"]) if counters["continuation_end"] else "en cours",
            "Protection jusqu’au": ds.fmt_date(counters["protection_end"]) if counters["protection_end"] else "—",
            "Certificats manquants": len(counters["missing_certificates"]),
            "Mutualité": ds.fmt_pct(counters["mutuality_refund_pct"]),
        })
    if table_rows:
        st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True)
    else:
        st.caption("Aucune incapacité enregistrée sur la période de référence.")

    ds.legal_basis(
        "art. L.121-6",
        "La continuation de salaire par l’employeur va jusqu’à la fin du mois du 77e jour "
        "d’incapacité, sur une période de référence de 18 mois.",
        source="Legilux",
    )

    with st.expander("Déclarer une incapacité"):
        _sick_form(company)


def _sick_form(company: dict) -> None:
    employees = db.rows("employees", "id, first_name, last_name",
                        company_id=company["id"], _order="last_name")
    types = db.rows("absence_types", "id, code, label")
    sick_type = next((t for t in types if t["code"] == "sick"), None)
    if not employees or not sick_type:
        return
    with st.form("sick"):
        columns = st.columns(5)
        names = {f"{e['last_name']} {e['first_name']}": e["id"] for e in employees}
        who = columns[0].selectbox("Salarié", list(names))
        start = columns[1].date_input("Du", db.reference_date())
        end = columns[2].date_input("Au", db.reference_date())
        days = columns[3].number_input("Jours décomptés", 0.0, 400.0, 1.0, step=0.5)
        certificate = columns[4].checkbox("Certificat reçu")
        original = st.checkbox(
            "Original reçu par la poste",
            help="Le dépôt numérique ne dispense pas de l’envoi de l’original.")
        if st.form_submit_button("Enregistrer", type="primary"):
            try:
                db.client().table("absences").insert({
                    "company_id": company["id"],
                    "employee_id": names[who],
                    "absence_type_id": sick_type["id"],
                    "start_date": start.isoformat(),
                    "end_date": end.isoformat(),
                    "days_count": float(days),
                    "status": "approved",
                    "certificate_received": certificate,
                    "certificate_original_received": original,
                }).execute()
                db.invalidate()
                st.success("Incapacité enregistrée.")
                st.rerun()
            except Exception as error:
                st.error(str(error))


# ==================================================== heures supplémentaires

def overtime() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return

    ds.section(
        "Heures supplémentaires",
        "La demande est adressée aux RH et doit être acceptée par les deux parties "
        "AVANT que les heures ne soient prestées.",
    )
    requests = db.rows("overtime_requests", "*, employees(first_name, last_name)",
                       company_id=company["id"], _order="period_start", _desc=True)

    for request in requests:
        employee = request.get("employees") or {}
        with st.container(border=True):
            columns = st.columns([3, 2, 2, 2])
            columns[0].markdown(
                f"**{employee.get('first_name','')} {employee.get('last_name','')}**<br>"
                f"<span class='lux-muted'>{ds.fmt_date(request['period_start'])} – "
                f"{ds.fmt_date(request['period_end'])} · {ds.fmt_num(request['hours'])} h · "
                f"{request['reason']}</span>",
                unsafe_allow_html=True)
            tone = {"approved": "ok", "rejected": "blocking", "requested": "info",
                    "hr_approved": "warning", "cancelled": "neutral"}[request["status"]]
            columns[1].markdown(ds.badge(request["status"], tone), unsafe_allow_html=True)
            columns[2].caption(
                ("RH : validé" if request["hr_validated_at"] else "RH : en attente")
                + " · "
                + ("salarié : accepté" if request["employee_accepted_at"] else "salarié : en attente")
            )
            if request["status"] in ("requested", "hr_approved"):
                if not request["hr_validated_at"] and columns[3].button(
                        "Valider (RH)", key=f"hr_{request['id']}", type="primary"):
                    _approve(request["id"], True)
                if not request["employee_accepted_at"] and columns[3].button(
                        "Accepter (salarié)", key=f"emp_{request['id']}"):
                    _approve(request["id"], False)

    if not requests:
        st.caption("Aucune demande enregistrée.")

    with st.expander("Nouvelle demande"):
        employees = db.rows("employees", "id, first_name, last_name",
                            company_id=company["id"], _order="last_name")
        if employees:
            with st.form("overtime"):
                columns = st.columns(5)
                names = {f"{e['last_name']} {e['first_name']}": e["id"] for e in employees}
                who = columns[0].selectbox("Salarié", list(names))
                start = columns[1].date_input("Du", db.reference_date())
                end = columns[2].date_input("Au", db.reference_date())
                hours = columns[3].number_input("Heures", 0.5, 200.0, 4.0, step=0.5)
                compensation = columns[4].selectbox("Compensation", ["money", "rest"])
                reason = st.text_input("Motif", "Surcroît ponctuel d’activité")
                if st.form_submit_button("Enregistrer la demande", type="primary"):
                    try:
                        db.client().table("overtime_requests").insert({
                            "company_id": company["id"],
                            "employee_id": names[who],
                            "period_start": start.isoformat(),
                            "period_end": end.isoformat(),
                            "hours": float(hours),
                            "reason": reason,
                            "compensation": compensation,
                            "requested_by": st.session_state["session"]["user_id"],
                        }).execute()
                        db.invalidate()
                        st.rerun()
                    except Exception as error:
                        st.error(str(error))


def _approve(request_id: str, as_hr: bool) -> None:
    try:
        db.engine("fn_overtime_approve", p_request=request_id, p_as_hr=as_hr)
        db.invalidate()
        st.rerun()
    except Exception as error:
        st.error(str(error))


# ============================================================== chèques-repas

def meal_vouchers() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return

    ds.section("Chèques-repas", "Attribution et périodes d’octroi")
    grants = db.rows("meal_voucher_grants", "*, employees(first_name, last_name)",
                     company_id=company["id"], _order="period_start", _desc=True)

    if grants:
        table_rows = []
        for grant in grants:
            check = db.call("fn_meal_voucher_check", p_grant=grant["id"])
            employee = grant.get("employees") or {}
            table_rows.append({
                "Salarié": f"{employee.get('first_name','')} {employee.get('last_name','')}".strip(),
                "Période": check["period"],
                "Nombre": grant["voucher_count"],
                "Valeur faciale": ds.fmt_eur(grant["face_value"]),
                "Part salarié": ds.fmt_eur(grant["employee_share"]),
                "Coût employeur": ds.fmt_eur(check["employer_cost"]),
                "Alertes": check["warning_count"],
            })
        st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True)
    else:
        st.caption("Aucune attribution enregistrée.")

    with st.expander("Nouvelle attribution"):
        employees = db.rows("employees", "id, first_name, last_name",
                            company_id=company["id"], _order="last_name")
        if employees:
            with st.form("vouchers"):
                columns = st.columns(5)
                names = {f"{e['last_name']} {e['first_name']}": e["id"] for e in employees}
                who = columns[0].selectbox("Salarié", list(names))
                start = columns[1].date_input("Du", db.reference_date().replace(day=1))
                end = columns[2].date_input("Au", db.reference_date())
                count = columns[3].number_input("Nombre", 0, 40, 20)
                face = columns[4].number_input("Valeur faciale", 0.0, 50.0, 15.0, step=0.5)
                share = st.number_input("Participation du salarié", 0.0, 50.0, 2.8, step=0.1)
                if st.form_submit_button("Attribuer", type="primary"):
                    try:
                        db.client().table("meal_voucher_grants").insert({
                            "company_id": company["id"],
                            "employee_id": names[who],
                            "period_start": start.isoformat(),
                            "period_end": end.isoformat(),
                            "voucher_count": int(count),
                            "face_value": float(face),
                            "employee_share": float(share),
                            "granted_on": db.reference_date().isoformat(),
                        }).execute()
                        db.invalidate()
                        st.rerun()
                    except Exception as error:
                        st.error(str(error))
