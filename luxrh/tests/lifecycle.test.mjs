// Cycle de vie du contrat, lecture auditée et validation d'adresse.
//
// Couvre ce que les migrations 46 à 57 ont apporté et que les quatre suites
// existantes ne touchaient pas. Le jeu de démonstration est rétabli à la fin :
// l'avenant coupe un contrat en deux, ce qui n'est pas rejouable en l'état.
import { URL_BASE as URL, KEY, account } from './config.mjs'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${String(e).slice(0, 220)}`) }

async function signIn({ email, password }) {
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

async function rpc(token, fn, args) {
  const r = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: h(token), body: JSON.stringify(args),
  })
  return { ok: r.ok, status: r.status, body: await r.json() }
}

async function rest(token, pathAndQuery, init = {}) {
  const r = await fetch(`${URL}/rest/v1/${pathAndQuery}`, { headers: h(token), ...init })
  return { ok: r.ok, status: r.status, body: await r.json().catch(() => null) }
}

const token = await signIn(account('manager'))
const employeeToken = await signIn(account('employee'))

// ---------------------------------------------------------------------------
console.log('\n== Validation des adresses ==')

for (const [libelle, pays, cp, attendu] of [
  ['Luxembourg-ville', 'LU', 'L-1424', 'ok'],
  ['Arlon, province de Luxembourg', 'BE', 'B-6700', 'ok'],
  ['Metz, Moselle', 'FR', 'F-57000', 'ok'],
  ['Bruxelles, hors zone', 'BE', 'B-1000', 'hors_perimetre'],
  ['Paris, hors zone', 'FR', 'F-75001', 'hors_perimetre'],
  ['Trèves — bornes allemandes non chargées', 'DE', 'D-54294', 'indeterminee'],
  ['Amsterdam — pays non couvert', 'NL', '1011AB', 'indeterminee'],
]) {
  const r = await rpc(token, 'fn_validate_address', { p_country: pays, p_postal: cp })
  if (!r.ok) ko(libelle, JSON.stringify(r.body))
  else if (r.body?.statut !== attendu) ko(libelle, `attendu ${attendu}, obtenu ${r.body?.statut}`)
  else ok(libelle, r.body.statut)
}

{
  // Le préfixe pays de la convention luxembourgeoise doit être toléré.
  const avec = await rpc(token, 'fn_validate_address', { p_country: 'LU', p_postal: 'L-1424' })
  const sans = await rpc(token, 'fn_validate_address', { p_country: 'LU', p_postal: '1424' })
  avec.body?.statut === sans.body?.statut
    ? ok('« L-1424 » et « 1424 » donnent le même verdict')
    : ko('préfixe pays toléré', `${avec.body?.statut} vs ${sans.body?.statut}`)
}

// ---------------------------------------------------------------------------
console.log('\n== Lecture auditée : périmètre et projection ==')

const societes = await rest(token, 'societes?select=id,raison_sociale&limit=1')
const company = societes.body?.[0]
if (!company) ko('société de démonstration', 'aucune société lisible')

{
  const r = await rpc(token, 'fn_employee_rows', { p_fields: ['nom'] })
  r.ok ? ko('appel sans périmètre refusé', 'a réussi') : ok('appel sans périmètre refusé', `HTTP ${r.status}`)
}
{
  const r = await rpc(token, 'fn_employee_rows', {
    p_company: company?.id, p_fields: ['nom', 'champ_invente'],
  })
  r.ok ? ko('champ inconnu refusé', 'a réussi') : ok('champ inconnu refusé', `HTTP ${r.status}`)
}
{
  const r = await rpc(token, 'fn_employee_rows', {
    p_company: company?.id, p_fields: ['nom', 'intitule_poste'], p_limit: 5,
  })
  if (!r.ok) ko('lecture pipelinée', JSON.stringify(r.body))
  else {
    const lignes = r.body ?? []
    ok('lecture pipelinée', `${lignes.length} ligne(s)`)
    const premiere = lignes[0] ?? {}
    premiere.nom != null
      ? ok('colonne demandée renseignée')
      : ko('colonne demandée renseignée', 'nom nul')
    premiere.courriel === null && premiere.matricule_national === null && premiere.iban === null
      ? ok('colonnes non demandées à nul — minimisation en colonnes')
      : ko('colonnes non demandées à nul', JSON.stringify(premiere).slice(0, 140))
  }
}
{
  // Un salarié ne lit pas le dossier d'un collègue par cette porte non plus.
  const r = await rpc(employeeToken, 'fn_employee_rows', {
    p_company: company?.id, p_fields: ['nom'], p_limit: 50,
  })
  const lignes = Array.isArray(r.body) ? r.body : []
  lignes.length <= 1
    ? ok('un salarié ne voit que son propre dossier', `${lignes.length} ligne(s)`)
    : ko('un salarié ne voit que son propre dossier', `${lignes.length} lignes rendues`)
}

// ---------------------------------------------------------------------------
console.log('\n== Registre des accès ==')

const employes = await rest(token, `salaries?select=id,nom&societe_id=eq.${company?.id}&limit=1`)
const employe = employes.body?.[0]

{
  const r = await rpc(token, 'fn_employee_sensitive', { p_employee: employe?.id })
  r.ok ? ok('déchiffrement autorisé au gestionnaire') : ko('déchiffrement', JSON.stringify(r.body))
}
{
  const r = await rpc(token, 'fn_person_access_report', { p_employee: employe?.id })
  if (!r.ok) ko('registre des accès', JSON.stringify(r.body))
  else {
    const lignes = r.body ?? []
    ok('registre des accès', `${lignes.length} événement(s)`)
    lignes.some((l) => l.nature === 'DECHIFFREMENT')
      ? ok('le déchiffrement qui précède y figure')
      : ko('le déchiffrement qui précède y figure', 'aucune ligne DECHIFFREMENT')
    const colonnes = Object.keys(lignes[0] ?? {})
    ;['quand', 'qui', 'quoi', 'd_ou'].every((c) => colonnes.includes(c))
      ? ok('qui / quoi / quand / d’où sont tous rendus')
      : ko('colonnes du registre', colonnes.join(', '))
  }
}
{
  const r = await rpc(employeeToken, 'fn_person_access_report', { p_employee: employe?.id })
  r.ok ? ko('un salarié ne lit pas le registre d’un collègue', 'a réussi')
       : ok('un salarié ne lit pas le registre d’un collègue', `HTTP ${r.status}`)
}

// ---------------------------------------------------------------------------
console.log('\n== Un seul contrat en cours ==')

const contrats = await rest(token,
  `contrats?select=id,salarie_id,societe_id,date_debut,date_fin,brut_mensuel,version,genre` +
  `&societe_id=eq.${company?.id}&statut=eq.en_cours&genre=eq.cdi&limit=1`)
const contrat = contrats.body?.[0]
if (!contrat) ko('contrat de démonstration', 'aucun CDI actif lisible')

{
  // Un second contrat actif qui recouvre le premier doit être refusé par la base.
  const r = await rest(token, 'contrats', {
    method: 'POST',
    body: JSON.stringify({
      societe_id: contrat?.societe_id, salarie_id: contrat?.salarie_id,
      genre: 'cdi', statut: 'en_cours', intitule_poste: 'Doublon de test',
      date_debut: contrat?.date_debut, brut_mensuel: 3000,
      heures_hebdomadaires: 40, jours_par_semaine: 5, periode_reference_mois: 1,
    }),
  })
  r.ok ? ko('second contrat actif chevauchant refusé', 'a été accepté')
       : ok('second contrat actif chevauchant refusé', `HTTP ${r.status}`)
}

// ---------------------------------------------------------------------------
console.log('\n== Avenant ==')

// La prise d'effet se déduit du contrat : figer une date rendrait la suite non
// rejouable dès que le jeu de démonstration change — ce qui est exactement ce
// qui s'est produit au premier essai.
const decale = (iso, jours = 0, mois = 0) => {
  const d = new Date(`${iso}T00:00:00Z`)
  d.setUTCMonth(d.getUTCMonth() + mois)
  d.setUTCDate(d.getUTCDate() + jours)
  return d.toISOString().slice(0, 10)
}
const prise_effet = decale(contrat?.date_debut, 0, 3)
const veille = decale(prise_effet, -1)

{
  const r = await rpc(token, 'fn_amend_contract', {
    p_contract: contrat?.id, p_effective_date: prise_effet,
    p_changes: { brut_mensuel: 4321 }, p_reason: '',
  })
  r.ok ? ko('avenant sans motif refusé', 'a réussi') : ok('avenant sans motif refusé', `HTTP ${r.status}`)
}
{
  const r = await rpc(token, 'fn_amend_contract', {
    p_contract: contrat?.id, p_effective_date: prise_effet,
    p_changes: {}, p_reason: 'Rien',
  })
  r.ok ? ko('avenant sans modification refusé', 'a réussi')
       : ok('avenant sans modification refusé', `HTTP ${r.status}`)
}

let nouveau = null
{
  const r = await rpc(token, 'fn_amend_contract', {
    p_contract: contrat?.id,
    p_effective_date: prise_effet,
    p_changes: { brut_mensuel: 4321, heures_hebdomadaires: 30 },
    p_reason: 'Augmentation et passage à temps partiel',
  })
  if (!r.ok) ko('avenant établi', JSON.stringify(r.body))
  else {
    nouveau = r.body?.new_contract_id
    ok('avenant établi', `version ${r.body?.version}`)
    r.body?.previous_end_date === veille
      ? ok('ancien contrat clos la veille de la prise d’effet')
      : ko('clôture de l’ancien', String(r.body?.previous_end_date))
  }
}
if (nouveau) {
  const ancien = await rest(token, `contrats?select=statut,date_fin&id=eq.${contrat.id}`)
  ancien.body?.[0]?.statut === 'termine'
    ? ok('ancien contrat au statut « termine »')
    : ko('statut de l’ancien', JSON.stringify(ancien.body))

  const neuf = await rest(token,
    `contrats?select=statut,version,date_debut,brut_mensuel,heures_hebdomadaires,est_temps_partiel,` +
    `contrat_precedent_id,signe_le,intitule_poste,genre&id=eq.${nouveau}`)
  const n = neuf.body?.[0] ?? {}
  n.statut === 'en_cours' ? ok('nouveau contrat actif') : ko('statut du nouveau', n.statut)
  n.version === (contrat.version ?? 1) + 1
    ? ok('version incrémentée', String(n.version)) : ko('version', String(n.version))
  n.contrat_precedent_id === contrat.id
    ? ok('chaînage vers l’ancien conservé') : ko('chaînage', String(n.contrat_precedent_id))
  Number(n.brut_mensuel) === 4321
    ? ok('modification appliquée', `${n.brut_mensuel} €`) : ko('modification', String(n.brut_mensuel))
  n.est_temps_partiel === true
    ? ok('temps partiel recalculé par le déclencheur')
    : ko('temps partiel', String(n.est_temps_partiel))
  n.signe_le === null
    ? ok('nouveau contrat non signé — un avenant se signe')
    : ko('signature', String(n.signe_le))
  n.genre === contrat.genre && n.intitule_poste != null
    ? ok('clauses non modifiées reprises', n.intitule_poste)
    : ko('reprise des clauses', JSON.stringify(n).slice(0, 140))

  const avenants = await rest(token,
    `avenants_contrat?select=motif,date_effet&contrat_id=eq.${nouveau}`)
  avenants.body?.length === 1
    ? ok('avenant journalisé', avenants.body[0].motif)
    : ko('journal de l’avenant', JSON.stringify(avenants.body))
}

// ---------------------------------------------------------------------------
console.log('\n== Nettoyage ==')
//
// `fn_seed_demo` refuse de recharger tant que des sociétés existent : la suite
// défait donc sa propre écriture, ce qui est de toute façon plus sûr — elle ne
// touche qu'aux deux lignes qu'elle a créées ou modifiées.
if (nouveau) {
  // L'avenant d'abord : tant qu'il est actif, l'ancien ne peut pas l'être aussi.
  const suppression = await rest(token, `contrats?id=eq.${nouveau}`, { method: 'DELETE' })
  suppression.ok ? ok('avenant de test supprimé') : ko('suppression de l’avenant', suppression.status)

  const remise = await fetch(`${URL}/rest/v1/contrats?id=eq.${contrat.id}`, {
    method: 'PATCH',
    headers: { ...h(token), Prefer: 'return=representation' },
    body: JSON.stringify({ statut: 'en_cours', date_fin: contrat.date_fin }),
  })
  const revenu = await remise.json().catch(() => null)
  remise.ok && revenu?.[0]?.statut === 'en_cours'
    ? ok('contrat d’origine rétabli', `fin ${revenu[0].date_fin ?? '—'}`)
    : ko('rétablissement du contrat', JSON.stringify(revenu).slice(0, 160))

  const restants = await rest(token,
    `contrats?select=id&salarie_id=eq.${contrat.salarie_id}&statut=eq.en_cours`)
  restants.body?.length === 1
    ? ok('un seul contrat actif à nouveau')
    : ko('contrats actifs après nettoyage', `${restants.body?.length}`)
}

console.log(`\nCycle de vie : ${pass} vérifications, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
