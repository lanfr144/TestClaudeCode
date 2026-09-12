import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { callEngine, supabase } from '@/lib/supabase'
import {
  useCompany, useContractCompliance, useCreateContract, useEmployees,
  useLegalParameters, useUpdateContract,
} from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, SeverityMark,
} from '@/components/ui'
import { currentCbas, date, estEnVigueur, eur, num } from '@/lib/format'

const STEPS = ['Employé', 'Poste & rémunération', 'Temps de travail', 'Essai & durée', 'Relecture'] as const

type Draft = {
  salarie_id: string
  new_employee: boolean
  prenom: string
  nom: string
  date_naissance: string
  residence: 'resident' | 'frontalier_fr' | 'frontalier_be' | 'frontalier_de'
  qualification: 'qualified' | 'unqualified'
  matricule_national: string
  iban: string
  genre: 'cdi' | 'cdd'
  intitule_poste: string
  description_poste: string
  lieu_travail: string
  categorie: string
  brut_mensuel: string
  date_debut: string
  date_fin: string
  motif_cdd: string
  heures_hebdomadaires: string
  jours_par_semaine: string
  repartition_travail: string
  periode_reference_mois: string
  travail_nuit: boolean
  jours_conge_annuel: string
  pause_minutes: string
  clause_non_concurrence: boolean
  clause_exclusivite: boolean
  duree_essai: string
  unite_essai: 'weeks' | 'mois'
}

const EMPTY: Draft = {
  salarie_id: '', new_employee: true, prenom: '', nom: '', date_naissance: '',
  residence: 'resident', qualification: 'qualified', matricule_national: '', iban: '',
  genre: 'cdi', intitule_poste: '', description_poste: '', lieu_travail: '', categorie: '',
  brut_mensuel: '', date_debut: '', date_fin: '', motif_cdd: '',
  heures_hebdomadaires: '40', jours_par_semaine: '5', repartition_travail: '5 jours sur 7, horaires variables',
  periode_reference_mois: '4', travail_nuit: false, jours_conge_annuel: '', pause_minutes: '30',
  clause_non_concurrence: false, clause_exclusivite: false, duree_essai: '3', unite_essai: 'mois',
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
  const salaries = useEmployees(activeCompanyId ?? undefined)
  const params = useLegalParameters()
  const compliance = useContractCompliance(contractId ?? undefined, referenceDate)
  const createContract = useCreateContract()
  const updateContract = useUpdateContract()

  const set = <K extends keyof Draft>(k: K, v: Draft[K]) => setD((p) => ({ ...p, [k]: v }))

  const cddReasons =
    (params.data?.find((p) => p.cle_parametre === 'cdd_reasons')?.valeur_json as unknown as string[] | undefined) ?? []
  const legalWeekly = params.data?.find(
    (p) => p.cle_parametre === 'normal_weekly_hours' && estEnVigueur(p, referenceDate),
  )
  const maxPrl = params.data?.find(
    (p) => p.cle_parametre === 'max_reference_period_months' && estEnVigueur(p, referenceDate),
  )
  const minLeave = params.data?.find(
    (p) => p.cle_parametre === 'annual_leave_min_days' && estEnVigueur(p, referenceDate),
  )
  const breakThreshold = params.data?.find(
    (p) => p.cle_parametre === 'break_threshold_hours' && estEnVigueur(p, referenceDate),
  )

  function toPayload() {
    return {
      societe_id: activeCompanyId!,
      salarie_id: d.salarie_id,
      genre: d.genre,
      statut: 'draft' as const,
      intitule_poste: d.intitule_poste || 'Poste à préciser',
      description_poste: d.description_poste || null,
      lieu_travail: d.lieu_travail || null,
      categorie: d.categorie || null,
      date_debut: d.date_debut || referenceDate,
      date_fin: d.genre === 'cdd' ? d.date_fin || null : null,
      motif_cdd: d.genre === 'cdd' ? d.motif_cdd || null : null,
      brut_mensuel: Number(d.brut_mensuel || 0),
      heures_hebdomadaires: Number(d.heures_hebdomadaires || 40),
      jours_par_semaine: Number(d.jours_par_semaine || 5),
      repartition_travail: d.repartition_travail || null,
      periode_reference_mois: Number(d.periode_reference_mois || 4),
      travail_nuit: d.travail_nuit,
      jours_conge_annuel: d.jours_conge_annuel ? Number(d.jours_conge_annuel) : null,
      pause_minutes: d.pause_minutes ? Number(d.pause_minutes) : null,
      clause_non_concurrence: d.clause_non_concurrence,
      clause_exclusivite: d.clause_exclusivite,
      duree_essai: d.duree_essai ? Number(d.duree_essai) : null,
      unite_essai: d.duree_essai ? d.unite_essai : null,
      indice_reference: Number(params.data?.find((p) => p.cle_parametre === 'wage_index' && estEnVigueur(p, referenceDate))
        ?.valeur_num ?? 0) || null,
    }
  }

  /** Le brouillon vit côté serveur : c'est lui que le moteur évalue. */
  async function saveDraft() {
    setBusy(true)
    setErr(null)
    try {
      let employeeId = d.salarie_id
      if (d.new_employee && !employeeId) {
        const { data: emp, error } = await supabase
          .from('salaries')
          .insert({
            societe_id: activeCompanyId!,
            prenom: d.prenom,
            nom: d.nom,
            date_naissance: d.date_naissance || null,
            residence: d.residence,
            qualification: d.qualification,
          })
          .select()
          .single()
        if (error) throw new Error(error.message)
        employeeId = emp.id
        set('salarie_id', employeeId)
        if (d.matricule_national || d.iban) {
          // Passe par callEngine : le moteur valide le matricule et chiffre les
          // deux champs. Un appel direct laisserait remonter l'erreur PL/pgSQL
          // sous une forme que le reste de l'application ne traite pas.
          await callEngine<void>('fn_set_employee_sensitive', {
            p_employee: employeeId,
            p_national_id: d.matricule_national || '',
            p_iban: d.iban || '',
          })
        }
      }
      const payload = { ...toPayload(), salarie_id: employeeId }
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
      await updateContract.mutateAsync({ id: contractId, statut: 'active', signe_le: referenceDate })
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
                    <Input value={d.prenom} onChange={(e) => set('prenom', e.target.value)} />
                  </Field>
                  <Field label="Nom" required>
                    <Input value={d.nom} onChange={(e) => set('nom', e.target.value)} />
                  </Field>
                  <Field label="Date de naissance">
                    <Input type="date" value={d.date_naissance} onChange={(e) => set('date_naissance', e.target.value)} />
                  </Field>
                  <Field
                    label="Matricule national"
                    hint="13 chiffres. La clé de contrôle est vérifiée à l’enregistrement ; la valeur est chiffrée au repos."
                  >
                    <Input
                      value={d.matricule_national}
                      onChange={(e) => set('matricule_national', e.target.value)}
                      placeholder="1994 03 18 227 xx"
                    />
                  </Field>
                  <Field label="Résidence" required hint="Détermine le régime fiscal applicable.">
                    <Select value={d.residence} onChange={(e) => set('residence', e.target.value as Draft['residence'])}>
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
                  <Select value={d.salarie_id} onChange={(e) => set('salarie_id', e.target.value)}>
                    <option value="">Choisir…</option>
                    {(salaries.data ?? []).map((e) => (
                      <option key={e.id} value={e.id}>
                        {e.nom} {e.prenom}
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
                <Select value={d.genre} onChange={(e) => set('genre', e.target.value as Draft['genre'])}>
                  <option value="cdi">CDI — durée indéterminée</option>
                  <option value="cdd">CDD — durée déterminée</option>
                </Select>
              </Field>
              <Field label="Intitulé du poste" required>
                <Input value={d.intitule_poste} onChange={(e) => set('intitule_poste', e.target.value)} />
              </Field>
              <Field label="Description de l’emploi" hint="Mention obligatoire au contrat.">
                <Input value={d.description_poste} onChange={(e) => set('description_poste', e.target.value)} />
              </Field>
              <Field label="Lieu de travail" hint="Mention obligatoire au contrat.">
                <Input
                  value={d.lieu_travail}
                  onChange={(e) => set('lieu_travail', e.target.value)}
                  placeholder={`${company.data?.ligne ?? ''} ${company.data?.localite ?? ''}`.trim()}
                />
              </Field>
              <Field
                label="Catégorie de la grille conventionnelle"
                hint={
                  currentCbas(company.data?.conventions_de_la_societe, referenceDate)
                    .map((l) => l.conventions_collectives?.nom)
                    .join(' · ') || 'Aucune convention rattachée à cette société'
                }
              >
                <Input value={d.categorie} onChange={(e) => set('categorie', e.target.value)} placeholder="A, B, C…" />
              </Field>
              <Field label="Rémunération mensuelle brute (€)" required>
                <Input
                  type="number" step="0.01"
                  value={d.brut_mensuel}
                  onChange={(e) => set('brut_mensuel', e.target.value)}
                />
              </Field>
              <Field label="Date de début" required>
                <Input type="date" value={d.date_debut} onChange={(e) => set('date_debut', e.target.value)} />
              </Field>
              {d.genre === 'cdd' && (
                <>
                  <Field label="Date de fin" required>
                    <Input type="date" value={d.date_fin} onChange={(e) => set('date_fin', e.target.value)} />
                  </Field>
                  <Field label="Motif de recours" required hint="Un CDD exige un motif figurant dans la liste légale.">
                    <Select value={d.motif_cdd} onChange={(e) => set('motif_cdd', e.target.value)}>
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
                hint={`Durée normale légale : ${num(legalWeekly?.valeur_num, 0)} h/semaine.`}
              >
                <Input
                  type="number" step="0.5"
                  value={d.heures_hebdomadaires} onChange={(e) => set('heures_hebdomadaires', e.target.value)}
                />
              </Field>
              <Field label="Répartition" hint="Mention obligatoire au contrat.">
                <Input value={d.repartition_travail} onChange={(e) => set('repartition_travail', e.target.value)} />
              </Field>
              <Field
                label="Période de référence (mois)"
                hint={`Maximum légal : ${num(maxPrl?.valeur_num, 0)} mois.`}
              >
                <Select
                  value={d.periode_reference_mois}
                  onChange={(e) => set('periode_reference_mois', e.target.value)}
                >
                  {[1, 2, 3, 4].map((m) => (
                    <option key={m} value={m}>{m} mois</option>
                  ))}
                </Select>
              </Field>
              <Field
                label="Congé annuel (jours ouvrables)" required
                hint={`Minimum légal : ${num(minLeave?.valeur_num, 0)} jours. La CCT peut être plus favorable.`}
              >
                <Input
                  type="number" step="0.5"
                  value={d.jours_conge_annuel} onChange={(e) => set('jours_conge_annuel', e.target.value)}
                />
              </Field>
              <Field
                label="Pause journalière (min)"
                hint={`Obligatoire au-delà de ${num(breakThreshold?.valeur_num, 0)} h. Durée renvoyée à la CCT ou au contrat.`}
              >
                <Input
                  type="number"
                  value={d.pause_minutes} onChange={(e) => set('pause_minutes', e.target.value)}
                />
              </Field>
              <Field label="Travail de nuit">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.travail_nuit}
                    onChange={(e) => set('travail_nuit', e.target.checked)}
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
                  value={d.duree_essai} onChange={(e) => set('duree_essai', e.target.value)}
                />
              </Field>
              <Field label="Unité">
                <Select
                  value={d.unite_essai}
                  onChange={(e) => set('unite_essai', e.target.value as Draft['unite_essai'])}
                >
                  <option value="mois">mois</option>
                  <option value="weeks">semaines</option>
                </Select>
              </Field>
              <Field label="Clause de non-concurrence">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.clause_non_concurrence}
                    onChange={(e) => set('clause_non_concurrence', e.target.checked)}
                  />
                  Le contrat en comporte une
                </label>
              </Field>
              <Field label="Clause d’exclusivité">
                <label className="flex min-h-[38px] items-center gap-2 text-sm text-ink-body">
                  <input
                    type="checkbox" checked={d.clause_exclusivite}
                    onChange={(e) => set('clause_exclusivite', e.target.checked)}
                  />
                  Le contrat en comporte une
                </label>
              </Field>

              {compliance.data?.probation && (
                <div className="sm:col-span-2">
                  <LegalBasis
                    reference={compliance.data.probation.reference_legale}
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
                  ['Type', d.genre.toUpperCase()],
                  ['Poste', d.intitule_poste],
                  ['Début', date(d.date_debut)],
                  ['Fin', d.genre === 'cdd' ? date(d.date_fin) : '—'],
                  ['Brut mensuel', eur(d.brut_mensuel)],
                  ['Durée hebdomadaire', `${d.heures_hebdomadaires} h`],
                  ['Congé annuel', `${d.jours_conge_annuel || '—'} j`],
                  ['Essai', d.duree_essai ? `${d.duree_essai} ${d.unite_essai === 'mois' ? 'mois' : 'semaines'}` : '—'],
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
                  <SeverityMark severity={c.severite} />
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink">{c.libelle}</p>
                    <p className="text-xs text-ink-muted">{c.detail}</p>
                    {c.reference_legale && (
                      <span className="mt-1 inline-bloc font-mono text-2xs text-ink-faint">{c.reference_legale}</span>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </Card>

          <Card title="Mentions obligatoires" dense>
            <ul className="divide-y divide-rule">
              {(compliance.data?.mandatory_mentions ?? []).map((m) => (
                <li key={m.libelle} className="flex items-center gap-2 px-4 py-2 text-sm">
                  <span className={m.ok ? 'text-success' : 'text-ink-faint'}>{m.ok ? '✓' : '○'}</span>
                  <span className={m.ok ? 'text-ink-body' : 'text-ink-muted'}>{m.libelle}</span>
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
