
-- =========================================================================
--  Salaire social minimum : barème par âge, règle de qualification, et prise
--  en compte de toutes les conventions applicables.
-- =========================================================================
insert into legal_parameters
  (family, param_key, label, value_json, value_num, unit, valid_from, source, legal_ref, note)
values
('social','ssm_age_scale','Barème du SSM par âge',
 '[{"from_age":18,"ratio":1.00,"label":"18 ans et plus"},
   {"from_age":17,"ratio":0.80,"label":"de 17 à 18 ans"},
   {"from_age":15,"ratio":0.75,"label":"de 15 à 17 ans"}]'::jsonb,
 null,'ratio','2019-01-01','Legilux','art. L.222-2',
 'Le salaire social minimum des adolescents est réduit selon l''âge.'),
('contract','qualification_experience_years','Ancienneté ouvrant la qualification',
 null,10,'ans','2019-01-01','Legilux','art. L.222-4',
 'Un salarié est réputé qualifié après cette durée d''exercice de la profession.'),
('worktime','minor_night_work_start','Début de l''interdiction de travail de nuit des mineurs',
 null,20,'heure','2019-01-01','Legilux','art. L.344-4',
 'Un salarié de moins de 18 ans ne peut être occupé entre 20 h et 6 h.'),
('worktime','minor_night_work_end','Fin de l''interdiction de travail de nuit des mineurs',
 null,6,'heure','2019-01-01','Legilux','art. L.344-4', null),
('worktime','minor_max_daily_hours','Durée journalière maximale d''un mineur',
 null,8,'h','2019-01-01','Legilux','art. L.344-3', null);

-- Ancienneté de carrière, pour la règle de qualification.
alter table employees
  add column if not exists career_start_date date,
  add column if not exists profession text;

comment on column employees.career_start_date is
  'Début d''exercice de la profession, tous employeurs confondus. Sert à établir la qualification.';

create or replace function fn_employee_age(p_employee uuid, p_on date default current_date)
returns numeric language sql stable set search_path = public as $$
  select case when e.birth_date is null then null
         else floor(extract(epoch from age(p_on, e.birth_date)) / (365.25 * 86400)) end
  from employees e where e.id = p_employee;
$$;

-- Qualifié par déclaration, ou par ancienneté dans la profession.
create or replace function fn_is_qualified(p_employee uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare e employees; years numeric; threshold numeric;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then return null; end if;

  threshold := fn_param_num('qualification_experience_years', p_on);
  if e.career_start_date is not null then
    years := round(extract(epoch from age(p_on, e.career_start_date)) / (365.25 * 86400), 2);
  end if;

  if e.qualification = 'qualified' then
    return jsonb_build_object('qualified', true, 'source', 'déclarée sur la fiche salarié',
      'career_years', years, 'threshold_years', threshold,
      'legal_ref', (fn_param('qualification_experience_years', p_on)).legal_ref);
  end if;

  if years is not null and years >= threshold then
    return jsonb_build_object('qualified', true,
      'source', years || ' ans d''exercice de la profession, seuil de ' || threshold || ' ans atteint',
      'career_years', years, 'threshold_years', threshold,
      'legal_ref', (fn_param('qualification_experience_years', p_on)).legal_ref);
  end if;

  return jsonb_build_object('qualified', false,
    'source', case when years is null then 'aucune ancienneté de carrière renseignée'
                   else years || ' ans d''exercice, seuil de ' || threshold || ' ans non atteint' end,
    'career_years', years, 'threshold_years', threshold,
    'legal_ref', (fn_param('qualification_experience_years', p_on)).legal_ref);
end $$;

-- =========================================================================
--  Salaire minimum applicable : âge, qualification, temps de travail, et la
--  meilleure grille parmi toutes les conventions applicables.
-- =========================================================================
create or replace function fn_min_salary(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; qual jsonb; is_qual boolean; p legal_parameters;
        ssm numeric; ssm_ref text; ssm_idx numeric; normal_weekly numeric; prorata numeric;
        age numeric; age_scale jsonb; item jsonb; age_ratio numeric := 1; age_label text := '18 ans et plus';
        seniority numeric; rec record; grid numeric; grid_cat text;
        best_grid numeric; best_cat text; best_cba text; grids jsonb := '[]'::jsonb;
begin
  select ct.*, e.birth_date into c
  from contracts ct join employees e on e.id = ct.employee_id
  where ct.id = p_contract;
  if not found then return null; end if;

  qual := fn_is_qualified(c.employee_id, p_on);
  is_qual := (qual->>'qualified')::boolean;

  p := fn_param(case when is_qual then 'ssm_monthly_qualified' else 'ssm_monthly_unqualified' end, p_on);
  ssm := p.value_num; ssm_ref := p.legal_ref; ssm_idx := p.index_ref;

  age := fn_employee_age(c.employee_id, p_on);
  age_scale := (fn_param('ssm_age_scale', p_on)).value_json;
  if age is not null and age_scale is not null then
    age_ratio := 0.75; age_label := 'moins de 15 ans';
    for item in select value from jsonb_array_elements(age_scale) order by (value->>'from_age')::int loop
      if age >= (item->>'from_age')::numeric then
        age_ratio := (item->>'ratio')::numeric; age_label := item->>'label';
      end if;
    end loop;
  end if;

  normal_weekly := fn_param_num('normal_weekly_hours', p_on);
  prorata := least(1.0, c.weekly_hours / nullif(normal_weekly, 0));
  seniority := extract(epoch from age(p_on, c.start_date)) / (365.25 * 86400);

  for rec in select * from fn_applicable_cbas(p_contract, p_on) loop
    select g.monthly_amount, g.category into grid, grid_cat
    from cba_salary_grids g
    where g.collective_agreement_id = rec.collective_agreement_id
      and (c.category is null or g.category = c.category)
      and seniority >= g.seniority_from_years
      and (g.seniority_to_years is null or seniority < g.seniority_to_years)
    order by g.monthly_amount desc limit 1;

    if grid is not null then
      grids := grids || jsonb_build_object(
        'cba', rec.name, 'origin', rec.origin, 'category', grid_cat, 'amount', grid);
      if best_grid is null or grid > best_grid then
        best_grid := grid; best_cat := grid_cat; best_cba := rec.name;
      end if;
    end if;
    grid := null; grid_cat := null;
  end loop;

  return jsonb_build_object(
    'ssm', round(ssm * age_ratio * prorata, 2),
    'ssm_full', ssm,
    'ssm_ref', ssm_ref,
    'ssm_index', ssm_idx,
    'qualification', qual,
    'is_qualified', is_qual,
    'age', age, 'age_ratio', age_ratio, 'age_band', age_label,
    'age_ref', (fn_param('ssm_age_scale', p_on)).legal_ref,
    'prorata', round(prorata, 4),
    'cba_grid', case when best_grid is null then null else round(best_grid * prorata, 2) end,
    'cba_category', best_cat,
    'cba_name', best_cba,
    'cba_grids_considered', grids,
    'floor', greatest(round(ssm * age_ratio * prorata, 2), coalesce(round(best_grid * prorata, 2), 0)),
    'contract_gross', c.monthly_gross);
end $$;

-- Congé annuel : la meilleure des conventions applicables face à la loi et au contrat.
create or replace function fn_annual_leave_rule(p_contract uuid, p_on date default current_date)
returns jsonb language plpgsql stable set search_path = public as $$
declare c record; law numeric; law_ref text; best jsonb; arb jsonb;
begin
  select ct.annual_leave_days into c from contracts ct where ct.id = p_contract;
  if not found then return null; end if;

  law := fn_param_num('annual_leave_min_days', p_on);
  law_ref := (fn_param('annual_leave_min_days', p_on)).legal_ref;
  best := fn_cba_best_num(p_contract, 'leave', 'annual_days', p_on, true);

  arb := fn_arbitrate('Congé annuel', law, law_ref,
                      (best->>'value')::numeric, coalesce(best->>'cba_name', 'CCT'),
                      c.annual_leave_days, true);
  return arb || jsonb_build_object('cba_considered', best->'considered');
end $$;
