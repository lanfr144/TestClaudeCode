import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from 'react'
import type { Arbitration, Severity } from '@/lib/engine'
import { num } from '@/lib/format'

/* ------------------------------------------------------------- primitives */

export function Card({
  title, subtitle, action, children, className = '', dense = false,
}: {
  title?: ReactNode; subtitle?: ReactNode; action?: ReactNode
  children: ReactNode; className?: string; dense?: boolean
}) {
  return (
    <section className={`lux-card ${className}`}>
      {(title || action) && (
        <header className="flex items-start justify-between gap-4 border-b border-rule px-4 py-3">
          <div>
            {typeof title === 'string' ? (
              <h2 className="text-base font-semibold text-ink">{title}</h2>
            ) : (
              title
            )}
            {subtitle && <p className="mt-0.5 text-xs text-ink-muted">{subtitle}</p>}
          </div>
          {action}
        </header>
      )}
      <div className={dense ? '' : 'p-4'}>{children}</div>
    </section>
  )
}

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md'
}

export function Button({ variant = 'secondary', size = 'md', className = '', ...props }: ButtonProps) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded font-semibold transition-colors ' +
    'disabled:cursor-not-allowed disabled:opacity-55'
  // 44 px de haut en taille normale : cible tactile accessible.
  const sizes = { sm: 'min-h-[34px] px-3 text-xs', md: 'min-h-[44px] px-4 text-sm' }
  const variants = {
    primary: 'bg-action text-white hover:bg-action-hover',
    secondary: 'bg-white text-ink-body border border-rule-strong hover:bg-rule-rail',
    ghost: 'text-action hover:bg-action-veil',
    danger: 'bg-danger text-white hover:bg-danger-deep',
  }
  return <button className={`${base} ${sizes[size]} ${variants[variant]} ${className}`} {...props} />
}

export function Field({
  label, hint, error, children, required,
}: { label: string; hint?: ReactNode; error?: string; children: ReactNode; required?: boolean }) {
  return (
    <label className="block">
      <span className="lux-label">
        {label}
        {required && <span className="ml-1 text-danger">*</span>}
      </span>
      <div className="mt-1.5">{children}</div>
      {error ? (
        <p className="mt-1 text-xs text-danger-ink">{error}</p>
      ) : hint ? (
        <p className="mt-1 text-xs text-ink-muted">{hint}</p>
      ) : null}
    </label>
  )
}

export const Input = (p: InputHTMLAttributes<HTMLInputElement>) => (
  <input {...p} className={`lux-input ${p.className ?? ''}`} />
)

export const Select = (p: SelectHTMLAttributes<HTMLSelectElement>) => (
  <select {...p} className={`lux-input ${p.className ?? ''}`} />
)

/* ------------------------------------------------------------------ états */

export const Skeleton = ({ className = 'h-4 w-full' }: { className?: string }) => (
  <div className={`lux-skeleton ${className}`} aria-hidden />
)

export function Loading({ label = 'Chargement…' }: { label?: string }) {
  return (
    <div className="space-y-2 p-4" role="status" aria-live="polite">
      <span className="sr-only">{label}</span>
      <Skeleton className="h-4 w-1/3" />
      <Skeleton className="h-4 w-2/3" />
      <Skeleton className="h-4 w-1/2" />
    </div>
  )
}

export function EmptyState({ title, detail, action }: { title: string; detail?: string; action?: ReactNode }) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-12 text-center">
      <div className="flex h-10 w-10 items-center justify-center rounded-md bg-rule-rail text-ink-faint">◍</div>
      <p className="text-sm font-semibold text-ink">{title}</p>
      {detail && <p className="max-w-md text-xs text-ink-muted">{detail}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  )
}

/** Aucune erreur silencieuse : tout échec est affiché avec son message. */
export function ErrorNote({ error }: { error: unknown }) {
  if (!error) return null
  const message = error instanceof Error ? error.message : String(error)
  return (
    <div className="rounded border border-danger/30 bg-danger-veil px-3 py-2 text-xs text-danger-ink" role="alert">
      <strong className="font-semibold">Erreur.</strong> {message}
    </div>
  )
}

/* ----------------------------------------------------------------- badges */

const BADGE_TONES = {
  blocking: 'bg-danger-veil text-danger-ink border-danger/25',
  warning: 'bg-warn-veil text-warn-ink border-warn/25',
  info: 'bg-action-veil text-action border-action/25',
  ok: 'bg-success-veil text-success-ink border-success/25',
  neutral: 'bg-rule-rail text-ink-muted border-rule-strong',
  violet: 'bg-violet-veil text-violet-deep border-violet-line',
} as const

export type BadgeTone = keyof typeof BADGE_TONES

export function Badge({ tone = 'neutral', children }: { tone?: BadgeTone; children: ReactNode }) {
  return (
    <span
      className={`inline-flex items-center gap-1 whitespace-nowrap rounded border px-2 py-0.5 text-2xs font-semibold ${BADGE_TONES[tone]}`}
    >
      {children}
    </span>
  )
}

export const SEVERITY_LABEL: Record<Severity, string> = {
  blocking: 'Bloquant',
  warning: 'Avertissement',
  info: 'À surveiller',
  ok: 'Conforme',
}

export const SEVERITY_GLYPH: Record<Severity, string> = {
  blocking: '✕',
  warning: '▲',
  info: 'i',
  ok: '✓',
}

export const severityTone = (s: Severity): BadgeTone =>
  s === 'blocking' ? 'blocking' : s === 'warning' ? 'warning' : s === 'ok' ? 'ok' : 'info'

export function SeverityMark({ severity }: { severity: Severity }) {
  const tone = severityTone(severity)
  return (
    <span
      aria-label={SEVERITY_LABEL[severity]}
      title={SEVERITY_LABEL[severity]}
      className={`inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full border text-2xs font-bold ${BADGE_TONES[tone]}`}
    >
      {SEVERITY_GLYPH[severity]}
    </span>
  )
}

/* ------------------------------------------------- composant « base légale »
 * Le composant signature du produit : il accompagne toute valeur retenue,
 * toute alerte, toute ligne de calcul.
 */

export function LegalBasis({
  reference, text, value, validity, source, compact = false,
}: {
  reference: string | null | undefined
  text?: string
  value?: string
  validity?: string
  source?: string
  compact?: boolean
}) {
  if (!reference) return null
  if (compact) {
    return (
      <span className="inline-flex items-center rounded bg-rule-rail px-1.5 py-0.5 font-mono text-2xs text-ink-faint">
        {reference}
      </span>
    )
  }
  return (
    <div className="rounded-md border border-rule bg-rule-rail/60 p-3">
      <p className="lux-label">Base légale</p>
      <p className="mt-1 font-mono text-xs text-violet">{reference}</p>
      {text && <p className="mt-1.5 text-sm leading-relaxed text-ink-body">{text}</p>}
      {(value || validity || source) && (
        <dl className="mt-3 grid grid-cols-3 gap-3 border-t border-rule pt-2.5">
          {value && (
            <div>
              <dt className="text-2xs text-ink-faint">Valeur utilisée</dt>
              <dd className="text-sm font-semibold text-ink">{value}</dd>
            </div>
          )}
          {validity && (
            <div>
              <dt className="text-2xs text-ink-faint">Validité</dt>
              <dd className="text-sm text-ink-body">{validity}</dd>
            </div>
          )}
          {source && (
            <div>
              <dt className="text-2xs text-ink-faint">Source</dt>
              <dd className="text-sm text-ink-body">{source}</dd>
            </div>
          )}
        </dl>
      )}
    </div>
  )
}

/* ------------------------------------------------- hiérarchie des normes */

export function ArbitrationPanel({ arbitration, unit = '' }: { arbitration: Arbitration; unit?: string }) {
  const rows = [
    { label: 'Code du travail', value: arbitration.law_value, ref: arbitration.law_ref, src: 'Code du travail' },
    { label: arbitration.cba_ref ?? 'CCT', value: arbitration.cba_value, ref: null, src: 'CCT' },
    { label: 'Contrat individuel', value: arbitration.contract_value, ref: null, src: 'Contrat individuel' },
  ]
  return (
    <div>
      <p className="lux-label">Hiérarchie des normes — {arbitration.label}</p>
      <div className="mt-2 grid gap-2 sm:grid-cols-3">
        {rows.map((r) => {
          const retained = r.src === arbitration.retained_source
          return (
            <div
              key={r.label}
              className={`rounded-md border p-2.5 ${
                retained ? 'border-violet bg-violet-veil' : 'border-rule bg-white'
              }`}
            >
              <p className="flex items-center gap-1.5 text-2xs text-ink-faint">
                <span className="truncate">{r.label}</span>
                {retained && <Badge tone="violet">retenu</Badge>}
              </p>
              <p className={`mt-1 text-lg font-semibold ${retained ? 'text-violet-deep' : 'text-ink-body'}`}>
                {r.value === null || r.value === undefined ? (
                  <span className="text-sm font-normal text-ink-faint">non stipulé</span>
                ) : (
                  `${num(r.value)} ${unit}`.trim()
                )}
              </p>
            </div>
          )
        })}
      </div>
      <p className="mt-2 text-xs text-ink-muted">
        Loi → CCT → contrat : la disposition la plus favorable au salarié l’emporte, et l’application dit
        laquelle a gagné.
      </p>
    </div>
  )
}

/* ------------------------------------------------- avertissement juridique */

export function LegalDisclaimer({ text }: { text?: string }) {
  return (
    <p className="rounded-md border border-rule bg-white px-3 py-2 text-xs text-ink-muted">
      <span className="font-semibold text-ink-body">LuxRH est un outil d’aide à la décision.</span>{' '}
      {text ?? 'Il ne se substitue pas à un conseil juridique.'}
    </p>
  )
}

/* ---------------------------------------------------------------- tableau */

export function Table({ head, children }: { head: ReactNode[]; children: ReactNode }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] border-collapse">
        <thead className="border-b border-rule bg-rule-rail/60">
          <tr>
            {head.map((h, i) => (
              <th key={i} scope="col" className="lux-th">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-rule">{children}</tbody>
      </table>
    </div>
  )
}

export function Avatar({ text, tone = 'violet' }: { text: string; tone?: 'violet' | 'action' }) {
  return (
    <span
      className={`inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-xs font-bold text-white ${
        tone === 'violet' ? 'bg-violet' : 'bg-action'
      }`}
    >
      {text}
    </span>
  )
}

export function StatTile({
  label, value, hint, tone = 'neutral',
}: { label: string; value: ReactNode; hint?: ReactNode; tone?: BadgeTone }) {
  const accent = {
    blocking: 'text-danger-ink', warning: 'text-warn-ink', info: 'text-action',
    ok: 'text-success-ink', neutral: 'text-ink', violet: 'text-violet-deep',
  }[tone]
  return (
    <div className="lux-card p-3.5">
      <p className="lux-label">{label}</p>
      <p className={`mt-1 text-2xl font-bold tracking-tight ${accent}`}>{value}</p>
      {hint && <p className="mt-0.5 text-xs text-ink-muted">{hint}</p>}
    </div>
  )
}
