-- 56 — Validation des adresses : Luxembourg par le CACLR, frontaliers par zones
--
-- Ce que la consigne demande
-- --------------------------
--   · Luxembourg : vérifier par l'API CACLR, ou charger le CACLR en base.
--   · Pays limitrophes : utiliser une API si elle existe, sinon **restreindre**
--     aux provinces de Liège, Namur et Luxembourg (BE), aux départements 54 et
--     57 (FR), à la Rhénanie-Palatinat et à la Sarre (DE).
--
-- La source luxembourgeoise, vérifiée
-- -----------------------------------
-- Le registre officiel est publié par l'Administration du cadastre et de la
-- topographie sous le nom **BD-Adresses**, sur data.public.lu. Il expose deux
-- voies, qui correspondent exactement à l'alternative de la consigne :
--
--   API   https://apiv3.geoportail.lu/geocode/search      (et /geocode/reverse)
--   Vrac  addresses.csv — 26,9 Mo, ~ 160 000 adresses géoréférencées
--         https://data.public.lu/datasets/adresses-georeferencees-bd-adresses
--
-- L'API est retenue par défaut : elle suit les mises à jour sans qu'on ait à
-- recharger quoi que ce soit. Elle est appelée par l'Edge Function
-- `address-validate`, jamais depuis le navigateur — voir son en-tête pour ce que
-- cela implique côté protection des données.
--
-- Ce qui est déclaré vide plutôt qu'inventé
-- -----------------------------------------
-- Les codes postaux belges et français se rattachent proprement à une province
-- ou à un département. **Les codes postaux allemands, non** : la Rhénanie-
-- Palatinat et la Sarre se partagent des préfixes avec leurs voisins, sans
-- découpage net. Plutôt que d'écrire un intervalle plausible et faux, la zone
-- allemande est déclarée **sans bornes postales** et marquée non vérifiée : la
-- validation répond alors « indéterminé », et le dit. Règle 7 du CLAUDE.md.

-- ===========================================================================
-- 1. Les zones autorisées
-- ===========================================================================

create table if not exists address_zones (
  id           uuid primary key default extensions.gen_random_uuid(),
  country      char(2) not null,
  kind         text    not null,
  code         text    not null,
  label        text    not null,
  postal_from  integer,
  postal_to    integer,
  is_verified  boolean not null default false,
  source       text    not null,
  note         text,
  constraint address_zone_unique unique (country, code),
  constraint address_zone_range  check (postal_to is null or postal_from is null
                                        or postal_to >= postal_from),
  constraint address_zone_verified_needs_range
    check (not is_verified or (postal_from is not null and postal_to is not null))
);

comment on table address_zones is $c$Zones géographiques dans lesquelles une adresse est acceptée. Hors de ces zones, la saisie est refusée : l'outil ne prétend pas couvrir des adresses qu'il ne sait pas vérifier.$c$;
comment on column address_zones.postal_from is $c$Borne basse du code postal, une fois le préfixe pays retiré. Nulle quand le pays n'admet pas de découpage postal fiable — voir is_verified.$c$;
comment on column address_zones.is_verified is $c$Vrai si les bornes postales sont établies et vérifiables. Faux pour une zone déclarée sans correspondance postale fiable : la validation répond alors « indéterminé » plutôt que d'accepter à tort.$c$;
comment on column address_zones.source is $c$D'où viennent les bornes. Une zone sans source n'a rien à faire ici.$c$;
comment on constraint address_zone_verified_needs_range on address_zones is
  'On ne peut pas se déclarer vérifié sans bornes : la contrainte interdit de cocher la case sans le travail.';

alter table address_zones enable row level security;

drop policy if exists address_zones_read on address_zones;
create policy address_zones_read on address_zones
  for select to authenticated using (true);

insert into address_zones (country, kind, code, label, postal_from, postal_to, is_verified, source, note) values
  ('LU', 'pays',        'LU',    'Luxembourg (tout le pays)',        1000,  9999, true,
   'BD-Adresses, Administration du cadastre et de la topographie, data.public.lu',
   'Codes postaux à quatre chiffres. La vérification fine de la rue et du numéro passe par l''API geocode du geoportail.'),

  ('BE', 'province',    'BE-WLG', 'Province de Liège',               4000,  4999, true,
   'Découpage postal belge par province (bpost)', null),
  ('BE', 'province',    'BE-WNA', 'Province de Namur',               5000,  5680, true,
   'Découpage postal belge par province (bpost)', null),
  ('BE', 'province',    'BE-WLX', 'Province de Luxembourg',          6600,  6999, true,
   'Découpage postal belge par province (bpost)', null),

  ('FR', 'departement', 'FR-54',  'Meurthe-et-Moselle',             54000, 54999, true,
   'Les deux premiers chiffres du code postal français désignent le département', null),
  ('FR', 'departement', 'FR-57',  'Moselle',                        57000, 57999, true,
   'Les deux premiers chiffres du code postal français désignent le département', null),

  ('DE', 'land',        'DE-RP',  'Rhénanie-Palatinat',              null,  null, false,
   'Zone déclarée ; correspondance postale non chargée',
   'Les codes postaux allemands ne se rattachent pas proprement à un Land : la Rhénanie-Palatinat partage des préfixes avec la Hesse, la Sarre et le Bade-Wurtemberg. Aucun intervalle n''est inscrit tant qu''une source fiable n''est pas chargée.'),
  ('DE', 'land',        'DE-SL',  'Sarre',                           null,  null, false,
   'Zone déclarée ; correspondance postale non chargée',
   'Même raison que pour la Rhénanie-Palatinat.')
on conflict (country, code) do update
  set label = excluded.label, postal_from = excluded.postal_from,
      postal_to = excluded.postal_to, is_verified = excluded.is_verified,
      source = excluded.source, note = excluded.note;

-- ===========================================================================
-- 2. Normaliser un code postal
-- ===========================================================================
-- Le jeu de données utilise la convention luxembourgeoise du préfixe pays :
-- « L-1424 », « F-57000 », « B-6700 », « D-54294 ». On le retire avant de
-- comparer, et on tolère les espaces et les tirets internes.

create or replace function fn_postal_number(p_country text, p_postal text)
returns integer language sql immutable set search_path = public as $$
  select nullif(regexp_replace(
           regexp_replace(upper(coalesce(p_postal, '')), '^\s*[A-Z]{1,2}\s*-\s*', ''),
           '[^0-9]', '', 'g'), '')::integer;
$$;

comment on function fn_postal_number(text, text) is
  'Code postal réduit à son nombre, préfixe pays et séparateurs retirés. « L-1424 » donne 1424.';

revoke execute on function fn_postal_number(text, text) from public, anon;
grant  execute on function fn_postal_number(text, text) to authenticated;

-- ===========================================================================
-- 3. Valider une adresse
-- ===========================================================================
-- Trois issues, jamais deux :
--   ok           la zone est identifiée et vérifiée ;
--   outside      le pays est couvert, le code postal est hors des zones ;
--   unknown      le pays n'est pas couvert, ou sa correspondance postale n'est
--                pas chargée. Ni accepté ni refusé : signalé.

create or replace function fn_validate_address(
  p_country text,
  p_postal  text,
  p_city    text default null
) returns jsonb language plpgsql stable set search_path = public as $$
declare
  v_pays  char(2) := upper(nullif(btrim(coalesce(p_country, '')), ''));
  v_num   integer := fn_postal_number(p_country, p_postal);
  z       address_zones%rowtype;
  v_zones int;
begin
  if v_pays is null then
    return jsonb_build_object('status', 'unknown', 'message',
      'Pays non renseigné : l''adresse ne peut pas être située.');
  end if;

  select count(*) into v_zones from address_zones where country = v_pays;
  if v_zones = 0 then
    return jsonb_build_object('status', 'unknown', 'country', v_pays,
      'message', format('Le pays « %s » n''est pas couvert. LuxRH ne vérifie que le '
                        'Luxembourg et les zones frontalières déclarées dans address_zones.', v_pays));
  end if;

  if v_num is null then
    return jsonb_build_object('status', 'unknown', 'country', v_pays,
      'message', 'Code postal absent ou illisible : la zone ne peut pas être déterminée.');
  end if;

  -- `exists` implicite : on s'arrête à la première zone qui contient le code.
  select * into z from address_zones
   where country = v_pays and is_verified
     and v_num between postal_from and postal_to
   limit 1;

  if z.id is not null then
    return jsonb_build_object(
      'status', 'ok', 'country', v_pays, 'postal', v_num,
      'zone', z.code, 'zone_label', z.label, 'source', z.source);
  end if;

  -- Le pays est couvert mais aucune zone vérifiée ne contient ce code : soit il
  -- est hors périmètre, soit le pays n'a pas de bornes chargées.
  if exists (select 1 from address_zones where country = v_pays and is_verified) then
    return jsonb_build_object(
      'status', 'outside', 'country', v_pays, 'postal', v_num,
      'allowed', (select jsonb_agg(jsonb_build_object('zone', code, 'label', label,
                                                      'from', postal_from, 'to', postal_to)
                                   order by postal_from)
                    from address_zones where country = v_pays and is_verified),
      'message', format('Le code postal %s est hors des zones couvertes pour %s.', v_num, v_pays));
  end if;

  return jsonb_build_object(
    'status', 'unknown', 'country', v_pays, 'postal', v_num,
    'zones', (select jsonb_agg(label order by label) from address_zones where country = v_pays),
    'message', format('Les zones déclarées pour %s n''ont pas de correspondance postale '
                      'chargée : l''adresse ne peut être ni confirmée ni écartée ici. '
                      'Une vérification manuelle ou par API reste nécessaire.', v_pays));
end $$;

comment on function fn_validate_address(text, text, text) is
  'Situe une adresse dans les zones autorisées. Répond ok, outside ou unknown — jamais un simple booléen, parce qu''« on ne sait pas » n''est pas « non ».';

revoke execute on function fn_validate_address(text, text, text) from public, anon;
grant  execute on function fn_validate_address(text, text, text) to authenticated;

-- ===========================================================================
-- 4. Le registre des vérifications
-- ===========================================================================
-- Une adresse indéterminée n'est pas refusée, mais elle ne doit pas non plus
-- disparaître dans le silence. Chaque écriture laisse ici son verdict.

create table if not exists address_checks (
  id           uuid primary key default extensions.gen_random_uuid(),
  entity_table text not null,
  entity_id    uuid not null,
  company_id   uuid,
  country      char(2),
  postal_code  text,
  status       text not null,
  zone_code    text,
  message      text,
  checked_at   timestamptz not null default now(),
  constraint address_check_status check (status in ('ok', 'outside', 'unknown')),
  constraint address_check_unique unique (entity_table, entity_id)
);

comment on table address_checks is $c$Dernier verdict de validation d'adresse par objet. Une adresse « unknown » y reste visible : c'est ce qui permet de la reprendre plus tard, plutôt que de la croire vérifiée.$c$;

create index if not exists idx_address_checks_status on address_checks (status, checked_at desc);

alter table address_checks enable row level security;

drop policy if exists address_checks_read on address_checks;
create policy address_checks_read on address_checks
  for select to authenticated
  using (company_id is null or has_company_access(company_id));

-- ===========================================================================
-- 5. Le déclencheur : la ligne écrite, et elle seule
-- ===========================================================================
-- Conformément à la règle des déclencheurs ciblés : ce déclencheur ne regarde
-- que `new`. Il ne parcourt aucune autre ligne de sa table, et n'interroge que
-- `address_zones`, qui compte huit lignes.

create or replace function fn_check_address()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_verdict jsonb;
  v_company uuid;
begin
  -- Rien à valider tant qu'aucune adresse n'est saisie.
  if new.postal_code is null and new.country is null then
    return new;
  end if;

  -- Sur une mise à jour, on ne revalide que si l'adresse a bougé.
  if tg_op = 'UPDATE'
     and new.country     is not distinct from old.country
     and new.postal_code is not distinct from old.postal_code
     and new.city        is not distinct from old.city then
    return new;
  end if;

  v_verdict := fn_validate_address(new.country, new.postal_code, new.city);

  if v_verdict ->> 'status' = 'outside' then
    raise exception '%', v_verdict ->> 'message'
      using hint = 'LuxRH restreint les adresses au Luxembourg et aux zones '
                   'frontalières déclarées. Ajoutez la zone dans address_zones '
                   'si le périmètre doit s''étendre.';
  end if;

  v_company := case tg_table_name
                 when 'companies' then new.id
                 else new.company_id
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

drop trigger if exists check_address on employees;
create trigger check_address before insert or update on employees
  for each row execute function fn_check_address();

drop trigger if exists check_address on companies;
create trigger check_address before insert or update on companies
  for each row execute function fn_check_address();

drop trigger if exists check_address on client_sites;
create trigger check_address before insert or update on client_sites
  for each row execute function fn_check_address();

-- ===========================================================================
-- 6. Ce qui reste à faire, et n'est pas du SQL
-- ===========================================================================
-- · La vérification fine d'une adresse luxembourgeoise — rue, numéro, existence
--   réelle — passe par l'Edge Function `address-validate`, qui interroge
--   l'API geocode du geoportail. Le déclencheur ci-dessus ne vérifie que la
--   zone : il ne prétend pas qu'une adresse située au Luxembourg existe.
-- · Les bornes postales allemandes restent à charger. Tant qu'elles manquent,
--   une adresse allemande est enregistrée avec le statut `unknown` :
--     select * from address_checks where status = 'unknown';
-- · Le chargement en vrac du CACLR (addresses.csv) reste une option si l'on
--   veut se passer de l'API : il faudrait alors une table `lu_addresses` et une
--   tâche de rafraîchissement.
