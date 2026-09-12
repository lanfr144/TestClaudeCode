-- Lecture auditée par fonction pipelinée — portage ORACLE
--
-- Contrairement à `oracle.sql`, ce fichier n'est PAS généré : il est écrit à la
-- main et maintenu à la main. `tools/emit_portable_schema.py` dérive les tables
-- du catalogue PostgreSQL ; il ne dérive pas le code procédural, qui n'a pas
-- d'équivalent mécanique d'un dialecte à l'autre.
--
-- Il est le pendant de la migration
-- `luxrh/supabase/migrations/20260910190000_50_read_audit_pipeline.sql`, dont il
-- reprend la logique avec les constructions natives d'Oracle :
--
--   PIPELINED / PIPE ROW ............ émission ligne à ligne
--   PRAGMA AUTONOMOUS_TRANSACTION ... trace qui survit au rollback de l'appelant
--   TABLE(f(x)) ..................... jointure latérale dans le FROM
--
-- Usage, exactement la forme demandée :
--
--   SELECT c."LEGAL_NAME", e.last_name, e.job_title, e.monthly_gross
--     FROM "COMPANIES" c,
--          TABLE(luxrh_audit.employee_rows(
--                  p_company   => c."ID",
--                  p_active_on => SYSDATE,
--                  p_fields    => 'last_name,job_title,monthly_gross')) e;
--
-- UNE DIFFÉRENCE À CONNAÎTRE
-- --------------------------
-- Sur PostgreSQL, l'identité de l'appelant vient de `auth.uid()` et l'isolation
-- est imposée par RLS. Oracle ne porte pas le moteur LuxRH et n'a pas de RLS
-- active dans ce projet (voir `docs/bases-de-donnees.md`). L'identité doit donc
-- être posée par l'application dans un contexte applicatif AVANT tout appel :
--
--   BEGIN luxrh_ctx.set_identity('<uuid-utilisateur>'); END;
--
-- Sans cela, la fonction refuse de produire la moindre ligne. C'est délibéré :
-- un contrôle d'accès qui échoue en position ouverte ne contrôle rien.

-- ===========================================================================
-- 1. Contexte applicatif : qui appelle
-- ===========================================================================

create or replace context LUXRH_CTX using luxrh_ctx;
/

create or replace package luxrh_ctx as
  procedure set_identity(p_user_id in varchar2);
  function  current_user_id return varchar2;
  procedure clear_identity;
end luxrh_ctx;
/

create or replace package body luxrh_ctx as

  procedure set_identity(p_user_id in varchar2) is
  begin
    dbms_session.set_context('LUXRH_CTX', 'USER_ID', p_user_id);
  end set_identity;

  function current_user_id return varchar2 is
  begin
    return sys_context('LUXRH_CTX', 'USER_ID');
  end current_user_id;

  procedure clear_identity is
  begin
    dbms_session.clear_context('LUXRH_CTX', null, 'USER_ID');
  end clear_identity;

end luxrh_ctx;
/

-- ===========================================================================
-- 2. Le type de ligne rendu
-- ===========================================================================
-- Toute colonne non demandée sort à NULL : la fonction ne rend que ce qui a été
-- réclamé, en colonnes comme en lignes.

create or replace type employee_row_t as object (
  employee_id    varchar2(36),
  company_id     varchar2(36),
  department_id  varchar2(36),
  first_name     varchar2(4000),
  last_name      varchar2(4000),
  email          varchar2(4000),
  phone          varchar2(4000),
  birth_date     date,
  residency      varchar2(20),
  qualification  varchar2(20),
  job_title      varchar2(4000),
  contract_kind  varchar2(20),
  start_date     date,
  end_date       date,
  monthly_gross  number(10,2),
  weekly_hours   number(5,2)
);
/

create or replace type employee_rows_t as table of employee_row_t;
/

-- ===========================================================================
-- 3. Le paquetage
-- ===========================================================================

create or replace package luxrh_audit as

  -- Trace une consultation. Transaction autonome : la ligne est validée même si
  -- l'appelant annule la sienne.
  procedure log_access(
    p_subject_employee in varchar2,
    p_company          in varchar2,
    p_entity_table     in varchar2,
    p_entity_id        in varchar2,
    p_action           in varchar2,
    p_scope            in varchar2 default null,
    p_row_count        in number   default 1);

  -- Lecture auditée des salariés. Les paramètres portent la clause WHERE,
  -- p_fields porte la projection (liste séparée par des virgules).
  function employee_rows(
    p_company    in varchar2 default null,
    p_department in varchar2 default null,
    p_employee   in varchar2 default null,
    p_search     in varchar2 default null,
    p_active_on  in date     default null,
    p_fields     in varchar2 default 'first_name,last_name',
    p_limit      in number   default 500
  ) return employee_rows_t pipelined;

end luxrh_audit;
/

create or replace package body luxrh_audit as

  -- ---------------------------------------------------------------------
  -- La transaction autonome
  -- ---------------------------------------------------------------------
  procedure log_access(
    p_subject_employee in varchar2,
    p_company          in varchar2,
    p_entity_table     in varchar2,
    p_entity_id        in varchar2,
    p_action           in varchar2,
    p_scope            in varchar2 default null,
    p_row_count        in number   default 1)
  is
    pragma autonomous_transaction;               -- ← ce que demande la consigne
    v_actor varchar2(36) := luxrh_ctx.current_user_id;
    v_label varchar2(4000);
  begin
    begin
      select "FULL_NAME" into v_label from "PROFILES" where "ID" = v_actor;
    exception when no_data_found then v_label := null;
    end;

    insert into "DATA_ACCESS_LOG" (
      "OCCURRED_AT", "ACTOR_ID", "ACTOR_LABEL", "COMPANY_ID",
      "SUBJECT_EMPLOYEE_ID", "ENTITY_TABLE", "ENTITY_ID", "ACTION",
      "SCOPE", "ROW_COUNT", "SOURCE_IP", "USER_AGENT", "REQUEST_ID",
      "IS_AUTONOMOUS")
    values (
      systimestamp, v_actor, v_label, p_company,
      p_subject_employee, p_entity_table, p_entity_id, p_action,
      p_scope, p_row_count,
      sys_context('USERENV', 'IP_ADDRESS'),
      sys_context('USERENV', 'MODULE'),
      sys_context('USERENV', 'SID'),
      1);

    commit;                                      -- valide la transaction autonome
  exception
    when others then
      -- Une trace qui échoue ne doit pas faire échouer la lecture, mais elle ne
      -- doit pas non plus disparaître sans bruit : on annule la transaction
      -- autonome et on laisse remonter le contexte à l'appel suivant.
      rollback;
      raise;
  end log_access;

  -- ---------------------------------------------------------------------
  -- Le contrôle d'accès
  -- ---------------------------------------------------------------------
  function has_company_access(p_company in varchar2) return boolean is
    v_count number;
  begin
    if luxrh_ctx.current_user_id is null then
      return false;                              -- échec en position fermée
    end if;
    select count(*) into v_count
    from "USER_ROLES" r
    where r."USER_ID" = luxrh_ctx.current_user_id
      and (r."COMPANY_ID" = p_company or r."COMPANY_ID" is null);
    return v_count > 0;
  end has_company_access;

  function is_self_employee(p_employee in varchar2) return boolean is
    v_count number;
  begin
    if luxrh_ctx.current_user_id is null then
      return false;
    end if;
    select count(*) into v_count
    from "EMPLOYEES" e
    where e."ID" = p_employee
      and e."USER_ID" = luxrh_ctx.current_user_id;
    return v_count > 0;
  end is_self_employee;

  function wants(p_fields in varchar2, p_name in varchar2) return boolean is
  begin
    return ',' || replace(p_fields, ' ', '') || ',' like '%,' || p_name || ',%';
  end wants;

  -- ---------------------------------------------------------------------
  -- La fonction pipelinée
  -- ---------------------------------------------------------------------
  function employee_rows(
    p_company    in varchar2 default null,
    p_department in varchar2 default null,
    p_employee   in varchar2 default null,
    p_search     in varchar2 default null,
    p_active_on  in date     default null,
    p_fields     in varchar2 default 'first_name,last_name',
    p_limit      in number   default 500
  ) return employee_rows_t pipelined
  is
    out_rec  employee_row_t := employee_row_t(null, null, null, null, null, null,
                                              null, null, null, null, null, null,
                                              null, null, null, null);
    v_emises number := 0;
  begin
    if luxrh_ctx.current_user_id is null then
      raise_application_error(-20001,
        'Identité non posée : appelez luxrh_ctx.set_identity avant toute lecture.');
    end if;

    if p_company is null and p_employee is null then
      raise_application_error(-20002,
        'Périmètre trop large : indiquez au moins une société ou un salarié.');
    end if;

    if p_company is not null and not has_company_access(p_company) then
      log_access(null, p_company, 'EMPLOYEES', p_company, 'READ',
                 'REFUSÉ — accès à la société', 0);
      raise_application_error(-20003, 'Accès refusé à cette société.');
    end if;

    for ligne in (
      select e."ID"            as employee_id,
             e."COMPANY_ID"    as company_id,
             e."DEPARTMENT_ID" as department_id,
             e."FIRST_NAME"    as first_name,
             e."LAST_NAME"     as last_name,
             e."EMAIL"         as email,
             e."PHONE"         as phone,
             e."BIRTH_DATE"    as birth_date,
             e."RESIDENCY"     as residency,
             e."QUALIFICATION" as qualification,
             c."JOB_TITLE"     as job_title,
             c."KIND"          as contract_kind,
             c."START_DATE"    as start_date,
             c."END_DATE"      as end_date,
             c."MONTHLY_GROSS" as monthly_gross,
             c."WEEKLY_HOURS"  as weekly_hours
      from "EMPLOYEES" e
      outer apply (
        select ct."JOB_TITLE", ct."KIND", ct."START_DATE", ct."END_DATE",
               ct."MONTHLY_GROSS", ct."WEEKLY_HOURS"
        from "CONTRACTS" ct
        where ct."EMPLOYEE_ID" = e."ID"
          and (p_active_on is null
               or (ct."START_DATE" <= p_active_on
                   and (ct."END_DATE" is null or ct."END_DATE" >= p_active_on)))
        order by ct."START_DATE" desc
        fetch first 1 rows only
      ) c
      where (p_company    is null or e."COMPANY_ID"    = p_company)
        and (p_department is null or e."DEPARTMENT_ID" = p_department)
        and (p_employee   is null or e."ID"            = p_employee)
        and (p_search     is null
             or upper(e."LAST_NAME")  like '%' || upper(p_search) || '%'
             or upper(e."FIRST_NAME") like '%' || upper(p_search) || '%')
      order by e."LAST_NAME", e."FIRST_NAME"
    ) loop

      -- Contrôle ligne à ligne, avant toute émission.
      if not (has_company_access(ligne.company_id)
              or is_self_employee(ligne.employee_id)) then
        log_access(ligne.employee_id, ligne.company_id, 'EMPLOYEES',
                   ligne.employee_id, 'READ', 'REFUSÉ — hors périmètre', 0);
        continue;
      end if;

      exit when v_emises >= p_limit;

      -- Projection : seulement les colonnes demandées, les autres restent nulles.
      out_rec := employee_row_t(null, null, null, null, null, null, null, null,
                                null, null, null, null, null, null, null, null);
      if wants(p_fields, 'employee_id')   then out_rec.employee_id   := ligne.employee_id;   end if;
      if wants(p_fields, 'company_id')    then out_rec.company_id    := ligne.company_id;    end if;
      if wants(p_fields, 'department_id') then out_rec.department_id := ligne.department_id; end if;
      if wants(p_fields, 'first_name')    then out_rec.first_name    := ligne.first_name;    end if;
      if wants(p_fields, 'last_name')     then out_rec.last_name     := ligne.last_name;     end if;
      if wants(p_fields, 'email')         then out_rec.email         := ligne.email;         end if;
      if wants(p_fields, 'phone')         then out_rec.phone         := ligne.phone;         end if;
      if wants(p_fields, 'birth_date')    then out_rec.birth_date    := ligne.birth_date;    end if;
      if wants(p_fields, 'residency')     then out_rec.residency     := ligne.residency;     end if;
      if wants(p_fields, 'qualification') then out_rec.qualification := ligne.qualification; end if;
      if wants(p_fields, 'job_title')     then out_rec.job_title     := ligne.job_title;     end if;
      if wants(p_fields, 'contract_kind') then out_rec.contract_kind := ligne.contract_kind; end if;
      if wants(p_fields, 'start_date')    then out_rec.start_date    := ligne.start_date;    end if;
      if wants(p_fields, 'end_date')      then out_rec.end_date      := ligne.end_date;      end if;
      if wants(p_fields, 'monthly_gross') then out_rec.monthly_gross := ligne.monthly_gross; end if;
      if wants(p_fields, 'weekly_hours')  then out_rec.weekly_hours  := ligne.weekly_hours;  end if;

      -- La trace AVANT l'émission, en transaction autonome.
      log_access(ligne.employee_id, ligne.company_id, 'EMPLOYEES',
                 ligne.employee_id, 'READ', p_fields, 1);

      pipe row(out_rec);
      v_emises := v_emises + 1;

    end loop;

    return;
  end employee_rows;

end luxrh_audit;
/

-- ===========================================================================
-- 4. Les données sensibles ne passent pas par cette fonction
-- ===========================================================================
-- `employee_row_t` ne porte ni matricule national ni IBAN, et c'est délibéré : le
-- chiffrement pgcrypto n'a pas d'équivalent porté sur Oracle dans ce projet, et
-- `backends.py` lève `EngineUnavailable` plutôt que de rendre une valeur
-- vraisemblable. Rendre ces colonnes ici supposerait de les avoir déchiffrées
-- ailleurs — donc de les avoir exposées.
--
-- Sur PostgreSQL, `fn_employee_rows` les rend, sous un contrôle d'accès plus
-- étroit que la simple lecture et avec une trace de type DECRYPT.
