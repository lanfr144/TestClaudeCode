import type { ReactNode } from 'react'
import type { VigilanceItem } from '@/lib/engine'
import { Badge, LegalBasis, SeverityMark, severityTone } from './ui'
import { date } from '@/lib/format'

function deadlineLabel(item: VigilanceItem) {
  if (item.days_left === null || item.days_left === undefined) return 'à surveiller'
  if (item.days_left < 0) return `échu depuis ${Math.abs(item.days_left)} j`
  if (item.days_left === 0) return "aujourd'hui"
  return `J-${item.days_left}`
}

/**
 * Une obligation, sa date limite, le salarié concerné, sa base légale et la
 * conséquence du non-respect — jamais l'un sans les autres.
 */
export function VigilanceRow({
  item, compact = false, actions,
}: { item: VigilanceItem; compact?: boolean; actions?: ReactNode }) {
  return (
    <li className="flex items-start gap-3 px-4 py-3">
      <SeverityMark severity={item.severite} />
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold text-ink">{item.titre}</p>
        <p className="mt-0.5 text-xs leading-relaxed text-ink-muted">
          {item.detail}
          {!compact && item.consequence && (
            <>
              {' '}
              <span className="text-ink-body">Conséquence : {item.consequence}</span>
            </>
          )}
        </p>
        {!compact && (item.reference_legale || actions) && (
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <LegalBasis compact reference={item.reference_legale} />
            {actions}
          </div>
        )}
        {compact && item.reference_legale && (
          <span className="mt-1 inline-bloc font-mono text-2xs text-ink-faint">{item.reference_legale}</span>
        )}
      </div>
      <div className="shrink-0 text-right">
        <p className="text-xs font-semibold text-ink-body">{deadlineLabel(item)}</p>
        {item.date_echeance && <p className="text-2xs text-ink-faint">{date(item.date_echeance)}</p>}
        <div className="mt-1">
          <Badge tone={severityTone(item.severite)}>
            {item.severite === 'bloquant' ? 'Bloquant' : item.severite === 'avertissement' ? 'Échéance' : 'Seuil'}
          </Badge>
        </div>
      </div>
    </li>
  )
}

export function VigilanceBlock({
  title, tone, items, compact, renderActions,
}: {
  title: string
  tone: 'bloquant' | 'avertissement' | 'info'
  items: VigilanceItem[]
  compact?: boolean
  renderActions?: (item: VigilanceItem) => ReactNode
}) {
  const bar = { bloquant: 'bg-danger', avertissement: 'bg-warn', info: 'bg-action' }[tone]
  return (
    <section className="lux-card overflow-hidden">
      <header className="flex items-center gap-2 border-b border-rule px-4 py-2.5">
        <span className={`h-2 w-2 rounded-full ${bar}`} aria-hidden />
        <h3 className="text-sm font-semibold text-ink">{title}</h3>
        <span className="ml-auto text-xs text-ink-faint">{items.length}</span>
      </header>
      {items.length === 0 ? (
        <p className="px-4 py-4 text-xs text-ink-muted">Rien à signaler dans ce bloc.</p>
      ) : (
        <ul className="divide-y divide-rule">
          {items.map((i) => (
            <VigilanceRow
              key={`${i.code_regle}-${i.salarie_id ?? i.planning_id ?? 'x'}`}
              item={i}
              compact={compact}
              actions={renderActions?.(i)}
            />
          ))}
        </ul>
      )}
    </section>
  )
}
