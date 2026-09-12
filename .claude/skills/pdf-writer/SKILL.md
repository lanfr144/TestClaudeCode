---
name: pdf-writer
description: Produit un PDF à partir de Markdown avec l'en-tête et le pied de page normalisés (logos am.png et Bts.png, titre centré, « Page X of Y », identifiant et code projet). À utiliser dès qu'un document du dépôt doit être livré en PDF.
---

# pdf-writer — en-têtes et pieds de page normalisés

Reprise dans ce dépôt de la norme `Header_Footer_Gemini.md`
(copie intégrale conservée dans [`reference-gemini.md`](reference-gemini.md)).

## Ce que la norme impose

| Boîte de marge | Contenu | Format |
|---|---|---|
| `@top-left` | logo `assets/am.png` | hauteur max **24,5 pt** |
| `@top-center` | titre du document | 8 pt, gris `#808080` |
| `@top-right` | logo `assets/Bts.png` | hauteur max **36,8 pt** |
| `@bottom-left` | identifiant utilisateur | `lanfr144` |
| `@bottom-center` | pagination | `Page X of Y` |
| `@bottom-right` | code projet | `DOPRO1` |

Page A4, marges **60 pt** (haut) · **48 pt** (droite) · **54 pt** (bas) · **48 pt** (gauche).
Le haut est à 60 pt pour que le logo de 36,8 pt n'entre pas en collision avec le texte.

## Deux chaînes de rendu, une seule géométrie

La norme est écrite en **CSS Paged Media** : le moteur alloue les boîtes de marge et y place
lui-même logos et numéros. Ce modèle déclaratif suppose WeasyPrint, qui réclame sous Windows
les bibliothèques système GTK/Pango — un **programme**, pas un paquet Python, et le
`CLAUDE.md` du dépôt interdit d'en installer un sans demander.

[`render_pdf.py`](render_pdf.py) reproduit donc la même géométrie **au point près** avec
`reportlab`, déjà présent dans `luxrh-py/.venv`. La classe `MarginBoxCanvas` dessine les six
boîtes et fait deux passes pour connaître le total de pages — ce que `counter(pages)` donne
gratuitement en CSS.

L'option `--html` écrit en parallèle le document HTML **avec le bloc `@page` déclaratif**,
pour que la chaîne WeasyPrint reste reproductible telle quelle sur une machine équipée :

```bash
pip install weasyprint && weasyprint docs/pdf/documentation.html sortie.pdf
```

## Utilisation

Un PDF par document :

```bash
luxrh-py/.venv/Scripts/python .claude/skills/pdf-writer/render_pdf.py \
  docs/architecture.md docs/demarrage.md --out-dir docs/pdf
```

Un seul PDF assemblé, avec page de garde et jumeau HTML :

```bash
luxrh-py/.venv/Scripts/python .claude/skills/pdf-writer/render_pdf.py \
  docs/index.md docs/presentation.md docs/architecture.md \
  --combine --cover --html \
  --out docs/pdf/LuxRH-documentation.pdf --title "Documentation LuxRH"
```

| Option | Effet |
|---|---|
| `--combine` | assemble toutes les sources dans un PDF unique |
| `--out` / `--out-dir` | chemin du PDF assemblé / dossier des PDF unitaires |
| `--cover` | page de garde avec le titre et la liste des documents |
| `--title` | titre de l'en-tête ; par défaut le premier `#` du fichier |
| `--footer-left` / `--footer-right` | remplacent `lanfr144` et `DOPRO1` |
| `--html` | écrit aussi le HTML au `@page` déclaratif |

## Ce que le rendu Markdown couvre

Titres `#` à `####`, paragraphes, listes à puces et numérotées, tableaux GFM, blocs de code
délimités, citations, filets horizontaux, et en ligne : `code`, **gras**, *italique*, ~~barré~~,
liens. Un `# titre` de niveau 1 ouvre une nouvelle page.

**Limite connue** : les blocs ` ```mermaid ` sont imprimés comme code source légendé
« Schéma Mermaid (source) », faute de moteur de rendu de diagrammes hors navigateur. Les
schémas restent lisibles dans les fichiers Markdown sur GitHub.

## Contenu du dossier

```
.claude/skills/pdf-writer/
├── SKILL.md              cette fiche
├── reference-gemini.md   la norme d'origine, telle quelle
├── render_pdf.py         le moteur de rendu
├── assets/               am.png, Bts.png
└── fonts/                Roboto Regular / Bold / Mono
```
