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
  categorie_professionnelle: 'Catégorie d’emploi',
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
  parental_leave: 'Congé conge_parental',
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
 * `debut_validite` et `fin_validite` sont **non nuls** depuis la migration 70 :
 * une validité ouverte porte cette date, jamais NULL. Elle tient dans un `time_t`
 * 32 bits signé, ce que 9999-12-31 ne fait pas — raison pour laquelle le projet
 * n'emploie qu'elle, y compris dans les schémas Oracle et MySQL dérivés.
 */
export const FIN_OUVERTE = '2037-12-31'

/**
 * Vrai si la ligne est en vigueur à la date donnée.
 *
 * Borne basse incluse, borne haute exclue — la convention du moteur.
 *
 * Les deux bornes sont exigées, et non optionnelles. C'est délibéré : tant que la
 * signature tolérait `string | null`, le corps devait prévoir le nul, et chaque
 * lecteur en concluait que la colonne pouvait l'être. Une colonne `not null` dont
 * tout le code se méfie n'est pas un invariant, c'est une convention à laquelle
 * personne ne croit. Le compilateur l'impose désormais à l'appelant.
 */
export function estEnVigueur(
  ligne: { debut_validite: string; fin_validite: string },
  le: string,
): boolean {
  return ligne.debut_validite <= le && ligne.fin_validite > le
}

/** Vrai si la validité n'a pas de fin connue, c'est-à-dire si elle porte la sentinelle. */
export function sansFin(fin_validite: string): boolean {
  return fin_validite >= FIN_OUVERTE
}

/** Convention applicable à une date, extraite de la table de liaison. */
export function currentCbas<
  T extends {
    debut_validite: string
    fin_validite: string
    conventions_collectives: { nom: string; code: string; portee?: string | null } | null
  },
>(links: T[] | null | undefined, on: string): T[] {
  return (links ?? []).filter((l) => estEnVigueur(l, on))
}

export const ABSENCE_STATUS_LABEL: Record<string, string> = {
  pending: 'En attente',
  approved: 'Validé',
  refused: 'Refusé',
  cancelled: 'Annulé',
}
