-- 69 — Relire le SQL des migrations appliquées
--
-- Pourquoi cette fonction existe
-- -------------------------------
-- Le dépôt et la base ont déjà divergé une fois : cinq migrations (45 à 45e)
-- étaient appliquées sans fichier correspondant, et il a fallu les reconstituer
-- à la main, ligne par ligne, en vérifiant les empreintes MD5.
--
-- Rien ne garantissait que cela ne se reproduise pas — jusqu'ici, remettre une
-- migration appliquée dans le dépôt supposait de la retaper. Cette fonction et
-- l'outil `tools/dump_migrations.py` rendent l'opération mécanique : tout ce qui
-- est appliqué peut être réécrit à l'identique dans `luxrh/supabase/migrations/`.
--
-- Accès
-- -----
-- Réservée aux administrateurs d'organisation. Le SQL d'une migration décrit la
-- structure, pas les données — mais il décrit aussi les contrôles d'accès, et
-- cela ne se lit pas par n'importe qui.

create or replace function fn_migrations_source(p_depuis text default '00000000000000')
returns table (version text, name text, sql text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_org_admin() then
    raise exception 'Lecture des migrations réservée aux administrateurs d''organisation.';
  end if;
  return query
    select m.version, m.name, array_to_string(m.statements, E';\n')
    from supabase_migrations.schema_migrations m
    where m.version >= p_depuis
    order by m.version;
end $$;

comment on function fn_migrations_source(text) is
  'SQL des migrations appliquées, pour que le dépôt puisse être remis en phase avec la base sans retaper. Née de la divergence 45 à 45e, qu''il a fallu reconstituer à la main.';

revoke execute on function fn_migrations_source(text) from public, anon;
grant  execute on function fn_migrations_source(text) to authenticated;
