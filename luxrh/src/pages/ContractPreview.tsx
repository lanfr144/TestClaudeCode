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
  const emp = c.salaries
  const company = c.societes
  const prob = comp?.probation

  /** Génération PDF côté serveur — jamais dans le navigateur. */
  async function exportPdf() {
    setExporting(true)
    setExportError(null)
    try {
      const { data, error } = await supabase.functions.invoke('contrat-pdf', {
        body: { contrat_id: id },
      })
      if (error) throw error
      const blob = data instanceof Blob ? data : new Blob([data as BlobPart], { type: 'application/pdf' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `contrat-${emp?.nom ?? 'salarie'}.pdf`
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
            Contrat de travail à durée {c.genre === 'cdi' ? 'indéterminée' : 'déterminée'} — {emp?.prenom}{' '}
            {emp?.nom}
          </h1>
          <p className="text-xs text-ink-muted">
            Version {c.version} · {c.statut === 'brouillon' ? 'brouillon' : c.statut}
          </p>
        </div>
        <div className="flex gap-2">
          <Button size="sm" onClick={exportPdf} disabled={exporting}>
            {exporting ? 'Génération…' : 'Exporter en PDF'}
          </Button>
          {c.statut === 'brouillon' && (
            <Button
              size="sm" variant="primary"
              disabled={!comp?.can_validate || update.isPending}
              onClick={() => update.mutate({ id: c.id, statut: 'en_cours', signe_le: referenceDate })}
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
            {company?.raison_sociale} · {company?.localite}
          </p>
          <h2 className="mt-4 text-center text-base font-bold uppercase tracking-wide text-ink">
            Contrat de travail à durée {c.genre === 'cdi' ? 'indéterminée' : 'déterminée'}
          </h2>

          <div className="mt-6 space-y-4 text-sm text-ink-body">
            <p>
              <strong>Entre les soussignés :</strong> la société{' '}
              <strong>{company?.raison_sociale}</strong>
              {company?.numero_rcs && `, RCS ${company.numero_rcs}`}, établie {company?.ligne},{' '}
              {company?.code_postal} {company?.localite}
              {company?.matricule_ccss && `, matricule CCSS ${company.matricule_ccss}`}, ci-après
              « l’employeur »,
            </p>
            <p>
              <strong>Et</strong> {emp?.prenom} <strong>{emp?.nom}</strong>
              {emp?.date_naissance && `, né(e) le ${date(emp.date_naissance)}`}
              {emp?.ligne && `, demeurant ${emp.ligne}, ${emp.code_postal ?? ''} ${emp.localite ?? ''}`},
              ci-après « le salarié », il a été convenu ce qui suit.
            </p>

            <p>
              <strong>Article 1 — Engagement et fonction.</strong> Le salarié est engagé en qualité de{' '}
              <strong>{c.intitule_poste}</strong>, à compter du <strong>{date(c.date_debut)}</strong>
              {c.lieu_travail && `, au lieu de travail sis ${c.lieu_travail}`}.
              {c.description_poste && ` ${c.description_poste}`}
            </p>

            {c.duree_essai && prob && (
              <p>
                <strong>Article 2 — Période d’essai.</strong> Le contrat est assorti d’une période d’essai de{' '}
                <strong>
                  {c.duree_essai} {c.unite_essai === 'mois' ? 'mois' : 'semaines'}
                </strong>
                , expirant le <strong>{date(prob.end)}</strong>. Pendant l’essai, chaque partie peut résilier
                moyennant un préavis de <strong>{prob.notice_days} jours</strong>, qui doit expirer au plus tard
                le dernier jour de l’essai.
              </p>
            )}

            <p>
              <strong>Article 3 — Durée de travail.</strong> La durée hebdomadaire est fixée à{' '}
              <strong>{num(c.heures_hebdomadaires, 2)} heures</strong>
              {c.repartition_travail && `, réparties selon la modalité suivante : ${c.repartition_travail}`}. Une
              période de référence de {c.periode_reference_mois} mois est applicable.
            </p>

            <p>
              <strong>Article 4 — Rémunération.</strong> La rémunération mensuelle brute est fixée à{' '}
              <strong>{eur(c.brut_mensuel)}</strong>
              {c.indice_reference && ` à l’indice ${num(c.indice_reference, 2)}`}, payable à la fin de chaque mois. Elle est
              adaptée à chaque variation de l’indice des prix à la consommation.
            </p>

            <p>
              <strong>Article 5 — Congé annuel.</strong> Le salarié bénéficie de{' '}
              <strong>{num(c.jours_conge_annuel, 0)} jours ouvrables</strong> de congé annuel payé
              {comp?.annual_leave.retained_source === 'CCT' && ', conformément à la convention collective applicable'}
              .
            </p>

            {c.genre === 'cdd' && (
              <p>
                <strong>Article 6 — Terme et motif de recours.</strong> Le contrat prend fin le{' '}
                <strong>{date(c.date_fin)}</strong>. Motif de recours : {c.motif_cdd}.
              </p>
            )}

            <p>
              <strong>Article {c.genre === 'cdd' ? 7 : 6} — Convention collective.</strong>{' '}
              {comp && comp.conventions_collectives.length > 0
                ? `Le contrat est régi par : ${comp.conventions_collectives
                    .map((a) => `${a.name} (${a.origin})`)
                    .join(', ')}.`
                : 'Aucune convention collective n’est applicable à ce contrat.'}
            </p>

            {c.clause_non_concurrence && (
              <p>
                <strong>Article {c.genre === 'cdd' ? 8 : 7} — Clause de non-concurrence.</strong> Le salarié
                s’interdit d’exercer une activité concurrente, dans les limites de temps, d’espace et
                d’activité définies à l’annexe.
              </p>
            )}
          </div>

          {(c.avenants_contrat ?? []).length > 0 && (
            <div className="mt-6 border-t border-rule pt-4">
              <p className="lux-libelle">Avenants</p>
              <ul className="mt-2 space-y-1 text-xs text-ink-muted">
                {(c.avenants_contrat ?? []).map((a) => (
                  <li key={a.id}>
                    {date(a.date_effet)} — {a.motif}
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
                  <SeverityMark severity={ck.severite} />
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink">{ck.libelle}</p>
                    <p className="text-xs text-ink-muted">{ck.detail}</p>
                    {ck.reference_legale && (
                      <span className="mt-1 inline-bloc font-mono text-2xs text-ink-faint">{ck.reference_legale}</span>
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
                <p className="lux-libelle">Salaire mensuel</p>
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
