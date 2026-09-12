"""Portabilité des données — RGPD et réversibilité.

Rien n'est assemblé ici : le serveur produit le document, contrôle qui a le
droit de le demander et journalise la demande. Cette page déclenche et propose
le téléchargement.
"""

from __future__ import annotations

import json
from datetime import date
from typing import Any

import streamlit as st

from . import client as db
from . import design as ds

NOM = {
    "employee": "mes-donnees",
    "company": "societe",
    "organization": "fiduciaire",
    "referential": "referentiel",
}


def _sections(document: dict[str, Any]) -> list[tuple[str, int]]:
    payload = document.get("payload") or {}
    parts = [(k, len(v)) for k, v in payload.items() if isinstance(v, list) and v]
    return sorted(parts, key=lambda p: -p[1])


def _offer(document: dict[str, Any], suffix: str = "") -> None:
    """Affiche le contenu du document, puis propose de l'enregistrer."""
    kind = document.get("genre", "export")
    stamp = (document.get("exported_at") or str(date.today()))[:10]
    name = "-".join(x for x in ("luxrh", NOM.get(kind, kind), suffix, stamp) if x) + ".json"
    corps = json.dumps(document, indent=2, ensure_ascii=False, default=str)

    st.success(f"Document prêt — {len(corps) / 1024:.0f} Ko.")
    parts = _sections(document)
    if parts:
        st.caption(" · ".join(f"{nom} {nb}" for nom, nb in parts))
    st.download_button("Enregistrer le fichier", corps, file_name=name,
                       mime="application/json", type="primary")


def portability() -> None:
    profile = db.profile() or {}
    admin = bool(profile.get("est_admin_organisation"))
    company = db.active_company()

    ds.section("Portabilité et reprise",
               "Sortir les données dans un format relisible, et repeupler une nouvelle implantation.")

    # ------------------------------------------------------------ droit d'accès
    st.markdown("**Droit d’accès — art. 15 et 20 du RGPD**")
    st.caption(
        "Le dossier complet de la personne : contrats, temps, absences, primes, documents. "
        "Matricule national et IBAN y figurent en clair — un export illisible ne satisferait "
        "pas le droit d’accès."
    )
    if st.button("Exporter mes données personnelles"):
        try:
            _offer(db.engine("fn_export_self"))
        except Exception as error:
            st.error(str(error))

    # ---------------------------------------------------------- réversibilité
    if company or admin:
        st.divider()
        st.markdown("**Réversibilité**")
        st.caption(
            "Ce que la société ou la fiduciaire emporte si elle quitte l’outil. Les pièces "
            "jointes restent dans le stockage : l’export en porte le descriptif et le chemin, "
            "pas le contenu binaire."
        )
        colonnes = st.columns(2)
        if company:
            with colonnes[0]:
                if st.button(f"Exporter {company['raison_sociale']}", use_container_width=True):
                    try:
                        _offer(db.engine("fn_export_company", p_company=company["id"]),
                               company["raison_sociale"][:24])
                    except Exception as error:
                        st.error(str(error))
        if admin:
            with colonnes[1]:
                if st.button("Exporter toute la fiduciaire", use_container_width=True):
                    try:
                        _offer(db.engine("fn_export_organization"))
                    except Exception as error:
                        st.error(str(error))

    # ------------------------------------------------------------- référentiel
    st.divider()
    st.markdown("**Référentiel — transmission du savoir**")
    st.caption(
        "Paramètres légaux datés, barèmes, catalogues et CCT. L’export se lit en clés "
        "naturelles (cle_parametre, codes, dates) et non en identifiants techniques : il peut "
        "donc repeupler une base neuve sans y dupliquer ce qui s’y trouve déjà."
    )
    if st.button("Exporter le référentiel"):
        try:
            _offer(db.engine("fn_export_referential"))
        except Exception as error:
            st.error(str(error))

    if not admin:
        return

    st.markdown("**Charger un référentiel**")
    mode = st.radio(
        "En cas de clé déjà présente",
        ["skip_existing", "replace"],
        horizontal=True,
        format_func=lambda m: "Conserver l’existant" if m == "skip_existing" else "Écraser à clé égale",
    )
    fichier = st.file_uploader("Fichier d’export LuxRH", type="json", key="import_ref")

    if fichier is not None and st.button("Charger", type="primary"):
        try:
            document = json.loads(fichier.getvalue().decode("utf-8"))
        except Exception:
            st.error(f"« {fichier.nom} » n’est pas un fichier JSON lisible.")
            return
        if document.get("format") != "luxrh.export/1":
            st.error(f"« {fichier.nom} » ne porte pas le format luxrh.export/1 : "
                     "ce n’est pas un export LuxRH.")
            return
        if document.get("genre") != "referential":
            st.error(f"Ce fichier est un export « {document.get('genre')} », pas un référentiel.")
            return

        try:
            rapport = db.engine("fn_import_referential", p_document=document, p_mode=mode)
            db.invalidate()
            st.success(rapport["message"])
            for rejet in rapport.get("rejected") or []:
                st.warning(rejet)
        except Exception as error:
            st.error(str(error))

    st.caption(
        "Un import n’efface jamais rien : il ajoute, ou remplace à clé égale. Les CCT chargées "
        "sont rattachées à votre organisation, jamais publiées à toutes."
    )
