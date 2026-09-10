
-- =========================================================================
--  Les droits à congé extraordinaire évoluent : le congé de mariage est passé
--  de 6 à 3 jours en 2018, celui de naissance de 2 à 10 jours. Un droit doit
--  donc porter une période de validité, comme tout paramètre légal.
-- =========================================================================
create table absence_entitlements (
  id uuid primary key default gen_random_uuid(),
  absence_type_id uuid not null references absence_types(id) on delete cascade,
  days numeric(5,1),
  valid_from date not null,
  valid_to date,
  legal_ref text,
  frequency_note text,
  -- Certains congés se comptent sur toute la carrière, par blocs.
  career_cap_days numeric(6,1),
  block_days numeric(5,1),
  period_months int,                 -- fenêtre de renouvellement du droit
  relationship_degree smallint,      -- 1er ou 2e degré, pour les congés de décès
  requires_evidence boolean not null default false,
  note text,
  constraint entitlement_range check (valid_to is null or valid_to > valid_from),
  exclude using gist (absence_type_id with =, daterange(valid_from, valid_to, '[)') with &&)
);
create index on absence_entitlements(absence_type_id, valid_from desc);

alter table absence_entitlements enable row level security;
create policy entitlements_read on absence_entitlements for select to authenticated using (true);
create policy entitlements_ins on absence_entitlements for insert to authenticated
  with check (is_org_admin());
create policy entitlements_upd on absence_entitlements for update to authenticated
  using (is_org_admin()) with check (is_org_admin());
create policy entitlements_del on absence_entitlements for delete to authenticated
  using (is_org_admin());

-- Types d'absence complémentaires.
insert into absence_types (code, label, category, legal_ref, requires_certificate, is_paid, counts_against_leave)
values
('death_first_degree','Décès d''un parent au 1er degré','extraordinary','art. L.233-16', false, true, false),
('death_second_degree','Décès d''un parent au 2e degré','extraordinary','art. L.233-16', false, true, false),
('youth_leave','Congé jeunesse','extraordinary','art. L.234-1', false, true, false),
('family_reasons','Congé pour raisons familiales','extraordinary','art. L.234-51', true, true, false),
('accompaniment','Congé d''accompagnement','extraordinary','art. L.234-65', true, true, false),
('paternity','Congé de paternité','extraordinary','art. L.233-16', false, true, false),
('parental','Congé parental','extraordinary','art. L.234-43', false, false, false),
('maternity','Congé de maternité','extraordinary','art. L.332-1', true, true, false)
on conflict (code) do nothing;

-- Droits datés. La version antérieure à 2018 est conservée : un calcul daté de
-- 2017 doit retrouver le droit alors applicable.
insert into absence_entitlements
  (absence_type_id, days, valid_from, valid_to, legal_ref, frequency_note, relationship_degree, requires_evidence)
select t.id, v.days, v.vfrom, v.vto, v.ref, v.note, v.degree, v.evidence
from (values
  ('marriage',            6.0, date '2000-01-01', date '2018-01-01', 'art. L.233-16', 'régime antérieur à la réforme de 2018', null::smallint, false),
  ('marriage',            3.0, date '2018-01-01', null,              'art. L.233-16', 'pour son propre mariage',               null::smallint, false),
  ('death_spouse',        3.0, date '2018-01-01', null,              'art. L.233-16', 'conjoint ou partenaire',                1::smallint,    true),
  ('death_first_degree',  3.0, date '2018-01-01', null,              'art. L.233-16', 'parent au 1er degré',                   1::smallint,    true),
  ('death_second_degree', 1.0, date '2018-01-01', null,              'art. L.233-16', 'parent au 2e degré',                    2::smallint,    true),
  ('death_child',         5.0, date '2018-01-01', null,              'art. L.233-16', 'enfant mineur',                         1::smallint,    true),
  ('birth',               2.0, date '2000-01-01', date '2018-01-01', 'art. L.233-16', 'régime antérieur à la réforme de 2018', null::smallint, false),
  ('birth',              10.0, date '2018-01-01', null,              'art. L.233-16', 'à prendre dans les 2 mois de la naissance', null::smallint, true),
  ('paternity',          10.0, date '2018-01-01', null,              'art. L.233-16', 'à prendre dans les 2 mois de la naissance', null::smallint, true),
  ('moving',              2.0, date '2018-01-01', null,              'art. L.233-16', '1 fois par 3 ans, sauf mutation professionnelle', null::smallint, false)
) as v(code, days, vfrom, vto, ref, note, degree, evidence)
join absence_types t on t.code = v.code;

-- Le congé jeunesse se compte sur toute la carrière, par blocs.
insert into absence_entitlements
  (absence_type_id, days, valid_from, legal_ref, frequency_note, career_cap_days, block_days, requires_evidence)
select t.id, 20, date '2018-01-01', 'art. L.234-1',
       '80 jours sur l''ensemble de la carrière, par blocs de 20 jours', 80, 20, true
from absence_types t where t.code = 'youth_leave';

-- Le déménagement se renouvelle tous les trois ans.
update absence_entitlements set period_months = 36
 where absence_type_id = (select id from absence_types where code = 'moving');

-- Les droits vivent désormais dans la table datée.
alter table absence_types drop column entitlement_days;
alter table absence_types drop column frequency_note;

-- Droit applicable à une date donnée.
create or replace function fn_absence_entitlement(p_type uuid, p_on date default current_date)
returns absence_entitlements language sql stable set search_path = public as $$
  select * from absence_entitlements
  where absence_type_id = p_type and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;
$$;

-- =========================================================================
--  Impact d'une demande, avec plafond de carrière et fenêtre de renouvellement.
-- =========================================================================
create or replace function fn_leave_request_impact(
  p_employee uuid, p_type uuid, p_start date, p_end date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare e employees; t absence_types; ent absence_entitlements;
        days numeric := 0; d date; holidays int := 0; bal jsonb;
        used_in_period numeric; used_career numeric; msg text; valid boolean := true;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Employé introuvable'; end if;
  if not (has_company_access(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé';
  end if;
  select * into t from absence_types where id = p_type;
  ent := fn_absence_entitlement(p_type, p_start);

  -- Jours ouvrables, jours fériés exclus.
  for d in select generate_series(p_start, p_end, '1 day')::date loop
    if extract(dow from d) <> 0 then
      if fn_is_public_holiday(d) then holidays := holidays + 1;
      else days := days + 1; end if;
    end if;
  end loop;

  if t.category = 'extraordinary' then
    select coalesce(sum(a.days_count), 0) into used_career
    from absences a
    where a.employee_id = p_employee and a.absence_type_id = p_type and a.status = 'approved';

    select coalesce(sum(a.days_count), 0) into used_in_period
    from absences a
    where a.employee_id = p_employee and a.absence_type_id = p_type and a.status = 'approved'
      and (ent.period_months is null
           or a.start_date >= (p_start - (ent.period_months || ' months')::interval)::date);

    msg := coalesce(fn_fmt(ent.days), '?') || ' jour(s) de droit'
           || coalesce(' — ' || ent.frequency_note, '') || '.';

    if ent.days is not null and days > ent.days then
      valid := false;
      msg := 'Le droit est de ' || fn_fmt(ent.days) || ' jour(s) pour ce motif, '
             || fn_fmt(days) || ' demandé(s).';
    elsif ent.career_cap_days is not null and used_career + days > ent.career_cap_days then
      valid := false;
      msg := 'Plafond de carrière atteint : ' || fn_fmt(used_career) || ' jour(s) déjà pris sur '
             || fn_fmt(ent.career_cap_days) || '.';
    elsif ent.period_months is not null and ent.days is not null
          and used_in_period + days > ent.days then
      valid := false;
      msg := 'Droit déjà consommé sur la période de ' || ent.period_months || ' mois ('
             || fn_fmt(used_in_period) || ' jour(s) pris).';
    end if;

    return jsonb_build_object(
      'days_counted', days, 'holidays_excluded', holidays,
      'category', t.category,
      'entitlement_days', ent.days,
      'career_cap_days', ent.career_cap_days,
      'block_days', ent.block_days,
      'used_career', used_career,
      'used_in_period', used_in_period,
      'period_months', ent.period_months,
      'requires_evidence', coalesce(ent.requires_evidence, false),
      'is_valid', valid, 'message', msg,
      'legal_ref', coalesce(ent.legal_ref, t.legal_ref));
  end if;

  bal := fn_leave_balance(p_employee, p_start);

  return jsonb_build_object(
    'days_counted', days, 'holidays_excluded', holidays,
    'category', t.category,
    'balance_before', (bal->>'balance')::numeric,
    'balance_after', round((bal->>'balance')::numeric - days, 2),
    'is_valid', not t.counts_against_leave or (bal->>'balance')::numeric >= days,
    'message', case
      when t.counts_against_leave and (bal->>'balance')::numeric < days
        then 'Solde de ' || fn_fmt((bal->>'balance')::numeric) || ' j. La demande dépasse de '
             || fn_fmt(days - (bal->>'balance')::numeric) || ' j le droit acquis à cette date.'
      when holidays > 0 then fn_fmt(holidays) || ' jour(s) férié(s) exclu(s) du décompte.'
      else 'Aucun jour férié sur la période.' end,
    'legal_ref', coalesce(ent.legal_ref, t.legal_ref));
end $$;

revoke execute on function fn_absence_entitlement(uuid, date) from anon, public;
grant execute on function fn_absence_entitlement(uuid, date) to authenticated;
