/**
 * Portabilité des données — RGPD et réversibilité.
 *
 * Rien n'est assemblé ici : le serveur produit le document complet, contrôle
 * qui a le droit de le demander et journalise la demande. Le navigateur ne fait
 * que déclencher et enregistrer le fichier.
 */

import { callEngine } from './supabase'

/** Enveloppe commune à tous les exports. */
export interface ExportDocument {
  format: 'luxrh.export/1'
  kind: 'employee' | 'company' | 'organization' | 'referential'
  exported_at: string
  payload: Record<string, unknown>
}

export interface ImportReport {
  mode: string
  added: number
  replaced: number
  skipped: number
  rejected: string[]
  message: string
}

const NOM: Record<ExportDocument['kind'], string> = {
  employee: 'mes-donnees',
  company: 'societe',
  organization: 'fiduciaire',
  referential: 'referentiel',
}

/** Nom de fichier daté, pour que deux exports successifs ne se recouvrent pas. */
function fileName(doc: ExportDocument, suffix?: string) {
  const jour = doc.exported_at.slice(0, 10)
  return ['luxrh', NOM[doc.kind], suffix, jour].filter(Boolean).join('-') + '.json'
}

/** Enregistre le document sur le poste de l'utilisateur. */
export function download(doc: ExportDocument, suffix?: string) {
  const blob = new Blob([JSON.stringify(doc, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = fileName(doc, suffix)
  a.click()
  URL.revokeObjectURL(url)
}

export const exportSelf = () => callEngine<ExportDocument>('fn_export_self')

export const exportEmployee = (employeeId: string) =>
  callEngine<ExportDocument>('fn_export_employee', { p_employee: employeeId })

export const exportCompany = (companyId: string) =>
  callEngine<ExportDocument>('fn_export_company', { p_company: companyId })

export const exportOrganization = () => callEngine<ExportDocument>('fn_export_organization')

export const exportReferential = () => callEngine<ExportDocument>('fn_export_referential')

export const importReferential = (doc: ExportDocument, mode: 'skip_existing' | 'replace') =>
  callEngine<ImportReport>('fn_import_referential', { p_document: doc, p_mode: mode })

/**
 * Lit un fichier choisi par l'utilisateur et vérifie l'enveloppe avant de
 * l'envoyer au serveur. Un fichier illisible doit se dire ici, pas à mi-import.
 */
export async function readDocument(file: File, expected: ExportDocument['kind']) {
  let parsed: unknown
  try {
    parsed = JSON.parse(await file.text())
  } catch {
    throw new Error(`« ${file.name} » n'est pas un fichier JSON lisible.`)
  }
  const doc = parsed as Partial<ExportDocument>
  if (doc.format !== 'luxrh.export/1') {
    throw new Error(
      `« ${file.name} » ne porte pas le format luxrh.export/1 : ce n'est pas un export LuxRH.`,
    )
  }
  if (doc.kind !== expected) {
    throw new Error(`Ce fichier est un export « ${doc.kind} », pas un ${expected}.`)
  }
  return doc as ExportDocument
}

/** Nombre d'enregistrements par section, pour annoncer ce qui part ou arrive. */
export function sections(doc: ExportDocument): { name: string; count: number }[] {
  return Object.entries(doc.payload)
    .filter(([, v]) => Array.isArray(v))
    .map(([name, v]) => ({ name, count: (v as unknown[]).length }))
    .filter((s) => s.count > 0)
    .sort((a, b) => b.count - a.count)
}
