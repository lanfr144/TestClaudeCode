import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useContracts, useVigilance } from '@/lib/queries'
import { Badge, Button, Card, EmptyState, ErrorNote, Input, Loading, Select, Table } from '@/components/ui'
import { date, eur, sansFin } from '@/lib/format'

type Filter = 'all' | 'en_cours' | 'brouillon' | 'termine'

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
    (scan.data?.items ?? []).find((i) => i.contrat_id === contractId)

  const rows = (data ?? []).filter((c) => {
    if (filter !== 'all' && c.statut !== filter) return false
    const name = `${c.salaries?.prenom ?? ''} ${c.salaries?.nom ?? ''} ${c.intitule_poste}`
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
            <option value="en_cours">Actifs</option>
            <option value="brouillon">Brouillons</option>
            <option value="termine">Échus</option>
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
                      {c.salaries?.prenom} {c.salaries?.nom}
                    </Link>
                  </td>
                  <td className="lux-td">
                    <Badge tone={c.genre === 'cdd' ? 'warning' : 'neutral'}>{c.genre.toUpperCase()}</Badge>
                  </td>
                  <td className="lux-td">{c.intitule_poste}</td>
                  <td className="lux-td">{date(c.date_debut)}</td>
                  <td className="lux-td">{sansFin(c.date_fin) ? '—' : date(c.date_fin)}</td>
                  <td className="lux-td font-mono">{eur(c.brut_mensuel)}</td>
                  <td className="lux-td">
                    <Badge tone={c.statut === 'en_cours' ? 'ok' : c.statut === 'brouillon' ? 'info' : 'neutral'}>
                      {c.statut}
                    </Badge>
                  </td>
                  <td className="lux-td">
                    {alert ? (
                      <Badge tone={alert.severite === 'bloquant' ? 'blocking' : 'warning'}>
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
