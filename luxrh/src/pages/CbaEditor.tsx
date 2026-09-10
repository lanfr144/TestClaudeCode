import { useEffect, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useCollectiveAgreements, useLegalParameters } from '@/lib/queries'
import { supabase } from '@/lib/supabase'
import type { Json } from '@/lib/database.types'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, Table,
} from '@/components/ui'
import { date, eur, num } from '@/lib/format'

const BLOCKS = [
  { key: 'salary_grid', label: 'Grille de salaires' },
  { key: 'worktime', label: 'Durée de travail' },
  { key: 'leave', label: 'Congés' },
  { key: 'surcharges', label: 'Majorations' },
  { key: 'premiums', label: 'Primes' },
  { key: 'notice_probation', label: 'Préavis & essai' },
  { key: 'custom_holidays', label: 'Jours fériés d’usage' },
] as const

/** Champs du bloc « majorations » : le formulaire alimente le moteur, pas du code. */
const SURCHARGE_FIELDS = [
  { key: 'night_pct', label: 'Travail de nuit', note: 'Aucune majoration légale générale.', min: null },
  { key: 'sunday_pct', label: 'Dimanche', note: 'Minimum légal', min: 'sunday_surcharge_pct' },
  { key: 'holiday_pct', label: 'Jour férié travaillé', note: 'Total légal', min: 'holiday_surcharge_pct' },
  { key: 'overtime_money_pct', label: 'Heure supplémentaire', note: 'Compensation en argent, légal', min: 'overtime_money_pct' },
] as const

export default function CbaEditor() {
  const { data, isLoading, error } = useCollectiveAgreements()
  const params = useLegalParameters()
  const qc = useQueryClient()
  const [cbaId, setCbaId] = useState<string>('')
  const [block, setBlock] = useState<(typeof BLOCKS)[number]['key']>('surcharges')
  const [draft, setDraft] = useState<Record<string, unknown>>({})
  const [saveError, setSaveError] = useState<unknown>(null)
  const [busy, setBusy] = useState(false)

  const cba = (data ?? []).find((c) => c.id === cbaId) ?? (data ?? [])[0]
  const rules = (cba?.cba_rules ?? []).find((r) => r.block === block)

  useEffect(() => {
    setDraft((rules?.rules as unknown as Record<string, unknown>) ?? {})
  }, [rules?.id, block, cba?.id])

  const legalMin = (key: string | null) =>
    key ? params.data?.find((p) => p.param_key === key && !p.valid_to) : undefined

  const isShared = cba && cba.organization_id === null

  async function save() {
    if (!cba || !rules) return
    setBusy(true)
    setSaveError(null)
    try {
      const { error } = await supabase
        .from('cba_rules')
        .update({ rules: draft as unknown as Json })
        .eq('id', rules.id)
      if (error) throw new Error(error.message)
      await qc.invalidateQueries({ queryKey: ['cba'] })
    } catch (e) {
      setSaveError(e)
    } finally {
      setBusy(false)
    }
  }

  async function duplicate() {
    if (!cba) return
    setBusy(true)
    setSaveError(null)
    try {
      const { data: profile } = await supabase.from('profiles').select('organization_id').single()
      const { data: created, error } = await supabase
        .from('collective_agreements')
        .insert({
          organization_id: profile!.organization_id,
          code: `${cba.code}-COPIE`,
          name: `${cba.name} (copie)`,
          sector: cba.sector,
          valid_from: cba.valid_from,
          valid_to: cba.valid_to,
          is_active: false,
        })
        .select()
        .single()
      if (error) throw new Error(error.message)
      for (const r of cba.cba_rules ?? []) {
        await supabase
          .from('cba_rules')
          .insert({ collective_agreement_id: created.id, block: r.block, rules: r.rules, is_complete: r.is_complete })
      }
      for (const g of cba.cba_salary_grids ?? []) {
        await supabase.from('cba_salary_grids').insert({
          collective_agreement_id: created.id,
          category: g.category,
          seniority_from_years: g.seniority_from_years,
          seniority_to_years: g.seniority_to_years,
          monthly_amount: g.monthly_amount,
          index_ref: g.index_ref,
        })
      }
      await qc.invalidateQueries({ queryKey: ['cba'] })
      setCbaId(created.id)
    } catch (e) {
      setSaveError(e)
    } finally {
      setBusy(false)
    }
  }

  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />
  if (!cba) return <Card title="Aucune convention collective">Le référentiel ne contient aucune CCT.</Card>

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">{cba.name}</h1>
          <p className="text-xs text-ink-muted">
            Secteur {cba.sector} · validité {date(cba.valid_from)} → {date(cba.valid_to)}
            {isShared && ' · CCT pré-chargée, en lecture seule'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={cba.id} onChange={(e) => setCbaId(e.target.value)} className="max-w-xs">
            {(data ?? []).map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </Select>
          <Button size="sm" onClick={duplicate} disabled={busy}>
            Dupliquer
          </Button>
          <Badge tone={cba.is_active ? 'ok' : 'neutral'}>{cba.is_active ? 'Active' : 'Brouillon'}</Badge>
        </div>
      </header>

      <nav className="flex flex-wrap gap-1.5" aria-label="Blocs de règles">
        {BLOCKS.map((b) => {
          const r = (cba.cba_rules ?? []).find((x) => x.block === b.key)
          return (
            <button
              key={b.key}
              onClick={() => setBlock(b.key)}
              className={`flex min-h-[34px] items-center gap-1.5 rounded border px-3 text-xs font-semibold ${
                block === b.key
                  ? 'border-violet bg-violet-veil text-violet-deep'
                  : 'border-rule-strong bg-white text-ink-muted hover:bg-rule-rail'
              }`}
            >
              {b.label}
              <span className={r?.is_complete ? 'text-success' : 'text-ink-faint'}>
                {r?.is_complete ? '✓' : '○'}
              </span>
            </button>
          )
        })}
      </nav>

      <div className="grid gap-4 lg:grid-cols-[1fr_320px]">
        <Card title={BLOCKS.find((b) => b.key === block)?.label}>
          <p className="mb-4 text-xs text-ink-muted">
            Aucune règle n’est écrite en code : ce formulaire alimente le moteur.
          </p>

          {block === 'surcharges' && (
            <div className="space-y-3">
              {SURCHARGE_FIELDS.map((f) => {
                const min = legalMin(f.min)
                const value = Number(draft[f.key] ?? 0)
                const below = min && value < Number(min.value_num)
                return (
                  <div key={f.key} className="flex items-center gap-3 border-b border-rule pb-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-ink">{f.label}</p>
                      <p className="text-xs text-ink-muted">
                        {f.note}
                        {min && ` ${num(min.value_num, 0)} %`}
                        {min && !below && ' — respecté'}
                      </p>
                    </div>
                    <div className="w-28">
                      <Input
                        type="number"
                        disabled={isShared}
                        value={String(draft[f.key] ?? '')}
                        onChange={(e) => setDraft({ ...draft, [f.key]: Number(e.target.value) })}
                      />
                    </div>
                    <span className="w-6 text-sm text-ink-muted">%</span>
                  </div>
                )
              })}
              <p className="rounded border border-warn/25 bg-warn-veil px-3 py-2 text-xs text-warn-ink">
                Une valeur inférieure au minimum légal est refusée à l’enregistrement : la CCT ne peut pas être
                moins favorable que la loi.
              </p>
            </div>
          )}

          {block === 'leave' && (
            <div className="grid gap-3 sm:grid-cols-2">
              <Field
                label="Congé annuel (jours)"
                hint={`Minimum légal : ${num(legalMin('annual_leave_min_days')?.value_num, 0)} j.`}
              >
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.annual_days ?? '')}
                  onChange={(e) => setDraft({ ...draft, annual_days: Number(e.target.value) })}
                />
              </Field>
              <Field label="Report autorisé jusqu’au" hint="Format MM-JJ.">
                <Input
                  disabled={isShared}
                  value={String(draft.carry_over_until ?? '')}
                  onChange={(e) => setDraft({ ...draft, carry_over_until: e.target.value })}
                />
              </Field>
            </div>
          )}

          {block === 'worktime' && (
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Durée hebdomadaire (h)">
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.weekly_hours ?? '')}
                  onChange={(e) => setDraft({ ...draft, weekly_hours: Number(e.target.value) })}
                />
              </Field>
              <Field
                label="Période de référence (mois)"
                hint={`Maximum légal : ${num(legalMin('max_reference_period_months')?.value_num, 0)} mois.`}
              >
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.reference_period_months ?? '')}
                  onChange={(e) => setDraft({ ...draft, reference_period_months: Number(e.target.value) })}
                />
              </Field>
              <Field label="Pause (min)">
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.break_minutes ?? '')}
                  onChange={(e) => setDraft({ ...draft, break_minutes: Number(e.target.value) })}
                />
              </Field>
              <Field label="Plage de nuit">
                <Input
                  disabled={isShared}
                  value={String(draft.night_window ?? '')}
                  onChange={(e) => setDraft({ ...draft, night_window: e.target.value })}
                />
              </Field>
            </div>
          )}

          {block === 'salary_grid' && (
            <Table head={['Catégorie', 'Ancienneté', 'Montant mensuel', 'Indice']}>
              {(cba.cba_salary_grids ?? [])
                .sort((a, b) => a.category.localeCompare(b.category) || a.seniority_from_years - b.seniority_from_years)
                .map((g) => (
                  <tr key={g.id}>
                    <td className="lux-td font-medium">{g.category}</td>
                    <td className="lux-td">
                      {num(g.seniority_from_years, 0)} – {g.seniority_to_years ? num(g.seniority_to_years, 0) : '+'} ans
                    </td>
                    <td className="lux-td font-mono">{eur(g.monthly_amount)}</td>
                    <td className="lux-td font-mono">{g.index_ref ? num(g.index_ref, 2) : '—'}</td>
                  </tr>
                ))}
            </Table>
          )}

          {(block === 'premiums' || block === 'custom_holidays' || block === 'notice_probation') && (
            <Field label="Règles du bloc (JSON)" hint="Édition libre tant que le formulaire dédié n’est pas ouvert.">
              <textarea
                disabled={isShared}
                className="lux-input min-h-[160px] font-mono text-xs"
                value={JSON.stringify(draft, null, 2)}
                onChange={(e) => {
                  try {
                    setDraft(JSON.parse(e.target.value))
                    setSaveError(null)
                  } catch {
                    setSaveError(new Error('JSON invalide'))
                  }
                }}
              />
            </Field>
          )}

          <ErrorNote error={saveError} />
          {!isShared && (
            <div className="mt-4 flex justify-end">
              <Button variant="primary" onClick={save} disabled={busy}>
                {busy ? 'Enregistrement…' : 'Enregistrer le bloc'}
              </Button>
            </div>
          )}
          {isShared && (
            <p className="mt-4 text-xs text-ink-muted">
              Cette CCT est livrée avec l’application. Dupliquez-la pour créer votre propre version modifiable.
            </p>
          )}
        </Card>

        <aside className="space-y-3">
          <LegalBasis
            reference="art. L.162-12"
            text="Une convention collective ne peut comporter de dispositions moins favorables au salarié que celles prévues par la loi."
            source="Legilux"
          />
          <Card title="Arbitrage">
            <p className="text-xs leading-relaxed text-ink-muted">
              Pour chaque règle, le moteur compare la valeur légale, la valeur conventionnelle et la valeur
              contractuelle, retient la plus favorable au salarié et conserve la trace de la norme retenue.
            </p>
          </Card>
        </aside>
      </div>
    </div>
  )
}
