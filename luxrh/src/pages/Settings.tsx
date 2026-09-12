import { useApp } from '@/context/AppContext'
import { useAuditLog, useLegalParameters } from '@/lib/queries'
import { PortabilityCard } from '@/components/Portability'
import { Badge, Card, ErrorNote, Loading, Table } from '@/components/ui'
import { ROLE_LABEL, date, estEnVigueur, num } from '@/lib/format'

/** Catégories de données et durées de conservation — registre RGPD. */
const RETENTION = [
  { data: 'Fiches de salaire, décomptes, pièces comptables', key: 'retention_payslips_years' },
  { data: 'Registre du temps de travail', key: 'retention_time_register_years' },
]

export default function Settings() {
  const { activeCompanyId, activeCompany, profile, referenceDate } = useApp()
  const audit = useAuditLog(activeCompanyId ?? undefined)
  const params = useLegalParameters()

  return (
    <div className="space-y-4">
      <header>
        <h1 className="text-xl font-bold tracking-tight text-ink">Paramètres et utilisateurs</h1>
        <p className="text-xs text-ink-muted">
          {profile?.organisations?.nom} · rôles, journal d’audit et conformité RGPD.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="Utilisateurs et rôles">
          <Table head={['Utilisateur', 'Rôle', 'Portée']}>
            <tr>
              <td className="lux-td">
                <span className="font-medium text-ink">{profile?.nom_complet}</span>
                <span className="bloc text-2xs text-ink-faint">{profile?.courriel}</span>
              </td>
              <td className="lux-td">
                {profile?.est_admin_organisation ? (
                  <Badge tone="violet">Administrateur de l’espace</Badge>
                ) : (
                  <Badge tone="neutral">Utilisateur</Badge>
                )}
              </td>
              <td className="lux-td text-xs text-ink-muted">toutes les sociétés</td>
            </tr>
            {(profile?.roles ?? []).map((r) => (
              <tr key={r.id}>
                <td className="lux-td text-xs text-ink-muted">{r.compte_id.slice(0, 8)}…</td>
                <td className="lux-td">{ROLE_LABEL[r.role]}</td>
                <td className="lux-td text-xs text-ink-muted">
                  {r.societe_id ? 'une société' : 'toutes les sociétés'}
                </td>
              </tr>
            ))}
          </Table>
          <p className="mt-3 text-xs text-ink-muted">
            Quatre rôles : admin fiduciaire, gestionnaire, manager de service, salarié. Un salarié ne voit que
            ses propres données — la restriction est appliquée par Row Level Security en base, pas par
            l’interface.
          </p>
        </Card>

        <Card title="RGPD">
          <div className="space-y-3">
            <div>
              <p className="lux-libelle">Durées de conservation</p>
              <ul className="mt-1.5 space-y-1 text-sm">
                {RETENTION.map((r) => {
                  const p = params.data?.find(
                    (x) => x.cle_parametre === r.key && estEnVigueur(x, referenceDate),
                  )
                  return (
                    <li key={r.key} className="flex justify-between gap-3 border-b border-rule pb-1">
                      <span className="text-ink-body">{r.data}</span>
                      <span className="shrink-0 font-mono text-ink">{num(p?.valeur_num, 0)} ans</span>
                    </li>
                  )
                })}
              </ul>
            </div>
            <div>
              <p className="lux-libelle">Chiffrement au repos</p>
              <p className="mt-1 text-xs text-ink-muted">
                Matricule national et coordonnées bancaires sont chiffrés en base. Ils ne sont lisibles que par
                une fonction serveur qui vérifie les droits de l’appelant, jamais par une requête directe.
              </p>
            </div>
            <div>
              <p className="lux-libelle">Droit d’accès et d’export</p>
              <p className="mt-1 text-xs text-ink-muted">
                Voir la carte « Portabilité et reprise » ci-dessous : l’export est produit par le serveur,
                qui vérifie le droit d’en faire la demande et journalise celle-ci.
              </p>
            </div>
            <p className="text-xs text-ink-muted">
              Données hébergées dans l’Union européenne. Aucune décision automatisée à effet juridique n’est
              prise sur une personne : l’application prépare et documente, la décision reste humaine.
            </p>
          </div>
        </Card>
      </div>

      <PortabilityCard />

      <Card
        dense
        title="Journal d’audit"
        subtitle={`Contrats, temps de travail et absences de ${activeCompany?.raison_sociale ?? 'la société active'} — inaltérable`}
      >
        {audit.isLoading ? (
          <Loading />
        ) : audit.error ? (
          <ErrorNote error={audit.error} />
        ) : (
          <Table head={['Horodatage', 'Auteur', 'Table', 'Action', 'Entité']}>
            {(audit.data ?? []).slice(0, 60).map((a) => (
              <tr key={a.id}>
                <td className="lux-td font-mono text-2xs">
                  {new Date(a.survenu_le).toLocaleString('fr-LU')}
                </td>
                <td className="lux-td">{a.auteur_libelle ?? '—'}</td>
                <td className="lux-td font-mono text-2xs">{a.entite_table}</td>
                <td className="lux-td">
                  <Badge tone={a.action === 'DELETE' ? 'blocking' : a.action === 'INSERT' ? 'ok' : 'info'}>
                    {a.action}
                  </Badge>
                </td>
                <td className="lux-td font-mono text-2xs text-ink-faint">{a.entite_id?.slice(0, 8) ?? '—'}</td>
              </tr>
            ))}
            {(audit.data ?? []).length === 0 && (
              <tr>
                <td className="lux-td text-ink-muted" colSpan={5}>
                  Aucune écriture tracée pour cette société. Le journal se remplit dès la première modification
                  de contrat, de temps ou d’absence.
                </td>
              </tr>
            )}
          </Table>
        )}
      </Card>

      <p className="text-2xs text-ink-faint">
        Dernière lecture du référentiel : {date(new Date())}.
      </p>
    </div>
  )
}
