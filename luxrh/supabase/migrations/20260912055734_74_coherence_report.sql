-- 74 — `fn_coherence_report` : ce que la base sait dire d'elle-même
--
-- Pourquoi une fonction et non des requêtes dans l'outil
-- -------------------------------------------------------
-- L'outil `tools/verifier_coherence.py` passe par PostgREST, comme les deux
-- interfaces. Il n'a pas de connexion directe et ne doit pas en avoir : ce qu'un
-- outil de vérification peut lire, il doit pouvoir le lire avec les droits d'un
-- administrateur ordinaire, pas avec ceux du propriétaire de la base.
--
-- Cette fonction réunit donc en un seul appel ce qu'il faut pour confronter le
-- dépôt, la base et la documentation. Un seul aller-retour : les sept contrôles
-- portaient chacun leur requête, et la latence finissait par décourager de lancer
-- la vérification — un contrôle qu'on ne lance pas ne sert à rien.
--
-- Ce qu'elle expose, et ce qu'elle n'expose pas
-- ----------------------------------------------
-- Uniquement du **catalogue système** : noms de tables, de colonnes, de fonctions,
-- présence de RLS, présence d'un commentaire. Aucune donnée métier, aucune ligne
-- d'aucune table applicative. Réservée aux administrateurs d'organisation, comme
-- `fn_schema_catalogue_for_admin`, parce que la forme d'un schéma renseigne déjà
-- sur ce qu'il contient.

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

    -- Les fonctions du moteur, pour vérifier qu'un front n'en appelle pas une
    -- qui n'existe pas. Un tel appel ne se voit qu'à l'exécution, sur l'écran
    -- d'un utilisateur.
    'fonctions', coalesce((select jsonb_agg(distinct p.proname)
                            from pg_proc p
                            join pg_namespace n on n.oid = p.pronamespace
                           where n.nspname = 'public' and p.proname like 'fn\_%'),
                          '[]'::jsonb),

    -- Règle 6 du projet : RLS sur toutes les tables, sans exception.
    'tables_sans_rls', coalesce((select jsonb_agg(c.relname order by c.relname)
                                  from pg_class c
                                  join pg_namespace n on n.oid = c.relnamespace
                                 where n.nspname = 'public' and c.relkind = 'r'
                                   and not c.relrowsecurity),
                                '[]'::jsonb),

    -- `anon` est le rôle d'un visiteur non authentifié. Aucune fonction du moteur
    -- ne doit lui être ouverte : il y en avait seize, dont six security definer.
    'fonctions_anon', coalesce((select jsonb_agg(distinct p.proname order by p.proname)
                                 from pg_proc p
                                 join pg_namespace n on n.oid = p.pronamespace
                                where n.nspname = 'public'
                                  and has_function_privilege('anon', p.oid, 'execute')),
                               '[]'::jsonb),

    'tables_sans_commentaire', coalesce((select jsonb_agg(c.relname order by c.relname)
                                          from pg_class c
                                          join pg_namespace n on n.oid = c.relnamespace
                                         where n.nspname = 'public' and c.relkind = 'r'
                                           and obj_description(c.oid) is null),
                                        '[]'::jsonb),

    'colonnes_sans_commentaire', coalesce((select jsonb_agg(c.relname || '.' || a.attname
                                                            order by c.relname, a.attnum)
                                            from pg_class c
                                            join pg_namespace n on n.oid = c.relnamespace
                                            join pg_attribute a on a.attrelid = c.oid
                                             and a.attnum > 0 and not a.attisdropped
                                           where n.nspname = 'public' and c.relkind = 'r'
                                             and col_description(c.oid, a.attnum) is null),
                                          '[]'::jsonb)
  ) into v_rapport;

  return v_rapport;
end $$;

comment on function fn_coherence_report() is
  'Réunit en un appel ce qui permet de confronter le dépôt, la base et la documentation : nombre de tables, de colonnes et de migrations, fonctions du moteur existantes, tables sans RLS, fonctions ouvertes à anon, tables et colonnes sans commentaire. Ne lit que le catalogue système, jamais une donnée métier. Réservée aux administrateurs : la forme d''un schéma renseigne déjà sur ce qu''il contient.';

revoke execute on function fn_coherence_report() from public, anon;
grant  execute on function fn_coherence_report() to authenticated;
