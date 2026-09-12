-- Schéma LuxRH pour ORACLE, dérivé du catalogue PostgreSQL.
-- Généré par tools/emit_portable_schema.py — ne pas modifier à la main :
-- la base PostgreSQL fait foi, ce fichier la suit.
--
-- Cible : Oracle 26ai. VARCHAR2 en sémantique CHAR (un « é » compte pour
-- un caractère, non pour deux octets). BOOLEAN natif, heures en INTERVAL DAY TO
-- SECOND, énumérations en tables de référence, tableaux et jsonb en CLOB.
-- Les clés étrangères d'auteur pointent vers APP_USERS.

-- ------------------------------------------------------------------
-- TABLES DE RÉFÉRENCE — à la place des types énumérés de PostgreSQL.
-- Chaque valeur porte sa période d'usage : on retire une valeur en la
-- datant, jamais en la supprimant, sinon l'historique devient illisible.
-- ------------------------------------------------------------------

create table "REF_BLOC_CONVENTION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_bloc_convention_pk primary key ("CODE")
);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('salary_grid', 'salary_grid', 1);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('worktime', 'worktime', 2);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('leave', 'leave', 3);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('premiums', 'premiums', 4);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('surcharges', 'surcharges', 5);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('notice_probation', 'notice_probation', 6);
insert into "REF_BLOC_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('custom_holidays', 'custom_holidays', 7);

create table "REF_CATEGORIE_ABSENCE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_categorie_absence_pk primary key ("CODE")
);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('annual_leave', 'annual_leave', 1);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('sick', 'sick', 2);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('extraordinary', 'extraordinary', 3);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('public_holiday', 'public_holiday', 4);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('unpaid', 'unpaid', 5);
insert into "REF_CATEGORIE_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('compensatory', 'compensatory', 6);

create table "REF_CLASSE_IMPOT" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_classe_impot_pk primary key ("CODE")
);
insert into "REF_CLASSE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('1', '1', 1);
insert into "REF_CLASSE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('1a', '1a', 2);
insert into "REF_CLASSE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('2', '2', 3);

create table "REF_ETAPE_DOCUMENT" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_etape_document_pk primary key ("CODE")
);
insert into "REF_ETAPE_DOCUMENT" ("CODE", "LABEL", "SORT_ORDER") values ('pre_hire', 'pre_hire', 1);
insert into "REF_ETAPE_DOCUMENT" ("CODE", "LABEL", "SORT_ORDER") values ('during_contract', 'during_contract', 2);
insert into "REF_ETAPE_DOCUMENT" ("CODE", "LABEL", "SORT_ORDER") values ('end_of_contract', 'end_of_contract', 3);

create table "REF_ETAT_ALERTE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_etat_alerte_pk primary key ("CODE")
);
insert into "REF_ETAT_ALERTE" ("CODE", "LABEL", "SORT_ORDER") values ('open', 'open', 1);
insert into "REF_ETAT_ALERTE" ("CODE", "LABEL", "SORT_ORDER") values ('handled', 'handled', 2);
insert into "REF_ETAT_ALERTE" ("CODE", "LABEL", "SORT_ORDER") values ('dismissed', 'dismissed', 3);

create table "REF_FAMILLE_PARAMETRE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_famille_parametre_pk primary key ("CODE")
);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('social', 'social', 1);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('fiscal', 'fiscal', 2);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('worktime', 'worktime', 3);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('leave', 'leave', 4);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('contract', 'contract', 5);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('effectif', 'effectif', 6);
insert into "REF_FAMILLE_PARAMETRE" ("CODE", "LABEL", "SORT_ORDER") values ('ccss', 'ccss', 7);

create table "REF_GENRE_CONTRAT" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_contrat_pk primary key ("CODE")
);
insert into "REF_GENRE_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('cdi', 'cdi', 1);
insert into "REF_GENRE_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('cdd', 'cdd', 2);
insert into "REF_GENRE_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('seasonal', 'seasonal', 3);
insert into "REF_GENRE_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('apprenticeship', 'apprenticeship', 4);
insert into "REF_GENRE_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('interim', 'interim', 5);

create table "REF_GENRE_ELEMENT_REMUNERATION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_element_remune_pk primary key ("CODE")
);
insert into "REF_GENRE_ELEMENT_REMUNERATION" ("CODE", "LABEL", "SORT_ORDER") values ('fixed', 'fixed', 1);
insert into "REF_GENRE_ELEMENT_REMUNERATION" ("CODE", "LABEL", "SORT_ORDER") values ('variable', 'variable', 2);
insert into "REF_GENRE_ELEMENT_REMUNERATION" ("CODE", "LABEL", "SORT_ORDER") values ('benefit_in_kind', 'benefit_in_kind', 3);
insert into "REF_GENRE_ELEMENT_REMUNERATION" ("CODE", "LABEL", "SORT_ORDER") values ('premium', 'premium', 4);
insert into "REF_GENRE_ELEMENT_REMUNERATION" ("CODE", "LABEL", "SORT_ORDER") values ('expense', 'expense', 5);

create table "REF_GENRE_ORGANISATION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_organisation_pk primary key ("CODE")
);
insert into "REF_GENRE_ORGANISATION" ("CODE", "LABEL", "SORT_ORDER") values ('fiduciary', 'fiduciary', 1);
insert into "REF_GENRE_ORGANISATION" ("CODE", "LABEL", "SORT_ORDER") values ('company', 'company', 2);

create table "REF_GENRE_QUALIFICATION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_qualification_pk primary key ("CODE")
);
insert into "REF_GENRE_QUALIFICATION" ("CODE", "LABEL", "SORT_ORDER") values ('qualified', 'qualified', 1);
insert into "REF_GENRE_QUALIFICATION" ("CODE", "LABEL", "SORT_ORDER") values ('unqualified', 'unqualified', 2);

create table "REF_GENRE_RESIDENCE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_residence_pk primary key ("CODE")
);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('resident', 'resident', 1);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_fr', 'frontalier_fr', 2);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_be', 'frontalier_be', 3);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_de', 'frontalier_de', 4);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_fra', 'frontalier_fra', 5);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_bel', 'frontalier_bel', 6);
insert into "REF_GENRE_RESIDENCE" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_deu', 'frontalier_deu', 7);

create table "REF_GENRE_SEVERITE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_severite_pk primary key ("CODE")
);
insert into "REF_GENRE_SEVERITE" ("CODE", "LABEL", "SORT_ORDER") values ('blocking', 'blocking', 1);
insert into "REF_GENRE_SEVERITE" ("CODE", "LABEL", "SORT_ORDER") values ('warning', 'warning', 2);
insert into "REF_GENRE_SEVERITE" ("CODE", "LABEL", "SORT_ORDER") values ('info', 'info', 3);
insert into "REF_GENRE_SEVERITE" ("CODE", "LABEL", "SORT_ORDER") values ('problem', 'problem', 4);

create table "REF_GENRE_SEXE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_sexe_pk primary key ("CODE")
);
insert into "REF_GENRE_SEXE" ("CODE", "LABEL", "SORT_ORDER") values ('male', 'male', 1);
insert into "REF_GENRE_SEXE" ("CODE", "LABEL", "SORT_ORDER") values ('female', 'female', 2);
insert into "REF_GENRE_SEXE" ("CODE", "LABEL", "SORT_ORDER") values ('unspecified', 'unspecified', 3);

create table "REF_GENRE_STATUT_SALARIE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_genre_statut_salarie_pk primary key ("CODE")
);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('pregnancy', 'pregnancy', 1);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('maternity_leave', 'maternity_leave', 2);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('breastfeeding', 'breastfeeding', 3);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('parental_leave', 'parental_leave', 4);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('delegate', 'delegate', 5);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('safety_delegate', 'safety_delegate', 6);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('equality_delegate', 'equality_delegate', 7);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('reemployment_bonus', 'reemployment_bonus', 8);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('company_manager', 'company_manager', 9);
insert into "REF_GENRE_STATUT_SALARIE" ("CODE", "LABEL", "SORT_ORDER") values ('protected_other', 'protected_other', 10);

create table "REF_PERIODICITE_IMPOT" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_periodicite_impot_pk primary key ("CODE")
);
insert into "REF_PERIODICITE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('monthly', 'monthly', 1);
insert into "REF_PERIODICITE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('daily', 'daily', 2);
insert into "REF_PERIODICITE_IMPOT" ("CODE", "LABEL", "SORT_ORDER") values ('annual', 'annual', 3);

create table "REF_PORTEE_CONVENTION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_portee_convention_pk primary key ("CODE")
);
insert into "REF_PORTEE_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('secteur', 'secteur', 1);
insert into "REF_PORTEE_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('harassment', 'harassment', 2);
insert into "REF_PORTEE_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('employee_category', 'employee_category', 3);
insert into "REF_PORTEE_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('department', 'department', 4);
insert into "REF_PORTEE_CONVENTION" ("CODE", "LABEL", "SORT_ORDER") values ('company', 'company', 5);

create table "REF_ROLE_APPLICATION" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_role_application_pk primary key ("CODE")
);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('fiduciary_admin', 'fiduciary_admin', 1);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('manager', 'manager', 2);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('service_manager', 'service_manager', 3);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('employee', 'employee', 4);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('medecine_travail', 'medecine_travail', 5);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('rh_urgence', 'rh_urgence', 6);
insert into "REF_ROLE_APPLICATION" ("CODE", "LABEL", "SORT_ORDER") values ('dispatching', 'dispatching', 7);

create table "REF_STATUT_ABSENCE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_statut_absence_pk primary key ("CODE")
);
insert into "REF_STATUT_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('pending', 'pending', 1);
insert into "REF_STATUT_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('approved', 'approved', 2);
insert into "REF_STATUT_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('refused', 'refused', 3);
insert into "REF_STATUT_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('cancelled', 'cancelled', 4);
insert into "REF_STATUT_ABSENCE" ("CODE", "LABEL", "SORT_ORDER") values ('proposed', 'proposed', 5);

create table "REF_STATUT_CONTRAT" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_statut_contrat_pk primary key ("CODE")
);
insert into "REF_STATUT_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('draft', 'draft', 1);
insert into "REF_STATUT_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('active', 'active', 2);
insert into "REF_STATUT_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('ended', 'ended', 3);
insert into "REF_STATUT_CONTRAT" ("CODE", "LABEL", "SORT_ORDER") values ('cancelled', 'cancelled', 4);

create table "REF_STATUT_PLANNING" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_statut_planning_pk primary key ("CODE")
);
insert into "REF_STATUT_PLANNING" ("CODE", "LABEL", "SORT_ORDER") values ('draft', 'draft', 1);
insert into "REF_STATUT_PLANNING" ("CODE", "LABEL", "SORT_ORDER") values ('publie', 'publie', 2);


create table "ABSENCES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "TYPE_ABSENCE_ID" VARCHAR2(36 CHAR) not null,
  "DATE_DEBUT" DATE not null,
  "DATE_FIN" DATE not null,
  "NOMBRE_JOURS" NUMBER(5,2) default 0 not null,
  "STATUT" VARCHAR2(9 CHAR) default 'pending' not null,
  "COMMENTAIRE" VARCHAR2(4000 CHAR),
  "CERTIFICAT_RECU" BOOLEAN default 0 not null,
  "CERTIFICAT_RECU_LE" DATE,
  "CERTIFICAT_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "DEMANDE_PAR" VARCHAR2(36 CHAR),
  "DECIDE_PAR" VARCHAR2(36 CHAR),
  "DECIDE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "NOTE_DECISION" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DECLARE_PAR_SALARIE" BOOLEAN default 0 not null,
  "CERTIFICAT_DEPOSE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "CERTIFICAT_ORIGINAL_RECU" BOOLEAN default 0 not null,
  "CERTIFICAT_ORIGINAL_RECU_LE" DATE,
  "ENFANT_ID" VARCHAR2(36 CHAR),
  "ABSENCE_PARENTE_ID" VARCHAR2(36 CHAR),
  "PROPOSEE_PAR" VARCHAR2(4000 CHAR),
  "RANG_PROPOSITION" NUMBER(5) default 0 not null,
  constraint absences_pkey primary key ("ID")
);

create table "ADRESSES_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "TYPE_ADRESSE" VARCHAR2(4000 CHAR) not null,
  "LIGNE" VARCHAR2(4000 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "LOCALITE" VARCHAR2(4000 CHAR),
  "PAYS" CHAR(3 CHAR) default 'LUX' not null,
  "LATITUDE" NUMBER(9,6),
  "LONGITUDE" NUMBER(9,6),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "ORIGINE" VARCHAR2(4000 CHAR) default 'saisie' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREE_PAR" VARCHAR2(36 CHAR),
  "SUPPRIME_LE" TIMESTAMP(6) WITH TIME ZONE,
  "SUPPRIME_PAR" VARCHAR2(36 CHAR),
  constraint adresses_salarie_pkey primary key ("ID")
);

create table "AGENCES_INTERIM" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "MATRICULE_CCSS" VARCHAR2(4000 CHAR),
  "NUMERO_RCS" VARCHAR2(4000 CHAR),
  "LIGNE" VARCHAR2(4000 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "LOCALITE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint agences_interim_pkey primary key ("ID")
);

create table "ALERTES_CONFORMITE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR),
  "CODE_REGLE" VARCHAR2(4000 CHAR) not null,
  "TITRE" VARCHAR2(4000 CHAR) not null,
  "DETAIL" VARCHAR2(4000 CHAR) not null,
  "CONSEQUENCE" VARCHAR2(4000 CHAR),
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "SEVERITE" VARCHAR2(8 CHAR) not null,
  "DATE_ECHEANCE" DATE,
  "ETAT" VARCHAR2(9 CHAR) default 'open' not null,
  "TRAITE_PAR" VARCHAR2(36 CHAR),
  "TRAITE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "NOTE_TRAITEMENT" VARCHAR2(4000 CHAR),
  "VU_LA_PREMIERE_FOIS_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint alertes_conformite_pkey primary key ("ID")
);

create table "ATTRIBUTIONS_TITRES_REPAS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "DEBUT_PERIODE" DATE not null,
  "FIN_PERIODE" DATE not null,
  "NOMBRE_TITRES" NUMBER(10) not null,
  "VALEUR_FACIALE" NUMBER(6,2) not null,
  "PART_SALARIALE" NUMBER(6,2) default 0 not null,
  "ATTRIBUE_LE" DATE,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint attributions_titres_repas_pk primary key ("ID")
);

create table "AVENANTS_CONTRAT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "DATE_EFFET" DATE not null,
  "MOTIF" VARCHAR2(4000 CHAR) not null,
  "MODIFICATIONS" CLOB not null constraint avenants_contrat_modifications_json check ("MODIFICATIONS" is json),
  "CREE_PAR" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint avenants_contrat_pkey primary key ("ID")
);

create table "CATEGORIES_SANCTION" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "RANG" NUMBER(5) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR) not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  constraint categories_sanction_pkey primary key ("CODE")
);

create table "CCT_REGLE_PRIME" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR) not null,
  "CONDITION_CODE" VARCHAR2(4000 CHAR) not null,
  "NATURE_PRIME" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "TAUX_PCT" NUMBER(7,4),
  "MONTANT" NUMBER(10,2),
  "ASSIETTE" VARCHAR2(4000 CHAR),
  "UNITE" VARCHAR2(4000 CHAR) not null,
  "SEUIL_MINUTES" NUMBER(10) default 0 not null,
  "CATEGORIE_VISEE" VARCHAR2(4000 CHAR),
  "ARTICLE" VARCHAR2(4000 CHAR),
  "URL_SOURCE" VARCHAR2(4000 CHAR) not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint cct_regle_prime_pkey primary key ("ID")
);

create table "COMPTES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "IDENTIFIANT" VARCHAR2(4000 CHAR) not null,
  "COURRIEL" VARCHAR2(4000 CHAR) not null,
  "NOM_COMPLET" VARCHAR2(4000 CHAR),
  "EMPREINTE_MOT_DE_PASSE" VARCHAR2(4000 CHAR),
  "EST_ADMIN" BOOLEAN default 0 not null,
  "COMPTE_AUTH_ID" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREE_PAR" VARCHAR2(36 CHAR),
  "MODIFIE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "MODIFIE_PAR" VARCHAR2(36 CHAR),
  "SUPPRIME_LE" TIMESTAMP(6) WITH TIME ZONE,
  "SUPPRIME_PAR" VARCHAR2(36 CHAR),
  constraint comptes_pkey primary key ("ID")
);

create table "CONTRATS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "GENRE" VARCHAR2(14 CHAR) not null,
  "STATUT" VARCHAR2(9 CHAR) default 'draft' not null,
  "INTITULE_POSTE" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION_POSTE" VARCHAR2(4000 CHAR),
  "LIEU_TRAVAIL" VARCHAR2(4000 CHAR),
  "CATEGORIE" VARCHAR2(4000 CHAR),
  "DATE_DEBUT" DATE not null,
  "DATE_FIN" DATE default '2037-12-31' not null,
  "MOTIF_CDD" VARCHAR2(4000 CHAR),
  "NOMBRE_RENOUVELLEMENTS" NUMBER(5) default 0 not null,
  "CONTRAT_PRECEDENT_ID" VARCHAR2(36 CHAR),
  "BRUT_MENSUEL" NUMBER(10,2) not null,
  "INDICE_REFERENCE" NUMBER(8,2),
  "HEURES_HEBDOMADAIRES" NUMBER(5,2) default 40 not null,
  "JOURS_PAR_SEMAINE" NUMBER(3,1) default 5 not null,
  "REPARTITION_TRAVAIL" VARCHAR2(4000 CHAR),
  "PERIODE_REFERENCE_MOIS" NUMBER(5) default 4 not null,
  "TRAVAIL_NUIT" BOOLEAN default 0 not null,
  "JOURS_CONGE_ANNUEL" NUMBER(5,2),
  "PAUSE_MINUTES" NUMBER(5),
  "CLAUSE_NON_CONCURRENCE" BOOLEAN default 0 not null,
  "CLAUSE_EXCLUSIVITE" BOOLEAN default 0 not null,
  "DUREE_ESSAI" NUMBER(10),
  "UNITE_ESSAI" VARCHAR2(4000 CHAR),
  "VERSION" NUMBER(5) default 1 not null,
  "SIGNE_LE" DATE,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "EST_TEMPS_PARTIEL" BOOLEAN default 0 not null,
  "NIVEAU_APPRENTISSAGE" VARCHAR2(4000 CHAR),
  "ANNEE_APPRENTISSAGE" NUMBER(5),
  "LIBELLE_SAISON" VARCHAR2(4000 CHAR),
  "AGENCE_INTERIM_ID" VARCHAR2(36 CHAR),
  "NOM_SOCIETE_UTILISATEUR" VARCHAR2(4000 CHAR),
  "MOTIF_MISSION" VARCHAR2(4000 CHAR),
  constraint contrats_pkey primary key ("ID")
);

create table "CONTROLES_ADRESSE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ENTITE_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITE_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR),
  "PAYS" CHAR(3 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "STATUT" VARCHAR2(4000 CHAR) not null,
  "CODE_ZONE" VARCHAR2(4000 CHAR),
  "MESSAGE" VARCHAR2(4000 CHAR),
  "CONTROLE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint controles_adresse_pkey primary key ("ID"),
  constraint address_check_unique unique ("ENTITE_TABLE", "ENTITE_ID")
);

create table "CONVENTIONS_COLLECTIVES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR),
  "CODE" VARCHAR2(4000 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "SECTEUR" VARCHAR2(4000 CHAR) not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "ACTIF" BOOLEAN default 0 not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "PORTEE" VARCHAR2(17 CHAR) default 'secteur' not null,
  "REMPLACE_ID" VARCHAR2(36 CHAR),
  "CATEGORIE_PROFESSIONNELLE" VARCHAR2(4000 CHAR),
  constraint conventions_collectives_pkey primary key ("ID")
);

create table "CONVENTIONS_DE_LA_SOCIETE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR) not null,
  "SERVICE_ID" VARCHAR2(36 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint conventions_de_la_societe_pk primary key ("ID")
);

create table "CONVENTIONS_DU_CONTRAT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR) not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR) not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint conventions_du_contrat_pkey primary key ("ID")
);

create table "CREDITS_IMPOT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "CLASSES_VISEES" CLOB,
  "REVENU_MIN" NUMBER(12,2),
  "REVENU_MAX" NUMBER(12,2),
  "MONTANT_MENSUEL" NUMBER(10,2),
  "PRORATISE_SUR_HEURES" BOOLEAN default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'ACD' not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint credits_impot_pkey primary key ("ID")
);

create table "CRENEAU_CONDITION" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "CRENEAU_ID" VARCHAR2(36 CHAR),
  "RELEVE_TEMPS_ID" VARCHAR2(36 CHAR),
  "SITE_CLIENT_ID" VARCHAR2(36 CHAR),
  "CONDITION_CODE" VARCHAR2(4000 CHAR) not null,
  "DATE_PRESTATION" DATE not null,
  "HEURE_DEBUT" INTERVAL DAY(0) TO SECOND(0) not null,
  "HEURE_FIN" INTERVAL DAY(0) TO SECOND(0) not null,
  "MINUTES" NUMBER(10),
  "CONSTATE_PAR" VARCHAR2(36 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SUPPRIME_LE" TIMESTAMP(6) WITH TIME ZONE,
  "SUPPRIME_PAR" VARCHAR2(36 CHAR),
  constraint creneau_condition_pkey primary key ("ID")
);

create table "CRENEAUX" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "PLANNING_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "DATE_CRENEAU" DATE not null,
  "HEURE_DEBUT" INTERVAL DAY(0) TO SECOND(0) not null,
  "HEURE_FIN" INTERVAL DAY(0) TO SECOND(0) not null,
  "PAUSE_MINUTES" NUMBER(5) default 0 not null,
  "LIBELLE" VARCHAR2(4000 CHAR),
  "MODELE_ID" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SITE_CLIENT_ID" VARCHAR2(36 CHAR),
  constraint creneaux_pkey primary key ("ID")
);

create table "DEMANDES_HEURES_SUP" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "PLANNING_ID" VARCHAR2(36 CHAR),
  "DEBUT_PERIODE" DATE not null,
  "FIN_PERIODE" DATE not null,
  "HEURES" NUMBER(6,2) not null,
  "MOTIF" VARCHAR2(4000 CHAR) not null,
  "STATUT" VARCHAR2(4000 CHAR) default 'requested' not null,
  "DEMANDE_PAR" VARCHAR2(36 CHAR),
  "DEMANDE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "VALIDE_RH_PAR" VARCHAR2(36 CHAR),
  "VALIDE_RH_LE" TIMESTAMP(6) WITH TIME ZONE,
  "ACCEPTE_PAR_SALARIE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "MOTIF_REFUS" VARCHAR2(4000 CHAR),
  "COMPENSATION" VARCHAR2(4000 CHAR) default 'money' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint demandes_heures_sup_pkey primary key ("ID")
);

create table "DISTANCES_TRAJET" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "REFERENCE_ORIGINE" VARCHAR2(4000 CHAR) not null,
  "REFERENCE_DESTINATION" VARCHAR2(4000 CHAR) not null,
  "DISTANCE_KM" NUMBER(8,2) not null,
  "DUREE_MINUTES" NUMBER(10),
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "CALCULE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CALCULE_PAR" VARCHAR2(36 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint distances_trajet_pkey primary key ("ID"),
  constraint travel_distance_unique unique ("REFERENCE_ORIGINE", "REFERENCE_DESTINATION")
);

create table "DOCUMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR),
  "ENTITE_TABLE" VARCHAR2(4000 CHAR),
  "ENTITE_ID" VARCHAR2(36 CHAR),
  "NOM" VARCHAR2(4000 CHAR) not null,
  "CHEMIN_STOCKAGE" VARCHAR2(4000 CHAR) not null,
  "TYPE_MIME" VARCHAR2(4000 CHAR),
  "TAILLE_OCTETS" NUMBER(19),
  "CONSERVATION_JUSQUAU" DATE,
  "SENSIBLE" BOOLEAN default 0 not null,
  "DEPOSE_PAR" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "TYPE_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "EMIS_LE" DATE,
  "EXPIRE_LE" DATE,
  "REMIS_LE" DATE,
  constraint documents_pkey primary key ("ID")
);

create table "DONNEES_FINANCIERES_SOCIETE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "EXERCICE" NUMBER(5) not null,
  "RESULTAT" NUMBER(14,2),
  "CHIFFRE_AFFAIRES" NUMBER(14,2),
  "SOURCE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint donnees_financieres_societe_ primary key ("ID"),
  constraint donnees_financieres_societe_ unique ("SOCIETE_ID", "EXERCICE")
);

create table "DROITS_ABSENCE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "TYPE_ABSENCE_ID" VARCHAR2(36 CHAR) not null,
  "JOURS" NUMBER(5,1),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE_FREQUENCE" VARCHAR2(4000 CHAR),
  "PLAFOND_CARRIERE_JOURS" NUMBER(6,1),
  "JOURS_BLOC" NUMBER(5,1),
  "DUREE_MOIS" NUMBER(10),
  "DEGRE_PARENTE" NUMBER(5),
  "PIECE_EXIGEE" BOOLEAN default 0 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint droits_absence_pkey primary key ("ID")
);

create table "ELEMENTS_REMUNERATION" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "GENRE" VARCHAR2(15 CHAR) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "MONTANT" NUMBER(10,2),
  "TAUX_PCT" NUMBER(6,3),
  "ASSIETTE" VARCHAR2(4000 CHAR),
  "PERIODICITE" VARCHAR2(4000 CHAR) default 'monthly' not null,
  "DANS_ASSIETTE_SALAIRE" BOOLEAN default 0 not null,
  "IMPOSABLE" BOOLEAN default 1 not null,
  "COTISABLE" BOOLEAN default 1 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "TYPE_AVANTAGE_ID" VARCHAR2(36 CHAR),
  constraint elements_remuneration_pkey primary key ("ID")
);

create table "ENFANTS_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "PRENOM" VARCHAR2(4000 CHAR),
  "NOM" VARCHAR2(4000 CHAR),
  "SEXE" VARCHAR2(11 CHAR),
  "DATE_NAISSANCE" DATE not null,
  "LIEN_PARENTE" VARCHAR2(4000 CHAR) default 'child' not null,
  "A_CHARGE" BOOLEAN default 1 not null,
  "REFUS_PARTAGE" BOOLEAN default 0 not null,
  "DATE_ADOPTION" DATE,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "REFUS_PHOTOS_EVENEMENTS" BOOLEAN default 0 not null,
  "INVITATION_EVENEMENTS" BOOLEAN default 0 not null,
  "EN_SITUATION_HANDICAP" BOOLEAN default 0 not null,
  "TAUX_HANDICAP_PCT" NUMBER(5,2),
  constraint enfants_salarie_pkey primary key ("ID")
);

create table "FICHE_SANTE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR),
  "ENFANT_ID" VARCHAR2(36 CHAR),
  "ALLERGIES" VARCHAR2(4000 CHAR),
  "PATHOLOGIES" VARCHAR2(4000 CHAR),
  "MEDECIN_TRAITANT" VARCHAR2(4000 CHAR),
  "MEDECIN_TELEPHONE" VARCHAR2(4000 CHAR),
  "GROUPE_SANGUIN" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "MAJ_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "MAJ_PAR" VARCHAR2(36 CHAR),
  "SUPPRIME_LE" TIMESTAMP(6) WITH TIME ZONE,
  "SUPPRIME_PAR" VARCHAR2(36 CHAR),
  constraint fiche_sante_pkey primary key ("ID"),
  constraint fs_une_par_personne unique ("SALARIE_ID", "ENFANT_ID")
);

create table "FICHES_RETENUE_IMPOT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "CLASSE_IMPOT" VARCHAR2(8 CHAR) not null,
  "TAUX" NUMBER(6,4),
  "INDEMNITE_MENSUELLE" NUMBER(10,2) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "CREDITS" CLOB default '[]' not null constraint fiches_retenue_impot_credits_json check ("CREDITS" is json),
  "DISTANCE_DOMICILE_KM" NUMBER(6,1),
  "FRAIS_PROFESSIONNELS_MENSUELS" NUMBER(10,2),
  "AUTRES_DEDUCTIONS_MENSUELLES" NUMBER(10,2) default 0 not null,
  "REFERENCE_CARTE" VARCHAR2(4000 CHAR),
  "EMIS_LE" DATE,
  constraint fiches_retenue_impot_pkey primary key ("ID")
);

create table "GRILLES_SALAIRES_CONVENTION" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR) not null,
  "CATEGORIE" VARCHAR2(4000 CHAR) not null,
  "ANCIENNETE_DE_ANNEES" NUMBER(4,1) default 0 not null,
  "ANCIENNETE_A_ANNEES" NUMBER(4,1),
  "MONTANT_MENSUEL" NUMBER(10,2) not null,
  "INDICE_REFERENCE" NUMBER(8,2),
  constraint grilles_salaires_convention_ primary key ("ID")
);

create table "HANDICAPS_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "TAUX_PCT" NUMBER(5,2) not null,
  "RECONNU_LE" DATE,
  "AUTORITE" VARCHAR2(4000 CHAR),
  "JOURS_CONGE_SUPPLEMENTAIRES_FORCES" NUMBER(4,1),
  "PIECE_JUSTIFICATIVE_ID" VARCHAR2(36 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint handicaps_salarie_pkey primary key ("ID")
);

create table "JOURNAL_ACCES" (
  "ID" NUMBER(19) not null,
  "SURVENU_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "AUTEUR_ID" VARCHAR2(36 CHAR),
  "AUTEUR_LIBELLE" VARCHAR2(4000 CHAR),
  "SOCIETE_ID" VARCHAR2(36 CHAR),
  "SALARIE_CONCERNE_ID" VARCHAR2(36 CHAR),
  "ENTITE_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITE_ID" VARCHAR2(36 CHAR),
  "ACTION" VARCHAR2(4000 CHAR) not null,
  "PORTEE" VARCHAR2(4000 CHAR),
  "NOMBRE_LIGNES" NUMBER(10),
  "IP_SOURCE" VARCHAR2(4000 CHAR),
  "AGENT_CLIENT" VARCHAR2(4000 CHAR),
  "IDENTIFIANT_REQUETE" VARCHAR2(4000 CHAR),
  "EST_AUTONOME" BOOLEAN default 0 not null,
  constraint journal_acces_pkey primary key ("ID")
);

create table "JOURNAL_ECRITURES" (
  "ID" NUMBER(19) not null,
  "SURVENU_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "AUTEUR_ID" VARCHAR2(36 CHAR),
  "AUTEUR_LIBELLE" VARCHAR2(4000 CHAR),
  "SOCIETE_ID" VARCHAR2(36 CHAR),
  "ENTITE_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITE_ID" VARCHAR2(36 CHAR),
  "ACTION" VARCHAR2(4000 CHAR) not null,
  "ANCIENNE_VALEUR" CLOB constraint journal_ecritures_ancienne_valeur_json check ("ANCIENNE_VALEUR" is json),
  "NOUVELLE_VALEUR" CLOB constraint journal_ecritures_nouvelle_valeur_json check ("NOUVELLE_VALEUR" is json),
  "IP_SOURCE" VARCHAR2(4000 CHAR),
  "AGENT_CLIENT" VARCHAR2(4000 CHAR),
  "IDENTIFIANT_REQUETE" VARCHAR2(4000 CHAR),
  constraint journal_ecritures_pkey primary key ("ID")
);

create table "JOURNAL_EXPORTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR) not null,
  "DEMANDE_PAR" VARCHAR2(36 CHAR),
  "GENRE_OBJET" VARCHAR2(4000 CHAR) not null,
  "OBJET_ID" VARCHAR2(36 CHAR),
  "NOMBRE_LIGNES" NUMBER(10) default 0 not null,
  "TAILLE_OCTETS" NUMBER(10) default 0 not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "IP_SOURCE" VARCHAR2(4000 CHAR),
  "AGENT_CLIENT" VARCHAR2(4000 CHAR),
  "IDENTIFIANT_REQUETE" VARCHAR2(4000 CHAR),
  constraint journal_exports_pkey primary key ("ID")
);

create table "JOURS_FERIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ANNEE" NUMBER(5) not null,
  "DATE_FERIE" DATE not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "EST_MOBILE" BOOLEAN default 0 not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR),
  "RECUPERABLE" BOOLEAN default 0 not null,
  "MOTIF_RECUPERATION" VARCHAR2(4000 CHAR),
  constraint jours_feries_pkey primary key ("ID")
);

create table "MODELES_CRENEAU" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "HEURE_DEBUT" INTERVAL DAY(0) TO SECOND(0) not null,
  "HEURE_FIN" INTERVAL DAY(0) TO SECOND(0) not null,
  "PAUSE_MINUTES" NUMBER(5) default 0 not null,
  "COULEUR" VARCHAR2(4000 CHAR) default '#017E84' not null,
  "SERVICE_ID" VARCHAR2(36 CHAR),
  constraint modeles_creneau_pkey primary key ("ID")
);

create table "ORGANISATIONS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "GENRE" VARCHAR2(9 CHAR) default 'fiduciary' not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint organisations_pkey primary key ("ID")
);

create table "PARAMETRES_ATTENDUS" (
  "CLE_PARAMETRE" VARCHAR2(4000 CHAR) not null,
  "LU_PAR" VARCHAR2(4000 CHAR) not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint parametres_attendus_pkey primary key ("CLE_PARAMETRE")
);

create table "PARAMETRES_LEGAUX" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "FAMILLE" VARCHAR2(8 CHAR) not null,
  "CLE_PARAMETRE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "VALEUR_NUM" NUMBER,
  "VALEUR_TEXTE" VARCHAR2(4000 CHAR),
  "VALEUR_JSON" CLOB constraint parametres_legaux_valeur_json_json check ("VALEUR_JSON" is json),
  "UNITE" VARCHAR2(4000 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "INDICE_REFERENCE" NUMBER(8,2),
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "SAISI_PAR" VARCHAR2(36 CHAR),
  "SAISI_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "VALIDE_PAR" VARCHAR2(36 CHAR),
  "VALIDE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "DERIVE_DE_CLE" VARCHAR2(4000 CHAR),
  "FACTEUR_DERIVE" NUMBER,
  "TOLERANCE_DERIVATION" NUMBER default 0.02 not null,
  constraint parametres_legaux_pkey primary key ("ID")
);

create table "PERIODES_REFERENCE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SERVICE_ID" VARCHAR2(36 CHAR),
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "DATE_DEBUT" DATE not null,
  "DATE_FIN" DATE not null,
  "MOIS" NUMBER(5) not null,
  constraint periodes_reference_pkey primary key ("ID")
);

create table "PERIODES_TAUX_SOCIETE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "CLASSE_ACTIVITE" VARCHAR2(4000 CHAR),
  "CLASSE_RISQUE_ACCIDENT" VARCHAR2(4000 CHAR),
  "FACTEUR_ACCIDENT" NUMBER(5,2) default 1.00 not null,
  "CLASSE_MUTUALITE" NUMBER(5),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'CCSS' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint periodes_taux_societe_pkey primary key ("ID")
);

create table "PERSONNE_INDICATEUR_SECOURS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR),
  "ENFANT_ID" VARCHAR2(36 CHAR),
  "INDICATEUR" VARCHAR2(4000 CHAR) not null,
  "PRECISION_LIEU" VARCHAR2(4000 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "POSE_PAR" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint personne_indicateur_secours_ primary key ("ID"),
  constraint pis_unique unique ("SALARIE_ID", "ENFANT_ID", "INDICATEUR", "DEBUT_VALIDITE")
);

create table "PLANNINGS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SERVICE_ID" VARCHAR2(36 CHAR),
  "DEBUT_SEMAINE" DATE not null,
  "LIBELLE" VARCHAR2(4000 CHAR),
  "STATUT" VARCHAR2(8 CHAR) default 'draft' not null,
  "PUBLIE_LE" TIMESTAMP(6) WITH TIME ZONE,
  "PUBLIE_PAR" VARCHAR2(36 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint plannings_pkey primary key ("ID"),
  constraint plannings_company_id_departm unique ("SOCIETE_ID", "SERVICE_ID", "DEBUT_SEMAINE"),
  constraint plannings_id_company_uk unique ("ID", "SOCIETE_ID")
);

create table "PRIMES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR),
  "RUPTURE_ID" VARCHAR2(36 CHAR),
  "GENRE" VARCHAR2(4000 CHAR) default 'other' not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "MONTANT" NUMBER(12,2) not null,
  "ATTRIBUE_LE" DATE not null,
  "EXERCICE" NUMBER(5) not null,
  "IMPOSABLE" BOOLEAN default 1 not null,
  "COTISABLE" BOOLEAN default 1 not null,
  "PART_EXONEREE_PCT" NUMBER(6,3) default 0 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint primes_pkey primary key ("ID")
);

create table "PROFILS" (
  "ID" VARCHAR2(36 CHAR) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR) not null,
  "NOM_COMPLET" VARCHAR2(4000 CHAR) default '' not null,
  "COURRIEL" VARCHAR2(4000 CHAR) default '' not null,
  "EST_ADMIN_ORGANISATION" BOOLEAN default 0 not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint profils_pkey primary key ("ID")
);

create table "PROLONGATIONS_ESSAI" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR) not null,
  "DATE_DEBUT" DATE not null,
  "DATE_FIN" DATE not null,
  "JOURS_AJOUTES" NUMBER(10) not null,
  "MOTIF" VARCHAR2(4000 CHAR) default 'incapacité de travail' not null,
  constraint prolongations_essai_pkey primary key ("ID")
);

create table "REF_ACTION_ACCES" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_action_acces_pkey primary key ("CODE")
);

create table "REF_COMPENSATION_HEURES_SUP" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_compensation_heures_sup_ primary key ("CODE")
);

create table "REF_CONDITION_TRAVAIL" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "FAMILLE" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR),
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_condition_travail_pkey primary key ("CODE")
);

create table "REF_INDICATEUR_SECOURS" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "CONSIGNE" VARCHAR2(4000 CHAR) not null,
  "VISIBLE_DISPATCHING" BOOLEAN default 1 not null,
  "VISIBLE_SECOURS" BOOLEAN default 1 not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_indicateur_secours_pkey primary key ("CODE")
);

create table "REF_LIEN_ENFANT" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_lien_enfant_pkey primary key ("CODE")
);

create table "REF_NATURE_PRIME" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "CATEGORIE" VARCHAR2(4000 CHAR) default 'autre' not null,
  "LIE_AUX_CONDITIONS" BOOLEAN default 0 not null,
  "URL_SOURCE" VARCHAR2(4000 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_nature_prime_pkey primary key ("CODE")
);

create table "REF_PAYS" (
  "ALPHA3" CHAR(3 CHAR) not null,
  "ALPHA2" CHAR(2 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "FRONTALIER" BOOLEAN default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  constraint ref_pays_pkey primary key ("ALPHA3"),
  constraint rp_alpha2_unique unique ("ALPHA2")
);

create table "REF_STATUT_HEURES_SUP" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_statut_heures_sup_pkey primary key ("CODE")
);

create table "REF_STATUT_VERIFICATION_ADRESSE" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_statut_verification_adre primary key ("CODE")
);

create table "REF_SUJET_EXPORT" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_sujet_export_pkey primary key ("CODE")
);

create table "REF_TYPE_ADRESSE" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "SERT_AU_FISCAL" BOOLEAN default 0 not null,
  "SERT_AUX_TOURNEES" BOOLEAN default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  constraint ref_type_adresse_pkey primary key ("CODE")
);

create table "REF_UNITE_ESSAI" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_unite_essai_pkey primary key ("CODE")
);

create table "REF_UNITE_PRIME" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR),
  "ORDRE" NUMBER(5) default 0 not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint ref_unite_prime_pkey primary key ("CODE")
);

create table "REGLES_CONVENTION" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONVENTION_ID" VARCHAR2(36 CHAR) not null,
  "BLOC" VARCHAR2(16 CHAR) not null,
  "REGLES" CLOB default '{}' not null constraint regles_convention_regles_json check ("REGLES" is json),
  "COMPLET" BOOLEAN default 0 not null,
  "MODIFIE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint regles_convention_pkey primary key ("ID"),
  constraint regles_convention_collective unique ("CONVENTION_ID", "BLOC")
);

create table "RELEVES_EFFECTIF" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "MOIS" DATE not null,
  "EFFECTIF" NUMBER(8,2) not null,
  constraint releves_effectif_pkey primary key ("ID"),
  constraint releves_effectif_company_id_ unique ("SOCIETE_ID", "MOIS")
);

create table "RELEVES_TEMPS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "DATE_RELEVE" DATE not null,
  "HEURE_DEBUT" INTERVAL DAY(0) TO SECOND(0),
  "HEURE_FIN" INTERVAL DAY(0) TO SECOND(0),
  "PAUSE_MINUTES" NUMBER(5) default 0 not null,
  "HEURES_TRAVAILLEES" NUMBER(5,2),
  "HEURES_PREVUES" NUMBER(5,2),
  "HEURES_DIMANCHE" NUMBER(5,2) default 0 not null,
  "HEURES_FERIE" NUMBER(5,2) default 0 not null,
  "HEURES_NUIT" NUMBER(5,2) default 0 not null,
  "HEURES_SUPPLEMENTAIRES" NUMBER(5,2) default 0 not null,
  "VALIDE" BOOLEAN default 0 not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'manual' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint releves_temps_pkey primary key ("ID"),
  constraint releves_temps_employee_id_en unique ("SALARIE_ID", "DATE_RELEVE")
);

create table "ROLES_COMPTE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPTE_ID" VARCHAR2(36 CHAR) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR),
  "ROLE" VARCHAR2(16 CHAR) not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint roles_compte_pkey primary key ("ID"),
  constraint roles_compte_user_id_company unique ("COMPTE_ID", "SOCIETE_ID", "ROLE")
);

create table "RUPTURES_CONTRAT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "MOTIF" VARCHAR2(4000 CHAR) not null,
  "MOTIF_PERSONNEL" BOOLEAN default 1 not null,
  "NOTIFIE_LE" DATE not null,
  "DEBUT_PREAVIS" DATE,
  "FIN_PREAVIS" DATE,
  "INDEMNITE_MOIS" NUMBER(4,1),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "PREAVIS_RENONCE" BOOLEAN default 0 not null,
  "RENONCIATION_CONVENUE_LE" DATE,
  "COMPENSATION_RENONCIATION" NUMBER(12,2),
  "NOTE_RENONCIATION" VARCHAR2(4000 CHAR),
  "FAUTE_GRAVE" BOOLEAN default 0 not null,
  constraint ruptures_contrat_pkey primary key ("ID")
);

create table "SALARIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "COMPTE_ID" VARCHAR2(36 CHAR),
  "SERVICE_ID" VARCHAR2(36 CHAR),
  "PRENOM" VARCHAR2(4000 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "DATE_NAISSANCE" DATE,
  "RESIDENCE" VARCHAR2(14 CHAR) not null,
  "QUALIFICATION" VARCHAR2(11 CHAR) default 'unqualified' not null,
  "LIGNE" VARCHAR2(4000 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "LOCALITE" VARCHAR2(4000 CHAR),
  "PAYS" VARCHAR2(4000 CHAR) default 'LU' not null,
  "COURRIEL" VARCHAR2(4000 CHAR),
  "TELEPHONE" VARCHAR2(4000 CHAR),
  "MATRICULE_NATIONAL_CHIFFRE" BLOB,
  "IBAN_CHIFFRE" BLOB,
  "MATRICULE_NATIONAL_INDICE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SEXE" VARCHAR2(11 CHAR) default 'unspecified' not null,
  "DATE_DEBUT_CARRIERE" DATE,
  "PROFESSION" VARCHAR2(4000 CHAR),
  "EST_CADRE" BOOLEAN default 0 not null,
  "SEXE_LEGAL" VARCHAR2(11 CHAR),
  "REFUS_PHOTOS_SOCIETE" BOOLEAN default 0 not null,
  "SOUHAITE_CONFIDENTIALITE" BOOLEAN default 0 not null,
  constraint salaries_pkey primary key ("ID"),
  constraint salaries_id_company_uk unique ("ID", "SOCIETE_ID")
);

create table "SANCTIONS_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "CONTRAT_ID" VARCHAR2(36 CHAR),
  "TYPE_SANCTION" VARCHAR2(4000 CHAR) not null,
  "FAITS_LE" DATE not null,
  "FAITS_CONNUS_LE" DATE not null,
  "NOTIFIE_LE" DATE,
  "EFFET_DU" DATE,
  "EFFET_AU" DATE,
  "MOTIF" VARCHAR2(4000 CHAR) not null,
  "PIECE_JUSTIFICATIVE_ID" VARCHAR2(36 CHAR),
  "RUPTURE_ID" VARCHAR2(36 CHAR),
  "CONTRAT_AVENANT_ID" VARCHAR2(36 CHAR),
  "SALARIE_ENTENDU_LE" DATE,
  "REPONSE_SALARIE" VARCHAR2(4000 CHAR),
  "CONTESTE_LE" DATE,
  "ISSUE_CONTESTATION" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "CONSERVATION_JUSQUAU" DATE,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREE_PAR" VARCHAR2(36 CHAR),
  "MODIFIE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "MODIFIE_PAR" VARCHAR2(36 CHAR),
  "SUPPRIME_LE" TIMESTAMP(6) WITH TIME ZONE,
  "SUPPRIME_PAR" VARCHAR2(36 CHAR),
  constraint sanctions_salarie_pkey primary key ("ID")
);

create table "SECRETS_APPLICATION" (
  "CLE" VARCHAR2(4000 CHAR) not null,
  "SECRET" VARCHAR2(4000 CHAR) not null,
  constraint secrets_application_pkey primary key ("CLE")
);

create table "SERVICES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "COUVERTURE_SOIR_MIN" NUMBER(5),
  constraint services_pkey primary key ("ID")
);

create table "SINISTRES_ACCIDENT_SOCIETE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "ANNEE" NUMBER(5) not null,
  "NOMBRE_SINISTRES" NUMBER(10) default 0 not null,
  "JOURS_PERDUS" NUMBER(10) default 0 not null,
  "COUT" NUMBER(12,2),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint sinistres_accident_societe_p primary key ("ID"),
  constraint sinistres_accident_societe_c unique ("SOCIETE_ID", "ANNEE")
);

create table "SITES_CLIENT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "NOM" VARCHAR2(4000 CHAR) not null,
  "NOM_CLIENT" VARCHAR2(4000 CHAR),
  "LIGNE" VARCHAR2(4000 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "LOCALITE" VARCHAR2(4000 CHAR),
  "PAYS" VARCHAR2(4000 CHAR) default 'LU' not null,
  "LATITUDE" NUMBER(9,6),
  "LONGITUDE" NUMBER(9,6),
  "ACTIF" BOOLEAN default 1 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint sites_client_pkey primary key ("ID")
);

create table "SOCIETES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANISATION_ID" VARCHAR2(36 CHAR) not null,
  "RAISON_SOCIALE" VARCHAR2(4000 CHAR) not null,
  "FORME_JURIDIQUE" VARCHAR2(4000 CHAR),
  "NUMERO_RCS" VARCHAR2(4000 CHAR),
  "MATRICULE_CCSS" VARCHAR2(4000 CHAR),
  "LIGNE" VARCHAR2(4000 CHAR),
  "CODE_POSTAL" VARCHAR2(4000 CHAR),
  "LOCALITE" VARCHAR2(4000 CHAR),
  "PAYS" VARCHAR2(4000 CHAR) default 'LU' not null,
  "CODE_NACE" VARCHAR2(4000 CHAR),
  "SECTEUR" VARCHAR2(4000 CHAR),
  "PERIODE_REFERENCE_MOIS" NUMBER(5) default 4 not null,
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "REGLEMENT_INTERIEUR_ADOPTE_LE" DATE,
  "REFERENCE_REGLEMENT_INTERIEUR" VARCHAR2(4000 CHAR),
  constraint societes_pkey primary key ("ID")
);

create table "STATUTS_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SOCIETE_ID" VARCHAR2(36 CHAR) not null,
  "SALARIE_ID" VARCHAR2(36 CHAR) not null,
  "GENRE" VARCHAR2(18 CHAR) not null,
  "DECLARE_LE" DATE default CURRENT_DATE not null,
  "DATE_DEBUT" DATE not null,
  "DATE_FIN" DATE default '2037-12-31' not null,
  "DATE_NAISSANCE_PREVUE" DATE,
  "DATE_NAISSANCE_REELLE" DATE,
  "PIECE_JUSTIFICATIVE_ID" VARCHAR2(36 CHAR),
  "CREDIT_HEURES_MENSUEL" NUMBER(5,1),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREE_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint statuts_salarie_pkey primary key ("ID")
);

create table "TRANCHES_IMPOT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CLASSE_IMPOT" VARCHAR2(8 CHAR) not null,
  "PERIODICITE" VARCHAR2(8 CHAR) default 'monthly' not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "TRANCHE_MIN" NUMBER(12,2) not null,
  "TRANCHE_MAX" NUMBER(12,2),
  "IMPOT_BASE" NUMBER(12,2) default 0 not null,
  "TAUX_AU_DESSUS_MINIMUM" NUMBER(7,4) not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'ACD' not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint tranches_impot_pkey primary key ("ID")
);

create table "TYPES_ABSENCE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "CATEGORIE" VARCHAR2(14 CHAR) not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "CERTIFICAT_EXIGE" BOOLEAN default 0 not null,
  "REMUNERE" BOOLEAN default 1 not null,
  "IMPUTE_SUR_CONGE" BOOLEAN default 0 not null,
  constraint types_absence_pkey primary key ("ID"),
  constraint types_absence_code_key unique ("CODE")
);

create table "TYPES_AVANTAGE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "METHODE_EVALUATION" VARCHAR2(4000 CHAR) not null,
  "IMPOSABLE" BOOLEAN default 1 not null,
  "COTISABLE" BOOLEAN default 1 not null,
  "PARAMETRES_EVALUATION" CLOB default '{}' not null constraint types_avantage_parametres_evaluat_json check ("PARAMETRES_EVALUATION" is json),
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint types_avantage_pkey primary key ("ID"),
  constraint types_avantage_code_key unique ("CODE")
);

create table "TYPES_DOCUMENT" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "ECHELON" VARCHAR2(15 CHAR) default 'during_contract' not null,
  "VALIDITE_MOIS" NUMBER(10),
  "OBLIGATOIRE" BOOLEAN default 0 not null,
  "RESIDENCES_VISEES" CLOB,
  "ALERTE_JOURS_AVANT" NUMBER(10) default 30 not null,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint types_document_pkey primary key ("ID"),
  constraint types_document_code_key unique ("CODE")
);

create table "TYPES_SANCTION" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "CODE_CATEGORIE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR) not null,
  "SUSPEND_PRESENCE" BOOLEAN default 0 not null,
  "AFFECTE_PAIE" BOOLEAN default 0 not null,
  "REGLEMENT_INTERIEUR_EXIGE" BOOLEAN default 0 not null,
  "MODIFIE_CONTRAT" BOOLEAN default 0 not null,
  "ROMPT_CONTRAT" BOOLEAN default 0 not null,
  "NEEDS_NOTICE" BOOLEAN,
  "REFERENCE_LEGALE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  constraint types_sanction_pkey primary key ("CODE")
);

create table "ZONES_ADRESSE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "PAYS" CHAR(3 CHAR) not null,
  "GENRE" VARCHAR2(4000 CHAR) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LIBELLE" VARCHAR2(4000 CHAR) not null,
  "CODE_POSTAL_DU" NUMBER(10),
  "CODE_POSTAL_AU" NUMBER(10),
  "VERIFIE" BOOLEAN default 0 not null,
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint zones_adresse_pkey primary key ("ID"),
  constraint address_zone_unique unique ("PAYS", "CODE")
);

-- Clés étrangères, posées après toutes les tables.
alter table "ABSENCES" add constraint absences_statut_ref foreign key ("STATUT") references "REF_STATUT_ABSENCE" ("CODE");
alter table "ALERTES_CONFORMITE" add constraint alertes_conformite_severite_ foreign key ("SEVERITE") references "REF_GENRE_SEVERITE" ("CODE");
alter table "ALERTES_CONFORMITE" add constraint alertes_conformite_etat_ref foreign key ("ETAT") references "REF_ETAT_ALERTE" ("CODE");
alter table "CONTRATS" add constraint contrats_genre_ref foreign key ("GENRE") references "REF_GENRE_CONTRAT" ("CODE");
alter table "CONTRATS" add constraint contrats_statut_ref foreign key ("STATUT") references "REF_STATUT_CONTRAT" ("CODE");
alter table "CONVENTIONS_COLLECTIVES" add constraint conventions_collec_portee_re foreign key ("PORTEE") references "REF_PORTEE_CONVENTION" ("CODE");
alter table "ELEMENTS_REMUNERATION" add constraint elements_remunerat_genre_ref foreign key ("GENRE") references "REF_GENRE_ELEMENT_REMUNERATION" ("CODE");
alter table "ENFANTS_SALARIE" add constraint enfants_salarie_sexe_ref foreign key ("SEXE") references "REF_GENRE_SEXE" ("CODE");
alter table "FICHES_RETENUE_IMPOT" add constraint fiches_retenue_imp_classe_im foreign key ("CLASSE_IMPOT") references "REF_CLASSE_IMPOT" ("CODE");
alter table "ORGANISATIONS" add constraint organisations_genre_ref foreign key ("GENRE") references "REF_GENRE_ORGANISATION" ("CODE");
alter table "PARAMETRES_LEGAUX" add constraint parametres_legaux_famille_re foreign key ("FAMILLE") references "REF_FAMILLE_PARAMETRE" ("CODE");
alter table "PLANNINGS" add constraint plannings_statut_ref foreign key ("STATUT") references "REF_STATUT_PLANNING" ("CODE");
alter table "REGLES_CONVENTION" add constraint regles_convention_bloc_ref foreign key ("BLOC") references "REF_BLOC_CONVENTION" ("CODE");
alter table "ROLES_COMPTE" add constraint roles_compte_role_ref foreign key ("ROLE") references "REF_ROLE_APPLICATION" ("CODE");
alter table "SALARIES" add constraint salaries_residence_ref foreign key ("RESIDENCE") references "REF_GENRE_RESIDENCE" ("CODE");
alter table "SALARIES" add constraint salaries_qualification_ref foreign key ("QUALIFICATION") references "REF_GENRE_QUALIFICATION" ("CODE");
alter table "SALARIES" add constraint salaries_sexe_ref foreign key ("SEXE") references "REF_GENRE_SEXE" ("CODE");
alter table "SALARIES" add constraint salaries_sexe_legal_ref foreign key ("SEXE_LEGAL") references "REF_GENRE_SEXE" ("CODE");
alter table "STATUTS_SALARIE" add constraint statuts_salarie_genre_ref foreign key ("GENRE") references "REF_GENRE_STATUT_SALARIE" ("CODE");
alter table "TRANCHES_IMPOT" add constraint tranches_impot_classe_impot_ foreign key ("CLASSE_IMPOT") references "REF_CLASSE_IMPOT" ("CODE");
alter table "TRANCHES_IMPOT" add constraint tranches_impot_periodicite_r foreign key ("PERIODICITE") references "REF_PERIODICITE_IMPOT" ("CODE");
alter table "TYPES_ABSENCE" add constraint types_absence_categorie_ref foreign key ("CATEGORIE") references "REF_CATEGORIE_ABSENCE" ("CODE");
alter table "TYPES_DOCUMENT" add constraint types_document_echelon_ref foreign key ("ECHELON") references "REF_ETAPE_DOCUMENT" ("CODE");

alter table "ABSENCES" add constraint absence_belongs_to_employees foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "ABSENCES" add constraint absences_absence_parente_id_ foreign key ("ABSENCE_PARENTE_ID") references "ABSENCES" ("ID") on delete set null;
alter table "ABSENCES" add constraint absences_absence_type_id_fke foreign key ("TYPE_ABSENCE_ID") references "TYPES_ABSENCE" ("ID");
alter table "ABSENCES" add constraint absences_child_id_fkey foreign key ("ENFANT_ID") references "ENFANTS_SALARIE" ("ID") on delete set null;
alter table "ABSENCES" add constraint absences_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ABSENCES" add constraint absences_decided_by_fkey foreign key ("DECIDE_PAR") references "APP_USERS" ("ID");
alter table "ABSENCES" add constraint absences_requested_by_fkey foreign key ("DEMANDE_PAR") references "APP_USERS" ("ID");
alter table "ADRESSES_SALARIE" add constraint adr_appartient_au_salarie foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "ADRESSES_SALARIE" add constraint adresses_salarie_type_adress foreign key ("TYPE_ADRESSE") references "REF_TYPE_ADRESSE" ("CODE");
alter table "AGENCES_INTERIM" add constraint agences_interim_organization foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID") on delete cascade;
alter table "ALERTES_CONFORMITE" add constraint alertes_conformite_company_i foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ALERTES_CONFORMITE" add constraint alertes_conformite_employee_ foreign key ("SALARIE_ID") references "SALARIES" ("ID") on delete set null;
alter table "ALERTES_CONFORMITE" add constraint alertes_conformite_handled_b foreign key ("TRAITE_PAR") references "APP_USERS" ("ID");
alter table "ATTRIBUTIONS_TITRES_REPAS" add constraint attributions_titres_repas_co foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ATTRIBUTIONS_TITRES_REPAS" add constraint voucher_belongs_to_employees foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "AVENANTS_CONTRAT" add constraint avenants_contrat_company_id_ foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "AVENANTS_CONTRAT" add constraint avenants_contrat_contract_id foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete cascade;
alter table "AVENANTS_CONTRAT" add constraint avenants_contrat_created_by_ foreign key ("CREE_PAR") references "APP_USERS" ("ID");
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_collective_a foreign key ("CONVENTION_ID") references "CONVENTIONS_COLLECTIVES" ("ID") on delete cascade;
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_condition_co foreign key ("CONDITION_CODE") references "REF_CONDITION_TRAVAIL" ("CODE");
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_nature_prime foreign key ("NATURE_PRIME") references "REF_NATURE_PRIME" ("CODE");
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_unite_ref foreign key ("UNITE") references "REF_UNITE_PRIME" ("CODE");
alter table "CONTRATS" add constraint contract_belongs_to_employee foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "CONTRATS" add constraint contrats_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "CONTRATS" add constraint contrats_interim_agency_fk foreign key ("AGENCE_INTERIM_ID") references "AGENCES_INTERIM" ("ID") on delete set null;
alter table "CONTRATS" add constraint contrats_previous_contract_i foreign key ("CONTRAT_PRECEDENT_ID") references "CONTRATS" ("ID") on delete set null;
alter table "CONTRATS" add constraint contrats_unite_essai_ref foreign key ("UNITE_ESSAI") references "REF_UNITE_ESSAI" ("CODE");
alter table "CONTROLES_ADRESSE" add constraint controles_adresse_statut_ref foreign key ("STATUT") references "REF_STATUT_VERIFICATION_ADRESSE" ("CODE");
alter table "CONVENTIONS_COLLECTIVES" add constraint conventions_collectives_orga foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID") on delete cascade;
alter table "CONVENTIONS_COLLECTIVES" add constraint conventions_collectives_supe foreign key ("REMPLACE_ID") references "CONVENTIONS_COLLECTIVES" ("ID") on delete set null;
alter table "CONVENTIONS_DE_LA_SOCIETE" add constraint conventions_de_la_societe_co foreign key ("CONVENTION_ID") references "CONVENTIONS_COLLECTIVES" ("ID");
alter table "CONVENTIONS_DE_LA_SOCIETE" add constraint conventions_de_la_societe_co foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "CONVENTIONS_DE_LA_SOCIETE" add constraint conventions_de_la_societe_de foreign key ("SERVICE_ID") references "SERVICES" ("ID") on delete cascade;
alter table "CONVENTIONS_DU_CONTRAT" add constraint conventions_du_contrat_colle foreign key ("CONVENTION_ID") references "CONVENTIONS_COLLECTIVES" ("ID");
alter table "CONVENTIONS_DU_CONTRAT" add constraint conventions_du_contrat_contr foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete cascade;
alter table "CRENEAU_CONDITION" add constraint cc_appartient_au_salarie foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "CRENEAU_CONDITION" add constraint cc_site_appartient_a_la_soci foreign key ("SITE_CLIENT_ID", "SOCIETE_ID") references "SITES_CLIENT" ("ID", "SOCIETE_ID") on delete set null;
alter table "CRENEAU_CONDITION" add constraint creneau_condition_condition_ foreign key ("CONDITION_CODE") references "REF_CONDITION_TRAVAIL" ("CODE");
alter table "CRENEAU_CONDITION" add constraint creneau_condition_shift_id_f foreign key ("CRENEAU_ID") references "CRENEAUX" ("ID") on delete cascade;
alter table "CRENEAU_CONDITION" add constraint creneau_condition_time_entry foreign key ("RELEVE_TEMPS_ID") references "RELEVES_TEMPS" ("ID") on delete cascade;
alter table "CRENEAUX" add constraint creneaux_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "CRENEAUX" add constraint creneaux_template_id_fkey foreign key ("MODELE_ID") references "MODELES_CRENEAU" ("ID") on delete set null;
alter table "CRENEAUX" add constraint shift_belongs_to_employees_c foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "CRENEAUX" add constraint shift_belongs_to_schedules_c foreign key ("PLANNING_ID", "SOCIETE_ID") references "PLANNINGS" ("ID", "SOCIETE_ID") on delete cascade;
alter table "CRENEAUX" add constraint shift_site_belongs_to_compan foreign key ("SITE_CLIENT_ID", "SOCIETE_ID") references "SITES_CLIENT" ("ID", "SOCIETE_ID") on delete set null;
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_company_ foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_compensa foreign key ("COMPENSATION") references "REF_COMPENSATION_HEURES_SUP" ("CODE");
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_hr_valid foreign key ("VALIDE_RH_PAR") references "APP_USERS" ("ID");
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_requeste foreign key ("DEMANDE_PAR") references "APP_USERS" ("ID");
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_schedule foreign key ("PLANNING_ID") references "PLANNINGS" ("ID") on delete set null;
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_statut_r foreign key ("STATUT") references "REF_STATUT_HEURES_SUP" ("CODE");
alter table "DEMANDES_HEURES_SUP" add constraint overtime_belongs_to_employee foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_document_type_id_f foreign key ("TYPE_DOCUMENT_ID") references "TYPES_DOCUMENT" ("ID") on delete set null;
alter table "DOCUMENTS" add constraint documents_employee_id_fkey foreign key ("SALARIE_ID") references "SALARIES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_uploaded_by_fkey foreign key ("DEPOSE_PAR") references "APP_USERS" ("ID");
alter table "DONNEES_FINANCIERES_SOCIETE" add constraint donnees_financieres_societe_ foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "DROITS_ABSENCE" add constraint droits_absence_absence_type_ foreign key ("TYPE_ABSENCE_ID") references "TYPES_ABSENCE" ("ID") on delete cascade;
alter table "ELEMENTS_REMUNERATION" add constraint elements_remuneration_benefi foreign key ("TYPE_AVANTAGE_ID") references "TYPES_AVANTAGE" ("ID") on delete set null;
alter table "ELEMENTS_REMUNERATION" add constraint elements_remuneration_compan foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ELEMENTS_REMUNERATION" add constraint elements_remuneration_contra foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete cascade;
alter table "ENFANTS_SALARIE" add constraint child_belongs_to_employees_c foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "ENFANTS_SALARIE" add constraint enfants_salarie_company_id_f foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ENFANTS_SALARIE" add constraint enfants_salarie_lien_ref foreign key ("LIEN_PARENTE") references "REF_LIEN_ENFANT" ("CODE");
alter table "FICHE_SANTE" add constraint fiche_sante_enfant_id_fkey foreign key ("ENFANT_ID") references "ENFANTS_SALARIE" ("ID") on delete cascade;
alter table "FICHES_RETENUE_IMPOT" add constraint fiches_retenue_impot_company foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "FICHES_RETENUE_IMPOT" add constraint fiches_retenue_impot_employe foreign key ("SALARIE_ID") references "SALARIES" ("ID") on delete cascade;
alter table "GRILLES_SALAIRES_CONVENTION" add constraint grilles_salaires_convention_ foreign key ("CONVENTION_ID") references "CONVENTIONS_COLLECTIVES" ("ID") on delete cascade;
alter table "HANDICAPS_SALARIE" add constraint disability_belongs_to_employ foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "HANDICAPS_SALARIE" add constraint handicaps_salarie_company_id foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "HANDICAPS_SALARIE" add constraint handicaps_salarie_evidence_d foreign key ("PIECE_JUSTIFICATIVE_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "JOURNAL_ACCES" add constraint journal_acces_action_ref foreign key ("ACTION") references "REF_ACTION_ACCES" ("CODE");
alter table "JOURNAL_EXPORTS" add constraint journal_exports_organization foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID") on delete cascade;
alter table "JOURNAL_EXPORTS" add constraint journal_exports_requested_by foreign key ("DEMANDE_PAR") references "APP_USERS" ("ID");
alter table "JOURNAL_EXPORTS" add constraint journal_exports_sujet_ref foreign key ("GENRE_OBJET") references "REF_SUJET_EXPORT" ("CODE");
alter table "MODELES_CRENEAU" add constraint modeles_creneau_company_id_f foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "MODELES_CRENEAU" add constraint modeles_creneau_department_i foreign key ("SERVICE_ID") references "SERVICES" ("ID") on delete set null;
alter table "PARAMETRES_LEGAUX" add constraint parametres_legaux_entered_by foreign key ("SAISI_PAR") references "APP_USERS" ("ID");
alter table "PARAMETRES_LEGAUX" add constraint parametres_legaux_validated_ foreign key ("VALIDE_PAR") references "APP_USERS" ("ID");
alter table "PERIODES_REFERENCE" add constraint periodes_reference_company_i foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "PERIODES_REFERENCE" add constraint periodes_reference_departmen foreign key ("SERVICE_ID") references "SERVICES" ("ID") on delete set null;
alter table "PERIODES_TAUX_SOCIETE" add constraint periodes_taux_societe_compan foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint personne_indicateur_secours_ foreign key ("ENFANT_ID") references "ENFANTS_SALARIE" ("ID") on delete cascade;
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint personne_indicateur_secours_ foreign key ("INDICATEUR") references "REF_INDICATEUR_SECOURS" ("CODE");
alter table "PLANNINGS" add constraint plannings_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "PLANNINGS" add constraint plannings_department_id_fkey foreign key ("SERVICE_ID") references "SERVICES" ("ID") on delete set null;
alter table "PLANNINGS" add constraint plannings_published_by_fkey foreign key ("PUBLIE_PAR") references "APP_USERS" ("ID");
alter table "PRIMES" add constraint premium_belongs_to_employees foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "PRIMES" add constraint primes_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "PRIMES" add constraint primes_contract_id_fkey foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete set null;
alter table "PRIMES" add constraint primes_nature_ref foreign key ("GENRE") references "REF_NATURE_PRIME" ("CODE");
alter table "PRIMES" add constraint primes_termination_id_fkey foreign key ("RUPTURE_ID") references "RUPTURES_CONTRAT" ("ID") on delete set null;
alter table "PROFILS" add constraint profils_id_fkey foreign key ("ID") references "APP_USERS" ("ID") on delete cascade;
alter table "PROFILS" add constraint profils_organization_id_fkey foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID");
alter table "PROLONGATIONS_ESSAI" add constraint prolongations_essai_contract foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete cascade;
alter table "REGLES_CONVENTION" add constraint regles_convention_collective foreign key ("CONVENTION_ID") references "CONVENTIONS_COLLECTIVES" ("ID") on delete cascade;
alter table "RELEVES_EFFECTIF" add constraint releves_effectif_company_id_ foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "RELEVES_TEMPS" add constraint releves_temps_company_id_fke foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "RELEVES_TEMPS" add constraint time_entry_belongs_to_employ foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "ROLES_COMPTE" add constraint roles_compte_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "ROLES_COMPTE" add constraint roles_compte_organization_id foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID") on delete cascade;
alter table "ROLES_COMPTE" add constraint roles_compte_user_id_fkey foreign key ("COMPTE_ID") references "APP_USERS" ("ID") on delete cascade;
alter table "RUPTURES_CONTRAT" add constraint ruptures_contrat_company_id_ foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "RUPTURES_CONTRAT" add constraint ruptures_contrat_contract_id foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete cascade;
alter table "SALARIES" add constraint salaries_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "SALARIES" add constraint salaries_department_id_fkey foreign key ("SERVICE_ID") references "SERVICES" ("ID") on delete set null;
alter table "SALARIES" add constraint salaries_user_id_fkey foreign key ("COMPTE_ID") references "APP_USERS" ("ID") on delete set null;
alter table "SANCTIONS_SALARIE" add constraint sanction_belongs_to_employee foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "SANCTIONS_SALARIE" add constraint sanctions_salarie_amendment_ foreign key ("CONTRAT_AVENANT_ID") references "CONTRATS" ("ID") on delete set null;
alter table "SANCTIONS_SALARIE" add constraint sanctions_salarie_contract_i foreign key ("CONTRAT_ID") references "CONTRATS" ("ID") on delete set null;
alter table "SANCTIONS_SALARIE" add constraint sanctions_salarie_evidence_d foreign key ("PIECE_JUSTIFICATIVE_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "SANCTIONS_SALARIE" add constraint sanctions_salarie_sanction_t foreign key ("TYPE_SANCTION") references "TYPES_SANCTION" ("CODE");
alter table "SANCTIONS_SALARIE" add constraint sanctions_salarie_terminatio foreign key ("RUPTURE_ID") references "RUPTURES_CONTRAT" ("ID") on delete set null;
alter table "SERVICES" add constraint services_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "SINISTRES_ACCIDENT_SOCIETE" add constraint sinistres_accident_societe_c foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "SITES_CLIENT" add constraint sites_client_company_id_fkey foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "SOCIETES" add constraint societes_organization_id_fke foreign key ("ORGANISATION_ID") references "ORGANISATIONS" ("ID") on delete cascade;
alter table "STATUTS_SALARIE" add constraint status_belongs_to_employees_ foreign key ("SALARIE_ID", "SOCIETE_ID") references "SALARIES" ("ID", "SOCIETE_ID") on delete cascade;
alter table "STATUTS_SALARIE" add constraint statuts_salarie_company_id_f foreign key ("SOCIETE_ID") references "SOCIETES" ("ID") on delete cascade;
alter table "STATUTS_SALARIE" add constraint statuts_salarie_evidence_doc foreign key ("PIECE_JUSTIFICATIVE_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "TYPES_SANCTION" add constraint types_sanction_category_code foreign key ("CODE_CATEGORIE") references "CATEGORIES_SANCTION" ("CODE");

-- Contraintes de validation.
alter table "ABSENCES" add constraint absence_days_positive CHECK ((nombre_jours >= (0)::numeric));
alter table "ABSENCES" add constraint absence_pas_sa_propre_parent CHECK (((absence_parente_id IS NULL) OR (absence_parente_id <> id)));
alter table "ABSENCES" add constraint absence_range CHECK ((date_fin >= date_debut));
alter table "ADRESSES_SALARIE" add constraint adr_a_une_adresse CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table "ADRESSES_SALARIE" add constraint adr_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table "ADRESSES_SALARIE" add constraint adr_periode CHECK ((fin_validite > debut_validite));
alter table "ATTRIBUTIONS_TITRES_REPAS" add constraint attributions_titres_repas_vo CHECK ((nombre_titres >= 0));
alter table "ATTRIBUTIONS_TITRES_REPAS" add constraint voucher_period CHECK ((fin_periode >= debut_periode));
alter table "ATTRIBUTIONS_TITRES_REPAS" add constraint voucher_share_within_face_va CHECK (((valeur_faciale > (0)::numeric) AND (part_salariale >= (0)::numeric) AND (part_salariale <= valeur_faciale)));
alter table "CATEGORIES_SANCTION" add constraint categories_sanction_periode_ CHECK ((fin_validite > debut_validite));
alter table "CATEGORIES_SANCTION" add constraint sanction_category_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "CCT_REGLE_PRIME" add constraint crp_periode CHECK ((fin_validite > debut_validite));
alter table "CCT_REGLE_PRIME" add constraint crp_seuil_positif CHECK ((seuil_minutes >= 0));
alter table "CCT_REGLE_PRIME" add constraint crp_source_non_vide CHECK ((btrim(url_source) <> ''::text));
alter table "CCT_REGLE_PRIME" add constraint crp_taux_exige_assiette CHECK (((taux_pct IS NULL) OR (assiette IS NOT NULL)));
alter table "CCT_REGLE_PRIME" add constraint crp_taux_ou_montant CHECK ((num_nonnulls(taux_pct, montant) = 1));
alter table "COMPTES" add constraint app_user_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table "COMPTES" add constraint app_user_email_shape CHECK ((courriel ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text));
alter table "COMPTES" add constraint app_user_userid_shape CHECK ((identifiant ~ '^[a-z0-9._-]{3,64}$'::text));
alter table "CONTRATS" add constraint cdd_needs_reason CHECK (((genre <> 'cdd'::genre_contrat) OR (motif_cdd IS NOT NULL)));
alter table "CONTRATS" add constraint contract_dates_order CHECK (((date_fin IS NULL) OR (date_fin >= date_debut)));
alter table "CONTRATS" add constraint contract_not_its_own_predece CHECK (((contrat_precedent_id IS NULL) OR (contrat_precedent_id <> id)));
alter table "CONTRATS" add constraint contract_quantities_positive CHECK (((heures_hebdomadaires > (0)::numeric) AND (jours_par_semaine > (0)::numeric) AND (jours_par_semaine <= (7)::numeric) AND (brut_mensuel >= (0)::numeric) AND (nombre_renouvellements >= 0) AND ((pause_minutes IS NULL) OR (pause_minutes >= 0)) AND ((jours_conge_annuel IS NULL) OR (jours_conge_annuel >= (0)::numeric)) AND ((duree_essai IS NULL) OR (duree_essai > 0)) AND ((annee_apprentissage IS NULL) OR (annee_apprentissage > 0))));
alter table "CONTRATS" add constraint contrats_periode_coherente CHECK ((date_fin >= date_debut));
alter table "CONTRATS" add constraint fixed_term_needs_end CHECK (((genre <> ALL (ARRAY['cdd'::genre_contrat, 'seasonal'::genre_contrat, 'interim'::genre_contrat, 'apprenticeship'::genre_contrat])) OR (date_fin IS NOT NULL)));
alter table "CONTRATS" add constraint interim_needs_user_company CHECK (((genre <> 'interim'::genre_contrat) OR (nom_societe_utilisateur IS NOT NULL)));
alter table "CONTRATS" add constraint probation_length_and_unit_to CHECK (((duree_essai IS NULL) = (unite_essai IS NULL)));
alter table "CONVENTIONS_COLLECTIVES" add constraint conventions_collectives_peri CHECK ((fin_validite > debut_validite));
alter table "CONVENTIONS_DE_LA_SOCIETE" add constraint company_cba_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "CONVENTIONS_DE_LA_SOCIETE" add constraint conventions_de_la_societe_pe CHECK ((fin_validite > debut_validite));
alter table "CONVENTIONS_DU_CONTRAT" add constraint contract_cba_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "CONVENTIONS_DU_CONTRAT" add constraint conventions_du_contrat_perio CHECK ((fin_validite > debut_validite));
alter table "CREDITS_IMPOT" add constraint credit_income_order CHECK (((revenu_max IS NULL) OR (revenu_min IS NULL) OR (revenu_max > revenu_min)));
alter table "CREDITS_IMPOT" add constraint credit_validity CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "CREDITS_IMPOT" add constraint credits_impot_periode_valide CHECK ((fin_validite > debut_validite));
alter table "CRENEAU_CONDITION" add constraint cc_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table "CRENEAU_CONDITION" add constraint cc_heures_differentes CHECK ((heure_debut <> heure_fin));
alter table "CRENEAU_CONDITION" add constraint cc_rattachement CHECK (((creneau_id IS NOT NULL) OR (releve_temps_id IS NOT NULL)));
alter table "CRENEAUX" add constraint shift_break_positive CHECK ((pause_minutes >= 0));
alter table "CRENEAUX" add constraint shift_times_differ CHECK ((heure_debut <> heure_fin));
alter table "DEMANDES_HEURES_SUP" add constraint demandes_heures_sup_hours_ch CHECK ((heures > (0)::numeric));
alter table "DEMANDES_HEURES_SUP" add constraint overtime_acceptance_follows_ CHECK (((accepte_par_salarie_le IS NULL) OR (valide_rh_le IS NOT NULL)));
alter table "DEMANDES_HEURES_SUP" add constraint overtime_approved_needs_both CHECK (((statut <> 'approved'::text) OR ((valide_rh_le IS NOT NULL) AND (accepte_par_salarie_le IS NOT NULL))));
alter table "DEMANDES_HEURES_SUP" add constraint overtime_period CHECK ((fin_periode >= debut_periode));
alter table "DISTANCES_TRAJET" add constraint travel_distance_positive CHECK ((distance_km >= (0)::numeric));
alter table "DISTANCES_TRAJET" add constraint travel_distance_refs_differ CHECK ((reference_origine <> reference_destination));
alter table "DOCUMENTS" add constraint document_expiry_after_issue CHECK (((expire_le IS NULL) OR (emis_le IS NULL) OR (expire_le >= emis_le)));
alter table "DOCUMENTS" add constraint document_size_positive CHECK (((taille_octets IS NULL) OR (taille_octets >= 0)));
alter table "DROITS_ABSENCE" add constraint droits_absence_periode_valid CHECK ((fin_validite > debut_validite));
alter table "DROITS_ABSENCE" add constraint entitlement_days_positive CHECK (((jours IS NULL) OR (jours >= (0)::numeric)));
alter table "DROITS_ABSENCE" add constraint entitlement_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "ELEMENTS_REMUNERATION" add constraint elements_remuneration_period CHECK ((fin_validite > debut_validite));
alter table "ELEMENTS_REMUNERATION" add constraint pay_component_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "ENFANTS_SALARIE" add constraint ec_taux_exige_handicap CHECK (((taux_handicap_pct IS NULL) OR en_situation_handicap));
alter table "ENFANTS_SALARIE" add constraint ec_taux_handicap CHECK (((taux_handicap_pct IS NULL) OR ((taux_handicap_pct > (0)::numeric) AND (taux_handicap_pct <= (100)::numeric))));
alter table "ENFANTS_SALARIE" add constraint privacy_minimises_data CHECK (((NOT refus_partage) OR ((prenom IS NULL) AND (nom IS NULL) AND (sexe IS NULL) AND (note IS NULL))));
alter table "FICHE_SANTE" add constraint fs_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table "FICHE_SANTE" add constraint fs_personne CHECK ((num_nonnulls(salarie_id, enfant_id) = 1));
alter table "FICHES_RETENUE_IMPOT" add constraint fiches_retenue_impot_periode CHECK ((fin_validite > debut_validite));
alter table "FICHES_RETENUE_IMPOT" add constraint tax_card_amounts_positive CHECK (((indemnite_mensuelle >= (0)::numeric) AND ((frais_professionnels_mensuels IS NULL) OR (frais_professionnels_mensuels >= (0)::numeric)) AND (autres_deductions_mensuelles >= (0)::numeric) AND ((distance_domicile_km IS NULL) OR (distance_domicile_km >= (0)::numeric))));
alter table "FICHES_RETENUE_IMPOT" add constraint tax_card_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "GRILLES_SALAIRES_CONVENTION" add constraint grid_amount_positive CHECK ((montant_mensuel > (0)::numeric));
alter table "GRILLES_SALAIRES_CONVENTION" add constraint grid_seniority_order CHECK (((anciennete_a_annees IS NULL) OR (anciennete_a_annees > anciennete_de_annees)));
alter table "HANDICAPS_SALARIE" add constraint disability_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "HANDICAPS_SALARIE" add constraint handicaps_salarie_periode_va CHECK ((fin_validite > debut_validite));
alter table "HANDICAPS_SALARIE" add constraint handicaps_salarie_rate_pct_c CHECK (((taux_pct > (0)::numeric) AND (taux_pct <= (100)::numeric)));
alter table "JOURS_FERIES" add constraint holiday_year_matches_date CHECK (((EXTRACT(year FROM date_ferie))::integer = annee));
alter table "MODELES_CRENEAU" add constraint template_break_positive CHECK ((pause_minutes >= 0));
alter table "PARAMETRES_LEGAUX" add constraint one_value CHECK (((num_nonnulls(valeur_num, valeur_texte, valeur_json) = 1) OR ((derive_de_cle IS NOT NULL) AND (num_nonnulls(valeur_num, valeur_texte, valeur_json) = 0))));
alter table "PARAMETRES_LEGAUX" add constraint parametres_legaux_periode_va CHECK ((fin_validite > debut_validite));
alter table "PARAMETRES_LEGAUX" add constraint valid_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "PERIODES_REFERENCE" add constraint periodes_reference_months_po CHECK ((mois >= 1));
alter table "PERIODES_REFERENCE" add constraint prl_range CHECK ((date_fin > date_debut));
alter table "PERIODES_TAUX_SOCIETE" add constraint periodes_taux_societe_mutual CHECK ((classe_mutualite >= 1));
alter table "PERIODES_TAUX_SOCIETE" add constraint periodes_taux_societe_period CHECK ((fin_validite > debut_validite));
alter table "PERIODES_TAUX_SOCIETE" add constraint rate_period_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint pis_periode CHECK ((fin_validite > debut_validite));
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint pis_personne CHECK ((num_nonnulls(salarie_id, enfant_id) = 1));
alter table "PLANNINGS" add constraint published_iff_timestamp CHECK (((statut = 'publie'::statut_planning) = (publie_le IS NOT NULL)));
alter table "PRIMES" add constraint premium_exempt_is_a_percenta CHECK (((part_exoneree_pct >= (0)::numeric) AND (part_exoneree_pct <= (100)::numeric)));
alter table "PRIMES" add constraint primes_amount_check CHECK ((montant >= (0)::numeric));
alter table "REF_ACTION_ACCES" add constraint raa_periode CHECK ((fin_validite > debut_validite));
alter table "REF_COMPENSATION_HEURES_SUP" add constraint rchs_periode CHECK ((fin_validite > debut_validite));
alter table "REF_CONDITION_TRAVAIL" add constraint rct_periode CHECK ((fin_validite > debut_validite));
alter table "REF_INDICATEUR_SECOURS" add constraint ris_periode CHECK ((fin_validite > debut_validite));
alter table "REF_LIEN_ENFANT" add constraint rle_periode CHECK ((fin_validite > debut_validite));
alter table "REF_NATURE_PRIME" add constraint rnp_periode CHECK ((fin_validite > debut_validite));
alter table "REF_PAYS" add constraint rp_periode CHECK ((fin_validite > debut_validite));
alter table "REF_STATUT_HEURES_SUP" add constraint rshs_periode CHECK ((fin_validite > debut_validite));
alter table "REF_STATUT_VERIFICATION_ADRESSE" add constraint rsva_periode CHECK ((fin_validite > debut_validite));
alter table "REF_SUJET_EXPORT" add constraint rse_periode CHECK ((fin_validite > debut_validite));
alter table "REF_TYPE_ADRESSE" add constraint rta_periode CHECK ((fin_validite > debut_validite));
alter table "REF_UNITE_ESSAI" add constraint rue_periode CHECK ((fin_validite > debut_validite));
alter table "REF_UNITE_PRIME" add constraint rup_periode CHECK ((fin_validite > debut_validite));
alter table "RELEVES_EFFECTIF" add constraint headcount_month_is_first_day CHECK (((EXTRACT(day FROM mois))::integer = 1));
alter table "RELEVES_EFFECTIF" add constraint headcount_positive CHECK ((effectif >= (0)::numeric));
alter table "RELEVES_TEMPS" add constraint time_entry_hours_positive CHECK (((pause_minutes >= 0) AND ((heures_travaillees IS NULL) OR (heures_travaillees >= (0)::numeric)) AND ((heures_prevues IS NULL) OR (heures_prevues >= (0)::numeric)) AND (heures_dimanche >= (0)::numeric) AND (heures_ferie >= (0)::numeric) AND (heures_nuit >= (0)::numeric) AND (heures_supplementaires >= (0)::numeric)));
alter table "RELEVES_TEMPS" add constraint time_entry_parts_within_work CHECK (((heures_travaillees IS NULL) OR ((heures_dimanche <= heures_travaillees) AND (heures_ferie <= heures_travaillees) AND (heures_nuit <= heures_travaillees) AND (heures_supplementaires <= heures_travaillees))));
alter table "RUPTURES_CONTRAT" add constraint notice_dates_order CHECK (((debut_preavis IS NULL) OR (fin_preavis IS NULL) OR (fin_preavis >= debut_preavis)));
alter table "RUPTURES_CONTRAT" add constraint waiver_compensation_positive CHECK (((compensation_renonciation IS NULL) OR (compensation_renonciation >= (0)::numeric)));
alter table "RUPTURES_CONTRAT" add constraint waiver_needs_agreement_date CHECK (((NOT preavis_renonce) OR (renonciation_convenue_le IS NOT NULL)));
alter table "SALARIES" add constraint employee_email_shape CHECK (((courriel IS NULL) OR (courriel ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text)));
alter table "SANCTIONS_SALARIE" add constraint sanction_dates_order CHECK (((effet_au IS NULL) OR (effet_du IS NULL) OR (effet_au >= effet_du)));
alter table "SANCTIONS_SALARIE" add constraint sanction_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table "SANCTIONS_SALARIE" add constraint sanction_known_after_facts CHECK ((faits_connus_le >= faits_le));
alter table "SANCTIONS_SALARIE" add constraint sanction_notified_after_know CHECK (((notifie_le IS NULL) OR (notifie_le >= faits_connus_le)));
alter table "SERVICES" add constraint coverage_positive CHECK (((couverture_soir_min IS NULL) OR (couverture_soir_min >= 0)));
alter table "SINISTRES_ACCIDENT_SOCIETE" add constraint accident_counts_positive CHECK (((nombre_sinistres >= 0) AND (jours_perdus >= 0) AND ((cout IS NULL) OR (cout >= (0)::numeric))));
alter table "SITES_CLIENT" add constraint client_site_has_an_address CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table "SOCIETES" add constraint ccss_matricule_format CHECK (((matricule_ccss IS NULL) OR (matricule_ccss ~ '^[0-9]{13}$'::text)));
alter table "SOCIETES" add constraint societes_reference_period_po CHECK ((periode_reference_mois >= 1));
alter table "STATUTS_SALARIE" add constraint status_range CHECK (((date_fin IS NULL) OR (date_fin >= date_debut)));
alter table "STATUTS_SALARIE" add constraint statuts_salarie_periode_cohe CHECK ((date_fin >= date_debut));
alter table "TRANCHES_IMPOT" add constraint bracket_range CHECK (((tranche_max IS NULL) OR (tranche_max > tranche_min)));
alter table "TRANCHES_IMPOT" add constraint bracket_validity CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "TRANCHES_IMPOT" add constraint tranches_impot_periode_valid CHECK ((fin_validite > debut_validite));
alter table "TYPES_SANCTION" add constraint sanction_type_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table "TYPES_SANCTION" add constraint types_sanction_periode_valid CHECK ((fin_validite > debut_validite));
alter table "ZONES_ADRESSE" add constraint address_zone_range CHECK (((code_postal_au IS NULL) OR (code_postal_du IS NULL) OR (code_postal_au >= code_postal_du)));
alter table "ZONES_ADRESSE" add constraint address_zone_verified_needs_ CHECK (((NOT verifie) OR ((code_postal_du IS NOT NULL) AND (code_postal_au IS NOT NULL))));

-- ------------------------------------------------------------------
-- COMMENTAIRES — 75 table(s) et 836 colonne(s).
-- Repris tels quels du schéma PostgreSQL, qui fait foi.
-- ------------------------------------------------------------------
comment on table "ABSENCES" is 'Absence d''un salarié : congé, maladie, congé extraordinaire. Le moteur en contrôle le droit, l''imputation et les justificatifs.';
comment on column "ABSENCES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ABSENCES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ABSENCES"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ABSENCES"."TYPE_ABSENCE_ID" is 'Type d''absence demandé. Détermine les pièces exigées, le délai de certificat et l''imputation sur les compteurs.';
comment on column "ABSENCES"."DATE_DEBUT" is 'Premier jour d''absence, inclus. Jour entier : une absence d''une demi-journée se compte par days_count, pas par les bornes.';
comment on column "ABSENCES"."DATE_FIN" is 'Dernier jour d''absence, INCLUS — contrairement aux bornes de validité du référentiel, qui sont exclusives. Une absence d''un seul jour porte la même date en début et en fin.';
comment on column "ABSENCES"."NOMBRE_JOURS" is 'Jours décomptés, calculés hors fériés et jours non ouvrés — pas la simple différence de dates.';
comment on column "ABSENCES"."STATUT" is 'Où en est la demande : proposé, en attente, validé, refusé, annulé. Un refus n''est jamais un point final — il doit s''accompagner d''une contre-proposition, chaînée par absence_parente_id.';
comment on column "ABSENCES"."COMMENTAIRE" is 'Motif ou précision donnée par le demandeur. Visible du salarié comme du gestionnaire : ce n''est pas une note interne.';
comment on column "ABSENCES"."CERTIFICAT_RECU" is 'Vrai dès réception du certificat, sous quelque forme que ce soit.';
comment on column "ABSENCES"."CERTIFICAT_RECU_LE" is 'Date de réception du certificat, original ou copie. C''est elle qui arrête le décompte du délai CCSS, pas la date d''émission du certificat.';
comment on column "ABSENCES"."CERTIFICAT_DOCUMENT_ID" is 'Pièce justificative rattachée. Sans clé étrangère stricte vers un document supprimé : l''absence reste lisible même si la pièce a été purgée.';
comment on column "ABSENCES"."DEMANDE_PAR" is 'Compte à l''origine de la demande. Peut différer du salarié : un gestionnaire saisit pour un salarié sans accès, et il faut savoir qui a saisi.';
comment on column "ABSENCES"."DECIDE_PAR" is 'Auteur de la décision d''acceptation ou de refus.';
comment on column "ABSENCES"."DECIDE_LE" is 'Horodatage de la décision. Avec decided_by, répond à « qui a tranché, et quand » — une validation d''absence est un acte opposable.';
comment on column "ABSENCES"."NOTE_DECISION" is 'Motivation de la décision, restituée au salarié.';
comment on column "ABSENCES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ABSENCES"."DECLARE_PAR_SALARIE" is 'Vrai si la déclaration vient de l''espace salarié, faux si elle est saisie par les RH.';
comment on column "ABSENCES"."CERTIFICAT_DEPOSE_LE" is 'Dépôt numérique du certificat par le salarié.';
comment on column "ABSENCES"."CERTIFICAT_ORIGINAL_RECU" is 'Réception de l''original papier, exigée séparément du dépôt numérique.';
comment on column "ABSENCES"."CERTIFICAT_ORIGINAL_RECU_LE" is 'Date de réception de l''ORIGINAL papier. Distincte de la copie : la CCSS exige l''original, et seule cette date solde l''obligation.';
comment on column "ABSENCES"."ENFANT_ID" is 'Enfant concerné, pour un congé lié à un enfant.';
comment on column "ABSENCES"."ABSENCE_PARENTE_ID" is 'Proposition que celle-ci remplace. Chaîne la demande initiale et les contre-propositions successives : c''est l''historique de la négociation, lisible dans les deux sens.';
comment on column "ABSENCES"."PROPOSEE_PAR" is 'Qui a formulé cette proposition : « salarie » pour la demande initiale, « employeur » pour une contre-proposition.';
comment on column "ABSENCES"."RANG_PROPOSITION" is 'Profondeur dans la chaîne. Zéro pour la demande initiale. Borné, pour qu''une négociation sans fin ne soit pas possible.';
comment on table "ADRESSES_SALARIE" is 'Les quatre adresses du salarié, historisées. Chaque type doit couvrir toute la période sans trou ni recouvrement, depuis la candidature jusqu''à bien après le départ : une erreur de salaire découverte plus tard suppose de pouvoir écrire à la personne.';
comment on column "ADRESSES_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ADRESSES_SALARIE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ADRESSES_SALARIE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ADRESSES_SALARIE"."TYPE_ADRESSE" is 'Nature de l''adresse, parmi ref_type_adresse : domicile légal, résidence effective, correspondance, facturation. Les quatre doivent être couvertes sans trou depuis la candidature jusqu''après le départ — une erreur de salaire découverte plus tard doit pouvoir être notifiée.';
comment on column "ADRESSES_SALARIE"."LIGNE" is 'Rue et numéro. Une seule ligne : le découpage varie trop d''un pays à l''autre pour être imposé.';
comment on column "ADRESSES_SALARIE"."CODE_POSTAL" is 'Code postal. Confronté au référentiel des localités : un code incohérent est signalé, jamais corrigé d''office.';
comment on column "ADRESSES_SALARIE"."LOCALITE" is 'Localité, telle qu''elle doit figurer sur un courrier.';
comment on column "ADRESSES_SALARIE"."PAYS" is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU. Trois lettres partout dans l''application.';
comment on column "ADRESSES_SALARIE"."LATITUDE" is 'Latitude en degrés décimaux, obtenue par géocodage. Sert au calcul des distances de tournée et à l''indemnité kilométrique ; nulle tant que l''adresse n''a pas été géocodée.';
comment on column "ADRESSES_SALARIE"."LONGITUDE" is 'Longitude en degrés décimaux. Voir latitude : le couple n''a de sens que complet.';
comment on column "ADRESSES_SALARIE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "ADRESSES_SALARIE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "ADRESSES_SALARIE"."ORIGINE" is 'D''où vient la ligne : « saisie » pour une saisie directe, « copie_domicile » pour une recopie automatique du domicile légal, « import » pour une reprise.';
comment on column "ADRESSES_SALARIE"."NOTE" is 'Précision de livraison ou de contact : étage, digicode, « chez ». Jamais une donnée de calcul.';
comment on column "ADRESSES_SALARIE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ADRESSES_SALARIE"."CREE_PAR" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "ADRESSES_SALARIE"."SUPPRIME_LE" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "ADRESSES_SALARIE"."SUPPRIME_PAR" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "AGENCES_INTERIM" is 'Agence de travail intérimaire, employeur juridique d''un salarié en mission chez une société utilisatrice.';
comment on column "AGENCES_INTERIM"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "AGENCES_INTERIM"."ORGANISATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "AGENCES_INTERIM"."NOM" is 'Raison sociale de l''agence d''intérim, telle qu''elle figure au contrat de mise à disposition.';
comment on column "AGENCES_INTERIM"."MATRICULE_CCSS" is 'Matricule CCSS de l''agence. C''est elle qui déclare le salarié, pas l''entreprise utilisatrice.';
comment on column "AGENCES_INTERIM"."NUMERO_RCS" is 'Numéro au registre de commerce. Permet de vérifier qu''une agence est autorisée avant de lui confier une mission.';
comment on column "AGENCES_INTERIM"."LIGNE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "AGENCES_INTERIM"."CODE_POSTAL" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "AGENCES_INTERIM"."LOCALITE" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "AGENCES_INTERIM"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "ALERTES_CONFORMITE" is 'Constats du moteur de vigilance. Chaque alerte porte son article : c''est ce qui distingue un avertissement d''une injonction opaque.';
comment on column "ALERTES_CONFORMITE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ALERTES_CONFORMITE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ALERTES_CONFORMITE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ALERTES_CONFORMITE"."CODE_REGLE" is 'Code stable de la règle, pour suivre une alerte à travers les scans successifs.';
comment on column "ALERTES_CONFORMITE"."TITRE" is 'Intitulé court de l''alerte, tel qu''il apparaît dans la liste de vigilance.';
comment on column "ALERTES_CONFORMITE"."DETAIL" is 'Explication complète : ce qui manque, pourquoi c''est exigé, et ce qu''il faut faire. Une alerte qui ne dit pas quoi faire ne sera pas traitée.';
comment on column "ALERTES_CONFORMITE"."CONSEQUENCE" is 'Ce qui arrive si rien n''est fait — sanction, requalification, nullité.';
comment on column "ALERTES_CONFORMITE"."REFERENCE_LEGALE" is 'Article qui fonde le constat.';
comment on column "ALERTES_CONFORMITE"."SEVERITE" is 'Gravité, qui commande le tri et la couleur à l''écran.';
comment on column "ALERTES_CONFORMITE"."DATE_ECHEANCE" is 'Échéance à laquelle le manquement devient effectif.';
comment on column "ALERTES_CONFORMITE"."ETAT" is 'État de traitement : ouverte, traitée, écartée.';
comment on column "ALERTES_CONFORMITE"."TRAITE_PAR" is 'Compte ayant traité l''alerte. Nul tant qu''elle est ouverte.';
comment on column "ALERTES_CONFORMITE"."TRAITE_LE" is 'Date de traitement. Avec handled_by, permet de mesurer le délai de réaction — la sévérité CCSS s''appuie dessus.';
comment on column "ALERTES_CONFORMITE"."NOTE_TRAITEMENT" is 'Justification de la prise en charge ou de la mise à l''écart.';
comment on column "ALERTES_CONFORMITE"."VU_LA_PREMIERE_FOIS_LE" is 'Première apparition du constat, conservée même si l''alerte réapparaît.';
comment on table "ATTRIBUTIONS_TITRES_REPAS" is 'Attribution de chèques-repas sur une période. La valeur faciale et la participation salariale sont contrôlées contre les limites du référentiel.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."DEBUT_PERIODE" is 'Premier jour de la période d''attribution, inclus.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."FIN_PERIODE" is 'Dernier jour de la période, INCLUS.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."NOMBRE_TITRES" is 'Nombre de chèques attribués sur la période.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."VALEUR_FACIALE" is 'Valeur faciale du chèque.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."PART_SALARIALE" is 'Part supportée par le salarié : c''est elle qui conditionne le régime fiscal de l''avantage.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."ATTRIBUE_LE" is 'Date de remise effective des titres. Distincte de la période qu''ils couvrent.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."NOTE" is 'Précisions sur le calcul du nombre de titres, notamment les jours d''absence déduits.';
comment on column "ATTRIBUTIONS_TITRES_REPAS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "AVENANTS_CONTRAT" is 'Avenant. Conserve ce qui a changé et à partir de quand, sans écraser l''état antérieur du contrat.';
comment on column "AVENANTS_CONTRAT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "AVENANTS_CONTRAT"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "AVENANTS_CONTRAT"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "AVENANTS_CONTRAT"."DATE_EFFET" is 'Prise d''effet, qui peut différer de la signature.';
comment on column "AVENANTS_CONTRAT"."MOTIF" is 'Motif de l''avenant, obligatoire. Un avenant sans motif est refusé par le moteur : c''est la pièce qui explique, des années après, pourquoi le contrat a changé.';
comment on column "AVENANTS_CONTRAT"."MODIFICATIONS" is 'Différentiel appliqué, en jsonb : ce que l''avenant modifie, et rien d''autre.';
comment on column "AVENANTS_CONTRAT"."CREE_PAR" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "AVENANTS_CONTRAT"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "CATEGORIES_SANCTION" is 'Les trois degrés de la sanction disciplinaire. Table de référence datée plutôt qu''énumération : un degré peut être renommé, ajouté ou retiré par DML, sans migration ni indisponibilité.';
comment on column "CATEGORIES_SANCTION"."CODE" is 'Code de la catégorie de sanction : mineure, lourde, rupture. Trois catégories, qui commandent la procédure exigée.';
comment on column "CATEGORIES_SANCTION"."LIBELLE" is 'Libellé de la catégorie à l''écran.';
comment on column "CATEGORIES_SANCTION"."RANG" is 'Gravité croissante. Sert à ordonner, jamais à décider : c''est le type de sanction qui porte les règles.';
comment on column "CATEGORIES_SANCTION"."DESCRIPTION" is 'Ce que la catégorie implique en matière de procédure, d''entretien préalable et de recours. C''est la colonne que lit un gestionnaire avant de choisir.';
comment on column "CATEGORIES_SANCTION"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CATEGORIES_SANCTION"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "CCT_REGLE_PRIME" is 'Règle de prime de condition telle que la convention collective la fixe. Aucune valeur légale générale ici : la loi ne définit pas ces primes, seules les CCT le font. Une règle sans source_url est refusée — elle ne pourrait pas être vérifiée.';
comment on column "CCT_REGLE_PRIME"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CCT_REGLE_PRIME"."CONVENTION_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CCT_REGLE_PRIME"."CONDITION_CODE" is 'Condition matérielle ouvrant droit à la prime, parmi ref_condition_travail : pénibilité, insalubrité, danger. Ces primes ne sont pas prévues par la loi générale — ce sont les conventions sectorielles qui les fixent.';
comment on column "CCT_REGLE_PRIME"."NATURE_PRIME" is 'Nature de la prime, parmi ref_nature_prime. Détermine son traitement fiscal et social.';
comment on column "CCT_REGLE_PRIME"."LIBELLE" is 'Intitulé de la règle tel qu''il apparaît dans la convention. Repris dans le détail du calcul, pour que le montant soit rattachable à son article.';
comment on column "CCT_REGLE_PRIME"."TAUX_PCT" is 'Taux appliqué à l''assiette. Exclusif du montant : une règle qui porterait les deux serait ambiguë, et la contrainte l''interdit.';
comment on column "CCT_REGLE_PRIME"."MONTANT" is 'Montant forfaitaire en euros, par unité. Exclusif de taux_pct : une règle est soit un forfait, soit un pourcentage, jamais les deux.';
comment on column "CCT_REGLE_PRIME"."ASSIETTE" is 'Base sur laquelle s''applique le pourcentage : salaire mensuel ou salaire horaire. Obligatoire dès qu''un taux est fixé ; une assiette que le moteur ne sait pas résoudre ressort en « non calculable » plutôt qu''en zéro.';
comment on column "CCT_REGLE_PRIME"."UNITE" is 'Ce à quoi la prime se rapporte, parmi ref_unite_prime : heure exposée, jour, mois, ou prestation. Détermine comment le temps relevé se convertit en montant.';
comment on column "CCT_REGLE_PRIME"."SEUIL_MINUTES" is 'Durée minimale d''exposition ouvrant le droit. Zéro si la moindre minute compte.';
comment on column "CCT_REGLE_PRIME"."CATEGORIE_VISEE" is 'Catégorie professionnelle à laquelle la règle se limite. Nulle si la règle vaut pour tous les salariés couverts par la convention.';
comment on column "CCT_REGLE_PRIME"."ARTICLE" is 'Article de la convention qui fonde la règle. C''est lui que l''application cite au salarié.';
comment on column "CCT_REGLE_PRIME"."URL_SOURCE" is 'Lien vers le texte déposé — les conventions luxembourgeoises sont publiées par l''ITM. Obligatoire.';
comment on column "CCT_REGLE_PRIME"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "CCT_REGLE_PRIME"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CCT_REGLE_PRIME"."NOTE" is 'Précisions d''application : cumul, proratisation, exclusions. Ce que l''article dit et que les colonnes ne portent pas.';
comment on table "COMPTES" is 'Comptes applicatifs. Point d''ancrage commun aux trois moteurs : sur PostgreSQL elle reflète auth.users et password_hash reste nul, l''authentification appartenant à Supabase ; sur Oracle et MySQL elle porte le mot de passe et devient la table d''identité vers laquelle pointent les clés étrangères d''auteur.';
comment on column "COMPTES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPTES"."IDENTIFIANT" is 'Identifiant de connexion, en minuscules. Unique parmi les comptes vivants seulement : un identifiant libéré par une suppression logique peut être réattribué.';
comment on column "COMPTES"."COURRIEL" is 'Adresse de connexion et de notification. Unique : c''est elle qui identifie le compte pour la récupération de mot de passe.';
comment on column "COMPTES"."NOM_COMPLET" is 'Nom affiché du compte. Modifiable par l''intéressé en libre-service, contrairement aux données d''identité du dossier salarié.';
comment on column "COMPTES"."EMPREINTE_MOT_DE_PASSE" is 'Empreinte bcrypt du mot de passe. NUL sur PostgreSQL/Supabase, où Auth détient le secret. Jamais le mot de passe en clair, à aucun moment.';
comment on column "COMPTES"."EST_ADMIN" is 'Administrateur : seul habilité à lire le catalogue du schéma et à créer d''autres comptes.';
comment on column "COMPTES"."COMPTE_AUTH_ID" is 'Compte auth.users correspondant, quand l''application tourne sur Supabase. Nul sur une cible autonome.';
comment on column "COMPTES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "COMPTES"."CREE_PAR" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "COMPTES"."MODIFIE_LE" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column "COMPTES"."MODIFIE_PAR" is 'Compte auteur de la dernière modification. Sur une table de comptes, savoir qui a changé quoi n''est pas optionnel.';
comment on column "COMPTES"."SUPPRIME_LE" is 'Suppression logique : la ligne reste, les clés étrangères qui la référencent tiennent, et le journal demeure lisible. Un compte parti doit encore pouvoir répondre de ce qu''il a fait.';
comment on column "COMPTES"."SUPPRIME_PAR" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "CONTRATS" is 'Contrat de travail. Le brouillon vit ici dès la première étape de l''assistant : c''est cette ligne que le moteur évalue, pas un objet en mémoire du navigateur.';
comment on column "CONTRATS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRATS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTRATS"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "CONTRATS"."GENRE" is 'Type de contrat : CDI, CDD, apprentissage, saisonnier, intérim, étudiant. Commande les clauses obligatoires et les contrôles.';
comment on column "CONTRATS"."STATUT" is 'Brouillon, actif, terminé. Un brouillon n''engage rien mais se contrôle déjà.';
comment on column "CONTRATS"."INTITULE_POSTE" is 'Intitulé du poste tel qu''il figure au contrat. Mention obligatoire : il fonde la classification conventionnelle, et donc le salaire minimum applicable.';
comment on column "CONTRATS"."DESCRIPTION_POSTE" is 'Description des fonctions. Sa précision détermine ce qu''un changement de tâches doit faire passer par un avenant plutôt que par une simple instruction.';
comment on column "CONTRATS"."LIEU_TRAVAIL" is 'Lieu d''exécution convenu. Mention obligatoire au contrat.';
comment on column "CONTRATS"."CATEGORIE" is 'Catégorie professionnelle, clé d''entrée dans la grille salariale conventionnelle.';
comment on column "CONTRATS"."DATE_DEBUT" is 'Prise d''effet du contrat, jour inclus. Point de départ de l''ancienneté, de la période d''essai et du droit à congé.';
comment on column "CONTRATS"."DATE_FIN" is 'Dernier jour du contrat, borne haute INCLUSE : le contrat est en cours le jour J si date_fin >= J. Jamais nulle — un contrat à durée indéterminée porte la sentinelle 2037-12-31, qui se lit « fin inconnue » et non « fin en 2037 ». Le caractère déterminé ou non de la durée se lit sur genre, pas sur cette date.';
comment on column "CONTRATS"."MOTIF_CDD" is 'Motif de recours au CDD. Un CDD sans motif licite est requalifiable.';
comment on column "CONTRATS"."NOMBRE_RENOUVELLEMENTS" is 'Nombre de renouvellements déjà consommés, borné par la loi.';
comment on column "CONTRATS"."CONTRAT_PRECEDENT_ID" is 'Contrat que celui-ci renouvelle, pour reconstituer la chaîne et l''ancienneté.';
comment on column "CONTRATS"."BRUT_MENSUEL" is 'Salaire mensuel brut convenu, hors éléments variables portés par contract_pay_components.';
comment on column "CONTRATS"."INDICE_REFERENCE" is 'Cote d''indice à la signature, pour distinguer une hausse réelle d''une indexation.';
comment on column "CONTRATS"."HEURES_HEBDOMADAIRES" is 'Durée hebdomadaire convenue. Sous le plein temps, is_part_time devient vrai.';
comment on column "CONTRATS"."JOURS_PAR_SEMAINE" is 'Nombre de jours travaillés par semaine, décimal pour les rythmes irréguliers.';
comment on column "CONTRATS"."REPARTITION_TRAVAIL" is 'Répartition convenue de l''horaire. Mention obligatoire au contrat pour un temps partiel.';
comment on column "CONTRATS"."PERIODE_REFERENCE_MOIS" is 'Période de référence propre au contrat, si elle déroge à celle de la société.';
comment on column "CONTRATS"."TRAVAIL_NUIT" is 'Vrai si le poste comporte du travail de nuit, qui ouvre ses propres protections.';
comment on column "CONTRATS"."JOURS_CONGE_ANNUEL" is 'Congé annuel convenu lorsqu''il dépasse le minimum légal. Nul renvoie au droit commun.';
comment on column "CONTRATS"."PAUSE_MINUTES" is 'Pause convenue par journée de travail.';
comment on column "CONTRATS"."CLAUSE_NON_CONCURRENCE" is 'Présence d''une clause de non-concurrence, dont la validité est soumise à conditions.';
comment on column "CONTRATS"."CLAUSE_EXCLUSIVITE" is 'Présence d''une clause d''exclusivité.';
comment on column "CONTRATS"."DUREE_ESSAI" is 'Durée de la période d''essai, exprimée dans l''unité portée par probation_unit.';
comment on column "CONTRATS"."UNITE_ESSAI" is 'Unité de la période d''essai : mois ou semaines. Les bornes légales diffèrent selon l''unité.';
comment on column "CONTRATS"."VERSION" is 'Version du contrat, incrémentée par les avenants.';
comment on column "CONTRATS"."SIGNE_LE" is 'Date de signature. Un contrat actif sans date de signature est un manquement.';
comment on column "CONTRATS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CONTRATS"."EST_TEMPS_PARTIEL" is 'Temps partiel, tenu à jour par le déclencheur fn_sync_part_time — ne pas écrire à la main.';
comment on column "CONTRATS"."NIVEAU_APPRENTISSAGE" is 'Niveau de la formation, pour un contrat d''apprentissage.';
comment on column "CONTRATS"."ANNEE_APPRENTISSAGE" is 'Année du cycle d''apprentissage, qui commande l''indemnité.';
comment on column "CONTRATS"."LIBELLE_SAISON" is 'Saison couverte, pour un contrat saisonnier.';
comment on column "CONTRATS"."AGENCE_INTERIM_ID" is 'Agence d''intérim employeuse, pour un contrat de mission.';
comment on column "CONTRATS"."NOM_SOCIETE_UTILISATEUR" is 'Société utilisatrice chez qui la mission s''exécute.';
comment on column "CONTRATS"."MOTIF_MISSION" is 'Motif de recours à l''intérim, soumis aux mêmes exigences que le motif de CDD.';
comment on table "CONTROLES_ADRESSE" is 'Dernier verdict de validation d''adresse par objet. Une adresse « unknown » y reste visible : c''est ce qui permet de la reprendre plus tard, plutôt que de la croire vérifiée.';
comment on column "CONTROLES_ADRESSE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTROLES_ADRESSE"."ENTITE_TABLE" is 'Table de la ligne vérifiée — employees, companies, client_sites. Le contrôle d''adresse est le même pour toutes ; cette colonne dit d''où vient celle-ci.';
comment on column "CONTROLES_ADRESSE"."ENTITE_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "CONTROLES_ADRESSE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTROLES_ADRESSE"."PAYS" is 'Code pays ISO 3166-1 alpha-3.';
comment on column "CONTROLES_ADRESSE"."CODE_POSTAL" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "CONTROLES_ADRESSE"."STATUT" is 'Résultat du contrôle, parmi ref_statut_verification_adresse : vérifiée, incohérente, hors périmètre, non vérifiable. « Non vérifiable » est un résultat, pas un échec : LuxRH ne couvre que le Luxembourg et les zones frontalières déclarées.';
comment on column "CONTROLES_ADRESSE"."CODE_ZONE" is 'Zone reconnue pour cette adresse : Luxembourg, ou zone frontalière déclarée. Détermine le régime de frontalier et les barèmes applicables.';
comment on column "CONTROLES_ADRESSE"."MESSAGE" is 'Explication du résultat, destinée à l''humain qui corrigera. Une adresse rejetée sans motif ne se corrige pas.';
comment on column "CONTROLES_ADRESSE"."CONTROLE_LE" is 'Date du contrôle. Un référentiel postal évolue : un contrôle ancien ne vaut pas contrôle actuel.';
comment on table "CONVENTIONS_COLLECTIVES" is 'Convention collective de travail. Sectorielle et partagée, ou propre à une organisation.';
comment on column "CONVENTIONS_COLLECTIVES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONVENTIONS_COLLECTIVES"."ORGANISATION_ID" is 'Nul pour une convention sectorielle partagée par toutes les organisations.';
comment on column "CONVENTIONS_COLLECTIVES"."CODE" is 'Code court, clé naturelle utilisée par l''export et l''import du référentiel.';
comment on column "CONVENTIONS_COLLECTIVES"."NOM" is 'Intitulé officiel de la convention, tel que publié par l''ITM.';
comment on column "CONVENTIONS_COLLECTIVES"."SECTEUR" is 'Secteur couvert. Sert à proposer la bonne convention lors du rattachement d''une société, jamais à l''imposer.';
comment on column "CONVENTIONS_COLLECTIVES"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CONVENTIONS_COLLECTIVES"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CONVENTIONS_COLLECTIVES"."ACTIF" is 'Faux quand la convention est dénoncée ou remplacée. Elle reste en base : une paie ancienne doit encore pouvoir citer la convention qui la fondait.';
comment on column "CONVENTIONS_COLLECTIVES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CONVENTIONS_COLLECTIVES"."PORTEE" is 'Portée : sectorielle, d''entreprise, ou d''établissement.';
comment on column "CONVENTIONS_COLLECTIVES"."REMPLACE_ID" is 'Convention que celle-ci remplace, pour suivre les renouvellements.';
comment on column "CONVENTIONS_COLLECTIVES"."CATEGORIE_PROFESSIONNELLE" is 'Catégorie de personnel visée lorsque la convention ne couvre pas tout l''effectif.';
comment on table "CONVENTIONS_DE_LA_SOCIETE" is 'Rattachement d''une société, ou d''un de ses services, à une convention collective, sur une période donnée. Une société peut en appliquer plusieurs simultanément.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."CONVENTION_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."SERVICE_ID" is 'Nul si la convention couvre toute la société.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."NOTE" is 'Circonstances du rattachement de la société à la convention : adhésion, extension, usage. Ce qui permet de le contester.';
comment on column "CONVENTIONS_DE_LA_SOCIETE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "CONVENTIONS_DU_CONTRAT" is 'Conventions applicables à un contrat donné, sur une période. Plusieurs conventions peuvent se cumuler ; le moteur retient la disposition la plus favorable et dit laquelle a gagné.';
comment on column "CONVENTIONS_DU_CONTRAT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONVENTIONS_DU_CONTRAT"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "CONVENTIONS_DU_CONTRAT"."CONVENTION_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CONVENTIONS_DU_CONTRAT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CONVENTIONS_DU_CONTRAT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CONVENTIONS_DU_CONTRAT"."NOTE" is 'Circonstances du rattachement au niveau du contrat, quand il déroge à celui de la société.';
comment on column "CONVENTIONS_DU_CONTRAT"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "CREDITS_IMPOT" is 'Crédits d''impôt, avec leur plage de revenu et les classes auxquelles ils s''appliquent.';
comment on column "CREDITS_IMPOT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CREDITS_IMPOT"."CODE" is 'Code du crédit d''impôt, stable, repris par le calcul de la retenue.';
comment on column "CREDITS_IMPOT"."LIBELLE" is 'Libellé du crédit tel qu''il apparaît sur le bulletin.';
comment on column "CREDITS_IMPOT"."CLASSES_VISEES" is 'Classes d''impôt ouvrant droit au crédit.';
comment on column "CREDITS_IMPOT"."REVENU_MIN" is 'Revenu à partir duquel le crédit est ouvert.';
comment on column "CREDITS_IMPOT"."REVENU_MAX" is 'Revenu au-delà duquel le crédit s''éteint.';
comment on column "CREDITS_IMPOT"."MONTANT_MENSUEL" is 'Montant mensuel du crédit, en euros. Nul quand le crédit ne se traduit pas par un montant fixe.';
comment on column "CREDITS_IMPOT"."PRORATISE_SUR_HEURES" is 'Vrai si le crédit se réduit au prorata du temps de travail.';
comment on column "CREDITS_IMPOT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CREDITS_IMPOT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CREDITS_IMPOT"."SOURCE" is 'Publication d''origine du montant. Obligatoire pour la même raison que sur tax_brackets.';
comment on column "CREDITS_IMPOT"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "CREDITS_IMPOT"."NOTE" is 'Conditions d''octroi et cumul avec les autres crédits.';
comment on table "CRENEAU_CONDITION" is 'Créneau réellement travaillé sous une condition ouvrant droit à prime : qui, quand, où, de quelle heure à quelle heure. C''est ce relevé qui rend la prime calculable — sans lui, la règle conventionnelle reste lettre morte.';
comment on column "CRENEAU_CONDITION"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CRENEAU_CONDITION"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CRENEAU_CONDITION"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "CRENEAU_CONDITION"."CRENEAU_ID" is 'Vacation planifiée. Le créneau se saisit au planning, puis se confirme au registre du temps.';
comment on column "CRENEAU_CONDITION"."RELEVE_TEMPS_ID" is 'Journée du registre du temps. C''est elle qui fait foi pour le paiement, le planning n''étant qu''une prévision.';
comment on column "CRENEAU_CONDITION"."SITE_CLIENT_ID" is 'Site client où la condition a été constatée. Nul pour une condition constatée dans les locaux de l''employeur.';
comment on column "CRENEAU_CONDITION"."CONDITION_CODE" is 'Condition constatée, parmi ref_condition_travail. C''est le constat qui ouvre le droit, pas le poste : un même salarié peut être exposé un jour et pas le lendemain.';
comment on column "CRENEAU_CONDITION"."DATE_PRESTATION" is 'Jour de la prestation. La règle conventionnelle applicable est celle en vigueur ce jour-là, pas celle d''aujourd''hui.';
comment on column "CRENEAU_CONDITION"."HEURE_DEBUT" is 'Heure de début d''exposition. Avec heure_fin, donne la durée qui sert au seuil et à la conversion en montant.';
comment on column "CRENEAU_CONDITION"."HEURE_FIN" is 'Heure de fin d''exposition. Un créneau ne franchit pas minuit : une exposition de nuit se saisit en deux créneaux.';
comment on column "CRENEAU_CONDITION"."MINUTES" is 'Durée exposée, calculée par la base. Un créneau qui franchit minuit est compté correctement.';
comment on column "CRENEAU_CONDITION"."CONSTATE_PAR" is 'Compte ayant constaté la condition. Une prime de pénibilité repose sur un constat : il a un auteur.';
comment on column "CRENEAU_CONDITION"."NOTE" is 'Circonstances du constat. Utile en cas de contestation, jamais utilisée par le calcul.';
comment on column "CRENEAU_CONDITION"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CRENEAU_CONDITION"."SUPPRIME_LE" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "CRENEAU_CONDITION"."SUPPRIME_PAR" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "CRENEAUX" is 'Vacation planifiée : un salarié, une date, des horaires. C''est l''unité que le moteur contrôle contre les repos et les durées maximales.';
comment on column "CRENEAUX"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CRENEAUX"."PLANNING_ID" is 'Planning auquel le créneau appartient. Un créneau n''existe pas hors d''un planning : c''est le planning qui porte le statut brouillon ou publié.';
comment on column "CRENEAUX"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CRENEAUX"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "CRENEAUX"."DATE_CRENEAU" is 'Jour du créneau. Un créneau qui déborde sur le lendemain porte la date de son début.';
comment on column "CRENEAUX"."HEURE_DEBUT" is 'Heure de début. Avec la durée, détermine les majorations de nuit, de dimanche et de jour férié.';
comment on column "CRENEAUX"."HEURE_FIN" is 'Heure de fin. Antérieure à start_time pour une vacation qui franchit minuit — fn_shift_end_ts résout le cas.';
comment on column "CRENEAUX"."PAUSE_MINUTES" is 'Pause de la vacation, déduite des heures travaillées.';
comment on column "CRENEAUX"."LIBELLE" is 'Précision sur le créneau : chantier, tournée, remplacement. Affichée au salarié.';
comment on column "CRENEAUX"."MODELE_ID" is 'Modèle dont la vacation est issue, s''il y en a un.';
comment on column "CRENEAUX"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CRENEAUX"."SITE_CLIENT_ID" is 'Lieu d''exécution de la vacation. Nul signifie « au siège de la société » — c''est le cas courant, et c''est aussi la référence à laquelle un dépassement se mesure.';
comment on table "DEMANDES_HEURES_SUP" is 'Demande d''heures supplémentaires. Elle exige un double accord : validation RH et acceptation du salarié.';
comment on column "DEMANDES_HEURES_SUP"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DEMANDES_HEURES_SUP"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DEMANDES_HEURES_SUP"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "DEMANDES_HEURES_SUP"."PLANNING_ID" is 'Planning auquel la demande se rattache, s''il y en a un.';
comment on column "DEMANDES_HEURES_SUP"."DEBUT_PERIODE" is 'Premier jour de la période couverte par la demande, inclus.';
comment on column "DEMANDES_HEURES_SUP"."FIN_PERIODE" is 'Dernier jour de la période, INCLUS.';
comment on column "DEMANDES_HEURES_SUP"."HEURES" is 'Nombre d''heures supplémentaires demandées sur la période.';
comment on column "DEMANDES_HEURES_SUP"."MOTIF" is 'Motif du recours aux heures supplémentaires, obligatoire. L''ITM peut le demander : les heures supplémentaires ne sont pas de droit.';
comment on column "DEMANDES_HEURES_SUP"."STATUT" is 'État de la demande. hr_approved ne suffit pas : tant que le salarié n''a pas accepté, les heures ne sont pas couvertes.';
comment on column "DEMANDES_HEURES_SUP"."DEMANDE_PAR" is 'Compte à l''origine de la demande, généralement l''employeur.';
comment on column "DEMANDES_HEURES_SUP"."DEMANDE_LE" is 'Horodatage du dépôt. Le délai de notification se compte à partir de là.';
comment on column "DEMANDES_HEURES_SUP"."VALIDE_RH_PAR" is 'Compte ayant validé côté ressources humaines, avant transmission éventuelle à l''ITM.';
comment on column "DEMANDES_HEURES_SUP"."VALIDE_RH_LE" is 'Horodatage de la validation RH.';
comment on column "DEMANDES_HEURES_SUP"."ACCEPTE_PAR_SALARIE_LE" is 'Horodatage de l''acceptation par le salarié.';
comment on column "DEMANDES_HEURES_SUP"."MOTIF_REFUS" is 'Motif du refus, restitué à l''auteur de la demande.';
comment on column "DEMANDES_HEURES_SUP"."COMPENSATION" is 'Mode de compensation retenu : repos compensateur ou paiement majoré.';
comment on column "DEMANDES_HEURES_SUP"."NOTE" is 'Précisions sur les circonstances ou sur la compensation retenue.';
comment on table "DISTANCES_TRAJET" is 'Distances routières mises en cache. Une adresse n''est transmise au service tiers qu''au premier calcul d''un couple ; les plannings suivants lisent cette table.';
comment on column "DISTANCES_TRAJET"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DISTANCES_TRAJET"."REFERENCE_ORIGINE" is 'Référence de l''origine, sous la forme « employee:<uuid> », « company:<uuid> » ou « site:<uuid> ». Aucune adresse n''est recopiée ici.';
comment on column "DISTANCES_TRAJET"."REFERENCE_DESTINATION" is 'Référence de la destination : site client, société, ou adresse saisie. Le trajet se calcule depuis une adresse du salarié vers cette destination.';
comment on column "DISTANCES_TRAJET"."DISTANCE_KM" is 'Distance routière en kilomètres, telle que renvoyée par le service d''itinéraire. Ce n''est pas la distance à vol d''oiseau : c''est celle qui fonde l''indemnité.';
comment on column "DISTANCES_TRAJET"."DUREE_MINUTES" is 'Durée estimée du trajet. Indicative : elle sert à construire les tournées, pas à rémunérer.';
comment on column "DISTANCES_TRAJET"."SOURCE" is 'Origine de la mesure : nom du service consulté, ou « manuel » si la distance a été saisie. Une distance sans source ne doit pas servir à payer.';
comment on column "DISTANCES_TRAJET"."CALCULE_LE" is 'Date du calcul. Une adresse change ; une distance vieille de trois ans mérite d''être revérifiée.';
comment on column "DISTANCES_TRAJET"."CALCULE_PAR" is 'Compte ayant déclenché le calcul. Un appel à un service externe se trace : il a un coût et il expose une adresse.';
comment on column "DISTANCES_TRAJET"."NOTE" is 'Circonstances du calcul : date, service interrogé, correction manuelle éventuelle.';
comment on table "DOCUMENTS" is 'Pièces déposées, rattachées à un salarié, à un contrat ou à une société. Le fichier vit dans le stockage ; cette table porte les métadonnées et la durée de conservation.';
comment on column "DOCUMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DOCUMENTS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DOCUMENTS"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "DOCUMENTS"."ENTITE_TABLE" is 'Table de l''objet rattaché, lorsque la pièce ne vise pas directement un salarié.';
comment on column "DOCUMENTS"."ENTITE_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "DOCUMENTS"."NOM" is 'Nom du document tel que présenté à l''utilisateur. Distinct du nom du fichier stocké.';
comment on column "DOCUMENTS"."CHEMIN_STOCKAGE" is 'Chemin dans le bucket de stockage. L''accès au fichier obéit aux mêmes règles que la ligne.';
comment on column "DOCUMENTS"."TYPE_MIME" is 'Type MIME déclaré à l''envoi. Sert à choisir la visionneuse ; il ne remplace pas un contrôle du contenu.';
comment on column "DOCUMENTS"."TAILLE_OCTETS" is 'Taille du fichier en octets, pour les quotas et l''affichage.';
comment on column "DOCUMENTS"."CONSERVATION_JUSQUAU" is 'Date au-delà de laquelle la pièce ne doit plus être conservée (RGPD, limitation de conservation).';
comment on column "DOCUMENTS"."SENSIBLE" is 'Vrai pour une pièce de catégorie particulière (santé, handicap) : accès et conservation restreints.';
comment on column "DOCUMENTS"."DEPOSE_PAR" is 'Compte ayant déposé le document.';
comment on column "DOCUMENTS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "DOCUMENTS"."TYPE_DOCUMENT_ID" is 'Type de document, parmi document_types. Détermine la durée de conservation et le caractère obligatoire de la pièce.';
comment on column "DOCUMENTS"."EMIS_LE" is 'Date de délivrance par l''autorité émettrice.';
comment on column "DOCUMENTS"."EXPIRE_LE" is 'Fin de validité de la pièce elle-même, qui déclenche l''alerte d''échéance.';
comment on column "DOCUMENTS"."REMIS_LE" is 'Date de remise au salarié, pour les pièces de fin de contrat.';
comment on table "DONNEES_FINANCIERES_SOCIETE" is 'Résultats annuels de la société. Sert au calcul de l''enveloppe des primes participatives, plafonnée sur le bénéfice de l''exercice précédent.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."EXERCICE" is 'Exercice comptable concerné, en année pleine.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."RESULTAT" is 'Bénéfice de l''exercice, assiette du plafond d''enveloppe.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."CHIFFRE_AFFAIRES" is 'Chiffre d''affaires de l''exercice, en euros. Sert aux seuils qui dépendent de la taille de l''entreprise.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."SOURCE" is 'Origine du chiffre : comptes annuels, situation intermédiaire.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."NOTE" is 'Origine du chiffre : comptes déposés, estimation, déclaration. Un seuil calculé sur une estimation ne se traite pas comme un seuil calculé sur des comptes.';
comment on column "DONNEES_FINANCIERES_SOCIETE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "DROITS_ABSENCE" is 'Droit ouvert par motif d''absence, daté. Un congé extraordinaire dont la durée change au fil des réformes porte ici plusieurs versions successives.';
comment on column "DROITS_ABSENCE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DROITS_ABSENCE"."TYPE_ABSENCE_ID" is 'Type d''absence auquel ce droit se rapporte. Le droit est daté : un même type peut ouvrir un nombre de jours différent selon la période.';
comment on column "DROITS_ABSENCE"."JOURS" is 'Nombre de jours ouverts par événement.';
comment on column "DROITS_ABSENCE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "DROITS_ABSENCE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "DROITS_ABSENCE"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "DROITS_ABSENCE"."NOTE_FREQUENCE" is 'Condition de renouvellement exprimée en clair quand elle ne se réduit pas à un nombre.';
comment on column "DROITS_ABSENCE"."PLAFOND_CARRIERE_JOURS" is 'Plafond sur toute la carrière, lorsque le droit n''est pas renouvelable indéfiniment.';
comment on column "DROITS_ABSENCE"."JOURS_BLOC" is 'Durée du bloc indivisible lorsque le droit doit être pris d''un seul tenant.';
comment on column "DROITS_ABSENCE"."DUREE_MOIS" is 'Fenêtre glissante sur laquelle le droit se reconstitue.';
comment on column "DROITS_ABSENCE"."DEGRE_PARENTE" is 'Degré de parenté exigé, pour les congés liés à un événement familial.';
comment on column "DROITS_ABSENCE"."PIECE_EXIGEE" is 'Vrai si un justificatif conditionne l''ouverture du droit.';
comment on column "DROITS_ABSENCE"."NOTE" is 'Précision sur l''origine du droit : disposition conventionnelle, usage d''entreprise, circonstance particulière. Lue par un humain, jamais par le moteur.';
comment on table "ELEMENTS_REMUNERATION" is 'Éléments de rémunération autres que le brut de base : primes récurrentes, avantages, indemnités.';
comment on column "ELEMENTS_REMUNERATION"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ELEMENTS_REMUNERATION"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "ELEMENTS_REMUNERATION"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ELEMENTS_REMUNERATION"."GENRE" is 'Nature de l''élément, qui commande son traitement fiscal et social.';
comment on column "ELEMENTS_REMUNERATION"."CODE" is 'Code de l''élément de rémunération : prime, indemnité, avantage. Stable, repris par la paie.';
comment on column "ELEMENTS_REMUNERATION"."LIBELLE" is 'Libellé de l''élément tel qu''il apparaît sur le bulletin.';
comment on column "ELEMENTS_REMUNERATION"."MONTANT" is 'Montant en euros. Nul quand l''élément se calcule au lieu d''être forfaitaire — un zéro dirait autre chose.';
comment on column "ELEMENTS_REMUNERATION"."TAUX_PCT" is 'Taux, pour un élément exprimé en pourcentage plutôt qu''en montant.';
comment on column "ELEMENTS_REMUNERATION"."ASSIETTE" is 'Assiette à laquelle le taux s''applique.';
comment on column "ELEMENTS_REMUNERATION"."PERIODICITE" is 'Périodicité de versement.';
comment on column "ELEMENTS_REMUNERATION"."DANS_ASSIETTE_SALAIRE" is 'Vrai si l''élément entre dans le salaire de référence servant au calcul des indemnités.';
comment on column "ELEMENTS_REMUNERATION"."IMPOSABLE" is 'Vrai si l''élément entre dans l''assiette imposable. Une prime exonérée mal marquée fausse la retenue à la source.';
comment on column "ELEMENTS_REMUNERATION"."COTISABLE" is 'Vrai si l''élément entre dans l''assiette des cotisations sociales. Indépendant de is_taxable : les deux assiettes ne coïncident pas.';
comment on column "ELEMENTS_REMUNERATION"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "ELEMENTS_REMUNERATION"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "ELEMENTS_REMUNERATION"."NOTE" is 'Fondement de l''élément : article de convention, usage, accord individuel. Ce qui permet de le défendre ou de le supprimer.';
comment on column "ELEMENTS_REMUNERATION"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ELEMENTS_REMUNERATION"."TYPE_AVANTAGE_ID" is 'Avantage en nature du catalogue, lorsque l''élément en est un.';
comment on table "ENFANTS_SALARIE" is 'Enfants du salarié. Données de catégorie familiale, collectées pour les droits qui en dépendent ; le salarié peut refuser leur usage — voir privacy_opt_out.';
comment on column "ENFANTS_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ENFANTS_SALARIE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ENFANTS_SALARIE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ENFANTS_SALARIE"."PRENOM" is 'Prénom de l''enfant. Nul quand seul le nombre d''enfants importe pour un droit et que l''identité n''a pas à être connue — la minimisation vaut aussi ici.';
comment on column "ENFANTS_SALARIE"."NOM" is 'Nom de l''enfant, s''il diffère de celui du parent.';
comment on column "ENFANTS_SALARIE"."SEXE" is 'Sexe de l''enfant, tel que déclaré. Aucun droit n''en dépend ; la colonne existe pour les documents administratifs qui l''exigent.';
comment on column "ENFANTS_SALARIE"."DATE_NAISSANCE" is 'Date de naissance. Fonde les droits liés aux enfants — congé parental, boni, classe d''impôt — et le déclenchement de leur extinction.';
comment on column "ENFANTS_SALARIE"."LIEN_PARENTE" is 'Lien : enfant, enfant adopté, enfant du conjoint.';
comment on column "ENFANTS_SALARIE"."A_CHARGE" is 'Vrai si l''enfant est à charge au sens des droits ouverts.';
comment on column "ENFANTS_SALARIE"."REFUS_PARTAGE" is 'Vrai si le salarié refuse que l''enfant soit pris en compte. Le moteur cesse alors d''en tirer un droit, sans effacer la ligne.';
comment on column "ENFANTS_SALARIE"."DATE_ADOPTION" is 'Date de l''adoption, qui ouvre ses propres droits, distincts de ceux liés à la naissance.';
comment on column "ENFANTS_SALARIE"."NOTE" is 'Précisions utiles au dossier familial. Jamais de donnée de santé : celles-ci vont en fiche_sante, qui porte les restrictions adéquates.';
comment on column "ENFANTS_SALARIE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ENFANTS_SALARIE"."REFUS_PHOTOS_EVENEMENTS" is 'L''enfant ne doit pas apparaître sur les photos des événements familiaux de la société.';
comment on column "ENFANTS_SALARIE"."INVITATION_EVENEMENTS" is 'L''enfant est convié aux événements de la société — Saint-Nicolas, journée des familles — avec ses parents.';
comment on column "ENFANTS_SALARIE"."EN_SITUATION_HANDICAP" is 'Situation de handicap. DONNÉE DE SANTÉ : même régime d''accès que la fiche santé.';
comment on column "ENFANTS_SALARIE"."TAUX_HANDICAP_PCT" is 'Taux de handicap reconnu, en pourcentage. Donnée de santé : accès restreint, lecture journalisée. Nul si aucun handicap n''est reconnu.';
comment on table "FICHE_SANTE" is 'Fiche santé d''un salarié ou d''un de ses enfants. DONNÉE DE SANTÉ au sens de l''article 9 du RGPD : accès réservé à la personne, à la médecine du travail et aux RH d''urgence. Le dispatching n''y accède jamais — il lit les indicateurs dérivés.';
comment on column "FICHE_SANTE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "FICHE_SANTE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "FICHE_SANTE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "FICHE_SANTE"."ENFANT_ID" is 'Enfant concerné quand la fiche porte sur un enfant et non sur le salarié. Exclusif de la fiche du salarié : une ligne concerne l''un ou l''autre.';
comment on column "FICHE_SANTE"."ALLERGIES" is 'Donnée brute. Ne jamais exposer au planning : c''est l''indicateur dérivé qui circule.';
comment on column "FICHE_SANTE"."PATHOLOGIES" is 'Pathologies déclarées. Donnée de santé au sens de l''article 9 du RGPD, sous le régime d''accès le plus strict : le dispatching n''y a jamais accès, il ne voit que des indicateurs dérivés et anonymisés.';
comment on column "FICHE_SANTE"."MEDECIN_TRAITANT" is 'Médecin traitant, pour le cas d''urgence. Donnée de santé.';
comment on column "FICHE_SANTE"."MEDECIN_TELEPHONE" is 'Téléphone du médecin traitant, appelable en urgence.';
comment on column "FICHE_SANTE"."GROUPE_SANGUIN" is 'Groupe sanguin déclaré. Donnée de santé, transmise aux secours et à personne d''autre.';
comment on column "FICHE_SANTE"."NOTE" is 'Consignes de prise en charge : allergies et conduite à tenir, traitement d''urgence disponible sur la personne — adrénaline pour une allergie aux piqûres, antihistaminique, mèche de cautérisation. C''est ce que les secours doivent savoir en arrivant.';
comment on column "FICHE_SANTE"."MAJ_LE" is 'Date de dernière mise à jour de la fiche. Une consigne de secours périmée est dangereuse : l''ancienneté de la fiche doit être visible.';
comment on column "FICHE_SANTE"."MAJ_PAR" is 'Compte ayant mis la fiche à jour. Sur une donnée de santé, toute écriture est attribuable et journalisée.';
comment on column "FICHE_SANTE"."SUPPRIME_LE" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "FICHE_SANTE"."SUPPRIME_PAR" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "FICHES_RETENUE_IMPOT" is 'Fiche de retenue d''impôt du salarié, datée. Donnée d''entrée du calcul brut vers net.';
comment on column "FICHES_RETENUE_IMPOT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "FICHES_RETENUE_IMPOT"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "FICHES_RETENUE_IMPOT"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "FICHES_RETENUE_IMPOT"."CLASSE_IMPOT" is 'Classe d''impôt portée par la fiche.';
comment on column "FICHES_RETENUE_IMPOT"."TAUX" is 'Taux de retenue inscrit sur la fiche, lorsqu''un taux est fixé plutôt qu''un barème.';
comment on column "FICHES_RETENUE_IMPOT"."INDEMNITE_MENSUELLE" is 'Abattement mensuel inscrit sur la fiche.';
comment on column "FICHES_RETENUE_IMPOT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "FICHES_RETENUE_IMPOT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "FICHES_RETENUE_IMPOT"."CREDITS" is 'Crédits d''impôt portés par la fiche, structurés.';
comment on column "FICHES_RETENUE_IMPOT"."DISTANCE_DOMICILE_KM" is 'Distance domicile-travail déclarée, base de l''abattement kilométrique.';
comment on column "FICHES_RETENUE_IMPOT"."FRAIS_PROFESSIONNELS_MENSUELS" is 'Frais professionnels mensuels retenus.';
comment on column "FICHES_RETENUE_IMPOT"."AUTRES_DEDUCTIONS_MENSUELLES" is 'Autres déductions mensuelles portées par la fiche.';
comment on column "FICHES_RETENUE_IMPOT"."REFERENCE_CARTE" is 'Référence de la fiche délivrée par l''administration.';
comment on column "FICHES_RETENUE_IMPOT"."EMIS_LE" is 'Date d''émission de la fiche de retenue par l''administration. Distincte de la période de validité : une fiche peut être émise après le début de la période qu''elle couvre.';
comment on table "GRILLES_SALAIRES_CONVENTION" is 'Grille de salaires conventionnelle : montant minimal par catégorie et par ancienneté.';
comment on column "GRILLES_SALAIRES_CONVENTION"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "GRILLES_SALAIRES_CONVENTION"."CONVENTION_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "GRILLES_SALAIRES_CONVENTION"."CATEGORIE" is 'Catégorie professionnelle de la grille, dans les termes de la convention. C''est elle qui relie un poste à un minimum conventionnel.';
comment on column "GRILLES_SALAIRES_CONVENTION"."ANCIENNETE_DE_ANNEES" is 'Ancienneté à partir de laquelle l''échelon s''applique.';
comment on column "GRILLES_SALAIRES_CONVENTION"."ANCIENNETE_A_ANNEES" is 'Ancienneté au-delà de laquelle l''échelon cesse. Nul pour le dernier échelon.';
comment on column "GRILLES_SALAIRES_CONVENTION"."MONTANT_MENSUEL" is 'Salaire mensuel minimum de la catégorie, en euros, à l''indice de référence de la convention. Le moteur l''indexe avant de le comparer au salaire réel.';
comment on column "GRILLES_SALAIRES_CONVENTION"."INDICE_REFERENCE" is 'Cote d''indice à laquelle le montant est exprimé, pour le réindexer correctement.';
comment on table "HANDICAPS_SALARIE" is 'Reconnaissance de travailleur handicapé. Donnée de santé au sens du RGPD : accès restreint et finalité limitée aux droits qui en découlent.';
comment on column "HANDICAPS_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "HANDICAPS_SALARIE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "HANDICAPS_SALARIE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "HANDICAPS_SALARIE"."TAUX_PCT" is 'Taux d''incapacité reconnu.';
comment on column "HANDICAPS_SALARIE"."RECONNU_LE" is 'Date de la décision de reconnaissance.';
comment on column "HANDICAPS_SALARIE"."AUTORITE" is 'Autorité ayant prononcé la reconnaissance.';
comment on column "HANDICAPS_SALARIE"."JOURS_CONGE_SUPPLEMENTAIRES_FORCES" is 'Jours de congé supplémentaires imposés par la décision, lorsqu''ils diffèrent du droit commun.';
comment on column "HANDICAPS_SALARIE"."PIECE_JUSTIFICATIVE_ID" is 'Pièce justificative, rangée dans documents avec le drapeau is_sensitive.';
comment on column "HANDICAPS_SALARIE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "HANDICAPS_SALARIE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "HANDICAPS_SALARIE"."NOTE" is 'Éléments de contexte sur la reconnaissance du handicap. Donnée sensible au sens de l''article 9 du RGPD : l''accès en est restreint, et sa lecture journalisée.';
comment on column "HANDICAPS_SALARIE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "JOURNAL_ACCES" is 'Journal des consultations de données personnelles. Complète audit_log, qui ne voit que les écritures : ici sont tracés les accès en LECTURE aux données sensibles, les déchiffrements et les téléchargements de pièces. Répond aux questions qui / quoi / quand / d''où pour une personne donnée.';
comment on column "JOURNAL_ACCES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "JOURNAL_ACCES"."SURVENU_LE" is 'Horodatage de la LECTURE. Ce journal répond au « quand » de l''article 15 du RGPD : à quel moment les données d''une personne ont été consultées.';
comment on column "JOURNAL_ACCES"."AUTEUR_ID" is 'Compte ayant lu. Répond au « par qui ». Renseigné par le serveur à partir de la session, jamais déclaré par l''appelant.';
comment on column "JOURNAL_ACCES"."AUTEUR_LIBELLE" is 'Nom de l''auteur figé au moment de l''accès : la trace reste lisible après suppression du compte.';
comment on column "JOURNAL_ACCES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "JOURNAL_ACCES"."SALARIE_CONCERNE_ID" is 'La personne DONT les données ont été vues — à ne pas confondre avec actor_id, qui est celle qui les a vues.';
comment on column "JOURNAL_ACCES"."ENTITE_TABLE" is 'Table lue. Répond au « quoi », avec la ligne visée et les colonnes effectivement renvoyées.';
comment on column "JOURNAL_ACCES"."ENTITE_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "JOURNAL_ACCES"."ACTION" is 'READ consultation, DECRYPT déchiffrement d''une donnée sensible, EXPORT extraction, DOWNLOAD téléchargement d''une pièce.';
comment on column "JOURNAL_ACCES"."PORTEE" is 'Ce qui a été vu, en clair : « matricule national, IBAN », « dossier complet ». Jamais la valeur elle-même.';
comment on column "JOURNAL_ACCES"."NOMBRE_LIGNES" is 'Nombre de lignes effectivement renvoyées à l''appelant. Une consultation qui ne renvoie rien reste une consultation et se journalise.';
comment on column "JOURNAL_ACCES"."IP_SOURCE" is 'Adresse IP d''origine, lue dans les en-têtes transmis par la passerelle. Répond au « d''où ».';
comment on column "JOURNAL_ACCES"."AGENT_CLIENT" is 'Agent déclaré par le client. Indicatif seulement : un agent se falsifie, il complète l''IP sans la remplacer.';
comment on column "JOURNAL_ACCES"."IDENTIFIANT_REQUETE" is 'Identifiant de la requête, pour rapprocher une ligne de ce journal des traces de la passerelle lors d''une investigation.';
comment on column "JOURNAL_ACCES"."EST_AUTONOME" is 'Vrai si la trace a été écrite hors de la transaction appelante, et survit donc à son annulation. Faux si dblink n''était pas configuré : la trace est alors aussi fragile que l''opération qu''elle décrit.';
comment on table "JOURNAL_ECRITURES" is 'Journal des écritures, alimenté par le déclencheur fn_audit. Conservé pour la traçabilité et la preuve, jamais modifié par l''application.';
comment on column "JOURNAL_ECRITURES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "JOURNAL_ECRITURES"."SURVENU_LE" is 'Horodatage de l''écriture auditée, posé par la base au moment du déclencheur. Ce n''est pas une date saisie : elle ne se retouche pas.';
comment on column "JOURNAL_ECRITURES"."AUTEUR_ID" is 'Compte auteur de l''écriture. Nul pour une opération de maintenance exécutée hors session applicative — cas rare, qui doit rester visible plutôt que d''être attribué à tort.';
comment on column "JOURNAL_ECRITURES"."AUTEUR_LIBELLE" is 'Nom de l''auteur figé au moment du fait : le journal reste lisible après suppression du compte.';
comment on column "JOURNAL_ECRITURES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "JOURNAL_ECRITURES"."ENTITE_TABLE" is 'Nom de la table concernée : le journal est polymorphe, sans clé étrangère.';
comment on column "JOURNAL_ECRITURES"."ENTITE_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "JOURNAL_ECRITURES"."ACTION" is 'Nature de l''écriture : insert, update, delete. La suppression enregistrée ici est logique ; une ligne n''est jamais retirée de la base.';
comment on column "JOURNAL_ECRITURES"."ANCIENNE_VALEUR" is 'État de la ligne avant écriture, en jsonb. Nul pour une insertion.';
comment on column "JOURNAL_ECRITURES"."NOUVELLE_VALEUR" is 'État de la ligne après écriture. Nul pour une suppression.';
comment on column "JOURNAL_ECRITURES"."IP_SOURCE" is 'Adresse d''origine de la requête, telle que rapportée par les en-têtes HTTP. Donnée déclarative : elle situe, elle ne prouve pas.';
comment on column "JOURNAL_ECRITURES"."AGENT_CLIENT" is 'Agent utilisateur de l''appelant, tronqué à 400 caractères.';
comment on column "JOURNAL_ECRITURES"."IDENTIFIANT_REQUETE" is 'Identifiant de requête, pour recouper une trace avec les journaux d''infrastructure.';
comment on table "JOURNAL_EXPORTS" is 'Registre des exports de portabilité. Trace qui a exporté quoi, quand, et pour quel volume — pièce de conformité au droit d''accès et à la portabilité (RGPD art. 15 et 20).';
comment on column "JOURNAL_EXPORTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "JOURNAL_EXPORTS"."ORGANISATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "JOURNAL_EXPORTS"."DEMANDE_PAR" is 'Compte ayant demandé l''export. Un export de données personnelles est un traitement : il a un demandeur nommé.';
comment on column "JOURNAL_EXPORTS"."GENRE_OBJET" is 'Nature du sujet exporté : self, employee, company, organization ou referential.';
comment on column "JOURNAL_EXPORTS"."OBJET_ID" is 'Ligne concernée par l''export, dans la table que désigne subject_kind. Nulle pour un export qui ne vise pas une ligne unique, comme le référentiel.';
comment on column "JOURNAL_EXPORTS"."NOMBRE_LIGNES" is 'Nombre d''objets contenus dans l''export, à des fins de contrôle de volume.';
comment on column "JOURNAL_EXPORTS"."TAILLE_OCTETS" is 'Taille de l''enveloppe produite, en octets.';
comment on column "JOURNAL_EXPORTS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "JOURNAL_EXPORTS"."IP_SOURCE" is 'Adresse d''origine de la demande d''export.';
comment on column "JOURNAL_EXPORTS"."AGENT_CLIENT" is 'Agent utilisateur de l''appelant.';
comment on column "JOURNAL_EXPORTS"."IDENTIFIANT_REQUETE" is 'Identifiant de requête, pour recoupement.';
comment on table "JOURS_FERIES" is 'Jours fériés légaux d''une année, complétés le cas échéant par les jours conventionnels.';
comment on column "JOURS_FERIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "JOURS_FERIES"."ANNEE" is 'Année du jour férié. Les fériés mobiles changent de date chaque année : une ligne par année.';
comment on column "JOURS_FERIES"."DATE_FERIE" is 'Date du jour férié. Un férié travaillé ouvre une majoration dont le taux vient du référentiel daté.';
comment on column "JOURS_FERIES"."NOM" is 'Nom du jour férié, affiché sur les plannings.';
comment on column "JOURS_FERIES"."EST_MOBILE" is 'Vrai pour un férié dont la date suit le calendrier pascal, calculé par fn_easter_sunday.';
comment on column "JOURS_FERIES"."CONVENTION_ID" is 'Renseigné pour un jour chômé d''origine conventionnelle, nul pour un férié légal.';
comment on column "JOURS_FERIES"."RECUPERABLE" is 'Vrai si le férié tombant un jour non ouvré ouvre droit à récupération.';
comment on column "JOURS_FERIES"."MOTIF_RECUPERATION" is 'Motif de la récupération, cité dans l''alerte.';
comment on table "MODELES_CRENEAU" is 'Modèle de vacation réutilisable, pour éviter de ressaisir les horaires courants.';
comment on column "MODELES_CRENEAU"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "MODELES_CRENEAU"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "MODELES_CRENEAU"."NOM" is 'Nom du modèle de créneau, pour le réutiliser lors de la construction d''un planning.';
comment on column "MODELES_CRENEAU"."HEURE_DEBUT" is 'Heure de début du modèle.';
comment on column "MODELES_CRENEAU"."HEURE_FIN" is 'Heure de fin du modèle. Peut être antérieure à start_time : le créneau franchit alors minuit.';
comment on column "MODELES_CRENEAU"."PAUSE_MINUTES" is 'Pause en minutes, déduite du temps de travail effectif. Le seuil légal au-delà duquel une pause est obligatoire vient du référentiel daté, jamais d''une valeur écrite ici.';
comment on column "MODELES_CRENEAU"."COULEUR" is 'Couleur d''affichage dans le planning. Confort d''usage, sans effet métier.';
comment on column "MODELES_CRENEAU"."SERVICE_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on table "ORGANISATIONS" is 'Fiduciaire ou entreprise unique. Racine de l''isolation : toute donnée appartient, directement ou par sa société, à une organisation.';
comment on column "ORGANISATIONS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ORGANISATIONS"."NOM" is 'Raison sociale de la fiduciaire ou de l''entreprise.';
comment on column "ORGANISATIONS"."GENRE" is 'Distingue une fiduciaire gérant plusieurs sociétés clientes d''une entreprise gérant la sienne.';
comment on column "ORGANISATIONS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PARAMETRES_ATTENDUS" is 'Clés de legal_parameters que le moteur lit. Sert à fn_referential_gaps pour signaler une clé attendue dont aucune version n''est chargée. Ne porte aucune valeur légale.';
comment on column "PARAMETRES_ATTENDUS"."CLE_PARAMETRE" is 'Clé d''un paramètre que le moteur attend. Sans cette table, fn_referential_gaps ne voyait pas les clés entièrement absentes : elle ne pouvait signaler que les périodes trouées.';
comment on column "PARAMETRES_ATTENDUS"."LU_PAR" is 'Fonction(s) du moteur qui lisent la clé, relevées dans le code des migrations.';
comment on column "PARAMETRES_ATTENDUS"."NOTE" is 'À quoi sert le paramètre et ce qui se casse en son absence. Ce qui permet de hiérarchiser les trous à combler.';
comment on table "PARAMETRES_LEGAUX" is 'Le référentiel. Tout seuil, taux ou durée légale du droit du travail luxembourgeois vit ici, jamais dans le code. Chaque valeur porte sa plage de validité, sa source et son article ; une contrainte d''exclusion GiST interdit deux versions qui se chevauchent pour une même clé.';
comment on column "PARAMETRES_LEGAUX"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PARAMETRES_LEGAUX"."FAMILLE" is 'Famille du paramètre : elle regroupe les clés par domaine et guide la détection des trous du référentiel.';
comment on column "PARAMETRES_LEGAUX"."CLE_PARAMETRE" is 'Clé stable du paramètre. C''est elle que le moteur interroge, jamais l''identifiant technique.';
comment on column "PARAMETRES_LEGAUX"."LIBELLE" is 'Intitulé du paramètre en français, pour les écrans de référentiel. Le code machine est param_key.';
comment on column "PARAMETRES_LEGAUX"."VALEUR_NUM" is 'Valeur numérique. Une seule des trois colonnes value_* est renseignée.';
comment on column "PARAMETRES_LEGAUX"."VALEUR_TEXTE" is 'Valeur textuelle, pour un paramètre qui n''est pas un nombre.';
comment on column "PARAMETRES_LEGAUX"."VALEUR_JSON" is 'Valeur structurée, pour un barème ou une table à plusieurs entrées.';
comment on column "PARAMETRES_LEGAUX"."UNITE" is 'Unité de la valeur (EUR, heures, jours, pourcentage...) — sans elle un nombre ne veut rien dire.';
comment on column "PARAMETRES_LEGAUX"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "PARAMETRES_LEGAUX"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "PARAMETRES_LEGAUX"."INDICE_REFERENCE" is 'Cote d''application de l''indice des prix au moment de la valeur, pour les montants indexés.';
comment on column "PARAMETRES_LEGAUX"."SOURCE" is 'Origine publique de la valeur (Mémorial, STATEC, CCSS...). Obligatoire : un paramètre sans source ne doit pas exister.';
comment on column "PARAMETRES_LEGAUX"."REFERENCE_LEGALE" is 'Article du Code du travail ou du texte qui fonde la valeur. C''est lui que les alertes citent à l''utilisateur.';
comment on column "PARAMETRES_LEGAUX"."NOTE" is 'Précisions d''interprétation : ce que la valeur recouvre exactement, et ce qu''elle ne recouvre pas.';
comment on column "PARAMETRES_LEGAUX"."SAISI_PAR" is 'Auteur de la saisie.';
comment on column "PARAMETRES_LEGAUX"."SAISI_LE" is 'Date de saisie de la valeur dans LuxRH. Distincte de sa date d''entrée en vigueur : une valeur peut être saisie avec retard, ou par anticipation.';
comment on column "PARAMETRES_LEGAUX"."VALIDE_PAR" is 'Relecteur ayant validé la version. Nul tant que la valeur n''a pas été contrôlée.';
comment on column "PARAMETRES_LEGAUX"."VALIDE_LE" is 'Date de validation par un second regard. Nulle tant que la valeur n''a pas été relue — une valeur légale non validée reste utilisable, mais elle est signalée.';
comment on column "PARAMETRES_LEGAUX"."DERIVE_DE_CLE" is 'Clé du paramètre dont celui-ci se déduit. La dérivation sert de contrôle de cohérence, pas de source.';
comment on column "PARAMETRES_LEGAUX"."FACTEUR_DERIVE" is 'Facteur appliqué au paramètre d''origine pour obtenir celui-ci.';
comment on column "PARAMETRES_LEGAUX"."TOLERANCE_DERIVATION" is 'Écart admis entre la valeur saisie et la valeur dérivée avant signalement d''une incohérence.';
comment on table "PERIODES_REFERENCE" is 'Période de référence sur laquelle la durée de travail se calcule en moyenne. Définie par société ou par service.';
comment on column "PERIODES_REFERENCE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PERIODES_REFERENCE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PERIODES_REFERENCE"."SERVICE_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column "PERIODES_REFERENCE"."LIBELLE" is 'Intitulé de la période de référence, pour l''identifier dans les écrans de suivi.';
comment on column "PERIODES_REFERENCE"."DATE_DEBUT" is 'Premier jour de la période de référence, inclus. C''est sur cette période que la durée moyenne de travail doit être respectée.';
comment on column "PERIODES_REFERENCE"."DATE_FIN" is 'Dernier jour de la période, INCLUS. Sa longueur maximale est fixée par le référentiel légal et par la convention, jamais écrite en dur.';
comment on column "PERIODES_REFERENCE"."MOIS" is 'Longueur de la période. Une période plus longue qu''un mois suppose un fondement conventionnel.';
comment on table "PERIODES_TAUX_SOCIETE" is 'Historique des taux propres à la société : classe de mutualité, facteur accident, classe d''activité. Un recalcul lit le taux en vigueur à la date du calcul.';
comment on column "PERIODES_TAUX_SOCIETE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PERIODES_TAUX_SOCIETE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PERIODES_TAUX_SOCIETE"."CLASSE_ACTIVITE" is 'Classe d''activité déclarée à la CCSS.';
comment on column "PERIODES_TAUX_SOCIETE"."CLASSE_RISQUE_ACCIDENT" is 'Classe de risque accident attribuée à la société.';
comment on column "PERIODES_TAUX_SOCIETE"."FACTEUR_ACCIDENT" is 'Facteur bonus-malus de l''assurance accident.';
comment on column "PERIODES_TAUX_SOCIETE"."CLASSE_MUTUALITE" is 'Classe de la Mutualité des employeurs, qui commande le taux de cotisation.';
comment on column "PERIODES_TAUX_SOCIETE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "PERIODES_TAUX_SOCIETE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "PERIODES_TAUX_SOCIETE"."SOURCE" is 'Origine du taux : courrier CCSS, décision de classement. Obligatoire.';
comment on column "PERIODES_TAUX_SOCIETE"."NOTE" is 'Origine du taux appliqué sur la période : notification de l''organisme, classe de risque, régularisation.';
comment on column "PERIODES_TAUX_SOCIETE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PERSONNE_INDICATEUR_SECOURS" is 'Indicateurs de secours portés par une personne. Dérivés de la fiche santé par la médecine du travail : ils circulent là où la donnée brute ne va pas. C''est ce qui permet au dispatching d''écarter une affectation sans savoir pourquoi.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."ENFANT_ID" is 'Enfant concerné quand l''indicateur porte sur un enfant. Exclusif de la personne salariée.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."INDICATEUR" is 'Indicateur de secours, parmi ref_indicateur_secours. C''est la forme ANONYMISÉE de l''information médicale : un booléen dérivé, sans diagnostic. Le dispatching voit l''indicateur, jamais la pathologie qui le fonde.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."PRECISION_LIEU" is 'Précision d''affectation quand l''indicateur en appelle une — un type de lieu, un environnement. Jamais une pathologie.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."POSE_PAR" is 'Compte ayant posé l''indicateur, à partir de la fiche de santé. La dérivation est un acte : elle a un auteur et une date.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PLANNINGS" is 'Planning hebdomadaire d''une société ou d''un service. Tant qu''il n''est pas publié, il n''est opposable à personne.';
comment on column "PLANNINGS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PLANNINGS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PLANNINGS"."SERVICE_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column "PLANNINGS"."DEBUT_SEMAINE" is 'Lundi de la semaine couverte.';
comment on column "PLANNINGS"."LIBELLE" is 'Intitulé du planning, pour s''y retrouver entre plusieurs semaines ou équipes. Sans effet sur le calcul.';
comment on column "PLANNINGS"."STATUT" is 'Brouillon ou publié. La publication passe par fn_publish_schedule, qui refuse un planning non conforme.';
comment on column "PLANNINGS"."PUBLIE_LE" is 'Horodatage de la publication, qui fait courir le délai de prévenance.';
comment on column "PLANNINGS"."PUBLIE_PAR" is 'Auteur de la publication.';
comment on column "PLANNINGS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PRIMES" is 'Primes versées, dont les primes participatives soumises à un double plafond : enveloppe société et plafond individuel.';
comment on column "PRIMES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PRIMES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PRIMES"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "PRIMES"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "PRIMES"."RUPTURE_ID" is 'Rupture à laquelle la prime se rattache, pour une indemnité de départ.';
comment on column "PRIMES"."GENRE" is 'Nature de la prime. Détermine son régime fiscal et social, et le plafond légal qui s''y applique le cas échéant.';
comment on column "PRIMES"."LIBELLE" is 'Libellé de la prime sur le bulletin.';
comment on column "PRIMES"."MONTANT" is 'Montant en euros pour la période. Le plafond d''exonération éventuel est vérifié par le moteur et non par une contrainte : il est daté.';
comment on column "PRIMES"."ATTRIBUE_LE" is 'Date d''attribution.';
comment on column "PRIMES"."EXERCICE" is 'Exercice d''imputation, qui détermine l''enveloppe et les plafonds applicables.';
comment on column "PRIMES"."IMPOSABLE" is 'Vrai si la prime entre dans l''assiette imposable, une fois le plafond d''exonération dépassé.';
comment on column "PRIMES"."COTISABLE" is 'Vrai si la prime entre dans l''assiette des cotisations. Distinct du régime fiscal.';
comment on column "PRIMES"."PART_EXONEREE_PCT" is 'Fraction exonérée de la prime, selon son régime.';
comment on column "PRIMES"."NOTE" is 'Fondement de la prime et calcul retenu. Une prime sans justification écrite se conteste mal.';
comment on column "PRIMES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PROFILS" is 'Compte utilisateur applicatif, en miroir de auth.users. Alimenté par le déclencheur handle_new_user à l''inscription.';
comment on column "PROFILS"."ID" is 'Identique à auth.users.id : le profil ne porte pas d''identité propre.';
comment on column "PROFILS"."ORGANISATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "PROFILS"."NOM_COMPLET" is 'Nom affiché de l''utilisateur dans l''interface. Doublon assumé de app_users.full_name : profiles est la vue applicative, app_users la table de comptes portable vers un autre SGBD.';
comment on column "PROFILS"."COURRIEL" is 'Recopié depuis auth.users pour l''affichage. L''authentification ne s''appuie jamais sur cette copie.';
comment on column "PROFILS"."EST_ADMIN_ORGANISATION" is 'Administrateur de l''organisation : seul habilité à charger un référentiel et à exporter la fiduciaire entière.';
comment on column "PROFILS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PROLONGATIONS_ESSAI" is 'Prolongation d''une période d''essai, suspendue par une absence. Trace la durée ajoutée et son motif.';
comment on column "PROLONGATIONS_ESSAI"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PROLONGATIONS_ESSAI"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "PROLONGATIONS_ESSAI"."DATE_DEBUT" is 'Premier jour de la prolongation d''essai, inclus.';
comment on column "PROLONGATIONS_ESSAI"."DATE_FIN" is 'Dernier jour de la prolongation, INCLUS. La durée totale d''essai reste plafonnée par la loi et par la convention : le moteur vérifie le cumul, pas seulement cette ligne.';
comment on column "PROLONGATIONS_ESSAI"."JOURS_AJOUTES" is 'Jours ajoutés à l''essai du fait de la suspension.';
comment on column "PROLONGATIONS_ESSAI"."MOTIF" is 'Motif de la prolongation. L''essai ne se prolonge pas par convenance : il faut une cause, généralement une suspension du contrat.';
comment on table "REF_ACTION_ACCES" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_ACTION_ACCES"."CODE" is 'Code de l''action journalisée dans le registre des accès : lecture, déchiffrement, export.';
comment on column "REF_ACTION_ACCES"."LIBELLE" is 'Libellé de l''action à l''écran du registre.';
comment on column "REF_ACTION_ACCES"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_ACTION_ACCES"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_ACTION_ACCES"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_ACTION_ACCES"."NOTE" is 'Ce que l''action recouvre exactement, pour que le registre se lise sans ambiguïté lors d''un contrôle.';
comment on table "REF_COMPENSATION_HEURES_SUP" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_COMPENSATION_HEURES_SUP"."CODE" is 'Code du mode de compensation des heures supplémentaires : repos ou argent.';
comment on column "REF_COMPENSATION_HEURES_SUP"."LIBELLE" is 'Libellé du mode de compensation à l''écran.';
comment on column "REF_COMPENSATION_HEURES_SUP"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_COMPENSATION_HEURES_SUP"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_COMPENSATION_HEURES_SUP"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_COMPENSATION_HEURES_SUP"."NOTE" is 'Règle applicable : le repos compensatoire est le principe, la compensation en argent l''exception encadrée.';
comment on table "REF_CONDITION_TRAVAIL" is 'Conditions matérielles d''exécution du travail ouvrant droit à prime. Les trois familles générales sont posées ; chaque convention collective en précise le détail et y ajoute les siennes, par insert et sans migration.';
comment on column "REF_CONDITION_TRAVAIL"."CODE" is 'Code de la condition matérielle de travail : pénibilité, insalubrité, danger.';
comment on column "REF_CONDITION_TRAVAIL"."LIBELLE" is 'Libellé de la condition à l''écran.';
comment on column "REF_CONDITION_TRAVAIL"."FAMILLE" is 'Famille générale : penibilite, insalubrite, danger. Sert à regrouper, jamais à calculer — c''est la règle conventionnelle qui porte le taux.';
comment on column "REF_CONDITION_TRAVAIL"."DESCRIPTION" is 'Ce que la condition recouvre concrètement, pour que le constat sur le terrain soit reproductible d''un chef d''équipe à l''autre.';
comment on column "REF_CONDITION_TRAVAIL"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_CONDITION_TRAVAIL"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_CONDITION_TRAVAIL"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_CONDITION_TRAVAIL"."NOTE" is 'Conventions qui reconnaissent cette condition et articles correspondants.';
comment on table "REF_INDICATEUR_SECOURS" is 'Indicateurs dérivés de la fiche santé, destinés au dispatching et aux secours. Ils disent ce qu''il faut faire sans révéler la pathologie : « porte de l''adrénaline » plutôt que « allergique aux guêpes ». C''est ce qui permet au planning de faire son travail sans accéder à une donnée de santé.';
comment on column "REF_INDICATEUR_SECOURS"."CODE" is 'Code de l''indicateur de secours. Forme ANONYMISÉE d''une information médicale : l''indicateur dit qu''il faut agir, jamais de quelle pathologie il s''agit.';
comment on column "REF_INDICATEUR_SECOURS"."LIBELLE" is 'Libellé de l''indicateur, tel que le voit le dispatching.';
comment on column "REF_INDICATEUR_SECOURS"."CONSIGNE" is 'Ce qu''il faut faire, en clair, pour qui n''est ni médecin ni RH. C''est le texte qu''un secouriste lit.';
comment on column "REF_INDICATEUR_SECOURS"."VISIBLE_DISPATCHING" is 'Vrai si l''indicateur guide l''affectation — une interdiction de lieu, par exemple. Faux pour un indicateur purement médical d''urgence.';
comment on column "REF_INDICATEUR_SECOURS"."VISIBLE_SECOURS" is 'Vrai si l''indicateur peut être transmis aux secours. Certains indicateurs servent à l''organisation du travail et ne doivent pas sortir de ce cadre.';
comment on column "REF_INDICATEUR_SECOURS"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_INDICATEUR_SECOURS"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_INDICATEUR_SECOURS"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_INDICATEUR_SECOURS"."NOTE" is 'Conduite à tenir associée, et limite de ce que l''indicateur autorise à divulguer.';
comment on table "REF_LIEN_ENFANT" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_LIEN_ENFANT"."CODE" is 'Code du lien entre l''adulte et l''enfant : filiation, adoption, garde, recueil.';
comment on column "REF_LIEN_ENFANT"."LIBELLE" is 'Libellé du lien à l''écran.';
comment on column "REF_LIEN_ENFANT"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_LIEN_ENFANT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_LIEN_ENFANT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_LIEN_ENFANT"."NOTE" is 'Droits que ce lien ouvre ou n''ouvre pas — tous les liens ne donnent pas les mêmes droits familiaux.';
comment on table "REF_NATURE_PRIME" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_NATURE_PRIME"."CODE" is 'Code de la nature de prime.';
comment on column "REF_NATURE_PRIME"."LIBELLE" is 'Libellé de la nature de prime à l''écran.';
comment on column "REF_NATURE_PRIME"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_NATURE_PRIME"."CATEGORIE" is 'Regroupement de la nature de prime, pour les états de synthèse.';
comment on column "REF_NATURE_PRIME"."LIE_AUX_CONDITIONS" is 'Vrai si la prime dépend des conditions réelles d''exécution, et non d''une clause constante du contrat. Elle se calcule alors sur les créneaux effectivement travaillés sous ces conditions.';
comment on column "REF_NATURE_PRIME"."URL_SOURCE" is 'Lien vers la convention collective qui fixe le taux et les conditions. Une prime conventionnelle sans source n''est pas vérifiable.';
comment on column "REF_NATURE_PRIME"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_NATURE_PRIME"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_NATURE_PRIME"."NOTE" is 'Traitement fiscal et social de cette nature de prime, et texte qui le fonde.';
comment on table "REF_PAYS" is 'Correspondance ISO 3166-1 alpha-3 / alpha-2. L''application stocke l''alpha-3 ; l''alpha-2 sert à lire l''existant et les sources externes le temps de la transition.';
comment on column "REF_PAYS"."ALPHA3" is 'Code ISO 3166-1 alpha-3 du pays. C''est la clé primaire et le format utilisé PARTOUT dans le schéma — une colonne char(2) avait déjà fait rejeter « LUX », le projet a tranché pour l''alpha-3 partout.';
comment on column "REF_PAYS"."ALPHA2" is 'Code ISO 3166-1 alpha-2, conservé pour dialoguer avec les services externes qui ne connaissent que celui-là. Jamais utilisé comme clé.';
comment on column "REF_PAYS"."NOM" is 'Nom du pays en français, pour l''affichage.';
comment on column "REF_PAYS"."FRONTALIER" is 'Vrai si le pays ouvre le régime de travailleur frontalier au Luxembourg. Commande le traitement fiscal et l''affiliation.';
comment on column "REF_PAYS"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_PAYS"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "REF_STATUT_HEURES_SUP" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_STATUT_HEURES_SUP"."CODE" is 'Code du statut d''une demande d''heures supplémentaires.';
comment on column "REF_STATUT_HEURES_SUP"."LIBELLE" is 'Libellé du statut à l''écran.';
comment on column "REF_STATUT_HEURES_SUP"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_STATUT_HEURES_SUP"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_STATUT_HEURES_SUP"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_STATUT_HEURES_SUP"."NOTE" is 'Ce qui fait passer une demande dans ce statut, et qui en a le pouvoir.';
comment on table "REF_STATUT_VERIFICATION_ADRESSE" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."CODE" is 'Code du résultat de vérification d''adresse.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."LIBELLE" is 'Libellé du résultat à l''écran.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_STATUT_VERIFICATION_ADRESSE"."NOTE" is 'Ce que le statut implique : bloquant, à corriger, ou simplement hors périmètre de vérification.';
comment on table "REF_SUJET_EXPORT" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_SUJET_EXPORT"."CODE" is 'Code du sujet d''un export : salarié, société, fiduciaire, référentiel.';
comment on column "REF_SUJET_EXPORT"."LIBELLE" is 'Libellé du sujet à l''écran.';
comment on column "REF_SUJET_EXPORT"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_SUJET_EXPORT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_SUJET_EXPORT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_SUJET_EXPORT"."NOTE" is 'Périmètre exact de ce sujet d''export et fondement juridique du droit correspondant.';
comment on table "REF_TYPE_ADRESSE" is 'Les quatre natures d''adresse d''un salarié. Table de domaine : en ajouter une ne demande pas de migration.';
comment on column "REF_TYPE_ADRESSE"."CODE" is 'Code du type d''adresse : domicile légal, résidence effective, correspondance, facturation.';
comment on column "REF_TYPE_ADRESSE"."LIBELLE" is 'Libellé du type d''adresse à l''écran.';
comment on column "REF_TYPE_ADRESSE"."DESCRIPTION" is 'Ce à quoi ce type d''adresse sert, et pourquoi il ne se confond pas avec les autres. Le domicile légal fonde la fiscalité ; la résidence effective fonde les trajets.';
comment on column "REF_TYPE_ADRESSE"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_TYPE_ADRESSE"."SERT_AU_FISCAL" is 'Vrai pour la seule adresse qui fonde les distances officielles et les indemnisations fiscales — le domicile légal. Les autres ne doivent jamais servir à cela.';
comment on column "REF_TYPE_ADRESSE"."SERT_AUX_TOURNEES" is 'Vrai si ce type d''adresse est celui d''où partent les calculs de distance. Un seul type sert de point de départ : sans cela, deux calculs donneraient deux résultats.';
comment on column "REF_TYPE_ADRESSE"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_TYPE_ADRESSE"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "REF_UNITE_ESSAI" is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column "REF_UNITE_ESSAI"."CODE" is 'Code de l''unité de durée de la période d''essai : jours, semaines, mois.';
comment on column "REF_UNITE_ESSAI"."LIBELLE" is 'Libellé de l''unité à l''écran.';
comment on column "REF_UNITE_ESSAI"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_UNITE_ESSAI"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_UNITE_ESSAI"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_UNITE_ESSAI"."NOTE" is 'Durées minimales et maximales exprimées dans cette unité, et texte qui les fixe.';
comment on table "REF_UNITE_PRIME" is 'Unités auxquelles une prime de condition se rapporte. Table de domaine datée, comme toutes les autres : ajouter une unité ne demande pas de migration.';
comment on column "REF_UNITE_PRIME"."CODE" is 'Code de l''unité à laquelle la prime se rapporte : heure exposée, jour, mois, prestation.';
comment on column "REF_UNITE_PRIME"."LIBELLE" is 'Libellé de l''unité à l''écran.';
comment on column "REF_UNITE_PRIME"."DESCRIPTION" is 'Comment le temps relevé se convertit en montant pour cette unité.';
comment on column "REF_UNITE_PRIME"."ORDRE" is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column "REF_UNITE_PRIME"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "REF_UNITE_PRIME"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "REF_UNITE_PRIME"."NOTE" is 'Précisions d''application, notamment sur les seuils et les arrondis.';
comment on table "REGLES_CONVENTION" is 'Contenu d''une convention, bloc par bloc, en jsonb. C''est ce que le moteur compare à la loi pour retenir la disposition la plus favorable.';
comment on column "REGLES_CONVENTION"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "REGLES_CONVENTION"."CONVENTION_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "REGLES_CONVENTION"."BLOC" is 'Domaine couvert par le bloc (temps de travail, congés, préavis, rémunération...).';
comment on column "REGLES_CONVENTION"."REGLES" is 'Clauses du bloc, structurées. Une clause absente n''est pas une clause nulle : elle est inconnue.';
comment on column "REGLES_CONVENTION"."COMPLET" is 'Faux tant que le bloc n''a pas été entièrement saisi : le moteur sait alors qu''il ne peut pas conclure sur ce domaine.';
comment on column "REGLES_CONVENTION"."MODIFIE_LE" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on table "RELEVES_EFFECTIF" is 'Effectif mensuel figé. Sert au calcul de la moyenne sur douze mois, qui déclenche les obligations de seuil (délégation, travailleurs handicapés).';
comment on column "RELEVES_EFFECTIF"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "RELEVES_EFFECTIF"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "RELEVES_EFFECTIF"."MOIS" is 'Premier jour du mois observé.';
comment on column "RELEVES_EFFECTIF"."EFFECTIF" is 'Effectif en équivalents temps plein, d''où le type décimal.';
comment on table "RELEVES_TEMPS" is 'Registre du temps réellement travaillé, distinct du planning. C''est lui qui fait foi pour les majorations et les heures supplémentaires.';
comment on column "RELEVES_TEMPS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "RELEVES_TEMPS"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "RELEVES_TEMPS"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "RELEVES_TEMPS"."DATE_RELEVE" is 'Jour du relevé. Un relevé par jour et par salarié : c''est la maille de tous les compteurs.';
comment on column "RELEVES_TEMPS"."HEURE_DEBUT" is 'Heure de début relevée. Nulle pour un relevé saisi en durée seule, sans horaires.';
comment on column "RELEVES_TEMPS"."HEURE_FIN" is 'Heure de fin relevée. Nulle dans le même cas que start_time — les deux vont ensemble.';
comment on column "RELEVES_TEMPS"."PAUSE_MINUTES" is 'Pause en minutes, déduite du temps de travail effectif de la journée.';
comment on column "RELEVES_TEMPS"."HEURES_TRAVAILLEES" is 'Heures effectivement travaillées, pause déduite.';
comment on column "RELEVES_TEMPS"."HEURES_PREVUES" is 'Heures planifiées pour la même journée, pour mesurer l''écart.';
comment on column "RELEVES_TEMPS"."HEURES_DIMANCHE" is 'Part travaillée un dimanche, qui ouvre sa propre majoration.';
comment on column "RELEVES_TEMPS"."HEURES_FERIE" is 'Part travaillée un jour férié.';
comment on column "RELEVES_TEMPS"."HEURES_NUIT" is 'Part travaillée en période de nuit.';
comment on column "RELEVES_TEMPS"."HEURES_SUPPLEMENTAIRES" is 'Heures supplémentaires retenues sur la journée.';
comment on column "RELEVES_TEMPS"."VALIDE" is 'Vrai une fois la journée validée. Une journée non validée ne nourrit aucun calcul définitif.';
comment on column "RELEVES_TEMPS"."SOURCE" is 'Origine de la saisie : pointage, saisie manuelle, report du planning.';
comment on column "RELEVES_TEMPS"."NOTE" is 'Circonstances du relevé : dépassement, incident, rattrapage. Ce qu''un contrôle voudra comprendre.';
comment on column "RELEVES_TEMPS"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "ROLES_COMPTE" is 'Habilitations. Une ligne par couple utilisateur/périmètre ; c''est la table que lisent tous les prédicats RLS.';
comment on column "ROLES_COMPTE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ROLES_COMPTE"."COMPTE_ID" is 'Compte auquel le rôle est attribué. Un compte peut porter plusieurs rôles ; c''est le plus permissif qui s''applique, et les politiques RLS lisent cette table, jamais une valeur transmise par le client.';
comment on column "ROLES_COMPTE"."ORGANISATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "ROLES_COMPTE"."SOCIETE_ID" is 'Nul pour un rôle qui porte sur toute l''organisation. Renseigné pour un rôle limité à une société.';
comment on column "ROLES_COMPTE"."ROLE" is 'Rôle applicatif. Le rôle employee restreint l''utilisateur à son propre dossier.';
comment on column "ROLES_COMPTE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "RUPTURES_CONTRAT" is 'Rupture du contrat : motif, préavis, indemnités. Le moteur contrôle la licéité avant que la rupture ne soit enregistrée.';
comment on column "RUPTURES_CONTRAT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "RUPTURES_CONTRAT"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "RUPTURES_CONTRAT"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "RUPTURES_CONTRAT"."MOTIF" is 'Motif de la rupture, obligatoire. Détermine le préavis, l''indemnité de départ et la possibilité de contester.';
comment on column "RUPTURES_CONTRAT"."MOTIF_PERSONNEL" is 'Vrai pour un motif personnel, faux pour un motif économique — la distinction commande la procédure de licenciement collectif.';
comment on column "RUPTURES_CONTRAT"."NOTIFIE_LE" is 'Date de notification, point de départ du préavis.';
comment on column "RUPTURES_CONTRAT"."DEBUT_PREAVIS" is 'Début effectif du préavis, qui suit des règles de calendrier propres.';
comment on column "RUPTURES_CONTRAT"."FIN_PREAVIS" is 'Fin du préavis.';
comment on column "RUPTURES_CONTRAT"."INDEMNITE_MOIS" is 'Indemnité de départ, exprimée en mois de salaire de référence.';
comment on column "RUPTURES_CONTRAT"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "RUPTURES_CONTRAT"."PREAVIS_RENONCE" is 'Vrai si les parties ont convenu de dispenser le préavis.';
comment on column "RUPTURES_CONTRAT"."RENONCIATION_CONVENUE_LE" is 'Date de l''accord de renonciation au préavis, s''il y en a un. Nulle en l''absence d''accord : le préavis court alors en entier.';
comment on column "RUPTURES_CONTRAT"."COMPENSATION_RENONCIATION" is 'Contrepartie financière de la dispense de préavis.';
comment on column "RUPTURES_CONTRAT"."NOTE_RENONCIATION" is 'Contenu de l''accord de renonciation, dans les termes convenus. Une renonciation se prouve.';
comment on column "RUPTURES_CONTRAT"."FAUTE_GRAVE" is 'Faute grave : supprime le préavis, sous conditions strictes de procédure.';
comment on table "SALARIES" is 'Salarié. Les deux données les plus sensibles — matricule national et IBAN — ne sont pas stockées en clair : voir national_id_enc et iban_enc.';
comment on column "SALARIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SALARIES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SALARIES"."COMPTE_ID" is 'Compte applicatif du salarié, s''il accède à son espace personnel. Nul sinon.';
comment on column "SALARIES"."SERVICE_ID" is 'Service de rattachement, qui commande le planning et parfois la convention applicable.';
comment on column "SALARIES"."PRENOM" is 'Prénom usuel du salarié. Distinct de l''état civil complet : c''est ce qui s''affiche et s''imprime.';
comment on column "SALARIES"."NOM" is 'Nom de famille. Sert au tri et à la recherche ; un index trigramme le rend cherchable en approximation.';
comment on column "SALARIES"."DATE_NAISSANCE" is 'Date de naissance. Nulle tant qu''elle n''est pas connue — au stade de la candidature, par exemple. Sert au calcul des majorations liées à l''âge et au contrôle de cohérence du matricule.';
comment on column "SALARIES"."RESIDENCE" is 'Résident ou frontalier, et de quel pays. Détermine les pièces exigées et le traitement fiscal.';
comment on column "SALARIES"."QUALIFICATION" is 'Qualifié ou non qualifié : détermine le salaire social minimum applicable.';
comment on column "SALARIES"."LIGNE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "SALARIES"."CODE_POSTAL" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "SALARIES"."LOCALITE" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "SALARIES"."PAYS" is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU.';
comment on column "SALARIES"."COURRIEL" is 'Adresse personnelle du salarié. Distincte de celle du compte applicatif : tous les salariés n''ont pas de compte, et l''adresse de contact survit à la fin du contrat.';
comment on column "SALARIES"."TELEPHONE" is 'Téléphone de contact. Utilisé par le dispatching ; l''accès en est restreint comme toute donnée de contact personnel.';
comment on column "SALARIES"."MATRICULE_NATIONAL_CHIFFRE" is 'Matricule national CHIFFRÉ (pgcrypto). Ne jamais lire directement : fn_employee_sensitive contrôle l''accès et déchiffre.';
comment on column "SALARIES"."IBAN_CHIFFRE" is 'IBAN CHIFFRÉ. Même règle d''accès que le matricule.';
comment on column "SALARIES"."MATRICULE_NATIONAL_INDICE" is 'Fragment non identifiant du matricule, affichable pour reconnaître une fiche sans exposer la donnée.';
comment on column "SALARIES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "SALARIES"."SEXE" is 'Sexe déclaré par le salarié, librement. Modifiable par lui depuis son espace. À ne pas confondre avec sexe_legal, qui est dérivé et non déclaratif. Sera renommé sexe_declare lors du passage au français.';
comment on column "SALARIES"."DATE_DEBUT_CARRIERE" is 'Début de carrière professionnelle, distinct de l''entrée dans la société. Sert à l''acquisition de la qualification par l''ancienneté.';
comment on column "SALARIES"."PROFESSION" is 'Profession déclarée, distincte de l''intitulé de poste porté par le contrat.';
comment on column "SALARIES"."EST_CADRE" is 'Vrai pour le personnel de direction, exclu de certains droits collectifs.';
comment on column "SALARIES"."SEXE_LEGAL" is 'Sexe juridique, DÉRIVÉ du matricule national : parité du numéro d''ordre (position 11). Recalculé à chaque écriture — toute valeur soumise est ignorée, la dérivation fait foi. Nul tant qu''aucun matricule n''est enregistré. Le salarié y a accès (RGPD art. 15) mais ne peut pas le modifier.';
comment on column "SALARIES"."REFUS_PHOTOS_SOCIETE" is 'Le salarié refuse d''apparaître sur les photos de la société. Consentement au sens du RGPD : révocable à tout moment, et sans justification à fournir.';
comment on column "SALARIES"."SOUHAITE_CONFIDENTIALITE" is 'Le salarié souhaite ne pas apparaître — annuaire, trombinoscope, communications. Distinct du droit à l''effacement, qui porte sur la donnée elle-même.';
comment on table "SANCTIONS_SALARIE" is 'Sanctions disciplinaires prononcées. Donnée personnelle sensible au sens du RGPD : accès restreint aux gestionnaires et à la personne concernée, conservation bornée par retention_until, suppression logique pour que le dossier reste cohérent après effacement.';
comment on column "SANCTIONS_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SANCTIONS_SALARIE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SANCTIONS_SALARIE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "SANCTIONS_SALARIE"."CONTRAT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "SANCTIONS_SALARIE"."TYPE_SANCTION" is 'Type de sanction prononcée, parmi sanction_types.';
comment on column "SANCTIONS_SALARIE"."FAITS_LE" is 'Date des faits reprochés.';
comment on column "SANCTIONS_SALARIE"."FAITS_CONNUS_LE" is 'Date à laquelle l''employeur en a eu connaissance. C''est elle, et non la date des faits, qui fait courir le délai de notification.';
comment on column "SANCTIONS_SALARIE"."NOTIFIE_LE" is 'Date de notification au salarié. Une sanction non notifiée n''existe pas à son égard.';
comment on column "SANCTIONS_SALARIE"."EFFET_DU" is 'Premier jour d''effet, inclus. Nul pour une sanction sans effet daté, comme un avertissement.';
comment on column "SANCTIONS_SALARIE"."EFFET_AU" is 'Dernier jour d''effet, INCLUS. Une mise à pied a une fin ; un avertissement n''en a pas.';
comment on column "SANCTIONS_SALARIE"."MOTIF" is 'Faits reprochés, obligatoires. Une sanction sans motif écrit est contestable de ce seul fait.';
comment on column "SANCTIONS_SALARIE"."PIECE_JUSTIFICATIVE_ID" is 'Pièce au dossier : lettre de notification, compte rendu d''entretien. Ce qui prouve que la procédure a été suivie.';
comment on column "SANCTIONS_SALARIE"."RUPTURE_ID" is 'Rupture correspondante, quand la sanction est un licenciement. Les deux lignes décrivent le même fait sous deux angles.';
comment on column "SANCTIONS_SALARIE"."CONTRAT_AVENANT_ID" is 'Avenant produit par la sanction, quand elle modifie le contrat — rétrogradation, mutation.';
comment on column "SANCTIONS_SALARIE"."SALARIE_ENTENDU_LE" is 'Date à laquelle le salarié a été entendu. L''entretien préalable est requis au-delà d''un seuil d''effectif que le moteur lit dans le référentiel.';
comment on column "SANCTIONS_SALARIE"."REPONSE_SALARIE" is 'Observations du salarié. Le droit de répondre fait partie de la procédure : la réponse se conserve, même si elle ne change pas la décision.';
comment on column "SANCTIONS_SALARIE"."CONTESTE_LE" is 'Date de contestation par le salarié. Nulle tant qu''il n''a pas contesté.';
comment on column "SANCTIONS_SALARIE"."ISSUE_CONTESTATION" is 'Issue de la contestation : maintien, réduction, retrait. Une sanction retirée reste en base, avec son issue — l''effacer réécrirait l''histoire.';
comment on column "SANCTIONS_SALARIE"."NOTE" is 'Suites internes : suivi, accompagnement, rappel à l''ordre ultérieur.';
comment on column "SANCTIONS_SALARIE"."CONSERVATION_JUSQUAU" is 'Date au-delà de laquelle la sanction ne doit plus être conservée. Un dossier disciplinaire ne se garde pas indéfiniment.';
comment on column "SANCTIONS_SALARIE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "SANCTIONS_SALARIE"."CREE_PAR" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "SANCTIONS_SALARIE"."MODIFIE_LE" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column "SANCTIONS_SALARIE"."MODIFIE_PAR" is 'Compte auteur de la dernière modification. Sur une sanction, chaque retouche doit rester attribuable.';
comment on column "SANCTIONS_SALARIE"."SUPPRIME_LE" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "SANCTIONS_SALARIE"."SUPPRIME_PAR" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "SECRETS_APPLICATION" is 'Clés de chiffrement du moteur. RLS active et VOLONTAIREMENT sans aucune politique : aucune ligne n''est donc accessible par l''API REST. Seules les fonctions security definer fn_encrypt_field et fn_decrypt_field y accèdent, et ces deux fonctions ne sont exécutables par personne hors du moteur.';
comment on column "SECRETS_APPLICATION"."CLE" is 'Nom du secret. La table porte RLS active et VOLONTAIREMENT aucune politique : aucune ligne n''est accessible par l''API REST, seules les fonctions security definer du moteur y accèdent.';
comment on column "SECRETS_APPLICATION"."SECRET" is 'Valeur du secret. Voir la remarque sur la table : elle n''est lisible par personne à travers l''API. Un secret qui vit dans la base qu''il protège reste un compromis assumé et documenté.';
comment on table "SERVICES" is 'Service ou établissement d''une société. Porte un planning et, le cas échéant, sa propre convention collective.';
comment on column "SERVICES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SERVICES"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SERVICES"."NOM" is 'Nom du service. Sert au périmètre de dispatching et à la résolution conventionnelle, qui peut se faire par service.';
comment on column "SERVICES"."COUVERTURE_SOIR_MIN" is 'Effectif minimal exigé en soirée. Contrainte d''exploitation, vérifiée à la validation d''un planning.';
comment on table "SINISTRES_ACCIDENT_SOCIETE" is 'Sinistralité accident déclarée par exercice. Alimente le suivi du facteur bonus-malus.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."ANNEE" is 'Année de survenance des sinistres, pour le calcul du bonus-malus accident du travail.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."NOMBRE_SINISTRES" is 'Nombre de sinistres déclarés.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."JOURS_PERDUS" is 'Journées de travail perdues sur l''exercice.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."COUT" is 'Coût des sinistres de l''année, en euros. Entre dans la détermination de la classe de risque et donc du taux de cotisation accident.';
comment on column "SINISTRES_ACCIDENT_SOCIETE"."NOTE" is 'Précisions sur les sinistres retenus ou exclus.';
comment on table "SITES_CLIENT" is 'Lieu où une vacation peut s''exécuter hors du siège : chantier, site client, antenne. Porte l''adresse qui sert au calcul de distance.';
comment on column "SITES_CLIENT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SITES_CLIENT"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SITES_CLIENT"."NOM" is 'Nom du site client, tel qu''il apparaît sur les plannings et les ordres de mission.';
comment on column "SITES_CLIENT"."NOM_CLIENT" is 'Nom du client donneur d''ordre, distinct du nom du site.';
comment on column "SITES_CLIENT"."LIGNE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "SITES_CLIENT"."CODE_POSTAL" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "SITES_CLIENT"."LOCALITE" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "SITES_CLIENT"."PAYS" is 'Pays du site, en code ISO 3166-1 alpha-3.';
comment on column "SITES_CLIENT"."LATITUDE" is 'Coordonnée, si elle est connue : elle évite de transmettre une adresse en clair au service de distance.';
comment on column "SITES_CLIENT"."LONGITUDE" is 'Longitude en degrés décimaux, obtenue par géocodage. Avec la latitude, permet de calculer la distance depuis l''adresse du salarié.';
comment on column "SITES_CLIENT"."ACTIF" is 'Faux quand le site n''est plus desservi. Le site reste en base : les plannings passés le nomment encore.';
comment on column "SITES_CLIENT"."NOTE" is 'Consignes d''accès et contraintes du site. Lues par qui s''y rend, pas par le moteur.';
comment on column "SITES_CLIENT"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "SOCIETES" is 'Société employeuse. Deuxième clé d''isolation après l''organisation : la quasi-totalité des tables métier porte un company_id.';
comment on column "SOCIETES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SOCIETES"."ORGANISATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "SOCIETES"."RAISON_SOCIALE" is 'Raison sociale, telle qu''inscrite au registre de commerce. C''est ce nom qui figure sur les contrats et les bulletins.';
comment on column "SOCIETES"."FORME_JURIDIQUE" is 'Forme juridique (Sàrl, SA, etc.). Sans effet sur le moteur, utile aux documents.';
comment on column "SOCIETES"."NUMERO_RCS" is 'Numéro au Registre de commerce et des sociétés.';
comment on column "SOCIETES"."MATRICULE_CCSS" is 'Matricule CCSS de l''employeur. Validé par fn_check_national_id (longueur, date encodée, clés de Luhn et de Verhoeff).';
comment on column "SOCIETES"."LIGNE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "SOCIETES"."CODE_POSTAL" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "SOCIETES"."LOCALITE" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "SOCIETES"."PAYS" is 'Pays du siège, en code ISO 3166-1 alpha-3. Le projet utilise partout l''alpha-3, y compris là où l''alpha-2 suffirait : un seul format évite les conversions silencieuses.';
comment on column "SOCIETES"."CODE_NACE" is 'Code d''activité NACE, base du rattachement sectoriel et de la classe de risque accident.';
comment on column "SOCIETES"."SECTEUR" is 'Secteur déclaré. Sert au rapprochement avec les conventions collectives sectorielles.';
comment on column "SOCIETES"."PERIODE_REFERENCE_MOIS" is 'Durée par défaut de la période de référence pour le calcul du temps de travail, si aucune période explicite n''est définie.';
comment on column "SOCIETES"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "SOCIETES"."REGLEMENT_INTERIEUR_ADOPTE_LE" is 'Date d''adoption des textes internes de l''entreprise. Sans eux, aucune sanction lourde n''est valable — le moteur le vérifie.';
comment on column "SOCIETES"."REFERENCE_REGLEMENT_INTERIEUR" is 'Référence et date d''adoption du règlement intérieur. Une sanction lourde n''est valable que si elle y figure : sans cette référence, le moteur le signale.';
comment on table "STATUTS_SALARIE" is 'Statuts protégés : grossesse, suites de couches, mandat de délégué. Ils conditionnent la protection contre le licenciement.';
comment on column "STATUTS_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "STATUTS_SALARIE"."SOCIETE_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "STATUTS_SALARIE"."SALARIE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "STATUTS_SALARIE"."GENRE" is 'Nature du statut, qui commande la protection applicable.';
comment on column "STATUTS_SALARIE"."DECLARE_LE" is 'Date à laquelle l''employeur a été informé. C''est elle, et non le fait lui-même, qui déclenche la protection.';
comment on column "STATUTS_SALARIE"."DATE_DEBUT" is 'Premier jour du statut, inclus. Un statut protégé — grossesse, délégation, congé parental — ouvre des protections qui commencent ce jour-là.';
comment on column "STATUTS_SALARIE"."DATE_FIN" is 'Dernier jour du statut, borne haute INCLUSE. Jamais nulle : un statut toujours actif porte la sentinelle 2037-12-31.';
comment on column "STATUTS_SALARIE"."DATE_NAISSANCE_PREVUE" is 'Date présumée de l''accouchement, qui borne la période protégée.';
comment on column "STATUTS_SALARIE"."DATE_NAISSANCE_REELLE" is 'Date réelle, qui rectifie la borne une fois connue.';
comment on column "STATUTS_SALARIE"."PIECE_JUSTIFICATIVE_ID" is 'Pièce justifiant le statut : certificat, procès-verbal d''élection. Une protection invoquée sans pièce ne tient pas devant l''ITM.';
comment on column "STATUTS_SALARIE"."CREDIT_HEURES_MENSUEL" is 'Crédit d''heures mensuel attaché au mandat, pour les délégués.';
comment on column "STATUTS_SALARIE"."NOTE" is 'Précisions sur la portée du statut et sur ce qu''il interdit à l''employeur.';
comment on column "STATUTS_SALARIE"."CREE_LE" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "TRANCHES_IMPOT" is 'Barème de l''impôt sur les traitements et salaires, par classe et par périodicité. Table structurellement prête ; son chargement relève de la V2 brut vers net.';
comment on column "TRANCHES_IMPOT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TRANCHES_IMPOT"."CLASSE_IMPOT" is 'Classe d''impôt à laquelle le barème s''applique. Le passage à la classe unique prévu pour 2027 se traduira par de nouvelles lignes datées, pas par une modification des anciennes.';
comment on column "TRANCHES_IMPOT"."PERIODICITE" is 'Périodicité du barème : mensuel, annuel. Un barème mensuel n''est pas le douzième d''un barème annuel.';
comment on column "TRANCHES_IMPOT"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "TRANCHES_IMPOT"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "TRANCHES_IMPOT"."TRANCHE_MIN" is 'Borne basse de la tranche.';
comment on column "TRANCHES_IMPOT"."TRANCHE_MAX" is 'Borne haute. Nul pour la dernière tranche.';
comment on column "TRANCHES_IMPOT"."IMPOT_BASE" is 'Impôt cumulé dû à la borne basse de la tranche.';
comment on column "TRANCHES_IMPOT"."TAUX_AU_DESSUS_MINIMUM" is 'Taux appliqué à la fraction du revenu dépassant la borne basse.';
comment on column "TRANCHES_IMPOT"."SOURCE" is 'Publication d''origine du barème. Sans source, un barème ne se vérifie pas — et la règle 7 du projet interdit de l''inventer.';
comment on column "TRANCHES_IMPOT"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TRANCHES_IMPOT"."NOTE" is 'Précisions sur la tranche : arrondis, cas particuliers, articulation avec les crédits.';
comment on table "TYPES_ABSENCE" is 'Catalogue des motifs d''absence : congés, maladie, congés extraordinaires, absences non rémunérées.';
comment on column "TYPES_ABSENCE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TYPES_ABSENCE"."CODE" is 'Code stable du type d''absence, utilisé par le moteur et par les deux interfaces. Il ne change jamais : c''est le libellé qui se retouche, pas le code.';
comment on column "TYPES_ABSENCE"."LIBELLE" is 'Libellé affiché du type d''absence, en français. Destiné à l''écran, jamais à une comparaison.';
comment on column "TYPES_ABSENCE"."CATEGORIE" is 'Famille d''absence, qui commande le traitement par le moteur.';
comment on column "TYPES_ABSENCE"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TYPES_ABSENCE"."CERTIFICAT_EXIGE" is 'Vrai si un justificatif est exigé pour que l''absence soit régulière.';
comment on column "TYPES_ABSENCE"."REMUNERE" is 'Vrai si l''absence est rémunérée par l''employeur.';
comment on column "TYPES_ABSENCE"."IMPUTE_SUR_CONGE" is 'Vrai si l''absence s''impute sur le solde de congé annuel.';
comment on table "TYPES_AVANTAGE" is 'Catalogue des avantages en nature et de leur méthode d''évaluation.';
comment on column "TYPES_AVANTAGE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TYPES_AVANTAGE"."CODE" is 'Code de l''avantage en nature, stable, utilisé par la paie.';
comment on column "TYPES_AVANTAGE"."LIBELLE" is 'Libellé de l''avantage à l''écran et sur le bulletin.';
comment on column "TYPES_AVANTAGE"."METHODE_EVALUATION" is 'Méthode d''évaluation : forfait, pourcentage, barème.';
comment on column "TYPES_AVANTAGE"."IMPOSABLE" is 'Vrai si l''avantage entre dans l''assiette imposable.';
comment on column "TYPES_AVANTAGE"."COTISABLE" is 'Vrai si l''avantage entre dans l''assiette cotisable.';
comment on column "TYPES_AVANTAGE"."PARAMETRES_EVALUATION" is 'Paramètres de la méthode. Les valeurs légales elles-mêmes restent dans legal_parameters.';
comment on column "TYPES_AVANTAGE"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TYPES_AVANTAGE"."NOTE" is 'Mode d''évaluation de l''avantage et texte qui le fonde.';
comment on table "TYPES_DOCUMENT" is 'Catalogue des pièces attendues d''un salarié ou d''un contrat, avec leur durée de validité et le préavis d''alerte avant échéance.';
comment on column "TYPES_DOCUMENT"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TYPES_DOCUMENT"."CODE" is 'Code du type de document, stable, utilisé par le moteur de conformité pour vérifier qu''une pièce obligatoire est présente.';
comment on column "TYPES_DOCUMENT"."LIBELLE" is 'Libellé du type de document à l''écran.';
comment on column "TYPES_DOCUMENT"."ECHELON" is 'Moment du cycle de vie où la pièce est attendue : embauche, cours de contrat, ou fin de contrat.';
comment on column "TYPES_DOCUMENT"."VALIDITE_MOIS" is 'Durée de validité en mois. Nul pour une pièce qui ne périme pas.';
comment on column "TYPES_DOCUMENT"."OBLIGATOIRE" is 'Vrai si l''absence de la pièce constitue un manquement, et non un simple oubli.';
comment on column "TYPES_DOCUMENT"."RESIDENCES_VISEES" is 'Statuts de résidence concernés : une autorisation de travail ne vise pas un résident.';
comment on column "TYPES_DOCUMENT"."ALERTE_JOURS_AVANT" is 'Délai d''anticipation de l''alerte avant expiration.';
comment on column "TYPES_DOCUMENT"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TYPES_DOCUMENT"."NOTE" is 'Fondement de l''obligation et durée de conservation attendue.';
comment on table "TYPES_SANCTION" is 'Catalogue des sanctions applicables, daté. Chaque type porte ses effets — présence, rémunération, contrat — et ce qu''il exige de l''employeur. Le moteur lit ces drapeaux ; il ne les devine pas.';
comment on column "TYPES_SANCTION"."CODE" is 'Code du type de sanction, stable. Huit types répartis dans les trois catégories.';
comment on column "TYPES_SANCTION"."CODE_CATEGORIE" is 'Catégorie de rattachement, parmi sanction_categories. Détermine la procédure et les délais.';
comment on column "TYPES_SANCTION"."LIBELLE" is 'Libellé du type de sanction à l''écran.';
comment on column "TYPES_SANCTION"."DESCRIPTION" is 'Portée exacte de la sanction et conditions de validité. Une sanction lourde suppose notamment qu''elle figure dans les textes internes de l''entreprise.';
comment on column "TYPES_SANCTION"."SUSPEND_PRESENCE" is 'Vrai si la sanction suspend la présence du salarié — mise à pied. Le planning doit alors cesser de l''affecter sur la période.';
comment on column "TYPES_SANCTION"."AFFECTE_PAIE" is 'Vrai si la rémunération est suspendue ou réduite. Distingue la mise à pied disciplinaire de la conservatoire, qui maintient le salaire.';
comment on column "TYPES_SANCTION"."REGLEMENT_INTERIEUR_EXIGE" is 'Vrai si la sanction n''est valable qu''à condition de figurer dans les textes internes de l''entreprise. C''est le cas de toutes les sanctions lourdes.';
comment on column "TYPES_SANCTION"."MODIFIE_CONTRAT" is 'Vrai si la sanction modifie le contrat. Elle passe alors par fn_amend_contract et, si la baisse de rémunération est substantielle, requiert l''''accord du salarié ou une procédure propre.';
comment on column "TYPES_SANCTION"."ROMPT_CONTRAT" is 'Vrai si la sanction met fin au contrat. Déclenche le circuit de rupture : préavis, indemnités, documents de fin de contrat.';
comment on column "TYPES_SANCTION"."NEEDS_NOTICE" is 'Vrai si un préavis est dû, faux s''''il ne l''''est pas, nul si la question ne se pose pas. Le calcul du préavis lui-même reste à fn_notice_period.';
comment on column "TYPES_SANCTION"."REFERENCE_LEGALE" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TYPES_SANCTION"."NOTE" is 'Références et précisions sur l''usage du type. Ce qui permet de vérifier qu''on applique la bonne sanction.';
comment on column "TYPES_SANCTION"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "TYPES_SANCTION"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "ZONES_ADRESSE" is 'Zones géographiques dans lesquelles une adresse est acceptée. Hors de ces zones, la saisie est refusée : l''outil ne prétend pas couvrir des adresses qu''il ne sait pas vérifier.';
comment on column "ZONES_ADRESSE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ZONES_ADRESSE"."PAYS" is 'Code pays ISO 3166-1 alpha-3. Trois lettres partout dans l''application.';
comment on column "ZONES_ADRESSE"."GENRE" is 'Nature de la zone : pays, région frontalière, plage de codes postaux. Détermine comment les bornes se lisent.';
comment on column "ZONES_ADRESSE"."CODE" is 'Code de la zone, repris par address_checks.zone_code et par les barèmes qui s''y réfèrent.';
comment on column "ZONES_ADRESSE"."LIBELLE" is 'Nom lisible de la zone, pour l''affichage et les messages de contrôle.';
comment on column "ZONES_ADRESSE"."CODE_POSTAL_DU" is 'Borne basse du code postal, une fois le préfixe pays retiré. Nulle quand le pays n''admet pas de découpage postal fiable — voir is_verified.';
comment on column "ZONES_ADRESSE"."CODE_POSTAL_AU" is 'Borne haute INCLUSE de la plage de codes postaux couverte. Nulle si la zone ne se décrit pas par une plage.';
comment on column "ZONES_ADRESSE"."VERIFIE" is 'Vrai si les bornes postales sont établies et vérifiables. Faux pour une zone déclarée sans correspondance postale fiable : la validation répond alors « indéterminé » plutôt que d''accepter à tort.';
comment on column "ZONES_ADRESSE"."SOURCE" is 'D''où viennent les bornes. Une zone sans source n''a rien à faire ici.';
comment on column "ZONES_ADRESSE"."NOTE" is 'Origine de la délimitation : convention, accord frontalier, choix de paramétrage. Ce qui permet de la contester.';
comment on table "REF_BLOC_CONVENTION" is 'Table de référence issue du type énuméré PostgreSQL bloc_convention.';
comment on table "REF_CATEGORIE_ABSENCE" is 'Table de référence issue du type énuméré PostgreSQL categorie_absence.';
comment on table "REF_CLASSE_IMPOT" is 'Table de référence issue du type énuméré PostgreSQL classe_impot.';
comment on table "REF_ETAPE_DOCUMENT" is 'Table de référence issue du type énuméré PostgreSQL etape_document.';
comment on table "REF_ETAT_ALERTE" is 'Table de référence issue du type énuméré PostgreSQL etat_alerte.';
comment on table "REF_FAMILLE_PARAMETRE" is 'Table de référence issue du type énuméré PostgreSQL famille_parametre.';
comment on table "REF_GENRE_CONTRAT" is 'Table de référence issue du type énuméré PostgreSQL genre_contrat.';
comment on table "REF_GENRE_ELEMENT_REMUNERATION" is 'Table de référence issue du type énuméré PostgreSQL genre_element_remuneration.';
comment on table "REF_GENRE_ORGANISATION" is 'Table de référence issue du type énuméré PostgreSQL genre_organisation.';
comment on table "REF_GENRE_QUALIFICATION" is 'Table de référence issue du type énuméré PostgreSQL genre_qualification.';
comment on table "REF_GENRE_RESIDENCE" is 'Table de référence issue du type énuméré PostgreSQL genre_residence.';
comment on table "REF_GENRE_SEVERITE" is 'Table de référence issue du type énuméré PostgreSQL genre_severite.';
comment on table "REF_GENRE_SEXE" is 'Table de référence issue du type énuméré PostgreSQL genre_sexe.';
comment on table "REF_GENRE_STATUT_SALARIE" is 'Table de référence issue du type énuméré PostgreSQL genre_statut_salarie.';
comment on table "REF_PERIODICITE_IMPOT" is 'Table de référence issue du type énuméré PostgreSQL periodicite_impot.';
comment on table "REF_PORTEE_CONVENTION" is 'Table de référence issue du type énuméré PostgreSQL portee_convention.';
comment on table "REF_ROLE_APPLICATION" is 'Table de référence issue du type énuméré PostgreSQL role_application.';
comment on table "REF_STATUT_ABSENCE" is 'Table de référence issue du type énuméré PostgreSQL statut_absence.';
comment on table "REF_STATUT_CONTRAT" is 'Table de référence issue du type énuméré PostgreSQL statut_contrat.';
comment on table "REF_STATUT_PLANNING" is 'Table de référence issue du type énuméré PostgreSQL statut_planning.';

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

create or replace trigger adresses_salarie_no_overlap
  for insert or update on "ADRESSES_SALARIE"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "ADRESSES_SALARIE"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "ADRESSES_SALARIE" a
             join "ADRESSES_SALARIE" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SALARIE_ID" = b."SALARIE_ID" and a."TYPE_ADRESSE" = b."TYPE_ADRESSE"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur adresses_salarie : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end adresses_salarie_no_overlap;
/

create or replace trigger attributions_titres_repa_no_overlap
  for insert or update on "ATTRIBUTIONS_TITRES_REPAS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "ATTRIBUTIONS_TITRES_REPAS"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "ATTRIBUTIONS_TITRES_REPAS" a
             join "ATTRIBUTIONS_TITRES_REPAS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SALARIE_ID" = b."SALARIE_ID"
              and a."DEBUT_PERIODE" < b."FIN_PERIODE"
              and a."FIN_PERIODE" > b."DEBUT_PERIODE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur attributions_titres_repas : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end attributions_titres_repa_no_overlap;
/

create or replace trigger contrats_no_overlap
  for insert or update on "CONTRATS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "CONTRATS"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "CONTRATS" a
             join "CONTRATS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SALARIE_ID" = b."SALARIE_ID"
              and a."DATE_DEBUT" < b."DATE_FIN"
              and a."DATE_FIN" > b."DATE_DEBUT");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur contrats : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end contrats_no_overlap;
/

create or replace trigger droits_absence_no_overlap
  for insert or update on "DROITS_ABSENCE"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "DROITS_ABSENCE"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "DROITS_ABSENCE" a
             join "DROITS_ABSENCE" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."TYPE_ABSENCE_ID" = b."TYPE_ABSENCE_ID"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur droits_absence : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end droits_absence_no_overlap;
/

create or replace trigger fiches_retenue_impot_no_overlap
  for insert or update on "FICHES_RETENUE_IMPOT"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "FICHES_RETENUE_IMPOT"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "FICHES_RETENUE_IMPOT" a
             join "FICHES_RETENUE_IMPOT" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SALARIE_ID" = b."SALARIE_ID"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur fiches_retenue_impot : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end fiches_retenue_impot_no_overlap;
/

create or replace trigger handicaps_salarie_no_overlap
  for insert or update on "HANDICAPS_SALARIE"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "HANDICAPS_SALARIE"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "HANDICAPS_SALARIE" a
             join "HANDICAPS_SALARIE" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SALARIE_ID" = b."SALARIE_ID"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur handicaps_salarie : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end handicaps_salarie_no_overlap;
/

create or replace trigger parametres_legaux_no_overlap
  for insert or update on "PARAMETRES_LEGAUX"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "PARAMETRES_LEGAUX"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "PARAMETRES_LEGAUX" a
             join "PARAMETRES_LEGAUX" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."CLE_PARAMETRE" = b."CLE_PARAMETRE"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur parametres_legaux : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end parametres_legaux_no_overlap;
/

create or replace trigger periodes_taux_societe_no_overlap
  for insert or update on "PERIODES_TAUX_SOCIETE"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "PERIODES_TAUX_SOCIETE"."ID"%type index by pls_integer;
  g_ids t_ids;

  after each row is
  begin
    g_ids(g_ids.count + 1) := :new."ID";
  end after each row;

  after statement is
    v_conflit number;
  begin
    -- La table n'est plus en mutation ici : on peut l'interroger.
    for i in 1 .. g_ids.count loop
      begin
        -- `exists` s'arrête au premier conflit trouvé ; inutile d'en
        -- compter davantage pour savoir qu'il y en a un.
        select 1 into v_conflit from dual
         where exists (
           select 1
             from "PERIODES_TAUX_SOCIETE" a
             join "PERIODES_TAUX_SOCIETE" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and a."SOCIETE_ID" = b."SOCIETE_ID"
              and a."DEBUT_VALIDITE" < b."FIN_VALIDITE"
              and a."FIN_VALIDITE" > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur periodes_taux_societe : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end periodes_taux_societe_no_overlap;
/


