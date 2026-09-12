-- 82 — Le rapport de cohérence détecte deux défauts qu'il laissait passer
--
-- Les migrations 80 et 81 ont retiré des tests de nullité et des `coalesce` qui
-- portaient sur une colonne `not null` depuis la migration 70, dont un bornait
-- à `9999-12-31` alors que la sentinelle du projet est `2037-12-31`.
--
-- Nettoyer une fois ne vaut rien si rien n'empêche que cela revienne. Le
-- générateur de schéma portable reproduisait d'ailleurs le défaut à chaque
-- exécution : le nettoyage aurait été défait à la régénération suivante.
--
-- Deux contrôles s'ajoutent donc au rapport de cohérence.
--
-- 1. UNE COLONNE `not null` TRAITÉE COMME NULLABLE
--    Repérée sur le nom : on ne retient que les noms de colonnes qui sont
--    `not null` dans **toutes** les tables où ils apparaissent. Un nom qui est
--    nullable quelque part ne dit rien, et le signaler produirait du bruit —
--    c'est ce qui rend les rapports illisibles, donc inutiles.
--
--    Ce n'est pas un défaut de style. Tant que la forme défensive traîne, le
--    lecteur en déduit que la colonne admet des nuls et reproduit la précaution ;
--    et le planificateur évalue une disjonction là où une comparaison suffit.
--
-- 2. UNE SENTINELLE CONCURRENTE
--    Toute date lointaine autre que 2037-12-31 dans un corps de fonction. Deux
--    sentinelles dans un même schéma, c'est la certitude qu'un jour l'une sera
--    comparée à l'autre.

set search_path = public;

create or replace function fn_coherence_report()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_rapport jsonb;
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

    -- Une colonne `not null` partout, que du code traite pourtant comme nullable.
    'non_nul_traite_comme_nullable', coalesce((
        with toujours_non_nul as (
          select a.attname
          from pg_attribute a
          join pg_class c on c.oid = a.attrelid and c.relkind = 'r'
          join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
          where a.attnum > 0 and not a.attisdropped
          group by a.attname
          having bool_and(a.attnotnull) and count(*) > 0
        )
        select jsonb_agg(distinct p.proname || ' :: ' || t.attname order by p.proname || ' :: ' || t.attname)
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
        cross join toujours_non_nul t
        where p.prokind = 'f'
          and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
          and (p.prosrc ~* ('(\m|\.)' || t.attname || '\M\s+is\s+null')
            or p.prosrc ~* ('coalesce\s*\(\s*[\w.]*\m' || t.attname || '\M\s*,'))),
      '[]'::jsonb),

    -- Toute date lointaine qui n'est pas la sentinelle du projet.
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
