-- 67f — Tous les codes pays passent en ISO 3166-1 alpha-3
--
-- Reprise de la migration 67d, qui avait échoué en réveillant le défaut de
-- `fn_check_address` corrigé par la 67e. Le contenu est inchangé.
--
-- Découvert en posant les adresses : `address_checks.country` était en `char(2)`
-- et refusait « LUX ». Contourner en écrivant « LU » aurait fait cohabiter deux
-- conventions dans la même base — exactement ce que la règle veut éviter.

alter table address_checks alter column country type char(3);
alter table address_zones  alter column country type char(3);

update address_zones z set country = p.alpha3
  from ref_pays p where btrim(z.country) = p.alpha2;
update address_checks c set country = p.alpha3
  from ref_pays p where btrim(c.country) = p.alpha2;
update employees e set country = p.alpha3
  from ref_pays p where upper(btrim(e.country)) = p.alpha2;
update companies c set country = p.alpha3
  from ref_pays p where upper(btrim(c.country)) = p.alpha2;
update client_sites s set country = p.alpha3
  from ref_pays p where upper(btrim(s.country)) = p.alpha2;

do $$
declare v_restants text;
begin
  select string_agg(distinct pays_inconnu, ', ') into v_restants
  from (
    select country as pays_inconnu from address_zones where length(btrim(country)) <> 3
    union select country from address_checks where length(btrim(country)) <> 3
    union select country from employees    where length(btrim(country)) <> 3
    union select country from companies    where length(btrim(country)) <> 3
    union select country from client_sites where length(btrim(country)) <> 3
  ) t where pays_inconnu is not null;
  if v_restants is not null then
    raise warning 'Codes pays non traduits, à reprendre à la main : %. '
                  'Ajoutez-les à ref_pays puis relancez la conversion.', v_restants;
  end if;
end $$;

create or replace function fn_validate_address(
  p_country text, p_postal text, p_city text default null
) returns jsonb language plpgsql stable set search_path = public as $$
declare
  v_alpha3 char(3) := fn_normaliser_pays(p_country);
  v_num    integer := fn_postal_number(p_country, p_postal);
  z        address_zones%rowtype;
  v_zones  int;
begin
  if v_alpha3 is null then
    return jsonb_build_object('status', 'unknown',
      'country', upper(btrim(coalesce(p_country, ''))),
      'message', format('Le pays « %s » n''est pas couvert. LuxRH ne vérifie que le Luxembourg '
                        'et les zones frontalières déclarées.', coalesce(p_country, '(absent)')));
  end if;

  select count(*) into v_zones from address_zones where btrim(country) = v_alpha3;
  if v_zones = 0 then
    return jsonb_build_object('status', 'unknown', 'country', v_alpha3,
      'message', format('Aucune zone déclarée pour %s.', v_alpha3));
  end if;

  if v_num is null then
    return jsonb_build_object('status', 'unknown', 'country', v_alpha3,
      'message', 'Code postal absent ou illisible : la zone ne peut pas être déterminée.');
  end if;

  select * into z from address_zones
   where btrim(country) = v_alpha3 and is_verified
     and v_num between postal_from and postal_to
   limit 1;

  if z.id is not null then
    return jsonb_build_object('status', 'ok', 'country', v_alpha3, 'postal', v_num,
      'zone', z.code, 'zone_label', z.label, 'source', z.source);
  end if;

  if exists (select 1 from address_zones where btrim(country) = v_alpha3 and is_verified) then
    return jsonb_build_object('status', 'outside', 'country', v_alpha3, 'postal', v_num,
      'allowed', (select jsonb_agg(jsonb_build_object('zone', code, 'label', label,
                                                      'from', postal_from, 'to', postal_to)
                                   order by postal_from)
                    from address_zones where btrim(country) = v_alpha3 and is_verified),
      'message', format('Le code postal %s est hors des zones couvertes pour %s.', v_num, v_alpha3));
  end if;

  return jsonb_build_object('status', 'unknown', 'country', v_alpha3, 'postal', v_num,
    'message', format('Les zones déclarées pour %s n''ont pas de correspondance postale chargée : '
                      'l''adresse ne peut être ni confirmée ni écartée ici.', v_alpha3));
end $$;

revoke execute on function fn_validate_address(text, text, text) from public, anon;
grant  execute on function fn_validate_address(text, text, text) to authenticated;

comment on function fn_postal_number(text, text) is
  'Code postal réduit à son nombre, préfixe postal et séparateurs retirés. « L-1424 » donne 1424. Le préfixe d''une lettre est une convention postale, distincte du code pays ISO qui, lui, est sur trois lettres.';
comment on column address_zones.country is $c$Code pays ISO 3166-1 alpha-3. Trois lettres partout dans l'application.$c$;
comment on column address_checks.country is $c$Code pays ISO 3166-1 alpha-3.$c$;
comment on column employees.country is $c$Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU.$c$;
