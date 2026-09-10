// Test de fumée : rejoue chaque requête et chaque RPC du front contre l'API réelle.
import { URL_BASE as URL, KEY, account } from './config.mjs'
const ON = '2026-09-09'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }

async function signIn(email, password) {
  const r = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
  const j = await r.json()
  if (!j.access_token) throw new Error('signIn: ' + JSON.stringify(j).slice(0, 200))
  return j.access_token
}

const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

async function rest(token, name, pathAndQuery) {
  const r = await fetch(`${URL}/rest/v1/${pathAndQuery}`, { headers: h(token) })
  const body = await r.json()
  if (!r.ok) return ko(name, JSON.stringify(body).slice(0, 220))
  ok(name, Array.isArray(body) ? `${body.length} ligne(s)` : 'objet')
  return body
}

async function rpc(token, fn, args, name = fn, expectError = false) {
  const r = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: h(token), body: JSON.stringify(args),
  })
  const body = await r.json()
  if (expectError) {
    if (r.ok) return ko(name, 'aurait dû être refusé, a réussi')
    return ok(name, 'refusé comme attendu')
  }
  if (!r.ok) return ko(name, JSON.stringify(body).slice(0, 220))
  ok(name)
  return body
}

const manager = account('manager')
const token = await signIn(manager.email, manager.password)
console.log('\n== Requêtes du front (gestionnaire) ==')

const profile = await rest(token, "profiles '*, organizations(*)'", 'profiles?select=*,organizations(*)')
await rest(token, 'user_roles', 'user_roles?select=*')
const companies = await rest(
  token, "companies '*, company_collective_agreements(...)'",
  'companies?select=*,company_collective_agreements(valid_from,valid_to,collective_agreements(name,code,sector,scope))&order=legal_name',
)
const bg = companies.find((c) => c.legal_name.startsWith('Brasserie'))

await rest(
  token, "company '*, departments, rate_periods, cba links'",
  `companies?select=*,departments(*),company_rate_periods(*),company_collective_agreements(*,collective_agreements(*,cba_rules(*)))&id=eq.${bg.id}`,
)
const employees = await rest(
  token, "employees '*, departments(name), contracts(...)'",
  `employees?select=*,departments(name),contracts(id,kind,status,job_title,start_date,end_date,probation_length,probation_unit,weekly_hours,monthly_gross)&company_id=eq.${bg.id}&order=last_name`,
)
const aicha = employees.find((e) => e.last_name === 'Diallo')
const tomas = employees.find((e) => e.last_name === 'Rocha')

await rest(
  token, "employee '*, tax_cards, contracts, documents'",
  `employees?select=*,departments(name),employee_tax_cards(*),contracts(*),documents(*)&id=eq.${aicha.id}`,
)
const contracts = await rest(
  token, "contracts '*, employees(first_name,last_name)'",
  `contracts?select=*,employees(first_name,last_name)&company_id=eq.${bg.id}&order=start_date.desc`,
)
const cAicha = contracts.find((c) => c.employee_id === aicha.id)
await rest(
  token, "contract '*, employees, companies, amendments, cba links'",
  `contracts?select=*,employees(*),companies(*),contract_amendments(*),contract_collective_agreements(*,collective_agreements(name,code,scope))&id=eq.${cAicha.id}`,
)
const schedules = await rest(token, 'schedules', `schedules?select=*&company_id=eq.${bg.id}&order=week_start.desc`)
const sched = schedules[0]
await rest(
  token, "shifts '*, employees(...)'",
  `shifts?select=*,employees(id,first_name,last_name)&schedule_id=eq.${sched.id}&order=shift_date&order=start_time`,
)
await rest(token, 'shift_templates', `shift_templates?select=*&company_id=eq.${bg.id}&order=start_time`)
const absTypes = await rest(
  token, "absence_types '*, absence_entitlements(*)'",
  'absence_types?select=*,absence_entitlements(*)&order=label',
)
await rest(
  token, "absences '*, employees, absence_types(*, entitlements)'",
  `absences?select=*,employees(id,first_name,last_name),absence_types(*,absence_entitlements(*))&company_id=eq.${bg.id}&order=start_date.desc`,
)
await rest(token, 'legal_parameters', 'legal_parameters?select=*&order=family&order=param_key&order=valid_from.desc')
await rest(token, "collective_agreements '*, rules, grids'", 'collective_agreements?select=*,cba_rules(*),cba_salary_grids(*)&order=name')
await rest(token, 'public_holidays', 'public_holidays?select=*&year=eq.2026&order=holiday_date')
await rest(token, "time_entries '*, employees(...)'", `time_entries?select=*,employees(first_name,last_name)&company_id=eq.${bg.id}&entry_date=gte.2026-09-01&entry_date=lte.2026-09-30`)
await rest(token, 'audit_log', `audit_log?select=*&company_id=eq.${bg.id}&order=occurred_at.desc&limit=200`)
await rest(token, "self shifts '*, schedules!inner(...)'", `shifts?select=*,schedules!inner(status,week_start)&employee_id=eq.${aicha.id}&shift_date=gte.2026-10-12&shift_date=lte.2026-10-18`)

await rest(token, 'document_types', 'document_types?select=*&order=label')
await rest(token, 'employee_statuses', `employee_statuses?select=*&company_id=eq.${bg.id}`)
await rest(token, 'company_rate_periods', `company_rate_periods?select=*&company_id=eq.${bg.id}`)
await rest(token, 'tax_brackets', 'tax_brackets?select=*&limit=5')
await rest(token, 'tax_credits', 'tax_credits?select=*&order=code')
await rest(token, 'benefit_types', 'benefit_types?select=*&order=label')
await rest(token, 'interim_agencies', 'interim_agencies?select=*')
await rest(token, 'contract_pay_components', `contract_pay_components?select=*&company_id=eq.${bg.id}`)
await rest(token, 'absence_entitlements', 'absence_entitlements?select=*&limit=10')

console.log('\n== Moteur de règles ==')
const comp = await rpc(token, 'fn_contract_compliance', { p_contract: cAicha.id, p_on: ON })
if (comp) ok('  → conformité', `${comp.blocking_count} blocage(s), validable=${comp.can_validate}`)
const val = await rpc(token, 'fn_validate_schedule', { p_schedule: sched.id })
if (val) ok('  → planning', `${val.blocking_count} bloquant, publiable=${val.can_publish}`)
await rpc(token, 'fn_reference_period_status', { p_company: bg.id, p_on: ON })
const lb = await rpc(token, 'fn_leave_balance', { p_employee: aicha.id, p_on: ON })
if (lb) ok('  → solde congés', `${lb.balance} j (${lb.entitlement_source})`)
const sc = await rpc(token, 'fn_sick_counters', { p_employee: tomas.id, p_on: ON })
if (sc) ok('  → maladie', `${sc.days_in_window}/${sc.limit_days} j, protection ${sc.protection_end}`)
await rpc(token, 'fn_leave_request_impact', {
  p_employee: aicha.id, p_type: absTypes.find((t) => t.code === 'annual_leave').id,
  p_start: '2026-10-26', p_end: '2026-10-30',
})
const scan = await rpc(token, 'fn_compliance_scan', { p_company: bg.id, p_on: ON })
if (scan) ok('  → vigilance', `${scan.overdue.length} en retard, ${scan.due_soon.length} sous 30 j, ${scan.watch.length} à surveiller`)
const hco = await rpc(token, 'fn_headcount_obligations', { p_company: bg.id, p_on: ON })
if (hco) ok('  → effectif', `moyenne ${hco.headcount.average}, scrutin ${hco.vote_mode}`)
await rpc(token, 'fn_collective_dismissal_counters', { p_company: bg.id, p_on: ON })
const sim = await rpc(token, 'fn_simulate_collective_dismissal', {
  p_company: bg.id, p_count: 6, p_date: '2026-09-20', p_personal_ground: false,
})
if (sim) ok('  → simulation', `déclenche=${sim.triggers}, ${sim.timeline.length} étapes`)
const sens = await rpc(token, 'fn_employee_sensitive', { p_employee: aicha.id })
if (sens) ok('  → données sensibles', `matricule déchiffré : ${sens[0]?.national_id ? 'oui' : 'non'}`)

console.log('\n== Extensions du moteur ==')
const rates = await rpc(token, 'fn_company_rates', { p_company: bg.id, p_on: ON })
if (rates) ok('  → taux société', `Mutualité ${rates.mutuality_class} · patronal ${rates.employer_total_pct} %`)
const cbas = await rpc(token, 'fn_applicable_cbas', { p_contract: cAicha.id, p_on: ON })
if (cbas) ok('  → conventions applicables', `${cbas.length} convention(s)`)
const qual = await rpc(token, 'fn_is_qualified', { p_employee: aicha.id, p_on: ON })
if (qual) ok('  → qualification', qual.source)
const prot = await rpc(token, 'fn_dismissal_protections', { p_employee: tomas.id, p_on: ON })
if (prot) ok('  → protections', `${prot.protections.length} protection(s) active(s)`)
const otel = await rpc(token, 'fn_overtime_eligibility', { p_employee: aicha.id, p_on: ON })
if (otel) ok('  → heures supplémentaires', otel.allowed ? 'autorisées' : 'interdites')
const deleg = await rpc(token, 'fn_delegation_eligibility', { p_employee: aicha.id, p_on: ON })
if (deleg) ok('  → éligibilité délégation', deleg.eligible ? 'éligible' : deleg.reasons[0]?.detail)
const eoc = await rpc(token, 'fn_end_of_contract_documents', { p_contract: cAicha.id })
if (eoc) ok('  → documents de fin de contrat', `${eoc.outstanding} en attente`)
const nid = await rpc(token, 'fn_check_national_id', { p_id: '123' })
if (nid) ok('  → contrôle matricule', nid.errors[0]?.message ?? 'valide')
const gaps = await rpc(token, 'fn_referential_gaps', { p_since: '2019-12-31' })
if (gaps) ok('  → couverture du référentiel',
  `${gaps.filter((g) => !g.covers_since).length} paramètre(s) sans historique 2019`)
const holes = await rpc(token, 'fn_referential_holes', {})
if (holes) ok('  → trous du référentiel', `${holes.length}`)
const inc = await rpc(token, 'fn_referential_inconsistencies', { p_on: ON })
if (inc) ok('  → cohérence des dérivations', `${inc.length} écart(s) hors tolérance`)
const hol = await rpc(token, 'fn_holiday_summary', { p_year: 2024 })
if (hol) ok('  → jours fériés 2024',
  `${hol.declared} déclarés sur ${hol.distinct_dates} dates, ${hol.recoverable} récupérable(s)`)
const abs = await rpc(token, 'fn_company_absenteeism', { p_company: bg.id, p_year: 2026 })
if (abs) ok('  → absentéisme', `${abs.absenteeism_rate_pct} %`)
const tax = await rpc(token, 'fn_income_tax', { p_taxable: 3400, p_class: '1', p_on: ON })
if (tax) ok('  → retenue d\'impôt', tax.found ? `${tax.tax} €` : 'barème non chargé, calcul suspendu')
const salref = await rpc(token, 'fn_salary_reference', { p_contract: cAicha.id, p_on: ON })
if (salref) ok('  → référence salariale', `${salref.reference_monthly} €`)

// L'isolation multi-societes est couverte par tests/rls.test.mjs, avec des comptes
// dedies : inutile d'inscrire un nouvel utilisateur a chaque execution.

console.log('\n== Fonctions internes non exposées ==')
await rpc(token, 'fn_decrypt_field', { p_cipher: '\\x00' }, 'fn_decrypt_field inaccessible', true)
await rpc(token, 'fn_encrypt_field', { p_plain: 'x' }, 'fn_encrypt_field inaccessible', true)

const anonRes = await fetch(`${URL}/rest/v1/rpc/fn_compliance_scan`, {
  method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
  body: JSON.stringify({ p_company: bg.id, p_on: ON }),
})
anonRes.ok ? ko('anon bloqué sur le moteur', 'a réussi !') : ok('anon bloqué sur le moteur', `HTTP ${anonRes.status}`)

console.log(`\n${pass} succès, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
