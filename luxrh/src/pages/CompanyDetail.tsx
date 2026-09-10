import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import {
  useCompany, useCompanyAbsenteeism, useCompanyRates, useHeadcount, useSetCompanyRates,
} from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, SeverityMark, Table,
} from '@/components/ui'
import { CBA_SCOPE_LABEL, date, num, pct } from '@/lib/format'

export default function CompanyDetail() {
  const { id } = useParams()
  const { referenceDate } = useApp()
  const { data: c, isLoading, error } = useCompany(id)
  const rates = useCompanyRates(id, referenceDate)
  const hc = useHeadcount(id, referenceDate)
  const absenteeism = useCompanyAbsenteeism(id, Number(referenceDate.slice(0, 4)) - 1)
  const setRates = useSetCompanyRates()

  const [open, setOpen] = useState(false)
  const [form, setForm] = useState({
    from: referenceDate, mutuality_class: '2', accident_factor: '1.00', activity_class: '', note: '',
  })

  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />
  if (!c) return <Card title="Société introuvable">Ce dossier n’existe pas ou n’est pas accessible.</Card>

  const r = rates.data
  const delegation = hc.data?.thresholds[0]
  const periods = [...(c.company_rate_periods ?? [])].sort((a, b) =>
    b.valid_from.localeCompare(a.valid_from),
  )
  const cbaLinks = c.company_collective_agreements ?? []
  const activeCbas = cbaLinks.filter(
    (l) => l.valid_from <= referenceDate && (!l.valid_to || l.valid_to > referenceDate),
  )

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">{c.legal_name}</h1>
        <p className="text-sm text-ink-muted">
          {c.rcs_number && `RCS ${c.rcs_number} · `}
          {c.address_line}, {c.postal_code} {c.city}
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="Paramètres CCSS" subtitle={r?.found ? `en vigueur au ${date(referenceDate)}` : undefined}>
          {rates.isLoading ? (
            <Loading />
          ) : !r?.found ? (
            <p className="text-sm text-ink-muted">{r?.message}</p>
          ) : (
            <dl className="space-y-2 text-sm">
              {[
                ['Matricule CCSS', c.ccss_matricule ?? '—'],
                ['Secteur NACE', c.nace_code ?? '—'],
                ['Classe d’activité', r.activity_class ?? '—'],
                ['Classe Mutualité', `${r.mutuality_class ?? '—'} · ${pct(r.mutuality_rate)}`],
                ['Facteur accident', `${num(r.accident_factor, 2)} · ${pct(r.accident_rate)}`],
                ['Total charges patronales', pct(r.employer_total_pct)],
                ['Période de référence', `${c.reference_period_months} mois`],
              ].map(([k, v]) => (
                <div key={k} className="flex justify-between gap-3 border-b border-rule pb-1.5">
                  <dt className="text-ink-muted">{k}</dt>
                  <dd className="font-mono text-ink">{v}</dd>
                </div>
              ))}
            </dl>
          )}
        </Card>

        <Card
          title="Conventions applicables"
          subtitle={`${activeCbas.length} en vigueur sur ${cbaLinks.length} rattachement(s)`}
        >
          {cbaLinks.length === 0 ? (
            <p className="text-sm text-ink-muted">
              Aucune convention rattachée. Seul le Code du travail s’applique.
            </p>
          ) : (
            <ul className="space-y-2.5">
              {cbaLinks.map((l) => {
                const active = l.valid_from <= referenceDate && (!l.valid_to || l.valid_to > referenceDate)
                const ca = l.collective_agreements
                const rules = (ca?.cba_rules ?? []) as { block: string; rules: Record<string, unknown> }[]
                const leaveRules = rules.find((b) => b.block === 'leave')?.rules as
                  | Record<string, number> | undefined
                const surcharges = rules.find((b) => b.block === 'surcharges')?.rules as
                  | Record<string, number> | undefined
                return (
                  <li key={l.id} className={`rounded border p-2.5 ${active ? 'border-violet bg-violet-veil' : 'border-rule'}`}>
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-ink">{ca?.name}</p>
                        <p className="text-2xs text-ink-muted">
                          {CBA_SCOPE_LABEL[ca?.scope ?? 'sector']} · {date(l.valid_from)} →{' '}
                          {l.valid_to ? date(l.valid_to) : '…'}
                        </p>
                      </div>
                      <Badge tone={active ? 'violet' : 'neutral'}>{active ? 'en vigueur' : 'échue'}</Badge>
                    </div>
                    {active && (
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {leaveRules?.annual_days !== undefined && (
                          <Badge tone="neutral">Congé {leaveRules.annual_days} j</Badge>
                        )}
                        {surcharges?.night_pct !== undefined && (
                          <Badge tone="neutral">Nuit +{surcharges.night_pct} %</Badge>
                        )}
                        {surcharges?.sunday_pct !== undefined && (
                          <Badge tone="neutral">Dimanche +{surcharges.sunday_pct} %</Badge>
                        )}
                      </div>
                    )}
                  </li>
                )
              })}
            </ul>
          )}
        </Card>

        <Card title="Services">
          {(c.departments ?? []).length === 0 ? (
            <p className="text-sm text-ink-muted">Aucun service déclaré.</p>
          ) : (
            <ul className="space-y-1.5 text-sm">
              {(c.departments ?? []).map((d) => (
                <li key={d.id} className="flex justify-between gap-2 border-b border-rule pb-1.5">
                  <span className="text-ink-body">{d.name}</span>
                  {d.min_evening_coverage && (
                    <span className="text-2xs text-ink-muted">
                      couverture min. {d.min_evening_coverage}
                    </span>
                  )}
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      {/* Historique des taux : un recalcul daté doit retrouver les taux d’alors. */}
      <Card
        dense
        title="Historique des taux CCSS"
        subtitle="Classe d’activité, classe Mutualité et facteur accident évoluent dans le temps"
        action={
          <Button size="sm" onClick={() => setOpen((v) => !v)}>
            {open ? 'Annuler' : 'Nouvelle période'}
          </Button>
        }
      >
        {open && (
          <div className="border-b border-rule bg-rule-rail/50 p-4">
            <div className="grid gap-3 sm:grid-cols-5">
              <Field label="À compter du" required>
                <Input type="date" value={form.from} onChange={(e) => setForm({ ...form, from: e.target.value })} />
              </Field>
              <Field label="Classe Mutualité">
                <Select
                  value={form.mutuality_class}
                  onChange={(e) => setForm({ ...form, mutuality_class: e.target.value })}
                >
                  {[1, 2, 3, 4].map((k) => <option key={k} value={k}>Classe {k}</option>)}
                </Select>
              </Field>
              <Field label="Facteur accident">
                <Input
                  type="number" step="0.01" value={form.accident_factor}
                  onChange={(e) => setForm({ ...form, accident_factor: e.target.value })}
                />
              </Field>
              <Field label="Classe d’activité">
                <Input
                  value={form.activity_class}
                  onChange={(e) => setForm({ ...form, activity_class: e.target.value })}
                />
              </Field>
              <div className="flex items-end">
                <Button
                  variant="primary" className="w-full" disabled={setRates.isPending}
                  onClick={() =>
                    setRates.mutate(
                      {
                        companyId: c.id, from: form.from,
                        mutualityClass: Number(form.mutuality_class),
                        accidentFactor: Number(form.accident_factor),
                        activityClass: form.activity_class || null,
                        note: form.note || null,
                      },
                      { onSuccess: () => setOpen(false) },
                    )
                  }
                >
                  {setRates.isPending ? 'Enregistrement…' : 'Ouvrir la période'}
                </Button>
              </div>
            </div>
            <ErrorNote error={setRates.error} />
            <p className="mt-2 text-xs text-ink-muted">
              La période précédente est automatiquement clôturée à cette date. Aucun recalcul antérieur
              n’est affecté.
            </p>
          </div>
        )}

        <Table head={['Du', 'Au', 'Classe d’activité', 'Mutualité', 'Facteur accident', 'Note']}>
          {periods.map((p) => (
            <tr key={p.id}>
              <td className="lux-td font-mono">{date(p.valid_from)}</td>
              <td className="lux-td font-mono">{p.valid_to ? date(p.valid_to) : '…'}</td>
              <td className="lux-td">{p.activity_class ?? '—'}</td>
              <td className="lux-td">{p.mutuality_class ? `Classe ${p.mutuality_class}` : '—'}</td>
              <td className="lux-td font-mono">{num(p.accident_factor, 2)}</td>
              <td className="lux-td text-2xs text-ink-muted">{p.note ?? '—'}</td>
            </tr>
          ))}
        </Table>
      </Card>

      <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
        <Card
          title="Effectif et obligations"
          subtitle={
            hc.data
              ? `Période de référence : ${date(hc.data.headcount.period_start)} → ${date(hc.data.headcount.period_end)}`
              : undefined
          }
        >
          {hc.isLoading ? (
            <Loading />
          ) : (
            hc.data && (
              <>
                <div className="grid gap-3 sm:grid-cols-3">
                  <div>
                    <p className="lux-label">Effectif moyen</p>
                    <p className="text-3xl font-bold tracking-tight text-ink">{hc.data.headcount.rounded}</p>
                    <p className="text-2xs text-ink-muted">
                      moyenne exacte {num(hc.data.headcount.average, 2)} · aujourd’hui{' '}
                      {hc.data.headcount.current}
                    </p>
                  </div>
                  <div>
                    <p className="lux-label">Seuil de délégation</p>
                    <p className="text-3xl font-bold tracking-tight text-ink">
                      {num(delegation?.threshold, 0)}
                    </p>
                    <p className="text-2xs text-ink-muted">{delegation?.status}</p>
                  </div>
                  <div>
                    <p className="lux-label">Mode de scrutin</p>
                    <p className="text-3xl font-bold capitalize tracking-tight text-ink">
                      {hc.data.vote_mode}
                    </p>
                  </div>
                </div>

                {delegation && (
                  <div
                    className={`mt-4 flex items-start gap-3 rounded-md border p-3 ${
                      delegation.reached ? 'border-warn/30 bg-warn-veil' : 'border-rule bg-rule-rail/60'
                    }`}
                  >
                    <SeverityMark severity={delegation.reached ? 'warning' : 'info'} />
                    <div>
                      <p className="text-sm text-ink-body">
                        {delegation.reached
                          ? `Seuil franchi : ${delegation.consequence}`
                          : `À ${delegation.gap} salarié(s) du seuil de la délégation du personnel. ${delegation.consequence}`}
                      </p>
                      <div className="mt-2">
                        <LegalBasis compact reference={delegation.legal_ref} />
                      </div>
                    </div>
                  </div>
                )}
              </>
            )
          )}
        </Card>

        <Card title="Absentéisme" subtitle={`Exercice ${Number(referenceDate.slice(0, 4)) - 1}`}>
          {absenteeism.isLoading ? (
            <Loading />
          ) : (
            absenteeism.data && (
              <>
                <p className="text-3xl font-bold tracking-tight text-ink">
                  {absenteeism.data.absenteeism_rate_pct === null
                    ? '—'
                    : `${num(absenteeism.data.absenteeism_rate_pct, 2)} %`}
                </p>
                <p className="mt-0.5 text-xs text-ink-muted">
                  {num(absenteeism.data.sick_days, 0)} jours d’incapacité pour un effectif moyen de{' '}
                  {num(absenteeism.data.average_headcount, 1)}
                </p>
                {absenteeism.data.suggested_mutuality_class && (
                  <p className="mt-2 rounded bg-violet-veil px-2 py-1.5 text-xs text-violet-deep">
                    Classe de Mutualité suggérée : {absenteeism.data.suggested_mutuality_class}
                  </p>
                )}
                <p className="mt-2 text-xs text-ink-muted">{absenteeism.data.message}</p>
              </>
            )
          )}
        </Card>
      </div>
    </div>
  )
}
