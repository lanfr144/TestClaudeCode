import { useState } from 'react'
import { NavLink, Navigate, Route, Routes, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { useApp } from '@/context/AppContext'
import { supabase } from '@/lib/supabase'
import {
  useAbsenceTypes, useCreateAbsence, useEmployee, useLeaveBalance, useLeaveImpact, useSickCounters,
} from '@/lib/queries'
import { Badge, Button, Card, ErrorNote, Field, Input, Loading, Select } from '@/components/ui'
import { ABSENCE_STATUS_LABEL, addDays, date, iso, mondayOf, num, time } from '@/lib/format'

const NAV: { to: string; label: string; end?: boolean }[] = [
  { to: '/mon-espace', label: 'Planning', end: true },
  { to: '/mon-espace/conges', label: 'Congés' },
  { to: '/mon-espace/documents', label: 'Documents' },
  { to: '/mon-espace/profil', label: 'Profil' },
]

function useSelfEmployeeId() {
  const { profile } = useApp()
  return profile?.selfEmployee?.id
}

/** Le salarié ne voit que ses propres shifts, et seulement sur un planning publié. */
function useMyShifts(employeeId?: string, weekStart?: string) {
  return useQuery({
    enabled: !!employeeId && !!weekStart,
    queryKey: ['self-shifts', employeeId, weekStart],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('shifts')
        .select('*, schedules!inner(status, week_start)')
        .eq('employee_id', employeeId!)
        .gte('shift_date', weekStart!)
        .lte('shift_date', iso(addDays(weekStart!, 6)))
        .order('shift_date')
        .order('start_time')
      if (error) throw new Error(error.message)
      return data
    },
  })
}

function MyPlanning() {
  const employeeId = useSelfEmployeeId()
  const { referenceDate } = useApp()
  const [weekStart, setWeekStart] = useState(() => iso(mondayOf(new Date(`${referenceDate}T00:00:00`))))
  const shifts = useMyShifts(employeeId, weekStart)
  const balance = useLeaveBalance(employeeId, referenceDate)
  const days = Array.from({ length: 7 }, (_, i) => iso(addDays(weekStart, i)))

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <Button size="sm" onClick={() => setWeekStart(iso(addDays(weekStart, -7)))} aria-label="Semaine précédente">←</Button>
        <h2 className="text-sm font-semibold text-ink">
          Mon planning · {date(days[0])} – {date(days[6])}
        </h2>
        <Button size="sm" onClick={() => setWeekStart(iso(addDays(weekStart, 7)))} aria-label="Semaine suivante">→</Button>
      </div>

      {shifts.isLoading ? (
        <Loading />
      ) : (
        <ul className="space-y-2">
          {days.map((d) => {
            const mine = (shifts.data ?? []).filter((s) => s.shift_date === d)
            const published = mine.some((s) => (s.schedules as { status: string }).status === 'published')
            return (
              <li key={d} className="lux-card p-3">
                <p className="text-2xs font-semibold uppercase tracking-[0.08em] text-ink-faint">
                  {new Date(`${d}T00:00:00`).toLocaleDateString('fr-LU', { weekday: 'long', day: 'numeric' })}
                </p>
                {mine.length === 0 ? (
                  <p className="mt-1 text-sm text-ink-muted">Repos</p>
                ) : !published ? (
                  // Aucun silence : un planning non publié s'affiche comme tel.
                  <p className="mt-1 text-sm text-ink-muted">
                    <Badge tone="neutral">Planning non publié</Badge>
                    <span className="mt-1 block text-xs">En cours de préparation.</span>
                  </p>
                ) : (
                  mine.map((s) => (
                    <p key={s.id} className="mt-1 text-sm text-ink">
                      <strong>{time(s.start_time)} – {time(s.end_time)}</strong>
                      <span className="ml-2 text-ink-muted">{s.label}</span>
                    </p>
                  ))
                )}
              </li>
            )
          })}
        </ul>
      )}

      <div className="grid grid-cols-2 gap-2">
        <div className="lux-card p-3">
          <p className="lux-label">Solde de congés</p>
          <p className="text-2xl font-bold text-ink">{num(balance.data?.balance, 1)} j</p>
        </div>
        <div className="lux-card p-3">
          <p className="lux-label">Entrées prévues</p>
          <p className="text-2xl font-bold text-ink">
            {(shifts.data ?? []).filter((s) => (s.schedules as { status: string }).status === 'published').length}
          </p>
        </div>
      </div>
    </div>
  )
}

function MyLeave() {
  const employeeId = useSelfEmployeeId()
  const { profile, referenceDate } = useApp()
  const types = useAbsenceTypes()
  const create = useCreateAbsence()
  const navigate = useNavigate()

  const [typeId, setTypeId] = useState('')
  const [start, setStart] = useState(referenceDate)
  const [end, setEnd] = useState(referenceDate)
  const [comment, setComment] = useState('')

  const impact = useLeaveImpact(employeeId, typeId, start, end)
  const requestable = (types.data ?? []).filter((t) =>
    ['annual_leave', 'extraordinary', 'unpaid'].includes(t.category),
  )

  return (
    <div className="space-y-3">
      <h2 className="text-sm font-semibold text-ink">Demander un congé</h2>

      <Field label="Type" required>
        <Select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
          <option value="">Choisir…</option>
          {requestable.map((t) => (
            <option key={t.id} value={t.id}>{t.label}</option>
          ))}
        </Select>
      </Field>
      <div className="grid grid-cols-2 gap-2">
        <Field label="Du" required>
          <Input type="date" value={start} onChange={(e) => setStart(e.target.value)} />
        </Field>
        <Field label="Au" required>
          <Input type="date" value={end} onChange={(e) => setEnd(e.target.value)} />
        </Field>
      </div>

      {/* La demande montre son impact avant l'envoi. */}
      {impact.data && (
        <div className="lux-card p-3">
          <div className="flex items-center justify-between">
            <span className="text-xs text-ink-muted">Jours décomptés</span>
            <span className="font-mono text-sm font-semibold text-ink">
              {num(impact.data.days_counted, 1)} j
            </span>
          </div>
          {impact.data.balance_after !== undefined && (
            <div className="mt-1 flex items-center justify-between">
              <span className="text-xs text-ink-muted">Solde après la demande</span>
              <span className="font-mono text-sm font-semibold text-ink">
                {num(impact.data.balance_after, 1)} j
              </span>
            </div>
          )}
          <p
            className={`mt-2 rounded px-2 py-1.5 text-xs ${
              impact.data.is_valid ? 'bg-rule-rail text-ink-muted' : 'bg-danger-veil text-danger-ink'
            }`}
          >
            {impact.data.message}
          </p>
          {impact.data.legal_ref && (
            <p className="mt-1 font-mono text-2xs text-ink-faint">{impact.data.legal_ref}</p>
          )}
        </div>
      )}

      <Field label="Commentaire (facultatif)">
        <Input value={comment} onChange={(e) => setComment(e.target.value)} />
      </Field>

      <ErrorNote error={create.error} />

      <div className="flex gap-2">
        <Button
          variant="primary"
          className="flex-1"
          disabled={!typeId || !impact.data?.is_valid || create.isPending}
          onClick={() =>
            create.mutate(
              {
                company_id: profile!.selfEmployee!.company_id,
                employee_id: employeeId!,
                absence_type_id: typeId,
                start_date: start,
                end_date: end,
                days_count: impact.data!.days_counted,
                status: 'pending',
                comment: comment || null,
              },
              { onSuccess: () => navigate('/mon-espace') },
            )
          }
        >
          {create.isPending ? 'Envoi…' : 'Envoyer la demande'}
        </Button>
      </div>
      <p className="text-xs text-ink-muted">Votre responsable est notifié dès l’envoi.</p>
    </div>
  )
}

function MyDocuments() {
  const employeeId = useSelfEmployeeId()
  const { data, isLoading } = useEmployee(employeeId)
  if (isLoading) return <Loading />
  return (
    <div className="space-y-3">
      <h2 className="text-sm font-semibold text-ink">Mes documents</h2>
      {(data?.contracts ?? []).map((c) => (
        <div key={c.id} className="lux-card p-3">
          <p className="text-sm font-medium text-ink">
            Contrat {c.kind.toUpperCase()} — {c.job_title}
          </p>
          <p className="text-xs text-ink-muted">depuis le {date(c.start_date)}</p>
        </div>
      ))}
      {(data?.documents ?? []).map((d) => (
        <div key={d.id} className="lux-card p-3">
          <p className="text-sm font-medium text-ink">{d.name}</p>
          <p className="text-xs text-ink-muted">{date(d.created_at)}</p>
        </div>
      ))}
      {(data?.documents ?? []).length === 0 && (
        <p className="text-xs text-ink-muted">
          Aucun document déposé. Vos fiches de salaire apparaîtront ici dès leur mise à disposition.
        </p>
      )}
    </div>
  )
}

function MyProfile() {
  const employeeId = useSelfEmployeeId()
  const { referenceDate, signOut, profile } = useApp()
  const { data } = useEmployee(employeeId)
  const sick = useSickCounters(employeeId, referenceDate)
  const balance = useLeaveBalance(employeeId, referenceDate)

  async function exportData() {
    const payload = {
      exported_at: new Date().toISOString(),
      employee: data,
      leave_balance: balance.data,
      sick_counters: sick.data,
      note: 'Export au titre du droit d’accès (art. 15 RGPD).',
    }
    const url = URL.createObjectURL(new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' }))
    const a = document.createElement('a')
    a.href = url
    a.download = 'mes-donnees.json'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-3">
      <Card title="Mon profil">
        <dl className="space-y-1.5 text-sm">
          <div className="flex justify-between gap-3">
            <dt className="text-ink-muted">Nom</dt>
            <dd className="text-ink">{data?.first_name} {data?.last_name}</dd>
          </div>
          <div className="flex justify-between gap-3">
            <dt className="text-ink-muted">Compte</dt>
            <dd className="text-ink">{profile?.email}</dd>
          </div>
          <div className="flex justify-between gap-3">
            <dt className="text-ink-muted">Solde de congés</dt>
            <dd className="font-mono text-ink">{num(balance.data?.balance, 2)} j</dd>
          </div>
        </dl>
      </Card>
      <Card title="Mes droits">
        <p className="text-xs leading-relaxed text-ink-muted">
          Vous pouvez exporter les données personnelles vous concernant. Vous ne voyez jamais les données d’un
          collègue : le cloisonnement est imposé en base.
        </p>
        <Button size="sm" className="mt-2 w-full" onClick={exportData}>
          Exporter mes données
        </Button>
      </Card>
      <Button className="w-full" onClick={signOut}>Se déconnecter</Button>
    </div>
  )
}

function MyRequests() {
  const employeeId = useSelfEmployeeId()
  const { data } = useQuery({
    enabled: !!employeeId,
    queryKey: ['self-absences', employeeId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('absences')
        .select('*, absence_types(label, category)')
        .eq('employee_id', employeeId!)
        .order('start_date', { ascending: false })
      if (error) throw new Error(error.message)
      return data
    },
  })
  if (!data?.length) return null
  return (
    <Card title="Mes demandes" dense>
      <ul className="divide-y divide-rule">
        {data.slice(0, 6).map((a) => (
          <li key={a.id} className="flex items-center justify-between gap-2 px-4 py-2">
            <span className="min-w-0 text-sm text-ink-body">
              <span className="block truncate">{a.absence_types?.label}</span>
              <span className="block text-2xs text-ink-faint">
                {date(a.start_date)} – {date(a.end_date)}
              </span>
            </span>
            <Badge tone={a.status === 'approved' ? 'ok' : a.status === 'pending' ? 'info' : 'neutral'}>
              {ABSENCE_STATUS_LABEL[a.status]}
            </Badge>
          </li>
        ))}
      </ul>
    </Card>
  )
}

export default function SelfService() {
  const { profile } = useApp()
  const employeeId = useSelfEmployeeId()

  if (!employeeId) {
    return (
      <div className="mx-auto max-w-md p-6">
        <Card title="Espace salarié indisponible">
          Votre compte n’est rattaché à aucune fiche salarié. Contactez votre gestionnaire.
        </Card>
      </div>
    )
  }

  return (
    <div className="mx-auto flex min-h-screen max-w-md flex-col bg-canvas">
      <header className="bg-violet px-4 py-4 text-white">
        <p className="text-2xs uppercase tracking-[0.14em] text-white/70">LuxRH</p>
        <p className="text-lg font-bold">Bonjour {profile?.full_name?.split(' ')[0]}</p>
      </header>

      <main className="flex-1 space-y-3 p-4 pb-24">
        <Routes>
          <Route
            index
            element={
              <>
                <MyPlanning />
                <MyRequests />
              </>
            }
          />
          <Route path="conges" element={<MyLeave />} />
          <Route path="documents" element={<MyDocuments />} />
          <Route path="profil" element={<MyProfile />} />
          <Route path="*" element={<Navigate to="/mon-espace" replace />} />
        </Routes>
      </main>

      {/* Cibles tactiles de 56 px : au-delà du minimum de 44 px. */}
      <nav
        className="fixed inset-x-0 bottom-0 mx-auto flex max-w-md border-t border-rule bg-white"
        aria-label="Navigation de l’espace salarié"
      >
        {NAV.map((n) => (
          <NavLink
            key={n.to}
            to={n.to}
            end={n.end}
            className={({ isActive }) =>
              `flex flex-1 items-center justify-center py-4 text-xs font-medium ${
                isActive ? 'border-t-2 border-violet text-violet-deep' : 'text-ink-muted'
              }`
            }
          >
            {n.label}
          </NavLink>
        ))}
      </nav>
    </div>
  )
}
