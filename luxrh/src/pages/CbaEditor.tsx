import { useEffect, useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { useCollectiveAgreements, useLegalParameters } from '@/lib/queries'
import { useApp } from '@/context/AppContext'
import { supabase } from '@/lib/supabase'
import type { Json } from '@/lib/database.types'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, Table,
} from '@/components/ui'
import { date, estEnVigueur, eur, num, sansFin } from '@/lib/format'

const BLOCKS = [
  { key: 'grille_salaires', label: 'Grille de salaires' },
  { key: 'temps_travail', label: 'Durée de travail' },
  { key: 'conges', label: 'Congés' },
  { key: 'majorations', label: 'Majorations' },
  { key: 'primes', label: 'Primes' },
  { key: 'preavis_essai', label: 'Préavis & essai' },
  { key: 'feries_usage', label: 'Jours fériés d’usage' },
] as const

/** Champs du bloc « majorations » : le formulaire alimente le moteur, pas du code. */
const SURCHARGE_FIELDS = [
  { key: 'night_pct', label: 'Travail de nuit', note: 'Aucune majoration légale générale.', min: null },
  { key: 'sunday_pct', label: 'Dimanche', note: 'Minimum légal', min: 'sunday_surcharge_pct' },
  { key: 'holiday_pct', label: 'Jour férié travaillé', note: 'Total légal', min: 'holiday_surcharge_pct' },
  { key: 'overtime_money_pct', label: 'Heure supplémentaire', note: 'Compensation en argent, légal', min: 'overtime_money_pct' },
] as const

export default function CbaEditor() {
  const { referenceDate } = useApp()
  const { data, isLoading, error } = useCollectiveAgreements()
  const params = useLegalParameters()
  const qc = useQueryClient()
  const [cbaId, setCbaId] = useState<string>('')
  const [block, setBlock] = useState<(typeof BLOCKS)[number]['key']>('majorations')
  const [draft, setDraft] = useState<Record<string, unknown>>({})
  const [saveError, setSaveError] = useState<unknown>(null)
  const [busy, setBusy] = useState(false)

  const cba = (data ?? []).find((c) => c.id === cbaId) ?? (data ?? [])[0]
  const rules = (cba?.regles_convention ?? []).find((r) => r.bloc === block)

  useEffect(() => {
    setDraft((rules?.regles as unknown as Record<string, unknown>) ?? {})
  }, [rules?.id, block, cba?.id])

  const legalMin = (key: string | null) =>
    key
      ? params.data?.find((p) => p.cle_parametre === key && estEnVigueur(p, referenceDate))
      : undefined

  const isShared = cba && cba.organisation_id === null

  async function save() {
    if (!cba || !rules) return
    setBusy(true)
    setSaveError(null)
    try {
      const { error } = await supabase
        .from('regles_convention')
        .update({ regles: draft as unknown as Json })
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
      const { data: profile } = await supabase.from('profils').select('organisation_id').single()
      const { data: created, error } = await supabase
        .from('conventions_collectives')
        .insert({
          organisation_id: profile!.organisation_id,
          code: `${cba.code}-COPIE`,
          nom: `${cba.nom} (copie)`,
          secteur: cba.secteur,
          debut_validite: cba.debut_validite,
          fin_validite: cba.fin_validite,
          actif: false,
        })
        .select()
        .single()
      if (error) throw new Error(error.message)
      for (const r of cba.regles_convention ?? []) {
        await supabase
          .from('regles_convention')
          .insert({ convention_id: created.id, bloc: r.bloc, regles: r.regles, complet: r.complet })
      }
      for (const g of cba.grilles_salaires_convention ?? []) {
        await supabase.from('grilles_salaires_convention').insert({
          convention_id: created.id,
          categorie: g.categorie,
          anciennete_de_annees: g.anciennete_de_annees,
          anciennete_a_annees: g.anciennete_a_annees,
          montant_mensuel: g.montant_mensuel,
          indice_reference: g.indice_reference,
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
          <h1 className="text-xl font-bold tracking-tight text-ink">{cba.nom}</h1>
          <p className="text-xs text-ink-muted">
            Secteur {cba.secteur} · validité {date(cba.debut_validite)} → {sansFin(cba.fin_validite) ? '…' : date(cba.fin_validite)}
            {isShared && ' · CCT pré-chargée, en lecture seule'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={cba.id} onChange={(e) => setCbaId(e.target.value)} className="max-w-xs">
            {(data ?? []).map((c) => (
              <option key={c.id} value={c.id}>{c.nom}</option>
            ))}
          </Select>
          <Button size="sm" onClick={duplicate} disabled={busy}>
            Dupliquer
          </Button>
          <Badge tone={cba.actif ? 'ok' : 'neutral'}>{cba.actif ? 'Active' : 'Brouillon'}</Badge>
        </div>
      </header>

      <nav className="flex flex-wrap gap-1.5" aria-label="Blocs de règles">
        {BLOCKS.map((b) => {
          const r = (cba.regles_convention ?? []).find((x) => x.bloc === b.key)
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
              <span className={r?.complet ? 'text-success' : 'text-ink-faint'}>
                {r?.complet ? '✓' : '○'}
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

          {block === 'majorations' && (
            <div className="space-y-3">
              {SURCHARGE_FIELDS.map((f) => {
                const min = legalMin(f.min)
                const value = Number(draft[f.key] ?? 0)
                const below = min && value < Number(min.valeur_num)
                return (
                  <div key={f.key} className="flex items-center gap-3 border-b border-rule pb-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-ink">{f.label}</p>
                      <p className="text-xs text-ink-muted">
                        {f.note}
                        {min && ` ${num(min.valeur_num, 0)} %`}
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

          {block === 'conges' && (
            <div className="grid gap-3 sm:grid-cols-2">
              <Field
                label="Congé annuel (jours)"
                hint={`Minimum légal : ${num(legalMin('annual_leave_min_days')?.valeur_num, 0)} j.`}
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

          {block === 'temps_travail' && (
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Durée hebdomadaire (h)">
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.heures_hebdomadaires ?? '')}
                  onChange={(e) => setDraft({ ...draft, heures_hebdomadaires: Number(e.target.value) })}
                />
              </Field>
              <Field
                label="Période de référence (mois)"
                hint={`Maximum légal : ${num(legalMin('max_reference_period_months')?.valeur_num, 0)} mois.`}
              >
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.periode_reference_mois ?? '')}
                  onChange={(e) => setDraft({ ...draft, periode_reference_mois: Number(e.target.value) })}
                />
              </Field>
              <Field label="Pause (min)">
                <Input
                  type="number" disabled={isShared}
                  value={String(draft.pause_minutes ?? '')}
                  onChange={(e) => setDraft({ ...draft, pause_minutes: Number(e.target.value) })}
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

          {block === 'grille_salaires' && (
            <Table head={['Catégorie', 'Ancienneté', 'Montant mensuel', 'Indice']}>
              {(cba.grilles_salaires_convention ?? [])
                .sort((a, b) => a.categorie.localeCompare(b.categorie) || a.anciennete_de_annees - b.anciennete_de_annees)
                .map((g) => (
                  <tr key={g.id}>
                    <td className="lux-td font-medium">{g.categorie}</td>
                    <td className="lux-td">
                      {num(g.anciennete_de_annees, 0)} – {g.anciennete_a_annees ? num(g.anciennete_a_annees, 0) : '+'} ans
                    </td>
                    <td className="lux-td font-mono">{eur(g.montant_mensuel)}</td>
                    <td className="lux-td font-mono">{g.indice_reference ? num(g.indice_reference, 2) : '—'}</td>
                  </tr>
                ))}
            </Table>
          )}

          {(block === 'primes' || block === 'feries_usage' || block === 'preavis_essai') && (
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
