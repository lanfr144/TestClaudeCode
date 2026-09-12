-- 80 — Les tests de nullité sur `fin_validite` sont morts : on les retire
--
-- Depuis la migration 70, `fin_validite` est `not null` avec pour défaut la
-- sentinelle 2037-12-31. Quatorze fonctions gardaient pourtant la forme
-- défensive héritée de l'époque nullable :
--
--     where debut_validite <= p_on and (fin_validite is null or fin_validite > p_on)
--
-- La première moitié ne peut plus être vraie. Ce n'est pas seulement inutile :
--
--   - le lecteur qui découvre le code en déduit que la colonne admet des nuls,
--     et reproduit la précaution dans le code qu'il écrit ensuite ;
--   - le planificateur doit évaluer une disjonction là où une simple
--     comparaison suffit, ce qui lui interdit certains parcours d'index ;
--   - et surtout, tant que la forme défensive traîne, l'invariant n'est
--     affirmé nulle part. Une colonne `not null` dont tout le code se méfie
--     n'est pas un invariant : c'est une convention que personne ne croit.
--
-- La substitution ne touche que `fin_validite`. `contrats.date_fin`,
-- `statuts_salarie.date_fin` et `sanctions_salarie.effet_au` restent nullables
-- et le resteront : un contrat à durée indéterminée n'a pas de fin, et lui en
-- inventer une reviendrait à dire que tout CDI s'arrête en 2037.

set search_path = public;

do $nettoyage$
declare
  f        record;
  v_def    text;
  v_avant  text;
  v_n      int := 0;
  v_total  int := 0;
begin
  for f in
    select p.oid, p.proname from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f'
      and p.prosrc ~* '(\w+\.)?fin_validite\s+is\s+null\s+or'
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;

    -- « (X.fin_validite is null or X.fin_validite > D) » devient « X.fin_validite > D ».
    v_def := regexp_replace(
      v_def,
      '\(\s*(\w+\.)?fin_validite\s+is\s+null\s+or\s+((\w+\.)?fin_validite\s*>\s*[A-Za-z0-9_.]+)\s*\)',
      '\2', 'gi');

    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
      v_total := v_total + (length(v_avant) - length(v_def));
    end if;
  end loop;
  raise notice '% fonction(s) nettoyee(s), % caractere(s) de code mort retires.',
               v_n, v_total;
end $nettoyage$;

-- Vérification : plus aucune fonction ne teste la nullité de `fin_validite`.
do $controle$
declare v_restant int;
begin
  select count(*) into v_restant
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
  where p.prokind = 'f' and p.prosrc ~* '(\w+\.)?fin_validite\s+is\s+null';
  if v_restant > 0 then
    raise exception '% fonction(s) testent encore la nullite de fin_validite.', v_restant;
  end if;
  raise notice 'Aucun test de nullite restant sur fin_validite.';
end $controle$;
