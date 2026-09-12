-- 83 — `date_fin` porte la sentinelle, comme toutes les fins de période
--
-- Vous aviez raison et mon argument était mauvais. J'avais soutenu qu'un contrat
-- à durée indéterminée « n'a pas de fin » et devait donc rester NULL. Mais c'est
-- précisément ce que la sentinelle exprime : fin INCONNUE, et non « fin en
-- 2037 ». Le raisonnement appliqué à `fin_validite` valait tout autant ici, et
-- le refuser laissait un NVL de plus dans le schéma Oracle.
--
-- BORNE HAUTE INCLUSE — à ne pas confondre avec `fin_validite`
-- ============================================================
-- `date_fin` est le dernier jour du contrat : il est en cours le jour J si
-- `date_fin >= J`. La contrainte d'exclusion le dit déjà, avec `'[]'`. Les
-- conditions réécrites plus bas conservent donc `>=`, pas `>`.
--
-- CE QUI RESTE NULLABLE, ET POURQUOI
-- ===================================
-- `ruptures_contrat.debut_preavis` / `fin_preavis` et
-- `sanctions_salarie.effet_du` / `effet_au`. L'absence y signifie « il n'y a pas
-- de période du tout » — une rupture pour faute grave n'a pas de préavis, un
-- avertissement n'a pas de période d'effet — et non « la période n'a pas de fin
-- connue ». Leur donner 2037-12-31 affirmerait un préavis courant jusqu'en 2037
-- et fausserait le calcul des protections contre le licenciement. Aucune n'entre
-- dans une contrainte d'exclusion : elles ne produisent donc aucun NVL.
--
-- UNE PREMIÈRE TENTATIVE A ÉCHOUÉ
-- ================================
-- L'expression rationnelle de réécriture admettait les parenthèses dans le
-- membre droit, et a donc traversé la fin d'une sous-requête `lateral` : le SQL
-- produit était invalide et la migration s'est annulée entièrement. Le membre
-- droit est désormais restreint à un identifiant simple, ce que sont les douze
-- occurrences réelles — vérifié une à une avant écriture.

set search_path = public;

-- 1. Les données. Remplacer NULL par la sentinelle RÉTRÉCIT l'intervalle
--    (NULL était non borné) : un rétrécissement ne peut pas créer de
--    chevauchement, la contrainte d'exclusion reste satisfaite.
do $donnees$
declare v_c int; v_s int;
begin
  update contrats set date_fin = date '2037-12-31' where date_fin is null;
  get diagnostics v_c = row_count;
  update statuts_salarie set date_fin = date '2037-12-31' where date_fin is null;
  get diagnostics v_s = row_count;
  raise notice '% contrat(s) et % statut(s) portent desormais la sentinelle.', v_c, v_s;
end $donnees$;

alter table contrats        alter column date_fin set default date '2037-12-31';
alter table contrats        alter column date_fin set not null;
alter table statuts_salarie alter column date_fin set default date '2037-12-31';
alter table statuts_salarie alter column date_fin set not null;

alter table contrats drop constraint if exists contrats_periode_coherente;
alter table contrats add constraint contrats_periode_coherente
  check (date_fin >= date_debut);
alter table statuts_salarie drop constraint if exists statuts_salarie_periode_coherente;
alter table statuts_salarie add constraint statuts_salarie_periode_coherente
  check (date_fin >= date_debut);

comment on column contrats.date_fin is
  'Dernier jour du contrat, borne haute INCLUSE : le contrat est en cours le jour J si date_fin >= J. Jamais nulle — un contrat à durée indéterminée porte la sentinelle 2037-12-31, qui se lit « fin inconnue » et non « fin en 2037 ». Le caractère déterminé ou non de la durée se lit sur genre, pas sur cette date.';
comment on column statuts_salarie.date_fin is
  'Dernier jour du statut, borne haute INCLUSE. Jamais nulle : un statut toujours actif porte la sentinelle 2037-12-31.';

-- 2. Les corps de fonctions.
do $fonctions$
declare
  f       record;
  v_def   text;
  v_avant text;
  v_n     int := 0;
begin
  for f in
    select p.oid from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
    where p.prokind = 'f' and p.prosrc ~ 'date_fin\s+is\s+null\s+or'
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    -- Membre droit : un identifiant simple, éventuellement suivi de « + n ».
    -- Aucune parenthèse admise, pour ne pas franchir la fin d'une sous-requête.
    v_def := regexp_replace(
      v_def,
      '\(\s*(\w+\.)?date_fin\s+is\s+null\s+or\s+((\w+\.)?date_fin\s*>=\s*\w[\w.]*(\s*\+\s*\d+)?)\s*\)',
      '\2', 'gi');
    if v_def is distinct from v_avant then
      execute v_def;
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '% fonction(s) nettoyee(s).', v_n;
end $fonctions$;

do $controle$
declare v_restant int;
begin
  select count(*) into v_restant
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
  where p.prokind = 'f' and p.prosrc ~ '(\w+\.)?date_fin\s+is\s+null';
  if v_restant > 0 then
    raise exception '% fonction(s) testent encore la nullite de date_fin.', v_restant;
  end if;
  raise notice 'date_fin : aucun test de nullite restant.';
end $controle$;
