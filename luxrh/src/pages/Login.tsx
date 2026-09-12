import { useState, type FormEvent } from 'react'
import { appUrl, supabase } from '@/lib/supabase'
import { Button, ErrorNote, Field, Input } from '@/components/ui'

type Mode = 'signin' | 'signup'

export default function Login() {
  const [mode, setMode] = useState<Mode>('signin')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [orgName, setOrgName] = useState('')
  const [orgKind, setOrgKind] = useState<'fiduciary' | 'company'>('fiduciary')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)

  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    setNotice(null)
    try {
      if (mode === 'signin') {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        if (error) throw error
      } else {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            // Sans cette redirection, le lien de confirmation renvoie vers la
            // « Site URL » du projet Supabase, qui n'est pas cette application.
            emailRedirectTo: appUrl(),
            data: {
              nom_complet: fullName,
              organization_name: orgName,
              organization_kind: orgKind,
            },
          },
        })
        if (error) throw error

        // Quand l'adresse est déjà enregistrée, Supabase répond « succès » sans
        // envoyer de courriel, pour ne pas révéler quels comptes existent. Le
        // signe distinctif est la liste d'identités vide. Le dire clairement
        // vaut mieux que d'annoncer une création qui n'a pas eu lieu.
        if (data.user && (data.user.identities?.length ?? 0) === 0) {
          setError(
            `Cette adresse est déjà enregistrée. Aucun courriel n'a été envoyé. ` +
              `Connectez-vous, ou utilisez « mot de passe oublié » si vous l'avez perdu.`,
          )
        } else if (!data.session) {
          setNotice(
            'Compte créé. Un courriel de confirmation vient de partir : ouvrez le lien ' +
              'depuis ce navigateur pour activer votre espace.',
          )
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-[1fr_460px]">
      <aside className="hidden flex-col justify-between bg-violet p-12 text-white lg:flex">
        <div className="flex items-center gap-2.5">
          <span className="flex h-8 w-8 items-center justify-center rounded bg-white/15 text-xs font-bold">LR</span>
          <span className="text-2xs font-semibold uppercase tracking-[0.14em] text-white/80">
            LuxRH · Assistant RH &amp; Paie
          </span>
        </div>
        <div className="max-w-lg">
          <h1 className="text-3xl font-bold leading-tight tracking-tight">
            L’application ne se contente pas de calculer : elle avertit et explique.
          </h1>
          <p className="mt-4 text-base leading-relaxed text-white/80">
            Contrats conformes, plannings validés en temps réel contre le droit du travail luxembourgeois,
            et un tableau de bord permanent des échéances et des seuils. Chaque alerte cite l’article qui la
            motive.
          </p>
          <ul className="mt-8 space-y-2 text-sm text-white/75">
            <li>· Référentiel légal daté — aucun taux, aucun seuil écrit en dur</li>
            <li>· Hiérarchie des normes : loi → CCT → contrat, la plus favorable l’emporte</li>
            <li>· Isolation multi-sociétés imposée en base, pas dans l’interface</li>
          </ul>
        </div>
        <p className="text-2xs text-white/55">Données hébergées dans l’Union européenne.</p>
      </aside>

      <main className="flex items-center justify-center bg-white px-6 py-12">
        <form onSubmit={submit} className="w-full max-w-sm space-y-4">
          <div>
            <h2 className="text-2xl font-bold tracking-tight text-ink">
              {mode === 'signin' ? 'Connexion' : 'Créer votre espace de travail'}
            </h2>
            <p className="mt-1 text-sm text-ink-muted">
              {mode === 'signin'
                ? 'Accédez à vos dossiers clients.'
                : 'Fiduciaire ou entreprise : vous serez administrateur de l’espace.'}
            </p>
          </div>

          {mode === 'signup' && (
            <>
              <Field label="Nom complet" required>
                <Input value={fullName} onChange={(e) => setFullName(e.target.value)} required autoComplete="name" />
              </Field>
              <Field label="Nom de l’espace de travail" required>
                <Input
                  value={orgName}
                  onChange={(e) => setOrgName(e.target.value)}
                  required
                  placeholder="Fiduciaire Weiland & Associés"
                />
              </Field>
              <Field label="Type d’espace">
                <div className="flex gap-2">
                  {(['fiduciary', 'company'] as const).map((k) => (
                    <button
                      key={k}
                      type="button"
                      onClick={() => setOrgKind(k)}
                      className={`min-h-[44px] flex-1 rounded border px-3 text-sm font-medium ${
                        orgKind === k
                          ? 'border-violet bg-violet-veil text-violet-deep'
                          : 'border-rule-strong text-ink-body hover:bg-rule-rail'
                      }`}
                    >
                      {k === 'fiduciary' ? 'Fiduciaire' : 'Entreprise'}
                    </button>
                  ))}
                </div>
              </Field>
            </>
          )}

          <Field label="Adresse e-mail" required>
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
          </Field>
          <Field label="Mot de passe" required hint={mode === 'signup' ? '8 caractères minimum.' : undefined}>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={8}
              autoComplete={mode === 'signin' ? 'current-password' : 'new-password'}
            />
          </Field>

          <ErrorNote error={error} />
          {notice && (
            <p className="rounded border border-action/25 bg-action-veil px-3 py-2 text-xs text-action">{notice}</p>
          )}

          <Button type="submit" variant="primary" className="w-full" disabled={busy}>
            {busy ? 'Un instant…' : mode === 'signin' ? 'Se connecter' : 'Créer l’espace'}
          </Button>

          <p className="text-center text-xs text-ink-muted">
            {mode === 'signin' ? 'Pas encore d’espace ?' : 'Vous avez déjà un compte ?'}{' '}
            <button
              type="button"
              onClick={() => {
                setMode(mode === 'signin' ? 'signup' : 'signin')
                setError(null)
              }}
              className="font-semibold text-action hover:underline"
            >
              {mode === 'signin' ? 'En créer un' : 'Se connecter'}
            </button>
          </p>
        </form>
      </main>
    </div>
  )
}
