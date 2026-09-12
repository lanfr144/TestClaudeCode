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

const profile = await rest(token, "profils '*, organisations(*)'", 'profils?select=*,organisations(*)')
await rest(token, 'roles_compte', 'roles_compte?select=*')
const societes = await rest(
  token, "societes '*, conventions_de_la_societe(...)'",
  'societes?select=*,conventions_de_la_societe(debut_validite,fin_validite,conventions_collectives(nom,code,secteur,portee))&order=raison_sociale',
)
const bg = societes.find((c) => c.raison_sociale.startsWith('Brasserie'))

await rest(
  token, "societe '*, services, rate_periods, cba links'",
  `societes?select=*,services(*),periodes_taux_societe(*),conventions_de_la_societe(*,conventions_collectives(*,regles_convention(*)))&id=eq.${bg.id}`,
)
const salaries = await rest(
  token, "salaries '*, services(nom), contrats(...)'",
  `salaries?select=*,services(nom),contrats(id,genre,statut,intitule_poste,date_debut,date_fin,duree_essai,unite_essai,heures_hebdomadaires,brut_mensuel)&societe_id=eq.${bg.id}&order=nom`,
)
const aicha = salaries.find((e) => e.nom === 'Diallo')
const tomas = salaries.find((e) => e.nom === 'Rocha')

await rest(
  token, "salarie '*, tax_cards, contrats, documents'",
  `salaries?select=*,services(nom),fiches_retenue_impot(*),contrats(*),documents(*)&id=eq.${aicha.id}`,
)
const contrats = await rest(
  token, "contrats '*, salaries(prenom,nom)'",
  `contrats?select=*,salaries(prenom,nom)&societe_id=eq.${bg.id}&order=date_debut.desc`,
)
const cAicha = contrats.find((c) => c.salarie_id === aicha.id)
await rest(
  token, "contrat '*, salaries, societes, amendments, cba links'",
  `contrats?select=*,salaries(*),societes(*),avenants_contrat(*),conventions_du_contrat(*,conventions_collectives(nom,code,portee))&id=eq.${cAicha.id}`,
)
const plannings = await rest(token, 'plannings', `plannings?select=*&societe_id=eq.${bg.id}&order=debut_semaine.desc`)
const sched = plannings[0]
await rest(
  token, "creneaux '*, salaries(...)'",
  `creneaux?select=*,salaries(id,prenom,nom)&planning_id=eq.${sched.id}&order=date_creneau&order=heure_debut`,
)
await rest(token, 'modeles_creneau', `modeles_creneau?select=*&societe_id=eq.${bg.id}&order=heure_debut`)
const absTypes = await rest(
  token, "types_absence '*, droits_absence(*)'",
  'types_absence?select=*,droits_absence(*)&order=libelle',
)
await rest(
  token, "absences '*, salaries, types_absence(*, entitlements)'",
  `absences?select=*,salaries(id,prenom,nom),types_absence(*,droits_absence(*))&societe_id=eq.${bg.id}&order=date_debut.desc`,
)
await rest(token, 'parametres_legaux', 'parametres_legaux?select=*&order=famille&order=cle_parametre&order=debut_validite.desc')
await rest(token, "conventions_collectives '*, regles, grids'", 'conventions_collectives?select=*,regles_convention(*),grilles_salaires_convention(*)&order=nom')
await rest(token, 'jours_feries', 'jours_feries?select=*&annee=eq.2026&order=date_ferie')
await rest(token, "releves_temps '*, salaries(...)'", `releves_temps?select=*,salaries(prenom,nom)&societe_id=eq.${bg.id}&date_releve=gte.2026-09-01&date_releve=lte.2026-09-30`)
await rest(token, 'journal_ecritures', `journal_ecritures?select=*&societe_id=eq.${bg.id}&order=survenu_le.desc&limit=200`)
await rest(token, "self creneaux '*, plannings!inner(...)'", `creneaux?select=*,plannings!inner(statut,debut_semaine)&salarie_id=eq.${aicha.id}&date_creneau=gte.2026-10-12&date_creneau=lte.2026-10-18`)

await rest(token, 'types_document', 'types_document?select=*&order=libelle')
await rest(token, 'statuts_salarie', `statuts_salarie?select=*&societe_id=eq.${bg.id}`)
await rest(token, 'periodes_taux_societe', `periodes_taux_societe?select=*&societe_id=eq.${bg.id}`)
await rest(token, 'tranches_impot', 'tranches_impot?select=*&limit=5')
await rest(token, 'credits_impot', 'credits_impot?select=*&order=code')
await rest(token, 'types_avantage', 'types_avantage?select=*&order=libelle')
await rest(token, 'agences_interim', 'agences_interim?select=*')
await rest(token, 'elements_remuneration', `elements_remuneration?select=*&societe_id=eq.${bg.id}`)
await rest(token, 'droits_absence', 'droits_absence?select=*&limit=10')

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
  p_employee: aicha.id, p_type: absTypes.find((t) => t.code === 'conge_annuel').id,
  p_start: '2026-10-26', p_end: '2026-10-30',
})
const scan = await rpc(token, 'fn_compliance_scan', { p_company: bg.id, p_on: ON })
if (scan) ok('  → vigilance', `${scan.overdue.length} en retard, ${scan.due_soon.length} sous 30 j, ${scan.watch.length} à surveiller`)
const hco = await rpc(token, 'fn_headcount_obligations', { p_company: bg.id, p_on: ON })
if (hco) ok('  → effectif', `moyenne ${hco.effectif.average}, scrutin ${hco.vote_mode}`)
await rpc(token, 'fn_collective_dismissal_counters', { p_company: bg.id, p_on: ON })
const sim = await rpc(token, 'fn_simulate_collective_dismissal', {
  p_company: bg.id, p_count: 6, p_date: '2026-09-20', p_personal_ground: false,
})
if (sim) ok('  → simulation', `déclenche=${sim.triggers}, ${sim.timeline.length} étapes`)
const sens = await rpc(token, 'fn_employee_sensitive', { p_employee: aicha.id })
if (sens) ok('  → données sensibles', `matricule déchiffré : ${sens[0]?.matricule_national ? 'oui' : 'non'}`)

console.log('\n== Extensions du moteur ==')
const rates = await rpc(token, 'fn_company_rates', { p_company: bg.id, p_on: ON })
if (rates) ok('  → taux société', `Mutualité ${rates.classe_mutualite} · patronal ${rates.employer_total_pct} %`)
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
  `${gaps.filter((g) => !g.couvre_depuis).length} paramètre(s) sans historique 2019`)
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
