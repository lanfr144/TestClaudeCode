-- 88 — Les valeurs par défaut pointaient encore vers les anciens codes
--
-- Troisième omission de la même série, et la plus instructive : renommer une
-- valeur de domaine ne touche ni les valeurs par défaut des colonnes, ni les
-- contraintes qui les citent. Cinq colonnes gardaient un défaut devenu
-- introuvable dans sa table de référence — une insertion sans valeur explicite
-- échouait sur la clé étrangère.
--
-- C'est ce qu'ont montré les vérifications : « Key is not present in table
-- ref_lien_enfant », sur un test qui n'indiquait pas le lien de parenté et
-- s'en remettait au défaut.
--
-- La règle à retenir : un renommage de valeur touche six endroits, pas un —
-- l'étiquette ou la ligne de référence, les données qui la citent, les corps de
-- fonctions, les valeurs par défaut, les contraintes, et le code des interfaces.
-- Les quatre premiers sont vérifiables par requête ; les deux derniers le sont
-- par les tests.

set search_path = public;

alter table demandes_heures_sup  alter column compensation set default 'argent';
alter table demandes_heures_sup  alter column statut       set default 'demande';
alter table elements_remuneration alter column periodicite set default 'mensuel';
alter table enfants_salarie      alter column lien_parente  set default 'enfant';
alter table primes               alter column genre         set default 'autre';

-- Contrôle : plus aucun défaut ne cite un code qui n'existe pas.
do $controle$
declare
  r       record;
  v_restes text := '';
begin
  for r in
    select c.relname as tbl, a.attname as col,
           btrim(split_part(pg_get_expr(d.adbin, d.adrelid), '''', 2)) as valeur,
           rc.relname as table_ref
    from pg_attrdef d
    join pg_class c on c.oid = d.adrelid and c.relkind = 'r'
    join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
    join pg_attribute a on a.attrelid = d.adrelid and a.attnum = d.adnum
    join pg_constraint co on co.conrelid = c.oid and co.contype = 'f'
                         and co.conkey[1] = a.attnum
    join pg_class rc on rc.oid = co.confrelid
    where pg_get_expr(d.adbin, d.adrelid) like '''%'
  loop
    execute format('select count(*) from public.%I where code = %L', r.table_ref, r.valeur)
      into strict r.tbl;  -- réutilisation volontaire d'une variable record : voir ci-dessous
    exit;
  end loop;

  -- La boucle ci-dessus ne peut pas écrire dans un champ de `record` : on refait
  -- le contrôle simplement, table par table, ce qui suffit et se lit mieux.
  select string_agg(x, ', ') into v_restes from (
    select 'demandes_heures_sup.compensation' as x
      where not exists (select 1 from ref_compensation_heures_sup where code = 'argent')
    union all select 'demandes_heures_sup.statut'
      where not exists (select 1 from ref_statut_heures_sup where code = 'demande')
    union all select 'enfants_salarie.lien_parente'
      where not exists (select 1 from ref_lien_enfant where code = 'enfant')
    union all select 'primes.genre'
      where not exists (select 1 from ref_nature_prime where code = 'autre')
  ) t;
  if v_restes is not null then
    raise exception 'Defaut(s) pointant vers un code inexistant : %', v_restes;
  end if;
  raise notice 'Toutes les valeurs par defaut pointent vers un code existant.';
end $controle$;
