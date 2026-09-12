import { useEffect, useRef, useState, type ReactNode } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router-dom'
import { useApp } from '@/context/AppContext'
import { useVigilance } from '@/lib/queries'
import { initials } from '@/lib/format'

const PRIMARY: { to: string; label: string; end?: boolean }[] = [
  { to: '/', label: 'Tableau de bord', end: true },
  { to: '/planning', label: 'Planning' },
  { to: '/employes', label: 'Employés' },
  { to: '/contrats', label: 'Contrats' },
  { to: '/conges', label: 'Congés' },
  { to: '/vigilance', label: 'Vigilance' },
]

const RAILS: Record<string, { title: string; items: { to: string; label: string }[] }> = {
  '/planning': {
    title: 'Exploitation',
    items: [
      { to: '/planning', label: 'Grille hebdomadaire' },
      { to: '/planning/modeles', label: 'Modèles de creneaux' },
      { to: '/planning/registre', label: 'Registre du temps' },
    ],
  },
  '/conges': {
    title: 'Absences',
    items: [
      { to: '/conges', label: 'Calendrier et demandes' },
      { to: '/conges/maladies', label: 'Maladies et compteurs' },
    ],
  },
  '/vigilance': {
    title: 'Conformité',
    items: [
      { to: '/vigilance', label: 'Centre de vigilance' },
      { to: '/vigilance/licenciement-collectif', label: 'Simulateur de licenciement collectif' },
    ],
  },
  '/contrats': {
    title: 'Contrats',
    items: [
      { to: '/contrats', label: 'Liste des contrats' },
      { to: '/contrats/nouveau', label: 'Assistant de création' },
    ],
  },
  '/referentiel': {
    title: 'Référentiel',
    items: [
      { to: '/referentiel', label: 'Paramètres légaux datés' },
      { to: '/referentiel/cct', label: 'Conventions collectives' },
      { to: '/referentiel/feries', label: 'Jours fériés' },
    ],
  },
  '/societes': {
    title: 'Dossiers',
    items: [
      { to: '/societes', label: 'Liste des sociétés' },
      { to: '/parametres', label: 'Utilisateurs et journal d’audit' },
    ],
  },
}

function railFor(pathname: string) {
  const key = Object.keys(RAILS).find((k) => pathname === k || pathname.startsWith(`${k}/`))
  return key ? RAILS[key] : null
}

function CompanySwitcher() {
  const { societes, activeCompany, setActiveCompany } = useApp()
  const [open, setOpen] = useState(false)
  const [q, setQ] = useState('')
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onClick)
    return () => document.removeEventListener('mousedown', onClick)
  }, [])

  const filtered = societes.filter((c) => c.raison_sociale.toLowerCase().includes(q.toLowerCase()))

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="listbox"
        aria-expanded={open}
        className="flex min-h-[34px] items-center gap-2 rounded bg-violet-deep/70 px-3 text-sm font-medium text-white hover:bg-violet-deep"
      >
        <span className="max-w-[220px] truncate">{activeCompany?.raison_sociale ?? 'Choisir un dossier'}</span>
        <span aria-hidden className="text-2xs opacity-80">▾</span>
      </button>
      {open && (
        <div className="absolute right-0 z-30 mt-1 w-80 rounded-md border border-rule bg-white p-2 shadow-pop">
          <input
            autoFocus
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Rechercher un dossier…"
            className="lux-input mb-2"
          />
          <ul role="listbox" className="max-h-72 overflow-y-auto">
            {filtered.map((c) => (
              <li key={c.id}>
                <button
                  role="option"
                  aria-selected={c.id === activeCompany?.id}
                  onClick={() => {
                    setActiveCompany(c.id)
                    setOpen(false)
                  }}
                  className={`flex w-full items-center gap-2.5 rounded px-2 py-2 text-left hover:bg-rule-rail ${
                    c.id === activeCompany?.id ? 'bg-violet-veil' : ''
                  }`}
                >
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded bg-violet text-2xs font-bold text-white">
                    {c.raison_sociale.slice(0, 2).toUpperCase()}
                  </span>
                  <span className="min-w-0">
                    <span className="bloc truncate text-sm font-medium text-ink">{c.raison_sociale}</span>
                    <span className="bloc truncate text-2xs text-ink-muted">
                      {c.secteur ?? 'Secteur non renseigné'}
                    </span>
                  </span>
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="px-2 py-3 text-xs text-ink-muted">Aucun dossier ne correspond.</li>
            )}
          </ul>
        </div>
      )}
    </div>
  )
}

export function AppShell({ breadcrumb, children }: { breadcrumb?: ReactNode[]; children: ReactNode }) {
  const { profile, activeCompanyId, activeCompany, signOut } = useApp()
  const { pathname } = useLocation()
  const navigate = useNavigate()
  const rail = railFor(pathname)
  const { data: scan } = useVigilance(activeCompanyId ?? undefined)
  const alertCount = (scan?.overdue.length ?? 0) + (scan?.due_soon.length ?? 0)

  return (
    <div className="min-h-screen bg-canvas">
      {/* Barre violette : identité et société active. */}
      <header className="bg-violet text-white">
        <div className="mx-auto flex h-14 max-w-[1440px] items-center gap-6 px-4">
          <button onClick={() => navigate('/')} className="flex items-center gap-2 font-bold tracking-tight">
            <span className="flex h-7 w-7 items-center justify-center rounded bg-white/15 text-xs">LR</span>
            LuxRH
          </button>
          <nav className="hidden items-center gap-1 md:flex" aria-label="Navigation principale">
            {PRIMARY.map((l) => (
              <NavLink
                key={l.to}
                to={l.to}
                end={l.end}
                className={({ isActive }) =>
                  `rounded px-2.5 py-1.5 text-sm transition-colors ${
                    isActive ? 'bg-white/15 font-semibold' : 'text-white/85 hover:bg-white/10'
                  }`
                }
              >
                {l.label}
              </NavLink>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-3">
            <CompanySwitcher />
            <NavLink
              to="/vigilance"
              className="flex items-center gap-1.5 rounded px-2 py-1 text-sm text-white/90 hover:bg-white/10"
            >
              Alertes
              {alertCount > 0 && (
                <span className="rounded bg-highlight px-1.5 text-2xs font-bold text-ink">{alertCount}</span>
              )}
            </NavLink>
            <button
              onClick={signOut}
              title={`${profile?.nom_complet ?? 'Utilisateur'} — se déconnecter`}
              className="flex h-8 w-8 items-center justify-center rounded-md bg-white/15 text-xs font-bold"
            >
              {initials(profile?.nom_complet?.split(' ')[0], profile?.nom_complet?.split(' ')[1])}
            </button>
          </div>
        </div>
      </header>

      {/* Rail gris clair : navigation du module. */}
      {rail && (
        <div className="border-b border-rule bg-rule-rail">
          <div className="mx-auto flex max-w-[1440px] items-center gap-4 overflow-x-auto px-4">
            <span className="shrink-0 py-2.5 text-2xs font-semibold uppercase tracking-[0.1em] text-ink-faint">
              {rail.title}
            </span>
            <nav className="flex gap-1" aria-label={rail.title}>
              {rail.items.map((i) => (
                <NavLink
                  key={i.to}
                  to={i.to}
                  end
                  className={({ isActive }) =>
                    `whitespace-nowrap border-b-2 px-2.5 py-2.5 text-sm ${
                      isActive
                        ? 'border-violet font-semibold text-violet-deep'
                        : 'border-transparent text-ink-muted hover:text-ink-body'
                    }`
                  }
                >
                  {i.label}
                </NavLink>
              ))}
            </nav>
          </div>
        </div>
      )}

      {/* Fil d'Ariane systématique : on doit toujours savoir dans quel dossier on travaille. */}
      <div className="border-b border-rule bg-white">
        <nav
          aria-label="Fil d'Ariane"
          className="mx-auto flex max-w-[1440px] items-center gap-1.5 px-4 py-2 text-xs text-ink-muted"
        >
          <span className="font-medium text-ink-body">{activeCompany?.raison_sociale ?? 'Aucun dossier'}</span>
          {breadcrumb?.map((b, i) => (
            <span key={i} className="flex items-center gap-1.5">
              <span aria-hidden className="text-ink-faint">›</span>
              <span className={i === breadcrumb.length - 1 ? 'text-ink-body' : ''}>{b}</span>
            </span>
          ))}
        </nav>
      </div>

      <main className="mx-auto max-w-[1440px] px-4 py-5">{children}</main>
    </div>
  )
}
