import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useSeedDemo } from '@/lib/queries'
import { Badge, Button, EmptyState, ErrorNote, Input, Loading } from '@/components/ui'
import { currentCbas } from '@/lib/format'

export default function CompanyPicker() {
  const { companies, companiesLoading, profile, setActiveCompany, referenceDate } = useApp()
  const [q, setQ] = useState('')
  const navigate = useNavigate()
  const seed = useSeedDemo()

  const filtered = companies.filter(
    (c) =>
      c.legal_name.toLowerCase().includes(q.toLowerCase()) ||
      (c.sector ?? '').toLowerCase().includes(q.toLowerCase()),
  )

  return (
    <div className="min-h-screen bg-canvas">
      <header className="bg-violet px-4 py-4 text-white">
        <div className="mx-auto flex max-w-3xl items-center gap-2.5">
          <span className="flex h-7 w-7 items-center justify-center rounded bg-white/15 text-xs font-bold">LR</span>
          <span className="font-bold tracking-tight">LuxRH</span>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-4 py-8">
        <h1 className="text-xl font-bold tracking-tight text-ink">Vos dossiers</h1>
        <p className="mt-1 text-sm text-ink-muted">
          {profile?.organizations?.name ?? 'Votre espace'} · {companies.length} société
          {companies.length > 1 ? 's' : ''}
        </p>

        <div className="mt-5">
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Rechercher un dossier…" />
        </div>

        {companiesLoading ? (
          <div className="mt-4 lux-card">
            <Loading />
          </div>
        ) : companies.length === 0 ? (
          <div className="mt-4 lux-card">
            <EmptyState
              title="Aucun dossier dans cet espace"
              detail="Créez votre première société, ou chargez le jeu de démonstration pour découvrir l’application avec des données réalistes."
              action={
                <div className="flex flex-col items-center gap-2">
                  <Button variant="primary" onClick={() => navigate('/societes')}>
                    Créer une société
                  </Button>
                  {profile?.is_org_admin && (
                    <Button size="sm" onClick={() => seed.mutate()} disabled={seed.isPending}>
                      {seed.isPending ? 'Chargement…' : 'Charger le jeu de démonstration'}
                    </Button>
                  )}
                  <ErrorNote error={seed.error} />
                </div>
              }
            />
          </div>
        ) : (
          <ul className="mt-4 space-y-2">
            {filtered.map((c) => (
              <li key={c.id}>
                <button
                  onClick={() => {
                    setActiveCompany(c.id)
                    navigate('/')
                  }}
                  className="lux-card flex w-full items-center gap-3 p-3 text-left hover:border-violet"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-md bg-violet text-sm font-bold text-white">
                    {c.legal_name.slice(0, 2).toUpperCase()}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-ink">{c.legal_name}</span>
                    <span className="block truncate text-xs text-ink-muted">
                      {c.sector ?? 'Secteur non renseigné'}
                      {(() => {
                        const cbas = currentCbas(c.company_collective_agreements, referenceDate)
                        return cbas.length === 0
                          ? ' · aucune convention'
                          : ` · ${cbas.map((l) => l.collective_agreements?.code).join(' + ')}`
                      })()}
                    </span>
                  </span>
                  {currentCbas(c.company_collective_agreements, referenceDate).length > 1 && (
                    <Badge tone="violet">
                      {currentCbas(c.company_collective_agreements, referenceDate).length} conventions
                    </Badge>
                  )}
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="lux-card px-4 py-6 text-center text-sm text-ink-muted">
                Aucun dossier ne correspond à « {q} ».
              </li>
            )}
          </ul>
        )}

        <p className="mt-6 text-xs text-ink-muted">
          Les données ne se croisent jamais : l’isolation entre dossiers est imposée en base par Row Level
          Security, pas par l’interface.
        </p>
      </main>
    </div>
  )
}
