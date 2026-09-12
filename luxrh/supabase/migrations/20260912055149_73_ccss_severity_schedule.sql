-- 73 — La tâche nocturne de recalcul des sévérités
--
-- Pourquoi un ordonnanceur de base et non un cron système
-- --------------------------------------------------------
-- La sévérité d'une échéance CCSS dépend du jour où on la regarde : `info` à sept
-- jours, `warning` à deux jours, `problem` une fois le délai passé. Elle change
-- donc toute seule, sans qu'aucune écriture ne survienne — un déclencheur ne peut
-- rien pour elle.
--
-- Le recalcul appartient à la base pour trois raisons.
--
-- 1. **Il suit la donnée.** Une sauvegarde restaurée ailleurs emporte la tâche avec
--    elle. Un cron système reste sur la machine qu'on a quittée.
-- 2. **Il ne dépend pas d'un hôte.** Les deux applications n'ont pas de serveur
--    commun ; l'une est un front statique, l'autre un Streamlit. Ni l'une ni l'autre
--    n'est un endroit où faire vivre une tâche planifiée.
-- 3. **Il se porte.** Oracle a DBMS_SCHEDULER, MySQL a l'EVENT SCHEDULER. Les trois
--    équivalents sont écrits en fin de fichier : le portage ne demande pas de
--    retrouver ce qu'un crontab faisait.
--
-- Heure retenue : 02h15. Après la bascule de date, avant l'arrivée des utilisateurs,
-- et décalée du quart d'heure où beaucoup de sauvegardes se lancent.

set search_path = public;

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise exception 'pg_cron n''est pas installé. Sur Supabase : create extension pg_cron; '
                    '(ou Database > Extensions dans le tableau de bord). Sans lui, les '
                    'sévérités ne se recalculent pas et une échéance dépassée reste affichée '
                    'comme « à venir » — une alerte fausse est pire qu''une alerte absente.';
  end if;

  -- Réenregistrement idempotent : une migration doit pouvoir être rejouée.
  perform cron.unschedule('luxrh_severites_ccss')
  where exists (select 1 from cron.job where jobname = 'luxrh_severites_ccss');

  perform cron.schedule(
    'luxrh_severites_ccss',
    '15 2 * * *',
    $cmd$select public.fn_recalculer_severites(current_date)$cmd$);
end $$;

comment on function fn_recalculer_severites(date) is
  'Recalcule la sévérité de toutes les échéances CCSS à la date donnée : info à sept jours, warning à deux jours, problem une fois le délai passé. Appelée chaque nuit à 02h15 par la tâche pg_cron « luxrh_severites_ccss », et appelable à la main pour rejouer une journée. Le paramètre de date existe pour cela : il rend la fonction testable sans attendre demain.';

-- ============================================================ équivalents portables
--
-- Oracle — DBMS_SCHEDULER :
--
--   begin
--     dbms_scheduler.create_job(
--       job_name        => 'LUXRH_SEVERITES_CCSS',
--       job_type        => 'PLSQL_BLOCK',
--       job_action      => 'begin fn_recalculer_severites(trunc(sysdate)); end;',
--       repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=15; BYSECOND=0',
--       enabled         => true,
--       comments        => 'Recalcul nocturne des sévérités d''échéance CCSS');
--   end;
--   /
--
-- MySQL — EVENT SCHEDULER (à activer une fois : SET GLOBAL event_scheduler = ON) :
--
--   create event if not exists luxrh_severites_ccss
--     on schedule every 1 day
--       starts (date(current_date) + interval 1 day + interval 135 minute)
--     do call fn_recalculer_severites(current_date());
--
-- Les trois font la même chose au même moment. Ce qui change est la syntaxe, pas
-- la décision : le recalcul vit dans la base, quelle que soit la base.
