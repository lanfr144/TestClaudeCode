import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import {
  useAbsences, useContractCompliance, useDelegationEligibility, useDismissalProtections,
  useEmployee, useEmployeeSensitive, useEmployeeStatuses, useLeaveBalance,
  useOvertimeEligibility, useQualification, useSickCounters,
} from '@/lib/queries'
import {
  ArbitrationPanel, Avatar, Badge, Button, Card, ErrorNote, LegalBasis, Loading, Table,
} from '@/components/ui'
import {
  ABSENCE_STATUS_LABEL, CONTRACT_KIND_LABEL, RESIDENCY_LABEL, SEX_LABEL, STATUS_KIND_LABEL,
  date, eur, initials, num,
} from '@/lib/format'

const TABS = ['Compteurs', 'Statuts & protections', 'Contrats', 'Absences', 'Documents'] as const
type Tab = (typeof TABS)[number]

export default function EmployeeDetail() {
  const { id } = useParams()
  const { referenceDate } = useApp()
  const [tab, setTab] = useState<Tab>('Compteurs')
  const [showSensitive, setShowSensitive] = useState(false)

  const { data: e, isLoading, error } = useEmployee(id)
  const activeContract = e?.contrats?.find((c) => c.statut === 'en_cours') ?? e?.contrats?.[0]
  const compliance = useContractCompliance(activeContract?.id, referenceDate)
  const leave = useLeaveBalance(id, referenceDate)
  const sick = useSickCounters(id, referenceDate)
  const absences = useAbsences(e?.societe_id)
  const sensitive = useEmployeeSensitive(showSensitive ? id : undefined)
  const statuses = useEmployeeStatuses(id)
  const protections = useDismissalProtections(id, referenceDate)
  const overtime = useOvertimeEligibility(id, referenceDate)
  const delegation = useDelegationEligibility(id, referenceDate)
  const qualification = useQualification(id, referenceDate)

  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />
  if (!e) return <Card title="Employé introuvable">Cet employé n’existe pas ou n’est pas accessible.</Card>

  const prob = compliance.data?.probation
  const taxCard = e.fiches_retenue_impot?.find((t) => t.fin_validite > referenceDate)
  const myAbsences = (absences.data ?? []).filter((a) => a.salarie_id === e.id)

  return (
    <div className="space-y-4">
      <div className="lux-card p-4">
        <div className="flex flex-wrap items-start gap-4">
          <Avatar text={initials(e.prenom, e.nom)} />
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-xl font-bold tracking-tight text-ink">
                {e.prenom} {e.nom}
              </h1>
              {prob?.is_running && <Badge tone="warning">En essai</Badge>}
              {activeContract && (
                <Badge tone="neutral">
                  {CONTRACT_KIND_LABEL[activeContract.genre] ?? activeContract.genre}{' '}
                  {activeContract.heures_hebdomadaires} h
                </Badge>
              )}
            </div>
            <p className="mt-0.5 text-sm text-ink-muted">
              {activeContract?.intitule_poste ?? 'Sans contrat actif'}
              {activeContract && ` · entrée le ${date(activeContract.date_debut)}`}
            </p>
          </div>
          {activeContract && (
            <Link to={`/contrats/${activeContract.id}`}>
              <Button size="sm">Ouvrir le contrat</Button>
            </Link>
          )}
        </div>

        <dl className="mt-4 grid gap-3 border-t border-rule pt-3 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <dt className="lux-libelle">Matricule national</dt>
            <dd className="mt-0.5 font-mono text-sm text-ink">
              {showSensitive ? (
                sensitive.isLoading ? '…' : (sensitive.data?.matricule_national ?? '—')
              ) : (
                <>
                  •••• •••• {e.matricule_national_indice ?? '••••'}{' '}
                  <button
                    onClick={() => setShowSensitive(true)}
                    className="ml-1 font-sans text-2xs font-semibold text-action hover:underline"
                  >
                    afficher
                  </button>
                </>
              )}
            </dd>
            {showSensitive && sensitive.error && <ErrorNote error={sensitive.error} />}
          </div>
          <div>
            <dt className="lux-libelle">Résidence</dt>
            <dd className="mt-0.5 text-sm text-ink">{RESIDENCY_LABEL[e.residence]}</dd>
          </div>
          <div>
            <dt className="lux-libelle">Sexe</dt>
            <dd className="mt-0.5 text-sm text-ink">{SEX_LABEL[e.sexe]}</dd>
          </div>
          <div>
            <dt className="lux-libelle">Classe d’impôt</dt>
            <dd className="mt-0.5 text-sm text-ink">{taxCard?.classe_impot ?? '—'}</dd>
          </div>
          <div>
            <dt className="lux-libelle">Qualification</dt>
            <dd className="mt-0.5 text-sm text-ink">
              {qualification.data?.qualified ? 'Qualifié(e)' : 'Non qualifié(e)'}
              {qualification.data && e.qualification === 'non_qualifie' && qualification.data.qualified && (
                <span className="ml-1 text-2xs text-warn-ink">par l’ancienneté</span>
              )}
            </dd>
          </div>
        </dl>
      </div>

      {/* Le dernier jour utile pour notifier une résiliation d'essai, en évidence. */}
      {prob?.is_running && (
        <div className="rounded-md border border-warn/30 bg-warn-veil p-4">
          <p className="text-sm font-bold text-warn-ink">
            Dernier jour pour notifier la rupture d’essai : {date(prob.last_day_to_notify)}
            {prob.days_until_deadline >= 0 && ` · J-${prob.days_until_deadline}`}
          </p>
          <p className="mt-1 text-xs leading-relaxed text-warn-deep">
            Essai du {date(prob.start)} au {date(prob.end)}
            {prob.extension_days > 0 &&
              ` (prolongé de ${prob.extension_days} jour(s) par une incapacité, plafonné à ${prob.extension_cap_days} jours)`}
            . Préavis d’essai de {prob.notice_days} jours devant expirer au plus tard le dernier jour de
            l’essai.
          </p>
          <div className="mt-2">
            <LegalBasis compact reference={prob.reference_legale} />
          </div>
        </div>
      )}

      {protections.data?.protected && (
        <div className="rounded-md border border-action/25 bg-action-veil px-4 py-3">
          <p className="text-xs font-semibold text-action">
            Protection contre le licenciement en cours — toute notification serait nulle.
          </p>
          <ul className="mt-1.5 space-y-1">
            {protections.data.protections.map((p, i) => (
              <li key={i} className="text-xs text-action">
                <strong>{p.libelle}</strong>
                {p.until && ` jusqu’au ${date(p.until)}`}
                {p.days_left !== null && p.days_left !== undefined && ` · J-${p.days_left}`}
                {p.reference_legale && <span className="ml-1 font-mono text-2xs opacity-80">{p.reference_legale}</span>}
              </li>
            ))}
          </ul>
        </div>
      )}

      <nav className="flex gap-1 border-b border-rule" aria-label="Sections de la fiche">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`border-b-2 px-3 py-2 text-sm ${
              tab === t
                ? 'border-violet font-semibold text-violet-deep'
                : 'border-transparent text-ink-muted hover:text-ink-body'
            }`}
          >
            {t}
          </button>
        ))}
      </nav>

      {tab === 'Compteurs' && (
        <div className="grid gap-4 lg:grid-cols-[340px_1fr]">
          <div className="space-y-3">
            <Card title="Solde de congés">
              {leave.isLoading ? (
                <Loading />
              ) : leave.data?.no_contract ? (
                <p className="text-xs text-ink-muted">Aucun contrat actif : pas d’acquisition en cours.</p>
              ) : (
                <>
                  <p className="text-3xl font-bold tracking-tight text-ink">
                    {num(leave.data?.balance, 2)} <span className="text-lg font-medium">j</span>
                  </p>
                  <p className="mt-0.5 text-xs text-ink-muted">
                    acquis {num(leave.data?.accrued, 2)} · pris {num(leave.data?.taken, 2)}
                  </p>
                </>
              )}
            </Card>
            <Card title="Incapacité / période de référence">
              {sick.isLoading ? (
                <Loading />
              ) : (
                <>
                  <p className="text-3xl font-bold tracking-tight text-ink">
                    {num(sick.data?.days_in_window, 0)}{' '}
                    <span className="text-lg font-medium text-ink-muted">/ {num(sick.data?.limit_days, 0)} j</span>
                  </p>
                  <p className="mt-0.5 text-xs text-ink-muted">
                    continuation de salaire employeur, sur {sick.data?.window_months} mois
                  </p>
                  {sick.data?.continuation_end && (
                    <p className="mt-2 rounded bg-warn-veil px-2 py-1.5 text-2xs text-warn-ink">
                      Fin de la continuation le {date(sick.data.continuation_end)} — la CNS prend le relais.
                    </p>
                  )}
                  <div className="mt-2">
                    <LegalBasis compact reference={sick.data?.reference_legale} />
                  </div>
                </>
              )}
            </Card>
          </div>

          <Card title="Détail du solde de congés" subtitle="Calcul reconstituable, ligne à ligne">
            {leave.data && !leave.data.no_contract && (
              <>
                <ul className="divide-y divide-rule">
                  {leave.data.lines.map((l, i) => (
                    <li
                      key={i}
                      className={`flex items-center justify-between gap-3 py-2 ${
                        l.sign === '=' ? 'font-semibold text-ink' : 'text-ink-body'
                      }`}
                    >
                      <span className="text-sm">{l.libelle}</span>
                      <span className="shrink-0 font-mono text-sm">
                        {l.sign === '=' ? '' : l.sign} {num(l.value, 2)} j
                      </span>
                    </li>
                  ))}
                </ul>
                <div className="mt-3">
                  <ArbitrationPanel arbitration={leave.data.arbitration} unit="j" />
                </div>
                <div className="mt-3">
                  <LegalBasis
                    reference={leave.data.reference_legale}
                    text="Le congé s’acquiert par douzième et par mois travaillé, dès la première année."
                    value={`${num(leave.data.entitlement_days, 0)} jours / an`}
                    validity={`retenu : ${leave.data.entitlement_source}`}
                    source="Legilux"
                  />
                </div>
              </>
            )}
          </Card>
        </div>
      )}

      {tab === 'Statuts & protections' && (
        <div className="grid gap-4 lg:grid-cols-2">
          <Card title="Statuts déclarés" dense>
            {(statuses.data ?? []).length === 0 ? (
              <p className="px-4 py-4 text-xs text-ink-muted">
                Aucun statut particulier. Grossesse, allaitement, mandat de délégué, prime de réemploi et
                gérance se déclarent ici : chacun ouvre des protections ou des interdictions que le moteur
                applique ensuite au planning et à la vigilance.
              </p>
            ) : (
              <ul className="divide-y divide-rule">
                {(statuses.data ?? []).map((s) => (
                  <li key={s.id} className="px-4 py-2.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-sm font-medium text-ink">{STATUS_KIND_LABEL[s.genre]}</span>
                      <Badge
                        tone={
                          s.date_debut <= referenceDate && s.date_fin >= referenceDate
                            ? 'violet'
                            : 'neutral'
                        }
                      >
                        {s.date_debut <= referenceDate && s.date_fin >= referenceDate
                          ? 'en cours'
                          : 'échu'}
                      </Badge>
                    </div>
                    <p className="text-2xs text-ink-muted">
                      du {date(s.date_debut)} {s.date_fin ? `au ${date(s.date_fin)}` : '(sans terme)'}
                      {s.date_naissance_prevue && ` · terme prévu le ${date(s.date_naissance_prevue)}`}
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </Card>

          <div className="space-y-3">
            <Card title="Heures supplémentaires">
              {overtime.isLoading ? (
                <Loading />
              ) : overtime.data?.allowed ? (
                <p className="text-sm text-success-ink">Aucune interdiction en vigueur.</p>
              ) : (
                <ul className="space-y-2">
                  {(overtime.data?.reasons ?? []).map((r) => (
                    <li key={r.code}>
                      <p className="text-sm font-medium text-danger-ink">{r.label}</p>
                      <p className="text-xs text-ink-muted">{r.detail}</p>
                      <LegalBasis compact reference={r.reference_legale} />
                    </li>
                  ))}
                </ul>
              )}
            </Card>

            <Card title="Éligibilité à la délégation du personnel">
              {delegation.isLoading ? (
                <Loading />
              ) : (
                <>
                  <p className={`text-sm font-semibold ${delegation.data?.eligible ? 'text-success-ink' : 'text-ink-body'}`}>
                    {delegation.data?.eligible ? 'Éligible' : 'Non éligible'}
                  </p>
                  <ul className="mt-1 space-y-0.5">
                    {(delegation.data?.reasons ?? []).map((r) => (
                      <li key={r.code} className="text-xs text-ink-muted">
                        · {r.detail}
                      </li>
                    ))}
                  </ul>
                  <div className="mt-2">
                    <LegalBasis compact reference={delegation.data?.reference_legale} />
                  </div>
                </>
              )}
            </Card>

            <Card title="Qualification">
              {qualification.data && (
                <>
                  <p className="text-sm font-semibold text-ink">
                    {qualification.data.qualified ? 'Qualifié(e)' : 'Non qualifié(e)'}
                  </p>
                  <p className="mt-0.5 text-xs text-ink-muted">{qualification.data.source}</p>
                  <div className="mt-2">
                    <LegalBasis compact reference={qualification.data.reference_legale} />
                  </div>
                </>
              )}
            </Card>
          </div>
        </div>
      )}

      {tab === 'Contrats' && (
        <Card dense>
          <Table head={['Type', 'Poste', 'Début', 'Fin', 'Brut mensuel', 'Statut', '']}>
            {(e.contrats ?? []).map((c) => (
              <tr key={c.id}>
                <td className="lux-td">
                  {CONTRACT_KIND_LABEL[c.genre] ?? c.genre}
                  {c.est_temps_partiel && <span className="ml-1 text-2xs text-ink-muted">temps partiel</span>}
                </td>
                <td className="lux-td">{c.intitule_poste}</td>
                <td className="lux-td">{date(c.date_debut)}</td>
                <td className="lux-td">{c.date_fin ? date(c.date_fin) : '—'}</td>
                <td className="lux-td font-mono">{eur(c.brut_mensuel)}</td>
                <td className="lux-td">
                  <Badge tone={c.statut === 'en_cours' ? 'ok' : 'neutral'}>{c.statut}</Badge>
                </td>
                <td className="lux-td">
                  <Link to={`/contrats/${c.id}`} className="text-xs font-semibold text-action hover:underline">
                    Ouvrir
                  </Link>
                </td>
              </tr>
            ))}
          </Table>
        </Card>
      )}

      {tab === 'Absences' && (
        <Card dense>
          <Table head={['Type', 'Du', 'Au', 'Jours', 'Statut', 'Certificat']}>
            {myAbsences.map((a) => (
              <tr key={a.id}>
                <td className="lux-td">{a.types_absence?.libelle}</td>
                <td className="lux-td">{date(a.date_debut)}</td>
                <td className="lux-td">{date(a.date_fin)}</td>
                <td className="lux-td font-mono">{num(a.nombre_jours, 2)}</td>
                <td className="lux-td">
                  <Badge tone={a.statut === 'valide' ? 'ok' : a.statut === 'en_attente' ? 'info' : 'neutral'}>
                    {ABSENCE_STATUS_LABEL[a.statut]}
                  </Badge>
                </td>
                <td className="lux-td">
                  {a.types_absence?.certificat_exige
                    ? a.certificat_recu
                      ? <Badge tone="ok">reçu</Badge>
                      : <Badge tone="blocking">manquant</Badge>
                    : '—'}
                </td>
              </tr>
            ))}
            {myAbsences.length === 0 && (
              <tr><td className="lux-td text-ink-muted" colSpan={6}>Aucune absence enregistrée.</td></tr>
            )}
          </Table>
        </Card>
      )}

      {tab === 'Documents' && (
        <Card>
          {(e.documents ?? []).length === 0 ? (
            <p className="text-xs text-ink-muted">
              Aucun document. Les contrats exportés en PDF et les justificatifs se rangent ici, dans un bucket
              privé, accessibles par URL signée à durée courte.
            </p>
          ) : (
            <ul className="divide-y divide-rule">
              {(e.documents ?? []).map((d) => (
                <li key={d.id} className="flex items-center justify-between py-2">
                  <span className="text-sm text-ink-body">{d.nom}</span>
                  <span className="text-2xs text-ink-faint">
                    {date(d.cree_le)}
                    {d.conservation_jusquau && ` · conservation jusqu’au ${date(d.conservation_jusquau)}`}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Card>
      )}
    </div>
  )
}
