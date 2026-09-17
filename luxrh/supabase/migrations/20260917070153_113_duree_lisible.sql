-- 113 — `fn_duree_lisible`, appelée par le relevé mais jamais créée
--
-- La migration 112 appelle `fn_duree_lisible`. PL/pgSQL n'analyse un corps qu'à
-- l'exécution : la migration est passée, et le premier appel aurait échoué sur
-- « function fn_duree_lisible(integer) does not exist ». Même piège qu'aux
-- migrations 98 et 99 — ce qui n'est pas exécuté n'est pas vérifié.

create or replace function fn_duree_lisible(p_minutes integer)
returns text
language sql
immutable
as $$
  -- « 1h30 », « 45min », « 8h ». Pas « 8h00 » : personne ne dit cela à l'oral,
  -- et ce relevé se lit à voix haute autant qu'à l'écran.
  select case
    when p_minutes is null then null
    when p_minutes = 0 then '0min'
    when p_minutes < 60 then p_minutes || 'min'
    when p_minutes % 60 = 0 then (p_minutes / 60) || 'h'
    else (p_minutes / 60) || 'h' || lpad((p_minutes % 60)::text, 2, '0')
  end;
$$;

comment on function fn_duree_lisible(integer) is
  'Rend une durée en minutes sous une forme lisible : 45min, 1h30, 8h. Employée par le relevé destiné au salarié.';

revoke execute on function fn_duree_lisible(integer) from public;
grant execute on function fn_duree_lisible(integer) to authenticated;

do $$
begin
  if fn_duree_lisible(0)   is distinct from '0min'  then raise exception '0'; end if;
  if fn_duree_lisible(45)  is distinct from '45min' then raise exception '45'; end if;
  if fn_duree_lisible(60)  is distinct from '1h'    then raise exception '60'; end if;
  if fn_duree_lisible(90)  is distinct from '1h30'  then raise exception '90'; end if;
  if fn_duree_lisible(65)  is distinct from '1h05'  then raise exception '65'; end if;
  if fn_duree_lisible(480) is distinct from '8h'    then raise exception '480'; end if;
  raise notice 'fn_duree_lisible : six cas vérifiés.';
end
$$;
