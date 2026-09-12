-- 67e — `fn_check_address` échouait sur toute écriture dans `companies`
--
-- Le défaut, latent depuis la migration 56
-- -----------------------------------------
-- Le déclencheur résolvait la société ainsi :
--
--     v_company := case tg_table_name
--                    when 'companies' then new.id
--                    else new.company_id
--                  end;
--
-- PL/pgSQL compile cette expression comme un tout : `new.company_id` doit
-- exister, même sur la branche qui ne sera pas prise. Or `companies` n'a pas de
-- colonne `company_id`. Résultat :
--
--     ERROR: record "new" has no field "company_id"
--
-- **Toute mise à jour de l'adresse d'une société échouait donc depuis la
-- migration 56.** Personne ne s'en était aperçu parce qu'aucun test ni aucun
-- écran ne modifie l'adresse d'une société — le jeu de démonstration la pose une
-- fois et n'y touche plus. C'est la conversion des codes pays en alpha-3 qui a
-- réveillé le cas, en écrivant dans `companies.country`.
--
-- La correction passe par `to_jsonb(new)`, qui lit un champ absent sans échouer
-- au lieu de le réclamer à la compilation.

create or replace function fn_check_address()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_verdict jsonb;
  v_company uuid;
  v_ligne   jsonb := to_jsonb(new);
begin
  if new.postal_code is null and new.country is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and new.country     is not distinct from old.country
     and new.postal_code is not distinct from old.postal_code
     and new.city        is not distinct from old.city then
    return new;
  end if;

  v_verdict := fn_validate_address(new.country, new.postal_code, new.city);

  if v_verdict ->> 'status' = 'outside' then
    raise exception '%', v_verdict ->> 'message'
      using hint = 'LuxRH restreint les adresses au Luxembourg et aux zones frontalières '
                   'déclarées. Ajoutez la zone dans address_zones si le périmètre doit s''étendre.';
  end if;

  -- `to_jsonb` lit un champ absent en renvoyant NULL, là où `new.company_id`
  -- exigeait que la colonne existe sur toutes les tables portant ce déclencheur.
  v_company := case tg_table_name
                 when 'companies' then (v_ligne ->> 'id')::uuid
                 else nullif(v_ligne ->> 'company_id', '')::uuid
               end;

  insert into address_checks (entity_table, entity_id, company_id, country,
                              postal_code, status, zone_code, message)
  values (tg_table_name, new.id, v_company, new.country, new.postal_code,
          v_verdict ->> 'status', v_verdict ->> 'zone', v_verdict ->> 'message')
  on conflict (entity_table, entity_id) do update
    set company_id = excluded.company_id, country = excluded.country,
        postal_code = excluded.postal_code, status = excluded.status,
        zone_code = excluded.zone_code, message = excluded.message,
        checked_at = now();

  return new;
end $$;

revoke execute on function fn_check_address() from public, anon, authenticated;

comment on function fn_check_address() is
  'Valide la zone d''une adresse à l''écriture et consigne le verdict. Lit company_id par to_jsonb, pour que le même déclencheur serve des tables qui n''ont pas toutes cette colonne.';
