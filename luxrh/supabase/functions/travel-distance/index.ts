/**
 * Calcul d'une distance routière entre deux points du modèle, et mise en cache.
 *
 * Pourquoi une Edge Function plutôt qu'un appel depuis la base ou le navigateur
 * ---------------------------------------------------------------------------
 * La clé d'API ne doit se trouver ni dans le front (elle serait publique) ni dans
 * la base (elle serait exposée à toute fuite de dump). Elle vit ici, en variable
 * d'environnement du serveur, et n'en sort pas.
 *
 * Protection des données
 * ----------------------
 * Cet appel transmet une adresse — celle du domicile d'un salarié dans le cas
 * courant — à un service tiers. Trois précautions en découlent, appliquées ici :
 *
 *   1. Le jeton de l'appelant est transmis à Supabase : la RLS s'applique, et
 *      `fn_address_of` refuse une adresse hors du périmètre de l'appelant.
 *   2. La distance est mise en cache par `fn_set_travel_distance`, qui trace la
 *      transmission dans `data_access_log` (action DOWNLOAD). Une adresse n'est
 *      donc transmise qu'une fois par couple, et on sait quand.
 *   3. Si la distance est déjà en cache, aucun appel externe n'a lieu.
 *
 * Ce que cela ne règle pas : le choix du fournisseur et son encadrement
 * contractuel (sous-traitance au sens de l'article 28 du RGPD). Voir
 * `docs/securite-et-conformite.md`.
 *
 * Variables d'environnement attendues
 * -----------------------------------
 *   DISTANCE_API_KEY       clé du service de distance
 *   DISTANCE_API_URL       point d'entrée ; par défaut l'API Distance Matrix
 *
 * Aucune valeur par défaut n'est fournie pour la clé : sans elle, la fonction
 * répond qu'elle ne peut pas conclure, plutôt que de renvoyer une distance
 * inventée.
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

/** Compose l'adresse envoyée au service. Coordonnées si on les a — elles évitent
 *  de transmettre une adresse postale en clair. */
function toQuery(addr: Record<string, unknown>): string | null {
  if (addr.latitude != null && addr.longitude != null) {
    return `${addr.latitude},${addr.longitude}`
  }
  const parts = [addr.line, addr.postal_code, addr.city, addr.country]
    .filter((p) => p != null && String(p).trim() !== '')
    .map(String)
  return parts.length ? parts.join(', ') : null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const authorization = req.headers.get('Authorization')
    if (!authorization) return json({ error: 'Authentification requise' }, 401)

    const { origin, destination, force } = await req.json()
    if (!origin || !destination) {
      return json({ error: 'origin et destination sont requis' }, 400)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authorization } } },
    )

    // 1. Déjà en cache ? Alors rien ne sort d'ici.
    if (!force) {
      const { data: cached } = await supabase.rpc('fn_travel_distance', {
        p_origin: origin,
        p_destination: destination,
      })
      if (cached?.found) return json({ ...cached, from_cache: true })
    }

    // 2. Résolution des adresses, sous le contrôle d'accès de la base.
    const [{ data: a, error: ea }, { data: b, error: eb }] = await Promise.all([
      supabase.rpc('fn_address_of', { p_ref: origin }),
      supabase.rpc('fn_address_of', { p_ref: destination }),
    ])
    if (ea || eb) return json({ error: (ea ?? eb)!.message }, 403)
    if (a?.found === false || b?.found === false) {
      return json({ found: false, message: (a?.found === false ? a : b).message }, 200)
    }

    const from = toQuery(a)
    const to = toQuery(b)
    if (!from || !to) {
      return json({
        found: false,
        message: "Adresse incomplète : le calcul n'est pas lancé.",
      })
    }

    // 3. Le service externe.
    const key = Deno.env.get('DISTANCE_API_KEY')
    if (!key) {
      return json({
        found: false,
        message:
          "Aucune clé de service de distance n'est configurée (DISTANCE_API_KEY). " +
          'Renseignez-la, ou saisissez la distance à la main : aucune valeur ' +
          "n'est estimée à la place.",
      })
    }

    const base = Deno.env.get('DISTANCE_API_URL') ??
      'https://maps.googleapis.com/maps/api/distancematrix/json'
    const url = new URL(base)
    url.searchParams.set('origins', from)
    url.searchParams.set('destinations', to)
    url.searchParams.set('units', 'metric')
    url.searchParams.set('mode', 'driving')
    url.searchParams.set('language', 'fr')
    url.searchParams.set('key', key)

    const response = await fetch(url, { signal: AbortSignal.timeout(10_000) })
    if (!response.ok) {
      return json({ found: false, message: `Service de distance indisponible (${response.status}).` }, 502)
    }
    const payload = await response.json()

    const element = payload?.rows?.[0]?.elements?.[0]
    if (payload?.status !== 'OK' || element?.status !== 'OK') {
      return json({
        found: false,
        message:
          `Le service n'a pas pu établir la distance (${element?.status ?? payload?.status}). ` +
          'Vérifiez les adresses, ou saisissez la distance à la main.',
      })
    }

    const km = Math.round((element.distance.value / 1000) * 100) / 100
    const minutes = Math.round(element.duration.value / 60)

    // 4. Mise en cache — et trace de la transmission de l'adresse.
    const { data: saved, error: es } = await supabase.rpc('fn_set_travel_distance', {
      p_origin: origin,
      p_destination: destination,
      p_km: km,
      p_minutes: minutes,
      p_source: new URL(base).host,
      p_note: `${element.distance.text} · ${element.duration.text}`,
    })
    if (es) return json({ error: es.message }, 403)

    return json({
      found: true,
      distance_km: km,
      duration_minutes: minutes,
      source: new URL(base).host,
      from_cache: false,
      saved,
    })
  } catch (e) {
    // Aucune erreur silencieuse : on dit ce qui a échoué.
    return json({ error: e instanceof Error ? e.message : String(e) }, 500)
  }
})
