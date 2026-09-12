-- 55 — Cycle de vie du contrat, et index de recherche par nom
--
-- Trois choses, dans l'ordre où elles se tiennent :
--   1. un salarié n'a qu'un seul contrat en cours à la fois — imposé en base ;
--   2. une modification de contrat passe par un avenant qui clôt l'ancien et
--      reprend toutes ses clauses ;
--   3. la recherche par nom cesse de balayer la table.

-- ===========================================================================
-- 1. Un seul contrat en cours à la fois
-- ===========================================================================
-- Une contrainte d'exclusion GiST, comme pour le référentiel daté : ce n'est pas
-- « un seul contrat actif » au sens d'un compteur, c'est « pas deux contrats
-- actifs dont les périodes se recouvrent ». La nuance compte : un contrat clos
-- au 31 mars et un nouveau qui commence au 1er avril sont tous deux légitimes,
-- et un chevauchement d'un seul jour ne l'est pas.
--
-- `end_date` nul donne une borne haute infinie : un CDI en cours bloque donc
-- tout autre contrat actif à partir de sa date de début.
--
-- Vérifié avant pose : 319 contrats actifs, **zéro** chevauchement, zéro salarié
-- à plus d'un contrat actif. La contrainte ne casse rien de l'existant.

alter table contracts
  add constraint one_active_contract_at_a_time
  exclude using gist (
    employee_id with =,
    daterange(start_date, end_date, '[]') with &&
  ) where (status = 'active');

comment on constraint one_active_contract_at_a_time on contracts is
  'Un salarié n''a qu''un seul contrat en cours à un instant donné. Contrainte d''exclusion plutôt que compteur : deux contrats actifs qui ne se recouvrent pas restent licites, un recouvrement d''un jour ne l''est pas.';

-- ===========================================================================
-- 2. L'avenant : clore, puis recréer en conservant tout
-- ===========================================================================
-- Le droit du travail luxembourgeois ne connaît pas la modification unilatérale
-- d'un élément essentiel : il faut un avenant signé. Techniquement, cela veut
-- dire que le contrat en cours se clôt et qu'un nouveau prend sa suite — et que
-- **rien ne doit se perdre au passage**.
--
-- D'où le choix de reconstruire la nouvelle ligne depuis `to_jsonb(ancien)`
-- plutôt que d'énumérer les colonnes : une colonne ajoutée demain sera reportée
-- sans que personne ait à y penser. Une énumération manuelle, elle, oublie
-- silencieusement — et un droit oublié dans un avenant est un droit perdu.
--
-- Sont également repris : les éléments de rémunération en vigueur
-- (`contract_pay_components`) et les conventions collectives applicables
-- (`contract_collective_agreements`). L'ancienneté, elle, se reconstitue par la
-- chaîne `previous_contract_id`, que le moteur suit déjà.

create or replace function fn_amend_contract(
  p_contract       uuid,
  p_effective_date date,
  p_changes        jsonb,
  p_reason         text
) returns jsonb language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  c            contracts%rowtype;
  v_changes    jsonb;
  v_payload    jsonb;
  v_new_id     uuid := extensions.gen_random_uuid();
  v_components int;
  v_cbas       int;
begin
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Un avenant porte son motif : indiquez-le.';
  end if;

  -- `for update` : deux avenants simultanés sur le même contrat s'excluent.
  select * into c from contracts where id = p_contract for update;
  if c.id is null then
    raise exception 'Contrat introuvable : %', p_contract;
  end if;
  if not can_manage_company(c.company_id) then
    raise exception 'Accès refusé : seul un gestionnaire de la société peut établir un avenant.';
  end if;
  if c.status <> 'active' then
    raise exception 'Seul un contrat en cours peut faire l''objet d''un avenant. '
                    'Celui-ci est au statut « % ».', c.status;
  end if;
  if p_effective_date <= c.start_date then
    raise exception 'La prise d''effet (%) doit être postérieure au début du contrat (%). '
                    'Un avenant ne réécrit pas le passé : pour corriger une erreur de saisie, '
                    'modifiez le contrat lui-même.', p_effective_date, c.start_date;
  end if;
  if c.end_date is not null and p_effective_date > c.end_date then
    raise exception 'La prise d''effet (%) est postérieure à la fin du contrat (%).',
                    p_effective_date, c.end_date;
  end if;

  -- Ce que l'appelant n'a pas le droit de changer par un avenant : l'identité de
  -- la ligne, le salarié, la société, et la mécanique de versionnement.
  v_changes := coalesce(p_changes, '{}'::jsonb)
               - 'id' - 'employee_id' - 'company_id' - 'version'
               - 'previous_contract_id' - 'created_at' - 'is_part_time';

  if v_changes = '{}'::jsonb then
    raise exception 'Aucune modification fournie : un avenant qui ne change rien n''en est pas un.';
  end if;

  -- 2.a — Clôture de l'ancien, la veille de la prise d'effet.
  update contracts
     set status   = 'ended',
         end_date = p_effective_date - 1
   where id = c.id;

  -- 2.b — Le nouveau, construit depuis l'ancien puis modifié.
  v_payload := to_jsonb(c)
               || v_changes
               || jsonb_build_object(
                    'id', v_new_id,
                    'previous_contract_id', c.id,
                    'version', c.version + 1,
                    'start_date', p_effective_date,
                    'status', 'active',
                    'created_at', now(),
                    -- Un avenant se signe : la nouvelle version part non signée,
                    -- et le moteur de vigilance le rappellera.
                    'signed_at', null);

  insert into contracts select (jsonb_populate_record(null::contracts, v_payload)).*;

  -- 2.c — Les clauses de rémunération en vigueur suivent.
  insert into contract_pay_components (
    contract_id, company_id, kind, code, label, amount, rate_pct, basis,
    periodicity, in_salary_reference, is_taxable, is_contributory,
    valid_from, valid_to, note, benefit_type_id)
  select v_new_id, company_id, kind, code, label, amount, rate_pct, basis,
         periodicity, in_salary_reference, is_taxable, is_contributory,
         greatest(valid_from, p_effective_date), valid_to, note, benefit_type_id
  from contract_pay_components
  where contract_id = c.id
    and (valid_to is null or valid_to > p_effective_date);
  get diagnostics v_components = row_count;

  -- 2.d — Les conventions applicables aussi.
  insert into contract_collective_agreements (
    contract_id, collective_agreement_id, valid_from, valid_to, note)
  select v_new_id, collective_agreement_id,
         greatest(valid_from, p_effective_date), valid_to, note
  from contract_collective_agreements
  where contract_id = c.id
    and (valid_to is null or valid_to > p_effective_date);
  get diagnostics v_cbas = row_count;

  -- 2.e — La trace.
  insert into contract_amendments (contract_id, company_id, effective_date,
                                   reason, changes, created_by)
  values (v_new_id, c.company_id, p_effective_date, p_reason,
          jsonb_build_object('from_contract', c.id, 'applied', v_changes),
          auth.uid());

  return jsonb_build_object(
    'ok', true,
    'previous_contract_id', c.id,
    'previous_end_date', p_effective_date - 1,
    'new_contract_id', v_new_id,
    'version', c.version + 1,
    'effective_date', p_effective_date,
    'applied', v_changes,
    'pay_components_carried', v_components,
    'collective_agreements_carried', v_cbas,
    'message', 'Avenant établi. Le nouveau contrat reprend toutes les clauses de '
               'l''ancien ; il reste à signer.');
end $$;

comment on function fn_amend_contract(uuid, date, jsonb, text) is
  'Établit un avenant : clôt le contrat en cours la veille de la prise d''effet et en crée un nouveau qui reprend toutes ses clauses, ses éléments de rémunération et ses conventions. La reprise passe par to_jsonb pour qu''aucune colonne ne soit oubliée.';

revoke execute on function fn_amend_contract(uuid, date, jsonb, text) from public, anon;
grant  execute on function fn_amend_contract(uuid, date, jsonb, text) to authenticated;

-- ===========================================================================
-- 3. Recherche par nom : deux index, deux usages
-- ===========================================================================
-- Un index fonctionnel sur `upper(last_name)` sert l'égalité et le **préfixe** —
-- « tous les salariés dont le nom commence par MEY ». Il ne sert PAS une
-- recherche infixe `%mey%`, qu'aucun index B-tree ne peut satisfaire.
--
-- Or c'est précisément une recherche infixe que `fn_employee_rows` effectue
-- (`ilike '%' || p_search || '%'`). Poser le seul index fonctionnel aurait donc
-- laissé la requête réelle sans index, tout en donnant l'impression du
-- contraire. D'où les deux : le fonctionnel pour l'égalité et le préfixe, un
-- index trigramme GIN pour l'infixe.

create index if not exists idx_employees_upper_last_name
  on employees (upper(last_name));
create index if not exists idx_employees_upper_first_name
  on employees (upper(first_name));

comment on index idx_employees_upper_last_name is
  'Recherche insensible à la casse sur le nom : égalité et préfixe. Pour une recherche infixe, c''est l''index trigramme qui sert.';

create extension if not exists pg_trgm with schema extensions;

create index if not exists idx_employees_last_name_trgm
  on employees using gin (last_name extensions.gin_trgm_ops);
create index if not exists idx_employees_first_name_trgm
  on employees using gin (first_name extensions.gin_trgm_ops);

comment on index idx_employees_last_name_trgm is
  'Sert la recherche infixe insensible à la casse de fn_employee_rows (ilike ''%…%''), qu''aucun index B-tree ne peut satisfaire.';

-- Sociétés et sites : mêmes usages, même traitement.
create index if not exists idx_companies_upper_legal_name
  on companies (upper(legal_name));
create index if not exists idx_client_sites_upper_name
  on client_sites (upper(name));

-- ===========================================================================
-- 4. Index de recherche textuelle : délibérément aucun
-- ===========================================================================
-- La consigne les réserve au besoin métier avéré. Il n'y en a pas aujourd'hui :
-- aucun écran ne fait de recherche plein texte sur `job_description`,
-- `absences.comment` ou `compliance_alerts.detail`. Un index GIN `tsvector` sur
-- ces colonnes coûterait de l'écriture et de l'espace pour servir une requête
-- que personne n'écrit.
--
-- Le jour où un écran cherchera dans les descriptions de poste, la ligne est
-- prête à décommenter — avec la configuration linguistique qu'il faudra
-- trancher, le corpus étant trilingue :
--
--   create index idx_contracts_job_description_fts
--     on contracts using gin (to_tsvector('french', coalesce(job_description, '')));
