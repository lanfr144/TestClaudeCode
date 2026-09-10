import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { callEngine, supabase } from './supabase'
import type {
  Absenteeism, ApplicableCba, CompanyRates, ComplianceScan, ContractCompliance,
  DelegationEligibility, DismissalCounters, DismissalProtections, DismissalSimulation,
  EndOfContractDocuments, HeadcountObligations, LeaveBalance, LeaveImpact,
  OvertimeEligibility, Qualification, ReferencePeriodStatus, ReferentialGap,
  ReferentialInconsistency, ScheduleValidation, SickCounters,
} from './engine'
import type { Database } from './database.types'

type Tables = Database['public']['Tables']
export type Company = Tables['companies']['Row']
export type Employee = Tables['employees']['Row']
export type Contract = Tables['contracts']['Row']
export type Absence = Tables['absences']['Row']
export type AbsenceType = Tables['absence_types']['Row']
export type Shift = Tables['shifts']['Row']
export type Schedule = Tables['schedules']['Row']
export type ShiftTemplate = Tables['shift_templates']['Row']
export type LegalParameter = Tables['legal_parameters']['Row']
export type CollectiveAgreement = Tables['collective_agreements']['Row']
export type TimeEntry = Tables['time_entries']['Row']
export type Department = Tables['departments']['Row']

export type CompanyRatePeriod = Tables['company_rate_periods']['Row']
export type CbaRule = Tables['cba_rules']['Row']
export type ContractAmendment = Tables['contract_amendments']['Row']
export type DocumentRow = Tables['documents']['Row']
export type EmployeeTaxCard = Tables['employee_tax_cards']['Row']
export type EmployeeStatus = Tables['employee_statuses']['Row']

/**
 * Au-delà de deux niveaux de jointure, l'inférence de supabase-js sature et
 * retombe sur `never`. Les requêtes de détail portent donc leur type explicite.
 */
export type CompanyCbaLink = Tables['company_collective_agreements']['Row'] & {
  collective_agreements: (CollectiveAgreement & { cba_rules: CbaRule[] }) | null
}

export type CompanyListRow = Company & {
  company_collective_agreements: {
    valid_from: string
    valid_to: string | null
    collective_agreements: { name: string; code: string; sector: string; scope: string } | null
  }[]
}

export type CompanyDetailRow = Company & {
  departments: Department[]
  company_rate_periods: CompanyRatePeriod[]
  company_collective_agreements: CompanyCbaLink[]
}

export type ContractDetailRow = Contract & {
  employees: Employee | null
  companies: Company | null
  contract_amendments: ContractAmendment[]
  contract_collective_agreements: {
    id: string
    valid_from: string
    valid_to: string | null
    collective_agreements: { name: string; code: string; scope: string } | null
  }[]
}

export type EmployeeDetailRow = Employee & {
  departments: { name: string } | null
  employee_tax_cards: EmployeeTaxCard[]
  contracts: Contract[]
  documents: DocumentRow[]
}

export type EmployeeListRow = Employee & {
  departments: { name: string } | null
  contracts: Pick<
    Contract,
    | 'id' | 'kind' | 'status' | 'job_title' | 'start_date' | 'end_date'
    | 'probation_length' | 'probation_unit' | 'weekly_hours' | 'monthly_gross'
  >[]
}

const unwrap = <T,>({ data, error }: { data: T | null; error: { message: string } | null }): T => {
  if (error) throw new Error(error.message)
  return data as T
}

/* ------------------------------------------------------------------ socle */

export const useProfile = () =>
  useQuery({
    queryKey: ['profile'],
    queryFn: async () => {
      const { data: auth } = await supabase.auth.getUser()
      if (!auth.user) return null
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*, organizations(*)')
        .eq('id', auth.user.id)
        .maybeSingle()
      if (error) throw new Error(error.message)
      if (!profile) return null
      const roles = unwrap(await supabase.from('user_roles').select('*'))
      const self = unwrap(
        await supabase.from('employees').select('id, company_id').eq('user_id', auth.user.id).maybeSingle(),
      ) as { id: string; company_id: string } | null
      return { ...profile, roles, selfEmployee: self }
    },
  })

export const useCompanies = () =>
  useQuery({
    queryKey: ['companies'],
    queryFn: async () =>
      unwrap<CompanyListRow[]>(
        await supabase.from('companies')
          .select('*, company_collective_agreements(valid_from, valid_to, collective_agreements(name, code, sector, scope))')
          .order('legal_name'),
      ),
  })

export const useCompany = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['company', id],
    queryFn: async () =>
      unwrap<CompanyDetailRow>(
        await supabase.from('companies')
          .select('*, departments(*), company_rate_periods(*), company_collective_agreements(*, collective_agreements(*, cba_rules(*)))')
          .eq('id', id!).single(),
      ),
  })

/* -------------------------------------------------------------- employes */

export const useEmployees = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['employees', companyId],
    queryFn: async () =>
      unwrap<EmployeeListRow[]>(
        await supabase.from('employees')
          .select(
            '*, departments(name), contracts(id, kind, status, job_title, start_date, end_date, probation_length, probation_unit, weekly_hours, monthly_gross)',
          )
          .eq('company_id', companyId!).order('last_name'),
      ),
  })

export const useEmployee = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['employee', id],
    queryFn: async () =>
      unwrap<EmployeeDetailRow>(
        await supabase.from('employees')
          .select('*, departments(name), employee_tax_cards(*), contracts(*), documents(*)')
          .eq('id', id!).single(),
      ),
  })

/** Matricule et IBAN : chiffres au repos, lus par RPC controle. */
export const useEmployeeSensitive = (id?: string) =>
  useQuery({
    enabled: !!id,
    retry: false,
    queryKey: ['employee-sensitive', id],
    queryFn: async () => {
      const rows = await callEngine<{ national_id: string | null; iban: string | null }[]>(
        'fn_employee_sensitive', { p_employee: id },
      )
      return rows?.[0] ?? null
    },
  })

/* -------------------------------------------------------------- contrats */

export const useContracts = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['contracts', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('contracts')
          .select('*, employees(first_name, last_name)')
          .eq('company_id', companyId!).order('start_date', { ascending: false }),
      ),
  })

export const useContract = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['contract', id],
    queryFn: async () =>
      unwrap<ContractDetailRow>(
        await supabase.from('contracts')
          .select('*, employees(*), companies(*), contract_amendments(*), contract_collective_agreements(*, collective_agreements(name, code, scope))')
          .eq('id', id!).single(),
      ),
  })

export const useContractCompliance = (contractId?: string, on?: string) =>
  useQuery({
    enabled: !!contractId,
    queryKey: ['contract-compliance', contractId, on],
    queryFn: () =>
      callEngine<ContractCompliance>('fn_contract_compliance', { p_contract: contractId, p_on: on }),
  })

export const useCreateContract = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (c: Tables['contracts']['Insert']) =>
      unwrap<Contract>(await supabase.from('contracts').insert(c).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['contracts'] })
      qc.invalidateQueries({ queryKey: ['employees'] })
    },
  })
}

export const useUpdateContract = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...patch }: Tables['contracts']['Update'] & { id: string }) =>
      unwrap<Contract>(await supabase.from('contracts').update(patch).eq('id', id).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['contract'] })
      qc.invalidateQueries({ queryKey: ['contracts'] })
      qc.invalidateQueries({ queryKey: ['contract-compliance'] })
    },
  })
}

/* -------------------------------------------------------------- planning */

export const useSchedules = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['schedules', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('schedules').select('*').eq('company_id', companyId!)
          .order('week_start', { ascending: false }),
      ),
  })

export const useSchedule = (companyId?: string, weekStart?: string) =>
  useQuery({
    enabled: !!companyId && !!weekStart,
    queryKey: ['schedule', companyId, weekStart],
    queryFn: async () => {
      const schedule = unwrap<Schedule | null>(
        await supabase.from('schedules').select('*')
          .eq('company_id', companyId!).eq('week_start', weekStart!).maybeSingle(),
      )
      if (!schedule) return { schedule: null, shifts: [] as ShiftWithEmployee[] }
      const shifts = unwrap(
        await supabase.from('shifts')
          .select('*, employees(id, first_name, last_name)')
          .eq('schedule_id', schedule.id)
          .order('shift_date').order('start_time'),
      ) as unknown as ShiftWithEmployee[]
      return { schedule, shifts }
    },
  })

export type ShiftWithEmployee = Shift & {
  employees: { id: string; first_name: string; last_name: string } | null
}

export const useScheduleValidation = (scheduleId?: string) =>
  useQuery({
    enabled: !!scheduleId,
    queryKey: ['schedule-validation', scheduleId],
    queryFn: () => callEngine<ScheduleValidation>('fn_validate_schedule', { p_schedule: scheduleId }),
  })

export const useShiftTemplates = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['shift-templates', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('shift_templates').select('*').eq('company_id', companyId!).order('start_time'),
      ),
  })

export const useReferencePeriod = (companyId?: string, on?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['reference-period', companyId, on],
    queryFn: () =>
      callEngine<ReferencePeriodStatus | null>('fn_reference_period_status', {
        p_company: companyId, p_on: on,
      }),
  })

export const usePublishSchedule = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (scheduleId: string) =>
      callEngine<ScheduleValidation>('fn_publish_schedule', { p_schedule: scheduleId }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['schedule'] })
      qc.invalidateQueries({ queryKey: ['schedule-validation'] })
      qc.invalidateQueries({ queryKey: ['vigilance'] })
    },
  })
}

export const useCreateSchedule = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (s: Tables['schedules']['Insert']) =>
      unwrap<Schedule>(await supabase.from('schedules').insert(s).select().single()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['schedule'] }),
  })
}

export const useUpsertShift = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (shift: Tables['shifts']['Insert']) =>
      unwrap<Shift>(await supabase.from('shifts').upsert(shift).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['schedule'] })
      qc.invalidateQueries({ queryKey: ['schedule-validation'] })
    },
  })
}

export const useDeleteShift = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('shifts').delete().eq('id', id)
      if (error) throw new Error(error.message)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['schedule'] })
      qc.invalidateQueries({ queryKey: ['schedule-validation'] })
    },
  })
}

/* -------------------------------------------------------------- absences */

export const useAbsenceTypes = () =>
  useQuery({
    queryKey: ['absence-types'],
    staleTime: 300000,
    queryFn: async () => unwrap(await supabase.from('absence_types').select('*').order('label')),
  })

export type AbsenceEntitlement = Tables['absence_entitlements']['Row']

export type AbsenceRow = Absence & {
  employees: { id: string; first_name: string; last_name: string } | null
  absence_types: (AbsenceType & { absence_entitlements: AbsenceEntitlement[] }) | null
}

export const useAbsences = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['absences', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('absences')
          .select('*, employees(id, first_name, last_name), absence_types(*, absence_entitlements(*))')
          .eq('company_id', companyId!).order('start_date', { ascending: false }),
      ) as unknown as AbsenceRow[],
  })

export const useLeaveBalance = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['leave-balance', employeeId, on],
    queryFn: () => callEngine<LeaveBalance>('fn_leave_balance', { p_employee: employeeId, p_on: on }),
  })

export const useSickCounters = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['sick-counters', employeeId, on],
    queryFn: () => callEngine<SickCounters>('fn_sick_counters', { p_employee: employeeId, p_on: on }),
  })

export const useLeaveImpact = (employeeId?: string, typeId?: string, start?: string, end?: string) =>
  useQuery({
    enabled: !!employeeId && !!typeId && !!start && !!end && start <= end,
    queryKey: ['leave-impact', employeeId, typeId, start, end],
    queryFn: () =>
      callEngine<LeaveImpact>('fn_leave_request_impact', {
        p_employee: employeeId, p_type: typeId, p_start: start, p_end: end,
      }),
  })

export const useDecideAbsence = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: { id: string; status: 'approved' | 'refused'; note?: string }) => {
      const { data: auth } = await supabase.auth.getUser()
      return unwrap(
        await supabase.from('absences')
          .update({
            status: v.status,
            decided_at: new Date().toISOString(),
            decided_by: auth.user?.id ?? null,
            decision_note: v.note ?? null,
          })
          .eq('id', v.id).select().single(),
      )
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['absences'] })
      qc.invalidateQueries({ queryKey: ['leave-balance'] })
      qc.invalidateQueries({ queryKey: ['vigilance'] })
      qc.invalidateQueries({ queryKey: ['schedule-validation'] })
    },
  })
}

export const useCreateAbsence = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (a: Tables['absences']['Insert']) =>
      unwrap<Absence>(await supabase.from('absences').insert(a).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['absences'] })
      qc.invalidateQueries({ queryKey: ['leave-balance'] })
      qc.invalidateQueries({ queryKey: ['self-absences'] })
    },
  })
}

export const useMarkCertificate = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) =>
      unwrap(
        await supabase.from('absences')
          .update({ certificate_received: true, certificate_received_at: new Date().toISOString().slice(0, 10) })
          .eq('id', id).select().single(),
      ),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['absences'] })
      qc.invalidateQueries({ queryKey: ['sick-counters'] })
      qc.invalidateQueries({ queryKey: ['vigilance'] })
    },
  })
}

/* ------------------------------------------------------------- vigilance */

export const useVigilance = (companyId?: string, on?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['vigilance', companyId, on],
    queryFn: () => callEngine<ComplianceScan>('fn_compliance_scan', { p_company: companyId, p_on: on }),
  })

export const useHeadcount = (companyId?: string, on?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['headcount', companyId, on],
    queryFn: () =>
      callEngine<HeadcountObligations>('fn_headcount_obligations', { p_company: companyId, p_on: on }),
  })

export const useDismissalCounters = (companyId?: string, on?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['dismissal-counters', companyId, on],
    queryFn: () =>
      callEngine<DismissalCounters>('fn_collective_dismissal_counters', { p_company: companyId, p_on: on }),
  })

export const useSimulateDismissal = () =>
  useMutation({
    mutationFn: (v: { companyId: string; count: number; date: string; personalGround: boolean }) =>
      callEngine<DismissalSimulation>('fn_simulate_collective_dismissal', {
        p_company: v.companyId, p_count: v.count, p_date: v.date, p_personal_ground: v.personalGround,
      }),
  })

/* ----------------------------------------------------------- referentiel */

export const useLegalParameters = () =>
  useQuery({
    queryKey: ['legal-parameters'],
    queryFn: async () =>
      unwrap(
        await supabase.from('legal_parameters').select('*')
          .order('family').order('param_key').order('valid_from', { ascending: false }),
      ),
  })

export const useCollectiveAgreements = () =>
  useQuery({
    queryKey: ['cba'],
    queryFn: async () =>
      unwrap(
        await supabase.from('collective_agreements')
          .select('*, cba_rules(*), cba_salary_grids(*)').order('name'),
      ),
  })

export const usePublicHolidays = (year: number) =>
  useQuery({
    queryKey: ['holidays', year],
    staleTime: 3600000,
    queryFn: async () =>
      unwrap(
        await supabase.from('public_holidays').select('*').eq('year', year).order('holiday_date'),
      ),
  })

/* ----------------------------------------------------- registre du temps */

export const useTimeEntries = (companyId?: string, from?: string, to?: string) =>
  useQuery({
    enabled: !!companyId && !!from && !!to,
    queryKey: ['time-entries', companyId, from, to],
    queryFn: async () =>
      unwrap(
        await supabase.from('time_entries')
          .select('*, employees(first_name, last_name)')
          .eq('company_id', companyId!).gte('entry_date', from!).lte('entry_date', to!)
          .order('entry_date', { ascending: false }),
      ),
  })

export const useUpsertTimeEntry = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (e: Tables['time_entries']['Insert']) =>
      unwrap(
        await supabase.from('time_entries')
          .upsert(e, { onConflict: 'employee_id,entry_date' }).select().single(),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['time-entries'] }),
  })
}

/* ---------------------------------------------------------- audit & RGPD */

export const useAuditLog = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['audit', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('audit_log').select('*').eq('company_id', companyId!)
          .order('occurred_at', { ascending: false }).limit(200),
      ),
  })

/* ------------------------------------------------- societe : taux et CCT */

export const useCompanyRates = (companyId?: string, on?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['company-rates', companyId, on],
    queryFn: () => callEngine<CompanyRates>('fn_company_rates', { p_company: companyId, p_on: on }),
  })

export const useSetCompanyRates = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (v: {
      companyId: string
      from: string
      mutualityClass: number
      accidentFactor: number
      activityClass?: string | null
      riskClass?: string | null
      note?: string | null
    }) =>
      callEngine('fn_set_company_rates', {
        p_company: v.companyId,
        p_from: v.from,
        p_mutuality_class: v.mutualityClass,
        p_accident_factor: v.accidentFactor,
        p_activity_class: v.activityClass ?? null,
        p_accident_risk_class: v.riskClass ?? null,
        p_note: v.note ?? null,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['company-rates'] })
      qc.invalidateQueries({ queryKey: ['company'] })
    },
  })
}

export const useApplicableCbas = (contractId?: string, on?: string) =>
  useQuery({
    enabled: !!contractId,
    queryKey: ['applicable-cbas', contractId, on],
    queryFn: () =>
      callEngine<ApplicableCba[]>('fn_applicable_cbas', { p_contract: contractId, p_on: on }),
  })

export const useCompanyAbsenteeism = (companyId?: string, year?: number) =>
  useQuery({
    enabled: !!companyId && !!year,
    queryKey: ['absenteeism', companyId, year],
    queryFn: () =>
      callEngine<Absenteeism>('fn_company_absenteeism', { p_company: companyId, p_year: year }),
  })

/* --------------------------------------- statuts proteges et eligibilite */

export const useEmployeeStatuses = (employeeId?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['employee-statuses', employeeId],
    queryFn: async () =>
      unwrap(
        await supabase.from('employee_statuses').select('*')
          .eq('employee_id', employeeId!).order('start_date', { ascending: false }),
      ),
  })

export const useCreateEmployeeStatus = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: Tables['employee_statuses']['Insert']) =>
      unwrap<EmployeeStatus>(await supabase.from('employee_statuses').insert(v).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['employee-statuses'] })
      qc.invalidateQueries({ queryKey: ['protections'] })
      qc.invalidateQueries({ queryKey: ['vigilance'] })
    },
  })
}

export const useDismissalProtections = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['protections', employeeId, on],
    queryFn: () =>
      callEngine<DismissalProtections>('fn_dismissal_protections', { p_employee: employeeId, p_on: on }),
  })

export const useOvertimeEligibility = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['overtime-eligibility', employeeId, on],
    queryFn: () =>
      callEngine<OvertimeEligibility>('fn_overtime_eligibility', { p_employee: employeeId, p_on: on }),
  })

export const useDelegationEligibility = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['delegation-eligibility', employeeId, on],
    queryFn: () =>
      callEngine<DelegationEligibility>('fn_delegation_eligibility', { p_employee: employeeId, p_on: on }),
  })

export const useQualification = (employeeId?: string, on?: string) =>
  useQuery({
    enabled: !!employeeId,
    queryKey: ['qualification', employeeId, on],
    queryFn: () => callEngine<Qualification>('fn_is_qualified', { p_employee: employeeId, p_on: on }),
  })

/* ------------------------------------------------------------- documents */

export const useDocumentTypes = () =>
  useQuery({
    queryKey: ['document-types'],
    staleTime: 300000,
    queryFn: async () => unwrap(await supabase.from('document_types').select('*').order('label')),
  })

export const useEndOfContractDocuments = (contractId?: string) =>
  useQuery({
    enabled: !!contractId,
    queryKey: ['eoc-documents', contractId],
    queryFn: () =>
      callEngine<EndOfContractDocuments>('fn_end_of_contract_documents', { p_contract: contractId }),
  })

/* ---------------------------------------------- referentiel : couverture */

export const useReferentialGaps = (since?: string) =>
  useQuery({
    queryKey: ['referential-gaps', since],
    queryFn: () => callEngine<ReferentialGap[]>('fn_referential_gaps', { p_since: since }),
  })

export const useReferentialHoles = () =>
  useQuery({
    queryKey: ['referential-holes'],
    queryFn: () =>
      callEngine<{ param_key: string; gap_from: string; gap_to: string }[]>('fn_referential_holes'),
  })

export const useReferentialInconsistencies = (on?: string) =>
  useQuery({
    queryKey: ['referential-inconsistencies', on],
    queryFn: () =>
      callEngine<ReferentialInconsistency[]>('fn_referential_inconsistencies', { p_on: on }),
  })

export const useAddParameterVersion = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (v: {
      key: string
      from: string
      valueNum?: number | null
      valueText?: string | null
      source?: string
      indexRef?: number | null
      note?: string | null
    }) =>
      callEngine('fn_add_parameter_version', {
        p_key: v.key,
        p_valid_from: v.from,
        p_value_num: v.valueNum ?? null,
        p_value_text: v.valueText ?? null,
        p_source: v.source ?? 'CCSS',
        p_index_ref: v.indexRef ?? null,
        p_note: v.note ?? null,
      }),
    onSuccess: () => qc.invalidateQueries(),
  })
}

export const useSeedDemo = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: () => callEngine<{ message: string }>('fn_seed_demo'),
    onSuccess: () => qc.invalidateQueries(),
  })
}
