-- 78c — Le dernier intervalle déguisé
--
-- `generate_series(debut, fin, '1 month')` passe son pas sous forme de chaîne,
-- sans `::interval` : la migration 78b, qui cherchait précisément ce suffixe, ne
-- l'a pas vu. Le littéral était devenu `'1 mois'`, et les deux fonctions qui en
-- dépendent — le calcul d'effectif moyen et le balayage de conformité —
-- s'arrêtaient sur « invalid input syntax for type interval ».
--
-- Un seul cas dans tout le schéma, vérifié avant correction : le motif
-- « nombre + unité entre apostrophes » ne se rencontre nulle part ailleurs, et
-- en particulier dans aucun message destiné à un utilisateur. C'est pour cela
-- que la substitution ci-dessous peut être générale sans être risquée.

set search_path = public;

do $pas$
declare
  f       record;
  v_def   text;
  v_avant text;
  v_n     int := 0;
begin
  for f in
    select p.oid from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f'
      and p.prosrc ~ '''\d+\s+(mois|jours|annee|annees|heures|minutes|semaines)'''
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    v_def := regexp_replace(v_def, '''(\d+\s+)mois''',     '''\1month''', 'g');
    v_def := regexp_replace(v_def, '''(\d+\s+)jours''',    '''\1days''', 'g');
    v_def := regexp_replace(v_def, '''(\d+\s+)annees?''',  '''\1years''', 'g');
    v_def := regexp_replace(v_def, '''(\d+\s+)heures''',   '''\1hours''', 'g');
    v_def := regexp_replace(v_def, '''(\d+\s+)minutes''',  '''\1minutes''', 'g');
    v_def := regexp_replace(v_def, '''(\d+\s+)semaines''', '''\1weeks''', 'g');
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% fonction(s) corrigee(s).', v_n;
end $pas$;
