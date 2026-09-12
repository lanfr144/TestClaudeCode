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

const [bg] = await get('societes?select=id&raison_sociale=like.Brasserie*')
const salaries = await get(`salaries?select=id,nom,date_naissance&societe_id=eq.${bg.id}`)
const marta = salaries.find((e) => e.nom === 'Ferreira')
const lena = salaries.find((e) => e.nom === 'Weber')
const [contract] = await get(`contrats?select=id&salarie_id=eq.${marta.id}`)

console.log('\n== Travailleur handicapé ==')
await del(`handicaps_salarie?salarie_id=eq.${marta.id}`)
{
  const [inserted] = await post('handicaps_salarie', {
    societe_id: bg.id, salarie_id: marta.id, taux_pct: 40,
    reconnu_le: '2024-01-15', autorite: 'Commission médicale', debut_validite: '2024-01-15',
  })
  inserted ? ok('statut enregistré') : ko('statut', 'insertion refusée')
  const [okRpc, extra] = await rpc('fn_disability_extra_leave', { p_employee: marta.id, p_on: ON })
  okRpc && extra.applies && extra.extra_days === 6
    ? ok('congé supplémentaire', `${extra.extra_days} j pour un taux de ${extra.taux_pct} %`)
    : ko('congé supplémentaire', JSON.stringify(extra))
}

console.log('\n== Enfants et confidentialité ==')
await del(`enfants_salarie?salarie_id=eq.${marta.id}`)
{
  await post('enfants_salarie', {
    societe_id: bg.id, salarie_id: marta.id, prenom: 'Léa', nom: 'Ferreira',
    sexe: 'feminin', date_naissance: '2018-05-04',
  })
  // Refus des attentions : le nom et le sexe ne doivent pas être conservés.
  const [okIns, refused] = await post('enfants_salarie', {
    societe_id: bg.id, salarie_id: marta.id, prenom: 'Hugo', nom: 'Ferreira',
    sexe: 'masculin', date_naissance: '2012-02-20', refus_partage: true,
  })
  if (!okIns) ko('enfant confidentiel', JSON.stringify(refused).slice(0, 140))
  else {
    const row = refused[0]
    row.prenom === null && row.nom === null && row.sexe === null
      ? ok('le refus des attentions efface le nom et le sexe', 'seule la date reste')
      : ko('minimisation', JSON.stringify(row))
  }
  const [, children] = await rpc('fn_employee_children', { p_employee: marta.id, p_on: ON })
  children.count === 2 && children.gift_eligible_count === 1
    ? ok('liste des attentions', `${children.gift_eligible_count} enfant sur ${children.count}`)
    : ko('liste des attentions', JSON.stringify(children).slice(0, 160))
}

console.log('\n== Heures supplémentaires : accord préalable ==')
await del(`demandes_heures_sup?salarie_id=eq.${marta.id}`)
{
  const [, created] = await post('demandes_heures_sup', {
    societe_id: bg.id, salarie_id: marta.id,
    debut_periode: '2026-10-12', fin_periode: '2026-10-18',
    heures: 6, motif: 'Banquet exceptionnel',
  })
  const request = created[0]
  request.statut === 'demande' ? ok('demande créée') : ko('demande', request.statut)

  await rpc('fn_overtime_approve', { p_request: request.id, p_as_hr: true })
  const [, afterHr] = await get(`demandes_heures_sup?select=statut&id=eq.${request.id}`)
    .then((rows) => [true, rows[0]])
  afterHr.statut === 'valide_rh'
    ? ok('validation RH seule ne suffit pas', afterHr.statut)
    : ko('validation RH', afterHr.statut)

  await rpc('fn_overtime_approve', { p_request: request.id, p_as_hr: false })
  const [after] = await get(`demandes_heures_sup?select=statut&id=eq.${request.id}`)
  after.statut === 'valide'
    ? ok('accord mutuel acquis', after.statut)
    : ko('accord mutuel', after.statut)

  const [, hours] = await rpc('fn_overtime_approved_hours', {
    p_employee: marta.id, p_from: '2026-10-12', p_to: '2026-10-18',
  })
  Number(hours) === 6 ? ok('heures couvertes par un accord', `${hours} h`) : ko('heures couvertes', hours)
}

console.log('\n== Chèques-repas ==')
await del(`attributions_titres_repas?salarie_id=eq.${marta.id}`)
{
  const [, granted] = await post('attributions_titres_repas', {
    societe_id: bg.id, salarie_id: marta.id,
    debut_periode: '2026-09-01', fin_periode: '2026-09-30',
    nombre_titres: 20, valeur_faciale: 18, part_salariale: 1.5,
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

  const [pregnant] = await get(`contrats?select=id&salarie_id=eq.${lena.id}`)
  const [, blocked] = await rpc('fn_can_terminate', {
    p_contract: pregnant.id, p_reason: 'licenciement_avec_preavis', p_on: ON,
  })
  !blocked.allowed && blocked.blockers.length > 0
    ? ok('grossesse : notification bloquée', blocked.blockers[0].detail.slice(0, 60) + '…')
    : ko('protection grossesse', JSON.stringify(blocked))
}

console.log('\n== Primes participatives et plafonds ==')
await del(`primes?salarie_id=eq.${marta.id}`)
await del(`donnees_financieres_societe?societe_id=eq.${bg.id}`)
{
  const [, noCap] = await rpc('fn_premium_caps', { p_company: bg.id, p_year: 2024 })
  !noCap.found
    ? ok('avant 2025 : plafonds non chargés, contrôle suspendu')
    : ko('plafonds 2024', 'des plafonds inventés ont été appliqués')

  await post('donnees_financieres_societe', { societe_id: bg.id, exercice: 2025, resultat: 200000 })
  await post('primes', {
    societe_id: bg.id, salarie_id: marta.id, contrat_id: contract.id,
    genre: 'participative', libelle: 'Prime participative 2026', montant: 20000,
    attribue_le: '2026-06-30', exercice: 2026,
  })
  const [, caps] = await rpc('fn_premium_caps', { p_company: bg.id, p_year: 2026 })
  caps.envelope === 15000
    ? ok('enveloppe = 7,5 % du bénéfice N-1', `${caps.envelope} €`)
    : ko('enveloppe', JSON.stringify(caps.envelope))
  caps.envelope_exceeded
    ? ok('dépassement de l’enveloppe détecté', `${caps.envelope_used} € distribués`)
    : ko('dépassement enveloppe', 'non détecté')
  const mine = caps.salaries[0]
  !mine.within_cap
    ? ok('plafond individuel dépassé', `excédent de ${mine.excess} €`)
    : ko('plafond individuel', JSON.stringify(mine))
}

console.log('\n== Nettoyage ==')
await del(`primes?salarie_id=eq.${marta.id}`)
await del(`donnees_financieres_societe?societe_id=eq.${bg.id}`)
await del(`attributions_titres_repas?salarie_id=eq.${marta.id}`)
await del(`demandes_heures_sup?salarie_id=eq.${marta.id}`)
await del(`enfants_salarie?salarie_id=eq.${marta.id}`)
await del(`handicaps_salarie?salarie_id=eq.${marta.id}`)
ok('jeu de démonstration rétabli')

console.log(`\n${pass} succès, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
