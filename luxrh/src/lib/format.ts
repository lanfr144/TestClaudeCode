const nf = (min: number, max: number) =>
  new Intl.NumberFormat('fr-LU', { minimumFractionDigits: min, maximumFractionDigits: max })

export const eur = (v: number | string | null | undefined) =>
  v === null || v === undefined || v === '' ? '—' : `${nf(2, 2).format(Number(v))} €`

export const num = (v: number | string | null | undefined, decimals = 2) =>
  v === null || v === undefined || v === '' ? '—' : nf(0, decimals).format(Number(v))

export const hours = (v: number | string | null | undefined) =>
  v === null || v === undefined ? '—' : `${nf(0, 2).format(Number(v))} h`

export const pct = (v: number | string | null | undefined) =>
  v === null || v === undefined ? '—' : `${nf(0, 2).format(Number(v))} %`

/** 2026-10-12 -> 12.10.2026 */
export const date = (v: string | Date | null | undefined) => {
  if (!v) return '—'
  const d = typeof v === 'string' ? new Date(`${v.slice(0, 10)}T00:00:00`) : v
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleDateString('fr-LU')
}

export const dateLong = (v: string | Date | null | undefined) => {
  if (!v) return '—'
  const d = typeof v === 'string' ? new Date(`${v.slice(0, 10)}T00:00:00`) : v
  return d.toLocaleDateString('fr-LU', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

export const dayShort = (v: string | Date) => {
  const d = typeof v === 'string' ? new Date(`${v.slice(0, 10)}T00:00:00`) : v
  return d.toLocaleDateString('fr-LU', { weekday: 'short', day: 'numeric' })
}

/** HH:MM:SS -> HH:MM */
export const time = (v: string | null | undefined) => (v ? v.slice(0, 5) : '—')

export const initials = (first?: string | null, last?: string | null) =>
  `${(first ?? '').charAt(0)}${(last ?? '').charAt(0)}`.toUpperCase() || '??'

export const iso = (d: Date) => d.toISOString().slice(0, 10)

/** Lundi de la semaine contenant d. */
export function mondayOf(d: Date): Date {
  const x = new Date(d)
  const day = (x.getDay() + 6) % 7
  x.setDate(x.getDate() - day)
  x.setHours(0, 0, 0, 0)
  return x
}

export function addDays(d: Date | string, n: number): Date {
  const x = typeof d === 'string' ? new Date(`${d.slice(0, 10)}T00:00:00`) : new Date(d)
  x.setDate(x.getDate() + n)
  return x
}

/** Numéro de semaine ISO 8601. */
export function isoWeek(d: Date): number {
  const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
  t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7))
  const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
  return Math.ceil(((t.getTime() - yearStart.getTime()) / 86400000 + 1) / 7)
}

export const RESIDENCY_LABEL: Record<string, string> = {
  resident: 'Résident',
  frontalier_fr: 'Frontalier (FR)',
  frontalier_be: 'Frontalier (BE)',
  frontalier_de: 'Frontalier (DE)',
}

export const ROLE_LABEL: Record<string, string> = {
  fiduciary_admin: 'Admin fiduciaire',
  manager: 'Gestionnaire',
  service_manager: 'Manager de service',
  employee: 'Salarié',
}

export const CBA_SCOPE_LABEL: Record<string, string> = {
  sector: 'Sectorielle',
  harassment: 'Harcèlement',
  employee_category: 'Catégorie d’emploi',
  department: 'Service',
  company: 'Entreprise',
}

export const CONTRACT_KIND_LABEL: Record<string, string> = {
  cdi: 'CDI',
  cdd: 'CDD',
  seasonal: 'Saisonnier',
  apprenticeship: 'Apprentissage',
  interim: 'Mission',
}

export const SEX_LABEL: Record<string, string> = {
  male: 'Homme',
  female: 'Femme',
  unspecified: 'Non précisé',
}

export const STATUS_KIND_LABEL: Record<string, string> = {
  pregnancy: 'Grossesse',
  maternity_leave: 'Congé de maternité',
  breastfeeding: 'Allaitement',
  parental_leave: 'Congé parental',
  delegate: 'Délégué du personnel',
  safety_delegate: 'Délégué à la sécurité',
  equality_delegate: 'Délégué à l’égalité',
  reemployment_bonus: 'Prime de réemploi',
  company_manager: 'Gérant de la société',
  protected_other: 'Autre statut protégé',
}

/**
 * Date sentinelle de « pas de fin connue ».
 *
 * La migration 70 a rendu `valid_to` non nul sur les treize tables datées : une
 * validité ouverte porte cette date, plus jamais NULL. Elle tient dans un `time_t`
 * 32 bits signé, ce que 9999-12-31 ne fait pas.
 */
export const FIN_OUVERTE = '2037-12-31'

/**
 * Vrai si la ligne est en vigueur a la date donnee.
 *
 * Borne basse inclusive, borne haute exclusive — la meme convention que le moteur.
 * Cette fonction existe parce que six ecrans testaient `!row.valid_to` pour
 * reconnaitre la version courante : depuis que la colonne est non nulle, ce test
 * est toujours faux et l'ecran perd silencieusement la valeur en vigueur. Passer
 * par une fonction nommee evite que la question se repose.
 */
export function estEnVigueur(
  row: { valid_from?: string | null; valid_to?: string | null },
  on: string,
): boolean {
  if (row.valid_from && row.valid_from > on) return false
  return !row.valid_to || row.valid_to > on
}

/** Vrai si la validite n'a pas de fin connue : NULL hier, date sentinelle aujourd'hui. */
export function sansFin(valid_to: string | null | undefined): boolean {
  return !valid_to || valid_to >= FIN_OUVERTE
}

/** Convention applicable a une date, extraite de la table de liaison. */
export function currentCbas<
  T extends {
    valid_from: string
    valid_to: string | null
    collective_agreements: { name: string; code: string; scope?: string | null } | null
  },
>(links: T[] | null | undefined, on: string): T[] {
  return (links ?? []).filter((l) => l.valid_from <= on && (!l.valid_to || l.valid_to > on))
}

export const ABSENCE_STATUS_LABEL: Record<string, string> = {
  pending: 'En attente',
  approved: 'Validé',
  refused: 'Refusé',
  cancelled: 'Annulé',
}
