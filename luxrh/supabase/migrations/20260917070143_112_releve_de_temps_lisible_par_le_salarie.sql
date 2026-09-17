-- 112 — Le relevé de temps, dit en français
--
-- Un salarié ne lit pas une table de segments. Il veut savoir ce qu'il a fait et
-- ce qui lui est dû, en une phrase :
--
--   « Vous avez travaillé de 22h00 à 02h00, bénéficié d'une pause de 1h00
--     (02h00 à 03h00), puis travaillé de 03h00 à 07h00.
--     (Total : 8h effectives, dont 7h de nuit et 1h de pause) »
--
-- La phrase se construit à partir des segments, jamais d'un calcul parallèle :
-- deux comptes du même temps finissent toujours par diverger, et c'est celui que
-- le salarié lit qui aurait tort.
--
-- ### Les majorations se cumulent
--
-- En droit luxembourgeois, la majoration du dimanche ou du jour férié **se
-- cumule** avec celle du travail de nuit. C'est pourquoi les segments portent
-- trois drapeaux indépendants et non une classe unique — et pourquoi le décompte
-- ci-dessous compte une heure de nuit un dimanche dans les deux totaux. La
-- somme des mentions dépasse donc le temps travaillé, et c'est exact.

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
  premier  boolean := true;
  h        text;
  mentions text[] := array[]::text[];
begin
  select e.societe_id into societe from salaries e where e.id = p_salarie;
  if societe is null then
    raise exception 'Salarié % introuvable.', p_salarie;
  end if;
  -- Le salarié lit son propre relevé ; le gestionnaire lit celui de sa société.
  if not (has_company_access(societe) or is_self_employee(p_salarie)) then
    raise exception 'Accès refusé au relevé du salarié %.', p_salarie;
  end if;

  minutes_effectives := 0; minutes_pause := 0; minutes_nuit := 0;
  minutes_dimanche := 0; minutes_ferie := 0; minutes_sup := 0;

  for s in
    select t.*, c.famille, c.remunere
    from segments_temps t
    join ref_classe_paie c on c.code = t.classe_paie
    where t.salarie_id = p_salarie
      and t.origine = p_origine
      and (t.debut_le at time zone fuseau)::date = p_jour
    order by t.debut_le
  loop
    h := to_char(s.debut_le at time zone fuseau, 'HH24"h"MI')
         || ' à ' || to_char(s.fin_le at time zone fuseau, 'HH24"h"MI');

    if s.famille = 'travail' then
      minutes_effectives := minutes_effectives + s.minutes;
      if s.classe_paie = 'heure_sup' then minutes_sup := minutes_sup + s.minutes; end if;
      -- Cumulatifs et non exclusifs : une heure de nuit un dimanche compte deux fois.
      if s.est_nuit     then minutes_nuit     := minutes_nuit     + s.minutes; end if;
      if s.est_dimanche then minutes_dimanche := minutes_dimanche + s.minutes; end if;
      if s.est_ferie    then minutes_ferie    := minutes_ferie    + s.minutes; end if;

      morceaux := morceaux || ((case when premier then 'travaillé de ' else 'puis travaillé de ' end) || h);

    elsif s.famille = 'interruption' then
      minutes_pause := minutes_pause + s.minutes;
      morceaux := morceaux || ('bénéficié d''une pause de ' || fn_duree_lisible(s.minutes)
                               || ' (' || h || ')');
    else
      morceaux := morceaux || ((case when s.remunere then 'été en déplacement de '
                                     else 'effectué un trajet de ' end) || h);
    end if;
    premier := false;
  end loop;

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
  'Rend le relevé d''une journée en une phrase lisible par le salarié, et les totaux qui la fondent. Construit depuis les segments, jamais d''un calcul parallèle. Les mentions de nuit, dimanche et jour férié se cumulent : leur somme peut dépasser le temps travaillé, et c''est exact.';

revoke execute on function fn_releve_lisible(uuid, date, text) from public;
grant execute on function fn_releve_lisible(uuid, date, text) to authenticated;
