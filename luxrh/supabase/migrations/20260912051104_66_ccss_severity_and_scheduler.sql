-- 66 — Sévérité selon le délai restant, et tâche d'ordonnanceur
--
-- La règle temporelle
-- -------------------
--   info     il reste 7 jours ou plus avant l'échéance
--   warning  il reste 2 jours ou moins
--   problem  le délai est dépassé
--   blocking conservé, et distinct : il n'exprime pas un retard mais une
--            impossibilité — une opération que le moteur refuse d'exécuter.
--            Un document CCSS en retard est un `problem` ; il n'empêche pas de
--            publier un planning.
--
-- Les seuils sont des réglages, pas des durées légales
-- -----------------------------------------------------
-- Sept jours et deux jours sont des choix d'anticipation, pas des règles de
-- droit. Ils vivent donc dans `legal_parameters` comme tous les réglages, et
-- la fonction applique une valeur de repli **en le disant** si elle ne les
-- trouve pas — plutôt que de laisser croire à un paramétrage.
--
-- L'ordonnanceur est celui du SGBD, pas celui du système
-- -------------------------------------------------------
-- Aucune tâche cron système, aucun planificateur Windows : le calcul tourne
-- dans la base. Sur PostgreSQL, `pg_cron`. Sur Oracle, `DBMS_SCHEDULER`. Sur
-- MySQL, l'`EVENT SCHEDULER`. La fonction ci-dessous est écrite pour être
-- appelée par l'un ou l'autre, sans rien savoir de qui l'appelle.

insert into expected_parameters (param_key, read_by, note) values
  ('ccss_alerte_info_jours', 'fn_recalculer_severites',
   'Nombre de jours avant échéance à partir duquel une alerte reste en information. Réglage d''anticipation, non légal.'),
  ('ccss_alerte_warning_jours', 'fn_recalculer_severites',
   'Nombre de jours avant échéance à partir duquel une alerte passe en avertissement. Réglage d''anticipation, non légal.')
on conflict (param_key) do update set read_by = excluded.read_by, note = excluded.note;

-- ===========================================================================
-- La règle, isolée pour être vérifiable seule
-- ===========================================================================

create or replace function fn_severite_pour_echeance(
  p_echeance date,
  p_le       date default current_date
) returns jsonb language plpgsql stable set search_path = public as $$
declare
  v_info    numeric := fn_param_num('ccss_alerte_info_jours', p_le);
  v_warning numeric := fn_param_num('ccss_alerte_warning_jours', p_le);
  v_reste   integer;
  v_defaut  boolean := (v_info is null or v_warning is null);
begin
  if p_echeance is null then
    return jsonb_build_object('severite', null, 'motif', 'Aucune échéance : rien à mesurer.');
  end if;

  -- Repli explicite, jamais silencieux.
  v_info    := coalesce(v_info, 7);
  v_warning := coalesce(v_warning, 2);
  v_reste   := p_echeance - p_le;

  return jsonb_build_object(
    'severite', case
                  when v_reste < 0            then 'problem'
                  when v_reste <= v_warning   then 'warning'
                  else 'info'
                end,
    'jours_restants', v_reste,
    'seuil_info', v_info,
    'seuil_warning', v_warning,
    'seuils_par_defaut', v_defaut,
    'motif', case
      when v_reste < 0          then format('Délai dépassé de %s jour(s).', -v_reste)
      when v_reste <= v_warning then format('Plus que %s jour(s) avant l''échéance.', v_reste)
      else format('%s jour(s) avant l''échéance.', v_reste)
    end || case when v_defaut
                then ' Seuils de repli appliqués : ccss_alerte_info_jours et '
                     'ccss_alerte_warning_jours ne sont pas chargés.'
                else '' end);
end $$;

comment on function fn_severite_pour_echeance(date, date) is
  'Sévérité d''une alerte selon le nombre de jours restant avant son échéance. Les seuils viennent du référentiel ; à défaut, un repli s''applique et la réponse le déclare.';

revoke execute on function fn_severite_pour_echeance(date, date) from public, anon;
grant  execute on function fn_severite_pour_echeance(date, date) to authenticated;

-- ===========================================================================
-- La tâche nocturne
-- ===========================================================================
-- Recalcule les sévérités des alertes ouvertes qui portent une échéance, et rend
-- le compte de ce qu'elle a changé. Idempotente : la relancer deux fois dans la
-- même nuit ne produit rien de plus.

create or replace function fn_recalculer_severites(p_le date default current_date)
returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare
  v_maj      int := 0;
  v_examinees int := 0;
  v_repartition jsonb;
begin
  with candidates as (
    select a.id, a.severity,
           (fn_severite_pour_echeance(a.due_date, p_le) ->> 'severite')::severity_kind as nouvelle
    from compliance_alerts a
    where a.state = 'open'
      and a.due_date is not null
      -- `blocking` n'est pas une étape du compte à rebours : on n'y touche pas.
      and a.severity <> 'blocking'
  ),
  maj as (
    update compliance_alerts a
       set severity = c.nouvelle
      from candidates c
     where a.id = c.id and c.nouvelle is not null and a.severity is distinct from c.nouvelle
    returning a.id
  )
  select (select count(*) from candidates), (select count(*) from maj)
    into v_examinees, v_maj;

  select jsonb_object_agg(severity::text, n) into v_repartition
  from (select severity, count(*) as n from compliance_alerts
         where state = 'open' group by severity) t;

  return jsonb_build_object(
    'execute_le', p_le,
    'alertes_examinees', v_examinees,
    'severites_modifiees', v_maj,
    'repartition', coalesce(v_repartition, '{}'::jsonb),
    'message', format('%s alerte(s) examinée(s), %s sévérité(s) mise(s) à jour.',
                      v_examinees, v_maj));
end $$;

comment on function fn_recalculer_severites(date) is
  'Tâche nocturne : recalcule la sévérité des alertes ouvertes selon le délai restant. Ne touche jamais à « blocking », qui n''est pas une étape du compte à rebours mais une impossibilité. Idempotente.';

revoke execute on function fn_recalculer_severites(date) from public, anon, authenticated;

-- ===========================================================================
-- Planification — à exécuter une fois pg_cron installé
-- ===========================================================================
-- pg_cron n'est pas installé sur ce déploiement : la planification ne peut pas
-- figurer dans cette migration sans la faire échouer. Elle est donc décrite ici
-- et reste à lancer :
--
--   create extension if not exists pg_cron;
--   select cron.schedule('luxrh-severites', '15 2 * * *',
--                        $$select fn_recalculer_severites()$$);
--
-- Contrôle :  select * from cron.job;
--             select * from cron.job_run_details order by start_time desc limit 5;
--
-- Sur Oracle :
--   dbms_scheduler.create_job(job_name => 'LUXRH_SEVERITES',
--     job_type => 'PLSQL_BLOCK', job_action => 'begin fn_recalculer_severites; end;',
--     repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=15', enabled => true);
--
-- Sur MySQL (event_scheduler = ON) :
--   create event luxrh_severites on schedule every 1 day
--     starts timestamp(current_date + interval 1 day, '02:15:00')
--     do call fn_recalculer_severites();
