-- 115 — La phrase ne raconte pas les coupures techniques
--
-- Le découpage crée un segment à chaque changement de qualification : minuit, la
-- fin de la fenêtre de nuit, le franchissement d'un seuil. Ce sont des frontières
-- de calcul, pas des événements vécus. La phrase les récitait :
--
--   « travaillé de 22h00 à 00h00, puis travaillé de 00h00 à 02h00, …
--     puis travaillé de 03h00 à 06h00, puis travaillé de 06h00 à 07h00 »
--
-- Le salarié, lui, a travaillé de 22h00 à 02h00 puis de 03h00 à 07h00. Il ne
-- s'est rien passé à minuit ni à six heures — sinon dans le calcul de sa paie.
--
-- Les plages contiguës de même nature sont donc fusionnées **pour la phrase**.
-- Les totaux restent calculés segment par segment : c'est là que la distinction
-- entre nuit et jour compte, et elle n'est pas perdue.

create or replace function fn_releve_lisible(
  p_salarie uuid,
  p_jour    date,
  p_origine text default 'planifie'
)
returns table (
  phrase              text,
  minutes_effectives  integer,
  minutes_pause       integer,
  minutes_nuit        integer,
  minutes_dimanche    integer,
  minutes_ferie       integer,
  minutes_sup         integer
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  fuseau   constant text := 'Europe/Luxembourg';
  societe  uuid;
  s        record;
  morceaux text[] := array[]::text[];
  mentions text[] := array[]::text[];
  -- La plage en cours de constitution.
  fam      text := null;
  remun    boolean := null;
  depart   timestamptz;
  arrivee  timestamptz;
  duree    integer := 0;

  procedure_close boolean;
begin
  select e.societe_id into societe from salaries e where e.id = p_salarie;
  if societe is null then
    raise exception 'Salarié % introuvable.', p_salarie;
  end if;
  if not (has_company_access(societe) or is_self_employee(p_salarie)) then
    raise exception 'Accès refusé au relevé du salarié %.', p_salarie;
  end if;

  minutes_effectives := 0; minutes_pause := 0; minutes_nuit := 0;
  minutes_dimanche := 0; minutes_ferie := 0; minutes_sup := 0;

  for s in
    select t.*, c.famille, c.remunere
    from segments_temps t
    join ref_classe_paie c on c.code = t.classe_paie
    left join creneaux cr on cr.id = t.creneau_id
    where t.salarie_id = p_salarie
      and t.origine = p_origine
      and coalesce(cr.date_creneau, (t.debut_le at time zone fuseau)::date) = p_jour
    order by t.debut_le
  loop
    -- Les totaux, segment par segment : c'est là que la nuit se distingue du jour.
    if s.famille = 'travail' then
      minutes_effectives := minutes_effectives + s.minutes;
      if s.classe_paie = 'heure_sup' then minutes_sup := minutes_sup + s.minutes; end if;
      if s.est_nuit     then minutes_nuit     := minutes_nuit     + s.minutes; end if;
      if s.est_dimanche then minutes_dimanche := minutes_dimanche + s.minutes; end if;
      if s.est_ferie    then minutes_ferie    := minutes_ferie    + s.minutes; end if;
    elsif s.famille = 'interruption' then
      minutes_pause := minutes_pause + s.minutes;
    end if;

    -- La phrase, plage par plage : on prolonge tant que rien ne change.
    if fam is not null and s.famille = fam and s.debut_le = arrivee then
      arrivee := s.fin_le;
      duree := duree + s.minutes;
    else
      if fam is not null then
        morceaux := morceaux || fn_plage_lisible(fam, remun, depart, arrivee, duree,
                                                 array_length(morceaux, 1) is null);
      end if;
      fam := s.famille; remun := s.remunere;
      depart := s.debut_le; arrivee := s.fin_le; duree := s.minutes;
    end if;
  end loop;

  if fam is not null then
    morceaux := morceaux || fn_plage_lisible(fam, remun, depart, arrivee, duree,
                                             array_length(morceaux, 1) is null);
  end if;

  if array_length(morceaux, 1) is null then
    phrase := 'Aucun temps enregistré pour le ' || to_char(p_jour, 'DD/MM/YYYY') || '.';
    return next;
    return;
  end if;

  if minutes_nuit     > 0 then mentions := mentions || (fn_duree_lisible(minutes_nuit)     || ' de nuit'); end if;
  if minutes_dimanche > 0 then mentions := mentions || (fn_duree_lisible(minutes_dimanche) || ' le dimanche'); end if;
  if minutes_ferie    > 0 then mentions := mentions || (fn_duree_lisible(minutes_ferie)    || ' un jour férié'); end if;
  if minutes_sup      > 0 then mentions := mentions || (fn_duree_lisible(minutes_sup)      || ' en heures supplémentaires'); end if;
  if minutes_pause    > 0 then mentions := mentions || (fn_duree_lisible(minutes_pause)    || ' de pause'); end if;

  phrase := 'Vous avez ' || array_to_string(morceaux, ', ') || '. (Total : '
            || fn_duree_lisible(minutes_effectives) || ' effectives'
            || case when array_length(mentions, 1) is null then ''
                    else ', dont ' || array_to_string(mentions, ' et ') end
            || ')';
  return next;
end;
$$;

comment on function fn_releve_lisible(uuid, date, text) is
  'Rend le relevé d''une journée de travail en une phrase lisible par le salarié, et les totaux qui la fondent. Le rattachement suit la vacation et non le calendrier, et les plages contiguës de même nature sont fusionnées : le salarié ne lit pas les coupures de minuit ou de fin de nuit, qui sont des frontières de calcul. Les mentions de nuit, dimanche et jour férié se cumulent.';

revoke execute on function fn_releve_lisible(uuid, date, text) from public;
grant execute on function fn_releve_lisible(uuid, date, text) to authenticated;
