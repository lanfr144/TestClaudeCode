/**
 * Formes de retour du moteur de règles PostgreSQL.
 * Le front ne recalcule rien : il affiche ce que le serveur a décidé,
 * avec la base légale que le serveur a citée.
 */

export type Severity = 'blocking' | 'warning' | 'info' | 'ok'

export interface Arbitration {
  label: string
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
  label: string
  severity: Severity
  detail: string
  legal_ref: string | null
}

export interface MandatoryMention {
  label: string
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
  legal_ref: string | null
}

export interface ContractCompliance {
  contract_id: string
  evaluated_on: string
  kind?: string
  is_part_time?: boolean
  collective_agreements: { name: string; code: string; scope: string; origin: string }[]
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
  severity: Exclude<Severity, 'ok'>
  code: string
  title: string
  detail: string
  legal_ref: string | null
  employee_id: string | null
  employee_name: string | null
  shift_date: string | null
}

export interface ScheduleEmployeeSummary {
  employee_id: string
  employee_name: string
  job_title: string | null
  contract_weekly_hours: number | null
  total_hours: number
  overtime_hours: number
  sundays: number
  longest_rest_hours: number
}

export interface ScheduleValidation {
  schedule_id: string
  week_start: string
  status: 'draft' | 'published'
  violations: Violation[]
  employees: ScheduleEmployeeSummary[]
  blocking_count: number
  warning_count: number
  can_publish: boolean
}

export interface LeaveLine {
  label: string
  value: number
  sign: '+' | '-' | '='
}

export interface LeaveBalance {
  employee_id: string
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
  legal_ref: string | null
  no_contract?: boolean
}

export interface SickCounters {
  employee_id: string
  window_months: number
  days_in_window: number
  limit_days: number
  remaining_days: number
  continuation_end: string | null
  protection_end: string | null
  protection_weeks: number
  mutuality_refund_pct: number
  certificate_deadline_days: number
  missing_certificates: { absence_id: string; start_date: string; days_late: number }[]
  legal_ref: string | null
  protection_ref: string | null
}

export interface LeaveImpact {
  days_counted: number
  holidays_excluded: number
  category: string
  balance_before?: number
  balance_after?: number
  /** Droit applicable a la date de la demande, lu dans absence_entitlements. */
  entitlement_days?: number | null
  career_cap_days?: number | null
  block_days?: number | null
  used_career?: number
  used_in_period?: number
  period_months?: number | null
  requires_evidence?: boolean
  is_valid: boolean
  message: string
  legal_ref: string | null
}

export interface Headcount {
  company_id: string
  reference_months: number
  period_start: string
  period_end: string
  average: number
  rounded: number
  current: number
  monthly: { month: string; headcount: number }[]
  legal_ref: string | null
}

export interface Threshold {
  threshold: number
  label: string
  reached: boolean
  gap: number
  status: string
  consequence: string
  legal_ref: string | null
}

export interface HeadcountObligations {
  headcount: Headcount
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
  legal_ref: string | null
}

export interface TimelineStep {
  when: string
  title: string
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
  rule_code: string
  employee_id?: string | null
  employee_name?: string | null
  contract_id?: string | null
  schedule_id?: string | null
  title: string
  detail: string
  consequence: string | null
  due_date: string | null
  days_left: number | null
  severity: Exclude<Severity, 'ok'>
  legal_ref: string | null
  category?: 'contract' | 'absence' | 'headcount' | 'worktime'
}

export interface ComplianceScan {
  company_id: string
  evaluated_on: string
  horizon_days: number
  items: VigilanceItem[]
  overdue: VigilanceItem[]
  due_soon: VigilanceItem[]
  watch: VigilanceItem[]
  headcount: HeadcountObligations
  dismissal_counters: DismissalCounters
  disclaimer: string
}

export interface ReferencePeriodStatus {
  label: string
  months: number
  start_date: string
  end_date: string
  average_weekly_hours: number
  target_weekly_hours: number
  margin_hours: number
  legal_ref: string | null
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
  activity_class?: string | null
  accident_risk_class?: string | null
  accident_factor?: number
  accident_base_rate?: number
  accident_rate?: number
  mutuality_class?: number | null
  mutuality_rate?: number | null
  employer_total_pct?: number
  legal_ref?: string | null
}

export type CbaScope = 'sector' | 'harassment' | 'employee_category' | 'department' | 'company'

export interface ApplicableCba {
  collective_agreement_id: string
  code: string
  name: string
  scope: CbaScope
  origin: string
  valid_from: string
  valid_to: string | null
}

export interface Qualification {
  qualified: boolean
  source: string
  career_years: number | null
  threshold_years: number
  legal_ref: string | null
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
  kind: string
  label: string
  until: string | null
  days_left: number | null
  consequence: string
  legal_ref: string | null
  declared_on?: string
  expected_birth_date?: string | null
  actual_birth_date?: string | null
}

export interface DismissalProtections {
  employee_id: string
  evaluated_on: string
  protected: boolean
  protections: Protection[]
}

export interface OvertimeEligibility {
  employee_id: string
  evaluated_on: string
  allowed: boolean
  reasons: { code: string; label: string; detail: string; legal_ref: string | null }[]
}

export interface DelegationEligibility {
  employee_id: string
  evaluated_on: string
  eligible: boolean
  seniority_months: number | null
  required_months: number
  reasons: { code: string; detail: string }[]
  legal_ref: string | null
}

export interface EndOfContractDocument {
  code: string
  label: string
  delivered: boolean
  delivered_at: string | null
  document_id: string | null
  legal_ref: string | null
  note: string | null
}

export interface EndOfContractDocuments {
  contract_id: string
  terminated: boolean
  notice_end: string | null
  documents: EndOfContractDocument[]
  outstanding: number
}

export interface ReferentialGap {
  family: string
  param_key: string
  label: string
  earliest_covered: string
  latest_covered: string
  versions: number
  covers_since: boolean
  gap_days: number
}

export interface ReferentialInconsistency {
  param_key: string
  label: string
  published: number
  derived: number
  difference: number
  tolerance: number
  source_key: string
}

export interface Absenteeism {
  company_id: string
  year: number
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
  tax_class?: string
  periodicity?: string
  bracket_min?: number
  bracket_max?: number | null
  base_tax?: number
  rate_over_min?: number
  valid_from?: string
  source?: string
  legal_ref?: string | null
}
