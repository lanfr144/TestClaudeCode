-- 110 — Trajets, étapes géocodées et typologie
--
-- Un trajet n'est pas une distance : c'est une **séquence ordonnée de points**,
-- chacun horodaté et situé. Le domicile, le dépôt, le magasin d'approvisionnement,
-- les chantiers successifs. C'est la séquence qui permet de dire, pour chaque
-- minute, si le salarié était couvert et s'il devait être payé — un kilométrage
-- total ne le permet pas.
--
-- Trois natures de trajet, trois traitements qui n'ont rien de commun :
--
-- | Nature | Rémunéré | Couverture |
-- |---|---|---|
-- | Domicile ↔ lieu de travail, pause repas extérieure | non | risque de **trajet** |
-- | Inter-chantiers, dépôt ↔ client | **oui**, taux contractuel | risque de **travail** |
-- | Domicile ↔ chantier direct | non | risque de trajet, **indemnité kilométrique** |
--
-- Les données de traceur — horodatage, distance réelle, trace de l'itinéraire —
-- sont accueillies telles quelles. La trace est en GeoJSON plutôt qu'en type
-- géométrique : le projet doit rester portable vers Oracle et MySQL, et une
-- extension spatiale n'y a pas le même nom ni la même syntaxe.

-- ------------------------------------------------------------ les domaines
create table ref_type_trajet (
  code            text primary key,
  libelle         text not null,
  remunere        boolean not null,
  indemnite_km    boolean not null default false,
  couverture_aaa  text not null references ref_couverture_aaa(code),
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);
comment on table ref_type_trajet is
  'Natures de trajet, et ce que chacune emporte : rémunération, indemnité kilométrique, couverture accident. Table de domaine datée.';
comment on column ref_type_trajet.code is 'Identifiant court porté par le trajet.';
comment on column ref_type_trajet.libelle is 'Intitulé lisible.';
comment on column ref_type_trajet.remunere is 'Le temps de ce trajet est-il du temps de travail effectif ?';
comment on column ref_type_trajet.indemnite_km is 'Ce trajet ouvre-t-il droit à une indemnité kilométrique ?';
comment on column ref_type_trajet.couverture_aaa is 'Couverture par défaut. Un détour ou une interruption peut la retirer au cas par cas.';
comment on column ref_type_trajet.description is 'Ce que la nature recouvre.';
comment on column ref_type_trajet.ordre is 'Ordre d''affichage.';
comment on column ref_type_trajet.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_type_trajet.fin_validite is 'Fin de validité, borne exclue.';
comment on column ref_type_trajet.note is 'Précision libre.';

insert into ref_type_trajet (code, libelle, remunere, indemnite_km, couverture_aaa, description, ordre) values
  ('domicile_travail', 'Domicile ↔ lieu de travail habituel', false, false, 'couvert',
   'Parcours normal entre la résidence principale et le lieu de travail. Pas du temps de travail effectif ; couvert au titre du risque de trajet, art. L.211-2 du Code de la sécurité sociale.', 1),
  ('domicile_chantier', 'Domicile ↔ chantier ou client, en direct', false, true, 'couvert',
   'Le salarié se rend directement sur un lieu d''exécution sans passer par le siège. Non rémunéré, mais ouvre l''indemnité kilométrique pour la part excédant le trajet habituel.', 2),
  ('pause_exterieure', 'Trajet vers le lieu de prise des repas', false, false, 'couvert',
   'L''art. L.211-2 assimile le lieu de prise habituelle des repas au lieu de travail pour le risque de trajet.', 3),
  ('inter_sites', 'Entre deux lieux d''exécution', true, false, 'couvert',
   'Déplacement d''un chantier à un autre au cours de la journée, sur instruction de l''employeur. Temps de travail effectif, payé au taux contractuel.', 10),
  ('depot_client', 'Dépôt ou siège ↔ client', true, false, 'couvert',
   'Départ du siège ou du dépôt vers un client, et retour. Temps de travail effectif.', 11),
  ('approvisionnement', 'Vers un fournisseur ou un magasin', true, false, 'couvert',
   'Passage par un magasin d''approvisionnement pour les besoins du chantier. Temps de travail effectif.', 12),
  ('mission', 'Déplacement en mission', true, false, 'couvert',
   'Déplacement professionnel hors du lieu habituel de travail.', 13);

create table ref_point_etape (
  code            text primary key,
  libelle         text not null,
  lieu_de_travail boolean not null default false,
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);
comment on table ref_point_etape is
  'Natures de point d''étape d''un trajet. Table de domaine datée.';
comment on column ref_point_etape.code is 'Identifiant court porté par l''étape.';
comment on column ref_point_etape.libelle is 'Intitulé lisible.';
comment on column ref_point_etape.lieu_de_travail is 'Ce point est-il un lieu d''exécution du travail ? C''est lui qui fait basculer un segment de trajet en segment de travail.';
comment on column ref_point_etape.description is 'Ce que la nature recouvre.';
comment on column ref_point_etape.ordre is 'Ordre d''affichage.';
comment on column ref_point_etape.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_point_etape.fin_validite is 'Fin de validité, borne exclue.';
comment on column ref_point_etape.note is 'Précision libre.';

insert into ref_point_etape (code, libelle, lieu_de_travail, description, ordre) values
  ('domicile', 'Domicile', false, 'Résidence principale du salarié, au sens de l''art. L.211-2 du Code de la sécurité sociale.', 1),
  ('siege', 'Siège de la société', true, 'Établissement principal de l''employeur.', 2),
  ('depot', 'Dépôt', true, 'Lieu de prise de matériel ou de véhicule.', 3),
  ('chantier', 'Chantier', true, 'Lieu d''exécution temporaire.', 4),
  ('site_client', 'Site client', true, 'Lieu d''exécution chez un client.', 5),
  ('magasin', 'Magasin d''approvisionnement', true, 'Fournisseur, pour les besoins du chantier.', 6),
  ('repas', 'Lieu de prise des repas', false, 'Assimilé au lieu de travail pour le risque de trajet.', 7),
  ('garde_enfant', 'Crèche ou école', false, 'Dépôt ou récupération d''un enfant. Interruption admise au titre des nécessités essentielles de la vie courante.', 8),
  ('autre', 'Autre', false, 'Point non classé — à qualifier.', 99);

-- --------------------------------------------------------------- les trajets
create table trajets (
  id                    uuid primary key default gen_random_uuid(),
  societe_id            uuid not null references societes(id) on delete cascade,
  salarie_id            uuid not null references salaries(id) on delete cascade,
  segment_temps_id      uuid references segments_temps(id) on delete set null,
  type_trajet           text not null references ref_type_trajet(code),
  debut_le              timestamptz not null,
  fin_le                timestamptz not null,
  distance_km_reelle    numeric(8,3),
  distance_km_reference numeric(8,3),
  distance_km_compensable numeric(8,3),
  source                text not null default 'declaratif',
  trace                 jsonb,
  remboursable          boolean,
  origine_remboursement text,
  couverture_aaa        text not null references ref_couverture_aaa(code) default 'a_determiner',
  motif_exclusion_aaa   text,
  note                  text,
  cree_le               timestamptz not null default now(),

  constraint trajet_non_vide check (fin_le > debut_le),
  constraint trajet_source_connue check (source in ('gps', 'declaratif', 'estime', 'planifie')),
  constraint trajet_distances_positives check (
    coalesce(distance_km_reelle, 0) >= 0
    and coalesce(distance_km_reference, 0) >= 0
    and coalesce(distance_km_compensable, 0) >= 0
  )
);

comment on table trajets is
  'Déplacement d''un salarié, composé d''étapes ordonnées. Porte ce qui se décide au niveau du trajet entier : sa nature, sa distance, sa couverture accident et son caractère remboursable.';
comment on column trajets.id is 'Identifiant du trajet.';
comment on column trajets.societe_id is 'Société employeuse. Clé d''isolation.';
comment on column trajets.salarie_id is 'Salarié qui se déplace.';
comment on column trajets.segment_temps_id is 'Segment de temps correspondant, lorsque le trajet est du temps de travail effectif. Nul pour un trajet domicile-travail, qui n''est pas du temps de travail.';
comment on column trajets.type_trajet is 'Nature du trajet — voir ref_type_trajet.';
comment on column trajets.debut_le is 'Départ. Horodatage avec fuseau : un trajet de nuit franchit minuit.';
comment on column trajets.fin_le is 'Arrivée, borne exclue.';
comment on column trajets.distance_km_reelle is 'Distance effectivement parcourue, relevée par le traceur ou déclarée.';
comment on column trajets.distance_km_reference is 'Distance du trajet habituel domicile-travail, qui sert de référence au calcul de la part compensable.';
comment on column trajets.distance_km_compensable is 'Part de la distance ouvrant droit à indemnité. Nulle tant que la formule de calcul n''est pas arrêtée — elle n''est pas inventée ici.';
comment on column trajets.source is 'D''où vient la mesure : gps, declaratif, estime, planifie. Un relevé de traceur et une saisie manuelle n''ont pas la même valeur probante.';
comment on column trajets.trace is 'Trace vectorielle de l''itinéraire, en GeoJSON. Pas de type géométrique : le schéma doit rester portable vers Oracle et MySQL.';
comment on column trajets.remboursable is 'Le trajet ouvre-t-il droit à remboursement ? Résulte du contrat, de la convention ou du règlement intérieur, la disposition la plus favorable l''emportant. Nul tant que la question n''est pas tranchée.';
comment on column trajets.origine_remboursement is 'Quelle norme a fondé le caractère remboursable : contrat, convention, reglement. Le moteur dit laquelle a gagné.';
comment on column trajets.couverture_aaa is 'Couverture par l''assurance accident — voir ref_couverture_aaa.';
comment on column trajets.motif_exclusion_aaa is 'Pourquoi la couverture est écartée, le cas échéant : détour, interruption, imprudence. Un refus sans motif est incontestable, donc inacceptable.';
comment on column trajets.note is 'Précision libre.';
comment on column trajets.cree_le is 'Horodatage de création.';

create index idx_trajets_salarie_periode on trajets (salarie_id, debut_le);
create index idx_trajets_societe_periode on trajets (societe_id, debut_le);

-- --------------------------------------------------------------- les étapes
create table etapes_trajet (
  id                 uuid primary key default gen_random_uuid(),
  trajet_id          uuid not null references trajets(id) on delete cascade,
  rang               smallint not null,
  type_point         text not null references ref_point_etape(code),
  libelle            text,
  site_client_id     uuid references sites_client(id),
  ligne              text,
  code_postal        text,
  localite           text,
  pays               text,
  latitude           numeric(9,6),
  longitude          numeric(9,6),
  source_geocodage   text,
  arrivee_le         timestamptz,
  depart_le          timestamptz,
  distance_depuis_precedente_km numeric(8,3),
  dans_la_zone       boolean,
  note               text,
  cree_le            timestamptz not null default now(),

  constraint etape_rang_unique unique (trajet_id, rang),
  constraint etape_ordre_horaire check (depart_le is null or arrivee_le is null or depart_le >= arrivee_le),
  constraint etape_latitude_valide check (latitude is null or (latitude between -90 and 90)),
  constraint etape_longitude_valide check (longitude is null or (longitude between -180 and 180))
);

comment on table etapes_trajet is
  'Point d''arrêt d''un trajet, dans l''ordre du parcours. C''est la séquence qui permet de dire, pour chaque minute, où était le salarié — et donc s''il était couvert et s''il devait être payé.';
comment on column etapes_trajet.id is 'Identifiant de l''étape.';
comment on column etapes_trajet.trajet_id is 'Trajet auquel l''étape appartient.';
comment on column etapes_trajet.rang is 'Position dans la séquence, à partir de 1. Unique par trajet.';
comment on column etapes_trajet.type_point is 'Nature du point — voir ref_point_etape.';
comment on column etapes_trajet.libelle is 'Nom du lieu, tel que le salarié le désigne.';
comment on column etapes_trajet.site_client_id is 'Site client correspondant, lorsque l''étape en est un.';
comment on column etapes_trajet.ligne is 'Rue et numéro.';
comment on column etapes_trajet.code_postal is 'Code postal.';
comment on column etapes_trajet.localite is 'Localité.';
comment on column etapes_trajet.pays is 'Pays, en ISO 3166-1 alpha-3.';
comment on column etapes_trajet.latitude is 'Latitude en degrés décimaux.';
comment on column etapes_trajet.longitude is 'Longitude en degrés décimaux.';
comment on column etapes_trajet.source_geocodage is 'Qui a situé ce point : geoportail, traceur, saisie manuelle. Une coordonnée sans provenance ne se vérifie pas.';
comment on column etapes_trajet.arrivee_le is 'Horodatage d''arrivée au point.';
comment on column etapes_trajet.depart_le is 'Horodatage de départ du point.';
comment on column etapes_trajet.distance_depuis_precedente_km is 'Distance parcourue depuis l''étape précédente.';
comment on column etapes_trajet.dans_la_zone is 'Le point relevé tombe-t-il dans la zone de tolérance de l''adresse attendue ? C''est ce contrôle qui fait basculer un trajet en travail effectif.';
comment on column etapes_trajet.note is 'Précision libre.';
comment on column etapes_trajet.cree_le is 'Horodatage de création.';

create index idx_etapes_trajet on etapes_trajet (trajet_id, rang);

-- ------------------------------------------------------------------- RLS
alter table ref_type_trajet enable row level security;
alter table ref_point_etape enable row level security;
alter table trajets enable row level security;
alter table etapes_trajet enable row level security;

create policy type_trajet_lecture on ref_type_trajet for select to authenticated using (true);
create policy point_etape_lecture on ref_point_etape for select to authenticated using (true);

create policy trajets_lecture on trajets for select
  using (has_company_access(societe_id) or is_self_employee(salarie_id));
create policy trajets_ins on trajets for insert with check (can_manage_company(societe_id));
create policy trajets_upd on trajets for update using (can_manage_company(societe_id));
create policy trajets_del on trajets for delete using (can_manage_company(societe_id));

-- Une étape suit le sort de son trajet : les mêmes yeux, les mêmes mains.
create policy etapes_lecture on etapes_trajet for select
  using (exists (select 1 from trajets t where t.id = trajet_id
                  and (has_company_access(t.societe_id) or is_self_employee(t.salarie_id))));
create policy etapes_ins on etapes_trajet for insert
  with check (exists (select 1 from trajets t where t.id = trajet_id and can_manage_company(t.societe_id)));
create policy etapes_upd on etapes_trajet for update
  using (exists (select 1 from trajets t where t.id = trajet_id and can_manage_company(t.societe_id)));
create policy etapes_del on etapes_trajet for delete
  using (exists (select 1 from trajets t where t.id = trajet_id and can_manage_company(t.societe_id)));
