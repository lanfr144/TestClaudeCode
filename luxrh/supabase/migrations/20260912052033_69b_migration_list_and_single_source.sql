-- 69b — Lister d'abord, lire ensuite
--
-- `fn_migrations_source` renvoyait le SQL de toutes les migrations d'un coup :
-- plus de 12 000 lignes, et la passerelle expirait en 504. Le découpage est
-- évident une fois le symptôme vu — lister est léger, lire ne concerne que ce
-- qui manque.

create or replace function fn_migrations_list()
returns table (version text, name text, taille integer)
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_org_admin() then
    raise exception 'Lecture des migrations réservée aux administrateurs d''organisation.';
  end if;
  return query
    select m.version, m.name,
           coalesce(length(array_to_string(m.statements, ';')), 0)
    from supabase_migrations.schema_migrations m
    order by m.version;
end $$;

comment on function fn_migrations_list() is
  'Inventaire des migrations appliquées — version, nom, taille. Léger : c''est par là qu''on commence avant de demander le SQL de celles qui manquent au dépôt.';

revoke execute on function fn_migrations_list() from public, anon;
grant  execute on function fn_migrations_list() to authenticated;

create or replace function fn_migration_source(p_version text)
returns text language plpgsql stable security definer set search_path = public as $$
declare v_sql text;
begin
  if not is_org_admin() then
    raise exception 'Lecture des migrations réservée aux administrateurs d''organisation.';
  end if;
  select array_to_string(m.statements, E';\n') into v_sql
  from supabase_migrations.schema_migrations m
  where m.version = p_version;
  if v_sql is null then
    raise exception 'Migration introuvable : %', p_version;
  end if;
  return v_sql;
end $$;

comment on function fn_migration_source(text) is
  'SQL d''une migration appliquée, une à la fois. La version qui les renvoyait toutes d''un bloc faisait expirer la passerelle.';

revoke execute on function fn_migration_source(text) from public, anon;
grant  execute on function fn_migration_source(text) to authenticated;

-- L'ancienne, qui renvoyait tout : retirée plutôt que laissée en piège.
drop function if exists fn_migrations_source(text);
