import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import {
  useAbsences, useLegalParameters, useSchedules, useVigilance,
} from '@/lib/queries'
import { Badge, Button, Card, ErrorNote, Loading, StatTile } from '@/components/ui'
import { VigilanceBlock } from '@/components/VigilanceItem'
import { date, dateLong, num } from '@/lib/format'

export default function Dashboard() {
  const { activeCompanyId, activeCompany, profile, referenceDate } = useApp()
  const scan = useVigilance(activeCompanyId ?? undefined, referenceDate)
  const schedules = useSchedules(activeCompanyId ?? undefined)
  const absences = useAbsences(activeCompanyId ?? undefined)
  const params = useLegalParameters()

  if (!activeCompanyId) {
    return <Card title="Aucun dossier sélectionné">Choisissez une société dans le sélecteur en haut à droite.</Card>
  }
  if (scan.isLoading) return <Card><Loading label="Analyse de conformité en cours…" /></Card>
  if (scan.error) return <ErrorNote error={scan.error} />

  const s = scan.data!
  const firstName = profile?.full_name?.split(' ')[0] ?? ''
  const attention = s.overdue.length + s.due_soon.length
  const draftSchedules = (schedules.data ?? []).filter((x) => x.status === 'draft')
  const blockingSchedules = s.items.filter((i) => i.rule_code === 'schedule_blocking').length
  const ongoing = (absences.data ?? []).filter(
    (a) => a.status === 'approved' && a.start_date <= referenceDate && a.end_date >= referenceDate,
  )
  const index = params.data?.find((p) => p.param_key === 'wage_index' && !p.valid_to)
  const dc = s.dismissal_counters
  const hc = s.headcount

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-ink">
            Bonjour {firstName} — {attention === 0 ? 'aucun point ne demande votre attention' : `${attention} point${attention > 1 ? 's' : ''} demande${attention > 1 ? 'nt' : ''} votre attention`}
          </h1>
          <p className="mt-0.5 text-sm capitalize text-ink-muted">
            {dateLong(referenceDate)} · {activeCompany?.legal_name} · {hc.headcount.current} salariés
          </p>
        </div>
        <div className="flex gap-2">
          <Link to="/dossiers"><Button size="sm">Toutes les sociétés</Button></Link>
          <Link to="/contrats/nouveau"><Button size="sm" variant="primary">Nouveau contrat</Button></Link>
        </div>
      </header>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <StatTile
          label="En retard" value={s.overdue.length} tone={s.overdue.length ? 'blocking' : 'ok'}
          hint={s.overdue[0]?.title.split('—')[0] ?? 'Rien en retard'}
        />
        <StatTile
          label={`Dans les ${s.horizon_days} jours`} value={s.due_soon.length}
          tone={s.due_soon.length ? 'warning' : 'ok'}
          hint="Essai, CDD, seuil d’effectif"
        />
        <StatTile
          label={`Effectif · ${hc.headcount.reference_months} mois`}
          value={`${hc.headcount.rounded} / ${num(hc.thresholds[0]?.threshold, 0)}`}
          tone={hc.thresholds[0]?.reached ? 'warning' : 'neutral'}
          hint={`Moyenne ${num(hc.headcount.average, 2)} · ${hc.thresholds[0]?.status}`}
        />
        <StatTile
          label="Plannings à publier" value={draftSchedules.length}
          tone={blockingSchedules ? 'blocking' : 'neutral'}
          hint={blockingSchedules ? `dont ${blockingSchedules} avec blocage` : 'aucun blocage'}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-semibold text-ink">Obligations en cours</h2>
            <Link to="/vigilance" className="text-xs font-semibold text-action hover:underline">
              Ouvrir le centre de vigilance →
            </Link>
          </div>
          <VigilanceBlock title="En retard" tone="blocking" items={s.overdue} compact />
          <VigilanceBlock title={`Dans les ${s.horizon_days} jours`} tone="warning" items={s.due_soon} compact />
          <VigilanceBlock title="À surveiller" tone="info" items={s.watch} compact />
        </div>

        <aside className="space-y-3">
          <Card title="Compteur licenciement collectif">
            <div className="space-y-2.5">
              {[
                { label: '30 jours glissants', w: dc.window_30 },
                { label: '90 jours glissants', w: dc.window_90 },
              ].map(({ label, w }) => (
                <div key={label}>
                  <div className="flex items-baseline justify-between">
                    <span className="text-xs text-ink-muted">{label}</span>
                    <span className="font-mono text-sm font-semibold text-ink">
                      {w.count} / {num(w.threshold, 0)}
                    </span>
                  </div>
                  <div className="mt-1 h-1.5 overflow-hidden rounded bg-rule-rail">
                    <div
                      className={`h-full ${w.count >= w.threshold ? 'bg-danger' : 'bg-violet'}`}
                      style={{ width: `${Math.min(100, (w.count / Number(w.threshold)) * 100)}%` }}
                    />
                  </div>
                </div>
              ))}
              <p className="text-xs leading-relaxed text-ink-muted">
                Encore <strong className="text-ink">{dc.window_30.remaining} notification(s)</strong> possibles
                sur 30 jours. Le compteur se libère le{' '}
                <strong className="text-ink">{date(dc.window_30.releases_on)}</strong>.
              </p>
              <Link to="/vigilance/licenciement-collectif">
                <Button size="sm" className="w-full">Simuler un scénario</Button>
              </Link>
            </div>
          </Card>

          <Card title="Absences en cours">
            {ongoing.length === 0 ? (
              <p className="text-xs text-ink-muted">Aucune absence en cours aujourd’hui.</p>
            ) : (
              <ul className="space-y-2">
                {ongoing.map((a) => (
                  <li key={a.id} className="flex items-center justify-between gap-2">
                    <Link
                      to={`/employes/${a.employees?.id}`}
                      className="truncate text-sm text-ink-body hover:text-action"
                    >
                      {a.employees?.first_name} {a.employees?.last_name}
                    </Link>
                    <Badge tone={a.absence_types?.category === 'sick' ? 'warning' : 'info'}>
                      {a.absence_types?.label}
                    </Badge>
                  </li>
                ))}
              </ul>
            )}
          </Card>

          <Card title="Référentiel">
            <p className="text-xs leading-relaxed text-ink-muted">
              Paramètres sociaux à l’indice{' '}
              <strong className="text-ink">{num(index?.value_num, 2)}</strong>, en vigueur depuis le{' '}
              <strong className="text-ink">{date(index?.valid_from)}</strong>.
            </p>
            <Link to="/referentiel" className="mt-2 inline-block text-xs font-semibold text-action hover:underline">
              Consulter le référentiel daté →
            </Link>
          </Card>
        </aside>
      </div>
    </div>
  )
}
