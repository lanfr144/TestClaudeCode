import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useContracts, useVigilance } from '@/lib/queries'
import { Badge, Button, Card, EmptyState, ErrorNote, Input, Loading, Select, Table } from '@/components/ui'
import { date, eur } from '@/lib/format'

type Filter = 'all' | 'active' | 'draft' | 'ended'

export default function Contracts() {
  const { activeCompanyId, referenceDate } = useApp()
  const { data, isLoading, error } = useContracts(activeCompanyId ?? undefined)
  const scan = useVigilance(activeCompanyId ?? undefined, referenceDate)
  const [filter, setFilter] = useState<Filter>('all')
  const [q, setQ] = useState('')

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />

  const alertFor = (contractId: string) =>
    (scan.data?.items ?? []).find((i) => i.contract_id === contractId)

  const rows = (data ?? []).filter((c) => {
    if (filter !== 'all' && c.status !== filter) return false
    const name = `${c.employees?.first_name ?? ''} ${c.employees?.last_name ?? ''} ${c.job_title}`
    return name.toLowerCase().includes(q.toLowerCase())
  })

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Contrats</h1>
          <p className="text-xs text-ink-muted">Actifs, en essai et échus, avec leurs alertes.</p>
        </div>
        <Link to="/contrats/nouveau">
          <Button variant="primary" size="sm">Nouveau contrat</Button>
        </Link>
      </header>

      <Card dense>
        <div className="flex flex-wrap items-center gap-2 border-b border-rule px-3 py-2.5">
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Rechercher…" className="max-w-xs" />
          <Select value={filter} onChange={(e) => setFilter(e.target.value as Filter)} className="max-w-[180px]">
            <option value="all">Tous les statuts</option>
            <option value="active">Actifs</option>
            <option value="draft">Brouillons</option>
            <option value="ended">Échus</option>
          </Select>
        </div>

        {rows.length === 0 ? (
          <EmptyState title="Aucun contrat" detail="Lancez l’assistant pour en créer un en cinq étapes." />
        ) : (
          <Table head={['Salarié', 'Type', 'Poste', 'Début', 'Fin', 'Brut', 'Statut', 'Alerte']}>
            {rows.map((c) => {
              const alert = alertFor(c.id)
              return (
                <tr key={c.id} className="hover:bg-rule-rail/50">
                  <td className="lux-td">
                    <Link to={`/contrats/${c.id}`} className="font-medium text-ink hover:text-action">
                      {c.employees?.first_name} {c.employees?.last_name}
                    </Link>
                  </td>
                  <td className="lux-td">
                    <Badge tone={c.kind === 'cdd' ? 'warning' : 'neutral'}>{c.kind.toUpperCase()}</Badge>
                  </td>
                  <td className="lux-td">{c.job_title}</td>
                  <td className="lux-td">{date(c.start_date)}</td>
                  <td className="lux-td">{c.end_date ? date(c.end_date) : '—'}</td>
                  <td className="lux-td font-mono">{eur(c.monthly_gross)}</td>
                  <td className="lux-td">
                    <Badge tone={c.status === 'active' ? 'ok' : c.status === 'draft' ? 'info' : 'neutral'}>
                      {c.status}
                    </Badge>
                  </td>
                  <td className="lux-td">
                    {alert ? (
                      <Badge tone={alert.severity === 'blocking' ? 'blocking' : 'warning'}>
                        {alert.days_left !== null ? `J-${alert.days_left}` : 'à surveiller'}
                      </Badge>
                    ) : (
                      '—'
                    )}
                  </td>
                </tr>
              )
            })}
          </Table>
        )}
      </Card>
    </div>
  )
}
