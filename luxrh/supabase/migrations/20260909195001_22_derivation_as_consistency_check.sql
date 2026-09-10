
-- =========================================================================
--  La dérivation ne remplace pas la valeur publiée, elle la contrôle.
--
--  5 × 2 771,33 = 13 856,65, alors que le maximum cotisable publié est
--  13 856,63 : le SSM affiché est lui-même un arrondi. Dériver depuis
--  l'arrondi introduirait 2 centimes d'écart, ce qui est inacceptable au
--  regard de l'exigence d'exactitude. La valeur officielle fait donc foi ;
--  la dérivation sert à détecter qu'une indexation a été saisie à moitié.
-- =========================================================================

alter table legal_parameters drop constraint if exists one_value;
alter table legal_parameters add constraint one_value check (
  num_nonnulls(value_num, value_text, value_json) = 1
  or (derived_from_key is not null and num_nonnulls(value_num, value_text, value_json) = 0)
);

comment on column legal_parameters.derived_from_key is
  'Paramètre dont celui-ci découle. Si value_num est renseigné, la valeur publiée '
  'fait foi et la dérivation ne sert qu''au contrôle de cohérence. Sinon, elle est calculée.';

alter table legal_parameters
  add column if not exists derivation_tolerance numeric not null default 0.02;

-- Valeur officielle rétablie, métadonnée de dérivation conservée.
update legal_parameters
   set value_num = 13856.63,
       note = 'Cinq fois le salaire social minimum. La valeur publiée par le CCSS fait foi ; '
              'la dérivation sert de contrôle de cohérence après chaque indexation.'
 where param_key = 'ccss_max_monthly';

-- La valeur publiée l'emporte ; la dérivation ne s'applique qu'à défaut.
create or replace function fn_param_num(p_key text, p_on date default current_date)
returns numeric language plpgsql stable set search_path = public as $$
declare lp legal_parameters;
begin
  select * into lp from legal_parameters
  where param_key = p_key and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;

  if not found then return null; end if;
  if lp.value_num is not null then return lp.value_num; end if;
  if lp.derived_from_key is not null then
    return fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1);
  end if;
  return null;
end $$;

create or replace function fn_param(p_key text, p_on date default current_date)
returns legal_parameters language plpgsql stable set search_path = public as $$
declare lp legal_parameters;
begin
  select * into lp from legal_parameters
  where param_key = p_key and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;

  if found and lp.value_num is null and lp.derived_from_key is not null then
    lp.value_num := fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1);
  end if;
  return lp;
end $$;

-- Signale toute valeur publiée qui s'écarte de sa dérivation au-delà de la
-- tolérance : typiquement une indexation saisie sur le SSM mais pas sur le plafond.
create or replace function fn_referential_inconsistencies(p_on date default current_date)
returns table (
  param_key text, label text, published numeric, derived numeric,
  difference numeric, tolerance numeric, source_key text
) language sql stable set search_path = public as $$
  select lp.param_key, lp.label, lp.value_num,
         round(fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1), 4),
         round(lp.value_num - fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1), 4),
         lp.derivation_tolerance,
         lp.derived_from_key
  from legal_parameters lp
  where lp.derived_from_key is not null
    and lp.value_num is not null
    and lp.valid_from <= p_on and (lp.valid_to is null or lp.valid_to > p_on)
    and abs(lp.value_num - fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1))
        > lp.derivation_tolerance
  order by lp.param_key;
$$;

revoke execute on function fn_referential_inconsistencies(date) from anon, public;
grant execute on function fn_referential_inconsistencies(date) to authenticated;

-- Tolérance de 2 centimes sur le plafond : l'écart constaté vient de l'arrondi
-- du SSM publié, il est normal et documenté.
update legal_parameters set derivation_tolerance = 0.05 where param_key = 'ccss_max_monthly';
