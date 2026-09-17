-- 103 — Dériver ce que le classeur calcule au lieu de le stocker
--
-- Le classeur ne recopie pas dans ses colonnes historiques les valeurs qu'il
-- déduit d'autres valeurs : le salaire social minimum se calcule de `ssm_100` et
-- de l'indice, et n'est donc attesté nulle part au 1er janvier 2025. La migration
-- 91 a refusé de reconduire une valeur périmée ; il reste à savoir la calculer.
--
-- Les formules de la colonne « formule » du classeur sont reprises telles
-- quelles. Aucune n'est réécrite « plus simplement » : une formule de paie
-- reproduite de mémoire est une formule fausse.
--
--     SSM      = ARRONDI(ssm_100 × indice / 100 ; 2)
--     MSNQ18   = SSM
--     MSNQ17   = PLANCHER(SSM × MSNQ17P ; 0,01)          MSNQ17P = 0,80
--     MSNQ15   = PLANCHER(SSM × MSNQ15P ; 0,01)          MSNQ15P = 0,75
--     MSQ18Q   = PLANCHER(SSM × MSQ18P  ; 0,01)          MSQ18P  = 1,20
--     MSQP     = PLANCHER(SSM × MICP    ; 0,01)          MICP    = 1,30
--     MC       = ARRONDI(indice / 100 × ssm_100 × MACP ; 2)   MACP = 5
--     …H       = PLANCHER(… / HEURS_MOIS ; 0,0001)       HEURS_MOIS = 173
--     IF       = ARRONDI(SSM / indice × 450 ; 2)
--     CPMi     = SSM ; CPMa = ARRONDI(CPMi × 5 / 3 ; 2)
--     CR_MAX   = 15 − CR_PAR
--
-- ### Plancher et non arrondi : un centime qui compte
--
-- Le classeur prescrit `PLANCHER.MATH` pour les multiples du SSM, pas `ARRONDI`.
-- Au 1er janvier 2025 : 2 637,79 × 1,2 = 3 165,348. Le plancher au centime donne
-- **3 165,34 €** ; l'arrondi donnerait 3 165,35 €. Le référentiel portait la
-- seconde valeur sous `ssm_monthly_qualified`.
--
-- Un centime sur un salaire minimum n'est pas un détail : c'est le seuil au-delà
-- duquel une rémunération est licite. La formule du classeur fait foi, et l'écart
-- est consigné plutôt que lissé.
--
-- `MSNQ18H100` porte dans le classeur la **même formule** que `MSNQ18H` alors que
-- ses valeurs historiques diffèrent d'un facteur dix (1,6145 contre 14,8609).
-- L'une des deux est fausse ; faute de savoir laquelle, aucune n'est dérivée ici.

create or replace function fn_deriver_parametre(p_cle text, p_on date)
returns numeric
language plpgsql
stable
as $$
declare
  ssm100  numeric := fn_param_num('ssm_100', p_on);
  indice  numeric := fn_param_num('indice', p_on);
  heures  numeric := fn_param_num('HEURS_MOIS', p_on);
  ssm     numeric;
begin
  -- Sans les deux ingrédients de base, rien ne se dérive. On rend NULL plutôt
  -- qu'un nombre : une valeur manquante doit rester manquante.
  if ssm100 is null or indice is null then
    return null;
  end if;

  ssm := round(ssm100 * indice / 100, 2);

  return case p_cle
    when 'SSM'       then ssm
    when 'MSNQ18'    then ssm
    when 'CPMi'      then ssm
    when 'MSNQ17'    then floor(ssm * fn_param_num('MSNQ17P', p_on) * 100) / 100
    when 'MSNQ15'    then floor(ssm * fn_param_num('MSNQ15P', p_on) * 100) / 100
    when 'MSQ18Q'    then floor(ssm * fn_param_num('MSQ18P',  p_on) * 100) / 100
    when 'MSQP'      then floor(ssm * fn_param_num('MICP',    p_on) * 100) / 100
    when 'MC'        then round(indice / 100 * ssm100 * fn_param_num('MACP', p_on), 2)
    when 'IF'        then round(ssm / indice * 450, 2)
    when 'CPMa'      then round(ssm * 5 / 3, 2)
    when 'CR_MAX'    then 15 - fn_param_num('CR_PAR', p_on)
    when 'REVISMFCM' then fn_param_num('REVISA', p_on)
    when 'PPSHJ'     then round(ssm100 * 0.09, 2)
    -- Les taux horaires : le montant mensuel divisé par le forfait de cent
    -- soixante-treize heures de l'art. L. 232-7, tronqué au dix-millième.
    when 'MSNQ18H'   then floor(ssm / heures * 10000) / 10000
    when 'MSNQ17H'   then floor(floor(ssm * fn_param_num('MSNQ17P', p_on) * 100) / 100
                                / heures * 10000) / 10000
    when 'MSNQ15H'   then floor(floor(ssm * fn_param_num('MSNQ15P', p_on) * 100) / 100
                                / heures * 10000) / 10000
    when 'MSQ18H'    then floor(floor(ssm * fn_param_num('MSQ18P', p_on) * 100) / 100
                                / heures * 10000) / 10000
    when 'CPMiH'     then round(ssm / heures, 2)
    when 'CPMaH'     then round(round(ssm * 5 / 3, 2) / heures, 2)
    else null
  end;
end;
$$;

comment on function fn_deriver_parametre(text, date) is
  'Calcule un paramètre que le classeur déduit d''autres paramètres, selon les formules de sa colonne « formule ». Rend NULL si les ingrédients manquent — jamais une valeur de remplacement. Les multiples du salaire social minimum se tronquent au centime, ils ne s''arrondissent pas : au 1er janvier 2025, le minimum qualifié vaut 3 165,34 € et non 3 165,35 €.';

revoke execute on function fn_deriver_parametre(text, date) from public;
grant execute on function fn_deriver_parametre(text, date) to authenticated;

-- `fn_param_num` sert la valeur dérivée en **dernier** recours. L'ordre importe :
--   1. la valeur explicitement chargée ;
--   2. la dérivation déclarative déjà en place (`derive_de_cle`, `facteur_derive`) ;
--   3. la formule du classeur.
-- Le défaut `current_date` est conservé : le retirer ferait échouer tous les
-- appels à un seul argument, et PostgreSQL refuse d'ailleurs de l'ôter par
-- « create or replace ».
create or replace function fn_param_num(p_key text, p_on date default current_date)
returns numeric
language plpgsql
stable
as $$
declare lp parametres_legaux;
begin
  select * into lp from parametres_legaux
  where cle_parametre = p_key and debut_validite <= p_on and fin_validite > p_on
  limit 1;

  if not found then
    return fn_deriver_parametre(p_key, p_on);
  end if;
  if lp.valeur_num is not null then return lp.valeur_num; end if;
  if lp.derive_de_cle is not null then
    return fn_param_num(lp.derive_de_cle, p_on) * coalesce(lp.facteur_derive, 1);
  end if;
  return fn_deriver_parametre(p_key, p_on);
end
$$;

comment on function fn_param_num(text, date) is
  'Valeur numérique d''un paramètre à une date. Lit le référentiel ; à défaut, applique la dérivation déclarative, puis les formules du classeur. Une valeur chargée l''emporte toujours sur une valeur calculée.';
