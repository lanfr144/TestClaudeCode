-- 58 — Table des comptes portable, et catalogue du schéma
--
-- Deux besoins distincts, réunis parce qu'ils débloquent la même chose.
--
-- 1. `app_users` — la table de comptes que les cibles Oracle et MySQL n'ont pas
--    -------------------------------------------------------------------------
--    Quatorze clés étrangères du schéma pointent vers `auth.users`, propre à
--    Supabase Auth : `absences.decided_by`, `documents.uploaded_by`,
--    `legal_parameters.validated_by`, `schedules.published_by`… Le générateur de
--    schéma portable les abandonnait toutes, avec une ligne dans la liste « non
--    traduit ». Signaler n'est pas traduire : un schéma Oracle livré ainsi n'a
--    aucune intégrité sur « qui a fait quoi ».
--
--    `app_users` est le point d'ancrage commun. Sur PostgreSQL elle reflète
--    `auth.users` (l'authentification reste à Supabase, `password_hash` y est
--    donc nul). Sur Oracle et MySQL, elle porte le mot de passe et devient la
--    table d'identité. Les UUID sont conservés d'un moteur à l'autre — aucun
--    remappage de séquence, conformément au principe de portabilité retenu.
--
-- 2. `fn_schema_catalogue()` — le catalogue, commentaires compris
--    ------------------------------------------------------------
--    L'extraction du catalogue se faisait par une requête à coller à la main, et
--    **n'extrayait pas les commentaires**. C'est pourquoi les 300 commentaires
--    de table et de colonne posés en migration 47 ne sont jamais arrivés dans
--    `schema/oracle.sql` ni `schema/mysql.sql`. Les deux bouts manquaient : la
--    lecture et l'écriture.
--
-- SUPPRESSION LOGIQUE
-- -------------------
-- `app_users` inaugure la convention : on ne supprime pas, on marque. Une ligne
-- effacée garde son identifiant, donc les clés étrangères qui la référencent
-- tiennent toujours, et le journal reste lisible. C'est la seule façon de
-- répondre « qui a fait cela » trois ans plus tard sur un compte parti.

-- ===========================================================================
-- 1. Les comptes
-- ===========================================================================

create table if not exists app_users (
  id            uuid primary key default extensions.gen_random_uuid(),
  userid        text not null,
  email         text not null,
  full_name     text,
  password_hash text,
  is_admin      boolean not null default false,
  auth_user_id  uuid,
  -- Traçabilité
  created_at    timestamptz not null default now(),
  created_by    uuid,
  updated_at    timestamptz not null default now(),
  updated_by    uuid,
  -- Suppression logique
  deleted_at    timestamptz,
  deleted_by    uuid,
  constraint app_user_userid_shape check (userid ~ '^[a-z0-9._-]{3,64}$'),
  constraint app_user_email_shape
    check (email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'),
  -- L'unicité ne vaut que sur les comptes vivants : un identifiant libéré par
  -- une suppression logique peut être réattribué.
  constraint app_user_deleted_pair check ((deleted_at is null) = (deleted_by is null))
);

create unique index if not exists idx_app_users_userid_actif
  on app_users (lower(userid)) where deleted_at is null;
create unique index if not exists idx_app_users_email_actif
  on app_users (lower(email))  where deleted_at is null;
create unique index if not exists idx_app_users_auth_actif
  on app_users (auth_user_id)  where auth_user_id is not null and deleted_at is null;

comment on table app_users is $c$Comptes applicatifs. Point d'ancrage commun aux trois moteurs : sur PostgreSQL elle reflète auth.users et password_hash reste nul, l'authentification appartenant à Supabase ; sur Oracle et MySQL elle porte le mot de passe et devient la table d'identité vers laquelle pointent les clés étrangères d'auteur.$c$;
comment on column app_users.userid is $c$Identifiant de connexion, en minuscules. Unique parmi les comptes vivants seulement : un identifiant libéré par une suppression logique peut être réattribué.$c$;
comment on column app_users.password_hash is $c$Empreinte bcrypt du mot de passe. NUL sur PostgreSQL/Supabase, où Auth détient le secret. Jamais le mot de passe en clair, à aucun moment.$c$;
comment on column app_users.auth_user_id is $c$Compte auth.users correspondant, quand l'application tourne sur Supabase. Nul sur une cible autonome.$c$;
comment on column app_users.deleted_at is $c$Suppression logique : la ligne reste, les clés étrangères qui la référencent tiennent, et le journal demeure lisible. Un compte parti doit encore pouvoir répondre de ce qu'il a fait.$c$;
comment on column app_users.is_admin is $c$Administrateur : seul habilité à lire le catalogue du schéma et à créer d'autres comptes.$c$;

alter table app_users enable row level security;

-- Chacun lit son propre compte ; un administrateur d'organisation lit tout le
-- monde. Aucune politique d'écriture : les comptes se créent par fonction.
drop policy if exists app_users_read on app_users;
create policy app_users_read on app_users
  for select to authenticated
  using (auth_user_id = auth.uid() or is_org_admin());

-- Reflet des profils existants, pour que la table ne naisse pas vide.
insert into app_users (id, userid, email, full_name, auth_user_id, is_admin)
select p.id,
       lower(regexp_replace(split_part(p.email, '@', 1), '[^a-zA-Z0-9._-]', '', 'g')),
       p.email, p.full_name, p.id, p.is_org_admin
from profiles p
where length(regexp_replace(split_part(p.email, '@', 1), '[^a-zA-Z0-9._-]', '', 'g')) >= 3
on conflict (id) do nothing;

-- Et maintien du reflet : un profil créé plus tard doit apparaître ici aussi.
create or replace function fn_sync_app_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_userid text;
begin
  v_userid := lower(regexp_replace(split_part(new.email, '@', 1), '[^a-zA-Z0-9._-]', '', 'g'));
  if length(v_userid) < 3 then
    v_userid := 'u' || replace(new.id::text, '-', '');
  end if;

  insert into app_users (id, userid, email, full_name, auth_user_id, is_admin)
  values (new.id, v_userid, new.email, new.full_name, new.id, new.is_org_admin)
  on conflict (id) do update
    set email = excluded.email, full_name = excluded.full_name,
        is_admin = excluded.is_admin, updated_at = now();
  return new;
end $$;

revoke execute on function fn_sync_app_user() from public, anon, authenticated;

drop trigger if exists sync_app_user on profiles;
create trigger sync_app_user after insert or update on profiles
  for each row execute function fn_sync_app_user();

-- ===========================================================================
-- 2. Créer un compte — le mot de passe passe en paramètre, jamais en fichier
-- ===========================================================================
-- Ce dépôt est public. Aucun mot de passe, aucun identifiant réel n'est écrit
-- dans une migration : ils seraient dans l'historique Git pour toujours. La
-- fonction prend le secret à l'exécution, le hache immédiatement, et ne le
-- conserve jamais en clair.

create or replace function fn_create_app_user(
  p_userid    text,
  p_email     text,
  p_password  text,
  p_full_name text default null,
  p_is_admin  boolean default false
) returns jsonb language plpgsql volatile security definer
set search_path = public, extensions as $$
declare v_id uuid; v_appelant uuid := auth.uid();
begin
  -- Premier compte : autorisé sans appelant, puisqu'il n'existe encore personne
  -- pour autoriser. Ensuite, seul un administrateur crée des comptes.
  if exists (select 1 from app_users where is_admin and deleted_at is null)
     and not is_org_admin() then
    raise exception 'Seul un administrateur peut créer un compte.';
  end if;

  if p_password is null or length(p_password) < 12 then
    raise exception 'Mot de passe trop court : douze caractères au minimum. '
                    'Il n''est ni stocké ni journalisé en clair, mais il protège '
                    'des données de santé et des matricules nationaux.';
  end if;

  insert into app_users (userid, email, full_name, is_admin, password_hash, created_by, updated_by)
  values (lower(btrim(p_userid)), lower(btrim(p_email)), p_full_name, p_is_admin,
          extensions.crypt(p_password, extensions.gen_salt('bf', 12)),
          v_appelant, v_appelant)
  returning id into v_id;

  -- Le mot de passe ne figure pas dans la réponse, ni dans aucun journal.
  return jsonb_build_object('ok', true, 'id', v_id, 'userid', lower(btrim(p_userid)),
                            'is_admin', p_is_admin,
                            'message', 'Compte créé. Le mot de passe est haché (bcrypt, coût 12) '
                                       'et n''est récupérable par personne, pas même par un administrateur.');
end $$;

comment on function fn_create_app_user(text, text, text, text, boolean) is
  'Crée un compte applicatif. Le mot de passe est pris en paramètre et haché immédiatement : il n''est jamais écrit dans une migration, ce dépôt étant public.';

revoke execute on function fn_create_app_user(text, text, text, text, boolean) from public, anon;
grant  execute on function fn_create_app_user(text, text, text, text, boolean) to authenticated;

create or replace function fn_check_app_password(p_userid text, p_password text)
returns boolean language plpgsql stable security definer
set search_path = public, extensions as $$
declare v_hash text;
begin
  select password_hash into v_hash
  from app_users
  where lower(userid) = lower(btrim(p_userid)) and deleted_at is null;
  -- Un compte inconnu et un mot de passe faux donnent la même réponse : rien
  -- n'apprend à l'appelant lequel des deux est en cause.
  if v_hash is null then return false; end if;
  return v_hash = extensions.crypt(p_password, v_hash);
end $$;

revoke execute on function fn_check_app_password(text, text) from public, anon, authenticated;

comment on function fn_check_app_password(text, text) is
  'Vérifie un mot de passe contre son empreinte. Sert aux cibles autonomes (Oracle, MySQL) ; sur Supabase, Auth s''en charge. Révoquée pour tous les rôles : elle n''a pas à être appelable depuis l''API.';

-- ===========================================================================
-- 3. Le catalogue du schéma, commentaires compris
-- ===========================================================================

create or replace function fn_schema_catalogue()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'generated_at', now(),
    'source', 'fn_schema_catalogue',
    'enums', (select jsonb_object_agg(t.typname, vals) from (
        select t.typname, jsonb_agg(e.enumlabel order by e.enumsortorder) as vals
          from pg_type t
          join pg_enum e on e.enumtypid = t.oid
          join pg_namespace n on n.oid = t.typnamespace
         where n.nspname = 'public'
         group by t.typname) t),
    'tables', (select jsonb_agg(x order by x->>'name') from (
        select jsonb_build_object(
          'name', c.relname,
          -- Ce qui manquait : le commentaire de la table…
          'comment', obj_description(c.oid, 'pg_class'),
          'columns', (select jsonb_agg(jsonb_build_object(
                'name', a.attname,
                'type', format_type(a.atttypid, a.atttypmod),
                'udt', tt.typname,
                'notnull', a.attnotnull,
                'default', pg_get_expr(d.adbin, d.adrelid),
                -- … et celui de chaque colonne.
                'comment', col_description(c.oid, a.attnum)) order by a.attnum)
              from pg_attribute a
              join pg_type tt on tt.oid = a.atttypid
              left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
             where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped),
          'constraints', (select jsonb_agg(jsonb_build_object(
                'name', co.conname, 'type', co.contype,
                'def', pg_get_constraintdef(co.oid),
                'comment', obj_description(co.oid, 'pg_constraint')) order by co.contype, co.conname)
              from pg_constraint co where co.conrelid = c.oid),
          'indexes', (select jsonb_agg(jsonb_build_object(
                'name', i.indexname, 'def', i.indexdef) order by i.indexname)
              from pg_indexes i
             where i.schemaname = 'public' and i.tablename = c.relname)
        ) as x
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
        left join pg_depend dep on dep.objid = c.oid
             and dep.classid = 'pg_class'::regclass and dep.deptype = 'e'
        where c.relkind = 'r' and dep.objid is null) s));
$$;

comment on function fn_schema_catalogue() is
  'Catalogue complet du schéma public : tables, colonnes, contraintes, index — et les commentaires, que l''extraction précédente omettait. Destinée à être lue par script pour régénérer les schémas portables Oracle et MySQL.';

revoke execute on function fn_schema_catalogue() from public, anon, authenticated;

-- Le catalogue décrit la structure, jamais les données. Il reste néanmoins
-- réservé aux administrateurs : la forme d'un schéma renseigne sur ce qu'il
-- contient.
create or replace function fn_schema_catalogue_for_admin()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not is_org_admin() then
    raise exception 'Lecture du catalogue réservée aux administrateurs d''organisation.';
  end if;
  return fn_schema_catalogue();
end $$;

comment on function fn_schema_catalogue_for_admin() is
  'Enveloppe contrôlée de fn_schema_catalogue : c''est celle-ci que l''API expose.';

revoke execute on function fn_schema_catalogue_for_admin() from public, anon;
grant  execute on function fn_schema_catalogue_for_admin() to authenticated;

-- ===========================================================================
-- Le compte administrateur : à créer par commande, hors du dépôt
-- ===========================================================================
-- Volontairement absent de cette migration. Le créer ici reviendrait à publier
-- un identifiant et un mot de passe sur GitHub, où l'historique les garderait
-- même après retrait.
--
-- À lancer une fois, depuis l'éditeur SQL ou un client, avec vos valeurs :
--
--   select fn_create_app_user(
--     p_userid   => '<identifiant>',
--     p_email    => '<courriel>',
--     p_password => '<mot de passe, douze caractères au moins>',
--     p_full_name=> '<nom complet>',
--     p_is_admin => true);
--
-- Contrôle : select userid, email, is_admin, password_hash is not null as protege
--              from app_users where is_admin;
