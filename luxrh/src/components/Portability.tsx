/**
 * Portabilité : sortir ses données, et recharger un référentiel.
 *
 * Trois portées, trois droits différents — le serveur les vérifie, l'interface
 * se contente de ne pas proposer ce qui sera refusé.
 */

import { useRef, useState } from 'react'
import { useApp } from '@/context/AppContext'
import {
  type ExportDocument,
  type ImportReport,
  download,
  exportCompany,
  exportOrganization,
  exportReferential,
  exportSelf,
  importReferential,
  readDocument,
  sections,
} from '@/lib/portability'
import { Badge, Button, Card, ErrorNote, Select } from '@/components/ui'

type Portee = 'self' | 'company' | 'organization' | 'referential'

export function PortabilityCard() {
  const { activeCompanyId, activeCompany, profile } = useApp()
  const admin = profile?.is_org_admin ?? false

  const [busy, setBusy] = useState<Portee | 'import' | null>(null)
  const [error, setError] = useState<unknown>(null)
  const [done, setDone] = useState<{ doc: ExportDocument; parts: ReturnType<typeof sections> } | null>(null)
  const [report, setReport] = useState<ImportReport | null>(null)
  const [mode, setMode] = useState<'skip_existing' | 'replace'>('skip_existing')
  const fileInput = useRef<HTMLInputElement>(null)

  async function run(portee: Portee) {
    setBusy(portee)
    setError(null)
    setDone(null)
    setReport(null)
    try {
      const doc =
        portee === 'self'
          ? await exportSelf()
          : portee === 'company'
            ? await exportCompany(activeCompanyId!)
            : portee === 'organization'
              ? await exportOrganization()
              : await exportReferential()
      download(doc, portee === 'company' ? activeCompany?.legal_name?.slice(0, 24) : undefined)
      setDone({ doc, parts: sections(doc) })
    } catch (e) {
      setError(e)
    } finally {
      setBusy(null)
    }
  }

  async function load(file: File) {
    setBusy('import')
    setError(null)
    setDone(null)
    setReport(null)
    try {
      setReport(await importReferential(await readDocument(file, 'referential'), mode))
    } catch (e) {
      setError(e)
    } finally {
      setBusy(null)
      if (fileInput.current) fileInput.current.value = ''
    }
  }

  return (
    <Card
      title="Portabilité et reprise"
      subtitle="Sortir les données dans un format relisible, et repeupler une nouvelle implantation"
    >
      <div className="space-y-4">
        <div>
          <p className="lux-label">Droit d’accès — art. 15 et 20 du RGPD</p>
          <p className="mt-1 text-xs text-ink-muted">
            Le dossier complet de la personne : contrats, temps, absences, primes, documents. Matricule
            national et IBAN y figurent en clair — un export illisible ne satisferait pas le droit d’accès.
          </p>
          <Button size="sm" className="mt-2" disabled={busy !== null} onClick={() => run('self')}>
            {busy === 'self' ? 'Préparation…' : 'Exporter mes données personnelles'}
          </Button>
        </div>

        {(admin || activeCompanyId) && (
          <div className="border-t border-rule pt-3">
            <p className="lux-label">Réversibilité</p>
            <p className="mt-1 text-xs text-ink-muted">
              Ce que la société ou la fiduciaire emporte si elle quitte l’outil. Les pièces jointes restent
              dans le stockage : l’export en porte le descriptif et le chemin, pas le contenu binaire.
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              {activeCompanyId && (
                <Button size="sm" disabled={busy !== null} onClick={() => run('company')}>
                  {busy === 'company' ? 'Préparation…' : `Exporter ${activeCompany?.legal_name ?? 'la société'}`}
                </Button>
              )}
              {admin && (
                <Button size="sm" disabled={busy !== null} onClick={() => run('organization')}>
                  {busy === 'organization' ? 'Préparation…' : 'Exporter toute la fiduciaire'}
                </Button>
              )}
            </div>
          </div>
        )}

        <div className="border-t border-rule pt-3">
          <p className="lux-label">Référentiel — transmission du savoir</p>
          <p className="mt-1 text-xs text-ink-muted">
            Paramètres légaux datés, barèmes, catalogues et CCT. L’export se lit en clés naturelles
            (<code className="font-mono text-2xs">param_key</code>, codes, dates) et non en identifiants
            techniques : il peut donc repeupler une base neuve sans y dupliquer ce qui s’y trouve déjà.
          </p>
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <Button size="sm" disabled={busy !== null} onClick={() => run('referential')}>
              {busy === 'referential' ? 'Préparation…' : 'Exporter le référentiel'}
            </Button>

            {admin && (
              <>
                <Select
                  className="w-auto"
                  value={mode}
                  onChange={(e) => setMode(e.target.value as typeof mode)}
                >
                  <option value="skip_existing">Conserver l’existant</option>
                  <option value="replace">Écraser à clé égale</option>
                </Select>
                <Button
                  size="sm"
                  variant="secondary"
                  disabled={busy !== null}
                  onClick={() => fileInput.current?.click()}
                >
                  {busy === 'import' ? 'Chargement…' : 'Charger un référentiel'}
                </Button>
                <input
                  ref={fileInput}
                  type="file"
                  accept="application/json,.json"
                  className="hidden"
                  onChange={(e) => {
                    const f = e.target.files?.[0]
                    if (f) void load(f)
                  }}
                />
              </>
            )}
          </div>
          {admin && (
            <p className="mt-1.5 text-2xs text-ink-faint">
              Un import n’efface jamais rien : il ajoute, ou remplace à clé égale. Les CCT chargées sont
              rattachées à votre organisation, jamais publiées à toutes.
            </p>
          )}
        </div>

        {error != null && <ErrorNote error={error} />}

        {done && (
          <div className="rounded border border-rule bg-surface-sunken p-2.5">
            <p className="text-xs font-medium text-ink">
              Fichier enregistré · {done.doc.kind} ·{' '}
              {new Date(done.doc.exported_at).toLocaleString('fr-LU')}
            </p>
            <div className="mt-1.5 flex flex-wrap gap-1">
              {done.parts.map((s) => (
                <Badge key={s.name} tone="neutral">
                  {s.name} {s.count}
                </Badge>
              ))}
            </div>
          </div>
        )}

        {report && (
          <div className="rounded border border-rule bg-surface-sunken p-2.5">
            <p className="text-xs font-medium text-ink">{report.message}</p>
            {report.rejected.length > 0 && (
              <ul className="mt-1.5 space-y-0.5 text-2xs text-blocking">
                {report.rejected.map((r) => (
                  <li key={r}>{r}</li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>
    </Card>
  )
}
