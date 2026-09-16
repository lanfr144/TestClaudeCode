-- 96 — Le temps se stocke en segments homogènes, pas en totaux
--
-- `releves_temps` porte des totaux par journée : `heures_nuit`, `heures_dimanche`,
-- `heures_ferie`, `heures_supplementaires`. Un total ne dit pas **quand**, et l'on
-- ne peut plus, après coup, répondre à la question qui compte pour l'assurance
-- accident : à 14 h 37, ce salarié était-il sous la responsabilité de l'employeur ?
--
-- Un segment est une plage sur laquelle **rien ne change** : même classe de paie,
-- mêmes qualifications, même lieu. Dès qu'une caractéristique change, un nouveau
-- segment commence. Les totaux restent calculables par somme ; l'inverse est faux.
--
-- Nuit, dimanche et jour férié sont des **drapeaux**, pas des classes exclusives.
-- L'art. L. 232-7, par. (3) le commande : « Si l'un des jours fériés énumérés à
-- l'article L. 232-2 tombe un dimanche, le salarié occupé ce jour a droit au cumul
-- des indemnités. » Une classe unique aurait écrasé l'une des deux.

-- ------------------------------------------------------- domaines datés
create table ref_classe_paie (
  code            text primary key,
  libelle         text not null,
  famille         text not null,
  remunere        boolean not null,
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);
comment on table ref_classe_paie is
  'Natures de temps portées par un segment. Table de domaine datée, comme les autres : ajouter une classe ne demande pas de migration.';
comment on column ref_classe_paie.code is 'Identifiant court, cité par les segments et les routines de paie.';
comment on column ref_classe_paie.libelle is 'Intitulé lisible, affiché dans les interfaces.';
comment on column ref_classe_paie.famille is 'Regroupement : travail effectif, interruption, déplacement.';
comment on column ref_classe_paie.remunere is 'Le temps de cette classe entre-t-il dans la rémunération ? Une pause repas n''y entre pas ; un trajet inter-sites si.';
comment on column ref_classe_paie.description is 'Ce que la classe recouvre, et ce qu''elle ne recouvre pas.';
comment on column ref_classe_paie.ordre is 'Ordre d''affichage.';
comment on column ref_classe_paie.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_classe_paie.fin_validite is 'Fin de validité, borne exclue. Sentinelle 2037-12-31 tant que la classe est en vigueur.';
comment on column ref_classe_paie.note is 'Précision libre.';

create table ref_couverture_aaa (
  code            text primary key,
  libelle         text not null,
  description     text,
  ordre           smallint not null default 0,
  debut_validite  date not null default date '1970-01-01',
  fin_validite    date not null default date '2037-12-31',
  note            text
);
comment on table ref_couverture_aaa is
  'États de couverture par l''Association d''assurance accident. Trois états et non un booléen : « on ne sait pas » n''est pas « non », et c''est justement l''état le plus fréquent tant que le Code de la sécurité sociale n''est pas au corpus.';
comment on column ref_couverture_aaa.code is 'Identifiant court porté par le segment.';
comment on column ref_couverture_aaa.libelle is 'Intitulé lisible.';
comment on column ref_couverture_aaa.description is 'Ce que l''état signifie, et sur quoi il se fonde.';
comment on column ref_couverture_aaa.ordre is 'Ordre d''affichage.';
comment on column ref_couverture_aaa.debut_validite is 'Début de validité, borne incluse.';
comment on column ref_couverture_aaa.fin_validite is 'Fin de validité, borne exclue.';
comment on column ref_couverture_aaa.note is 'Précision libre.';

insert into ref_couverture_aaa (code, libelle, description, ordre) values
  ('couvert', 'Couvert',
   'Temps de travail effectif exécuté pour l''employeur, sous sa subordination.', 1),
  ('non_couvert', 'Hors couverture',
   'Temps dont il est établi qu''il échappe à la couverture. Aucun segment ne reçoit cet état par défaut : il se constate, il ne se présume pas.', 2),
  ('a_determiner', 'À déterminer',
   'Qualification non tranchée. Le trajet domicile-travail, la pause repas prise hors de l''entreprise et le déplacement entre deux sites relèvent du Code de la sécurité sociale, qui ne figure pas au corpus documentaire du projet. Tant que la source manque, l''état reste celui-ci — un trou déclaré vaut mieux qu''une qualification inventée.', 3);

insert into ref_classe_paie (code, libelle, famille, remunere, description, ordre) values
  ('normal', 'Heure normale', 'travail', true,
   'Temps de travail effectif dans les limites de la durée normale.', 1),
  ('heure_sup', 'Heure supplémentaire', 'travail', true,
   'Temps de travail au-delà des limites journalière ou hebdomadaire. La qualification se constate sur la période de référence, jamais sur le seul créneau : c''est pourquoi aucun segment ne naît avec cette classe.', 2),
  ('astreinte', 'Astreinte', 'travail', true,
   'Période où le salarié se tient à disposition sans prestation effective.', 3),
  ('pause_repas', 'Pause repas', 'interruption', false,
   'Interruption pour le repas. N''entre pas dans le temps de travail effectif.', 10),
  ('pause_courte', 'Pause courte', 'interruption', false,
   'Interruption brève. Son caractère rémunéré dépend de la convention collective.', 11),
  ('trajet_domicile', 'Trajet domicile-travail', 'deplacement', false,
   'Déplacement entre le domicile et le lieu de travail. N''est pas du temps de travail effectif.', 20),
  ('trajet_inter_sites', 'Trajet entre deux sites', 'deplacement', true,
   'Déplacement d''un lieu d''exécution à un autre au cours de la journée, sur instruction de l''employeur.', 21),
  ('trajet_mission', 'Déplacement en mission', 'deplacement', true,
   'Déplacement professionnel hors du lieu habituel.', 22);

-- ------------------------------------------------------------- les segments
create table segments_temps (
  id               uuid primary key default gen_random_uuid(),
  societe_id       uuid not null references societes(id) on delete cascade,
  salarie_id       uuid not null references salaries(id) on delete cascade,
  creneau_id       uuid references creneaux(id) on delete cascade,
  releve_temps_id  uuid references releves_temps(id) on delete cascade,
  site_client_id   uuid references sites_client(id),
  debut_le         timestamptz not null,
  fin_le           timestamptz not null,
  minutes          integer generated always as
                     (ceil(extract(epoch from (fin_le - debut_le)) / 60)::integer) stored,
  classe_paie      text not null references ref_classe_paie(code),
  couverture_aaa   text not null references ref_couverture_aaa(code) default 'a_determiner',
  est_nuit         boolean not null default false,
  est_dimanche     boolean not null default false,
  est_ferie        boolean not null default false,
  origine          text not null default 'planifie',
  note             text,
  cree_le          timestamptz not null default now(),

  constraint segment_non_vide check (fin_le > debut_le),
  constraint segment_origine_connue check (origine in ('planifie', 'constate')),
  -- Un salarié n'est qu'à un endroit à la fois. Le planifié et le constaté se
  -- superposent volontairement : on compare l'un à l'autre.
  constraint segment_sans_recouvrement exclude using gist (
    salarie_id with =,
    origine with =,
    tstzrange(debut_le, fin_le) with &&
  )
);

comment on table segments_temps is
  'Segment de temps homogène : une plage sur laquelle la classe de paie, les qualifications de nuit, dimanche et jour férié, et le lieu ne changent pas. Remplace les totaux journaliers de releves_temps pour tout ce qui demande de savoir non pas combien, mais quand.';
comment on column segments_temps.id is 'Identifiant du segment.';
comment on column segments_temps.societe_id is 'Société employeuse. Clé d''isolation.';
comment on column segments_temps.salarie_id is 'Salarié auquel le segment se rapporte.';
comment on column segments_temps.creneau_id is 'Vacation planifiée dont ce segment est issu, s''il vient du planning.';
comment on column segments_temps.releve_temps_id is 'Relevé de temps dont ce segment est issu, s''il vient du constat.';
comment on column segments_temps.site_client_id is 'Lieu d''exécution, lorsque le segment ne se déroule pas au siège.';
comment on column segments_temps.debut_le is 'Début du segment. Horodatage avec fuseau : une vacation de nuit franchit minuit, et un changement d''heure ne doit pas décaler le décompte.';
comment on column segments_temps.fin_le is 'Fin du segment, borne exclue.';
comment on column segments_temps.minutes is 'Durée en minutes, calculée. Arrondie au supérieur : une minute entamée est due.';
comment on column segments_temps.classe_paie is 'Nature du temps — voir ref_classe_paie.';
comment on column segments_temps.couverture_aaa is 'Le salarié est-il sous la couverture de l''assurance accident pendant ce segment ? Voir ref_couverture_aaa.';
comment on column segments_temps.est_nuit is 'Le segment tombe dans la fenêtre de nuit du référentiel (H_NUIT à H_MATIN).';
comment on column segments_temps.est_dimanche is 'Le segment tombe un dimanche.';
comment on column segments_temps.est_ferie is 'Le segment tombe un jour férié légal. Cumulable avec est_dimanche : l''art. L. 232-7, par. (3) commande le cumul des indemnités.';
comment on column segments_temps.origine is 'planifie : issu du planning. constate : issu du relevé réel. Les deux coexistent pour être comparés.';
comment on column segments_temps.note is 'Précision libre.';
comment on column segments_temps.cree_le is 'Horodatage de création.';

create index idx_segments_salarie_periode on segments_temps (salarie_id, debut_le);
create index idx_segments_societe_periode on segments_temps (societe_id, debut_le);
create index idx_segments_creneau on segments_temps (creneau_id) where creneau_id is not null;

-- ------------------------------------------------------------------- RLS
alter table ref_classe_paie enable row level security;
alter table ref_couverture_aaa enable row level security;
alter table segments_temps enable row level security;

create policy classe_paie_lecture on ref_classe_paie for select to authenticated using (true);
create policy couverture_aaa_lecture on ref_couverture_aaa for select to authenticated using (true);

create policy segments_lecture on segments_temps for select
  using (has_company_access(societe_id) or is_self_employee(salarie_id));
create policy segments_ecriture_ins on segments_temps for insert
  with check (can_manage_company(societe_id));
create policy segments_ecriture_upd on segments_temps for update
  using (can_manage_company(societe_id));
create policy segments_ecriture_del on segments_temps for delete
  using (can_manage_company(societe_id));
