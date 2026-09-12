-- 74b — Le rapport de cohérence ignore ce qui appartient à une extension
--
-- Premier lancement de tools/verifier_coherence.py : 223 écarts, dont 188
-- « fonctions exécutables par anon ». Toutes portaient des noms comme
-- gbt_bytea_picksplit ou float8_dist : ce sont les routines de support de
-- btree_gist, qui vit dans le schéma public. PostgreSQL accorde EXECUTE à PUBLIC
-- sur les fonctions d'extension — c'est normal et sans danger.
--
-- Le défaut n'était pas dans la base, il était dans le contrôle : un rapport qui
-- noie un vrai signal sous 188 faux ne sera pas lu, donc ne servira à rien.
-- Le filtre est celui qu'emploie déjà le générateur de schéma portable : pg_depend
-- avec deptype 'e', qui distingue ce qui appartient à une extension.
--
-- Le vrai constat subsiste, et ressort maintenant seul : btree_gist est installé
-- dans public plutôt que dans extensions. Il est désormais remonté comme UN point.

set search_path = public;

create or replace function fn_coherence_report()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_rapport jsonb;
begin
  if not is_org_admin() then
    raise exception 'Rapport de cohérence réservé aux administrateurs d''organisation.';
  end if;

  select jsonb_build_object(
    'tables', (select count(*) from pg_class c
                join pg_namespace n on n.oid = c.relnamespace
               where n.nspname = 'public' and c.relkind = 'r'),
    'colonnes', (select count(*) from pg_class c
                  join pg_namespace n on n.oid = c.relnamespace
                  join pg_attribute a on a.attrelid = c.oid
                   and a.attnum > 0 and not a.attisdropped
                 where n.nspname = 'public' and c.relkind = 'r'),
    'migrations', (select count(*) from supabase_migrations.schema_migrations),

    'fonctions', coalesce((select jsonb_agg(distinct p.proname)
                            from pg_proc p
                            join pg_namespace n on n.oid = p.pronamespace
                           where n.nspname = 'public' and p.proname like 'fn\_%'),
                          '[]'::jsonb),

    'tables_sans_rls', coalesce((select jsonb_agg(c.relname order by c.relname)
                                  from pg_class c
                                  join pg_namespace n on n.oid = c.relnamespace
                                 where n.nspname = 'public' and c.relkind = 'r'
                                   and not c.relrowsecurity
                                   and not exists (select 1 from pg_depend d
                                                    where d.objid = c.oid
                                                      and d.deptype = 'e')),
                                '[]'::jsonb),

    -- Seules les fonctions de l'application comptent ici. Celles d'une extension
    -- sont exécutables par PUBLIC par construction : les signaler une par une
    -- rendait le rapport illisible.
    'fonctions_anon', coalesce((select jsonb_agg(distinct p.proname order by p.proname)
                                 from pg_proc p
                                 join pg_namespace n on n.oid = p.pronamespace
                                where n.nspname = 'public'
                                  and has_function_privilege('anon', p.oid, 'execute')
                                  and not exists (select 1 from pg_depend d
                                                   where d.objid = p.oid
                                                     and d.deptype = 'e')),
                               '[]'::jsonb),

    -- Le constat qui était noyé : une extension installée dans le schéma applicatif.
    'extensions_dans_public', coalesce((select jsonb_agg(e.extname order by e.extname)
                                         from pg_extension e
                                         join pg_namespace n on n.oid = e.extnamespace
                                        where n.nspname = 'public'),
                                       '[]'::jsonb),

    'tables_sans_commentaire', coalesce((select jsonb_agg(c.relname order by c.relname)
                                          from pg_class c
                                          join pg_namespace n on n.oid = c.relnamespace
                                         where n.nspname = 'public' and c.relkind = 'r'
                                           and obj_description(c.oid) is null
                                           and not exists (select 1 from pg_depend d
                                                            where d.objid = c.oid
                                                              and d.deptype = 'e')),
                                        '[]'::jsonb),

    'colonnes_sans_commentaire', coalesce((select jsonb_agg(c.relname || '.' || a.attname
                                                            order by c.relname, a.attnum)
                                            from pg_class c
                                            join pg_namespace n on n.oid = c.relnamespace
                                            join pg_attribute a on a.attrelid = c.oid
                                             and a.attnum > 0 and not a.attisdropped
                                           where n.nspname = 'public' and c.relkind = 'r'
                                             and col_description(c.oid, a.attnum) is null
                                             and not exists (select 1 from pg_depend d
                                                              where d.objid = c.oid
                                                                and d.deptype = 'e')),
                                          '[]'::jsonb)
  ) into v_rapport;

  return v_rapport;
end $$;

revoke execute on function fn_coherence_report() from public, anon;
grant  execute on function fn_coherence_report() to authenticated;
