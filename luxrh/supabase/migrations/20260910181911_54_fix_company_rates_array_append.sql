-- 54 — Correction de fn_company_rates : concaténation de tableau mal typée
--
-- La migration 50 écrivait `manques := manques || 'accident_class_rates';`.
-- Le littéral n'ayant pas de type déclaré, PostgreSQL résout la surcharge
-- `anyarray || anyarray` plutôt que `anyarray || anyelement`, et tente de lire la
-- chaîne comme un littéral de tableau :
--
--   {"code":"22P02","message":"malformed array literal: \"accident_class_rates\""}
--
-- Attrapé par la suite de tests à l'application de la migration 50 — la seule
-- vérification qui échouait après le retrait des clés redondantes.
--
-- `array_append` lève l'ambiguïté sans dépendre de la résolution de surcharge, et
-- `cardinality(...) = 0` remplace la comparaison au tableau vide, plus lisible.
-- Le comportement métier est inchangé : c'est la même fonction, qui compile.

create or replace function fn_company_rates(p_company uuid, p_on date default current_date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  rp            company_rate_periods%rowtype;
  mut_rates     jsonb;
  mut_rate      numeric;
  class_rates   jsonb;
  accident_rate numeric;
  accident_base numeric;
  source_taux   text;
  manques       text[] := '{}';
begin
  if not has_company_access(p_company) then
    raise exception 'Accès refusé à cette société.';
  end if;

  select * into rp
  from company_rate_periods
  where company_id = p_company
    and valid_from <= p_on
    and (valid_to is null or valid_to > p_on)
  order by valid_from desc
  limit 1;

  if rp.id is null then
    return jsonb_build_object(
      'found', false,
      'evaluated_on', p_on,
      'message', 'Aucun taux n''est enregistré pour cette société à cette date. '
                 'Renseignez la classe de mutualité et le facteur accident avant tout calcul.');
  end if;

  mut_rates := (fn_param('mutuality_class_rates', p_on)).value_json;
  if mut_rates is null then
    manques := array_append(manques, 'mutuality_class_rates');
  else
    select (e->>'rate')::numeric into mut_rate
    from jsonb_array_elements(mut_rates) e
    where (e->>'class')::int = rp.mutuality_class;
    if mut_rate is null then
      manques := array_append(manques, format('mutuality_class_rates[classe %s]', rp.mutuality_class));
    end if;
  end if;

  accident_base := fn_param_num('ccss_accident_base_employer', p_on);
  if accident_base is null then
    manques := array_append(manques, 'ccss_accident_base_employer');
  end if;

  class_rates := (fn_param('accident_class_rates', p_on)).value_json;
  if class_rates is null then
    manques     := array_append(manques, 'accident_class_rates');
    source_taux := 'base';
  elsif rp.accident_risk_class is null then
    source_taux := 'base';
  else
    select (e->>'rate')::numeric into accident_rate
    from jsonb_array_elements(class_rates) e
    where e->>'class' = rp.accident_risk_class;
    if accident_rate is null then
      manques     := array_append(manques, format('accident_class_rates[classe %s]', rp.accident_risk_class));
      source_taux := 'base';
    else
      source_taux := 'classe';
    end if;
  end if;

  accident_rate := coalesce(accident_rate, accident_base);
  if accident_rate is not null then
    accident_rate := accident_rate * rp.accident_factor;
  end if;

  return jsonb_build_object(
    'found', true,
    'evaluated_on', p_on,
    'period_from', rp.valid_from,
    'period_to', rp.valid_to,
    'activity_class', rp.activity_class,
    'accident_risk_class', rp.accident_risk_class,
    'accident_factor', rp.accident_factor,
    'mutuality_class', rp.mutuality_class,
    'mutuality_rate', mut_rate,
    'accident_rate', accident_rate,
    -- Ce que l'ancienne version taisait :
    'accident_rate_source', source_taux,
    'complete', (cardinality(manques) = 0) and accident_rate is not null and mut_rate is not null,
    'missing_parameters', to_jsonb(manques),
    'message', case
      when cardinality(manques) = 0 then null
      when source_taux = 'base' then
        'Le taux de la classe de risque accident n''est pas disponible : le taux de base '
        'a été utilisé à sa place. Ce résultat ne doit pas servir de base à une déclaration. '
        'Paramètres manquants : ' || array_to_string(manques, ', ') || '.'
      else 'Paramètres manquants : ' || array_to_string(manques, ', ') || '.'
    end);
end $$;

revoke execute on function fn_company_rates(uuid, date) from anon, public;
grant  execute on function fn_company_rates(uuid, date) to authenticated;
