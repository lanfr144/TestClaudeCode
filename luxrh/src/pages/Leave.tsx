import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import {
  useAbsences, useDecideAbsence, useEmployees, useLeaveBalance, usePublicHolidays,
} from '@/lib/queries'
import { Badge, Button, Card, ErrorNote, LegalBasis, Loading } from '@/components/ui'
import { ABSENCE_STATUS_LABEL, addDays, date, iso, num } from '@/lib/format'
import type { AbsenceRow } from '@/lib/queries'

const CATEGORY_STYLE: Record<string, string> = {
  annual_leave: 'bg-action text-white',
  sick: 'bg-warn text-white',
  extraordinary: 'bg-violet text-white',
  compensatory: 'bg-ink-faint text-white',
  unpaid: 'bg-rule-strong text-ink',
  public_holiday: 'bg-violet-veil text-violet-deep',
}

function PendingRequest({ a }: { a: AbsenceRow }) {
  const { referenceDate } = useApp()
  const balance = useLeaveBalance(a.employee_id, referenceDate)
  const decide = useDecideAbsence()
  const counts = a.absence_types?.counts_against_leave ?? false
  // Le droit applicable est celui en vigueur a la date de la demande, pas le droit actuel.
  const entitlement = (a.absence_types?.absence_entitlements ?? []).find(
    (e) => e.valid_from <= a.start_date && (!e.valid_to || e.valid_to > a.start_date),
  )
  const after = (balance.data?.balance ?? 0) - Number(a.days_count)
  const insufficient = counts && after < 0

  return (
    <li className="px-4 py-3">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div>
          <Link to={`/employes/${a.employee_id}`} className="text-sm font-semibold text-ink hover:text-action">
            {a.employees?.first_name} {a.employees?.last_name}
          </Link>
          <p className="text-xs text-ink-muted">
            {a.absence_types?.label} · {date(a.start_date)} – {date(a.end_date)} ·{' '}
            {num(a.days_count, 2)} jour(s)
          </p>
        </div>
        <Badge tone={insufficient ? 'blocking' : a.absence_types?.category === 'extraordinary' ? 'ok' : 'info'}>
          {insufficient
            ? 'Solde insuffisant'
            : a.absence_types?.category === 'extraordinary'
              ? 'Droit vérifié'
              : 'En attente'}
        </Badge>
      </div>

      <div className="mt-2 grid gap-2 text-xs sm:grid-cols-3">
        {counts && (
          <div className="rounded bg-rule-rail px-2 py-1.5">
            <span className="block text-ink-faint">Solde après</span>
            <span className="font-mono font-semibold text-ink">{num(after, 2)} j</span>
          </div>
        )}
        {entitlement?.days != null && (
          <div className="rounded bg-rule-rail px-2 py-1.5">
            <span className="block text-ink-faint">Droit à cette date</span>
            <span className="font-mono font-semibold text-ink">{num(entitlement.days, 0)} j</span>
          </div>
        )}
        {a.comment && (
          <div className="rounded bg-rule-rail px-2 py-1.5">
            <span className="block text-ink-faint">Commentaire</span>
            <span className="text-ink-body">{a.comment}</span>
          </div>
        )}
      </div>

      {insufficient && (
        <p className="mt-2 rounded border border-danger/25 bg-danger-veil px-2 py-1.5 text-xs text-danger-ink">
          Solde de {num(balance.data?.balance, 2)} j à cette date. La demande dépasse de{' '}
          {num(Math.abs(after), 2)} j le droit acquis.
        </p>
      )}
      {(entitlement?.legal_ref ?? a.absence_types?.legal_ref) && (
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <LegalBasis compact reference={entitlement?.legal_ref ?? a.absence_types?.legal_ref} />
          {entitlement?.frequency_note && (
            <span className="text-2xs text-ink-muted">{entitlement.frequency_note}</span>
          )}
          {entitlement?.career_cap_days != null && (
            <span className="text-2xs text-ink-muted">
              plafond de carrière : {num(entitlement.career_cap_days, 0)} j
            </span>
          )}
        </div>
      )}

      <ErrorNote error={decide.error} />
      <div className="mt-2 flex gap-2">
        <Button
          size="sm" variant="primary" disabled={decide.isPending}
          onClick={() => decide.mutate({ id: a.id, status: 'approved' })}
        >
          Valider
        </Button>
        <Button size="sm" disabled={decide.isPending} onClick={() => decide.mutate({ id: a.id, status: 'refused' })}>
          Refuser
        </Button>
      </div>
    </li>
  )
}

function TeamBalance({ employeeId, name }: { employeeId: string; name: string }) {
  const { referenceDate } = useApp()
  const b = useLeaveBalance(employeeId, referenceDate)
  return (
    <li className="flex items-center justify-between gap-2 px-4 py-2">
      <Link to={`/employes/${employeeId}`} className="truncate text-sm text-ink-body hover:text-action">
        {name}
      </Link>
      <span className="shrink-0 font-mono text-sm font-semibold text-ink">
        {b.isLoading ? '…' : `${num(b.data?.balance, 1)} j`}
      </span>
    </li>
  )
}

export default function Leave() {
  const { activeCompanyId, referenceDate } = useApp()
  const absences = useAbsences(activeCompanyId ?? undefined)
  const employees = useEmployees(activeCompanyId ?? undefined)
  const [monthStart, setMonthStart] = useState(() => `${referenceDate.slice(0, 7)}-01`)
  const holidays = usePublicHolidays(Number(monthStart.slice(0, 4)))

  const days = useMemo(() => {
    const first = new Date(`${monthStart}T00:00:00`)
    const count = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()
    return Array.from({ length: count }, (_, i) => iso(addDays(first, i)))
  }, [monthStart])

  const pending = (absences.data ?? []).filter((a) => a.status === 'pending')
  const withContract = (employees.data ?? []).filter((e) => e.contracts?.some((c) => c.status === 'active'))

  const shiftMonth = (delta: number) => {
    const d = new Date(`${monthStart}T00:00:00`)
    d.setMonth(d.getMonth() + delta)
    setMonthStart(iso(d).slice(0, 8) + '01')
  }

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (absences.isLoading || employees.isLoading) return <Card><Loading /></Card>

  const nextHoliday = (holidays.data ?? []).find((h) => h.holiday_date >= referenceDate)

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Button size="sm" onClick={() => shiftMonth(-1)} aria-label="Mois précédent">←</Button>
          <h1 className="text-xl font-bold capitalize tracking-tight text-ink">
            {new Date(`${monthStart}T00:00:00`).toLocaleDateString('fr-LU', { month: 'long', year: 'numeric' })}
          </h1>
          <Button size="sm" onClick={() => shiftMonth(1)} aria-label="Mois suivant">→</Button>
        </div>
        <div className="flex flex-wrap items-center gap-3 text-2xs">
          {[
            ['annual_leave', 'Congé validé'],
            ['sick', 'Maladie'],
            ['extraordinary', 'Extraordinaire'],
            ['public_holiday', 'Férié'],
          ].map(([k, l]) => (
            <span key={k} className="flex items-center gap-1.5">
              <span className={`h-3 w-3 rounded-sm ${CATEGORY_STYLE[k]}`} aria-hidden />
              {l}
            </span>
          ))}
        </div>
      </header>

      <div className="grid gap-4 xl:grid-cols-[1fr_380px]">
        <div className="space-y-3">
          <Card dense>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[900px] border-collapse">
                <thead>
                  <tr className="border-b border-rule bg-rule-rail/60">
                    <th className="lux-th sticky left-0 w-44 bg-rule-rail/60">Salarié</th>
                    {days.map((d) => {
                      const wd = new Date(`${d}T00:00:00`).getDay()
                      const holiday = (holidays.data ?? []).some((h) => h.holiday_date === d)
                      return (
                        <th
                          key={d}
                          className={`px-0.5 py-2 text-center text-2xs font-medium ${
                            holiday ? 'bg-violet-veil text-violet-deep' : wd === 0 ? 'text-ink-faint' : 'text-ink-muted'
                          }`}
                        >
                          {new Date(`${d}T00:00:00`).getDate()}
                        </th>
                      )
                    })}
                  </tr>
                </thead>
                <tbody className="divide-y divide-rule">
                  {withContract.map((e) => (
                    <tr key={e.id}>
                      <td className="sticky left-0 bg-white px-3 py-1.5 text-sm text-ink-body">
                        <Link to={`/employes/${e.id}`} className="hover:text-action">
                          {e.first_name} {e.last_name}
                        </Link>
                      </td>
                      {days.map((d) => {
                        const a = (absences.data ?? []).find(
                          (x) =>
                            x.employee_id === e.id && x.status !== 'refused' &&
                            x.start_date <= d && x.end_date >= d,
                        )
                        const holiday = (holidays.data ?? []).some((h) => h.holiday_date === d)
                        const style = a
                          ? CATEGORY_STYLE[a.absence_types?.category ?? 'annual_leave']
                          : holiday
                            ? CATEGORY_STYLE.public_holiday
                            : ''
                        return (
                          <td key={d} className="px-0.5 py-1.5">
                            <div
                              title={a ? `${a.absence_types?.label} — ${ABSENCE_STATUS_LABEL[a.status]}` : undefined}
                              className={`mx-auto h-5 w-5 rounded-sm ${style} ${
                                a?.status === 'pending' ? 'opacity-50' : ''
                              } ${!a && !holiday ? 'bg-rule-rail' : ''}`}
                            />
                          </td>
                        )
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>

          <p className="text-xs text-ink-muted">
            Jour férié du mois :{' '}
            {(holidays.data ?? []).filter((h) => h.holiday_date.startsWith(monthStart.slice(0, 7))).length === 0
              ? `aucun. Prochain : ${nextHoliday ? `${date(nextHoliday.holiday_date)} (${nextHoliday.name})` : '—'}`
              : (holidays.data ?? [])
                  .filter((h) => h.holiday_date.startsWith(monthStart.slice(0, 7)))
                  .map((h) => `${date(h.holiday_date)} ${h.name}`)
                  .join(' · ')}
          </p>
        </div>

        <aside className="space-y-3">
          <Card dense title={`Demandes en attente (${pending.length})`}>
            {pending.length === 0 ? (
              <p className="px-4 py-4 text-xs text-ink-muted">Aucune demande à traiter.</p>
            ) : (
              <ul className="divide-y divide-rule">
                {pending.map((a) => (
                  <PendingRequest key={a.id} a={a} />
                ))}
              </ul>
            )}
          </Card>

          <Card dense title="Soldes de l’équipe">
            <ul className="divide-y divide-rule">
              {withContract.slice(0, 15).map((e) => (
                <TeamBalance key={e.id} employeeId={e.id} name={`${e.first_name} ${e.last_name}`} />
              ))}
            </ul>
          </Card>
        </aside>
      </div>
    </div>
  )
}
