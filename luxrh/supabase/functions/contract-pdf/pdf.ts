/**
 * Générateur PDF minimal, sans dépendance externe.
 * Helvetica / Helvetica-Bold, encodage WinAnsi, pagination et césure automatiques.
 * Suffisant pour un contrat de travail ; à remplacer par un moteur de gabarits
 * si la mise en page devient plus riche.
 */

export type Line =
  | { kind: 'text'; text: string; bold?: boolean; size?: number; gap?: number }
  | { kind: 'space'; height: number }
  | { kind: 'rule' }

const PAGE_W = 595.28 // A4
const PAGE_H = 841.89
const MARGIN_X = 56
const MARGIN_TOP = 64
const MARGIN_BOTTOM = 64
const LEADING = 1.45

/** Table de correspondance Unicode → WinAnsiEncoding pour les caractères courants. */
const WIN_ANSI_EXTRA: Record<string, number> = {
  '€': 0x80, '‚': 0x82, 'ƒ': 0x83, '„': 0x84, '…': 0x85, '†': 0x86, '‡': 0x87,
  'ˆ': 0x88, '‰': 0x89, 'Š': 0x8a, '‹': 0x8b, 'Œ': 0x8c, 'Ž': 0x8e,
  '‘': 0x91, '’': 0x92, '“': 0x93, '”': 0x94, '•': 0x95, '–': 0x96, '—': 0x97,
  '˜': 0x98, '™': 0x99, 'š': 0x9a, '›': 0x9b, 'œ': 0x9c, 'ž': 0x9e, 'Ÿ': 0x9f,
}

function toWinAnsi(s: string): number[] {
  const out: number[] = []
  for (const ch of s) {
    const code = ch.codePointAt(0)!
    if (code < 0x100) out.push(code)
    else if (WIN_ANSI_EXTRA[ch] !== undefined) out.push(WIN_ANSI_EXTRA[ch])
    else out.push(0x3f) // '?'
  }
  return out
}

/** Échappe (, ) et \ puis encode en WinAnsi. */
function pdfString(s: string): number[] {
  const out: number[] = []
  for (const b of toWinAnsi(s)) {
    if (b === 0x28 || b === 0x29 || b === 0x5c) out.push(0x5c)
    out.push(b)
  }
  return out
}

// Largeurs Helvetica (unités de 1/1000 em) pour les codes 32..255 utiles.
const HELV_WIDTHS: Record<number, number> = {
  32: 278, 33: 278, 34: 355, 35: 556, 36: 556, 37: 889, 38: 667, 39: 191,
  40: 333, 41: 333, 42: 389, 43: 584, 44: 278, 45: 333, 46: 278, 47: 278,
  48: 556, 49: 556, 50: 556, 51: 556, 52: 556, 53: 556, 54: 556, 55: 556,
  56: 556, 57: 556, 58: 278, 59: 278, 60: 584, 61: 584, 62: 584, 63: 556,
  64: 1015, 65: 667, 66: 667, 67: 722, 68: 722, 69: 667, 70: 611, 71: 778,
  72: 722, 73: 278, 74: 500, 75: 667, 76: 556, 77: 833, 78: 722, 79: 778,
  80: 667, 81: 778, 82: 722, 83: 667, 84: 611, 85: 722, 86: 667, 87: 944,
  88: 667, 89: 667, 90: 611, 91: 278, 92: 278, 93: 278, 94: 469, 95: 556,
  96: 333, 97: 556, 98: 556, 99: 500, 100: 556, 101: 556, 102: 278, 103: 556,
  104: 556, 105: 222, 106: 222, 107: 500, 108: 222, 109: 833, 110: 556,
  111: 556, 112: 556, 113: 556, 114: 333, 115: 500, 116: 278, 117: 556,
  118: 500, 119: 722, 120: 500, 121: 500, 122: 500, 123: 334, 124: 260,
  125: 334, 126: 584,
}

function charWidth(code: number, bold: boolean): number {
  const base = HELV_WIDTHS[code] ?? (code >= 0xc0 ? 600 : 556)
  return bold ? Math.round(base * 1.06) : base
}

function textWidth(s: string, size: number, bold: boolean): number {
  return toWinAnsi(s).reduce((w, c) => w + charWidth(c, bold), 0) * size / 1000
}

function wrap(text: string, size: number, bold: boolean, maxWidth: number): string[] {
  const words = text.split(/\s+/).filter(Boolean)
  const lines: string[] = []
  let current = ''
  for (const w of words) {
    const candidate = current ? `${current} ${w}` : w
    if (textWidth(candidate, size, bold) > maxWidth && current) {
      lines.push(current)
      current = w
    } else {
      current = candidate
    }
  }
  if (current) lines.push(current)
  return lines.length ? lines : ['']
}

export function buildPdf(title: string, lines: Line[]): Uint8Array {
  const usableWidth = PAGE_W - 2 * MARGIN_X
  const pages: number[][] = []
  let stream: number[] = []
  let y = PAGE_H - MARGIN_TOP

  const push = (s: string) => {
    for (let i = 0; i < s.length; i++) stream.push(s.charCodeAt(i))
  }

  const newPage = () => {
    if (stream.length) pages.push(stream)
    stream = []
    y = PAGE_H - MARGIN_TOP
  }

  const drawText = (text: string, size: number, bold: boolean) => {
    if (y < MARGIN_BOTTOM + size * LEADING) newPage()
    push(`BT /${bold ? 'F2' : 'F1'} ${size} Tf 1 0 0 1 ${MARGIN_X.toFixed(2)} ${y.toFixed(2)} Tm (`)
    for (const b of pdfString(text)) stream.push(b)
    push(') Tj ET\n')
    y -= size * LEADING
  }

  for (const line of lines) {
    if (line.kind === 'space') {
      y -= line.height
      if (y < MARGIN_BOTTOM) newPage()
      continue
    }
    if (line.kind === 'rule') {
      if (y < MARGIN_BOTTOM + 12) newPage()
      push(
        `0.85 0.84 0.85 RG 0.7 w ${MARGIN_X} ${y.toFixed(2)} m ` +
          `${(PAGE_W - MARGIN_X).toFixed(2)} ${y.toFixed(2)} l S\n`,
      )
      y -= 10
      continue
    }
    const size = line.size ?? 10
    const bold = line.bold ?? false
    for (const l of wrap(line.text, size, bold, usableWidth)) drawText(l, size, bold)
    if (line.gap) y -= line.gap
  }
  if (stream.length) pages.push(stream)
  if (pages.length === 0) pages.push([])

  // ---- assemblage du fichier ----
  const objects: number[][] = []
  const addObject = (bytes: number[]) => {
    objects.push(bytes)
    return objects.length // les numéros d'objet démarrent à 1
  }
  const raw = (s: string) => Array.from(s, (c) => c.charCodeAt(0))

  const fontRegular = addObject(raw('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'))
  const fontBold = addObject(raw('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>'))

  // Chaque page consomme deux objets (flux + page) ; l'objet /Pages vient juste après.
  const pagesObjNumber = objects.length + pages.length * 2 + 1
  const pageNumbers: number[] = []

  for (const content of pages) {
    const contentNo = addObject([...raw(`<< /Length ${content.length} >>\nstream\n`), ...content, ...raw('\nendstream')])
    const pageNo = addObject(
      raw(
        `<< /Type /Page /Parent ${pagesObjNumber} 0 R /MediaBox [0 0 ${PAGE_W.toFixed(2)} ${PAGE_H.toFixed(2)}] ` +
          `/Resources << /Font << /F1 ${fontRegular} 0 R /F2 ${fontBold} 0 R >> >> /Contents ${contentNo} 0 R >>`,
      ),
    )
    pageNumbers.push(pageNo)
  }

  const pagesNo = addObject(
    raw(
      `<< /Type /Pages /Kids [${pageNumbers.map((n) => `${n} 0 R`).join(' ')}] /Count ${pageNumbers.length} >>`,
    ),
  )
  const catalogNo = addObject(raw(`<< /Type /Catalog /Pages ${pagesNo} 0 R >>`))
  const infoNo = addObject(
    [...raw('<< /Title ('), ...pdfString(title), ...raw(') /Producer (LuxRH) >>')],
  )

  const out: number[] = []
  const offsets: number[] = []
  out.push(...raw('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'))

  objects.forEach((body, i) => {
    offsets[i] = out.length
    out.push(...raw(`${i + 1} 0 obj\n`), ...body, ...raw('\nendobj\n'))
  })

  const xrefStart = out.length
  out.push(...raw(`xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`))
  for (const off of offsets) out.push(...raw(`${String(off).padStart(10, '0')} 00000 n \n`))
  out.push(
    ...raw(
      `trailer\n<< /Size ${objects.length + 1} /Root ${catalogNo} 0 R /Info ${infoNo} 0 R >>\n` +
        `startxref\n${xrefStart}\n%%EOF\n`,
    ),
  )

  return Uint8Array.from(out.map((b) => b & 0xff))
}
