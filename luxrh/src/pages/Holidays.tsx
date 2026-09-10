import { useState } from 'react'
import { usePublicHolidays } from '@/lib/queries'
import { Badge, Button, Card, ErrorNote, LegalBasis, Loading, Table } from '@/components/ui'
import { date } from '@/lib/format'

export default function Holidays() {
  const [year, setYear] = useState(new Date().getFullYear())
  const { data, isLoading, error } = usePublicHolidays(year)

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Jours fériés légaux</h1>
          <p className="text-xs text-ink-muted">
            Générés par algorithme à partir de la date de Pâques, jamais saisis à la main.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" onClick={() => setYear((y) => y - 1)}>←</Button>
          <span className="min-w-[64px] text-center text-lg font-bold text-ink">{year}</span>
          <Button size="sm" onClick={() => setYear((y) => y + 1)}>→</Button>
        </div>
      </header>

      {error && <ErrorNote error={error} />}

      <div className="grid gap-4 lg:grid-cols-[1fr_320px]">
        <Card dense>
          {isLoading ? (
            <Loading />
          ) : (
            <Table head={['Date', 'Jour', 'Fête', 'Type']}>
              {(data ?? []).map((h) => (
                <tr key={h.id}>
                  <td className="lux-td font-mono">{date(h.holiday_date)}</td>
                  <td className="lux-td capitalize">
                    {new Date(`${h.holiday_date}T00:00:00`).toLocaleDateString('fr-LU', { weekday: 'long' })}
                  </td>
                  <td className="lux-td font-medium text-ink">{h.name}</td>
                  <td className="lux-td">
                    <Badge tone={h.is_mobile ? 'violet' : 'neutral'}>
                      {h.is_mobile ? 'fête mobile' : 'date fixe'}
                    </Badge>
                  </td>
                </tr>
              ))}
              {(data ?? []).length === 0 && (
                <tr>
                  <td className="lux-td text-ink-muted" colSpan={4}>
                    Aucun jour férié généré pour {year}.
                  </td>
                </tr>
              )}
            </Table>
          )}
        </Card>

        <aside className="space-y-3">
          <LegalBasis
            reference="art. L.232-2"
            text="Onze jours fériés légaux, dont la Journée de l'Europe du 9 mai."
            value={`${(data ?? []).length} jours`}
            validity={String(year)}
            source="Legilux"
          />
          <Card title="Fêtes mobiles">
            <p className="text-xs leading-relaxed text-ink-muted">
              Lundi de Pâques, Ascension et Lundi de Pentecôte sont calculés à partir du comput ecclésiastique
              (algorithme de Gauss-Meeus), ce qui garantit une génération correcte pour toute année demandée.
            </p>
            <p className="mt-2 text-xs leading-relaxed text-ink-muted">
              Un jour férié tombant un jour non travaillé ouvre droit à un jour de compensation. Une CCT peut
              ajouter ses propres jours fériés d'usage.
            </p>
          </Card>
        </aside>
      </div>
    </div>
  )
}
