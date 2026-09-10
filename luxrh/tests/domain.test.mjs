// Ajouts métier : handicap, enfants, heures supplémentaires, chèques-repas,
// protections de fin de contrat et plafonds de primes.
import { URL_BASE as URL, KEY, account } from './config.mjs'

const ON = '2026-09-10'
let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }
const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

const token = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
  method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: account('manager').email, password: account('manager').password }),
}).then((r) => r.json()).then((j) => j.access_token)

const get = (q) => fetch(`${URL}/rest/v1/${q}`, { headers: h(token) }).then((r) => r.json())
const post = (path, body) =>
  fetch(`${URL}/rest/v1/${path}`, {
    method: 'POST', headers: { ...h(token), Prefer: 'return=representation' },
    body: JSON.stringify(body),
  }).then(async (r) => [r.ok, await r.json()])
const del = (q) => fetch(`${URL}/rest/v1/${q}`, { method: 'DELETE', headers: h(token) })
const rpc = async (fn, args = {}) => {
  const r = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: h(token), body: JSON.stringify(args),
  })
  const body = await r.json()
  return [r.ok, body]
}

const [bg] = await get('companies?select=id&legal_name=like.Brasserie*')
const employees = await get(`employees?select=id,last_name,birth_date&company_id=eq.${bg.id}`)
const marta = employees.find((e) => e.last_name === 'Ferreira')
const lena = employees.find((e) => e.last_name === 'Weber')
const [contract] = await get(`contracts?select=id&employee_id=eq.${marta.id}`)

console.log('\n== Travailleur handicapé ==')
await del(`employee_disabilities?employee_id=eq.${marta.id}`)
{
  const [inserted] = await post('employee_disabilities', {
    company_id: bg.id, employee_id: marta.id, rate_pct: 40,
    recognized_on: '2024-01-15', authority: 'Commission médicale', valid_from: '2024-01-15',
  })
  inserted ? ok('statut enregistré') : ko('statut', 'insertion refusée')
  const [okRpc, extra] = await rpc('fn_disability_extra_leave', { p_employee: marta.id, p_on: ON })
  okRpc && extra.applies && extra.extra_days === 6
    ? ok('congé supplémentaire', `${extra.extra_days} j pour un taux de ${extra.rate_pct} %`)
    : ko('congé supplémentaire', JSON.stringify(extra))
}

console.log('\n== Enfants et confidentialité ==')
await del(`employee_children?employee_id=eq.${marta.id}`)
{
  await post('employee_children', {
    company_id: bg.id, employee_id: marta.id, first_name: 'Léa', last_name: 'Ferreira',
    sex: 'female', birth_date: '2018-05-04',
  })
  // Refus des attentions : le nom et le sexe ne doivent pas être conservés.
  const [okIns, refused] = await post('employee_children', {
    company_id: bg.id, employee_id: marta.id, first_name: 'Hugo', last_name: 'Ferreira',
    sex: 'male', birth_date: '2012-02-20', privacy_opt_out: true,
  })
  if (!okIns) ko('enfant confidentiel', JSON.stringify(refused).slice(0, 140))
  else {
    const row = refused[0]
    row.first_name === null && row.last_name === null && row.sex === null
      ? ok('le refus des attentions efface le nom et le sexe', 'seule la date reste')
      : ko('minimisation', JSON.stringify(row))
  }
  const [, children] = await rpc('fn_employee_children', { p_employee: marta.id, p_on: ON })
  children.count === 2 && children.gift_eligible_count === 1
    ? ok('liste des attentions', `${children.gift_eligible_count} enfant sur ${children.count}`)
    : ko('liste des attentions', JSON.stringify(children).slice(0, 160))
}

console.log('\n== Heures supplémentaires : accord préalable ==')
await del(`overtime_requests?employee_id=eq.${marta.id}`)
{
  const [, created] = await post('overtime_requests', {
    company_id: bg.id, employee_id: marta.id,
    period_start: '2026-10-12', period_end: '2026-10-18',
    hours: 6, reason: 'Banquet exceptionnel',
  })
  const request = created[0]
  request.status === 'requested' ? ok('demande créée') : ko('demande', request.status)

  await rpc('fn_overtime_approve', { p_request: request.id, p_as_hr: true })
  const [, afterHr] = await get(`overtime_requests?select=status&id=eq.${request.id}`)
    .then((rows) => [true, rows[0]])
  afterHr.status === 'hr_approved'
    ? ok('validation RH seule ne suffit pas', afterHr.status)
    : ko('validation RH', afterHr.status)

  await rpc('fn_overtime_approve', { p_request: request.id, p_as_hr: false })
  const [after] = await get(`overtime_requests?select=status&id=eq.${request.id}`)
  after.status === 'approved'
    ? ok('accord mutuel acquis', after.status)
    : ko('accord mutuel', after.status)

  const [, hours] = await rpc('fn_overtime_approved_hours', {
    p_employee: marta.id, p_from: '2026-10-12', p_to: '2026-10-18',
  })
  Number(hours) === 6 ? ok('heures couvertes par un accord', `${hours} h`) : ko('heures couvertes', hours)
}

console.log('\n== Chèques-repas ==')
await del(`meal_voucher_grants?employee_id=eq.${marta.id}`)
{
  const [, granted] = await post('meal_voucher_grants', {
    company_id: bg.id, employee_id: marta.id,
    period_start: '2026-09-01', period_end: '2026-09-30',
    voucher_count: 20, face_value: 18, employee_share: 1.5,
  })
  const [, check] = await rpc('fn_meal_voucher_check', { p_grant: granted[0].id })
  check.warning_count === 2
    ? ok('dépassements signalés', 'valeur faciale et participation hors limites')
    : ko('contrôle chèques-repas', JSON.stringify(check.checks))
}

console.log('\n== Protections de fin de contrat ==')
{
  const [, allowed] = await rpc('fn_can_terminate', {
    p_contract: contract.id, p_reason: 'licenciement_avec_preavis', p_on: ON,
  })
  allowed.allowed ? ok('aucune protection sur Marta Ferreira') : ko('fin de contrat', JSON.stringify(allowed.blockers))

  const [pregnant] = await get(`contracts?select=id&employee_id=eq.${lena.id}`)
  const [, blocked] = await rpc('fn_can_terminate', {
    p_contract: pregnant.id, p_reason: 'licenciement_avec_preavis', p_on: ON,
  })
  !blocked.allowed && blocked.blockers.length > 0
    ? ok('grossesse : notification bloquée', blocked.blockers[0].detail.slice(0, 60) + '…')
    : ko('protection grossesse', JSON.stringify(blocked))
}

console.log('\n== Primes participatives et plafonds ==')
await del(`premiums?employee_id=eq.${marta.id}`)
await del(`company_financials?company_id=eq.${bg.id}`)
{
  const [, noCap] = await rpc('fn_premium_caps', { p_company: bg.id, p_year: 2024 })
  !noCap.found
    ? ok('avant 2025 : plafonds non chargés, contrôle suspendu')
    : ko('plafonds 2024', 'des plafonds inventés ont été appliqués')

  await post('company_financials', { company_id: bg.id, fiscal_year: 2025, profit: 200000 })
  await post('premiums', {
    company_id: bg.id, employee_id: marta.id, contract_id: contract.id,
    kind: 'participative', label: 'Prime participative 2026', amount: 20000,
    granted_on: '2026-06-30', fiscal_year: 2026,
  })
  const [, caps] = await rpc('fn_premium_caps', { p_company: bg.id, p_year: 2026 })
  caps.envelope === 15000
    ? ok('enveloppe = 7,5 % du bénéfice N-1', `${caps.envelope} €`)
    : ko('enveloppe', JSON.stringify(caps.envelope))
  caps.envelope_exceeded
    ? ok('dépassement de l’enveloppe détecté', `${caps.envelope_used} € distribués`)
    : ko('dépassement enveloppe', 'non détecté')
  const mine = caps.employees[0]
  !mine.within_cap
    ? ok('plafond individuel dépassé', `excédent de ${mine.excess} €`)
    : ko('plafond individuel', JSON.stringify(mine))
}

console.log('\n== Nettoyage ==')
await del(`premiums?employee_id=eq.${marta.id}`)
await del(`company_financials?company_id=eq.${bg.id}`)
await del(`meal_voucher_grants?employee_id=eq.${marta.id}`)
await del(`overtime_requests?employee_id=eq.${marta.id}`)
await del(`employee_children?employee_id=eq.${marta.id}`)
await del(`employee_disabilities?employee_id=eq.${marta.id}`)
ok('jeu de démonstration rétabli')

console.log(`\n${pass} succès, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
