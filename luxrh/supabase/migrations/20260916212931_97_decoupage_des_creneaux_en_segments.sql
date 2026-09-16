-- 97 — Découper une vacation en segments homogènes
--
-- Le principe : on rassemble tous les instants où une qualification **change**,
-- on les trie, et l'on crée un segment entre chaque paire consécutive. Chaque
-- segment est alors homogène par construction, sans qu'il faille énumérer les cas.
--
-- Les instants de rupture :
--
--   * le début et la fin de la vacation ;
--   * le début et la fin de la pause ;
--   * chaque minuit traversé — le jour change, donc le dimanche et le jour férié
--     peuvent changer ;
--   * chaque passage de `H_NUIT` et de `H_MATIN` — les bornes de la fenêtre de
--     nuit, lues dans le référentiel et jamais écrites en dur.
--
-- Les qualifications s'évaluent **au milieu** de chaque sous-intervalle. Les
-- évaluer sur une borne ferait dépendre le résultat du fait que la borne est
-- incluse ou exclue, et un segment de 22 h 00 à 23 h 00 se retrouverait tantôt
-- de nuit, tantôt non.

create or replace function fn_decouper_creneau(p_creneau uuid)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c            record;
  fuseau       constant text := 'Europe/Luxembourg';
  debut        timestamptz;
  fin          timestamptz;
  pause_debut  timestamptz;
  pause_fin    timestamptz;
  h_nuit       numeric;
  h_matin      numeric;
  ruptures     timestamptz[];
  jour         date;
  bornes       timestamptz[];
  i            integer;
  seg_debut    timestamptz;
  seg_fin      timestamptz;
  milieu       timestamptz;
  heure_locale numeric;
  est_pause    boolean;
  poses        integer := 0;
begin
  select cr.*, p.societe_id as societe
    into c
  from creneaux cr
  join plannings p on p.id = cr.planning_id
  where cr.id = p_creneau;

  if not found then
    raise exception 'Créneau % introuvable.', p_creneau;
  end if;

  debut := (c.date_creneau + c.heure_debut) at time zone fuseau;
  fin   := (c.date_creneau + c.heure_fin)   at time zone fuseau;

  -- Une vacation qui se termine avant d'avoir commencé franchit minuit.
  if fin <= debut then
    fin := (c.date_creneau + 1 + c.heure_fin) at time zone fuseau;
  end if;

  -- La fenêtre de nuit vient du référentiel. Elle a une valeur pour toute date
  -- depuis la sentinelle ; si elle manquait, mieux vaut s'arrêter que produire
  -- des segments dont aucun ne serait de nuit.
  h_nuit  := fn_param_num('H_NUIT',  c.date_creneau);
  h_matin := fn_param_num('H_MATIN', c.date_creneau);
  if h_nuit is null or h_matin is null then
    raise exception 'Fenêtre de nuit absente du référentiel au % (H_NUIT, H_MATIN).', c.date_creneau;
  end if;

  -- La pause se place au milieu de la vacation. Le créneau ne dit pas quand elle
  -- est prise ; la poser au milieu est une convention, énoncée plutôt que tue.
  -- Un relevé de temps réel, lui, la situera exactement.
  if coalesce(c.pause_minutes, 0) > 0 then
    pause_debut := debut + ((fin - debut) / 2) - make_interval(mins => c.pause_minutes / 2);
    pause_fin   := pause_debut + make_interval(mins => c.pause_minutes);
  end if;

  ruptures := array[debut, fin];
  if pause_debut is not null then
    ruptures := ruptures || pause_debut || pause_fin;
  end if;

  -- Minuits, débuts et fins de nuit traversés.
  jour := (debut at time zone fuseau)::date;
  while jour <= (fin at time zone fuseau)::date loop
    ruptures := ruptures
      || ((jour + 1)::timestamp at time zone fuseau)
      || ((jour + make_interval(mins => (h_nuit  * 60)::int))::timestamp at time zone fuseau)
      || ((jour + make_interval(mins => (h_matin * 60)::int))::timestamp at time zone fuseau);
    jour := jour + 1;
  end loop;

  select array_agg(distinct r order by r)
    into bornes
  from unnest(ruptures) r
  where r >= debut and r <= fin;

  delete from segments_temps where creneau_id = p_creneau and origine = 'planifie';

  for i in 1 .. array_length(bornes, 1) - 1 loop
    seg_debut := bornes[i];
    seg_fin   := bornes[i + 1];
    continue when seg_fin <= seg_debut;

    milieu       := seg_debut + (seg_fin - seg_debut) / 2;
    heure_locale := extract(hour from milieu at time zone fuseau)
                  + extract(minute from milieu at time zone fuseau) / 60.0;
    est_pause    := pause_debut is not null
                    and milieu >= pause_debut and milieu < pause_fin;

    insert into segments_temps (
      societe_id, salarie_id, creneau_id, site_client_id,
      debut_le, fin_le, classe_paie, couverture_aaa,
      est_nuit, est_dimanche, est_ferie, origine
    ) values (
      c.societe, c.salarie_id, p_creneau, c.site_client_id,
      seg_debut, seg_fin,
      case when est_pause then 'pause_repas' else 'normal' end,
      -- Le travail effectif est couvert. La pause ne l'est pas d'office : sa
      -- qualification relève du Code de la sécurité sociale, absent du corpus.
      case when est_pause then 'a_determiner' else 'couvert' end,
      (heure_locale >= h_nuit or heure_locale < h_matin),
      extract(dow from milieu at time zone fuseau) = 0,
      exists (select 1 from jours_feries jf
               where jf.date_ferie = (milieu at time zone fuseau)::date),
      'planifie'
    );
    poses := poses + 1;
  end loop;

  return poses;
end;
$$;

comment on function fn_decouper_creneau(uuid) is
  'Découpe une vacation planifiée en segments homogènes et les enregistre. Rend le nombre de segments posés. Idempotente : les segments planifiés du créneau sont remplacés à chaque appel.';

revoke execute on function fn_decouper_creneau(uuid) from public;
grant execute on function fn_decouper_creneau(uuid) to authenticated;
