-- 49 — Journal des accès : qui, quoi, quand, d'où
--
-- Constat avant cette migration
-- ------------------------------
-- Trois questions du RGPD sur quatre restaient sans réponse.
--
--   audit_log   13 tables sous déclencheur fn_audit, en ÉCRITURE seulement.
--               `employees`, `documents` et `employee_tax_cards` — les trois
--               tables les plus chargées en données personnelles — n'en avaient
--               aucun.
--   export_log  les exports de portabilité, avec leur auteur et leur volume.
--   lectures    RIEN. Aucune consultation n'était tracée, pas même le
--               déchiffrement du matricule national et de l'IBAN.
--   provenance  RIEN. Aucune adresse, aucun agent utilisateur, nulle part.
--
-- Un responsable de traitement doit pouvoir établir qui a vu les données d'une
-- personne, lesquelles, quand, et depuis où (RGPD art. 5.2 sur la responsabilité,
-- art. 15 sur le droit d'accès, art. 30 sur le registre, art. 32 sur la sécurité).
-- Cette migration donne les quatre réponses.
--
-- Ce qu'elle ne prétend pas faire
-- --------------------------------
-- Elle ne journalise pas *toute* lecture de *toute* colonne : tracer chaque
-- `select` d'une liste d'employés produirait un volume ingérable et noierait le
-- signal. Elle trace les accès qui comptent — données sensibles déchiffrées,
-- exports, consultations de dossier individuel — et l'article 30 se satisfait
-- d'une traçabilité proportionnée au risque. La liste des points instrumentés
-- est explicite en fin de migration.

-- ===========================================================================
-- 1. D'où vient l'appel
-- ===========================================================================
-- PostgREST expose les en-têtes HTTP de la requête dans le paramètre de session
-- `request.headers`. C'est la seule source de provenance disponible en base :
-- `inet_client_addr()` ne voit que le pooler de Supabase, pas le poste appelant.

create or replace function fn_request_source()
returns jsonb language plpgsql stable set search_path = public as $$
declare v_headers jsonb;
begin
  begin
    v_headers := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then
    v_headers := null;                       -- appel hors PostgREST (psql, tâche)
  end;

  return jsonb_build_object(
    -- x-forwarded-for peut porter une chaîne de relais : le premier est l'origine.
    'ip', coalesce(
            nullif(btrim(split_part(v_headers ->> 'x-forwarded-for', ',', 1)), ''),
            v_headers ->> 'cf-connecting-ip',
            host(inet_client_addr())),
    'user_agent', left(v_headers ->> 'user-agent', 400),
    'request_id', coalesce(v_headers ->> 'x-request-id', v_headers ->> 'cf-ray')
  );
end $$;

comment on function fn_request_source() is
  'Provenance de l''appel courant, lue dans les en-têtes HTTP exposés par PostgREST. Renvoie des valeurs nulles hors contexte HTTP, jamais une erreur : une trace incomplète vaut mieux qu''une écriture refusée.';

-- L'adresse est stockée en `text` et non en `inet` : un en-tête `x-forwarded-for`
-- est une donnée d'entrée non fiable, et un cast raté ferait échouer l'écriture
-- qu'on cherche justement à tracer.

-- ===========================================================================
-- 2. La provenance sur les journaux existants
-- ===========================================================================

alter table audit_log  add column if not exists source_ip   text;
alter table audit_log  add column if not exists user_agent  text;
alter table audit_log  add column if not exists request_id  text;
alter table export_log add column if not exists source_ip   text;
alter table export_log add column if not exists user_agent  text;
alter table export_log add column if not exists request_id  text;

comment on column audit_log.source_ip  is $c$Adresse d'origine de la requête, telle que rapportée par les en-têtes HTTP. Donnée déclarative : elle situe, elle ne prouve pas.$c$;
comment on column audit_log.user_agent is $c$Agent utilisateur de l'appelant, tronqué à 400 caractères.$c$;
comment on column audit_log.request_id is $c$Identifiant de requête, pour recouper une trace avec les journaux d'infrastructure.$c$;
comment on column export_log.source_ip  is $c$Adresse d'origine de la demande d'export.$c$;
comment on column export_log.user_agent is $c$Agent utilisateur de l'appelant.$c$;
comment on column export_log.request_id is $c$Identifiant de requête, pour recoupement.$c$;

-- Un déclencheur remplit ces colonnes : aucune fonction du moteur n'a besoin
-- d'être réécrite, et une insertion future dans ces journaux sera tracée sans
-- que son auteur ait à y penser.

create or replace function fn_stamp_source()
returns trigger language plpgsql set search_path = public as $$
declare v_src jsonb := fn_request_source();
begin
  new.source_ip  := coalesce(new.source_ip,  v_src ->> 'ip');
  new.user_agent := coalesce(new.user_agent, v_src ->> 'user_agent');
  new.request_id := coalesce(new.request_id, v_src ->> 'request_id');
  return new;
end $$;

drop trigger if exists stamp_source on audit_log;
create trigger stamp_source before insert on audit_log
  for each row execute function fn_stamp_source();

drop trigger if exists stamp_source on export_log;
create trigger stamp_source before insert on export_log
  for each row execute function fn_stamp_source();

-- ===========================================================================
-- 3. Le journal des consultations
-- ===========================================================================

create table if not exists data_access_log (
  id                  bigint generated always as identity primary key,
  occurred_at         timestamptz not null default now(),
  actor_id            uuid,
  actor_label         text,
  company_id          uuid,
  subject_employee_id uuid,
  entity_table        text not null,
  entity_id           uuid,
  action              text not null,
  scope               text,
  row_count           integer,
  source_ip           text,
  user_agent          text,
  request_id          text,
  constraint access_action_known
    check (action in ('READ', 'DECRYPT', 'EXPORT', 'DOWNLOAD'))
);

comment on table data_access_log is $c$Journal des consultations de données personnelles. Complète audit_log, qui ne voit que les écritures : ici sont tracés les accès en LECTURE aux données sensibles, les déchiffrements et les téléchargements de pièces. Répond aux questions qui / quoi / quand / d'où pour une personne donnée.$c$;
comment on column data_access_log.subject_employee_id is $c$La personne DONT les données ont été vues — à ne pas confondre avec actor_id, qui est celle qui les a vues.$c$;
comment on column data_access_log.action is $c$READ consultation, DECRYPT déchiffrement d'une donnée sensible, EXPORT extraction, DOWNLOAD téléchargement d'une pièce.$c$;
comment on column data_access_log.scope is $c$Ce qui a été vu, en clair : « matricule national, IBAN », « dossier complet ». Jamais la valeur elle-même.$c$;
comment on column data_access_log.actor_label is $c$Nom de l'auteur figé au moment de l'accès : la trace reste lisible après suppression du compte.$c$;

create index if not exists idx_access_log_subject
  on data_access_log (subject_employee_id, occurred_at desc);
create index if not exists idx_access_log_actor
  on data_access_log (actor_id, occurred_at desc);
create index if not exists idx_access_log_company
  on data_access_log (company_id, occurred_at desc);

-- Règle 6 du CLAUDE.md : RLS sur toutes les tables, sans exception.
alter table data_access_log enable row level security;

-- Lecture : les gestionnaires de la société concernée, et la personne elle-même
-- pour ce qui la concerne — c'est la contrepartie du droit d'accès.
create policy access_log_read on data_access_log
  for select to authenticated
  using (
    (company_id is not null and can_manage_company(company_id))
    or (subject_employee_id is not null and is_self_employee(subject_employee_id))
  );

-- Personne n'écrit ni ne modifie ce journal depuis l'API : seules les fonctions
-- security definer du moteur y insèrent. Aucune politique d'insertion, de mise à
-- jour ni de suppression n'est créée, et c'est délibéré — un journal que son
-- sujet peut effacer ne prouve rien.

create trigger stamp_source before insert on data_access_log
  for each row execute function fn_stamp_source();

-- ===========================================================================
-- 4. Écrire dans le journal
-- ===========================================================================

create or replace function fn_log_access(
  p_subject_employee uuid,
  p_entity_table     text,
  p_entity_id        uuid,
  p_action           text,
  p_scope            text default null,
  p_row_count        integer default null
) returns void language plpgsql security definer set search_path = public as $$
declare v_company uuid;
begin
  if p_subject_employee is not null then
    select company_id into v_company from employees where id = p_subject_employee;
  end if;

  insert into data_access_log(
    actor_id, actor_label, company_id, subject_employee_id,
    entity_table, entity_id, action, scope, row_count)
  values (
    auth.uid(),
    (select full_name from profiles where id = auth.uid()),
    v_company, p_subject_employee,
    p_entity_table, p_entity_id, p_action, p_scope, p_row_count);
end $$;

comment on function fn_log_access(uuid, text, uuid, text, text, integer) is
  'Enregistre une consultation. Appelée par les fonctions du moteur, jamais par l''API : elle est révoquée pour tous les rôles applicatifs.';

revoke execute on function fn_log_access(uuid, text, uuid, text, text, integer)
  from authenticated, anon, public;

-- ===========================================================================
-- 5. Le déchiffrement des données sensibles est désormais tracé
-- ===========================================================================
-- Seule modification de comportement de cette migration. La fonction passe de
-- `stable` à `volatile` : une fonction stable ne peut pas écrire, et sans écriture
-- il n'y a pas de trace. Le contrôle d'accès est inchangé, à la lettre.

create or replace function fn_employee_sensitive(p_employee uuid)
returns table(national_id text, iban text)
language plpgsql volatile security definer set search_path = public as $$
declare v_company uuid;
begin
  select company_id into v_company from employees where id = p_employee;
  if v_company is null then raise exception 'Employé introuvable'; end if;
  if not (can_manage_company(v_company)
          or exists (select 1 from employees e where e.id = p_employee and e.user_id = auth.uid())) then
    -- L'accès refusé se trace aussi : une tentative repoussée est un signal.
    perform fn_log_access(p_employee, 'employees', p_employee, 'DECRYPT',
                          'REFUSÉ — matricule national, IBAN', 0);
    raise exception 'Accès refusé aux données sensibles';
  end if;

  perform fn_log_access(p_employee, 'employees', p_employee, 'DECRYPT',
                        'matricule national, IBAN', 1);

  return query
    select fn_decrypt_field(e.national_id_enc), fn_decrypt_field(e.iban_enc)
    from employees e where e.id = p_employee;
end $$;

comment on function fn_employee_sensitive(uuid) is
  'Déchiffre le matricule national et l''IBAN après contrôle d''accès. Chaque appel, accepté ou refusé, laisse une ligne dans data_access_log.';

-- ===========================================================================
-- 6. Les trois tables de données personnelles qui n'étaient pas auditées
-- ===========================================================================

create trigger audit_employees
  after insert or update or delete on employees
  for each row execute function fn_audit();

create trigger audit_documents
  after insert or update or delete on documents
  for each row execute function fn_audit();

create trigger audit_tax_cards
  after insert or update or delete on employee_tax_cards
  for each row execute function fn_audit();

create trigger audit_meal_vouchers
  after insert or update or delete on meal_voucher_grants
  for each row execute function fn_audit();

-- ===========================================================================
-- 7. Le journal d'écritures ne conserve plus de chiffré
-- ===========================================================================
-- `employees` porte national_id_enc et iban_enc. Sans précaution, chaque écriture
-- en aurait déposé une copie chiffrée dans audit_log : autant de copies à protéger,
-- pour une valeur que le journal n'a aucune raison de connaître. fn_audit remplace
-- désormais toute colonne dont le nom finit par `_enc` par une mention.

create or replace function fn_redact_encrypted(p_row jsonb)
returns jsonb language sql immutable set search_path = public as $$
  select coalesce(
    jsonb_object_agg(
      cle,
      case when cle like '%\_enc' then to_jsonb('[chiffré]'::text) else valeur end),
    '{}'::jsonb)
  from jsonb_each(coalesce(p_row, '{}'::jsonb)) as t(cle, valeur);
$$;

comment on function fn_redact_encrypted(jsonb) is
  'Remplace la valeur de toute colonne dont le nom finit par _enc. Le journal dit qu''une donnée chiffrée a changé, sans en conserver une copie de plus.';

revoke execute on function fn_redact_encrypted(jsonb) from authenticated, anon, public;

create or replace function fn_audit()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_company uuid; v_row jsonb;
begin
  v_row := to_jsonb(coalesce(new, old));
  v_company := nullif(v_row ->> 'company_id','')::uuid;

  insert into audit_log(actor_id, actor_label, company_id, entity_table, entity_id,
                        action, old_value, new_value)
  values (
    auth.uid(),
    (select full_name from profiles where id = auth.uid()),
    v_company,
    tg_table_name,
    nullif(v_row ->> 'id','')::uuid,
    tg_op,
    case when tg_op in ('UPDATE','DELETE') then fn_redact_encrypted(to_jsonb(old)) end,
    case when tg_op in ('UPDATE','INSERT') then fn_redact_encrypted(to_jsonb(new)) end
  );
  return coalesce(new, old);
end $$;

-- ===========================================================================
-- 8. La réponse : qui, quoi, quand, d'où
-- ===========================================================================

create or replace function fn_person_access_report(
  p_employee uuid,
  p_from     timestamptz default null,
  p_to       timestamptz default null
) returns table(
  quand       timestamptz,
  qui         text,
  qui_id      uuid,
  quoi        text,
  detail      text,
  nature      text,
  d_ou        text,
  agent       text,
  requete     text
) language plpgsql stable security definer set search_path = public as $$
declare v_company uuid;
begin
  select company_id into v_company from employees where id = p_employee;
  if v_company is null then
    raise exception 'Employé introuvable : %', p_employee;
  end if;
  if not (can_manage_company(v_company) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé : ce registre est réservé aux gestionnaires de la société et à la personne concernée.';
  end if;

  return query
    -- Consultations et déchiffrements
    select a.occurred_at, coalesce(a.actor_label, '(compte supprimé)'), a.actor_id,
           a.entity_table, a.scope, a.action, a.source_ip, a.user_agent, a.request_id
    from data_access_log a
    where a.subject_employee_id = p_employee

    union all
    -- Écritures sur les tables rattachées à la personne
    select l.occurred_at, coalesce(l.actor_label, '(compte supprimé)'), l.actor_id,
           l.entity_table, null::text, l.action, l.source_ip, l.user_agent, l.request_id
    from audit_log l
    where l.entity_id = p_employee
       or (l.entity_table = 'contracts'  and l.new_value ->> 'employee_id' = p_employee::text)
       or (l.entity_table = 'absences'   and l.new_value ->> 'employee_id' = p_employee::text)
       or (l.entity_table = 'shifts'     and l.new_value ->> 'employee_id' = p_employee::text)
       or (l.entity_table = 'time_entries' and l.new_value ->> 'employee_id' = p_employee::text)

    union all
    -- Exports de portabilité qui portent sur la personne
    select e.created_at, coalesce(pr.full_name, '(compte supprimé)'), e.requested_by,
           'export:' || e.subject_kind, e.row_count || ' objets', 'EXPORT',
           e.source_ip, e.user_agent, e.request_id
    from export_log e
    left join profiles pr on pr.id = e.requested_by
    where e.subject_kind = 'employee' and e.subject_id = p_employee

    order by 1 desc;
end $$;

comment on function fn_person_access_report(uuid, timestamptz, timestamptz) is
  'Registre des accès aux données d''une personne : qui, quoi, quand, d''où. Réservé aux gestionnaires de sa société et à elle-même. Sert de pièce au droit d''accès (RGPD art. 15) et au registre des traitements (art. 30).';

revoke execute on function fn_person_access_report(uuid, timestamptz, timestamptz) from public, anon;
grant  execute on function fn_person_access_report(uuid, timestamptz, timestamptz) to authenticated;

-- Les fonctions nouvelles ne doivent pas hériter du `execute` accordé à PUBLIC
-- à la création — c'est l'oubli corrigé par la migration 46.
revoke execute on function fn_request_source() from public, anon, authenticated;
revoke execute on function fn_stamp_source()   from public, anon, authenticated;

-- ===========================================================================
-- Points instrumentés, et ceux qui restent à instrumenter
-- ===========================================================================
-- Tracé par cette migration :
--   · déchiffrement du matricule national et de l'IBAN, accepté ou refusé
--   · écritures sur employees, documents, employee_tax_cards, meal_voucher_grants,
--     en plus des treize tables déjà couvertes
--   · provenance (adresse, agent, identifiant de requête) sur les trois journaux
--
-- Restent à instrumenter, dans une migration ultérieure — chacune suppose de
-- redéfinir la fonction concernée pour y insérer un appel à fn_log_access :
--   · fn_export_self, fn_export_employee, fn_export_company : l'export_log les
--     couvre déjà pour le « qui / quoi / quand », mais pas la ligne de lecture
--     correspondante dans data_access_log
--   · la consultation d'un dossier salarié depuis l'écran EmployeeDetail
--   · le téléchargement d'une pièce depuis le stockage (action DOWNLOAD)
--
-- À décider, hors migration : la durée de conservation de ces journaux. Le RGPD
-- impose de la fixer, pas de la fixer à une valeur précise. Elle dépend du délai
-- de prescription retenu et n'est donc pas un paramètre technique.
