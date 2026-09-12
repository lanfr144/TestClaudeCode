"""Tableau de bord, sociétés et employés."""

from __future__ import annotations

import pandas as pd
import streamlit as st

from . import client as db
from . import design as ds
from .design import sans_fin


# ============================================================= tableau de bord

def dashboard() -> None:
    company = db.active_company()
    if not company:
        st.warning("Aucun dossier dans cet espace. Ouvrez l’écran *Sociétés* pour en créer un.")
        return

    on = db.reference_date()
    scan = db.call("fn_compliance_scan", p_company=company["id"], p_on=on)
    profile = db.profile() or {}
    prenom = (profile.get("nom_complet") or "").split(" ")[0]

    attention = len(scan["overdue"]) + len(scan["due_soon"])
    headcount = scan["effectif"]["effectif"]

    st.markdown(
        f"## Bonjour {prenom} — "
        + ("aucun point ne demande votre attention"
           if attention == 0
           else f"{attention} point{'s' if attention > 1 else ''} "
                f"demande{'nt' if attention > 1 else ''} votre attention")
    )
    st.caption(
        f"{on.strftime('%A %d %B %Y')} · {company['raison_sociale']} · "
        f"{effectif['current']} salariés"
    )

    columns = st.columns(4)
    with columns[0]:
        ds.stat("En retard", len(scan["overdue"]),
                scan["overdue"][0]["titre"].split("—")[0] if scan["overdue"] else "Rien en retard",
                "blocking" if scan["overdue"] else "ok")
    with columns[1]:
        ds.stat(f"Dans les {scan['horizon_days']} jours", len(scan["due_soon"]),
                "Essai, CDD, documents", "warning" if scan["due_soon"] else "ok")
    with columns[2]:
        threshold = scan["effectif"]["thresholds"][0]
        ds.stat(f"Effectif · {effectif['reference_months']} mois",
                f"{effectif['rounded']} / {ds.fmt_num(threshold['threshold'], 0)}",
                f"moyenne {ds.fmt_num(effectif['average'])} · {threshold['statut']}",
                "warning" if threshold["reached"] else "neutral")
    with columns[3]:
        blocking = sum(1 for i in scan["items"] if i["code_regle"] == "schedule_blocking")
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
            st.markdown(f"**{titre} · {len(items)}**")
            if not items:
                st.caption("Rien à signaler dans ce bloc.")
            for item in items:
                ds.alert_card(
                    item["severite"], item["titre"], item["detail"],
                    item.get("consequence"), item.get("reference_legale"),
                    _deadline(item),
                )

    with right:
        counters = scan["dismissal_counters"]
        ds.section("Compteur licenciement collectif")
        for label, window in (("30 jours glissants", counters["window_30"]),
                              ("90 jours glissants", counters["window_90"])):
            st.markdown(
                f'<div class="lux-card"><div class="lux-libelle">{libelle}</div>'
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
                f'<b>{ds.fmt_num(index["valeur_num"])}</b>, en vigueur depuis le '
                f'<b>{ds.fmt_date(index["debut_validite"])}</b>.</span></div>',
                unsafe_allow_html=True,
            )

    ds.disclaimer(scan.get("disclaimer"))


def _deadline(item: dict) -> str:
    days = item.get("days_left")
    if days is None:
        return "à surveiller"
    if days < 0:
        return f"échu depuis {abs(jours)} j"
    return "aujourd’hui" if days == 0 else f"J-{jours}"


@st.cache_data(ttl=300, show_spinner=False)
def _params_cached(_token: str) -> list[dict]:
    return db.rows("parametres_legaux", "*", _order="cle_parametre")


def _param(key: str) -> dict | None:
    token = st.session_state.get("session", {}).get("access_token", "")
    on = db.reference_date().isoformat()
    for row in _params_cached(token):
        if row["cle_parametre"] == key and row["debut_validite"] <= on and row["fin_validite"] > on:
            return row
    return None


# =================================================================== sociétés

def companies_view() -> None:
    ds.section("Sociétés", "Chaque dossier client est cloisonné en base, pas dans l’interface.")
    on = db.reference_date().isoformat()
    all_companies = db.societes()

    table_rows = []
    for company in all_companies:
        active = [
            link for link in (company.get("conventions_de_la_societe") or [])
            if link["debut_validite"] <= on and link["fin_validite"] > on
        ]
        table_rows.append({
            "Société": company["raison_sociale"],
            "Secteur": company.get("secteur") or "—",
            "Conventions": ", ".join(
                link["conventions_collectives"]["code"] for link in active
                if link.get("conventions_collectives")
            ) or "aucune",
            "Matricule CCSS": company.get("matricule_ccss") or "—",
        })
    st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True)

    with st.expander("Créer une société"):
        _company_form()


def _company_form() -> None:
    with st.form("new_company"):
        columns = st.columns(3)
        raison_sociale = columns[0].text_input("Raison sociale *")
        forme_juridique = columns[1].text_input("Forme juridique", "Sàrl")
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

        agreements = db.rows("conventions_collectives", "id, nom, code, portee", _order="nom")
        options = {"— aucune convention —": None} | {
            f"{a['nom']} ({a['code']})": a["id"] for a in agreements
        }
        chosen = columns[1].selectbox("Convention collective", list(options))

        if st.form_submit_button("Créer la société", type="primary"):
            if not raison_sociale:
                st.error("La raison sociale est obligatoire.")
                return
            try:
                profile = db.profile()
                created = db.client().table("societes").insert({
                    "organisation_id": profile["organisation_id"],
                    "raison_sociale": raison_sociale,
                    "forme_juridique": forme_juridique or None,
                    "numero_rcs": rcs or None,
                    "matricule_ccss": "".join(filter(str.isdigit, ccss)) or None,
                    "ligne": address or None,
                    "code_postal": postal or None,
                    "localite": city or None,
                    "code_nace": nace or None,
                    "secteur": sector or None,
                }).execute().data[0]

                db.engine("fn_set_company_rates",
                          p_company=created["id"], p_from=rates_from,
                          p_mutuality_class=int(mutuality), p_accident_factor=float(accident),
                          p_activity_class=activity or None, p_accident_risk_class=None,
                          p_note="Période ouverte à la création du dossier.")

                if options[chosen]:
                    db.client().table("conventions_de_la_societe").insert({
                        "societe_id": created["id"],
                        "convention_id": options[chosen],
                        "debut_validite": rates_from.isoformat(),
                    }).execute()

                db.refresh_companies()
                db.invalidate()
                st.success(f"{raison_sociale} créée.")
                st.rerun()
            except Exception as error:  # aucune erreur silencieuse
                st.error(str(error))


def company_detail() -> None:
    company = db.active_company()
    if not company:
        st.info("Aucun dossier sélectionné.")
        return
    on = db.reference_date()

    st.markdown(f"## {company['raison_sociale']}")
    st.caption(
        f"{('RCS ' + company['numero_rcs'] + ' · ') if company.get('numero_rcs') else ''}"
        f"{company.get('ligne') or ''}, {company.get('code_postal') or ''} "
        f"{company.get('localite') or ''}"
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
                ("Matricule CCSS", company.get("matricule_ccss") or "—"),
                ("Classe d’activité", rates.get("classe_activite") or "—"),
                ("Classe Mutualité", f"{rates.get('classe_mutualite')} · {ds.fmt_pct(rates.get('mutuality_rate'))}"),
                ("Facteur accident", f"{ds.fmt_num(rates.get('facteur_accident'))} · {ds.fmt_pct(rates.get('accident_rate'))}"),
                ("Total charges patronales", ds.fmt_pct(rates.get("employer_total_pct"))),
            ):
                st.markdown(f"<span class='lux-muted'>{libelle}</span><br><b>{value}</b>",
                            unsafe_allow_html=True)

    with middle:
        ds.section("Conventions applicables")
        links = company.get("conventions_de_la_societe") or []
        if not links:
            st.caption("Aucune convention rattachée. Seul le Code du travail s’applique.")
        for link in links:
            agreement = link.get("conventions_collectives") or {}
            active = link["debut_validite"] <= on.isoformat() and link["fin_validite"] > on.isoformat(
            )
            st.markdown(
                f"<div class='lux-card' style='margin-bottom:6px'>"
                f"<b>{ds.esc(agreement.get('nom',''))}</b> {ds.badge('en vigueur' if active else 'échue', 'violet' if active else 'neutral')}"
                f"<div class='lux-muted'>{ds.fmt_date(link['debut_validite'])} → "
                f"{ds.fmt_date(link['fin_validite']) if not sans_fin(link['fin_validite']) else '…'}</div></div>",
                unsafe_allow_html=True,
            )

    with right:
        ds.section("Effectif et obligations")
        headcount = obligations["effectif"]
        st.metric("Effectif moyen", headcount["rounded"],
                  help=f"moyenne exacte {ds.fmt_num(effectif['average'])}")
        for threshold in obligations["thresholds"]:
            st.markdown(
                f"{ds.badge(threshold['statut'], 'warning' if threshold['reached'] else 'neutral')} "
                f"<span class='lux-muted'>{ds.fmt_num(threshold['threshold'],0)} — {threshold['libelle']}</span>",
                unsafe_allow_html=True,
            )

    ds.section("Historique des taux CCSS",
               "Classe d’activité, classe Mutualité et facteur accident évoluent dans le temps.")
    periods = db.rows("periodes_taux_societe", "*", societe_id=company["id"],
                      _order="debut_validite", _desc=True)
    if periods:
        st.dataframe(
            pd.DataFrame([{
                "Du": ds.fmt_date(p["debut_validite"]),
                "Au": ds.fmt_date(p["fin_validite"]) if not sans_fin(p["fin_validite"]) else "…",
                "Classe d’activité": p.get("classe_activite") or "—",
                "Mutualité": p.get("classe_mutualite"),
                "Facteur accident": p.get("facteur_accident"),
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

    salaries = db.rows(
        "salaries",
        "*, services(nom), contrats(id, genre, statut, intitule_poste, heures_hebdomadaires, brut_mensuel)",
        societe_id=company["id"], _order="nom",
    )
    scan = db.call("fn_compliance_scan", p_company=company["id"], p_on=on)
    alerts: dict[str, dict] = {}
    for item in scan["items"]:
        if item.get("salarie_id"):
            alerts.setdefault(item["salarie_id"], item)

    search = st.text_input("Rechercher", placeholder="Nom, prénom ou poste…")
    only_active = st.checkbox("Contrat actif seulement", value=True)

    table_rows = []
    for employee in salaries:
        contract = next((c for c in employee.get("contrats", []) if c["statut"] == "active"), None)
        if only_active and not contract:
            continue
        haystack = f"{employee['prenom']} {employee['nom']} {contract['intitule_poste'] if contract else ''}"
        if search and search.lower() not in haystack.lower():
            continue
        alert = alerts.get(employee["id"])
        table_rows.append({
            "Salarié": f"{employee['prenom']} {employee['nom']}",
            "Poste": contract["intitule_poste"] if contract else "—",
            "Contrat": contract["genre"].upper() if contract else "—",
            "Temps": f"{contract['heures_hebdomadaires']} h" if contract else "—",
            "Résidence": employee["residence"],
            "Conformité": alert["titre"].split("—")[0].strip() if alert else "Conforme",
        })

    st.caption(f"{len(table_rows)} salarié(s) affiché(s) sur {len(salaries)}.")
    st.dataframe(pd.DataFrame(table_rows), use_container_width=True, hide_index=True, height=420)

    names = {f"{e['nom']} {e['prenom']}": e["id"] for e in salaries}
    if names:
        chosen = st.selectbox("Ouvrir une fiche", list(names))
        if st.button("Ouvrir la fiche salarié"):
            st.session_state["salarie_id"] = names[chosen]
            st.session_state["goto"] = "employee_detail"
            st.rerun()


def employee_detail() -> None:
    salarie_id = st.session_state.get("salarie_id")
    if not salarie_id:
        st.info("Sélectionnez un salarié depuis la liste.")
        return
    on = db.reference_date()

    employee = db.client().table("salaries").select(
        "*, services(nom), fiches_retenue_impot(*), contrats(*)"
    ).eq("id", salarie_id).single().execute().data
    contract = next((c for c in employee.get("contrats", []) if c["statut"] == "active"), None)

    st.markdown(f"## {employee['prenom']} {employee['nom']}")
    st.caption(
        f"{contract['intitule_poste'] if contract else 'Sans contrat actif'}"
        f"{' · entrée le ' + ds.fmt_date(contract['date_debut']) if contract else ''}"
    )

    qualification = db.call("fn_is_qualified", p_employee=salarie_id, p_on=on)
    protections = db.call("fn_dismissal_protections", p_employee=salarie_id, p_on=on)
    overtime = db.call("fn_overtime_eligibility", p_employee=salarie_id, p_on=on)
    delegation = db.call("fn_delegation_eligibility", p_employee=salarie_id, p_on=on)
    balance = db.call("fn_leave_balance", p_employee=salarie_id, p_on=on)
    sick = db.call("fn_sick_counters", p_employee=salarie_id, p_on=on)
    disability = db.call("fn_disability_extra_leave", p_employee=salarie_id, p_on=on)
    children = db.call("fn_employee_children", p_employee=salarie_id, p_on=on)

    columns = st.columns(4)
    columns[0].markdown(
        f"<span class='lux-libelle'>Matricule</span><br>"
        f"<span class='lux-mono'>•••• {employee.get('matricule_national_indice') or '••••'}</span>",
        unsafe_allow_html=True)
    columns[1].markdown(f"<span class='lux-libelle'>Résidence</span><br>{employee['residence']}",
                        unsafe_allow_html=True)
    columns[2].markdown(f"<span class='lux-libelle'>Sexe</span><br>{employee['sexe']}",
                        unsafe_allow_html=True)
    columns[3].markdown(
        f"<span class='lux-libelle'>Qualification</span><br>"
        f"{'Qualifié(e)' if qualification['qualified'] else 'Non qualifié(e)'}",
        unsafe_allow_html=True)

    if protections.get("protected"):
        details = " · ".join(
            f"{p['libelle']}" + (f" jusqu’au {ds.fmt_date(p['until'])}" if p.get("until") else "")
            for p in protections["protections"]
        )
        ds.alert_card("info", "Protection contre le licenciement en cours", details,
                      "Toute notification pendant cette période serait nulle.",
                      protections["protections"][0].get("reference_legale"))

    if st.button("Afficher le matricule complet"):
        try:
            sensitive = db.engine("fn_employee_sensitive", p_employee=salarie_id)
            st.info(f"Matricule : {sensitive[0]['matricule_national']} · IBAN : {sensitive[0]['iban']}")
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
                    f"taux {ds.fmt_pct(disability.get('taux_pct'))}" if disability.get("applies") else "aucun statut")

        if balance.get("lines"):
            ds.section("Détail du solde", "Calcul reconstituable, ligne à ligne")
            st.dataframe(
                pd.DataFrame([{"Ligne": l["libelle"], "Signe": l["sign"], "Jours": l["value"]}
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
                ds.alert_card("blocking", reason["libelle"], reason["detail"],
                              None, reason.get("reference_legale"))
            statuses = db.rows("statuts_salarie", "*", salarie_id=salarie_id,
                               _order="date_debut", _desc=True)
            ds.section("Statuts déclarés")
            if not statuses:
                st.caption("Aucun statut particulier déclaré.")
            for status in statuses:
                st.markdown(
                    f"{ds.badge(statut['genre'], 'violet')} "
                    f"<span class='lux-muted'>du {ds.fmt_date(statut['date_debut'])} "
                    f"{'au ' + ds.fmt_date(statut['date_fin']) if statut['date_fin'] else '(sans terme)'}</span>",
                    unsafe_allow_html=True)
        with right:
            ds.section("Éligibilité à la délégation")
            if delegation["eligible"]:
                st.success("Éligible.")
            else:
                for reason in delegation["reasons"]:
                    st.markdown(f"· {motif['detail']}")
            ds.legal_basis(delegation.get("reference_legale"),
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
                    "Prénom": c.get("prenom") or "— (confidentiel)",
                    "Âge": c["age"],
                    "Né(e) le": ds.fmt_date(c["date_naissance"]),
                    "Lien": c["lien_parente"],
                    "Attentions": "non" if c["refus_partage"] else ("oui" if c["eligible_for_gift"] else "hors âge"),
                } for c in children["children"]]),
                use_container_width=True, hide_index=True)
        _child_form(employee)

    with tabs[3]:
        contrats = employee.get("contrats", [])
        if contrats:
            st.dataframe(
                pd.DataFrame([{
                    "Type": c["genre"].upper(),
                    "Poste": c["intitule_poste"],
                    "Début": ds.fmt_date(c["date_debut"]),
                    "Fin": ds.fmt_date(c["date_fin"]) if c["date_fin"] else "—",
                    "Brut": ds.fmt_eur(c["brut_mensuel"]),
                    "Statut": c["statut"],
                } for c in contrats]),
                use_container_width=True, hide_index=True)


def _child_form(employee: dict) -> None:
    with st.expander("Ajouter un enfant"):
        with st.form(f"child_{employee['id']}"):
            privacy = st.checkbox(
                "Le salarié refuse les attentions de la société",
                help="Seule la date de naissance est alors conservée, pour établir les droits à congé.",
            )
            columns = st.columns(4)
            prenom = columns[0].text_input("Prénom", disabled=privacy)
            nom = columns[1].text_input("Nom", disabled=privacy)
            sex = columns[2].selectbox("Sexe", ["unspecified", "female", "male"], disabled=privacy)
            birth = columns[3].date_input("Date de naissance")
            relationship = st.selectbox("Lien", ["child", "adopted", "foster", "stepchild"])
            if st.form_submit_button("Enregistrer", type="primary"):
                try:
                    db.client().table("enfants_salarie").insert({
                        "societe_id": employee["societe_id"],
                        "salarie_id": employee["id"],
                        "prenom": None if privacy else (prenom or None),
                        "nom": None if privacy else (nom or None),
                        "sexe": None if privacy else sex,
                        "date_naissance": birth.isoformat(),
                        "lien_parente": relationship,
                        "refus_partage": privacy,
                    }).execute()
                    db.invalidate()
                    st.success("Enfant enregistré.")
                    st.rerun()
                except Exception as error:
                    st.error(str(error))
