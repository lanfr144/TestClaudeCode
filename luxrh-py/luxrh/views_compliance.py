"""Contrats, vigilance, licenciement collectif, primes et référentiel."""

from __future__ import annotations

import pandas as pd
import streamlit as st

from . import client as db
from . import design as ds

CATEGORIES = {
    "all": "Toutes",
    "contract": "Contrats",
    "worktime": "Temps de travail",
    "absence": "Absences",
    "headcount": "Effectif",
    "document": "Documents",
    "protection": "Protections",
}


# =================================================================== contrats

def contracts() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return

    rows = db.rows("contracts", "*, employees(first_name, last_name)",
                   company_id=company["id"], _order="start_date", _desc=True)
    ds.section("Contrats", f"{len(rows)} contrat(s) dans ce dossier")
    st.dataframe(
        pd.DataFrame([{
            "Salarié": f"{(c.get('employees') or {}).get('first_name','')} "
                       f"{(c.get('employees') or {}).get('last_name','')}".strip(),
            "Type": c["kind"].upper(),
            "Temps partiel": "oui" if c.get("is_part_time") else "",
            "Poste": c["job_title"],
            "Début": ds.fmt_date(c["start_date"]),
            "Fin": ds.fmt_date(c["end_date"]) if c["end_date"] else "—",
            "Brut": ds.fmt_eur(c["monthly_gross"]),
            "Statut": c["status"],
        } for c in rows]),
        use_container_width=True, hide_index=True, height=340)

    if not rows:
        return

    labels = {
        f"{(c.get('employees') or {}).get('last_name','')} — {c['job_title']} ({c['kind'].upper()})": c["id"]
        for c in rows
    }
    chosen = st.selectbox("Analyser un contrat", list(labels))
    _contract_compliance(labels[chosen])


def _contract_compliance(contract_id: str) -> None:
    on = db.reference_date()
    compliance = db.call("fn_contract_compliance", p_contract=contract_id, p_on=on)
    salary = compliance["salary"]

    left, right = st.columns([2, 1])
    with left:
        ds.section(
            "Panneau de conformité",
            f"{compliance['blocking_count']} blocage(s), {compliance['warning_count']} avertissement(s)",
        )
        st.markdown(
            ds.badge("Validable" if compliance["can_validate"] else "Blocage",
                     "ok" if compliance["can_validate"] else "blocking"),
            unsafe_allow_html=True)
        ds.checks_list(compliance["checks"])

        ds.section("Mentions obligatoires")
        for mention in compliance["mandatory_mentions"]:
            st.markdown(f"{'✓' if mention['ok'] else '○'} {mention['label']}")

    with right:
        ds.section("Salaire minimum applicable")
        st.markdown(
            f"<div class='lux-card'>"
            f"<div class='lux-muted'>SSM {'qualifié' if salary['is_qualified'] else 'non qualifié'}"
            f" · {salary['age_band']}</div>"
            f"<div style='font-size:20px;font-weight:700'>{ds.fmt_eur(salary['ssm'])}</div>"
            f"<div class='lux-muted'>{salary['qualification']['source']}</div></div>",
            unsafe_allow_html=True)
        if salary.get("cba_grid") is not None:
            st.markdown(
                f"<div class='lux-card'><div class='lux-muted'>Grille "
                f"{salary.get('cba_name') or 'CCT'} · cat. {salary.get('cba_category')}</div>"
                f"<div style='font-size:20px;font-weight:700'>{ds.fmt_eur(salary['cba_grid'])}</div>"
                f"</div>", unsafe_allow_html=True)
        ds.legal_basis(salary.get("ssm_ref"), value=ds.fmt_eur(salary.get("ssm_full")),
                       validity=f"indice {ds.fmt_num(salary.get('ssm_index'))}"
                       if salary.get("ssm_index") else None, source="CCSS")

        if compliance.get("probation"):
            probation = compliance["probation"]
            ds.section("Dates calculées")
            st.metric("Dernier jour pour notifier la rupture d’essai",
                      ds.fmt_date(probation["last_day_to_notify"]),
                      f"J-{probation['days_until_deadline']}")
            st.caption(
                f"Essai jusqu’au {ds.fmt_date(probation['end'])} · préavis de "
                f"{probation['notice_days']} jours"
                + (f" · prolongé de {probation['extension_days']} jour(s) par une incapacité"
                   if probation["extension_days"] else "")
            )

    ds.section("Conventions applicables")
    for agreement in compliance["collective_agreements"]:
        st.markdown(
            f"{ds.badge(agreement['origin'], 'violet')} **{agreement['name']}** "
            f"<span class='lux-muted'>({agreement['scope']})</span>",
            unsafe_allow_html=True)
    ds.arbitration(compliance["annual_leave"], "j")


# ================================================================== vigilance

def vigilance() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()
    scan = db.call("fn_compliance_scan", p_company=company["id"], p_on=on)

    ds.section("Centre de vigilance",
               "Toutes les obligations, leur base légale et la conséquence du non-respect.")
    chosen = st.radio("Filtrer", list(CATEGORIES), horizontal=True,
                      format_func=lambda k: CATEGORIES[k], label_visibility="collapsed")

    def keep(items: list[dict]) -> list[dict]:
        return items if chosen == "all" else [i for i in items if i.get("category") == chosen]

    left, right = st.columns([2, 1])
    with left:
        for title, items in (
            ("En retard", keep(scan["overdue"])),
            (f"Dans les {scan['horizon_days']} jours", keep(scan["due_soon"])),
            ("À surveiller", keep(scan["watch"])),
        ):
            st.markdown(f"**{title} · {len(items)}**")
            if not items:
                st.caption("Rien à signaler.")
            for item in items:
                days = item.get("days_left")
                right_text = (
                    "à surveiller" if days is None
                    else (f"échu depuis {abs(days)} j" if days < 0 else f"J-{days}")
                )
                ds.alert_card(item["severity"], item["title"], item["detail"],
                              item.get("consequence"), item.get("legal_ref"), right_text)

    with right:
        obligations = scan["headcount"]
        ds.section("Seuils d’effectif",
                   f"Effectif moyen {ds.fmt_num(obligations['headcount']['average'])} "
                   f"sur {obligations['headcount']['reference_months']} mois")
        for threshold in obligations["thresholds"]:
            st.markdown(
                f"{ds.badge(threshold['status'], 'warning' if threshold['reached'] else 'neutral')} "
                f"**{ds.fmt_num(threshold['threshold'], 0)}** — {threshold['label']}",
                unsafe_allow_html=True)
        if obligations.get("delegates_due"):
            due = obligations["delegates_due"]
            st.caption(
                f"Tranche {due['from']}–{due['to'] or '+'} : {due['effective']} délégué(s) "
                f"effectif(s) et {due['substitute']} suppléant(s), scrutin {obligations['vote_mode']}."
            )
        st.caption("Chaque seuil est lu dans le référentiel daté, jamais codé en dur.")

    ds.disclaimer(scan.get("disclaimer"))


# ============================================== simulateur de licenciement

def dismissal_simulator() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    ds.section("Simuler un scénario de licenciement",
               "Aide à la décision. Aucune notification n’est envoyée depuis cet écran.")
    counters = db.call("fn_collective_dismissal_counters", p_company=company["id"], p_on=on)

    columns = st.columns(4)
    count = columns[0].number_input("Nombre de licenciements", 1, 500, 6)
    when = columns[1].date_input("Date de notification envisagée", on)
    ground = columns[2].selectbox("Motif", ["Non inhérent à la personne", "Inhérent à la personne"])
    run = columns[3].button("Simuler", type="primary")

    left, right = st.columns([2, 1])
    with right:
        ds.section(f"Compteurs glissants au {ds.fmt_date(on)}")
        for label, window in (("30 jours", counters["window_30"]), ("90 jours", counters["window_90"])):
            st.markdown(
                f"<div class='lux-card'><div class='lux-label'>{label}</div>"
                f"<div style='font-size:22px;font-weight:700'>{window['count']} / "
                f"{ds.fmt_num(window['threshold'], 0)}</div>"
                f"<div class='lux-muted'>encore {window['remaining']} possible(s) · se libère le "
                f"{ds.fmt_date(window['releases_on'])}</div></div>",
                unsafe_allow_html=True)
        ds.legal_basis("art. L.166-1",
                       "La procédure s’applique dès que le nombre de licenciements pour un motif "
                       "non inhérent à la personne atteint le seuil sur 30 ou sur 90 jours.",
                       source="Legilux")

    with left:
        if run:
            result = db.engine(
                "fn_simulate_collective_dismissal",
                p_company=company["id"], p_count=int(count), p_date=when,
                p_personal_ground=ground.startswith("Inhérent"))
            st.session_state["simulation"] = result

        result = st.session_state.get("simulation")
        if result:
            ds.alert_card(
                "blocking" if result["triggers"] else "ok",
                "La procédure de licenciement collectif se déclenche" if result["triggers"]
                else "La procédure ne se déclenche pas",
                result["verdict"],
                None, ", ".join(result.get("legal_refs", [])))

            for alternative in result.get("alternatives", []):
                st.markdown(f"· **Alternative** — {alternative['label']}")

            if result.get("timeline"):
                ds.section("Chronologie de la procédure")
                for step in result["timeline"]:
                    st.markdown(
                        f"<div class='lux-card'><span class='lux-mono'>{step['when']}</span>"
                        f"<div style='font-weight:600'>{step['title']}</div>"
                        f"<div class='lux-muted'>{step['detail']}</div></div>",
                        unsafe_allow_html=True)
                st.warning("Aucune notification ne peut intervenir avant l’issue de la procédure.")
            ds.disclaimer(result.get("disclaimer"))


# ==================================================================== primes

def premiums() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    year = st.number_input("Exercice", 2019, 2100, db.reference_date().year)

    caps = db.call("fn_premium_caps", p_company=company["id"], p_year=int(year))
    ds.section("Primes et plafonds légaux",
               "Le régime participatif est plafonné par salarié et par entreprise.")

    if not caps.get("found"):
        st.warning(caps.get("message"))
    else:
        columns = st.columns(4)
        with columns[0]:
            ds.stat("Plafond individuel", f"{ds.fmt_num(caps['individual_cap_pct'], 0)} %",
                    "du brut annuel")
        with columns[1]:
            ds.stat("Plafond entreprise", f"{ds.fmt_num(caps['company_cap_pct'])} %",
                    f"du bénéfice {int(year) - 1}")
        with columns[2]:
            ds.stat("Enveloppe",
                    ds.fmt_eur(caps["envelope"]) if caps["envelope"] is not None else "—",
                    "non calculable" if caps["envelope"] is None else "disponible")
        with columns[3]:
            ds.stat("Distribué", ds.fmt_eur(caps["envelope_used"]),
                    "dépassement" if caps["envelope_exceeded"] else "dans l’enveloppe",
                    "blocking" if caps["envelope_exceeded"] else "ok")
        st.caption(caps.get("message", ""))

        if caps["employees"]:
            st.dataframe(
                pd.DataFrame([{
                    "Salarié": e["employee_name"],
                    "Brut annuel": ds.fmt_eur(e["annual_gross"]),
                    "Plafond individuel": ds.fmt_eur(e["individual_cap"]),
                    "Attribué": ds.fmt_eur(e["granted"]),
                    "Dans le plafond": "oui" if e["within_cap"] else "NON",
                    "Excédent": ds.fmt_eur(e["excess"]) if e["excess"] else "—",
                } for e in caps["employees"]]),
                use_container_width=True, hide_index=True)
        ds.legal_basis(caps.get("legal_ref"),
                       "La prime individuelle ne peut excéder le pourcentage du brut annuel, et "
                       "l’enveloppe distribuée le pourcentage du bénéfice de l’exercice précédent.",
                       source="ACD")

    with st.expander("Bénéfice de l’exercice précédent"):
        with st.form("financials"):
            profit = st.number_input("Bénéfice", value=0.0, step=1000.0, format="%.2f")
            if st.form_submit_button("Enregistrer", type="primary"):
                try:
                    db.client().table("company_financials").upsert({
                        "company_id": company["id"],
                        "fiscal_year": int(year) - 1,
                        "profit": profit,
                        "source": "saisie manuelle",
                    }, on_conflict="company_id,fiscal_year").execute()
                    db.invalidate()
                    st.rerun()
                except Exception as error:
                    st.error(str(error))


# =============================================================== référentiel

def referential() -> None:
    on = db.reference_date()
    parameters = db.rows("legal_parameters", "*", _order="param_key")
    gaps = db.call("fn_referential_gaps", p_since="2019-12-31")
    holes = db.call("fn_referential_holes")
    inconsistencies = db.call("fn_referential_inconsistencies", p_on=on)

    ds.section("Référentiel légal daté",
               "Les valeurs lues sont celles en vigueur à la date du calcul, jamais les actuelles.")

    columns = st.columns(3)
    with columns[0]:
        ds.stat("Couvrent 2019", sum(1 for g in gaps if g["covers_since"]), tone="ok")
    with columns[1]:
        ds.stat("À compléter", sum(1 for g in gaps if not g["covers_since"]),
                "historique manquant", "warning")
    with columns[2]:
        ds.stat("Trous internes", len(holes), "périodes non couvertes",
                "blocking" if holes else "ok")

    if inconsistencies:
        for item in inconsistencies:
            ds.alert_card(
                "warning", item["label"],
                f"Valeur publiée {ds.fmt_num(item['published'])}, dérivée de {item['source_key']} "
                f"{ds.fmt_num(item['derived'])} — écart de {ds.fmt_num(item['difference'])}.",
                "Une indexation a peut-être été saisie à moitié.")

    st.caption(
        "Aucune valeur n’est inventée. Les paramètres sans historique doivent être saisis depuis "
        "la source officielle avant tout recalcul portant sur une période antérieure."
    )

    families = sorted({p["family"] for p in parameters})
    family = st.selectbox("Famille", families,
                          index=families.index("ccss") if "ccss" in families else 0)
    in_force = [
        p for p in parameters
        if p["family"] == family and p["valid_from"] <= on.isoformat()
        and (not p["valid_to"] or p["valid_to"] > on.isoformat())
    ]
    st.dataframe(
        pd.DataFrame([{
            "Paramètre": p["label"],
            "Clé": p["param_key"],
            "Valeur": _value(p),
            "En vigueur": ds.fmt_date(p["valid_from"]),
            "Indice": p["index_ref"],
            "Source": p["source"],
            "Base légale": p["legal_ref"] or "—",
        } for p in in_force]),
        use_container_width=True, hide_index=True, height=400)

    keys = sorted({p["param_key"] for p in parameters if p["family"] == family})
    if not keys:
        return
    key = st.selectbox("Historique d’un paramètre", keys)
    history = [p for p in parameters if p["param_key"] == key]
    history.sort(key=lambda p: p["valid_from"], reverse=True)
    st.dataframe(
        pd.DataFrame([{
            "Du": ds.fmt_date(p["valid_from"]),
            "Au": ds.fmt_date(p["valid_to"]) if p["valid_to"] else "…",
            "Valeur": _value(p),
            "Source": p["source"],
            "Note": p["note"] or "",
        } for p in history]),
        use_container_width=True, hide_index=True)

    _new_version_form(key, history)


def _value(row: dict) -> str:
    if row["value_num"] is not None:
        return f"{ds.fmt_num(row['value_num'], 4)} {row['unit'] or ''}".strip()
    if row["value_text"] is not None:
        return row["value_text"]
    if row.get("derived_from_key"):
        return f"dérivé de {row['derived_from_key']} × {row.get('derived_factor')}"
    return str(row["value_json"])


def _new_version_form(key: str, history: list[dict]) -> None:
    current = history[0] if history else None
    with st.expander("Charger une nouvelle version datée"):
        st.caption(
            "Les paramètres sociaux sont publiés par le CCSS et l’ACD après chaque changement. "
            "La date d’application et la date de chargement sont distinctes : si la nouvelle "
            "valeur s’applique à une période déjà traitée, les recalculs sont signalés."
        )
        with st.form(f"version_{key}"):
            columns = st.columns(3)
            valid_from = columns[0].date_input("Applicable à compter du", db.reference_date())
            value = columns[1].text_input("Nouvelle valeur")
            source = columns[2].text_input("Source", current["source"] if current else "CCSS")
            note = st.text_input("Note", "Chargement depuis la publication officielle.")
            if st.form_submit_button("Enregistrer la version", type="primary"):
                try:
                    numeric = current and current["value_num"] is not None
                    db.engine("fn_add_parameter_version",
                              p_key=key, p_valid_from=valid_from,
                              p_value_num=float(value.replace(",", ".")) if numeric else None,
                              p_value_text=None if numeric else value,
                              p_value_json=None, p_source=source,
                              p_index_ref=None, p_note=note)
                    db.invalidate()
                    st.success(
                        "Version enregistrée. La précédente est clôturée à cette date ; "
                        "une double lecture par une autre personne reste requise."
                    )
                    st.rerun()
                except Exception as error:
                    st.error(str(error))
