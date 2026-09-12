import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import {
  useAbsences, useAbsenceTypes, useCreateAbsence, useEmployees, useMarkCertificate, useSickCounters,
} from '@/lib/queries'
import {
  Badge, Button, Card, ErrorNote, Field, Input, LegalBasis, Loading, Select, Table,
} from '@/components/ui'
import { date, num } from '@/lib/format'

function CounterRow({ employeeId, name }: { employeeId: string; name: string }) {
  const { referenceDate } = useApp()
  const s = useSickCounters(employeeId, referenceDate)
  if (s.isLoading) return null
  const d = s.data
  if (!d || d.days_in_window === 0) return null
  return (
    <tr>
      <td className="lux-td">
        <Link to={`/employes/${employeeId}`} className="font-medium text-ink hover:text-action">
          {name}
        </Link>
      </td>
      <td className="lux-td font-mono">
        {num(d.days_in_window, 0)} / {num(d.limit_days, 0)} j
        <span className="ml-1 text-2xs text-ink-faint">sur {d.window_months} mois</span>
      </td>
      <td className="lux-td">{d.continuation_end ? date(d.continuation_end) : 'en cours'}</td>
      <td className="lux-td">
        {d.protection_end ? (
          <Badge tone="info">jusqu’au {date(d.protection_end)}</Badge>
        ) : (
          <span className="text-ink-faint">—</span>
        )}
      </td>
      <td className="lux-td">
        {d.missing_certificates.length > 0 ? (
          <Badge tone="blocking">{d.missing_certificates.length} manquant</Badge>
        ) : (
          <Badge tone="ok">à jour</Badge>
        )}
      </td>
      <td className="lux-td text-2xs text-ink-muted">
        {num(d.mutuality_refund_pct, 0)} % remboursables
      </td>
    </tr>
  )
}

export default function SickLeave() {
  const { activeCompanyId, referenceDate } = useApp()
  const salaries = useEmployees(activeCompanyId ?? undefined)
  const absences = useAbsences(activeCompanyId ?? undefined)
  const types = useAbsenceTypes()
  const create = useCreateAbsence()
  const markCert = useMarkCertificate()

  const [form, setForm] = useState({ salarie_id: '', date_debut: referenceDate, date_fin: referenceDate, days: '' })

  const sickType = (types.data ?? []).find((t) => t.code === 'sick')
  const sickAbsences = (absences.data ?? []).filter((a) => a.types_absence?.categorie === 'sick')

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (salaries.isLoading) return <Card><Loading /></Card>

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">Absences et maladies</h1>
        <p className="text-xs text-ink-muted">
          Compteurs de continuation de salaire, protection contre le licenciement et suivi des certificats.
        </p>
      </header>

      <Card title="Déclarer une incapacité de travail">
        <div className="grid gap-3 sm:grid-cols-5">
          <Field label="Salarié" required>
            <Select
              value={form.salarie_id}
              onChange={(e) => setForm({ ...form, salarie_id: e.target.value })}
            >
              <option value="">Choisir…</option>
              {(salaries.data ?? []).map((e) => (
                <option key={e.id} value={e.id}>{e.nom} {e.prenom}</option>
              ))}
            </Select>
          </Field>
          <Field label="Du" required>
            <Input type="date" value={form.date_debut} onChange={(e) => setForm({ ...form, date_debut: e.target.value })} />
          </Field>
          <Field label="Au" required>
            <Input type="date" value={form.date_fin} onChange={(e) => setForm({ ...form, date_fin: e.target.value })} />
          </Field>
          <Field label="Jours décomptés" hint="Jours d’incapacité imputés au compteur.">
            <Input type="number" step="0.5" value={form.days} onChange={(e) => setForm({ ...form, days: e.target.value })} />
          </Field>
          <div className="flex items-end">
            <Button
              variant="primary"
              className="w-full"
              disabled={!form.salarie_id || !sickType || create.isPending}
              onClick={() =>
                create.mutate({
                  societe_id: activeCompanyId,
                  salarie_id: form.salarie_id,
                  type_absence_id: sickType!.id,
                  date_debut: form.date_debut,
                  date_fin: form.date_fin,
                  nombre_jours: Number(form.days || 0),
                  statut: 'approved',
                })
              }
            >
              Enregistrer
            </Button>
          </div>
        </div>
        <ErrorNote error={create.error} />
        <p className="mt-3 text-xs text-ink-muted">
          La déclaration déclenche les compteurs de continuation de salaire et la protection contre le
          licenciement. Le certificat médical doit être remis dans les délais légaux.
        </p>
        <div className="mt-2">
          <LegalBasis
            reference="art. L.121-6"
            text="La continuation de salaire par l’employeur va jusqu’à la fin du mois du 77e jour d’incapacité, sur une période de référence de 18 mois."
          />
        </div>
      </Card>

      <Card title="Compteurs par salarié" dense>
        <Table
          head={[
            'Salarié', 'Incapacité / période', 'Fin de continuation', 'Protection licenciement',
            'Certificats', 'Mutualité',
          ]}
        >
          {(salaries.data ?? []).map((e) => (
            <CounterRow key={e.id} employeeId={e.id} name={`${e.prenom} ${e.nom}`} />
          ))}
        </Table>
      </Card>

      <Card title="Incapacités enregistrées" dense>
        <Table head={['Salarié', 'Du', 'Au', 'Jours', 'Certificat', '']}>
          {sickAbsences.map((a) => (
            <tr key={a.id}>
              <td className="lux-td">
                {a.salaries?.prenom} {a.salaries?.nom}
              </td>
              <td className="lux-td">{date(a.date_debut)}</td>
              <td className="lux-td">{date(a.date_fin)}</td>
              <td className="lux-td font-mono">{num(a.nombre_jours, 2)}</td>
              <td className="lux-td">
                {a.certificat_recu ? (
                  <Badge tone="ok">reçu le {date(a.certificat_recu_le)}</Badge>
                ) : (
                  <Badge tone="blocking">manquant</Badge>
                )}
              </td>
              <td className="lux-td">
                {!a.certificat_recu && (
                  <Button size="sm" disabled={markCert.isPending} onClick={() => markCert.mutate(a.id)}>
                    Marquer reçu
                  </Button>
                )}
              </td>
            </tr>
          ))}
          {sickAbsences.length === 0 && (
            <tr><td className="lux-td text-ink-muted" colSpan={6}>Aucune incapacité enregistrée.</td></tr>
          )}
        </Table>
      </Card>
    </div>
  )
}
