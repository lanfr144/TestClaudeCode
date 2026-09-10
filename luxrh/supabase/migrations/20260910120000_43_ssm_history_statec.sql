-- 43. Historique officiel du salaire social minimum et de l'indice.
--
-- Le referentiel ne portait qu'une seule version de ces trois parametres, celle
-- en vigueur. Tout recalcul portant sur une periode anterieure -- une regularisation,
-- un contrat repris, un controle CCSS -- lisait donc un montant trop eleve.
--
-- Source : STATEC, portail lustat, jeu de donnees DF_C1201
-- « Salaire social minimum detaille (en EUR) », publie sur data.public.lu.
-- Les valeurs ne sont pas calculees ici : elles sont reprises telles que publiees.
-- La derniere version (2026-06-01), deja presente et issue de la publication CCSS,
-- est laissee intacte ; les valeurs STATEC a cette date lui sont identiques,
-- ce qui vaut recoupement entre les deux sources.

set search_path = public, extensions;

with officiel(param_key, vfrom, vto, valeur, indice) as (values
  ('ssm_monthly_unqualified', date '2006-12-01', date '2007-01-01', 1541.00, 668.46),
  ('ssm_monthly_unqualified', date '2007-01-01', date '2008-03-01', 1570.28, 668.46),
  ('ssm_monthly_unqualified', date '2008-03-01', date '2009-01-01', 1609.53, 685.17),
  ('ssm_monthly_unqualified', date '2009-01-01', date '2009-03-01', 1641.74, 685.17),
  ('ssm_monthly_unqualified', date '2009-03-01', date '2010-07-01', 1682.76, 702.29),
  ('ssm_monthly_unqualified', date '2010-07-01', date '2011-01-01', 1724.81, 719.84),
  ('ssm_monthly_unqualified', date '2011-01-01', date '2011-10-01', 1757.56, 719.84),
  ('ssm_monthly_unqualified', date '2011-10-01', date '2012-10-01', 1801.49, 737.83),
  ('ssm_monthly_unqualified', date '2012-10-01', date '2013-01-01', 1846.51, 756.27),
  ('ssm_monthly_unqualified', date '2013-01-01', date '2013-10-01', 1874.19, 756.27),
  ('ssm_monthly_unqualified', date '2013-10-01', date '2015-01-01', 1921.03, 775.17),
  ('ssm_monthly_unqualified', date '2015-01-01', date '2017-01-01', 1922.96, 775.17),
  ('ssm_monthly_unqualified', date '2017-01-01', date '2018-08-01', 1998.59, 794.54),
  ('ssm_monthly_unqualified', date '2018-08-01', date '2019-01-01', 2048.54, 814.40),
  ('ssm_monthly_unqualified', date '2019-01-01', date '2020-01-01', 2089.75, 814.40),
  ('ssm_monthly_unqualified', date '2020-01-01', date '2021-01-01', 2141.99, 834.76),
  ('ssm_monthly_unqualified', date '2021-01-01', date '2021-10-01', 2201.93, 834.76),
  ('ssm_monthly_unqualified', date '2021-10-01', date '2022-04-01', 2256.95, 855.62),
  ('ssm_monthly_unqualified', date '2022-04-01', date '2023-01-01', 2313.38, 877.01),
  ('ssm_monthly_unqualified', date '2023-01-01', date '2023-02-01', 2387.40, 877.01),
  ('ssm_monthly_unqualified', date '2023-02-01', date '2023-04-01', 2447.07, 898.93),
  ('ssm_monthly_unqualified', date '2023-04-01', date '2023-09-01', 2508.24, 921.40),
  ('ssm_monthly_unqualified', date '2023-09-01', date '2025-01-01', 2570.93, 944.43),
  ('ssm_monthly_unqualified', date '2025-01-01', date '2025-05-01', 2637.79, 944.43),
  ('ssm_monthly_unqualified', date '2025-05-01', date '2026-06-01', 2703.74, 968.04),
  ('ssm_monthly_qualified', date '2006-12-01', date '2007-01-01', 1849.20, 668.46),
  ('ssm_monthly_qualified', date '2007-01-01', date '2008-03-01', 1884.34, 668.46),
  ('ssm_monthly_qualified', date '2008-03-01', date '2009-01-01', 1931.44, 685.17),
  ('ssm_monthly_qualified', date '2009-01-01', date '2009-03-01', 1970.08, 685.17),
  ('ssm_monthly_qualified', date '2009-03-01', date '2010-07-01', 2019.31, 702.29),
  ('ssm_monthly_qualified', date '2010-07-01', date '2011-01-01', 2069.77, 719.84),
  ('ssm_monthly_qualified', date '2011-01-01', date '2011-10-01', 2109.07, 719.84),
  ('ssm_monthly_qualified', date '2011-10-01', date '2012-10-01', 2161.78, 737.83),
  ('ssm_monthly_qualified', date '2012-10-01', date '2013-01-01', 2215.81, 756.27),
  ('ssm_monthly_qualified', date '2013-01-01', date '2013-10-01', 2249.03, 756.27),
  ('ssm_monthly_qualified', date '2013-10-01', date '2015-01-01', 2305.23, 775.17),
  ('ssm_monthly_qualified', date '2015-01-01', date '2017-01-01', 2307.56, 775.17),
  ('ssm_monthly_qualified', date '2017-01-01', date '2018-08-01', 2398.30, 794.54),
  ('ssm_monthly_qualified', date '2018-08-01', date '2019-01-01', 2458.25, 814.40),
  ('ssm_monthly_qualified', date '2019-01-01', date '2020-01-01', 2507.70, 814.40),
  ('ssm_monthly_qualified', date '2020-01-01', date '2021-01-01', 2570.39, 834.76),
  ('ssm_monthly_qualified', date '2021-01-01', date '2021-10-01', 2642.32, 834.76),
  ('ssm_monthly_qualified', date '2021-10-01', date '2022-04-01', 2708.35, 855.62),
  ('ssm_monthly_qualified', date '2022-04-01', date '2023-01-01', 2776.05, 877.01),
  ('ssm_monthly_qualified', date '2023-01-01', date '2023-02-01', 2864.88, 877.01),
  ('ssm_monthly_qualified', date '2023-02-01', date '2023-04-01', 2936.48, 898.93),
  ('ssm_monthly_qualified', date '2023-04-01', date '2023-09-01', 3009.88, 921.40),
  ('ssm_monthly_qualified', date '2023-09-01', date '2025-01-01', 3085.11, 944.43),
  ('ssm_monthly_qualified', date '2025-01-01', date '2025-05-01', 3165.35, 944.43),
  ('ssm_monthly_qualified', date '2025-05-01', date '2026-06-01', 3244.48, 968.04),
  ('wage_index', date '2006-12-01', date '2007-01-01', 668.46, 668.46),
  ('wage_index', date '2007-01-01', date '2008-03-01', 668.46, 668.46),
  ('wage_index', date '2008-03-01', date '2009-01-01', 685.17, 685.17),
  ('wage_index', date '2009-01-01', date '2009-03-01', 685.17, 685.17),
  ('wage_index', date '2009-03-01', date '2010-07-01', 702.29, 702.29),
  ('wage_index', date '2010-07-01', date '2011-01-01', 719.84, 719.84),
  ('wage_index', date '2011-01-01', date '2011-10-01', 719.84, 719.84),
  ('wage_index', date '2011-10-01', date '2012-10-01', 737.83, 737.83),
  ('wage_index', date '2012-10-01', date '2013-01-01', 756.27, 756.27),
  ('wage_index', date '2013-01-01', date '2013-10-01', 756.27, 756.27),
  ('wage_index', date '2013-10-01', date '2015-01-01', 775.17, 775.17),
  ('wage_index', date '2015-01-01', date '2017-01-01', 775.17, 775.17),
  ('wage_index', date '2017-01-01', date '2018-08-01', 794.54, 794.54),
  ('wage_index', date '2018-08-01', date '2019-01-01', 814.40, 814.40),
  ('wage_index', date '2019-01-01', date '2020-01-01', 814.40, 814.40),
  ('wage_index', date '2020-01-01', date '2021-01-01', 834.76, 834.76),
  ('wage_index', date '2021-01-01', date '2021-10-01', 834.76, 834.76),
  ('wage_index', date '2021-10-01', date '2022-04-01', 855.62, 855.62),
  ('wage_index', date '2022-04-01', date '2023-01-01', 877.01, 877.01),
  ('wage_index', date '2023-01-01', date '2023-02-01', 877.01, 877.01),
  ('wage_index', date '2023-02-01', date '2023-04-01', 898.93, 898.93),
  ('wage_index', date '2023-04-01', date '2023-09-01', 921.40, 921.40),
  ('wage_index', date '2023-09-01', date '2025-01-01', 944.43, 944.43),
  ('wage_index', date '2025-01-01', date '2025-05-01', 944.43, 944.43),
  ('wage_index', date '2025-05-01', date '2026-06-01', 968.04, 968.04)
),
courant as (
  -- family / label / unit ne se reinventent pas : on les reprend de la version
  -- existante, pour que l'historique soit homogene avec elle.
  select distinct on (param_key) param_key, family, label, unit
    from legal_parameters
   where param_key in (select param_key from officiel)
   order by param_key, valid_from desc
)
insert into legal_parameters
      (family, param_key, label, value_num, unit, valid_from, valid_to,
       index_ref, source, legal_ref, note)
select c.family, o.param_key, c.label, o.valeur, c.unit, o.vfrom, o.vto,
       o.indice,
       'STATEC / lustat DF_C1201',
       'Reglement grand-ducal portant fixation du salaire social minimum',
       'Historique repris du portail open data ; valeur publiee, non recalculee.'
  from officiel o
  join courant c using (param_key)
 where not exists (
   select 1 from legal_parameters lp
    where lp.param_key = o.param_key and lp.valid_from = o.vfrom);
