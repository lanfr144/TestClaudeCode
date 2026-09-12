import { useState } from 'react'
import { useApp } from '@/context/AppContext'
import { useDismissalCounters, useSimulateDismissal } from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, LegalDisclaimer, Loading, Select,
  SeverityMark,
} from '@/components/ui'
import { date, num } from '@/lib/format'

export default function DismissalSimulator() {
  const { activeCompanyId, referenceDate } = useApp()
  const counters = useDismissalCounters(activeCompanyId ?? undefined, referenceDate)
  const simulate = useSimulateDismissal()

  const [count, setCount] = useState('6')
  const [when, setWhen] = useState(referenceDate)
  const [ground, setGround] = useState<'economic' | 'personal'>('economic')

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>

  const result = simulate.data

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">Simuler un scénario de licenciement</h1>
        <p className="text-xs text-ink-muted">
          Aide à la décision. Aucune notification n’est envoyée depuis cet écran.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
        <div className="space-y-4">
          <Card title="Scénario">
            <div className="grid gap-3 sm:grid-cols-4">
              <Field label="Nombre de licenciements" required>
                <Input type="number" min={1} value={count} onChange={(e) => setCount(e.target.value)} />
              </Field>
              <Field label="Date de notification envisagée" required>
                <Input type="date" value={when} onChange={(e) => setWhen(e.target.value)} />
              </Field>
              <Field label="Motif" hint="Seuls les motifs non inhérents à la personne alimentent les compteurs.">
                <Select value={ground} onChange={(e) => setGround(e.target.value as 'economic' | 'personal')}>
                  <option value="economic">Non inhérent à la personne</option>
                  <option value="personal">Inhérent à la personne</option>
                </Select>
              </Field>
              <div className="flex items-end">
                <Button
                  variant="primary" className="w-full" disabled={simulate.isPending}
                  onClick={() =>
                    simulate.mutate({
                      companyId: activeCompanyId,
                      count: Number(count || 0),
                      date: when,
                      personalGround: ground === 'personal',
                    })
                  }
                >
                  {simulate.isPending ? 'Simulation…' : 'Simuler'}
                </Button>
              </div>
            </div>
            <ErrorNote error={simulate.error} />
          </Card>

          {result && (
            <>
              <div
                className={`rounded-md border p-4 ${
                  result.triggers ? 'border-danger/30 bg-danger-veil' : 'border-success/30 bg-success-veil'
                }`}
              >
                <div className="flex items-start gap-3">
                  <SeverityMark severity={result.triggers ? 'bloquant' : 'ok'} />
                  <div>
                    <p
                      className={`text-sm font-bold ${
                        result.triggers ? 'text-danger-ink' : 'text-success-ink'
                      }`}
                    >
                      {result.triggers
                        ? 'La procédure de licenciement collectif se déclenche'
                        : 'La procédure de licenciement collectif ne se déclenche pas'}
                    </p>
                    <p className="mt-1 text-xs leading-relaxed text-ink-body">{result.verdict}</p>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {result.legal_refs.map((r) => (
                        <LegalBasis key={r} compact reference={r} />
                      ))}
                    </div>
                  </div>
                </div>

                {result.alternatives.length > 0 && (
                  <ul className="mt-3 space-y-1.5 border-t border-danger/20 pt-3">
                    {result.alternatives.map((a, i) => (
                      <li key={i} className="flex items-center gap-2 text-xs text-ink-body">
                        <span className="lux-libelle">Alternative</span>
                        {a.label}
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              {result.timeline.length > 0 && (
                <Card title="Chronologie de la procédure">
                  <ol className="relative space-y-4 border-l border-rule pl-5">
                    {result.timeline.map((step, i) => (
                      <li key={i} className="relative">
                        <span
                          className="absolute -left-[26px] top-1 flex h-3 w-3 items-center justify-center rounded-full border-2 border-white bg-violet"
                          aria-hidden
                        />
                        <p className="font-mono text-2xs text-ink-faint">{step.when}</p>
                        <p className="text-sm font-semibold text-ink">{step.titre}</p>
                        <p className="text-xs leading-relaxed text-ink-muted">{step.detail}</p>
                      </li>
                    ))}
                  </ol>
                  <p className="mt-4 rounded border border-warn/30 bg-warn-veil px-3 py-2 text-xs font-medium text-warn-ink">
                    Aucune notification ne peut intervenir avant l’issue de la procédure.
                  </p>
                </Card>
              )}

              <LegalDisclaimer text={result.disclaimer.replace(/^LuxRH[^.]*\.\s*/, '')} />
            </>
          )}
        </div>

        <aside className="space-y-3">
          <Card title={`Compteurs glissants au ${date(referenceDate)}`}>
            {counters.isLoading ? (
              <Loading />
            ) : (
              <div className="space-y-4">
                {[
                  { label: '30 jours', w: counters.data?.window_30 },
                  { label: '90 jours', w: counters.data?.window_90 },
                ].map(({ label, w }) =>
                  w ? (
                    <div key={label}>
                      <div className="flex items-baseline justify-between">
                        <span className="text-sm font-semibold text-ink">{label}</span>
                        <span className="font-mono text-sm text-ink">
                          {w.count} / {num(w.threshold, 0)}
                        </span>
                      </div>
                      <div className="mt-1 h-1.5 overflow-hidden rounded bg-rule-rail">
                        <div
                          className={`h-full ${w.count >= w.threshold ? 'bg-danger' : 'bg-violet'}`}
                          style={{ width: `${Math.min(100, (w.count / Number(w.threshold)) * 100)}%` }}
                        />
                      </div>
                      <p className="mt-1 text-xs text-ink-muted">
                        Encore <strong className="text-ink">{w.remaining}</strong> notification(s) possibles.
                        {w.releases_on && (
                          <>
                            {' '}Se libère le <strong className="text-ink">{date(w.releases_on)}</strong>.
                          </>
                        )}
                      </p>
                    </div>
                  ) : null,
                )}
                <LegalBasis compact reference={counters.data?.reference_legale} />
              </div>
            )}
          </Card>

          <Card title="Ce que dit la loi">
            <p className="text-xs leading-relaxed text-ink-muted">
              La procédure de licenciement collectif s’applique dès que le nombre de licenciements pour un
              motif non inhérent à la personne du salarié atteint le seuil sur 30 ou sur 90 jours. Elle impose
              l’information de la délégation du personnel et de l’ADEM, une négociation de plan social, puis, en
              cas de désaccord, la saisine de l’Office national de conciliation.
            </p>
            <div className="mt-2 flex gap-1.5">
              <LegalBasis compact reference="art. L.166-1" />
              <LegalBasis compact reference="art. L.166-2" />
            </div>
          </Card>

          <Badge tone="neutral">Aucune donnée n’est modifiée par cette simulation</Badge>
        </aside>
      </div>
    </div>
  )
}
