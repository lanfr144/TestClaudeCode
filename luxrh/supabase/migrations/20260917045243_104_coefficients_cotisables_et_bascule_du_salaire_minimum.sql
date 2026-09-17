-- 104 — Les coefficients cotisables, et le salaire minimum dérivé
--
-- ### Deux coefficients que le classeur n'historise pas
--
-- `MICP` (1,30) et `MACP` (5) ne figurent que dans les colonnes de travail du
-- classeur, jamais dans ses relevés datés — l'audit les signalait comme
-- bloquants. Sans eux, `MSQP` (minimum cotisable des pensionnés) et `MC`
-- (maximum cotisable) ne se dérivent pas et restent nuls.
--
-- Ce sont des coefficients, non des montants indexés : ils ne bougent pas d'un
-- relevé à l'autre. Ils sont chargés depuis les colonnes de travail, avec cette
-- provenance déclarée et **sans référence légale** — leur base est au Code de la
-- sécurité sociale, qui n'est pas au corpus. `fn_referential_gaps` continuera de
-- le rappeler.
--
-- ### Le salaire minimum vient désormais de la formule
--
-- `ssm_monthly_qualified` et `ssm_monthly_unqualified` faisaient double emploi
-- avec `MSQ18Q` et `MSNQ18`, désormais dérivés. Deux valeurs pour une même
-- grandeur finissent toujours par diverger — et elles divergeaient déjà d'un
-- centime : 3 165,35 € chargés contre 3 165,34 € calculés.
--
-- La formule du classeur tronque au centime là où la valeur chargée arrondissait.
-- Sur un salaire minimum, c'est le seuil de licéité d'une rémunération : la
-- source fait foi, et la valeur chargée disparaît.

insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, reference_legale, note)
values
  ('social', 'MICP', 'Coefficient du minimum cotisable des pensionnés',
   1.3, 'facteur', date '1970-01-01', date '2037-12-31',
   'paramètres.xlsx (colonne de travail)', null,
   'Cent trente pour cent du salaire social minimum. Absent des relevés datés du classeur ; base légale au Code de la sécurité sociale, à verser au corpus.'),
  ('social', 'MACP', 'Coefficient du maximum cotisable',
   5, 'facteur', date '1970-01-01', date '2037-12-31',
   'paramètres.xlsx (colonne de travail)', null,
   'Cinq fois le salaire social minimum, tous régimes sauf assurance dépendance. Absent des relevés datés ; base légale au Code de la sécurité sociale.')
on conflict do nothing;

-- ------------------------------------------- `fn_min_salary` cite les clés du classeur
do $$
declare
  corps text;
  avant text;
begin
  corps := pg_get_functiondef('fn_min_salary'::regproc);
  avant := corps;
  corps := replace(corps, '''ssm_monthly_qualified''',   '''MSQ18Q''');
  corps := replace(corps, '''ssm_monthly_unqualified''', '''MSNQ18''');
  if corps = avant then
    raise exception 'ARRÊT : fn_min_salary ne cite plus les anciennes clés — déjà repris ?';
  end if;
  execute corps;
end
$$;

-- ------------------------------------------------- retrait des clés supplantées
do $$
declare
  citations text;
  retirees  int;
begin
  select string_agg(distinct proname, ', ') into citations
  from pg_proc
  where pronamespace = 'public'::regnamespace
    and pg_get_functiondef(oid) ~ 'ssm_monthly_(un)?qualified';

  if citations is not null then
    raise exception 'ARRÊT : ces routines citent encore les anciennes clés — %', citations;
  end if;

  delete from parametres_legaux
   where cle_parametre in ('ssm_monthly_qualified', 'ssm_monthly_unqualified');
  get diagnostics retirees = row_count;
  raise notice '% version(s) retirée(s).', retirees;
end
$$;

-- --------------------------------------------------------------- vérification
do $$
declare
  ssm    numeric := fn_param_num('SSM',    date '2025-01-01');
  qual   numeric := fn_param_num('MSQ18Q', date '2025-01-01');
  msqp   numeric := fn_param_num('MSQP',   date '2025-01-01');
  mc     numeric := fn_param_num('MC',     date '2025-01-01');
begin
  if ssm  is distinct from 2637.79   then raise exception 'SSM = % au lieu de 2637,79', ssm; end if;
  if qual is distinct from 3165.34   then raise exception 'MSQ18Q = % au lieu de 3165,34', qual; end if;
  if msqp is null                    then raise exception 'MSQP reste nul malgré MICP'; end if;
  if mc   is null                    then raise exception 'MC reste nul malgré MACP'; end if;
  raise notice 'Socle 2025-01-01 : SSM %, qualifié %, min. pensionnés %, max. cotisable %',
               ssm, qual, msqp, mc;
end
$$;
