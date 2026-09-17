-- 108 — Une heure supplémentaire ne se compte pas deux fois
--
-- La migration 106 incrémentait les cumuls journalier et hebdomadaire de
-- **toutes** les minutes du segment, y compris celles qu'elle venait de
-- requalifier. Le seuil hebdomadaire était donc franchi plus tôt qu'il ne le
-- devait, et les dépassements s'additionnaient au lieu de se recouvrir.
--
-- Sur cinq journées de neuf heures :
--
--   | | heures normales | supplémentaires |
--   |---|---|---|
--   | attendu  | 40 h | 5 h |
--   | obtenu   | 36 h | 9 h |
--
-- Quarante-cinq heures travaillées, une durée normale de quarante : il y a cinq
-- heures supplémentaires, et pas une de plus. Le seuil journalier dit **quelles**
-- heures sont supplémentaires ; il n'en crée pas.
--
-- Les cumuls ne comptent donc que les minutes imputées au contingent normal.
-- Le test `luxrh/tests/segments.test.mjs` l'a relevé au premier passage.

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
  societe     uuid;
  seuil_jour  numeric;
  seuil_sem   numeric;
  s           record;
  jour        date;
  jour_vu     date := null;
  cumul_jour  numeric := 0;
  cumul_sem   numeric := 0;
  semaine_vue date := null;
  reste       numeric;
  imputees    numeric;
  bascule     timestamptz;
  requalifies integer := 0;
begin
  select e.societe_id into societe from salaries e where e.id = p_salarie;
  if societe is null then
    raise exception 'Salarié % introuvable.', p_salarie;
  end if;
  if not has_company_access(societe) then
    raise exception 'Accès refusé aux segments du salarié %.', p_salarie;
  end if;

  seuil_jour := fn_param_num('JOUR_H',    p_debut) * 60;
  seuil_sem  := fn_param_num('SEMAINE_H', p_debut) * 60;
  if seuil_jour is null or seuil_sem is null then
    raise exception 'Seuils absents du référentiel au % (JOUR_H, SEMAINE_H).', p_debut;
  end if;

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
    if semaine_vue is distinct from date_trunc('week', jour)::date then
      semaine_vue := date_trunc('week', jour)::date;
      cumul_sem := 0;
    end if;

    -- Le premier seuil franchi l'emporte.
    reste := least(seuil_jour - cumul_jour, seuil_sem - cumul_sem);

    if reste <= 0 then
      update segments_temps set classe_paie = 'heure_sup' where id = s.id;
      requalifies := requalifies + 1;
      imputees := 0;

    elsif reste < s.minutes then
      -- Le seuil tombe au milieu : on scinde à l'instant du franchissement.
      -- Une vacation de 7 h à 17 h dépasse à 15 h ; les huit premières heures
      -- restent normales.
      bascule := s.debut_le + make_interval(mins => reste::int);
      update segments_temps set fin_le = bascule where id = s.id;

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
      imputees := reste;

    else
      imputees := s.minutes;
    end if;

    -- Seules les minutes imputées au contingent normal avancent les cumuls. Une
    -- heure déjà supplémentaire au titre de la journée ne doit pas rapprocher du
    -- plafond hebdomadaire : elle serait comptée deux fois.
    cumul_jour := cumul_jour + imputees;
    cumul_sem  := cumul_sem  + imputees;
  end loop;

  return requalifies;
end;
$$;

comment on function fn_qualifier_heures_sup(uuid, date, date, text) is
  'Requalifie en heures supplémentaires les segments de travail au-delà des seuils journalier et hebdomadaire, en scindant celui qui franchit un seuil. Seules les minutes imputées au contingent normal avancent les cumuls : une heure déjà supplémentaire au titre du jour ne rapproche pas du plafond de la semaine. Contrôle l''accès à la société du salarié, `security definer` contournant RLS. Idempotente.';

revoke execute on function fn_qualifier_heures_sup(uuid, date, date, text) from public;
grant execute on function fn_qualifier_heures_sup(uuid, date, date, text) to authenticated;
