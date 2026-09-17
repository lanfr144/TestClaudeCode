// Segments de temps : découpage d'une vacation, requalification des heures
// supplémentaires, et contrôle d'accès.
//
// Ces fonctions sont `security definer` : elles contournent RLS et portent donc
// leur propre garde. Un test qui ne vérifierait que le calcul laisserait passer
// une fonction par laquelle n'importe quel salarié réécrirait les heures d'un
// collègue.
import { URL_BASE as URL, KEY, account } from './config.mjs'

let pass = 0, fail = 0
const ok = (n, d = '') => { pass++; console.log(`  ok   ${n}${d ? ' — ' + d : ''}`) }
const ko = (n, e) => { fail++; console.log(`  FAIL ${n} :: ${e}`) }
const h = (t) => ({ apikey: KEY, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' })

async function jeton(nom) {
  const r = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: account(nom).email, password: account(nom).password }),
  }).then((r) => r.json())
  return r.access_token
}

const token = await jeton('manager')
const get = (t, q) => fetch(`${URL}/rest/v1/${q}`, { headers: h(t) }).then((r) => r.json())
const post = (t, path, body) =>
  fetch(`${URL}/rest/v1/${path}`, {
    method: 'POST', headers: { ...h(t), Prefer: 'return=representation' },
    body: JSON.stringify(body),
  }).then(async (r) => [r.ok, await r.json()])
const del = (t, q) => fetch(`${URL}/rest/v1/${q}`, { method: 'DELETE', headers: h(t) })
const rpc = async (t, fn, args = {}) => {
  const r = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers: h(t), body: JSON.stringify(args),
  })
  return { ok: r.ok, status: r.status, body: await r.json().catch(() => null) }
}

console.log('\n== Segments de temps ==')

// Un planning et un salarié existants : on ne crée pas d'organisation de test,
// on greffe sur ce qui est là et on nettoie derrière soi.
const modeles = await get(token, 'creneaux?select=planning_id,societe_id,salarie_id&limit=1')
const modele = modeles?.[0]
if (!modele) {
  ko('jeu d’essai', 'aucun créneau existant pour servir de modèle')
} else {
  // Une semaine à 9 heures par jour, du lundi au vendredi : chaque journée
  // dépasse le seuil de 8 h, et la semaine dépasse 40 h au quatrième jour.
  const LUNDI = '2027-03-01' // un lundi
  const crees = []
  for (let j = 0; j < 5; j++) {
    const d = new Date(`${LUNDI}T00:00:00Z`)
    d.setUTCDate(d.getUTCDate() + j)
    const jour = d.toISOString().slice(0, 10)
    const [okc, body] = await post(token, 'creneaux', {
      planning_id: modele.planning_id,
      societe_id: modele.societe_id,
      salarie_id: modele.salarie_id,
      date_creneau: jour,
      heure_debut: '08:00',
      heure_fin: '17:00',
      pause_minutes: 0,
      libelle: 'ESSAI segments',
    })
    if (okc) crees.push(body[0].id)
  }
  crees.length === 5
    ? ok('cinq vacations de 9 h posées')
    : ko('jeu d’essai', `${crees.length} vacation(s) créée(s)`)

  // --- découpage
  let segments = 0
  for (const id of crees) {
    const r = await rpc(token, 'fn_decouper_creneau', { p_creneau: id })
    if (r.ok) segments += r.body
  }
  segments >= 5
    ? ok('vacations découpées en segments', `${segments} segment(s)`)
    : ko('découpage', String(segments))

  // --- requalification
  const q = await rpc(token, 'fn_qualifier_heures_sup', {
    p_salarie: modele.salarie_id, p_debut: LUNDI, p_fin: '2027-03-05',
  })
  q.ok ? ok('requalification exécutée', `${q.body} segment(s) touché(s)`)
       : ko('requalification', JSON.stringify(q.body))

  const tous = await get(token,
    `segments_temps?select=debut_le,fin_le,minutes,classe_paie` +
    `&salarie_id=eq.${modele.salarie_id}&debut_le=gte.2027-03-01&debut_le=lt.2027-03-08` +
    `&order=debut_le`)

  const normales = tous.filter((s) => s.classe_paie === 'normal')
  const sup = tous.filter((s) => s.classe_paie === 'heure_sup')
  const minutes = (l) => l.reduce((t, s) => t + s.minutes, 0)

  // Chaque journée porte 9 h ; 8 h normales, 1 h supplémentaire. Mais le seuil
  // hebdomadaire de 40 h tombe au cours du cinquième jour : à partir de là, tout
  // est supplémentaire. Quatre jours à 8 h font 32 h ; le cinquième n'ouvre donc
  // que 8 h de marge hebdomadaire — déjà consommées par les jours précédents.
  minutes(normales) === 40 * 60
    ? ok('quarante heures normales', `${minutes(normales) / 60} h`)
    : ko('heures normales', `${minutes(normales) / 60} h au lieu de 40`)

  minutes(sup) === 5 * 60
    ? ok('cinq heures supplémentaires', `${minutes(sup) / 60} h`)
    : ko('heures supplémentaires', `${minutes(sup) / 60} h au lieu de 5`)

  // --- idempotence : un second passage ne doit rien changer
  await rpc(token, 'fn_qualifier_heures_sup', {
    p_salarie: modele.salarie_id, p_debut: LUNDI, p_fin: '2027-03-05',
  })
  const apres = await get(token,
    `segments_temps?select=minutes,classe_paie&salarie_id=eq.${modele.salarie_id}` +
    `&debut_le=gte.2027-03-01&debut_le=lt.2027-03-08`)
  apres.length === tous.length
    ? ok('requalification idempotente', `${apres.length} segment(s) inchangé(s)`)
    : ko('idempotence', `${tous.length} puis ${apres.length} segments`)

  // --- contrôle d'accès : un salarié d'une autre société est refusé
  const autre = await jeton('other')
  if (autre) {
    const refus = await rpc(autre, 'fn_qualifier_heures_sup', {
      p_salarie: modele.salarie_id, p_debut: LUNDI, p_fin: '2027-03-05',
    })
    !refus.ok
      ? ok('requalification refusée à un tiers', `HTTP ${refus.status}`)
      : ko('contrôle d’accès', 'un tiers a pu requalifier les segments')

    const refus2 = await rpc(autre, 'fn_decouper_creneau', { p_creneau: crees[0] })
    !refus2.ok
      ? ok('découpage refusé à un tiers', `HTTP ${refus2.status}`)
      : ko('contrôle d’accès', 'un tiers a pu découper un créneau')
  }

  // --- restitution en langage naturel, sur une vacation de nuit
  //
  // Le cas de la spécification : 22h00 → 02h00, pause d'une heure, 03h00 → 07h00.
  // Huit heures effectives, dont sept de nuit — la fenêtre s'arrête à 06h00.
  const [okn, nuitBody] = await post(token, 'creneaux', {
    planning_id: modele.planning_id,
    societe_id: modele.societe_id,
    salarie_id: modele.salarie_id,
    date_creneau: '2027-03-15',
    heure_debut: '22:00',
    heure_fin: '07:00',
    pause_minutes: 60,
    libelle: 'ESSAI nuit',
  })
  if (okn) {
    const idNuit = nuitBody[0].id
    await rpc(token, 'fn_decouper_creneau', { p_creneau: idNuit })

    const r = await rpc(token, 'fn_releve_lisible', {
      p_salarie: modele.salarie_id, p_jour: '2027-03-15',
    })
    const l = r.body?.[0]
    if (!r.ok || !l) {
      ko('restitution lisible', JSON.stringify(r.body))
    } else {
      console.log(`       « ${l.phrase} »`)
      l.phrase.includes('travaillé de 22h00')
        ? ok('la phrase commence à 22h00')
        : ko('phrase', l.phrase)
      l.phrase.includes('pause')
        ? ok('la pause est mentionnée')
        : ko('pause absente', l.phrase)
      l.minutes_effectives === 480
        ? ok('huit heures effectives', `${l.minutes_effectives} min`)
        : ko('effectives', `${l.minutes_effectives} min au lieu de 480`)
      l.minutes_pause === 60
        ? ok('une heure de pause', `${l.minutes_pause} min`)
        : ko('pause', `${l.minutes_pause} min au lieu de 60`)
      // 22h→02h = 4h de nuit, 03h→06h = 3h de nuit, 06h→07h hors fenêtre.
      l.minutes_nuit === 420
        ? ok('sept heures de nuit', `${l.minutes_nuit} min`)
        : ko('nuit', `${l.minutes_nuit} min au lieu de 420`)
    }
    await del(token, `creneaux?id=eq.${idNuit}`)
  }

  // --- nettoyage : les segments partent en cascade avec les créneaux
  for (const id of crees) await del(token, `creneaux?id=eq.${id}`)
  const restants = await get(token,
    `segments_temps?select=id&salarie_id=eq.${modele.salarie_id}` +
    `&debut_le=gte.2027-03-01&debut_le=lt.2027-03-08`)
  restants.length === 0
    ? ok('jeu d’essai supprimé')
    : ko('nettoyage', `${restants.length} segment(s) restant(s)`)
}

console.log(`\nSegments : ${pass + fail} vérifications, ${fail} échec(s).`)
process.exit(fail ? 1 : 0)
