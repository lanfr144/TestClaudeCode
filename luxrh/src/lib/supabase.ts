import { createClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !key) {
  throw new Error(
    "Configuration Supabase manquante : renseignez VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.local",
  )
}

export const supabase = createClient<Database>(url, key, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    // Le lien de confirmation renvoie vers l'application avec un jeton : sans
    // cette option, il n'est jamais consommé et l'utilisateur reste déconnecté.
    detectSessionInUrl: true,
    // PKCE renvoie le jeton en paramètre de requête plutôt qu'en fragment,
    // ce qui le rend lisible par un serveur — indispensable pour Streamlit,
    // et plus sûr ici aussi.
    flowType: 'pkce',
  },
})

/** URL de retour des liens de confirmation, autorisée côté Supabase. */
export const appUrl = () => window.location.origin

/**
 * Appelle une fonction du moteur de règles. Aucune règle légale n'est évaluée
 * dans le navigateur : le serveur calcule, valide et décide.
 */
export async function callEngine<T>(fn: string, args: Record<string, unknown> = {}): Promise<T> {
  const { data, error } = await supabase.rpc(fn as never, args as never)
  if (error) throw new Error(error.message)
  return data as T
}
