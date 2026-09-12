-- Reconstitué depuis la base le 10 septembre 2026 : cette migration était appliquée
-- sans fichier correspondant dans le dépôt. Voir docs/ecarts-a-corriger.md.
-- 45. L'export du referentiel manquait les CCT sectorielles.
--
-- Une CCT dont l'organization_id est nul est partagee : la politique RLS
-- `cba_read` la rend visible a tous. L'export la filtrait pourtant sur la seule
-- organisation du demandeur, et repartait donc sans aucune des CCT nationales
-- ni leurs regles ou grilles -- exactement le savoir qu'il devait emporter.
--
-- A l'import, ces CCT sont en revanche rattachees a l'organisation qui charge
-- le document. Laisser un locataire creer des lignes partagees les rendrait
-- visibles a tous les autres : le semis des CCT nationales releve de la
-- plateforme, pas d'un import de locataire. Le drapeau `is_shared` conserve
-- l'origine sans conferer la portee.

set search_path = public, extensions;

create or replace function fn_export_referential()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  payload jsonb;
  org     uuid := auth_org_id();
begin
  if org is null then
    raise exception 'Export refuse : compte non rattache a une organisation.';
  end if;

  payload := jsonb_build_object(
    'legal_parameters', (select coalesce(jsonb_agg(to_jsonb(t) - 'id' - 'entered_by' - 'entered_at'
                                                    - 'validated_by' - 'validated_at'
                                         order by t.param_key, t.valid_from), '[]'::jsonb)
                           from legal_parameters t),
    'absence_types',    (select coalesce(jsonb_agg(to_jsonb(t) - 'id' order by t.code), '[]'::jsonb)
                           from absence_types t),
    'absence_entitlements',
                        (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'absence_type_id')
                                  || jsonb_build_object('absence_type_code', a.code)
                                  order by a.code, t.valid_from), '[]'::jsonb)
                           from absence_entitlements t
                           join absence_types a on a.id = t.absence_type_id),
    'benefit_types',    (select coalesce(jsonb_agg(to_jsonb(t) - 'id' order by t.code), '[]'::jsonb)
                           from benefit_types t),
    'document_types',   (select coalesce(jsonb_agg(to_jsonb(t) - 'id' order by t.code), '[]'::jsonb)
                           from document_types t),
    'tax_brackets',     (select coalesce(jsonb_agg(to_jsonb(t) - 'id'
                                         order by t.tax_class, t.valid_from, t.bracket_min), '[]'::jsonb)
                           from tax_brackets t),
    'tax_credits',      (select coalesce(jsonb_agg(to_jsonb(t) - 'id'
                                         order by t.code, t.valid_from), '[]'::jsonb)
                           from tax_credits t),
    'public_holidays',  (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by t.holiday_date), '[]'::jsonb)
                           from public_holidays t
                           left join collective_agreements a on a.id = t.collective_agreement_id),
    'collective_agreements',
                        (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'organization_id' - 'supersedes_id' - 'created_at')
                                  || jsonb_build_object('is_shared', t.organization_id is null)
                                  order by t.code, t.valid_from), '[]'::jsonb)
                           from collective_agreements t
                          where t.organization_id is null or t.organization_id = org),
    'cba_rules',        (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id' - 'updated_at')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by a.code, t.block::text), '[]'::jsonb)
                           from cba_rules t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id is null or a.organization_id = org),
    'cba_salary_grids', (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by a.code, t.category, t.seniority_from_years), '[]'::jsonb)
                           from cba_salary_grids t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id is null or a.organization_id = org));

  insert into export_log (organization_id, requested_by, subject_kind, row_count, byte_size)
  values (org, auth.uid(), 'referential', fn_payload_rows(payload), length(payload::text));

  return jsonb_build_object(
    'format', 'luxrh.export/1', 'kind', 'referential',
    'exported_at', now(), 'payload', payload);
end $$;

comment on function fn_export_referential() is
  'Transmission du savoir : referentiel legal et CCT (partagees comprises), en cles naturelles.';


-- L'import doit reconnaitre une CCT deja presente, qu'elle soit partagee ou
-- propre a l'organisation : sinon il en cree un doublon sous le meme code.
create or replace function fn_cba_by_code(p_code text, p_org uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select id from collective_agreements
   where code = p_code and (organization_id = p_org or organization_id is null)
   order by (organization_id = p_org) desc, valid_from desc
   limit 1;
$$;

revoke all on function fn_cba_by_code(text, uuid) from public, anon, authenticated;
