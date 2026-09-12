import { useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useApp } from '@/context/AppContext'
import { useCompany, useShiftTemplates } from '@/lib/queries'
import { supabase } from '@/lib/supabase'
import {
  Button, Card, EmptyState, ErrorNote, Field, Input, Loading, Select, Table,
} from '@/components/ui'
import { time } from '@/lib/format'

const EMPTY = { nom: '', heure_debut: '09:00', heure_fin: '17:00', pause_minutes: '30', couleur: '#017E84', service_id: '' }

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
      const { error } = await supabase.from('modeles_creneau').insert({
        societe_id: activeCompanyId!,
        nom: form.nom,
        heure_debut: form.heure_debut,
        heure_fin: form.heure_fin,
        pause_minutes: Number(form.pause_minutes || 0),
        couleur: form.couleur,
        service_id: form.service_id || null,
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
    const { error } = await supabase.from('modeles_creneau').delete().eq('id', id)
    if (error) setErr(new Error(error.message))
    else await qc.invalidateQueries({ queryKey: ['shift-templates'] })
  }

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">Modèles de creneaux</h1>
        <p className="text-xs text-ink-muted">
          Bibliothèque réutilisable : glissez un modèle sur une case du planning pour créer un shift.
        </p>
      </header>

      <Card title="Nouveau modèle">
        <div className="grid gap-3 sm:grid-cols-6">
          <Field label="Nom" required>
            <Input value={form.nom} onChange={(e) => setForm({ ...form, nom: e.target.value })} placeholder="Service soir" />
          </Field>
          <Field label="Début" required>
            <Input type="time" value={form.heure_debut} onChange={(e) => setForm({ ...form, heure_debut: e.target.value })} />
          </Field>
          <Field label="Fin" required hint="Une fin antérieure au début franchit minuit.">
            <Input type="time" value={form.heure_fin} onChange={(e) => setForm({ ...form, heure_fin: e.target.value })} />
          </Field>
          <Field label="Pause (min)">
            <Input type="number" value={form.pause_minutes} onChange={(e) => setForm({ ...form, pause_minutes: e.target.value })} />
          </Field>
          <Field label="Service">
            <Select value={form.service_id} onChange={(e) => setForm({ ...form, service_id: e.target.value })}>
              <option value="">Tous</option>
              {(company.data?.services ?? []).map((d) => (
                <option key={d.id} value={d.id}>{d.nom}</option>
              ))}
            </Select>
          </Field>
          <Field label="Couleur">
            <Input type="color" value={form.couleur} onChange={(e) => setForm({ ...form, couleur: e.target.value })} className="h-[38px] p-1" />
          </Field>
        </div>
        <ErrorNote error={err} />
        <div className="mt-4 flex justify-end">
          <Button variant="primary" onClick={create} disabled={busy || !form.nom}>
            {busy ? 'Enregistrement…' : 'Ajouter le modèle'}
          </Button>
        </div>
      </Card>

      <Card dense>
        {(data ?? []).length === 0 ? (
          <EmptyState title="Aucun modèle" detail="Créez vos creneaux types pour construire les plannings plus vite." />
        ) : (
          <Table head={['Modèle', 'Horaire', 'Pause', 'Service', '']}>
            {(data ?? []).map((t) => (
              <tr key={t.id}>
                <td className="lux-td">
                  <span className="inline-flex items-center gap-2">
                    <span className="h-3 w-3 rounded-sm" style={{ background: t.couleur }} aria-hidden />
                    <span className="font-medium text-ink">{t.nom}</span>
                  </span>
                </td>
                <td className="lux-td font-mono">{time(t.heure_debut)} – {time(t.heure_fin)}</td>
                <td className="lux-td">{t.pause_minutes} min</td>
                <td className="lux-td">
                  {(company.data?.services ?? []).find((d) => d.id === t.service_id)?.nom ?? 'Tous'}
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
