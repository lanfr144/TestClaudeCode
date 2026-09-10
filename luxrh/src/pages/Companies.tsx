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
  legal_name: '', legal_form: 'Sàrl', rcs_number: '', ccss_matricule: '',
  address_line: '', postal_code: '', city: '', nace_code: '', sector: '',
  activity_class: '', mutuality_class: '2', accident_factor: '1.00',
  collective_agreement_id: '', rates_from: '',
}

export default function Companies() {
  const { companies, profile, referenceDate } = useApp()
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
        .from('companies')
        .insert({
          organization_id: profile!.organization_id,
          legal_name: form.legal_name,
          legal_form: form.legal_form || null,
          rcs_number: form.rcs_number || null,
          ccss_matricule: form.ccss_matricule.replace(/\D/g, '') || null,
          address_line: form.address_line || null,
          postal_code: form.postal_code || null,
          city: form.city || null,
          nace_code: form.nace_code || null,
          sector: form.sector || null,
        })
        .select()
        .single()
      if (error) throw new Error(error.message)

      await callEngine('fn_set_company_rates', {
        p_company: company.id,
        p_from: form.rates_from,
        p_mutuality_class: Number(form.mutuality_class),
        p_accident_factor: Number(form.accident_factor),
        p_activity_class: form.activity_class || null,
        p_accident_risk_class: null,
        p_note: 'Période ouverte à la création du dossier.',
      })

      if (form.collective_agreement_id) {
        const { error: e2 } = await supabase.from('company_collective_agreements').insert({
          company_id: company.id,
          collective_agreement_id: form.collective_agreement_id,
          valid_from: form.rates_from,
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
            {profile?.organizations?.name} · {companies.length} dossier{companies.length > 1 ? 's' : ''}
          </p>
        </div>
        <div className="flex gap-2">
          {companies.length === 0 && profile?.is_org_admin && (
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
              <Input value={form.legal_name} onChange={(e) => setForm({ ...form, legal_name: e.target.value })} />
            </Field>
            <Field label="Forme juridique" required>
              <Input value={form.legal_form} onChange={(e) => setForm({ ...form, legal_form: e.target.value })} />
            </Field>
            <Field label="RCS">
              <Input value={form.rcs_number} onChange={(e) => setForm({ ...form, rcs_number: e.target.value })} />
            </Field>
            <Field label="Matricule CCSS" required hint="13 chiffres, format vérifié à l’enregistrement.">
              <Input
                value={form.ccss_matricule}
                onChange={(e) => setForm({ ...form, ccss_matricule: e.target.value })}
              />
            </Field>
            <Field label="Adresse" required>
              <Input value={form.address_line} onChange={(e) => setForm({ ...form, address_line: e.target.value })} />
            </Field>
            <Field label="Code postal / ville" required>
              <div className="flex gap-2">
                <Input
                  className="w-28" value={form.postal_code}
                  onChange={(e) => setForm({ ...form, postal_code: e.target.value })}
                />
                <Input value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
              </div>
            </Field>
            <Field label="Secteur NACE" required>
              <Input
                value={form.nace_code}
                onChange={(e) => setForm({ ...form, nace_code: e.target.value })}
                placeholder="56.10"
              />
            </Field>
            <Field label="Secteur d’activité">
              <Input value={form.sector} onChange={(e) => setForm({ ...form, sector: e.target.value })} />
            </Field>
            <Field
              label="Convention collective"
              hint="D’autres conventions pourront être rattachées ensuite, chacune avec sa période."
            >
              <Select
                value={form.collective_agreement_id}
                onChange={(e) => setForm({ ...form, collective_agreement_id: e.target.value })}
              >
                <option value="">Aucune convention</option>
                {(cba.data ?? []).map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} — {CBA_SCOPE_LABEL[c.scope]}
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
                value={form.activity_class}
                onChange={(e) => setForm({ ...form, activity_class: e.target.value })}
              />
            </Field>
            <Field label="Classe de cotisation Mutualité" hint="1 à 4, historisée.">
              <Select
                value={form.mutuality_class}
                onChange={(e) => setForm({ ...form, mutuality_class: e.target.value })}
              >
                {[1, 2, 3, 4].map((c) => <option key={c} value={c}>Classe {c}</option>)}
              </Select>
            </Field>
            <Field label="Facteur bonus-malus accident">
              <Input
                type="number" step="0.01" value={form.accident_factor}
                onChange={(e) => setForm({ ...form, accident_factor: e.target.value })}
              />
            </Field>
          </div>
          <ErrorNote error={err} />
          <div className="mt-4 flex justify-end">
            <Button variant="primary" onClick={create} disabled={busy || !form.legal_name}>
              {busy ? 'Enregistrement…' : 'Créer la société'}
            </Button>
          </div>
        </Card>
      )}

      <Card dense>
        {companies.length === 0 ? (
          <EmptyState
            title="Aucun dossier"
            detail="Créez une société, ou chargez le jeu de démonstration pour parcourir l’application avec des données réalistes."
          />
        ) : (
          <Table head={['Société', 'Secteur', 'Conventions applicables', 'Matricule CCSS']}>
            {companies.map((c) => {
              const cbas = currentCbas(c.company_collective_agreements, referenceDate)
              return (
                <tr key={c.id} className="hover:bg-rule-rail/50">
                  <td className="lux-td">
                    <Link to={`/societes/${c.id}`} className="font-medium text-ink hover:text-action">
                      {c.legal_name}
                    </Link>
                  </td>
                  <td className="lux-td">{c.sector ?? '—'}</td>
                  <td className="lux-td">
                    {cbas.length === 0 ? (
                      <span className="text-ink-faint">aucune</span>
                    ) : (
                      <span className="flex flex-wrap gap-1">
                        {cbas.map((l) => (
                          <Badge key={l.collective_agreements?.code} tone="violet">
                            {l.collective_agreements?.code}
                          </Badge>
                        ))}
                      </span>
                    )}
                  </td>
                  <td className="lux-td font-mono text-2xs">{c.ccss_matricule ?? '—'}</td>
                </tr>
              )
            })}
          </Table>
        )}
      </Card>
    </div>
  )
}
