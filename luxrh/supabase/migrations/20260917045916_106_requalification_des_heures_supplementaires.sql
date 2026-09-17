-- 106 — L'heure supplémentaire se constate, elle ne se planifie pas
--
-- Aucun segment ne naît « heure supplémentaire » : la qualification dépend du
-- **cumul** sur la journée et sur la semaine, donc de segments que le découpage
-- d'une vacation isolée ne connaît pas. Un salarié qui fait neuf heures un mardi
-- et six le mercredi n'a pas fait d'heure supplémentaire si l'on raisonne à la
-- semaine.
--
-- La requalification est donc une seconde passe, qui parcourt les segments de
-- travail effectif dans l'ordre chronologique et **scinde** celui qui franchit un
-- seuil. Scinder plutôt que basculer le segment entier : une vacation de 7 h à
-- 17 h dépasse le seuil journalier à 15 h — les huit premières heures restent
-- normales, et seules les deux dernières sont supplémentaires.
--
-- Deux seuils, lus au référentiel et jamais écrits en dur :
--
--     JOUR_H     8 h   art. L. 211-5
--     SEMAINE_H  40 h  art. L. 211-5
--
-- Le premier franchi l'emporte. Le compte hebdomadaire ne redémarre pas à chaque
-- journée : c'est ce qui distingue un dépassement ponctuel d'un dépassement de
-- semaine.
--
-- Les pauses et les déplacements ne comptent pas : seule la famille « travail »
-- de `ref_classe_paie` alimente le cumul. Une pause repas de midi ne doit pas
-- rapprocher le salarié de son plafond.

create or replace function fn_qualifier_heures_sup(
  p_salarie uuid,
  p_debut   date,
  p_fin     date,
  p_origine text default 'planifie'
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  fuseau      constant text := 'Europe/Luxembourg';
  seuil_jour  numeric;
  seuil_sem   numeric;
  s           record;
  jour        date;
  jour_vu     date := null;
  cumul_jour  numeric := 0;
  cumul_sem   numeric := 0;
  semaine_vue date := null;
  reste_jour  numeric;
  reste_sem   numeric;
  reste       numeric;
  bascule     timestamptz;
  requalifies integer := 0;
begin
  seuil_jour := fn_param_num('JOUR_H',    p_debut) * 60;
  seuil_sem  := fn_param_num('SEMAINE_H', p_debut) * 60;
  if seuil_jour is null or seuil_sem is null then
    raise exception 'Seuils absents du référentiel au % (JOUR_H, SEMAINE_H).', p_debut;
  end if;

  -- On repart d'un état propre : toute heure supplémentaire de la période est
  -- d'abord ramenée à « normal », sinon un second passage cumulerait sur un
  -- découpage déjà fait et scinderait à l'infini.
  update segments_temps t
     set classe_paie = 'normal'
   where t.salarie_id = p_salarie
     and t.origine = p_origine
     and t.classe_paie = 'heure_sup'
     and (t.debut_le at time zone fuseau)::date between p_debut and p_fin;

  for s in
    select t.*
    from segments_temps t
    join ref_classe_paie c on c.code = t.classe_paie
    where t.salarie_id = p_salarie
      and t.origine = p_origine
      and c.famille = 'travail'
      and (t.debut_le at time zone fuseau)::date between p_debut and p_fin
    order by t.debut_le
  loop
    jour := (s.debut_le at time zone fuseau)::date;

    if jour_vu is distinct from jour then
      jour_vu := jour;
      cumul_jour := 0;
    end if;

    -- Semaine ISO : le lundi ouvre le compte. `date_trunc('week')` s'en charge.
    if semaine_vue is distinct from date_trunc('week', jour)::date then
      semaine_vue := date_trunc('week', jour)::date;
      cumul_sem := 0;
    end if;

    reste_jour := seuil_jour - cumul_jour;
    reste_sem  := seuil_sem  - cumul_sem;
    reste      := least(reste_jour, reste_sem);

    if reste <= 0 then
      -- Le seuil était déjà franchi : le segment entier est supplémentaire.
      update segments_temps set classe_paie = 'heure_sup' where id = s.id;
      requalifies := requalifies + 1;

    elsif reste < s.minutes then
      -- Le seuil tombe au milieu : on scinde à l'instant exact du franchissement.
      bascule := s.debut_le + make_interval(mins => reste::int);

      update segments_temps
         set fin_le = bascule
       where id = s.id;

      insert into segments_temps (
        societe_id, salarie_id, creneau_id, releve_temps_id, site_client_id,
        debut_le, fin_le, classe_paie, couverture_aaa,
        est_nuit, est_dimanche, est_ferie, origine, note
      ) values (
        s.societe_id, s.salarie_id, s.creneau_id, s.releve_temps_id, s.site_client_id,
        bascule, s.fin_le, 'heure_sup', s.couverture_aaa,
        s.est_nuit, s.est_dimanche, s.est_ferie, s.origine,
        'scindé au franchissement du seuil'
      );
      requalifies := requalifies + 1;
    end if;

    cumul_jour := cumul_jour + s.minutes;
    cumul_sem  := cumul_sem  + s.minutes;
  end loop;

  return requalifies;
end;
$$;

comment on function fn_qualifier_heures_sup(uuid, date, date, text) is
  'Requalifie en heures supplémentaires les segments de travail au-delà des seuils journalier et hebdomadaire, en scindant celui qui franchit un seuil. Rend le nombre de segments touchés. Idempotente : les heures supplémentaires de la période sont d''abord ramenées à « normal ». Les pauses et les déplacements n''entrent pas dans le cumul.';

revoke execute on function fn_qualifier_heures_sup(uuid, date, date, text) from public;
grant execute on function fn_qualifier_heures_sup(uuid, date, date, text) to authenticated;
