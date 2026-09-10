// Portabilité : export RGPD, réversibilité, et aller-retour du référentiel.
// Le point sensible n'est pas que l'export fonctionne, c'est qu'il refuse.
import { URL_BASE as URL, KEY, account } from './config.mjs'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }
const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

const signIn = async (who) => {
  const a = account(who)
  const r = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: a.email, password: a.password }),
  }).then((x) => x.json())
  if (!r.access_token) throw new Error(`connexion ${who} refusée : ${r.error_description ?? r.msg}`)
  return r.access_token
}

const manager = await signIn('manager')
const employee = await signIn('employee')

const get = (t, q) => fetch(`${URL}/rest/v1/${q}`, { headers: h(t) }).then((r) => r.json())
const rpc = async (t, fn, args = {}) => {
  const r = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: h(t), body: JSON.stringify(args),
  })
  return [r.ok, await r.json()]
}

const rows = (doc, key) => (doc?.payload?.[key] ?? []).length

console.log('\n== Droit d’accès du salarié ==')
{
  const [good, doc] = await rpc(employee, 'fn_export_self')
  good ? ok('export personnel produit') : ko('export personnel', JSON.stringify(doc))
  doc?.format === 'luxrh.export/1' ? ok('enveloppe versionnée') : ko('enveloppe', doc?.format)
  doc?.kind === 'employee' ? ok('genre « employee »') : ko('genre', doc?.kind)

  const moi = doc?.payload?.employee ?? {}
  // Un export où le matricule reste chiffré ne satisfait pas le droit d'accès.
  typeof moi.national_id === 'string' && /^\d{13}$/.test(moi.national_id)
    ? ok('matricule national déchiffré', moi.national_id.slice(0, 4) + '…')
    : ko('matricule déchiffré', JSON.stringify(moi.national_id))
  'national_id_enc' in moi
    ? ko('champ chiffré', 'le bytea brut est encore dans la sortie')
    : ok('champ chiffré brut retiré')
  rows(doc, 'contracts') >= 1 ? ok('contrats présents') : ko('contrats', '0')
}

console.log('\n== Ce que l’export doit refuser ==')
{
  const autres = await get(manager, 'employees?select=id&limit=40')
  const moi = await rpc(employee, 'fn_export_self').then(([, d]) => d?.payload?.employee?.id)
  const collegue = autres.find((e) => e.id !== moi)
  const [good, body] = await rpc(employee, 'fn_export_employee', { p_employee: collegue.id })
  !good && /acc[eè]s/i.test(JSON.stringify(body))
    ? ok('un salarié ne peut pas exporter un collègue')
    : ko('cloisonnement salarié', good ? 'export accordé !' : JSON.stringify(body))
}
{
  const [good, body] = await rpc(employee, 'fn_export_organization')
  !good ? ok('un salarié ne peut pas exporter la fiduciaire')
        : ko('cloisonnement fiduciaire', 'export accordé !')
  void body
}
{
  const [good] = await rpc(employee, 'fn_import_referential',
    { p_document: { format: 'luxrh.export/1', kind: 'referential', payload: {} }, p_mode: 'replace' })
  !good ? ok('un salarié ne peut pas charger un référentiel')
        : ko('import réservé à l’admin', 'import accepté !')
}

console.log('\n== Réversibilité ==')
{
  const [bg] = await get(manager, 'companies?select=id,legal_name&limit=1')
  const [good, doc] = await rpc(manager, 'fn_export_company', { p_company: bg.id })
  good ? ok(`société exportée`, bg.legal_name) : ko('export société', JSON.stringify(doc))
  rows(doc, 'employees') >= 1 ? ok('salariés inclus', `${rows(doc, 'employees')}`) : ko('salariés', '0')
  rows(doc, 'departments') >= 1 ? ok('services inclus') : ko('services', '0')
}
{
  const [good, doc] = await rpc(manager, 'fn_export_organization')
  good ? ok('fiduciaire exportée', `${rows(doc, 'companies')} sociétés`)
       : ko('export fiduciaire', JSON.stringify(doc))
}

console.log('\n== Référentiel : aller-retour ==')
let referentiel
{
  const [good, doc] = await rpc(manager, 'fn_export_referential')
  good ? ok('référentiel exporté') : ko('export référentiel', JSON.stringify(doc))
  referentiel = doc

  rows(doc, 'legal_parameters') > 100
    ? ok('paramètres légaux', `${rows(doc, 'legal_parameters')} versions`)
    : ko('paramètres légaux', `${rows(doc, 'legal_parameters')}`)

  // Les CCT sectorielles ont organization_id nul : les filtrer sur la seule
  // organisation du demandeur les ferait disparaître de l'export.
  rows(doc, 'collective_agreements') >= 1
    ? ok('CCT partagées incluses', `${rows(doc, 'collective_agreements')}`)
    : ko('CCT partagées', 'aucune CCT dans l’export')
  rows(doc, 'cba_rules') >= 1 ? ok('blocs de règles CCT inclus') : ko('règles CCT', '0')

  // Clés naturelles, pas d'identifiants techniques : sinon l'import dupliquerait.
  const p = doc?.payload?.legal_parameters?.[0] ?? {}
  !('id' in p) && 'param_key' in p && 'valid_from' in p
    ? ok('clés naturelles, sans identifiant technique')
    : ko('clés naturelles', JSON.stringify(Object.keys(p).slice(0, 6)))
}
{
  // Recharger un référentiel déjà en place ne doit rien ajouter ni rien rejeter.
  const [good, rapport] = await rpc(manager, 'fn_import_referential',
    { p_document: referentiel, p_mode: 'skip_existing' })
  good ? ok('import accepté') : ko('import', JSON.stringify(rapport))
  rapport?.added === 0 ? ok('aucun doublon créé') : ko('doublons', `${rapport?.added} ajoutés`)
  ;(rapport?.rejected ?? []).length === 0
    ? ok('aucun rejet')
    : ko('rejets', JSON.stringify(rapport.rejected.slice(0, 2)))
  rapport?.skipped > 100 ? ok('lignes reconnues', `${rapport.skipped}`) : ko('reconnaissance', `${rapport?.skipped}`)
}
{
  const [good, body] = await rpc(manager, 'fn_import_referential',
    { p_document: { format: 'autre-outil/2', kind: 'referential', payload: {} }, p_mode: 'skip_existing' })
  !good && /format/i.test(JSON.stringify(body))
    ? ok('un format étranger est refusé, et nommé')
    : ko('contrôle du format', good ? 'accepté !' : JSON.stringify(body))
}
{
  const [good, body] = await rpc(manager, 'fn_import_referential',
    { p_document: { format: 'luxrh.export/1', kind: 'company', payload: {} }, p_mode: 'skip_existing' })
  !good ? ok('un export de société n’est pas pris pour un référentiel')
        : ko('contrôle du genre', 'accepté !')
  void body
}

console.log('\n== Registre des exports ==')
{
  const journal = await get(manager, 'export_log?select=subject_kind,row_count,byte_size&order=created_at.desc&limit=5')
  Array.isArray(journal) && journal.length > 0
    ? ok('demandes journalisées', `${journal.length} dernières`)
    : ko('registre', JSON.stringify(journal))
  journal[0]?.row_count > 0
    ? ok('volume compté', `${journal[0].row_count} objets`)
    : ko('volume', `${journal[0]?.row_count}`)
}

console.log(`\nPortabilité : ${pass} vérifications, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
