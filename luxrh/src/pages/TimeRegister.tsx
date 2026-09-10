import { useMemo, useState } from 'react'
import { useApp } from '@/context/AppContext'
import { useEmployees, useTimeEntries, useUpsertTimeEntry } from '@/lib/queries'
import {
  Badge, Button, Card, EmptyState, ErrorNote, Field, Input, LegalBasis, Loading, Select, Table,
} from '@/components/ui'
import { date, num } from '@/lib/format'

/** Registre exigé par l'art. L.211-29, exportable et présentable à l'ITM. */
export default function TimeRegister() {
  const { activeCompanyId, referenceDate } = useApp()
  const [from, setFrom] = useState(() => `${referenceDate.slice(0, 7)}-01`)
  const [to, setTo] = useState(referenceDate)
  const entries = useTimeEntries(activeCompanyId ?? undefined, from, to)
  const employees = useEmployees(activeCompanyId ?? undefined)
  const upsert = useUpsertTimeEntry()

  const [form, setForm] = useState({
    employee_id: '', entry_date: referenceDate, start_time: '09:00', end_time: '17:00',
    break_minutes: '30', planned_hours: '', note: '',
  })

  const worked = useMemo(() => {
    const [sh, sm] = form.start_time.split(':').map(Number)
    const [eh, em] = form.end_time.split(':').map(Number)
    let mins = eh * 60 + em - (sh * 60 + sm)
    if (mins <= 0) mins += 24 * 60
    return Math.round((mins - Number(form.break_minutes || 0)) / 0.6) / 100
  }, [form.start_time, form.end_time, form.break_minutes])

  function exportCsv() {
    const rows = [
      ['Salarié', 'Date', 'Début', 'Fin', 'Pause (min)', 'Heures prestées', 'Heures prévues', 'Écart', 'Validé'],
      ...(entries.data ?? []).map((e) => [
        `${e.employees?.first_name ?? ''} ${e.employees?.last_name ?? ''}`.trim(),
        e.entry_date, e.start_time ?? '', e.end_time ?? '', String(e.break_minutes),
        String(e.worked_hours ?? ''), String(e.planned_hours ?? ''),
        String(Number(e.worked_hours ?? 0) - Number(e.planned_hours ?? 0)),
        e.is_validated ? 'oui' : 'non',
      ]),
    ]
    const csv = rows.map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(';')).join('\r\n')
    const url = URL.createObjectURL(new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' }))
    const a = document.createElement('a')
    a.href = url
    a.download = `registre-temps-${from}_${to}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Registre du temps de travail</h1>
          <p className="text-xs text-ink-muted">
            Heures réellement prestées, comparées au prévisionnel. Toute modification est tracée dans le
            journal d’audit ; les données sont conservées 10 ans.
          </p>
        </div>
        <div className="flex items-end gap-2">
          <Field label="Du"><Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} /></Field>
          <Field label="Au"><Input type="date" value={to} onChange={(e) => setTo(e.target.value)} /></Field>
          <Button size="sm" onClick={exportCsv}>Exporter en CSV</Button>
        </div>
      </header>

      <Card title="Saisir une journée">
        <div className="grid gap-3 sm:grid-cols-6">
          <Field label="Salarié" required>
            <Select value={form.employee_id} onChange={(e) => setForm({ ...form, employee_id: e.target.value })}>
              <option value="">Choisir…</option>
              {(employees.data ?? []).map((e) => (
                <option key={e.id} value={e.id}>{e.last_name} {e.first_name}</option>
              ))}
            </Select>
          </Field>
          <Field label="Date" required>
            <Input type="date" value={form.entry_date} onChange={(e) => setForm({ ...form, entry_date: e.target.value })} />
          </Field>
          <Field label="Début"><Input type="time" value={form.start_time} onChange={(e) => setForm({ ...form, start_time: e.target.value })} /></Field>
          <Field label="Fin"><Input type="time" value={form.end_time} onChange={(e) => setForm({ ...form, end_time: e.target.value })} /></Field>
          <Field label="Pause (min)"><Input type="number" value={form.break_minutes} onChange={(e) => setForm({ ...form, break_minutes: e.target.value })} /></Field>
          <Field label="Heures prévues" hint={`Presté calculé : ${num(worked, 2)} h`}>
            <Input type="number" step="0.25" value={form.planned_hours} onChange={(e) => setForm({ ...form, planned_hours: e.target.value })} />
          </Field>
        </div>
        <ErrorNote error={upsert.error} />
        <div className="mt-4 flex justify-end">
          <Button
            variant="primary"
            disabled={!form.employee_id || upsert.isPending}
            onClick={() =>
              upsert.mutate({
                company_id: activeCompanyId,
                employee_id: form.employee_id,
                entry_date: form.entry_date,
                start_time: form.start_time,
                end_time: form.end_time,
                break_minutes: Number(form.break_minutes || 0),
                worked_hours: worked,
                planned_hours: form.planned_hours ? Number(form.planned_hours) : null,
                note: form.note || null,
              })
            }
          >
            {upsert.isPending ? 'Enregistrement…' : 'Enregistrer la journée'}
          </Button>
        </div>
      </Card>

      <Card dense subtitle={`Du ${date(from)} au ${date(to)}`} title="Journées enregistrées">
        {entries.isLoading ? (
          <Loading />
        ) : (entries.data ?? []).length === 0 ? (
          <EmptyState title="Aucune journée sur la période" detail="Saisissez le réel ou importez-le." />
        ) : (
          <Table head={['Salarié', 'Date', 'Début', 'Fin', 'Pause', 'Presté', 'Prévu', 'Écart', 'Statut']}>
            {(entries.data ?? []).map((e) => {
              const gap = Number(e.worked_hours ?? 0) - Number(e.planned_hours ?? 0)
              return (
                <tr key={e.id}>
                  <td className="lux-td">{e.employees?.first_name} {e.employees?.last_name}</td>
                  <td className="lux-td font-mono">{date(e.entry_date)}</td>
                  <td className="lux-td font-mono">{e.start_time?.slice(0, 5) ?? '—'}</td>
                  <td className="lux-td font-mono">{e.end_time?.slice(0, 5) ?? '—'}</td>
                  <td className="lux-td">{e.break_minutes} min</td>
                  <td className="lux-td font-mono font-semibold">{num(e.worked_hours, 2)} h</td>
                  <td className="lux-td font-mono">{e.planned_hours !== null ? `${num(e.planned_hours, 2)} h` : '—'}</td>
                  <td className={`lux-td font-mono ${gap > 0 ? 'text-warn-ink' : gap < 0 ? 'text-danger-ink' : ''}`}>
                    {e.planned_hours !== null ? `${gap > 0 ? '+' : ''}${num(gap, 2)} h` : '—'}
                  </td>
                  <td className="lux-td">
                    <Badge tone={e.is_validated ? 'ok' : 'neutral'}>{e.is_validated ? 'validé' : 'saisi'}</Badge>
                  </td>
                </tr>
              )
            })}
          </Table>
        )}
      </Card>

      <LegalBasis
        reference="art. L.211-29"
        text="L’employeur tient un registre spécial ou un fichier reprenant, pour chaque jour, le début et la fin de la journée de travail ainsi que les heures prestées au-delà de la durée normale."
        validity="conservation 10 ans"
        source="Legilux"
      />
    </div>
  )
}
