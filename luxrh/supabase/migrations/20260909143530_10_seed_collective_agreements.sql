
-- =========================================================================
--  CCT PRÉ-CHARGÉES (organization_id null = partagées, en lecture seule)
--  HORECA · Aides et soins · Gardiennage — US9
-- =========================================================================
do $$
declare horeca uuid; sas uuid; garde uuid;
begin
  insert into collective_agreements(organization_id, code, name, sector, valid_from, valid_to, is_active)
  values (null,'HORECA-2025','CCT HORECA 2025-2027','HORECA','2025-01-01','2027-12-31',true)
  returning id into horeca;

  insert into collective_agreements(organization_id, code, name, sector, valid_from, valid_to, is_active)
  values (null,'SAS-2025','CCT Secteur d''aides et de soins 2025-2027','Aides et soins','2025-01-01','2027-12-31',true)
  returning id into sas;

  insert into collective_agreements(organization_id, code, name, sector, valid_from, valid_to, is_active)
  values (null,'GARD-2025','CCT Gardiennage et sécurité 2025-2027','Gardiennage','2025-01-01','2027-12-31',true)
  returning id into garde;

  -- ---------- HORECA ----------
  insert into cba_rules(collective_agreement_id, block, rules, is_complete) values
  (horeca,'leave','{"annual_days":28,"extra_seniority_days":[{"after_years":10,"days":1},{"after_years":20,"days":2}],"carry_over_until":"03-31"}',true),
  (horeca,'worktime','{"weekly_hours":40,"reference_period_months":4,"break_minutes":30,"break_threshold_hours":6,"night_window":"22:00-06:00"}',true),
  (horeca,'surcharges','{"night_pct":15,"sunday_pct":70,"holiday_pct":300,"overtime_money_pct":140}',true),
  (horeca,'notice_probation','{"probation_months_max":6,"notice_probation_days":15}',true),
  (horeca,'salary_grid','{"categories":["A","B","C"],"index_ref":992.24}',true),
  (horeca,'premiums','{}',false),
  (horeca,'custom_holidays','{}',false);

  insert into cba_salary_grids(collective_agreement_id, category, seniority_from_years, seniority_to_years, monthly_amount, index_ref) values
  (horeca,'A',0,2,3325.59,992.24),(horeca,'A',2,5,3410.00,992.24),(horeca,'A',5,null,3495.00,992.24),
  (horeca,'B',0,2,3388.00,992.24),(horeca,'B',2,5,3470.00,992.24),(horeca,'B',5,null,3560.00,992.24),
  (horeca,'C',0,2,3620.00,992.24),(horeca,'C',2,5,3745.00,992.24),(horeca,'C',5,null,3880.00,992.24);

  -- ---------- SECTEUR D'AIDES ET DE SOINS ----------
  insert into cba_rules(collective_agreement_id, block, rules, is_complete) values
  (sas,'leave','{"annual_days":26,"extra_shift_work_days":3,"carry_over_until":"03-31"}',true),
  (sas,'worktime','{"weekly_hours":40,"reference_period_months":4,"break_minutes":30,"night_window":"21:00-06:00"}',true),
  (sas,'surcharges','{"night_pct":20,"sunday_pct":70,"holiday_pct":300,"overtime_money_pct":140,"saturday_pct":25}',true),
  (sas,'notice_probation','{"probation_months_max":6,"notice_probation_days":15}',true),
  (sas,'salary_grid','{"categories":["C1","C2","C3"],"index_ref":992.24}',true),
  (sas,'premiums','{"annual_bonus_month":true}',true),
  (sas,'custom_holidays','{}',false);

  insert into cba_salary_grids(collective_agreement_id, category, seniority_from_years, seniority_to_years, monthly_amount, index_ref) values
  (sas,'C1',0,3,3325.59,992.24),(sas,'C1',3,null,3480.00,992.24),
  (sas,'C2',0,3,3690.00,992.24),(sas,'C2',3,null,3865.00,992.24),
  (sas,'C3',0,3,4180.00,992.24),(sas,'C3',3,null,4390.00,992.24);

  -- ---------- GARDIENNAGE ----------
  insert into cba_rules(collective_agreement_id, block, rules, is_complete) values
  (garde,'leave','{"annual_days":26,"extra_night_worker_days":2,"carry_over_until":"03-31"}',true),
  (garde,'worktime','{"weekly_hours":40,"reference_period_months":4,"break_minutes":30,"night_window":"22:00-06:00"}',true),
  (garde,'surcharges','{"night_pct":20,"sunday_pct":70,"holiday_pct":300,"overtime_money_pct":140}',true),
  (garde,'notice_probation','{"probation_months_max":6,"notice_probation_days":15}',true),
  (garde,'salary_grid','{"categories":["Agent","Agent confirmé","Chef d''équipe"],"index_ref":992.24}',true),
  (garde,'premiums','{}',false),
  (garde,'custom_holidays','{}',false);

  insert into cba_salary_grids(collective_agreement_id, category, seniority_from_years, seniority_to_years, monthly_amount, index_ref) values
  (garde,'Agent',0,3,2771.33,992.24),(garde,'Agent',3,null,2890.00,992.24),
  (garde,'Agent confirmé',0,3,3120.00,992.24),(garde,'Agent confirmé',3,null,3265.00,992.24),
  (garde,'Chef d''équipe',0,null,3560.00,992.24);
end $$;

-- Refus d'une règle de CCT moins favorable que la loi (US8)
create or replace function fn_check_cba_not_worse()
returns trigger language plpgsql set search_path = public as $$
declare v numeric; legal numeric;
begin
  if new.block = 'surcharges' then
    foreach v in array array[]::numeric[] loop end loop;
    legal := fn_param_num('sunday_surcharge_pct', current_date);
    v := nullif(new.rules->>'sunday_pct','')::numeric;
    if v is not null and v < legal then
      raise exception 'Majoration dimanche de % %% inférieure au minimum légal de % %%', v, legal;
    end if;
    legal := fn_param_num('holiday_surcharge_pct', current_date);
    v := nullif(new.rules->>'holiday_pct','')::numeric;
    if v is not null and v < legal then
      raise exception 'Majoration jour férié de % %% inférieure au minimum légal de % %%', v, legal;
    end if;
    legal := fn_param_num('overtime_money_pct', current_date);
    v := nullif(new.rules->>'overtime_money_pct','')::numeric;
    if v is not null and v < legal then
      raise exception 'Majoration heure supplémentaire de % %% inférieure au minimum légal de % %%', v, legal;
    end if;
  elsif new.block = 'leave' then
    legal := fn_param_num('annual_leave_min_days', current_date);
    v := nullif(new.rules->>'annual_days','')::numeric;
    if v is not null and v < legal then
      raise exception 'Congé annuel de % jours inférieur au minimum légal de % jours', v, legal;
    end if;
  elsif new.block = 'worktime' then
    legal := fn_param_num('max_reference_period_months', current_date);
    v := nullif(new.rules->>'reference_period_months','')::numeric;
    if v is not null and v > legal then
      raise exception 'Période de référence de % mois supérieure au maximum légal de % mois', v, legal;
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

create trigger cba_rules_guard before insert or update on cba_rules
  for each row execute function fn_check_cba_not_worse();
