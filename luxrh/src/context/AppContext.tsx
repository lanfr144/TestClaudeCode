import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { useCompanies, useProfile } from '@/lib/queries'

const ACTIVE_COMPANY_KEY = 'luxrh.activeCompany'

interface AppState {
  session: Session | null
  authReady: boolean
  profile: ReturnType<typeof useProfile>['data']
  societes: NonNullable<ReturnType<typeof useCompanies>['data']>
  companiesLoading: boolean
  activeCompanyId: string | null
  activeCompany: NonNullable<ReturnType<typeof useCompanies>['data']>[number] | null
  setActiveCompany: (id: string) => void
  /** Date de référence de tous les calculs datés. */
  referenceDate: string
  setReferenceDate: (d: string) => void
  isEmployeeOnly: boolean
  signOut: () => Promise<void>
}

const Ctx = createContext<AppState | null>(null)

export function AppProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [authReady, setAuthReady] = useState(false)
  const [activeCompanyId, setActive] = useState<string | null>(
    () => localStorage.getItem(ACTIVE_COMPANY_KEY),
  )
  const [referenceDate, setReferenceDate] = useState(() => new Date().toISOString().slice(0, 10))

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      setAuthReady(true)
    })
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s))
    return () => sub.subscription.unsubscribe()
  }, [])

  const { data: profile } = useProfile()
  const { data: societes = [], isLoading: companiesLoading } = useCompanies()

  // Un salarié en self-service n'a qu'une société : on la sélectionne d'office.
  const isEmployeeOnly = !!profile?.selfEmployee && !profile?.est_admin_organisation &&
    !profile?.roles?.some((r) => r.role !== 'employee')

  useEffect(() => {
    if (activeCompanyId && societes.some((c) => c.id === activeCompanyId)) return
    const fallback = profile?.selfEmployee?.societe_id ?? societes[0]?.id ?? null
    if (fallback) {
      setActive(fallback)
      localStorage.setItem(ACTIVE_COMPANY_KEY, fallback)
    }
  }, [societes, activeCompanyId, profile])

  const setActiveCompany = (id: string) => {
    setActive(id)
    localStorage.setItem(ACTIVE_COMPANY_KEY, id)
  }

  const value = useMemo<AppState>(
    () => ({
      session,
      authReady,
      profile,
      societes,
      companiesLoading,
      activeCompanyId,
      activeCompany: societes.find((c) => c.id === activeCompanyId) ?? null,
      setActiveCompany,
      referenceDate,
      setReferenceDate,
      isEmployeeOnly,
      signOut: async () => {
        localStorage.removeItem(ACTIVE_COMPANY_KEY)
        await supabase.auth.signOut()
      },
    }),
    [session, authReady, profile, societes, companiesLoading, activeCompanyId, referenceDate, isEmployeeOnly],
  )

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}

export function useApp() {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useApp doit être utilisé dans AppProvider')
  return ctx
}
