
-- =========================================================================
--  Un document a une durée de validité et, parfois, une obligation de remise.
--  Un extrait de casier judiciaire périmé ou un permis de travail expiré sont
--  des risques de conformité, pas des détails d'archivage.
-- =========================================================================
create type document_stage as enum ('pre_hire', 'during_contract', 'end_of_contract');

create table document_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  label text not null,
  stage document_stage not null default 'during_contract',
  validity_months int,                       -- null = sans péremption
  is_mandatory boolean not null default false,
  applies_to_residency residency_kind[],     -- null = tous
  alert_days_before int not null default 30,
  legal_ref text,
  note text
);

alter table documents
  add column if not exists document_type_id uuid references document_types(id) on delete set null,
  add column if not exists issued_on date,
  add column if not exists expires_on date,
  add column if not exists delivered_at date;

create index if not exists documents_type_idx on documents(document_type_id);
create index if not exists documents_expiry_idx on documents(company_id, expires_on);

alter table document_types enable row level security;
create policy doc_types_read on document_types for select to authenticated using (true);
create policy doc_types_ins on document_types for insert to authenticated with check (is_org_admin());
create policy doc_types_upd on document_types for update to authenticated
  using (is_org_admin()) with check (is_org_admin());
create policy doc_types_del on document_types for delete to authenticated using (is_org_admin());

insert into document_types
  (code, label, stage, validity_months, is_mandatory, applies_to_residency, alert_days_before, legal_ref, note)
values
('criminal_record','Extrait de casier judiciaire','pre_hire', 6, false, null, 30, null,
 'Valable six mois à compter de sa délivrance.'),
('work_permit','Autorisation de travail','pre_hire', null, true,
 null, 60, 'art. L.572-1',
 'Requise pour les ressortissants de pays tiers. La date d''expiration est celle du titre.'),
('medical_hiring','Examen médical d''embauche','pre_hire', null, true, null, 30, 'art. L.326-1',
 'Préalable à l''embauche ou dans les deux mois pour les postes non à risque.'),
('medical_periodic','Visite médicale périodique','during_contract', 24, true, null, 45, 'art. L.326-4', null),
('medical_certificate','Certificat d''incapacité de travail','during_contract', null, false, null, 0,
 'art. L.121-6', 'Original à transmettre par voie postale, même après dépôt numérique.'),
('signed_contract','Contrat signé','during_contract', null, true, null, 15, 'art. L.121-4', null),
('tax_card','Fiche de retenue d''impôt','during_contract', 12, true, null, 30, null, null),
('final_settlement','Reçu pour solde de tout compte','end_of_contract', null, true, null, 0, 'art. L.125-8',
 'À remettre au salarié à la fin du contrat.'),
('work_certificate','Certificat de travail','end_of_contract', null, true, null, 0, 'art. L.125-9',
 'Mentionne exclusivement la nature et la durée de l''emploi, sauf demande contraire du salarié.'),
('adem_declaration','Déclaration de sortie ADEM/CCSS','end_of_contract', null, true, null, 0, null, null),
('leave_balance_statement','Décompte des congés restants','end_of_contract', null, true, null, 0, null, null);

-- La date de péremption se déduit de la délivrance et de la durée de validité.
create or replace function fn_document_expiry()
returns trigger language plpgsql set search_path = public as $$
declare months int;
begin
  if new.expires_on is null and new.issued_on is not null and new.document_type_id is not null then
    select validity_months into months from document_types where id = new.document_type_id;
    if months is not null then
      new.expires_on := (new.issued_on + (months || ' months')::interval)::date;
    end if;
  end if;
  return new;
end $$;

create trigger documents_expiry before insert or update of issued_on, document_type_id on documents
  for each row execute function fn_document_expiry();

-- Documents de fin de contrat : ce qui reste à remettre.
create or replace function fn_end_of_contract_documents(p_contract uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare c contracts; term contract_terminations; out_j jsonb := '[]'::jsonb; dt record; doc documents;
begin
  select * into c from contracts where id = p_contract;
  if c.id is null then raise exception 'Contrat introuvable'; end if;
  if not has_company_access(c.company_id) then raise exception 'Accès refusé'; end if;

  select * into term from contract_terminations where contract_id = p_contract
  order by notified_on desc limit 1;

  for dt in select * from document_types where stage = 'end_of_contract' and is_mandatory order by label loop
    select * into doc from documents
    where employee_id = c.employee_id and document_type_id = dt.id
    order by created_at desc limit 1;

    out_j := out_j || jsonb_build_object(
      'code', dt.code, 'label', dt.label,
      'delivered', doc.id is not null,
      'delivered_at', doc.delivered_at,
      'document_id', doc.id,
      'legal_ref', dt.legal_ref, 'note', dt.note);
    doc := null;
  end loop;

  return jsonb_build_object(
    'contract_id', p_contract,
    'terminated', term.id is not null,
    'notice_end', term.notice_end,
    'documents', out_j,
    'outstanding', (select count(*) from jsonb_array_elements(out_j) x
                    where not (x->>'delivered')::boolean));
end $$;

-- Paramètres de vigilance sur l'absentéisme.
insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, legal_ref, note)
values
('leave','sick_excessive_window_months','Fenêtre d''appréciation de l''absentéisme maladie',
 12,'mois','2019-01-01','produit',null,
 'Paramètre de vigilance, non légal : sert à repérer les situations à examiner.'),
('leave','sick_excessive_days_threshold','Seuil d''absentéisme maladie déclenchant un examen',
 78,'jours','2019-01-01','produit',null,
 'Au-delà, et une fois la protection de 26 semaines expirée, un licenciement devient '
 'juridiquement envisageable. L''outil signale, il ne décide pas.');

revoke execute on function fn_end_of_contract_documents(uuid) from anon, public;
grant execute on function fn_end_of_contract_documents(uuid) to authenticated;
