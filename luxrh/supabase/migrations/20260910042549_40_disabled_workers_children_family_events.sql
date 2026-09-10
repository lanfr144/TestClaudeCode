
-- =========================================================================
--  Travailleurs handicapés : le statut et son taux ouvrent des jours de
--  congé supplémentaires.
-- =========================================================================
create table employee_disabilities (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  rate_pct numeric(5,2) not null check (rate_pct > 0 and rate_pct <= 100),
  recognized_on date,
  authority text,
  extra_leave_days_override numeric(4,1),
  evidence_document_id uuid references documents(id) on delete set null,
  valid_from date not null,
  valid_to date,
  note text,
  created_at timestamptz not null default now(),
  constraint disability_range check (valid_to is null or valid_to > valid_from),
  exclude using gist (employee_id with =, daterange(valid_from, valid_to, '[)') with &&)
);
create index on employee_disabilities(company_id);

alter table employee_disabilities enable row level security;
create policy disability_read on employee_disabilities for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy disability_ins on employee_disabilities for insert to authenticated
  with check (can_manage_company(company_id));
create policy disability_upd on employee_disabilities for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy disability_del on employee_disabilities for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_disabilities after insert or update or delete on employee_disabilities
  for each row execute function fn_audit();

insert into legal_parameters
  (family, param_key, label, value_json, unit, valid_from, source, legal_ref, note)
values
('leave','disabled_extra_leave_scale','Congé supplémentaire du travailleur handicapé',
 '[{"from_rate":30,"days":6,"label":"taux de 30 % et plus"}]'::jsonb,'jours',
 '2019-01-01','Legilux','art. L.233-4',
 'Barème par taux de reconnaissance. À re-vérifier sur la source officielle.'),
('leave','family_reasons_leave_scale','Congé pour raisons familiales par tranche d''âge de l''enfant',
 '[{"from_age":0,"to_age":4,"days":12},{"from_age":4,"to_age":13,"days":18},{"from_age":13,"to_age":18,"days":5}]'::jsonb,
 'jours','2019-01-01','Legilux','art. L.234-51',
 'Nombre de jours par enfant et par tranche d''âge, sur la période de référence. À re-vérifier.');

insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, note)
values
('leave','saint_nicolas_age_max','Âge maximum pour les attentions de fin d''année',
 12,'ans','2019-01-01','produit',
 'Paramètre d''entreprise, non légal : sert à établir la liste des enfants concernés.');

-- =========================================================================
--  Enfants : droits à congé, et attentions de la société (Saint-Nicolas).
--  Le refus des attentions restreint la donnée au strict nécessaire.
-- =========================================================================
create table employee_children (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  first_name text,
  last_name text,
  sex sex_kind,
  birth_date date not null,
  relationship text not null default 'child'
    check (relationship in ('child','adopted','foster','stepchild')),
  is_dependent boolean not null default true,
  privacy_opt_out boolean not null default false,
  adoption_date date,
  note text,
  created_at timestamptz not null default now(),
  constraint privacy_minimises_data check (
    not privacy_opt_out
    or (first_name is null and last_name is null and sex is null and note is null))
);
create index on employee_children(employee_id);
create index on employee_children(company_id);

comment on table employee_children is
  'Le refus des attentions de la société (privacy_opt_out) restreint la donnée à la seule date '
  'de naissance, strictement nécessaire au calcul des droits à congé. Minimisation RGPD.';

create or replace function fn_child_privacy()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.privacy_opt_out then
    new.first_name := null;
    new.last_name := null;
    new.sex := null;
    new.note := null;
  end if;
  return new;
end $$;

create trigger children_privacy before insert or update on employee_children
  for each row execute function fn_child_privacy();

alter table employee_children enable row level security;
create policy children_read on employee_children for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy children_ins on employee_children for insert to authenticated
  with check (can_manage_company(company_id) or is_self_employee(employee_id));
create policy children_upd on employee_children for update to authenticated
  using (can_manage_company(company_id) or is_self_employee(employee_id))
  with check (can_manage_company(company_id) or is_self_employee(employee_id));
create policy children_del on employee_children for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_children after insert or update or delete on employee_children
  for each row execute function fn_audit();

alter table absences add column if not exists child_id uuid references employee_children(id) on delete set null;
create index if not exists absences_child_idx on absences(child_id);

-- Congé supplémentaire pour handicap, applicable à une date.
create or replace function fn_disability_extra_leave(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare d employee_disabilities; scale jsonb; item jsonb; days numeric;
begin
  select * into d from employee_disabilities
  where employee_id = p_employee and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;
  if d.id is null then
    return jsonb_build_object('applies', false, 'extra_days', 0);
  end if;

  if d.extra_leave_days_override is not null then
    days := d.extra_leave_days_override;
  else
    scale := (fn_param('disabled_extra_leave_scale', p_on)).value_json;
    for item in select value from jsonb_array_elements(scale) order by (value->>'from_rate')::numeric loop
      if d.rate_pct >= (item->>'from_rate')::numeric then days := (item->>'days')::numeric; end if;
    end loop;
  end if;

  return jsonb_build_object(
    'applies', true, 'rate_pct', d.rate_pct, 'extra_days', coalesce(days, 0),
    'recognized_on', d.recognized_on, 'authority', d.authority,
    'legal_ref', (fn_param('disabled_extra_leave_scale', p_on)).legal_ref);
end $$;

-- Enfants d'un salarié : la vue « attentions » ne sort que ceux qui l'acceptent.
create or replace function fn_employee_children(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; rows jsonb := '[]'::jsonb; ch record; age numeric;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé';
  end if;

  for ch in select * from employee_children where employee_id = p_employee order by birth_date loop
    age := floor(extract(epoch from age(p_on, ch.birth_date)) / (365.25 * 86400));
    rows := rows || jsonb_build_object(
      'id', ch.id,
      'age', age,
      'birth_date', ch.birth_date,
      'relationship', ch.relationship,
      'is_dependent', ch.is_dependent,
      'privacy_opt_out', ch.privacy_opt_out,
      'first_name', case when ch.privacy_opt_out then null else ch.first_name end,
      'last_name', case when ch.privacy_opt_out then null else ch.last_name end,
      'sex', case when ch.privacy_opt_out then null else ch.sex end,
      'eligible_for_gift', (not ch.privacy_opt_out)
        and age <= fn_param_num('saint_nicolas_age_max', p_on));
  end loop;

  return jsonb_build_object(
    'employee_id', p_employee, 'evaluated_on', p_on,
    'children', rows,
    'count', jsonb_array_length(rows),
    'gift_eligible_count', (select count(*) from jsonb_array_elements(rows) x
                            where (x->>'eligible_for_gift')::boolean),
    'privacy_note','Les enfants dont le salarié a refusé les attentions ne sont connus que par '
      || 'leur date de naissance, strictement pour établir les droits à congé.');
end $$;

revoke execute on function fn_disability_extra_leave(uuid, date) from anon, public;
revoke execute on function fn_employee_children(uuid, date) from anon, public;
grant execute on function fn_disability_extra_leave(uuid, date) to authenticated;
grant execute on function fn_employee_children(uuid, date) to authenticated;
