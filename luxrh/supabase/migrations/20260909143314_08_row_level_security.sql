
-- =========================================================================
--  ROW LEVEL SECURITY — l'isolation multi-sociétés est imposée en base,
--  jamais dans l'interface.
-- =========================================================================

create or replace function is_self_employee(p_employee uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from employees e where e.id = p_employee and e.user_id = auth.uid());
$$;

alter table organizations           enable row level security;
alter table profiles                enable row level security;
alter table companies               enable row level security;
alter table departments             enable row level security;
alter table user_roles              enable row level security;
alter table employees               enable row level security;
alter table employee_tax_cards      enable row level security;
alter table contracts               enable row level security;
alter table contract_amendments     enable row level security;
alter table probation_extensions    enable row level security;
alter table contract_terminations   enable row level security;
alter table shift_templates         enable row level security;
alter table reference_periods       enable row level security;
alter table schedules               enable row level security;
alter table shifts                  enable row level security;
alter table time_entries            enable row level security;
alter table absences                enable row level security;
alter table absence_types           enable row level security;
alter table documents               enable row level security;
alter table compliance_alerts       enable row level security;
alter table headcount_snapshots     enable row level security;
alter table legal_parameters        enable row level security;
alter table tax_scales              enable row level security;
alter table public_holidays         enable row level security;
alter table collective_agreements   enable row level security;
alter table cba_rules               enable row level security;
alter table cba_salary_grids        enable row level security;
alter table audit_log               enable row level security;
alter table app_secrets             enable row level security;   -- aucune policy : inaccessible

-- ---------- socle ----------
create policy org_read on organizations for select to authenticated
  using (id = auth_org_id());

create policy profile_read on profiles for select to authenticated
  using (organization_id = auth_org_id());
create policy profile_self_update on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy roles_read on user_roles for select to authenticated
  using (organization_id = auth_org_id());
create policy roles_admin_write on user_roles for all to authenticated
  using (organization_id = auth_org_id() and is_org_admin())
  with check (organization_id = auth_org_id() and is_org_admin());

create policy companies_read on companies for select to authenticated
  using (has_company_access(id) or exists (
    select 1 from employees e where e.company_id = companies.id and e.user_id = auth.uid()));
create policy companies_write on companies for all to authenticated
  using (organization_id = auth_org_id() and (is_org_admin() or can_manage_company(id)))
  with check (organization_id = auth_org_id() and is_org_admin());

create policy departments_read on departments for select to authenticated
  using (has_company_access(company_id));
create policy departments_write on departments for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- ---------- données de société : lecture gestionnaire + self-service salarié ----------
create policy employees_read on employees for select to authenticated
  using (has_company_access(company_id) or user_id = auth.uid());
create policy employees_write on employees for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy taxcards_read on employee_tax_cards for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy taxcards_write on employee_tax_cards for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy contracts_read on contracts for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy contracts_write on contracts for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy amendments_read on contract_amendments for select to authenticated
  using (has_company_access(company_id) or exists (
    select 1 from contracts c where c.id = contract_id and is_self_employee(c.employee_id)));
create policy amendments_write on contract_amendments for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy probext_read on probation_extensions for select to authenticated
  using (exists (select 1 from contracts c where c.id = contract_id
                 and (has_company_access(c.company_id) or is_self_employee(c.employee_id))));
create policy probext_write on probation_extensions for all to authenticated
  using (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)))
  with check (exists (select 1 from contracts c where c.id = contract_id and can_manage_company(c.company_id)));

create policy terminations_read on contract_terminations for select to authenticated
  using (has_company_access(company_id));
create policy terminations_write on contract_terminations for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- ---------- temps de travail ----------
create policy shifttpl_read on shift_templates for select to authenticated
  using (has_company_access(company_id));
create policy shifttpl_write on shift_templates for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy refperiod_read on reference_periods for select to authenticated
  using (has_company_access(company_id));
create policy refperiod_write on reference_periods for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- Le salarié ne voit que les plannings publiés qui le concernent.
create policy schedules_read on schedules for select to authenticated
  using (has_company_access(company_id) or (status = 'published' and exists (
    select 1 from shifts s join employees e on e.id = s.employee_id
    where s.schedule_id = schedules.id and e.user_id = auth.uid())));
create policy schedules_write on schedules for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy shifts_read on shifts for select to authenticated
  using (has_company_access(company_id)
     or (is_self_employee(employee_id)
         and exists (select 1 from schedules sc where sc.id = schedule_id and sc.status = 'published')));
create policy shifts_write on shifts for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy timeentries_read on time_entries for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy timeentries_write on time_entries for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- ---------- absences ----------
create policy absence_types_read on absence_types for select to authenticated using (true);
create policy absence_types_write on absence_types for all to authenticated
  using (is_org_admin()) with check (is_org_admin());

create policy absences_read on absences for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
-- un salarié peut déposer sa propre demande, jamais la valider
create policy absences_self_insert on absences for insert to authenticated
  with check (is_self_employee(employee_id) and status = 'pending');
create policy absences_self_cancel on absences for update to authenticated
  using (is_self_employee(employee_id) and status = 'pending')
  with check (is_self_employee(employee_id) and status in ('pending','cancelled'));
create policy absences_manage on absences for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- ---------- documents & vigilance ----------
create policy documents_read on documents for select to authenticated
  using (has_company_access(company_id) or is_self_employee(employee_id));
create policy documents_write on documents for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy alerts_read on compliance_alerts for select to authenticated
  using (has_company_access(company_id));
create policy alerts_write on compliance_alerts for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

create policy headcount_read on headcount_snapshots for select to authenticated
  using (has_company_access(company_id));
create policy headcount_write on headcount_snapshots for all to authenticated
  using (can_manage_company(company_id)) with check (can_manage_company(company_id));

-- ---------- référentiel : lecture universelle, écriture administrateur ----------
create policy params_read on legal_parameters for select to authenticated using (true);
create policy params_write on legal_parameters for all to authenticated
  using (is_org_admin()) with check (is_org_admin());

create policy scales_read on tax_scales for select to authenticated using (true);
create policy scales_write on tax_scales for all to authenticated
  using (is_org_admin()) with check (is_org_admin());

create policy holidays_read on public_holidays for select to authenticated using (true);
create policy holidays_write on public_holidays for all to authenticated
  using (is_org_admin()) with check (is_org_admin());

create policy cba_read on collective_agreements for select to authenticated
  using (organization_id is null or organization_id = auth_org_id());
create policy cba_write on collective_agreements for all to authenticated
  using (organization_id = auth_org_id() and is_org_admin())
  with check (organization_id = auth_org_id() and is_org_admin());

create policy cbarules_read on cba_rules for select to authenticated
  using (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and (a.organization_id is null or a.organization_id = auth_org_id())));
create policy cbarules_write on cba_rules for all to authenticated
  using (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and a.organization_id = auth_org_id() and is_org_admin()))
  with check (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and a.organization_id = auth_org_id() and is_org_admin()));

create policy cbagrid_read on cba_salary_grids for select to authenticated
  using (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and (a.organization_id is null or a.organization_id = auth_org_id())));
create policy cbagrid_write on cba_salary_grids for all to authenticated
  using (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and a.organization_id = auth_org_id() and is_org_admin()))
  with check (exists (select 1 from collective_agreements a where a.id = collective_agreement_id
                 and a.organization_id = auth_org_id() and is_org_admin()));

-- ---------- audit : lisible, jamais modifiable ----------
create policy audit_read on audit_log for select to authenticated
  using (company_id is null or has_company_access(company_id));

-- =========================================================================
--  Création de l'espace de travail à l'inscription (US1)
-- =========================================================================
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_org uuid; v_name text; v_kind org_kind;
begin
  v_name := coalesce(nullif(new.raw_user_meta_data->>'organization_name',''), 'Mon espace de travail');
  v_kind := coalesce(nullif(new.raw_user_meta_data->>'organization_kind','')::org_kind, 'fiduciary');

  insert into organizations(name, kind) values (v_name, v_kind) returning id into v_org;

  insert into profiles(id, organization_id, full_name, email, is_org_admin)
  values (new.id, v_org,
          coalesce(new.raw_user_meta_data->>'full_name',''),
          coalesce(new.email,''), true);

  insert into user_roles(user_id, organization_id, company_id, role)
  values (new.id, v_org, null, 'fiduciary_admin');

  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
