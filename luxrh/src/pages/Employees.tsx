import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useEmployees, useVigilance } from '@/lib/queries'
import {
  Avatar, Badge, Button, Card, EmptyState, ErrorNote, Input, Loading, Select, Table,
} from '@/components/ui'
import { RESIDENCY_LABEL, initials } from '@/lib/format'

type StatusFilter = 'all' | 'active' | 'probation' | 'ended'

const PAGE = 50

export default function Employees() {
  const { activeCompanyId, referenceDate } = useApp()
  const { data, isLoading, error } = useEmployees(activeCompanyId ?? undefined)
  const scan = useVigilance(activeCompanyId ?? undefined, referenceDate)
  const [q, setQ] = useState('')
  const [status, setStatus] = useState<StatusFilter>('active')
  // Volume cible : 1 000 salaries. On affiche par pages plutot que tout d'un coup.
  const [shown, setShown] = useState(PAGE)

  // La conformité affichée vient du moteur, pas d'un calcul local.
  const alertsByEmployee = useMemo(() => {
    const m = new Map<string, { label: string; tone: 'blocking' | 'warning' | 'info' }>()
    for (const i of scan.data?.items ?? []) {
      if (!i.employee_id) continue
      const label =
        i.rule_code === 'probation_deadline'
          ? `Essai · J-${i.days_left}`
          : i.rule_code === 'cdd_term'
            ? `CDD J-${i.days_left}`
            : i.rule_code === 'missing_certificate'
              ? 'Certificat ✕'
              : i.title
      const tone = i.severity
      const prev = m.get(i.employee_id)
      if (!prev || (prev.tone !== 'blocking' && tone === 'blocking')) m.set(i.employee_id, { label, tone })
    }
    return m
  }, [scan.data])

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />

  const employees = (data ?? []).filter((e) => {
    const active = e.contracts?.find((c) => c.status === 'active')
    if (status === 'active' && !active) return false
    if (status === 'ended' && active) return false
    if (status === 'probation' && !(active?.probation_length && active.status === 'active')) return false
    const hay = `${e.first_name} ${e.last_name} ${active?.job_title ?? ''}`.toLowerCase()
    return hay.includes(q.toLowerCase())
  })

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">{employees.length} salariés</h1>
          <p className="text-xs text-ink-muted">Cliquez sur une ligne pour ouvrir la fiche.</p>
        </div>
        <Link to="/contrats/nouveau">
          <Button variant="primary" size="sm">Nouvel employé et contrat</Button>
        </Link>
      </header>

      <Card dense>
        <div className="flex flex-wrap items-center gap-2 border-b border-rule px-3 py-2.5">
          <Input
            value={q}
            onChange={(e) => {
              setQ(e.target.value)
              setShown(PAGE)
            }}
            placeholder="Rechercher…"
            className="max-w-xs"
          />
          <Select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as StatusFilter)
              setShown(PAGE)
            }}
            className="max-w-[180px]"
          >
            <option value="active">Contrat actif</option>
            <option value="probation">En période d’essai</option>
            <option value="ended">Sans contrat actif</option>
            <option value="all">Tous</option>
          </Select>
        </div>

        {employees.length === 0 ? (
          <EmptyState title="Aucun salarié ne correspond" detail="Ajustez la recherche ou le filtre." />
        ) : (
          <Table head={['Salarié', 'Poste', 'Contrat', 'Temps', 'Résidence', 'Conformité']}>
            {employees.slice(0, shown).map((e) => {
              const c = e.contracts?.find((x) => x.status === 'active') ?? e.contracts?.[0]
              const alert = alertsByEmployee.get(e.id)
              return (
                <tr key={e.id} className="hover:bg-rule-rail/50">
                  <td className="lux-td">
                    <Link to={`/employes/${e.id}`} className="flex items-center gap-2.5">
                      <Avatar text={initials(e.first_name, e.last_name)} />
                      <span className="font-medium text-ink hover:text-action">
                        {e.first_name} {e.last_name}
                      </span>
                    </Link>
                  </td>
                  <td className="lux-td">{c?.job_title ?? '—'}</td>
                  <td className="lux-td">
                    {c ? (
                      <Badge tone={c.kind === 'cdd' ? 'warning' : 'neutral'}>{c.kind.toUpperCase()}</Badge>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="lux-td">{c ? `${c.weekly_hours} h` : '—'}</td>
                  <td className="lux-td">{RESIDENCY_LABEL[e.residency]}</td>
                  <td className="lux-td">
                    {alert ? (
                      <Badge tone={alert.tone}>{alert.label}</Badge>
                    ) : (
                      <Badge tone="ok">Conforme</Badge>
                    )}
                  </td>
                </tr>
              )
            })}
          </Table>
        )}

        {employees.length > shown && (
          <div className="flex items-center justify-between gap-3 border-t border-rule px-3 py-2.5">
            <span className="text-xs text-ink-muted">
              {shown} sur {employees.length} salariés affichés
            </span>
            <Button size="sm" onClick={() => setShown((n) => n + PAGE)}>
              Afficher {Math.min(PAGE, employees.length - shown)} de plus
            </Button>
          </div>
        )}
      </Card>
    </div>
  )
}
