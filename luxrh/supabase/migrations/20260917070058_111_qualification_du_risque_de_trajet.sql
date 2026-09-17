-- 111 — Qualifier le risque de trajet : loi, jurisprudence, géorepérage
--
-- **Art. L. 211-2 du Code de la sécurité sociale** : l'accident de trajet est
-- assimilé à un accident du travail lorsqu'il survient sur le **parcours normal**
-- d'aller-retour entre la résidence principale — ou le lieu de prise habituelle
-- des repas — et le lieu de travail.
--
-- Trois critères constants du Conseil arbitral et du Conseil supérieur de la
-- sécurité sociale, et c'est leur conjonction qui décide :
--
--   1. **Itinéraire direct et protégé**, parcouru dans une plage de temps en
--      rapport avec les heures de prise et de fin de service ;
--   2. **Détour ou interruption** dicté par l'intérêt personnel : la couverture
--      tombe (CSSS, arrêt n° 456/12). Sauf s'il s'agit d'une nécessité
--      essentielle de la vie courante — achat de nourriture de subsistance,
--      dépôt ou récupération d'un enfant en bas âge ;
--   3. **Moyen de transport** : tout moyen habituel ou raisonnable est couvert,
--      sauf imprudence grave ou faute intentionnelle rompant le lien causal.
--
-- Le moteur **qualifie et motive** ; il ne décide pas à la place de l'AAA. Un
-- refus de couverture sans motif exposé est incontestable, donc inacceptable.

create table ref_motif_interruption (
  code            text primary key,
  libelle         text not null,
  conserve_aaa    boolean not null,
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);
comment on table ref_motif_interruption is
  'Motifs de détour ou d''interruption d''un trajet, et leur effet sur la couverture accident. La jurisprudence distingue la nécessité essentielle de la vie courante, qui préserve la couverture, de l''intérêt personnel, qui la fait tomber.';
comment on column ref_motif_interruption.code is 'Identifiant court porté par le trajet.';
comment on column ref_motif_interruption.libelle is 'Intitulé lisible.';
comment on column ref_motif_interruption.conserve_aaa is 'La couverture survit-elle à cette interruption ? C''est la question que tranche la jurisprudence, et elle se lit ici plutôt que dans du code.';
comment on column ref_motif_interruption.description is 'Ce que le motif recouvre, et sur quoi il se fonde.';
comment on column ref_motif_interruption.ordre is 'Ordre d''affichage.';
comment on column ref_motif_interruption.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_motif_interruption.fin_validite is 'Fin de validité, borne exclue. Un revirement de jurisprudence se date, il n''écrase pas le passé.';
comment on column ref_motif_interruption.note is 'Référence de l''arrêt, le cas échéant.';

insert into ref_motif_interruption (code, libelle, conserve_aaa, description, ordre, note) values
  ('aucune', 'Aucune interruption', true,
   'Trajet direct, sans arrêt ni détour.', 1, null),
  ('garde_enfant', 'Dépôt ou récupération d''un enfant', true,
   'Crèche, école ou assistante maternelle, pour un enfant en bas âge. Nécessité essentielle de la vie courante.', 2,
   'Critère jurisprudentiel constant du Conseil supérieur de la sécurité sociale.'),
  ('subsistance', 'Achat de nourriture de subsistance', true,
   'Course alimentaire courante sur le parcours. Nécessité essentielle de la vie courante.', 3,
   'Critère jurisprudentiel constant. Un achat non alimentaire ou un détour important relève de l''intérêt personnel.'),
  ('covoiturage', 'Prise ou dépose d''un collègue', true,
   'Covoiturage habituel vers le même lieu de travail : le parcours reste normal.', 4, null),
  ('soins', 'Rendez-vous médical imposé', true,
   'Visite de médecine du travail ou soins prescrits en lien avec l''emploi.', 5, null),
  ('interet_personnel', 'Motif d''intérêt personnel', false,
   'Détour ou interruption dicté par la convenance personnelle, étranger à l''emploi. La couverture tombe.', 10,
   'CSSS, arrêt n° 456/12.'),
  ('imprudence_grave', 'Imprudence grave ou faute intentionnelle', false,
   'Imprégnation alcoolique caractérisée, vitesse excessive délibérée : le lien causal est rompu.', 11, null),
  ('a_qualifier', 'Interruption non qualifiée', false,
   'Une interruption a été relevée sans que son motif soit établi. La couverture n''est pas acquise tant que le motif n''est pas renseigné — elle n''est pas refusée non plus.', 20, null);

alter table ref_motif_interruption enable row level security;
create policy motif_interruption_lecture on ref_motif_interruption for select to authenticated using (true);

alter table trajets
  add column motif_interruption text references ref_motif_interruption(code) default 'aucune',
  add column duree_interruption_minutes integer,
  add column moyen_transport text;

comment on column trajets.motif_interruption is
  'Motif du détour ou de l''interruption — voir ref_motif_interruption. C''est lui qui décide du maintien de la couverture.';
comment on column trajets.duree_interruption_minutes is
  'Durée cumulée des arrêts hors étapes prévues. Une interruption brève pour une nécessité de la vie courante ne rompt pas le parcours ; une interruption longue le rompt.';
comment on column trajets.moyen_transport is
  'Moyen employé : voiture, transport en commun, vélo, marche. Tout moyen habituel ou raisonnable est couvert ; ce champ sert à établir qu''il l''était.';

-- ------------------------------------------------------ paramètres du moteur
insert into parametres_legaux
  (famille, cle_parametre, libelle, valeur_num, unite,
   debut_validite, fin_validite, source, reference_legale, note)
values
  ('temps_travail', 'GEOFENCE_RAYON_M',
   'Rayon de tolérance autour d''une adresse d''étape', 75, 'mètres',
   date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH', null,
   'Un relevé GPS n''est jamais exact au mètre. En deçà de ce rayon, le salarié est tenu pour arrivé : c''est ce qui fait basculer un segment de trajet en segment de travail effectif. Choix d''outil, entre les 50 et 100 mètres usuels.'),
  ('temps_travail', 'TRAJET_TOLERANCE_MINUTES',
   'Écart admis entre le trajet et les heures de service', 60, 'minutes',
   date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH', null,
   'La jurisprudence exige un trajet « effectué pendant une période de temps en rapport avec les heures de début et de fin de travail », sans fixer de durée. Ce paramètre rend ce jugement explicite et discutable, au lieu de le cacher dans du code.'),
  ('temps_travail', 'TRAJET_INTERRUPTION_MAX_MINUTES',
   'Durée au-delà de laquelle une interruption rompt le parcours', 30, 'minutes',
   date '1970-01-01', date '2037-12-31', 'Paramétrage applicatif LuxRH', null,
   'Même une nécessité de la vie courante ne préserve pas la couverture si l''arrêt se prolonge. Aucune durée n''est fixée par les textes : ce seuil est un choix d''outil, à confronter à la jurisprudence.')
on conflict do nothing;

-- ------------------------------------------------------------- géorepérage
create or replace function fn_distance_km(
  lat1 numeric, lon1 numeric, lat2 numeric, lon2 numeric
)
returns numeric
language sql
immutable
as $$
  -- Formule de haversine. Rayon terrestre moyen : 6371 km. Suffisante ici : on
  -- compare des points distants de quelques dizaines de mètres à quelques
  -- dizaines de kilomètres, où l'écart avec une géodésique reste sous le mètre.
  select case
    when lat1 is null or lon1 is null or lat2 is null or lon2 is null then null
    else round((6371 * 2 * asin(sqrt(
      power(sin(radians(lat2 - lat1) / 2), 2)
      + cos(radians(lat1)) * cos(radians(lat2))
      * power(sin(radians(lon2 - lon1) / 2), 2)
    )))::numeric, 4)
  end;
$$;
comment on function fn_distance_km(numeric, numeric, numeric, numeric) is
  'Distance à vol d''oiseau entre deux points, en kilomètres, par la formule de haversine. Sert au géorepérage, pas au calcul d''une indemnité kilométrique — celle-ci se fonde sur la distance routière.';

create or replace function fn_dans_la_zone(
  lat_releve numeric, lon_releve numeric,
  lat_attendu numeric, lon_attendu numeric,
  p_on date default current_date
)
returns boolean
language sql
stable
as $$
  -- Rend NULL, et non « faux », quand une coordonnée manque : on ne sait pas.
  select case
    when lat_releve is null or lon_releve is null
      or lat_attendu is null or lon_attendu is null then null
    else fn_distance_km(lat_releve, lon_releve, lat_attendu, lon_attendu) * 1000
         <= coalesce(fn_param_num('GEOFENCE_RAYON_M', p_on), 75)
  end;
$$;
comment on function fn_dans_la_zone(numeric, numeric, numeric, numeric, date) is
  'Le point relevé tombe-t-il dans la zone de tolérance de l''adresse attendue ? Rend NULL si une coordonnée manque — « on ne sait pas » n''est pas « non ».';

revoke execute on function fn_distance_km(numeric, numeric, numeric, numeric) from public;
revoke execute on function fn_dans_la_zone(numeric, numeric, numeric, numeric, date) from public;
grant execute on function fn_distance_km(numeric, numeric, numeric, numeric) to authenticated;
grant execute on function fn_dans_la_zone(numeric, numeric, numeric, numeric, date) to authenticated;
