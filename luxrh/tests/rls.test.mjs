// Vérifie que le cloisonnement est bien imposé en base, pas dans l'interface.
import { URL_BASE as URL, KEY, account } from './config.mjs'
const ON = '2026-09-09'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }

const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

async function signIn(email, password) {
  const j = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  }).then((r) => r.json())
  if (!j.access_token) throw new Error(`signIn ${email}: ${JSON.stringify(j).slice(0, 200)}`)
  return j.access_token
}

const get = (t, q) => fetch(`${URL}/rest/v1/${q}`, { headers: h(t) }).then(async (r) => [r.ok, await r.json()])
const call = (t, fn, args) =>
  fetch(`${URL}/rest/v1/rpc/${fn}`, { method: 'POST', headers: h(t), body: JSON.stringify(args) })
    .then(async (r) => [r.ok, await r.json()])

const admin = await signIn(account('manager').email, account('manager').password)
const [, societes] = await get(admin, 'societes?select=id,raison_sociale')
const bg = societes.find((c) => c.raison_sociale.startsWith('Brasserie'))
const [, emps] = await get(admin, `salaries?select=id,nom&societe_id=eq.${bg.id}`)
const marta = emps.find((e) => e.nom === 'Ferreira')
const aicha = emps.find((e) => e.nom === 'Diallo')
const [, scheds] = await get(admin, `plannings?select=id,statut&societe_id=eq.${bg.id}`)

console.log('\n== Un autre espace de travail ==')
const other = await signIn(account('other').email, account('other').password)
for (const [label, q] of [
  ['sociétés', 'societes?select=id'],
  ['salariés', 'salaries?select=id'],
  ['contrats', 'contrats?select=id'],
  ['plannings', 'plannings?select=id'],
  ['creneaux', 'creneaux?select=id'],
  ['absences', 'absences?select=id'],
  ['journal d’audit', 'journal_ecritures?select=id'],
  ['documents', 'documents?select=id'],
]) {
  const [okRes, rows] = await get(other, q)
  if (!okRes) ko(`${label} — requête refusée`, JSON.stringify(rows).slice(0, 120))
  else if (rows.length === 0) ok(`ne voit aucun(e) ${label}`)
  else ko(`isolation ${label}`, `${rows.length} ligne(s) visibles !`)
}
for (const [fn, args, label] of [
  ['fn_compliance_scan', { p_company: bg.id, p_on: ON }, 'vigilance d’une société tierce'],
  ['fn_validate_schedule', { p_schedule: scheds[0].id }, 'planning d’un tiers'],
  ['fn_employee_sensitive', { p_employee: aicha.id }, 'matricule d’un tiers'],
  ['fn_headcount', { p_company: bg.id, p_on: ON }, 'effectif d’un tiers'],
  ['fn_leave_balance', { p_employee: aicha.id, p_on: ON }, 'solde de congés d’un tiers'],
]) {
  const [okRes] = await call(other, fn, args)
  okRes ? ko(`${label} — accès accordé !`) : ok(`${label} refusé`)
}
// Le référentiel légal, lui, est bien public aux utilisateurs connectés.
const [okParams, params] = await get(other, 'parametres_legaux?select=id&limit=5')
okParams && params.length > 0 ? ok('le référentiel légal reste lisible') : ko('référentiel légal', 'illisible')

console.log('\n== Espace salarié (Marta Ferreira) ==')
const emp = await signIn(account('employee').email, account('employee').password)
const [, myEmps] = await get(emp, 'salaries?select=id,nom')
myEmps.length === 1 && myEmps[0].id === marta.id
  ? ok('ne voit que sa propre fiche', myEmps[0].nom)
  : ko('fiches salariés visibles', JSON.stringify(myEmps.map((e) => e.nom)))

const [, myContracts] = await get(emp, 'contrats?select=id,salarie_id')
myContracts.every((c) => c.salarie_id === marta.id)
  ? ok('ne voit que ses propres contrats', `${myContracts.length}`)
  : ko('contrats visibles', 'contrats d’autrui exposés !')

const [, myAbs] = await get(emp, 'absences?select=id,salarie_id')
myAbs.every((a) => a.salarie_id === marta.id)
  ? ok('ne voit que ses propres absences', `${myAbs.length}`)
  : ko('absences visibles', 'absences d’autrui exposées !')

// Le planning de la semaine 42 est en brouillon : il ne doit rien voir.
const [, myShifts] = await get(emp, 'creneaux?select=id,salarie_id')
myShifts.length === 0
  ? ok('aucun shift visible tant que le planning est en brouillon')
  : ko('creneaux visibles', `${myShifts.length} shift(s) d’un planning non publié !`)

const [okSelf] = await call(emp, 'fn_leave_balance', { p_employee: marta.id, p_on: ON })
okSelf ? ok('peut consulter son propre solde de congés') : ko('solde propre', 'refusé')

const [okOther] = await call(emp, 'fn_leave_balance', { p_employee: aicha.id, p_on: ON })
okOther ? ko('solde d’un collègue', 'accès accordé !') : ok('ne peut pas lire le solde d’un collègue')

const [okScan] = await call(emp, 'fn_compliance_scan', { p_company: bg.id, p_on: ON })
okScan ? ko('centre de vigilance', 'accessible à un salarié !') : ok('centre de vigilance refusé au salarié')

// Un salarié ne peut pas valider sa propre demande de congé.
const [okWrite, wErr] = await fetch(`${URL}/rest/v1/absences?salarie_id=eq.${marta.id}`, {
  method: 'PATCH', headers: { ...h(emp), Prefer: 'return=representation' },
  body: JSON.stringify({ statut: 'valide' }),
}).then(async (r) => [r.ok, await r.json()])
!okWrite || (Array.isArray(wErr) && wErr.length === 0)
  ? ok('ne peut pas valider une absence lui-même')
  : ko('validation d’absence', 'un salarié a pu approuver !')

console.log(`\n${pass} succès, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
