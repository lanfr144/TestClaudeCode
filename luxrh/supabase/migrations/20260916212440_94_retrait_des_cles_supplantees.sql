-- 94 — Retrait des clés anglaises supplantées par le classeur
--
-- Douze clés faisaient double emploi avec la colonne `Abrege`. Deux valeurs pour
-- une même grandeur finissent toujours par diverger, et c'est l'ancienne qu'on
-- oublie de mettre à jour.
--
-- Ne sont **pas** retirées :
--
--   * `ssm_monthly_qualified` et `ssm_monthly_unqualified`. Leurs équivalents
--     `MSQ18Q` et `MSNQ18` n'ont pas de valeur au 1er janvier 2025 : le classeur
--     les dérive de `ssm_100` et de l'indice, et ne les recopie pas. Les retirer
--     laisserait `fn_min_salary` sans salaire minimum. Le rapprochement est fait :
--     279,3 × 944,43 / 100 = 2 637,79 €, exactement la valeur enregistrée.
--   * `max_reference_period_months` : le classeur ne porte pas d'équivalent.
--   * `wage_index` : doublon de `indice`, mais plus récent (992,24 au 1er juin
--     2026) et hors de l'horizon de chargement. Le retirer perdrait une valeur.
--
-- Avant retrait, on vérifie qu'aucune routine ne les cite encore. La migration 92
-- a converti les appels ; ce contrôle garantit qu'aucun n'a été écrit depuis.

do $controle$
declare
  cles constant text[] := array[
    'max_weekly_hours', 'normal_weekly_hours', 'normal_daily_hours',
    'max_daily_hours', 'min_daily_rest_hours', 'min_weekly_rest_hours',
    'annual_leave_min_days', 'overtime_rest_ratio', 'sunday_surcharge_pct',
    'holiday_surcharge_pct', 'night_min_surcharge_if_cba_pct', 'overtime_money_pct'
  ];
  citations text;
  retirees  int;
begin
  select string_agg(distinct p.proname, ', ')
    into citations
  from pg_proc p, unnest(cles) c
  where p.pronamespace = 'public'::regnamespace
    and pg_get_functiondef(p.oid) like '%fn_param%(''' || c || '''%';

  if citations is not null then
    raise exception 'ARRÊT : ces routines citent encore une clé supplantée — %', citations;
  end if;

  delete from parametres_legaux where cle_parametre = any(cles);
  get diagnostics retirees = row_count;
  raise notice '% version(s) de paramètre retirée(s) pour % clé(s).',
               retirees, array_length(cles, 1);
end
$controle$;
