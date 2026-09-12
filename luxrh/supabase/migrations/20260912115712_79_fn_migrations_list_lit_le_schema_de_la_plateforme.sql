-- 79 — `fn_migrations_list` lisait une colonne renommée qui ne l'était pas
--
-- Le renommage ne portait que sur le schéma `public`. Mais la substitution
-- textuelle des corps de fonctions, elle, ne connaît pas les schémas : elle a
-- transformé `m.name` en `m.nom` dans une requête qui interroge
-- `supabase_migrations.schema_migrations` — une table de la plateforme, dont les
-- colonnes n'ont évidemment pas bougé.
--
-- Une seule fonction sur les trois qui lisent ce schéma était touchée, les deux
-- autres ne nommant que `version` et `statements`.
--
-- La leçon vaut pour tout renommage mené par substitution : ce qui limite la
-- portée est le `search_path`, pas le texte. Un corps de fonction peut nommer une
-- table d'un autre schéma, et la substitution la suivra.

set search_path = public;

create or replace function public.fn_migrations_list()
returns table(version text, nom text, taille integer)
language plpgsql stable security definer set search_path to 'public'
as $function$
begin
  if not est_admin_organisation() then
    raise exception 'Lecture des migrations réservée aux administrateurs d''organisation.';
  end if;
  return query
    -- `m.name` : colonne de la plateforme, hors périmètre du renommage.
    select m.version, m.name,
           coalesce(length(array_to_string(m.statements, ';')), 0)
    from supabase_migrations.schema_migrations m
    order by m.version;
end $function$;

revoke execute on function public.fn_migrations_list() from public, anon;
grant  execute on function public.fn_migrations_list() to authenticated;
