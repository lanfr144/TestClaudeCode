-- 44b. Portabilité : import du référentiel légal et des CCT.
--
-- Le pendant de 44a. L'import reconnaît les lignes par clés naturelles
-- (`param_key`, `code`, dates de validité) et non par identifiant technique :
-- recharger un référentiel déjà en place ne doit rien dupliquer. Les cinq
-- correctifs 45 à 45e affinent cette reconnaissance.

set search_path = public, extensions;

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
    raise exception 'Import refuse : reserve a l''administrateur de l''organisation.';
  end if;
  if p_mode not in ('skip_existing','replace') then
    raise exception 'Mode inconnu : % (attendu skip_existing ou replace)', p_mode;
  end if;
  if p_document ->> 'format' is distinct from 'luxrh.export/1' then
    raise exception 'Format non reconnu : %. Attendu luxrh.export/1.',
                    coalesce(p_document ->> 'format', 'absent');
  end if;
  if p_document ->> 'kind' is distinct from 'referential' then
    raise exception 'Ce document est un export « % », pas un referentiel.',
                    coalesce(p_document ->> 'kind', 'sans genre');
  end if;

  data := p_document -> 'payload';

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
               (ligne ->> 'value_num')::numeric, ligne ->> 'value_text', ligne -> 'value_json',
               ligne ->> 'unit', (ligne ->> 'valid_from')::date, (ligne ->> 'valid_to')::date,
               (ligne ->> 'index_ref')::numeric, ligne ->> 'source', ligne ->> 'legal_ref',
               ligne ->> 'note', ligne ->> 'derived_from_key',
               (ligne ->> 'derived_factor')::numeric, auth.uid();
      exception when others then
        rejets := rejets || format('legal_parameters %s au %s : %s',
                                   ligne ->> 'param_key', ligne ->> 'valid_from', sqlerrm);
        ajoutes := greatest(ajoutes - 1, 0);
      end;
    end if;
  end loop;

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
             (select array_agg((value #>> '{}')::residency_kind)
                from jsonb_array_elements(coalesce(ligne -> 'applies_to_residency', '[]'::jsonb))),
             (ligne ->> 'alert_days_before')::integer, ligne ->> 'legal_ref', ligne ->> 'note';
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'benefit_types', '[]'::jsonb))
  loop
    if exists (select 1 from benefit_types where code = ligne ->> 'code') then
      ignores := ignores + 1;
    else
      insert into benefit_types (code, label, valuation_method, is_taxable, is_contributory,
                                 valuation_params, legal_ref, note)
      values (ligne ->> 'code', ligne ->> 'label', ligne ->> 'valuation_method',
              (ligne ->> 'is_taxable')::boolean, (ligne ->> 'is_contributory')::boolean,
              ligne -> 'valuation_params', ligne ->> 'legal_ref', ligne ->> 'note');
      ajoutes := ajoutes + 1;
    end if;
  end loop;

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

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'collective_agreements', '[]'::jsonb))
  loop
    if exists (select 1 from collective_agreements
                where organization_id = org and code = ligne ->> 'code'
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
    select id into cba from collective_agreements
     where organization_id = org and code = ligne ->> 'collective_agreement_code'
     order by valid_from desc limit 1;
    if cba is null then
      rejets := rejets || format('cba_rules : CCT « %s » inconnue',
                                 ligne ->> 'collective_agreement_code');
    elsif exists (select 1 from cba_rules
                   where collective_agreement_id = cba
                     and block = (ligne ->> 'block')::cba_block) then
      if p_mode = 'replace' then
        update cba_rules set rules = ligne -> 'rules',
                             is_complete = (ligne ->> 'is_complete')::boolean, updated_at = now()
         where collective_agreement_id = cba and block = (ligne ->> 'block')::cba_block;
        remplaces := remplaces + 1;
      else
        ignores := ignores + 1;
      end if;
    else
      insert into cba_rules (collective_agreement_id, block, rules, is_complete)
      values (cba, (ligne ->> 'block')::cba_block, ligne -> 'rules',
              (ligne ->> 'is_complete')::boolean);
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'cba_salary_grids', '[]'::jsonb))
  loop
    select id into cba from collective_agreements
     where organization_id = org and code = ligne ->> 'collective_agreement_code'
     order by valid_from desc limit 1;
    if cba is null then
      rejets := rejets || format('cba_salary_grids : CCT « %s » inconnue',
                                 ligne ->> 'collective_agreement_code');
    elsif exists (select 1 from cba_salary_grids
                   where collective_agreement_id = cba and category = ligne ->> 'category'
                     and seniority_from_years is not distinct from
                         (ligne ->> 'seniority_from_years')::integer) then
      ignores := ignores + 1;
    else
      insert into cba_salary_grids (collective_agreement_id, category, seniority_from_years,
                                    seniority_to_years, monthly_amount, index_ref)
      values (cba, ligne ->> 'category', (ligne ->> 'seniority_from_years')::integer,
              (ligne ->> 'seniority_to_years')::integer, (ligne ->> 'monthly_amount')::numeric,
              (ligne ->> 'index_ref')::numeric);
      ajoutes := ajoutes + 1;
    end if;
  end loop;

  for ligne in select * from jsonb_array_elements(coalesce(data -> 'public_holidays', '[]'::jsonb))
  loop
    cba := null;
    if ligne ->> 'collective_agreement_code' is not null then
      select id into cba from collective_agreements
       where organization_id = org and code = ligne ->> 'collective_agreement_code'
       order by valid_from desc limit 1;
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
    'message',   format('%s ajoutes, %s remplaces, %s deja presents, %s rejetes.',
                        ajoutes, remplaces, ignores, coalesce(array_length(rejets, 1), 0)));
end $$;

comment on function fn_import_referential(jsonb, text) is
  'Repeuple le referentiel d''une nouvelle implementation a partir d''un export.';

grant execute on function fn_import_referential(jsonb, text) to authenticated;
