-- La policy de `schedules` interrogeait `shifts`, dont la policy interrogeait
-- `schedules` : PostgreSQL détectait une récursion infinie et refusait toute
-- lecture de planning. On passe par des fonctions SECURITY DEFINER, qui ne
-- déclenchent pas de nouvelle évaluation de policy.

create or replace function has_shift_in_schedule(p_schedule uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from shifts s
    join employees e on e.id = s.employee_id
    where s.schedule_id = p_schedule and e.user_id = auth.uid()
  );
$$;

create or replace function schedule_is_published(p_schedule uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from schedules sc where sc.id = p_schedule and sc.status = 'published');
$$;

revoke execute on function has_shift_in_schedule(uuid) from anon, public;
revoke execute on function schedule_is_published(uuid) from anon, public;
grant  execute on function has_shift_in_schedule(uuid) to authenticated;
grant  execute on function schedule_is_published(uuid) to authenticated;

-- Le salarié ne voit que les plannings publiés sur lesquels il figure.
drop policy schedules_read on schedules;
create policy schedules_read on schedules for select to authenticated
  using (
    has_company_access(company_id)
    or (status = 'published' and has_shift_in_schedule(id))
  );

-- Et il ne voit ses shifts que si le planning qui les porte est publié.
drop policy shifts_read on shifts;
create policy shifts_read on shifts for select to authenticated
  using (
    has_company_access(company_id)
    or (is_self_employee(employee_id) and schedule_is_published(schedule_id))
  );
