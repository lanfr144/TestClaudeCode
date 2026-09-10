import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { supabase } from '@/lib/supabase'
import {
  useCompany, useContractCompliance, useCreateContract, useEmployees,
  useLegalParameters, useUpdateContract,
} from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, SeverityMark,
} from '@/components/ui'
import { currentCbas, date, eur, num } from '@/lib/format'

const STEPS = ['Employé', 'Poste & rémunération', 'Temps de travail', 'Essai & durée', 'Relecture'] as const

type Draft = {
  employee_id: string
  new_employee: boolean
  first_name: string
  last_name: string
  birth_date: string
  residency: 'resident' | 'frontalier_fr' | 'frontalier_be' | 'frontalier_de'
  qualification: 'qualified' | 'unqualified'
  national_id: string
  iban: string
  kind: 'cdi' | 'cdd'
  job_title: string
  job_description: string
  work_place: string
  category: string
  monthly_gross: string
  start_date: string
  end_date: string
  cdd_reason: string
  weekly_hours: string
  days_per_week: string
  work_distribution: string
  reference_period_months: string
  night_work: boolean
  annual_leave_days: string
  break_minutes: string
  non_compete_clause: boolean
  exclusivity_clause: boolean
  probation_length: string
  probation_unit: 'weeks' | 'months'
}

const EMPTY: Draft = {
  employee_id: '', new_employee: true, first_name: '', last_name: '', birth_date: '',
  residency: 'resident', qualification: 'qualified', national_id: '', iban: '',
  kind: 'cdi', job_title: '', job_description: '', work_place: '', category: '',
  monthly_gross: '', start_date: '', end_date: '', cdd_reason: '',
  weekly_hours: '40', days_per_week: '5', work_distribution: '5 jours sur 7, horaires variables',
  reference_period_months: '4', night_work: false, annual_leave_days: '', break_minutes: '30',
  non_compete_clause: false, exclusivity_clause: false, probation_length: '3', probation_unit: 'months',
}

export default function ContractWizard() {
  const { activeCompanyId, referenceDate } = useApp()
  const navigate = useNavigate()
  const [step, setStep] = useState(0)
  const [d, setD] = useState<Draft>(EMPTY)
  const [contractId, setContractId] = useState<string | null>(null)
  const [savedAt, setSavedAt] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<unknown>(null)

  const company = useCompany(activeCompanyId ?? undefined)
  const employees = useEmployees(activeCompanyId ?? undefined)
  const params = useLegalParameters()
  const compliance = useContractCompliance(contractId ?? undefined, referenceDate)
  const createContract = useCreateContract()
  const updateContract = useUpdateContract()

  const set = <K extends keyof Draft>(k: K, v: Draft[K]) => setD((p) => ({ ...p, [k]: v }))

  const cddReasons =
    (params.data?.find((p) => p.param_key === 'cdd_reasons')?.value_json as unknown as string[] | undefined) ?? []
  const legalWeekly = params.data?.find((p) => p.param_key === 'normal_weekly_hours' && !p.valid_to)
  const maxPrl = params.data?.find((p) => p.param_key === 'max_reference_period_months' && !p.valid_to)
  const minLeave = params.data?.find((p) => p.param_key === 'annual_leave_min_days' && !p.valid_to)
  const breakThreshold = params.data?.find((p) => p.param_key === 'break_threshold_hours' && !p.valid_to)

  function toPayload() {
    return {
      company_id: activeCompanyId!,
      employee_id: d.employee_id,
      kind: d.kind,
      status: 'draft' as const,
      job_title: d.job_title || 'Poste à préciser',
      job_description: d.job_description || null,
      work_place: d.work_place || null,
      category: d.category || null,
      start_date: d.start_date || referenceDate,
      end_date: d.kind === 'cdd' ? d.end_date || null : null,
      cdd_reason: d.kind === 'cdd' ? d.cdd_reason || null : null,
      monthly_gross: Number(d.monthly_gross || 0),
      weekly_hours: Number(d.weekly_hours || 40),
      days_per_week: Number(d.days_per_week || 5),
      work_distribution: d.work_distribution || null,
      reference_period_months: Number(d.reference_period_months || 4),
      night_work: d.night_work,
      annual_leave_days: d.annual_leave_days ? Number(d.annual_leave_days) : null,
      break_minutes: d.break_minutes ? Number(d.break_minutes) : null,
      non_compete_clause: d.non_compete_clause,
      exclusivity_clause: d.exclusivity_clause,
      probation_length: d.probation_length ? Number(d.probation_length) : null,
      probation_unit: d.probation_length ? d.probation_unit : null,
      index_ref: Number(params.data?.find((p) => p.param_key === 'wage_index' && !p.valid_to)?.value_num ?? 0) || null,
    }
  }

  /** Le brouillon vit côté serveur : c'est lui que le moteur évalue. */
  async function saveDraft() {
    setBusy(true)
    setErr(null)
    try {
      let employeeId = d.employee_id
      if (d.new_employee && !employeeId) {
        const { data: emp, error } = await supabase
          .from('employees')
          .insert({
            company_id: activeCompanyId!,
            first_name: d.first_name,
            last_name: d.last_name,
            birth_date: d.birth_date || null,
            residency: d.residency,
            qualification: d.qualification,
          })
          .select()
          .single()
        if (error) throw new Error(error.message)
        employeeId = emp.id
        set('employee_id', employeeId)
        if (d.national_id || d.iban) {
          const { error: e2 } = await supabase.rpc('fn_set_employee_sensitive', {
            p_employee: employeeId,
            p_national_id: d.national_id || '',
            p_iban: d.iban || '',
          })
          if (e2) throw new Error(e2.message)
        }
      }
      const payload = { ...toPayload(), employee_id: employeeId }
      if (contractId) await updateContract.mutateAsync({ id: contractId, ...payload })
      else {
        const created = await createContract.mutateAsync(payload)
        setContractId(created.id)
      }
      setSavedAt(new Date().toLocaleTimeString('fr-LU', { hour: '2-digit', minute: '2-digit' }))
      return true
    } catch (e) {
      setErr(e)
      return false
    } finally {
      setBusy(false)
    }
  }

  async function next() {
    if (await saveDraft()) setStep((s) => Math.min(STEPS.length - 1, s + 1))
  }

  async function validate() {
    if (!contractId) return
    setBusy(true)
    setErr(null)
    try {
      await updateContract.mutateAsync({ id: contractId, status: 'active', signed_at: referenceDate })
      navigate(`/contrats/${contractId}`)
    } catch (e) {
      setErr(e)
    } finally {
      setBusy(false)
    }
  }

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-xl font-bold tracking-tight text-ink">
          Assistant de création de contrat — étape {step + 1} / {STEPS.length}
        </h1>
        <p className="text-xs text-ink-muted">
          {savedAt ? `Brouillon enregistré à ${savedAt}` : 'Brouillon non enregistré'} ·{' '}
          <button onClick={() => navigate('/contrats')} className="font-semibold text-action hover:underline">
            Quitter l’assistant
          </button>
        </p>
      </header>

      <ol className="flex flex-wrap gap-1.5">
        {STEPS.map((s, i) => (
          <li key={s}>
            <button
              onClick={() => i < step && setStep(i)}
              disabled={i > step}
              className={`flex min-h-[36px] items-center gap-2 rounded border px-3 text-sm ${
                i === step
                  ? 'border-violet bg-violet-veil font-semibold text-violet-deep'
                  : i < step
                    ? 'border-rule bg-white text-ink-body'
                    : 'border-rule bg-white text-ink-faint'
              }`}
            >
              <span aria-hidden>{i < step ? '✓' : i + 1}</span>
              {s}
            </button>
          </li>
        ))}
      </ol>

      <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
        <Card>
          <ErrorNote error={err} />

          {step === 0 && (
            <div className="space-y-4">
              <div className="flex gap-2">
                {[
                  { v: true, l: 'Nouveau salarié' },
                  { v: false, l: 'Salarié existant' },
                ].map((o) => (
                  <button
                    key={String(o.v)}
                    onClick={() => set('new_employee', o.v)}
                    className={`min-h-[44px] flex-1 rounded border px-3 text-sm font-medium ${
                      d.new_employee === o.v
                        ? 'border-violet bg-violet-veil text-violet-deep'
                        : 'border-rule-strong hover:bg-rule-rail'
                    }`}
                  >
                    {o.l}
                  </button>
                ))}
              </div>

              {d.new_employee ? (
                <div className="grid gap-4 sm:grid-cols-2">
                  <Field label="Prénom" required>
                    <Input value={d.first_name} onChange={(e) => set('first_name', e.target.value)} />
                  </Field>
                  <Field label="Nom" required>
                    <Input value={d.last_name} onChange={(e) => set('last_name', e.target.value)} />
                  </Field>
                  <Field label="Date de naissance">
                    <Input type="date" value={d.birth_date} onChange={(e) => set('birth_date', e.target.value)} />
                  </Field>
                  <Field
                    label="Matricule national"
                    hint="13 chiffres. La clé de contrôle est vérifiée à l’enregistrement ; la valeur est chiffrée au repos."
                  >
                    <Input
                      value={d.national_id}
                      onChange={(e) => set('national_id', e.target.value)}
                      placeholder="1994 03 18 227 xx"
                    />
                  </Field>
                  <Field label="Résidence" required hint="Détermine le régime fiscal applicable.">
                    <Select value={d.residency} onChange={(e) => set('residency', e.target.value as Draft['residency'])}>
                      <option value="resident">Résident</option>
                      <option value="frontalier_fr">Frontalier (FR)</option>
                      <option value="frontalier_be">Frontalier (BE)</option>
                      <option value="frontalier_de">Frontalier (DE)</option>
                    </Select>
                  </Field>
                  <Field label="Qualification" required hint="Détermine le salaire social minimum applicable.">
                    <Select
                      value={d.qualification}
                      onChange={(e) => set('qualification', e.target.value as Draft['qualification'])}
                    >
                      <option value="qualified">Qualifié(e)</option>
                      <option value="unqualified">Non qualifié(e)</option>
                    </Select>
                  </Field>
                  <Field label="IBAN" hint="Chiffré au repos.">
                    <Input value={d.iban} onChange={(e) => set('iban', e.target.value)} placeholder="LU28 ..." />
                  </Field>
                </div>
              ) : (
                <Field label="Salarié" required>
                  <Select value={d.employee_id} onChange={(e) => set('employee_id', e.target.value)}>
                    <option value="">Choisir…</option>
                    {(employees.data ?? []).map((e) => (
                      <option key={e.id} value={e.id}>
                        {e.last_name} {e.first_name}
                      </option>
                    ))}
                  </Select>
                </Field>
              )}
            </div>
          )}

          {step === 1 && (
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Type de contrat" required>
                <Select value={d.kind} onChange={(e) => set('kind', e.target.value as Draft['kind'])}>
                  <option value="cdi">CDI — durée indéterminée</option>
                  <option value="cdd">CDD — durée déterminée</option>
                </Select>
              </Field>
              <Field label="Intitulé du poste" required>
                <Input value={d.job_title} onChange={(e) => set('job_title', e.target.value)} />
              </Field>
              <Field label="Description de l’emploi" hint="Mention obligatoire au contrat.">
                <Input value={d.job_description} onChange={(e) => set('job_description', e.target.value)} />
              </Field>
              <Field label="Lieu de travail" hint="Mention obligatoire au contrat.">
                <Input
                  value={d.work_place}
                  onChange={(e) => set('work_place', e.target.value)}
                  placeholder={`${company.data?.address_line ?? ''} ${company.data?.city ?? ''}`.trim()}
                />
              </Field>
              <Field
                label="Catégorie de la grille conventionnelle"
                hint={
                  currentCbas(company.data?.company_collective_agreements, referenceDate)
                    .map((l) => l.collective_agreements?.name)
                    .join(' · ') || 'Aucune convention rattachée à cette société'
                }
              >
                <Input value={d.category} onChange={(e) => set('category', e.target.value)} placeholder="A, B, C…" />
              </Field>
              <Field label="Rémunération mensuelle brute (€)" required>
                <Input
                  type="number" step="0.01"
                  value={d.monthly_gross}
                  onChange={(e) => set('monthly_gross', e.target.value)}
                />
              </Field>
              <Field label="Date de début" required>
                <Input type="date" value={d.start_date} onChange={(e) => set('start_date', e.target.value)} />
              </Field>
              {d.kind === 'cdd' && (
                <>
                  <Field label="Date de fin" required>
                    <Input type="date" value={d.end_date} onChange={(e) => set('end_date', e.target.value)} />
                  </Field>
                  <Field label="Motif de recours" required hint="Un CDD exige un motif figurant dans la liste légale.">
                    <Select value={d.cdd_reason} onChange={(e) => set('cdd_reason', e.target.value)}>
                      <option value="">Choisir un motif…</option>
                      {cddReasons.map((r) => (
                        <option key={r} value={r}>{r}</option>
                      ))}
                    </Select>
                  </Field>
                </>
              )}
            </div>
          )}

          {step === 2 && (
            <div className="grid gap-4 sm:grid-cols-2">
              <Field
                label="Durée hebdomadaire (h)" required
                hint={`Durée normale légale : ${num(legalWeekly?.value_num, 0)} h/semaine.`}
              >
                <Input
                  type="number" step="0.5"
                  value={d.weekly_hours} onChange={(e) => set('weekly_hours', e.target.value)}
                />
              </Field>
              <Field label="Répartition" hint="Mention obligatoire au contrat.">
                <Input value={d.work_distribution} onChange={(e) => set('work_distribution', e.target.value)} />
              </Field>
              <Field
                label="Période de référence (mois)"
                hint={`Maximum légal : ${num(maxPrl?.value_num, 0)} mois.`}
              >
                <Select
                  value={d.reference_period_months}
                  onChange={(e) => set('reference_period_months', e.target.value)}
                >
                  {[1, 2, 3, 4].map((m) => (
                    <option key={m} value={m}>{m} mois</option>
                  ))}
                </Select>
              </Field>
              <Field
                label="Congé annuel (jours ouvrables)" required
                hint={`Minimum légal : ${num(minLeave?.value_num, 0)} jours. La CCT peut être plus favorable.`}
              >
                <Input
                  type="number" step="0.5"
                  value={d.annual_leave_days} onChange={(e) => set('annual_leave_days', e.target.value)}
                />
              </Field>
              <Field
                label="Pause journalière (min)"
                hint={`Obligatoire au-delà de ${num(breakThreshold?.value_num, 0)} h. Durée renvoyée à la CCT ou au contrat.`}
              >
                <Input
                  type="number"
                  value={d.break_minutes} onChange={(e) => set('break_minutes', e.target.value)}
                />
              </Field>
              <Field label="Travail de nuit">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.night_work}
                    onChange={(e) => set('night_work', e.target.checked)}
                  />
                  Le poste comporte du travail de nuit
                </label>
              </Field>
            </div>
          )}

          {step === 3 && (
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Durée de la période d’essai">
                <Input
                  type="number"
                  value={d.probation_length} onChange={(e) => set('probation_length', e.target.value)}
                />
              </Field>
              <Field label="Unité">
                <Select
                  value={d.probation_unit}
                  onChange={(e) => set('probation_unit', e.target.value as Draft['probation_unit'])}
                >
                  <option value="months">mois</option>
                  <option value="weeks">semaines</option>
                </Select>
              </Field>
              <Field label="Clause de non-concurrence">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.non_compete_clause}
                    onChange={(e) => set('non_compete_clause', e.target.checked)}
                  />
                  Le contrat en comporte une
                </label>
              </Field>
              <Field label="Clause d’exclusivité">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.exclusivity_clause}
                    onChange={(e) => set('exclusivity_clause', e.target.checked)}
                  />
                  Le contrat en comporte une
                </label>
              </Field>

              {compliance.data?.probation && (
                <div className="sm:col-span-2">
                  <LegalBasis
                    reference={compliance.data.probation.legal_ref}
                    text="Le préavis d’essai doit expirer au plus tard le dernier jour de la période d’essai."
                    value={`fin d’essai le ${date(compliance.data.probation.end)}`}
                    validity={`préavis de ${compliance.data.probation.notice_days} jours`}
                    source="Legilux"
                  />
                  <p className="mt-2 rounded border border-warn/30 bg-warn-veil px-3 py-2 text-sm font-semibold text-warn-ink">
                    Dernier jour pour notifier une résiliation :{' '}
                    {date(compliance.data.probation.last_day_to_notify)}
                  </p>
                </div>
              )}
            </div>
          )}

          {step === 4 && (
            <div className="space-y-3">
              <h2 className="text-base font-semibold text-ink">Relecture</h2>
              <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-2">
                {[
                  ['Type', d.kind.toUpperCase()],
                  ['Poste', d.job_title],
                  ['Début', date(d.start_date)],
                  ['Fin', d.kind === 'cdd' ? date(d.end_date) : '—'],
                  ['Brut mensuel', eur(d.monthly_gross)],
                  ['Durée hebdomadaire', `${d.weekly_hours} h`],
                  ['Congé annuel', `${d.annual_leave_days || '—'} j`],
                  ['Essai', d.probation_length ? `${d.probation_length} ${d.probation_unit === 'months' ? 'mois' : 'semaines'}` : '—'],
                ].map(([k, v]) => (
                  <div key={k} className="flex justify-between gap-3 border-b border-rule py-1">
                    <dt className="text-ink-muted">{k}</dt>
                    <dd className="font-medium text-ink">{v}</dd>
                  </div>
                ))}
              </dl>
              {compliance.data && !compliance.data.can_validate && (
                <p className="rounded border border-danger/30 bg-danger-veil px-3 py-2 text-xs text-danger-ink">
                  Ce contrat porte {compliance.data.blocking_count} non-conformité(s) bloquante(s). La
                  validation est refusée tant qu’elles subsistent.
                </p>
              )}
            </div>
          )}

          <div className="mt-5 flex items-center justify-between gap-2 border-t border-rule pt-4">
            <Button size="sm" onClick={() => setStep((s) => Math.max(0, s - 1))} disabled={step === 0}>
              ← Précédent
            </Button>
            <div className="flex gap-2">
              <Button size="sm" onClick={saveDraft} disabled={busy}>
                Enregistrer le brouillon
              </Button>
              {step < STEPS.length - 1 ? (
                <Button size="sm" variant="primary" onClick={next} disabled={busy}>
                  {busy ? 'Enregistrement…' : 'Continuer →'}
                </Button>
              ) : (
                <Button
                  size="sm" variant="primary" onClick={validate}
                  disabled={busy || !compliance.data?.can_validate}
                >
                  Valider le contrat
                </Button>
              )}
            </div>
          </div>
        </Card>

        {/* Conformité en direct — évaluée par le serveur à chaque enregistrement. */}
        <aside className="space-y-3">
          <Card
            dense
            title={
              <span className="flex items-center gap-2">
                Conformité en direct
                {compliance.data && compliance.data.blocking_count > 0 && (
                  <Badge tone="blocking">{compliance.data.blocking_count} blocage</Badge>
                )}
                {compliance.data && compliance.data.blocking_count === 0 && compliance.data.warning_count > 0 && (
                  <Badge tone="warning">{compliance.data.warning_count} attention</Badge>
                )}
              </span>
            }
          >
            {!contractId && (
              <p className="px-4 py-4 text-xs text-ink-muted">
                Enregistrez le brouillon pour lancer les contrôles de conformité.
              </p>
            )}
            {compliance.isLoading && <Loading />}
            <ul className="divide-y divide-rule">
              {(compliance.data?.checks ?? []).map((c) => (
                <li key={c.code} className="flex items-start gap-2.5 px-4 py-2.5">
                  <SeverityMark severity={c.severity} />
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink">{c.label}</p>
                    <p className="text-xs text-ink-muted">{c.detail}</p>
                    {c.legal_ref && (
                      <span className="mt-1 inline-block font-mono text-2xs text-ink-faint">{c.legal_ref}</span>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </Card>

          <Card title="Mentions obligatoires" dense>
            <ul className="divide-y divide-rule">
              {(compliance.data?.mandatory_mentions ?? []).map((m) => (
                <li key={m.label} className="flex items-center gap-2 px-4 py-2 text-sm">
                  <span className={m.ok ? 'text-success' : 'text-ink-faint'}>{m.ok ? '✓' : '○'}</span>
                  <span className={m.ok ? 'text-ink-body' : 'text-ink-muted'}>{m.label}</span>
                </li>
              ))}
              {!compliance.data && (
                <li className="px-4 py-3 text-xs text-ink-muted">
                  La liste s’active dès le premier enregistrement.
                </li>
              )}
            </ul>
          </Card>
        </aside>
      </div>
    </div>
  )
}
