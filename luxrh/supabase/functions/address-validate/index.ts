/**
 * Vérification d'une adresse.
 *
 * Deux régimes, selon le pays
 * ---------------------------
 *   Luxembourg  : interrogation du registre officiel **BD-Adresses** de
 *                 l'Administration du cadastre et de la topographie, par l'API
 *                 geocode du geoportail. C'est la voie « API CACLR » ; l'autre
 *                 voie prévue — charger `addresses.csv` en base — reste ouverte
 *                 et n'a pas été retenue par défaut, une API suivant les mises à
 *                 jour sans qu'on ait à recharger quoi que ce soit.
 *
 *                 Jeu de données :
 *                 https://data.public.lu/datasets/adresses-georeferencees-bd-adresses
 *                 Point d'entrée : https://apiv3.geoportail.lu/geocode/search
 *
 *   BE / FR / DE : aucune API publique n'est utilisée. La vérification se
 *                 limite donc à la **zone géographique**, par `fn_validate_address` :
 *                 provinces de Liège, Namur et Luxembourg ; départements 54 et
 *                 57 ; Rhénanie-Palatinat et Sarre. Le jour où une API existe
 *                 pour l'un de ces pays, elle se branche ici, à côté du cas
 *                 luxembourgeois.
 *
 * Ce que cette fonction ne fait pas
 * ---------------------------------
 * Elle ne remplace pas le déclencheur `check_address` : celui-ci s'applique à
 * toute écriture, y compris à celles qui ne passent pas par ici. La fonction
 * apporte ce que la base ne peut pas savoir — qu'une rue et un numéro existent
 * réellement à Luxembourg.
 *
 * Protection des données
 * ----------------------
 * L'appel transmet une adresse à un service tiers, fût-il public. Trois
 * précautions, comme pour `travel-distance` :
 *   · le jeton de l'appelant est transmis à Supabase, donc la RLS s'applique ;
 *   · seule l'adresse est envoyée — jamais le nom de la personne ;
 *   · le résultat n'est pas conservé ici : c'est `address_checks` qui garde le
 *     verdict, sans l'adresse normalisée renvoyée par le service.
 *
 * Le geoportail n'exige pas de clé d'API. Rien n'est donc à configurer, et rien
 * n'est inventé si la configuration manque.
 */
import { createClient } from 'jsr:@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })

const GEOCODE = Deno.env.get('LU_GEOCODE_URL') ??
  'https://apiv3.geoportail.lu/geocode/search'

/** Retire le préfixe pays de la convention luxembourgeoise : « L-1424 » → « 1424 ». */
const sansPrefixe = (cp: string) => cp.replace(/^\s*[A-Za-z]{1,2}\s*-\s*/, '').trim()

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const authorization = req.headers.get('Authorization')
    if (!authorization) return json({ error: 'Authentification requise' }, 401)

    const { country, postal_code, city, street, house_number } = await req.json()
    if (!country) return json({ error: 'country est requis' }, 400)

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authorization } } },
    )

    // 1. La zone, d'abord : inutile d'interroger un service pour une adresse
    //    que le périmètre exclut de toute façon.
    const { data: zone, error: ez } = await supabase.rpc('fn_validate_address', {
      p_country: country,
      p_postal: postal_code ?? null,
      p_city: city ?? null,
    })
    if (ez) return json({ error: ez.message }, 403)

    if (zone?.status === 'outside') {
      return json({ ...zone, verified_by: 'zone', message: zone.message })
    }

    // 2. Hors Luxembourg, on s'arrête là — et on le dit, plutôt que de laisser
    //    croire à une vérification qui n'a pas eu lieu.
    if (String(country).toUpperCase() !== 'LU') {
      return json({
        ...zone,
        verified_by: 'zone',
        message:
          zone?.status === 'ok'
            ? "Adresse située dans une zone couverte. L'existence de la rue et du " +
              "numéro n'est pas vérifiée : aucune API publique n'est utilisée pour ce pays."
            : zone?.message,
      })
    }

    // 3. Luxembourg : le registre officiel.
    const requete = [house_number, street, sansPrefixe(String(postal_code ?? '')), city]
      .filter((p) => p != null && String(p).trim() !== '')
      .join(' ')
      .trim()

    if (!requete) {
      return json({
        ...zone,
        verified_by: 'zone',
        message: 'Adresse trop incomplète pour être recherchée dans le registre.',
      })
    }

    const url = new URL(GEOCODE)
    url.searchParams.set('queryString', requete)

    const reponse = await fetch(url, { signal: AbortSignal.timeout(10_000) })
    if (!reponse.ok) {
      // Le service est indisponible : on ne conclut pas à sa place.
      return json({
        ...zone,
        verified_by: 'zone',
        registry: 'indisponible',
        message:
          `Le registre d'adresses n'a pas répondu (${reponse.status}). La zone est ` +
          `confirmée, l'existence de l'adresse ne l'est pas.`,
      })
    }

    // Forme de la réponse, relevée sur le service le 10 septembre 2026 :
    //   { success, count, request, results: [ { name, accuracy, address,
    //     "matching street", ratio, geomlonlat, AddressDetails: { postnumber,
    //     street, zip, locality, … } } ] }
    // `accuracy` vaut 8 pour une correspondance au numéro près ; les valeurs
    // inférieures désignent une rue ou une localité seule.
    const payload = await reponse.json()
    const candidats: Record<string, never>[] = Array.isArray(payload?.results)
      ? payload.results
      : []
    const auNumero = candidats.find((r) => Number(r?.['accuracy']) >= 8)
    const exact = auNumero ?? candidats[0]

    if (!exact) {
      return json({
        ...zone,
        verified_by: 'registre',
        registry: 'introuvable',
        status: 'unknown',
        message:
          "Cette adresse n'a pas été trouvée dans le registre BD-Adresses. " +
          'Vérifiez la rue et le numéro, ou confirmez la saisie manuellement.',
      })
    }

    const details = (exact['AddressDetails'] ?? {}) as Record<string, unknown>
    const zipTrouve = details.zip == null ? null : String(details.zip)
    const zipSaisi = sansPrefixe(String(postal_code ?? ''))

    // Le service accepte une requête approximative et rend son meilleur
    // candidat : un code postal qui ne correspond pas est un signal, pas un
    // détail. On le remonte plutôt que de valider en bloc.
    const zipDiverge = zipSaisi !== '' && zipTrouve !== null && zipTrouve !== zipSaisi

    return json({
      ...zone,
      verified_by: 'registre',
      registry: auNumero ? 'trouvee' : 'approchante',
      status: auNumero && !zipDiverge ? 'ok' : 'unknown',
      matched: exact['address'] ?? exact['name'] ?? null,
      accuracy: exact['accuracy'] ?? null,
      postal_code_found: zipTrouve,
      locality_found: details.locality ?? null,
      street_found: details.street ?? null,
      source: 'BD-Adresses — Administration du cadastre et de la topographie',
      message: zipDiverge
        ? `Le registre situe cette adresse en ${zipTrouve}, et non en ${zipSaisi}. ` +
          'À confirmer avant enregistrement.'
        : auNumero
        ? 'Adresse confirmée au numéro près par le registre officiel luxembourgeois.'
        : "Le registre reconnaît la rue ou la localité, mais pas le numéro. " +
          'La correspondance est approchante.',
    })
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500)
  }
})
