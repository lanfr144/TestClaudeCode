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
export type Company = Tables['societes']['Row']
export type Employee = Tables['salaries']['Row']
export type Contract = Tables['contrats']['Row']
export type Absence = Tables['absences']['Row']
export type AbsenceType = Tables['types_absence']['Row']
export type Shift = Tables['creneaux']['Row']
export type Schedule = Tables['plannings']['Row']
export type ShiftTemplate = Tables['modeles_creneau']['Row']
export type LegalParameter = Tables['parametres_legaux']['Row']
export type CollectiveAgreement = Tables['conventions_collectives']['Row']
export type TimeEntry = Tables['releves_temps']['Row']
export type Department = Tables['services']['Row']

export type CompanyRatePeriod = Tables['periodes_taux_societe']['Row']
export type CbaRule = Tables['regles_convention']['Row']
export type ContractAmendment = Tables['avenants_contrat']['Row']
export type DocumentRow = Tables['documents']['Row']
export type EmployeeTaxCard = Tables['fiches_retenue_impot']['Row']
export type EmployeeStatus = Tables['statuts_salarie']['Row']

/**
 * Au-delà de deux niveaux de jointure, l'inférence de supabase-js sature et
 * retombe sur `never`. Les requêtes de détail portent donc leur type explicite.
 */
export type CompanyCbaLink = Tables['conventions_de_la_societe']['Row'] & {
  conventions_collectives: (CollectiveAgreement & { regles_convention: CbaRule[] }) | null
}

export type CompanyListRow = Company & {
  conventions_de_la_societe: {
    debut_validite: string
    fin_validite: string | null
    conventions_collectives: { nom: string; code: string; secteur: string; portee: string } | null
  }[]
}

export type CompanyDetailRow = Company & {
  services: Department[]
  periodes_taux_societe: CompanyRatePeriod[]
  conventions_de_la_societe: CompanyCbaLink[]
}

export type ContractDetailRow = Contract & {
  salaries: Employee | null
  societes: Company | null
  avenants_contrat: ContractAmendment[]
  conventions_du_contrat: {
    id: string
    debut_validite: string
    fin_validite: string | null
    conventions_collectives: { nom: string; code: string; portee: string } | null
  }[]
}

export type EmployeeDetailRow = Employee & {
  services: { nom: string } | null
  fiches_retenue_impot: EmployeeTaxCard[]
  contrats: Contract[]
  documents: DocumentRow[]
}

export type EmployeeListRow = Employee & {
  services: { nom: string } | null
  contrats: Pick<
    Contract,
    | 'id' | 'genre' | 'statut' | 'intitule_poste' | 'date_debut' | 'date_fin'
    | 'duree_essai' | 'unite_essai' | 'heures_hebdomadaires' | 'brut_mensuel'
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
        .from('profils')
        .select('*, organisations(*)')
        .eq('id', auth.user.id)
        .maybeSingle()
      if (error) throw new Error(error.message)
      if (!profile) return null
      const roles = unwrap(await supabase.from('roles_compte').select('*'))
      const self = unwrap(
        await supabase.from('salaries').select('id, societe_id').eq('compte_id', auth.user.id).maybeSingle(),
      ) as { id: string; societe_id: string } | null
      return { ...profile, roles, selfEmployee: self }
    },
  })

export const useCompanies = () =>
  useQuery({
    queryKey: ['societes'],
    queryFn: async () =>
      unwrap<CompanyListRow[]>(
        await supabase.from('societes')
          .select('*, conventions_de_la_societe(debut_validite, fin_validite, conventions_collectives(nom, code, secteur, portee))')
          .order('raison_sociale'),
      ),
  })

export const useCompany = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['company', id],
    queryFn: async () =>
      unwrap<CompanyDetailRow>(
        await supabase.from('societes')
          .select('*, services(*), periodes_taux_societe(*), conventions_de_la_societe(*, conventions_collectives(*, regles_convention(*)))')
          .eq('id', id!).single(),
      ),
  })

/* -------------------------------------------------------------- employes */

export const useEmployees = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['salaries', companyId],
    queryFn: async () =>
      unwrap<EmployeeListRow[]>(
        await supabase.from('salaries')
          .select(
            '*, services(nom), contrats(id, genre, statut, intitule_poste, date_debut, date_fin, duree_essai, unite_essai, heures_hebdomadaires, brut_mensuel)',
          )
          .eq('societe_id', companyId!).order('nom'),
      ),
  })

export const useEmployee = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['employee', id],
    queryFn: async () =>
      unwrap<EmployeeDetailRow>(
        await supabase.from('salaries')
          .select('*, services(nom), fiches_retenue_impot(*), contrats(*), documents(*)')
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
      const rows = await callEngine<{ matricule_national: string | null; iban: string | null }[]>(
        'fn_employee_sensitive', { p_employee: id },
      )
      return rows?.[0] ?? null
    },
  })

/* -------------------------------------------------------------- contrats */

export const useContracts = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['contrats', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('contrats')
          .select('*, salaries(prenom, nom)')
          .eq('societe_id', companyId!).order('date_debut', { ascending: false }),
      ),
  })

export const useContract = (id?: string) =>
  useQuery({
    enabled: !!id,
    queryKey: ['contract', id],
    queryFn: async () =>
      unwrap<ContractDetailRow>(
        await supabase.from('contrats')
          .select('*, salaries(*), societes(*), avenants_contrat(*), conventions_du_contrat(*, conventions_collectives(nom, code, portee))')
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
    mutationFn: async (c: Tables['contrats']['Insert']) =>
      unwrap<Contract>(await supabase.from('contrats').insert(c).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['contrats'] })
      qc.invalidateQueries({ queryKey: ['salaries'] })
    },
  })
}

export const useUpdateContract = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...patch }: Tables['contrats']['Update'] & { id: string }) =>
      unwrap<Contract>(await supabase.from('contrats').update(patch).eq('id', id).select().single()),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['contract'] })
      qc.invalidateQueries({ queryKey: ['contrats'] })
      qc.invalidateQueries({ queryKey: ['contract-compliance'] })
    },
  })
}

/* -------------------------------------------------------------- planning */

export const useSchedules = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['plannings', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('plannings').select('*').eq('societe_id', companyId!)
          .order('debut_semaine', { ascending: false }),
      ),
  })

export const useSchedule = (companyId?: string, weekStart?: string) =>
  useQuery({
    enabled: !!companyId && !!weekStart,
    queryKey: ['schedule', companyId, weekStart],
    queryFn: async () => {
      const schedule = unwrap<Schedule | null>(
        await supabase.from('plannings').select('*')
          .eq('societe_id', companyId!).eq('debut_semaine', weekStart!).maybeSingle(),
      )
      if (!schedule) return { schedule: null, creneaux: [] as ShiftWithEmployee[] }
      const creneaux = unwrap(
        await supabase.from('creneaux')
          .select('*, salaries(id, prenom, nom)')
          .eq('planning_id', schedule.id)
          .order('date_creneau').order('heure_debut'),
      ) as unknown as ShiftWithEmployee[]
      return { schedule, creneaux }
    },
  })

export type ShiftWithEmployee = Shift & {
  salaries: { id: string; prenom: string; nom: string } | null
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
        await supabase.from('modeles_creneau').select('*').eq('societe_id', companyId!).order('heure_debut'),
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
    mutationFn: async (s: Tables['plannings']['Insert']) =>
      unwrap<Schedule>(await supabase.from('plannings').insert(s).select().single()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['schedule'] }),
  })
}

export const useUpsertShift = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (shift: Tables['creneaux']['Insert']) =>
      unwrap<Shift>(await supabase.from('creneaux').upsert(shift).select().single()),
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
      const { error } = await supabase.from('creneaux').delete().eq('id', id)
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
    queryFn: async () => unwrap(await supabase.from('types_absence').select('*').order('libelle')),
  })

export type AbsenceEntitlement = Tables['droits_absence']['Row']

export type AbsenceRow = Absence & {
  salaries: { id: string; prenom: string; nom: string } | null
  types_absence: (AbsenceType & { droits_absence: AbsenceEntitlement[] }) | null
}

export const useAbsences = (companyId?: string) =>
  useQuery({
    enabled: !!companyId,
    queryKey: ['absences', companyId],
    queryFn: async () =>
      unwrap(
        await supabase.from('absences')
          .select('*, salaries(id, prenom, nom), types_absence(*, droits_absence(*))')
          .eq('societe_id', companyId!).order('date_debut', { ascending: false }),
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
            statut: v.status,
            decide_le: new Date().toISOString(),
            decide_par: auth.user?.id ?? null,
            note_decision: v.note ?? null,
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
          .update({ certificat_recu: true, certificat_recu_le: new Date().toISOString().slice(0, 10) })
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
    queryKey: ['effectif', companyId, on],
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
        await supabase.from('parametres_legaux').select('*')
          .order('famille').order('cle_parametre').order('debut_validite', { ascending: false }),
      ),
  })

export const useCollectiveAgreements = () =>
  useQuery({
    queryKey: ['cba'],
    queryFn: async () =>
      unwrap(
        await supabase.from('conventions_collectives')
          .select('*, regles_convention(*), grilles_salaires_convention(*)').order('nom'),
      ),
  })

export const usePublicHolidays = (year: number) =>
  useQuery({
    queryKey: ['holidays', year],
    staleTime: 3600000,
    queryFn: async () =>
      unwrap(
        await supabase.from('jours_feries').select('*').eq('annee', year).order('date_ferie'),
      ),
  })

/* ----------------------------------------------------- registre du temps */

export const useTimeEntries = (companyId?: string, from?: string, to?: string) =>
  useQuery({
    enabled: !!companyId && !!from && !!to,
    queryKey: ['time-entries', companyId, from, to],
    queryFn: async () =>
      unwrap(
        await supabase.from('releves_temps')
          .select('*, salaries(prenom, nom)')
          .eq('societe_id', companyId!).gte('date_releve', from!).lte('date_releve', to!)
          .order('date_releve', { ascending: false }),
      ),
  })

export const useUpsertTimeEntry = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (e: Tables['releves_temps']['Insert']) =>
      unwrap(
        await supabase.from('releves_temps')
          .upsert(e, { onConflict: 'salarie_id,date_releve' }).select().single(),
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
        await supabase.from('journal_ecritures').select('*').eq('societe_id', companyId!)
          .order('survenu_le', { ascending: false }).limit(200),
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
        await supabase.from('statuts_salarie').select('*')
          .eq('salarie_id', employeeId!).order('date_debut', { ascending: false }),
      ),
  })

export const useCreateEmployeeStatus = () => {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: Tables['statuts_salarie']['Insert']) =>
      unwrap<EmployeeStatus>(await supabase.from('statuts_salarie').insert(v).select().single()),
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
    queryFn: async () => unwrap(await supabase.from('types_document').select('*').order('libelle')),
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
      callEngine<{ cle_parametre: string; trou_du: string; trou_au: string }[]>('fn_referential_holes'),
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
