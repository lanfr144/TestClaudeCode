-- 118 — `fn_tracer_suivi_temps` était exécutable par `anon`
--
-- Une fonction créée sans `revoke` hérite du droit d'exécution implicite de
-- PUBLIC. Celle-ci est `security definer` et écrit dans le journal d'audit : un
-- visiteur anonyme aurait pu l'appeler.
--
-- L'exploitation directe est malaisée — une fonction de déclencheur attend un
-- contexte que seul PostgreSQL fournit — mais le raisonnement est le mauvais. Un
-- droit qu'on accorde parce qu'il « ne sert à rien » est un droit qu'on n'a pas
-- décidé d'accorder.
--
-- Une fonction de déclencheur n'a besoin d'aucun appelant : PostgreSQL l'exécute
-- sous le propriétaire de la table, sans vérifier de droit. Elle est donc retirée
-- à tout le monde.
--
-- Relevé par `tools/verifier_coherence.py`, dont c'est exactement l'office.

revoke execute on function fn_tracer_suivi_temps() from public;
revoke execute on function fn_tracer_suivi_temps() from anon;

do $$
declare
  ouvertes text;
begin
  select string_agg(p.proname, ', ')
    into ouvertes
  from pg_proc p
  where p.pronamespace = 'public'::regnamespace
    and has_function_privilege('anon', p.oid, 'execute')
    and p.proname like 'fn_%';

  if ouvertes is not null then
    raise exception 'ARRÊT : ces fonctions restent ouvertes à anon — %', ouvertes;
  end if;
  raise notice 'Aucune fonction applicative exécutable par anon.';
end
$$;
