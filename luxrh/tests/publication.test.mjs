// Un planning contenant une violation bloquante ne peut pas être publié.
// Une fois la violation corrigée, il le peut — et le salarié voit alors ses horaires.
import { URL_BASE as URL, KEY, account } from './config.mjs'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }
const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

async function signIn(email, password) {
  const j = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  }).then((r) => r.json())
  return j.access_token
}
const get = (t, q) => fetch(`${URL}/rest/v1/${q}`, { headers: h(t) }).then((r) => r.json())
const patch = (t, q, body) =>
  fetch(`${URL}/rest/v1/${q}`, { method: 'PATCH', headers: { ...h(t), Prefer: 'return=representation' }, body: JSON.stringify(body) })
    .then(async (r) => [r.ok, await r.json()])
const call = (t, fn, args) =>
  fetch(`${URL}/rest/v1/rpc/${fn}`, { method: 'POST', headers: h(t), body: JSON.stringify(args) })
    .then(async (r) => [r.ok, await r.json()])

const admin = await signIn(account('manager').email, account('manager').password)
const [bg] = await get(admin, 'companies?select=id&legal_name=like.Brasserie*')
const [sched] = await get(admin, `schedules?select=id,status,week_start&company_id=eq.${bg.id}`)
const [marta] = await get(admin, `employees?select=id&company_id=eq.${bg.id}&last_name=eq.Ferreira`)

console.log('\n== 1. Refus de publication ==')
let [, v] = await call(admin, 'fn_validate_schedule', { p_schedule: sched.id })
ok('violations détectées', `${v.blocking_count} bloquant(e), ${v.warning_count} avertissement(s)`)
const daily = v.violations.find((x) => x.code === 'daily_rest')
daily ? ok('violation attendue', daily.title) : ko('violation attendue', 'repos journalier non détecté')
daily?.legal_ref ? ok('base légale citée', daily.legal_ref) : ko('base légale', 'absente')

const [pubOk, pubErr] = await call(admin, 'fn_publish_schedule', { p_schedule: sched.id })
pubOk
  ? ko('publication', 'acceptée malgré un blocage !')
  : ok('publication refusée', String(pubErr.message).slice(0, 80))

console.log('\n== 2. Correction puis publication ==')
// La reprise du jeudi à 07:00 après une fin le mercredi à 23:30 ne laisse que 7 h 30 de repos.
const [shiftJeu] = await get(admin, `shifts?select=id,start_time&employee_id=eq.${marta.id}&shift_date=eq.2026-10-15`)
await patch(admin, `shifts?id=eq.${shiftJeu.id}`, { start_time: '11:00' })
;[, v] = await call(admin, 'fn_validate_schedule', { p_schedule: sched.id })
v.blocking_count === 0
  ? ok('plus aucune violation bloquante', `publiable=${v.can_publish}`)
  : ko('après correction', `${v.blocking_count} blocage(s) subsistent`)

const [pub2Ok, pub2] = await call(admin, 'fn_publish_schedule', { p_schedule: sched.id })
pub2Ok && pub2.published ? ok('planning publié') : ko('publication', JSON.stringify(pub2).slice(0, 140))

console.log('\n== 3. Le salarié voit ses horaires ==')
const emp = await signIn(account('employee').email, account('employee').password)
const myShifts = await get(emp, `shifts?select=id,shift_date,start_time,end_time&order=shift_date`)
myShifts.length > 0
  ? ok('shifts visibles une fois le planning publié', `${myShifts.length} services`)
  : ko('shifts du salarié', 'toujours invisibles')
const mySched = await get(emp, 'schedules?select=id,status')
mySched.length === 1 && mySched[0].status === 'published'
  ? ok('planning publié visible')
  : ko('planning visible', JSON.stringify(mySched))

console.log('\n== 4. Retour à l’état de démonstration ==')
await patch(admin, `shifts?id=eq.${shiftJeu.id}`, { start_time: shiftJeu.start_time })
await patch(admin, `schedules?id=eq.${sched.id}`, { status: 'draft', published_at: null, published_by: null })
const [, vBack] = await call(admin, 'fn_validate_schedule', { p_schedule: sched.id })
vBack.blocking_count === 1 && vBack.status === 'draft'
  ? ok('état initial rétabli', '1 blocage, brouillon')
  : ko('restauration', `${vBack.blocking_count} blocage(s), statut ${vBack.status}`)
const backShifts = await get(emp, 'shifts?select=id')
backShifts.length === 0
  ? ok('le salarié ne voit à nouveau plus rien')
  : ko('restauration RLS', `${backShifts.length} shift(s) encore visibles`)

console.log(`\n${pass} succès, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
