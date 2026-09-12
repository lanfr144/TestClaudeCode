-- 81 — Les deux derniers `coalesce` morts, et une colonne de sortie oubliée
--
-- Suite du nettoyage entamé en 80. Deux fonctions enrobaient encore
-- `fin_validite` dans un `coalesce`, alors que la colonne est `not null` depuis
-- la migration 70.
--
-- 1. `fn_referential_gaps` bornait à `date '9999-12-31'`. Outre l'inutilité, la
--    sentinelle était la mauvaise : le projet n'en connaît qu'une, **2037-12-31**,
--    choisie pour tenir dans un `time_t` 32 bits signé. Deux sentinelles
--    concurrentes dans un même schéma, c'est la garantie qu'un jour l'une sera
--    comparée à l'autre.
--
-- 2. `fn_sanction_check` affichait `coalesce(fin_validite::text, 'indéterminé')`.
--    Le repli ne se déclenchait plus, si bien que le message annonçait une
--    validité s'arrêtant au « 2037-12-31 » — une date de convention présentée à
--    l'utilisateur comme une échéance réelle. Le test porte désormais sur la
--    sentinelle, ce qui rend « indéterminé » à nouveau atteignable.
--
-- Et une omission de ma part : la colonne de sortie `latest_covered` n'a pas été
-- traduite par la migration 77 — je l'avais laissée tomber en recopiant la table
-- de correspondance. Elle devient `couvert_jusqua`, comme prévu au dictionnaire.
-- Aucune interface ne la lisait, ce qui explique que rien ne l'ait signalée : une
-- colonne que personne ne lit ne se plaint pas d'être mal nommée.

set search_path = public;

-- Le type de retour change : `create or replace` est refusé, il faut supprimer.
drop function if exists public.fn_referential_gaps(date);

create function public.fn_referential_gaps(p_since date default '2019-12-31'::date)
returns table(famille famille_parametre, cle_parametre text, libelle text,
              couvert_depuis date, couvert_jusqua date, versions integer,
              couvre_depuis boolean, jours_manquants integer, lu_par text)
language sql stable set search_path to 'public'
as $function$
  select lp.famille,
         coalesce(ep.cle_parametre, lp.cle_parametre)       as cle_parametre,
         min(lp.libelle)                                    as libelle,
         min(lp.debut_validite)                             as couvert_depuis,
         -- `fin_validite` est non nulle : une validité ouverte porte déjà la
         -- sentinelle 2037-12-31. Aucun repli à prévoir.
         max(lp.fin_validite)                               as couvert_jusqua,
         count(lp.id)::int                                  as versions,
         coalesce(min(lp.debut_validite) <= p_since, false) as couvre_depuis,
         case when count(lp.id) = 0 then null
              else greatest(0, (min(lp.debut_validite) - p_since))::int end as jours_manquants,
         min(ep.lu_par)                                     as lu_par
  from parametres_attendus ep
  full outer join parametres_legaux lp on lp.cle_parametre = ep.cle_parametre
  group by lp.famille, coalesce(ep.cle_parametre, lp.cle_parametre)
  order by count(lp.id) = 0 desc,
           coalesce(min(lp.debut_validite) <= p_since, false),
           lp.famille, 2;
$function$;

comment on function public.fn_referential_gaps(date) is
  'Recense les paramètres légaux attendus et l''historique réellement chargé : depuis quand chacun est couvert, jusqu''à quand, combien de versions, et combien de jours manquent avant la date de référence. Une clé entièrement absente y figure avec zéro version — c''est la raison d''être de la jointure externe complète sur parametres_attendus.';

revoke execute on function public.fn_referential_gaps(date) from public, anon;
grant  execute on function public.fn_referential_gaps(date) to authenticated;

-- `fn_sanction_check` : rendre « indéterminé » à nouveau atteignable.
do $sanction$
declare v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
  where p.proname = 'fn_sanction_check';

  v_def := replace(v_def,
    'coalesce(t.fin_validite::text, ''indéterminé'')',
    'case when t.fin_validite >= date ''2037-12-31'' then ''indéterminé'' '
    || 'else t.fin_validite::text end');

  execute v_def;
end $sanction$;

-- Contrôle : plus aucun repli sur `fin_validite`, nulle part.
do $controle$
declare v_restant int;
begin
  select count(*) into v_restant
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
  where p.prokind = 'f'
    and (p.prosrc ~* 'coalesce\s*\(\s*[\w.]*fin_validite'
      or p.prosrc ~* '[\w.]*fin_validite\s+is\s+null');
  if v_restant > 0 then
    raise exception '% fonction(s) traitent encore fin_validite comme nullable.', v_restant;
  end if;
  raise notice 'fin_validite : plus aucun repli ni test de nullite dans le schema.';
end $controle$;
