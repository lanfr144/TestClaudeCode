import { useMemo, useState } from 'react'
import { useApp } from '@/context/AppContext'
import {
  useAbsences, useCreateSchedule, useDeleteShift, useEmployees, usePublicHolidays,
  usePublishSchedule, useReferencePeriod, useSchedule, useScheduleValidation,
  useShiftTemplates, useUpsertShift, type ShiftWithEmployee,
} from '@/lib/queries'
import {
  Badge, Button, Card, EmptyState, ErrorNote, LegalBasis, Loading, Select, SeverityMark,
} from '@/components/ui'
import { addDays, date, hours, isoWeek, iso, mondayOf, num, time } from '@/lib/format'
import type { Violation } from '@/lib/engine'

const DAY_LABELS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']

export default function Planning() {
  const { activeCompanyId, referenceDate } = useApp()
  const [weekStart, setWeekStart] = useState(() => iso(mondayOf(new Date(`${referenceDate}T00:00:00`))))
  const [pendingEmployee, setPendingEmployee] = useState('')

  const { data, isLoading, error } = useSchedule(activeCompanyId ?? undefined, weekStart)
  const schedule = data?.schedule ?? null
  const creneaux = data?.creneaux ?? []
  const validation = useScheduleValidation(schedule?.id)
  const templates = useShiftTemplates(activeCompanyId ?? undefined)
  const salaries = useEmployees(activeCompanyId ?? undefined)
  const absences = useAbsences(activeCompanyId ?? undefined)
  const holidays = usePublicHolidays(new Date(`${weekStart}T00:00:00`).getFullYear())
  const prl = useReferencePeriod(activeCompanyId ?? undefined, referenceDate)

  const createSchedule = useCreateSchedule()
  const upsertShift = useUpsertShift()
  const deleteShift = useDeleteShift()
  const publish = usePublishSchedule()

  const days = useMemo(
    () => Array.from({ length: 7 }, (_, i) => iso(addDays(weekStart, i))),
    [weekStart],
  )

  // Salariés présents sur la grille, plus ceux ajoutés à la main.
  const [extraRows, setExtraRows] = useState<string[]>([])
  const rowIds = useMemo(() => {
    const fromShifts = [...new Set(creneaux.map((s) => s.salarie_id))]
    return [...new Set([...fromShifts, ...extraRows])]
  }, [creneaux, extraRows])

  const rows = rowIds
    .map((id) => (salaries.data ?? []).find((e) => e.id === id))
    .filter((e): e is NonNullable<typeof e> => !!e)

  const violationsByCell = useMemo(() => {
    const map = new Map<string, Violation[]>()
    for (const v of validation.data?.violations ?? []) {
      if (!v.salarie_id || !v.date_creneau) continue
      const k = `${v.salarie_id}|${v.date_creneau}`
      map.set(k, [...(map.get(k) ?? []), v])
    }
    return map
  }, [validation.data])

  const summaryFor = (id: string) => validation.data?.salaries.find((e) => e.salarie_id === id)

  const absenceOn = (employeeId: string, day: string) =>
    (absences.data ?? []).find(
      (a) => a.salarie_id === employeeId && a.statut !== 'refused' && a.date_debut <= day && a.date_fin >= day,
    )

  const isHoliday = (day: string) => (holidays.data ?? []).some((h) => h.date_ferie === day)

  async function ensureSchedule(): Promise<string> {
    if (schedule) return schedule.id
    const created = await createSchedule.mutateAsync({
      societe_id: activeCompanyId!,
      debut_semaine: weekStart,
      libelle: `Semaine ${isoWeek(new Date(`${weekStart}T00:00:00`))}`,
      statut: 'draft',
    })
    return created.id
  }

  async function dropTemplate(employeeId: string, day: string, templateId: string) {
    const t = (templates.data ?? []).find((x) => x.id === templateId)
    if (!t) return
    const scheduleId = await ensureSchedule()
    await upsertShift.mutateAsync({
      planning_id: scheduleId,
      societe_id: activeCompanyId!,
      salarie_id: employeeId,
      date_creneau: day,
      heure_debut: t.heure_debut,
      heure_fin: t.heure_fin,
      pause_minutes: t.pause_minutes,
      libelle: t.nom,
      modele_id: t.id,
    })
  }

  async function moveShift(shift: ShiftWithEmployee, employeeId: string, day: string) {
    await upsertShift.mutateAsync({
      id: shift.id,
      planning_id: shift.planning_id,
      societe_id: shift.societe_id,
      salarie_id: employeeId,
      date_creneau: day,
      heure_debut: shift.heure_debut,
      heure_fin: shift.heure_fin,
      pause_minutes: shift.pause_minutes,
      libelle: shift.libelle,
      modele_id: shift.modele_id,
    })
  }

  const weekNo = isoWeek(new Date(`${weekStart}T00:00:00`))
  const published = schedule?.statut === 'publie'

  if (!activeCompanyId) return <Card title="Aucun dossier sélectionné">Choisissez une société.</Card>
  if (isLoading) return <Card><Loading label="Chargement du planning…" /></Card>
  if (error) return <ErrorNote error={error} />

  return (
    <div className="space-y-4">
      {/* Période de référence */}
      {prl.data && (
        <div className="lux-card flex flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3">
          <div>
            <p className="lux-libelle">Période de référence</p>
            <p className="text-sm font-medium text-ink">
              {prl.data.libelle} · {date(prl.data.date_debut)} → {date(prl.data.date_fin)}
            </p>
          </div>
          <div>
            <p className="lux-libelle">Moyenne constatée</p>
            <p className="text-sm font-semibold text-ink">
              {num(prl.data.average_weekly_hours, 1)} h / sem.
            </p>
          </div>
          <p className="text-xs text-ink-muted">
            {prl.data.margin_hours >= 0
              ? `Marge de ${num(prl.data.margin_hours, 1)} h avant heures supplémentaires.`
              : `Dépassement de ${num(Math.abs(prl.data.margin_hours), 1)} h sur la moyenne cible.`}
          </p>
          <div className="ml-auto"><LegalBasis compact reference={prl.data.reference_legale} /></div>
        </div>
      )}

      <header className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Button size="sm" onClick={() => setWeekStart(iso(addDays(weekStart, -7)))} aria-label="Semaine précédente">
            ←
          </Button>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-ink">
              Semaine {weekNo} · {date(days[0])} – {date(days[6])}
            </h1>
            <p className="text-xs text-ink-muted">
              {published ? `Publié le ${date(schedule?.publie_le)}` : 'Brouillon — non publié'}
            </p>
          </div>
          <Button size="sm" onClick={() => setWeekStart(iso(addDays(weekStart, 7)))} aria-label="Semaine suivante">
            →
          </Button>
        </div>

        <div className="flex items-center gap-2">
          <Badge tone={published ? 'ok' : 'neutral'}>{published ? 'Publié' : 'Brouillon'}</Badge>
          <Button
            variant="primary"
            size="sm"
            disabled={!schedule || published || publish.isPending || !validation.data?.can_publish}
            onClick={() => schedule && publish.mutate(schedule.id)}
          >
            {publish.isPending
              ? 'Publication…'
              : validation.data && !validation.data.can_publish
                ? `Publier · ${validation.data.blocking_count} blocage${validation.data.blocking_count > 1 ? 's' : ''}`
                : 'Publier et notifier'}
          </Button>
        </div>
      </header>

      <ErrorNote error={publish.error ?? upsertShift.error ?? deleteShift.error} />

      <div className="grid gap-4 xl:grid-cols-[1fr_360px]">
        <div className="space-y-3">
          {/* Palette de modèles : glisser sur une case. */}
          <div className="lux-card flex flex-wrap items-center gap-2 px-3 py-2.5">
            <span className="lux-libelle">Modèles</span>
            {(templates.data ?? []).map((t) => (
              <span
                key={t.id}
                draggable
                onDragStart={(e) => e.dataTransfer.setData('application/x-template', t.id)}
                className="cursor-grab rounded border px-2 py-1 text-2xs font-semibold text-white active:cursor-grabbing"
                style={{ background: t.couleur, borderColor: t.couleur }}
                title={`${time(t.heure_debut)}–${time(t.heure_fin)}`}
              >
                {t.nom} · {time(t.heure_debut)}–{time(t.heure_fin)}
              </span>
            ))}
            {(templates.data ?? []).length === 0 && (
              <span className="text-xs text-ink-muted">Aucun modèle enregistré.</span>
            )}
          </div>

          <div className="lux-card overflow-x-auto">
            <table className="w-full min-w-[900px] border-collapse">
              <thead>
                <tr className="border-b border-rule bg-rule-rail/60">
                  <th className="lux-th w-52">Salarié</th>
                  {days.map((d, i) => (
                    <th key={d} className={`lux-th text-center ${isHoliday(d) ? 'bg-violet-veil' : ''}`}>
                      {DAY_LABELS[i]} {new Date(`${d}T00:00:00`).getDate()}
                      {isHoliday(d) && <span className="bloc text-2xs font-normal text-violet">férié</span>}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-rule">
                {rows.map((emp) => {
                  const sum = summaryFor(emp.id)
                  return (
                    <tr key={emp.id} className="align-top">
                      <td className="px-3 py-2">
                        <p className="text-sm font-medium text-ink">
                          {emp.prenom} {emp.nom}
                        </p>
                        <p className="text-2xs text-ink-muted">{sum?.intitule_poste ?? '—'}</p>
                        {sum && (
                          <p className="mt-1 text-2xs text-ink-faint">
                            {hours(sum.total_hours)}
                            {sum.heures_supplementaires > 0 && (
                              <span className="text-warn-ink"> · +{num(sum.heures_supplementaires, 1)} h supp.</span>
                            )}
                            {sum.sundays > 0 && <span> · {sum.sundays} dim.</span>}
                          </p>
                        )}
                      </td>
                      {days.map((d) => {
                        const cellShifts = creneaux.filter((s) => s.salarie_id === emp.id && s.date_creneau === d)
                        const abs = absenceOn(emp.id, d)
                        const cellViolations = violationsByCell.get(`${emp.id}|${d}`) ?? []
                        const worst = cellViolations.find((v) => v.severite === 'blocking')
                          ?? cellViolations.find((v) => v.severite === 'warning')
                        return (
                          <td
                            key={d}
                            onDragOver={(e) => {
                              if (!published) e.preventDefault()
                            }}
                            onDrop={(e) => {
                              if (published) return
                              e.preventDefault()
                              const tpl = e.dataTransfer.getData('application/x-template')
                              const shiftId = e.dataTransfer.getData('application/x-shift')
                              if (tpl) void dropTemplate(emp.id, d, tpl)
                              else if (shiftId) {
                                const s = creneaux.find((x) => x.id === shiftId)
                                if (s) void moveShift(s, emp.id, d)
                              }
                            }}
                            className={`min-w-[110px] px-1.5 py-1.5 ${
                              worst?.severite === 'blocking'
                                ? 'bg-danger-veil'
                                : worst?.severite === 'warning'
                                  ? 'bg-warn-veil'
                                  : isHoliday(d)
                                    ? 'bg-violet-veil/50'
                                    : ''
                            }`}
                          >
                            {abs && (
                              <div
                                className={`mb-1 rounded border px-1.5 py-1 text-2xs ${
                                  abs.types_absence?.categorie === 'sick'
                                    ? 'border-warn/30 bg-warn-veil text-warn-ink'
                                    : abs.statut === 'approved'
                                      ? 'border-action/30 bg-action-veil text-action'
                                      : 'border-rule-strong bg-white text-ink-muted'
                                }`}
                              >
                                <span className="bloc font-semibold">{abs.types_absence?.libelle}</span>
                                <span className="bloc">
                                  {abs.statut === 'approved' ? 'validé' : 'en attente'}
                                </span>
                              </div>
                            )}
                            {cellShifts.map((s) => (
                              <div
                                key={s.id}
                                draggable={!published}
                                onDragStart={(e) => e.dataTransfer.setData('application/x-shift', s.id)}
                                className="group mb-1 rounded border border-rule-strong bg-white px-1.5 py-1 text-2xs"
                              >
                                <span className="bloc font-semibold text-ink">
                                  {time(s.heure_debut)}–{time(s.heure_fin)}
                                </span>
                                <span className="bloc truncate text-ink-muted">{s.libelle ?? 'Service'}</span>
                                {!published && (
                                  <button
                                    onClick={() => deleteShift.mutate(s.id)}
                                    className="mt-0.5 hidden text-danger group-hover:bloc"
                                  >
                                    Supprimer
                                  </button>
                                )}
                              </div>
                            ))}
                            {worst && (
                              <p className="flex items-center gap-1 text-2xs font-semibold text-ink-body">
                                <SeverityMark severity={worst.severite} />
                                {worst.code === 'daily_rest' ? 'Repos 11 h' : worst.code === 'max_daily_hours' ? '10 h max' : 'Contrôle'}
                              </p>
                            )}
                          </td>
                        )
                      })}
                    </tr>
                  )
                })}
                {rows.length === 0 && (
                  <tr>
                    <td colSpan={8}>
                      <EmptyState
                        title="Aucun salarié sur cette semaine"
                        detail="Ajoutez un salarié à la grille, puis glissez un modèle de shift sur une case."
                      />
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {!published && (
            <div className="flex items-center gap-2">
              <Select
                value={pendingEmployee}
                onChange={(e) => setPendingEmployee(e.target.value)}
                className="max-w-xs"
              >
                <option value="">Ajouter un salarié à la grille…</option>
                {(salaries.data ?? [])
                  .filter((e) => !rowIds.includes(e.id))
                  .map((e) => (
                    <option key={e.id} value={e.id}>
                      {e.nom} {e.prenom}
                    </option>
                  ))}
              </Select>
              <Button
                size="sm"
                disabled={!pendingEmployee}
                onClick={() => {
                  setExtraRows((r) => [...r, pendingEmployee])
                  setPendingEmployee('')
                }}
              >
                Ajouter
              </Button>
            </div>
          )}
        </div>

        {/* Panneau de contrôles légaux */}
        <aside className="space-y-3">
          <Card
            dense
            title={
              <span className="flex items-center gap-2">
                Contrôles légaux
                {validation.data && validation.data.blocking_count > 0 && (
                  <Badge tone="blocking">{validation.data.blocking_count} bloquant</Badge>
                )}
              </span>
            }
            subtitle="évalué à chaque modification"
          >
            {validation.isFetching && <Loading label="Revalidation…" />}
            {!validation.isFetching && (validation.data?.violations.length ?? 0) === 0 && (
              <p className="px-4 py-4 text-xs text-ink-muted">
                {schedule
                  ? 'Aucune violation détectée : le planning est publiable.'
                  : 'Aucun planning pour cette semaine. Glissez un modèle sur une case pour le créer.'}
              </p>
            )}
            <ul className="divide-y divide-rule">
              {(validation.data?.violations ?? []).map((v, i) => (
                <li key={i} className="flex items-start gap-2.5 px-4 py-3">
                  <SeverityMark severity={v.severite} />
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-ink">{v.titre}</p>
                    <p className="mt-0.5 text-xs leading-relaxed text-ink-muted">{v.detail}</p>
                    {v.reference_legale && (
                      <span className="mt-1.5 inline-bloc">
                        <LegalBasis compact reference={v.reference_legale} />
                      </span>
                    )}
                  </div>
                </li>
              ))}
            </ul>
          </Card>

          {validation.data && validation.data.salaries.length > 0 && (
            <Card title="Compteurs de la semaine" dense>
              <ul className="divide-y divide-rule">
                {validation.data.salaries.map((e) => (
                  <li key={e.salarie_id} className="flex items-center justify-between gap-2 px-4 py-2">
                    <span className="truncate text-sm text-ink-body">{e.employee_name}</span>
                    <span className="shrink-0 font-mono text-xs text-ink-muted">
                      {num(e.total_hours, 1)} h
                      {e.heures_supplementaires > 0 && <span className="text-warn-ink"> +{num(e.heures_supplementaires, 1)}</span>}
                    </span>
                  </li>
                ))}
              </ul>
            </Card>
          )}
        </aside>
      </div>
    </div>
  )
}
