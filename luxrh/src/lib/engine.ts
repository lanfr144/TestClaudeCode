/**
 * Formes de retour du moteur de règles PostgreSQL.
 * Le front ne recalcule rien : il affiche ce que le serveur a décidé,
 * avec la base légale que le serveur a citée.
 */

export type Severity = 'blocking' | 'warning' | 'info' | 'ok'

export interface Arbitration {
  libelle: string
  law_value: number | null
  law_ref: string | null
  cba_value: number | null
  cba_ref: string | null
  contract_value: number | null
  retained_value: number | null
  retained_source: 'Code du travail' | 'CCT' | 'Contrat individuel'
  retained_ref: string | null
}

export interface ComplianceCheck {
  code: string
  libelle: string
  severite: Severity
  detail: string
  reference_legale: string | null
}

export interface MandatoryMention {
  libelle: string
  ok: boolean
}

export interface MinSalary {
  ssm: number
  ssm_full: number
  ssm_ref: string | null
  ssm_index: number | null
  qualification: 'qualified' | 'unqualified'
  prorata: number
  cba_grid: number | null
  cba_category: string | null
  floor: number
  contract_gross: number
}

export interface Probation {
  start: string
  base_end: string
  extension_days: number
  extension_cap_days: number
  end: string
  notice_days: number
  last_day_to_notify: string
  days_until_deadline: number
  is_running: boolean
  reference_legale: string | null
}

export interface ContractCompliance {
  contrat_id: string
  evaluated_on: string
  genre?: string
  est_temps_partiel?: boolean
  conventions_collectives: { name: string; code: string; scope: string; origin: string }[]
  checks: ComplianceCheck[]
  mandatory_mentions: MandatoryMention[]
  salary: MinSalaryDetail
  annual_leave: Arbitration
  probation: Probation | null
  blocking_count: number
  warning_count: number
  can_validate: boolean
}

export interface Violation {
  severite: Exclude<Severity, 'ok'>
  code: string
  titre: string
  detail: string
  reference_legale: string | null
  salarie_id: string | null
  employee_name: string | null
  date_creneau: string | null
}

export interface ScheduleEmployeeSummary {
  salarie_id: string
  employee_name: string
  intitule_poste: string | null
  contract_weekly_hours: number | null
  total_hours: number
  heures_supplementaires: number
  sundays: number
  longest_rest_hours: number
}

export interface ScheduleValidation {
  planning_id: string
  debut_semaine: string
  statut: 'draft' | 'publie'
  violations: Violation[]
  salaries: ScheduleEmployeeSummary[]
  blocking_count: number
  warning_count: number
  can_publish: boolean
}

export interface LeaveLine {
  libelle: string
  value: number
  sign: '+' | '-' | '='
}

export interface LeaveBalance {
  salarie_id: string
  evaluated_on: string
  entitlement_days: number
  entitlement_source: string
  arbitration: Arbitration
  accrued: number
  taken: number
  balance: number
  months_counted: number
  prorata: number
  lines: LeaveLine[]
  reference_legale: string | null
  no_contract?: boolean
}

export interface SickCounters {
  salarie_id: string
  window_months: number
  days_in_window: number
  limit_days: number
  remaining_days: number
  continuation_end: string | null
  protection_end: string | null
  protection_weeks: number
  mutuality_refund_pct: number
  certificate_deadline_days: number
  missing_certificates: { absence_id: string; date_debut: string; days_late: number }[]
  reference_legale: string | null
  protection_ref: string | null
}

export interface LeaveImpact {
  days_counted: number
  holidays_excluded: number
  categorie: string
  balance_before?: number
  balance_after?: number
  /** Droit applicable a la date de la demande, lu dans droits_absence. */
  entitlement_days?: number | null
  plafond_carriere_jours?: number | null
  jours_bloc?: number | null
  used_career?: number
  used_in_period?: number
  duree_mois?: number | null
  piece_exigee?: boolean
  is_valid: boolean
  message: string
  reference_legale: string | null
}

export interface Headcount {
  societe_id: string
  reference_months: number
  debut_periode: string
  fin_periode: string
  average: number
  rounded: number
  current: number
  monthly: { month: string; headcount: number }[]
  reference_legale: string | null
}

export interface Threshold {
  threshold: number
  libelle: string
  reached: boolean
  gap: number
  statut: string
  consequence: string
  reference_legale: string | null
}

export interface HeadcountObligations {
  effectif: Headcount
  thresholds: Threshold[]
  delegates_due: { from: number; to: number | null; effective: number; substitute: number } | null
  vote_mode: 'majoritaire' | 'proportionnel'
}

export interface DismissalWindow {
  count: number
  threshold: number
  remaining: number
  releases_on: string | null
}

export interface DismissalCounters {
  evaluated_on: string
  window_30: DismissalWindow
  window_90: DismissalWindow
  reference_legale: string | null
}

export interface TimelineStep {
  when: string
  titre: string
  detail: string
  date: string
}

export interface DismissalSimulation {
  triggers: boolean
  counters: DismissalCounters
  requested_count: number
  requested_date: string
  total_30: number
  total_90: number
  verdict: string
  alternatives: { label: string }[]
  timeline: TimelineStep[]
  legal_refs: string[]
  disclaimer: string
}

export interface VigilanceItem {
  code_regle: string
  salarie_id?: string | null
  employee_name?: string | null
  contrat_id?: string | null
  planning_id?: string | null
  titre: string
  detail: string
  consequence: string | null
  date_echeance: string | null
  days_left: number | null
  severite: Exclude<Severity, 'ok'>
  reference_legale: string | null
  categorie?: 'contract' | 'absence' | 'effectif' | 'worktime'
}

export interface ComplianceScan {
  societe_id: string
  evaluated_on: string
  horizon_days: number
  items: VigilanceItem[]
  overdue: VigilanceItem[]
  due_soon: VigilanceItem[]
  watch: VigilanceItem[]
  effectif: HeadcountObligations
  dismissal_counters: DismissalCounters
  disclaimer: string
}

export interface ReferencePeriodStatus {
  libelle: string
  months: number
  date_debut: string
  date_fin: string
  average_weekly_hours: number
  target_weekly_hours: number
  margin_hours: number
  reference_legale: string | null
}

/* ===================================================================== */
/*  Extensions du moteur — taux société, conventions multiples,          */
/*  statuts protégés, documents, couverture du référentiel.              */
/* ===================================================================== */

export interface CompanyRates {
  found: boolean
  evaluated_on: string
  message?: string
  period_from?: string
  period_to?: string | null
  classe_activite?: string | null
  classe_risque_accident?: string | null
  facteur_accident?: number
  accident_base_rate?: number
  accident_rate?: number
  classe_mutualite?: number | null
  mutuality_rate?: number | null
  employer_total_pct?: number
  reference_legale?: string | null
}

export type CbaScope = 'secteur' | 'harassment' | 'categorie_professionnelle' | 'department' | 'company'

export interface ApplicableCba {
  convention_id: string
  code: string
  nom: string
  portee: CbaScope
  origine: string
  debut_validite: string
  fin_validite: string | null
}

export interface Qualification {
  qualified: boolean
  source: string
  career_years: number | null
  threshold_years: number
  reference_legale: string | null
}

/** fn_min_salary enrichi : âge, qualification détaillée, grilles multiples. */
export interface MinSalaryDetail extends Omit<MinSalary, 'qualification'> {
  qualification: Qualification
  is_qualified: boolean
  age: number | null
  age_ratio: number
  age_band: string
  age_ref: string | null
  cba_name: string | null
  cba_grids_considered: { cba: string; origin: string; category: string; amount: number }[]
}

export interface Protection {
  genre: string
  libelle: string
  until: string | null
  days_left: number | null
  consequence: string
  reference_legale: string | null
  declare_le?: string
  date_naissance_prevue?: string | null
  date_naissance_reelle?: string | null
}

export interface DismissalProtections {
  salarie_id: string
  evaluated_on: string
  protected: boolean
  protections: Protection[]
}

export interface OvertimeEligibility {
  salarie_id: string
  evaluated_on: string
  allowed: boolean
  reasons: { code: string; label: string; detail: string; reference_legale: string | null }[]
}

export interface DelegationEligibility {
  salarie_id: string
  evaluated_on: string
  eligible: boolean
  seniority_months: number | null
  required_months: number
  reasons: { code: string; detail: string }[]
  reference_legale: string | null
}

export interface EndOfContractDocument {
  code: string
  libelle: string
  delivered: boolean
  remis_le: string | null
  document_id: string | null
  reference_legale: string | null
  note: string | null
}

export interface EndOfContractDocuments {
  contrat_id: string
  terminated: boolean
  fin_preavis: string | null
  documents: EndOfContractDocument[]
  outstanding: number
}

export interface ReferentialGap {
  family: string
  cle_parametre: string
  libelle: string
  couvert_depuis: string
  couvert_jusqua: string
  versions: number
  couvre_depuis: boolean
  jours_manquants: number
}

export interface ReferentialInconsistency {
  cle_parametre: string
  libelle: string
  publie: number
  derived: number
  difference: number
  tolerance: number
  cle_source: string
}

export interface Absenteeism {
  societe_id: string
  annee: number
  sick_days: number
  average_headcount: number
  theoretical_working_days: number
  absenteeism_rate_pct: number | null
  suggested_mutuality_class: number | null
  message: string
}

export interface IncomeTax {
  found: boolean
  taxable: number
  tax: number | null
  message?: string
  classe_impot?: string
  periodicity?: string
  tranche_min?: number
  tranche_max?: number | null
  impot_base?: number
  taux_au_dessus_minimum?: number
  debut_validite?: string
  source?: string
  reference_legale?: string | null
}
