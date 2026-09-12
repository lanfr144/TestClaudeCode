#!/usr/bin/env python
"""Rendu PDF d'un document Markdown selon la norme d'en-tête et de pied de page
« pdf-writer » (voir SKILL.md et reference-gemini.md).

La norme est décrite en CSS Paged Media (boîtes de marge `@top-left`, `@top-center`, …).
Faute de moteur WeasyPrint installable ici (il réclame les bibliothèques système GTK),
le rendu est produit par reportlab en reproduisant la même géométrie au point près :
marges 60/48/54/48 pt, logos de 24,5 pt et 36,8 pt de haut, mentions grises de 8 pt.

L'option --html écrit en parallèle le document HTML avec le bloc `@page` déclaratif,
pour que la chaîne WeasyPrint reste reproductible sur une machine équipée.

Usage :
    python render_pdf.py docs/index.md [docs/autre.md ...] --out-dir docs/pdf
    python render_pdf.py docs/*.md --combine --out docs/pdf/LuxRH-documentation.pdf
"""

from __future__ import annotations

import argparse
import html as html_mod
import os
import re
import sys

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as canvas_module
from reportlab.platypus import (
    BaseDocTemplate,
    CondPageBreak,
    Frame,
    HRFlowable,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Preformatted,
    Spacer,
    Table,
    TableStyle,
)

SKILL_DIR = os.path.dirname(os.path.abspath(__file__))

# --- Géométrie de la norme (points typographiques) --------------------------

PAGE_W, PAGE_H = A4
MARGIN_TOP, MARGIN_RIGHT, MARGIN_BOTTOM, MARGIN_LEFT = 60, 48, 54, 48
LOGO_LEFT_H = 24.5          # am.png
LOGO_RIGHT_H = 36.8         # Bts.png
MARGIN_TEXT_SIZE = 8
MARGIN_TEXT_COLOR = colors.HexColor("#808080")

FOOTER_LEFT_DEFAULT = "lanfr144"
FOOTER_RIGHT_DEFAULT = "DOPRO1"

# --- Polices ----------------------------------------------------------------

FONT_BODY, FONT_BOLD, FONT_MONO = "Roboto", "Roboto-Bold", "RobotoMono"


def register_fonts() -> None:
    fonts = os.path.join(SKILL_DIR, "fonts")
    pdfmetrics.registerFont(TTFont(FONT_BODY, os.path.join(fonts, "Roboto-Regular.ttf")))
    pdfmetrics.registerFont(TTFont(FONT_BOLD, os.path.join(fonts, "Roboto-Bold.ttf")))
    pdfmetrics.registerFont(TTFont(FONT_MONO, os.path.join(fonts, "RobotoMono-Regular.ttf")))
    pdfmetrics.registerFontFamily(FONT_BODY, normal=FONT_BODY, bold=FONT_BOLD,
                                  italic=FONT_BODY, boldItalic=FONT_BOLD)


# --- Styles -----------------------------------------------------------------

INK = colors.HexColor("#1a1a1a")
MUTED = colors.HexColor("#5b6570")
ACCENT = colors.HexColor("#1f4e79")
RULE = colors.HexColor("#d5dae0")
CODE_BG = colors.HexColor("#f4f6f8")


def build_styles() -> dict:
    body = ParagraphStyle("body", fontName=FONT_BODY, fontSize=9.5, leading=14,
                          textColor=INK, spaceAfter=6)
    return {
        "body": body,
        "h1": ParagraphStyle("h1", parent=body, fontName=FONT_BOLD, fontSize=19, leading=24,
                             textColor=ACCENT, spaceBefore=4, spaceAfter=10),
        "h2": ParagraphStyle("h2", parent=body, fontName=FONT_BOLD, fontSize=13.5, leading=18,
                             textColor=ACCENT, spaceBefore=14, spaceAfter=6),
        "h3": ParagraphStyle("h3", parent=body, fontName=FONT_BOLD, fontSize=11, leading=15,
                             textColor=INK, spaceBefore=11, spaceAfter=4),
        "h4": ParagraphStyle("h4", parent=body, fontName=FONT_BOLD, fontSize=9.8, leading=13,
                             textColor=MUTED, spaceBefore=9, spaceAfter=3),
        "quote": ParagraphStyle("quote", parent=body, leftIndent=12, textColor=MUTED,
                                borderPadding=(0, 0, 0, 0)),
        "li": ParagraphStyle("li", parent=body, spaceAfter=2),
        "code": ParagraphStyle("code", fontName=FONT_MONO, fontSize=7.8, leading=10.6,
                               textColor=INK),
        "th": ParagraphStyle("th", fontName=FONT_BOLD, fontSize=8.4, leading=11.5,
                             textColor=colors.white),
        "td": ParagraphStyle("td", fontName=FONT_BODY, fontSize=8.4, leading=11.5,
                             textColor=INK),
        "caption": ParagraphStyle("caption", parent=body, fontSize=7.6, textColor=MUTED,
                                  spaceBefore=2, spaceAfter=8),
    }


# --- Markdown : formatage en ligne ------------------------------------------

_LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
_CODE = re.compile(r"`([^`]+)`")
_BOLD = re.compile(r"\*\*(.+?)\*\*", re.S)
_ITALIC = re.compile(r"(?<![\*\w])\*(?!\s)([^*]+?)(?<!\s)\*(?!\*)")
_STRIKE = re.compile(r"~~(.+?)~~", re.S)


def inline(text: str) -> str:
    """Convertit le Markdown en ligne vers le mini-balisage de reportlab."""
    out = html_mod.escape(text, quote=False)
    placeholders: list[str] = []

    def stash(markup: str) -> str:
        placeholders.append(markup)
        return f"\x00{len(placeholders) - 1}\x00"

    out = _CODE.sub(lambda m: stash(
        f'<font face="{FONT_MONO}" size="8.4" backColor="#f0f2f4">{m.group(1)}</font>'), out)
    def lien(m: "re.Match[str]") -> str:
        cible, texte = m.group(2), m.group(1)
        # Une ancre interne (#section) n'a pas d'équivalent en PDF : reportlab
        # cherche une destination nommée et échoue si elle n'existe pas. On garde
        # le texte, souligné comme un lien, sans destination.
        if cible.startswith("#"):
            return stash(f'<font color="#1f4e79"><u>{texte}</u></font>')
        return stash(f'<a href="{html_mod.escape(cible, quote=True)}" color="#1f4e79">'
                     f'<u>{texte}</u></a>')

    out = _LINK.sub(lien, out)
    out = _BOLD.sub(r"<b>\1</b>", out)
    out = _ITALIC.sub(r"<i>\1</i>", out)
    out = _STRIKE.sub(r"<strike>\1</strike>", out)

    for i, markup in enumerate(placeholders):
        out = out.replace(f"\x00{i}\x00", markup)
    return out


# --- Markdown : découpage en blocs ------------------------------------------

_FENCE = re.compile(r"^\s*(```|~~~)\s*([\w+-]*)\s*$")
_HEADING = re.compile(r"^(#{1,6})\s+(.*)$")
_HR = re.compile(r"^\s*([-*_])(\s*\1){2,}\s*$")
_ULI = re.compile(r"^(\s*)[-*+]\s+(.*)$")
_OLI = re.compile(r"^(\s*)(\d+)[.)]\s+(.*)$")
_QUOTE = re.compile(r"^\s*>\s?(.*)$")
_TABLE_SEP = re.compile(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)+\|?\s*$")


def split_row(line: str) -> list[str]:
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in re.split(r"(?<!\\)\|", line)]


def parse_blocks(lines: list[str]) -> list[tuple]:
    """Retourne une liste de blocs ('type', charge utile)."""
    blocks: list[tuple] = []
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]

        fence = _FENCE.match(line)
        if fence:
            marker, lang = fence.group(1), fence.group(2)
            i += 1
            buf: list[str] = []
            while i < n and not re.match(rf"^\s*{re.escape(marker)}\s*$", lines[i]):
                buf.append(lines[i])
                i += 1
            i += 1
            blocks.append(("code", lang.lower(), buf))
            continue

        if not line.strip():
            i += 1
            continue

        if _HR.match(line):
            blocks.append(("hr",))
            i += 1
            continue

        heading = _HEADING.match(line)
        if heading:
            blocks.append(("h", len(heading.group(1)), heading.group(2).strip()))
            i += 1
            continue

        # Tableau : ligne de cellules suivie d'une ligne de séparation
        if "|" in line and i + 1 < n and _TABLE_SEP.match(lines[i + 1]):
            header = split_row(line)
            i += 2
            rows: list[list[str]] = []
            while i < n and lines[i].strip() and "|" in lines[i]:
                rows.append(split_row(lines[i]))
                i += 1
            blocks.append(("table", header, rows))
            continue

        if _QUOTE.match(line):
            buf = []
            while i < n and _QUOTE.match(lines[i]):
                buf.append(_QUOTE.match(lines[i]).group(1))
                i += 1
            blocks.append(("quote", " ".join(b.strip() for b in buf).strip()))
            continue

        if _ULI.match(line) or _OLI.match(line):
            ordered = bool(_OLI.match(line))
            items: list[str] = []
            while i < n:
                match = _OLI.match(lines[i]) if ordered else _ULI.match(lines[i])
                if not match:
                    # continuation indentée de l'item courant
                    if items and lines[i].strip() and lines[i][:1] in " \t" \
                            and not _ULI.match(lines[i]) and not _OLI.match(lines[i]):
                        items[-1] += " " + lines[i].strip()
                        i += 1
                        continue
                    break
                items.append(match.group(3) if ordered else match.group(2))
                i += 1
            blocks.append(("list", ordered, items))
            continue

        buf = []
        while i < n and lines[i].strip() and not _HEADING.match(lines[i]) \
                and not _FENCE.match(lines[i]) and not _HR.match(lines[i]) \
                and not _ULI.match(lines[i]) and not _OLI.match(lines[i]) \
                and not _QUOTE.match(lines[i]):
            buf.append(lines[i].strip())
            i += 1
        if buf:
            blocks.append(("p", " ".join(buf)))
    return blocks


# --- Blocs -> flowables reportlab -------------------------------------------

def code_flowable(lang: str, lines: list[str], styles: dict, width: float) -> list:
    label = {"mermaid": "Schéma Mermaid (source)"}.get(lang)
    text = "\n".join(lines) or " "
    # repli léger : on tronque les lignes trop longues pour ne pas déborder
    max_chars = int((width - 16) / (styles["code"].fontSize * 0.6))
    wrapped: list[str] = []
    for raw in text.split("\n"):
        while len(raw) > max_chars:
            cut = raw.rfind(" ", 0, max_chars)
            cut = cut if cut > max_chars * 0.5 else max_chars
            wrapped.append(raw[:cut])
            raw = "    " + raw[cut:].lstrip()
        wrapped.append(raw)
    block = Table([[Preformatted("\n".join(wrapped), styles["code"])]], colWidths=[width])
    block.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CODE_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    out = [Spacer(1, 3), block]
    out.append(Paragraph(label, styles["caption"]) if label else Spacer(1, 7))
    return out


def table_flowable(header: list[str], rows: list[list[str]], styles: dict, width: float) -> list:
    cols = max(len(header), max((len(r) for r in rows), default=0))
    header = header + [""] * (cols - len(header))
    data = [[Paragraph(inline(c), styles["th"]) for c in header]]
    for row in rows:
        row = row + [""] * (cols - len(row))
        data.append([Paragraph(inline(c), styles["td"]) for c in row[:cols]])

    # largeurs proportionnelles au contenu, bornées ; l'en-tête est en gras et
    # réclame un peu plus de place que sa longueur brute ne le suggère
    weights = []
    for col in range(cols):
        longest = max((len(str(r[col])) if col < len(r) else 0) for r in rows) if rows else 0
        weights.append(min(max(longest, len(header[col]) + 3, 6), 60))
    total = sum(weights)
    widths = [width * w / total for w in weights]

    # Plancher : une colonne ne doit jamais couper le mot le plus long de son
    # en-tête. On relève les colonnes trop étroites et on reprend la différence
    # sur les autres, au prorata de leur largeur.
    floors = [
        min(width / cols * 1.8,
            max((pdfmetrics.stringWidth(w, FONT_BOLD, styles["th"].fontSize)
                 for w in re.sub(r"[`*]", "", head).split() or [""]), default=0) + 12)
        for head in header
    ]
    deficit = sum(max(0.0, f - w) for f, w in zip(floors, widths))
    if deficit > 0:
        slack = sum(max(0.0, w - f) for f, w in zip(floors, widths))
        if slack > deficit:
            widths = [f if w < f else w - (w - f) * deficit / slack
                      for f, w in zip(floors, widths)]

    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), ACCENT),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.4, RULE),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for r in range(1, len(data)):
        if r % 2 == 0:
            style.append(("BACKGROUND", (0, r), (-1, r), colors.HexColor("#f7f9fa")))
    table.setStyle(TableStyle(style))
    return [Spacer(1, 3), table, Spacer(1, 9)]


def to_flowables(blocks: list[tuple], styles: dict, width: float, skip_first_h1: bool) -> list:
    flow: list = []
    seen_h1 = False
    for block in blocks:
        kind = block[0]
        if kind == "h":
            level, text = block[1], block[2]
            if level == 1:
                if skip_first_h1 and not seen_h1:
                    seen_h1 = True
                    continue
                seen_h1 = True
                flow.append(CondPageBreak(120))
            style = styles.get(f"h{min(level, 4)}", styles["h4"])
            flow.append(Paragraph(inline(text), style))
            if level <= 2:
                flow.append(HRFlowable(width="100%", thickness=0.6, color=RULE,
                                       spaceBefore=1, spaceAfter=7))
        elif kind == "p":
            flow.append(Paragraph(inline(block[1]), styles["body"]))
        elif kind == "quote":
            para = Table([[Paragraph(inline(block[1]), styles["quote"])]], colWidths=[width])
            para.setStyle(TableStyle([
                ("LINEBEFORE", (0, 0), (0, -1), 2, ACCENT),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]))
            flow += [Spacer(1, 2), para, Spacer(1, 7)]
        elif kind == "list":
            ordered, items = block[1], block[2]
            flow.append(ListFlowable(
                [ListItem(Paragraph(inline(t), styles["li"]), leftIndent=14) for t in items],
                bulletType="1" if ordered else "bullet",
                bulletFontName=FONT_BODY, bulletFontSize=9.5 if ordered else 6,
                bulletOffsetY=0 if ordered else -1,
                start="1" if ordered else None, leftIndent=14, bulletDedent=10,
            ))
            flow.append(Spacer(1, 6))
        elif kind == "code":
            flow += code_flowable(block[1], block[2], styles, width)
        elif kind == "table":
            flow += table_flowable(block[1], block[2], styles, width)
        elif kind == "hr":
            flow.append(HRFlowable(width="100%", thickness=0.5, color=RULE,
                                   spaceBefore=6, spaceAfter=8))
    return flow


# --- Canevas : en-tête, pied de page, « Page X of Y » ------------------------

class MarginBoxCanvas(canvas_module.Canvas):
    """Reproduit les boîtes de marge CSS de la norme. Deux passes : la seconde
    connaît le nombre total de pages, ce que `counter(pages)` fait en CSS."""

    title_text = ""
    footer_left = FOOTER_LEFT_DEFAULT
    footer_right = FOOTER_RIGHT_DEFAULT

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._pages: list[dict] = []

    def showPage(self):
        self._pages.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        total = len(self._pages)
        for state in self._pages:
            self.__dict__.update(state)
            self._draw_margin_boxes(total)
            super().showPage()
        super().save()

    def _draw_margin_boxes(self, total: int) -> None:
        self.saveState()

        top_center_y = PAGE_H - MARGIN_TOP / 2
        assets = os.path.join(SKILL_DIR, "assets")

        for name, max_h, align in (("am.png", LOGO_LEFT_H, "left"),
                                   ("Bts.png", LOGO_RIGHT_H, "right")):
            path = os.path.join(assets, name)
            if not os.path.exists(path):
                continue
            iw, ih = ImageReader(path).getSize()
            h = max_h
            w = iw * h / ih
            x = MARGIN_LEFT if align == "left" else PAGE_W - MARGIN_RIGHT - w
            self.drawImage(path, x, top_center_y - h / 2, width=w, height=h,
                           mask="auto", preserveAspectRatio=True)

        self.setFont(FONT_BODY, MARGIN_TEXT_SIZE)
        self.setFillColor(MARGIN_TEXT_COLOR)
        self.drawCentredString(PAGE_W / 2, top_center_y - MARGIN_TEXT_SIZE / 3,
                               self.title_text)

        footer_y = MARGIN_BOTTOM / 2
        self.setStrokeColor(RULE)
        self.setLineWidth(0.4)
        self.line(MARGIN_LEFT, MARGIN_BOTTOM - 10, PAGE_W - MARGIN_RIGHT, MARGIN_BOTTOM - 10)
        self.drawString(MARGIN_LEFT, footer_y - MARGIN_TEXT_SIZE, self.footer_left)
        self.drawCentredString(PAGE_W / 2, footer_y - MARGIN_TEXT_SIZE,
                               f"Page {self._pageNumber} of {total}")
        self.drawRightString(PAGE_W - MARGIN_RIGHT, footer_y - MARGIN_TEXT_SIZE,
                             self.footer_right)
        self.restoreState()


# --- Assemblage --------------------------------------------------------------

def read_markdown(path: str) -> tuple[str, list[str]]:
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.read().replace("\r\n", "\n").split("\n")
    title = os.path.basename(path)
    for line in lines:
        match = _HEADING.match(line)
        if match and len(match.group(1)) == 1:
            title = match.group(2).strip()
            break
    return title, lines


def build_pdf(sources: list[str], out_path: str, title: str,
              footer_left: str, footer_right: str, cover: bool) -> None:
    register_fonts()
    styles = build_styles()
    frame_w = PAGE_W - MARGIN_LEFT - MARGIN_RIGHT
    frame_h = PAGE_H - MARGIN_TOP - MARGIN_BOTTOM

    story: list = []
    if cover:
        story += [
            Spacer(1, frame_h * 0.26),
            Paragraph(inline(title), ParagraphStyle(
                "cover", parent=styles["h1"], fontSize=27, leading=33, spaceAfter=4)),
            HRFlowable(width="42%", thickness=1.6, color=ACCENT, hAlign="LEFT",
                       spaceBefore=6, spaceAfter=12),
            Paragraph("Documentation du projet LuxRH — assistant RH &amp; paie pour le droit "
                      "du travail luxembourgeois.", ParagraphStyle(
                          "sub", parent=styles["body"], fontSize=11, leading=16,
                          textColor=MUTED)),
            Spacer(1, 16),
            Paragraph("Sommaire des documents assemblés :", styles["h4"]),
            ListFlowable(
                [ListItem(Paragraph(inline(read_markdown(s)[0]), styles["li"]), leftIndent=14)
                 for s in sources],
                bulletType="bullet", bulletFontName=FONT_BODY, bulletFontSize=8,
                leftIndent=14, bulletDedent=10),
            PageBreak(),
        ]

    for index, source in enumerate(sources):
        doc_title, lines = read_markdown(source)
        if index and not cover:
            story.append(PageBreak())
        elif index:
            story.append(PageBreak())
        story.append(Paragraph(inline(doc_title), styles["h1"]))
        story.append(HRFlowable(width="100%", thickness=0.8, color=ACCENT,
                                spaceBefore=1, spaceAfter=9))
        story += to_flowables(parse_blocks(lines), styles, frame_w, skip_first_h1=True)

    doc = BaseDocTemplate(
        out_path, pagesize=A4,
        leftMargin=MARGIN_LEFT, rightMargin=MARGIN_RIGHT,
        topMargin=MARGIN_TOP, bottomMargin=MARGIN_BOTTOM,
        title=title, author=footer_left, subject="Documentation LuxRH",
    )
    doc.addPageTemplates([PageTemplate(
        id="norme",
        frames=[Frame(MARGIN_LEFT, MARGIN_BOTTOM, frame_w, frame_h,
                      leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)],
    )])

    MarginBoxCanvas.title_text = title
    MarginBoxCanvas.footer_left = footer_left
    MarginBoxCanvas.footer_right = footer_right
    doc.build(story, canvasmaker=MarginBoxCanvas)


# --- Sortie HTML déclarative (chaîne WeasyPrint) ------------------------------

CSS_TEMPLATE = """@page {{
    size: A4;
    margin: {top}pt {right}pt {bottom}pt {left}pt;
    @top-left    {{ content: url("assets/am.png");  image-resolution: 300dpi; vertical-align: middle; }}
    @top-center  {{ content: "{title}"; font-family: 'Roboto', Helvetica, sans-serif; font-size: 8pt; color: #808080; vertical-align: middle; text-align: center; }}
    @top-right   {{ content: url("assets/Bts.png"); image-resolution: 300dpi; vertical-align: middle; }}
    @bottom-left   {{ content: "{fleft}";  font-family: 'Roboto', Helvetica, sans-serif; font-size: 8pt; color: #808080; }}
    @bottom-center {{ content: "Page " counter(page) " of " counter(pages); font-family: 'Roboto', Helvetica, sans-serif; font-size: 8pt; color: #808080; }}
    @bottom-right  {{ content: "{fright}"; font-family: 'Roboto', Helvetica, sans-serif; font-size: 8pt; color: #808080; }}
}}
img[src$="am.png"]  {{ max-height: {logol}pt; }}
img[src$="Bts.png"] {{ max-height: {logor}pt; }}
body {{ font-family: 'Roboto', Helvetica, sans-serif; font-size: 9.5pt; line-height: 1.45; color: #1a1a1a; }}
h1, h2 {{ color: #1f4e79; border-bottom: 0.6pt solid #d5dae0; padding-bottom: 3pt; }}
h1 {{ page-break-before: always; }} h1:first-of-type {{ page-break-before: avoid; }}
table {{ border-collapse: collapse; width: 100%; font-size: 8.4pt; }}
th {{ background: #1f4e79; color: #fff; text-align: left; }}
th, td {{ border: 0.4pt solid #d5dae0; padding: 4pt 5pt; vertical-align: top; }}
tr:nth-child(even) td {{ background: #f7f9fa; }}
pre {{ background: #f4f6f8; border: 0.5pt solid #d5dae0; padding: 6pt 8pt;
      font-family: 'RobotoMono', monospace; font-size: 7.8pt; white-space: pre-wrap; }}
code {{ font-family: 'RobotoMono', monospace; background: #f0f2f4; }}
blockquote {{ border-left: 2pt solid #1f4e79; margin-left: 0; padding-left: 10pt; color: #5b6570; }}
a {{ color: #1f4e79; }}
"""


def build_html(sources: list[str], out_path: str, title: str,
               footer_left: str, footer_right: str) -> None:
    try:
        import markdown as md_lib
    except ImportError:
        print("  (HTML ignoré : module `markdown` absent)", file=sys.stderr)
        return
    parts = []
    for source in sources:
        with open(source, "r", encoding="utf-8") as handle:
            parts.append(md_lib.markdown(handle.read(),
                                         extensions=["tables", "fenced_code", "toc"]))
    css = CSS_TEMPLATE.format(top=MARGIN_TOP, right=MARGIN_RIGHT, bottom=MARGIN_BOTTOM,
                              left=MARGIN_LEFT, title=title, fleft=footer_left,
                              fright=footer_right, logol=LOGO_LEFT_H, logor=LOGO_RIGHT_H)
    with open(out_path, "w", encoding="utf-8") as handle:
        handle.write(f"<!doctype html>\n<html lang=\"fr\"><head><meta charset=\"utf-8\">\n"
                     f"<title>{html_mod.escape(title)}</title>\n<style>\n{css}</style>\n"
                     f"</head><body>\n" + "\n<hr>\n".join(parts) + "\n</body></html>\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("sources", nargs="+", help="fichiers Markdown à rendre")
    parser.add_argument("--out", help="chemin du PDF (avec --combine)")
    parser.add_argument("--out-dir", default=".", help="dossier de sortie (sans --combine)")
    parser.add_argument("--combine", action="store_true",
                        help="assembler toutes les sources en un seul PDF")
    parser.add_argument("--title", help="titre de l'en-tête (défaut : premier H1)")
    parser.add_argument("--footer-left", default=FOOTER_LEFT_DEFAULT)
    parser.add_argument("--footer-right", default=FOOTER_RIGHT_DEFAULT)
    parser.add_argument("--cover", action="store_true", help="ajouter une page de garde")
    parser.add_argument("--html", action="store_true",
                        help="écrire aussi le HTML avec le @page déclaratif")
    args = parser.parse_args()

    missing = [s for s in args.sources if not os.path.exists(s)]
    if missing:
        print("Fichiers introuvables : " + ", ".join(missing), file=sys.stderr)
        return 1

    if args.combine:
        out = args.out or os.path.join(args.out_dir, "documentation.pdf")
        os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
        title = args.title or "Documentation LuxRH"
        build_pdf(args.sources, out, title, args.footer_left, args.footer_right, args.cover)
        print(f"PDF  {out}")
        if args.html:
            build_html(args.sources, os.path.splitext(out)[0] + ".html", title,
                       args.footer_left, args.footer_right)
            print(f"HTML {os.path.splitext(out)[0] + '.html'}")
        return 0

    os.makedirs(args.out_dir, exist_ok=True)
    for source in args.sources:
        title = args.title or read_markdown(source)[0]
        out = os.path.join(args.out_dir,
                           os.path.splitext(os.path.basename(source))[0] + ".pdf")
        build_pdf([source], out, title, args.footer_left, args.footer_right, False)
        print(f"PDF  {out}")
        if args.html:
            build_html([source], os.path.splitext(out)[0] + ".html", title,
                       args.footer_left, args.footer_right)
    return 0


if __name__ == "__main__":
    sys.exit(main())
