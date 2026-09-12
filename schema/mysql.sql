-- Schéma LuxRH pour MYSQL, dérivé du catalogue PostgreSQL.
-- Généré par tools/emit_portable_schema.py — ne pas modifier à la main :
-- la base PostgreSQL fait foi, ce fichier la suit.
--
-- Écarts assumés : DATETIME ne conserve pas le fuseau (tout est écrit en UTC),
-- booléens en TINYINT(1), énumérations en tables de référence,
-- tableaux et jsonb en JSON. Les clés d'auteur pointent vers app_users.

-- ------------------------------------------------------------------
-- TABLES DE RÉFÉRENCE — à la place des types énumérés de PostgreSQL.
-- Chaque valeur porte sa période d'usage : on retire une valeur en la
-- datant, jamais en la supprimant, sinon l'historique devient illisible.
-- ------------------------------------------------------------------

create table `ref_absence_category` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_absence_category_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('annual_leave', 'annual_leave', 1);
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('sick', 'sick', 2);
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('extraordinary', 'extraordinary', 3);
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('public_holiday', 'public_holiday', 4);
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('unpaid', 'unpaid', 5);
insert into `ref_absence_category` (`code`, `label`, `sort_order`) values ('compensatory', 'compensatory', 6);

create table `ref_absence_status` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_absence_status_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_absence_status` (`code`, `label`, `sort_order`) values ('pending', 'pending', 1);
insert into `ref_absence_status` (`code`, `label`, `sort_order`) values ('approved', 'approved', 2);
insert into `ref_absence_status` (`code`, `label`, `sort_order`) values ('refused', 'refused', 3);
insert into `ref_absence_status` (`code`, `label`, `sort_order`) values ('cancelled', 'cancelled', 4);
insert into `ref_absence_status` (`code`, `label`, `sort_order`) values ('proposed', 'proposed', 5);

create table `ref_alert_state` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_alert_state_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_alert_state` (`code`, `label`, `sort_order`) values ('open', 'open', 1);
insert into `ref_alert_state` (`code`, `label`, `sort_order`) values ('handled', 'handled', 2);
insert into `ref_alert_state` (`code`, `label`, `sort_order`) values ('dismissed', 'dismissed', 3);

create table `ref_app_role` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_app_role_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('fiduciary_admin', 'fiduciary_admin', 1);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('manager', 'manager', 2);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('service_manager', 'service_manager', 3);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('employee', 'employee', 4);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('medecine_travail', 'medecine_travail', 5);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('rh_urgence', 'rh_urgence', 6);
insert into `ref_app_role` (`code`, `label`, `sort_order`) values ('dispatching', 'dispatching', 7);

create table `ref_cba_block` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_cba_block_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('salary_grid', 'salary_grid', 1);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('worktime', 'worktime', 2);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('leave', 'leave', 3);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('premiums', 'premiums', 4);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('surcharges', 'surcharges', 5);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('notice_probation', 'notice_probation', 6);
insert into `ref_cba_block` (`code`, `label`, `sort_order`) values ('custom_holidays', 'custom_holidays', 7);

create table `ref_cba_scope` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_cba_scope_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_cba_scope` (`code`, `label`, `sort_order`) values ('sector', 'sector', 1);
insert into `ref_cba_scope` (`code`, `label`, `sort_order`) values ('harassment', 'harassment', 2);
insert into `ref_cba_scope` (`code`, `label`, `sort_order`) values ('employee_category', 'employee_category', 3);
insert into `ref_cba_scope` (`code`, `label`, `sort_order`) values ('department', 'department', 4);
insert into `ref_cba_scope` (`code`, `label`, `sort_order`) values ('company', 'company', 5);

create table `ref_contract_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_contract_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_contract_kind` (`code`, `label`, `sort_order`) values ('cdi', 'cdi', 1);
insert into `ref_contract_kind` (`code`, `label`, `sort_order`) values ('cdd', 'cdd', 2);
insert into `ref_contract_kind` (`code`, `label`, `sort_order`) values ('seasonal', 'seasonal', 3);
insert into `ref_contract_kind` (`code`, `label`, `sort_order`) values ('apprenticeship', 'apprenticeship', 4);
insert into `ref_contract_kind` (`code`, `label`, `sort_order`) values ('interim', 'interim', 5);

create table `ref_contract_status` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_contract_status_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_contract_status` (`code`, `label`, `sort_order`) values ('draft', 'draft', 1);
insert into `ref_contract_status` (`code`, `label`, `sort_order`) values ('active', 'active', 2);
insert into `ref_contract_status` (`code`, `label`, `sort_order`) values ('ended', 'ended', 3);
insert into `ref_contract_status` (`code`, `label`, `sort_order`) values ('cancelled', 'cancelled', 4);

create table `ref_document_stage` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_document_stage_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_document_stage` (`code`, `label`, `sort_order`) values ('pre_hire', 'pre_hire', 1);
insert into `ref_document_stage` (`code`, `label`, `sort_order`) values ('during_contract', 'during_contract', 2);
insert into `ref_document_stage` (`code`, `label`, `sort_order`) values ('end_of_contract', 'end_of_contract', 3);

create table `ref_employee_status_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_employee_status_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('pregnancy', 'pregnancy', 1);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('maternity_leave', 'maternity_leave', 2);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('breastfeeding', 'breastfeeding', 3);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('parental_leave', 'parental_leave', 4);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('delegate', 'delegate', 5);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('safety_delegate', 'safety_delegate', 6);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('equality_delegate', 'equality_delegate', 7);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('reemployment_bonus', 'reemployment_bonus', 8);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('company_manager', 'company_manager', 9);
insert into `ref_employee_status_kind` (`code`, `label`, `sort_order`) values ('protected_other', 'protected_other', 10);

create table `ref_org_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_org_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_org_kind` (`code`, `label`, `sort_order`) values ('fiduciary', 'fiduciary', 1);
insert into `ref_org_kind` (`code`, `label`, `sort_order`) values ('company', 'company', 2);

create table `ref_param_family` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_param_family_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('social', 'social', 1);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('fiscal', 'fiscal', 2);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('worktime', 'worktime', 3);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('leave', 'leave', 4);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('contract', 'contract', 5);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('headcount', 'headcount', 6);
insert into `ref_param_family` (`code`, `label`, `sort_order`) values ('ccss', 'ccss', 7);

create table `ref_pay_component_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_pay_component_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_pay_component_kind` (`code`, `label`, `sort_order`) values ('fixed', 'fixed', 1);
insert into `ref_pay_component_kind` (`code`, `label`, `sort_order`) values ('variable', 'variable', 2);
insert into `ref_pay_component_kind` (`code`, `label`, `sort_order`) values ('benefit_in_kind', 'benefit_in_kind', 3);
insert into `ref_pay_component_kind` (`code`, `label`, `sort_order`) values ('premium', 'premium', 4);
insert into `ref_pay_component_kind` (`code`, `label`, `sort_order`) values ('expense', 'expense', 5);

create table `ref_qualification_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_qualification_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_qualification_kind` (`code`, `label`, `sort_order`) values ('qualified', 'qualified', 1);
insert into `ref_qualification_kind` (`code`, `label`, `sort_order`) values ('unqualified', 'unqualified', 2);

create table `ref_residency_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_residency_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('resident', 'resident', 1);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_fr', 'frontalier_fr', 2);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_be', 'frontalier_be', 3);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_de', 'frontalier_de', 4);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_fra', 'frontalier_fra', 5);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_bel', 'frontalier_bel', 6);
insert into `ref_residency_kind` (`code`, `label`, `sort_order`) values ('frontalier_deu', 'frontalier_deu', 7);

create table `ref_schedule_status` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_schedule_status_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_schedule_status` (`code`, `label`, `sort_order`) values ('draft', 'draft', 1);
insert into `ref_schedule_status` (`code`, `label`, `sort_order`) values ('published', 'published', 2);

create table `ref_severity_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_severity_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_severity_kind` (`code`, `label`, `sort_order`) values ('blocking', 'blocking', 1);
insert into `ref_severity_kind` (`code`, `label`, `sort_order`) values ('warning', 'warning', 2);
insert into `ref_severity_kind` (`code`, `label`, `sort_order`) values ('info', 'info', 3);
insert into `ref_severity_kind` (`code`, `label`, `sort_order`) values ('problem', 'problem', 4);

create table `ref_sex_kind` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_sex_kind_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_sex_kind` (`code`, `label`, `sort_order`) values ('male', 'male', 1);
insert into `ref_sex_kind` (`code`, `label`, `sort_order`) values ('female', 'female', 2);
insert into `ref_sex_kind` (`code`, `label`, `sort_order`) values ('unspecified', 'unspecified', 3);

create table `ref_tax_class` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_tax_class_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_tax_class` (`code`, `label`, `sort_order`) values ('1', '1', 1);
insert into `ref_tax_class` (`code`, `label`, `sort_order`) values ('1a', '1a', 2);
insert into `ref_tax_class` (`code`, `label`, `sort_order`) values ('2', '2', 3);

create table `ref_tax_periodicity` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_tax_periodicity_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_tax_periodicity` (`code`, `label`, `sort_order`) values ('monthly', 'monthly', 1);
insert into `ref_tax_periodicity` (`code`, `label`, `sort_order`) values ('daily', 'daily', 2);
insert into `ref_tax_periodicity` (`code`, `label`, `sort_order`) values ('annual', 'annual', 3);


create table `absence_entitlements` (
  `id` CHAR(36) default (UUID()) not null,
  `absence_type_id` CHAR(36) not null,
  `days` DECIMAL(5,1),
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `legal_ref` TEXT,
  `frequency_note` TEXT,
  `career_cap_days` DECIMAL(6,1),
  `block_days` DECIMAL(5,1),
  `period_months` INT,
  `relationship_degree` SMALLINT,
  `requires_evidence` TINYINT(1) default 0 not null,
  `note` TEXT,
  constraint absence_entitlements_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `absence_types` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `label` TEXT not null,
  `category` VARCHAR(64) not null,
  `legal_ref` TEXT,
  `requires_certificate` TINYINT(1) default 0 not null,
  `is_paid` TINYINT(1) default 1 not null,
  `counts_against_leave` TINYINT(1) default 0 not null,
  constraint absence_types_pkey primary key (`id`),
  constraint absence_types_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `absences` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `absence_type_id` CHAR(36) not null,
  `start_date` DATE not null,
  `end_date` DATE not null,
  `days_count` DECIMAL(5,2) default 0 not null,
  `status` VARCHAR(64) default 'pending' not null,
  `comment` TEXT,
  `certificate_received` TINYINT(1) default 0 not null,
  `certificate_received_at` DATE,
  `certificate_document_id` CHAR(36),
  `requested_by` CHAR(36),
  `decided_by` CHAR(36),
  `decided_at` DATETIME(6),
  `decision_note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `declared_by_employee` TINYINT(1) default 0 not null,
  `certificate_uploaded_at` DATETIME(6),
  `certificate_original_received` TINYINT(1) default 0 not null,
  `certificate_original_received_at` DATE,
  `child_id` CHAR(36),
  `absence_parente_id` CHAR(36),
  `proposee_par` TEXT,
  `rang_proposition` SMALLINT default 0 not null,
  constraint absences_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `address_checks` (
  `id` CHAR(36) default (UUID()) not null,
  `entity_table` VARCHAR(255) not null,
  `entity_id` CHAR(36) not null,
  `company_id` CHAR(36),
  `country` CHAR(3),
  `postal_code` TEXT,
  `status` TEXT not null,
  `zone_code` TEXT,
  `message` TEXT,
  `checked_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint address_checks_pkey primary key (`id`),
  constraint address_check_unique unique (`entity_table`, `entity_id`)
) engine=InnoDB default charset=utf8mb4;

create table `address_zones` (
  `id` CHAR(36) default (UUID()) not null,
  `country` CHAR(3) not null,
  `kind` TEXT not null,
  `code` VARCHAR(255) not null,
  `label` TEXT not null,
  `postal_from` INT,
  `postal_to` INT,
  `is_verified` TINYINT(1) default 0 not null,
  `source` TEXT not null,
  `note` TEXT,
  constraint address_zones_pkey primary key (`id`),
  constraint address_zone_unique unique (`country`, `code`)
) engine=InnoDB default charset=utf8mb4;

create table `adresses_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `type_adresse` TEXT not null,
  `ligne` TEXT,
  `code_postal` TEXT,
  `localite` TEXT,
  `pays` CHAR(3) default 'LUX' not null,
  `latitude` DECIMAL(9,6),
  `longitude` DECIMAL(9,6),
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `origine` TEXT default 'saisie' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `created_by` CHAR(36),
  `deleted_at` DATETIME(6),
  `deleted_by` CHAR(36),
  constraint adresses_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `app_secrets` (
  `key` VARCHAR(255) not null,
  `secret` TEXT not null,
  constraint app_secrets_pkey primary key (`key`)
) engine=InnoDB default charset=utf8mb4;

create table `app_users` (
  `id` CHAR(36) default (UUID()) not null,
  `userid` TEXT not null,
  `email` TEXT not null,
  `full_name` TEXT,
  `password_hash` TEXT,
  `is_admin` TINYINT(1) default 0 not null,
  `auth_user_id` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `created_by` CHAR(36),
  `updated_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `updated_by` CHAR(36),
  `deleted_at` DATETIME(6),
  `deleted_by` CHAR(36),
  constraint app_users_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `audit_log` (
  `id` BIGINT not null,
  `occurred_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `actor_id` CHAR(36),
  `actor_label` TEXT,
  `company_id` CHAR(36),
  `entity_table` TEXT not null,
  `entity_id` CHAR(36),
  `action` TEXT not null,
  `old_value` JSON,
  `new_value` JSON,
  `source_ip` TEXT,
  `user_agent` TEXT,
  `request_id` TEXT,
  constraint audit_log_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `benefit_types` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `label` TEXT not null,
  `valuation_method` TEXT not null,
  `is_taxable` TINYINT(1) default 1 not null,
  `is_contributory` TINYINT(1) default 1 not null,
  `valuation_params` JSON default '{}' not null,
  `legal_ref` TEXT,
  `note` TEXT,
  constraint benefit_types_pkey primary key (`id`),
  constraint benefit_types_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `cba_rules` (
  `id` CHAR(36) default (UUID()) not null,
  `collective_agreement_id` CHAR(36) not null,
  `block` VARCHAR(64) not null,
  `rules` JSON default '{}' not null,
  `is_complete` TINYINT(1) default 0 not null,
  `updated_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint cba_rules_pkey primary key (`id`),
  constraint cba_rules_collective_agreeme unique (`collective_agreement_id`, `block`)
) engine=InnoDB default charset=utf8mb4;

create table `cba_salary_grids` (
  `id` CHAR(36) default (UUID()) not null,
  `collective_agreement_id` CHAR(36) not null,
  `category` TEXT not null,
  `seniority_from_years` DECIMAL(4,1) default 0 not null,
  `seniority_to_years` DECIMAL(4,1),
  `monthly_amount` DECIMAL(10,2) not null,
  `index_ref` DECIMAL(8,2),
  constraint cba_salary_grids_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `cct_regle_prime` (
  `id` CHAR(36) default (UUID()) not null,
  `collective_agreement_id` CHAR(36) not null,
  `condition_code` TEXT not null,
  `nature_prime` TEXT not null,
  `libelle` TEXT not null,
  `taux_pct` DECIMAL(7,4),
  `montant` DECIMAL(10,2),
  `assiette` TEXT,
  `unite` TEXT not null,
  `seuil_minutes` INT default 0 not null,
  `categorie_visee` TEXT,
  `article` TEXT,
  `source_url` TEXT not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint cct_regle_prime_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `client_sites` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `name` TEXT not null,
  `client_name` TEXT,
  `address_line` TEXT,
  `postal_code` TEXT,
  `city` TEXT,
  `country` TEXT default 'LU' not null,
  `latitude` DECIMAL(9,6),
  `longitude` DECIMAL(9,6),
  `is_active` TINYINT(1) default 1 not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint client_sites_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `collective_agreements` (
  `id` CHAR(36) default (UUID()) not null,
  `organization_id` CHAR(36),
  `code` TEXT not null,
  `name` TEXT not null,
  `sector` TEXT not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `is_active` TINYINT(1) default 0 not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `scope` VARCHAR(64) default 'sector' not null,
  `supersedes_id` CHAR(36),
  `employee_category` TEXT,
  constraint collective_agreements_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `companies` (
  `id` CHAR(36) default (UUID()) not null,
  `organization_id` CHAR(36) not null,
  `legal_name` TEXT not null,
  `legal_form` TEXT,
  `rcs_number` TEXT,
  `ccss_matricule` TEXT,
  `address_line` TEXT,
  `postal_code` TEXT,
  `city` TEXT,
  `country` TEXT default 'LU' not null,
  `nace_code` TEXT,
  `sector` TEXT,
  `reference_period_months` SMALLINT default 4 not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `internal_rules_adopted_on` DATE,
  `internal_rules_reference` TEXT,
  constraint companies_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `company_accident_claims` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `year` SMALLINT not null,
  `claim_count` INT default 0 not null,
  `days_lost` INT default 0 not null,
  `cost` DECIMAL(12,2),
  `note` TEXT,
  constraint company_accident_claims_pkey primary key (`id`),
  constraint company_accident_claims_comp unique (`company_id`, `year`)
) engine=InnoDB default charset=utf8mb4;

create table `company_collective_agreements` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `collective_agreement_id` CHAR(36) not null,
  `department_id` CHAR(36),
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint company_collective_agreement primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `company_financials` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `fiscal_year` SMALLINT not null,
  `profit` DECIMAL(14,2),
  `revenue` DECIMAL(14,2),
  `source` TEXT,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint company_financials_pkey primary key (`id`),
  constraint company_financials_company_i unique (`company_id`, `fiscal_year`)
) engine=InnoDB default charset=utf8mb4;

create table `company_rate_periods` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `activity_class` TEXT,
  `accident_risk_class` TEXT,
  `accident_factor` DECIMAL(5,2) default 1.00 not null,
  `mutuality_class` SMALLINT,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `source` TEXT default 'CCSS' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint company_rate_periods_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `compliance_alerts` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36),
  `rule_code` TEXT not null,
  `title` TEXT not null,
  `detail` TEXT not null,
  `consequence` TEXT,
  `legal_ref` TEXT,
  `severity` VARCHAR(64) not null,
  `due_date` DATE,
  `state` VARCHAR(64) default 'open' not null,
  `handled_by` CHAR(36),
  `handled_at` DATETIME(6),
  `handled_note` TEXT,
  `first_seen_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint compliance_alerts_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contract_amendments` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `effective_date` DATE not null,
  `reason` TEXT not null,
  `changes` JSON not null,
  `created_by` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint contract_amendments_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contract_collective_agreements` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `collective_agreement_id` CHAR(36) not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint contract_collective_agreemen primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contract_pay_components` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `kind` VARCHAR(64) not null,
  `code` TEXT not null,
  `label` TEXT not null,
  `amount` DECIMAL(10,2),
  `rate_pct` DECIMAL(6,3),
  `basis` TEXT,
  `periodicity` TEXT default 'monthly' not null,
  `in_salary_reference` TINYINT(1) default 0 not null,
  `is_taxable` TINYINT(1) default 1 not null,
  `is_contributory` TINYINT(1) default 1 not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `benefit_type_id` CHAR(36),
  constraint contract_pay_components_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contract_terminations` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `reason` TEXT not null,
  `is_personal_ground` TINYINT(1) default 1 not null,
  `notified_on` DATE not null,
  `notice_start` DATE,
  `notice_end` DATE,
  `severance_months` DECIMAL(4,1),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `notice_waived` TINYINT(1) default 0 not null,
  `waiver_agreed_on` DATE,
  `waiver_compensation` DECIMAL(12,2),
  `waiver_note` TEXT,
  `is_gross_misconduct` TINYINT(1) default 0 not null,
  constraint contract_terminations_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contracts` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `kind` VARCHAR(64) not null,
  `status` VARCHAR(64) default 'draft' not null,
  `job_title` TEXT not null,
  `job_description` TEXT,
  `work_place` TEXT,
  `category` TEXT,
  `start_date` DATE not null,
  `end_date` DATE,
  `cdd_reason` TEXT,
  `renewal_count` SMALLINT default 0 not null,
  `previous_contract_id` CHAR(36),
  `monthly_gross` DECIMAL(10,2) not null,
  `index_ref` DECIMAL(8,2),
  `weekly_hours` DECIMAL(5,2) default 40 not null,
  `days_per_week` DECIMAL(3,1) default 5 not null,
  `work_distribution` TEXT,
  `reference_period_months` SMALLINT default 4 not null,
  `night_work` TINYINT(1) default 0 not null,
  `annual_leave_days` DECIMAL(5,2),
  `break_minutes` SMALLINT,
  `non_compete_clause` TINYINT(1) default 0 not null,
  `exclusivity_clause` TINYINT(1) default 0 not null,
  `probation_length` INT,
  `probation_unit` TEXT,
  `version` SMALLINT default 1 not null,
  `signed_at` DATE,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `is_part_time` TINYINT(1) default 0 not null,
  `apprenticeship_level` TEXT,
  `apprenticeship_year` SMALLINT,
  `season_label` TEXT,
  `interim_agency_id` CHAR(36),
  `user_company_name` TEXT,
  `mission_reason` TEXT,
  constraint contracts_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `creneau_condition` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `shift_id` CHAR(36),
  `time_entry_id` CHAR(36),
  `client_site_id` CHAR(36),
  `condition_code` TEXT not null,
  `date_prestation` DATE not null,
  `heure_debut` TIME not null,
  `heure_fin` TIME not null,
  `minutes` INT,
  `constate_par` CHAR(36),
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `deleted_at` DATETIME(6),
  `deleted_by` CHAR(36),
  constraint creneau_condition_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `data_access_log` (
  `id` BIGINT not null,
  `occurred_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `actor_id` CHAR(36),
  `actor_label` TEXT,
  `company_id` CHAR(36),
  `subject_employee_id` CHAR(36),
  `entity_table` TEXT not null,
  `entity_id` CHAR(36),
  `action` TEXT not null,
  `scope` TEXT,
  `row_count` INT,
  `source_ip` TEXT,
  `user_agent` TEXT,
  `request_id` TEXT,
  `is_autonomous` TINYINT(1) default 0 not null,
  constraint data_access_log_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `departments` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `name` TEXT not null,
  `min_evening_coverage` SMALLINT,
  constraint departments_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `document_types` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `label` TEXT not null,
  `stage` VARCHAR(64) default 'during_contract' not null,
  `validity_months` INT,
  `is_mandatory` TINYINT(1) default 0 not null,
  `applies_to_residency` JSON,
  `alert_days_before` INT default 30 not null,
  `legal_ref` TEXT,
  `note` TEXT,
  constraint document_types_pkey primary key (`id`),
  constraint document_types_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `documents` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36),
  `entity_table` TEXT,
  `entity_id` CHAR(36),
  `name` TEXT not null,
  `storage_path` TEXT not null,
  `mime_type` TEXT,
  `size_bytes` BIGINT,
  `retention_until` DATE,
  `is_sensitive` TINYINT(1) default 0 not null,
  `uploaded_by` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `document_type_id` CHAR(36),
  `issued_on` DATE,
  `expires_on` DATE,
  `delivered_at` DATE,
  constraint documents_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_children` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `first_name` TEXT,
  `last_name` TEXT,
  `sex` VARCHAR(64),
  `birth_date` DATE not null,
  `relationship` TEXT default 'child' not null,
  `is_dependent` TINYINT(1) default 1 not null,
  `privacy_opt_out` TINYINT(1) default 0 not null,
  `adoption_date` DATE,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `refus_photos_evenements` TINYINT(1) default 0 not null,
  `invitation_evenements` TINYINT(1) default 0 not null,
  `en_situation_handicap` TINYINT(1) default 0 not null,
  `taux_handicap_pct` DECIMAL(5,2),
  constraint employee_children_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_disabilities` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `rate_pct` DECIMAL(5,2) not null,
  `recognized_on` DATE,
  `authority` TEXT,
  `extra_leave_days_override` DECIMAL(4,1),
  `evidence_document_id` CHAR(36),
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint employee_disabilities_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_sanctions` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `contract_id` CHAR(36),
  `sanction_type` TEXT not null,
  `facts_on` DATE not null,
  `facts_known_on` DATE not null,
  `notified_on` DATE,
  `effective_from` DATE,
  `effective_to` DATE,
  `reason` TEXT not null,
  `evidence_document_id` CHAR(36),
  `termination_id` CHAR(36),
  `amendment_contract_id` CHAR(36),
  `employee_heard_on` DATE,
  `employee_response` TEXT,
  `contested_on` DATE,
  `contest_outcome` TEXT,
  `note` TEXT,
  `retention_until` DATE,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `created_by` CHAR(36),
  `updated_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `updated_by` CHAR(36),
  `deleted_at` DATETIME(6),
  `deleted_by` CHAR(36),
  constraint employee_sanctions_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_statuses` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `kind` VARCHAR(64) not null,
  `declared_on` DATE default CURRENT_DATE not null,
  `start_date` DATE not null,
  `end_date` DATE,
  `expected_birth_date` DATE,
  `actual_birth_date` DATE,
  `evidence_document_id` CHAR(36),
  `hours_credit_monthly` DECIMAL(5,1),
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint employee_statuses_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_tax_cards` (
  `id` CHAR(36) default (UUID()) not null,
  `employee_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `tax_class` VARCHAR(64) not null,
  `rate` DECIMAL(6,4),
  `monthly_allowance` DECIMAL(10,2) default 0 not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `credits` JSON default '[]' not null,
  `commute_distance_km` DECIMAL(6,1),
  `professional_expenses_monthly` DECIMAL(10,2),
  `other_deductions_monthly` DECIMAL(10,2) default 0 not null,
  `card_reference` TEXT,
  `issued_on` DATE,
  constraint employee_tax_cards_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employees` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `user_id` CHAR(36),
  `department_id` CHAR(36),
  `first_name` TEXT not null,
  `last_name` TEXT not null,
  `birth_date` DATE,
  `residency` VARCHAR(64) not null,
  `qualification` VARCHAR(64) default 'unqualified' not null,
  `address_line` TEXT,
  `postal_code` TEXT,
  `city` TEXT,
  `country` TEXT default 'LU' not null,
  `email` TEXT,
  `phone` TEXT,
  `national_id_enc` LONGBLOB,
  `iban_enc` LONGBLOB,
  `national_id_hint` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `sex` VARCHAR(64) default 'unspecified' not null,
  `career_start_date` DATE,
  `profession` TEXT,
  `is_management` TINYINT(1) default 0 not null,
  `sexe_legal` VARCHAR(64),
  `refus_photos_societe` TINYINT(1) default 0 not null,
  `souhaite_confidentialite` TINYINT(1) default 0 not null,
  constraint employees_pkey primary key (`id`),
  constraint employees_id_company_uk unique (`id`, `company_id`)
) engine=InnoDB default charset=utf8mb4;

create table `expected_parameters` (
  `param_key` VARCHAR(255) not null,
  `read_by` TEXT not null,
  `note` TEXT,
  constraint expected_parameters_pkey primary key (`param_key`)
) engine=InnoDB default charset=utf8mb4;

create table `export_log` (
  `id` CHAR(36) default (UUID()) not null,
  `organization_id` CHAR(36) not null,
  `requested_by` CHAR(36),
  `subject_kind` TEXT not null,
  `subject_id` CHAR(36),
  `row_count` INT default 0 not null,
  `byte_size` INT default 0 not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `source_ip` TEXT,
  `user_agent` TEXT,
  `request_id` TEXT,
  constraint export_log_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `fiche_sante` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36),
  `enfant_id` CHAR(36),
  `allergies` TEXT,
  `pathologies` TEXT,
  `medecin_traitant` TEXT,
  `medecin_telephone` TEXT,
  `groupe_sanguin` TEXT,
  `note` TEXT,
  `maj_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `maj_par` CHAR(36),
  `deleted_at` DATETIME(6),
  `deleted_by` CHAR(36),
  constraint fiche_sante_pkey primary key (`id`),
  constraint fs_une_par_personne unique (`employee_id`, `enfant_id`)
) engine=InnoDB default charset=utf8mb4;

create table `headcount_snapshots` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `month` DATE not null,
  `headcount` DECIMAL(8,2) not null,
  constraint headcount_snapshots_pkey primary key (`id`),
  constraint headcount_snapshots_company_ unique (`company_id`, `month`)
) engine=InnoDB default charset=utf8mb4;

create table `interim_agencies` (
  `id` CHAR(36) default (UUID()) not null,
  `organization_id` CHAR(36) not null,
  `name` TEXT not null,
  `ccss_matricule` TEXT,
  `rcs_number` TEXT,
  `address_line` TEXT,
  `postal_code` TEXT,
  `city` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint interim_agencies_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `legal_parameters` (
  `id` CHAR(36) default (UUID()) not null,
  `family` VARCHAR(64) not null,
  `param_key` TEXT not null,
  `label` TEXT not null,
  `value_num` DECIMAL(30,10),
  `value_text` TEXT,
  `value_json` JSON,
  `unit` TEXT,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `index_ref` DECIMAL(8,2),
  `source` TEXT not null,
  `legal_ref` TEXT,
  `note` TEXT,
  `entered_by` CHAR(36),
  `entered_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `validated_by` CHAR(36),
  `validated_at` DATETIME(6),
  `derived_from_key` TEXT,
  `derived_factor` DECIMAL(30,10),
  `derivation_tolerance` DECIMAL(30,10) default 0.02 not null,
  constraint legal_parameters_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `meal_voucher_grants` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `period_start` DATE not null,
  `period_end` DATE not null,
  `voucher_count` INT not null,
  `face_value` DECIMAL(6,2) not null,
  `employee_share` DECIMAL(6,2) default 0 not null,
  `granted_on` DATE,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint meal_voucher_grants_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `organizations` (
  `id` CHAR(36) default (UUID()) not null,
  `name` TEXT not null,
  `kind` VARCHAR(64) default 'fiduciary' not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint organizations_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `overtime_requests` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `schedule_id` CHAR(36),
  `period_start` DATE not null,
  `period_end` DATE not null,
  `hours` DECIMAL(6,2) not null,
  `reason` TEXT not null,
  `status` TEXT default 'requested' not null,
  `requested_by` CHAR(36),
  `requested_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `hr_validated_by` CHAR(36),
  `hr_validated_at` DATETIME(6),
  `employee_accepted_at` DATETIME(6),
  `rejected_reason` TEXT,
  `compensation` TEXT default 'money' not null,
  `note` TEXT,
  constraint overtime_requests_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `personne_indicateur_secours` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36),
  `enfant_id` CHAR(36),
  `indicateur` VARCHAR(255) not null,
  `precision_lieu` TEXT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `pose_par` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint personne_indicateur_secours_ primary key (`id`),
  constraint pis_unique unique (`employee_id`, `enfant_id`, `indicateur`, `debut_validite`)
) engine=InnoDB default charset=utf8mb4;

create table `premiums` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `contract_id` CHAR(36),
  `termination_id` CHAR(36),
  `kind` TEXT default 'other' not null,
  `label` TEXT not null,
  `amount` DECIMAL(12,2) not null,
  `granted_on` DATE not null,
  `fiscal_year` SMALLINT not null,
  `is_taxable` TINYINT(1) default 1 not null,
  `is_contributory` TINYINT(1) default 1 not null,
  `exempt_pct` DECIMAL(6,3) default 0 not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint premiums_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `probation_extensions` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `from_date` DATE not null,
  `to_date` DATE not null,
  `days_added` INT not null,
  `reason` TEXT default 'incapacité de travail' not null,
  constraint probation_extensions_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `profiles` (
  `id` CHAR(36) not null,
  `organization_id` CHAR(36) not null,
  `full_name` TEXT default '' not null,
  `email` TEXT default '' not null,
  `is_org_admin` TINYINT(1) default 0 not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint profiles_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `public_holidays` (
  `id` CHAR(36) default (UUID()) not null,
  `year` SMALLINT not null,
  `holiday_date` DATE not null,
  `name` TEXT not null,
  `is_mobile` TINYINT(1) default 0 not null,
  `collective_agreement_id` CHAR(36),
  `is_recoverable` TINYINT(1) default 0 not null,
  `recovery_reason` TEXT,
  constraint public_holidays_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_action_acces` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_action_acces_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_compensation_heures_sup` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_compensation_heures_sup_ primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_condition_travail` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `famille` TEXT not null,
  `description` TEXT,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_condition_travail_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_indicateur_secours` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `consigne` TEXT not null,
  `visible_dispatching` TINYINT(1) default 1 not null,
  `visible_secours` TINYINT(1) default 1 not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_indicateur_secours_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_lien_enfant` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_lien_enfant_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_nature_prime` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `categorie` TEXT default 'autre' not null,
  `lie_aux_conditions` TINYINT(1) default 0 not null,
  `source_url` TEXT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_nature_prime_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_pays` (
  `alpha3` CHAR(3) not null,
  `alpha2` CHAR(2) not null,
  `nom` TEXT not null,
  `frontalier` TINYINT(1) default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  constraint ref_pays_pkey primary key (`alpha3`),
  constraint rp_alpha2_unique unique (`alpha2`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_statut_heures_sup` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_statut_heures_sup_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_statut_verification_adresse` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_statut_verification_adre primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_sujet_export` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_sujet_export_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_type_adresse` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `description` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `sert_au_fiscal` TINYINT(1) default 0 not null,
  `sert_aux_tournees` TINYINT(1) default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  constraint ref_type_adresse_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_unite_essai` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_unite_essai_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `ref_unite_prime` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `description` TEXT,
  `ordre` SMALLINT default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint ref_unite_prime_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `reference_periods` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `department_id` CHAR(36),
  `label` TEXT not null,
  `start_date` DATE not null,
  `end_date` DATE not null,
  `months` SMALLINT not null,
  constraint reference_periods_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `sanction_categories` (
  `code` VARCHAR(255) not null,
  `label` TEXT not null,
  `rank` SMALLINT not null,
  `description` TEXT not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  constraint sanction_categories_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `sanction_types` (
  `code` VARCHAR(255) not null,
  `category_code` TEXT not null,
  `label` TEXT not null,
  `description` TEXT not null,
  `affects_presence` TINYINT(1) default 0 not null,
  `affects_pay` TINYINT(1) default 0 not null,
  `requires_internal_rules` TINYINT(1) default 0 not null,
  `is_contract_change` TINYINT(1) default 0 not null,
  `ends_contract` TINYINT(1) default 0 not null,
  `needs_notice` TINYINT(1),
  `legal_ref` TEXT,
  `note` TEXT,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  constraint sanction_types_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `schedules` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `department_id` CHAR(36),
  `week_start` DATE not null,
  `label` TEXT,
  `status` VARCHAR(64) default 'draft' not null,
  `published_at` DATETIME(6),
  `published_by` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint schedules_pkey primary key (`id`),
  constraint schedules_company_id_departm unique (`company_id`, `department_id`, `week_start`),
  constraint schedules_id_company_uk unique (`id`, `company_id`)
) engine=InnoDB default charset=utf8mb4;

create table `shift_templates` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `name` TEXT not null,
  `start_time` TIME not null,
  `end_time` TIME not null,
  `break_minutes` SMALLINT default 0 not null,
  `color` TEXT default '#017E84' not null,
  `department_id` CHAR(36),
  constraint shift_templates_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `shifts` (
  `id` CHAR(36) default (UUID()) not null,
  `schedule_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `shift_date` DATE not null,
  `start_time` TIME not null,
  `end_time` TIME not null,
  `break_minutes` SMALLINT default 0 not null,
  `label` TEXT,
  `template_id` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `client_site_id` CHAR(36),
  constraint shifts_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `tax_brackets` (
  `id` CHAR(36) default (UUID()) not null,
  `tax_class` VARCHAR(64) not null,
  `periodicity` VARCHAR(64) default 'monthly' not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `bracket_min` DECIMAL(12,2) not null,
  `bracket_max` DECIMAL(12,2),
  `base_tax` DECIMAL(12,2) default 0 not null,
  `rate_over_min` DECIMAL(7,4) not null,
  `source` TEXT default 'ACD' not null,
  `legal_ref` TEXT,
  `note` TEXT,
  constraint tax_brackets_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `tax_credits` (
  `id` CHAR(36) default (UUID()) not null,
  `code` TEXT not null,
  `label` TEXT not null,
  `applies_to_classes` JSON,
  `income_min` DECIMAL(12,2),
  `income_max` DECIMAL(12,2),
  `monthly_amount` DECIMAL(10,2),
  `prorated_on_hours` TINYINT(1) default 0 not null,
  `valid_from` DATE default '1970-01-01' not null,
  `valid_to` DATE default '2037-12-31' not null,
  `source` TEXT default 'ACD' not null,
  `legal_ref` TEXT,
  `note` TEXT,
  constraint tax_credits_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `time_entries` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `entry_date` DATE not null,
  `start_time` TIME,
  `end_time` TIME,
  `break_minutes` SMALLINT default 0 not null,
  `worked_hours` DECIMAL(5,2),
  `planned_hours` DECIMAL(5,2),
  `sunday_hours` DECIMAL(5,2) default 0 not null,
  `holiday_hours` DECIMAL(5,2) default 0 not null,
  `night_hours` DECIMAL(5,2) default 0 not null,
  `overtime_hours` DECIMAL(5,2) default 0 not null,
  `is_validated` TINYINT(1) default 0 not null,
  `source` TEXT default 'manual' not null,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint time_entries_pkey primary key (`id`),
  constraint time_entries_employee_id_ent unique (`employee_id`, `entry_date`)
) engine=InnoDB default charset=utf8mb4;

create table `travel_distances` (
  `id` CHAR(36) default (UUID()) not null,
  `origin_ref` VARCHAR(255) not null,
  `destination_ref` VARCHAR(255) not null,
  `distance_km` DECIMAL(8,2) not null,
  `duration_minutes` INT,
  `source` TEXT not null,
  `computed_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `computed_by` CHAR(36),
  `note` TEXT,
  constraint travel_distances_pkey primary key (`id`),
  constraint travel_distance_unique unique (`origin_ref`, `destination_ref`)
) engine=InnoDB default charset=utf8mb4;

create table `user_roles` (
  `id` CHAR(36) default (UUID()) not null,
  `user_id` CHAR(36) not null,
  `organization_id` CHAR(36) not null,
  `company_id` CHAR(36),
  `role` VARCHAR(64) not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint user_roles_pkey primary key (`id`),
  constraint user_roles_user_id_company_i unique (`user_id`, `company_id`, `role`)
) engine=InnoDB default charset=utf8mb4;

-- Clés étrangères, posées après toutes les tables.
alter table `absence_types` add constraint absence_types_category_ref foreign key (`category`) references `ref_absence_category` (`code`);
alter table `absences` add constraint absences_status_ref foreign key (`status`) references `ref_absence_status` (`code`);
alter table `cba_rules` add constraint cba_rules_block_ref foreign key (`block`) references `ref_cba_block` (`code`);
alter table `collective_agreements` add constraint collective_agreeme_scope_ref foreign key (`scope`) references `ref_cba_scope` (`code`);
alter table `compliance_alerts` add constraint compliance_alerts_severity_r foreign key (`severity`) references `ref_severity_kind` (`code`);
alter table `compliance_alerts` add constraint compliance_alerts_state_ref foreign key (`state`) references `ref_alert_state` (`code`);
alter table `contract_pay_components` add constraint contract_pay_compo_kind_ref foreign key (`kind`) references `ref_pay_component_kind` (`code`);
alter table `contracts` add constraint contracts_kind_ref foreign key (`kind`) references `ref_contract_kind` (`code`);
alter table `contracts` add constraint contracts_status_ref foreign key (`status`) references `ref_contract_status` (`code`);
alter table `document_types` add constraint document_types_stage_ref foreign key (`stage`) references `ref_document_stage` (`code`);
alter table `employee_children` add constraint employee_children_sex_ref foreign key (`sex`) references `ref_sex_kind` (`code`);
alter table `employee_statuses` add constraint employee_statuses_kind_ref foreign key (`kind`) references `ref_employee_status_kind` (`code`);
alter table `employee_tax_cards` add constraint employee_tax_cards_tax_class foreign key (`tax_class`) references `ref_tax_class` (`code`);
alter table `employees` add constraint employees_residency_ref foreign key (`residency`) references `ref_residency_kind` (`code`);
alter table `employees` add constraint employees_qualification_ref foreign key (`qualification`) references `ref_qualification_kind` (`code`);
alter table `employees` add constraint employees_sex_ref foreign key (`sex`) references `ref_sex_kind` (`code`);
alter table `employees` add constraint employees_sexe_legal_ref foreign key (`sexe_legal`) references `ref_sex_kind` (`code`);
alter table `legal_parameters` add constraint legal_parameters_family_ref foreign key (`family`) references `ref_param_family` (`code`);
alter table `organizations` add constraint organizations_kind_ref foreign key (`kind`) references `ref_org_kind` (`code`);
alter table `schedules` add constraint schedules_status_ref foreign key (`status`) references `ref_schedule_status` (`code`);
alter table `tax_brackets` add constraint tax_brackets_tax_class_ref foreign key (`tax_class`) references `ref_tax_class` (`code`);
alter table `tax_brackets` add constraint tax_brackets_periodicity_ref foreign key (`periodicity`) references `ref_tax_periodicity` (`code`);
alter table `user_roles` add constraint user_roles_role_ref foreign key (`role`) references `ref_app_role` (`code`);

alter table `absence_entitlements` add constraint absence_entitlements_absence foreign key (`absence_type_id`) references `absence_types` (`id`) on delete cascade;
alter table `absences` add constraint absence_belongs_to_employees foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `absences` add constraint absences_absence_parente_id_ foreign key (`absence_parente_id`) references `absences` (`id`) on delete set null;
alter table `absences` add constraint absences_absence_type_id_fke foreign key (`absence_type_id`) references `absence_types` (`id`);
alter table `absences` add constraint absences_child_id_fkey foreign key (`child_id`) references `employee_children` (`id`) on delete set null;
alter table `absences` add constraint absences_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `absences` add constraint absences_decided_by_fkey foreign key (`decided_by`) references `app_users` (`id`);
alter table `absences` add constraint absences_requested_by_fkey foreign key (`requested_by`) references `app_users` (`id`);
alter table `address_checks` add constraint address_checks_statut_ref foreign key (`status`) references `ref_statut_verification_adresse` (`code`);
alter table `adresses_salarie` add constraint adr_appartient_au_salarie foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `adresses_salarie` add constraint adresses_salarie_type_adress foreign key (`type_adresse`) references `ref_type_adresse` (`code`);
alter table `cba_rules` add constraint cba_rules_collective_agreeme foreign key (`collective_agreement_id`) references `collective_agreements` (`id`) on delete cascade;
alter table `cba_salary_grids` add constraint cba_salary_grids_collective_ foreign key (`collective_agreement_id`) references `collective_agreements` (`id`) on delete cascade;
alter table `cct_regle_prime` add constraint cct_regle_prime_collective_a foreign key (`collective_agreement_id`) references `collective_agreements` (`id`) on delete cascade;
alter table `cct_regle_prime` add constraint cct_regle_prime_condition_co foreign key (`condition_code`) references `ref_condition_travail` (`code`);
alter table `cct_regle_prime` add constraint cct_regle_prime_nature_prime foreign key (`nature_prime`) references `ref_nature_prime` (`code`);
alter table `cct_regle_prime` add constraint cct_regle_prime_unite_ref foreign key (`unite`) references `ref_unite_prime` (`code`);
alter table `client_sites` add constraint client_sites_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `collective_agreements` add constraint collective_agreements_organi foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `collective_agreements` add constraint collective_agreements_supers foreign key (`supersedes_id`) references `collective_agreements` (`id`) on delete set null;
alter table `companies` add constraint companies_organization_id_fk foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `company_accident_claims` add constraint company_accident_claims_comp foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `company_collective_agreements` add constraint company_collective_agreement foreign key (`collective_agreement_id`) references `collective_agreements` (`id`);
alter table `company_collective_agreements` add constraint company_collective_agreement foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `company_collective_agreements` add constraint company_collective_agreement foreign key (`department_id`) references `departments` (`id`) on delete cascade;
alter table `company_financials` add constraint company_financials_company_i foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `company_rate_periods` add constraint company_rate_periods_company foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `compliance_alerts` add constraint compliance_alerts_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `compliance_alerts` add constraint compliance_alerts_employee_i foreign key (`employee_id`) references `employees` (`id`) on delete set null;
alter table `compliance_alerts` add constraint compliance_alerts_handled_by foreign key (`handled_by`) references `app_users` (`id`);
alter table `contract_amendments` add constraint contract_amendments_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_amendments` add constraint contract_amendments_contract foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_amendments` add constraint contract_amendments_created_ foreign key (`created_by`) references `app_users` (`id`);
alter table `contract_collective_agreements` add constraint contract_collective_agreemen foreign key (`collective_agreement_id`) references `collective_agreements` (`id`);
alter table `contract_collective_agreements` add constraint contract_collective_agreemen foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_pay_components` add constraint contract_pay_components_bene foreign key (`benefit_type_id`) references `benefit_types` (`id`) on delete set null;
alter table `contract_pay_components` add constraint contract_pay_components_comp foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_pay_components` add constraint contract_pay_components_cont foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_terminations` add constraint contract_terminations_compan foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_terminations` add constraint contract_terminations_contra foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contracts` add constraint contract_belongs_to_employee foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `contracts` add constraint contracts_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contracts` add constraint contracts_interim_agency_fk foreign key (`interim_agency_id`) references `interim_agencies` (`id`) on delete set null;
alter table `contracts` add constraint contracts_previous_contract_ foreign key (`previous_contract_id`) references `contracts` (`id`) on delete set null;
alter table `contracts` add constraint contracts_unite_essai_ref foreign key (`probation_unit`) references `ref_unite_essai` (`code`);
alter table `creneau_condition` add constraint cc_appartient_au_salarie foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `creneau_condition` add constraint cc_site_appartient_a_la_soci foreign key (`client_site_id`, `company_id`) references `client_sites` (`id`, `company_id`) on delete set null;
alter table `creneau_condition` add constraint creneau_condition_condition_ foreign key (`condition_code`) references `ref_condition_travail` (`code`);
alter table `creneau_condition` add constraint creneau_condition_shift_id_f foreign key (`shift_id`) references `shifts` (`id`) on delete cascade;
alter table `creneau_condition` add constraint creneau_condition_time_entry foreign key (`time_entry_id`) references `time_entries` (`id`) on delete cascade;
alter table `data_access_log` add constraint data_access_log_action_ref foreign key (`action`) references `ref_action_acces` (`code`);
alter table `departments` add constraint departments_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `documents` add constraint documents_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `documents` add constraint documents_document_type_id_f foreign key (`document_type_id`) references `document_types` (`id`) on delete set null;
alter table `documents` add constraint documents_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `documents` add constraint documents_uploaded_by_fkey foreign key (`uploaded_by`) references `app_users` (`id`);
alter table `employee_children` add constraint child_belongs_to_employees_c foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `employee_children` add constraint employee_children_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_children` add constraint employee_children_lien_ref foreign key (`relationship`) references `ref_lien_enfant` (`code`);
alter table `employee_disabilities` add constraint disability_belongs_to_employ foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `employee_disabilities` add constraint employee_disabilities_compan foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_disabilities` add constraint employee_disabilities_eviden foreign key (`evidence_document_id`) references `documents` (`id`) on delete set null;
alter table `employee_sanctions` add constraint employee_sanctions_amendment foreign key (`amendment_contract_id`) references `contracts` (`id`) on delete set null;
alter table `employee_sanctions` add constraint employee_sanctions_contract_ foreign key (`contract_id`) references `contracts` (`id`) on delete set null;
alter table `employee_sanctions` add constraint employee_sanctions_evidence_ foreign key (`evidence_document_id`) references `documents` (`id`) on delete set null;
alter table `employee_sanctions` add constraint employee_sanctions_sanction_ foreign key (`sanction_type`) references `sanction_types` (`code`);
alter table `employee_sanctions` add constraint employee_sanctions_terminati foreign key (`termination_id`) references `contract_terminations` (`id`) on delete set null;
alter table `employee_sanctions` add constraint sanction_belongs_to_employee foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `employee_statuses` add constraint employee_statuses_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_statuses` add constraint employee_statuses_evidence_d foreign key (`evidence_document_id`) references `documents` (`id`) on delete set null;
alter table `employee_statuses` add constraint status_belongs_to_employees_ foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `employee_tax_cards` add constraint employee_tax_cards_company_i foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_tax_cards` add constraint employee_tax_cards_employee_ foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employees` add constraint employees_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employees` add constraint employees_department_id_fkey foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `employees` add constraint employees_user_id_fkey foreign key (`user_id`) references `app_users` (`id`) on delete set null;
alter table `export_log` add constraint export_log_organization_id_f foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `export_log` add constraint export_log_requested_by_fkey foreign key (`requested_by`) references `app_users` (`id`);
alter table `export_log` add constraint export_log_sujet_ref foreign key (`subject_kind`) references `ref_sujet_export` (`code`);
alter table `fiche_sante` add constraint fiche_sante_enfant_id_fkey foreign key (`enfant_id`) references `employee_children` (`id`) on delete cascade;
alter table `headcount_snapshots` add constraint headcount_snapshots_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `interim_agencies` add constraint interim_agencies_organizatio foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `legal_parameters` add constraint legal_parameters_entered_by_ foreign key (`entered_by`) references `app_users` (`id`);
alter table `legal_parameters` add constraint legal_parameters_validated_b foreign key (`validated_by`) references `app_users` (`id`);
alter table `meal_voucher_grants` add constraint meal_voucher_grants_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `meal_voucher_grants` add constraint voucher_belongs_to_employees foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_belongs_to_employee foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_requests_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_requests_compensati foreign key (`compensation`) references `ref_compensation_heures_sup` (`code`);
alter table `overtime_requests` add constraint overtime_requests_hr_validat foreign key (`hr_validated_by`) references `app_users` (`id`);
alter table `overtime_requests` add constraint overtime_requests_requested_ foreign key (`requested_by`) references `app_users` (`id`);
alter table `overtime_requests` add constraint overtime_requests_schedule_i foreign key (`schedule_id`) references `schedules` (`id`) on delete set null;
alter table `overtime_requests` add constraint overtime_requests_statut_ref foreign key (`status`) references `ref_statut_heures_sup` (`code`);
alter table `personne_indicateur_secours` add constraint personne_indicateur_secours_ foreign key (`enfant_id`) references `employee_children` (`id`) on delete cascade;
alter table `personne_indicateur_secours` add constraint personne_indicateur_secours_ foreign key (`indicateur`) references `ref_indicateur_secours` (`code`);
alter table `premiums` add constraint premium_belongs_to_employees foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `premiums` add constraint premiums_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `premiums` add constraint premiums_contract_id_fkey foreign key (`contract_id`) references `contracts` (`id`) on delete set null;
alter table `premiums` add constraint premiums_nature_ref foreign key (`kind`) references `ref_nature_prime` (`code`);
alter table `premiums` add constraint premiums_termination_id_fkey foreign key (`termination_id`) references `contract_terminations` (`id`) on delete set null;
alter table `probation_extensions` add constraint probation_extensions_contrac foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `profiles` add constraint profiles_id_fkey foreign key (`id`) references `app_users` (`id`) on delete cascade;
alter table `profiles` add constraint profiles_organization_id_fke foreign key (`organization_id`) references `organizations` (`id`);
alter table `reference_periods` add constraint reference_periods_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `reference_periods` add constraint reference_periods_department foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `sanction_types` add constraint sanction_types_category_code foreign key (`category_code`) references `sanction_categories` (`code`);
alter table `schedules` add constraint schedules_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `schedules` add constraint schedules_department_id_fkey foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `schedules` add constraint schedules_published_by_fkey foreign key (`published_by`) references `app_users` (`id`);
alter table `shift_templates` add constraint shift_templates_company_id_f foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `shift_templates` add constraint shift_templates_department_i foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `shifts` add constraint shift_belongs_to_employees_c foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `shifts` add constraint shift_belongs_to_schedules_c foreign key (`schedule_id`, `company_id`) references `schedules` (`id`, `company_id`) on delete cascade;
alter table `shifts` add constraint shift_site_belongs_to_compan foreign key (`client_site_id`, `company_id`) references `client_sites` (`id`, `company_id`) on delete set null;
alter table `shifts` add constraint shifts_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `shifts` add constraint shifts_template_id_fkey foreign key (`template_id`) references `shift_templates` (`id`) on delete set null;
alter table `time_entries` add constraint time_entries_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `time_entries` add constraint time_entry_belongs_to_employ foreign key (`employee_id`, `company_id`) references `employees` (`id`, `company_id`) on delete cascade;
alter table `user_roles` add constraint user_roles_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `user_roles` add constraint user_roles_organization_id_f foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `user_roles` add constraint user_roles_user_id_fkey foreign key (`user_id`) references `app_users` (`id`) on delete cascade;

-- Contraintes de validation.
alter table `absence_entitlements` add constraint absence_entitlements_periode CHECK ((valid_to > valid_from));
alter table `absence_entitlements` add constraint entitlement_days_positive CHECK (((days IS NULL) OR (days >= (0)::numeric)));
alter table `absence_entitlements` add constraint entitlement_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `absences` add constraint absence_days_positive CHECK ((days_count >= (0)::numeric));
alter table `absences` add constraint absence_pas_sa_propre_parent CHECK (((absence_parente_id IS NULL) OR (absence_parente_id <> id)));
alter table `absences` add constraint absence_range CHECK ((end_date >= start_date));
alter table `address_zones` add constraint address_zone_range CHECK (((postal_to IS NULL) OR (postal_from IS NULL) OR (postal_to >= postal_from)));
alter table `address_zones` add constraint address_zone_verified_needs_ CHECK (((NOT is_verified) OR ((postal_from IS NOT NULL) AND (postal_to IS NOT NULL))));
alter table `adresses_salarie` add constraint adr_a_une_adresse CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table `adresses_salarie` add constraint adr_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table `adresses_salarie` add constraint adr_periode CHECK ((fin_validite > debut_validite));
alter table `app_users` add constraint app_user_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table `app_users` add constraint app_user_email_shape CHECK ((email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text));
alter table `app_users` add constraint app_user_userid_shape CHECK ((userid ~ '^[a-z0-9._-]{3,64}$'::text));
alter table `cba_salary_grids` add constraint grid_amount_positive CHECK ((monthly_amount > (0)::numeric));
alter table `cba_salary_grids` add constraint grid_seniority_order CHECK (((seniority_to_years IS NULL) OR (seniority_to_years > seniority_from_years)));
alter table `cct_regle_prime` add constraint crp_periode CHECK ((fin_validite > debut_validite));
alter table `cct_regle_prime` add constraint crp_seuil_positif CHECK ((seuil_minutes >= 0));
alter table `cct_regle_prime` add constraint crp_source_non_vide CHECK ((btrim(source_url) <> ''::text));
alter table `cct_regle_prime` add constraint crp_taux_exige_assiette CHECK (((taux_pct IS NULL) OR (assiette IS NOT NULL)));
alter table `cct_regle_prime` add constraint crp_taux_ou_montant CHECK ((num_nonnulls(taux_pct, montant) = 1));
alter table `client_sites` add constraint client_site_has_an_address CHECK (((address_line IS NOT NULL) OR ((postal_code IS NOT NULL) AND (city IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table `collective_agreements` add constraint collective_agreements_period CHECK ((valid_to > valid_from));
alter table `companies` add constraint ccss_matricule_format CHECK (((ccss_matricule IS NULL) OR (ccss_matricule ~ '^[0-9]{13}$'::text)));
alter table `companies` add constraint companies_reference_period_p CHECK ((reference_period_months >= 1));
alter table `company_accident_claims` add constraint accident_counts_positive CHECK (((claim_count >= 0) AND (days_lost >= 0) AND ((cost IS NULL) OR (cost >= (0)::numeric))));
alter table `company_collective_agreements` add constraint company_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `company_collective_agreements` add constraint company_collective_agreement CHECK ((valid_to > valid_from));
alter table `company_rate_periods` add constraint company_rate_periods_mutuali CHECK ((mutuality_class >= 1));
alter table `company_rate_periods` add constraint company_rate_periods_periode CHECK ((valid_to > valid_from));
alter table `company_rate_periods` add constraint rate_period_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contract_collective_agreements` add constraint contract_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contract_collective_agreements` add constraint contract_collective_agreemen CHECK ((valid_to > valid_from));
alter table `contract_pay_components` add constraint contract_pay_components_peri CHECK ((valid_to > valid_from));
alter table `contract_pay_components` add constraint pay_component_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contract_terminations` add constraint notice_dates_order CHECK (((notice_start IS NULL) OR (notice_end IS NULL) OR (notice_end >= notice_start)));
alter table `contract_terminations` add constraint waiver_compensation_positive CHECK (((waiver_compensation IS NULL) OR (waiver_compensation >= (0)::numeric)));
alter table `contract_terminations` add constraint waiver_needs_agreement_date CHECK (((NOT notice_waived) OR (waiver_agreed_on IS NOT NULL)));
alter table `contracts` add constraint cdd_needs_reason CHECK (((kind <> 'cdd'::contract_kind) OR (cdd_reason IS NOT NULL)));
alter table `contracts` add constraint contract_dates_order CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table `contracts` add constraint contract_not_its_own_predece CHECK (((previous_contract_id IS NULL) OR (previous_contract_id <> id)));
alter table `contracts` add constraint contract_quantities_positive CHECK (((weekly_hours > (0)::numeric) AND (days_per_week > (0)::numeric) AND (days_per_week <= (7)::numeric) AND (monthly_gross >= (0)::numeric) AND (renewal_count >= 0) AND ((break_minutes IS NULL) OR (break_minutes >= 0)) AND ((annual_leave_days IS NULL) OR (annual_leave_days >= (0)::numeric)) AND ((probation_length IS NULL) OR (probation_length > 0)) AND ((apprenticeship_year IS NULL) OR (apprenticeship_year > 0))));
alter table `contracts` add constraint fixed_term_needs_end CHECK (((kind <> ALL (ARRAY['cdd'::contract_kind, 'seasonal'::contract_kind, 'interim'::contract_kind, 'apprenticeship'::contract_kind])) OR (end_date IS NOT NULL)));
alter table `contracts` add constraint interim_needs_user_company CHECK (((kind <> 'interim'::contract_kind) OR (user_company_name IS NOT NULL)));
alter table `contracts` add constraint probation_length_and_unit_to CHECK (((probation_length IS NULL) = (probation_unit IS NULL)));
alter table `creneau_condition` add constraint cc_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table `creneau_condition` add constraint cc_heures_differentes CHECK ((heure_debut <> heure_fin));
alter table `creneau_condition` add constraint cc_rattachement CHECK (((shift_id IS NOT NULL) OR (time_entry_id IS NOT NULL)));
alter table `departments` add constraint coverage_positive CHECK (((min_evening_coverage IS NULL) OR (min_evening_coverage >= 0)));
alter table `documents` add constraint document_expiry_after_issue CHECK (((expires_on IS NULL) OR (issued_on IS NULL) OR (expires_on >= issued_on)));
alter table `documents` add constraint document_size_positive CHECK (((size_bytes IS NULL) OR (size_bytes >= 0)));
alter table `employee_children` add constraint ec_taux_exige_handicap CHECK (((taux_handicap_pct IS NULL) OR en_situation_handicap));
alter table `employee_children` add constraint ec_taux_handicap CHECK (((taux_handicap_pct IS NULL) OR ((taux_handicap_pct > (0)::numeric) AND (taux_handicap_pct <= (100)::numeric))));
alter table `employee_children` add constraint privacy_minimises_data CHECK (((NOT privacy_opt_out) OR ((first_name IS NULL) AND (last_name IS NULL) AND (sex IS NULL) AND (note IS NULL))));
alter table `employee_disabilities` add constraint disability_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `employee_disabilities` add constraint employee_disabilities_period CHECK ((valid_to > valid_from));
alter table `employee_disabilities` add constraint employee_disabilities_rate_p CHECK (((rate_pct > (0)::numeric) AND (rate_pct <= (100)::numeric)));
alter table `employee_sanctions` add constraint sanction_dates_order CHECK (((effective_to IS NULL) OR (effective_from IS NULL) OR (effective_to >= effective_from)));
alter table `employee_sanctions` add constraint sanction_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table `employee_sanctions` add constraint sanction_known_after_facts CHECK ((facts_known_on >= facts_on));
alter table `employee_sanctions` add constraint sanction_notified_after_know CHECK (((notified_on IS NULL) OR (notified_on >= facts_known_on)));
alter table `employee_statuses` add constraint status_range CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table `employee_tax_cards` add constraint employee_tax_cards_periode_v CHECK ((valid_to > valid_from));
alter table `employee_tax_cards` add constraint tax_card_amounts_positive CHECK (((monthly_allowance >= (0)::numeric) AND ((professional_expenses_monthly IS NULL) OR (professional_expenses_monthly >= (0)::numeric)) AND (other_deductions_monthly >= (0)::numeric) AND ((commute_distance_km IS NULL) OR (commute_distance_km >= (0)::numeric))));
alter table `employee_tax_cards` add constraint tax_card_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `employees` add constraint employee_email_shape CHECK (((email IS NULL) OR (email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text)));
alter table `fiche_sante` add constraint fs_deleted_pair CHECK (((deleted_at IS NULL) = (deleted_by IS NULL)));
alter table `fiche_sante` add constraint fs_personne CHECK ((num_nonnulls(employee_id, enfant_id) = 1));
alter table `headcount_snapshots` add constraint headcount_month_is_first_day CHECK (((EXTRACT(day FROM month))::integer = 1));
alter table `headcount_snapshots` add constraint headcount_positive CHECK ((headcount >= (0)::numeric));
alter table `legal_parameters` add constraint legal_parameters_periode_val CHECK ((valid_to > valid_from));
alter table `legal_parameters` add constraint one_value CHECK (((num_nonnulls(value_num, value_text, value_json) = 1) OR ((derived_from_key IS NOT NULL) AND (num_nonnulls(value_num, value_text, value_json) = 0))));
alter table `legal_parameters` add constraint valid_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `meal_voucher_grants` add constraint meal_voucher_grants_voucher_ CHECK ((voucher_count >= 0));
alter table `meal_voucher_grants` add constraint voucher_period CHECK ((period_end >= period_start));
alter table `meal_voucher_grants` add constraint voucher_share_within_face_va CHECK (((face_value > (0)::numeric) AND (employee_share >= (0)::numeric) AND (employee_share <= face_value)));
alter table `overtime_requests` add constraint overtime_acceptance_follows_ CHECK (((employee_accepted_at IS NULL) OR (hr_validated_at IS NOT NULL)));
alter table `overtime_requests` add constraint overtime_approved_needs_both CHECK (((status <> 'approved'::text) OR ((hr_validated_at IS NOT NULL) AND (employee_accepted_at IS NOT NULL))));
alter table `overtime_requests` add constraint overtime_period CHECK ((period_end >= period_start));
alter table `overtime_requests` add constraint overtime_requests_hours_chec CHECK ((hours > (0)::numeric));
alter table `personne_indicateur_secours` add constraint pis_periode CHECK ((fin_validite > debut_validite));
alter table `personne_indicateur_secours` add constraint pis_personne CHECK ((num_nonnulls(employee_id, enfant_id) = 1));
alter table `premiums` add constraint premium_exempt_is_a_percenta CHECK (((exempt_pct >= (0)::numeric) AND (exempt_pct <= (100)::numeric)));
alter table `premiums` add constraint premiums_amount_check CHECK ((amount >= (0)::numeric));
alter table `public_holidays` add constraint holiday_year_matches_date CHECK (((EXTRACT(year FROM holiday_date))::integer = year));
alter table `ref_action_acces` add constraint raa_periode CHECK ((fin_validite > debut_validite));
alter table `ref_compensation_heures_sup` add constraint rchs_periode CHECK ((fin_validite > debut_validite));
alter table `ref_condition_travail` add constraint rct_periode CHECK ((fin_validite > debut_validite));
alter table `ref_indicateur_secours` add constraint ris_periode CHECK ((fin_validite > debut_validite));
alter table `ref_lien_enfant` add constraint rle_periode CHECK ((fin_validite > debut_validite));
alter table `ref_nature_prime` add constraint rnp_periode CHECK ((fin_validite > debut_validite));
alter table `ref_pays` add constraint rp_periode CHECK ((fin_validite > debut_validite));
alter table `ref_statut_heures_sup` add constraint rshs_periode CHECK ((fin_validite > debut_validite));
alter table `ref_statut_verification_adresse` add constraint rsva_periode CHECK ((fin_validite > debut_validite));
alter table `ref_sujet_export` add constraint rse_periode CHECK ((fin_validite > debut_validite));
alter table `ref_type_adresse` add constraint rta_periode CHECK ((fin_validite > debut_validite));
alter table `ref_unite_essai` add constraint rue_periode CHECK ((fin_validite > debut_validite));
alter table `ref_unite_prime` add constraint rup_periode CHECK ((fin_validite > debut_validite));
alter table `reference_periods` add constraint prl_range CHECK ((end_date > start_date));
alter table `reference_periods` add constraint reference_periods_months_pos CHECK ((months >= 1));
alter table `sanction_categories` add constraint sanction_categories_periode_ CHECK ((valid_to > valid_from));
alter table `sanction_categories` add constraint sanction_category_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `sanction_types` add constraint sanction_type_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `sanction_types` add constraint sanction_types_periode_valid CHECK ((valid_to > valid_from));
alter table `schedules` add constraint published_iff_timestamp CHECK (((status = 'published'::schedule_status) = (published_at IS NOT NULL)));
alter table `shift_templates` add constraint template_break_positive CHECK ((break_minutes >= 0));
alter table `shifts` add constraint shift_break_positive CHECK ((break_minutes >= 0));
alter table `shifts` add constraint shift_times_differ CHECK ((start_time <> end_time));
alter table `tax_brackets` add constraint bracket_range CHECK (((bracket_max IS NULL) OR (bracket_max > bracket_min)));
alter table `tax_brackets` add constraint bracket_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `tax_brackets` add constraint tax_brackets_periode_valide CHECK ((valid_to > valid_from));
alter table `tax_credits` add constraint credit_income_order CHECK (((income_max IS NULL) OR (income_min IS NULL) OR (income_max > income_min)));
alter table `tax_credits` add constraint credit_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `tax_credits` add constraint tax_credits_periode_valide CHECK ((valid_to > valid_from));
alter table `time_entries` add constraint time_entry_hours_positive CHECK (((break_minutes >= 0) AND ((worked_hours IS NULL) OR (worked_hours >= (0)::numeric)) AND ((planned_hours IS NULL) OR (planned_hours >= (0)::numeric)) AND (sunday_hours >= (0)::numeric) AND (holiday_hours >= (0)::numeric) AND (night_hours >= (0)::numeric) AND (overtime_hours >= (0)::numeric)));
alter table `time_entries` add constraint time_entry_parts_within_work CHECK (((worked_hours IS NULL) OR ((sunday_hours <= worked_hours) AND (holiday_hours <= worked_hours) AND (night_hours <= worked_hours) AND (overtime_hours <= worked_hours))));
alter table `travel_distances` add constraint travel_distance_positive CHECK ((distance_km >= (0)::numeric));
alter table `travel_distances` add constraint travel_distance_refs_differ CHECK ((origin_ref <> destination_ref));

-- ------------------------------------------------------------------
-- COMMENTAIRES — 75 table(s) et 836 colonne(s).
-- Repris tels quels du schéma PostgreSQL, qui fait foi.
-- ------------------------------------------------------------------
comment on table `absence_entitlements` is 'Droit ouvert par motif d''absence, daté. Un congé extraordinaire dont la durée change au fil des réformes porte ici plusieurs versions successives.';
comment on column `absence_entitlements`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `absence_entitlements`.`absence_type_id` is 'Type d''absence auquel ce droit se rapporte. Le droit est daté : un même type peut ouvrir un nombre de jours différent selon la période.';
comment on column `absence_entitlements`.`days` is 'Nombre de jours ouverts par événement.';
comment on column `absence_entitlements`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `absence_entitlements`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `absence_entitlements`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `absence_entitlements`.`frequency_note` is 'Condition de renouvellement exprimée en clair quand elle ne se réduit pas à un nombre.';
comment on column `absence_entitlements`.`career_cap_days` is 'Plafond sur toute la carrière, lorsque le droit n''est pas renouvelable indéfiniment.';
comment on column `absence_entitlements`.`block_days` is 'Durée du bloc indivisible lorsque le droit doit être pris d''un seul tenant.';
comment on column `absence_entitlements`.`period_months` is 'Fenêtre glissante sur laquelle le droit se reconstitue.';
comment on column `absence_entitlements`.`relationship_degree` is 'Degré de parenté exigé, pour les congés liés à un événement familial.';
comment on column `absence_entitlements`.`requires_evidence` is 'Vrai si un justificatif conditionne l''ouverture du droit.';
comment on column `absence_entitlements`.`note` is 'Précision sur l''origine du droit : disposition conventionnelle, usage d''entreprise, circonstance particulière. Lue par un humain, jamais par le moteur.';
comment on table `absence_types` is 'Catalogue des motifs d''absence : congés, maladie, congés extraordinaires, absences non rémunérées.';
comment on column `absence_types`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `absence_types`.`code` is 'Code stable du type d''absence, utilisé par le moteur et par les deux interfaces. Il ne change jamais : c''est le libellé qui se retouche, pas le code.';
comment on column `absence_types`.`label` is 'Libellé affiché du type d''absence, en français. Destiné à l''écran, jamais à une comparaison.';
comment on column `absence_types`.`category` is 'Famille d''absence, qui commande le traitement par le moteur.';
comment on column `absence_types`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `absence_types`.`requires_certificate` is 'Vrai si un justificatif est exigé pour que l''absence soit régulière.';
comment on column `absence_types`.`is_paid` is 'Vrai si l''absence est rémunérée par l''employeur.';
comment on column `absence_types`.`counts_against_leave` is 'Vrai si l''absence s''impute sur le solde de congé annuel.';
comment on table `absences` is 'Absence d''un salarié : congé, maladie, congé extraordinaire. Le moteur en contrôle le droit, l''imputation et les justificatifs.';
comment on column `absences`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `absences`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `absences`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `absences`.`absence_type_id` is 'Type d''absence demandé. Détermine les pièces exigées, le délai de certificat et l''imputation sur les compteurs.';
comment on column `absences`.`start_date` is 'Premier jour d''absence, inclus. Jour entier : une absence d''une demi-journée se compte par days_count, pas par les bornes.';
comment on column `absences`.`end_date` is 'Dernier jour d''absence, INCLUS — contrairement aux bornes de validité du référentiel, qui sont exclusives. Une absence d''un seul jour porte la même date en début et en fin.';
comment on column `absences`.`days_count` is 'Jours décomptés, calculés hors fériés et jours non ouvrés — pas la simple différence de dates.';
comment on column `absences`.`status` is 'Où en est la demande : proposé, en attente, validé, refusé, annulé. Un refus n''est jamais un point final — il doit s''accompagner d''une contre-proposition, chaînée par absence_parente_id.';
comment on column `absences`.`comment` is 'Motif ou précision donnée par le demandeur. Visible du salarié comme du gestionnaire : ce n''est pas une note interne.';
comment on column `absences`.`certificate_received` is 'Vrai dès réception du certificat, sous quelque forme que ce soit.';
comment on column `absences`.`certificate_received_at` is 'Date de réception du certificat, original ou copie. C''est elle qui arrête le décompte du délai CCSS, pas la date d''émission du certificat.';
comment on column `absences`.`certificate_document_id` is 'Pièce justificative rattachée. Sans clé étrangère stricte vers un document supprimé : l''absence reste lisible même si la pièce a été purgée.';
comment on column `absences`.`requested_by` is 'Compte à l''origine de la demande. Peut différer du salarié : un gestionnaire saisit pour un salarié sans accès, et il faut savoir qui a saisi.';
comment on column `absences`.`decided_by` is 'Auteur de la décision d''acceptation ou de refus.';
comment on column `absences`.`decided_at` is 'Horodatage de la décision. Avec decided_by, répond à « qui a tranché, et quand » — une validation d''absence est un acte opposable.';
comment on column `absences`.`decision_note` is 'Motivation de la décision, restituée au salarié.';
comment on column `absences`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `absences`.`declared_by_employee` is 'Vrai si la déclaration vient de l''espace salarié, faux si elle est saisie par les RH.';
comment on column `absences`.`certificate_uploaded_at` is 'Dépôt numérique du certificat par le salarié.';
comment on column `absences`.`certificate_original_received` is 'Réception de l''original papier, exigée séparément du dépôt numérique.';
comment on column `absences`.`certificate_original_received_at` is 'Date de réception de l''ORIGINAL papier. Distincte de la copie : la CCSS exige l''original, et seule cette date solde l''obligation.';
comment on column `absences`.`child_id` is 'Enfant concerné, pour un congé lié à un enfant.';
comment on column `absences`.`absence_parente_id` is 'Proposition que celle-ci remplace. Chaîne la demande initiale et les contre-propositions successives : c''est l''historique de la négociation, lisible dans les deux sens.';
comment on column `absences`.`proposee_par` is 'Qui a formulé cette proposition : « salarie » pour la demande initiale, « employeur » pour une contre-proposition.';
comment on column `absences`.`rang_proposition` is 'Profondeur dans la chaîne. Zéro pour la demande initiale. Borné, pour qu''une négociation sans fin ne soit pas possible.';
comment on table `address_checks` is 'Dernier verdict de validation d''adresse par objet. Une adresse « unknown » y reste visible : c''est ce qui permet de la reprendre plus tard, plutôt que de la croire vérifiée.';
comment on column `address_checks`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `address_checks`.`entity_table` is 'Table de la ligne vérifiée — employees, companies, client_sites. Le contrôle d''adresse est le même pour toutes ; cette colonne dit d''où vient celle-ci.';
comment on column `address_checks`.`entity_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `address_checks`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `address_checks`.`country` is 'Code pays ISO 3166-1 alpha-3.';
comment on column `address_checks`.`postal_code` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `address_checks`.`status` is 'Résultat du contrôle, parmi ref_statut_verification_adresse : vérifiée, incohérente, hors périmètre, non vérifiable. « Non vérifiable » est un résultat, pas un échec : LuxRH ne couvre que le Luxembourg et les zones frontalières déclarées.';
comment on column `address_checks`.`zone_code` is 'Zone reconnue pour cette adresse : Luxembourg, ou zone frontalière déclarée. Détermine le régime de frontalier et les barèmes applicables.';
comment on column `address_checks`.`message` is 'Explication du résultat, destinée à l''humain qui corrigera. Une adresse rejetée sans motif ne se corrige pas.';
comment on column `address_checks`.`checked_at` is 'Date du contrôle. Un référentiel postal évolue : un contrôle ancien ne vaut pas contrôle actuel.';
comment on table `address_zones` is 'Zones géographiques dans lesquelles une adresse est acceptée. Hors de ces zones, la saisie est refusée : l''outil ne prétend pas couvrir des adresses qu''il ne sait pas vérifier.';
comment on column `address_zones`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `address_zones`.`country` is 'Code pays ISO 3166-1 alpha-3. Trois lettres partout dans l''application.';
comment on column `address_zones`.`kind` is 'Nature de la zone : pays, région frontalière, plage de codes postaux. Détermine comment les bornes se lisent.';
comment on column `address_zones`.`code` is 'Code de la zone, repris par address_checks.zone_code et par les barèmes qui s''y réfèrent.';
comment on column `address_zones`.`label` is 'Nom lisible de la zone, pour l''affichage et les messages de contrôle.';
comment on column `address_zones`.`postal_from` is 'Borne basse du code postal, une fois le préfixe pays retiré. Nulle quand le pays n''admet pas de découpage postal fiable — voir is_verified.';
comment on column `address_zones`.`postal_to` is 'Borne haute INCLUSE de la plage de codes postaux couverte. Nulle si la zone ne se décrit pas par une plage.';
comment on column `address_zones`.`is_verified` is 'Vrai si les bornes postales sont établies et vérifiables. Faux pour une zone déclarée sans correspondance postale fiable : la validation répond alors « indéterminé » plutôt que d''accepter à tort.';
comment on column `address_zones`.`source` is 'D''où viennent les bornes. Une zone sans source n''a rien à faire ici.';
comment on column `address_zones`.`note` is 'Origine de la délimitation : convention, accord frontalier, choix de paramétrage. Ce qui permet de la contester.';
comment on table `adresses_salarie` is 'Les quatre adresses du salarié, historisées. Chaque type doit couvrir toute la période sans trou ni recouvrement, depuis la candidature jusqu''à bien après le départ : une erreur de salaire découverte plus tard suppose de pouvoir écrire à la personne.';
comment on column `adresses_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `adresses_salarie`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `adresses_salarie`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `adresses_salarie`.`type_adresse` is 'Nature de l''adresse, parmi ref_type_adresse : domicile légal, résidence effective, correspondance, facturation. Les quatre doivent être couvertes sans trou depuis la candidature jusqu''après le départ — une erreur de salaire découverte plus tard doit pouvoir être notifiée.';
comment on column `adresses_salarie`.`ligne` is 'Rue et numéro. Une seule ligne : le découpage varie trop d''un pays à l''autre pour être imposé.';
comment on column `adresses_salarie`.`code_postal` is 'Code postal. Confronté au référentiel des localités : un code incohérent est signalé, jamais corrigé d''office.';
comment on column `adresses_salarie`.`localite` is 'Localité, telle qu''elle doit figurer sur un courrier.';
comment on column `adresses_salarie`.`pays` is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU. Trois lettres partout dans l''application.';
comment on column `adresses_salarie`.`latitude` is 'Latitude en degrés décimaux, obtenue par géocodage. Sert au calcul des distances de tournée et à l''indemnité kilométrique ; nulle tant que l''adresse n''a pas été géocodée.';
comment on column `adresses_salarie`.`longitude` is 'Longitude en degrés décimaux. Voir latitude : le couple n''a de sens que complet.';
comment on column `adresses_salarie`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `adresses_salarie`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `adresses_salarie`.`origine` is 'D''où vient la ligne : « saisie » pour une saisie directe, « copie_domicile » pour une recopie automatique du domicile légal, « import » pour une reprise.';
comment on column `adresses_salarie`.`note` is 'Précision de livraison ou de contact : étage, digicode, « chez ». Jamais une donnée de calcul.';
comment on column `adresses_salarie`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `adresses_salarie`.`created_by` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `adresses_salarie`.`deleted_at` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `adresses_salarie`.`deleted_by` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `app_secrets` is 'Clés de chiffrement du moteur. RLS active et VOLONTAIREMENT sans aucune politique : aucune ligne n''est donc accessible par l''API REST. Seules les fonctions security definer fn_encrypt_field et fn_decrypt_field y accèdent, et ces deux fonctions ne sont exécutables par personne hors du moteur.';
comment on column `app_secrets`.`key` is 'Nom du secret. La table porte RLS active et VOLONTAIREMENT aucune politique : aucune ligne n''est accessible par l''API REST, seules les fonctions security definer du moteur y accèdent.';
comment on column `app_secrets`.`secret` is 'Valeur du secret. Voir la remarque sur la table : elle n''est lisible par personne à travers l''API. Un secret qui vit dans la base qu''il protège reste un compromis assumé et documenté.';
comment on table `app_users` is 'Comptes applicatifs. Point d''ancrage commun aux trois moteurs : sur PostgreSQL elle reflète auth.users et password_hash reste nul, l''authentification appartenant à Supabase ; sur Oracle et MySQL elle porte le mot de passe et devient la table d''identité vers laquelle pointent les clés étrangères d''auteur.';
comment on column `app_users`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `app_users`.`userid` is 'Identifiant de connexion, en minuscules. Unique parmi les comptes vivants seulement : un identifiant libéré par une suppression logique peut être réattribué.';
comment on column `app_users`.`email` is 'Adresse de connexion et de notification. Unique : c''est elle qui identifie le compte pour la récupération de mot de passe.';
comment on column `app_users`.`full_name` is 'Nom affiché du compte. Modifiable par l''intéressé en libre-service, contrairement aux données d''identité du dossier salarié.';
comment on column `app_users`.`password_hash` is 'Empreinte bcrypt du mot de passe. NUL sur PostgreSQL/Supabase, où Auth détient le secret. Jamais le mot de passe en clair, à aucun moment.';
comment on column `app_users`.`is_admin` is 'Administrateur : seul habilité à lire le catalogue du schéma et à créer d''autres comptes.';
comment on column `app_users`.`auth_user_id` is 'Compte auth.users correspondant, quand l''application tourne sur Supabase. Nul sur une cible autonome.';
comment on column `app_users`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `app_users`.`created_by` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `app_users`.`updated_at` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column `app_users`.`updated_by` is 'Compte auteur de la dernière modification. Sur une table de comptes, savoir qui a changé quoi n''est pas optionnel.';
comment on column `app_users`.`deleted_at` is 'Suppression logique : la ligne reste, les clés étrangères qui la référencent tiennent, et le journal demeure lisible. Un compte parti doit encore pouvoir répondre de ce qu''il a fait.';
comment on column `app_users`.`deleted_by` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `audit_log` is 'Journal des écritures, alimenté par le déclencheur fn_audit. Conservé pour la traçabilité et la preuve, jamais modifié par l''application.';
comment on column `audit_log`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `audit_log`.`occurred_at` is 'Horodatage de l''écriture auditée, posé par la base au moment du déclencheur. Ce n''est pas une date saisie : elle ne se retouche pas.';
comment on column `audit_log`.`actor_id` is 'Compte auteur de l''écriture. Nul pour une opération de maintenance exécutée hors session applicative — cas rare, qui doit rester visible plutôt que d''être attribué à tort.';
comment on column `audit_log`.`actor_label` is 'Nom de l''auteur figé au moment du fait : le journal reste lisible après suppression du compte.';
comment on column `audit_log`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `audit_log`.`entity_table` is 'Nom de la table concernée : le journal est polymorphe, sans clé étrangère.';
comment on column `audit_log`.`entity_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `audit_log`.`action` is 'Nature de l''écriture : insert, update, delete. La suppression enregistrée ici est logique ; une ligne n''est jamais retirée de la base.';
comment on column `audit_log`.`old_value` is 'État de la ligne avant écriture, en jsonb. Nul pour une insertion.';
comment on column `audit_log`.`new_value` is 'État de la ligne après écriture. Nul pour une suppression.';
comment on column `audit_log`.`source_ip` is 'Adresse d''origine de la requête, telle que rapportée par les en-têtes HTTP. Donnée déclarative : elle situe, elle ne prouve pas.';
comment on column `audit_log`.`user_agent` is 'Agent utilisateur de l''appelant, tronqué à 400 caractères.';
comment on column `audit_log`.`request_id` is 'Identifiant de requête, pour recouper une trace avec les journaux d''infrastructure.';
comment on table `benefit_types` is 'Catalogue des avantages en nature et de leur méthode d''évaluation.';
comment on column `benefit_types`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `benefit_types`.`code` is 'Code de l''avantage en nature, stable, utilisé par la paie.';
comment on column `benefit_types`.`label` is 'Libellé de l''avantage à l''écran et sur le bulletin.';
comment on column `benefit_types`.`valuation_method` is 'Méthode d''évaluation : forfait, pourcentage, barème.';
comment on column `benefit_types`.`is_taxable` is 'Vrai si l''avantage entre dans l''assiette imposable.';
comment on column `benefit_types`.`is_contributory` is 'Vrai si l''avantage entre dans l''assiette cotisable.';
comment on column `benefit_types`.`valuation_params` is 'Paramètres de la méthode. Les valeurs légales elles-mêmes restent dans legal_parameters.';
comment on column `benefit_types`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `benefit_types`.`note` is 'Mode d''évaluation de l''avantage et texte qui le fonde.';
comment on table `cba_rules` is 'Contenu d''une convention, bloc par bloc, en jsonb. C''est ce que le moteur compare à la loi pour retenir la disposition la plus favorable.';
comment on column `cba_rules`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `cba_rules`.`collective_agreement_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `cba_rules`.`block` is 'Domaine couvert par le bloc (temps de travail, congés, préavis, rémunération...).';
comment on column `cba_rules`.`rules` is 'Clauses du bloc, structurées. Une clause absente n''est pas une clause nulle : elle est inconnue.';
comment on column `cba_rules`.`is_complete` is 'Faux tant que le bloc n''a pas été entièrement saisi : le moteur sait alors qu''il ne peut pas conclure sur ce domaine.';
comment on column `cba_rules`.`updated_at` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on table `cba_salary_grids` is 'Grille de salaires conventionnelle : montant minimal par catégorie et par ancienneté.';
comment on column `cba_salary_grids`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `cba_salary_grids`.`collective_agreement_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `cba_salary_grids`.`category` is 'Catégorie professionnelle de la grille, dans les termes de la convention. C''est elle qui relie un poste à un minimum conventionnel.';
comment on column `cba_salary_grids`.`seniority_from_years` is 'Ancienneté à partir de laquelle l''échelon s''applique.';
comment on column `cba_salary_grids`.`seniority_to_years` is 'Ancienneté au-delà de laquelle l''échelon cesse. Nul pour le dernier échelon.';
comment on column `cba_salary_grids`.`monthly_amount` is 'Salaire mensuel minimum de la catégorie, en euros, à l''indice de référence de la convention. Le moteur l''indexe avant de le comparer au salaire réel.';
comment on column `cba_salary_grids`.`index_ref` is 'Cote d''indice à laquelle le montant est exprimé, pour le réindexer correctement.';
comment on table `cct_regle_prime` is 'Règle de prime de condition telle que la convention collective la fixe. Aucune valeur légale générale ici : la loi ne définit pas ces primes, seules les CCT le font. Une règle sans source_url est refusée — elle ne pourrait pas être vérifiée.';
comment on column `cct_regle_prime`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `cct_regle_prime`.`collective_agreement_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `cct_regle_prime`.`condition_code` is 'Condition matérielle ouvrant droit à la prime, parmi ref_condition_travail : pénibilité, insalubrité, danger. Ces primes ne sont pas prévues par la loi générale — ce sont les conventions sectorielles qui les fixent.';
comment on column `cct_regle_prime`.`nature_prime` is 'Nature de la prime, parmi ref_nature_prime. Détermine son traitement fiscal et social.';
comment on column `cct_regle_prime`.`libelle` is 'Intitulé de la règle tel qu''il apparaît dans la convention. Repris dans le détail du calcul, pour que le montant soit rattachable à son article.';
comment on column `cct_regle_prime`.`taux_pct` is 'Taux appliqué à l''assiette. Exclusif du montant : une règle qui porterait les deux serait ambiguë, et la contrainte l''interdit.';
comment on column `cct_regle_prime`.`montant` is 'Montant forfaitaire en euros, par unité. Exclusif de taux_pct : une règle est soit un forfait, soit un pourcentage, jamais les deux.';
comment on column `cct_regle_prime`.`assiette` is 'Base sur laquelle s''applique le pourcentage : salaire mensuel ou salaire horaire. Obligatoire dès qu''un taux est fixé ; une assiette que le moteur ne sait pas résoudre ressort en « non calculable » plutôt qu''en zéro.';
comment on column `cct_regle_prime`.`unite` is 'Ce à quoi la prime se rapporte, parmi ref_unite_prime : heure exposée, jour, mois, ou prestation. Détermine comment le temps relevé se convertit en montant.';
comment on column `cct_regle_prime`.`seuil_minutes` is 'Durée minimale d''exposition ouvrant le droit. Zéro si la moindre minute compte.';
comment on column `cct_regle_prime`.`categorie_visee` is 'Catégorie professionnelle à laquelle la règle se limite. Nulle si la règle vaut pour tous les salariés couverts par la convention.';
comment on column `cct_regle_prime`.`article` is 'Article de la convention qui fonde la règle. C''est lui que l''application cite au salarié.';
comment on column `cct_regle_prime`.`source_url` is 'Lien vers le texte déposé — les conventions luxembourgeoises sont publiées par l''ITM. Obligatoire.';
comment on column `cct_regle_prime`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `cct_regle_prime`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `cct_regle_prime`.`note` is 'Précisions d''application : cumul, proratisation, exclusions. Ce que l''article dit et que les colonnes ne portent pas.';
comment on table `client_sites` is 'Lieu où une vacation peut s''exécuter hors du siège : chantier, site client, antenne. Porte l''adresse qui sert au calcul de distance.';
comment on column `client_sites`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `client_sites`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `client_sites`.`name` is 'Nom du site client, tel qu''il apparaît sur les plannings et les ordres de mission.';
comment on column `client_sites`.`client_name` is 'Nom du client donneur d''ordre, distinct du nom du site.';
comment on column `client_sites`.`address_line` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `client_sites`.`postal_code` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `client_sites`.`city` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `client_sites`.`country` is 'Pays du site, en code ISO 3166-1 alpha-3.';
comment on column `client_sites`.`latitude` is 'Coordonnée, si elle est connue : elle évite de transmettre une adresse en clair au service de distance.';
comment on column `client_sites`.`longitude` is 'Longitude en degrés décimaux, obtenue par géocodage. Avec la latitude, permet de calculer la distance depuis l''adresse du salarié.';
comment on column `client_sites`.`is_active` is 'Faux quand le site n''est plus desservi. Le site reste en base : les plannings passés le nomment encore.';
comment on column `client_sites`.`note` is 'Consignes d''accès et contraintes du site. Lues par qui s''y rend, pas par le moteur.';
comment on column `client_sites`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `collective_agreements` is 'Convention collective de travail. Sectorielle et partagée, ou propre à une organisation.';
comment on column `collective_agreements`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `collective_agreements`.`organization_id` is 'Nul pour une convention sectorielle partagée par toutes les organisations.';
comment on column `collective_agreements`.`code` is 'Code court, clé naturelle utilisée par l''export et l''import du référentiel.';
comment on column `collective_agreements`.`name` is 'Intitulé officiel de la convention, tel que publié par l''ITM.';
comment on column `collective_agreements`.`sector` is 'Secteur couvert. Sert à proposer la bonne convention lors du rattachement d''une société, jamais à l''imposer.';
comment on column `collective_agreements`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `collective_agreements`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `collective_agreements`.`is_active` is 'Faux quand la convention est dénoncée ou remplacée. Elle reste en base : une paie ancienne doit encore pouvoir citer la convention qui la fondait.';
comment on column `collective_agreements`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `collective_agreements`.`scope` is 'Portée : sectorielle, d''entreprise, ou d''établissement.';
comment on column `collective_agreements`.`supersedes_id` is 'Convention que celle-ci remplace, pour suivre les renouvellements.';
comment on column `collective_agreements`.`employee_category` is 'Catégorie de personnel visée lorsque la convention ne couvre pas tout l''effectif.';
comment on table `companies` is 'Société employeuse. Deuxième clé d''isolation après l''organisation : la quasi-totalité des tables métier porte un company_id.';
comment on column `companies`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `companies`.`organization_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `companies`.`legal_name` is 'Raison sociale, telle qu''inscrite au registre de commerce. C''est ce nom qui figure sur les contrats et les bulletins.';
comment on column `companies`.`legal_form` is 'Forme juridique (Sàrl, SA, etc.). Sans effet sur le moteur, utile aux documents.';
comment on column `companies`.`rcs_number` is 'Numéro au Registre de commerce et des sociétés.';
comment on column `companies`.`ccss_matricule` is 'Matricule CCSS de l''employeur. Validé par fn_check_national_id (longueur, date encodée, clés de Luhn et de Verhoeff).';
comment on column `companies`.`address_line` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `companies`.`postal_code` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `companies`.`city` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `companies`.`country` is 'Pays du siège, en code ISO 3166-1 alpha-3. Le projet utilise partout l''alpha-3, y compris là où l''alpha-2 suffirait : un seul format évite les conversions silencieuses.';
comment on column `companies`.`nace_code` is 'Code d''activité NACE, base du rattachement sectoriel et de la classe de risque accident.';
comment on column `companies`.`sector` is 'Secteur déclaré. Sert au rapprochement avec les conventions collectives sectorielles.';
comment on column `companies`.`reference_period_months` is 'Durée par défaut de la période de référence pour le calcul du temps de travail, si aucune période explicite n''est définie.';
comment on column `companies`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `companies`.`internal_rules_adopted_on` is 'Date d''adoption des textes internes de l''entreprise. Sans eux, aucune sanction lourde n''est valable — le moteur le vérifie.';
comment on column `companies`.`internal_rules_reference` is 'Référence et date d''adoption du règlement intérieur. Une sanction lourde n''est valable que si elle y figure : sans cette référence, le moteur le signale.';
comment on table `company_accident_claims` is 'Sinistralité accident déclarée par exercice. Alimente le suivi du facteur bonus-malus.';
comment on column `company_accident_claims`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `company_accident_claims`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `company_accident_claims`.`year` is 'Année de survenance des sinistres, pour le calcul du bonus-malus accident du travail.';
comment on column `company_accident_claims`.`claim_count` is 'Nombre de sinistres déclarés.';
comment on column `company_accident_claims`.`days_lost` is 'Journées de travail perdues sur l''exercice.';
comment on column `company_accident_claims`.`cost` is 'Coût des sinistres de l''année, en euros. Entre dans la détermination de la classe de risque et donc du taux de cotisation accident.';
comment on column `company_accident_claims`.`note` is 'Précisions sur les sinistres retenus ou exclus.';
comment on table `company_collective_agreements` is 'Rattachement d''une société, ou d''un de ses services, à une convention collective, sur une période donnée. Une société peut en appliquer plusieurs simultanément.';
comment on column `company_collective_agreements`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `company_collective_agreements`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `company_collective_agreements`.`collective_agreement_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `company_collective_agreements`.`department_id` is 'Nul si la convention couvre toute la société.';
comment on column `company_collective_agreements`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `company_collective_agreements`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `company_collective_agreements`.`note` is 'Circonstances du rattachement de la société à la convention : adhésion, extension, usage. Ce qui permet de le contester.';
comment on column `company_collective_agreements`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `company_financials` is 'Résultats annuels de la société. Sert au calcul de l''enveloppe des primes participatives, plafonnée sur le bénéfice de l''exercice précédent.';
comment on column `company_financials`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `company_financials`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `company_financials`.`fiscal_year` is 'Exercice comptable concerné, en année pleine.';
comment on column `company_financials`.`profit` is 'Bénéfice de l''exercice, assiette du plafond d''enveloppe.';
comment on column `company_financials`.`revenue` is 'Chiffre d''affaires de l''exercice, en euros. Sert aux seuils qui dépendent de la taille de l''entreprise.';
comment on column `company_financials`.`source` is 'Origine du chiffre : comptes annuels, situation intermédiaire.';
comment on column `company_financials`.`note` is 'Origine du chiffre : comptes déposés, estimation, déclaration. Un seuil calculé sur une estimation ne se traite pas comme un seuil calculé sur des comptes.';
comment on column `company_financials`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `company_rate_periods` is 'Historique des taux propres à la société : classe de mutualité, facteur accident, classe d''activité. Un recalcul lit le taux en vigueur à la date du calcul.';
comment on column `company_rate_periods`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `company_rate_periods`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `company_rate_periods`.`activity_class` is 'Classe d''activité déclarée à la CCSS.';
comment on column `company_rate_periods`.`accident_risk_class` is 'Classe de risque accident attribuée à la société.';
comment on column `company_rate_periods`.`accident_factor` is 'Facteur bonus-malus de l''assurance accident.';
comment on column `company_rate_periods`.`mutuality_class` is 'Classe de la Mutualité des employeurs, qui commande le taux de cotisation.';
comment on column `company_rate_periods`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `company_rate_periods`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `company_rate_periods`.`source` is 'Origine du taux : courrier CCSS, décision de classement. Obligatoire.';
comment on column `company_rate_periods`.`note` is 'Origine du taux appliqué sur la période : notification de l''organisme, classe de risque, régularisation.';
comment on column `company_rate_periods`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `compliance_alerts` is 'Constats du moteur de vigilance. Chaque alerte porte son article : c''est ce qui distingue un avertissement d''une injonction opaque.';
comment on column `compliance_alerts`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `compliance_alerts`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `compliance_alerts`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `compliance_alerts`.`rule_code` is 'Code stable de la règle, pour suivre une alerte à travers les scans successifs.';
comment on column `compliance_alerts`.`title` is 'Intitulé court de l''alerte, tel qu''il apparaît dans la liste de vigilance.';
comment on column `compliance_alerts`.`detail` is 'Explication complète : ce qui manque, pourquoi c''est exigé, et ce qu''il faut faire. Une alerte qui ne dit pas quoi faire ne sera pas traitée.';
comment on column `compliance_alerts`.`consequence` is 'Ce qui arrive si rien n''est fait — sanction, requalification, nullité.';
comment on column `compliance_alerts`.`legal_ref` is 'Article qui fonde le constat.';
comment on column `compliance_alerts`.`severity` is 'Gravité, qui commande le tri et la couleur à l''écran.';
comment on column `compliance_alerts`.`due_date` is 'Échéance à laquelle le manquement devient effectif.';
comment on column `compliance_alerts`.`state` is 'État de traitement : ouverte, traitée, écartée.';
comment on column `compliance_alerts`.`handled_by` is 'Compte ayant traité l''alerte. Nul tant qu''elle est ouverte.';
comment on column `compliance_alerts`.`handled_at` is 'Date de traitement. Avec handled_by, permet de mesurer le délai de réaction — la sévérité CCSS s''appuie dessus.';
comment on column `compliance_alerts`.`handled_note` is 'Justification de la prise en charge ou de la mise à l''écart.';
comment on column `compliance_alerts`.`first_seen_at` is 'Première apparition du constat, conservée même si l''alerte réapparaît.';
comment on table `contract_amendments` is 'Avenant. Conserve ce qui a changé et à partir de quand, sans écraser l''état antérieur du contrat.';
comment on column `contract_amendments`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contract_amendments`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `contract_amendments`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `contract_amendments`.`effective_date` is 'Prise d''effet, qui peut différer de la signature.';
comment on column `contract_amendments`.`reason` is 'Motif de l''avenant, obligatoire. Un avenant sans motif est refusé par le moteur : c''est la pièce qui explique, des années après, pourquoi le contrat a changé.';
comment on column `contract_amendments`.`changes` is 'Différentiel appliqué, en jsonb : ce que l''avenant modifie, et rien d''autre.';
comment on column `contract_amendments`.`created_by` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `contract_amendments`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `contract_collective_agreements` is 'Conventions applicables à un contrat donné, sur une période. Plusieurs conventions peuvent se cumuler ; le moteur retient la disposition la plus favorable et dit laquelle a gagné.';
comment on column `contract_collective_agreements`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contract_collective_agreements`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `contract_collective_agreements`.`collective_agreement_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `contract_collective_agreements`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `contract_collective_agreements`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `contract_collective_agreements`.`note` is 'Circonstances du rattachement au niveau du contrat, quand il déroge à celui de la société.';
comment on column `contract_collective_agreements`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `contract_pay_components` is 'Éléments de rémunération autres que le brut de base : primes récurrentes, avantages, indemnités.';
comment on column `contract_pay_components`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contract_pay_components`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `contract_pay_components`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `contract_pay_components`.`kind` is 'Nature de l''élément, qui commande son traitement fiscal et social.';
comment on column `contract_pay_components`.`code` is 'Code de l''élément de rémunération : prime, indemnité, avantage. Stable, repris par la paie.';
comment on column `contract_pay_components`.`label` is 'Libellé de l''élément tel qu''il apparaît sur le bulletin.';
comment on column `contract_pay_components`.`amount` is 'Montant en euros. Nul quand l''élément se calcule au lieu d''être forfaitaire — un zéro dirait autre chose.';
comment on column `contract_pay_components`.`rate_pct` is 'Taux, pour un élément exprimé en pourcentage plutôt qu''en montant.';
comment on column `contract_pay_components`.`basis` is 'Assiette à laquelle le taux s''applique.';
comment on column `contract_pay_components`.`periodicity` is 'Périodicité de versement.';
comment on column `contract_pay_components`.`in_salary_reference` is 'Vrai si l''élément entre dans le salaire de référence servant au calcul des indemnités.';
comment on column `contract_pay_components`.`is_taxable` is 'Vrai si l''élément entre dans l''assiette imposable. Une prime exonérée mal marquée fausse la retenue à la source.';
comment on column `contract_pay_components`.`is_contributory` is 'Vrai si l''élément entre dans l''assiette des cotisations sociales. Indépendant de is_taxable : les deux assiettes ne coïncident pas.';
comment on column `contract_pay_components`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `contract_pay_components`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `contract_pay_components`.`note` is 'Fondement de l''élément : article de convention, usage, accord individuel. Ce qui permet de le défendre ou de le supprimer.';
comment on column `contract_pay_components`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `contract_pay_components`.`benefit_type_id` is 'Avantage en nature du catalogue, lorsque l''élément en est un.';
comment on table `contract_terminations` is 'Rupture du contrat : motif, préavis, indemnités. Le moteur contrôle la licéité avant que la rupture ne soit enregistrée.';
comment on column `contract_terminations`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contract_terminations`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `contract_terminations`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `contract_terminations`.`reason` is 'Motif de la rupture, obligatoire. Détermine le préavis, l''indemnité de départ et la possibilité de contester.';
comment on column `contract_terminations`.`is_personal_ground` is 'Vrai pour un motif personnel, faux pour un motif économique — la distinction commande la procédure de licenciement collectif.';
comment on column `contract_terminations`.`notified_on` is 'Date de notification, point de départ du préavis.';
comment on column `contract_terminations`.`notice_start` is 'Début effectif du préavis, qui suit des règles de calendrier propres.';
comment on column `contract_terminations`.`notice_end` is 'Fin du préavis.';
comment on column `contract_terminations`.`severance_months` is 'Indemnité de départ, exprimée en mois de salaire de référence.';
comment on column `contract_terminations`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `contract_terminations`.`notice_waived` is 'Vrai si les parties ont convenu de dispenser le préavis.';
comment on column `contract_terminations`.`waiver_agreed_on` is 'Date de l''accord de renonciation au préavis, s''il y en a un. Nulle en l''absence d''accord : le préavis court alors en entier.';
comment on column `contract_terminations`.`waiver_compensation` is 'Contrepartie financière de la dispense de préavis.';
comment on column `contract_terminations`.`waiver_note` is 'Contenu de l''accord de renonciation, dans les termes convenus. Une renonciation se prouve.';
comment on column `contract_terminations`.`is_gross_misconduct` is 'Faute grave : supprime le préavis, sous conditions strictes de procédure.';
comment on table `contracts` is 'Contrat de travail. Le brouillon vit ici dès la première étape de l''assistant : c''est cette ligne que le moteur évalue, pas un objet en mémoire du navigateur.';
comment on column `contracts`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contracts`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `contracts`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `contracts`.`kind` is 'Type de contrat : CDI, CDD, apprentissage, saisonnier, intérim, étudiant. Commande les clauses obligatoires et les contrôles.';
comment on column `contracts`.`status` is 'Brouillon, actif, terminé. Un brouillon n''engage rien mais se contrôle déjà.';
comment on column `contracts`.`job_title` is 'Intitulé du poste tel qu''il figure au contrat. Mention obligatoire : il fonde la classification conventionnelle, et donc le salaire minimum applicable.';
comment on column `contracts`.`job_description` is 'Description des fonctions. Sa précision détermine ce qu''un changement de tâches doit faire passer par un avenant plutôt que par une simple instruction.';
comment on column `contracts`.`work_place` is 'Lieu d''exécution convenu. Mention obligatoire au contrat.';
comment on column `contracts`.`category` is 'Catégorie professionnelle, clé d''entrée dans la grille salariale conventionnelle.';
comment on column `contracts`.`start_date` is 'Prise d''effet du contrat, jour inclus. Point de départ de l''ancienneté, de la période d''essai et du droit à congé.';
comment on column `contracts`.`end_date` is 'Dernier jour du contrat, INCLUS. Nulle pour un contrat à durée indéterminée en cours. Un avenant clôt le contrat précédent la veille de sa prise d''effet.';
comment on column `contracts`.`cdd_reason` is 'Motif de recours au CDD. Un CDD sans motif licite est requalifiable.';
comment on column `contracts`.`renewal_count` is 'Nombre de renouvellements déjà consommés, borné par la loi.';
comment on column `contracts`.`previous_contract_id` is 'Contrat que celui-ci renouvelle, pour reconstituer la chaîne et l''ancienneté.';
comment on column `contracts`.`monthly_gross` is 'Salaire mensuel brut convenu, hors éléments variables portés par contract_pay_components.';
comment on column `contracts`.`index_ref` is 'Cote d''indice à la signature, pour distinguer une hausse réelle d''une indexation.';
comment on column `contracts`.`weekly_hours` is 'Durée hebdomadaire convenue. Sous le plein temps, is_part_time devient vrai.';
comment on column `contracts`.`days_per_week` is 'Nombre de jours travaillés par semaine, décimal pour les rythmes irréguliers.';
comment on column `contracts`.`work_distribution` is 'Répartition convenue de l''horaire. Mention obligatoire au contrat pour un temps partiel.';
comment on column `contracts`.`reference_period_months` is 'Période de référence propre au contrat, si elle déroge à celle de la société.';
comment on column `contracts`.`night_work` is 'Vrai si le poste comporte du travail de nuit, qui ouvre ses propres protections.';
comment on column `contracts`.`annual_leave_days` is 'Congé annuel convenu lorsqu''il dépasse le minimum légal. Nul renvoie au droit commun.';
comment on column `contracts`.`break_minutes` is 'Pause convenue par journée de travail.';
comment on column `contracts`.`non_compete_clause` is 'Présence d''une clause de non-concurrence, dont la validité est soumise à conditions.';
comment on column `contracts`.`exclusivity_clause` is 'Présence d''une clause d''exclusivité.';
comment on column `contracts`.`probation_length` is 'Durée de la période d''essai, exprimée dans l''unité portée par probation_unit.';
comment on column `contracts`.`probation_unit` is 'Unité de la période d''essai : mois ou semaines. Les bornes légales diffèrent selon l''unité.';
comment on column `contracts`.`version` is 'Version du contrat, incrémentée par les avenants.';
comment on column `contracts`.`signed_at` is 'Date de signature. Un contrat actif sans date de signature est un manquement.';
comment on column `contracts`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `contracts`.`is_part_time` is 'Temps partiel, tenu à jour par le déclencheur fn_sync_part_time — ne pas écrire à la main.';
comment on column `contracts`.`apprenticeship_level` is 'Niveau de la formation, pour un contrat d''apprentissage.';
comment on column `contracts`.`apprenticeship_year` is 'Année du cycle d''apprentissage, qui commande l''indemnité.';
comment on column `contracts`.`season_label` is 'Saison couverte, pour un contrat saisonnier.';
comment on column `contracts`.`interim_agency_id` is 'Agence d''intérim employeuse, pour un contrat de mission.';
comment on column `contracts`.`user_company_name` is 'Société utilisatrice chez qui la mission s''exécute.';
comment on column `contracts`.`mission_reason` is 'Motif de recours à l''intérim, soumis aux mêmes exigences que le motif de CDD.';
comment on table `creneau_condition` is 'Créneau réellement travaillé sous une condition ouvrant droit à prime : qui, quand, où, de quelle heure à quelle heure. C''est ce relevé qui rend la prime calculable — sans lui, la règle conventionnelle reste lettre morte.';
comment on column `creneau_condition`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `creneau_condition`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `creneau_condition`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `creneau_condition`.`shift_id` is 'Vacation planifiée. Le créneau se saisit au planning, puis se confirme au registre du temps.';
comment on column `creneau_condition`.`time_entry_id` is 'Journée du registre du temps. C''est elle qui fait foi pour le paiement, le planning n''étant qu''une prévision.';
comment on column `creneau_condition`.`client_site_id` is 'Site client où la condition a été constatée. Nul pour une condition constatée dans les locaux de l''employeur.';
comment on column `creneau_condition`.`condition_code` is 'Condition constatée, parmi ref_condition_travail. C''est le constat qui ouvre le droit, pas le poste : un même salarié peut être exposé un jour et pas le lendemain.';
comment on column `creneau_condition`.`date_prestation` is 'Jour de la prestation. La règle conventionnelle applicable est celle en vigueur ce jour-là, pas celle d''aujourd''hui.';
comment on column `creneau_condition`.`heure_debut` is 'Heure de début d''exposition. Avec heure_fin, donne la durée qui sert au seuil et à la conversion en montant.';
comment on column `creneau_condition`.`heure_fin` is 'Heure de fin d''exposition. Un créneau ne franchit pas minuit : une exposition de nuit se saisit en deux créneaux.';
comment on column `creneau_condition`.`minutes` is 'Durée exposée, calculée par la base. Un créneau qui franchit minuit est compté correctement.';
comment on column `creneau_condition`.`constate_par` is 'Compte ayant constaté la condition. Une prime de pénibilité repose sur un constat : il a un auteur.';
comment on column `creneau_condition`.`note` is 'Circonstances du constat. Utile en cas de contestation, jamais utilisée par le calcul.';
comment on column `creneau_condition`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `creneau_condition`.`deleted_at` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `creneau_condition`.`deleted_by` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `data_access_log` is 'Journal des consultations de données personnelles. Complète audit_log, qui ne voit que les écritures : ici sont tracés les accès en LECTURE aux données sensibles, les déchiffrements et les téléchargements de pièces. Répond aux questions qui / quoi / quand / d''où pour une personne donnée.';
comment on column `data_access_log`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `data_access_log`.`occurred_at` is 'Horodatage de la LECTURE. Ce journal répond au « quand » de l''article 15 du RGPD : à quel moment les données d''une personne ont été consultées.';
comment on column `data_access_log`.`actor_id` is 'Compte ayant lu. Répond au « par qui ». Renseigné par le serveur à partir de la session, jamais déclaré par l''appelant.';
comment on column `data_access_log`.`actor_label` is 'Nom de l''auteur figé au moment de l''accès : la trace reste lisible après suppression du compte.';
comment on column `data_access_log`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `data_access_log`.`subject_employee_id` is 'La personne DONT les données ont été vues — à ne pas confondre avec actor_id, qui est celle qui les a vues.';
comment on column `data_access_log`.`entity_table` is 'Table lue. Répond au « quoi », avec la ligne visée et les colonnes effectivement renvoyées.';
comment on column `data_access_log`.`entity_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `data_access_log`.`action` is 'READ consultation, DECRYPT déchiffrement d''une donnée sensible, EXPORT extraction, DOWNLOAD téléchargement d''une pièce.';
comment on column `data_access_log`.`scope` is 'Ce qui a été vu, en clair : « matricule national, IBAN », « dossier complet ». Jamais la valeur elle-même.';
comment on column `data_access_log`.`row_count` is 'Nombre de lignes effectivement renvoyées à l''appelant. Une consultation qui ne renvoie rien reste une consultation et se journalise.';
comment on column `data_access_log`.`source_ip` is 'Adresse IP d''origine, lue dans les en-têtes transmis par la passerelle. Répond au « d''où ».';
comment on column `data_access_log`.`user_agent` is 'Agent déclaré par le client. Indicatif seulement : un agent se falsifie, il complète l''IP sans la remplacer.';
comment on column `data_access_log`.`request_id` is 'Identifiant de la requête, pour rapprocher une ligne de ce journal des traces de la passerelle lors d''une investigation.';
comment on column `data_access_log`.`is_autonomous` is 'Vrai si la trace a été écrite hors de la transaction appelante, et survit donc à son annulation. Faux si dblink n''était pas configuré : la trace est alors aussi fragile que l''opération qu''elle décrit.';
comment on table `departments` is 'Service ou établissement d''une société. Porte un planning et, le cas échéant, sa propre convention collective.';
comment on column `departments`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `departments`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `departments`.`name` is 'Nom du service. Sert au périmètre de dispatching et à la résolution conventionnelle, qui peut se faire par service.';
comment on column `departments`.`min_evening_coverage` is 'Effectif minimal exigé en soirée. Contrainte d''exploitation, vérifiée à la validation d''un planning.';
comment on table `document_types` is 'Catalogue des pièces attendues d''un salarié ou d''un contrat, avec leur durée de validité et le préavis d''alerte avant échéance.';
comment on column `document_types`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `document_types`.`code` is 'Code du type de document, stable, utilisé par le moteur de conformité pour vérifier qu''une pièce obligatoire est présente.';
comment on column `document_types`.`label` is 'Libellé du type de document à l''écran.';
comment on column `document_types`.`stage` is 'Moment du cycle de vie où la pièce est attendue : embauche, cours de contrat, ou fin de contrat.';
comment on column `document_types`.`validity_months` is 'Durée de validité en mois. Nul pour une pièce qui ne périme pas.';
comment on column `document_types`.`is_mandatory` is 'Vrai si l''absence de la pièce constitue un manquement, et non un simple oubli.';
comment on column `document_types`.`applies_to_residency` is 'Statuts de résidence concernés : une autorisation de travail ne vise pas un résident.';
comment on column `document_types`.`alert_days_before` is 'Délai d''anticipation de l''alerte avant expiration.';
comment on column `document_types`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `document_types`.`note` is 'Fondement de l''obligation et durée de conservation attendue.';
comment on table `documents` is 'Pièces déposées, rattachées à un salarié, à un contrat ou à une société. Le fichier vit dans le stockage ; cette table porte les métadonnées et la durée de conservation.';
comment on column `documents`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `documents`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `documents`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `documents`.`entity_table` is 'Table de l''objet rattaché, lorsque la pièce ne vise pas directement un salarié.';
comment on column `documents`.`entity_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `documents`.`name` is 'Nom du document tel que présenté à l''utilisateur. Distinct du nom du fichier stocké.';
comment on column `documents`.`storage_path` is 'Chemin dans le bucket de stockage. L''accès au fichier obéit aux mêmes règles que la ligne.';
comment on column `documents`.`mime_type` is 'Type MIME déclaré à l''envoi. Sert à choisir la visionneuse ; il ne remplace pas un contrôle du contenu.';
comment on column `documents`.`size_bytes` is 'Taille du fichier en octets, pour les quotas et l''affichage.';
comment on column `documents`.`retention_until` is 'Date au-delà de laquelle la pièce ne doit plus être conservée (RGPD, limitation de conservation).';
comment on column `documents`.`is_sensitive` is 'Vrai pour une pièce de catégorie particulière (santé, handicap) : accès et conservation restreints.';
comment on column `documents`.`uploaded_by` is 'Compte ayant déposé le document.';
comment on column `documents`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `documents`.`document_type_id` is 'Type de document, parmi document_types. Détermine la durée de conservation et le caractère obligatoire de la pièce.';
comment on column `documents`.`issued_on` is 'Date de délivrance par l''autorité émettrice.';
comment on column `documents`.`expires_on` is 'Fin de validité de la pièce elle-même, qui déclenche l''alerte d''échéance.';
comment on column `documents`.`delivered_at` is 'Date de remise au salarié, pour les pièces de fin de contrat.';
comment on table `employee_children` is 'Enfants du salarié. Données de catégorie familiale, collectées pour les droits qui en dépendent ; le salarié peut refuser leur usage — voir privacy_opt_out.';
comment on column `employee_children`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employee_children`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employee_children`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `employee_children`.`first_name` is 'Prénom de l''enfant. Nul quand seul le nombre d''enfants importe pour un droit et que l''identité n''a pas à être connue — la minimisation vaut aussi ici.';
comment on column `employee_children`.`last_name` is 'Nom de l''enfant, s''il diffère de celui du parent.';
comment on column `employee_children`.`sex` is 'Sexe de l''enfant, tel que déclaré. Aucun droit n''en dépend ; la colonne existe pour les documents administratifs qui l''exigent.';
comment on column `employee_children`.`birth_date` is 'Date de naissance. Fonde les droits liés aux enfants — congé parental, boni, classe d''impôt — et le déclenchement de leur extinction.';
comment on column `employee_children`.`relationship` is 'Lien : enfant, enfant adopté, enfant du conjoint.';
comment on column `employee_children`.`is_dependent` is 'Vrai si l''enfant est à charge au sens des droits ouverts.';
comment on column `employee_children`.`privacy_opt_out` is 'Vrai si le salarié refuse que l''enfant soit pris en compte. Le moteur cesse alors d''en tirer un droit, sans effacer la ligne.';
comment on column `employee_children`.`adoption_date` is 'Date de l''adoption, qui ouvre ses propres droits, distincts de ceux liés à la naissance.';
comment on column `employee_children`.`note` is 'Précisions utiles au dossier familial. Jamais de donnée de santé : celles-ci vont en fiche_sante, qui porte les restrictions adéquates.';
comment on column `employee_children`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `employee_children`.`refus_photos_evenements` is 'L''enfant ne doit pas apparaître sur les photos des événements familiaux de la société.';
comment on column `employee_children`.`invitation_evenements` is 'L''enfant est convié aux événements de la société — Saint-Nicolas, journée des familles — avec ses parents.';
comment on column `employee_children`.`en_situation_handicap` is 'Situation de handicap. DONNÉE DE SANTÉ : même régime d''accès que la fiche santé.';
comment on column `employee_children`.`taux_handicap_pct` is 'Taux de handicap reconnu, en pourcentage. Donnée de santé : accès restreint, lecture journalisée. Nul si aucun handicap n''est reconnu.';
comment on table `employee_disabilities` is 'Reconnaissance de travailleur handicapé. Donnée de santé au sens du RGPD : accès restreint et finalité limitée aux droits qui en découlent.';
comment on column `employee_disabilities`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employee_disabilities`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employee_disabilities`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `employee_disabilities`.`rate_pct` is 'Taux d''incapacité reconnu.';
comment on column `employee_disabilities`.`recognized_on` is 'Date de la décision de reconnaissance.';
comment on column `employee_disabilities`.`authority` is 'Autorité ayant prononcé la reconnaissance.';
comment on column `employee_disabilities`.`extra_leave_days_override` is 'Jours de congé supplémentaires imposés par la décision, lorsqu''ils diffèrent du droit commun.';
comment on column `employee_disabilities`.`evidence_document_id` is 'Pièce justificative, rangée dans documents avec le drapeau is_sensitive.';
comment on column `employee_disabilities`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `employee_disabilities`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `employee_disabilities`.`note` is 'Éléments de contexte sur la reconnaissance du handicap. Donnée sensible au sens de l''article 9 du RGPD : l''accès en est restreint, et sa lecture journalisée.';
comment on column `employee_disabilities`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `employee_sanctions` is 'Sanctions disciplinaires prononcées. Donnée personnelle sensible au sens du RGPD : accès restreint aux gestionnaires et à la personne concernée, conservation bornée par retention_until, suppression logique pour que le dossier reste cohérent après effacement.';
comment on column `employee_sanctions`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employee_sanctions`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employee_sanctions`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `employee_sanctions`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `employee_sanctions`.`sanction_type` is 'Type de sanction prononcée, parmi sanction_types.';
comment on column `employee_sanctions`.`facts_on` is 'Date des faits reprochés.';
comment on column `employee_sanctions`.`facts_known_on` is 'Date à laquelle l''employeur en a eu connaissance. C''est elle, et non la date des faits, qui fait courir le délai de notification.';
comment on column `employee_sanctions`.`notified_on` is 'Date de notification au salarié. Une sanction non notifiée n''existe pas à son égard.';
comment on column `employee_sanctions`.`effective_from` is 'Premier jour d''effet, inclus. Nul pour une sanction sans effet daté, comme un avertissement.';
comment on column `employee_sanctions`.`effective_to` is 'Dernier jour d''effet, INCLUS. Une mise à pied a une fin ; un avertissement n''en a pas.';
comment on column `employee_sanctions`.`reason` is 'Faits reprochés, obligatoires. Une sanction sans motif écrit est contestable de ce seul fait.';
comment on column `employee_sanctions`.`evidence_document_id` is 'Pièce au dossier : lettre de notification, compte rendu d''entretien. Ce qui prouve que la procédure a été suivie.';
comment on column `employee_sanctions`.`termination_id` is 'Rupture correspondante, quand la sanction est un licenciement. Les deux lignes décrivent le même fait sous deux angles.';
comment on column `employee_sanctions`.`amendment_contract_id` is 'Avenant produit par la sanction, quand elle modifie le contrat — rétrogradation, mutation.';
comment on column `employee_sanctions`.`employee_heard_on` is 'Date à laquelle le salarié a été entendu. L''entretien préalable est requis au-delà d''un seuil d''effectif que le moteur lit dans le référentiel.';
comment on column `employee_sanctions`.`employee_response` is 'Observations du salarié. Le droit de répondre fait partie de la procédure : la réponse se conserve, même si elle ne change pas la décision.';
comment on column `employee_sanctions`.`contested_on` is 'Date de contestation par le salarié. Nulle tant qu''il n''a pas contesté.';
comment on column `employee_sanctions`.`contest_outcome` is 'Issue de la contestation : maintien, réduction, retrait. Une sanction retirée reste en base, avec son issue — l''effacer réécrirait l''histoire.';
comment on column `employee_sanctions`.`note` is 'Suites internes : suivi, accompagnement, rappel à l''ordre ultérieur.';
comment on column `employee_sanctions`.`retention_until` is 'Date au-delà de laquelle la sanction ne doit plus être conservée. Un dossier disciplinaire ne se garde pas indéfiniment.';
comment on column `employee_sanctions`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `employee_sanctions`.`created_by` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `employee_sanctions`.`updated_at` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column `employee_sanctions`.`updated_by` is 'Compte auteur de la dernière modification. Sur une sanction, chaque retouche doit rester attribuable.';
comment on column `employee_sanctions`.`deleted_at` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `employee_sanctions`.`deleted_by` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `employee_statuses` is 'Statuts protégés : grossesse, suites de couches, mandat de délégué. Ils conditionnent la protection contre le licenciement.';
comment on column `employee_statuses`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employee_statuses`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employee_statuses`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `employee_statuses`.`kind` is 'Nature du statut, qui commande la protection applicable.';
comment on column `employee_statuses`.`declared_on` is 'Date à laquelle l''employeur a été informé. C''est elle, et non le fait lui-même, qui déclenche la protection.';
comment on column `employee_statuses`.`start_date` is 'Premier jour du statut, inclus. Un statut protégé — grossesse, délégation, congé parental — ouvre des protections qui commencent ce jour-là.';
comment on column `employee_statuses`.`end_date` is 'Dernier jour du statut, INCLUS. Nulle tant que le statut court.';
comment on column `employee_statuses`.`expected_birth_date` is 'Date présumée de l''accouchement, qui borne la période protégée.';
comment on column `employee_statuses`.`actual_birth_date` is 'Date réelle, qui rectifie la borne une fois connue.';
comment on column `employee_statuses`.`evidence_document_id` is 'Pièce justifiant le statut : certificat, procès-verbal d''élection. Une protection invoquée sans pièce ne tient pas devant l''ITM.';
comment on column `employee_statuses`.`hours_credit_monthly` is 'Crédit d''heures mensuel attaché au mandat, pour les délégués.';
comment on column `employee_statuses`.`note` is 'Précisions sur la portée du statut et sur ce qu''il interdit à l''employeur.';
comment on column `employee_statuses`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `employee_tax_cards` is 'Fiche de retenue d''impôt du salarié, datée. Donnée d''entrée du calcul brut vers net.';
comment on column `employee_tax_cards`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employee_tax_cards`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `employee_tax_cards`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employee_tax_cards`.`tax_class` is 'Classe d''impôt portée par la fiche.';
comment on column `employee_tax_cards`.`rate` is 'Taux de retenue inscrit sur la fiche, lorsqu''un taux est fixé plutôt qu''un barème.';
comment on column `employee_tax_cards`.`monthly_allowance` is 'Abattement mensuel inscrit sur la fiche.';
comment on column `employee_tax_cards`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `employee_tax_cards`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `employee_tax_cards`.`credits` is 'Crédits d''impôt portés par la fiche, structurés.';
comment on column `employee_tax_cards`.`commute_distance_km` is 'Distance domicile-travail déclarée, base de l''abattement kilométrique.';
comment on column `employee_tax_cards`.`professional_expenses_monthly` is 'Frais professionnels mensuels retenus.';
comment on column `employee_tax_cards`.`other_deductions_monthly` is 'Autres déductions mensuelles portées par la fiche.';
comment on column `employee_tax_cards`.`card_reference` is 'Référence de la fiche délivrée par l''administration.';
comment on column `employee_tax_cards`.`issued_on` is 'Date d''émission de la fiche de retenue par l''administration. Distincte de la période de validité : une fiche peut être émise après le début de la période qu''elle couvre.';
comment on table `employees` is 'Salarié. Les deux données les plus sensibles — matricule national et IBAN — ne sont pas stockées en clair : voir national_id_enc et iban_enc.';
comment on column `employees`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `employees`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `employees`.`user_id` is 'Compte applicatif du salarié, s''il accède à son espace personnel. Nul sinon.';
comment on column `employees`.`department_id` is 'Service de rattachement, qui commande le planning et parfois la convention applicable.';
comment on column `employees`.`first_name` is 'Prénom usuel du salarié. Distinct de l''état civil complet : c''est ce qui s''affiche et s''imprime.';
comment on column `employees`.`last_name` is 'Nom de famille. Sert au tri et à la recherche ; un index trigramme le rend cherchable en approximation.';
comment on column `employees`.`birth_date` is 'Date de naissance. Nulle tant qu''elle n''est pas connue — au stade de la candidature, par exemple. Sert au calcul des majorations liées à l''âge et au contrôle de cohérence du matricule.';
comment on column `employees`.`residency` is 'Résident ou frontalier, et de quel pays. Détermine les pièces exigées et le traitement fiscal.';
comment on column `employees`.`qualification` is 'Qualifié ou non qualifié : détermine le salaire social minimum applicable.';
comment on column `employees`.`address_line` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `employees`.`postal_code` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `employees`.`city` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `employees`.`country` is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU.';
comment on column `employees`.`email` is 'Adresse personnelle du salarié. Distincte de celle du compte applicatif : tous les salariés n''ont pas de compte, et l''adresse de contact survit à la fin du contrat.';
comment on column `employees`.`phone` is 'Téléphone de contact. Utilisé par le dispatching ; l''accès en est restreint comme toute donnée de contact personnel.';
comment on column `employees`.`national_id_enc` is 'Matricule national CHIFFRÉ (pgcrypto). Ne jamais lire directement : fn_employee_sensitive contrôle l''accès et déchiffre.';
comment on column `employees`.`iban_enc` is 'IBAN CHIFFRÉ. Même règle d''accès que le matricule.';
comment on column `employees`.`national_id_hint` is 'Fragment non identifiant du matricule, affichable pour reconnaître une fiche sans exposer la donnée.';
comment on column `employees`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `employees`.`sex` is 'Sexe déclaré par le salarié, librement. Modifiable par lui depuis son espace. À ne pas confondre avec sexe_legal, qui est dérivé et non déclaratif. Sera renommé sexe_declare lors du passage au français.';
comment on column `employees`.`career_start_date` is 'Début de carrière professionnelle, distinct de l''entrée dans la société. Sert à l''acquisition de la qualification par l''ancienneté.';
comment on column `employees`.`profession` is 'Profession déclarée, distincte de l''intitulé de poste porté par le contrat.';
comment on column `employees`.`is_management` is 'Vrai pour le personnel de direction, exclu de certains droits collectifs.';
comment on column `employees`.`sexe_legal` is 'Sexe juridique, DÉRIVÉ du matricule national : parité du numéro d''ordre (position 11). Recalculé à chaque écriture — toute valeur soumise est ignorée, la dérivation fait foi. Nul tant qu''aucun matricule n''est enregistré. Le salarié y a accès (RGPD art. 15) mais ne peut pas le modifier.';
comment on column `employees`.`refus_photos_societe` is 'Le salarié refuse d''apparaître sur les photos de la société. Consentement au sens du RGPD : révocable à tout moment, et sans justification à fournir.';
comment on column `employees`.`souhaite_confidentialite` is 'Le salarié souhaite ne pas apparaître — annuaire, trombinoscope, communications. Distinct du droit à l''effacement, qui porte sur la donnée elle-même.';
comment on table `expected_parameters` is 'Clés de legal_parameters que le moteur lit. Sert à fn_referential_gaps pour signaler une clé attendue dont aucune version n''est chargée. Ne porte aucune valeur légale.';
comment on column `expected_parameters`.`param_key` is 'Clé d''un paramètre que le moteur attend. Sans cette table, fn_referential_gaps ne voyait pas les clés entièrement absentes : elle ne pouvait signaler que les périodes trouées.';
comment on column `expected_parameters`.`read_by` is 'Fonction(s) du moteur qui lisent la clé, relevées dans le code des migrations.';
comment on column `expected_parameters`.`note` is 'À quoi sert le paramètre et ce qui se casse en son absence. Ce qui permet de hiérarchiser les trous à combler.';
comment on table `export_log` is 'Registre des exports de portabilité. Trace qui a exporté quoi, quand, et pour quel volume — pièce de conformité au droit d''accès et à la portabilité (RGPD art. 15 et 20).';
comment on column `export_log`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `export_log`.`organization_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `export_log`.`requested_by` is 'Compte ayant demandé l''export. Un export de données personnelles est un traitement : il a un demandeur nommé.';
comment on column `export_log`.`subject_kind` is 'Nature du sujet exporté : self, employee, company, organization ou referential.';
comment on column `export_log`.`subject_id` is 'Ligne concernée par l''export, dans la table que désigne subject_kind. Nulle pour un export qui ne vise pas une ligne unique, comme le référentiel.';
comment on column `export_log`.`row_count` is 'Nombre d''objets contenus dans l''export, à des fins de contrôle de volume.';
comment on column `export_log`.`byte_size` is 'Taille de l''enveloppe produite, en octets.';
comment on column `export_log`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `export_log`.`source_ip` is 'Adresse d''origine de la demande d''export.';
comment on column `export_log`.`user_agent` is 'Agent utilisateur de l''appelant.';
comment on column `export_log`.`request_id` is 'Identifiant de requête, pour recoupement.';
comment on table `fiche_sante` is 'Fiche santé d''un salarié ou d''un de ses enfants. DONNÉE DE SANTÉ au sens de l''article 9 du RGPD : accès réservé à la personne, à la médecine du travail et aux RH d''urgence. Le dispatching n''y accède jamais — il lit les indicateurs dérivés.';
comment on column `fiche_sante`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `fiche_sante`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `fiche_sante`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `fiche_sante`.`enfant_id` is 'Enfant concerné quand la fiche porte sur un enfant et non sur le salarié. Exclusif de la fiche du salarié : une ligne concerne l''un ou l''autre.';
comment on column `fiche_sante`.`allergies` is 'Donnée brute. Ne jamais exposer au planning : c''est l''indicateur dérivé qui circule.';
comment on column `fiche_sante`.`pathologies` is 'Pathologies déclarées. Donnée de santé au sens de l''article 9 du RGPD, sous le régime d''accès le plus strict : le dispatching n''y a jamais accès, il ne voit que des indicateurs dérivés et anonymisés.';
comment on column `fiche_sante`.`medecin_traitant` is 'Médecin traitant, pour le cas d''urgence. Donnée de santé.';
comment on column `fiche_sante`.`medecin_telephone` is 'Téléphone du médecin traitant, appelable en urgence.';
comment on column `fiche_sante`.`groupe_sanguin` is 'Groupe sanguin déclaré. Donnée de santé, transmise aux secours et à personne d''autre.';
comment on column `fiche_sante`.`note` is 'Consignes de prise en charge : allergies et conduite à tenir, traitement d''urgence disponible sur la personne — adrénaline pour une allergie aux piqûres, antihistaminique, mèche de cautérisation. C''est ce que les secours doivent savoir en arrivant.';
comment on column `fiche_sante`.`maj_le` is 'Date de dernière mise à jour de la fiche. Une consigne de secours périmée est dangereuse : l''ancienneté de la fiche doit être visible.';
comment on column `fiche_sante`.`maj_par` is 'Compte ayant mis la fiche à jour. Sur une donnée de santé, toute écriture est attribuable et journalisée.';
comment on column `fiche_sante`.`deleted_at` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `fiche_sante`.`deleted_by` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `headcount_snapshots` is 'Effectif mensuel figé. Sert au calcul de la moyenne sur douze mois, qui déclenche les obligations de seuil (délégation, travailleurs handicapés).';
comment on column `headcount_snapshots`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `headcount_snapshots`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `headcount_snapshots`.`month` is 'Premier jour du mois observé.';
comment on column `headcount_snapshots`.`headcount` is 'Effectif en équivalents temps plein, d''où le type décimal.';
comment on table `interim_agencies` is 'Agence de travail intérimaire, employeur juridique d''un salarié en mission chez une société utilisatrice.';
comment on column `interim_agencies`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `interim_agencies`.`organization_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `interim_agencies`.`name` is 'Raison sociale de l''agence d''intérim, telle qu''elle figure au contrat de mise à disposition.';
comment on column `interim_agencies`.`ccss_matricule` is 'Matricule CCSS de l''agence. C''est elle qui déclare le salarié, pas l''entreprise utilisatrice.';
comment on column `interim_agencies`.`rcs_number` is 'Numéro au registre de commerce. Permet de vérifier qu''une agence est autorisée avant de lui confier une mission.';
comment on column `interim_agencies`.`address_line` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `interim_agencies`.`postal_code` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `interim_agencies`.`city` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `interim_agencies`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `legal_parameters` is 'Le référentiel. Tout seuil, taux ou durée légale du droit du travail luxembourgeois vit ici, jamais dans le code. Chaque valeur porte sa plage de validité, sa source et son article ; une contrainte d''exclusion GiST interdit deux versions qui se chevauchent pour une même clé.';
comment on column `legal_parameters`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `legal_parameters`.`family` is 'Famille du paramètre : elle regroupe les clés par domaine et guide la détection des trous du référentiel.';
comment on column `legal_parameters`.`param_key` is 'Clé stable du paramètre. C''est elle que le moteur interroge, jamais l''identifiant technique.';
comment on column `legal_parameters`.`label` is 'Intitulé du paramètre en français, pour les écrans de référentiel. Le code machine est param_key.';
comment on column `legal_parameters`.`value_num` is 'Valeur numérique. Une seule des trois colonnes value_* est renseignée.';
comment on column `legal_parameters`.`value_text` is 'Valeur textuelle, pour un paramètre qui n''est pas un nombre.';
comment on column `legal_parameters`.`value_json` is 'Valeur structurée, pour un barème ou une table à plusieurs entrées.';
comment on column `legal_parameters`.`unit` is 'Unité de la valeur (EUR, heures, jours, pourcentage...) — sans elle un nombre ne veut rien dire.';
comment on column `legal_parameters`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `legal_parameters`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `legal_parameters`.`index_ref` is 'Cote d''application de l''indice des prix au moment de la valeur, pour les montants indexés.';
comment on column `legal_parameters`.`source` is 'Origine publique de la valeur (Mémorial, STATEC, CCSS...). Obligatoire : un paramètre sans source ne doit pas exister.';
comment on column `legal_parameters`.`legal_ref` is 'Article du Code du travail ou du texte qui fonde la valeur. C''est lui que les alertes citent à l''utilisateur.';
comment on column `legal_parameters`.`note` is 'Précisions d''interprétation : ce que la valeur recouvre exactement, et ce qu''elle ne recouvre pas.';
comment on column `legal_parameters`.`entered_by` is 'Auteur de la saisie.';
comment on column `legal_parameters`.`entered_at` is 'Date de saisie de la valeur dans LuxRH. Distincte de sa date d''entrée en vigueur : une valeur peut être saisie avec retard, ou par anticipation.';
comment on column `legal_parameters`.`validated_by` is 'Relecteur ayant validé la version. Nul tant que la valeur n''a pas été contrôlée.';
comment on column `legal_parameters`.`validated_at` is 'Date de validation par un second regard. Nulle tant que la valeur n''a pas été relue — une valeur légale non validée reste utilisable, mais elle est signalée.';
comment on column `legal_parameters`.`derived_from_key` is 'Clé du paramètre dont celui-ci se déduit. La dérivation sert de contrôle de cohérence, pas de source.';
comment on column `legal_parameters`.`derived_factor` is 'Facteur appliqué au paramètre d''origine pour obtenir celui-ci.';
comment on column `legal_parameters`.`derivation_tolerance` is 'Écart admis entre la valeur saisie et la valeur dérivée avant signalement d''une incohérence.';
comment on table `meal_voucher_grants` is 'Attribution de chèques-repas sur une période. La valeur faciale et la participation salariale sont contrôlées contre les limites du référentiel.';
comment on column `meal_voucher_grants`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `meal_voucher_grants`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `meal_voucher_grants`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `meal_voucher_grants`.`period_start` is 'Premier jour de la période d''attribution, inclus.';
comment on column `meal_voucher_grants`.`period_end` is 'Dernier jour de la période, INCLUS.';
comment on column `meal_voucher_grants`.`voucher_count` is 'Nombre de chèques attribués sur la période.';
comment on column `meal_voucher_grants`.`face_value` is 'Valeur faciale du chèque.';
comment on column `meal_voucher_grants`.`employee_share` is 'Part supportée par le salarié : c''est elle qui conditionne le régime fiscal de l''avantage.';
comment on column `meal_voucher_grants`.`granted_on` is 'Date de remise effective des titres. Distincte de la période qu''ils couvrent.';
comment on column `meal_voucher_grants`.`note` is 'Précisions sur le calcul du nombre de titres, notamment les jours d''absence déduits.';
comment on column `meal_voucher_grants`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `organizations` is 'Fiduciaire ou entreprise unique. Racine de l''isolation : toute donnée appartient, directement ou par sa société, à une organisation.';
comment on column `organizations`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `organizations`.`name` is 'Raison sociale de la fiduciaire ou de l''entreprise.';
comment on column `organizations`.`kind` is 'Distingue une fiduciaire gérant plusieurs sociétés clientes d''une entreprise gérant la sienne.';
comment on column `organizations`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `overtime_requests` is 'Demande d''heures supplémentaires. Elle exige un double accord : validation RH et acceptation du salarié.';
comment on column `overtime_requests`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `overtime_requests`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `overtime_requests`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `overtime_requests`.`schedule_id` is 'Planning auquel la demande se rattache, s''il y en a un.';
comment on column `overtime_requests`.`period_start` is 'Premier jour de la période couverte par la demande, inclus.';
comment on column `overtime_requests`.`period_end` is 'Dernier jour de la période, INCLUS.';
comment on column `overtime_requests`.`hours` is 'Nombre d''heures supplémentaires demandées sur la période.';
comment on column `overtime_requests`.`reason` is 'Motif du recours aux heures supplémentaires, obligatoire. L''ITM peut le demander : les heures supplémentaires ne sont pas de droit.';
comment on column `overtime_requests`.`status` is 'État de la demande. hr_approved ne suffit pas : tant que le salarié n''a pas accepté, les heures ne sont pas couvertes.';
comment on column `overtime_requests`.`requested_by` is 'Compte à l''origine de la demande, généralement l''employeur.';
comment on column `overtime_requests`.`requested_at` is 'Horodatage du dépôt. Le délai de notification se compte à partir de là.';
comment on column `overtime_requests`.`hr_validated_by` is 'Compte ayant validé côté ressources humaines, avant transmission éventuelle à l''ITM.';
comment on column `overtime_requests`.`hr_validated_at` is 'Horodatage de la validation RH.';
comment on column `overtime_requests`.`employee_accepted_at` is 'Horodatage de l''acceptation par le salarié.';
comment on column `overtime_requests`.`rejected_reason` is 'Motif du refus, restitué à l''auteur de la demande.';
comment on column `overtime_requests`.`compensation` is 'Mode de compensation retenu : repos compensateur ou paiement majoré.';
comment on column `overtime_requests`.`note` is 'Précisions sur les circonstances ou sur la compensation retenue.';
comment on table `personne_indicateur_secours` is 'Indicateurs de secours portés par une personne. Dérivés de la fiche santé par la médecine du travail : ils circulent là où la donnée brute ne va pas. C''est ce qui permet au dispatching d''écarter une affectation sans savoir pourquoi.';
comment on column `personne_indicateur_secours`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `personne_indicateur_secours`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `personne_indicateur_secours`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `personne_indicateur_secours`.`enfant_id` is 'Enfant concerné quand l''indicateur porte sur un enfant. Exclusif de la personne salariée.';
comment on column `personne_indicateur_secours`.`indicateur` is 'Indicateur de secours, parmi ref_indicateur_secours. C''est la forme ANONYMISÉE de l''information médicale : un booléen dérivé, sans diagnostic. Le dispatching voit l''indicateur, jamais la pathologie qui le fonde.';
comment on column `personne_indicateur_secours`.`precision_lieu` is 'Précision d''affectation quand l''indicateur en appelle une — un type de lieu, un environnement. Jamais une pathologie.';
comment on column `personne_indicateur_secours`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `personne_indicateur_secours`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `personne_indicateur_secours`.`pose_par` is 'Compte ayant posé l''indicateur, à partir de la fiche de santé. La dérivation est un acte : elle a un auteur et une date.';
comment on column `personne_indicateur_secours`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `premiums` is 'Primes versées, dont les primes participatives soumises à un double plafond : enveloppe société et plafond individuel.';
comment on column `premiums`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `premiums`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `premiums`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `premiums`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `premiums`.`termination_id` is 'Rupture à laquelle la prime se rattache, pour une indemnité de départ.';
comment on column `premiums`.`kind` is 'Nature de la prime. Détermine son régime fiscal et social, et le plafond légal qui s''y applique le cas échéant.';
comment on column `premiums`.`label` is 'Libellé de la prime sur le bulletin.';
comment on column `premiums`.`amount` is 'Montant en euros pour la période. Le plafond d''exonération éventuel est vérifié par le moteur et non par une contrainte : il est daté.';
comment on column `premiums`.`granted_on` is 'Date d''attribution.';
comment on column `premiums`.`fiscal_year` is 'Exercice d''imputation, qui détermine l''enveloppe et les plafonds applicables.';
comment on column `premiums`.`is_taxable` is 'Vrai si la prime entre dans l''assiette imposable, une fois le plafond d''exonération dépassé.';
comment on column `premiums`.`is_contributory` is 'Vrai si la prime entre dans l''assiette des cotisations. Distinct du régime fiscal.';
comment on column `premiums`.`exempt_pct` is 'Fraction exonérée de la prime, selon son régime.';
comment on column `premiums`.`note` is 'Fondement de la prime et calcul retenu. Une prime sans justification écrite se conteste mal.';
comment on column `premiums`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `probation_extensions` is 'Prolongation d''une période d''essai, suspendue par une absence. Trace la durée ajoutée et son motif.';
comment on column `probation_extensions`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `probation_extensions`.`contract_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `probation_extensions`.`from_date` is 'Premier jour de la prolongation d''essai, inclus.';
comment on column `probation_extensions`.`to_date` is 'Dernier jour de la prolongation, INCLUS. La durée totale d''essai reste plafonnée par la loi et par la convention : le moteur vérifie le cumul, pas seulement cette ligne.';
comment on column `probation_extensions`.`days_added` is 'Jours ajoutés à l''essai du fait de la suspension.';
comment on column `probation_extensions`.`reason` is 'Motif de la prolongation. L''essai ne se prolonge pas par convenance : il faut une cause, généralement une suspension du contrat.';
comment on table `profiles` is 'Compte utilisateur applicatif, en miroir de auth.users. Alimenté par le déclencheur handle_new_user à l''inscription.';
comment on column `profiles`.`id` is 'Identique à auth.users.id : le profil ne porte pas d''identité propre.';
comment on column `profiles`.`organization_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `profiles`.`full_name` is 'Nom affiché de l''utilisateur dans l''interface. Doublon assumé de app_users.full_name : profiles est la vue applicative, app_users la table de comptes portable vers un autre SGBD.';
comment on column `profiles`.`email` is 'Recopié depuis auth.users pour l''affichage. L''authentification ne s''appuie jamais sur cette copie.';
comment on column `profiles`.`is_org_admin` is 'Administrateur de l''organisation : seul habilité à charger un référentiel et à exporter la fiduciaire entière.';
comment on column `profiles`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `public_holidays` is 'Jours fériés légaux d''une année, complétés le cas échéant par les jours conventionnels.';
comment on column `public_holidays`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `public_holidays`.`year` is 'Année du jour férié. Les fériés mobiles changent de date chaque année : une ligne par année.';
comment on column `public_holidays`.`holiday_date` is 'Date du jour férié. Un férié travaillé ouvre une majoration dont le taux vient du référentiel daté.';
comment on column `public_holidays`.`name` is 'Nom du jour férié, affiché sur les plannings.';
comment on column `public_holidays`.`is_mobile` is 'Vrai pour un férié dont la date suit le calendrier pascal, calculé par fn_easter_sunday.';
comment on column `public_holidays`.`collective_agreement_id` is 'Renseigné pour un jour chômé d''origine conventionnelle, nul pour un férié légal.';
comment on column `public_holidays`.`is_recoverable` is 'Vrai si le férié tombant un jour non ouvré ouvre droit à récupération.';
comment on column `public_holidays`.`recovery_reason` is 'Motif de la récupération, cité dans l''alerte.';
comment on table `ref_action_acces` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_action_acces`.`code` is 'Code de l''action journalisée dans le registre des accès : lecture, déchiffrement, export.';
comment on column `ref_action_acces`.`libelle` is 'Libellé de l''action à l''écran du registre.';
comment on column `ref_action_acces`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_action_acces`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_action_acces`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_action_acces`.`note` is 'Ce que l''action recouvre exactement, pour que le registre se lise sans ambiguïté lors d''un contrôle.';
comment on table `ref_compensation_heures_sup` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_compensation_heures_sup`.`code` is 'Code du mode de compensation des heures supplémentaires : repos ou argent.';
comment on column `ref_compensation_heures_sup`.`libelle` is 'Libellé du mode de compensation à l''écran.';
comment on column `ref_compensation_heures_sup`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_compensation_heures_sup`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_compensation_heures_sup`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_compensation_heures_sup`.`note` is 'Règle applicable : le repos compensatoire est le principe, la compensation en argent l''exception encadrée.';
comment on table `ref_condition_travail` is 'Conditions matérielles d''exécution du travail ouvrant droit à prime. Les trois familles générales sont posées ; chaque convention collective en précise le détail et y ajoute les siennes, par insert et sans migration.';
comment on column `ref_condition_travail`.`code` is 'Code de la condition matérielle de travail : pénibilité, insalubrité, danger.';
comment on column `ref_condition_travail`.`libelle` is 'Libellé de la condition à l''écran.';
comment on column `ref_condition_travail`.`famille` is 'Famille générale : penibilite, insalubrite, danger. Sert à regrouper, jamais à calculer — c''est la règle conventionnelle qui porte le taux.';
comment on column `ref_condition_travail`.`description` is 'Ce que la condition recouvre concrètement, pour que le constat sur le terrain soit reproductible d''un chef d''équipe à l''autre.';
comment on column `ref_condition_travail`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_condition_travail`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_condition_travail`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_condition_travail`.`note` is 'Conventions qui reconnaissent cette condition et articles correspondants.';
comment on table `ref_indicateur_secours` is 'Indicateurs dérivés de la fiche santé, destinés au dispatching et aux secours. Ils disent ce qu''il faut faire sans révéler la pathologie : « porte de l''adrénaline » plutôt que « allergique aux guêpes ». C''est ce qui permet au planning de faire son travail sans accéder à une donnée de santé.';
comment on column `ref_indicateur_secours`.`code` is 'Code de l''indicateur de secours. Forme ANONYMISÉE d''une information médicale : l''indicateur dit qu''il faut agir, jamais de quelle pathologie il s''agit.';
comment on column `ref_indicateur_secours`.`libelle` is 'Libellé de l''indicateur, tel que le voit le dispatching.';
comment on column `ref_indicateur_secours`.`consigne` is 'Ce qu''il faut faire, en clair, pour qui n''est ni médecin ni RH. C''est le texte qu''un secouriste lit.';
comment on column `ref_indicateur_secours`.`visible_dispatching` is 'Vrai si l''indicateur guide l''affectation — une interdiction de lieu, par exemple. Faux pour un indicateur purement médical d''urgence.';
comment on column `ref_indicateur_secours`.`visible_secours` is 'Vrai si l''indicateur peut être transmis aux secours. Certains indicateurs servent à l''organisation du travail et ne doivent pas sortir de ce cadre.';
comment on column `ref_indicateur_secours`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_indicateur_secours`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_indicateur_secours`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_indicateur_secours`.`note` is 'Conduite à tenir associée, et limite de ce que l''indicateur autorise à divulguer.';
comment on table `ref_lien_enfant` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_lien_enfant`.`code` is 'Code du lien entre l''adulte et l''enfant : filiation, adoption, garde, recueil.';
comment on column `ref_lien_enfant`.`libelle` is 'Libellé du lien à l''écran.';
comment on column `ref_lien_enfant`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_lien_enfant`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_lien_enfant`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_lien_enfant`.`note` is 'Droits que ce lien ouvre ou n''ouvre pas — tous les liens ne donnent pas les mêmes droits familiaux.';
comment on table `ref_nature_prime` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_nature_prime`.`code` is 'Code de la nature de prime.';
comment on column `ref_nature_prime`.`libelle` is 'Libellé de la nature de prime à l''écran.';
comment on column `ref_nature_prime`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_nature_prime`.`categorie` is 'Regroupement de la nature de prime, pour les états de synthèse.';
comment on column `ref_nature_prime`.`lie_aux_conditions` is 'Vrai si la prime dépend des conditions réelles d''exécution, et non d''une clause constante du contrat. Elle se calcule alors sur les créneaux effectivement travaillés sous ces conditions.';
comment on column `ref_nature_prime`.`source_url` is 'Lien vers la convention collective qui fixe le taux et les conditions. Une prime conventionnelle sans source n''est pas vérifiable.';
comment on column `ref_nature_prime`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_nature_prime`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_nature_prime`.`note` is 'Traitement fiscal et social de cette nature de prime, et texte qui le fonde.';
comment on table `ref_pays` is 'Correspondance ISO 3166-1 alpha-3 / alpha-2. L''application stocke l''alpha-3 ; l''alpha-2 sert à lire l''existant et les sources externes le temps de la transition.';
comment on column `ref_pays`.`alpha3` is 'Code ISO 3166-1 alpha-3 du pays. C''est la clé primaire et le format utilisé PARTOUT dans le schéma — une colonne char(2) avait déjà fait rejeter « LUX », le projet a tranché pour l''alpha-3 partout.';
comment on column `ref_pays`.`alpha2` is 'Code ISO 3166-1 alpha-2, conservé pour dialoguer avec les services externes qui ne connaissent que celui-là. Jamais utilisé comme clé.';
comment on column `ref_pays`.`nom` is 'Nom du pays en français, pour l''affichage.';
comment on column `ref_pays`.`frontalier` is 'Vrai si le pays ouvre le régime de travailleur frontalier au Luxembourg. Commande le traitement fiscal et l''affiliation.';
comment on column `ref_pays`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_pays`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `ref_statut_heures_sup` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_statut_heures_sup`.`code` is 'Code du statut d''une demande d''heures supplémentaires.';
comment on column `ref_statut_heures_sup`.`libelle` is 'Libellé du statut à l''écran.';
comment on column `ref_statut_heures_sup`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_statut_heures_sup`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_statut_heures_sup`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_statut_heures_sup`.`note` is 'Ce qui fait passer une demande dans ce statut, et qui en a le pouvoir.';
comment on table `ref_statut_verification_adresse` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_statut_verification_adresse`.`code` is 'Code du résultat de vérification d''adresse.';
comment on column `ref_statut_verification_adresse`.`libelle` is 'Libellé du résultat à l''écran.';
comment on column `ref_statut_verification_adresse`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_statut_verification_adresse`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_statut_verification_adresse`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_statut_verification_adresse`.`note` is 'Ce que le statut implique : bloquant, à corriger, ou simplement hors périmètre de vérification.';
comment on table `ref_sujet_export` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_sujet_export`.`code` is 'Code du sujet d''un export : salarié, société, fiduciaire, référentiel.';
comment on column `ref_sujet_export`.`libelle` is 'Libellé du sujet à l''écran.';
comment on column `ref_sujet_export`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_sujet_export`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_sujet_export`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_sujet_export`.`note` is 'Périmètre exact de ce sujet d''export et fondement juridique du droit correspondant.';
comment on table `ref_type_adresse` is 'Les quatre natures d''adresse d''un salarié. Table de domaine : en ajouter une ne demande pas de migration.';
comment on column `ref_type_adresse`.`code` is 'Code du type d''adresse : domicile légal, résidence effective, correspondance, facturation.';
comment on column `ref_type_adresse`.`libelle` is 'Libellé du type d''adresse à l''écran.';
comment on column `ref_type_adresse`.`description` is 'Ce à quoi ce type d''adresse sert, et pourquoi il ne se confond pas avec les autres. Le domicile légal fonde la fiscalité ; la résidence effective fonde les trajets.';
comment on column `ref_type_adresse`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_type_adresse`.`sert_au_fiscal` is 'Vrai pour la seule adresse qui fonde les distances officielles et les indemnisations fiscales — le domicile légal. Les autres ne doivent jamais servir à cela.';
comment on column `ref_type_adresse`.`sert_aux_tournees` is 'Vrai si ce type d''adresse est celui d''où partent les calculs de distance. Un seul type sert de point de départ : sans cela, deux calculs donneraient deux résultats.';
comment on column `ref_type_adresse`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_type_adresse`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `ref_unite_essai` is 'Table de domaine datée, remplaçant une contrainte CHECK de liste. On ajoute une valeur par insert, on la retire en la datant.';
comment on column `ref_unite_essai`.`code` is 'Code de l''unité de durée de la période d''essai : jours, semaines, mois.';
comment on column `ref_unite_essai`.`libelle` is 'Libellé de l''unité à l''écran.';
comment on column `ref_unite_essai`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_unite_essai`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_unite_essai`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_unite_essai`.`note` is 'Durées minimales et maximales exprimées dans cette unité, et texte qui les fixe.';
comment on table `ref_unite_prime` is 'Unités auxquelles une prime de condition se rapporte. Table de domaine datée, comme toutes les autres : ajouter une unité ne demande pas de migration.';
comment on column `ref_unite_prime`.`code` is 'Code de l''unité à laquelle la prime se rapporte : heure exposée, jour, mois, prestation.';
comment on column `ref_unite_prime`.`libelle` is 'Libellé de l''unité à l''écran.';
comment on column `ref_unite_prime`.`description` is 'Comment le temps relevé se convertit en montant pour cette unité.';
comment on column `ref_unite_prime`.`ordre` is 'Rang d''affichage dans les listes. Sert uniquement à présenter les valeurs dans un ordre lisible plutôt qu''alphabétique ; aucune règle métier ne s''y appuie.';
comment on column `ref_unite_prime`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `ref_unite_prime`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `ref_unite_prime`.`note` is 'Précisions d''application, notamment sur les seuils et les arrondis.';
comment on table `reference_periods` is 'Période de référence sur laquelle la durée de travail se calcule en moyenne. Définie par société ou par service.';
comment on column `reference_periods`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `reference_periods`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `reference_periods`.`department_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column `reference_periods`.`label` is 'Intitulé de la période de référence, pour l''identifier dans les écrans de suivi.';
comment on column `reference_periods`.`start_date` is 'Premier jour de la période de référence, inclus. C''est sur cette période que la durée moyenne de travail doit être respectée.';
comment on column `reference_periods`.`end_date` is 'Dernier jour de la période, INCLUS. Sa longueur maximale est fixée par le référentiel légal et par la convention, jamais écrite en dur.';
comment on column `reference_periods`.`months` is 'Longueur de la période. Une période plus longue qu''un mois suppose un fondement conventionnel.';
comment on table `sanction_categories` is 'Les trois degrés de la sanction disciplinaire. Table de référence datée plutôt qu''énumération : un degré peut être renommé, ajouté ou retiré par DML, sans migration ni indisponibilité.';
comment on column `sanction_categories`.`code` is 'Code de la catégorie de sanction : mineure, lourde, rupture. Trois catégories, qui commandent la procédure exigée.';
comment on column `sanction_categories`.`label` is 'Libellé de la catégorie à l''écran.';
comment on column `sanction_categories`.`rank` is 'Gravité croissante. Sert à ordonner, jamais à décider : c''est le type de sanction qui porte les règles.';
comment on column `sanction_categories`.`description` is 'Ce que la catégorie implique en matière de procédure, d''entretien préalable et de recours. C''est la colonne que lit un gestionnaire avant de choisir.';
comment on column `sanction_categories`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `sanction_categories`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `sanction_types` is 'Catalogue des sanctions applicables, daté. Chaque type porte ses effets — présence, rémunération, contrat — et ce qu''il exige de l''employeur. Le moteur lit ces drapeaux ; il ne les devine pas.';
comment on column `sanction_types`.`code` is 'Code du type de sanction, stable. Huit types répartis dans les trois catégories.';
comment on column `sanction_types`.`category_code` is 'Catégorie de rattachement, parmi sanction_categories. Détermine la procédure et les délais.';
comment on column `sanction_types`.`label` is 'Libellé du type de sanction à l''écran.';
comment on column `sanction_types`.`description` is 'Portée exacte de la sanction et conditions de validité. Une sanction lourde suppose notamment qu''elle figure dans les textes internes de l''entreprise.';
comment on column `sanction_types`.`affects_presence` is 'Vrai si la sanction suspend la présence du salarié — mise à pied. Le planning doit alors cesser de l''affecter sur la période.';
comment on column `sanction_types`.`affects_pay` is 'Vrai si la rémunération est suspendue ou réduite. Distingue la mise à pied disciplinaire de la conservatoire, qui maintient le salaire.';
comment on column `sanction_types`.`requires_internal_rules` is 'Vrai si la sanction n''est valable qu''à condition de figurer dans les textes internes de l''entreprise. C''est le cas de toutes les sanctions lourdes.';
comment on column `sanction_types`.`is_contract_change` is 'Vrai si la sanction modifie le contrat. Elle passe alors par fn_amend_contract et, si la baisse de rémunération est substantielle, requiert l''''accord du salarié ou une procédure propre.';
comment on column `sanction_types`.`ends_contract` is 'Vrai si la sanction met fin au contrat. Déclenche le circuit de rupture : préavis, indemnités, documents de fin de contrat.';
comment on column `sanction_types`.`needs_notice` is 'Vrai si un préavis est dû, faux s''''il ne l''''est pas, nul si la question ne se pose pas. Le calcul du préavis lui-même reste à fn_notice_period.';
comment on column `sanction_types`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `sanction_types`.`note` is 'Références et précisions sur l''usage du type. Ce qui permet de vérifier qu''on applique la bonne sanction.';
comment on column `sanction_types`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `sanction_types`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `schedules` is 'Planning hebdomadaire d''une société ou d''un service. Tant qu''il n''est pas publié, il n''est opposable à personne.';
comment on column `schedules`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `schedules`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `schedules`.`department_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column `schedules`.`week_start` is 'Lundi de la semaine couverte.';
comment on column `schedules`.`label` is 'Intitulé du planning, pour s''y retrouver entre plusieurs semaines ou équipes. Sans effet sur le calcul.';
comment on column `schedules`.`status` is 'Brouillon ou publié. La publication passe par fn_publish_schedule, qui refuse un planning non conforme.';
comment on column `schedules`.`published_at` is 'Horodatage de la publication, qui fait courir le délai de prévenance.';
comment on column `schedules`.`published_by` is 'Auteur de la publication.';
comment on column `schedules`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `shift_templates` is 'Modèle de vacation réutilisable, pour éviter de ressaisir les horaires courants.';
comment on column `shift_templates`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `shift_templates`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `shift_templates`.`name` is 'Nom du modèle de créneau, pour le réutiliser lors de la construction d''un planning.';
comment on column `shift_templates`.`start_time` is 'Heure de début du modèle.';
comment on column `shift_templates`.`end_time` is 'Heure de fin du modèle. Peut être antérieure à start_time : le créneau franchit alors minuit.';
comment on column `shift_templates`.`break_minutes` is 'Pause en minutes, déduite du temps de travail effectif. Le seuil légal au-delà duquel une pause est obligatoire vient du référentiel daté, jamais d''une valeur écrite ici.';
comment on column `shift_templates`.`color` is 'Couleur d''affichage dans le planning. Confort d''usage, sans effet métier.';
comment on column `shift_templates`.`department_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on table `shifts` is 'Vacation planifiée : un salarié, une date, des horaires. C''est l''unité que le moteur contrôle contre les repos et les durées maximales.';
comment on column `shifts`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `shifts`.`schedule_id` is 'Planning auquel le créneau appartient. Un créneau n''existe pas hors d''un planning : c''est le planning qui porte le statut brouillon ou publié.';
comment on column `shifts`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `shifts`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `shifts`.`shift_date` is 'Jour du créneau. Un créneau qui déborde sur le lendemain porte la date de son début.';
comment on column `shifts`.`start_time` is 'Heure de début. Avec la durée, détermine les majorations de nuit, de dimanche et de jour férié.';
comment on column `shifts`.`end_time` is 'Heure de fin. Antérieure à start_time pour une vacation qui franchit minuit — fn_shift_end_ts résout le cas.';
comment on column `shifts`.`break_minutes` is 'Pause de la vacation, déduite des heures travaillées.';
comment on column `shifts`.`label` is 'Précision sur le créneau : chantier, tournée, remplacement. Affichée au salarié.';
comment on column `shifts`.`template_id` is 'Modèle dont la vacation est issue, s''il y en a un.';
comment on column `shifts`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `shifts`.`client_site_id` is 'Lieu d''exécution de la vacation. Nul signifie « au siège de la société » — c''est le cas courant, et c''est aussi la référence à laquelle un dépassement se mesure.';
comment on table `tax_brackets` is 'Barème de l''impôt sur les traitements et salaires, par classe et par périodicité. Table structurellement prête ; son chargement relève de la V2 brut vers net.';
comment on column `tax_brackets`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `tax_brackets`.`tax_class` is 'Classe d''impôt à laquelle le barème s''applique. Le passage à la classe unique prévu pour 2027 se traduira par de nouvelles lignes datées, pas par une modification des anciennes.';
comment on column `tax_brackets`.`periodicity` is 'Périodicité du barème : mensuel, annuel. Un barème mensuel n''est pas le douzième d''un barème annuel.';
comment on column `tax_brackets`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `tax_brackets`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `tax_brackets`.`bracket_min` is 'Borne basse de la tranche.';
comment on column `tax_brackets`.`bracket_max` is 'Borne haute. Nul pour la dernière tranche.';
comment on column `tax_brackets`.`base_tax` is 'Impôt cumulé dû à la borne basse de la tranche.';
comment on column `tax_brackets`.`rate_over_min` is 'Taux appliqué à la fraction du revenu dépassant la borne basse.';
comment on column `tax_brackets`.`source` is 'Publication d''origine du barème. Sans source, un barème ne se vérifie pas — et la règle 7 du projet interdit de l''inventer.';
comment on column `tax_brackets`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `tax_brackets`.`note` is 'Précisions sur la tranche : arrondis, cas particuliers, articulation avec les crédits.';
comment on table `tax_credits` is 'Crédits d''impôt, avec leur plage de revenu et les classes auxquelles ils s''appliquent.';
comment on column `tax_credits`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `tax_credits`.`code` is 'Code du crédit d''impôt, stable, repris par le calcul de la retenue.';
comment on column `tax_credits`.`label` is 'Libellé du crédit tel qu''il apparaît sur le bulletin.';
comment on column `tax_credits`.`applies_to_classes` is 'Classes d''impôt ouvrant droit au crédit.';
comment on column `tax_credits`.`income_min` is 'Revenu à partir duquel le crédit est ouvert.';
comment on column `tax_credits`.`income_max` is 'Revenu au-delà duquel le crédit s''éteint.';
comment on column `tax_credits`.`monthly_amount` is 'Montant mensuel du crédit, en euros. Nul quand le crédit ne se traduit pas par un montant fixe.';
comment on column `tax_credits`.`prorated_on_hours` is 'Vrai si le crédit se réduit au prorata du temps de travail.';
comment on column `tax_credits`.`valid_from` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `tax_credits`.`valid_to` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `tax_credits`.`source` is 'Publication d''origine du montant. Obligatoire pour la même raison que sur tax_brackets.';
comment on column `tax_credits`.`legal_ref` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `tax_credits`.`note` is 'Conditions d''octroi et cumul avec les autres crédits.';
comment on table `time_entries` is 'Registre du temps réellement travaillé, distinct du planning. C''est lui qui fait foi pour les majorations et les heures supplémentaires.';
comment on column `time_entries`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `time_entries`.`company_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `time_entries`.`employee_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `time_entries`.`entry_date` is 'Jour du relevé. Un relevé par jour et par salarié : c''est la maille de tous les compteurs.';
comment on column `time_entries`.`start_time` is 'Heure de début relevée. Nulle pour un relevé saisi en durée seule, sans horaires.';
comment on column `time_entries`.`end_time` is 'Heure de fin relevée. Nulle dans le même cas que start_time — les deux vont ensemble.';
comment on column `time_entries`.`break_minutes` is 'Pause en minutes, déduite du temps de travail effectif de la journée.';
comment on column `time_entries`.`worked_hours` is 'Heures effectivement travaillées, pause déduite.';
comment on column `time_entries`.`planned_hours` is 'Heures planifiées pour la même journée, pour mesurer l''écart.';
comment on column `time_entries`.`sunday_hours` is 'Part travaillée un dimanche, qui ouvre sa propre majoration.';
comment on column `time_entries`.`holiday_hours` is 'Part travaillée un jour férié.';
comment on column `time_entries`.`night_hours` is 'Part travaillée en période de nuit.';
comment on column `time_entries`.`overtime_hours` is 'Heures supplémentaires retenues sur la journée.';
comment on column `time_entries`.`is_validated` is 'Vrai une fois la journée validée. Une journée non validée ne nourrit aucun calcul définitif.';
comment on column `time_entries`.`source` is 'Origine de la saisie : pointage, saisie manuelle, report du planning.';
comment on column `time_entries`.`note` is 'Circonstances du relevé : dépassement, incident, rattrapage. Ce qu''un contrôle voudra comprendre.';
comment on column `time_entries`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `travel_distances` is 'Distances routières mises en cache. Une adresse n''est transmise au service tiers qu''au premier calcul d''un couple ; les plannings suivants lisent cette table.';
comment on column `travel_distances`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `travel_distances`.`origin_ref` is 'Référence de l''origine, sous la forme « employee:<uuid> », « company:<uuid> » ou « site:<uuid> ». Aucune adresse n''est recopiée ici.';
comment on column `travel_distances`.`destination_ref` is 'Référence de la destination : site client, société, ou adresse saisie. Le trajet se calcule depuis une adresse du salarié vers cette destination.';
comment on column `travel_distances`.`distance_km` is 'Distance routière en kilomètres, telle que renvoyée par le service d''itinéraire. Ce n''est pas la distance à vol d''oiseau : c''est celle qui fonde l''indemnité.';
comment on column `travel_distances`.`duration_minutes` is 'Durée estimée du trajet. Indicative : elle sert à construire les tournées, pas à rémunérer.';
comment on column `travel_distances`.`source` is 'Origine de la mesure : nom du service consulté, ou « manuel » si la distance a été saisie. Une distance sans source ne doit pas servir à payer.';
comment on column `travel_distances`.`computed_at` is 'Date du calcul. Une adresse change ; une distance vieille de trois ans mérite d''être revérifiée.';
comment on column `travel_distances`.`computed_by` is 'Compte ayant déclenché le calcul. Un appel à un service externe se trace : il a un coût et il expose une adresse.';
comment on column `travel_distances`.`note` is 'Circonstances du calcul : date, service interrogé, correction manuelle éventuelle.';
comment on table `user_roles` is 'Habilitations. Une ligne par couple utilisateur/périmètre ; c''est la table que lisent tous les prédicats RLS.';
comment on column `user_roles`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `user_roles`.`user_id` is 'Compte auquel le rôle est attribué. Un compte peut porter plusieurs rôles ; c''est le plus permissif qui s''applique, et les politiques RLS lisent cette table, jamais une valeur transmise par le client.';
comment on column `user_roles`.`organization_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `user_roles`.`company_id` is 'Nul pour un rôle qui porte sur toute l''organisation. Renseigné pour un rôle limité à une société.';
comment on column `user_roles`.`role` is 'Rôle applicatif. Le rôle employee restreint l''utilisateur à son propre dossier.';
comment on column `user_roles`.`created_at` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `ref_absence_category` is 'Table de référence issue du type énuméré PostgreSQL absence_category.';
comment on table `ref_absence_status` is 'Table de référence issue du type énuméré PostgreSQL absence_status.';
comment on table `ref_alert_state` is 'Table de référence issue du type énuméré PostgreSQL alert_state.';
comment on table `ref_app_role` is 'Table de référence issue du type énuméré PostgreSQL app_role.';
comment on table `ref_cba_block` is 'Table de référence issue du type énuméré PostgreSQL cba_block.';
comment on table `ref_cba_scope` is 'Table de référence issue du type énuméré PostgreSQL cba_scope.';
comment on table `ref_contract_kind` is 'Table de référence issue du type énuméré PostgreSQL contract_kind.';
comment on table `ref_contract_status` is 'Table de référence issue du type énuméré PostgreSQL contract_status.';
comment on table `ref_document_stage` is 'Table de référence issue du type énuméré PostgreSQL document_stage.';
comment on table `ref_employee_status_kind` is 'Table de référence issue du type énuméré PostgreSQL employee_status_kind.';
comment on table `ref_org_kind` is 'Table de référence issue du type énuméré PostgreSQL org_kind.';
comment on table `ref_param_family` is 'Table de référence issue du type énuméré PostgreSQL param_family.';
comment on table `ref_pay_component_kind` is 'Table de référence issue du type énuméré PostgreSQL pay_component_kind.';
comment on table `ref_qualification_kind` is 'Table de référence issue du type énuméré PostgreSQL qualification_kind.';
comment on table `ref_residency_kind` is 'Table de référence issue du type énuméré PostgreSQL residency_kind.';
comment on table `ref_schedule_status` is 'Table de référence issue du type énuméré PostgreSQL schedule_status.';
comment on table `ref_severity_kind` is 'Table de référence issue du type énuméré PostgreSQL severity_kind.';
comment on table `ref_sex_kind` is 'Table de référence issue du type énuméré PostgreSQL sex_kind.';
comment on table `ref_tax_class` is 'Table de référence issue du type énuméré PostgreSQL tax_class.';
comment on table `ref_tax_periodicity` is 'Table de référence issue du type énuméré PostgreSQL tax_periodicity.';

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

delimiter $$
create trigger absence_entitlements_no_overlap_insert after insert on `absence_entitlements`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `absence_entitlements` b
     where b.`id` <> new.`id`
       and new.`absence_type_id` <=> b.`absence_type_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur absence_entitlements';
  end if;
end$$
create trigger absence_entitlements_no_overlap_update after update on `absence_entitlements`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `absence_entitlements` b
     where b.`id` <> new.`id`
       and new.`absence_type_id` <=> b.`absence_type_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur absence_entitlements';
  end if;
end$$
delimiter ;

delimiter $$
create trigger adresses_salarie_no_overlap_insert after insert on `adresses_salarie`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `adresses_salarie` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id` and new.`type_adresse` <=> b.`type_adresse`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur adresses_salarie';
  end if;
end$$
create trigger adresses_salarie_no_overlap_update after update on `adresses_salarie`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `adresses_salarie` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id` and new.`type_adresse` <=> b.`type_adresse`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur adresses_salarie';
  end if;
end$$
delimiter ;

delimiter $$
create trigger company_rate_periods_no_overlap_insert after insert on `company_rate_periods`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `company_rate_periods` b
     where b.`id` <> new.`id`
       and new.`company_id` <=> b.`company_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur company_rate_periods';
  end if;
end$$
create trigger company_rate_periods_no_overlap_update after update on `company_rate_periods`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `company_rate_periods` b
     where b.`id` <> new.`id`
       and new.`company_id` <=> b.`company_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur company_rate_periods';
  end if;
end$$
delimiter ;

delimiter $$
create trigger contracts_no_overlap_insert after insert on `contracts`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `contracts` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`start_date` < ifnull(b.`end_date`, '9999-12-31')
       and ifnull(new.`end_date`, '9999-12-31') > b.`start_date`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur contracts';
  end if;
end$$
create trigger contracts_no_overlap_update after update on `contracts`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `contracts` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`start_date` < ifnull(b.`end_date`, '9999-12-31')
       and ifnull(new.`end_date`, '9999-12-31') > b.`start_date`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur contracts';
  end if;
end$$
delimiter ;

delimiter $$
create trigger employee_disabilities_no_overlap_insert after insert on `employee_disabilities`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `employee_disabilities` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_disabilities';
  end if;
end$$
create trigger employee_disabilities_no_overlap_update after update on `employee_disabilities`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `employee_disabilities` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_disabilities';
  end if;
end$$
delimiter ;

delimiter $$
create trigger employee_tax_cards_no_overlap_insert after insert on `employee_tax_cards`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `employee_tax_cards` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_tax_cards';
  end if;
end$$
create trigger employee_tax_cards_no_overlap_update after update on `employee_tax_cards`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `employee_tax_cards` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_tax_cards';
  end if;
end$$
delimiter ;

delimiter $$
create trigger legal_parameters_no_overlap_insert after insert on `legal_parameters`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `legal_parameters` b
     where b.`id` <> new.`id`
       and new.`param_key` <=> b.`param_key`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur legal_parameters';
  end if;
end$$
create trigger legal_parameters_no_overlap_update after update on `legal_parameters`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `legal_parameters` b
     where b.`id` <> new.`id`
       and new.`param_key` <=> b.`param_key`
       and new.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
       and ifnull(new.`valid_to`, '9999-12-31') > b.`valid_from`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur legal_parameters';
  end if;
end$$
delimiter ;

delimiter $$
create trigger meal_voucher_grants_no_overlap_insert after insert on `meal_voucher_grants`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `meal_voucher_grants` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`period_start` < ifnull(b.`period_end`, '9999-12-31')
       and ifnull(new.`period_end`, '9999-12-31') > b.`period_start`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur meal_voucher_grants';
  end if;
end$$
create trigger meal_voucher_grants_no_overlap_update after update on `meal_voucher_grants`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `meal_voucher_grants` b
     where b.`id` <> new.`id`
       and new.`employee_id` <=> b.`employee_id`
       and new.`period_start` < ifnull(b.`period_end`, '9999-12-31')
       and ifnull(new.`period_end`, '9999-12-31') > b.`period_start`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur meal_voucher_grants';
  end if;
end$$
delimiter ;


