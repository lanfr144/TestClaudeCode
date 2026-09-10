import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useContract, useContractCompliance, useUpdateContract } from '@/lib/queries'
import { supabase } from '@/lib/supabase'
import {
  ArbitrationPanel, Badge, Button, Card, ErrorNote, LegalBasis, Loading, SeverityMark,
} from '@/components/ui'
import { date, eur, num } from '@/lib/format'

export default function ContractPreview() {
  const { id } = useParams()
  const { referenceDate } = useApp()
  const { data: c, isLoading, error } = useContract(id)
  const compliance = useContractCompliance(id, referenceDate)
  const update = useUpdateContract()
  const [exporting, setExporting] = useState(false)
  const [exportError, setExportError] = useState<unknown>(null)

  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />
  if (!c) return <Card title="Contrat introuvable">Ce contrat n’existe pas ou n’est pas accessible.</Card>

  const comp = compliance.data
  const emp = c.employees
  const company = c.companies
  const prob = comp?.probation

  /** Génération PDF côté serveur — jamais dans le navigateur. */
  async function exportPdf() {
    setExporting(true)
    setExportError(null)
    try {
      const { data, error } = await supabase.functions.invoke('contract-pdf', {
        body: { contract_id: id },
      })
      if (error) throw error
      const blob = data instanceof Blob ? data : new Blob([data as BlobPart], { type: 'application/pdf' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `contrat-${emp?.last_name ?? 'salarie'}.pdf`
      a.click()
      URL.revokeObjectURL(url)
    } catch (e) {
      setExportError(e)
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">
            Contrat de travail à durée {c.kind === 'cdi' ? 'indéterminée' : 'déterminée'} — {emp?.first_name}{' '}
            {emp?.last_name}
          </h1>
          <p className="text-xs text-ink-muted">
            Version {c.version} · {c.status === 'draft' ? 'brouillon' : c.status}
          </p>
        </div>
        <div className="flex gap-2">
          <Button size="sm" onClick={exportPdf} disabled={exporting}>
            {exporting ? 'Génération…' : 'Exporter en PDF'}
          </Button>
          {c.status === 'draft' && (
            <Button
              size="sm" variant="primary"
              disabled={!comp?.can_validate || update.isPending}
              onClick={() => update.mutate({ id: c.id, status: 'active', signed_at: referenceDate })}
            >
              Valider et envoyer
            </Button>
          )}
        </div>
      </header>

      <ErrorNote error={exportError ?? update.error} />

      <div className="grid gap-4 lg:grid-cols-[1fr_380px]">
        {/* Le document */}
        <article className="lux-card p-8 leading-relaxed">
          <p className="text-xs text-ink-muted">
            {company?.legal_name} · {company?.city}
          </p>
          <h2 className="mt-4 text-center text-base font-bold uppercase tracking-wide text-ink">
            Contrat de travail à durée {c.kind === 'cdi' ? 'indéterminée' : 'déterminée'}
          </h2>

          <div className="mt-6 space-y-4 text-sm text-ink-body">
            <p>
              <strong>Entre les soussignés :</strong> la société{' '}
              <strong>{company?.legal_name}</strong>
              {company?.rcs_number && `, RCS ${company.rcs_number}`}, établie {company?.address_line},{' '}
              {company?.postal_code} {company?.city}
              {company?.ccss_matricule && `, matricule CCSS ${company.ccss_matricule}`}, ci-après
              « l’employeur »,
            </p>
            <p>
              <strong>Et</strong> {emp?.first_name} <strong>{emp?.last_name}</strong>
              {emp?.birth_date && `, né(e) le ${date(emp.birth_date)}`}
              {emp?.address_line && `, demeurant ${emp.address_line}, ${emp.postal_code ?? ''} ${emp.city ?? ''}`},
              ci-après « le salarié », il a été convenu ce qui suit.
            </p>

            <p>
              <strong>Article 1 — Engagement et fonction.</strong> Le salarié est engagé en qualité de{' '}
              <strong>{c.job_title}</strong>, à compter du <strong>{date(c.start_date)}</strong>
              {c.work_place && `, au lieu de travail sis ${c.work_place}`}.
              {c.job_description && ` ${c.job_description}`}
            </p>

            {c.probation_length && prob && (
              <p>
                <strong>Article 2 — Période d’essai.</strong> Le contrat est assorti d’une période d’essai de{' '}
                <strong>
                  {c.probation_length} {c.probation_unit === 'months' ? 'mois' : 'semaines'}
                </strong>
                , expirant le <strong>{date(prob.end)}</strong>. Pendant l’essai, chaque partie peut résilier
                moyennant un préavis de <strong>{prob.notice_days} jours</strong>, qui doit expirer au plus tard
                le dernier jour de l’essai.
              </p>
            )}

            <p>
              <strong>Article 3 — Durée de travail.</strong> La durée hebdomadaire est fixée à{' '}
              <strong>{num(c.weekly_hours, 2)} heures</strong>
              {c.work_distribution && `, réparties selon la modalité suivante : ${c.work_distribution}`}. Une
              période de référence de {c.reference_period_months} mois est applicable.
            </p>

            <p>
              <strong>Article 4 — Rémunération.</strong> La rémunération mensuelle brute est fixée à{' '}
              <strong>{eur(c.monthly_gross)}</strong>
              {c.index_ref && ` à l’indice ${num(c.index_ref, 2)}`}, payable à la fin de chaque mois. Elle est
              adaptée à chaque variation de l’indice des prix à la consommation.
            </p>

            <p>
              <strong>Article 5 — Congé annuel.</strong> Le salarié bénéficie de{' '}
              <strong>{num(c.annual_leave_days, 0)} jours ouvrables</strong> de congé annuel payé
              {comp?.annual_leave.retained_source === 'CCT' && ', conformément à la convention collective applicable'}
              .
            </p>

            {c.kind === 'cdd' && (
              <p>
                <strong>Article 6 — Terme et motif de recours.</strong> Le contrat prend fin le{' '}
                <strong>{date(c.end_date)}</strong>. Motif de recours : {c.cdd_reason}.
              </p>
            )}

            <p>
              <strong>Article {c.kind === 'cdd' ? 7 : 6} — Convention collective.</strong>{' '}
              {comp && comp.collective_agreements.length > 0
                ? `Le contrat est régi par : ${comp.collective_agreements
                    .map((a) => `${a.name} (${a.origin})`)
                    .join(', ')}.`
                : 'Aucune convention collective n’est applicable à ce contrat.'}
            </p>

            {c.non_compete_clause && (
              <p>
                <strong>Article {c.kind === 'cdd' ? 8 : 7} — Clause de non-concurrence.</strong> Le salarié
                s’interdit d’exercer une activité concurrente, dans les limites de temps, d’espace et
                d’activité définies à l’annexe.
              </p>
            )}
          </div>

          {(c.contract_amendments ?? []).length > 0 && (
            <div className="mt-6 border-t border-rule pt-4">
              <p className="lux-label">Avenants</p>
              <ul className="mt-2 space-y-1 text-xs text-ink-muted">
                {(c.contract_amendments ?? []).map((a) => (
                  <li key={a.id}>
                    {date(a.effective_date)} — {a.reason}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </article>

        {/* Panneau de conformité */}
        <aside className="space-y-3">
          <Card
            dense
            title={
              <span className="flex items-center gap-2">
                Panneau de conformité
                <Badge tone={comp?.can_validate ? 'ok' : 'blocking'}>
                  {comp?.can_validate ? 'Validable' : 'Blocage'}
                </Badge>
              </span>
            }
          >
            {compliance.isLoading && <Loading />}
            <ul className="divide-y divide-rule">
              {(comp?.checks ?? []).map((ck) => (
                <li key={ck.code} className="flex items-start gap-2.5 px-4 py-2.5">
                  <SeverityMark severity={ck.severity} />
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink">{ck.label}</p>
                    <p className="text-xs text-ink-muted">{ck.detail}</p>
                    {ck.legal_ref && (
                      <span className="mt-1 inline-block font-mono text-2xs text-ink-faint">{ck.legal_ref}</span>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </Card>

          {comp && (
            <Card title="Arbitrage loi / CCT / contrat">
              <ArbitrationPanel arbitration={comp.annual_leave} unit="j" />
              <div className="mt-4 border-t border-rule pt-3">
                <p className="lux-label">Salaire mensuel</p>
                <ul className="mt-2 space-y-1.5 text-sm">
                  <li className="flex justify-between gap-3">
                    <span className="text-ink-muted">
                      SSM {comp.salary.is_qualified ? 'qualifié' : 'non qualifié'}
                      {comp.salary.prorata < 1 && ` (prorata ${num(comp.salary.prorata * 100, 0)} %)`}
                    </span>
                    <span className="font-mono text-ink-body">{eur(comp.salary.ssm)}</span>
                  </li>
                  {comp.salary.cba_grid !== null && (
                    <li className="flex justify-between gap-3">
                      <span className="text-ink-muted">
                        Grille {comp.salary.cba_name ?? 'CCT'} · cat. {comp.salary.cba_category}
                      </span>
                      <span className="font-mono text-ink-body">{eur(comp.salary.cba_grid)}</span>
                    </li>
                  )}
                  <li className="flex justify-between gap-3 border-t border-rule pt-1.5 font-semibold">
                    <span className="text-violet-deep">Contrat · retenu</span>
                    <span className="font-mono text-violet-deep">{eur(comp.salary.contract_gross)}</span>
                  </li>
                </ul>
                <div className="mt-2">
                  <LegalBasis
                    reference={comp.salary.ssm_ref}
                    value={eur(comp.salary.ssm_full)}
                    validity={comp.salary.ssm_index ? `indice ${num(comp.salary.ssm_index, 2)}` : undefined}
                    source="CCSS"
                  />
                </div>
              </div>
            </Card>
          )}

          {prob && (
            <Card title="Dates calculées">
              <dl className="space-y-1.5 text-sm">
                {[
                  ['Fin d’essai', date(prob.end)],
                  ['Préavis d’essai', `${prob.notice_days} jours`],
                  ['Dernier jour pour notifier', date(prob.last_day_to_notify)],
                ].map(([k, v], i) => (
                  <div
                    key={k}
                    className={`flex justify-between gap-3 ${i === 2 ? 'font-semibold text-warn-ink' : 'text-ink-body'}`}
                  >
                    <dt>{k}</dt>
                    <dd className="font-mono">{v}</dd>
                  </div>
                ))}
              </dl>
              {prob.extension_days > 0 && (
                <p className="mt-2 text-xs text-ink-muted">
                  Essai prolongé de {prob.extension_days} jour(s) par une incapacité de travail, plafond de{' '}
                  {prob.extension_cap_days} jours.
                </p>
              )}
            </Card>
          )}
        </aside>
      </div>
    </div>
  )
}
