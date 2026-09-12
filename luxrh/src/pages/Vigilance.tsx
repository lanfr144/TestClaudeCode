import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useVigilance } from '@/lib/queries'
import { Badge, Button, Card, ErrorNote, Field, Input, LegalDisclaimer, Loading } from '@/components/ui'
import { VigilanceBlock } from '@/components/VigilanceItem'
import { num } from '@/lib/format'

const FILTERS = [
  { key: 'all', label: 'Toutes' },
  { key: 'contract', label: 'Contrats' },
  { key: 'worktime', label: 'Temps de travail' },
  { key: 'absence', label: 'Absences' },
  { key: 'effectif', label: 'Effectif' },
  { key: 'document', label: 'Documents' },
  { key: 'protection', label: 'Protections' },
] as const

export default function Vigilance() {
  const { activeCompanyId, referenceDate, setReferenceDate } = useApp()
  const [filter, setFilter] = useState<(typeof FILTERS)[number]['key']>('all')
  const { data, isLoading, error } = useVigilance(activeCompanyId ?? undefined, referenceDate)

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading label="Analyse de conformité…" /></Card>
  if (error) return <ErrorNote error={error} />

  const s = data!
  const keep = (items: typeof s.items) =>
    filter === 'all' ? items : items.filter((i) => i.categorie === filter)

  const hc = s.effectif

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Centre de vigilance</h1>
          <p className="text-xs text-ink-muted">
            Toutes les obligations, leur base légale et la conséquence du non-respect.
          </p>
        </div>
        <div className="w-48">
          {/* Aucun calcul ne s'exécute sans date de référence. */}
          <Field label="Évalué à la date du">
            <Input type="date" value={referenceDate} onChange={(e) => setReferenceDate(e.target.value)} />
          </Field>
        </div>
      </header>

      <nav className="flex flex-wrap gap-1.5" aria-label="Filtrer par domaine">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            className={`min-h-[34px] rounded border px-3 text-xs font-semibold ${
              filter === f.key
                ? 'border-violet bg-violet-veil text-violet-deep'
                : 'border-rule-strong bg-white text-ink-muted hover:bg-rule-rail'
            }`}
          >
            {f.label}
          </button>
        ))}
      </nav>

      <div className="grid gap-4 xl:grid-cols-[1fr_340px]">
        <div className="space-y-3">
          <VigilanceBlock title={`En retard · ${keep(s.overdue).length}`} tone="blocking" items={keep(s.overdue)} />
          <VigilanceBlock
            title={`Dans les ${s.horizon_days} jours · ${keep(s.due_soon).length}`}
            tone="warning"
            items={keep(s.due_soon)}
          />
          <VigilanceBlock title={`À surveiller · ${keep(s.watch).length}`} tone="info" items={keep(s.watch)} />
        </div>

        <aside className="space-y-3">
          <Card title="Seuils d’effectif" subtitle={`Effectif moyen ${num(hc.effectif.average, 2)} sur ${hc.effectif.reference_months} mois`}>
            <ul className="space-y-2.5">
              {hc.thresholds.map((t) => (
                <li key={t.threshold} className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-ink">{num(t.threshold, 0)} salariés</p>
                    <p className="text-xs text-ink-muted">{t.libelle}</p>
                  </div>
                  <Badge tone={t.reached ? 'warning' : 'neutral'}>{t.statut}</Badge>
                </li>
              ))}
            </ul>
            {hc.delegates_due && (
              <p className="mt-3 rounded bg-rule-rail px-2.5 py-2 text-xs text-ink-body">
                Tranche {hc.delegates_due.from}–{hc.delegates_due.to ?? '+'} :{' '}
                <strong>{hc.delegates_due.effective}</strong> délégué(s) effectif(s) et{' '}
                <strong>{hc.delegates_due.substitute}</strong> suppléant(s), scrutin {hc.vote_mode}.
              </p>
            )}
            <p className="mt-2 text-2xs text-ink-muted">
              Chaque seuil est lu dans le référentiel daté, jamais codé en dur.
            </p>
          </Card>

          <Card title="Licenciement collectif">
            <ul className="space-y-2 text-sm">
              {[
                { label: '30 jours glissants', w: s.dismissal_counters.window_30 },
                { label: '90 jours glissants', w: s.dismissal_counters.window_90 },
              ].map(({ label, w }) => (
                <li key={label} className="flex items-center justify-between gap-2">
                  <span className="text-ink-muted">{label}</span>
                  <span className="font-mono font-semibold text-ink">
                    {w.count} / {num(w.threshold, 0)}
                  </span>
                </li>
              ))}
            </ul>
            <Link to="/vigilance/licenciement-collectif">
              <Button size="sm" className="mt-3 w-full">Ouvrir le simulateur</Button>
            </Link>
          </Card>

          <LegalDisclaimer />
        </aside>
      </div>
    </div>
  )
}
