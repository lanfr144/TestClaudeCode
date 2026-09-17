-- 116 — `fn_plage_lisible`, et une variable oubliée
--
-- La migration 115 appelle `fn_plage_lisible` sans l'avoir créée, et déclare une
-- variable `procedure_close` qui ne sert à rien. Ni l'un ni l'autre n'empêche la
-- migration de passer : PL/pgSQL n'analyse le corps qu'à l'exécution. C'est la
-- troisième fois dans ce chantier — d'où les tests qui appellent réellement.

create or replace function fn_plage_lisible(
  p_famille  text,
  p_remunere boolean,
  p_debut    timestamptz,
  p_fin      timestamptz,
  p_minutes  integer,
  p_premier  boolean
)
returns text
language sql
immutable
as $$
  select case p_famille
    when 'travail' then
      (case when p_premier then 'travaillé de ' else 'puis travaillé de ' end)
      || to_char(p_debut at time zone 'Europe/Luxembourg', 'HH24"h"MI')
      || ' à ' || to_char(p_fin at time zone 'Europe/Luxembourg', 'HH24"h"MI')
    when 'interruption' then
      'bénéficié d''une pause de ' || fn_duree_lisible(p_minutes)
      || ' (' || to_char(p_debut at time zone 'Europe/Luxembourg', 'HH24"h"MI')
      || ' à ' || to_char(p_fin at time zone 'Europe/Luxembourg', 'HH24"h"MI') || ')'
    else
      (case when p_remunere then 'été en déplacement de ' else 'effectué un trajet de ' end)
      || to_char(p_debut at time zone 'Europe/Luxembourg', 'HH24"h"MI')
      || ' à ' || to_char(p_fin at time zone 'Europe/Luxembourg', 'HH24"h"MI')
  end;
$$;

comment on function fn_plage_lisible(text, boolean, timestamptz, timestamptz, integer, boolean) is
  'Met en mots une plage de temps, selon sa nature. Employée par fn_releve_lisible pour composer la phrase rendue au salarié.';

revoke execute on function fn_plage_lisible(text, boolean, timestamptz, timestamptz, integer, boolean) from public;
grant execute on function fn_plage_lisible(text, boolean, timestamptz, timestamptz, integer, boolean) to authenticated;

-- La variable inutile de la migration 115.
do $$
declare
  corps text;
begin
  corps := pg_get_functiondef('fn_releve_lisible(uuid, date, text)'::regprocedure);
  if corps like '%procedure_close%' then
    corps := replace(corps, E'\n  procedure_close boolean;\n', E'\n');
    execute corps;
    raise notice 'fn_releve_lisible : variable inutile retirée.';
  end if;
end
$$;
