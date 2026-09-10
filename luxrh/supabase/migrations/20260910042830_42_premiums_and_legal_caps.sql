
-- =========================================================================
--  Primes : montant, traitement fiscal, et plafonds légaux du régime
--  participatif. Deux plafonds cohabitent : un par salarié, un par entreprise.
-- =========================================================================
create table company_financials (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  fiscal_year smallint not null,
  profit numeric(14,2),
  revenue numeric(14,2),
  source text,
  note text,
  created_at timestamptz not null default now(),
  unique (company_id, fiscal_year)
);

alter table company_financials enable row level security;
create policy financials_read on company_financials for select to authenticated
  using (has_company_access(company_id));
create policy financials_ins on company_financials for insert to authenticated
  with check (can_manage_company(company_id));
create policy financials_upd on company_financials for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy financials_del on company_financials for delete to authenticated
  using (can_manage_company(company_id));

create table premiums (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(id) on delete cascade,
  employee_id uuid not null references employees(id) on delete cascade,
  contract_id uuid references contracts(id) on delete set null,
  termination_id uuid references contract_terminations(id) on delete set null,
  kind text not null default 'other' check (kind in (
    'participative','thirteenth_month','performance','seniority',
    'exceptional','notice_waiver','other')),
  label text not null,
  amount numeric(12,2) not null check (amount >= 0),
  granted_on date not null,
  fiscal_year smallint not null,
  is_taxable boolean not null default true,
  is_contributory boolean not null default true,
  exempt_pct numeric(6,3) not null default 0,
  note text,
  created_at timestamptz not null default now()
);
create index on premiums(company_id, fiscal_year);
create index on premiums(employee_id, fiscal_year);

alter table premiums enable row level security;
create policy premiums_read on premiums for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy premiums_ins on premiums for insert to authenticated
  with check (can_manage_company(company_id));
create policy premiums_upd on premiums for update to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));
create policy premiums_del on premiums for delete to authenticated
  using (can_manage_company(company_id));

create trigger audit_premiums after insert or update or delete on premiums
  for each row execute function fn_audit();

-- Plafonds du régime participatif. Seules les valeurs communiquées pour 2025
-- sont chargées : avant cette date, le barème est absent et le moteur le dit
-- plutôt que d'appliquer un plafond inventé.
insert into legal_parameters
  (family, param_key, label, value_num, unit, valid_from, source, legal_ref, note)
values
('fiscal','participative_premium_individual_cap_pct',
 'Prime participative — plafond individuel',
 30,'% du brut annuel','2025-01-01','ACD','art. 115 (13a) LIR',
 'La prime individuelle ne peut excéder 30 % du salaire annuel brut du salarié. '
 'Le régime antérieur à 2025 n''est pas chargé.'),
('fiscal','participative_premium_company_cap_pct',
 'Prime participative — plafond de l''enveloppe entreprise',
 7.5,'% du bénéfice N-1','2025-01-01','ACD','art. 115 (13a) LIR',
 'L''enveloppe globale distribuée ne peut dépasser 7,5 % du bénéfice de l''exercice précédent.'),
('fiscal','participative_premium_exempt_pct',
 'Prime participative — part exonérée d''impôt',
 50,'%','2025-01-01','ACD','art. 115 (13a) LIR',
 'Part exonérée dans le chef du salarié. À re-vérifier sur la source officielle.');

-- Enveloppe et plafonds individuels d'un exercice.
create or replace function fn_premium_caps(p_company uuid, p_year int)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare on_date date; ind_cap numeric; env_cap numeric; profit numeric;
        envelope numeric; used numeric; rows jsonb := '[]'::jsonb; r record;
        annual_gross numeric; cap numeric; granted numeric;
begin
  if not has_company_access(p_company) then raise exception 'Accès refusé'; end if;
  on_date := make_date(p_year, 1, 1);

  ind_cap := fn_param_num('participative_premium_individual_cap_pct', on_date);
  env_cap := fn_param_num('participative_premium_company_cap_pct', on_date);

  if ind_cap is null or env_cap is null then
    return jsonb_build_object(
      'found', false, 'fiscal_year', p_year,
      'message','Les plafonds du régime participatif ne sont pas chargés pour ' || p_year
        || '. Le contrôle est suspendu plutôt que fondé sur un plafond inventé.');
  end if;

  select cf.profit into profit from company_financials cf
  where cf.company_id = p_company and cf.fiscal_year = p_year - 1;

  envelope := case when profit is null then null else round(profit * env_cap / 100.0, 2) end;

  select coalesce(sum(amount), 0) into used from premiums
  where company_id = p_company and fiscal_year = p_year and kind = 'participative';

  -- Plafond individuel : part du brut annuel de chaque bénéficiaire.
  for r in
    select p.employee_id, e.first_name || ' ' || e.last_name as name,
           sum(p.amount) as granted
    from premiums p join employees e on e.id = p.employee_id
    where p.company_id = p_company and p.fiscal_year = p_year and p.kind = 'participative'
    group by p.employee_id, e.first_name, e.last_name
  loop
    select ct.monthly_gross * 12 into annual_gross from contracts ct
    where ct.employee_id = r.employee_id
      and ct.start_date <= make_date(p_year, 12, 31)
      and (ct.end_date is null or ct.end_date >= on_date)
    order by ct.start_date desc limit 1;

    cap := case when annual_gross is null then null else round(annual_gross * ind_cap / 100.0, 2) end;
    granted := r.granted;

    rows := rows || jsonb_build_object(
      'employee_id', r.employee_id, 'employee_name', r.name,
      'annual_gross', annual_gross, 'individual_cap', cap, 'granted', granted,
      'within_cap', cap is null or granted <= cap,
      'excess', case when cap is not null and granted > cap then round(granted - cap, 2) else 0 end);
  end loop;

  return jsonb_build_object(
    'found', true, 'company_id', p_company, 'fiscal_year', p_year,
    'individual_cap_pct', ind_cap, 'company_cap_pct', env_cap,
    'previous_year_profit', profit,
    'envelope', envelope,
    'envelope_used', used,
    'envelope_remaining', case when envelope is null then null else round(envelope - used, 2) end,
    'envelope_exceeded', envelope is not null and used > envelope,
    'employees', rows,
    'exempt_pct', fn_param_num('participative_premium_exempt_pct', on_date),
    'legal_ref', (fn_param('participative_premium_individual_cap_pct', on_date)).legal_ref,
    'message', case when profit is null
      then 'Le bénéfice de l''exercice ' || (p_year - 1) || ' n''est pas renseigné : '
           || 'l''enveloppe globale ne peut pas être établie.'
      else 'Enveloppe calculée sur le bénéfice de l''exercice précédent.' end);
end $$;

-- Contrôle d'une prime avant enregistrement définitif.
create or replace function fn_premium_check(p_premium uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare p premiums; caps jsonb; mine jsonb; checks jsonb := '[]'::jsonb; exempt numeric;
begin
  select * into p from premiums where id = p_premium;
  if p.id is null then raise exception 'Prime introuvable'; end if;
  if not has_company_access(p.company_id) then raise exception 'Accès refusé'; end if;

  if p.kind <> 'participative' then
    return jsonb_build_object(
      'premium_id', p_premium, 'kind', p.kind, 'checks', '[]'::jsonb,
      'message','Cette prime ne relève pas du régime participatif : aucun plafond légal spécifique.');
  end if;

  caps := fn_premium_caps(p.company_id, p.fiscal_year);
  if not (caps->>'found')::boolean then
    return jsonb_build_object('premium_id', p_premium, 'checks', '[]'::jsonb,
      'message', caps->>'message');
  end if;

  select value into mine from jsonb_array_elements(caps->'employees') value
  where (value->>'employee_id')::uuid = p.employee_id;

  checks := checks || jsonb_build_object(
    'code','individual_cap','label','Plafond individuel',
    'severity', case when mine is null or (mine->>'within_cap')::boolean then 'ok' else 'blocking' end,
    'detail', case when mine is null then 'Aucun brut annuel exploitable pour ce salarié.'
      else fn_fmt((mine->>'granted')::numeric) || ' € attribués · plafond '
           || coalesce(fn_fmt((mine->>'individual_cap')::numeric), '—') || ' € ('
           || (caps->>'individual_cap_pct') || ' % du brut annuel)' end,
    'legal_ref', caps->>'legal_ref');

  checks := checks || jsonb_build_object(
    'code','company_envelope','label','Enveloppe de l''entreprise',
    'severity', case when caps->>'envelope' is null then 'warning'
                     when (caps->>'envelope_exceeded')::boolean then 'blocking' else 'ok' end,
    'detail', case when caps->>'envelope' is null then caps->>'message'
      else fn_fmt((caps->>'envelope_used')::numeric) || ' € distribués sur une enveloppe de '
           || fn_fmt((caps->>'envelope')::numeric) || ' € ('
           || (caps->>'company_cap_pct') || ' % du bénéfice ' || (p.fiscal_year - 1) || ')' end,
    'legal_ref', caps->>'legal_ref');

  exempt := fn_param_num('participative_premium_exempt_pct', make_date(p.fiscal_year, 1, 1));

  return jsonb_build_object(
    'premium_id', p_premium, 'kind', p.kind, 'amount', p.amount,
    'checks', checks,
    'exempt_pct', exempt,
    'exempt_amount', round(p.amount * coalesce(exempt, 0) / 100.0, 2),
    'taxable_amount', round(p.amount * (1 - coalesce(exempt, 0) / 100.0), 2),
    'blocking_count', (select count(*) from jsonb_array_elements(checks) x where x->>'severity' = 'blocking'));
end $$;

revoke execute on function fn_premium_caps(uuid, int) from anon, public;
revoke execute on function fn_premium_check(uuid) from anon, public;
grant execute on function fn_premium_caps(uuid, int) to authenticated;
grant execute on function fn_premium_check(uuid) to authenticated;
