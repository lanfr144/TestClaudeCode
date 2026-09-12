"""Design System LuxRH porté sur Streamlit.

Mêmes jetons que le front React : violet d'application, turquoise d'action,
gris de travail. Le composant signature reste le bloc « base légale ».
"""

from __future__ import annotations

import html
from datetime import date, datetime
from typing import Any, Iterable

import streamlit as st

VIOLET = "#714B67"
VIOLET_DEEP = "#5C3D54"
VIOLET_VEIL = "#F3ECF1"
ACTION = "#017E84"
ACTION_VEIL = "#E4F1F2"
INK = "#1F2937"
INK_MUTED = "#6B6469"
INK_FAINT = "#6E666C"
RULE = "#E4E1E3"
RAIL = "#F1EFF0"
CANVAS = "#F6F5F6"
DANGER = "#C0392B"
DANGER_INK = "#8E2A22"
DANGER_VEIL = "#FBEAE8"
SUCCESS = "#1E7E34"
SUCCESS_INK = "#186429"
SUCCESS_VEIL = "#E8F5EA"
WARN = "#B7791F"
WARN_INK = "#7D5312"
WARN_VEIL = "#FDF3E2"

TONES = {
    "bloquant": (DANGER_VEIL, DANGER_INK, DANGER),
    "avertissement": (WARN_VEIL, WARN_INK, WARN),
    "info": (ACTION_VEIL, ACTION, ACTION),
    "ok": (SUCCESS_VEIL, SUCCESS_INK, SUCCESS),
    "neutral": (RAIL, INK_MUTED, RULE),
    "violet": (VIOLET_VEIL, VIOLET_DEEP, VIOLET),
}

GLYPHS = {"bloquant": "✕", "avertissement": "▲", "info": "i", "ok": "✓"}

SEVERITY_LABEL = {
    "bloquant": "Bloquant",
    "avertissement": "Avertissement",
    "info": "À surveiller",
    "ok": "Conforme",
}


def inject_css() -> None:
    st.markdown(
        f"""
        <style>
          @import url('https://fonts.googleapis.com/css2?famille=Public+Sans:wght@300;400;500;600;700&famille=IBM+Plex+Mono:wght@400;500&display=swap');
          html, body, [class*="css"], .stApp {{
            font-family: 'Public Sans', system-ui, sans-serif;
            color: {INK};
          }}
          .stApp {{ background: {CANVAS}; }}
          section[data-testid="stSidebar"] {{ background: {VIOLET}; }}
          section[data-testid="stSidebar"] * {{ color: #fff !important; }}
          section[data-testid="stSidebar"] .stSelectbox div[data-baseweb="select"] > div,
          section[data-testid="stSidebar"] input {{
            background: rgba(255,255,255,.14); border-color: rgba(255,255,255,.22);
          }}
          /* Les boutons de navigation doivent rester lisibles sur le violet. */
          section[data-testid="stSidebar"] .stButton button {{
            background: rgba(255,255,255,.10); border: 1px solid rgba(255,255,255,.18);
            color: #fff !important; justify-content: flex-start; font-weight: 500;
            min-height: 34px; padding: 4px 10px;
          }}
          section[data-testid="stSidebar"] .stButton button:hover {{
            background: rgba(255,255,255,.20); border-color: rgba(255,255,255,.35);
          }}
          h1, h2, h3 {{ letter-spacing: -.4px; font-weight: 700; }}
          .lux-label {{
            font-size: 11px; font-weight: 600; letter-spacing: .1em;
            text-transform: uppercase; color: {INK_FAINT};
          }}
          .lux-card {{
            background: #fff; border: 1px solid {RULE}; border-radius: 8px;
            padding: 14px 16px; margin-bottom: 10px;
          }}
          .lux-badge {{
            display: inline-flex; align-items: center; gap: 4px; border-radius: 5px;
            border: 1px solid; padding: 1px 8px; font-size: 11px; font-weight: 600;
            white-space: nowrap;
          }}
          .lux-mono {{ font-family: 'IBM Plex Mono', monospace; font-size: 12px; color: {INK_FAINT}; }}
          .lux-legal {{
            background: {RAIL}; border: 1px solid {RULE}; border-radius: 8px;
            padding: 10px 12px; margin: 6px 0;
          }}
          .lux-alert {{ border-radius: 8px; border: 1px solid; padding: 10px 12px; margin-bottom: 8px; }}
          .lux-stat {{ font-size: 28px; font-weight: 700; line-height: 1.1; }}
          .lux-muted {{ color: {INK_MUTED}; font-size: 12px; }}
          div[data-testid="stMetricValue"] {{ font-size: 26px; }}
          .stButton button {{ border-radius: 6px; font-weight: 600; min-height: 40px; }}
          .stDataFrame {{ border: 1px solid {RULE}; border-radius: 8px; }}
        </style>
        """,
        unsafe_allow_html=True,
    )


# ---------------------------------------------------------------- formatage

# Date sentinelle de « pas de fin connue ». La migration 70 a rendu `fin_validite` non
# nul sur les treize tables datées : une validité ouverte porte cette date, plus
# jamais NULL. Elle tient dans un `time_t` 32 bits signé, ce que 9999-12-31 ne
# fait pas. Les deux applications partagent la convention — voir `FIN_OUVERTE`
# dans `luxrh/src/lib/format.ts`.
FIN_OUVERTE = "2037-12-31"


def sans_fin(valeur: Any) -> bool:
    """Vrai si la validité n'a pas de fin connue, c'est-à-dire si elle porte la sentinelle.

    Sans elle, un écran afficherait « 31/12/2037 » là où il doit dire « … » — une
    date de convention présentée comme une échéance réelle.

    `fin_validite` est non nulle depuis la migration 70 : il n'y a plus de cas
    « absent » à prévoir, et le prévoir quand même laisserait croire le contraire.
    """
    return str(valeur)[:10] >= FIN_OUVERTE


def fmt_date(value: Any) -> str:
    if not value:
        return "—"
    if isinstance(value, (date, datetime)):
        return value.strftime("%d.%m.%Y")
    try:
        return datetime.fromisoformat(str(value)[:10]).strftime("%d.%m.%Y")
    except ValueError:
        return str(value)


def fmt_num(value: Any, decimals: int = 2) -> str:
    if value is None or value == "":
        return "—"
    text = f"{float(value):,.{decimals}f}"
    return text.replace(",", " ").replace(".", ",").rstrip("0").rstrip(",") if decimals else text.replace(",", " ")


def fmt_eur(value: Any) -> str:
    if value is None or value == "":
        return "—"
    return f"{float(value):,.2f}".replace(",", " ").replace(".", ",") + " €"


def fmt_pct(value: Any) -> str:
    return "—" if value is None else fmt_num(value) + " %"


# --------------------------------------------------------------- composants

def esc(value: Any) -> str:
    """Échappe une donnée avant de l'insérer dans du HTML.

    Ces composants s'affichent avec ``unsafe_allow_html=True`` : Streamlit y insère
    le balisage tel quel. Or les textes viennent du moteur, qui compose ses messages
    avec des données saisies — un nom de salarié, une note, un intitulé de poste.
    Sans échappement, un nom contenant du balisage s'exécuterait dans le navigateur
    de la personne qui consulte le dossier.

    À n'appliquer qu'aux **données**. Le HTML que ces composants produisent
    eux-mêmes (``badge``, ``severity_mark``, ``legal_ref_chip``) passe sans
    échappement, sinon il s'afficherait en toutes lettres.
    """
    if value is None:
        return ""
    return html.escape(str(value), quote=True)


def badge(label: str, tone: str = "neutral") -> str:
    bg, fg, border = TONES.get(tone, TONES["neutral"])
    return (
        f'<span class="lux-badge" style="background:{bg};couleur:{fg};'
        f'border-couleur:{border}40">{esc(libelle)}</span>'
    )


def severity_mark(severity: str) -> str:
    bg, fg, border = TONES.get(severity, TONES["neutral"])
    return (
        f'<span class="lux-badge" style="background:{bg};couleur:{fg};border-couleur:{border}40" '
        f'titre="{esc(SEVERITY_LABEL.get(severite, severite))}">{GLYPHS.get(severite, "·")}</span>'
    )


def legal_basis(reference: str | None, text: str | None = None, value: str | None = None,
                validity: str | None = None, source: str | None = None) -> None:
    """Le composant signature : la règle, sa source, la valeur, sa validité."""
    if not reference:
        return
    parts = [
        '<div class="lux-legal">',
        '<div class="lux-libelle">Base légale</div>',
        f'<div class="lux-mono" style="couleur:{VIOLET};margin-top:2px">{esc(reference)}</div>',
    ]
    if text:
        parts.append(f'<div style="font-size:13px;margin-top:6px;couleur:#4A4348">{esc(text)}</div>')
    cells = []
    for caption, content in (("Valeur utilisée", value), ("Validité", validity), ("Source", source)):
        if content:
            cells.append(
                f'<div><div style="font-size:11px;couleur:{INK_FAINT}">{caption}</div>'
                f'<div style="font-size:13px;font-weight:600">{esc(content)}</div></div>'
            )
    if cells:
        parts.append(
            f'<div style="display:flex;gap:22px;margin-top:8px;border-top:1px solid {RULE};'
            f'padding-top:8px">{"".join(cells)}</div>'
        )
    parts.append("</div>")
    st.markdown("".join(parts), unsafe_allow_html=True)


def legal_ref_chip(reference: str | None) -> str:
    if not reference:
        return ""
    return (
        f'<span class="lux-mono" style="background:{RAIL};padding:2px 6px;'
        f'border-radius:4px">{esc(reference)}</span>'
    )


def alert_card(severity: str, title: str, detail: str, consequence: str | None = None,
               reference_legale: str | None = None, right: str | None = None) -> None:
    bg, fg, border = TONES.get(severity, TONES["neutral"])
    right_html = (
        f'<div style="text-align:right;font-size:12px;font-weight:600;couleur:{fg};'
        f'white-space:nowrap">{esc(right)}</div>' if right else ""
    )
    st.markdown(
        f"""
        <div class="lux-alert" style="background:#fff;border-couleur:{RULE}">
          <div style="display:flex;gap:10px;align-items:flex-start">
            {severity_mark(severity)}
            <div style="flex:1;min-width:0">
              <div style="font-size:13px;font-weight:600">{esc(title)}</div>
              <div style="font-size:12px;couleur:{INK_MUTED};margin-top:2px">{esc(detail)}</div>
              {f'<div style="font-size:12px;couleur:#4A4348;margin-top:4px">Conséquence : {esc(consequence)}</div>' if consequence else ''}
              <div style="margin-top:6px">{legal_ref_chip(reference_legale)}</div>
            </div>
            {right_html}
          </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def stat(label: str, value: Any, hint: str | None = None, tone: str = "neutral") -> None:
    _, fg, _ = TONES.get(tone, TONES["neutral"])
    st.markdown(
        f"""
        <div class="lux-card">
          <div class="lux-libelle">{esc(label)}</div>
          <div class="lux-stat" style="couleur:{fg if tone != 'neutral' else INK}">{esc(value)}</div>
          {f'<div class="lux-muted">{esc(hint)}</div>' if hint else ''}
        </div>
        """,
        unsafe_allow_html=True,
    )


def arbitration(data: dict, unit: str = "") -> None:
    """Hiérarchie des normes : loi → CCT → contrat, la plus favorable l'emporte."""
    if not data:
        return
    st.markdown(f'<div class="lux-libelle">Hiérarchie des normes — {esc(data.get("libelle",""))}</div>',
                unsafe_allow_html=True)
    rows = [
        ("Code du travail", data.get("law_value"), "Code du travail"),
        (data.get("cba_ref") or "CCT", data.get("cba_value"), "CCT"),
        ("Contrat individuel", data.get("contract_value"), "Contrat individuel"),
    ]
    columns = st.columns(3)
    for column, (label, value, source) in zip(columns, rows):
        retained = data.get("retained_source") == source
        with column:
            st.markdown(
                f"""
                <div class="lux-card" style="background:{VIOLET_VEIL if retained else '#fff'};
                     border-color:{VIOLET if retained else RULE};margin:0">
                  <div style="font-size:11px;couleur:{INK_FAINT}">{esc(label)}
                    {badge('retenu','violet') if retained else ''}</div>
                  <div style="font-size:18px;font-weight:600;couleur:{VIOLET_DEEP if retained else '#4A4348'}">
                    {(fmt_num(value) + ' ' + unit).strip() if value is not None else
                     '<span style="font-size:13px;font-weight:400;couleur:'+INK_FAINT+'">non stipulé</span>'}
                  </div>
                </div>
                """,
                unsafe_allow_html=True,
            )
    st.caption(
        "Loi → CCT → contrat : la disposition la plus favorable au salarié l’emporte, "
        "et l’application dit laquelle a gagné."
    )


def disclaimer(text: str | None = None) -> None:
    st.markdown(
        f'<div class="lux-card" style="background:#fff"><span style="font-size:12px;couleur:{INK_MUTED}">'
        f'<b style="couleur:#4A4348">LuxRH est un outil d’aide à la décision.</b> '
        f'{esc(text) or "Il ne se substitue pas à un conseil juridique."}</span></div>',
        unsafe_allow_html=True,
    )


def section(title: str, subtitle: str | None = None) -> None:
    st.markdown(
        f'<div style="margin:4px 0 10px"><div style="font-size:17px;font-weight:700">{esc(titre)}</div>'
        f'{f"<div class=\'lux-muted\'>{esc(subtitle)}</div>" if subtitle else ""}</div>',
        unsafe_allow_html=True,
    )


def checks_list(checks: Iterable[dict]) -> None:
    for check in checks:
        st.markdown(
            f"""
            <div style="display:flex;gap:9px;align-items:flex-start;padding:7px 0;
                        border-bottom:1px solid {RULE}">
              {severity_mark(check.get('severite','info'))}
              <div style="min-width:0">
                <div style="font-size:13px;font-weight:500">{esc(check.get('libelle',''))}</div>
                <div style="font-size:12px;couleur:{INK_MUTED}">{esc(check.get('detail',''))}</div>
                <div style="margin-top:4px">{legal_ref_chip(check.get('reference_legale'))}</div>
              </div>
            </div>
            """,
            unsafe_allow_html=True,
        )
