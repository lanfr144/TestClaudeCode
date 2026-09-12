-- 44a. Portabilité : export des données personnelles et du référentiel.
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
--
-- Cette migration ne porte que les exports. L'import du référentiel est en 44b,
-- et cinq correctifs le suivent (45 à 45e) : CCT partagées, ancienneté numérique,
-- null JSON, comptage des lignes imbriquées. Il a existé un fichier « 44 »
-- récapitulatif écrit après coup, qui fondait 44a et 44b en un seul bloc ; il a
-- été retiré parce que `db push` l'aurait rejoué et aurait écrasé ces correctifs.
-- Une migration appliquée ne se réécrit pas, même pour la rendre plus lisible.

set search_path = public, extensions;

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
create policy export_log_read on export_log for select using (organization_id = auth_org_id());

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
    raise exception 'Table % hors du perimetre exportable', p_table;
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(t) order by t::text), ''[]''::jsonb) '
    'from %I t where t.%I = $1', p_table, p_column)
  into v using p_value;

  return v;
end $$;

revoke all on function fn_rows_json(text, text, uuid) from public, anon, authenticated;

create or replace function fn_payload_rows(p_payload jsonb)
returns integer language sql immutable as $$
  select coalesce(sum(n), 0)::integer from (
    select case jsonb_typeof(value)
             when 'array'  then jsonb_array_length(value)
             when 'object' then fn_payload_rows(value)
             else 0 end as n
      from jsonb_each(p_payload)
     where jsonb_typeof(p_payload) = 'object'
  ) t;
$$;

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
    raise exception 'Salarie introuvable : %', p_employee;
  end if;

  if not (is_self_employee(p_employee) or can_manage_company(emp.company_id)) then
    raise exception 'Export refuse : vous n''avez pas acces a ce dossier.';
  end if;

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
    'format', 'luxrh.export/1', 'kind', 'employee',
    'exported_at', now(), 'payload', payload);
end $$;

comment on function fn_export_employee(uuid) is
  'RGPD art. 15 et 20 : dossier complet d''un salarie, champs chiffres rendus en clair.';

create or replace function fn_export_self()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  emp uuid;
begin
  select id into emp from employees where user_id = auth.uid() limit 1;
  if emp is null then
    raise exception 'Aucun dossier salarie n''est rattache a votre compte.';
  end if;
  return fn_export_employee(emp);
end $$;

create or replace function fn_export_company(p_company uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  cie     companies;
  payload jsonb;
begin
  select * into cie from companies where id = p_company;
  if not found then
    raise exception 'Societe introuvable : %', p_company;
  end if;
  if not can_manage_company(p_company) then
    raise exception 'Export refuse : vous ne gerez pas cette societe.';
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
    'format', 'luxrh.export/1', 'kind', 'company',
    'exported_at', now(), 'payload', payload);
end $$;

comment on function fn_export_company(uuid) is
  'Reversibilite : dossier complet d''une societe, salaries inclus.';

create or replace function fn_export_organization()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  org     organizations;
  payload jsonb;
begin
  select * into org from organizations where id = auth_org_id();
  if not found then
    raise exception 'Aucune organisation rattachee a votre compte.';
  end if;
  if not is_org_admin() then
    raise exception 'Export refuse : reserve a l''administrateur de l''organisation.';
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
    'format', 'luxrh.export/1', 'kind', 'organization',
    'exported_at', now(), 'payload', payload);
end $$;

comment on function fn_export_organization() is
  'Reversibilite : la fiduciaire emporte l''integralite de ses dossiers.';

create or replace function fn_export_referential()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  payload jsonb;
begin
  if auth_org_id() is null then
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
                        (select coalesce(jsonb_agg(to_jsonb(t) - 'id' - 'organization_id' - 'supersedes_id'
                                                     - 'created_at'
                                         order by t.code, t.valid_from), '[]'::jsonb)
                           from collective_agreements t
                          where t.organization_id = auth_org_id()),
    'cba_rules',        (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id' - 'updated_at')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by a.code, t.block::text), '[]'::jsonb)
                           from cba_rules t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id = auth_org_id()),
    'cba_salary_grids', (select coalesce(jsonb_agg(
                                  (to_jsonb(t) - 'id' - 'collective_agreement_id')
                                  || jsonb_build_object('collective_agreement_code', a.code)
                                  order by a.code, t.category, t.seniority_from_years), '[]'::jsonb)
                           from cba_salary_grids t
                           join collective_agreements a on a.id = t.collective_agreement_id
                          where a.organization_id = auth_org_id()));

  insert into export_log (organization_id, requested_by, subject_kind, row_count, byte_size)
  values (auth_org_id(), auth.uid(), 'referential',
          fn_payload_rows(payload), length(payload::text));

  return jsonb_build_object(
    'format', 'luxrh.export/1', 'kind', 'referential',
    'exported_at', now(), 'payload', payload);
end $$;

comment on function fn_export_referential() is
  'Transmission du savoir : referentiel legal et CCT, en cles naturelles.';

grant execute on function fn_export_employee(uuid)  to authenticated;
grant execute on function fn_export_self()          to authenticated;
grant execute on function fn_export_company(uuid)   to authenticated;
grant execute on function fn_export_organization()  to authenticated;
grant execute on function fn_export_referential()   to authenticated;
