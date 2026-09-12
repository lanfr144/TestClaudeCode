-- 61 — Les contraintes CHECK de liste deviennent des tables de domaine
--
-- Huit colonnes portaient leur ensemble de valeurs dans une contrainte `check`.
-- Ajouter une valeur exigeait une migration ; en retirer une rendait illisibles
-- les lignes qui la portaient encore. Elles pointent désormais vers une table de
-- référence datée : on ajoute par `insert`, on retire en datant, et l'historique
-- reste lisible.
--
-- Les colonnes de ces nouvelles tables sont en français — première brique du
-- passage au français, posée sur du neuf plutôt que sur de l'existant.
--
-- Convention temporelle : `debut_validite` au 1er janvier 1970, `fin_validite`
-- NOT NULL au 31 décembre 2037. Une borne haute non nulle supprime les
-- `fin_validite is null or fin_validite > date` disséminés dans le moteur.

create table if not exists ref_statut_verification_adresse (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rsva_periode check (fin_validite > debut_validite));
insert into ref_statut_verification_adresse (code, libelle, ordre, note) values
  ('ok',      'Adresse située dans une zone couverte', 1, null),
  ('outside', 'Adresse hors des zones couvertes', 2, 'Refusée à l''écriture.'),
  ('unknown', 'Zone indéterminée', 3, 'Ni confirmée ni écartée : à reprendre.')
on conflict (code) do update set libelle = excluded.libelle, ordre = excluded.ordre;

create table if not exists ref_unite_essai (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rue_periode check (fin_validite > debut_validite));
insert into ref_unite_essai (code, libelle, ordre, note) values
  ('weeks',  'Semaines', 1, 'Les bornes légales diffèrent selon l''unité.'),
  ('months', 'Mois',     2, null)
on conflict (code) do update set libelle = excluded.libelle;

create table if not exists ref_action_acces (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint raa_periode check (fin_validite > debut_validite));
insert into ref_action_acces (code, libelle, ordre, note) values
  ('READ',     'Consultation', 1, null),
  ('DECRYPT',  'Déchiffrement d''une donnée sensible', 2, null),
  ('EXPORT',   'Extraction', 3, null),
  ('DOWNLOAD', 'Téléchargement ou transmission à un tiers', 4, null)
on conflict (code) do update set libelle = excluded.libelle;

create table if not exists ref_lien_enfant (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rle_periode check (fin_validite > debut_validite));
insert into ref_lien_enfant (code, libelle, ordre) values
  ('child',     'Enfant', 1),
  ('adopted',   'Enfant adopté', 2),
  ('foster',    'Enfant accueilli', 3),
  ('stepchild', 'Enfant du conjoint', 4)
on conflict (code) do update set libelle = excluded.libelle;

create table if not exists ref_sujet_export (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rse_periode check (fin_validite > debut_validite));
insert into ref_sujet_export (code, libelle, ordre) values
  ('employee',     'Dossier d''un salarié', 1),
  ('company',      'Dossier d''une société', 2),
  ('organization', 'Fiduciaire entière', 3),
  ('referential',  'Référentiel légal', 4)
on conflict (code) do update set libelle = excluded.libelle;

create table if not exists ref_statut_heures_sup (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rshs_periode check (fin_validite > debut_validite));
insert into ref_statut_heures_sup (code, libelle, ordre, note) values
  ('requested',   'Demandée', 1, null),
  ('hr_approved', 'Validée par les RH', 2, 'Ne suffit pas : l''acceptation du salarié reste requise.'),
  ('approved',    'Accord mutuel acquis', 3, null),
  ('rejected',    'Refusée', 4, null),
  ('cancelled',   'Annulée', 5, null)
on conflict (code) do update set libelle = excluded.libelle, note = excluded.note;

create table if not exists ref_compensation_heures_sup (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rchs_periode check (fin_validite > debut_validite));
insert into ref_compensation_heures_sup (code, libelle, ordre) values
  ('money', 'Paiement majoré', 1),
  ('rest',  'Repos compensateur', 2)
on conflict (code) do update set libelle = excluded.libelle;

create table if not exists ref_nature_prime (
  code text primary key, libelle text not null, ordre smallint not null default 0,
  categorie text not null default 'autre',
  lie_aux_conditions boolean not null default false,
  source_url text,
  debut_validite date not null default date '1970-01-01',
  fin_validite   date not null default date '2037-12-31',
  note text, constraint rnp_periode check (fin_validite > debut_validite));

insert into ref_nature_prime (code, libelle, ordre, categorie, lie_aux_conditions, note) values
  ('participative',    'Prime participative', 1, 'resultat', false, null),
  ('thirteenth_month', 'Treizième mois', 2, 'periodique', false, null),
  ('performance',      'Prime de performance', 3, 'performance', false, null),
  ('seniority',        'Prime d''ancienneté', 4, 'anciennete', false, null),
  ('exceptional',      'Prime exceptionnelle', 5, 'exceptionnel', false, null),
  ('notice_waiver',    'Contrepartie de dispense de préavis', 6, 'rupture', false, null),
  -- Les trois natures qui n'existaient pas, et qui tombaient donc dans « other ».
  ('penibilite',       'Prime de pénibilité', 7, 'conditions_travail', true,
   'Fixée par convention collective, jamais par la loi générale. Le taux et les conditions d''ouverture vivent dans la CCT.'),
  ('insalubrite',      'Prime d''insalubrité', 8, 'conditions_travail', true,
   'Fixée par convention collective. Due au titre des conditions matérielles d''exécution du travail.'),
  ('danger',           'Prime de danger', 9, 'conditions_travail', true,
   'Fixée par convention collective. Due au titre de l''exposition au risque pendant la prestation.'),
  ('other',            'Autre', 99, 'autre', false,
   'À n''utiliser que lorsque aucune nature ne convient — et à signaler si le cas se répète.')
on conflict (code) do update
  set libelle = excluded.libelle, ordre = excluded.ordre, categorie = excluded.categorie,
      lie_aux_conditions = excluded.lie_aux_conditions, note = excluded.note;

comment on table ref_nature_prime is $c$Natures de prime. Les trois natures liées aux conditions matérielles d'exécution du travail — pénibilité, insalubrité, danger — y figurent explicitement : elles tombaient auparavant dans « autre », ce qui interdisait tout calcul. source_url pointe vers la convention collective qui les fixe.$c$;
comment on column ref_nature_prime.lie_aux_conditions is $c$Vrai si la prime dépend des conditions réelles d'exécution, et non d'une clause constante du contrat. Elle se calcule alors sur les créneaux effectivement travaillés sous ces conditions.$c$;
comment on column ref_nature_prime.source_url is $c$Lien vers la convention collective qui fixe le taux et les conditions. Une prime conventionnelle sans source n'est pas vérifiable.$c$;

do $$
declare t text;
begin
  foreach t in array array['ref_statut_verification_adresse','ref_unite_essai','ref_action_acces',
                           'ref_lien_enfant','ref_sujet_export','ref_statut_heures_sup',
                           'ref_compensation_heures_sup','ref_nature_prime']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists %I on %I', t || '_lecture', t);
    execute format('create policy %I on %I for select to authenticated using (true)',
                   t || '_lecture', t);
    execute format($f$comment on table %I is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.'$f$, t);
  end loop;
end $$;

alter table address_checks     drop constraint address_check_status;
alter table contracts          drop constraint contracts_probation_unit_check;
alter table data_access_log    drop constraint access_action_known;
alter table employee_children  drop constraint employee_children_relationship_check;
alter table export_log         drop constraint export_log_subject_kind_check;
alter table overtime_requests  drop constraint overtime_requests_status_check;
alter table overtime_requests  drop constraint overtime_requests_compensation_check;
alter table premiums           drop constraint premiums_kind_check;

alter table address_checks    add constraint address_checks_statut_ref
  foreign key (status) references ref_statut_verification_adresse (code);
alter table contracts         add constraint contracts_unite_essai_ref
  foreign key (probation_unit) references ref_unite_essai (code);
alter table data_access_log   add constraint data_access_log_action_ref
  foreign key (action) references ref_action_acces (code);
alter table employee_children add constraint employee_children_lien_ref
  foreign key (relationship) references ref_lien_enfant (code);
alter table export_log        add constraint export_log_sujet_ref
  foreign key (subject_kind) references ref_sujet_export (code);
alter table overtime_requests add constraint overtime_requests_statut_ref
  foreign key (status) references ref_statut_heures_sup (code);
alter table overtime_requests add constraint overtime_requests_compensation_ref
  foreign key (compensation) references ref_compensation_heures_sup (code);
alter table premiums          add constraint premiums_nature_ref
  foreign key (kind) references ref_nature_prime (code);
