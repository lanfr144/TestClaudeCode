
-- =========================================================================
--  Paramètres dérivés et profondeur historique du référentiel
-- =========================================================================

-- Certaines valeurs ne sont pas saisies mais déduites d'une autre : le maximum
-- cotisable vaut cinq fois le salaire social minimum. Le déduire évite qu'une
-- indexation laisse les deux valeurs désynchronisées.
alter table legal_parameters
  add column if not exists derived_from_key text,
  add column if not exists derived_factor numeric;

alter table legal_parameters drop constraint if exists one_value;
alter table legal_parameters add constraint one_value check (
  (derived_from_key is not null and num_nonnulls(value_num, value_text, value_json) = 0)
  or (derived_from_key is null and num_nonnulls(value_num, value_text, value_json) = 1)
);

comment on column legal_parameters.derived_from_key is
  'Clé du paramètre source. La valeur est alors calculée : source × derived_factor.';

-- Résolution récursive : un paramètre dérivé lit sa source à la même date.
create or replace function fn_param_num(p_key text, p_on date default current_date)
returns numeric language plpgsql stable set search_path = public as $$
declare lp legal_parameters;
begin
  select * into lp from legal_parameters
  where param_key = p_key and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;

  if not found then return null; end if;
  if lp.derived_from_key is not null then
    return fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1);
  end if;
  return lp.value_num;
end $$;

-- fn_param renvoie la ligne avec sa valeur résolue, pour que l'interface affiche
-- le montant effectif tout en sachant qu'il est dérivé.
create or replace function fn_param(p_key text, p_on date default current_date)
returns legal_parameters language plpgsql stable set search_path = public as $$
declare lp legal_parameters;
begin
  select * into lp from legal_parameters
  where param_key = p_key and valid_from <= p_on and (valid_to is null or valid_to > p_on)
  limit 1;

  if found and lp.derived_from_key is not null then
    lp.value_num := fn_param_num(lp.derived_from_key, p_on) * coalesce(lp.derived_factor, 1);
  end if;
  return lp;
end $$;

-- Le maximum cotisable devient dérivé du SSM non qualifié.
update legal_parameters
   set value_num = null, derived_from_key = 'ssm_monthly_unqualified', derived_factor = 5,
       note = 'Cinq fois le salaire social minimum non qualifié — recalculé à chaque indexation.'
 where param_key = 'ccss_max_monthly';

-- Les cotisations et plafonds relèvent de la famille CCSS, distincte des
-- paramètres sociaux de portée générale.
update legal_parameters set family = 'ccss'
 where param_key like 'ccss\_%' or param_key = 'mutuality_class_rates';

-- =========================================================================
--  Profondeur historique : le référentiel doit remonter au dernier changement
--  antérieur au 31.12.2019. Aucune valeur n'est inventée : on expose
--  précisément ce qui manque pour que la saisie soit dirigée.
-- =========================================================================
create or replace function fn_referential_gaps(p_since date default date '2019-12-31')
returns table (
  family param_family,
  param_key text,
  label text,
  earliest_covered date,
  latest_covered date,
  versions int,
  covers_since boolean,
  gap_days int
) language sql stable set search_path = public as $$
  select lp.family,
         lp.param_key,
         min(lp.label),
         min(lp.valid_from),
         max(coalesce(lp.valid_to, date '9999-12-31')),
         count(*)::int,
         min(lp.valid_from) <= p_since,
         greatest(0, (min(lp.valid_from) - p_since))::int
  from legal_parameters lp
  group by lp.family, lp.param_key
  order by (min(lp.valid_from) <= p_since), lp.family, lp.param_key;
$$;

-- Trous internes : deux versions successives qui ne se touchent pas laisseraient
-- un calcul daté sans paramètre applicable.
create or replace function fn_referential_holes()
returns table (param_key text, gap_from date, gap_to date)
language sql stable set search_path = public as $$
  select param_key, valid_to as gap_from, next_from as gap_to
  from (
    select param_key, valid_to,
           lead(valid_from) over (partition by param_key order by valid_from) as next_from
    from legal_parameters
  ) t
  where valid_to is not null and next_from is not null and next_from > valid_to
  order by param_key, valid_to;
$$;

-- Saisie d'une nouvelle version datée, sans toucher au code (US6).
-- Clôture automatiquement la version précédente à la date d'effet.
create or replace function fn_add_parameter_version(
  p_key text, p_valid_from date, p_value_num numeric default null,
  p_value_text text default null, p_value_json jsonb default null,
  p_source text default 'CCSS', p_index_ref numeric default null, p_note text default null)
returns legal_parameters language plpgsql volatile security definer set search_path = public as $$
declare prev legal_parameters; created legal_parameters;
begin
  if not is_org_admin() then
    raise exception 'La saisie du référentiel est réservée à l''administrateur de l''espace';
  end if;

  select * into prev from legal_parameters
  where param_key = p_key and valid_from <= p_valid_from
    and (valid_to is null or valid_to > p_valid_from)
  limit 1;

  if prev.id is null then
    raise exception 'Paramètre % inconnu : créez-le d''abord avec sa famille et sa base légale', p_key;
  end if;
  if prev.valid_from = p_valid_from then
    raise exception 'Une version de % existe déjà au %', p_key, p_valid_from;
  end if;

  update legal_parameters set valid_to = p_valid_from where id = prev.id;

  insert into legal_parameters(
    family, param_key, label, value_num, value_text, value_json, unit,
    valid_from, valid_to, index_ref, source, legal_ref, note, entered_by)
  values (
    prev.family, p_key, prev.label, p_value_num, p_value_text, p_value_json, prev.unit,
    p_valid_from, prev.valid_to, coalesce(p_index_ref, prev.index_ref), p_source, prev.legal_ref,
    p_note, auth.uid())
  returning * into created;

  return created;
end $$;

-- Double lecture avant activation : un second administrateur valide la saisie.
create or replace function fn_validate_parameter_version(p_id uuid)
returns legal_parameters language plpgsql volatile security definer set search_path = public as $$
declare row_out legal_parameters;
begin
  if not is_org_admin() then raise exception 'Réservé à l''administrateur de l''espace'; end if;
  select * into row_out from legal_parameters where id = p_id;
  if row_out.entered_by = auth.uid() then
    raise exception 'La double lecture doit être faite par une autre personne que celle qui a saisi';
  end if;
  update legal_parameters set validated_by = auth.uid(), validated_at = now()
   where id = p_id returning * into row_out;
  return row_out;
end $$;

revoke execute on function fn_add_parameter_version(text, date, numeric, text, jsonb, text, numeric, text) from anon, public;
revoke execute on function fn_validate_parameter_version(uuid) from anon, public;
revoke execute on function fn_referential_gaps(date) from anon, public;
revoke execute on function fn_referential_holes() from anon, public;
grant execute on function fn_add_parameter_version(text, date, numeric, text, jsonb, text, numeric, text) to authenticated;
grant execute on function fn_validate_parameter_version(uuid) to authenticated;
grant execute on function fn_referential_gaps(date) to authenticated;
grant execute on function fn_referential_holes() to authenticated;
