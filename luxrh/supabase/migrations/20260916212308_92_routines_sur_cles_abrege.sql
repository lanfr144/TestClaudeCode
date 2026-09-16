-- 92 — Les routines de calcul citent les clés `Abrege`
--
-- Le cahier des charges fixe la colonne `Abrege` du classeur comme identifiant
-- canonique des paramètres. Les huit routines qui lisaient les clés anglaises
-- lisent désormais celles du classeur.
--
-- Deux précautions, chacune pour une erreur qui serait passée inaperçue.
--
-- 1. **L'encodage diffère.** Le classeur porte des taux (0,7), le référentiel
--    portait des pourcentages (70). Un simple échange de nom aurait divisé la
--    majoration du dimanche par cent sans que rien ne le signale. Deux fonctions
--    d'adaptation, de même arité que `fn_param_num`, font la conversion à la
--    lecture : la substitution reste un remplacement de nom, et l'arithmétique
--    des routines n'est pas touchée.
--
-- 2. **On ne substitue que dans un appel à `fn_param`.** `'max_weekly_hours'`
--    est aussi un **code de constat** rendu à l'interface
--    (`jsonb_build_object('code','max_weekly_hours', …)`). Renommer le littéral
--    partout aurait changé le contrat de l'API sans qu'aucun test SQL ne le voie
--    — le front seul serait tombé. La substitution porte donc sur
--    `fn_param_num('clé'` et `fn_param('clé'`, jamais sur le littéral nu.

-- ---------------------------------------------------------------- adaptateurs
create or replace function fn_param_pct(p_key text, p_on date)
returns numeric language sql stable as $$
  -- Un taux du classeur (0,7) rendu en pourcentage (70).
  select fn_param_num(p_key, p_on) * 100;
$$;
comment on function fn_param_pct(text, date) is
  'Rend en pourcentage un paramètre stocké en taux. Le classeur des paramètres exprime les majorations en taux (0,7) là où les routines et les règles de convention raisonnent en pourcentage (70).';

create or replace function fn_param_pct_total(p_key text, p_on date)
returns numeric language sql stable as $$
  -- Une majoration (0,4) rendue en pourcentage de la rémunération totale (140).
  select 100 + fn_param_num(p_key, p_on) * 100;
$$;
comment on function fn_param_pct_total(text, date) is
  'Rend le pourcentage total dû à partir d''un taux de majoration : 0,4 donne 140. Le Code du travail énonce une majoration, la paie manipule un total.';

revoke execute on function fn_param_pct(text, date) from public;
revoke execute on function fn_param_pct_total(text, date) from public;
grant execute on function fn_param_pct(text, date) to authenticated;
grant execute on function fn_param_pct_total(text, date) to authenticated;

-- ------------------------------------------------------------- la substitution
do $migration$
declare
  -- ancienne clé -> (fonction de lecture, nouvelle clé). Une fonction de lecture
  -- différente de `fn_param_num` signale une conversion d'unité.
  corresp constant jsonb := jsonb_build_object(
    'max_weekly_hours',               jsonb_build_array('fn_param_num', 'SEMAINE_MAX'),
    'normal_weekly_hours',            jsonb_build_array('fn_param_num', 'SEMAINE_H'),
    'normal_daily_hours',             jsonb_build_array('fn_param_num', 'JOUR_H'),
    'max_daily_hours',                jsonb_build_array('fn_param_num', 'JOUR_MAX_H'),
    'min_daily_rest_hours',           jsonb_build_array('fn_param_num', 'REPOS_MIN'),
    'min_weekly_rest_hours',          jsonb_build_array('fn_param_num', 'REPOS_WE'),
    'annual_leave_min_days',          jsonb_build_array('fn_param_num', 'CONGE_J'),
    'overtime_rest_ratio',            jsonb_build_array('fn_param_num', 'H_SUP_REPOS'),
    'sunday_surcharge_pct',           jsonb_build_array('fn_param_pct', 'H_DIM_PCT'),
    'holiday_surcharge_pct',          jsonb_build_array('fn_param_pct', 'H_FER_PCT'),
    'night_min_surcharge_if_cba_pct', jsonb_build_array('fn_param_pct', 'H_NUI_PCT'),
    'overtime_money_pct',             jsonb_build_array('fn_param_pct_total', 'H_SUP_PCT')
  );
  r            record;
  corps        text;
  avant        text;
  ancienne     text;
  lecture      text;
  nouvelle     text;
  touchees     int := 0;
  remplacements int := 0;
begin
  for r in
    select p.oid, p.proname
    from pg_proc p
    where p.pronamespace = 'public'::regnamespace
      and p.proname in ('fn_annual_leave_rule', 'fn_check_cba_not_worse',
                        'fn_contract_compliance', 'fn_leave_balance',
                        'fn_min_salary', 'fn_reference_period_status',
                        'fn_sync_part_time', 'fn_validate_schedule')
  loop
    corps := pg_get_functiondef(r.oid);
    avant := corps;

    for ancienne in select jsonb_object_keys(corresp) loop
      lecture  := corresp -> ancienne ->> 0;
      nouvelle := corresp -> ancienne ->> 1;

      -- `fn_param_num('ancienne'` -> `<lecture>('nouvelle'`
      corps := replace(corps,
                       'fn_param_num(''' || ancienne || '''',
                       lecture || '(''' || nouvelle || '''');

      -- `fn_param('ancienne'` -> `fn_param('nouvelle'` : la référence légale se
      -- lit toujours par `fn_param`, quelle que soit l'unité de la valeur.
      corps := replace(corps,
                       'fn_param(''' || ancienne || '''',
                       'fn_param(''' || nouvelle || '''');
    end loop;

    if corps <> avant then
      execute corps;
      touchees := touchees + 1;
      remplacements := remplacements
        + (length(avant) - length(replace(avant, 'fn_param', ''))) / length('fn_param');
      raise notice 'réécrite : %', r.proname;
    else
      raise notice 'inchangée : %', r.proname;
    end if;
  end loop;

  -- Huit routines étaient attendues. Si l'une n'a pas bougé, c'est que sa clé a
  -- déjà changé de nom ailleurs, ou que la substitution n'a pas mordu : dans les
  -- deux cas il faut le savoir avant que le calcul ne parte en production.
  if touchees <> 8 then
    raise exception 'ARRÊT : % routine(s) réécrite(s), 8 attendues.', touchees;
  end if;
end
$migration$;

-- ------------------------------------------- plus aucune référence aux anciennes
do $controle$
declare
  restantes text;
begin
  select string_agg(p.proname || ' -> ' || m[1], ', ')
    into restantes
  from pg_proc p
  cross join lateral regexp_matches(
    pg_get_functiondef(p.oid),
    'fn_param(?:_num)?\(''(max_weekly_hours|normal_weekly_hours|normal_daily_hours|max_daily_hours|min_daily_rest_hours|min_weekly_rest_hours|annual_leave_min_days|overtime_rest_ratio|sunday_surcharge_pct|holiday_surcharge_pct|night_min_surcharge_if_cba_pct|overtime_money_pct)''',
    'g') as m
  where p.pronamespace = 'public'::regnamespace;

  if restantes is not null then
    raise exception 'ARRÊT : appels non convertis — %', restantes;
  end if;
end
$controle$;
