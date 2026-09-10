import { useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useApp } from '@/context/AppContext'
import { useCompany, useShiftTemplates } from '@/lib/queries'
import { supabase } from '@/lib/supabase'
import {
  Button, Card, EmptyState, ErrorNote, Field, Input, Loading, Select, Table,
} from '@/components/ui'
import { time } from '@/lib/format'

const EMPTY = { name: '', start_time: '09:00', end_time: '17:00', break_minutes: '30', color: '#017E84', department_id: '' }

export default function ShiftTemplates() {
  const { activeCompanyId } = useApp()
  const { data, isLoading, error } = useShiftTemplates(activeCompanyId ?? undefined)
  const company = useCompany(activeCompanyId ?? undefined)
  const qc = useQueryClient()
  const [form, setForm] = useState(EMPTY)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<unknown>(null)

  async function create() {
    setBusy(true)
    setErr(null)
    try {
      const { error } = await supabase.from('shift_templates').insert({
        company_id: activeCompanyId!,
        name: form.name,
        start_time: form.start_time,
        end_time: form.end_time,
        break_minutes: Number(form.break_minutes || 0),
        color: form.color,
        department_id: form.department_id || null,
      })
      if (error) throw new Error(error.message)
      await qc.invalidateQueries({ queryKey: ['shift-templates'] })
      setForm(EMPTY)
    } catch (e) {
      setErr(e)
    } finally {
      setBusy(false)
    }
  }

  async function remove(id: string) {
    const { error } = await supabase.from('shift_templates').delete().eq('id', id)
    if (error) setErr(new Error(error.message))
    else await qc.invalidateQueries({ queryKey: ['shift-templates'] })
  }

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">Modèles de shifts</h1>
        <p className="text-xs text-ink-muted">
          Bibliothèque réutilisable : glissez un modèle sur une case du planning pour créer un shift.
        </p>
      </header>

      <Card title="Nouveau modèle">
        <div className="grid gap-3 sm:grid-cols-6">
          <Field label="Nom" required>
            <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Service soir" />
          </Field>
          <Field label="Début" required>
            <Input type="time" value={form.start_time} onChange={(e) => setForm({ ...form, start_time: e.target.value })} />
          </Field>
          <Field label="Fin" required hint="Une fin antérieure au début franchit minuit.">
            <Input type="time" value={form.end_time} onChange={(e) => setForm({ ...form, end_time: e.target.value })} />
          </Field>
          <Field label="Pause (min)">
            <Input type="number" value={form.break_minutes} onChange={(e) => setForm({ ...form, break_minutes: e.target.value })} />
          </Field>
          <Field label="Service">
            <Select value={form.department_id} onChange={(e) => setForm({ ...form, department_id: e.target.value })}>
              <option value="">Tous</option>
              {(company.data?.departments ?? []).map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </Select>
          </Field>
          <Field label="Couleur">
            <Input type="color" value={form.color} onChange={(e) => setForm({ ...form, color: e.target.value })} className="h-[38px] p-1" />
          </Field>
        </div>
        <ErrorNote error={err} />
        <div className="mt-4 flex justify-end">
          <Button variant="primary" onClick={create} disabled={busy || !form.name}>
            {busy ? 'Enregistrement…' : 'Ajouter le modèle'}
          </Button>
        </div>
      </Card>

      <Card dense>
        {(data ?? []).length === 0 ? (
          <EmptyState title="Aucun modèle" detail="Créez vos shifts types pour construire les plannings plus vite." />
        ) : (
          <Table head={['Modèle', 'Horaire', 'Pause', 'Service', '']}>
            {(data ?? []).map((t) => (
              <tr key={t.id}>
                <td className="lux-td">
                  <span className="inline-flex items-center gap-2">
                    <span className="h-3 w-3 rounded-sm" style={{ background: t.color }} aria-hidden />
                    <span className="font-medium text-ink">{t.name}</span>
                  </span>
                </td>
                <td className="lux-td font-mono">{time(t.start_time)} – {time(t.end_time)}</td>
                <td className="lux-td">{t.break_minutes} min</td>
                <td className="lux-td">
                  {(company.data?.departments ?? []).find((d) => d.id === t.department_id)?.name ?? 'Tous'}
                </td>
                <td className="lux-td">
                  <button onClick={() => remove(t.id)} className="text-xs font-semibold text-danger hover:underline">
                    Supprimer
                  </button>
                </td>
              </tr>
            ))}
          </Table>
        )}
      </Card>
    </div>
  )
}
