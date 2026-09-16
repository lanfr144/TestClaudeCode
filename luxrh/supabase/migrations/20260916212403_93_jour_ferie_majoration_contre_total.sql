-- 93 — Jour férié : la majoration n'est pas le total
--
-- La migration 92 a ramené le jour férié de 300 à 100 en tenant le 300 pour une
-- erreur. Il n'en était pas une : les deux nombres expriment deux grandeurs
-- différentes, et c'est la conversion qui manquait.
--
-- Art. L. 232-7, par. (2) : « Le salarié rémunéré au mois touche pour chaque
-- heure travaillée son salaire horaire moyen **majoré de cent pour cent**, sans
-- préjudice de son salaire mensuel normal. »
--
-- Pour une heure travaillée un jour férié, trois parts se cumulent :
--
--     100 %   le salaire mensuel normal, qui couvre déjà cette heure
--   + 100 %   le salaire des heures effectivement prestées
--   + 100 %   la majoration de l'article L. 232-7
--   -------
--     300 %   au total
--
-- Le classeur porte la **majoration** (`H_FER_PCT` = 1). Les conventions
-- collectives, et le champ « Jour férié travaillé » de l'éditeur de CCT dont
-- l'intitulé dit bien « Total légal », portent le **total** (300).
--
-- Avec 100 au lieu de 300, `fn_check_cba_not_worse` aurait accepté une
-- convention à 150 % — moins favorable que la loi — en la croyant conforme.
-- Rien n'aurait échoué : le contrôle serait simplement devenu complaisant.
--
-- Le dimanche ne suit pas la même règle : l'article L. 231-7 énonce un supplément
-- de 70 %, et la convention stocke 70. Là, majoration et valeur stockée
-- coïncident, et `fn_param_pct` convient. D'où une fonction distincte plutôt
-- qu'un socle ajouté à toutes les majorations.

create or replace function fn_param_pct_ferie(p_key text, p_on date)
returns numeric language sql stable as $$
  -- 100 (salaire mensuel) + 100 (heure prestée) + 100 × majoration.
  select 200 + fn_param_num(p_key, p_on) * 100;
$$;
comment on function fn_param_pct_ferie(text, date) is
  'Rend le pourcentage total dû pour une heure travaillée un jour férié, à partir de la majoration de l''art. L. 232-7 : salaire mensuel normal, salaire des heures prestées et majoration se cumulent. Une majoration de 100 % donne un total de 300 %.';

revoke execute on function fn_param_pct_ferie(text, date) from public;
grant execute on function fn_param_pct_ferie(text, date) to authenticated;

do $migration$
declare
  r        record;
  corps    text;
  avant    text;
  touchees int := 0;
begin
  for r in
    select p.oid, p.proname
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and pg_get_functiondef(p.oid) like '%fn_param_pct(''H_FER_PCT''%'
  loop
    corps := pg_get_functiondef(r.oid);
    avant := corps;
    corps := replace(corps, 'fn_param_pct(''H_FER_PCT''', 'fn_param_pct_ferie(''H_FER_PCT''');
    if corps <> avant then
      execute corps;
      touchees := touchees + 1;
      raise notice 'réécrite : %', r.proname;
    end if;
  end loop;

  -- `fn_check_cba_not_worse` et `fn_validate_schedule` lisent toutes deux le
  -- taux du jour férié. Si l'une échappait à la reprise, le contrôle de
  -- non-régression conventionnelle resterait faux.
  if touchees <> 2 then
    raise exception 'ARRÊT : % routine(s) reprises, 2 attendues.', touchees;
  end if;
end
$migration$;
