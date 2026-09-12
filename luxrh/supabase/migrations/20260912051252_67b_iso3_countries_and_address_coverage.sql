-- 67b — Codes pays ISO-3 partout, et couverture continue des adresses
--
-- Deux chantiers qui se rejoignent : les adresses du salarié naissent en
-- alpha-3, alors que `address_zones` et `employees.country` portent encore de
-- l'alpha-2. Plutôt que de faire cohabiter deux conventions en silence, on
-- normalise à l'entrée et on accepte les deux le temps que les fronts suivent.

create table if not exists ref_pays (
  alpha3         char(3) primary key,
  alpha2         char(2) not null,
  nom            text not null,
  frontalier     boolean not null default false,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  constraint rp_periode check (fin_validite > debut_validite),
  constraint rp_alpha2_unique unique (alpha2)
);

comment on table ref_pays is $c$Correspondance ISO 3166-1 alpha-3 / alpha-2. L'application stocke l'alpha-3 ; l'alpha-2 sert à lire l'existant et les sources externes le temps de la transition.$c$;

insert into ref_pays (alpha3, alpha2, nom, frontalier) values
  ('LUX', 'LU', 'Luxembourg', false),
  ('FRA', 'FR', 'France', true),
  ('BEL', 'BE', 'Belgique', true),
  ('DEU', 'DE', 'Allemagne', true)
on conflict (alpha3) do update set alpha2 = excluded.alpha2, nom = excluded.nom,
                                   frontalier = excluded.frontalier;

alter table ref_pays enable row level security;
drop policy if exists ref_pays_lecture on ref_pays;
create policy ref_pays_lecture on ref_pays for select to authenticated using (true);

create or replace function fn_normaliser_pays(p_pays text)
returns char(3) language sql stable set search_path = public as $$
  select coalesce(
    (select alpha3 from ref_pays where alpha3 = upper(btrim(coalesce(p_pays, '')))),
    (select alpha3 from ref_pays where alpha2 = upper(btrim(coalesce(p_pays, '')))));
$$;

comment on function fn_normaliser_pays(text) is
  'Ramène un code pays à son alpha-3, qu''il arrive en deux ou trois lettres. Renvoie NULL pour un pays inconnu — jamais une valeur inventée.';

revoke execute on function fn_normaliser_pays(text) from public, anon;
grant  execute on function fn_normaliser_pays(text) to authenticated;

-- `fn_validate_address` accepte désormais les deux conventions.
create or replace function fn_validate_address(
  p_country text, p_postal text, p_city text default null
) returns jsonb language plpgsql stable set search_path = public as $$
declare
  v_alpha3 char(3) := fn_normaliser_pays(p_country);
  v_alpha2 char(2);
  v_num    integer := fn_postal_number(p_country, p_postal);
  z        address_zones%rowtype;
  v_zones  int;
begin
  if v_alpha3 is null then
    return jsonb_build_object('status', 'unknown', 'country', upper(btrim(coalesce(p_country, ''))),
      'message', format('Le pays « %s » n''est pas couvert. LuxRH ne vérifie que le Luxembourg '
                        'et les zones frontalières déclarées.', coalesce(p_country, '(absent)')));
  end if;

  select alpha2 into v_alpha2 from ref_pays where alpha3 = v_alpha3;

  select count(*) into v_zones from address_zones where country = v_alpha2;
  if v_zones = 0 then
    return jsonb_build_object('status', 'unknown', 'country', v_alpha3,
      'message', format('Aucune zone déclarée pour %s.', v_alpha3));
  end if;

  if v_num is null then
    return jsonb_build_object('status', 'unknown', 'country', v_alpha3,
      'message', 'Code postal absent ou illisible : la zone ne peut pas être déterminée.');
  end if;

  select * into z from address_zones
   where country = v_alpha2 and is_verified and v_num between postal_from and postal_to
   limit 1;

  if z.id is not null then
    return jsonb_build_object('status', 'ok', 'country', v_alpha3, 'postal', v_num,
      'zone', z.code, 'zone_label', z.label, 'source', z.source);
  end if;

  if exists (select 1 from address_zones where country = v_alpha2 and is_verified) then
    return jsonb_build_object('status', 'outside', 'country', v_alpha3, 'postal', v_num,
      'allowed', (select jsonb_agg(jsonb_build_object('zone', code, 'label', label,
                                                      'from', postal_from, 'to', postal_to)
                                   order by postal_from)
                    from address_zones where country = v_alpha2 and is_verified),
      'message', format('Le code postal %s est hors des zones couvertes pour %s.', v_num, v_alpha3));
  end if;

  return jsonb_build_object('status', 'unknown', 'country', v_alpha3, 'postal', v_num,
    'message', format('Les zones déclarées pour %s n''ont pas de correspondance postale chargée : '
                      'l''adresse ne peut être ni confirmée ni écartée ici.', v_alpha3));
end $$;

revoke execute on function fn_validate_address(text, text, text) from public, anon;
grant  execute on function fn_validate_address(text, text, text) to authenticated;

-- ===========================================================================
-- La couverture : aucune période sans adresse, pour aucun des quatre types
-- ===========================================================================

create or replace function fn_verifier_couverture_adresses(
  p_employee uuid, p_depuis date default null
) returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_company uuid;
  v_depuis  date;
  t         record;
  v_trous   jsonb := '[]'::jsonb;
  v_curseur date;
  a         record;
begin
  select company_id into v_company from employees where id = p_employee;
  if v_company is null then raise exception 'Salarié introuvable : %', p_employee; end if;
  if not (has_company_access(v_company) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé aux adresses de ce salarié.';
  end if;

  -- À défaut de date fournie, on remonte au plus ancien contrat : c'est au plus
  -- tôt la candidature.
  v_depuis := coalesce(p_depuis,
    (select min(start_date) from contracts where employee_id = p_employee),
    current_date);

  for t in select code, libelle from ref_type_adresse order by ordre loop
    v_curseur := v_depuis;
    for a in
      select debut_validite, fin_validite
      from adresses_salarie
      where employee_id = p_employee and type_adresse = t.code and deleted_at is null
      order by debut_validite
    loop
      if a.debut_validite > v_curseur then
        v_trous := v_trous || jsonb_build_object(
          'type', t.code, 'libelle', t.libelle,
          'du', v_curseur, 'au', a.debut_validite - 1,
          'motif', 'aucune adresse enregistrée sur cette période');
      end if;
      v_curseur := greatest(v_curseur, a.fin_validite);
    end loop;

    if v_curseur < date '2037-12-31' then
      v_trous := v_trous || jsonb_build_object(
        'type', t.code, 'libelle', t.libelle,
        'du', v_curseur, 'au', date '2037-12-31',
        'motif', 'la couverture ne va pas jusqu''à la sentinelle : une erreur de salaire '
                 'découverte plus tard laisserait la personne injoignable');
    end if;
  end loop;

  return jsonb_build_object(
    'employee_id', p_employee, 'depuis', v_depuis,
    'trous', v_trous,
    'complet', jsonb_array_length(v_trous) = 0,
    'message', case when jsonb_array_length(v_trous) = 0
                    then 'Les quatre adresses couvrent toute la période, sans trou.'
                    else format('%s trou(s) de couverture.', jsonb_array_length(v_trous)) end);
end $$;

revoke execute on function fn_verifier_couverture_adresses(uuid, date) from public, anon;
grant  execute on function fn_verifier_couverture_adresses(uuid, date) to authenticated;

-- ===========================================================================
-- Poser les quatre adresses depuis le domicile légal
-- ===========================================================================

create or replace function fn_poser_adresses_depuis_domicile(
  p_employee uuid,
  p_depuis   date default null
) returns jsonb language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  e        employees%rowtype;
  v_depuis date;
  t        record;
  v_creees int := 0;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Salarié introuvable : %', p_employee; end if;
  if not (can_manage_company(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé.';
  end if;

  v_depuis := coalesce(p_depuis,
    (select min(start_date) from contracts where employee_id = p_employee),
    current_date);

  for t in select code from ref_type_adresse order by ordre loop
    if not exists (select 1 from adresses_salarie
                    where employee_id = p_employee and type_adresse = t.code
                      and deleted_at is null) then
      insert into adresses_salarie (company_id, employee_id, type_adresse, ligne,
                                    code_postal, localite, pays, debut_validite,
                                    fin_validite, origine, created_by)
      values (e.company_id, p_employee, t.code, e.address_line, e.postal_code, e.city,
              coalesce(fn_normaliser_pays(e.country), 'LUX'), v_depuis, date '2037-12-31',
              'copie_domicile', auth.uid());
      v_creees := v_creees + 1;
    end if;
  end loop;

  return jsonb_build_object('ok', true, 'employee_id', p_employee,
    'adresses_creees', v_creees, 'depuis', v_depuis,
    'couverture', fn_verifier_couverture_adresses(p_employee, v_depuis),
    'message', format('%s adresse(s) posée(s) par recopie du domicile légal. '
                      'À préciser ensuite pour celles qui diffèrent.', v_creees));
end $$;

revoke execute on function fn_poser_adresses_depuis_domicile(uuid, date) from public, anon;
grant  execute on function fn_poser_adresses_depuis_domicile(uuid, date) to authenticated;

-- ===========================================================================
-- Déménager : clore la veille, insérer la nouvelle
-- ===========================================================================
-- L'historisation stricte, appliquée. C'est elle qui permet de recalculer une
-- prime de trajet sur la première quinzaine du mois, avant le déménagement.

create or replace function fn_changer_adresse(
  p_employee    uuid,
  p_type        text,
  p_effet       date,
  p_ligne       text,
  p_code_postal text,
  p_localite    text,
  p_pays        text default 'LUX'
) returns jsonb language plpgsql volatile security definer set search_path = public, extensions as $$
declare
  e         employees%rowtype;
  v_ancien  adresses_salarie%rowtype;
  v_nouveau uuid;
begin
  select * into e from employees where id = p_employee;
  if e.id is null then raise exception 'Salarié introuvable : %', p_employee; end if;
  if not (can_manage_company(e.company_id) or is_self_employee(p_employee)) then
    raise exception 'Accès refusé.';
  end if;
  if not exists (select 1 from ref_type_adresse where code = p_type) then
    raise exception 'Type d''adresse inconnu : %', p_type;
  end if;

  select * into v_ancien from adresses_salarie
   where employee_id = p_employee and type_adresse = p_type and deleted_at is null
     and debut_validite <= p_effet and fin_validite > p_effet;

  if v_ancien.id is not null then
    if v_ancien.debut_validite = p_effet then
      raise exception 'Une adresse de ce type commence déjà le % : corrigez-la plutôt que '
                      'd''en ouvrir une seconde le même jour.', p_effet;
    end if;
    -- On clôt la veille : la période précédente reste exacte pour tout recalcul.
    update adresses_salarie set fin_validite = p_effet where id = v_ancien.id;
  end if;

  insert into adresses_salarie (company_id, employee_id, type_adresse, ligne, code_postal,
                                localite, pays, debut_validite, fin_validite, origine, created_by)
  values (e.company_id, p_employee, p_type, p_ligne, p_code_postal, p_localite,
          coalesce(fn_normaliser_pays(p_pays), 'LUX'), p_effet, date '2037-12-31',
          'saisie', auth.uid())
  returning id into v_nouveau;

  return jsonb_build_object('ok', true, 'type', p_type, 'effet', p_effet,
    'ancienne_close_au', case when v_ancien.id is not null then p_effet - 1 end,
    'nouvelle', v_nouveau,
    'couverture', fn_verifier_couverture_adresses(p_employee),
    'message', 'Adresse changée. L''ancienne période reste intacte pour les recalculs '
               'rétroactifs — une prime de trajet d''avant le déménagement reste juste.');
end $$;

revoke execute on function fn_changer_adresse(uuid, text, date, text, text, text, text) from public, anon;
grant  execute on function fn_changer_adresse(uuid, text, date, text, text, text, text) to authenticated;
