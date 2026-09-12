-- 82b — Le contrôle ajouté en 82 était trop large
--
-- Première exécution : cinq signalements, tous faux. `v_contrat.id is null`
-- après un `select ... into` teste la **variable**, pas la colonne — c'est
-- l'idiome PL/pgSQL pour « aucune ligne trouvée », et il est parfaitement
-- correct. Une règle textuelle ne distingue pas un champ de variable d'une
-- référence de colonne.
--
-- C'est exactement le travers que le § 13 de la feuille de route décrit, et que
-- j'ai reproduit : un rapport qui noie un vrai signal sous des faux ne sera pas
-- lu, donc ne servira à rien. Deux fois déjà — les 188 routines de btree_gist,
-- puis les vingt « 13 tables » de la documentation.
--
-- Le contrôle est donc ramené aux seules **bornes de validité**. Ces colonnes-là
-- ne servent jamais de témoin de recherche : on ne teste pas
-- `v_ligne.fin_validite is null` pour savoir si un `select` a trouvé quelque
-- chose. Un test de nullité sur elles est donc toujours du code mort, sans
-- exception à prévoir.
--
-- Étroit et juste vaut mieux que large et bruyant.

set search_path = public;

create or replace function fn_coherence_report()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_rapport jsonb;
  -- Les bornes de validité, et elles seules. Ajouter un nom ici suppose de
  -- vérifier qu'il ne sert jamais de témoin après un `select ... into`.
  v_bornes constant text[] := array['fin_validite', 'debut_validite'];
begin
  if not est_admin_organisation() then
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
                                                    where d.objid = c.oid and d.deptype = 'e')),
                                '[]'::jsonb),

    'fonctions_anon', coalesce((select jsonb_agg(distinct p.proname order by p.proname)
                                 from pg_proc p
                                 join pg_namespace n on n.oid = p.pronamespace
                                where n.nspname = 'public'
                                  and has_function_privilege('anon', p.oid, 'execute')
                                  and not exists (select 1 from pg_depend d
                                                   where d.objid = p.oid and d.deptype = 'e')),
                               '[]'::jsonb),

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
                                                            where d.objid = c.oid and d.deptype = 'e')),
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
                                                              where d.objid = c.oid and d.deptype = 'e')),
                                          '[]'::jsonb),

    'non_nul_traite_comme_nullable', coalesce((
        select jsonb_agg(distinct p.proname || ' :: ' || b.borne
                         order by p.proname || ' :: ' || b.borne)
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
        cross join unnest(v_bornes) as b(borne)
        where p.prokind = 'f'
          and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
          and exists (select 1 from pg_attribute a
                      join pg_class c on c.oid = a.attrelid and c.relkind = 'r'
                      join pg_namespace n2 on n2.oid = c.relnamespace and n2.nspname = 'public'
                      where a.attname = b.borne and a.attnum > 0 and not a.attisdropped
                      having bool_and(a.attnotnull))
          and (p.prosrc ~* ('(\m|\.)' || b.borne || '\M\s+is\s+null')
            or p.prosrc ~* ('coalesce\s*\(\s*[\w.]*\m' || b.borne || '\M\s*,'))),
      '[]'::jsonb),

    'sentinelles_concurrentes', coalesce((
        select jsonb_agg(distinct p.proname order by p.proname)
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
        where p.prokind = 'f'
          and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
          and p.prosrc ~ '''(9999|2999|3000|2100)-[0-9]{2}-[0-9]{2}'''),
      '[]'::jsonb)
  ) into v_rapport;

  return v_rapport;
end $$;

revoke execute on function fn_coherence_report() from public, anon;
grant  execute on function fn_coherence_report() to authenticated;
