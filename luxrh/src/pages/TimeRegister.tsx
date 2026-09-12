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
  const salaries = useEmployees(activeCompanyId ?? undefined)
  const upsert = useUpsertTimeEntry()

  const [form, setForm] = useState({
    salarie_id: '', date_releve: referenceDate, heure_debut: '09:00', heure_fin: '17:00',
    pause_minutes: '30', heures_prevues: '', note: '',
  })

  const worked = useMemo(() => {
    const [sh, sm] = form.heure_debut.split(':').map(Number)
    const [eh, em] = form.heure_fin.split(':').map(Number)
    let mins = eh * 60 + em - (sh * 60 + sm)
    if (mins <= 0) mins += 24 * 60
    return Math.round((mins - Number(form.pause_minutes || 0)) / 0.6) / 100
  }, [form.heure_debut, form.heure_fin, form.pause_minutes])

  function exportCsv() {
    const rows = [
      ['Salarié', 'Date', 'Début', 'Fin', 'Pause (min)', 'Heures prestées', 'Heures prévues', 'Écart', 'Validé'],
      ...(entries.data ?? []).map((e) => [
        `${e.salaries?.prenom ?? ''} ${e.salaries?.nom ?? ''}`.trim(),
        e.date_releve, e.heure_debut ?? '', e.heure_fin ?? '', String(e.pause_minutes),
        String(e.heures_travaillees ?? ''), String(e.heures_prevues ?? ''),
        String(Number(e.heures_travaillees ?? 0) - Number(e.heures_prevues ?? 0)),
        e.valide ? 'oui' : 'non',
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
            <Select value={form.salarie_id} onChange={(e) => setForm({ ...form, salarie_id: e.target.value })}>
              <option value="">Choisir…</option>
              {(salaries.data ?? []).map((e) => (
                <option key={e.id} value={e.id}>{e.nom} {e.prenom}</option>
              ))}
            </Select>
          </Field>
          <Field label="Date" required>
            <Input type="date" value={form.date_releve} onChange={(e) => setForm({ ...form, date_releve: e.target.value })} />
          </Field>
          <Field label="Début"><Input type="time" value={form.heure_debut} onChange={(e) => setForm({ ...form, heure_debut: e.target.value })} /></Field>
          <Field label="Fin"><Input type="time" value={form.heure_fin} onChange={(e) => setForm({ ...form, heure_fin: e.target.value })} /></Field>
          <Field label="Pause (min)"><Input type="number" value={form.pause_minutes} onChange={(e) => setForm({ ...form, pause_minutes: e.target.value })} /></Field>
          <Field label="Heures prévues" hint={`Presté calculé : ${num(worked, 2)} h`}>
            <Input type="number" step="0.25" value={form.heures_prevues} onChange={(e) => setForm({ ...form, heures_prevues: e.target.value })} />
          </Field>
        </div>
        <ErrorNote error={upsert.error} />
        <div className="mt-4 flex justify-end">
          <Button
            variant="primary"
            disabled={!form.salarie_id || upsert.isPending}
            onClick={() =>
              upsert.mutate({
                societe_id: activeCompanyId,
                salarie_id: form.salarie_id,
                date_releve: form.date_releve,
                heure_debut: form.heure_debut,
                heure_fin: form.heure_fin,
                pause_minutes: Number(form.pause_minutes || 0),
                heures_travaillees: worked,
                heures_prevues: form.heures_prevues ? Number(form.heures_prevues) : null,
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
              const gap = Number(e.heures_travaillees ?? 0) - Number(e.heures_prevues ?? 0)
              return (
                <tr key={e.id}>
                  <td className="lux-td">{e.salaries?.prenom} {e.salaries?.nom}</td>
                  <td className="lux-td font-mono">{date(e.date_releve)}</td>
                  <td className="lux-td font-mono">{e.heure_debut?.slice(0, 5) ?? '—'}</td>
                  <td className="lux-td font-mono">{e.heure_fin?.slice(0, 5) ?? '—'}</td>
                  <td className="lux-td">{e.pause_minutes} min</td>
                  <td className="lux-td font-mono font-semibold">{num(e.heures_travaillees, 2)} h</td>
                  <td className="lux-td font-mono">{e.heures_prevues !== null ? `${num(e.heures_prevues, 2)} h` : '—'}</td>
                  <td className={`lux-td font-mono ${gap > 0 ? 'text-warn-ink' : gap < 0 ? 'text-danger-ink' : ''}`}>
                    {e.heures_prevues !== null ? `${gap > 0 ? '+' : ''}${num(gap, 2)} h` : '—'}
                  </td>
                  <td className="lux-td">
                    <Badge tone={e.valide ? 'ok' : 'neutral'}>{e.valide ? 'validé' : 'saisi'}</Badge>
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
