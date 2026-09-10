/**
 * Génération du contrat de travail en PDF.
 *
 * Le document est rendu côté serveur avec le jeton de l'appelant : la RLS
 * s'applique donc telle quelle, et un gestionnaire ne peut produire que les
 * contrats des sociétés auxquelles il a accès. Les dates et les contrôles de
 * conformité repris dans le document viennent du moteur de règles, jamais
 * d'un calcul refait ici.
 */
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { buildPdf, type Line } from './pdf.ts'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const fmtDate = (v: string | null | undefined) =>
  v ? new Date(`${v.slice(0, 10)}T00:00:00`).toLocaleDateString('fr-LU') : '—'

const fmtEur = (v: number | string | null | undefined) =>
  v === null || v === undefined
    ? '—'
    : `${new Intl.NumberFormat('fr-LU', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(v))} EUR`

const fmtNum = (v: number | string | null | undefined, d = 2) =>
  v === null || v === undefined
    ? '—'
    : new Intl.NumberFormat('fr-LU', { maximumFractionDigits: d }).format(Number(v))

const KIND_LABEL: Record<string, string> = {
  cdi: 'A DUREE INDETERMINEE',
  cdd: 'A DUREE DETERMINEE',
  seasonal: 'SAISONNIER',
  apprenticeship: "D'APPRENTISSAGE",
  interim: 'DE MISSION',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })

  try {
    const authorization = req.headers.get('Authorization')
    if (!authorization) {
      return new Response(JSON.stringify({ error: 'Authentification requise' }), {
        status: 401,
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const { contract_id } = await req.json()
    if (!contract_id) {
      return new Response(JSON.stringify({ error: 'contract_id manquant' }), {
        status: 400,
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authorization } } },
    )

    const { data: c, error } = await supabase
      .from('contracts')
      .select('*, employees(*), companies(*)')
      .eq('id', contract_id)
      .single()
    if (error || !c) {
      return new Response(JSON.stringify({ error: error?.message ?? 'Contrat introuvable' }), {
        status: 404,
        headers: { ...CORS, 'Content-Type': 'application/json' },
      })
    }

    const { data: compliance } = await supabase.rpc('fn_contract_compliance', {
      p_contract: contract_id,
      p_on: new Date().toISOString().slice(0, 10),
    })

    const emp = c.employees
    const co = c.companies
    const engine = compliance as {
      probation?: Record<string, string>
      collective_agreements?: { name: string; origin: string }[]
    } | null
    const prob = engine?.probation
    const cbas = engine?.collective_agreements ?? []
    const kindLabel = KIND_LABEL[c.kind] ?? c.kind.toUpperCase()

    let article = 1
    const art = () => `Article ${article++} — `

    const lines: Line[] = [
      { kind: 'text', text: co.legal_name, size: 9 },
      { kind: 'text', text: `${co.address_line ?? ''}, ${co.postal_code ?? ''} ${co.city ?? ''}`, size: 9 },
      { kind: 'space', height: 18 },
      { kind: 'text', text: `CONTRAT DE TRAVAIL ${kindLabel}`, bold: true, size: 14 },
      { kind: 'rule' },
      { kind: 'space', height: 6 },
      {
        kind: 'text',
        text:
          `Entre les soussignés : la société ${co.legal_name}` +
          (co.rcs_number ? `, RCS ${co.rcs_number}` : '') +
          `, établie ${co.address_line ?? ''}, ${co.postal_code ?? ''} ${co.city ?? ''}` +
          (co.ccss_matricule ? `, matricule CCSS ${co.ccss_matricule}` : '') +
          `, ci-après « l'employeur »,`,
        gap: 6,
      },
      {
        kind: 'text',
        text:
          `Et ${emp.first_name} ${emp.last_name}` +
          (emp.birth_date ? `, né(e) le ${fmtDate(emp.birth_date)}` : '') +
          (emp.address_line ? `, demeurant ${emp.address_line}, ${emp.postal_code ?? ''} ${emp.city ?? ''}` : '') +
          `, ci-après « le salarié », il a été convenu ce qui suit.`,
        gap: 10,
      },
      {
        kind: 'text',
        text:
          `${art()}Engagement et fonction. Le salarié est engagé en qualité de ${c.job_title}, ` +
          `à compter du ${fmtDate(c.start_date)}` +
          (c.work_place ? `, au lieu de travail sis ${c.work_place}` : '') +
          '.' + (c.job_description ? ` ${c.job_description}` : ''),
        gap: 6,
      },
    ]

    if (c.kind === 'interim' && c.user_company_name) {
      lines.push({
        kind: 'text',
        text:
          `${art()}Mise à disposition. Le salarié est mis à disposition de l'entreprise utilisatrice ` +
          `${c.user_company_name}` +
          (c.mission_reason ? `, pour le motif suivant : ${c.mission_reason}` : '') + '.',
        gap: 6,
      })
    }

    if (c.probation_length && prob) {
      lines.push({
        kind: 'text',
        text:
          `${art()}Période d'essai. Le contrat est assorti d'une période d'essai de ${c.probation_length} ` +
          `${c.probation_unit === 'months' ? 'mois' : 'semaines'}, expirant le ${fmtDate(prob.end)}. ` +
          `Pendant l'essai, chaque partie peut résilier moyennant un préavis de ${prob.notice_days} jours, ` +
          `qui doit expirer au plus tard le dernier jour de l'essai.`,
        gap: 6,
      })
    }

    lines.push(
      {
        kind: 'text',
        text:
          `${art()}Durée de travail. La durée hebdomadaire est fixée à ${fmtNum(c.weekly_hours)} heures` +
          (c.is_part_time ? ', le contrat étant conclu à temps partiel' : '') +
          (c.work_distribution ? `, réparties selon la modalité suivante : ${c.work_distribution}` : '') +
          `. Une période de référence de ${c.reference_period_months} mois est applicable.`,
        gap: 6,
      },
      {
        kind: 'text',
        text:
          `${art()}Rémunération. La rémunération mensuelle brute est fixée à ${fmtEur(c.monthly_gross)}` +
          (c.index_ref ? ` à l'indice ${fmtNum(c.index_ref)}` : '') +
          `, payable à la fin de chaque mois. Elle est adaptée à chaque variation de l'indice des prix ` +
          `à la consommation.`,
        gap: 6,
      },
      {
        kind: 'text',
        text:
          `${art()}Congé annuel. Le salarié bénéficie de ${fmtNum(c.annual_leave_days, 0)} jours ouvrables ` +
          `de congé annuel payé.`,
        gap: 6,
      },
    )

    if (c.end_date) {
      lines.push({
        kind: 'text',
        text:
          `${art()}Terme du contrat. Le contrat prend fin le ${fmtDate(c.end_date)}.` +
          (c.cdd_reason ? ` Motif de recours : ${c.cdd_reason}.` : '') +
          (c.season_label ? ` Saison couverte : ${c.season_label}.` : ''),
        gap: 6,
      })
    }

    lines.push({
      kind: 'text',
      text:
        `${art()}Conventions collectives. ` +
        (cbas.length > 0
          ? `Le contrat est régi par : ${cbas.map((a) => `${a.name} (${a.origin})`).join(', ')}.`
          : `Aucune convention collective n'est applicable à ce contrat.`),
      gap: 6,
    })

    if (c.non_compete_clause) {
      lines.push({
        kind: 'text',
        text:
          `${art()}Clause de non-concurrence. Le salarié s'interdit d'exercer une activité concurrente, ` +
          `dans les limites de temps, d'espace et d'activité définies à l'annexe.`,
        gap: 6,
      })
    }

    lines.push(
      { kind: 'space', height: 16 },
      { kind: 'text', text: `Fait à ${co.city ?? 'Luxembourg'}, le ${fmtDate(new Date().toISOString())}.`, gap: 24 },
      { kind: 'text', text: `L'employeur                                        Le salarié`, size: 9 },
      { kind: 'space', height: 24 },
      { kind: 'rule' },
      {
        kind: 'text',
        size: 8,
        text:
          `Document généré par LuxRH le ${new Date().toLocaleString('fr-LU')}. ` +
          `Les dates et montants repris ci-dessus sont calculés à partir du référentiel légal daté. ` +
          `Ce document est une aide à la rédaction et ne se substitue pas à un conseil juridique.`,
      },
    )

    const pdf = buildPdf(`Contrat ${emp.last_name} — ${co.legal_name}`, lines)

    // Le document est aussi rangé dans le dossier du salarié, bucket privé.
    const path = `${co.id}/${emp.id}/contrat-${contract_id}.pdf`
    const { error: upErr } = await supabase.storage
      .from('documents')
      .upload(path, pdf, { contentType: 'application/pdf', upsert: true })

    if (!upErr) {
      await supabase.from('documents').upsert(
        {
          company_id: co.id,
          employee_id: emp.id,
          entity_table: 'contracts',
          entity_id: contract_id,
          name: `Contrat de travail — ${emp.first_name} ${emp.last_name}`,
          storage_path: path,
          mime_type: 'application/pdf',
          size_bytes: pdf.byteLength,
        },
        { onConflict: 'storage_path' },
      )
    }

    return new Response(pdf, {
      headers: {
        ...CORS,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="contrat-${emp.last_name}.pdf"`,
      },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e instanceof Error ? e.message : String(e) }), {
      status: 500,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  }
})
