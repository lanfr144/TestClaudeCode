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

create table "REF_ABSENCE_CATEGORY" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_absence_category_pk primary key ("CODE")
);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('annual_leave', 'annual_leave', 1);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('sick', 'sick', 2);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('extraordinary', 'extraordinary', 3);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('public_holiday', 'public_holiday', 4);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('unpaid', 'unpaid', 5);
insert into "REF_ABSENCE_CATEGORY" ("CODE", "LABEL", "SORT_ORDER") values ('compensatory', 'compensatory', 6);

create table "REF_ABSENCE_STATUS" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_absence_status_pk primary key ("CODE")
);
insert into "REF_ABSENCE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('pending', 'pending', 1);
insert into "REF_ABSENCE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('approved', 'approved', 2);
insert into "REF_ABSENCE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('refused', 'refused', 3);
insert into "REF_ABSENCE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('cancelled', 'cancelled', 4);
insert into "REF_ABSENCE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('proposed', 'proposed', 5);

create table "REF_ALERT_STATE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_alert_state_pk primary key ("CODE")
);
insert into "REF_ALERT_STATE" ("CODE", "LABEL", "SORT_ORDER") values ('open', 'open', 1);
insert into "REF_ALERT_STATE" ("CODE", "LABEL", "SORT_ORDER") values ('handled', 'handled', 2);
insert into "REF_ALERT_STATE" ("CODE", "LABEL", "SORT_ORDER") values ('dismissed', 'dismissed', 3);

create table "REF_APP_ROLE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_app_role_pk primary key ("CODE")
);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('fiduciary_admin', 'fiduciary_admin', 1);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('manager', 'manager', 2);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('service_manager', 'service_manager', 3);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('employee', 'employee', 4);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('medecine_travail', 'medecine_travail', 5);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('rh_urgence', 'rh_urgence', 6);
insert into "REF_APP_ROLE" ("CODE", "LABEL", "SORT_ORDER") values ('dispatching', 'dispatching', 7);

create table "REF_CBA_BLOCK" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_cba_block_pk primary key ("CODE")
);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('salary_grid', 'salary_grid', 1);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('worktime', 'worktime', 2);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('leave', 'leave', 3);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('premiums', 'premiums', 4);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('surcharges', 'surcharges', 5);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('notice_probation', 'notice_probation', 6);
insert into "REF_CBA_BLOCK" ("CODE", "LABEL", "SORT_ORDER") values ('custom_holidays', 'custom_holidays', 7);

create table "REF_CBA_SCOPE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_cba_scope_pk primary key ("CODE")
);
insert into "REF_CBA_SCOPE" ("CODE", "LABEL", "SORT_ORDER") values ('sector', 'sector', 1);
insert into "REF_CBA_SCOPE" ("CODE", "LABEL", "SORT_ORDER") values ('harassment', 'harassment', 2);
insert into "REF_CBA_SCOPE" ("CODE", "LABEL", "SORT_ORDER") values ('employee_category', 'employee_category', 3);
insert into "REF_CBA_SCOPE" ("CODE", "LABEL", "SORT_ORDER") values ('department', 'department', 4);
insert into "REF_CBA_SCOPE" ("CODE", "LABEL", "SORT_ORDER") values ('company', 'company', 5);

create table "REF_CONTRACT_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_contract_kind_pk primary key ("CODE")
);
insert into "REF_CONTRACT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('cdi', 'cdi', 1);
insert into "REF_CONTRACT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('cdd', 'cdd', 2);
insert into "REF_CONTRACT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('seasonal', 'seasonal', 3);
insert into "REF_CONTRACT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('apprenticeship', 'apprenticeship', 4);
insert into "REF_CONTRACT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('interim', 'interim', 5);

create table "REF_CONTRACT_STATUS" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_contract_status_pk primary key ("CODE")
);
insert into "REF_CONTRACT_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('draft', 'draft', 1);
insert into "REF_CONTRACT_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('active', 'active', 2);
insert into "REF_CONTRACT_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('ended', 'ended', 3);
insert into "REF_CONTRACT_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('cancelled', 'cancelled', 4);

create table "REF_DOCUMENT_STAGE" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_document_stage_pk primary key ("CODE")
);
insert into "REF_DOCUMENT_STAGE" ("CODE", "LABEL", "SORT_ORDER") values ('pre_hire', 'pre_hire', 1);
insert into "REF_DOCUMENT_STAGE" ("CODE", "LABEL", "SORT_ORDER") values ('during_contract', 'during_contract', 2);
insert into "REF_DOCUMENT_STAGE" ("CODE", "LABEL", "SORT_ORDER") values ('end_of_contract', 'end_of_contract', 3);

create table "REF_EMPLOYEE_STATUS_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_employee_status_kind_pk primary key ("CODE")
);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('pregnancy', 'pregnancy', 1);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('maternity_leave', 'maternity_leave', 2);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('breastfeeding', 'breastfeeding', 3);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('parental_leave', 'parental_leave', 4);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('delegate', 'delegate', 5);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('safety_delegate', 'safety_delegate', 6);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('equality_delegate', 'equality_delegate', 7);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('reemployment_bonus', 'reemployment_bonus', 8);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('company_manager', 'company_manager', 9);
insert into "REF_EMPLOYEE_STATUS_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('protected_other', 'protected_other', 10);

create table "REF_ORG_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_org_kind_pk primary key ("CODE")
);
insert into "REF_ORG_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('fiduciary', 'fiduciary', 1);
insert into "REF_ORG_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('company', 'company', 2);

create table "REF_PARAM_FAMILY" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_param_family_pk primary key ("CODE")
);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('social', 'social', 1);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('fiscal', 'fiscal', 2);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('worktime', 'worktime', 3);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('leave', 'leave', 4);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('contract', 'contract', 5);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('headcount', 'headcount', 6);
insert into "REF_PARAM_FAMILY" ("CODE", "LABEL", "SORT_ORDER") values ('ccss', 'ccss', 7);

create table "REF_PAY_COMPONENT_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_pay_component_kind_pk primary key ("CODE")
);
insert into "REF_PAY_COMPONENT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('fixed', 'fixed', 1);
insert into "REF_PAY_COMPONENT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('variable', 'variable', 2);
insert into "REF_PAY_COMPONENT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('benefit_in_kind', 'benefit_in_kind', 3);
insert into "REF_PAY_COMPONENT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('premium', 'premium', 4);
insert into "REF_PAY_COMPONENT_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('expense', 'expense', 5);

create table "REF_QUALIFICATION_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_qualification_kind_pk primary key ("CODE")
);
insert into "REF_QUALIFICATION_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('qualified', 'qualified', 1);
insert into "REF_QUALIFICATION_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('unqualified', 'unqualified', 2);

create table "REF_RESIDENCY_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_residency_kind_pk primary key ("CODE")
);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('resident', 'resident', 1);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_fr', 'frontalier_fr', 2);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_be', 'frontalier_be', 3);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_de', 'frontalier_de', 4);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_fra', 'frontalier_fra', 5);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_bel', 'frontalier_bel', 6);
insert into "REF_RESIDENCY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('frontalier_deu', 'frontalier_deu', 7);

create table "REF_SCHEDULE_STATUS" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_schedule_status_pk primary key ("CODE")
);
insert into "REF_SCHEDULE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('draft', 'draft', 1);
insert into "REF_SCHEDULE_STATUS" ("CODE", "LABEL", "SORT_ORDER") values ('published', 'published', 2);

create table "REF_SEVERITY_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_severity_kind_pk primary key ("CODE")
);
insert into "REF_SEVERITY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('blocking', 'blocking', 1);
insert into "REF_SEVERITY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('warning', 'warning', 2);
insert into "REF_SEVERITY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('info', 'info', 3);
insert into "REF_SEVERITY_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('problem', 'problem', 4);

create table "REF_SEX_KIND" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_sex_kind_pk primary key ("CODE")
);
insert into "REF_SEX_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('male', 'male', 1);
insert into "REF_SEX_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('female', 'female', 2);
insert into "REF_SEX_KIND" ("CODE", "LABEL", "SORT_ORDER") values ('unspecified', 'unspecified', 3);

create table "REF_TAX_CLASS" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_tax_class_pk primary key ("CODE")
);
insert into "REF_TAX_CLASS" ("CODE", "LABEL", "SORT_ORDER") values ('1', '1', 1);
insert into "REF_TAX_CLASS" ("CODE", "LABEL", "SORT_ORDER") values ('1a', '1a', 2);
insert into "REF_TAX_CLASS" ("CODE", "LABEL", "SORT_ORDER") values ('2', '2', 3);

create table "REF_TAX_PERIODICITY" (
  "CODE" VARCHAR2(64 CHAR) not null,
  "LABEL" VARCHAR2(200 CHAR),
  "SORT_ORDER" NUMBER(5),
  "VALID_FROM" DATE default date '1900-01-01',
  "VALID_TO" DATE,
  constraint ref_tax_periodicity_pk primary key ("CODE")
);
insert into "REF_TAX_PERIODICITY" ("CODE", "LABEL", "SORT_ORDER") values ('monthly', 'monthly', 1);
insert into "REF_TAX_PERIODICITY" ("CODE", "LABEL", "SORT_ORDER") values ('daily', 'daily', 2);
insert into "REF_TAX_PERIODICITY" ("CODE", "LABEL", "SORT_ORDER") values ('annual', 'annual', 3);


create table "ABSENCE_ENTITLEMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ABSENCE_TYPE_ID" VARCHAR2(36 CHAR) not null,
  "DAYS" NUMBER(5,1),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "FREQUENCY_NOTE" VARCHAR2(4000 CHAR),
  "CAREER_CAP_DAYS" NUMBER(6,1),
  "BLOCK_DAYS" NUMBER(5,1),
  "PERIOD_MONTHS" NUMBER(10),
  "RELATIONSHIP_DEGREE" NUMBER(5),
  "REQUIRES_EVIDENCE" BOOLEAN default 0 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint absence_entitlements_pkey primary key ("ID")
);

create table "ABSENCE_TYPES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "CATEGORY" VARCHAR2(14 CHAR) not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "REQUIRES_CERTIFICATE" BOOLEAN default 0 not null,
  "IS_PAID" BOOLEAN default 1 not null,
  "COUNTS_AGAINST_LEAVE" BOOLEAN default 0 not null,
  constraint absence_types_pkey primary key ("ID"),
  constraint absence_types_code_key unique ("CODE")
);

create table "ABSENCES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "ABSENCE_TYPE_ID" VARCHAR2(36 CHAR) not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE not null,
  "DAYS_COUNT" NUMBER(5,2) default 0 not null,
  "STATUS" VARCHAR2(9 CHAR) default 'pending' not null,
  "COMMENT" VARCHAR2(4000 CHAR),
  "CERTIFICATE_RECEIVED" BOOLEAN default 0 not null,
  "CERTIFICATE_RECEIVED_AT" DATE,
  "CERTIFICATE_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "REQUESTED_BY" VARCHAR2(36 CHAR),
  "DECIDED_BY" VARCHAR2(36 CHAR),
  "DECIDED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DECISION_NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DECLARED_BY_EMPLOYEE" BOOLEAN default 0 not null,
  "CERTIFICATE_UPLOADED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "CERTIFICATE_ORIGINAL_RECEIVED" BOOLEAN default 0 not null,
  "CERTIFICATE_ORIGINAL_RECEIVED_AT" DATE,
  "CHILD_ID" VARCHAR2(36 CHAR),
  "ABSENCE_PARENTE_ID" VARCHAR2(36 CHAR),
  "PROPOSEE_PAR" VARCHAR2(4000 CHAR),
  "RANG_PROPOSITION" NUMBER(5) default 0 not null,
  constraint absences_pkey primary key ("ID")
);

create table "ADDRESS_CHECKS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ENTITY_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITY_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR),
  "COUNTRY" CHAR(3 CHAR),
  "POSTAL_CODE" VARCHAR2(4000 CHAR),
  "STATUS" VARCHAR2(4000 CHAR) not null,
  "ZONE_CODE" VARCHAR2(4000 CHAR),
  "MESSAGE" VARCHAR2(4000 CHAR),
  "CHECKED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint address_checks_pkey primary key ("ID"),
  constraint address_check_unique unique ("ENTITY_TABLE", "ENTITY_ID")
);

create table "ADDRESS_ZONES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COUNTRY" CHAR(3 CHAR) not null,
  "KIND" VARCHAR2(4000 CHAR) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "POSTAL_FROM" NUMBER(10),
  "POSTAL_TO" NUMBER(10),
  "IS_VERIFIED" BOOLEAN default 0 not null,
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint address_zones_pkey primary key ("ID"),
  constraint address_zone_unique unique ("COUNTRY", "CODE")
);

create table "ADRESSES_SALARIE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
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
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREATED_BY" VARCHAR2(36 CHAR),
  "DELETED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DELETED_BY" VARCHAR2(36 CHAR),
  constraint adresses_salarie_pkey primary key ("ID")
);

create table "APP_SECRETS" (
  "KEY" VARCHAR2(4000 CHAR) not null,
  "SECRET" VARCHAR2(4000 CHAR) not null,
  constraint app_secrets_pkey primary key ("KEY")
);

create table "APP_USERS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "USERID" VARCHAR2(4000 CHAR) not null,
  "EMAIL" VARCHAR2(4000 CHAR) not null,
  "FULL_NAME" VARCHAR2(4000 CHAR),
  "PASSWORD_HASH" VARCHAR2(4000 CHAR),
  "IS_ADMIN" BOOLEAN default 0 not null,
  "AUTH_USER_ID" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREATED_BY" VARCHAR2(36 CHAR),
  "UPDATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "UPDATED_BY" VARCHAR2(36 CHAR),
  "DELETED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DELETED_BY" VARCHAR2(36 CHAR),
  constraint app_users_pkey primary key ("ID")
);

create table "AUDIT_LOG" (
  "ID" NUMBER(19) not null,
  "OCCURRED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "ACTOR_ID" VARCHAR2(36 CHAR),
  "ACTOR_LABEL" VARCHAR2(4000 CHAR),
  "COMPANY_ID" VARCHAR2(36 CHAR),
  "ENTITY_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITY_ID" VARCHAR2(36 CHAR),
  "ACTION" VARCHAR2(4000 CHAR) not null,
  "OLD_VALUE" CLOB constraint audit_log_old_value_json check ("OLD_VALUE" is json),
  "NEW_VALUE" CLOB constraint audit_log_new_value_json check ("NEW_VALUE" is json),
  "SOURCE_IP" VARCHAR2(4000 CHAR),
  "USER_AGENT" VARCHAR2(4000 CHAR),
  "REQUEST_ID" VARCHAR2(4000 CHAR),
  constraint audit_log_pkey primary key ("ID")
);

create table "BENEFIT_TYPES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "VALUATION_METHOD" VARCHAR2(4000 CHAR) not null,
  "IS_TAXABLE" BOOLEAN default 1 not null,
  "IS_CONTRIBUTORY" BOOLEAN default 1 not null,
  "VALUATION_PARAMS" CLOB default '{}' not null constraint benefit_types_valuation_params_json check ("VALUATION_PARAMS" is json),
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint benefit_types_pkey primary key ("ID"),
  constraint benefit_types_code_key unique ("CODE")
);

create table "CBA_RULES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR) not null,
  "BLOCK" VARCHAR2(16 CHAR) not null,
  "RULES" CLOB default '{}' not null constraint cba_rules_rules_json check ("RULES" is json),
  "IS_COMPLETE" BOOLEAN default 0 not null,
  "UPDATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint cba_rules_pkey primary key ("ID"),
  constraint cba_rules_collective_agreeme unique ("COLLECTIVE_AGREEMENT_ID", "BLOCK")
);

create table "CBA_SALARY_GRIDS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR) not null,
  "CATEGORY" VARCHAR2(4000 CHAR) not null,
  "SENIORITY_FROM_YEARS" NUMBER(4,1) default 0 not null,
  "SENIORITY_TO_YEARS" NUMBER(4,1),
  "MONTHLY_AMOUNT" NUMBER(10,2) not null,
  "INDEX_REF" NUMBER(8,2),
  constraint cba_salary_grids_pkey primary key ("ID")
);

create table "CCT_REGLE_PRIME" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR) not null,
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
  "SOURCE_URL" VARCHAR2(4000 CHAR) not null,
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint cct_regle_prime_pkey primary key ("ID")
);

create table "CLIENT_SITES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "CLIENT_NAME" VARCHAR2(4000 CHAR),
  "ADDRESS_LINE" VARCHAR2(4000 CHAR),
  "POSTAL_CODE" VARCHAR2(4000 CHAR),
  "CITY" VARCHAR2(4000 CHAR),
  "COUNTRY" VARCHAR2(4000 CHAR) default 'LU' not null,
  "LATITUDE" NUMBER(9,6),
  "LONGITUDE" NUMBER(9,6),
  "IS_ACTIVE" BOOLEAN default 1 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint client_sites_pkey primary key ("ID")
);

create table "COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR),
  "CODE" VARCHAR2(4000 CHAR) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "SECTOR" VARCHAR2(4000 CHAR) not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "IS_ACTIVE" BOOLEAN default 0 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SCOPE" VARCHAR2(17 CHAR) default 'sector' not null,
  "SUPERSEDES_ID" VARCHAR2(36 CHAR),
  "EMPLOYEE_CATEGORY" VARCHAR2(4000 CHAR),
  constraint collective_agreements_pkey primary key ("ID")
);

create table "COMPANIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR) not null,
  "LEGAL_NAME" VARCHAR2(4000 CHAR) not null,
  "LEGAL_FORM" VARCHAR2(4000 CHAR),
  "RCS_NUMBER" VARCHAR2(4000 CHAR),
  "CCSS_MATRICULE" VARCHAR2(4000 CHAR),
  "ADDRESS_LINE" VARCHAR2(4000 CHAR),
  "POSTAL_CODE" VARCHAR2(4000 CHAR),
  "CITY" VARCHAR2(4000 CHAR),
  "COUNTRY" VARCHAR2(4000 CHAR) default 'LU' not null,
  "NACE_CODE" VARCHAR2(4000 CHAR),
  "SECTOR" VARCHAR2(4000 CHAR),
  "REFERENCE_PERIOD_MONTHS" NUMBER(5) default 4 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "INTERNAL_RULES_ADOPTED_ON" DATE,
  "INTERNAL_RULES_REFERENCE" VARCHAR2(4000 CHAR),
  constraint companies_pkey primary key ("ID")
);

create table "COMPANY_ACCIDENT_CLAIMS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "YEAR" NUMBER(5) not null,
  "CLAIM_COUNT" NUMBER(10) default 0 not null,
  "DAYS_LOST" NUMBER(10) default 0 not null,
  "COST" NUMBER(12,2),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint company_accident_claims_pkey primary key ("ID"),
  constraint company_accident_claims_comp unique ("COMPANY_ID", "YEAR")
);

create table "COMPANY_COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR) not null,
  "DEPARTMENT_ID" VARCHAR2(36 CHAR),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_collective_agreement primary key ("ID")
);

create table "COMPANY_FINANCIALS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "FISCAL_YEAR" NUMBER(5) not null,
  "PROFIT" NUMBER(14,2),
  "REVENUE" NUMBER(14,2),
  "SOURCE" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_financials_pkey primary key ("ID"),
  constraint company_financials_company_i unique ("COMPANY_ID", "FISCAL_YEAR")
);

create table "COMPANY_RATE_PERIODS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "ACTIVITY_CLASS" VARCHAR2(4000 CHAR),
  "ACCIDENT_RISK_CLASS" VARCHAR2(4000 CHAR),
  "ACCIDENT_FACTOR" NUMBER(5,2) default 1.00 not null,
  "MUTUALITY_CLASS" NUMBER(5),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'CCSS' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_rate_periods_pkey primary key ("ID")
);

create table "COMPLIANCE_ALERTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR),
  "RULE_CODE" VARCHAR2(4000 CHAR) not null,
  "TITLE" VARCHAR2(4000 CHAR) not null,
  "DETAIL" VARCHAR2(4000 CHAR) not null,
  "CONSEQUENCE" VARCHAR2(4000 CHAR),
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "SEVERITY" VARCHAR2(8 CHAR) not null,
  "DUE_DATE" DATE,
  "STATE" VARCHAR2(9 CHAR) default 'open' not null,
  "HANDLED_BY" VARCHAR2(36 CHAR),
  "HANDLED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "HANDLED_NOTE" VARCHAR2(4000 CHAR),
  "FIRST_SEEN_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint compliance_alerts_pkey primary key ("ID")
);

create table "CONTRACT_AMENDMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EFFECTIVE_DATE" DATE not null,
  "REASON" VARCHAR2(4000 CHAR) not null,
  "CHANGES" CLOB not null constraint contract_amendments_changes_json check ("CHANGES" is json),
  "CREATED_BY" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint contract_amendments_pkey primary key ("ID")
);

create table "CONTRACT_COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR) not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint contract_collective_agreemen primary key ("ID")
);

create table "CONTRACT_PAY_COMPONENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "KIND" VARCHAR2(15 CHAR) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "AMOUNT" NUMBER(10,2),
  "RATE_PCT" NUMBER(6,3),
  "BASIS" VARCHAR2(4000 CHAR),
  "PERIODICITY" VARCHAR2(4000 CHAR) default 'monthly' not null,
  "IN_SALARY_REFERENCE" BOOLEAN default 0 not null,
  "IS_TAXABLE" BOOLEAN default 1 not null,
  "IS_CONTRIBUTORY" BOOLEAN default 1 not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "BENEFIT_TYPE_ID" VARCHAR2(36 CHAR),
  constraint contract_pay_components_pkey primary key ("ID")
);

create table "CONTRACT_TERMINATIONS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "REASON" VARCHAR2(4000 CHAR) not null,
  "IS_PERSONAL_GROUND" BOOLEAN default 1 not null,
  "NOTIFIED_ON" DATE not null,
  "NOTICE_START" DATE,
  "NOTICE_END" DATE,
  "SEVERANCE_MONTHS" NUMBER(4,1),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "NOTICE_WAIVED" BOOLEAN default 0 not null,
  "WAIVER_AGREED_ON" DATE,
  "WAIVER_COMPENSATION" NUMBER(12,2),
  "WAIVER_NOTE" VARCHAR2(4000 CHAR),
  "IS_GROSS_MISCONDUCT" BOOLEAN default 0 not null,
  constraint contract_terminations_pkey primary key ("ID")
);

create table "CONTRACTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "KIND" VARCHAR2(14 CHAR) not null,
  "STATUS" VARCHAR2(9 CHAR) default 'draft' not null,
  "JOB_TITLE" VARCHAR2(4000 CHAR) not null,
  "JOB_DESCRIPTION" VARCHAR2(4000 CHAR),
  "WORK_PLACE" VARCHAR2(4000 CHAR),
  "CATEGORY" VARCHAR2(4000 CHAR),
  "START_DATE" DATE not null,
  "END_DATE" DATE,
  "CDD_REASON" VARCHAR2(4000 CHAR),
  "RENEWAL_COUNT" NUMBER(5) default 0 not null,
  "PREVIOUS_CONTRACT_ID" VARCHAR2(36 CHAR),
  "MONTHLY_GROSS" NUMBER(10,2) not null,
  "INDEX_REF" NUMBER(8,2),
  "WEEKLY_HOURS" NUMBER(5,2) default 40 not null,
  "DAYS_PER_WEEK" NUMBER(3,1) default 5 not null,
  "WORK_DISTRIBUTION" VARCHAR2(4000 CHAR),
  "REFERENCE_PERIOD_MONTHS" NUMBER(5) default 4 not null,
  "NIGHT_WORK" BOOLEAN default 0 not null,
  "ANNUAL_LEAVE_DAYS" NUMBER(5,2),
  "BREAK_MINUTES" NUMBER(5),
  "NON_COMPETE_CLAUSE" BOOLEAN default 0 not null,
  "EXCLUSIVITY_CLAUSE" BOOLEAN default 0 not null,
  "PROBATION_LENGTH" NUMBER(10),
  "PROBATION_UNIT" VARCHAR2(4000 CHAR),
  "VERSION" NUMBER(5) default 1 not null,
  "SIGNED_AT" DATE,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "IS_PART_TIME" BOOLEAN default 0 not null,
  "APPRENTICESHIP_LEVEL" VARCHAR2(4000 CHAR),
  "APPRENTICESHIP_YEAR" NUMBER(5),
  "SEASON_LABEL" VARCHAR2(4000 CHAR),
  "INTERIM_AGENCY_ID" VARCHAR2(36 CHAR),
  "USER_COMPANY_NAME" VARCHAR2(4000 CHAR),
  "MISSION_REASON" VARCHAR2(4000 CHAR),
  constraint contracts_pkey primary key ("ID")
);

create table "CRENEAU_CONDITION" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "SHIFT_ID" VARCHAR2(36 CHAR),
  "TIME_ENTRY_ID" VARCHAR2(36 CHAR),
  "CLIENT_SITE_ID" VARCHAR2(36 CHAR),
  "CONDITION_CODE" VARCHAR2(4000 CHAR) not null,
  "DATE_PRESTATION" DATE not null,
  "HEURE_DEBUT" INTERVAL DAY(0) TO SECOND(0) not null,
  "HEURE_FIN" INTERVAL DAY(0) TO SECOND(0) not null,
  "MINUTES" NUMBER(10),
  "CONSTATE_PAR" VARCHAR2(36 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DELETED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DELETED_BY" VARCHAR2(36 CHAR),
  constraint creneau_condition_pkey primary key ("ID")
);

create table "DATA_ACCESS_LOG" (
  "ID" NUMBER(19) not null,
  "OCCURRED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "ACTOR_ID" VARCHAR2(36 CHAR),
  "ACTOR_LABEL" VARCHAR2(4000 CHAR),
  "COMPANY_ID" VARCHAR2(36 CHAR),
  "SUBJECT_EMPLOYEE_ID" VARCHAR2(36 CHAR),
  "ENTITY_TABLE" VARCHAR2(4000 CHAR) not null,
  "ENTITY_ID" VARCHAR2(36 CHAR),
  "ACTION" VARCHAR2(4000 CHAR) not null,
  "SCOPE" VARCHAR2(4000 CHAR),
  "ROW_COUNT" NUMBER(10),
  "SOURCE_IP" VARCHAR2(4000 CHAR),
  "USER_AGENT" VARCHAR2(4000 CHAR),
  "REQUEST_ID" VARCHAR2(4000 CHAR),
  "IS_AUTONOMOUS" BOOLEAN default 0 not null,
  constraint data_access_log_pkey primary key ("ID")
);

create table "DEPARTMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "MIN_EVENING_COVERAGE" NUMBER(5),
  constraint departments_pkey primary key ("ID")
);

create table "DOCUMENT_TYPES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "STAGE" VARCHAR2(15 CHAR) default 'during_contract' not null,
  "VALIDITY_MONTHS" NUMBER(10),
  "IS_MANDATORY" BOOLEAN default 0 not null,
  "APPLIES_TO_RESIDENCY" CLOB,
  "ALERT_DAYS_BEFORE" NUMBER(10) default 30 not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint document_types_pkey primary key ("ID"),
  constraint document_types_code_key unique ("CODE")
);

create table "DOCUMENTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR),
  "ENTITY_TABLE" VARCHAR2(4000 CHAR),
  "ENTITY_ID" VARCHAR2(36 CHAR),
  "NAME" VARCHAR2(4000 CHAR) not null,
  "STORAGE_PATH" VARCHAR2(4000 CHAR) not null,
  "MIME_TYPE" VARCHAR2(4000 CHAR),
  "SIZE_BYTES" NUMBER(19),
  "RETENTION_UNTIL" DATE,
  "IS_SENSITIVE" BOOLEAN default 0 not null,
  "UPLOADED_BY" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DOCUMENT_TYPE_ID" VARCHAR2(36 CHAR),
  "ISSUED_ON" DATE,
  "EXPIRES_ON" DATE,
  "DELIVERED_AT" DATE,
  constraint documents_pkey primary key ("ID")
);

create table "EMPLOYEE_CHILDREN" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "FIRST_NAME" VARCHAR2(4000 CHAR),
  "LAST_NAME" VARCHAR2(4000 CHAR),
  "SEX" VARCHAR2(11 CHAR),
  "BIRTH_DATE" DATE not null,
  "RELATIONSHIP" VARCHAR2(4000 CHAR) default 'child' not null,
  "IS_DEPENDENT" BOOLEAN default 1 not null,
  "PRIVACY_OPT_OUT" BOOLEAN default 0 not null,
  "ADOPTION_DATE" DATE,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "REFUS_PHOTOS_EVENEMENTS" BOOLEAN default 0 not null,
  "INVITATION_EVENEMENTS" BOOLEAN default 0 not null,
  "EN_SITUATION_HANDICAP" BOOLEAN default 0 not null,
  "TAUX_HANDICAP_PCT" NUMBER(5,2),
  constraint employee_children_pkey primary key ("ID")
);

create table "EMPLOYEE_DISABILITIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "RATE_PCT" NUMBER(5,2) not null,
  "RECOGNIZED_ON" DATE,
  "AUTHORITY" VARCHAR2(4000 CHAR),
  "EXTRA_LEAVE_DAYS_OVERRIDE" NUMBER(4,1),
  "EVIDENCE_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint employee_disabilities_pkey primary key ("ID")
);

create table "EMPLOYEE_SANCTIONS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR),
  "SANCTION_TYPE" VARCHAR2(4000 CHAR) not null,
  "FACTS_ON" DATE not null,
  "FACTS_KNOWN_ON" DATE not null,
  "NOTIFIED_ON" DATE,
  "EFFECTIVE_FROM" DATE,
  "EFFECTIVE_TO" DATE,
  "REASON" VARCHAR2(4000 CHAR) not null,
  "EVIDENCE_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "TERMINATION_ID" VARCHAR2(36 CHAR),
  "AMENDMENT_CONTRACT_ID" VARCHAR2(36 CHAR),
  "EMPLOYEE_HEARD_ON" DATE,
  "EMPLOYEE_RESPONSE" VARCHAR2(4000 CHAR),
  "CONTESTED_ON" DATE,
  "CONTEST_OUTCOME" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "RETENTION_UNTIL" DATE,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CREATED_BY" VARCHAR2(36 CHAR),
  "UPDATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "UPDATED_BY" VARCHAR2(36 CHAR),
  "DELETED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DELETED_BY" VARCHAR2(36 CHAR),
  constraint employee_sanctions_pkey primary key ("ID")
);

create table "EMPLOYEE_STATUSES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "KIND" VARCHAR2(18 CHAR) not null,
  "DECLARED_ON" DATE default CURRENT_DATE not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE,
  "EXPECTED_BIRTH_DATE" DATE,
  "ACTUAL_BIRTH_DATE" DATE,
  "EVIDENCE_DOCUMENT_ID" VARCHAR2(36 CHAR),
  "HOURS_CREDIT_MONTHLY" NUMBER(5,1),
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint employee_statuses_pkey primary key ("ID")
);

create table "EMPLOYEE_TAX_CARDS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "TAX_CLASS" VARCHAR2(8 CHAR) not null,
  "RATE" NUMBER(6,4),
  "MONTHLY_ALLOWANCE" NUMBER(10,2) default 0 not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "CREDITS" CLOB default '[]' not null constraint employee_tax_cards_credits_json check ("CREDITS" is json),
  "COMMUTE_DISTANCE_KM" NUMBER(6,1),
  "PROFESSIONAL_EXPENSES_MONTHLY" NUMBER(10,2),
  "OTHER_DEDUCTIONS_MONTHLY" NUMBER(10,2) default 0 not null,
  "CARD_REFERENCE" VARCHAR2(4000 CHAR),
  "ISSUED_ON" DATE,
  constraint employee_tax_cards_pkey primary key ("ID")
);

create table "EMPLOYEES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "USER_ID" VARCHAR2(36 CHAR),
  "DEPARTMENT_ID" VARCHAR2(36 CHAR),
  "FIRST_NAME" VARCHAR2(4000 CHAR) not null,
  "LAST_NAME" VARCHAR2(4000 CHAR) not null,
  "BIRTH_DATE" DATE,
  "RESIDENCY" VARCHAR2(14 CHAR) not null,
  "QUALIFICATION" VARCHAR2(11 CHAR) default 'unqualified' not null,
  "ADDRESS_LINE" VARCHAR2(4000 CHAR),
  "POSTAL_CODE" VARCHAR2(4000 CHAR),
  "CITY" VARCHAR2(4000 CHAR),
  "COUNTRY" VARCHAR2(4000 CHAR) default 'LU' not null,
  "EMAIL" VARCHAR2(4000 CHAR),
  "PHONE" VARCHAR2(4000 CHAR),
  "NATIONAL_ID_ENC" BLOB,
  "IBAN_ENC" BLOB,
  "NATIONAL_ID_HINT" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SEX" VARCHAR2(11 CHAR) default 'unspecified' not null,
  "CAREER_START_DATE" DATE,
  "PROFESSION" VARCHAR2(4000 CHAR),
  "IS_MANAGEMENT" BOOLEAN default 0 not null,
  "SEXE_LEGAL" VARCHAR2(11 CHAR),
  "REFUS_PHOTOS_SOCIETE" BOOLEAN default 0 not null,
  "SOUHAITE_CONFIDENTIALITE" BOOLEAN default 0 not null,
  constraint employees_pkey primary key ("ID"),
  constraint employees_id_company_uk unique ("ID", "COMPANY_ID")
);

create table "EXPECTED_PARAMETERS" (
  "PARAM_KEY" VARCHAR2(4000 CHAR) not null,
  "READ_BY" VARCHAR2(4000 CHAR) not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint expected_parameters_pkey primary key ("PARAM_KEY")
);

create table "EXPORT_LOG" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR) not null,
  "REQUESTED_BY" VARCHAR2(36 CHAR),
  "SUBJECT_KIND" VARCHAR2(4000 CHAR) not null,
  "SUBJECT_ID" VARCHAR2(36 CHAR),
  "ROW_COUNT" NUMBER(10) default 0 not null,
  "BYTE_SIZE" NUMBER(10) default 0 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SOURCE_IP" VARCHAR2(4000 CHAR),
  "USER_AGENT" VARCHAR2(4000 CHAR),
  "REQUEST_ID" VARCHAR2(4000 CHAR),
  constraint export_log_pkey primary key ("ID")
);

create table "FICHE_SANTE" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR),
  "ENFANT_ID" VARCHAR2(36 CHAR),
  "ALLERGIES" VARCHAR2(4000 CHAR),
  "PATHOLOGIES" VARCHAR2(4000 CHAR),
  "MEDECIN_TRAITANT" VARCHAR2(4000 CHAR),
  "MEDECIN_TELEPHONE" VARCHAR2(4000 CHAR),
  "GROUPE_SANGUIN" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "MAJ_LE" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "MAJ_PAR" VARCHAR2(36 CHAR),
  "DELETED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DELETED_BY" VARCHAR2(36 CHAR),
  constraint fiche_sante_pkey primary key ("ID"),
  constraint fs_une_par_personne unique ("EMPLOYEE_ID", "ENFANT_ID")
);

create table "HEADCOUNT_SNAPSHOTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "MONTH" DATE not null,
  "HEADCOUNT" NUMBER(8,2) not null,
  constraint headcount_snapshots_pkey primary key ("ID"),
  constraint headcount_snapshots_company_ unique ("COMPANY_ID", "MONTH")
);

create table "INTERIM_AGENCIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "CCSS_MATRICULE" VARCHAR2(4000 CHAR),
  "RCS_NUMBER" VARCHAR2(4000 CHAR),
  "ADDRESS_LINE" VARCHAR2(4000 CHAR),
  "POSTAL_CODE" VARCHAR2(4000 CHAR),
  "CITY" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint interim_agencies_pkey primary key ("ID")
);

create table "LEGAL_PARAMETERS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "FAMILY" VARCHAR2(9 CHAR) not null,
  "PARAM_KEY" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "VALUE_NUM" NUMBER,
  "VALUE_TEXT" VARCHAR2(4000 CHAR),
  "VALUE_JSON" CLOB constraint legal_parameters_value_json_json check ("VALUE_JSON" is json),
  "UNIT" VARCHAR2(4000 CHAR),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "INDEX_REF" NUMBER(8,2),
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "ENTERED_BY" VARCHAR2(36 CHAR),
  "ENTERED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "VALIDATED_BY" VARCHAR2(36 CHAR),
  "VALIDATED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DERIVED_FROM_KEY" VARCHAR2(4000 CHAR),
  "DERIVED_FACTOR" NUMBER,
  "DERIVATION_TOLERANCE" NUMBER default 0.02 not null,
  constraint legal_parameters_pkey primary key ("ID")
);

create table "MEAL_VOUCHER_GRANTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "PERIOD_START" DATE not null,
  "PERIOD_END" DATE not null,
  "VOUCHER_COUNT" NUMBER(10) not null,
  "FACE_VALUE" NUMBER(6,2) not null,
  "EMPLOYEE_SHARE" NUMBER(6,2) default 0 not null,
  "GRANTED_ON" DATE,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint meal_voucher_grants_pkey primary key ("ID")
);

create table "ORGANIZATIONS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "KIND" VARCHAR2(9 CHAR) default 'fiduciary' not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint organizations_pkey primary key ("ID")
);

create table "OVERTIME_REQUESTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "SCHEDULE_ID" VARCHAR2(36 CHAR),
  "PERIOD_START" DATE not null,
  "PERIOD_END" DATE not null,
  "HOURS" NUMBER(6,2) not null,
  "REASON" VARCHAR2(4000 CHAR) not null,
  "STATUS" VARCHAR2(4000 CHAR) default 'requested' not null,
  "REQUESTED_BY" VARCHAR2(36 CHAR),
  "REQUESTED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "HR_VALIDATED_BY" VARCHAR2(36 CHAR),
  "HR_VALIDATED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "EMPLOYEE_ACCEPTED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "REJECTED_REASON" VARCHAR2(4000 CHAR),
  "COMPENSATION" VARCHAR2(4000 CHAR) default 'money' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  constraint overtime_requests_pkey primary key ("ID")
);

create table "PERSONNE_INDICATEUR_SECOURS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR),
  "ENFANT_ID" VARCHAR2(36 CHAR),
  "INDICATEUR" VARCHAR2(4000 CHAR) not null,
  "PRECISION_LIEU" VARCHAR2(4000 CHAR),
  "DEBUT_VALIDITE" DATE default '1970-01-01' not null,
  "FIN_VALIDITE" DATE default '2037-12-31' not null,
  "POSE_PAR" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint personne_indicateur_secours_ primary key ("ID"),
  constraint pis_unique unique ("EMPLOYEE_ID", "ENFANT_ID", "INDICATEUR", "DEBUT_VALIDITE")
);

create table "PREMIUMS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR),
  "TERMINATION_ID" VARCHAR2(36 CHAR),
  "KIND" VARCHAR2(4000 CHAR) default 'other' not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "AMOUNT" NUMBER(12,2) not null,
  "GRANTED_ON" DATE not null,
  "FISCAL_YEAR" NUMBER(5) not null,
  "IS_TAXABLE" BOOLEAN default 1 not null,
  "IS_CONTRIBUTORY" BOOLEAN default 1 not null,
  "EXEMPT_PCT" NUMBER(6,3) default 0 not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint premiums_pkey primary key ("ID")
);

create table "PROBATION_EXTENSIONS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36 CHAR) not null,
  "FROM_DATE" DATE not null,
  "TO_DATE" DATE not null,
  "DAYS_ADDED" NUMBER(10) not null,
  "REASON" VARCHAR2(4000 CHAR) default 'incapacité de travail' not null,
  constraint probation_extensions_pkey primary key ("ID")
);

create table "PROFILES" (
  "ID" VARCHAR2(36 CHAR) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR) not null,
  "FULL_NAME" VARCHAR2(4000 CHAR) default '' not null,
  "EMAIL" VARCHAR2(4000 CHAR) default '' not null,
  "IS_ORG_ADMIN" BOOLEAN default 0 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint profiles_pkey primary key ("ID")
);

create table "PUBLIC_HOLIDAYS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "YEAR" NUMBER(5) not null,
  "HOLIDAY_DATE" DATE not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "IS_MOBILE" BOOLEAN default 0 not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36 CHAR),
  "IS_RECOVERABLE" BOOLEAN default 0 not null,
  "RECOVERY_REASON" VARCHAR2(4000 CHAR),
  constraint public_holidays_pkey primary key ("ID")
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
  "SOURCE_URL" VARCHAR2(4000 CHAR),
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

create table "REFERENCE_PERIODS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "DEPARTMENT_ID" VARCHAR2(36 CHAR),
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE not null,
  "MONTHS" NUMBER(5) not null,
  constraint reference_periods_pkey primary key ("ID")
);

create table "SANCTION_CATEGORIES" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "RANK" NUMBER(5) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR) not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  constraint sanction_categories_pkey primary key ("CODE")
);

create table "SANCTION_TYPES" (
  "CODE" VARCHAR2(4000 CHAR) not null,
  "CATEGORY_CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "DESCRIPTION" VARCHAR2(4000 CHAR) not null,
  "AFFECTS_PRESENCE" BOOLEAN default 0 not null,
  "AFFECTS_PAY" BOOLEAN default 0 not null,
  "REQUIRES_INTERNAL_RULES" BOOLEAN default 0 not null,
  "IS_CONTRACT_CHANGE" BOOLEAN default 0 not null,
  "ENDS_CONTRACT" BOOLEAN default 0 not null,
  "NEEDS_NOTICE" BOOLEAN,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  constraint sanction_types_pkey primary key ("CODE")
);

create table "SCHEDULES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "DEPARTMENT_ID" VARCHAR2(36 CHAR),
  "WEEK_START" DATE not null,
  "LABEL" VARCHAR2(4000 CHAR),
  "STATUS" VARCHAR2(9 CHAR) default 'draft' not null,
  "PUBLISHED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "PUBLISHED_BY" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint schedules_pkey primary key ("ID"),
  constraint schedules_company_id_departm unique ("COMPANY_ID", "DEPARTMENT_ID", "WEEK_START"),
  constraint schedules_id_company_uk unique ("ID", "COMPANY_ID")
);

create table "SHIFT_TEMPLATES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "NAME" VARCHAR2(4000 CHAR) not null,
  "START_TIME" INTERVAL DAY(0) TO SECOND(0) not null,
  "END_TIME" INTERVAL DAY(0) TO SECOND(0) not null,
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "COLOR" VARCHAR2(4000 CHAR) default '#017E84' not null,
  "DEPARTMENT_ID" VARCHAR2(36 CHAR),
  constraint shift_templates_pkey primary key ("ID")
);

create table "SHIFTS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SCHEDULE_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "SHIFT_DATE" DATE not null,
  "START_TIME" INTERVAL DAY(0) TO SECOND(0) not null,
  "END_TIME" INTERVAL DAY(0) TO SECOND(0) not null,
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "LABEL" VARCHAR2(4000 CHAR),
  "TEMPLATE_ID" VARCHAR2(36 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "CLIENT_SITE_ID" VARCHAR2(36 CHAR),
  constraint shifts_pkey primary key ("ID")
);

create table "TAX_BRACKETS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "TAX_CLASS" VARCHAR2(8 CHAR) not null,
  "PERIODICITY" VARCHAR2(8 CHAR) default 'monthly' not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "BRACKET_MIN" NUMBER(12,2) not null,
  "BRACKET_MAX" NUMBER(12,2),
  "BASE_TAX" NUMBER(12,2) default 0 not null,
  "RATE_OVER_MIN" NUMBER(7,4) not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'ACD' not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint tax_brackets_pkey primary key ("ID")
);

create table "TAX_CREDITS" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000 CHAR) not null,
  "LABEL" VARCHAR2(4000 CHAR) not null,
  "APPLIES_TO_CLASSES" CLOB,
  "INCOME_MIN" NUMBER(12,2),
  "INCOME_MAX" NUMBER(12,2),
  "MONTHLY_AMOUNT" NUMBER(10,2),
  "PRORATED_ON_HOURS" BOOLEAN default 0 not null,
  "VALID_FROM" DATE default '1970-01-01' not null,
  "VALID_TO" DATE default '2037-12-31' not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'ACD' not null,
  "LEGAL_REF" VARCHAR2(4000 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint tax_credits_pkey primary key ("ID")
);

create table "TIME_ENTRIES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR) not null,
  "EMPLOYEE_ID" VARCHAR2(36 CHAR) not null,
  "ENTRY_DATE" DATE not null,
  "START_TIME" INTERVAL DAY(0) TO SECOND(0),
  "END_TIME" INTERVAL DAY(0) TO SECOND(0),
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "WORKED_HOURS" NUMBER(5,2),
  "PLANNED_HOURS" NUMBER(5,2),
  "SUNDAY_HOURS" NUMBER(5,2) default 0 not null,
  "HOLIDAY_HOURS" NUMBER(5,2) default 0 not null,
  "NIGHT_HOURS" NUMBER(5,2) default 0 not null,
  "OVERTIME_HOURS" NUMBER(5,2) default 0 not null,
  "IS_VALIDATED" BOOLEAN default 0 not null,
  "SOURCE" VARCHAR2(4000 CHAR) default 'manual' not null,
  "NOTE" VARCHAR2(4000 CHAR),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint time_entries_pkey primary key ("ID"),
  constraint time_entries_employee_id_ent unique ("EMPLOYEE_ID", "ENTRY_DATE")
);

create table "TRAVEL_DISTANCES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORIGIN_REF" VARCHAR2(4000 CHAR) not null,
  "DESTINATION_REF" VARCHAR2(4000 CHAR) not null,
  "DISTANCE_KM" NUMBER(8,2) not null,
  "DURATION_MINUTES" NUMBER(10),
  "SOURCE" VARCHAR2(4000 CHAR) not null,
  "COMPUTED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "COMPUTED_BY" VARCHAR2(36 CHAR),
  "NOTE" VARCHAR2(4000 CHAR),
  constraint travel_distances_pkey primary key ("ID"),
  constraint travel_distance_unique unique ("ORIGIN_REF", "DESTINATION_REF")
);

create table "USER_ROLES" (
  "ID" VARCHAR2(36 CHAR) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "USER_ID" VARCHAR2(36 CHAR) not null,
  "ORGANIZATION_ID" VARCHAR2(36 CHAR) not null,
  "COMPANY_ID" VARCHAR2(36 CHAR),
  "ROLE" VARCHAR2(16 CHAR) not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint user_roles_pkey primary key ("ID"),
  constraint user_roles_user_id_company_i unique ("USER_ID", "COMPANY_ID", "ROLE")
);

-- Clés étrangères, posées après toutes les tables.
alter table "ABSENCE_TYPES" add constraint absence_types_category_ref foreign key ("CATEGORY") references "REF_ABSENCE_CATEGORY" ("CODE");
alter table "ABSENCES" add constraint absences_status_ref foreign key ("STATUS") references "REF_ABSENCE_STATUS" ("CODE");
alter table "CBA_RULES" add constraint cba_rules_block_ref foreign key ("BLOCK") references "REF_CBA_BLOCK" ("CODE");
alter table "COLLECTIVE_AGREEMENTS" add constraint collective_agreeme_scope_ref foreign key ("SCOPE") references "REF_CBA_SCOPE" ("CODE");
alter table "COMPLIANCE_ALERTS" add constraint compliance_alerts_severity_r foreign key ("SEVERITY") references "REF_SEVERITY_KIND" ("CODE");
alter table "COMPLIANCE_ALERTS" add constraint compliance_alerts_state_ref foreign key ("STATE") references "REF_ALERT_STATE" ("CODE");
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_compo_kind_ref foreign key ("KIND") references "REF_PAY_COMPONENT_KIND" ("CODE");
alter table "CONTRACTS" add constraint contracts_kind_ref foreign key ("KIND") references "REF_CONTRACT_KIND" ("CODE");
alter table "CONTRACTS" add constraint contracts_status_ref foreign key ("STATUS") references "REF_CONTRACT_STATUS" ("CODE");
alter table "DOCUMENT_TYPES" add constraint document_types_stage_ref foreign key ("STAGE") references "REF_DOCUMENT_STAGE" ("CODE");
alter table "EMPLOYEE_CHILDREN" add constraint employee_children_sex_ref foreign key ("SEX") references "REF_SEX_KIND" ("CODE");
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_kind_ref foreign key ("KIND") references "REF_EMPLOYEE_STATUS_KIND" ("CODE");
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_tax_class foreign key ("TAX_CLASS") references "REF_TAX_CLASS" ("CODE");
alter table "EMPLOYEES" add constraint employees_residency_ref foreign key ("RESIDENCY") references "REF_RESIDENCY_KIND" ("CODE");
alter table "EMPLOYEES" add constraint employees_qualification_ref foreign key ("QUALIFICATION") references "REF_QUALIFICATION_KIND" ("CODE");
alter table "EMPLOYEES" add constraint employees_sex_ref foreign key ("SEX") references "REF_SEX_KIND" ("CODE");
alter table "EMPLOYEES" add constraint employees_sexe_legal_ref foreign key ("SEXE_LEGAL") references "REF_SEX_KIND" ("CODE");
alter table "LEGAL_PARAMETERS" add constraint legal_parameters_family_ref foreign key ("FAMILY") references "REF_PARAM_FAMILY" ("CODE");
alter table "ORGANIZATIONS" add constraint organizations_kind_ref foreign key ("KIND") references "REF_ORG_KIND" ("CODE");
alter table "SCHEDULES" add constraint schedules_status_ref foreign key ("STATUS") references "REF_SCHEDULE_STATUS" ("CODE");
alter table "TAX_BRACKETS" add constraint tax_brackets_tax_class_ref foreign key ("TAX_CLASS") references "REF_TAX_CLASS" ("CODE");
alter table "TAX_BRACKETS" add constraint tax_brackets_periodicity_ref foreign key ("PERIODICITY") references "REF_TAX_PERIODICITY" ("CODE");
alter table "USER_ROLES" add constraint user_roles_role_ref foreign key ("ROLE") references "REF_APP_ROLE" ("CODE");

alter table "ABSENCE_ENTITLEMENTS" add constraint absence_entitlements_absence foreign key ("ABSENCE_TYPE_ID") references "ABSENCE_TYPES" ("ID") on delete cascade;
alter table "ABSENCES" add constraint absence_belongs_to_employees foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "ABSENCES" add constraint absences_absence_parente_id_ foreign key ("ABSENCE_PARENTE_ID") references "ABSENCES" ("ID") on delete set null;
alter table "ABSENCES" add constraint absences_absence_type_id_fke foreign key ("ABSENCE_TYPE_ID") references "ABSENCE_TYPES" ("ID");
alter table "ABSENCES" add constraint absences_child_id_fkey foreign key ("CHILD_ID") references "EMPLOYEE_CHILDREN" ("ID") on delete set null;
alter table "ABSENCES" add constraint absences_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "ABSENCES" add constraint absences_decided_by_fkey foreign key ("DECIDED_BY") references "APP_USERS" ("ID");
alter table "ABSENCES" add constraint absences_requested_by_fkey foreign key ("REQUESTED_BY") references "APP_USERS" ("ID");
alter table "ADDRESS_CHECKS" add constraint address_checks_statut_ref foreign key ("STATUS") references "REF_STATUT_VERIFICATION_ADRESSE" ("CODE");
alter table "ADRESSES_SALARIE" add constraint adr_appartient_au_salarie foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "ADRESSES_SALARIE" add constraint adresses_salarie_type_adress foreign key ("TYPE_ADRESSE") references "REF_TYPE_ADRESSE" ("CODE");
alter table "CBA_RULES" add constraint cba_rules_collective_agreeme foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete cascade;
alter table "CBA_SALARY_GRIDS" add constraint cba_salary_grids_collective_ foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete cascade;
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_collective_a foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete cascade;
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_condition_co foreign key ("CONDITION_CODE") references "REF_CONDITION_TRAVAIL" ("CODE");
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_nature_prime foreign key ("NATURE_PRIME") references "REF_NATURE_PRIME" ("CODE");
alter table "CCT_REGLE_PRIME" add constraint cct_regle_prime_unite_ref foreign key ("UNITE") references "REF_UNITE_PRIME" ("CODE");
alter table "CLIENT_SITES" add constraint client_sites_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COLLECTIVE_AGREEMENTS" add constraint collective_agreements_organi foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "COLLECTIVE_AGREEMENTS" add constraint collective_agreements_supers foreign key ("SUPERSEDES_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete set null;
alter table "COMPANIES" add constraint companies_organization_id_fk foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "COMPANY_ACCIDENT_CLAIMS" add constraint company_accident_claims_comp foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_collective_agreement foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID");
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_collective_agreement foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_collective_agreement foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete cascade;
alter table "COMPANY_FINANCIALS" add constraint company_financials_company_i foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COMPANY_RATE_PERIODS" add constraint company_rate_periods_company foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COMPLIANCE_ALERTS" add constraint compliance_alerts_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "COMPLIANCE_ALERTS" add constraint compliance_alerts_employee_i foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete set null;
alter table "COMPLIANCE_ALERTS" add constraint compliance_alerts_handled_by foreign key ("HANDLED_BY") references "APP_USERS" ("ID");
alter table "CONTRACT_AMENDMENTS" add constraint contract_amendments_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_AMENDMENTS" add constraint contract_amendments_contract foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_AMENDMENTS" add constraint contract_amendments_created_ foreign key ("CREATED_BY") references "APP_USERS" ("ID");
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_collective_agreemen foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID");
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_collective_agreemen foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_bene foreign key ("BENEFIT_TYPE_ID") references "BENEFIT_TYPES" ("ID") on delete set null;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_comp foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_cont foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_TERMINATIONS" add constraint contract_terminations_compan foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_TERMINATIONS" add constraint contract_terminations_contra foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACTS" add constraint contract_belongs_to_employee foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "CONTRACTS" add constraint contracts_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACTS" add constraint contracts_interim_agency_fk foreign key ("INTERIM_AGENCY_ID") references "INTERIM_AGENCIES" ("ID") on delete set null;
alter table "CONTRACTS" add constraint contracts_previous_contract_ foreign key ("PREVIOUS_CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "CONTRACTS" add constraint contracts_unite_essai_ref foreign key ("PROBATION_UNIT") references "REF_UNITE_ESSAI" ("CODE");
alter table "CRENEAU_CONDITION" add constraint cc_appartient_au_salarie foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "CRENEAU_CONDITION" add constraint cc_site_appartient_a_la_soci foreign key ("CLIENT_SITE_ID", "COMPANY_ID") references "CLIENT_SITES" ("ID", "COMPANY_ID") on delete set null;
alter table "CRENEAU_CONDITION" add constraint creneau_condition_condition_ foreign key ("CONDITION_CODE") references "REF_CONDITION_TRAVAIL" ("CODE");
alter table "CRENEAU_CONDITION" add constraint creneau_condition_shift_id_f foreign key ("SHIFT_ID") references "SHIFTS" ("ID") on delete cascade;
alter table "CRENEAU_CONDITION" add constraint creneau_condition_time_entry foreign key ("TIME_ENTRY_ID") references "TIME_ENTRIES" ("ID") on delete cascade;
alter table "DATA_ACCESS_LOG" add constraint data_access_log_action_ref foreign key ("ACTION") references "REF_ACTION_ACCES" ("CODE");
alter table "DEPARTMENTS" add constraint departments_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_document_type_id_f foreign key ("DOCUMENT_TYPE_ID") references "DOCUMENT_TYPES" ("ID") on delete set null;
alter table "DOCUMENTS" add constraint documents_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_uploaded_by_fkey foreign key ("UPLOADED_BY") references "APP_USERS" ("ID");
alter table "EMPLOYEE_CHILDREN" add constraint child_belongs_to_employees_c foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "EMPLOYEE_CHILDREN" add constraint employee_children_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_CHILDREN" add constraint employee_children_lien_ref foreign key ("RELATIONSHIP") references "REF_LIEN_ENFANT" ("CODE");
alter table "EMPLOYEE_DISABILITIES" add constraint disability_belongs_to_employ foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_compan foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_eviden foreign key ("EVIDENCE_DOCUMENT_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "EMPLOYEE_SANCTIONS" add constraint employee_sanctions_amendment foreign key ("AMENDMENT_CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "EMPLOYEE_SANCTIONS" add constraint employee_sanctions_contract_ foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "EMPLOYEE_SANCTIONS" add constraint employee_sanctions_evidence_ foreign key ("EVIDENCE_DOCUMENT_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "EMPLOYEE_SANCTIONS" add constraint employee_sanctions_sanction_ foreign key ("SANCTION_TYPE") references "SANCTION_TYPES" ("CODE");
alter table "EMPLOYEE_SANCTIONS" add constraint employee_sanctions_terminati foreign key ("TERMINATION_ID") references "CONTRACT_TERMINATIONS" ("ID") on delete set null;
alter table "EMPLOYEE_SANCTIONS" add constraint sanction_belongs_to_employee foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_evidence_d foreign key ("EVIDENCE_DOCUMENT_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "EMPLOYEE_STATUSES" add constraint status_belongs_to_employees_ foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_company_i foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_employee_ foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEES" add constraint employees_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEES" add constraint employees_department_id_fkey foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "EMPLOYEES" add constraint employees_user_id_fkey foreign key ("USER_ID") references "APP_USERS" ("ID") on delete set null;
alter table "EXPORT_LOG" add constraint export_log_organization_id_f foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "EXPORT_LOG" add constraint export_log_requested_by_fkey foreign key ("REQUESTED_BY") references "APP_USERS" ("ID");
alter table "EXPORT_LOG" add constraint export_log_sujet_ref foreign key ("SUBJECT_KIND") references "REF_SUJET_EXPORT" ("CODE");
alter table "FICHE_SANTE" add constraint fiche_sante_enfant_id_fkey foreign key ("ENFANT_ID") references "EMPLOYEE_CHILDREN" ("ID") on delete cascade;
alter table "HEADCOUNT_SNAPSHOTS" add constraint headcount_snapshots_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "INTERIM_AGENCIES" add constraint interim_agencies_organizatio foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "LEGAL_PARAMETERS" add constraint legal_parameters_entered_by_ foreign key ("ENTERED_BY") references "APP_USERS" ("ID");
alter table "LEGAL_PARAMETERS" add constraint legal_parameters_validated_b foreign key ("VALIDATED_BY") references "APP_USERS" ("ID");
alter table "MEAL_VOUCHER_GRANTS" add constraint meal_voucher_grants_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "MEAL_VOUCHER_GRANTS" add constraint voucher_belongs_to_employees foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_belongs_to_employee foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_compensati foreign key ("COMPENSATION") references "REF_COMPENSATION_HEURES_SUP" ("CODE");
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_hr_validat foreign key ("HR_VALIDATED_BY") references "APP_USERS" ("ID");
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_requested_ foreign key ("REQUESTED_BY") references "APP_USERS" ("ID");
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_schedule_i foreign key ("SCHEDULE_ID") references "SCHEDULES" ("ID") on delete set null;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_statut_ref foreign key ("STATUS") references "REF_STATUT_HEURES_SUP" ("CODE");
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint personne_indicateur_secours_ foreign key ("ENFANT_ID") references "EMPLOYEE_CHILDREN" ("ID") on delete cascade;
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint personne_indicateur_secours_ foreign key ("INDICATEUR") references "REF_INDICATEUR_SECOURS" ("CODE");
alter table "PREMIUMS" add constraint premium_belongs_to_employees foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "PREMIUMS" add constraint premiums_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "PREMIUMS" add constraint premiums_contract_id_fkey foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "PREMIUMS" add constraint premiums_nature_ref foreign key ("KIND") references "REF_NATURE_PRIME" ("CODE");
alter table "PREMIUMS" add constraint premiums_termination_id_fkey foreign key ("TERMINATION_ID") references "CONTRACT_TERMINATIONS" ("ID") on delete set null;
alter table "PROBATION_EXTENSIONS" add constraint probation_extensions_contrac foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "PROFILES" add constraint profiles_id_fkey foreign key ("ID") references "APP_USERS" ("ID") on delete cascade;
alter table "PROFILES" add constraint profiles_organization_id_fke foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID");
alter table "REFERENCE_PERIODS" add constraint reference_periods_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "REFERENCE_PERIODS" add constraint reference_periods_department foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SANCTION_TYPES" add constraint sanction_types_category_code foreign key ("CATEGORY_CODE") references "SANCTION_CATEGORIES" ("CODE");
alter table "SCHEDULES" add constraint schedules_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SCHEDULES" add constraint schedules_department_id_fkey foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SCHEDULES" add constraint schedules_published_by_fkey foreign key ("PUBLISHED_BY") references "APP_USERS" ("ID");
alter table "SHIFT_TEMPLATES" add constraint shift_templates_company_id_f foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SHIFT_TEMPLATES" add constraint shift_templates_department_i foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SHIFTS" add constraint shift_belongs_to_employees_c foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "SHIFTS" add constraint shift_belongs_to_schedules_c foreign key ("SCHEDULE_ID", "COMPANY_ID") references "SCHEDULES" ("ID", "COMPANY_ID") on delete cascade;
alter table "SHIFTS" add constraint shift_site_belongs_to_compan foreign key ("CLIENT_SITE_ID", "COMPANY_ID") references "CLIENT_SITES" ("ID", "COMPANY_ID") on delete set null;
alter table "SHIFTS" add constraint shifts_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SHIFTS" add constraint shifts_template_id_fkey foreign key ("TEMPLATE_ID") references "SHIFT_TEMPLATES" ("ID") on delete set null;
alter table "TIME_ENTRIES" add constraint time_entries_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "TIME_ENTRIES" add constraint time_entry_belongs_to_employ foreign key ("EMPLOYEE_ID", "COMPANY_ID") references "EMPLOYEES" ("ID", "COMPANY_ID") on delete cascade;
alter table "USER_ROLES" add constraint user_roles_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "USER_ROLES" add constraint user_roles_organization_id_f foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "USER_ROLES" add constraint user_roles_user_id_fkey foreign key ("USER_ID") references "APP_USERS" ("ID") on delete cascade;

-- Contraintes de validation.
alter table "ABSENCE_ENTITLEMENTS" add constraint absence_entitlements_periode CHECK ((valid_to > valid_from));
alter table "ABSENCE_ENTITLEMENTS" add constraint entitlement_days_positive CHECK (((days IS NULL) OR (days >= (0)::numeric)));
alter table "ABSENCE_ENTITLEMENTS" add constraint entitlement_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "ABSENCES" add constraint absence_days_positive CHECK ((days_count >= (0)::numeric));
alter table "ABSENCES" add constraint absence_pas_sa_propre_parent CHECK (((absence_parente_id IS NULL) OR (absence_parente_id <> id)));
alter table "ABSENCES" add constraint absence_range CHECK ((end_date >= start_date));
alter table "ADDRESS_ZONES" add constraint address_zone_range CHECK (((postal_to IS NULL) OR (postal_from IS NULL) OR (postal_to >= postal_from)));
alter table "ADDRESS_ZONES" add constraint address_zone_verified_needs_ CHECK (((NOT is_verified) OR ((postal_from IS NOT NULL) AND (postal_to IS NOT NULL))));
alter table "ADRESSES_SALARIE" add constraint adr_a_une_adresse CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table "ADRESSES_SALARIE" add constraint adr_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table "ADRESSES_SALARIE" add constraint adr_periode CHECK ((fin_validite > debut_validite));
alter table "APP_USERS" add constraint app_user_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table "APP_USERS" add constraint app_user_email_shape CHECK ((email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text));
alter table "APP_USERS" add constraint app_user_userid_shape CHECK ((userid ~ '^[a-z0-9._-]{3,64}$'::text));
alter table "CBA_SALARY_GRIDS" add constraint grid_amount_positive CHECK ((monthly_amount > (0)::numeric));
alter table "CBA_SALARY_GRIDS" add constraint grid_seniority_order CHECK (((seniority_to_years IS NULL) OR (seniority_to_years > seniority_from_years)));
alter table "CCT_REGLE_PRIME" add constraint crp_periode CHECK ((fin_validite > debut_validite));
alter table "CCT_REGLE_PRIME" add constraint crp_seuil_positif CHECK ((seuil_minutes >= 0));
alter table "CCT_REGLE_PRIME" add constraint crp_source_non_vide CHECK ((btrim(source_url) <> ''::text));
alter table "CCT_REGLE_PRIME" add constraint crp_taux_exige_assiette CHECK (((taux_pct IS NULL) OR (assiette IS NOT NULL)));
alter table "CCT_REGLE_PRIME" add constraint crp_taux_ou_montant CHECK ((num_nonnulls(taux_pct, montant) = 1));
alter table "CLIENT_SITES" add constraint client_site_has_an_address CHECK (((address_line IS NOT NULL) OR ((postal_code IS NOT NULL) AND (city IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table "COLLECTIVE_AGREEMENTS" add constraint collective_agreements_period CHECK ((valid_to > valid_from));
alter table "COMPANIES" add constraint ccss_matricule_format CHECK (((ccss_matricule IS NULL) OR (ccss_matricule ~ '^[0-9]{13}$'::text)));
alter table "COMPANIES" add constraint companies_reference_period_p CHECK ((reference_period_months >= 1));
alter table "COMPANY_ACCIDENT_CLAIMS" add constraint accident_counts_positive CHECK (((claim_count >= 0) AND (days_lost >= 0) AND ((cost IS NULL) OR (cost >= (0)::numeric))));
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_collective_agreement CHECK ((valid_to > valid_from));
alter table "COMPANY_RATE_PERIODS" add constraint company_rate_periods_mutuali CHECK ((mutuality_class >= 1));
alter table "COMPANY_RATE_PERIODS" add constraint company_rate_periods_periode CHECK ((valid_to > valid_from));
alter table "COMPANY_RATE_PERIODS" add constraint rate_period_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_collective_agreemen CHECK ((valid_to > valid_from));
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_peri CHECK ((valid_to > valid_from));
alter table "CONTRACT_PAY_COMPONENTS" add constraint pay_component_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACT_TERMINATIONS" add constraint notice_dates_order CHECK (((notice_start IS NULL) OR (notice_end IS NULL) OR (notice_end >= notice_start)));
alter table "CONTRACT_TERMINATIONS" add constraint waiver_compensation_positive CHECK (((waiver_compensation IS NULL) OR (waiver_compensation >= (0)::numeric)));
alter table "CONTRACT_TERMINATIONS" add constraint waiver_needs_agreement_date CHECK (((NOT notice_waived) OR (waiver_agreed_on IS NOT NULL)));
alter table "CONTRACTS" add constraint cdd_needs_reason CHECK (((kind <> 'cdd'::contract_kind) OR (cdd_reason IS NOT NULL)));
alter table "CONTRACTS" add constraint contract_dates_order CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table "CONTRACTS" add constraint contract_not_its_own_predece CHECK (((previous_contract_id IS NULL) OR (previous_contract_id <> id)));
alter table "CONTRACTS" add constraint contract_quantities_positive CHECK (((weekly_hours > (0)::numeric) AND (days_per_week > (0)::numeric) AND (days_per_week <= (7)::numeric) AND (monthly_gross >= (0)::numeric) AND (renewal_count >= 0) AND ((break_minutes IS NULL) OR (break_minutes >= 0)) AND ((annual_leave_days IS NULL) OR (annual_leave_days >= (0)::numeric)) AND ((probation_length IS NULL) OR (probation_length > 0)) AND ((apprenticeship_year IS NULL) OR (apprenticeship_year > 0))));
alter table "CONTRACTS" add constraint fixed_term_needs_end CHECK (((kind <> ALL (ARRAY['cdd'::contract_kind, 'seasonal'::contract_kind, 'interim'::contract_kind, 'apprenticeship'::contract_kind])) OR (end_date IS NOT NULL)));
alter table "CONTRACTS" add constraint interim_needs_user_company CHECK (((kind <> 'interim'::contract_kind) OR (user_company_name IS NOT NULL)));
alter table "CONTRACTS" add constraint probation_length_and_unit_to CHECK (((probation_length IS NULL) = (probation_unit IS NULL)));
alter table "CRENEAU_CONDITION" add constraint cc_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table "CRENEAU_CONDITION" add constraint cc_heures_differentes CHECK ((heure_debut <> heure_fin));
alter table "CRENEAU_CONDITION" add constraint cc_rattachement CHECK (((shift_id IS NOT NULL) OR (time_entry_id IS NOT NULL)));
alter table "DEPARTMENTS" add constraint coverage_positive CHECK (((min_evening_coverage IS NULL) OR (min_evening_coverage >= 0)));
alter table "DOCUMENTS" add constraint document_expiry_after_issue CHECK (((expires_on IS NULL) OR (issued_on IS NULL) OR (expires_on >= issued_on)));
alter table "DOCUMENTS" add constraint document_size_positive CHECK (((size_bytes IS NULL) OR (size_bytes >= 0)));
alter table "EMPLOYEE_CHILDREN" add constraint ec_taux_exige_handicap CHECK (((taux_handicap_pct IS NULL) OR en_situation_handicap));
alter table "EMPLOYEE_CHILDREN" add constraint ec_taux_handicap CHECK (((taux_handicap_pct IS NULL) OR ((taux_handicap_pct > (0)::numeric) AND (taux_handicap_pct <= (100)::numeric))));
alter table "EMPLOYEE_CHILDREN" add constraint privacy_minimises_data CHECK (((NOT privacy_opt_out) OR ((first_name IS NULL) AND (last_name IS NULL) AND (sex IS NULL) AND (note IS NULL))));
alter table "EMPLOYEE_DISABILITIES" add constraint disability_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_period CHECK ((valid_to > valid_from));
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_rate_p CHECK (((rate_pct > (0)::numeric) AND (rate_pct <= (100)::numeric)));
alter table "EMPLOYEE_SANCTIONS" add constraint sanction_dates_order CHECK (((effective_to IS NULL) OR (effective_from IS NULL) OR (effective_to >= effective_from)));
alter table "EMPLOYEE_SANCTIONS" add constraint sanction_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table "EMPLOYEE_SANCTIONS" add constraint sanction_known_after_facts CHECK ((facts_known_on >= facts_on));
alter table "EMPLOYEE_SANCTIONS" add constraint sanction_notified_after_know CHECK (((notified_on IS NULL) OR (notified_on >= facts_known_on)));
alter table "EMPLOYEE_STATUSES" add constraint status_range CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_periode_v CHECK ((valid_to > valid_from));
alter table "EMPLOYEE_TAX_CARDS" add constraint tax_card_amounts_positive CHECK (((monthly_allowance >= (0)::numeric) AND ((professional_expenses_monthly IS NULL) OR (professional_expenses_monthly >= (0)::numeric)) AND (other_deductions_monthly >= (0)::numeric) AND ((commute_distance_km IS NULL) OR (commute_distance_km >= (0)::numeric))));
alter table "EMPLOYEE_TAX_CARDS" add constraint tax_card_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "EMPLOYEES" add constraint employee_email_shape CHECK (((email IS NULL) OR (email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text)));
alter table "FICHE_SANTE" add constraint fs_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table "FICHE_SANTE" add constraint fs_personne CHECK ((num_nonnulls(employee_id, enfant_id) = 1));
alter table "HEADCOUNT_SNAPSHOTS" add constraint headcount_month_is_first_day CHECK (((EXTRACT(day FROM month))::integer = 1));
alter table "HEADCOUNT_SNAPSHOTS" add constraint headcount_positive CHECK ((headcount >= (0)::numeric));
alter table "LEGAL_PARAMETERS" add constraint legal_parameters_periode_val CHECK ((valid_to > valid_from));
alter table "LEGAL_PARAMETERS" add constraint one_value CHECK (((num_nonnulls(value_num, value_text, value_json) = 1) OR ((derived_from_key IS NOT NULL) AND (num_nonnulls(value_num, value_text, value_json) = 0))));
alter table "LEGAL_PARAMETERS" add constraint valid_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "MEAL_VOUCHER_GRANTS" add constraint meal_voucher_grants_voucher_ CHECK ((voucher_count >= 0));
alter table "MEAL_VOUCHER_GRANTS" add constraint voucher_period CHECK ((period_end >= period_start));
alter table "MEAL_VOUCHER_GRANTS" add constraint voucher_share_within_face_va CHECK (((face_value > (0)::numeric) AND (employee_share >= (0)::numeric) AND (employee_share <= face_value)));
alter table "OVERTIME_REQUESTS" add constraint overtime_acceptance_follows_ CHECK (((employee_accepted_at IS NULL) OR (hr_validated_at IS NOT NULL)));
alter table "OVERTIME_REQUESTS" add constraint overtime_approved_needs_both CHECK (((status <> 'approved'::text) OR ((hr_validated_at IS NOT NULL) AND (employee_accepted_at IS NOT NULL))));
alter table "OVERTIME_REQUESTS" add constraint overtime_period CHECK ((period_end >= period_start));
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_hours_chec CHECK ((hours > (0)::numeric));
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint pis_periode CHECK ((fin_validite > debut_validite));
alter table "PERSONNE_INDICATEUR_SECOURS" add constraint pis_personne CHECK ((num_nonnulls(employee_id, enfant_id) = 1));
alter table "PREMIUMS" add constraint premium_exempt_is_a_percenta CHECK (((exempt_pct >= (0)::numeric) AND (exempt_pct <= (100)::numeric)));
alter table "PREMIUMS" add constraint premiums_amount_check CHECK ((amount >= (0)::numeric));
alter table "PUBLIC_HOLIDAYS" add constraint holiday_year_matches_date CHECK (((EXTRACT(year FROM holiday_date))::integer = year));
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
alter table "REFERENCE_PERIODS" add constraint prl_range CHECK ((end_date > start_date));
alter table "REFERENCE_PERIODS" add constraint reference_periods_months_pos CHECK ((months >= 1));
alter table "SANCTION_CATEGORIES" add constraint sanction_categories_periode_ CHECK ((valid_to > valid_from));
alter table "SANCTION_CATEGORIES" add constraint sanction_category_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "SANCTION_TYPES" add constraint sanction_type_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "SANCTION_TYPES" add constraint sanction_types_periode_valid CHECK ((valid_to > valid_from));
alter table "SCHEDULES" add constraint published_iff_timestamp CHECK (((status = 'published'::schedule_status) = (published_at IS NOT NULL)));
alter table "SHIFT_TEMPLATES" add constraint template_break_positive CHECK ((break_minutes >= 0));
alter table "SHIFTS" add constraint shift_break_positive CHECK ((break_minutes >= 0));
alter table "SHIFTS" add constraint shift_times_differ CHECK ((start_time <> end_time));
alter table "TAX_BRACKETS" add constraint bracket_range CHECK (((bracket_max IS NULL) OR (bracket_max > bracket_min)));
alter table "TAX_BRACKETS" add constraint bracket_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "TAX_BRACKETS" add constraint tax_brackets_periode_valide CHECK ((valid_to > valid_from));
alter table "TAX_CREDITS" add constraint credit_income_order CHECK (((income_max IS NULL) OR (income_min IS NULL) OR (income_max > income_min)));
alter table "TAX_CREDITS" add constraint credit_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "TAX_CREDITS" add constraint tax_credits_periode_valide CHECK ((valid_to > valid_from));
alter table "TIME_ENTRIES" add constraint time_entry_hours_positive CHECK (((break_minutes >= 0) AND ((worked_hours IS NULL) OR (worked_hours >= (0)::numeric)) AND ((planned_hours IS NULL) OR (planned_hours >= (0)::numeric)) AND (sunday_hours >= (0)::numeric) AND (holiday_hours >= (0)::numeric) AND (night_hours >= (0)::numeric) AND (overtime_hours >= (0)::numeric)));
alter table "TIME_ENTRIES" add constraint time_entry_parts_within_work CHECK (((worked_hours IS NULL) OR ((sunday_hours <= worked_hours) AND (holiday_hours <= worked_hours) AND (night_hours <= worked_hours) AND (overtime_hours <= worked_hours))));
alter table "TRAVEL_DISTANCES" add constraint travel_distance_positive CHECK ((distance_km >= (0)::numeric));
alter table "TRAVEL_DISTANCES" add constraint travel_distance_refs_differ CHECK ((origin_ref <> destination_ref));

-- ------------------------------------------------------------------
-- COMMENTAIRES — 75 table(s) et 836 colonne(s).
-- Repris tels quels du schéma PostgreSQL, qui fait foi.
-- ------------------------------------------------------------------
comment on table "ABSENCE_ENTITLEMENTS" is 'Droit ouvert par motif d''absence, daté. Un congé extraordinaire dont la durée change au fil des réformes porte ici plusieurs versions successives.';
comment on column "ABSENCE_ENTITLEMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ABSENCE_ENTITLEMENTS"."ABSENCE_TYPE_ID" is 'Type d''absence auquel ce droit se rapporte. Le droit est daté : un même type peut ouvrir un nombre de jours différent selon la période.';
comment on column "ABSENCE_ENTITLEMENTS"."DAYS" is 'Nombre de jours ouverts par événement.';
comment on column "ABSENCE_ENTITLEMENTS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "ABSENCE_ENTITLEMENTS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "ABSENCE_ENTITLEMENTS"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "ABSENCE_ENTITLEMENTS"."FREQUENCY_NOTE" is 'Condition de renouvellement exprimée en clair quand elle ne se réduit pas à un nombre.';
comment on column "ABSENCE_ENTITLEMENTS"."CAREER_CAP_DAYS" is 'Plafond sur toute la carrière, lorsque le droit n''est pas renouvelable indéfiniment.';
comment on column "ABSENCE_ENTITLEMENTS"."BLOCK_DAYS" is 'Durée du bloc indivisible lorsque le droit doit être pris d''un seul tenant.';
comment on column "ABSENCE_ENTITLEMENTS"."PERIOD_MONTHS" is 'Fenêtre glissante sur laquelle le droit se reconstitue.';
comment on column "ABSENCE_ENTITLEMENTS"."RELATIONSHIP_DEGREE" is 'Degré de parenté exigé, pour les congés liés à un événement familial.';
comment on column "ABSENCE_ENTITLEMENTS"."REQUIRES_EVIDENCE" is 'Vrai si un justificatif conditionne l''ouverture du droit.';
comment on column "ABSENCE_ENTITLEMENTS"."NOTE" is 'Précision sur l''origine du droit : disposition conventionnelle, usage d''entreprise, circonstance particulière. Lue par un humain, jamais par le moteur.';
comment on table "ABSENCE_TYPES" is 'Catalogue des motifs d''absence : congés, maladie, congés extraordinaires, absences non rémunérées.';
comment on column "ABSENCE_TYPES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ABSENCE_TYPES"."CODE" is 'Code stable du type d''absence, utilisé par le moteur et par les deux interfaces. Il ne change jamais : c''est le libellé qui se retouche, pas le code.';
comment on column "ABSENCE_TYPES"."LABEL" is 'Libellé affiché du type d''absence, en français. Destiné à l''écran, jamais à une comparaison.';
comment on column "ABSENCE_TYPES"."CATEGORY" is 'Famille d''absence, qui commande le traitement par le moteur.';
comment on column "ABSENCE_TYPES"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "ABSENCE_TYPES"."REQUIRES_CERTIFICATE" is 'Vrai si un justificatif est exigé pour que l''absence soit régulière.';
comment on column "ABSENCE_TYPES"."IS_PAID" is 'Vrai si l''absence est rémunérée par l''employeur.';
comment on column "ABSENCE_TYPES"."COUNTS_AGAINST_LEAVE" is 'Vrai si l''absence s''impute sur le solde de congé annuel.';
comment on table "ABSENCES" is 'Absence d''un salarié : congé, maladie, congé extraordinaire. Le moteur en contrôle le droit, l''imputation et les justificatifs.';
comment on column "ABSENCES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ABSENCES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ABSENCES"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "ABSENCES"."ABSENCE_TYPE_ID" is 'Type d''absence demandé. Détermine les pièces exigées, le délai de certificat et l''imputation sur les compteurs.';
comment on column "ABSENCES"."START_DATE" is 'Premier jour d''absence, inclus. Jour entier : une absence d''une demi-journée se compte par days_count, pas par les bornes.';
comment on column "ABSENCES"."END_DATE" is 'Dernier jour d''absence, INCLUS — contrairement aux bornes de validité du référentiel, qui sont exclusives. Une absence d''un seul jour porte la même date en début et en fin.';
comment on column "ABSENCES"."DAYS_COUNT" is 'Jours décomptés, calculés hors fériés et jours non ouvrés — pas la simple différence de dates.';
comment on column "ABSENCES"."STATUS" is 'Où en est la demande : proposé, en attente, validé, refusé, annulé. Un refus n''est jamais un point final — il doit s''accompagner d''une contre-proposition, chaînée par absence_parente_id.';
comment on column "ABSENCES"."COMMENT" is 'Motif ou précision donnée par le demandeur. Visible du salarié comme du gestionnaire : ce n''est pas une note interne.';
comment on column "ABSENCES"."CERTIFICATE_RECEIVED" is 'Vrai dès réception du certificat, sous quelque forme que ce soit.';
comment on column "ABSENCES"."CERTIFICATE_RECEIVED_AT" is 'Date de réception du certificat, original ou copie. C''est elle qui arrête le décompte du délai CCSS, pas la date d''émission du certificat.';
comment on column "ABSENCES"."CERTIFICATE_DOCUMENT_ID" is 'Pièce justificative rattachée. Sans clé étrangère stricte vers un document supprimé : l''absence reste lisible même si la pièce a été purgée.';
comment on column "ABSENCES"."REQUESTED_BY" is 'Compte à l''origine de la demande. Peut différer du salarié : un gestionnaire saisit pour un salarié sans accès, et il faut savoir qui a saisi.';
comment on column "ABSENCES"."DECIDED_BY" is 'Auteur de la décision d''acceptation ou de refus.';
comment on column "ABSENCES"."DECIDED_AT" is 'Horodatage de la décision. Avec decided_by, répond à « qui a tranché, et quand » — une validation d''absence est un acte opposable.';
comment on column "ABSENCES"."DECISION_NOTE" is 'Motivation de la décision, restituée au salarié.';
comment on column "ABSENCES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ABSENCES"."DECLARED_BY_EMPLOYEE" is 'Vrai si la déclaration vient de l''espace salarié, faux si elle est saisie par les RH.';
comment on column "ABSENCES"."CERTIFICATE_UPLOADED_AT" is 'Dépôt numérique du certificat par le salarié.';
comment on column "ABSENCES"."CERTIFICATE_ORIGINAL_RECEIVED" is 'Réception de l''original papier, exigée séparément du dépôt numérique.';
comment on column "ABSENCES"."CERTIFICATE_ORIGINAL_RECEIVED_AT" is 'Date de réception de l''ORIGINAL papier. Distincte de la copie : la CCSS exige l''original, et seule cette date solde l''obligation.';
comment on column "ABSENCES"."CHILD_ID" is 'Enfant concerné, pour un congé lié à un enfant.';
comment on column "ABSENCES"."ABSENCE_PARENTE_ID" is 'Proposition que celle-ci remplace. Chaîne la demande initiale et les contre-propositions successives : c''est l''historique de la négociation, lisible dans les deux sens.';
comment on column "ABSENCES"."PROPOSEE_PAR" is 'Qui a formulé cette proposition : « salarie » pour la demande initiale, « employeur » pour une contre-proposition.';
comment on column "ABSENCES"."RANG_PROPOSITION" is 'Profondeur dans la chaîne. Zéro pour la demande initiale. Borné, pour qu''une négociation sans fin ne soit pas possible.';
comment on table "ADDRESS_CHECKS" is 'Dernier verdict de validation d''adresse par objet. Une adresse « unknown » y reste visible : c''est ce qui permet de la reprendre plus tard, plutôt que de la croire vérifiée.';
comment on column "ADDRESS_CHECKS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ADDRESS_CHECKS"."ENTITY_TABLE" is 'Table de la ligne vérifiée — employees, companies, client_sites. Le contrôle d''adresse est le même pour toutes ; cette colonne dit d''où vient celle-ci.';
comment on column "ADDRESS_CHECKS"."ENTITY_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "ADDRESS_CHECKS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ADDRESS_CHECKS"."COUNTRY" is 'Code pays ISO 3166-1 alpha-3.';
comment on column "ADDRESS_CHECKS"."POSTAL_CODE" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "ADDRESS_CHECKS"."STATUS" is 'Résultat du contrôle, parmi ref_statut_verification_adresse : vérifiée, incohérente, hors périmètre, non vérifiable. « Non vérifiable » est un résultat, pas un échec : LuxRH ne couvre que le Luxembourg et les zones frontalières déclarées.';
comment on column "ADDRESS_CHECKS"."ZONE_CODE" is 'Zone reconnue pour cette adresse : Luxembourg, ou zone frontalière déclarée. Détermine le régime de frontalier et les barèmes applicables.';
comment on column "ADDRESS_CHECKS"."MESSAGE" is 'Explication du résultat, destinée à l''humain qui corrigera. Une adresse rejetée sans motif ne se corrige pas.';
comment on column "ADDRESS_CHECKS"."CHECKED_AT" is 'Date du contrôle. Un référentiel postal évolue : un contrôle ancien ne vaut pas contrôle actuel.';
comment on table "ADDRESS_ZONES" is 'Zones géographiques dans lesquelles une adresse est acceptée. Hors de ces zones, la saisie est refusée : l''outil ne prétend pas couvrir des adresses qu''il ne sait pas vérifier.';
comment on column "ADDRESS_ZONES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ADDRESS_ZONES"."COUNTRY" is 'Code pays ISO 3166-1 alpha-3. Trois lettres partout dans l''application.';
comment on column "ADDRESS_ZONES"."KIND" is 'Nature de la zone : pays, région frontalière, plage de codes postaux. Détermine comment les bornes se lisent.';
comment on column "ADDRESS_ZONES"."CODE" is 'Code de la zone, repris par address_checks.zone_code et par les barèmes qui s''y réfèrent.';
comment on column "ADDRESS_ZONES"."LABEL" is 'Nom lisible de la zone, pour l''affichage et les messages de contrôle.';
comment on column "ADDRESS_ZONES"."POSTAL_FROM" is 'Borne basse du code postal, une fois le préfixe pays retiré. Nulle quand le pays n''admet pas de découpage postal fiable — voir is_verified.';
comment on column "ADDRESS_ZONES"."POSTAL_TO" is 'Borne haute INCLUSE de la plage de codes postaux couverte. Nulle si la zone ne se décrit pas par une plage.';
comment on column "ADDRESS_ZONES"."IS_VERIFIED" is 'Vrai si les bornes postales sont établies et vérifiables. Faux pour une zone déclarée sans correspondance postale fiable : la validation répond alors « indéterminé » plutôt que d''accepter à tort.';
comment on column "ADDRESS_ZONES"."SOURCE" is 'D''où viennent les bornes. Une zone sans source n''a rien à faire ici.';
comment on column "ADDRESS_ZONES"."NOTE" is 'Origine de la délimitation : convention, accord frontalier, choix de paramétrage. Ce qui permet de la contester.';
comment on table "ADRESSES_SALARIE" is 'Les quatre adresses du salarié, historisées. Chaque type doit couvrir toute la période sans trou ni recouvrement, depuis la candidature jusqu''à bien après le départ : une erreur de salaire découverte plus tard suppose de pouvoir écrire à la personne.';
comment on column "ADRESSES_SALARIE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ADRESSES_SALARIE"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "ADRESSES_SALARIE"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
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
comment on column "ADRESSES_SALARIE"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "ADRESSES_SALARIE"."CREATED_BY" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "ADRESSES_SALARIE"."DELETED_AT" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "ADRESSES_SALARIE"."DELETED_BY" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "APP_SECRETS" is 'Clés de chiffrement du moteur. RLS active et VOLONTAIREMENT sans aucune politique : aucune ligne n''est donc accessible par l''API REST. Seules les fonctions security definer fn_encrypt_field et fn_decrypt_field y accèdent, et ces deux fonctions ne sont exécutables par personne hors du moteur.';
comment on column "APP_SECRETS"."KEY" is 'Nom du secret. La table porte RLS active et VOLONTAIREMENT aucune politique : aucune ligne n''est accessible par l''API REST, seules les fonctions security definer du moteur y accèdent.';
comment on column "APP_SECRETS"."SECRET" is 'Valeur du secret. Voir la remarque sur la table : elle n''est lisible par personne à travers l''API. Un secret qui vit dans la base qu''il protège reste un compromis assumé et documenté.';
comment on table "APP_USERS" is 'Comptes applicatifs. Point d''ancrage commun aux trois moteurs : sur PostgreSQL elle reflète auth.users et password_hash reste nul, l''authentification appartenant à Supabase ; sur Oracle et MySQL elle porte le mot de passe et devient la table d''identité vers laquelle pointent les clés étrangères d''auteur.';
comment on column "APP_USERS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "APP_USERS"."USERID" is 'Identifiant de connexion, en minuscules. Unique parmi les comptes vivants seulement : un identifiant libéré par une suppression logique peut être réattribué.';
comment on column "APP_USERS"."EMAIL" is 'Adresse de connexion et de notification. Unique : c''est elle qui identifie le compte pour la récupération de mot de passe.';
comment on column "APP_USERS"."FULL_NAME" is 'Nom affiché du compte. Modifiable par l''intéressé en libre-service, contrairement aux données d''identité du dossier salarié.';
comment on column "APP_USERS"."PASSWORD_HASH" is 'Empreinte bcrypt du mot de passe. NUL sur PostgreSQL/Supabase, où Auth détient le secret. Jamais le mot de passe en clair, à aucun moment.';
comment on column "APP_USERS"."IS_ADMIN" is 'Administrateur : seul habilité à lire le catalogue du schéma et à créer d''autres comptes.';
comment on column "APP_USERS"."AUTH_USER_ID" is 'Compte auth.users correspondant, quand l''application tourne sur Supabase. Nul sur une cible autonome.';
comment on column "APP_USERS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "APP_USERS"."CREATED_BY" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "APP_USERS"."UPDATED_AT" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column "APP_USERS"."UPDATED_BY" is 'Compte auteur de la dernière modification. Sur une table de comptes, savoir qui a changé quoi n''est pas optionnel.';
comment on column "APP_USERS"."DELETED_AT" is 'Suppression logique : la ligne reste, les clés étrangères qui la référencent tiennent, et le journal demeure lisible. Un compte parti doit encore pouvoir répondre de ce qu''il a fait.';
comment on column "APP_USERS"."DELETED_BY" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "AUDIT_LOG" is 'Journal des écritures, alimenté par le déclencheur fn_audit. Conservé pour la traçabilité et la preuve, jamais modifié par l''application.';
comment on column "AUDIT_LOG"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "AUDIT_LOG"."OCCURRED_AT" is 'Horodatage de l''écriture auditée, posé par la base au moment du déclencheur. Ce n''est pas une date saisie : elle ne se retouche pas.';
comment on column "AUDIT_LOG"."ACTOR_ID" is 'Compte auteur de l''écriture. Nul pour une opération de maintenance exécutée hors session applicative — cas rare, qui doit rester visible plutôt que d''être attribué à tort.';
comment on column "AUDIT_LOG"."ACTOR_LABEL" is 'Nom de l''auteur figé au moment du fait : le journal reste lisible après suppression du compte.';
comment on column "AUDIT_LOG"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "AUDIT_LOG"."ENTITY_TABLE" is 'Nom de la table concernée : le journal est polymorphe, sans clé étrangère.';
comment on column "AUDIT_LOG"."ENTITY_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "AUDIT_LOG"."ACTION" is 'Nature de l''écriture : insert, update, delete. La suppression enregistrée ici est logique ; une ligne n''est jamais retirée de la base.';
comment on column "AUDIT_LOG"."OLD_VALUE" is 'État de la ligne avant écriture, en jsonb. Nul pour une insertion.';
comment on column "AUDIT_LOG"."NEW_VALUE" is 'État de la ligne après écriture. Nul pour une suppression.';
comment on column "AUDIT_LOG"."SOURCE_IP" is 'Adresse d''origine de la requête, telle que rapportée par les en-têtes HTTP. Donnée déclarative : elle situe, elle ne prouve pas.';
comment on column "AUDIT_LOG"."USER_AGENT" is 'Agent utilisateur de l''appelant, tronqué à 400 caractères.';
comment on column "AUDIT_LOG"."REQUEST_ID" is 'Identifiant de requête, pour recouper une trace avec les journaux d''infrastructure.';
comment on table "BENEFIT_TYPES" is 'Catalogue des avantages en nature et de leur méthode d''évaluation.';
comment on column "BENEFIT_TYPES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "BENEFIT_TYPES"."CODE" is 'Code de l''avantage en nature, stable, utilisé par la paie.';
comment on column "BENEFIT_TYPES"."LABEL" is 'Libellé de l''avantage à l''écran et sur le bulletin.';
comment on column "BENEFIT_TYPES"."VALUATION_METHOD" is 'Méthode d''évaluation : forfait, pourcentage, barème.';
comment on column "BENEFIT_TYPES"."IS_TAXABLE" is 'Vrai si l''avantage entre dans l''assiette imposable.';
comment on column "BENEFIT_TYPES"."IS_CONTRIBUTORY" is 'Vrai si l''avantage entre dans l''assiette cotisable.';
comment on column "BENEFIT_TYPES"."VALUATION_PARAMS" is 'Paramètres de la méthode. Les valeurs légales elles-mêmes restent dans legal_parameters.';
comment on column "BENEFIT_TYPES"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "BENEFIT_TYPES"."NOTE" is 'Mode d''évaluation de l''avantage et texte qui le fonde.';
comment on table "CBA_RULES" is 'Contenu d''une convention, bloc par bloc, en jsonb. C''est ce que le moteur compare à la loi pour retenir la disposition la plus favorable.';
comment on column "CBA_RULES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CBA_RULES"."COLLECTIVE_AGREEMENT_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CBA_RULES"."BLOCK" is 'Domaine couvert par le bloc (temps de travail, congés, préavis, rémunération...).';
comment on column "CBA_RULES"."RULES" is 'Clauses du bloc, structurées. Une clause absente n''est pas une clause nulle : elle est inconnue.';
comment on column "CBA_RULES"."IS_COMPLETE" is 'Faux tant que le bloc n''a pas été entièrement saisi : le moteur sait alors qu''il ne peut pas conclure sur ce domaine.';
comment on column "CBA_RULES"."UPDATED_AT" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on table "CBA_SALARY_GRIDS" is 'Grille de salaires conventionnelle : montant minimal par catégorie et par ancienneté.';
comment on column "CBA_SALARY_GRIDS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CBA_SALARY_GRIDS"."COLLECTIVE_AGREEMENT_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CBA_SALARY_GRIDS"."CATEGORY" is 'Catégorie professionnelle de la grille, dans les termes de la convention. C''est elle qui relie un poste à un minimum conventionnel.';
comment on column "CBA_SALARY_GRIDS"."SENIORITY_FROM_YEARS" is 'Ancienneté à partir de laquelle l''échelon s''applique.';
comment on column "CBA_SALARY_GRIDS"."SENIORITY_TO_YEARS" is 'Ancienneté au-delà de laquelle l''échelon cesse. Nul pour le dernier échelon.';
comment on column "CBA_SALARY_GRIDS"."MONTHLY_AMOUNT" is 'Salaire mensuel minimum de la catégorie, en euros, à l''indice de référence de la convention. Le moteur l''indexe avant de le comparer au salaire réel.';
comment on column "CBA_SALARY_GRIDS"."INDEX_REF" is 'Cote d''indice à laquelle le montant est exprimé, pour le réindexer correctement.';
comment on table "CCT_REGLE_PRIME" is 'Règle de prime de condition telle que la convention collective la fixe. Aucune valeur légale générale ici : la loi ne définit pas ces primes, seules les CCT le font. Une règle sans source_url est refusée — elle ne pourrait pas être vérifiée.';
comment on column "CCT_REGLE_PRIME"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CCT_REGLE_PRIME"."COLLECTIVE_AGREEMENT_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
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
comment on column "CCT_REGLE_PRIME"."SOURCE_URL" is 'Lien vers le texte déposé — les conventions luxembourgeoises sont publiées par l''ITM. Obligatoire.';
comment on column "CCT_REGLE_PRIME"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "CCT_REGLE_PRIME"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CCT_REGLE_PRIME"."NOTE" is 'Précisions d''application : cumul, proratisation, exclusions. Ce que l''article dit et que les colonnes ne portent pas.';
comment on table "CLIENT_SITES" is 'Lieu où une vacation peut s''exécuter hors du siège : chantier, site client, antenne. Porte l''adresse qui sert au calcul de distance.';
comment on column "CLIENT_SITES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CLIENT_SITES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CLIENT_SITES"."NAME" is 'Nom du site client, tel qu''il apparaît sur les plannings et les ordres de mission.';
comment on column "CLIENT_SITES"."CLIENT_NAME" is 'Nom du client donneur d''ordre, distinct du nom du site.';
comment on column "CLIENT_SITES"."ADDRESS_LINE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "CLIENT_SITES"."POSTAL_CODE" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "CLIENT_SITES"."CITY" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "CLIENT_SITES"."COUNTRY" is 'Pays du site, en code ISO 3166-1 alpha-3.';
comment on column "CLIENT_SITES"."LATITUDE" is 'Coordonnée, si elle est connue : elle évite de transmettre une adresse en clair au service de distance.';
comment on column "CLIENT_SITES"."LONGITUDE" is 'Longitude en degrés décimaux, obtenue par géocodage. Avec la latitude, permet de calculer la distance depuis l''adresse du salarié.';
comment on column "CLIENT_SITES"."IS_ACTIVE" is 'Faux quand le site n''est plus desservi. Le site reste en base : les plannings passés le nomment encore.';
comment on column "CLIENT_SITES"."NOTE" is 'Consignes d''accès et contraintes du site. Lues par qui s''y rend, pas par le moteur.';
comment on column "CLIENT_SITES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "COLLECTIVE_AGREEMENTS" is 'Convention collective de travail. Sectorielle et partagée, ou propre à une organisation.';
comment on column "COLLECTIVE_AGREEMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COLLECTIVE_AGREEMENTS"."ORGANIZATION_ID" is 'Nul pour une convention sectorielle partagée par toutes les organisations.';
comment on column "COLLECTIVE_AGREEMENTS"."CODE" is 'Code court, clé naturelle utilisée par l''export et l''import du référentiel.';
comment on column "COLLECTIVE_AGREEMENTS"."NAME" is 'Intitulé officiel de la convention, tel que publié par l''ITM.';
comment on column "COLLECTIVE_AGREEMENTS"."SECTOR" is 'Secteur couvert. Sert à proposer la bonne convention lors du rattachement d''une société, jamais à l''imposer.';
comment on column "COLLECTIVE_AGREEMENTS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "COLLECTIVE_AGREEMENTS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "COLLECTIVE_AGREEMENTS"."IS_ACTIVE" is 'Faux quand la convention est dénoncée ou remplacée. Elle reste en base : une paie ancienne doit encore pouvoir citer la convention qui la fondait.';
comment on column "COLLECTIVE_AGREEMENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "COLLECTIVE_AGREEMENTS"."SCOPE" is 'Portée : sectorielle, d''entreprise, ou d''établissement.';
comment on column "COLLECTIVE_AGREEMENTS"."SUPERSEDES_ID" is 'Convention que celle-ci remplace, pour suivre les renouvellements.';
comment on column "COLLECTIVE_AGREEMENTS"."EMPLOYEE_CATEGORY" is 'Catégorie de personnel visée lorsque la convention ne couvre pas tout l''effectif.';
comment on table "COMPANIES" is 'Société employeuse. Deuxième clé d''isolation après l''organisation : la quasi-totalité des tables métier porte un company_id.';
comment on column "COMPANIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPANIES"."ORGANIZATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "COMPANIES"."LEGAL_NAME" is 'Raison sociale, telle qu''inscrite au registre de commerce. C''est ce nom qui figure sur les contrats et les bulletins.';
comment on column "COMPANIES"."LEGAL_FORM" is 'Forme juridique (Sàrl, SA, etc.). Sans effet sur le moteur, utile aux documents.';
comment on column "COMPANIES"."RCS_NUMBER" is 'Numéro au Registre de commerce et des sociétés.';
comment on column "COMPANIES"."CCSS_MATRICULE" is 'Matricule CCSS de l''employeur. Validé par fn_check_national_id (longueur, date encodée, clés de Luhn et de Verhoeff).';
comment on column "COMPANIES"."ADDRESS_LINE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "COMPANIES"."POSTAL_CODE" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "COMPANIES"."CITY" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "COMPANIES"."COUNTRY" is 'Pays du siège, en code ISO 3166-1 alpha-3. Le projet utilise partout l''alpha-3, y compris là où l''alpha-2 suffirait : un seul format évite les conversions silencieuses.';
comment on column "COMPANIES"."NACE_CODE" is 'Code d''activité NACE, base du rattachement sectoriel et de la classe de risque accident.';
comment on column "COMPANIES"."SECTOR" is 'Secteur déclaré. Sert au rapprochement avec les conventions collectives sectorielles.';
comment on column "COMPANIES"."REFERENCE_PERIOD_MONTHS" is 'Durée par défaut de la période de référence pour le calcul du temps de travail, si aucune période explicite n''est définie.';
comment on column "COMPANIES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "COMPANIES"."INTERNAL_RULES_ADOPTED_ON" is 'Date d''adoption des textes internes de l''entreprise. Sans eux, aucune sanction lourde n''est valable — le moteur le vérifie.';
comment on column "COMPANIES"."INTERNAL_RULES_REFERENCE" is 'Référence et date d''adoption du règlement intérieur. Une sanction lourde n''est valable que si elle y figure : sans cette référence, le moteur le signale.';
comment on table "COMPANY_ACCIDENT_CLAIMS" is 'Sinistralité accident déclarée par exercice. Alimente le suivi du facteur bonus-malus.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."YEAR" is 'Année de survenance des sinistres, pour le calcul du bonus-malus accident du travail.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."CLAIM_COUNT" is 'Nombre de sinistres déclarés.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."DAYS_LOST" is 'Journées de travail perdues sur l''exercice.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."COST" is 'Coût des sinistres de l''année, en euros. Entre dans la détermination de la classe de risque et donc du taux de cotisation accident.';
comment on column "COMPANY_ACCIDENT_CLAIMS"."NOTE" is 'Précisions sur les sinistres retenus ou exclus.';
comment on table "COMPANY_COLLECTIVE_AGREEMENTS" is 'Rattachement d''une société, ou d''un de ses services, à une convention collective, sur une période donnée. Une société peut en appliquer plusieurs simultanément.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."COLLECTIVE_AGREEMENT_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."DEPARTMENT_ID" is 'Nul si la convention couvre toute la société.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."NOTE" is 'Circonstances du rattachement de la société à la convention : adhésion, extension, usage. Ce qui permet de le contester.';
comment on column "COMPANY_COLLECTIVE_AGREEMENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "COMPANY_FINANCIALS" is 'Résultats annuels de la société. Sert au calcul de l''enveloppe des primes participatives, plafonnée sur le bénéfice de l''exercice précédent.';
comment on column "COMPANY_FINANCIALS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPANY_FINANCIALS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "COMPANY_FINANCIALS"."FISCAL_YEAR" is 'Exercice comptable concerné, en année pleine.';
comment on column "COMPANY_FINANCIALS"."PROFIT" is 'Bénéfice de l''exercice, assiette du plafond d''enveloppe.';
comment on column "COMPANY_FINANCIALS"."REVENUE" is 'Chiffre d''affaires de l''exercice, en euros. Sert aux seuils qui dépendent de la taille de l''entreprise.';
comment on column "COMPANY_FINANCIALS"."SOURCE" is 'Origine du chiffre : comptes annuels, situation intermédiaire.';
comment on column "COMPANY_FINANCIALS"."NOTE" is 'Origine du chiffre : comptes déposés, estimation, déclaration. Un seuil calculé sur une estimation ne se traite pas comme un seuil calculé sur des comptes.';
comment on column "COMPANY_FINANCIALS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "COMPANY_RATE_PERIODS" is 'Historique des taux propres à la société : classe de mutualité, facteur accident, classe d''activité. Un recalcul lit le taux en vigueur à la date du calcul.';
comment on column "COMPANY_RATE_PERIODS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPANY_RATE_PERIODS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "COMPANY_RATE_PERIODS"."ACTIVITY_CLASS" is 'Classe d''activité déclarée à la CCSS.';
comment on column "COMPANY_RATE_PERIODS"."ACCIDENT_RISK_CLASS" is 'Classe de risque accident attribuée à la société.';
comment on column "COMPANY_RATE_PERIODS"."ACCIDENT_FACTOR" is 'Facteur bonus-malus de l''assurance accident.';
comment on column "COMPANY_RATE_PERIODS"."MUTUALITY_CLASS" is 'Classe de la Mutualité des employeurs, qui commande le taux de cotisation.';
comment on column "COMPANY_RATE_PERIODS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "COMPANY_RATE_PERIODS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "COMPANY_RATE_PERIODS"."SOURCE" is 'Origine du taux : courrier CCSS, décision de classement. Obligatoire.';
comment on column "COMPANY_RATE_PERIODS"."NOTE" is 'Origine du taux appliqué sur la période : notification de l''organisme, classe de risque, régularisation.';
comment on column "COMPANY_RATE_PERIODS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "COMPLIANCE_ALERTS" is 'Constats du moteur de vigilance. Chaque alerte porte son article : c''est ce qui distingue un avertissement d''une injonction opaque.';
comment on column "COMPLIANCE_ALERTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "COMPLIANCE_ALERTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "COMPLIANCE_ALERTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "COMPLIANCE_ALERTS"."RULE_CODE" is 'Code stable de la règle, pour suivre une alerte à travers les scans successifs.';
comment on column "COMPLIANCE_ALERTS"."TITLE" is 'Intitulé court de l''alerte, tel qu''il apparaît dans la liste de vigilance.';
comment on column "COMPLIANCE_ALERTS"."DETAIL" is 'Explication complète : ce qui manque, pourquoi c''est exigé, et ce qu''il faut faire. Une alerte qui ne dit pas quoi faire ne sera pas traitée.';
comment on column "COMPLIANCE_ALERTS"."CONSEQUENCE" is 'Ce qui arrive si rien n''est fait — sanction, requalification, nullité.';
comment on column "COMPLIANCE_ALERTS"."LEGAL_REF" is 'Article qui fonde le constat.';
comment on column "COMPLIANCE_ALERTS"."SEVERITY" is 'Gravité, qui commande le tri et la couleur à l''écran.';
comment on column "COMPLIANCE_ALERTS"."DUE_DATE" is 'Échéance à laquelle le manquement devient effectif.';
comment on column "COMPLIANCE_ALERTS"."STATE" is 'État de traitement : ouverte, traitée, écartée.';
comment on column "COMPLIANCE_ALERTS"."HANDLED_BY" is 'Compte ayant traité l''alerte. Nul tant qu''elle est ouverte.';
comment on column "COMPLIANCE_ALERTS"."HANDLED_AT" is 'Date de traitement. Avec handled_by, permet de mesurer le délai de réaction — la sévérité CCSS s''appuie dessus.';
comment on column "COMPLIANCE_ALERTS"."HANDLED_NOTE" is 'Justification de la prise en charge ou de la mise à l''écart.';
comment on column "COMPLIANCE_ALERTS"."FIRST_SEEN_AT" is 'Première apparition du constat, conservée même si l''alerte réapparaît.';
comment on table "CONTRACT_AMENDMENTS" is 'Avenant. Conserve ce qui a changé et à partir de quand, sans écraser l''état antérieur du contrat.';
comment on column "CONTRACT_AMENDMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRACT_AMENDMENTS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "CONTRACT_AMENDMENTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTRACT_AMENDMENTS"."EFFECTIVE_DATE" is 'Prise d''effet, qui peut différer de la signature.';
comment on column "CONTRACT_AMENDMENTS"."REASON" is 'Motif de l''avenant, obligatoire. Un avenant sans motif est refusé par le moteur : c''est la pièce qui explique, des années après, pourquoi le contrat a changé.';
comment on column "CONTRACT_AMENDMENTS"."CHANGES" is 'Différentiel appliqué, en jsonb : ce que l''avenant modifie, et rien d''autre.';
comment on column "CONTRACT_AMENDMENTS"."CREATED_BY" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "CONTRACT_AMENDMENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "CONTRACT_COLLECTIVE_AGREEMENTS" is 'Conventions applicables à un contrat donné, sur une période. Plusieurs conventions peuvent se cumuler ; le moteur retient la disposition la plus favorable et dit laquelle a gagné.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."COLLECTIVE_AGREEMENT_ID" is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."NOTE" is 'Circonstances du rattachement au niveau du contrat, quand il déroge à celui de la société.';
comment on column "CONTRACT_COLLECTIVE_AGREEMENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "CONTRACT_PAY_COMPONENTS" is 'Éléments de rémunération autres que le brut de base : primes récurrentes, avantages, indemnités.';
comment on column "CONTRACT_PAY_COMPONENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRACT_PAY_COMPONENTS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "CONTRACT_PAY_COMPONENTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTRACT_PAY_COMPONENTS"."KIND" is 'Nature de l''élément, qui commande son traitement fiscal et social.';
comment on column "CONTRACT_PAY_COMPONENTS"."CODE" is 'Code de l''élément de rémunération : prime, indemnité, avantage. Stable, repris par la paie.';
comment on column "CONTRACT_PAY_COMPONENTS"."LABEL" is 'Libellé de l''élément tel qu''il apparaît sur le bulletin.';
comment on column "CONTRACT_PAY_COMPONENTS"."AMOUNT" is 'Montant en euros. Nul quand l''élément se calcule au lieu d''être forfaitaire — un zéro dirait autre chose.';
comment on column "CONTRACT_PAY_COMPONENTS"."RATE_PCT" is 'Taux, pour un élément exprimé en pourcentage plutôt qu''en montant.';
comment on column "CONTRACT_PAY_COMPONENTS"."BASIS" is 'Assiette à laquelle le taux s''applique.';
comment on column "CONTRACT_PAY_COMPONENTS"."PERIODICITY" is 'Périodicité de versement.';
comment on column "CONTRACT_PAY_COMPONENTS"."IN_SALARY_REFERENCE" is 'Vrai si l''élément entre dans le salaire de référence servant au calcul des indemnités.';
comment on column "CONTRACT_PAY_COMPONENTS"."IS_TAXABLE" is 'Vrai si l''élément entre dans l''assiette imposable. Une prime exonérée mal marquée fausse la retenue à la source.';
comment on column "CONTRACT_PAY_COMPONENTS"."IS_CONTRIBUTORY" is 'Vrai si l''élément entre dans l''assiette des cotisations sociales. Indépendant de is_taxable : les deux assiettes ne coïncident pas.';
comment on column "CONTRACT_PAY_COMPONENTS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "CONTRACT_PAY_COMPONENTS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "CONTRACT_PAY_COMPONENTS"."NOTE" is 'Fondement de l''élément : article de convention, usage, accord individuel. Ce qui permet de le défendre ou de le supprimer.';
comment on column "CONTRACT_PAY_COMPONENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CONTRACT_PAY_COMPONENTS"."BENEFIT_TYPE_ID" is 'Avantage en nature du catalogue, lorsque l''élément en est un.';
comment on table "CONTRACT_TERMINATIONS" is 'Rupture du contrat : motif, préavis, indemnités. Le moteur contrôle la licéité avant que la rupture ne soit enregistrée.';
comment on column "CONTRACT_TERMINATIONS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRACT_TERMINATIONS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "CONTRACT_TERMINATIONS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTRACT_TERMINATIONS"."REASON" is 'Motif de la rupture, obligatoire. Détermine le préavis, l''indemnité de départ et la possibilité de contester.';
comment on column "CONTRACT_TERMINATIONS"."IS_PERSONAL_GROUND" is 'Vrai pour un motif personnel, faux pour un motif économique — la distinction commande la procédure de licenciement collectif.';
comment on column "CONTRACT_TERMINATIONS"."NOTIFIED_ON" is 'Date de notification, point de départ du préavis.';
comment on column "CONTRACT_TERMINATIONS"."NOTICE_START" is 'Début effectif du préavis, qui suit des règles de calendrier propres.';
comment on column "CONTRACT_TERMINATIONS"."NOTICE_END" is 'Fin du préavis.';
comment on column "CONTRACT_TERMINATIONS"."SEVERANCE_MONTHS" is 'Indemnité de départ, exprimée en mois de salaire de référence.';
comment on column "CONTRACT_TERMINATIONS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CONTRACT_TERMINATIONS"."NOTICE_WAIVED" is 'Vrai si les parties ont convenu de dispenser le préavis.';
comment on column "CONTRACT_TERMINATIONS"."WAIVER_AGREED_ON" is 'Date de l''accord de renonciation au préavis, s''il y en a un. Nulle en l''absence d''accord : le préavis court alors en entier.';
comment on column "CONTRACT_TERMINATIONS"."WAIVER_COMPENSATION" is 'Contrepartie financière de la dispense de préavis.';
comment on column "CONTRACT_TERMINATIONS"."WAIVER_NOTE" is 'Contenu de l''accord de renonciation, dans les termes convenus. Une renonciation se prouve.';
comment on column "CONTRACT_TERMINATIONS"."IS_GROSS_MISCONDUCT" is 'Faute grave : supprime le préavis, sous conditions strictes de procédure.';
comment on table "CONTRACTS" is 'Contrat de travail. Le brouillon vit ici dès la première étape de l''assistant : c''est cette ligne que le moteur évalue, pas un objet en mémoire du navigateur.';
comment on column "CONTRACTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CONTRACTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CONTRACTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "CONTRACTS"."KIND" is 'Type de contrat : CDI, CDD, apprentissage, saisonnier, intérim, étudiant. Commande les clauses obligatoires et les contrôles.';
comment on column "CONTRACTS"."STATUS" is 'Brouillon, actif, terminé. Un brouillon n''engage rien mais se contrôle déjà.';
comment on column "CONTRACTS"."JOB_TITLE" is 'Intitulé du poste tel qu''il figure au contrat. Mention obligatoire : il fonde la classification conventionnelle, et donc le salaire minimum applicable.';
comment on column "CONTRACTS"."JOB_DESCRIPTION" is 'Description des fonctions. Sa précision détermine ce qu''un changement de tâches doit faire passer par un avenant plutôt que par une simple instruction.';
comment on column "CONTRACTS"."WORK_PLACE" is 'Lieu d''exécution convenu. Mention obligatoire au contrat.';
comment on column "CONTRACTS"."CATEGORY" is 'Catégorie professionnelle, clé d''entrée dans la grille salariale conventionnelle.';
comment on column "CONTRACTS"."START_DATE" is 'Prise d''effet du contrat, jour inclus. Point de départ de l''ancienneté, de la période d''essai et du droit à congé.';
comment on column "CONTRACTS"."END_DATE" is 'Dernier jour du contrat, INCLUS. Nulle pour un contrat à durée indéterminée en cours. Un avenant clôt le contrat précédent la veille de sa prise d''effet.';
comment on column "CONTRACTS"."CDD_REASON" is 'Motif de recours au CDD. Un CDD sans motif licite est requalifiable.';
comment on column "CONTRACTS"."RENEWAL_COUNT" is 'Nombre de renouvellements déjà consommés, borné par la loi.';
comment on column "CONTRACTS"."PREVIOUS_CONTRACT_ID" is 'Contrat que celui-ci renouvelle, pour reconstituer la chaîne et l''ancienneté.';
comment on column "CONTRACTS"."MONTHLY_GROSS" is 'Salaire mensuel brut convenu, hors éléments variables portés par contract_pay_components.';
comment on column "CONTRACTS"."INDEX_REF" is 'Cote d''indice à la signature, pour distinguer une hausse réelle d''une indexation.';
comment on column "CONTRACTS"."WEEKLY_HOURS" is 'Durée hebdomadaire convenue. Sous le plein temps, is_part_time devient vrai.';
comment on column "CONTRACTS"."DAYS_PER_WEEK" is 'Nombre de jours travaillés par semaine, décimal pour les rythmes irréguliers.';
comment on column "CONTRACTS"."WORK_DISTRIBUTION" is 'Répartition convenue de l''horaire. Mention obligatoire au contrat pour un temps partiel.';
comment on column "CONTRACTS"."REFERENCE_PERIOD_MONTHS" is 'Période de référence propre au contrat, si elle déroge à celle de la société.';
comment on column "CONTRACTS"."NIGHT_WORK" is 'Vrai si le poste comporte du travail de nuit, qui ouvre ses propres protections.';
comment on column "CONTRACTS"."ANNUAL_LEAVE_DAYS" is 'Congé annuel convenu lorsqu''il dépasse le minimum légal. Nul renvoie au droit commun.';
comment on column "CONTRACTS"."BREAK_MINUTES" is 'Pause convenue par journée de travail.';
comment on column "CONTRACTS"."NON_COMPETE_CLAUSE" is 'Présence d''une clause de non-concurrence, dont la validité est soumise à conditions.';
comment on column "CONTRACTS"."EXCLUSIVITY_CLAUSE" is 'Présence d''une clause d''exclusivité.';
comment on column "CONTRACTS"."PROBATION_LENGTH" is 'Durée de la période d''essai, exprimée dans l''unité portée par probation_unit.';
comment on column "CONTRACTS"."PROBATION_UNIT" is 'Unité de la période d''essai : mois ou semaines. Les bornes légales diffèrent selon l''unité.';
comment on column "CONTRACTS"."VERSION" is 'Version du contrat, incrémentée par les avenants.';
comment on column "CONTRACTS"."SIGNED_AT" is 'Date de signature. Un contrat actif sans date de signature est un manquement.';
comment on column "CONTRACTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CONTRACTS"."IS_PART_TIME" is 'Temps partiel, tenu à jour par le déclencheur fn_sync_part_time — ne pas écrire à la main.';
comment on column "CONTRACTS"."APPRENTICESHIP_LEVEL" is 'Niveau de la formation, pour un contrat d''apprentissage.';
comment on column "CONTRACTS"."APPRENTICESHIP_YEAR" is 'Année du cycle d''apprentissage, qui commande l''indemnité.';
comment on column "CONTRACTS"."SEASON_LABEL" is 'Saison couverte, pour un contrat saisonnier.';
comment on column "CONTRACTS"."INTERIM_AGENCY_ID" is 'Agence d''intérim employeuse, pour un contrat de mission.';
comment on column "CONTRACTS"."USER_COMPANY_NAME" is 'Société utilisatrice chez qui la mission s''exécute.';
comment on column "CONTRACTS"."MISSION_REASON" is 'Motif de recours à l''intérim, soumis aux mêmes exigences que le motif de CDD.';
comment on table "CRENEAU_CONDITION" is 'Créneau réellement travaillé sous une condition ouvrant droit à prime : qui, quand, où, de quelle heure à quelle heure. C''est ce relevé qui rend la prime calculable — sans lui, la règle conventionnelle reste lettre morte.';
comment on column "CRENEAU_CONDITION"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "CRENEAU_CONDITION"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "CRENEAU_CONDITION"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "CRENEAU_CONDITION"."SHIFT_ID" is 'Vacation planifiée. Le créneau se saisit au planning, puis se confirme au registre du temps.';
comment on column "CRENEAU_CONDITION"."TIME_ENTRY_ID" is 'Journée du registre du temps. C''est elle qui fait foi pour le paiement, le planning n''étant qu''une prévision.';
comment on column "CRENEAU_CONDITION"."CLIENT_SITE_ID" is 'Site client où la condition a été constatée. Nul pour une condition constatée dans les locaux de l''employeur.';
comment on column "CRENEAU_CONDITION"."CONDITION_CODE" is 'Condition constatée, parmi ref_condition_travail. C''est le constat qui ouvre le droit, pas le poste : un même salarié peut être exposé un jour et pas le lendemain.';
comment on column "CRENEAU_CONDITION"."DATE_PRESTATION" is 'Jour de la prestation. La règle conventionnelle applicable est celle en vigueur ce jour-là, pas celle d''aujourd''hui.';
comment on column "CRENEAU_CONDITION"."HEURE_DEBUT" is 'Heure de début d''exposition. Avec heure_fin, donne la durée qui sert au seuil et à la conversion en montant.';
comment on column "CRENEAU_CONDITION"."HEURE_FIN" is 'Heure de fin d''exposition. Un créneau ne franchit pas minuit : une exposition de nuit se saisit en deux créneaux.';
comment on column "CRENEAU_CONDITION"."MINUTES" is 'Durée exposée, calculée par la base. Un créneau qui franchit minuit est compté correctement.';
comment on column "CRENEAU_CONDITION"."CONSTATE_PAR" is 'Compte ayant constaté la condition. Une prime de pénibilité repose sur un constat : il a un auteur.';
comment on column "CRENEAU_CONDITION"."NOTE" is 'Circonstances du constat. Utile en cas de contestation, jamais utilisée par le calcul.';
comment on column "CRENEAU_CONDITION"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "CRENEAU_CONDITION"."DELETED_AT" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "CRENEAU_CONDITION"."DELETED_BY" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "DATA_ACCESS_LOG" is 'Journal des consultations de données personnelles. Complète audit_log, qui ne voit que les écritures : ici sont tracés les accès en LECTURE aux données sensibles, les déchiffrements et les téléchargements de pièces. Répond aux questions qui / quoi / quand / d''où pour une personne donnée.';
comment on column "DATA_ACCESS_LOG"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DATA_ACCESS_LOG"."OCCURRED_AT" is 'Horodatage de la LECTURE. Ce journal répond au « quand » de l''article 15 du RGPD : à quel moment les données d''une personne ont été consultées.';
comment on column "DATA_ACCESS_LOG"."ACTOR_ID" is 'Compte ayant lu. Répond au « par qui ». Renseigné par le serveur à partir de la session, jamais déclaré par l''appelant.';
comment on column "DATA_ACCESS_LOG"."ACTOR_LABEL" is 'Nom de l''auteur figé au moment de l''accès : la trace reste lisible après suppression du compte.';
comment on column "DATA_ACCESS_LOG"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DATA_ACCESS_LOG"."SUBJECT_EMPLOYEE_ID" is 'La personne DONT les données ont été vues — à ne pas confondre avec actor_id, qui est celle qui les a vues.';
comment on column "DATA_ACCESS_LOG"."ENTITY_TABLE" is 'Table lue. Répond au « quoi », avec la ligne visée et les colonnes effectivement renvoyées.';
comment on column "DATA_ACCESS_LOG"."ENTITY_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "DATA_ACCESS_LOG"."ACTION" is 'READ consultation, DECRYPT déchiffrement d''une donnée sensible, EXPORT extraction, DOWNLOAD téléchargement d''une pièce.';
comment on column "DATA_ACCESS_LOG"."SCOPE" is 'Ce qui a été vu, en clair : « matricule national, IBAN », « dossier complet ». Jamais la valeur elle-même.';
comment on column "DATA_ACCESS_LOG"."ROW_COUNT" is 'Nombre de lignes effectivement renvoyées à l''appelant. Une consultation qui ne renvoie rien reste une consultation et se journalise.';
comment on column "DATA_ACCESS_LOG"."SOURCE_IP" is 'Adresse IP d''origine, lue dans les en-têtes transmis par la passerelle. Répond au « d''où ».';
comment on column "DATA_ACCESS_LOG"."USER_AGENT" is 'Agent déclaré par le client. Indicatif seulement : un agent se falsifie, il complète l''IP sans la remplacer.';
comment on column "DATA_ACCESS_LOG"."REQUEST_ID" is 'Identifiant de la requête, pour rapprocher une ligne de ce journal des traces de la passerelle lors d''une investigation.';
comment on column "DATA_ACCESS_LOG"."IS_AUTONOMOUS" is 'Vrai si la trace a été écrite hors de la transaction appelante, et survit donc à son annulation. Faux si dblink n''était pas configuré : la trace est alors aussi fragile que l''opération qu''elle décrit.';
comment on table "DEPARTMENTS" is 'Service ou établissement d''une société. Porte un planning et, le cas échéant, sa propre convention collective.';
comment on column "DEPARTMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DEPARTMENTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DEPARTMENTS"."NAME" is 'Nom du service. Sert au périmètre de dispatching et à la résolution conventionnelle, qui peut se faire par service.';
comment on column "DEPARTMENTS"."MIN_EVENING_COVERAGE" is 'Effectif minimal exigé en soirée. Contrainte d''exploitation, vérifiée à la validation d''un planning.';
comment on table "DOCUMENT_TYPES" is 'Catalogue des pièces attendues d''un salarié ou d''un contrat, avec leur durée de validité et le préavis d''alerte avant échéance.';
comment on column "DOCUMENT_TYPES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DOCUMENT_TYPES"."CODE" is 'Code du type de document, stable, utilisé par le moteur de conformité pour vérifier qu''une pièce obligatoire est présente.';
comment on column "DOCUMENT_TYPES"."LABEL" is 'Libellé du type de document à l''écran.';
comment on column "DOCUMENT_TYPES"."STAGE" is 'Moment du cycle de vie où la pièce est attendue : embauche, cours de contrat, ou fin de contrat.';
comment on column "DOCUMENT_TYPES"."VALIDITY_MONTHS" is 'Durée de validité en mois. Nul pour une pièce qui ne périme pas.';
comment on column "DOCUMENT_TYPES"."IS_MANDATORY" is 'Vrai si l''absence de la pièce constitue un manquement, et non un simple oubli.';
comment on column "DOCUMENT_TYPES"."APPLIES_TO_RESIDENCY" is 'Statuts de résidence concernés : une autorisation de travail ne vise pas un résident.';
comment on column "DOCUMENT_TYPES"."ALERT_DAYS_BEFORE" is 'Délai d''anticipation de l''alerte avant expiration.';
comment on column "DOCUMENT_TYPES"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "DOCUMENT_TYPES"."NOTE" is 'Fondement de l''obligation et durée de conservation attendue.';
comment on table "DOCUMENTS" is 'Pièces déposées, rattachées à un salarié, à un contrat ou à une société. Le fichier vit dans le stockage ; cette table porte les métadonnées et la durée de conservation.';
comment on column "DOCUMENTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "DOCUMENTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "DOCUMENTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "DOCUMENTS"."ENTITY_TABLE" is 'Table de l''objet rattaché, lorsque la pièce ne vise pas directement un salarié.';
comment on column "DOCUMENTS"."ENTITY_ID" is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column "DOCUMENTS"."NAME" is 'Nom du document tel que présenté à l''utilisateur. Distinct du nom du fichier stocké.';
comment on column "DOCUMENTS"."STORAGE_PATH" is 'Chemin dans le bucket de stockage. L''accès au fichier obéit aux mêmes règles que la ligne.';
comment on column "DOCUMENTS"."MIME_TYPE" is 'Type MIME déclaré à l''envoi. Sert à choisir la visionneuse ; il ne remplace pas un contrôle du contenu.';
comment on column "DOCUMENTS"."SIZE_BYTES" is 'Taille du fichier en octets, pour les quotas et l''affichage.';
comment on column "DOCUMENTS"."RETENTION_UNTIL" is 'Date au-delà de laquelle la pièce ne doit plus être conservée (RGPD, limitation de conservation).';
comment on column "DOCUMENTS"."IS_SENSITIVE" is 'Vrai pour une pièce de catégorie particulière (santé, handicap) : accès et conservation restreints.';
comment on column "DOCUMENTS"."UPLOADED_BY" is 'Compte ayant déposé le document.';
comment on column "DOCUMENTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "DOCUMENTS"."DOCUMENT_TYPE_ID" is 'Type de document, parmi document_types. Détermine la durée de conservation et le caractère obligatoire de la pièce.';
comment on column "DOCUMENTS"."ISSUED_ON" is 'Date de délivrance par l''autorité émettrice.';
comment on column "DOCUMENTS"."EXPIRES_ON" is 'Fin de validité de la pièce elle-même, qui déclenche l''alerte d''échéance.';
comment on column "DOCUMENTS"."DELIVERED_AT" is 'Date de remise au salarié, pour les pièces de fin de contrat.';
comment on table "EMPLOYEE_CHILDREN" is 'Enfants du salarié. Données de catégorie familiale, collectées pour les droits qui en dépendent ; le salarié peut refuser leur usage — voir privacy_opt_out.';
comment on column "EMPLOYEE_CHILDREN"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEE_CHILDREN"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEE_CHILDREN"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "EMPLOYEE_CHILDREN"."FIRST_NAME" is 'Prénom de l''enfant. Nul quand seul le nombre d''enfants importe pour un droit et que l''identité n''a pas à être connue — la minimisation vaut aussi ici.';
comment on column "EMPLOYEE_CHILDREN"."LAST_NAME" is 'Nom de l''enfant, s''il diffère de celui du parent.';
comment on column "EMPLOYEE_CHILDREN"."SEX" is 'Sexe de l''enfant, tel que déclaré. Aucun droit n''en dépend ; la colonne existe pour les documents administratifs qui l''exigent.';
comment on column "EMPLOYEE_CHILDREN"."BIRTH_DATE" is 'Date de naissance. Fonde les droits liés aux enfants — congé parental, boni, classe d''impôt — et le déclenchement de leur extinction.';
comment on column "EMPLOYEE_CHILDREN"."RELATIONSHIP" is 'Lien : enfant, enfant adopté, enfant du conjoint.';
comment on column "EMPLOYEE_CHILDREN"."IS_DEPENDENT" is 'Vrai si l''enfant est à charge au sens des droits ouverts.';
comment on column "EMPLOYEE_CHILDREN"."PRIVACY_OPT_OUT" is 'Vrai si le salarié refuse que l''enfant soit pris en compte. Le moteur cesse alors d''en tirer un droit, sans effacer la ligne.';
comment on column "EMPLOYEE_CHILDREN"."ADOPTION_DATE" is 'Date de l''adoption, qui ouvre ses propres droits, distincts de ceux liés à la naissance.';
comment on column "EMPLOYEE_CHILDREN"."NOTE" is 'Précisions utiles au dossier familial. Jamais de donnée de santé : celles-ci vont en fiche_sante, qui porte les restrictions adéquates.';
comment on column "EMPLOYEE_CHILDREN"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "EMPLOYEE_CHILDREN"."REFUS_PHOTOS_EVENEMENTS" is 'L''enfant ne doit pas apparaître sur les photos des événements familiaux de la société.';
comment on column "EMPLOYEE_CHILDREN"."INVITATION_EVENEMENTS" is 'L''enfant est convié aux événements de la société — Saint-Nicolas, journée des familles — avec ses parents.';
comment on column "EMPLOYEE_CHILDREN"."EN_SITUATION_HANDICAP" is 'Situation de handicap. DONNÉE DE SANTÉ : même régime d''accès que la fiche santé.';
comment on column "EMPLOYEE_CHILDREN"."TAUX_HANDICAP_PCT" is 'Taux de handicap reconnu, en pourcentage. Donnée de santé : accès restreint, lecture journalisée. Nul si aucun handicap n''est reconnu.';
comment on table "EMPLOYEE_DISABILITIES" is 'Reconnaissance de travailleur handicapé. Donnée de santé au sens du RGPD : accès restreint et finalité limitée aux droits qui en découlent.';
comment on column "EMPLOYEE_DISABILITIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEE_DISABILITIES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEE_DISABILITIES"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "EMPLOYEE_DISABILITIES"."RATE_PCT" is 'Taux d''incapacité reconnu.';
comment on column "EMPLOYEE_DISABILITIES"."RECOGNIZED_ON" is 'Date de la décision de reconnaissance.';
comment on column "EMPLOYEE_DISABILITIES"."AUTHORITY" is 'Autorité ayant prononcé la reconnaissance.';
comment on column "EMPLOYEE_DISABILITIES"."EXTRA_LEAVE_DAYS_OVERRIDE" is 'Jours de congé supplémentaires imposés par la décision, lorsqu''ils diffèrent du droit commun.';
comment on column "EMPLOYEE_DISABILITIES"."EVIDENCE_DOCUMENT_ID" is 'Pièce justificative, rangée dans documents avec le drapeau is_sensitive.';
comment on column "EMPLOYEE_DISABILITIES"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "EMPLOYEE_DISABILITIES"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "EMPLOYEE_DISABILITIES"."NOTE" is 'Éléments de contexte sur la reconnaissance du handicap. Donnée sensible au sens de l''article 9 du RGPD : l''accès en est restreint, et sa lecture journalisée.';
comment on column "EMPLOYEE_DISABILITIES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "EMPLOYEE_SANCTIONS" is 'Sanctions disciplinaires prononcées. Donnée personnelle sensible au sens du RGPD : accès restreint aux gestionnaires et à la personne concernée, conservation bornée par retention_until, suppression logique pour que le dossier reste cohérent après effacement.';
comment on column "EMPLOYEE_SANCTIONS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEE_SANCTIONS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEE_SANCTIONS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "EMPLOYEE_SANCTIONS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "EMPLOYEE_SANCTIONS"."SANCTION_TYPE" is 'Type de sanction prononcée, parmi sanction_types.';
comment on column "EMPLOYEE_SANCTIONS"."FACTS_ON" is 'Date des faits reprochés.';
comment on column "EMPLOYEE_SANCTIONS"."FACTS_KNOWN_ON" is 'Date à laquelle l''employeur en a eu connaissance. C''est elle, et non la date des faits, qui fait courir le délai de notification.';
comment on column "EMPLOYEE_SANCTIONS"."NOTIFIED_ON" is 'Date de notification au salarié. Une sanction non notifiée n''existe pas à son égard.';
comment on column "EMPLOYEE_SANCTIONS"."EFFECTIVE_FROM" is 'Premier jour d''effet, inclus. Nul pour une sanction sans effet daté, comme un avertissement.';
comment on column "EMPLOYEE_SANCTIONS"."EFFECTIVE_TO" is 'Dernier jour d''effet, INCLUS. Une mise à pied a une fin ; un avertissement n''en a pas.';
comment on column "EMPLOYEE_SANCTIONS"."REASON" is 'Faits reprochés, obligatoires. Une sanction sans motif écrit est contestable de ce seul fait.';
comment on column "EMPLOYEE_SANCTIONS"."EVIDENCE_DOCUMENT_ID" is 'Pièce au dossier : lettre de notification, compte rendu d''entretien. Ce qui prouve que la procédure a été suivie.';
comment on column "EMPLOYEE_SANCTIONS"."TERMINATION_ID" is 'Rupture correspondante, quand la sanction est un licenciement. Les deux lignes décrivent le même fait sous deux angles.';
comment on column "EMPLOYEE_SANCTIONS"."AMENDMENT_CONTRACT_ID" is 'Avenant produit par la sanction, quand elle modifie le contrat — rétrogradation, mutation.';
comment on column "EMPLOYEE_SANCTIONS"."EMPLOYEE_HEARD_ON" is 'Date à laquelle le salarié a été entendu. L''entretien préalable est requis au-delà d''un seuil d''effectif que le moteur lit dans le référentiel.';
comment on column "EMPLOYEE_SANCTIONS"."EMPLOYEE_RESPONSE" is 'Observations du salarié. Le droit de répondre fait partie de la procédure : la réponse se conserve, même si elle ne change pas la décision.';
comment on column "EMPLOYEE_SANCTIONS"."CONTESTED_ON" is 'Date de contestation par le salarié. Nulle tant qu''il n''a pas contesté.';
comment on column "EMPLOYEE_SANCTIONS"."CONTEST_OUTCOME" is 'Issue de la contestation : maintien, réduction, retrait. Une sanction retirée reste en base, avec son issue — l''effacer réécrirait l''histoire.';
comment on column "EMPLOYEE_SANCTIONS"."NOTE" is 'Suites internes : suivi, accompagnement, rappel à l''ordre ultérieur.';
comment on column "EMPLOYEE_SANCTIONS"."RETENTION_UNTIL" is 'Date au-delà de laquelle la sanction ne doit plus être conservée. Un dossier disciplinaire ne se garde pas indéfiniment.';
comment on column "EMPLOYEE_SANCTIONS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "EMPLOYEE_SANCTIONS"."CREATED_BY" is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column "EMPLOYEE_SANCTIONS"."UPDATED_AT" is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column "EMPLOYEE_SANCTIONS"."UPDATED_BY" is 'Compte auteur de la dernière modification. Sur une sanction, chaque retouche doit rester attribuable.';
comment on column "EMPLOYEE_SANCTIONS"."DELETED_AT" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "EMPLOYEE_SANCTIONS"."DELETED_BY" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "EMPLOYEE_STATUSES" is 'Statuts protégés : grossesse, suites de couches, mandat de délégué. Ils conditionnent la protection contre le licenciement.';
comment on column "EMPLOYEE_STATUSES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEE_STATUSES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEE_STATUSES"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "EMPLOYEE_STATUSES"."KIND" is 'Nature du statut, qui commande la protection applicable.';
comment on column "EMPLOYEE_STATUSES"."DECLARED_ON" is 'Date à laquelle l''employeur a été informé. C''est elle, et non le fait lui-même, qui déclenche la protection.';
comment on column "EMPLOYEE_STATUSES"."START_DATE" is 'Premier jour du statut, inclus. Un statut protégé — grossesse, délégation, congé parental — ouvre des protections qui commencent ce jour-là.';
comment on column "EMPLOYEE_STATUSES"."END_DATE" is 'Dernier jour du statut, INCLUS. Nulle tant que le statut court.';
comment on column "EMPLOYEE_STATUSES"."EXPECTED_BIRTH_DATE" is 'Date présumée de l''accouchement, qui borne la période protégée.';
comment on column "EMPLOYEE_STATUSES"."ACTUAL_BIRTH_DATE" is 'Date réelle, qui rectifie la borne une fois connue.';
comment on column "EMPLOYEE_STATUSES"."EVIDENCE_DOCUMENT_ID" is 'Pièce justifiant le statut : certificat, procès-verbal d''élection. Une protection invoquée sans pièce ne tient pas devant l''ITM.';
comment on column "EMPLOYEE_STATUSES"."HOURS_CREDIT_MONTHLY" is 'Crédit d''heures mensuel attaché au mandat, pour les délégués.';
comment on column "EMPLOYEE_STATUSES"."NOTE" is 'Précisions sur la portée du statut et sur ce qu''il interdit à l''employeur.';
comment on column "EMPLOYEE_STATUSES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "EMPLOYEE_TAX_CARDS" is 'Fiche de retenue d''impôt du salarié, datée. Donnée d''entrée du calcul brut vers net.';
comment on column "EMPLOYEE_TAX_CARDS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEE_TAX_CARDS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "EMPLOYEE_TAX_CARDS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEE_TAX_CARDS"."TAX_CLASS" is 'Classe d''impôt portée par la fiche.';
comment on column "EMPLOYEE_TAX_CARDS"."RATE" is 'Taux de retenue inscrit sur la fiche, lorsqu''un taux est fixé plutôt qu''un barème.';
comment on column "EMPLOYEE_TAX_CARDS"."MONTHLY_ALLOWANCE" is 'Abattement mensuel inscrit sur la fiche.';
comment on column "EMPLOYEE_TAX_CARDS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "EMPLOYEE_TAX_CARDS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "EMPLOYEE_TAX_CARDS"."CREDITS" is 'Crédits d''impôt portés par la fiche, structurés.';
comment on column "EMPLOYEE_TAX_CARDS"."COMMUTE_DISTANCE_KM" is 'Distance domicile-travail déclarée, base de l''abattement kilométrique.';
comment on column "EMPLOYEE_TAX_CARDS"."PROFESSIONAL_EXPENSES_MONTHLY" is 'Frais professionnels mensuels retenus.';
comment on column "EMPLOYEE_TAX_CARDS"."OTHER_DEDUCTIONS_MONTHLY" is 'Autres déductions mensuelles portées par la fiche.';
comment on column "EMPLOYEE_TAX_CARDS"."CARD_REFERENCE" is 'Référence de la fiche délivrée par l''administration.';
comment on column "EMPLOYEE_TAX_CARDS"."ISSUED_ON" is 'Date d''émission de la fiche de retenue par l''administration. Distincte de la période de validité : une fiche peut être émise après le début de la période qu''elle couvre.';
comment on table "EMPLOYEES" is 'Salarié. Les deux données les plus sensibles — matricule national et IBAN — ne sont pas stockées en clair : voir national_id_enc et iban_enc.';
comment on column "EMPLOYEES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EMPLOYEES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "EMPLOYEES"."USER_ID" is 'Compte applicatif du salarié, s''il accède à son espace personnel. Nul sinon.';
comment on column "EMPLOYEES"."DEPARTMENT_ID" is 'Service de rattachement, qui commande le planning et parfois la convention applicable.';
comment on column "EMPLOYEES"."FIRST_NAME" is 'Prénom usuel du salarié. Distinct de l''état civil complet : c''est ce qui s''affiche et s''imprime.';
comment on column "EMPLOYEES"."LAST_NAME" is 'Nom de famille. Sert au tri et à la recherche ; un index trigramme le rend cherchable en approximation.';
comment on column "EMPLOYEES"."BIRTH_DATE" is 'Date de naissance. Nulle tant qu''elle n''est pas connue — au stade de la candidature, par exemple. Sert au calcul des majorations liées à l''âge et au contrôle de cohérence du matricule.';
comment on column "EMPLOYEES"."RESIDENCY" is 'Résident ou frontalier, et de quel pays. Détermine les pièces exigées et le traitement fiscal.';
comment on column "EMPLOYEES"."QUALIFICATION" is 'Qualifié ou non qualifié : détermine le salaire social minimum applicable.';
comment on column "EMPLOYEES"."ADDRESS_LINE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "EMPLOYEES"."POSTAL_CODE" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "EMPLOYEES"."CITY" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "EMPLOYEES"."COUNTRY" is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU.';
comment on column "EMPLOYEES"."EMAIL" is 'Adresse personnelle du salarié. Distincte de celle du compte applicatif : tous les salariés n''ont pas de compte, et l''adresse de contact survit à la fin du contrat.';
comment on column "EMPLOYEES"."PHONE" is 'Téléphone de contact. Utilisé par le dispatching ; l''accès en est restreint comme toute donnée de contact personnel.';
comment on column "EMPLOYEES"."NATIONAL_ID_ENC" is 'Matricule national CHIFFRÉ (pgcrypto). Ne jamais lire directement : fn_employee_sensitive contrôle l''accès et déchiffre.';
comment on column "EMPLOYEES"."IBAN_ENC" is 'IBAN CHIFFRÉ. Même règle d''accès que le matricule.';
comment on column "EMPLOYEES"."NATIONAL_ID_HINT" is 'Fragment non identifiant du matricule, affichable pour reconnaître une fiche sans exposer la donnée.';
comment on column "EMPLOYEES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "EMPLOYEES"."SEX" is 'Sexe déclaré par le salarié, librement. Modifiable par lui depuis son espace. À ne pas confondre avec sexe_legal, qui est dérivé et non déclaratif. Sera renommé sexe_declare lors du passage au français.';
comment on column "EMPLOYEES"."CAREER_START_DATE" is 'Début de carrière professionnelle, distinct de l''entrée dans la société. Sert à l''acquisition de la qualification par l''ancienneté.';
comment on column "EMPLOYEES"."PROFESSION" is 'Profession déclarée, distincte de l''intitulé de poste porté par le contrat.';
comment on column "EMPLOYEES"."IS_MANAGEMENT" is 'Vrai pour le personnel de direction, exclu de certains droits collectifs.';
comment on column "EMPLOYEES"."SEXE_LEGAL" is 'Sexe juridique, DÉRIVÉ du matricule national : parité du numéro d''ordre (position 11). Recalculé à chaque écriture — toute valeur soumise est ignorée, la dérivation fait foi. Nul tant qu''aucun matricule n''est enregistré. Le salarié y a accès (RGPD art. 15) mais ne peut pas le modifier.';
comment on column "EMPLOYEES"."REFUS_PHOTOS_SOCIETE" is 'Le salarié refuse d''apparaître sur les photos de la société. Consentement au sens du RGPD : révocable à tout moment, et sans justification à fournir.';
comment on column "EMPLOYEES"."SOUHAITE_CONFIDENTIALITE" is 'Le salarié souhaite ne pas apparaître — annuaire, trombinoscope, communications. Distinct du droit à l''effacement, qui porte sur la donnée elle-même.';
comment on table "EXPECTED_PARAMETERS" is 'Clés de legal_parameters que le moteur lit. Sert à fn_referential_gaps pour signaler une clé attendue dont aucune version n''est chargée. Ne porte aucune valeur légale.';
comment on column "EXPECTED_PARAMETERS"."PARAM_KEY" is 'Clé d''un paramètre que le moteur attend. Sans cette table, fn_referential_gaps ne voyait pas les clés entièrement absentes : elle ne pouvait signaler que les périodes trouées.';
comment on column "EXPECTED_PARAMETERS"."READ_BY" is 'Fonction(s) du moteur qui lisent la clé, relevées dans le code des migrations.';
comment on column "EXPECTED_PARAMETERS"."NOTE" is 'À quoi sert le paramètre et ce qui se casse en son absence. Ce qui permet de hiérarchiser les trous à combler.';
comment on table "EXPORT_LOG" is 'Registre des exports de portabilité. Trace qui a exporté quoi, quand, et pour quel volume — pièce de conformité au droit d''accès et à la portabilité (RGPD art. 15 et 20).';
comment on column "EXPORT_LOG"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "EXPORT_LOG"."ORGANIZATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "EXPORT_LOG"."REQUESTED_BY" is 'Compte ayant demandé l''export. Un export de données personnelles est un traitement : il a un demandeur nommé.';
comment on column "EXPORT_LOG"."SUBJECT_KIND" is 'Nature du sujet exporté : self, employee, company, organization ou referential.';
comment on column "EXPORT_LOG"."SUBJECT_ID" is 'Ligne concernée par l''export, dans la table que désigne subject_kind. Nulle pour un export qui ne vise pas une ligne unique, comme le référentiel.';
comment on column "EXPORT_LOG"."ROW_COUNT" is 'Nombre d''objets contenus dans l''export, à des fins de contrôle de volume.';
comment on column "EXPORT_LOG"."BYTE_SIZE" is 'Taille de l''enveloppe produite, en octets.';
comment on column "EXPORT_LOG"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "EXPORT_LOG"."SOURCE_IP" is 'Adresse d''origine de la demande d''export.';
comment on column "EXPORT_LOG"."USER_AGENT" is 'Agent utilisateur de l''appelant.';
comment on column "EXPORT_LOG"."REQUEST_ID" is 'Identifiant de requête, pour recoupement.';
comment on table "FICHE_SANTE" is 'Fiche santé d''un salarié ou d''un de ses enfants. DONNÉE DE SANTÉ au sens de l''article 9 du RGPD : accès réservé à la personne, à la médecine du travail et aux RH d''urgence. Le dispatching n''y accède jamais — il lit les indicateurs dérivés.';
comment on column "FICHE_SANTE"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "FICHE_SANTE"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "FICHE_SANTE"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "FICHE_SANTE"."ENFANT_ID" is 'Enfant concerné quand la fiche porte sur un enfant et non sur le salarié. Exclusif de la fiche du salarié : une ligne concerne l''un ou l''autre.';
comment on column "FICHE_SANTE"."ALLERGIES" is 'Donnée brute. Ne jamais exposer au planning : c''est l''indicateur dérivé qui circule.';
comment on column "FICHE_SANTE"."PATHOLOGIES" is 'Pathologies déclarées. Donnée de santé au sens de l''article 9 du RGPD, sous le régime d''accès le plus strict : le dispatching n''y a jamais accès, il ne voit que des indicateurs dérivés et anonymisés.';
comment on column "FICHE_SANTE"."MEDECIN_TRAITANT" is 'Médecin traitant, pour le cas d''urgence. Donnée de santé.';
comment on column "FICHE_SANTE"."MEDECIN_TELEPHONE" is 'Téléphone du médecin traitant, appelable en urgence.';
comment on column "FICHE_SANTE"."GROUPE_SANGUIN" is 'Groupe sanguin déclaré. Donnée de santé, transmise aux secours et à personne d''autre.';
comment on column "FICHE_SANTE"."NOTE" is 'Consignes de prise en charge : allergies et conduite à tenir, traitement d''urgence disponible sur la personne — adrénaline pour une allergie aux piqûres, antihistaminique, mèche de cautérisation. C''est ce que les secours doivent savoir en arrivant.';
comment on column "FICHE_SANTE"."MAJ_LE" is 'Date de dernière mise à jour de la fiche. Une consigne de secours périmée est dangereuse : l''ancienneté de la fiche doit être visible.';
comment on column "FICHE_SANTE"."MAJ_PAR" is 'Compte ayant mis la fiche à jour. Sur une donnée de santé, toute écriture est attribuable et journalisée.';
comment on column "FICHE_SANTE"."DELETED_AT" is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column "FICHE_SANTE"."DELETED_BY" is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table "HEADCOUNT_SNAPSHOTS" is 'Effectif mensuel figé. Sert au calcul de la moyenne sur douze mois, qui déclenche les obligations de seuil (délégation, travailleurs handicapés).';
comment on column "HEADCOUNT_SNAPSHOTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "HEADCOUNT_SNAPSHOTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "HEADCOUNT_SNAPSHOTS"."MONTH" is 'Premier jour du mois observé.';
comment on column "HEADCOUNT_SNAPSHOTS"."HEADCOUNT" is 'Effectif en équivalents temps plein, d''où le type décimal.';
comment on table "INTERIM_AGENCIES" is 'Agence de travail intérimaire, employeur juridique d''un salarié en mission chez une société utilisatrice.';
comment on column "INTERIM_AGENCIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "INTERIM_AGENCIES"."ORGANIZATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "INTERIM_AGENCIES"."NAME" is 'Raison sociale de l''agence d''intérim, telle qu''elle figure au contrat de mise à disposition.';
comment on column "INTERIM_AGENCIES"."CCSS_MATRICULE" is 'Matricule CCSS de l''agence. C''est elle qui déclare le salarié, pas l''entreprise utilisatrice.';
comment on column "INTERIM_AGENCIES"."RCS_NUMBER" is 'Numéro au registre de commerce. Permet de vérifier qu''une agence est autorisée avant de lui confier une mission.';
comment on column "INTERIM_AGENCIES"."ADDRESS_LINE" is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column "INTERIM_AGENCIES"."POSTAL_CODE" is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column "INTERIM_AGENCIES"."CITY" is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column "INTERIM_AGENCIES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "LEGAL_PARAMETERS" is 'Le référentiel. Tout seuil, taux ou durée légale du droit du travail luxembourgeois vit ici, jamais dans le code. Chaque valeur porte sa plage de validité, sa source et son article ; une contrainte d''exclusion GiST interdit deux versions qui se chevauchent pour une même clé.';
comment on column "LEGAL_PARAMETERS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "LEGAL_PARAMETERS"."FAMILY" is 'Famille du paramètre : elle regroupe les clés par domaine et guide la détection des trous du référentiel.';
comment on column "LEGAL_PARAMETERS"."PARAM_KEY" is 'Clé stable du paramètre. C''est elle que le moteur interroge, jamais l''identifiant technique.';
comment on column "LEGAL_PARAMETERS"."LABEL" is 'Intitulé du paramètre en français, pour les écrans de référentiel. Le code machine est param_key.';
comment on column "LEGAL_PARAMETERS"."VALUE_NUM" is 'Valeur numérique. Une seule des trois colonnes value_* est renseignée.';
comment on column "LEGAL_PARAMETERS"."VALUE_TEXT" is 'Valeur textuelle, pour un paramètre qui n''est pas un nombre.';
comment on column "LEGAL_PARAMETERS"."VALUE_JSON" is 'Valeur structurée, pour un barème ou une table à plusieurs entrées.';
comment on column "LEGAL_PARAMETERS"."UNIT" is 'Unité de la valeur (EUR, heures, jours, pourcentage...) — sans elle un nombre ne veut rien dire.';
comment on column "LEGAL_PARAMETERS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "LEGAL_PARAMETERS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "LEGAL_PARAMETERS"."INDEX_REF" is 'Cote d''application de l''indice des prix au moment de la valeur, pour les montants indexés.';
comment on column "LEGAL_PARAMETERS"."SOURCE" is 'Origine publique de la valeur (Mémorial, STATEC, CCSS...). Obligatoire : un paramètre sans source ne doit pas exister.';
comment on column "LEGAL_PARAMETERS"."LEGAL_REF" is 'Article du Code du travail ou du texte qui fonde la valeur. C''est lui que les alertes citent à l''utilisateur.';
comment on column "LEGAL_PARAMETERS"."NOTE" is 'Précisions d''interprétation : ce que la valeur recouvre exactement, et ce qu''elle ne recouvre pas.';
comment on column "LEGAL_PARAMETERS"."ENTERED_BY" is 'Auteur de la saisie.';
comment on column "LEGAL_PARAMETERS"."ENTERED_AT" is 'Date de saisie de la valeur dans LuxRH. Distincte de sa date d''entrée en vigueur : une valeur peut être saisie avec retard, ou par anticipation.';
comment on column "LEGAL_PARAMETERS"."VALIDATED_BY" is 'Relecteur ayant validé la version. Nul tant que la valeur n''a pas été contrôlée.';
comment on column "LEGAL_PARAMETERS"."VALIDATED_AT" is 'Date de validation par un second regard. Nulle tant que la valeur n''a pas été relue — une valeur légale non validée reste utilisable, mais elle est signalée.';
comment on column "LEGAL_PARAMETERS"."DERIVED_FROM_KEY" is 'Clé du paramètre dont celui-ci se déduit. La dérivation sert de contrôle de cohérence, pas de source.';
comment on column "LEGAL_PARAMETERS"."DERIVED_FACTOR" is 'Facteur appliqué au paramètre d''origine pour obtenir celui-ci.';
comment on column "LEGAL_PARAMETERS"."DERIVATION_TOLERANCE" is 'Écart admis entre la valeur saisie et la valeur dérivée avant signalement d''une incohérence.';
comment on table "MEAL_VOUCHER_GRANTS" is 'Attribution de chèques-repas sur une période. La valeur faciale et la participation salariale sont contrôlées contre les limites du référentiel.';
comment on column "MEAL_VOUCHER_GRANTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "MEAL_VOUCHER_GRANTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "MEAL_VOUCHER_GRANTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "MEAL_VOUCHER_GRANTS"."PERIOD_START" is 'Premier jour de la période d''attribution, inclus.';
comment on column "MEAL_VOUCHER_GRANTS"."PERIOD_END" is 'Dernier jour de la période, INCLUS.';
comment on column "MEAL_VOUCHER_GRANTS"."VOUCHER_COUNT" is 'Nombre de chèques attribués sur la période.';
comment on column "MEAL_VOUCHER_GRANTS"."FACE_VALUE" is 'Valeur faciale du chèque.';
comment on column "MEAL_VOUCHER_GRANTS"."EMPLOYEE_SHARE" is 'Part supportée par le salarié : c''est elle qui conditionne le régime fiscal de l''avantage.';
comment on column "MEAL_VOUCHER_GRANTS"."GRANTED_ON" is 'Date de remise effective des titres. Distincte de la période qu''ils couvrent.';
comment on column "MEAL_VOUCHER_GRANTS"."NOTE" is 'Précisions sur le calcul du nombre de titres, notamment les jours d''absence déduits.';
comment on column "MEAL_VOUCHER_GRANTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "ORGANIZATIONS" is 'Fiduciaire ou entreprise unique. Racine de l''isolation : toute donnée appartient, directement ou par sa société, à une organisation.';
comment on column "ORGANIZATIONS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "ORGANIZATIONS"."NAME" is 'Raison sociale de la fiduciaire ou de l''entreprise.';
comment on column "ORGANIZATIONS"."KIND" is 'Distingue une fiduciaire gérant plusieurs sociétés clientes d''une entreprise gérant la sienne.';
comment on column "ORGANIZATIONS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "OVERTIME_REQUESTS" is 'Demande d''heures supplémentaires. Elle exige un double accord : validation RH et acceptation du salarié.';
comment on column "OVERTIME_REQUESTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "OVERTIME_REQUESTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "OVERTIME_REQUESTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "OVERTIME_REQUESTS"."SCHEDULE_ID" is 'Planning auquel la demande se rattache, s''il y en a un.';
comment on column "OVERTIME_REQUESTS"."PERIOD_START" is 'Premier jour de la période couverte par la demande, inclus.';
comment on column "OVERTIME_REQUESTS"."PERIOD_END" is 'Dernier jour de la période, INCLUS.';
comment on column "OVERTIME_REQUESTS"."HOURS" is 'Nombre d''heures supplémentaires demandées sur la période.';
comment on column "OVERTIME_REQUESTS"."REASON" is 'Motif du recours aux heures supplémentaires, obligatoire. L''ITM peut le demander : les heures supplémentaires ne sont pas de droit.';
comment on column "OVERTIME_REQUESTS"."STATUS" is 'État de la demande. hr_approved ne suffit pas : tant que le salarié n''a pas accepté, les heures ne sont pas couvertes.';
comment on column "OVERTIME_REQUESTS"."REQUESTED_BY" is 'Compte à l''origine de la demande, généralement l''employeur.';
comment on column "OVERTIME_REQUESTS"."REQUESTED_AT" is 'Horodatage du dépôt. Le délai de notification se compte à partir de là.';
comment on column "OVERTIME_REQUESTS"."HR_VALIDATED_BY" is 'Compte ayant validé côté ressources humaines, avant transmission éventuelle à l''ITM.';
comment on column "OVERTIME_REQUESTS"."HR_VALIDATED_AT" is 'Horodatage de la validation RH.';
comment on column "OVERTIME_REQUESTS"."EMPLOYEE_ACCEPTED_AT" is 'Horodatage de l''acceptation par le salarié.';
comment on column "OVERTIME_REQUESTS"."REJECTED_REASON" is 'Motif du refus, restitué à l''auteur de la demande.';
comment on column "OVERTIME_REQUESTS"."COMPENSATION" is 'Mode de compensation retenu : repos compensateur ou paiement majoré.';
comment on column "OVERTIME_REQUESTS"."NOTE" is 'Précisions sur les circonstances ou sur la compensation retenue.';
comment on table "PERSONNE_INDICATEUR_SECOURS" is 'Indicateurs de secours portés par une personne. Dérivés de la fiche santé par la médecine du travail : ils circulent là où la donnée brute ne va pas. C''est ce qui permet au dispatching d''écarter une affectation sans savoir pourquoi.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."ENFANT_ID" is 'Enfant concerné quand l''indicateur porte sur un enfant. Exclusif de la personne salariée.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."INDICATEUR" is 'Indicateur de secours, parmi ref_indicateur_secours. C''est la forme ANONYMISÉE de l''information médicale : un booléen dérivé, sans diagnostic. Le dispatching voit l''indicateur, jamais la pathologie qui le fonde.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."PRECISION_LIEU" is 'Précision d''affectation quand l''indicateur en appelle une — un type de lieu, un environnement. Jamais une pathologie.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."DEBUT_VALIDITE" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."FIN_VALIDITE" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."POSE_PAR" is 'Compte ayant posé l''indicateur, à partir de la fiche de santé. La dérivation est un acte : elle a un auteur et une date.';
comment on column "PERSONNE_INDICATEUR_SECOURS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PREMIUMS" is 'Primes versées, dont les primes participatives soumises à un double plafond : enveloppe société et plafond individuel.';
comment on column "PREMIUMS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PREMIUMS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "PREMIUMS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "PREMIUMS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "PREMIUMS"."TERMINATION_ID" is 'Rupture à laquelle la prime se rattache, pour une indemnité de départ.';
comment on column "PREMIUMS"."KIND" is 'Nature de la prime. Détermine son régime fiscal et social, et le plafond légal qui s''y applique le cas échéant.';
comment on column "PREMIUMS"."LABEL" is 'Libellé de la prime sur le bulletin.';
comment on column "PREMIUMS"."AMOUNT" is 'Montant en euros pour la période. Le plafond d''exonération éventuel est vérifié par le moteur et non par une contrainte : il est daté.';
comment on column "PREMIUMS"."GRANTED_ON" is 'Date d''attribution.';
comment on column "PREMIUMS"."FISCAL_YEAR" is 'Exercice d''imputation, qui détermine l''enveloppe et les plafonds applicables.';
comment on column "PREMIUMS"."IS_TAXABLE" is 'Vrai si la prime entre dans l''assiette imposable, une fois le plafond d''exonération dépassé.';
comment on column "PREMIUMS"."IS_CONTRIBUTORY" is 'Vrai si la prime entre dans l''assiette des cotisations. Distinct du régime fiscal.';
comment on column "PREMIUMS"."EXEMPT_PCT" is 'Fraction exonérée de la prime, selon son régime.';
comment on column "PREMIUMS"."NOTE" is 'Fondement de la prime et calcul retenu. Une prime sans justification écrite se conteste mal.';
comment on column "PREMIUMS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PROBATION_EXTENSIONS" is 'Prolongation d''une période d''essai, suspendue par une absence. Trace la durée ajoutée et son motif.';
comment on column "PROBATION_EXTENSIONS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PROBATION_EXTENSIONS"."CONTRACT_ID" is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column "PROBATION_EXTENSIONS"."FROM_DATE" is 'Premier jour de la prolongation d''essai, inclus.';
comment on column "PROBATION_EXTENSIONS"."TO_DATE" is 'Dernier jour de la prolongation, INCLUS. La durée totale d''essai reste plafonnée par la loi et par la convention : le moteur vérifie le cumul, pas seulement cette ligne.';
comment on column "PROBATION_EXTENSIONS"."DAYS_ADDED" is 'Jours ajoutés à l''essai du fait de la suspension.';
comment on column "PROBATION_EXTENSIONS"."REASON" is 'Motif de la prolongation. L''essai ne se prolonge pas par convenance : il faut une cause, généralement une suspension du contrat.';
comment on table "PROFILES" is 'Compte utilisateur applicatif, en miroir de auth.users. Alimenté par le déclencheur handle_new_user à l''inscription.';
comment on column "PROFILES"."ID" is 'Identique à auth.users.id : le profil ne porte pas d''identité propre.';
comment on column "PROFILES"."ORGANIZATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "PROFILES"."FULL_NAME" is 'Nom affiché de l''utilisateur dans l''interface. Doublon assumé de app_users.full_name : profiles est la vue applicative, app_users la table de comptes portable vers un autre SGBD.';
comment on column "PROFILES"."EMAIL" is 'Recopié depuis auth.users pour l''affichage. L''authentification ne s''appuie jamais sur cette copie.';
comment on column "PROFILES"."IS_ORG_ADMIN" is 'Administrateur de l''organisation : seul habilité à charger un référentiel et à exporter la fiduciaire entière.';
comment on column "PROFILES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "PUBLIC_HOLIDAYS" is 'Jours fériés légaux d''une année, complétés le cas échéant par les jours conventionnels.';
comment on column "PUBLIC_HOLIDAYS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "PUBLIC_HOLIDAYS"."YEAR" is 'Année du jour férié. Les fériés mobiles changent de date chaque année : une ligne par année.';
comment on column "PUBLIC_HOLIDAYS"."HOLIDAY_DATE" is 'Date du jour férié. Un férié travaillé ouvre une majoration dont le taux vient du référentiel daté.';
comment on column "PUBLIC_HOLIDAYS"."NAME" is 'Nom du jour férié, affiché sur les plannings.';
comment on column "PUBLIC_HOLIDAYS"."IS_MOBILE" is 'Vrai pour un férié dont la date suit le calendrier pascal, calculé par fn_easter_sunday.';
comment on column "PUBLIC_HOLIDAYS"."COLLECTIVE_AGREEMENT_ID" is 'Renseigné pour un jour chômé d''origine conventionnelle, nul pour un férié légal.';
comment on column "PUBLIC_HOLIDAYS"."IS_RECOVERABLE" is 'Vrai si le férié tombant un jour non ouvré ouvre droit à récupération.';
comment on column "PUBLIC_HOLIDAYS"."RECOVERY_REASON" is 'Motif de la récupération, cité dans l''alerte.';
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
comment on column "REF_NATURE_PRIME"."SOURCE_URL" is 'Lien vers la convention collective qui fixe le taux et les conditions. Une prime conventionnelle sans source n''est pas vérifiable.';
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
comment on table "REFERENCE_PERIODS" is 'Période de référence sur laquelle la durée de travail se calcule en moyenne. Définie par société ou par service.';
comment on column "REFERENCE_PERIODS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "REFERENCE_PERIODS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "REFERENCE_PERIODS"."DEPARTMENT_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column "REFERENCE_PERIODS"."LABEL" is 'Intitulé de la période de référence, pour l''identifier dans les écrans de suivi.';
comment on column "REFERENCE_PERIODS"."START_DATE" is 'Premier jour de la période de référence, inclus. C''est sur cette période que la durée moyenne de travail doit être respectée.';
comment on column "REFERENCE_PERIODS"."END_DATE" is 'Dernier jour de la période, INCLUS. Sa longueur maximale est fixée par le référentiel légal et par la convention, jamais écrite en dur.';
comment on column "REFERENCE_PERIODS"."MONTHS" is 'Longueur de la période. Une période plus longue qu''un mois suppose un fondement conventionnel.';
comment on table "SANCTION_CATEGORIES" is 'Les trois degrés de la sanction disciplinaire. Table de référence datée plutôt qu''énumération : un degré peut être renommé, ajouté ou retiré par DML, sans migration ni indisponibilité.';
comment on column "SANCTION_CATEGORIES"."CODE" is 'Code de la catégorie de sanction : mineure, lourde, rupture. Trois catégories, qui commandent la procédure exigée.';
comment on column "SANCTION_CATEGORIES"."LABEL" is 'Libellé de la catégorie à l''écran.';
comment on column "SANCTION_CATEGORIES"."RANK" is 'Gravité croissante. Sert à ordonner, jamais à décider : c''est le type de sanction qui porte les règles.';
comment on column "SANCTION_CATEGORIES"."DESCRIPTION" is 'Ce que la catégorie implique en matière de procédure, d''entretien préalable et de recours. C''est la colonne que lit un gestionnaire avant de choisir.';
comment on column "SANCTION_CATEGORIES"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "SANCTION_CATEGORIES"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "SANCTION_TYPES" is 'Catalogue des sanctions applicables, daté. Chaque type porte ses effets — présence, rémunération, contrat — et ce qu''il exige de l''employeur. Le moteur lit ces drapeaux ; il ne les devine pas.';
comment on column "SANCTION_TYPES"."CODE" is 'Code du type de sanction, stable. Huit types répartis dans les trois catégories.';
comment on column "SANCTION_TYPES"."CATEGORY_CODE" is 'Catégorie de rattachement, parmi sanction_categories. Détermine la procédure et les délais.';
comment on column "SANCTION_TYPES"."LABEL" is 'Libellé du type de sanction à l''écran.';
comment on column "SANCTION_TYPES"."DESCRIPTION" is 'Portée exacte de la sanction et conditions de validité. Une sanction lourde suppose notamment qu''elle figure dans les textes internes de l''entreprise.';
comment on column "SANCTION_TYPES"."AFFECTS_PRESENCE" is 'Vrai si la sanction suspend la présence du salarié — mise à pied. Le planning doit alors cesser de l''affecter sur la période.';
comment on column "SANCTION_TYPES"."AFFECTS_PAY" is 'Vrai si la rémunération est suspendue ou réduite. Distingue la mise à pied disciplinaire de la conservatoire, qui maintient le salaire.';
comment on column "SANCTION_TYPES"."REQUIRES_INTERNAL_RULES" is 'Vrai si la sanction n''est valable qu''à condition de figurer dans les textes internes de l''entreprise. C''est le cas de toutes les sanctions lourdes.';
comment on column "SANCTION_TYPES"."IS_CONTRACT_CHANGE" is 'Vrai si la sanction modifie le contrat. Elle passe alors par fn_amend_contract et, si la baisse de rémunération est substantielle, requiert l''''accord du salarié ou une procédure propre.';
comment on column "SANCTION_TYPES"."ENDS_CONTRACT" is 'Vrai si la sanction met fin au contrat. Déclenche le circuit de rupture : préavis, indemnités, documents de fin de contrat.';
comment on column "SANCTION_TYPES"."NEEDS_NOTICE" is 'Vrai si un préavis est dû, faux s''''il ne l''''est pas, nul si la question ne se pose pas. Le calcul du préavis lui-même reste à fn_notice_period.';
comment on column "SANCTION_TYPES"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "SANCTION_TYPES"."NOTE" is 'Références et précisions sur l''usage du type. Ce qui permet de vérifier qu''on applique la bonne sanction.';
comment on column "SANCTION_TYPES"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "SANCTION_TYPES"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table "SCHEDULES" is 'Planning hebdomadaire d''une société ou d''un service. Tant qu''il n''est pas publié, il n''est opposable à personne.';
comment on column "SCHEDULES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SCHEDULES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SCHEDULES"."DEPARTMENT_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column "SCHEDULES"."WEEK_START" is 'Lundi de la semaine couverte.';
comment on column "SCHEDULES"."LABEL" is 'Intitulé du planning, pour s''y retrouver entre plusieurs semaines ou équipes. Sans effet sur le calcul.';
comment on column "SCHEDULES"."STATUS" is 'Brouillon ou publié. La publication passe par fn_publish_schedule, qui refuse un planning non conforme.';
comment on column "SCHEDULES"."PUBLISHED_AT" is 'Horodatage de la publication, qui fait courir le délai de prévenance.';
comment on column "SCHEDULES"."PUBLISHED_BY" is 'Auteur de la publication.';
comment on column "SCHEDULES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "SHIFT_TEMPLATES" is 'Modèle de vacation réutilisable, pour éviter de ressaisir les horaires courants.';
comment on column "SHIFT_TEMPLATES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SHIFT_TEMPLATES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SHIFT_TEMPLATES"."NAME" is 'Nom du modèle de créneau, pour le réutiliser lors de la construction d''un planning.';
comment on column "SHIFT_TEMPLATES"."START_TIME" is 'Heure de début du modèle.';
comment on column "SHIFT_TEMPLATES"."END_TIME" is 'Heure de fin du modèle. Peut être antérieure à start_time : le créneau franchit alors minuit.';
comment on column "SHIFT_TEMPLATES"."BREAK_MINUTES" is 'Pause en minutes, déduite du temps de travail effectif. Le seuil légal au-delà duquel une pause est obligatoire vient du référentiel daté, jamais d''une valeur écrite ici.';
comment on column "SHIFT_TEMPLATES"."COLOR" is 'Couleur d''affichage dans le planning. Confort d''usage, sans effet métier.';
comment on column "SHIFT_TEMPLATES"."DEPARTMENT_ID" is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on table "SHIFTS" is 'Vacation planifiée : un salarié, une date, des horaires. C''est l''unité que le moteur contrôle contre les repos et les durées maximales.';
comment on column "SHIFTS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "SHIFTS"."SCHEDULE_ID" is 'Planning auquel le créneau appartient. Un créneau n''existe pas hors d''un planning : c''est le planning qui porte le statut brouillon ou publié.';
comment on column "SHIFTS"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "SHIFTS"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "SHIFTS"."SHIFT_DATE" is 'Jour du créneau. Un créneau qui déborde sur le lendemain porte la date de son début.';
comment on column "SHIFTS"."START_TIME" is 'Heure de début. Avec la durée, détermine les majorations de nuit, de dimanche et de jour férié.';
comment on column "SHIFTS"."END_TIME" is 'Heure de fin. Antérieure à start_time pour une vacation qui franchit minuit — fn_shift_end_ts résout le cas.';
comment on column "SHIFTS"."BREAK_MINUTES" is 'Pause de la vacation, déduite des heures travaillées.';
comment on column "SHIFTS"."LABEL" is 'Précision sur le créneau : chantier, tournée, remplacement. Affichée au salarié.';
comment on column "SHIFTS"."TEMPLATE_ID" is 'Modèle dont la vacation est issue, s''il y en a un.';
comment on column "SHIFTS"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column "SHIFTS"."CLIENT_SITE_ID" is 'Lieu d''exécution de la vacation. Nul signifie « au siège de la société » — c''est le cas courant, et c''est aussi la référence à laquelle un dépassement se mesure.';
comment on table "TAX_BRACKETS" is 'Barème de l''impôt sur les traitements et salaires, par classe et par périodicité. Table structurellement prête ; son chargement relève de la V2 brut vers net.';
comment on column "TAX_BRACKETS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TAX_BRACKETS"."TAX_CLASS" is 'Classe d''impôt à laquelle le barème s''applique. Le passage à la classe unique prévu pour 2027 se traduira par de nouvelles lignes datées, pas par une modification des anciennes.';
comment on column "TAX_BRACKETS"."PERIODICITY" is 'Périodicité du barème : mensuel, annuel. Un barème mensuel n''est pas le douzième d''un barème annuel.';
comment on column "TAX_BRACKETS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "TAX_BRACKETS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "TAX_BRACKETS"."BRACKET_MIN" is 'Borne basse de la tranche.';
comment on column "TAX_BRACKETS"."BRACKET_MAX" is 'Borne haute. Nul pour la dernière tranche.';
comment on column "TAX_BRACKETS"."BASE_TAX" is 'Impôt cumulé dû à la borne basse de la tranche.';
comment on column "TAX_BRACKETS"."RATE_OVER_MIN" is 'Taux appliqué à la fraction du revenu dépassant la borne basse.';
comment on column "TAX_BRACKETS"."SOURCE" is 'Publication d''origine du barème. Sans source, un barème ne se vérifie pas — et la règle 7 du projet interdit de l''inventer.';
comment on column "TAX_BRACKETS"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TAX_BRACKETS"."NOTE" is 'Précisions sur la tranche : arrondis, cas particuliers, articulation avec les crédits.';
comment on table "TAX_CREDITS" is 'Crédits d''impôt, avec leur plage de revenu et les classes auxquelles ils s''appliquent.';
comment on column "TAX_CREDITS"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TAX_CREDITS"."CODE" is 'Code du crédit d''impôt, stable, repris par le calcul de la retenue.';
comment on column "TAX_CREDITS"."LABEL" is 'Libellé du crédit tel qu''il apparaît sur le bulletin.';
comment on column "TAX_CREDITS"."APPLIES_TO_CLASSES" is 'Classes d''impôt ouvrant droit au crédit.';
comment on column "TAX_CREDITS"."INCOME_MIN" is 'Revenu à partir duquel le crédit est ouvert.';
comment on column "TAX_CREDITS"."INCOME_MAX" is 'Revenu au-delà duquel le crédit s''éteint.';
comment on column "TAX_CREDITS"."MONTHLY_AMOUNT" is 'Montant mensuel du crédit, en euros. Nul quand le crédit ne se traduit pas par un montant fixe.';
comment on column "TAX_CREDITS"."PRORATED_ON_HOURS" is 'Vrai si le crédit se réduit au prorata du temps de travail.';
comment on column "TAX_CREDITS"."VALID_FROM" is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column "TAX_CREDITS"."VALID_TO" is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column "TAX_CREDITS"."SOURCE" is 'Publication d''origine du montant. Obligatoire pour la même raison que sur tax_brackets.';
comment on column "TAX_CREDITS"."LEGAL_REF" is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column "TAX_CREDITS"."NOTE" is 'Conditions d''octroi et cumul avec les autres crédits.';
comment on table "TIME_ENTRIES" is 'Registre du temps réellement travaillé, distinct du planning. C''est lui qui fait foi pour les majorations et les heures supplémentaires.';
comment on column "TIME_ENTRIES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TIME_ENTRIES"."COMPANY_ID" is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column "TIME_ENTRIES"."EMPLOYEE_ID" is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column "TIME_ENTRIES"."ENTRY_DATE" is 'Jour du relevé. Un relevé par jour et par salarié : c''est la maille de tous les compteurs.';
comment on column "TIME_ENTRIES"."START_TIME" is 'Heure de début relevée. Nulle pour un relevé saisi en durée seule, sans horaires.';
comment on column "TIME_ENTRIES"."END_TIME" is 'Heure de fin relevée. Nulle dans le même cas que start_time — les deux vont ensemble.';
comment on column "TIME_ENTRIES"."BREAK_MINUTES" is 'Pause en minutes, déduite du temps de travail effectif de la journée.';
comment on column "TIME_ENTRIES"."WORKED_HOURS" is 'Heures effectivement travaillées, pause déduite.';
comment on column "TIME_ENTRIES"."PLANNED_HOURS" is 'Heures planifiées pour la même journée, pour mesurer l''écart.';
comment on column "TIME_ENTRIES"."SUNDAY_HOURS" is 'Part travaillée un dimanche, qui ouvre sa propre majoration.';
comment on column "TIME_ENTRIES"."HOLIDAY_HOURS" is 'Part travaillée un jour férié.';
comment on column "TIME_ENTRIES"."NIGHT_HOURS" is 'Part travaillée en période de nuit.';
comment on column "TIME_ENTRIES"."OVERTIME_HOURS" is 'Heures supplémentaires retenues sur la journée.';
comment on column "TIME_ENTRIES"."IS_VALIDATED" is 'Vrai une fois la journée validée. Une journée non validée ne nourrit aucun calcul définitif.';
comment on column "TIME_ENTRIES"."SOURCE" is 'Origine de la saisie : pointage, saisie manuelle, report du planning.';
comment on column "TIME_ENTRIES"."NOTE" is 'Circonstances du relevé : dépassement, incident, rattrapage. Ce qu''un contrôle voudra comprendre.';
comment on column "TIME_ENTRIES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "TRAVEL_DISTANCES" is 'Distances routières mises en cache. Une adresse n''est transmise au service tiers qu''au premier calcul d''un couple ; les plannings suivants lisent cette table.';
comment on column "TRAVEL_DISTANCES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "TRAVEL_DISTANCES"."ORIGIN_REF" is 'Référence de l''origine, sous la forme « employee:<uuid> », « company:<uuid> » ou « site:<uuid> ». Aucune adresse n''est recopiée ici.';
comment on column "TRAVEL_DISTANCES"."DESTINATION_REF" is 'Référence de la destination : site client, société, ou adresse saisie. Le trajet se calcule depuis une adresse du salarié vers cette destination.';
comment on column "TRAVEL_DISTANCES"."DISTANCE_KM" is 'Distance routière en kilomètres, telle que renvoyée par le service d''itinéraire. Ce n''est pas la distance à vol d''oiseau : c''est celle qui fonde l''indemnité.';
comment on column "TRAVEL_DISTANCES"."DURATION_MINUTES" is 'Durée estimée du trajet. Indicative : elle sert à construire les tournées, pas à rémunérer.';
comment on column "TRAVEL_DISTANCES"."SOURCE" is 'Origine de la mesure : nom du service consulté, ou « manuel » si la distance a été saisie. Une distance sans source ne doit pas servir à payer.';
comment on column "TRAVEL_DISTANCES"."COMPUTED_AT" is 'Date du calcul. Une adresse change ; une distance vieille de trois ans mérite d''être revérifiée.';
comment on column "TRAVEL_DISTANCES"."COMPUTED_BY" is 'Compte ayant déclenché le calcul. Un appel à un service externe se trace : il a un coût et il expose une adresse.';
comment on column "TRAVEL_DISTANCES"."NOTE" is 'Circonstances du calcul : date, service interrogé, correction manuelle éventuelle.';
comment on table "USER_ROLES" is 'Habilitations. Une ligne par couple utilisateur/périmètre ; c''est la table que lisent tous les prédicats RLS.';
comment on column "USER_ROLES"."ID" is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column "USER_ROLES"."USER_ID" is 'Compte auquel le rôle est attribué. Un compte peut porter plusieurs rôles ; c''est le plus permissif qui s''applique, et les politiques RLS lisent cette table, jamais une valeur transmise par le client.';
comment on column "USER_ROLES"."ORGANIZATION_ID" is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column "USER_ROLES"."COMPANY_ID" is 'Nul pour un rôle qui porte sur toute l''organisation. Renseigné pour un rôle limité à une société.';
comment on column "USER_ROLES"."ROLE" is 'Rôle applicatif. Le rôle employee restreint l''utilisateur à son propre dossier.';
comment on column "USER_ROLES"."CREATED_AT" is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table "REF_ABSENCE_CATEGORY" is 'Table de référence issue du type énuméré PostgreSQL absence_category.';
comment on table "REF_ABSENCE_STATUS" is 'Table de référence issue du type énuméré PostgreSQL absence_status.';
comment on table "REF_ALERT_STATE" is 'Table de référence issue du type énuméré PostgreSQL alert_state.';
comment on table "REF_APP_ROLE" is 'Table de référence issue du type énuméré PostgreSQL app_role.';
comment on table "REF_CBA_BLOCK" is 'Table de référence issue du type énuméré PostgreSQL cba_block.';
comment on table "REF_CBA_SCOPE" is 'Table de référence issue du type énuméré PostgreSQL cba_scope.';
comment on table "REF_CONTRACT_KIND" is 'Table de référence issue du type énuméré PostgreSQL contract_kind.';
comment on table "REF_CONTRACT_STATUS" is 'Table de référence issue du type énuméré PostgreSQL contract_status.';
comment on table "REF_DOCUMENT_STAGE" is 'Table de référence issue du type énuméré PostgreSQL document_stage.';
comment on table "REF_EMPLOYEE_STATUS_KIND" is 'Table de référence issue du type énuméré PostgreSQL employee_status_kind.';
comment on table "REF_ORG_KIND" is 'Table de référence issue du type énuméré PostgreSQL org_kind.';
comment on table "REF_PARAM_FAMILY" is 'Table de référence issue du type énuméré PostgreSQL param_family.';
comment on table "REF_PAY_COMPONENT_KIND" is 'Table de référence issue du type énuméré PostgreSQL pay_component_kind.';
comment on table "REF_QUALIFICATION_KIND" is 'Table de référence issue du type énuméré PostgreSQL qualification_kind.';
comment on table "REF_RESIDENCY_KIND" is 'Table de référence issue du type énuméré PostgreSQL residency_kind.';
comment on table "REF_SCHEDULE_STATUS" is 'Table de référence issue du type énuméré PostgreSQL schedule_status.';
comment on table "REF_SEVERITY_KIND" is 'Table de référence issue du type énuméré PostgreSQL severity_kind.';
comment on table "REF_SEX_KIND" is 'Table de référence issue du type énuméré PostgreSQL sex_kind.';
comment on table "REF_TAX_CLASS" is 'Table de référence issue du type énuméré PostgreSQL tax_class.';
comment on table "REF_TAX_PERIODICITY" is 'Table de référence issue du type énuméré PostgreSQL tax_periodicity.';

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

create or replace trigger absence_entitlements_no_overlap
  for insert or update on "ABSENCE_ENTITLEMENTS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "ABSENCE_ENTITLEMENTS"."ID"%type index by pls_integer;
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
             from "ABSENCE_ENTITLEMENTS" a
             join "ABSENCE_ENTITLEMENTS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."ABSENCE_TYPE_ID" = b."ABSENCE_TYPE_ID" or (a."ABSENCE_TYPE_ID" is null and b."ABSENCE_TYPE_ID" is null))
              and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
              and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur absence_entitlements : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end absence_entitlements_no_overlap;
/

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
              and (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null)) and (a."TYPE_ADRESSE" = b."TYPE_ADRESSE" or (a."TYPE_ADRESSE" is null and b."TYPE_ADRESSE" is null))
              and a."DEBUT_VALIDITE" < nvl(b."FIN_VALIDITE", date '9999-12-31')
              and nvl(a."FIN_VALIDITE", date '9999-12-31') > b."DEBUT_VALIDITE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur adresses_salarie : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end adresses_salarie_no_overlap;
/

create or replace trigger company_rate_periods_no_overlap
  for insert or update on "COMPANY_RATE_PERIODS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "COMPANY_RATE_PERIODS"."ID"%type index by pls_integer;
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
             from "COMPANY_RATE_PERIODS" a
             join "COMPANY_RATE_PERIODS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."COMPANY_ID" = b."COMPANY_ID" or (a."COMPANY_ID" is null and b."COMPANY_ID" is null))
              and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
              and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur company_rate_periods : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end company_rate_periods_no_overlap;
/

create or replace trigger contracts_no_overlap
  for insert or update on "CONTRACTS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "CONTRACTS"."ID"%type index by pls_integer;
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
             from "CONTRACTS" a
             join "CONTRACTS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
              and a."START_DATE" < nvl(b."END_DATE", date '9999-12-31')
              and nvl(a."END_DATE", date '9999-12-31') > b."START_DATE");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur contracts : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end contracts_no_overlap;
/

create or replace trigger employee_disabilities_no_overlap
  for insert or update on "EMPLOYEE_DISABILITIES"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "EMPLOYEE_DISABILITIES"."ID"%type index by pls_integer;
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
             from "EMPLOYEE_DISABILITIES" a
             join "EMPLOYEE_DISABILITIES" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
              and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
              and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur employee_disabilities : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end employee_disabilities_no_overlap;
/

create or replace trigger employee_tax_cards_no_overlap
  for insert or update on "EMPLOYEE_TAX_CARDS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "EMPLOYEE_TAX_CARDS"."ID"%type index by pls_integer;
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
             from "EMPLOYEE_TAX_CARDS" a
             join "EMPLOYEE_TAX_CARDS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
              and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
              and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur employee_tax_cards : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end employee_tax_cards_no_overlap;
/

create or replace trigger legal_parameters_no_overlap
  for insert or update on "LEGAL_PARAMETERS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "LEGAL_PARAMETERS"."ID"%type index by pls_integer;
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
             from "LEGAL_PARAMETERS" a
             join "LEGAL_PARAMETERS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."PARAM_KEY" = b."PARAM_KEY" or (a."PARAM_KEY" is null and b."PARAM_KEY" is null))
              and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
              and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur legal_parameters : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end legal_parameters_no_overlap;
/

create or replace trigger meal_voucher_grants_no_overlap
  for insert or update on "MEAL_VOUCHER_GRANTS"
  compound trigger

  -- Les identifiants écrits par l'instruction en cours, et eux seuls.
  type t_ids is table of "MEAL_VOUCHER_GRANTS"."ID"%type index by pls_integer;
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
             from "MEAL_VOUCHER_GRANTS" a
             join "MEAL_VOUCHER_GRANTS" b on b."ID" <> a."ID"
            where a."ID" = g_ids(i)
              and (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
              and a."PERIOD_START" < nvl(b."PERIOD_END", date '9999-12-31')
              and nvl(a."PERIOD_END", date '9999-12-31') > b."PERIOD_START");
        raise_application_error(-20001,
          'Deux periodes se recouvrent sur meal_voucher_grants : une date ne peut avoir qu''une valeur');
      exception
        when no_data_found then null;   -- aucun conflit sur cette ligne
      end;
    end loop;
  end after statement;

end meal_voucher_grants_no_overlap;
/


