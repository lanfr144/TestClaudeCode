-- =========================================================================
--  Performance : le PRD exige qu'un planning mensuel de 50 salariés se
--  charge en moins de 2 secondes. Trois corrections.
-- =========================================================================

-- 1. auth.uid() était réévalué pour chaque ligne. Enveloppé dans un sous-select,
--    il n'est calculé qu'une fois par requête.
drop policy profile_self_update on profiles;
create policy profile_self_update on profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy companies_read on companies;
create policy companies_read on companies for select to authenticated
  using (
    has_company_access(id)
    or exists (
      select 1 from employees e
      where e.company_id = companies.id and e.user_id = (select auth.uid())
    )
  );

drop policy employees_read on employees;
create policy employees_read on employees for select to authenticated
  using (has_company_access(company_id) or user_id = (select auth.uid()));

-- 2. Les policies d'écriture étaient déclarées FOR ALL : elles s'ajoutaient donc
--    à la policy de lecture sur chaque SELECT, doublant le travail du planificateur.
--    On les scinde en insert / update / delete, à expressions identiques.
do $$
declare p record;
begin
  for p in
    select tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public' and cmd = 'ALL'
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (%s)',
      p.policyname || '_ins', p.tablename, coalesce(p.with_check, p.qual));
    execute format(
      'create policy %I on public.%I for update to authenticated using (%s) with check (%s)',
      p.policyname || '_upd', p.tablename, p.qual, coalesce(p.with_check, p.qual));
    execute format(
      'create policy %I on public.%I for delete to authenticated using (%s)',
      p.policyname || '_del', p.tablename, p.qual);
  end loop;
end $$;

-- 3. Clés étrangères empruntées par les écrans, sans index de couverture.
create index if not exists shifts_company_id_idx            on shifts(company_id);
create index if not exists shifts_template_id_idx           on shifts(template_id);
create index if not exists schedules_department_id_idx      on schedules(department_id);
create index if not exists employees_department_id_idx      on employees(department_id);
create index if not exists absences_absence_type_id_idx     on absences(absence_type_id);
create index if not exists contract_terminations_contract_id_idx on contract_terminations(contract_id);
create index if not exists probation_extensions_contract_id_idx  on probation_extensions(contract_id);
create index if not exists contract_amendments_company_id_idx    on contract_amendments(company_id);
create index if not exists employee_tax_cards_company_id_idx     on employee_tax_cards(company_id);
create index if not exists shift_templates_department_id_idx     on shift_templates(department_id);
create index if not exists reference_periods_department_id_idx   on reference_periods(department_id);
create index if not exists companies_cba_idx                on companies(collective_agreement_id);
create index if not exists contracts_previous_contract_idx  on contracts(previous_contract_id);
create index if not exists user_roles_organization_id_idx    on user_roles(organization_id);
create index if not exists compliance_alerts_employee_id_idx on compliance_alerts(employee_id);

-- L'écran de planning lit toujours les shifts d'une société sur une plage de dates.
create index if not exists shifts_company_date_idx on shifts(company_id, shift_date);
-- Le moteur de vigilance balaie les contrats actifs d'une société.
create index if not exists contracts_company_status_idx on contracts(company_id, status);
