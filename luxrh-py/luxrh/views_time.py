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

    week = st.session_state.setdefault("debut_semaine", _monday(db.reference_date()))
    navigation = st.columns([1, 6, 1, 2])
    if navigation[0].button("← Semaine"):
        st.session_state["debut_semaine"] = week - timedelta(days=7)
        st.rerun()
    if navigation[2].button("Semaine →"):
        st.session_state["debut_semaine"] = week + timedelta(days=7)
        st.rerun()
    picked = navigation[3].date_input("Aller à la semaine du", week, label_visibility="collapsed")
    if _monday(picked) != week:
        st.session_state["debut_semaine"] = _monday(picked)
        st.rerun()

    days = [week + timedelta(days=i) for i in range(7)]
    navigation[1].markdown(
        f"### Semaine {week.isocalendar().week} · {ds.fmt_date(jours[0])} – {ds.fmt_date(jours[6])}"
    )

    plannings = db.rows("plannings", "*", societe_id=company["id"], debut_semaine=week.isoformat())
    schedule = plannings[0] if plannings else None

    if not schedule:
        st.info("Aucun planning pour cette semaine.")
        if st.button("Créer le planning de la semaine", type="primary"):
            db.client().table("plannings").insert({
                "societe_id": company["id"],
                "debut_semaine": week.isoformat(),
                "libelle": f"Semaine {week.isocalendar().week}",
                "statut": "brouillon",
            }).execute()
            db.invalidate()
            st.rerun()
        return

    validation = db.call("fn_validate_schedule", p_schedule=schedule["id"])
    creneaux = db.rows("creneaux", "*, salaries(id, prenom, nom)",
                     planning_id=schedule["id"], _order="date_creneau")
    absences = db.rows("absences", "*, types_absence(libelle, categorie)", societe_id=company["id"])

    header = st.columns([3, 1, 2])
    header[1].markdown(
        ds.badge("Publié" if schedule["statut"] == "publie" else "Brouillon",
                 "ok" if schedule["statut"] == "publie" else "neutral"),
        unsafe_allow_html=True)
    publish_label = (
        "Publier et notifier" if validation["can_publish"]
        else f"Publier · {validation['blocking_count']} blocage(s)"
    )
    if header[2].button(publish_label, type="primary",
                        disabled=schedule["statut"] == "publie" or not validation["can_publish"]):
        try:
            db.engine("fn_publish_schedule", p_schedule=schedule["id"])
            db.invalidate()
            st.success("Planning publié.")
            st.rerun()
        except Exception as error:
            st.error(str(error))

    # --- grille ---
    grid: dict[str, dict[str, list[str]]] = {}
    for shift in creneaux:
        employee = shift.get("salaries") or {}
        name = f"{salarie.get('prenom','')} {salarie.get('nom','')}".strip()
        column = DAYS[date.fromisoformat(shift["date_creneau"]).weekday()]
        grid.setdefault(name, {}).setdefault(column, []).append(
            f"{shift['heure_debut'][:5]}–{shift['heure_fin'][:5]}"
        )
    for absence in absences:
        if absence["statut"] == "refuse":
            continue
        for i, day in enumerate(days):
            if absence["date_debut"] <= day.isoformat() <= absence["date_fin"]:
                employee = next(
                    (f"{s['salaries']['prenom']} {s['salaries']['nom']}"
                     for s in creneaux if s["salarie_id"] == absence["salarie_id"]), None)
                if employee:
                    label = (absence.get("types_absence") or {}).get("libelle", "Absence")
                    grid.setdefault(employee, {}).setdefault(DAYS[i], []).append(f"[{libelle}]")

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

        if validation["salaries"]:
            st.dataframe(
                pd.DataFrame([{
                    "Salarié": e["employee_name"],
                    "Heures": e["total_hours"],
                    "Heures sup.": e["heures_supplementaires"],
                    "Sup. autorisées": "oui" if e.get("overtime_allowed", True) else "NON",
                    "Dimanches": e["sundays"],
                    "Repos le plus long": f"{e['longest_rest_hours']} h",
                } for e in validation["salaries"]]),
                use_container_width=True, hide_index=True)

    with right:
        ds.section("Contrôles légaux", "évalué à chaque modification")
        if not validation["violations"]:
            st.success("Aucune violation : le planning est publiable.")
        for violation in validation["violations"]:
            ds.alert_card(violation["severite"], violation["titre"], violation["detail"],
                          None, violation.get("reference_legale"))

    with st.expander("Ajouter un shift"):
        _shift_form(company, schedule, days)


def _shift_form(company: dict, schedule: dict, days: list[date]) -> None:
    salaries = db.rows("salaries", "id, prenom, nom",
                        societe_id=company["id"], _order="nom")
    templates = db.rows("modeles_creneau", "*", societe_id=company["id"], _order="heure_debut")
    if not salaries:
        st.caption("Aucun salarié dans ce dossier.")
        return

    with st.form("shift"):
        columns = st.columns(4)
        names = {f"{e['nom']} {e['prenom']}": e["id"] for e in salaries}
        who = columns[0].selectbox("Salarié", list(names))
        when = columns[1].selectbox("Jour", days, format_func=ds.fmt_date)
        template_names = {"— saisie libre —": None} | {t["nom"]: t for t in templates}
        template = columns[2].selectbox("Modèle", list(template_names))
        pause_minutes = columns[3].number_input("Pause (min)", 0, 240, 30, step=15)
        picked = template_names[template]
        start = columns[0].text_input("Début", picked["heure_debut"][:5] if picked else "09:00")
        end = columns[1].text_input("Fin", picked["heure_fin"][:5] if picked else "17:00")
        label = columns[2].text_input("Libellé", picked["nom"] if picked else "Service")

        if st.form_submit_button("Ajouter", type="primary"):
            try:
                db.client().table("creneaux").insert({
                    "planning_id": schedule["id"],
                    "societe_id": company["id"],
                    "salarie_id": names[who],
                    "date_creneau": when.isoformat(),
                    "heure_debut": start,
                    "heure_fin": end,
                    "pause_minutes": int(pause_minutes),
                    "libelle": label,
                    "modele_id": picked["id"] if picked else None,
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
        "*, salaries(prenom, nom), types_absence(libelle, categorie, impute_sur_conge, reference_legale)",
        societe_id=company["id"], _order="date_debut", _desc=True,
    )
    pending = [a for a in absences if a["statut"] == "en_attente"]

    ds.section("Demandes en attente", f"{len(en_attente)} à traiter")
    for absence in pending:
        employee = absence.get("salaries") or {}
        kind = absence.get("types_absence") or {}
        impact = db.call("fn_leave_request_impact",
                         p_employee=absence["salarie_id"],
                         p_type=absence["type_absence_id"],
                         p_start=absence["date_debut"], p_end=absence["date_fin"])

        with st.container(border=True):
            columns = st.columns([3, 2, 2])
            columns[0].markdown(
                f"**{ds.esc(salarie.get('prenom',''))} {ds.esc(salarie.get('nom',''))}** — "
                f"{ds.esc(genre.get('libelle',''))}<br>"
                f"<span class='lux-muted'>{ds.fmt_date(absence['date_debut'])} – "
                f"{ds.fmt_date(absence['date_fin'])} · {ds.fmt_num(absence['nombre_jours'])} jour(s)</span>",
                unsafe_allow_html=True)
            columns[1].markdown(
                ds.badge("Conforme" if impact["is_valid"] else "Refus recommandé",
                         "ok" if impact["is_valid"] else "bloquant"),
                unsafe_allow_html=True)
            columns[1].caption(impact["message"])
            if impact.get("balance_after") is not None:
                columns[2].metric("Solde après", f"{ds.fmt_num(impact['balance_after'])} j")
            if impact.get("reference_legale"):
                columns[2].markdown(ds.legal_ref_chip(impact["reference_legale"]), unsafe_allow_html=True)

            actions = st.columns([1, 1, 6])
            if actions[0].button("Valider", key=f"ok_{absence['id']}", type="primary"):
                _decide(absence["id"], "valide")
            if actions[1].button("Refuser", key=f"no_{absence['id']}"):
                _decide(absence["id"], "refuse")

    ds.section("Toutes les absences")
    if absences:
        st.dataframe(
            pd.DataFrame([{
                "Salarié": f"{(a.get('salaries') or {}).get('prenom','')} "
                           f"{(a.get('salaries') or {}).get('nom','')}".strip(),
                "Type": (a.get("types_absence") or {}).get("libelle", ""),
                "Du": ds.fmt_date(a["date_debut"]),
                "Au": ds.fmt_date(a["date_fin"]),
                "Jours": a["nombre_jours"],
                "Statut": a["statut"],
            } for a in absences]),
            use_container_width=True, hide_index=True, height=360)

    ds.section("Soldes de l’équipe")
    salaries = db.rows("salaries", "id, prenom, nom",
                        societe_id=company["id"], _order="nom", _limit=25)
    balances = []
    for employee in salaries:
        balance = db.call("fn_leave_balance", p_employee=employee["id"], p_on=on)
        if not balance.get("no_contract"):
            balances.append({
                "Salarié": f"{salarie['prenom']} {salarie['nom']}",
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
            "statut": status,
            "decide_le": "now()",
            "decide_par": st.session_state["session"]["compte_id"],
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
    salaries = db.rows("salaries", "id, prenom, nom",
                        societe_id=company["id"], _order="nom")
    table_rows = []
    for employee in salaries:
        counters = db.call("fn_sick_counters", p_employee=employee["id"], p_on=on)
        if counters["days_in_window"] == 0:
            continue
        table_rows.append({
            "Salarié": f"{salarie['prenom']} {salarie['nom']}",
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
    salaries = db.rows("salaries", "id, prenom, nom",
                        societe_id=company["id"], _order="nom")
    types = db.rows("types_absence", "id, code, libelle")
    sick_type = next((t for t in types if t["code"] == "maladie"), None)
    if not salaries or not sick_type:
        return
    with st.form("maladie"):
        columns = st.columns(5)
        names = {f"{e['nom']} {e['prenom']}": e["id"] for e in salaries}
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
                    "societe_id": company["id"],
                    "salarie_id": names[who],
                    "type_absence_id": sick_type["id"],
                    "date_debut": start.isoformat(),
                    "date_fin": end.isoformat(),
                    "nombre_jours": float(days),
                    "statut": "valide",
                    "certificat_recu": certificate,
                    "certificat_original_recu": original,
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
    requests = db.rows("demandes_heures_sup", "*, salaries(prenom, nom)",
                       societe_id=company["id"], _order="debut_periode", _desc=True)

    for request in requests:
        employee = request.get("salaries") or {}
        with st.container(border=True):
            columns = st.columns([3, 2, 2, 2])
            columns[0].markdown(
                f"**{ds.esc(salarie.get('prenom',''))} {ds.esc(salarie.get('nom',''))}**<br>"
                f"<span class='lux-muted'>{ds.fmt_date(request['debut_periode'])} – "
                f"{ds.fmt_date(request['fin_periode'])} · {ds.fmt_num(request['heures'])} h · "
                f"{ds.esc(request['motif'])}</span>",
                unsafe_allow_html=True)
            tone = {"valide": "ok", "refuse": "bloquant", "demande": "info",
                    "hr_approved": "warning", "cancelled": "neutral"}[request["statut"]]
            columns[1].markdown(ds.badge(request["statut"], tone), unsafe_allow_html=True)
            columns[2].caption(
                ("RH : validé" if request["valide_rh_le"] else "RH : en attente")
                + " · "
                + ("salarié : accepté" if request["accepte_par_salarie_le"] else "salarié : en attente")
            )
            if request["statut"] in ("demande", "valide_rh"):
                if not request["valide_rh_le"] and columns[3].button(
                        "Valider (RH)", key=f"hr_{request['id']}", type="primary"):
                    _approve(request["id"], True)
                if not request["accepte_par_salarie_le"] and columns[3].button(
                        "Accepter (salarié)", key=f"emp_{request['id']}"):
                    _approve(request["id"], False)

    if not requests:
        st.caption("Aucune demande enregistrée.")

    with st.expander("Nouvelle demande"):
        salaries = db.rows("salaries", "id, prenom, nom",
                            societe_id=company["id"], _order="nom")
        if salaries:
            with st.form("overtime"):
                columns = st.columns(5)
                names = {f"{e['nom']} {e['prenom']}": e["id"] for e in salaries}
                who = columns[0].selectbox("Salarié", list(names))
                start = columns[1].date_input("Du", db.reference_date())
                end = columns[2].date_input("Au", db.reference_date())
                hours = columns[3].number_input("Heures", 0.5, 200.0, 4.0, step=0.5)
                compensation = columns[4].selectbox("Compensation", ["argent", "repos"])
                reason = st.text_input("Motif", "Surcroît ponctuel d’activité")
                if st.form_submit_button("Enregistrer la demande", type="primary"):
                    try:
                        db.client().table("demandes_heures_sup").insert({
                            "societe_id": company["id"],
                            "salarie_id": names[who],
                            "debut_periode": start.isoformat(),
                            "fin_periode": end.isoformat(),
                            "heures": float(hours),
                            "motif": reason,
                            "compensation": compensation,
                            "demande_par": st.session_state["session"]["compte_id"],
                        }).execute()
                        db.invalidate()
                        st.rerun()
                    except Exception as error:
                        st.error(str(error))


def _approve(identifiant_requete: str, as_hr: bool) -> None:
    try:
        db.engine("fn_overtime_approve", p_request=identifiant_requete, p_as_hr=as_hr)
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
    grants = db.rows("attributions_titres_repas", "*, salaries(prenom, nom)",
                     societe_id=company["id"], _order="debut_periode", _desc=True)

    if grants:
        table_rows = []
        for grant in grants:
            check = db.call("fn_meal_voucher_check", p_grant=grant["id"])
            employee = grant.get("salaries") or {}
            table_rows.append({
                "Salarié": f"{salarie.get('prenom','')} {salarie.get('nom','')}".strip(),
                "Période": check["period"],
                "Nombre": grant["nombre_titres"],
                "Valeur faciale": ds.fmt_eur(grant["valeur_faciale"]),
                "Part salarié": ds.fmt_eur(grant["part_salariale"]),
                "Coût employeur": ds.fmt_eur(check["employer_cost"]),
                "Alertes": check["warning_count"],
            })
        st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True)
    else:
        st.caption("Aucune attribution enregistrée.")

    with st.expander("Nouvelle attribution"):
        salaries = db.rows("salaries", "id, prenom, nom",
                            societe_id=company["id"], _order="nom")
        if salaries:
            with st.form("vouchers"):
                columns = st.columns(5)
                names = {f"{e['nom']} {e['prenom']}": e["id"] for e in salaries}
                who = columns[0].selectbox("Salarié", list(names))
                start = columns[1].date_input("Du", db.reference_date().replace(day=1))
                end = columns[2].date_input("Au", db.reference_date())
                count = columns[3].number_input("Nombre", 0, 40, 20)
                face = columns[4].number_input("Valeur faciale", 0.0, 50.0, 15.0, step=0.5)
                share = st.number_input("Participation du salarié", 0.0, 50.0, 2.8, step=0.1)
                if st.form_submit_button("Attribuer", type="primary"):
                    try:
                        db.client().table("attributions_titres_repas").insert({
                            "societe_id": company["id"],
                            "salarie_id": names[who],
                            "debut_periode": start.isoformat(),
                            "fin_periode": end.isoformat(),
                            "nombre_titres": int(count),
                            "valeur_faciale": float(face),
                            "part_salariale": float(share),
                            "attribue_le": db.reference_date().isoformat(),
                        }).execute()
                        db.invalidate()
                        st.rerun()
                    except Exception as error:
                        st.error(str(error))
