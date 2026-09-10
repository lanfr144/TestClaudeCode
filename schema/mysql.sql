-- Schéma LuxRH pour MYSQL, dérivé du catalogue PostgreSQL.
-- Généré par tools/emit_portable_schema.py — ne pas modifier à la main :
-- la base PostgreSQL fait foi, ce fichier la suit.
--
-- Écarts assumés : DATETIME ne conserve pas le fuseau (tout est écrit en UTC),
-- booléens en TINYINT(1), tableaux en JSON.

create table `absence_entitlements` (
  `id` CHAR(36) default (UUID()) not null,
  `absence_type_id` CHAR(36) not null,
  `days` DECIMAL(5,1),
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `category` ENUM('annual_leave', 'sick', 'extraordinary', 'public_holiday', 'unpaid', 'compensatory') not null,
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
  `status` ENUM('pending', 'approved', 'refused', 'cancelled') default 'pending' not null,
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
  constraint absences_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `app_secrets` (
  `key` VARCHAR(255) not null,
  `secret` TEXT not null,
  constraint app_secrets_pkey primary key (`key`)
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
  `block` ENUM('salary_grid', 'worktime', 'leave', 'premiums', 'surcharges', 'notice_probation', 'custom_holidays') not null,
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

create table `collective_agreements` (
  `id` CHAR(36) default (UUID()) not null,
  `organization_id` CHAR(36),
  `code` TEXT not null,
  `name` TEXT not null,
  `sector` TEXT not null,
  `valid_from` DATE not null,
  `valid_to` DATE,
  `is_active` TINYINT(1) default 0 not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `scope` ENUM('sector', 'harassment', 'employee_category', 'department', 'company') default 'sector' not null,
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
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `severity` ENUM('blocking', 'warning', 'info') not null,
  `due_date` DATE,
  `state` ENUM('open', 'handled', 'dismissed') default 'open' not null,
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
  `valid_from` DATE not null,
  `valid_to` DATE,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint contract_collective_agreemen primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contract_pay_components` (
  `id` CHAR(36) default (UUID()) not null,
  `contract_id` CHAR(36) not null,
  `company_id` CHAR(36) not null,
  `kind` ENUM('fixed', 'variable', 'benefit_in_kind', 'premium', 'expense') not null,
  `code` TEXT not null,
  `label` TEXT not null,
  `amount` DECIMAL(10,2),
  `rate_pct` DECIMAL(6,3),
  `basis` TEXT,
  `periodicity` TEXT default 'monthly' not null,
  `in_salary_reference` TINYINT(1) default 0 not null,
  `is_taxable` TINYINT(1) default 1 not null,
  `is_contributory` TINYINT(1) default 1 not null,
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `kind` ENUM('cdi', 'cdd', 'seasonal', 'apprenticeship', 'interim') not null,
  `status` ENUM('draft', 'active', 'ended', 'cancelled') default 'draft' not null,
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
  `stage` ENUM('pre_hire', 'during_contract', 'end_of_contract') default 'during_contract' not null,
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
  `sex` ENUM('male', 'female', 'unspecified'),
  `birth_date` DATE not null,
  `relationship` TEXT default 'child' not null,
  `is_dependent` TINYINT(1) default 1 not null,
  `privacy_opt_out` TINYINT(1) default 0 not null,
  `adoption_date` DATE,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
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
  `valid_from` DATE not null,
  `valid_to` DATE,
  `note` TEXT,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint employee_disabilities_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `employee_statuses` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `employee_id` CHAR(36) not null,
  `kind` ENUM('pregnancy', 'maternity_leave', 'breastfeeding', 'parental_leave', 'delegate', 'safety_delegate', 'equality_delegate', 'reemployment_bonus', 'company_manager', 'protected_other') not null,
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
  `tax_class` ENUM('1', '1a', '2') not null,
  `rate` DECIMAL(6,4),
  `monthly_allowance` DECIMAL(10,2) default 0 not null,
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `residency` ENUM('resident', 'frontalier_fr', 'frontalier_be', 'frontalier_de') not null,
  `qualification` ENUM('qualified', 'unqualified') default 'unqualified' not null,
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
  `sex` ENUM('male', 'female', 'unspecified') default 'unspecified' not null,
  `career_start_date` DATE,
  `profession` TEXT,
  `is_management` TINYINT(1) default 0 not null,
  constraint employees_pkey primary key (`id`)
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
  constraint export_log_pkey primary key (`id`)
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
  `family` ENUM('social', 'fiscal', 'worktime', 'leave', 'contract', 'headcount', 'ccss') not null,
  `param_key` TEXT not null,
  `label` TEXT not null,
  `value_num` DECIMAL(30,10),
  `value_text` TEXT,
  `value_json` JSON,
  `unit` TEXT,
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `kind` ENUM('fiduciary', 'company') default 'fiduciary' not null,
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
  `reason` TEXT default 'incapacitÃ© de travail' not null,
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

create table `schedules` (
  `id` CHAR(36) default (UUID()) not null,
  `company_id` CHAR(36) not null,
  `department_id` CHAR(36),
  `week_start` DATE not null,
  `label` TEXT,
  `status` ENUM('draft', 'published') default 'draft' not null,
  `published_at` DATETIME(6),
  `published_by` CHAR(36),
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint schedules_pkey primary key (`id`),
  constraint schedules_company_id_departm unique (`company_id`, `department_id`, `week_start`)
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
  constraint shifts_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `tax_brackets` (
  `id` CHAR(36) default (UUID()) not null,
  `tax_class` ENUM('1', '1a', '2') not null,
  `periodicity` ENUM('monthly', 'daily', 'annual') default 'monthly' not null,
  `valid_from` DATE not null,
  `valid_to` DATE,
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
  `valid_from` DATE not null,
  `valid_to` DATE,
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

create table `user_roles` (
  `id` CHAR(36) default (UUID()) not null,
  `user_id` CHAR(36) not null,
  `organization_id` CHAR(36) not null,
  `company_id` CHAR(36),
  `role` ENUM('fiduciary_admin', 'manager', 'service_manager', 'employee') not null,
  `created_at` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint user_roles_pkey primary key (`id`),
  constraint user_roles_user_id_company_i unique (`user_id`, `company_id`, `role`)
) engine=InnoDB default charset=utf8mb4;

-- Clés étrangères, posées après toutes les tables.
alter table `absence_entitlements` add constraint absence_entitlements_absence foreign key (`absence_type_id`) references `absence_types` (`id`) on delete cascade;
alter table `absences` add constraint absences_absence_type_id_fke foreign key (`absence_type_id`) references `absence_types` (`id`);
alter table `absences` add constraint absences_child_id_fkey foreign key (`child_id`) references `employee_children` (`id`) on delete set null;
alter table `absences` add constraint absences_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `absences` add constraint absences_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `cba_rules` add constraint cba_rules_collective_agreeme foreign key (`collective_agreement_id`) references `collective_agreements` (`id`) on delete cascade;
alter table `cba_salary_grids` add constraint cba_salary_grids_collective_ foreign key (`collective_agreement_id`) references `collective_agreements` (`id`) on delete cascade;
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
alter table `contract_amendments` add constraint contract_amendments_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_amendments` add constraint contract_amendments_contract foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_collective_agreements` add constraint contract_collective_agreemen foreign key (`collective_agreement_id`) references `collective_agreements` (`id`);
alter table `contract_collective_agreements` add constraint contract_collective_agreemen foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_pay_components` add constraint contract_pay_components_bene foreign key (`benefit_type_id`) references `benefit_types` (`id`) on delete set null;
alter table `contract_pay_components` add constraint contract_pay_components_comp foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_pay_components` add constraint contract_pay_components_cont foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contract_terminations` add constraint contract_terminations_compan foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contract_terminations` add constraint contract_terminations_contra foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `contracts` add constraint contracts_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `contracts` add constraint contracts_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `contracts` add constraint contracts_interim_agency_fk foreign key (`interim_agency_id`) references `interim_agencies` (`id`) on delete set null;
alter table `contracts` add constraint contracts_previous_contract_ foreign key (`previous_contract_id`) references `contracts` (`id`) on delete set null;
alter table `departments` add constraint departments_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `documents` add constraint documents_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `documents` add constraint documents_document_type_id_f foreign key (`document_type_id`) references `document_types` (`id`) on delete set null;
alter table `documents` add constraint documents_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employee_children` add constraint employee_children_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_children` add constraint employee_children_employee_i foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employee_disabilities` add constraint employee_disabilities_compan foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_disabilities` add constraint employee_disabilities_employ foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employee_disabilities` add constraint employee_disabilities_eviden foreign key (`evidence_document_id`) references `documents` (`id`) on delete set null;
alter table `employee_statuses` add constraint employee_statuses_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_statuses` add constraint employee_statuses_employee_i foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employee_statuses` add constraint employee_statuses_evidence_d foreign key (`evidence_document_id`) references `documents` (`id`) on delete set null;
alter table `employee_tax_cards` add constraint employee_tax_cards_company_i foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employee_tax_cards` add constraint employee_tax_cards_employee_ foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `employees` add constraint employees_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `employees` add constraint employees_department_id_fkey foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `export_log` add constraint export_log_organization_id_f foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `headcount_snapshots` add constraint headcount_snapshots_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `interim_agencies` add constraint interim_agencies_organizatio foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;
alter table `meal_voucher_grants` add constraint meal_voucher_grants_company_ foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `meal_voucher_grants` add constraint meal_voucher_grants_employee foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_requests_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_requests_employee_i foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `overtime_requests` add constraint overtime_requests_schedule_i foreign key (`schedule_id`) references `schedules` (`id`) on delete set null;
alter table `premiums` add constraint premiums_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `premiums` add constraint premiums_contract_id_fkey foreign key (`contract_id`) references `contracts` (`id`) on delete set null;
alter table `premiums` add constraint premiums_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `premiums` add constraint premiums_termination_id_fkey foreign key (`termination_id`) references `contract_terminations` (`id`) on delete set null;
alter table `probation_extensions` add constraint probation_extensions_contrac foreign key (`contract_id`) references `contracts` (`id`) on delete cascade;
alter table `profiles` add constraint profiles_organization_id_fke foreign key (`organization_id`) references `organizations` (`id`);
alter table `reference_periods` add constraint reference_periods_company_id foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `reference_periods` add constraint reference_periods_department foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `schedules` add constraint schedules_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `schedules` add constraint schedules_department_id_fkey foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `shift_templates` add constraint shift_templates_company_id_f foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `shift_templates` add constraint shift_templates_department_i foreign key (`department_id`) references `departments` (`id`) on delete set null;
alter table `shifts` add constraint shifts_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `shifts` add constraint shifts_employee_id_fkey foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `shifts` add constraint shifts_schedule_id_fkey foreign key (`schedule_id`) references `schedules` (`id`) on delete cascade;
alter table `shifts` add constraint shifts_template_id_fkey foreign key (`template_id`) references `shift_templates` (`id`) on delete set null;
alter table `time_entries` add constraint time_entries_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `time_entries` add constraint time_entries_employee_id_fke foreign key (`employee_id`) references `employees` (`id`) on delete cascade;
alter table `user_roles` add constraint user_roles_company_id_fkey foreign key (`company_id`) references `companies` (`id`) on delete cascade;
alter table `user_roles` add constraint user_roles_organization_id_f foreign key (`organization_id`) references `organizations` (`id`) on delete cascade;

-- Contraintes de validation.
alter table `absence_entitlements` add constraint entitlement_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `absences` add constraint absence_range CHECK ((end_date >= start_date));
alter table `companies` add constraint ccss_matricule_format CHECK (((ccss_matricule IS NULL) OR (ccss_matricule ~ '^[0-9]{13}$'::text)));
alter table `companies` add constraint companies_reference_period_m CHECK (((reference_period_months >= 1) AND (reference_period_months <= 4)));
alter table `company_collective_agreements` add constraint company_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `company_rate_periods` add constraint company_rate_periods_mutuali CHECK (((mutuality_class >= 1) AND (mutuality_class <= 4)));
alter table `company_rate_periods` add constraint rate_period_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contract_collective_agreements` add constraint contract_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contract_pay_components` add constraint pay_component_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `contracts` add constraint cdd_needs_reason CHECK (((kind <> 'cdd'::contract_kind) OR (cdd_reason IS NOT NULL)));
alter table `contracts` add constraint fixed_term_needs_end CHECK (((kind <> ALL (ARRAY['cdd'::contract_kind, 'seasonal'::contract_kind, 'interim'::contract_kind, 'apprenticeship'::contract_kind])) OR (end_date IS NOT NULL)));
alter table `contracts` add constraint interim_needs_user_company CHECK (((kind <> 'interim'::contract_kind) OR (user_company_name IS NOT NULL)));
alter table `employee_children` add constraint privacy_minimises_data CHECK (((NOT privacy_opt_out) OR ((first_name IS NULL) AND (last_name IS NULL) AND (sex IS NULL) AND (note IS NULL))));
alter table `employee_disabilities` add constraint disability_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `employee_disabilities` add constraint employee_disabilities_rate_p CHECK (((rate_pct > (0)::numeric) AND (rate_pct <= (100)::numeric)));
alter table `employee_statuses` add constraint status_range CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table `legal_parameters` add constraint one_value CHECK (((num_nonnulls(value_num, value_text, value_json) = 1) OR ((derived_from_key IS NOT NULL) AND (num_nonnulls(value_num, value_text, value_json) = 0))));
alter table `legal_parameters` add constraint valid_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `meal_voucher_grants` add constraint meal_voucher_grants_voucher_ CHECK ((voucher_count >= 0));
alter table `meal_voucher_grants` add constraint voucher_period CHECK ((period_end >= period_start));
alter table `overtime_requests` add constraint overtime_period CHECK ((period_end >= period_start));
alter table `overtime_requests` add constraint overtime_requests_hours_chec CHECK ((hours > (0)::numeric));
alter table `premiums` add constraint premiums_amount_check CHECK ((amount >= (0)::numeric));
alter table `reference_periods` add constraint prl_range CHECK ((end_date > start_date));
alter table `reference_periods` add constraint reference_periods_months_che CHECK (((months >= 1) AND (months <= 4)));
alter table `tax_brackets` add constraint bracket_range CHECK (((bracket_max IS NULL) OR (bracket_max > bracket_min)));
alter table `tax_brackets` add constraint bracket_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table `tax_credits` add constraint credit_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

delimiter $$
create trigger absence_entitlements_no_overlap_insert after insert on `absence_entitlements`
for each row begin
  declare n int;
  select count(*) into n
    from `absence_entitlements` a join `absence_entitlements` b on a.`id` <> b.`id`
   where a.`absence_type_id` <=> b.`absence_type_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur absence_entitlements';
  end if;
end$$
create trigger absence_entitlements_no_overlap_update after update on `absence_entitlements`
for each row begin
  declare n int;
  select count(*) into n
    from `absence_entitlements` a join `absence_entitlements` b on a.`id` <> b.`id`
   where a.`absence_type_id` <=> b.`absence_type_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur absence_entitlements';
  end if;
end$$
delimiter ;

delimiter $$
create trigger company_rate_periods_no_overlap_insert after insert on `company_rate_periods`
for each row begin
  declare n int;
  select count(*) into n
    from `company_rate_periods` a join `company_rate_periods` b on a.`id` <> b.`id`
   where a.`company_id` <=> b.`company_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur company_rate_periods';
  end if;
end$$
create trigger company_rate_periods_no_overlap_update after update on `company_rate_periods`
for each row begin
  declare n int;
  select count(*) into n
    from `company_rate_periods` a join `company_rate_periods` b on a.`id` <> b.`id`
   where a.`company_id` <=> b.`company_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur company_rate_periods';
  end if;
end$$
delimiter ;

delimiter $$
create trigger employee_disabilities_no_overlap_insert after insert on `employee_disabilities`
for each row begin
  declare n int;
  select count(*) into n
    from `employee_disabilities` a join `employee_disabilities` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_disabilities';
  end if;
end$$
create trigger employee_disabilities_no_overlap_update after update on `employee_disabilities`
for each row begin
  declare n int;
  select count(*) into n
    from `employee_disabilities` a join `employee_disabilities` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_disabilities';
  end if;
end$$
delimiter ;

delimiter $$
create trigger employee_tax_cards_no_overlap_insert after insert on `employee_tax_cards`
for each row begin
  declare n int;
  select count(*) into n
    from `employee_tax_cards` a join `employee_tax_cards` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_tax_cards';
  end if;
end$$
create trigger employee_tax_cards_no_overlap_update after update on `employee_tax_cards`
for each row begin
  declare n int;
  select count(*) into n
    from `employee_tax_cards` a join `employee_tax_cards` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur employee_tax_cards';
  end if;
end$$
delimiter ;

delimiter $$
create trigger legal_parameters_no_overlap_insert after insert on `legal_parameters`
for each row begin
  declare n int;
  select count(*) into n
    from `legal_parameters` a join `legal_parameters` b on a.`id` <> b.`id`
   where a.`param_key` <=> b.`param_key`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur legal_parameters';
  end if;
end$$
create trigger legal_parameters_no_overlap_update after update on `legal_parameters`
for each row begin
  declare n int;
  select count(*) into n
    from `legal_parameters` a join `legal_parameters` b on a.`id` <> b.`id`
   where a.`param_key` <=> b.`param_key`
     and a.`valid_from` < ifnull(b.`valid_to`, '9999-12-31')
     and ifnull(a.`valid_to`, '9999-12-31') > b.`valid_from`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur legal_parameters';
  end if;
end$$
delimiter ;

delimiter $$
create trigger meal_voucher_grants_no_overlap_insert after insert on `meal_voucher_grants`
for each row begin
  declare n int;
  select count(*) into n
    from `meal_voucher_grants` a join `meal_voucher_grants` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`period_start` < ifnull(b.`period_end`, '9999-12-31')
     and ifnull(a.`period_end`, '9999-12-31') > b.`period_start`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur meal_voucher_grants';
  end if;
end$$
create trigger meal_voucher_grants_no_overlap_update after update on `meal_voucher_grants`
for each row begin
  declare n int;
  select count(*) into n
    from `meal_voucher_grants` a join `meal_voucher_grants` b on a.`id` <> b.`id`
   where a.`employee_id` <=> b.`employee_id`
     and a.`period_start` < ifnull(b.`period_end`, '9999-12-31')
     and ifnull(a.`period_end`, '9999-12-31') > b.`period_start`;
  if n > 0 then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur meal_voucher_grants';
  end if;
end$$
delimiter ;


-- ------------------------------------------------------------------
-- CE QUI N'A PAS ÉTÉ TRADUIT — à reprendre à la main.
-- Rien n'est omis en silence : une contrainte perdue est un invariant
-- perdu, et l'on ne s'en aperçoit qu'au moment où elle aurait servi.
-- ------------------------------------------------------------------
--   absences.absences_decided_by_fkey : référence auth.users, propre à Supabase Auth. À rattacher à
--   la table des comptes de la cible.
--   absences.absences_requested_by_fkey : référence auth.users, propre à Supabase Auth. À rattacher
--   à la table des comptes de la cible.
--   compliance_alerts.compliance_alerts_handled_by_fkey : référence auth.users, propre à Supabase
--   Auth. À rattacher à la table des comptes de la cible.
--   contract_amendments.contract_amendments_created_by_fkey : référence auth.users, propre à
--   Supabase Auth. À rattacher à la table des comptes de la cible.
--   contracts.contracts_probation_unit_check : expression propre à PostgreSQL — CHECK
--   ((probation_unit = ANY (ARRAY['weeks'::text, 'months'::text])))
--   documents.documents_uploaded_by_fkey : référence auth.users, propre à Supabase Auth. À rattacher
--   à la table des comptes de la cible.
--   employee_children.employee_children_relationship_check : expression propre à PostgreSQL — CHECK
--   ((relationship = ANY (ARRAY['child'::text, 'adopted'::text, 'foster'::text,
--   'stepchild'::text])))
--   employees.employees_user_id_fkey : référence auth.users, propre à Supabase Auth. À rattacher à
--   la table des comptes de la cible.
--   export_log.export_log_requested_by_fkey : référence auth.users, propre à Supabase Auth. À
--   rattacher à la table des comptes de la cible.
--   export_log.export_log_subject_kind_check : expression propre à PostgreSQL — CHECK ((subject_kind
--   = ANY (ARRAY['employee'::text, 'company'::text, 'organization'::text, 'referential'::text])))
--   legal_parameters.legal_parameters_entered_by_fkey : référence auth.users, propre à Supabase
--   Auth. À rattacher à la table des comptes de la cible.
--   legal_parameters.legal_parameters_validated_by_fkey : référence auth.users, propre à Supabase
--   Auth. À rattacher à la table des comptes de la cible.
--   overtime_requests.overtime_requests_compensation_check : expression propre à PostgreSQL — CHECK
--   ((compensation = ANY (ARRAY['money'::text, 'rest'::text])))
--   overtime_requests.overtime_requests_hr_validated_by_fkey : référence auth.users, propre à
--   Supabase Auth. À rattacher à la table des comptes de la cible.
--   overtime_requests.overtime_requests_requested_by_fkey : référence auth.users, propre à Supabase
--   Auth. À rattacher à la table des comptes de la cible.
--   overtime_requests.overtime_requests_status_check : expression propre à PostgreSQL — CHECK
--   ((status = ANY (ARRAY['requested'::text, 'hr_approved'::text, 'approved'::text,
--   'rejected'::text, 'cancelled'::text])))
--   premiums.premiums_kind_check : expression propre à PostgreSQL — CHECK ((kind = ANY
--   (ARRAY['participative'::text, 'thirteenth_month'::text, 'performance'::text, 'seniority'::text,
--   'exceptional'::text, 'notice_waiver'::text, 'other'::text])))
--   profiles.profiles_id_fkey : référence auth.users, propre à Supabase Auth. À rattacher à la table
--   des comptes de la cible.
--   schedules.schedules_published_by_fkey : référence auth.users, propre à Supabase Auth. À
--   rattacher à la table des comptes de la cible.
--   user_roles.user_roles_user_id_fkey : référence auth.users, propre à Supabase Auth. À rattacher à
--   la table des comptes de la cible.
