// Configuration des tests : variables d'environnement, sinon .env.local.
// Aucun identifiant n'est écrit en dur : le dépôt est public.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)))
const env = {}
const file = path.join(root, '.env.local')

if (fs.existsSync(file)) {
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*)$/.exec(line)
    if (m) env[m[1]] = m[2].trim()
  }
}

const read = (key) => process.env[key] ?? env[key]

export const URL_BASE = read('VITE_SUPABASE_URL')
export const KEY = read('VITE_SUPABASE_ANON_KEY')

if (!URL_BASE || !KEY) {
  throw new Error(
    'Configuration Supabase manquante : renseignez VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.local',
  )
}

/**
 * Comptes de démonstration. Les adresses ne sont pas des secrets ; les mots de
 * passe viennent de l'environnement ou de .env.local, jamais du dépôt.
 */
export const ACCOUNTS = {
  manager: { email: 'demo@luxrh.lu', password: read('LUXRH_MANAGER_PASSWORD') },
  employee: { email: 'marta@luxrh.lu', password: read('LUXRH_EMPLOYEE_PASSWORD') },
  other: { email: 'autre@luxrh.lu', password: read('LUXRH_OTHER_PASSWORD') },
}

export function account(name) {
  const found = ACCOUNTS[name]
  if (!found?.password) {
    throw new Error(
      `Mot de passe du compte « ${name} » absent. Ajoutez LUXRH_${name.toUpperCase()}_PASSWORD ` +
        'dans .env.local (voir .env.example).',
    )
  }
  return found
}
