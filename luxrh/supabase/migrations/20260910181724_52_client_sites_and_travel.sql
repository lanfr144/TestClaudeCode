-- 52 — Lieux d'intervention, distances et indemnisation des dépassements
--
-- Ce que cette migration rend possible
-- ------------------------------------
-- Une vacation ne s'exécute pas toujours au siège. Quand elle a lieu chez un
-- client, le trajet du salarié s'allonge, et ce dépassement lui est dû. Il faut
-- donc trois choses que le modèle n'avait pas : l'adresse du lieu d'intervention,
-- la distance entre deux adresses, et la règle qui transforme un dépassement de
-- kilomètres en montant.
--
-- Ce que cette migration NE fait PAS
-- -----------------------------------
-- Elle n'inscrit aucun tarif kilométrique. Le taux est un paramètre — légal,
-- conventionnel ou contractuel selon le cas — et il vit dans `legal_parameters`.
-- Tant qu'aucune source publique ne l'établit, la clé reste déclarée et vide, et
-- `fn_referential_gaps` la signale. Un montant plausible mais faux se recopierait
-- dans une fiche de paie : c'est exactement ce que la règle 7 du CLAUDE.md
-- interdit.
--
-- AVERTISSEMENT — PROTECTION DES DONNÉES
-- ---------------------------------------
-- Calculer une distance depuis le domicile d'un salarié suppose de transmettre
-- son adresse à un service tiers. C'est un traitement de donnée personnelle par
-- un sous-traitant, qui appelle : une base légale, une mention dans le registre
-- des traitements, un contrat de sous-traitance avec le fournisseur, et
-- l'information du salarié.
--
-- Le modèle retenu ici en limite la portée :
--   · la distance est CALCULÉE UNE FOIS puis mise en cache — une adresse n'est
--     transmise qu'au premier calcul du couple, pas à chaque planning ;
--   · le cache conserve la distance, pas la trajectoire ;
--   · chaque calcul laisse une trace dans data_access_log, action DOWNLOAD,
--     de sorte qu'on puisse dire quelles adresses ont été transmises et quand ;
--   · aucune adresse n'est envoyée depuis le navigateur : l'appel part d'une
--     Edge Function, la clé d'API ne quitte jamais le serveur.
--
-- Ce que cela ne règle pas : la décision d'utiliser un fournisseur donné, et son
-- encadrement contractuel. Voir `docs/securite-et-conformite.md`.

-- ===========================================================================
-- 1. Les lieux d'intervention
-- ===========================================================================

create table if not exists client_sites (
  id           uuid primary key default extensions.gen_random_uuid(),
  company_id   uuid not null references companies(id) on delete cascade,
  name         text not null,
  client_name  text,
  address_line text,
  postal_code  text,
  city         text,
  country      text not null default 'LU',
  latitude     numeric(9,6),
  longitude    numeric(9,6),
  is_active    boolean not null default true,
  note         text,
  created_at   timestamptz not null default now(),
  constraint client_site_has_an_address
    check (address_line is not null or (postal_code is not null and city is not null)
           or (latitude is not null and longitude is not null))
);

comment on table client_sites is $c$Lieu où une vacation peut s'exécuter hors du siège : chantier, site client, antenne. Porte l'adresse qui sert au calcul de distance.$c$;
comment on column client_sites.client_name is $c$Nom du client donneur d'ordre, distinct du nom du site.$c$;
comment on column client_sites.latitude is $c$Coordonnée, si elle est connue : elle évite de transmettre une adresse en clair au service de distance.$c$;
comment on constraint client_site_has_an_address on client_sites is
  'Un site sans adresse ni coordonnées ne permet aucun calcul : autant le refuser à la saisie.';

create index if not exists idx_client_sites_company on client_sites (company_id, is_active);
create unique index if not exists idx_client_sites_id_company on client_sites (id, company_id);

alter table client_sites enable row level security;

create policy client_sites_read on client_sites
  for select to authenticated using (has_company_access(company_id));
create policy client_sites_write on client_sites
  for insert to authenticated with check (can_manage_company(company_id));
create policy client_sites_update on client_sites
  for update to authenticated using (can_manage_company(company_id))
  with check (can_manage_company(company_id));
create policy client_sites_delete on client_sites
  for delete to authenticated using (can_manage_company(company_id));

-- Une vacation peut désigner son lieu. Nul = au siège.
alter table shifts add column if not exists client_site_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'shift_site_belongs_to_company') then
    -- `set null (client_site_id)` et non `set null` tout court : sans la liste de
    -- colonnes, la suppression d'un site tenterait de vider aussi company_id, qui
    -- est obligatoire. La liste de colonnes exige PostgreSQL 15 ou plus.
    alter table shifts
      add constraint shift_site_belongs_to_company
      foreign key (client_site_id, company_id) references client_sites (id, company_id)
      on update cascade on delete set null (client_site_id);
  end if;
end $$;

comment on column shifts.client_site_id is $c$Lieu d'exécution de la vacation. Nul signifie « au siège de la société » — c'est le cas courant, et c'est aussi la référence à laquelle un dépassement se mesure.$c$;

-- ===========================================================================
-- 2. Le cache des distances
-- ===========================================================================
-- Une distance entre deux points ne change pas d'un planning à l'autre. La
-- calculer une fois, la conserver, et savoir d'où elle vient.

create table if not exists travel_distances (
  id               uuid primary key default extensions.gen_random_uuid(),
  origin_ref       text not null,
  destination_ref  text not null,
  distance_km      numeric(8,2) not null,
  duration_minutes integer,
  source           text not null,
  computed_at      timestamptz not null default now(),
  computed_by      uuid,
  note             text,
  constraint travel_distance_positive check (distance_km >= 0),
  constraint travel_distance_refs_differ check (origin_ref <> destination_ref),
  constraint travel_distance_unique unique (origin_ref, destination_ref)
);

comment on table travel_distances is $c$Distances routières mises en cache. Une adresse n'est transmise au service tiers qu'au premier calcul d'un couple ; les plannings suivants lisent cette table.$c$;
comment on column travel_distances.origin_ref is $c$Référence de l'origine, sous la forme « employee:<uuid> », « company:<uuid> » ou « site:<uuid> ». Aucune adresse n'est recopiée ici.$c$;
comment on column travel_distances.source is $c$Origine de la mesure : nom du service consulté, ou « manuel » si la distance a été saisie. Une distance sans source ne doit pas servir à payer.$c$;
comment on column travel_distances.computed_at is $c$Date du calcul. Une adresse change ; une distance vieille de trois ans mérite d'être revérifiée.$c$;

alter table travel_distances enable row level security;

-- Le cache ne porte que des références et des kilomètres, mais ces références
-- désignent des personnes : il n'est lisible que par qui a accès à la société.
create policy travel_distances_read on travel_distances
  for select to authenticated
  using (
    exists (select 1 from employees e
            where 'employee:' || e.id = travel_distances.origin_ref
              and has_company_access(e.company_id))
    or exists (select 1 from companies c
               where 'company:' || c.id = travel_distances.destination_ref
                 and has_company_access(c.id))
    or exists (select 1 from client_sites s
               where 'site:' || s.id = travel_distances.destination_ref
                 and has_company_access(s.company_id))
  );

-- Écriture réservée au moteur et à l'Edge Function : aucune politique d'insertion
-- pour les comptes applicatifs.

-- ===========================================================================
-- 3. Résoudre une référence en adresse
-- ===========================================================================

create or replace function fn_address_of(p_ref text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_kind text := split_part(p_ref, ':', 1);
  v_id   uuid;
  v_out  jsonb;
begin
  begin
    v_id := split_part(p_ref, ':', 2)::uuid;
  exception when others then
    raise exception 'Référence mal formée : % (attendu « employee:<uuid> », « company:<uuid> » ou « site:<uuid> »)', p_ref;
  end;

  if v_kind = 'employee' then
    select jsonb_build_object('line', e.address_line, 'postal_code', e.postal_code,
                              'city', e.city, 'country', e.country,
                              'company_id', e.company_id)
      into v_out
    from employees e where e.id = v_id and has_company_access(e.company_id);
  elsif v_kind = 'company' then
    select jsonb_build_object('line', c.address_line, 'postal_code', c.postal_code,
                              'city', c.city, 'country', c.country,
                              'company_id', c.id)
      into v_out
    from companies c where c.id = v_id and has_company_access(c.id);
  elsif v_kind = 'site' then
    select jsonb_build_object('line', s.address_line, 'postal_code', s.postal_code,
                              'city', s.city, 'country', s.country,
                              'latitude', s.latitude, 'longitude', s.longitude,
                              'company_id', s.company_id)
      into v_out
    from client_sites s where s.id = v_id and has_company_access(s.company_id);
  else
    raise exception 'Type de référence inconnu : %', v_kind;
  end if;

  if v_out is null then
    raise exception 'Référence introuvable ou hors de votre périmètre : %', p_ref;
  end if;

  if v_out ->> 'line' is null and v_out ->> 'postal_code' is null
     and v_out ->> 'latitude' is null then
    return jsonb_build_object('found', false, 'ref', p_ref,
      'message', 'Aucune adresse n''est enregistrée pour ' || p_ref
                 || '. Renseignez-la avant tout calcul de distance.');
  end if;

  return v_out || jsonb_build_object('found', true, 'ref', p_ref);
end $$;

revoke execute on function fn_address_of(text) from public, anon;
grant  execute on function fn_address_of(text) to authenticated;

-- ===========================================================================
-- 4. Lire une distance
-- ===========================================================================

create or replace function fn_travel_distance(p_origin text, p_destination text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare d travel_distances%rowtype;
begin
  if p_origin = p_destination then
    return jsonb_build_object('found', true, 'distance_km', 0, 'source', 'identité');
  end if;

  select * into d from travel_distances
  where origin_ref = p_origin and destination_ref = p_destination;

  if d.id is null then
    -- Symétrie : un aller vaut un retour, à défaut de mieux.
    select * into d from travel_distances
    where origin_ref = p_destination and destination_ref = p_origin;
  end if;

  if d.id is null then
    return jsonb_build_object(
      'found', false, 'origin', p_origin, 'destination', p_destination,
      'message', 'Cette distance n''a pas encore été calculée. Lancez le calcul '
                 'depuis le planning : l''adresse sera transmise une seule fois, '
                 'puis conservée.');
  end if;

  return jsonb_build_object(
    'found', true, 'distance_km', d.distance_km,
    'duration_minutes', d.duration_minutes,
    'source', d.source, 'computed_at', d.computed_at);
end $$;

revoke execute on function fn_travel_distance(text, text) from public, anon;
grant  execute on function fn_travel_distance(text, text) to authenticated;

-- ===========================================================================
-- 5. Le dépassement, et ce qu'il vaut
-- ===========================================================================
-- Principe retenu : le trajet domicile → siège est celui que le salarié
-- effectuerait de toute façon. N'est indemnisé que ce qui l'excède, aller-retour.
-- Ce choix est une règle de gestion, pas une règle de droit : il est ici pour
-- être discuté, et il est nommé dans la réponse (`rule`).

create or replace function fn_shift_travel(p_shift uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  s              shifts%rowtype;
  v_employee_ref text;
  v_company_ref  text;
  v_site_ref     text;
  d_site         jsonb;
  d_base         jsonb;
  km_site        numeric;
  km_base        numeric;
  km_excess      numeric;
  taux           numeric;
  manques        text[] := '{}';
begin
  select * into s from shifts where id = p_shift;
  if s.id is null then
    raise exception 'Vacation introuvable : %', p_shift;
  end if;
  if not has_company_access(s.company_id) then
    raise exception 'Accès refusé à cette vacation.';
  end if;

  if s.client_site_id is null then
    return jsonb_build_object(
      'found', true, 'shift_id', p_shift, 'excess_km', 0, 'amount', 0,
      'rule', 'Vacation au siège : aucun dépassement.',
      'complete', true);
  end if;

  v_employee_ref := 'employee:' || s.employee_id;
  v_company_ref  := 'company:'  || s.company_id;
  v_site_ref     := 'site:'     || s.client_site_id;

  d_site := fn_travel_distance(v_employee_ref, v_site_ref);
  d_base := fn_travel_distance(v_employee_ref, v_company_ref);

  if not (d_site ->> 'found')::boolean then manques := manques || 'distance domicile → site'; end if;
  if not (d_base ->> 'found')::boolean then manques := manques || 'distance domicile → siège'; end if;

  taux := fn_param_num('mileage_allowance_eur_per_km', s.shift_date);
  if taux is null then manques := manques || 'paramètre mileage_allowance_eur_per_km'; end if;

  if manques <> '{}'::text[] then
    return jsonb_build_object(
      'found', false, 'shift_id', p_shift,
      'missing', to_jsonb(manques),
      'message', 'Le dépassement ne peut pas être calculé. Manque : '
                 || array_to_string(manques, ', ') || '. '
                 || 'Aucun montant n''est proposé tant qu''un élément manque : '
                 || 'un chiffre approximatif se recopierait dans une paie.');
  end if;

  km_site   := (d_site ->> 'distance_km')::numeric;
  km_base   := (d_base ->> 'distance_km')::numeric;
  km_excess := greatest(0, km_site - km_base) * 2;   -- aller-retour

  return jsonb_build_object(
    'found', true, 'complete', true,
    'shift_id', p_shift, 'shift_date', s.shift_date,
    'employee_id', s.employee_id, 'client_site_id', s.client_site_id,
    'km_home_to_site', km_site,
    'km_home_to_office', km_base,
    'excess_km', km_excess,
    'rate_eur_per_km', taux,
    'amount', round(km_excess * taux, 2),
    'rule', 'Seul l''excédent sur le trajet domicile → siège est indemnisé, aller-retour.',
    'distance_source', d_site ->> 'source',
    'distance_computed_at', d_site ->> 'computed_at');
end $$;

revoke execute on function fn_shift_travel(uuid) from public, anon;
grant  execute on function fn_shift_travel(uuid) to authenticated;

-- Synthèse d'un planning : ce que la semaine coûte en déplacements.
create or replace function fn_schedule_travel(p_schedule uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_company uuid;
  lignes    jsonb := '[]'::jsonb;
  r         record;
  detail    jsonb;
  total     numeric := 0;
  incomplet int := 0;
begin
  select company_id into v_company from schedules where id = p_schedule;
  if v_company is null then raise exception 'Planning introuvable : %', p_schedule; end if;
  if not has_company_access(v_company) then raise exception 'Accès refusé à ce planning.'; end if;

  for r in select id from shifts where schedule_id = p_schedule and client_site_id is not null
  loop
    detail := fn_shift_travel(r.id);
    lignes := lignes || detail;
    if (detail ->> 'found')::boolean then
      total := total + coalesce((detail ->> 'amount')::numeric, 0);
    else
      incomplet := incomplet + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'schedule_id', p_schedule,
    'lines', lignes,
    'total_amount', total,
    'incomplete_count', incomplet,
    'complete', incomplet = 0,
    'message', case when incomplet > 0
      then incomplet || ' vacation(s) ne peuvent pas être chiffrées : distance ou '
           'paramètre manquant. Le total ci-dessus est donc partiel.'
      else null end);
end $$;

revoke execute on function fn_schedule_travel(uuid) from public, anon;
grant  execute on function fn_schedule_travel(uuid) to authenticated;

-- ===========================================================================
-- 6. La clé attendue, déclarée et vide
-- ===========================================================================
-- Conformément à la règle 7 : la clé existe dans la liste des attendues, aucune
-- valeur n'est inventée, et fn_referential_gaps la fait remonter en tête.

insert into expected_parameters (param_key, read_by, note) values
  ('mileage_allowance_eur_per_km', 'fn_shift_travel',
   'Tarif d''indemnisation kilométrique. Peut être légal, conventionnel ou contractuel selon le cas : à charger avec sa source et sa plage de validité avant tout paiement de dépassement.')
on conflict (param_key) do update
  set read_by = excluded.read_by, note = excluded.note;

-- ===========================================================================
-- 7. Écrire une distance
-- ===========================================================================
-- Appelée par l'Edge Function `travel-distance` après consultation du service
-- externe, ou par un gestionnaire qui saisit une distance à la main.

create or replace function fn_set_travel_distance(
  p_origin      text,
  p_destination text,
  p_km          numeric,
  p_minutes     integer,
  p_source      text,
  p_note        text default null
) returns jsonb language plpgsql volatile security definer set search_path = public as $$
declare v_company uuid;
begin
  if p_source is null or btrim(p_source) = '' then
    raise exception 'Une distance sans source ne doit pas servir à payer : indiquez son origine.';
  end if;
  if p_km is null or p_km < 0 then
    raise exception 'Distance invalide : %', p_km;
  end if;

  v_company := (fn_address_of(p_origin) ->> 'company_id')::uuid;
  if not can_manage_company(v_company) then
    raise exception 'Accès refusé : seul un gestionnaire de la société peut enregistrer une distance.';
  end if;

  insert into travel_distances(origin_ref, destination_ref, distance_km,
                               duration_minutes, source, computed_by, note)
  values (p_origin, p_destination, p_km, p_minutes, p_source, auth.uid(), p_note)
  on conflict (origin_ref, destination_ref) do update
    set distance_km = excluded.distance_km,
        duration_minutes = excluded.duration_minutes,
        source = excluded.source,
        computed_at = now(),
        computed_by = excluded.computed_by,
        note = excluded.note;

  -- La transmission d'une adresse à un tiers est un accès à une donnée
  -- personnelle : elle se trace comme tel.
  if split_part(p_origin, ':', 1) = 'employee' then
    perform fn_log_access(split_part(p_origin, ':', 2)::uuid, 'employees',
                          split_part(p_origin, ':', 2)::uuid, 'DOWNLOAD',
                          'adresse transmise au service de distance : ' || p_source, 1);
  end if;

  return jsonb_build_object('ok', true, 'origin', p_origin,
                            'destination', p_destination, 'distance_km', p_km);
end $$;

revoke execute on function fn_set_travel_distance(text, text, numeric, integer, text, text)
  from public, anon;
grant  execute on function fn_set_travel_distance(text, text, numeric, integer, text, text)
  to authenticated;

comment on function fn_set_travel_distance(text, text, numeric, integer, text, text) is
  'Enregistre une distance dans le cache. Exige une source, contrôle le droit de gestion, et trace la transmission de l''adresse du salarié au service consulté.';
