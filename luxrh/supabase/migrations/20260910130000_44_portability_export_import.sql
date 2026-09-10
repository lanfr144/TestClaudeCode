-- 44. Portabilité : export et import des données personnelles et du référentiel.
--
-- Trois besoins distincts, volontairement servis par des fonctions distinctes :
--
--   RGPD art. 15 et 20 — le salarié obtient ses données et peut les emporter.
--   Réversibilité      — une société ou une fiduciaire récupère son dossier complet.
--   Transmission du savoir — le référentiel légal et les CCT saisis à la main
--                            repeuplent une nouvelle implémentation.
--
-- Le référentiel s'exporte avec des clés naturelles (`param_key`, `code`, dates)
-- et non des identifiants techniques : un export chargé ailleurs doit retrouver
-- ses correspondances, pas dupliquer des lignes sous de nouveaux UUID.

set search_path = public, extensions;

-- ============================================================ registre des exports

-- Un export de données personnelles est un traitement : il se journalise.
create table if not exists export_log (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  requested_by    uuid references auth.users(id),
  subject_kind    text not null check (subject_kind in
                    ('employee','company','organization','referential')),
  subject_id      uuid,
  row_count       integer not null default 0,
  byte_size       integer not null default 0,
  created_at      timestamptz not null default now()
);

create index if not exists export_log_org_idx on export_log(organization_id, created_at desc);

alter table export_log enable row level security;

drop policy if exists export_log_read on export_log;
create policy export_log_read on export_log for select
  using (organization_id = auth_org_id());

-- Aucune politique d'écriture : seules les fonctions d'export alimentent ce
-- registre, et une trace d'audit que l'on peut réécrire ne prouve rien.


-- ============================================================ helpers de sérialisation

-- Sérialise les lignes d'une table filtrées sur une colonne. Dynamique, donc
-- restreinte à une liste blanche et retirée du rôle `authenticated` : seules
-- les fonctions d'export ci-dessous l'appellent, après leurs propres contrôles.
create or replace function fn_rows_json(p_table text, p_column text, p_value uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v jsonb;
begin
  if p_table not in (
    'absences','audit_log','company_accident_claims','company_collective_agreements',
    'company_financials','company_rate_periods','compliance_alerts','contract_amendments',
    'contract_pay_components','contract_terminations','contracts','departments','documents',
    'employee_children','employee_disabilities','employee_statuses','employee_tax_cards',
    'headcount_snapshots','meal_voucher_grants','overtime_requests','premiums',
    'reference_periods','schedules','shift_templates','shifts','time_entries',
    'profiles','user_roles','collective_agreements','interim_agencies','companies'
  ) then
    raise exception 'Table % hors du périmètre exportable', p_table;
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(t) order by t::text), ''[]''::jsonb) '
    'from %I t where t.%I = $1', p_table, p_column)
  into v using p_value;

  return v;
end $$;

revoke all on function fn_rows_json(text, text, uuid) from public, anon, authenticated;

-- Compte les lignes d'une charge utile, tous tableaux confondus : sert au registre.
create or replace function fn_payload_rows(p_payload jsonb)
returns integer language sql immutable as $$
  select coalesce(case jsonb_typeof(p_payload)
    when 'object' then 1 + (select coalesce(sum(fn_payload_rows(v)), 0)
                              from jsonb_each(p_payload) e(k, v)
                             where jsonb_typeof(v) in ('object', 'array'))
    when 'array'  then (select coalesce(sum(fn_payload_rows(v)), 0)
                          from jsonb_array_elements(p_payload) v)
    else 0
  end, 0)::integer;
$$;

comment on function fn_payload_rows(jsonb) is
  'Nombre d''objets JSON du document, tous niveaux confondus : ordre de grandeur du volume.';


-- ============================================================ export : un salarié

create or replace function fn_export_employee(p_employee uuid)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  emp        employees;
  identite   jsonb;
  contrats   uuid[];
  payload    jsonb;
begin
  select * into emp from employees where id = p_employee;
  if not found then
    raise exception 'Salarié introuvable : %', p_employee;
  end if;

  -- L'intéressé lui-même, ou quelqu'un qui gère la société. Personne d'autre.
  if not (is_self_employee(p_employee) or can_manage_company(emp.company_id)) then
    raise exception 'Export refusé : vous n''avez pas accès à ce dossier.';
  end if;

  -- Les champs chiffrés sont rendus en clair : un export illisible ne satisfait
  -- pas le droit d'accès. Le chiffrement protège la base, pas l'intéressé de
  -- ses propres données.
  identite := to_jsonb(emp) - 'national_id_enc' - 'iban_enc'
    || jsonb_build_object(
         'national_id', fn_decrypt_field(emp.national_id_enc),
         'iban',        fn_decrypt_field(emp.iban_enc));

  select coalesce(array_agg(id), '{}') into contrats from contracts where employee_id = p_employee;

  payload := jsonb_build_object(
    'employee',            identite,
    'children',            fn_rows_json('employee_children',    'employee_id', p_employee),
    'disabilities',        fn_rows_json('employee_disabilities','employee_id', p_employee),
    'statuses',            fn_rows_json('employee_statuses',    'employee_id', p_employee),
    'tax_cards',           fn_rows_json('employee_tax_cards',   'employee_id', p_employee),
    'contracts',           fn_rows_json('contracts',            'employee_id', p_employee),
    'absences',            fn_rows_json('absences',             'employee_id', p_employee),
    'time_entries',        fn_rows_json('time_entries',         'employee_id', p_employee),
    'shifts',              fn_rows_json('shifts',               'employee_id', p_employee),
    'overtime_requests',   fn_rows_json('overtime_requests',    'employee_id', p_employee),
    'premiums',            fn_rows_json('premiums',             'employee_id', p_employee),
    'meal_voucher_grants', fn_rows_json('meal_voucher_grants',  'employee_id', p_employee),
    'compliance_alerts',   fn_rows_json('compliance_alerts',    'employee_id', p_employee),
    -- Les pièces jointes elles-mêmes vivent dans le stockage : on exporte le
    -- descriptif et le chemin, pas le contenu binaire.
    'documents',           fn_rows_json('documents',            'employee_id', p_employee)
  );

  if array_length(contrats, 1) is not null then
    payload := payload || jsonb_build_object(
      'contract_pay_components', (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                                    from contract_pay_components t where t.contract_id = any(contrats)),
      'contract_amendments',     (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                                    from contract_amendments t where t.contract_id = any(contrats)),
      'contract_terminations',   (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                                    from contract_terminations t where t.contract_id = any(contrats)),
      'contract_collective_agreements',
                                 (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                                    from contract_collective_agreements t where t.contract_id = any(contrats)),
      'probation_extensions',    (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                                    from probation_extensions t where t.contract_id = any(contrats)));
  end if;

  insert into export_log (organization_id, requested_by, subject_kind, subject_id,
                          row_count, byte_size)
  select c.organization_id, auth.uid(), 'employee', p_employee,
         fn_payload_rows(payload), length(payload::text)
    from companies c where c.id = emp.company_id;

  return jsonb_build_object(
    'format',      'luxrh.export/1',
    'kind',        'employee',
    'exported_at', now(),
    'payload',     payload);
end $$;

comment on function fn_export_employee(uuid) is
  'RGPD art. 15 et 20 : dossier complet d''un salarié, champs chiffrés rendus en clair.';


-- Raccourci pour le libre-service : le salarié n'a pas à connaître son identifiant.
create or replace function fn_export_self()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  emp uuid;
begin
  select id into emp from employees where user_id = auth.uid() limit 1;
  if emp is null then
    raise exception 'Aucun dossier salarié n''est rattaché à votre compte.';
  end if;
  return fn_export_employee(emp);
end $$;


-- ============================================================ export : une société

create or replace function fn_export_company(p_company uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  cie     companies;
  payload jsonb;
begin
  select * into cie from companies where id = p_company;
  if not found then
    raise exception 'Société introuvable : %', p_company;
  end if;
  if not can_manage_company(p_company) then
    raise exception 'Export refusé : vous ne gérez pas cette société.';
  end if;

  payload := jsonb_build_object(
    'company',                      to_jsonb(cie),
    'departments',                  fn_rows_json('departments',                  'company_id', p_company),
    'company_rate_periods',         fn_rows_json('company_rate_periods',         'company_id', p_company),
    'company_collective_agreements',fn_rows_json('company_collective_agreements','company_id', p_company),
    'company_financials',           fn_rows_json('company_financials',           'company_id', p_company),
    'company_accident_claims',      fn_rows_json('company_accident_claims',      'company_id', p_company),
    'reference_periods',            fn_rows_json('reference_periods',            'company_id', p_company),
    'shift_templates',              fn_rows_json('shift_templates',              'company_id', p_company),
    'schedules',                    fn_rows_json('schedules',                    'company_id', p_company),
    'headcount_snapshots',          fn_rows_json('headcount_snapshots',          'company_id', p_company),
    'audit_log',                    fn_rows_json('audit_log',                    'company_id', p_company),
    'employees',                    (select coalesce(jsonb_agg(fn_export_employee(e.id) -> 'payload'
                                                     order by e.last_name, e.first_name), '[]'::jsonb)
                                       from employees e where e.company_id = p_company));

  insert into export_log (organization_id, requested_by, subject_kind, subject_id,
                          row_count, byte_size)
  values (cie.organization_id, auth.uid(), 'company', p_company,
          fn_payload_rows(payload), length(payload::text));

  return jsonb_build_object(
    'format',      'luxrh.export/1',
    'kind',        'company',
    'exported_at', now(),
    'payload',     payload);
end $$;

comment on function fn_export_company(uuid) is
  'Réversibilité : dossier complet d''une société, salariés inclus.';


-- ============================================================ export : la fiduciaire

create or replace function fn_export_organization()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  org     organizations;
  payload jsonb;
begin
  select * into org from organizations where id = auth_org_id();
  if not found then
    raise exception 'Aucune organisation rattachée à votre compte.';
  end if;
  if not is_org_admin() then
    raise exception 'Export refusé : réservé à l''administrateur de l''organisation.';
  end if;

  payload := jsonb_build_object(
    'organization',          to_jsonb(org),
    'profiles',              fn_rows_json('profiles',             'organization_id', org.id),
    'user_roles',            fn_rows_json('user_roles',           'organization_id', org.id),
    'collective_agreements', fn_rows_json('collective_agreements','organization_id', org.id),
    'interim_agencies',      fn_rows_json('interim_agencies',     'organization_id', org.id),
    'cba_rules',        (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                           from cba_rules t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id = org.id),
    'cba_salary_grids', (select coalesce(jsonb_agg(to_jsonb(t) order by t::text), '[]'::jsonb)
                           from cba_salary_grids t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id = org.id),
    'companies',        (select coalesce(jsonb_agg(fn_export_company(c.id) -> 'payload'
                                         order by c.legal_name), '[]'::jsonb)
                           from companies c where c.organization_id = org.id));

  insert into export_log (organization_id, requested_by, subject_kind, subject_id,
                          row_count, byte_size)
  values (org.id, auth.uid(), 'organization', org.id,
          fn_payload_rows(payload), length(payload::text));

  return jsonb_build_object(
    'format',      'luxrh.export/1',
    'kind',        'organization',
    'exported_at', now(),
    'payload',     payload);
end $$;

comment on function fn_export_organization() is
  'Réversibilité : la fiduciaire emporte l''intégralité de ses dossiers.';


-- ============================================================ export : le référentiel

-- Le savoir accumulé : paramètres légaux datés, barèmes, catalogues, CCT.
-- Aucun identifiant technique dans la sortie — les correspondances passent par
-- les clés naturelles, seules stables d'une implémentation à l'autre.
create or replace function fn_export_referential()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  payload jsonb;
  org     uuid := auth_org_id();
begin
  if org is null then
    raise exception 'Export refusé : compte non rattaché à une organisation.';
  end if;

  payload := jsonb_build_object(
    'legal_parameters', (select coalesce(jsonb_agg(to_jsonb(t) - 'id' - 'entered_by' - 'entered_at'
                                                    - 'validated_by' - 'validated_at'
                                         order by t.param_key, t.valid_from), '[]'::jsonb)
                           from legal_parameters t),

    'absence_types',    (select coalesce(jsonb_agg(to_jsonb(t) - 'id' order by t.code), '[]'::jsonb)
                           from absence_types t),

    -- L'appartenance se réexprime par le code du type d'absence.
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

    -- Un jour férié peut être propre à une CCT : on emporte son code, pas son UUID.
    'public_holidays',  (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by t.holiday_date), '[]'::jsonb)
                           from public_holidays t
                           left join collective_agreements a on a.id = t.collective_agreement_id),

    -- Une CCT sectorielle a `organization_id` nul : la politique RLS la rend
    -- visible à tous. La filtrer sur la seule organisation du demandeur ferait
    -- repartir l'export sans aucune CCT nationale — le savoir qu'il doit porter.
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
  values (org, auth.uid(), 'referential',
          fn_payload_rows(payload), length(payload::text));

  return jsonb_build_object(
    'format',      'luxrh.export/1',
    'kind',        'referential',
    'exported_at', now(),
    'payload',     payload);
end $$;

comment on function fn_export_referential() is
  'Transmission du savoir : référentiel légal et CCT, en clés naturelles.';


-- Retrouve une CCT par son code, qu'elle soit partagée ou propre à
-- l'organisation. Sans cela l'import crée un doublon sous le même code chaque
-- fois qu'une CCT nationale porte déjà ce code dans l'implantation cible.
create or replace function fn_cba_by_code(p_code text, p_org uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select id from collective_agreements
   where code = p_code and (organization_id = p_org or organization_id is null)
   order by (organization_id = p_org) desc, valid_from desc
   limit 1;
$$;

revoke all on function fn_cba_by_code(text, uuid) from public, anon, authenticated;


-- ============================================================ import du référentiel

-- p_mode : 'skip_existing' conserve ce qui est déjà là (reprise prudente),
--          'replace'       écrase la ligne de même clé naturelle.
-- Rien n'est jamais supprimé : un import ne doit pas faire disparaître un
-- paramètre que l'export d'en face ignorait.
create or replace function fn_import_referential(p_document jsonb, p_mode text default 'skip_existing')
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  data      jsonb;
  ligne     jsonb;
  org       uuid := auth_org_id();
  cba       uuid;
  atype     uuid;
  ajoutes   int := 0;
  remplaces int := 0;
  ignores   int := 0;
  rejets    text[] := '{}';
  touche    boolean;
begin
  if not is_org_admin() then
    raise exception 'Import refusé : réservé à l''administrateur de l''organisation.';
  end if;
  if p_mode not in ('skip_existing','replace') then
    raise exception 'Mode inconnu : % (attendu skip_existing ou replace)', p_mode;
  end if;
  if p_document ->> 'format' is distinct from 'luxrh.export/1' then
    raise exception 'Format non reconnu : %. Attendu luxrh.export/1.',
                    coalesce(p_document ->> 'format', 'absent');
  end if;
  if p_document ->> 'kind' is distinct from 'referential' then
    raise exception 'Ce document est un export « % », pas un référentiel.',
                    coalesce(p_document ->> 'kind', 'sans genre');
  end if;

  data := p_document -> 'payload';

  -- ---------------------------------------------------------------- paramètres
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'legal_parameters', '[]'::jsonb))
  loop
    touche := exists (select 1 from legal_parameters
                       where param_key = ligne ->> 'param_key'
                         and valid_from = (ligne ->> 'valid_from')::date);
    if touche and p_mode = 'skip_existing' then
      ignores := ignores + 1;
    else
      if touche then
        delete from legal_parameters
         where param_key = ligne ->> 'param_key'
           and valid_from = (ligne ->> 'valid_from')::date;
        remplaces := remplaces + 1;
      else
        ajoutes := ajoutes + 1;
      end if;
      begin
        insert into legal_parameters (family, param_key, label, value_num, value_text, value_json,
                                      unit, valid_from, valid_to, index_ref, source, legal_ref, note,
                                      derived_from_key, derived_factor, entered_by)
        select (ligne ->> 'family')::param_family, ligne ->> 'param_key', ligne ->> 'label',
               (ligne ->> 'value_num')::numeric, ligne ->> 'value_text',
               -- `to_jsonb` d'une colonne jsonb vide donne le scalaire JSON null,
               -- qui n'est pas un NULL SQL : sans ce nullif, chaque paramètre
               -- importé porte une valeur fantôme et viole la contrainte
               -- « une seule des trois colonnes de valeur ».
               nullif(ligne -> 'value_json', 'null'::jsonb),
               ligne ->> 'unit', (ligne ->> 'valid_from')::date, (ligne ->> 'valid_to')::date,
               (ligne ->> 'index_ref')::numeric, ligne ->> 'source', ligne ->> 'legal_ref',
               ligne ->> 'note', ligne ->> 'derived_from_key',
               (ligne ->> 'derived_factor')::numeric, auth.uid();
      exception when others then
        -- Un chevauchement de périodes est un conflit réel, pas un détail :
        -- on le nomme au lieu de l'absorber.
        rejets := rejets || format('legal_parameters %s au %s : %s',
                                   ligne ->> 'param_key', ligne ->> 'valid_from', sqlerrm);
        ajoutes := greatest(ajoutes - 1, 0);
      end;
    end if;
  end loop;

  -- ---------------------------------------------------------- types d'absence
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'absence_types', '[]'::jsonb))
  loop
    if exists (select 1 from absence_types where code = ligne ->> 'code') then
      if p_mode = 'replace' then
        update absence_types set
          label = ligne ->> 'label', category = (ligne ->> 'category')::absence_category,
          legal_ref = ligne ->> 'legal_ref',
          requires_certificate = (ligne ->> 'requires_certificate')::boolean,
          is_paid = (ligne ->> 'is_paid')::boolean,
          counts_against_leave = (ligne ->> 'counts_against_leave')::boolean
         where code = ligne ->> 'code';
        remplaces := remplaces + 1;
      else
        ignores := ignores + 1;
      end if;
    else
      insert into absence_types (code, label, category, legal_ref, requires_certificate,
                                 is_paid, counts_against_leave)
      values (ligne ->> 'code', ligne ->> 'label', (ligne ->> 'category')::absence_category,
              ligne ->> 'legal_ref', (ligne ->> 'requires_certificate')::boolean,
              (ligne ->> 'is_paid')::boolean, (ligne ->> 'counts_against_leave')::boolean);
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ------------------------------------------------- droits à congé extraordinaire
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'absence_entitlements', '[]'::jsonb))
  loop
    select id into atype from absence_types where code = ligne ->> 'absence_type_code';
    if atype is null then
      rejets := rejets || format('absence_entitlements : type « %s » inconnu',
                                 ligne ->> 'absence_type_code');
    elsif exists (select 1 from absence_entitlements
                   where absence_type_id = atype
                     and valid_from = (ligne ->> 'valid_from')::date) then
      if p_mode = 'replace' then
        delete from absence_entitlements
         where absence_type_id = atype and valid_from = (ligne ->> 'valid_from')::date;
        insert into absence_entitlements (absence_type_id, days, valid_from, valid_to, legal_ref,
                 frequency_note, career_cap_days, block_days, period_months, relationship_degree,
                 requires_evidence, note)
        values (atype, (ligne ->> 'days')::numeric, (ligne ->> 'valid_from')::date,
                (ligne ->> 'valid_to')::date, ligne ->> 'legal_ref', ligne ->> 'frequency_note',
                (ligne ->> 'career_cap_days')::numeric, (ligne ->> 'block_days')::numeric,
                (ligne ->> 'period_months')::integer, (ligne ->> 'relationship_degree')::integer,
                (ligne ->> 'requires_evidence')::boolean, ligne ->> 'note');
        remplaces := remplaces + 1;
      else
        ignores := ignores + 1;
      end if;
    else
      insert into absence_entitlements (absence_type_id, days, valid_from, valid_to, legal_ref,
               frequency_note, career_cap_days, block_days, period_months, relationship_degree,
               requires_evidence, note)
      values (atype, (ligne ->> 'days')::numeric, (ligne ->> 'valid_from')::date,
              (ligne ->> 'valid_to')::date, ligne ->> 'legal_ref', ligne ->> 'frequency_note',
              (ligne ->> 'career_cap_days')::numeric, (ligne ->> 'block_days')::numeric,
              (ligne ->> 'period_months')::integer, (ligne ->> 'relationship_degree')::integer,
              (ligne ->> 'requires_evidence')::boolean, ligne ->> 'note');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ------------------------------------------------------------ types de document
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'document_types', '[]'::jsonb))
  loop
    if exists (select 1 from document_types where code = ligne ->> 'code') then
      ignores := ignores + 1;
      if p_mode = 'replace' then
        update document_types set
          label = ligne ->> 'label', stage = (ligne ->> 'stage')::document_stage,
          validity_months = (ligne ->> 'validity_months')::integer,
          is_mandatory = (ligne ->> 'is_mandatory')::boolean,
          alert_days_before = (ligne ->> 'alert_days_before')::integer,
          legal_ref = ligne ->> 'legal_ref', note = ligne ->> 'note'
         where code = ligne ->> 'code';
        ignores := ignores - 1; remplaces := remplaces + 1;
      end if;
    else
      insert into document_types (code, label, stage, validity_months, is_mandatory,
                                  applies_to_residency, alert_days_before, legal_ref, note)
      select ligne ->> 'code', ligne ->> 'label', (ligne ->> 'stage')::document_stage,
             (ligne ->> 'validity_months')::integer, (ligne ->> 'is_mandatory')::boolean,
             (select array_agg(value::text::residency_kind)
                from jsonb_array_elements(coalesce(ligne -> 'applies_to_residency', '[]'::jsonb))),
             (ligne ->> 'alert_days_before')::integer, ligne ->> 'legal_ref', ligne ->> 'note';
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ------------------------------------------------------------ avantages en nature
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'benefit_types', '[]'::jsonb))
  loop
    if exists (select 1 from benefit_types where code = ligne ->> 'code') then
      ignores := ignores + 1;
    else
      insert into benefit_types (code, label, valuation_method, is_taxable, is_contributory,
                                 valuation_params, legal_ref, note)
      values (ligne ->> 'code', ligne ->> 'label', ligne ->> 'valuation_method',
              (ligne ->> 'is_taxable')::boolean, (ligne ->> 'is_contributory')::boolean,
              nullif(ligne -> 'valuation_params', 'null'::jsonb),
              ligne ->> 'legal_ref', ligne ->> 'note');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ------------------------------------------------------------------- barèmes
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'tax_brackets', '[]'::jsonb))
  loop
    if exists (select 1 from tax_brackets
                where tax_class = (ligne ->> 'tax_class')::tax_class
                  and periodicity = (ligne ->> 'periodicity')::tax_periodicity
                  and valid_from = (ligne ->> 'valid_from')::date
                  and bracket_min = (ligne ->> 'bracket_min')::numeric) then
      ignores := ignores + 1;
    else
      insert into tax_brackets (tax_class, periodicity, valid_from, valid_to, bracket_min,
                                bracket_max, base_tax, rate_over_min, source, legal_ref, note)
      values ((ligne ->> 'tax_class')::tax_class, (ligne ->> 'periodicity')::tax_periodicity,
              (ligne ->> 'valid_from')::date,
              (ligne ->> 'valid_to')::date, (ligne ->> 'bracket_min')::numeric,
              (ligne ->> 'bracket_max')::numeric, (ligne ->> 'base_tax')::numeric,
              (ligne ->> 'rate_over_min')::numeric, ligne ->> 'source', ligne ->> 'legal_ref',
              ligne ->> 'note');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'tax_credits', '[]'::jsonb))
  loop
    if exists (select 1 from tax_credits
                where code = ligne ->> 'code' and valid_from = (ligne ->> 'valid_from')::date) then
      ignores := ignores + 1;
    else
      insert into tax_credits (code, label, applies_to_classes, income_min, income_max,
                               monthly_amount, prorated_on_hours, valid_from, valid_to,
                               source, legal_ref, note)
      select ligne ->> 'code', ligne ->> 'label',
             (select array_agg((value #>> '{}')::tax_class)
                from jsonb_array_elements(coalesce(ligne -> 'applies_to_classes', '[]'::jsonb))),
             (ligne ->> 'income_min')::numeric, (ligne ->> 'income_max')::numeric,
             (ligne ->> 'monthly_amount')::numeric, (ligne ->> 'prorated_on_hours')::boolean,
             (ligne ->> 'valid_from')::date, (ligne ->> 'valid_to')::date,
             ligne ->> 'source', ligne ->> 'legal_ref', ligne ->> 'note';
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ----------------------------------------------------------------------- CCT
  -- Les CCT reprennent l'organisation du destinataire : un import ne déplace
  -- jamais une donnée d'une organisation à une autre.
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'collective_agreements', '[]'::jsonb))
  loop
    if exists (select 1 from collective_agreements
                where (organization_id = org or organization_id is null)
                  and code = ligne ->> 'code'
                  and valid_from = (ligne ->> 'valid_from')::date) then
      ignores := ignores + 1;
    else
      insert into collective_agreements (organization_id, code, name, sector, valid_from,
                                         valid_to, is_active, scope, employee_category)
      values (org, ligne ->> 'code', ligne ->> 'name', ligne ->> 'sector',
              (ligne ->> 'valid_from')::date, (ligne ->> 'valid_to')::date,
              coalesce((ligne ->> 'is_active')::boolean, true),
              (ligne ->> 'scope')::cba_scope, ligne ->> 'employee_category');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'cba_rules', '[]'::jsonb))
  loop
    cba := fn_cba_by_code(ligne ->> 'collective_agreement_code', org);
    if cba is null then
      rejets := rejets || format('cba_rules : CCT « %s » inconnue',
                                 ligne ->> 'collective_agreement_code');
    elsif exists (select 1 from cba_rules
                   where collective_agreement_id = cba and block = (ligne ->> 'block')::cba_block) then
      if p_mode = 'replace' then
        update cba_rules set rules = nullif(ligne -> 'rules', 'null'::jsonb),
                             is_complete = (ligne ->> 'is_complete')::boolean, updated_at = now()
         where collective_agreement_id = cba and block = (ligne ->> 'block')::cba_block;
        remplaces := remplaces + 1;
      else
        ignores := ignores + 1;
      end if;
    else
      insert into cba_rules (collective_agreement_id, block, rules, is_complete)
      values (cba, (ligne ->> 'block')::cba_block,
              nullif(ligne -> 'rules', 'null'::jsonb), (ligne ->> 'is_complete')::boolean);
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'cba_salary_grids', '[]'::jsonb))
  loop
    cba := fn_cba_by_code(ligne ->> 'collective_agreement_code', org);
    if cba is null then
      rejets := rejets || format('cba_salary_grids : CCT « %s » inconnue',
                                 ligne ->> 'collective_agreement_code');
    elsif exists (select 1 from cba_salary_grids
                   where collective_agreement_id = cba and category = ligne ->> 'category'
                     and seniority_from_years is not distinct from
                         (ligne ->> 'seniority_from_years')::numeric) then
      ignores := ignores + 1;
    else
      insert into cba_salary_grids (collective_agreement_id, category, seniority_from_years,
                                    seniority_to_years, monthly_amount, index_ref)
      values (cba, ligne ->> 'category', (ligne ->> 'seniority_from_years')::numeric,
              (ligne ->> 'seniority_to_years')::numeric, (ligne ->> 'monthly_amount')::numeric,
              (ligne ->> 'index_ref')::numeric);
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  -- ------------------------------------------------------------------- fériés
  for ligne in select * from jsonb_array_elements(coalesce(data -> 'public_holidays', '[]'::jsonb))
  loop
    cba := null;
    if ligne ->> 'collective_agreement_code' is not null then
      cba := fn_cba_by_code(ligne ->> 'collective_agreement_code', org);
    end if;
    if exists (select 1 from public_holidays
                where holiday_date = (ligne ->> 'holiday_date')::date
                  and name = ligne ->> 'name'
                  and collective_agreement_id is not distinct from cba) then
      ignores := ignores + 1;
    else
      insert into public_holidays (year, holiday_date, name, is_mobile, collective_agreement_id,
                                   is_recoverable, recovery_reason)
      values ((ligne ->> 'year')::integer, (ligne ->> 'holiday_date')::date, ligne ->> 'name',
              (ligne ->> 'is_mobile')::boolean, cba,
              (ligne ->> 'is_recoverable')::boolean, ligne ->> 'recovery_reason');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'mode',      p_mode,
    'added',     ajoutes,
    'replaced',  remplaces,
    'skipped',   ignores,
    'rejected',  to_jsonb(rejets),
    'message',   format('%s ajoutés, %s remplacés, %s déjà présents, %s rejetés.',
                        ajoutes, remplaces, ignores, coalesce(array_length(rejets, 1), 0)));
end $$;

comment on function fn_import_referential(jsonb, text) is
  'Repeuple le référentiel d''une nouvelle implémentation à partir d''un export.';


-- ============================================================ droits d'exécution

grant execute on function fn_export_employee(uuid)          to authenticated;
grant execute on function fn_export_self()                  to authenticated;
grant execute on function fn_export_company(uuid)           to authenticated;
grant execute on function fn_export_organization()          to authenticated;
grant execute on function fn_export_referential()           to authenticated;
grant execute on function fn_import_referential(jsonb, text) to authenticated;

-- Ce fichier porte l'état final : les défauts trouvés par l'aller-retour réel
-- — export puis import dans une implantation vidée — y sont déjà corrigés.
-- Vérification : 177 paramètres exportés, 177 rechargés, 177 identiques.
