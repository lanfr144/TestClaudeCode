-- 67 — Les quatre adresses du salarié, historisées sans trou
--
-- Quatre adresses, toutes obligatoires, toutes datées
-- ----------------------------------------------------
--   domicile_legal    l'adresse officielle. **Seule base** des distances et des
--                     indemnisations fiscales.
--   residence         là où la personne vit effectivement — un logement loué
--                     près du travail pour la semaine, par exemple.
--   derniere_etape    l'arrêt juste avant le travail : crèche, école.
--   premiere_etape    le premier arrêt après le travail.
--
-- Les deux dernières servent à agencer les tournées client : l'ordre des
-- visites épouse le trajet réel de la personne, dépose et récupération des
-- enfants comprises.
--
-- Pourquoi quatre lignes même quand l'adresse est la même
-- --------------------------------------------------------
-- Duplication volontaire. Une requête de planning ne doit pas avoir à savoir
-- que « l'étape n'est pas renseignée, donc c'est le domicile ». Elle lit la
-- ligne du type qu'elle veut, à la date qu'elle veut, et trouve toujours
-- quelque chose.
--
-- Couverture continue, du dépôt de candidature à bien après le départ
-- --------------------------------------------------------------------
-- Une erreur de salaire découverte trois ans plus tard suppose de pouvoir
-- écrire à la personne. La couverture ne s'arrête donc pas à la sortie : la
-- dernière période court jusqu'au 31/12/2037, sentinelle du projet.
--
-- Deux garanties, posées par le schéma et non par l'application :
--   · contrainte d'exclusion GiST — deux périodes du même type ne se recouvrent
--     jamais pour un même salarié ;
--   · `fn_verifier_couverture_adresses` — aucun trou entre deux périodes.

create table if not exists ref_type_adresse (
  code           text primary key,
  libelle        text not null,
  description    text not null,
  ordre          smallint not null default 0,
  sert_au_fiscal boolean not null default false,
  sert_aux_tournees boolean not null default false,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  constraint rta_periode check (fin_validite > debut_validite)
);

comment on table ref_type_adresse is $c$Les quatre natures d'adresse d'un salarié. Table de domaine : en ajouter une ne demande pas de migration.$c$;
comment on column ref_type_adresse.sert_au_fiscal is $c$Vrai pour la seule adresse qui fonde les distances officielles et les indemnisations fiscales — le domicile légal. Les autres ne doivent jamais servir à cela.$c$;

insert into ref_type_adresse (code, libelle, description, ordre, sert_au_fiscal, sert_aux_tournees) values
  ('domicile_legal',  'Domicile légal',
   'Adresse officielle enregistrée auprès des administrations. Seule base des distances et indemnisations fiscales.', 1, true, false),
  ('residence',       'Lieu de résidence actuel',
   'Où le salarié vit effectivement au quotidien, s''il diffère du domicile légal.', 2, false, false),
  ('derniere_etape',  'Dernière étape pour venir',
   'Point d''arrêt final avant d''arriver au travail — crèche, école.', 3, false, true),
  ('premiere_etape',  'Première étape pour repartir',
   'Premier point d''arrêt après avoir quitté le travail.', 4, false, true)
on conflict (code) do update
  set libelle = excluded.libelle, description = excluded.description,
      ordre = excluded.ordre, sert_au_fiscal = excluded.sert_au_fiscal,
      sert_aux_tournees = excluded.sert_aux_tournees;

alter table ref_type_adresse enable row level security;
drop policy if exists ref_type_adresse_lecture on ref_type_adresse;
create policy ref_type_adresse_lecture on ref_type_adresse
  for select to authenticated using (true);

create table if not exists adresses_salarie (
  id             uuid primary key default extensions.gen_random_uuid(),
  company_id     uuid not null,
  employee_id    uuid not null,
  type_adresse   text not null references ref_type_adresse(code),
  ligne          text,
  code_postal    text,
  localite       text,
  pays           char(3) not null default 'LUX',
  latitude       numeric(9,6),
  longitude      numeric(9,6),
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  origine        text not null default 'saisie',
  note           text,
  created_at     timestamptz not null default now(),
  created_by     uuid,
  deleted_at     timestamptz,
  deleted_by     uuid,
  constraint adr_periode check (fin_validite > debut_validite),
  constraint adr_deleted_pair check ((deleted_at is null) = (deleted_by is null)),
  constraint adr_a_une_adresse
    check (ligne is not null or (code_postal is not null and localite is not null)
           or (latitude is not null and longitude is not null)),
  constraint adr_appartient_au_salarie
    foreign key (employee_id, company_id) references employees (id, company_id)
    on update cascade on delete cascade,
  -- Deux périodes du même type ne se recouvrent jamais pour un même salarié.
  constraint adr_pas_de_recouvrement
    exclude using gist (
      employee_id with =,
      type_adresse with =,
      daterange(debut_validite, fin_validite, '[)') with &&
    )
);

comment on table adresses_salarie is $c$Les quatre adresses du salarié, historisées. Chaque type doit couvrir toute la période sans trou ni recouvrement, depuis la candidature jusqu'à bien après le départ : une erreur de salaire découverte plus tard suppose de pouvoir écrire à la personne.$c$;
comment on column adresses_salarie.pays is $c$Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU. Trois lettres partout dans l'application.$c$;
comment on column adresses_salarie.origine is $c$D'où vient la ligne : « saisie » pour une saisie directe, « copie_domicile » pour une recopie automatique du domicile légal, « import » pour une reprise.$c$;
comment on constraint adr_pas_de_recouvrement on adresses_salarie is
  'Un salarié n''a qu''une adresse par type à un instant donné. Contrainte d''exclusion : c''est la base qui l''impose, pas l''interface.';

create index if not exists idx_adresses_salarie
  on adresses_salarie (employee_id, type_adresse, debut_validite) where deleted_at is null;

alter table adresses_salarie enable row level security;
drop policy if exists adresses_salarie_lecture on adresses_salarie;
create policy adresses_salarie_lecture on adresses_salarie
  for select to authenticated
  using (deleted_at is null and (has_company_access(company_id) or is_self_employee(employee_id)));
drop policy if exists adresses_salarie_ecriture on adresses_salarie;
create policy adresses_salarie_ecriture on adresses_salarie
  for insert to authenticated
  with check (can_manage_company(company_id) or is_self_employee(employee_id));
drop policy if exists adresses_salarie_maj on adresses_salarie;
create policy adresses_salarie_maj on adresses_salarie
  for update to authenticated using (can_manage_company(company_id))
  with check (can_manage_company(company_id));

create trigger audit_adresses_salarie after insert or update or delete on adresses_salarie
  for each row execute function fn_audit();

-- La validation de zone s'applique ici comme ailleurs.
create or replace function fn_verifier_adresse_salarie()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_verdict jsonb;
begin
  v_verdict := fn_validate_address(new.pays, new.code_postal, new.localite);
  if v_verdict ->> 'status' = 'outside' then
    raise exception '%', v_verdict ->> 'message'
      using hint = 'Les adresses sont restreintes au Luxembourg et aux zones frontalières '
                   'déclarées dans address_zones.';
  end if;
  insert into address_checks (entity_table, entity_id, company_id, country,
                              postal_code, status, zone_code, message)
  values ('adresses_salarie', new.id, new.company_id, new.pays, new.code_postal,
          v_verdict ->> 'status', v_verdict ->> 'zone', v_verdict ->> 'message')
  on conflict (entity_table, entity_id) do update
    set status = excluded.status, zone_code = excluded.zone_code,
        message = excluded.message, checked_at = now();
  return new;
end $$;

revoke execute on function fn_verifier_adresse_salarie() from public, anon, authenticated;

drop trigger if exists verifier_adresse on adresses_salarie;
create trigger verifier_adresse after insert or update on adresses_salarie
  for each row execute function fn_verifier_adresse_salarie();
