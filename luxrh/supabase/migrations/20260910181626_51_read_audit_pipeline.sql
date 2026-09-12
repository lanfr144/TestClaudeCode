-- 51 — Lecture auditée par fonction pipeline
--
-- Ce qui est demandé, et sa traduction
-- ------------------------------------
-- Le modèle de référence est la fonction pipelinée d'Oracle :
--
--     SELECT c.name, Book.name, Book.author, Book.abstract
--       FROM Catalogs c, TABLE(GetBooks(c.cat)) Book;
--
-- avec, dans le corps, un contrôle d'accès, un `insert` dans un journal sous
-- `PRAGMA AUTONOMOUS_TRANSACTION`, puis `PIPE ROW(out_rec)`.
--
-- PostgreSQL rend chacun de ces trois éléments, sous un autre nom :
--
--   | Oracle                          | PostgreSQL                                  |
--   |---------------------------------|---------------------------------------------|
--   | `PIPELINED` + `PIPE ROW(rec)`   | `returns setof <type>` + `return next rec`  |
--   | `TABLE(f(x))` dans le FROM      | `cross join lateral f(x)`                   |
--   | `PRAGMA AUTONOMOUS_TRANSACTION` | `dblink` — voir la note ci-dessous          |
--
-- Le comportement est le même : les lignes sont produites une à une, l'appelant
-- peut s'arrêter avant la fin, et chaque ligne rendue laisse une trace qui survit
-- à l'annulation de la transaction appelante.
--
-- La version Oracle littérale, avec `PIPELINED`, `PIPE ROW` et le vrai `PRAGMA`,
-- est dans `schema/oracle_audit_pipeline.sql` pour le portage Oracle du projet.
--
-- Sur la transaction autonome
-- ---------------------------
-- PostgreSQL n'a pas d'équivalent natif du `PRAGMA` d'Oracle. Le seul moyen
-- d'écrire hors de la transaction courante est d'ouvrir une seconde connexion :
-- c'est ce que fait `dblink`. Cette connexion réclame une chaîne de connexion,
-- qui vit dans `app_secrets` sous la clé `dblink_conninfo`.
--
-- Si elle n'y est pas, la trace est tout de même écrite — dans la transaction
-- courante — et la ligne porte alors `is_autonomous = false`. Le journal déclare
-- ainsi sa propre faiblesse plutôt que de la taire : une trace en transaction
-- disparaît avec un `rollback`, et il faut pouvoir le savoir après coup.

create extension if not exists dblink with schema extensions;

alter table data_access_log
  add column if not exists is_autonomous boolean not null default false;

comment on column data_access_log.is_autonomous is
  'Vrai si la trace a été écrite hors de la transaction appelante, et survit donc à son annulation. Faux si dblink n''était pas configuré : la trace est alors aussi fragile que l''opération qu''elle décrit.';

-- ===========================================================================
-- 1. L'écriture autonome
-- ===========================================================================

create or replace function fn_audit_conninfo()
returns text language plpgsql stable security definer set search_path = public, extensions as $$
declare v text;
begin
  select secret into v from app_secrets where key = 'dblink_conninfo';
  return v;
end $$;

revoke execute on function fn_audit_conninfo() from public, anon, authenticated;

create or replace function fn_log_access_autonomous(
  p_subject_employee uuid,
  p_company          uuid,
  p_entity_table     text,
  p_entity_id        uuid,
  p_action           text,
  p_scope            text default null,
  p_row_count        integer default 1
) returns void language plpgsql security definer set search_path = public, extensions as $$
declare
  v_conninfo text := fn_audit_conninfo();
  v_actor    uuid := auth.uid();
  v_label    text;
  v_src      jsonb := fn_request_source();
  v_sql      text;
begin
  select full_name into v_label from profiles where id = v_actor;

  if v_conninfo is null then
    -- Repli assumé : la trace est écrite dans la transaction courante et le dit.
    insert into data_access_log(
      actor_id, actor_label, company_id, subject_employee_id, entity_table,
      entity_id, action, scope, row_count, source_ip, user_agent, request_id,
      is_autonomous)
    values (
      v_actor, v_label, p_company, p_subject_employee, p_entity_table,
      p_entity_id, p_action, p_scope, p_row_count,
      v_src ->> 'ip', v_src ->> 'user_agent', v_src ->> 'request_id',
      false);
    return;
  end if;

  -- Transaction autonome : seconde connexion, validée indépendamment. Si
  -- l'appelant annule sa transaction, la trace reste.
  v_sql := format(
    'insert into public.data_access_log('
    ' actor_id, actor_label, company_id, subject_employee_id, entity_table,'
    ' entity_id, action, scope, row_count, source_ip, user_agent, request_id,'
    ' is_autonomous) values (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, true)',
    v_actor, v_label, p_company, p_subject_employee, p_entity_table,
    p_entity_id, p_action, p_scope, p_row_count,
    v_src ->> 'ip', v_src ->> 'user_agent', v_src ->> 'request_id');

  perform extensions.dblink_exec(v_conninfo, v_sql, true);

exception when others then
  -- Une trace qui échoue ne doit pas faire échouer la lecture — mais elle ne doit
  -- pas non plus disparaître sans bruit. On retombe en transaction, en le disant.
  insert into data_access_log(
    actor_id, actor_label, company_id, subject_employee_id, entity_table,
    entity_id, action, scope, row_count, source_ip, user_agent, request_id,
    is_autonomous)
  values (
    v_actor, v_label, p_company, p_subject_employee, p_entity_table,
    p_entity_id, p_action,
    coalesce(p_scope, '') || ' [trace autonome indisponible : ' || sqlerrm || ']',
    p_row_count, v_src ->> 'ip', v_src ->> 'user_agent', v_src ->> 'request_id',
    false);
end $$;

revoke execute on function fn_log_access_autonomous(uuid, uuid, text, uuid, text, text, integer)
  from public, anon, authenticated;

comment on function fn_log_access_autonomous(uuid, uuid, text, uuid, text, text, integer) is
  'Écrit une trace de consultation hors de la transaction appelante, via dblink — équivalent PostgreSQL du PRAGMA AUTONOMOUS_TRANSACTION d''Oracle. Retombe en transaction, en le déclarant, si dblink n''est pas configuré.';

-- ===========================================================================
-- 2. Le type de ligne rendu
-- ===========================================================================
-- Une seule ligne par salarié, et seulement les colonnes demandées : les autres
-- sortent à nul. C'est la minimisation appliquée à la sortie, pas seulement au
-- stockage — le RGPD demande les deux.

do $$
begin
  if not exists (select 1 from pg_type where typname = 'employee_row') then
    create type employee_row as (
      employee_id   uuid,
      company_id    uuid,
      department_id uuid,
      first_name    text,
      last_name     text,
      email         text,
      phone         text,
      birth_date    date,
      residency     residency_kind,
      qualification qualification_kind,
      job_title     text,
      contract_kind contract_kind,
      start_date    date,
      end_date      date,
      monthly_gross numeric,
      weekly_hours  numeric,
      national_id   text,
      iban          text
    );
  end if;
end $$;

comment on type employee_row is
  'Ligne rendue par fn_employee_rows. Toute colonne non demandée dans p_fields sort à nul : la fonction ne renvoie que ce qui a été réclamé.';

-- ===========================================================================
-- 3. La fonction pipeline
-- ===========================================================================
-- Usage, à la manière du TABLE(GetBooks(c.cat)) d'Oracle :
--
--   select c.legal_name, e.last_name, e.job_title, e.monthly_gross
--     from companies c
--     cross join lateral fn_employee_rows(
--            p_company    => c.id,
--            p_active_on  => current_date,
--            p_fields     => array['last_name','job_title','monthly_gross']) e;
--
-- Les paramètres portent la clause where : société, service, salarié, recherche
-- sur le nom, date d'activité du contrat. Aucune ligne hors du périmètre demandé
-- n'est produite, et aucune ligne à laquelle l'appelant n'a pas droit ne l'est non
-- plus — le contrôle est fait ligne à ligne, avant d'émettre.

create or replace function fn_employee_rows(
  p_company     uuid    default null,
  p_department  uuid    default null,
  p_employee    uuid    default null,
  p_search      text    default null,
  p_active_on   date    default null,
  p_fields      text[]  default array['first_name','last_name'],
  p_limit       integer default 500
) returns setof employee_row
language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  ligne        record;
  sortie       employee_row;
  demande      text[] := coalesce(p_fields, '{}');
  veut_sensible boolean := demande && array['national_id','iban'];
  emises       integer := 0;
  inconnues    text[];
begin
  -- --- Garde-fous sur la demande elle-même ---------------------------------
  if p_company is null and p_employee is null then
    raise exception 'Périmètre trop large : indiquez au moins une société ou un salarié. '
                    'Une lecture sans périmètre n''est pas une lecture, c''est une extraction.';
  end if;

  select array_agg(f) into inconnues
  from unnest(demande) f
  where f not in ('employee_id','company_id','department_id','first_name','last_name',
                  'email','phone','birth_date','residency','qualification','job_title',
                  'contract_kind','start_date','end_date','monthly_gross','weekly_hours',
                  'national_id','iban');
  if inconnues is not null then
    raise exception 'Champs inconnus : %. Aucune donnée n''est renvoyée sur une demande '
                    'que la fonction ne comprend pas.', array_to_string(inconnues, ', ');
  end if;

  -- --- Contrôle d'accès sur le périmètre ------------------------------------
  if p_company is not null and not (has_company_access(p_company)) then
    perform fn_log_access_autonomous(null, p_company, 'employees', p_company, 'READ',
                                     'REFUSÉ — accès à la société', 0);
    raise exception 'Accès refusé à cette société.';
  end if;

  -- --- Parcours -------------------------------------------------------------
  for ligne in
    select e.id, e.company_id, e.department_id, e.first_name, e.last_name, e.email,
           e.phone, e.birth_date, e.residency, e.qualification,
           e.national_id_enc, e.iban_enc,
           c.job_title, c.kind as contract_kind, c.start_date, c.end_date,
           c.monthly_gross, c.weekly_hours
    from employees e
    left join lateral (
      select ct.job_title, ct.kind, ct.start_date, ct.end_date,
             ct.monthly_gross, ct.weekly_hours
      from contracts ct
      where ct.employee_id = e.id
        and (p_active_on is null
             or (ct.start_date <= p_active_on
                 and (ct.end_date is null or ct.end_date >= p_active_on)))
      order by ct.start_date desc
      limit 1
    ) c on true
    where (p_company    is null or e.company_id    = p_company)
      and (p_department is null or e.department_id = p_department)
      and (p_employee   is null or e.id            = p_employee)
      and (p_search     is null
           or e.last_name  ilike '%' || p_search || '%'
           or e.first_name ilike '%' || p_search || '%')
      and (p_active_on is null or c.job_title is not null)
    order by e.last_name, e.first_name
  loop
    -- Contrôle ligne à ligne : un gestionnaire de la société, ou le salarié
    -- lui-même. Une ligne hors droit n'est pas émise, et son refus est tracé.
    if not (has_company_access(ligne.company_id) or is_self_employee(ligne.id)) then
      perform fn_log_access_autonomous(ligne.id, ligne.company_id, 'employees',
                                       ligne.id, 'READ', 'REFUSÉ — hors périmètre', 0);
      continue;
    end if;

    -- Les données sensibles exigent un droit plus étroit que la simple lecture.
    if veut_sensible
       and not (can_manage_company(ligne.company_id) or is_self_employee(ligne.id)) then
      perform fn_log_access_autonomous(ligne.id, ligne.company_id, 'employees',
                                       ligne.id, 'DECRYPT',
                                       'REFUSÉ — matricule national, IBAN', 0);
      raise exception 'Accès refusé aux données sensibles du salarié %.', ligne.id;
    end if;

    if emises >= p_limit then
      exit;
    end if;

    -- --- Construction de la ligne : seulement les colonnes demandées --------
    -- Initialisée à dix-huit nuls plutôt qu'à NULL : affecter un champ d'une
    -- variable composite nulle dépend de la version de PostgreSQL, une ligne de
    -- nuls explicites ne dépend de rien.
    sortie := row(null, null, null, null, null, null, null, null, null,
                  null, null, null, null, null, null, null, null, null)::employee_row;
    if 'employee_id'   = any(demande) then sortie.employee_id   := ligne.id;            end if;
    if 'company_id'    = any(demande) then sortie.company_id    := ligne.company_id;    end if;
    if 'department_id' = any(demande) then sortie.department_id := ligne.department_id; end if;
    if 'first_name'    = any(demande) then sortie.first_name    := ligne.first_name;    end if;
    if 'last_name'     = any(demande) then sortie.last_name     := ligne.last_name;     end if;
    if 'email'         = any(demande) then sortie.email         := ligne.email;         end if;
    if 'phone'         = any(demande) then sortie.phone         := ligne.phone;         end if;
    if 'birth_date'    = any(demande) then sortie.birth_date    := ligne.birth_date;    end if;
    if 'residency'     = any(demande) then sortie.residency     := ligne.residency;     end if;
    if 'qualification' = any(demande) then sortie.qualification := ligne.qualification; end if;
    if 'job_title'     = any(demande) then sortie.job_title     := ligne.job_title;     end if;
    if 'contract_kind' = any(demande) then sortie.contract_kind := ligne.contract_kind; end if;
    if 'start_date'    = any(demande) then sortie.start_date    := ligne.start_date;    end if;
    if 'end_date'      = any(demande) then sortie.end_date      := ligne.end_date;      end if;
    if 'monthly_gross' = any(demande) then sortie.monthly_gross := ligne.monthly_gross; end if;
    if 'weekly_hours'  = any(demande) then sortie.weekly_hours  := ligne.weekly_hours;  end if;
    if 'national_id'   = any(demande) then sortie.national_id   := fn_decrypt_field(ligne.national_id_enc); end if;
    if 'iban'          = any(demande) then sortie.iban          := fn_decrypt_field(ligne.iban_enc);        end if;

    -- --- La trace, AVANT d'émettre la ligne ---------------------------------
    -- Équivalent du bloc qui précède `PIPE ROW(out_rec)` en Oracle : la trace est
    -- écrite d'abord, hors transaction, de sorte qu'une lecture interrompue ou
    -- annulée reste consignée.
    perform fn_log_access_autonomous(
      ligne.id, ligne.company_id, 'employees', ligne.id,
      case when veut_sensible then 'DECRYPT' else 'READ' end,
      array_to_string(demande, ', '), 1);

    return next sortie;          -- ← PIPE ROW(out_rec)
    emises := emises + 1;
  end loop;

  return;
end $$;

comment on function fn_employee_rows(uuid, uuid, uuid, text, date, text[], integer) is
  'Lecture auditée des salariés, ligne par ligne. Les paramètres portent la clause where ; p_fields porte la projection. Chaque ligne est contrôlée puis tracée hors transaction avant d''être émise. Équivalent PostgreSQL d''une fonction pipelinée Oracle.';

revoke execute on function fn_employee_rows(uuid, uuid, uuid, text, date, text[], integer)
  from public, anon;
grant  execute on function fn_employee_rows(uuid, uuid, uuid, text, date, text[], integer)
  to authenticated;

-- ===========================================================================
-- 4. Le même patron pour le registre du temps
-- ===========================================================================
-- Deuxième exemple, pour que le patron soit lisible plutôt que deviné.

do $$
begin
  if not exists (select 1 from pg_type where typname = 'time_entry_row') then
    create type time_entry_row as (
      entry_id      uuid,
      employee_id   uuid,
      entry_date    date,
      worked_hours  numeric,
      overtime_hours numeric,
      night_hours   numeric,
      sunday_hours  numeric,
      holiday_hours numeric,
      is_validated  boolean
    );
  end if;
end $$;

create or replace function fn_time_entry_rows(
  p_employee  uuid,
  p_from      date,
  p_to        date,
  p_only_validated boolean default false,
  p_limit     integer default 1000
) returns setof time_entry_row
language plpgsql volatile security definer set search_path = public, extensions as $$
declare ligne record; sortie time_entry_row; v_company uuid; emises integer := 0;
begin
  if p_from is null or p_to is null then
    raise exception 'Indiquez une période : une lecture du registre du temps sans bornes '
                    'n''est pas justifiable au titre de la minimisation.';
  end if;

  select company_id into v_company from employees where id = p_employee;
  if v_company is null then
    raise exception 'Salarié introuvable : %', p_employee;
  end if;
  if not (has_company_access(v_company) or is_self_employee(p_employee)) then
    perform fn_log_access_autonomous(p_employee, v_company, 'time_entries', null,
                                     'READ', 'REFUSÉ', 0);
    raise exception 'Accès refusé au registre du temps de ce salarié.';
  end if;

  for ligne in
    select t.id, t.employee_id, t.entry_date, t.worked_hours, t.overtime_hours,
           t.night_hours, t.sunday_hours, t.holiday_hours, t.is_validated
    from time_entries t
    where t.employee_id = p_employee
      and t.entry_date between p_from and p_to
      and (not p_only_validated or t.is_validated)
    order by t.entry_date
  loop
    exit when emises >= p_limit;
    sortie := row(ligne.id, ligne.employee_id, ligne.entry_date, ligne.worked_hours,
                  ligne.overtime_hours, ligne.night_hours, ligne.sunday_hours,
                  ligne.holiday_hours, ligne.is_validated)::time_entry_row;

    perform fn_log_access_autonomous(
      p_employee, v_company, 'time_entries', ligne.id, 'READ',
      format('registre du temps %s → %s', p_from, p_to), 1);

    return next sortie;          -- ← PIPE ROW(out_rec)
    emises := emises + 1;
  end loop;
  return;
end $$;

comment on function fn_time_entry_rows(uuid, date, date, boolean, integer) is
  'Lecture auditée du registre du temps sur une période bornée. Même patron que fn_employee_rows : contrôle, trace autonome, puis émission ligne à ligne.';

revoke execute on function fn_time_entry_rows(uuid, date, date, boolean, integer) from public, anon;
grant  execute on function fn_time_entry_rows(uuid, date, date, boolean, integer) to authenticated;

-- ===========================================================================
-- 5. Ce qu'il reste à faire, et qui n'est pas du SQL
-- ===========================================================================
-- Pour que la trace soit réellement autonome, il faut déposer la chaîne de
-- connexion dans app_secrets :
--
--   insert into app_secrets(key, secret)
--   values ('dblink_conninfo', 'dbname=postgres user=... password=... host=... port=5432')
--   on conflict (key) do update set secret = excluded.secret;
--
-- Tant qu'elle n'y est pas, les traces sont écrites en transaction et portent
-- `is_autonomous = false`. Elles existent, elles sont simplement aussi fragiles
-- que l'opération qu'elles décrivent.
--
-- Requête de contrôle :
--   select is_autonomous, count(*) from data_access_log group by 1;
