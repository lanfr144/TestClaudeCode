import { useMemo, useState } from 'react'
import { useApp } from '@/context/AppContext'
import {
  useAddParameterVersion, useLegalParameters, useReferentialGaps, useReferentialHoles,
  useReferentialInconsistencies,
} from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, SeverityMark, Table,
} from '@/components/ui'
import { date, num, sansFin } from '@/lib/format'
import type { LegalParameter } from '@/lib/queries'

const FAMILY_LABEL: Record<string, string> = {
  social: 'Paramètres sociaux',
  fiscal: 'Paramètres fiscaux',
  worktime: 'Temps de travail',
  leave: 'Congés et absences',
  contract: 'Cycle de vie du contrat',
  headcount: 'Seuils d’effectif',
}

function formatValue(p: LegalParameter) {
  if (p.value_num !== null) return `${num(p.value_num, 4)}${p.unit ? ` ${p.unit}` : ''}`
  if (p.value_text !== null) return p.value_text
  return JSON.stringify(p.value_json)
}

export default function Referential() {
  const { referenceDate, setReferenceDate } = useApp()
  const { data, isLoading, error } = useLegalParameters()
  const [family, setFamily] = useState('social')
  const [selected, setSelected] = useState<string | null>(null)
  const [newValue, setNewValue] = useState('')
  const [newFrom, setNewFrom] = useState(referenceDate)
  const gaps = useReferentialGaps('2019-12-31')
  const holes = useReferentialHoles()
  const inconsistencies = useReferentialInconsistencies(referenceDate)
  const addVersion = useAddParameterVersion()

  const inForce = useMemo(
    () =>
      (data ?? []).filter(
        (p) => p.valid_from <= referenceDate && (!p.valid_to || p.valid_to > referenceDate),
      ),
    [data, referenceDate],
  )

  const history = useMemo(
    () => (selected ? (data ?? []).filter((p) => p.param_key === selected) : []),
    [data, selected],
  )

  if (isLoading) return <Card><Loading /></Card>
  if (error) return <ErrorNote error={error} />

  const rows = inForce.filter((p) => p.family === family)
  const selectedInForce = inForce.find((p) => p.param_key === selected)

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Référentiel légal daté</h1>
          <p className="text-xs text-ink-muted">
            Calcul daté : les valeurs lues sont celles en vigueur à la date du calcul, jamais les actuelles.
          </p>
        </div>
        <div className="w-48">
          <Field label="Au">
            <Input type="date" value={referenceDate} onChange={(e) => setReferenceDate(e.target.value)} />
          </Field>
        </div>
      </header>

      <nav className="flex flex-wrap gap-1.5" aria-label="Familles de paramètres">
        {Object.entries(FAMILY_LABEL).map(([k, l]) => (
          <button
            key={k}
            onClick={() => setFamily(k)}
            className={`min-h-[34px] rounded border px-3 text-xs font-semibold ${
              family === k
                ? 'border-violet bg-violet-veil text-violet-deep'
                : 'border-rule-strong bg-white text-ink-muted hover:bg-rule-rail'
            }`}
          >
            {l}
          </button>
        ))}
      </nav>

      <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
        <Card dense title={FAMILY_LABEL[family]} subtitle={`${rows.length} paramètre(s) en vigueur au ${date(referenceDate)}`}>
          <Table head={['Paramètre', 'Valeur', 'En vigueur', 'Indice', 'Source', 'Base légale']}>
            {rows.map((p) => (
              <tr
                key={p.id}
                onClick={() => setSelected(p.param_key)}
                className={`cursor-pointer hover:bg-rule-rail/60 ${
                  selected === p.param_key ? 'bg-violet-veil' : ''
                }`}
              >
                <td className="lux-td">
                  <span className="font-medium text-ink">{p.label}</span>
                  <span className="block font-mono text-2xs text-ink-faint">{p.param_key}</span>
                </td>
                <td className="lux-td whitespace-nowrap font-mono font-semibold text-ink">{formatValue(p)}</td>
                <td className="lux-td whitespace-nowrap">
                  {date(p.valid_from)} → {sansFin(p.valid_to) ? '…' : date(p.valid_to)}
                </td>
                <td className="lux-td font-mono">{p.index_ref ? num(p.index_ref, 2) : '—'}</td>
                <td className="lux-td">{p.source}</td>
                <td className="lux-td font-mono text-2xs">{p.legal_ref ?? '—'}</td>
              </tr>
            ))}
          </Table>
        </Card>

        <aside className="space-y-3">
          {/* Ce que le référentiel ne couvre pas encore, dit explicitement. */}
          <Card title="Couverture du référentiel" subtitle="profondeur exigée : 31.12.2019">
            <div className="grid grid-cols-3 gap-2 text-center">
              <div>
                <p className="text-2xl font-bold text-success-ink">
                  {(gaps.data ?? []).filter((g) => g.covers_since).length}
                </p>
                <p className="text-2xs text-ink-muted">couvrent 2019</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-warn-ink">
                  {(gaps.data ?? []).filter((g) => !g.covers_since).length}
                </p>
                <p className="text-2xs text-ink-muted">à compléter</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-danger-ink">{(holes.data ?? []).length}</p>
                <p className="text-2xs text-ink-muted">trous</p>
              </div>
            </div>
            {(inconsistencies.data ?? []).length > 0 && (
              <div className="mt-3 space-y-1.5 border-t border-rule pt-2.5">
                {(inconsistencies.data ?? []).map((i) => (
                  <p key={i.param_key} className="flex items-start gap-2 text-xs text-warn-ink">
                    <SeverityMark severity="warning" />
                    <span>
                      {i.label} : valeur publiée {num(i.published, 2)}, dérivée de {i.source_key}{' '}
                      {num(i.derived, 2)} — écart de {num(i.difference, 2)}.
                    </span>
                  </p>
                ))}
              </div>
            )}
            <p className="mt-2 text-xs text-ink-muted">
              Aucune valeur n’est inventée. Les paramètres sans historique doivent être saisis depuis
              la source officielle avant tout recalcul portant sur une période antérieure.
            </p>
          </Card>

          {selectedInForce ? (
            <>
              <Card title="Historique des versions" subtitle={selectedInForce.label}>
                <ul className="space-y-2">
                  {history.map((h) => {
                    const current = h.id === selectedInForce.id
                    return (
                      <li
                        key={h.id}
                        className={`rounded border p-2.5 ${
                          current ? 'border-violet bg-violet-veil' : 'border-rule bg-white'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="text-2xs text-ink-muted">
                            {date(h.valid_from)} → {sansFin(h.valid_to) ? '…' : date(h.valid_to)}
                          </span>
                          {current && <Badge tone="violet">en vigueur</Badge>}
                        </div>
                        <p className="mt-0.5 font-mono text-sm font-semibold text-ink">{formatValue(h)}</p>
                        {h.note && <p className="mt-1 text-2xs text-ink-muted">{h.note}</p>}
                      </li>
                    )
                  })}
                </ul>
                {history.length > 1 && (
                  <p className="mt-3 text-xs text-ink-muted">
                    Un calcul daté d’une période antérieure utilise la version en vigueur à cette date-là. Un
                    changement de paramètre ne modifie jamais rétroactivement une période clôturée.
                  </p>
                )}
              </Card>

              <LegalBasis
                reference={selectedInForce.legal_ref}
                text={selectedInForce.note ?? undefined}
                value={formatValue(selectedInForce)}
                validity={`depuis ${date(selectedInForce.valid_from)}`}
                source={selectedInForce.source}
              />

              {/* Saisie d'une nouvelle version sans toucher au code (US6). */}
              <Card title="Nouvelle version datée">
                <div className="grid gap-2 sm:grid-cols-2">
                  <Field label="À compter du" required>
                    <Input type="date" value={newFrom} onChange={(e) => setNewFrom(e.target.value)} />
                  </Field>
                  <Field label="Nouvelle valeur" required>
                    <Input value={newValue} onChange={(e) => setNewValue(e.target.value)} />
                  </Field>
                </div>
                <ErrorNote error={addVersion.error} />
                <Button
                  size="sm" variant="primary" className="mt-2 w-full"
                  disabled={!newValue || addVersion.isPending}
                  onClick={() =>
                    addVersion.mutate(
                      {
                        key: selectedInForce.param_key,
                        from: newFrom,
                        valueNum: selectedInForce.value_num !== null ? Number(newValue) : null,
                        valueText: selectedInForce.value_text !== null ? newValue : null,
                        note: 'Saisie depuis l’écran du référentiel.',
                      },
                      { onSuccess: () => setNewValue('') },
                    )
                  }
                >
                  {addVersion.isPending ? 'Enregistrement…' : 'Ouvrir la version'}
                </Button>
                <p className="mt-2 text-xs text-ink-muted">
                  La version en cours est clôturée à cette date. Une double lecture par une autre
                  personne reste requise avant activation.
                </p>
              </Card>
            </>
          ) : (
            <Card title="Historique des versions">
              <p className="text-xs text-ink-muted">
                Sélectionnez un paramètre pour voir ses versions successives et sa base légale.
              </p>
            </Card>
          )}

          <Card title="Mise à jour du référentiel">
            <p className="text-xs leading-relaxed text-ink-muted">
              Aucune API officielle ne publie les paramètres sociaux ni les barèmes fiscaux luxembourgeois. La
              mise à jour est un processus manuel supervisé : saisie d’une nouvelle version datée, validation en
              double lecture, journal des modifications, puis rejeu du jeu de tests de non-régression.
            </p>
            <ul className="mt-3 space-y-1 text-xs text-ink-body">
              <li>· Veille fiscale au 1er janvier</li>
              <li>· Veille sociale à chaque publication d’indexation</li>
              <li>· Sources : avis annuel CCSS, formules de calcul ACD, publications ITM, Legilux</li>
            </ul>
          </Card>
        </aside>
      </div>
    </div>
  )
}
