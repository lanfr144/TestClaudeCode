import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { useApp } from '@/context/AppContext'
import { useCollectiveAgreements, useSeedDemo } from '@/lib/queries'
import { supabase, callEngine } from '@/lib/supabase'
import {
  Badge, Button, Card, EmptyState, ErrorNote, Field, Input, Select, Table,
} from '@/components/ui'
import { CBA_SCOPE_LABEL, currentCbas } from '@/lib/format'

const EMPTY = {
  raison_sociale: '', forme_juridique: 'Sàrl', numero_rcs: '', matricule_ccss: '',
  ligne: '', code_postal: '', localite: '', code_nace: '', secteur: '',
  classe_activite: '', classe_mutualite: '2', facteur_accident: '1.00',
  convention_id: '', rates_from: '',
}

export default function Companies() {
  const { societes, profile, referenceDate } = useApp()
  const cba = useCollectiveAgreements()
  const seed = useSeedDemo()
  const qc = useQueryClient()
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState({ ...EMPTY, rates_from: referenceDate })
  const [err, setErr] = useState<unknown>(null)
  const [busy, setBusy] = useState(false)

  /**
   * Les taux et les conventions ne sont plus des colonnes de la société :
   * ils s'ouvrent en périodes, dès la création.
   */
  async function create() {
    setBusy(true)
    setErr(null)
    try {
      const { data: company, error } = await supabase
        .from('societes')
        .insert({
          organisation_id: profile!.organisation_id,
          raison_sociale: form.raison_sociale,
          forme_juridique: form.forme_juridique || null,
          numero_rcs: form.numero_rcs || null,
          matricule_ccss: form.matricule_ccss.replace(/\D/g, '') || null,
          ligne: form.ligne || null,
          code_postal: form.code_postal || null,
          localite: form.localite || null,
          code_nace: form.code_nace || null,
          secteur: form.secteur || null,
        })
        .select()
        .single()
      if (error) throw new Error(error.message)

      await callEngine('fn_set_company_rates', {
        p_company: company.id,
        p_from: form.rates_from,
        p_mutuality_class: Number(form.classe_mutualite),
        p_accident_factor: Number(form.facteur_accident),
        p_activity_class: form.classe_activite || null,
        p_accident_risk_class: null,
        p_note: 'Période ouverte à la création du dossier.',
      })

      if (form.convention_id) {
        const { error: e2 } = await supabase.from('conventions_de_la_societe').insert({
          societe_id: company.id,
          convention_id: form.convention_id,
          debut_validite: form.rates_from,
        })
        if (e2) throw new Error(e2.message)
      }

      await qc.invalidateQueries()
      setForm({ ...EMPTY, rates_from: referenceDate })
      setOpen(false)
    } catch (e) {
      setErr(e)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="space-y-4">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold tracking-tight text-ink">Sociétés</h1>
          <p className="text-xs text-ink-muted">
            {profile?.organisations?.nom} · {societes.length} dossier{societes.length > 1 ? 's' : ''}
          </p>
        </div>
        <div className="flex gap-2">
          {societes.length === 0 && profile?.est_admin_organisation && (
            <Button size="sm" onClick={() => seed.mutate()} disabled={seed.isPending}>
              {seed.isPending ? 'Chargement…' : 'Charger le jeu de démonstration'}
            </Button>
          )}
          <Button size="sm" variant="primary" onClick={() => setOpen((v) => !v)}>
            {open ? 'Annuler' : 'Créer une société'}
          </Button>
        </div>
      </header>

      <ErrorNote error={seed.error} />

      {open && (
        <Card title="Nouvelle société">
          <div className="grid gap-3 sm:grid-cols-3">
            <Field label="Raison sociale" required>
              <Input value={form.raison_sociale} onChange={(e) => setForm({ ...form, raison_sociale: e.target.value })} />
            </Field>
            <Field label="Forme juridique" required>
              <Input value={form.forme_juridique} onChange={(e) => setForm({ ...form, forme_juridique: e.target.value })} />
            </Field>
            <Field label="RCS">
              <Input value={form.numero_rcs} onChange={(e) => setForm({ ...form, numero_rcs: e.target.value })} />
            </Field>
            <Field label="Matricule CCSS" required hint="13 chiffres, format vérifié à l’enregistrement.">
              <Input
                value={form.matricule_ccss}
                onChange={(e) => setForm({ ...form, matricule_ccss: e.target.value })}
              />
            </Field>
            <Field label="Adresse" required>
              <Input value={form.ligne} onChange={(e) => setForm({ ...form, ligne: e.target.value })} />
            </Field>
            <Field label="Code postal / ville" required>
              <div className="flex gap-2">
                <Input
                  className="w-28" value={form.code_postal}
                  onChange={(e) => setForm({ ...form, code_postal: e.target.value })}
                />
                <Input value={form.localite} onChange={(e) => setForm({ ...form, localite: e.target.value })} />
              </div>
            </Field>
            <Field label="Secteur NACE" required>
              <Input
                value={form.code_nace}
                onChange={(e) => setForm({ ...form, code_nace: e.target.value })}
                placeholder="56.10"
              />
            </Field>
            <Field label="Secteur d’activité">
              <Input value={form.secteur} onChange={(e) => setForm({ ...form, secteur: e.target.value })} />
            </Field>
            <Field
              label="Convention collective"
              hint="D’autres conventions pourront être rattachées ensuite, chacune avec sa période."
            >
              <Select
                value={form.convention_id}
                onChange={(e) => setForm({ ...form, convention_id: e.target.value })}
              >
                <option value="">Aucune convention</option>
                {(cba.data ?? []).map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nom} — {CBA_SCOPE_LABEL[c.portee]}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Taux applicables à compter du" required>
              <Input
                type="date" value={form.rates_from}
                onChange={(e) => setForm({ ...form, rates_from: e.target.value })}
              />
            </Field>
            <Field label="Classe d’activité" hint="Détermine la classe de risque accident.">
              <Input
                value={form.classe_activite}
                onChange={(e) => setForm({ ...form, classe_activite: e.target.value })}
              />
            </Field>
            <Field label="Classe de cotisation Mutualité" hint="1 à 4, historisée.">
              <Select
                value={form.classe_mutualite}
                onChange={(e) => setForm({ ...form, classe_mutualite: e.target.value })}
              >
                {[1, 2, 3, 4].map((c) => <option key={c} value={c}>Classe {c}</option>)}
              </Select>
            </Field>
            <Field label="Facteur bonus-malus accident">
              <Input
                type="number" step="0.01" value={form.facteur_accident}
                onChange={(e) => setForm({ ...form, facteur_accident: e.target.value })}
              />
            </Field>
          </div>
          <ErrorNote error={err} />
          <div className="mt-4 flex justify-end">
            <Button variant="primary" onClick={create} disabled={busy || !form.raison_sociale}>
              {busy ? 'Enregistrement…' : 'Créer la société'}
            </Button>
          </div>
        </Card>
      )}

      <Card dense>
        {societes.length === 0 ? (
          <EmptyState
            title="Aucun dossier"
            detail="Créez une société, ou chargez le jeu de démonstration pour parcourir l’application avec des données réalistes."
          />
        ) : (
          <Table head={['Société', 'Secteur', 'Conventions applicables', 'Matricule CCSS']}>
            {societes.map((c) => {
              const cbas = currentCbas(c.conventions_de_la_societe, referenceDate)
              return (
                <tr key={c.id} className="hover:bg-rule-rail/50">
                  <td className="lux-td">
                    <Link to={`/societes/${c.id}`} className="font-medium text-ink hover:text-action">
                      {c.raison_sociale}
                    </Link>
                  </td>
                  <td className="lux-td">{c.secteur ?? '—'}</td>
                  <td className="lux-td">
                    {cbas.length === 0 ? (
                      <span className="text-ink-faint">aucune</span>
                    ) : (
                      <span className="flex flex-wrap gap-1">
                        {cbas.map((l) => (
                          <Badge key={l.conventions_collectives?.code} tone="violet">
                            {l.conventions_collectives?.code}
                          </Badge>
                        ))}
                      </span>
                    )}
                  </td>
                  <td className="lux-td font-mono text-2xs">{c.matricule_ccss ?? '—'}</td>
                </tr>
              )
            })}
          </Table>
        )}
      </Card>
    </div>
  )
}
