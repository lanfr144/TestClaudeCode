-- Schéma LuxRH pour ORACLE, dérivé du catalogue PostgreSQL.
-- Généré par tools/emit_portable_schema.py — ne pas modifier à la main :
-- la base PostgreSQL fait foi, ce fichier la suit.
--
-- Écarts assumés : pas de type TIME (heures en VARCHAR2 'HH24:MI:SS'),
-- booléens en NUMBER(1), énumérations en VARCHAR2 + CHECK, tableaux en JSON.

create table "ABSENCE_ENTITLEMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ABSENCE_TYPE_ID" VARCHAR2(36) not null,
  "DAYS" NUMBER(5,1),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "LEGAL_REF" VARCHAR2(4000),
  "FREQUENCY_NOTE" VARCHAR2(4000),
  "CAREER_CAP_DAYS" NUMBER(6,1),
  "BLOCK_DAYS" NUMBER(5,1),
  "PERIOD_MONTHS" NUMBER(10),
  "RELATIONSHIP_DEGREE" NUMBER(5),
  "REQUIRES_EVIDENCE" NUMBER(1) default 0 not null constraint absence_entitlements_requires_evidence_bool check ("REQUIRES_EVIDENCE" in (0, 1)),
  "NOTE" VARCHAR2(4000),
  constraint absence_entitlements_pkey primary key ("ID")
);

create table "ABSENCE_TYPES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "CATEGORY" VARCHAR2(14) not null
    constraint absence_types_category_enum check ("CATEGORY" in ('annual_leave', 'sick', 'extraordinary', 'public_holiday', 'unpaid', 'compensatory')),
  "LEGAL_REF" VARCHAR2(4000),
  "REQUIRES_CERTIFICATE" NUMBER(1) default 0 not null constraint absence_types_requires_certifica_bool check ("REQUIRES_CERTIFICATE" in (0, 1)),
  "IS_PAID" NUMBER(1) default 1 not null constraint absence_types_is_paid_bool check ("IS_PAID" in (0, 1)),
  "COUNTS_AGAINST_LEAVE" NUMBER(1) default 0 not null constraint absence_types_counts_against_lea_bool check ("COUNTS_AGAINST_LEAVE" in (0, 1)),
  constraint absence_types_pkey primary key ("ID"),
  constraint absence_types_code_key unique ("CODE")
);

create table "ABSENCES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "ABSENCE_TYPE_ID" VARCHAR2(36) not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE not null,
  "DAYS_COUNT" NUMBER(5,2) default 0 not null,
  "STATUS" VARCHAR2(9) default 'pending' not null
    constraint absences_status_enum check ("STATUS" in ('pending', 'approved', 'refused', 'cancelled')),
  "COMMENT" VARCHAR2(4000),
  "CERTIFICATE_RECEIVED" NUMBER(1) default 0 not null constraint absences_certificate_receiv_bool check ("CERTIFICATE_RECEIVED" in (0, 1)),
  "CERTIFICATE_RECEIVED_AT" DATE,
  "CERTIFICATE_DOCUMENT_ID" VARCHAR2(36),
  "REQUESTED_BY" VARCHAR2(36),
  "DECIDED_BY" VARCHAR2(36),
  "DECIDED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DECISION_NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DECLARED_BY_EMPLOYEE" NUMBER(1) default 0 not null constraint absences_declared_by_employ_bool check ("DECLARED_BY_EMPLOYEE" in (0, 1)),
  "CERTIFICATE_UPLOADED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "CERTIFICATE_ORIGINAL_RECEIVED" NUMBER(1) default 0 not null constraint absences_certificate_origin_bool check ("CERTIFICATE_ORIGINAL_RECEIVED" in (0, 1)),
  "CERTIFICATE_ORIGINAL_RECEIVED_AT" DATE,
  "CHILD_ID" VARCHAR2(36),
  constraint absences_pkey primary key ("ID")
);

create table "APP_SECRETS" (
  "KEY" VARCHAR2(4000) not null,
  "SECRET" VARCHAR2(4000) not null,
  constraint app_secrets_pkey primary key ("KEY")
);

create table "AUDIT_LOG" (
  "ID" NUMBER(19) not null,
  "OCCURRED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "ACTOR_ID" VARCHAR2(36),
  "ACTOR_LABEL" VARCHAR2(4000),
  "COMPANY_ID" VARCHAR2(36),
  "ENTITY_TABLE" VARCHAR2(4000) not null,
  "ENTITY_ID" VARCHAR2(36),
  "ACTION" VARCHAR2(4000) not null,
  "OLD_VALUE" CLOB constraint audit_log_old_value_json check ("OLD_VALUE" is json),
  "NEW_VALUE" CLOB constraint audit_log_new_value_json check ("NEW_VALUE" is json),
  constraint audit_log_pkey primary key ("ID")
);

create table "BENEFIT_TYPES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "VALUATION_METHOD" VARCHAR2(4000) not null,
  "IS_TAXABLE" NUMBER(1) default 1 not null constraint benefit_types_is_taxable_bool check ("IS_TAXABLE" in (0, 1)),
  "IS_CONTRIBUTORY" NUMBER(1) default 1 not null constraint benefit_types_is_contributory_bool check ("IS_CONTRIBUTORY" in (0, 1)),
  "VALUATION_PARAMS" CLOB default '{}' not null constraint benefit_types_valuation_params_json check ("VALUATION_PARAMS" is json),
  "LEGAL_REF" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  constraint benefit_types_pkey primary key ("ID"),
  constraint benefit_types_code_key unique ("CODE")
);

create table "CBA_RULES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36) not null,
  "BLOCK" VARCHAR2(16) not null
    constraint cba_rules_block_enum check ("BLOCK" in ('salary_grid', 'worktime', 'leave', 'premiums', 'surcharges', 'notice_probation', 'custom_holidays')),
  "RULES" CLOB default '{}' not null constraint cba_rules_rules_json check ("RULES" is json),
  "IS_COMPLETE" NUMBER(1) default 0 not null constraint cba_rules_is_complete_bool check ("IS_COMPLETE" in (0, 1)),
  "UPDATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint cba_rules_pkey primary key ("ID"),
  constraint cba_rules_collective_agreeme unique ("COLLECTIVE_AGREEMENT_ID", "BLOCK")
);

create table "CBA_SALARY_GRIDS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36) not null,
  "CATEGORY" VARCHAR2(4000) not null,
  "SENIORITY_FROM_YEARS" NUMBER(4,1) default 0 not null,
  "SENIORITY_TO_YEARS" NUMBER(4,1),
  "MONTHLY_AMOUNT" NUMBER(10,2) not null,
  "INDEX_REF" NUMBER(8,2),
  constraint cba_salary_grids_pkey primary key ("ID")
);

create table "COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36),
  "CODE" VARCHAR2(4000) not null,
  "NAME" VARCHAR2(4000) not null,
  "SECTOR" VARCHAR2(4000) not null,
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "IS_ACTIVE" NUMBER(1) default 0 not null constraint collective_agreement_is_active_bool check ("IS_ACTIVE" in (0, 1)),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SCOPE" VARCHAR2(17) default 'sector' not null
    constraint collective_agreement_scope_enum check ("SCOPE" in ('sector', 'harassment', 'employee_category', 'department', 'company')),
  "SUPERSEDES_ID" VARCHAR2(36),
  "EMPLOYEE_CATEGORY" VARCHAR2(4000),
  constraint collective_agreements_pkey primary key ("ID")
);

create table "COMPANIES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36) not null,
  "LEGAL_NAME" VARCHAR2(4000) not null,
  "LEGAL_FORM" VARCHAR2(4000),
  "RCS_NUMBER" VARCHAR2(4000),
  "CCSS_MATRICULE" VARCHAR2(4000),
  "ADDRESS_LINE" VARCHAR2(4000),
  "POSTAL_CODE" VARCHAR2(4000),
  "CITY" VARCHAR2(4000),
  "COUNTRY" VARCHAR2(4000) default 'LU' not null,
  "NACE_CODE" VARCHAR2(4000),
  "SECTOR" VARCHAR2(4000),
  "REFERENCE_PERIOD_MONTHS" NUMBER(5) default 4 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint companies_pkey primary key ("ID")
);

create table "COMPANY_ACCIDENT_CLAIMS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "YEAR" NUMBER(5) not null,
  "CLAIM_COUNT" NUMBER(10) default 0 not null,
  "DAYS_LOST" NUMBER(10) default 0 not null,
  "COST" NUMBER(12,2),
  "NOTE" VARCHAR2(4000),
  constraint company_accident_claims_pkey primary key ("ID"),
  constraint company_accident_claims_comp unique ("COMPANY_ID", "YEAR")
);

create table "COMPANY_COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36) not null,
  "DEPARTMENT_ID" VARCHAR2(36),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_collective_agreement primary key ("ID")
);

create table "COMPANY_FINANCIALS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "FISCAL_YEAR" NUMBER(5) not null,
  "PROFIT" NUMBER(14,2),
  "REVENUE" NUMBER(14,2),
  "SOURCE" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_financials_pkey primary key ("ID"),
  constraint company_financials_company_i unique ("COMPANY_ID", "FISCAL_YEAR")
);

create table "COMPANY_RATE_PERIODS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "ACTIVITY_CLASS" VARCHAR2(4000),
  "ACCIDENT_RISK_CLASS" VARCHAR2(4000),
  "ACCIDENT_FACTOR" NUMBER(5,2) default 1.00 not null,
  "MUTUALITY_CLASS" NUMBER(5),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "SOURCE" VARCHAR2(4000) default 'CCSS' not null,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint company_rate_periods_pkey primary key ("ID")
);

create table "COMPLIANCE_ALERTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36),
  "RULE_CODE" VARCHAR2(4000) not null,
  "TITLE" VARCHAR2(4000) not null,
  "DETAIL" VARCHAR2(4000) not null,
  "CONSEQUENCE" VARCHAR2(4000),
  "LEGAL_REF" VARCHAR2(4000),
  "SEVERITY" VARCHAR2(8) not null
    constraint compliance_alerts_severity_enum check ("SEVERITY" in ('blocking', 'warning', 'info')),
  "DUE_DATE" DATE,
  "STATE" VARCHAR2(9) default 'open' not null
    constraint compliance_alerts_state_enum check ("STATE" in ('open', 'handled', 'dismissed')),
  "HANDLED_BY" VARCHAR2(36),
  "HANDLED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "HANDLED_NOTE" VARCHAR2(4000),
  "FIRST_SEEN_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint compliance_alerts_pkey primary key ("ID")
);

create table "CONTRACT_AMENDMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EFFECTIVE_DATE" DATE not null,
  "REASON" VARCHAR2(4000) not null,
  "CHANGES" CLOB not null constraint contract_amendments_changes_json check ("CHANGES" is json),
  "CREATED_BY" VARCHAR2(36),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint contract_amendments_pkey primary key ("ID")
);

create table "CONTRACT_COLLECTIVE_AGREEMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36) not null,
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36) not null,
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint contract_collective_agreemen primary key ("ID")
);

create table "CONTRACT_PAY_COMPONENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "KIND" VARCHAR2(15) not null
    constraint contract_pay_compone_kind_enum check ("KIND" in ('fixed', 'variable', 'benefit_in_kind', 'premium', 'expense')),
  "CODE" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "AMOUNT" NUMBER(10,2),
  "RATE_PCT" NUMBER(6,3),
  "BASIS" VARCHAR2(4000),
  "PERIODICITY" VARCHAR2(4000) default 'monthly' not null,
  "IN_SALARY_REFERENCE" NUMBER(1) default 0 not null constraint contract_pay_compone_in_salary_referenc_bool check ("IN_SALARY_REFERENCE" in (0, 1)),
  "IS_TAXABLE" NUMBER(1) default 1 not null constraint contract_pay_compone_is_taxable_bool check ("IS_TAXABLE" in (0, 1)),
  "IS_CONTRIBUTORY" NUMBER(1) default 1 not null constraint contract_pay_compone_is_contributory_bool check ("IS_CONTRIBUTORY" in (0, 1)),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "BENEFIT_TYPE_ID" VARCHAR2(36),
  constraint contract_pay_components_pkey primary key ("ID")
);

create table "CONTRACT_TERMINATIONS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "REASON" VARCHAR2(4000) not null,
  "IS_PERSONAL_GROUND" NUMBER(1) default 1 not null constraint contract_termination_is_personal_ground_bool check ("IS_PERSONAL_GROUND" in (0, 1)),
  "NOTIFIED_ON" DATE not null,
  "NOTICE_START" DATE,
  "NOTICE_END" DATE,
  "SEVERANCE_MONTHS" NUMBER(4,1),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "NOTICE_WAIVED" NUMBER(1) default 0 not null constraint contract_termination_notice_waived_bool check ("NOTICE_WAIVED" in (0, 1)),
  "WAIVER_AGREED_ON" DATE,
  "WAIVER_COMPENSATION" NUMBER(12,2),
  "WAIVER_NOTE" VARCHAR2(4000),
  "IS_GROSS_MISCONDUCT" NUMBER(1) default 0 not null constraint contract_termination_is_gross_misconduc_bool check ("IS_GROSS_MISCONDUCT" in (0, 1)),
  constraint contract_terminations_pkey primary key ("ID")
);

create table "CONTRACTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "KIND" VARCHAR2(14) not null
    constraint contracts_kind_enum check ("KIND" in ('cdi', 'cdd', 'seasonal', 'apprenticeship', 'interim')),
  "STATUS" VARCHAR2(9) default 'draft' not null
    constraint contracts_status_enum check ("STATUS" in ('draft', 'active', 'ended', 'cancelled')),
  "JOB_TITLE" VARCHAR2(4000) not null,
  "JOB_DESCRIPTION" VARCHAR2(4000),
  "WORK_PLACE" VARCHAR2(4000),
  "CATEGORY" VARCHAR2(4000),
  "START_DATE" DATE not null,
  "END_DATE" DATE,
  "CDD_REASON" VARCHAR2(4000),
  "RENEWAL_COUNT" NUMBER(5) default 0 not null,
  "PREVIOUS_CONTRACT_ID" VARCHAR2(36),
  "MONTHLY_GROSS" NUMBER(10,2) not null,
  "INDEX_REF" NUMBER(8,2),
  "WEEKLY_HOURS" NUMBER(5,2) default 40 not null,
  "DAYS_PER_WEEK" NUMBER(3,1) default 5 not null,
  "WORK_DISTRIBUTION" VARCHAR2(4000),
  "REFERENCE_PERIOD_MONTHS" NUMBER(5) default 4 not null,
  "NIGHT_WORK" NUMBER(1) default 0 not null constraint contracts_night_work_bool check ("NIGHT_WORK" in (0, 1)),
  "ANNUAL_LEAVE_DAYS" NUMBER(5,2),
  "BREAK_MINUTES" NUMBER(5),
  "NON_COMPETE_CLAUSE" NUMBER(1) default 0 not null constraint contracts_non_compete_clause_bool check ("NON_COMPETE_CLAUSE" in (0, 1)),
  "EXCLUSIVITY_CLAUSE" NUMBER(1) default 0 not null constraint contracts_exclusivity_clause_bool check ("EXCLUSIVITY_CLAUSE" in (0, 1)),
  "PROBATION_LENGTH" NUMBER(10),
  "PROBATION_UNIT" VARCHAR2(4000),
  "VERSION" NUMBER(5) default 1 not null,
  "SIGNED_AT" DATE,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "IS_PART_TIME" NUMBER(1) default 0 not null constraint contracts_is_part_time_bool check ("IS_PART_TIME" in (0, 1)),
  "APPRENTICESHIP_LEVEL" VARCHAR2(4000),
  "APPRENTICESHIP_YEAR" NUMBER(5),
  "SEASON_LABEL" VARCHAR2(4000),
  "INTERIM_AGENCY_ID" VARCHAR2(36),
  "USER_COMPANY_NAME" VARCHAR2(4000),
  "MISSION_REASON" VARCHAR2(4000),
  constraint contracts_pkey primary key ("ID")
);

create table "DEPARTMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "NAME" VARCHAR2(4000) not null,
  "MIN_EVENING_COVERAGE" NUMBER(5),
  constraint departments_pkey primary key ("ID")
);

create table "DOCUMENT_TYPES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "STAGE" VARCHAR2(15) default 'during_contract' not null
    constraint document_types_stage_enum check ("STAGE" in ('pre_hire', 'during_contract', 'end_of_contract')),
  "VALIDITY_MONTHS" NUMBER(10),
  "IS_MANDATORY" NUMBER(1) default 0 not null constraint document_types_is_mandatory_bool check ("IS_MANDATORY" in (0, 1)),
  "APPLIES_TO_RESIDENCY" CLOB,
  "ALERT_DAYS_BEFORE" NUMBER(10) default 30 not null,
  "LEGAL_REF" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  constraint document_types_pkey primary key ("ID"),
  constraint document_types_code_key unique ("CODE")
);

create table "DOCUMENTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36),
  "ENTITY_TABLE" VARCHAR2(4000),
  "ENTITY_ID" VARCHAR2(36),
  "NAME" VARCHAR2(4000) not null,
  "STORAGE_PATH" VARCHAR2(4000) not null,
  "MIME_TYPE" VARCHAR2(4000),
  "SIZE_BYTES" NUMBER(19),
  "RETENTION_UNTIL" DATE,
  "IS_SENSITIVE" NUMBER(1) default 0 not null constraint documents_is_sensitive_bool check ("IS_SENSITIVE" in (0, 1)),
  "UPLOADED_BY" VARCHAR2(36),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "DOCUMENT_TYPE_ID" VARCHAR2(36),
  "ISSUED_ON" DATE,
  "EXPIRES_ON" DATE,
  "DELIVERED_AT" DATE,
  constraint documents_pkey primary key ("ID")
);

create table "EMPLOYEE_CHILDREN" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "FIRST_NAME" VARCHAR2(4000),
  "LAST_NAME" VARCHAR2(4000),
  "SEX" VARCHAR2(11)
    constraint employee_children_sex_enum check ("SEX" in ('male', 'female', 'unspecified')),
  "BIRTH_DATE" DATE not null,
  "RELATIONSHIP" VARCHAR2(4000) default 'child' not null,
  "IS_DEPENDENT" NUMBER(1) default 1 not null constraint employee_children_is_dependent_bool check ("IS_DEPENDENT" in (0, 1)),
  "PRIVACY_OPT_OUT" NUMBER(1) default 0 not null constraint employee_children_privacy_opt_out_bool check ("PRIVACY_OPT_OUT" in (0, 1)),
  "ADOPTION_DATE" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint employee_children_pkey primary key ("ID")
);

create table "EMPLOYEE_DISABILITIES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "RATE_PCT" NUMBER(5,2) not null,
  "RECOGNIZED_ON" DATE,
  "AUTHORITY" VARCHAR2(4000),
  "EXTRA_LEAVE_DAYS_OVERRIDE" NUMBER(4,1),
  "EVIDENCE_DOCUMENT_ID" VARCHAR2(36),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint employee_disabilities_pkey primary key ("ID")
);

create table "EMPLOYEE_STATUSES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "KIND" VARCHAR2(18) not null
    constraint employee_statuses_kind_enum check ("KIND" in ('pregnancy', 'maternity_leave', 'breastfeeding', 'parental_leave', 'delegate', 'safety_delegate', 'equality_delegate', 'reemployment_bonus', 'company_manager', 'protected_other')),
  "DECLARED_ON" DATE default CURRENT_DATE not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE,
  "EXPECTED_BIRTH_DATE" DATE,
  "ACTUAL_BIRTH_DATE" DATE,
  "EVIDENCE_DOCUMENT_ID" VARCHAR2(36),
  "HOURS_CREDIT_MONTHLY" NUMBER(5,1),
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint employee_statuses_pkey primary key ("ID")
);

create table "EMPLOYEE_TAX_CARDS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "TAX_CLASS" VARCHAR2(8) not null
    constraint employee_tax_cards_tax_class_enum check ("TAX_CLASS" in ('1', '1a', '2')),
  "RATE" NUMBER(6,4),
  "MONTHLY_ALLOWANCE" NUMBER(10,2) default 0 not null,
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "CREDITS" CLOB default '[]' not null constraint employee_tax_cards_credits_json check ("CREDITS" is json),
  "COMMUTE_DISTANCE_KM" NUMBER(6,1),
  "PROFESSIONAL_EXPENSES_MONTHLY" NUMBER(10,2),
  "OTHER_DEDUCTIONS_MONTHLY" NUMBER(10,2) default 0 not null,
  "CARD_REFERENCE" VARCHAR2(4000),
  "ISSUED_ON" DATE,
  constraint employee_tax_cards_pkey primary key ("ID")
);

create table "EMPLOYEES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "USER_ID" VARCHAR2(36),
  "DEPARTMENT_ID" VARCHAR2(36),
  "FIRST_NAME" VARCHAR2(4000) not null,
  "LAST_NAME" VARCHAR2(4000) not null,
  "BIRTH_DATE" DATE,
  "RESIDENCY" VARCHAR2(13) not null
    constraint employees_residency_enum check ("RESIDENCY" in ('resident', 'frontalier_fr', 'frontalier_be', 'frontalier_de')),
  "QUALIFICATION" VARCHAR2(11) default 'unqualified' not null
    constraint employees_qualification_enum check ("QUALIFICATION" in ('qualified', 'unqualified')),
  "ADDRESS_LINE" VARCHAR2(4000),
  "POSTAL_CODE" VARCHAR2(4000),
  "CITY" VARCHAR2(4000),
  "COUNTRY" VARCHAR2(4000) default 'LU' not null,
  "EMAIL" VARCHAR2(4000),
  "PHONE" VARCHAR2(4000),
  "NATIONAL_ID_ENC" BLOB,
  "IBAN_ENC" BLOB,
  "NATIONAL_ID_HINT" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "SEX" VARCHAR2(11) default 'unspecified' not null
    constraint employees_sex_enum check ("SEX" in ('male', 'female', 'unspecified')),
  "CAREER_START_DATE" DATE,
  "PROFESSION" VARCHAR2(4000),
  "IS_MANAGEMENT" NUMBER(1) default 0 not null constraint employees_is_management_bool check ("IS_MANAGEMENT" in (0, 1)),
  constraint employees_pkey primary key ("ID")
);

create table "EXPORT_LOG" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36) not null,
  "REQUESTED_BY" VARCHAR2(36),
  "SUBJECT_KIND" VARCHAR2(4000) not null,
  "SUBJECT_ID" VARCHAR2(36),
  "ROW_COUNT" NUMBER(10) default 0 not null,
  "BYTE_SIZE" NUMBER(10) default 0 not null,
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint export_log_pkey primary key ("ID")
);

create table "HEADCOUNT_SNAPSHOTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "MONTH" DATE not null,
  "HEADCOUNT" NUMBER(8,2) not null,
  constraint headcount_snapshots_pkey primary key ("ID"),
  constraint headcount_snapshots_company_ unique ("COMPANY_ID", "MONTH")
);

create table "INTERIM_AGENCIES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "ORGANIZATION_ID" VARCHAR2(36) not null,
  "NAME" VARCHAR2(4000) not null,
  "CCSS_MATRICULE" VARCHAR2(4000),
  "RCS_NUMBER" VARCHAR2(4000),
  "ADDRESS_LINE" VARCHAR2(4000),
  "POSTAL_CODE" VARCHAR2(4000),
  "CITY" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint interim_agencies_pkey primary key ("ID")
);

create table "LEGAL_PARAMETERS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "FAMILY" VARCHAR2(9) not null
    constraint legal_parameters_family_enum check ("FAMILY" in ('social', 'fiscal', 'worktime', 'leave', 'contract', 'headcount', 'ccss')),
  "PARAM_KEY" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "VALUE_NUM" NUMBER,
  "VALUE_TEXT" VARCHAR2(4000),
  "VALUE_JSON" CLOB constraint legal_parameters_value_json_json check ("VALUE_JSON" is json),
  "UNIT" VARCHAR2(4000),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "INDEX_REF" NUMBER(8,2),
  "SOURCE" VARCHAR2(4000) not null,
  "LEGAL_REF" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  "ENTERED_BY" VARCHAR2(36),
  "ENTERED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "VALIDATED_BY" VARCHAR2(36),
  "VALIDATED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "DERIVED_FROM_KEY" VARCHAR2(4000),
  "DERIVED_FACTOR" NUMBER,
  "DERIVATION_TOLERANCE" NUMBER default 0.02 not null,
  constraint legal_parameters_pkey primary key ("ID")
);

create table "MEAL_VOUCHER_GRANTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "PERIOD_START" DATE not null,
  "PERIOD_END" DATE not null,
  "VOUCHER_COUNT" NUMBER(10) not null,
  "FACE_VALUE" NUMBER(6,2) not null,
  "EMPLOYEE_SHARE" NUMBER(6,2) default 0 not null,
  "GRANTED_ON" DATE,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint meal_voucher_grants_pkey primary key ("ID")
);

create table "ORGANIZATIONS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "NAME" VARCHAR2(4000) not null,
  "KIND" VARCHAR2(9) default 'fiduciary' not null
    constraint organizations_kind_enum check ("KIND" in ('fiduciary', 'company')),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint organizations_pkey primary key ("ID")
);

create table "OVERTIME_REQUESTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "SCHEDULE_ID" VARCHAR2(36),
  "PERIOD_START" DATE not null,
  "PERIOD_END" DATE not null,
  "HOURS" NUMBER(6,2) not null,
  "REASON" VARCHAR2(4000) not null,
  "STATUS" VARCHAR2(4000) default 'requested' not null,
  "REQUESTED_BY" VARCHAR2(36),
  "REQUESTED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  "HR_VALIDATED_BY" VARCHAR2(36),
  "HR_VALIDATED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "EMPLOYEE_ACCEPTED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "REJECTED_REASON" VARCHAR2(4000),
  "COMPENSATION" VARCHAR2(4000) default 'money' not null,
  "NOTE" VARCHAR2(4000),
  constraint overtime_requests_pkey primary key ("ID")
);

create table "PREMIUMS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "CONTRACT_ID" VARCHAR2(36),
  "TERMINATION_ID" VARCHAR2(36),
  "KIND" VARCHAR2(4000) default 'other' not null,
  "LABEL" VARCHAR2(4000) not null,
  "AMOUNT" NUMBER(12,2) not null,
  "GRANTED_ON" DATE not null,
  "FISCAL_YEAR" NUMBER(5) not null,
  "IS_TAXABLE" NUMBER(1) default 1 not null constraint premiums_is_taxable_bool check ("IS_TAXABLE" in (0, 1)),
  "IS_CONTRIBUTORY" NUMBER(1) default 1 not null constraint premiums_is_contributory_bool check ("IS_CONTRIBUTORY" in (0, 1)),
  "EXEMPT_PCT" NUMBER(6,3) default 0 not null,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint premiums_pkey primary key ("ID")
);

create table "PROBATION_EXTENSIONS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CONTRACT_ID" VARCHAR2(36) not null,
  "FROM_DATE" DATE not null,
  "TO_DATE" DATE not null,
  "DAYS_ADDED" NUMBER(10) not null,
  "REASON" VARCHAR2(4000) default 'incapacitÃ© de travail' not null,
  constraint probation_extensions_pkey primary key ("ID")
);

create table "PROFILES" (
  "ID" VARCHAR2(36) not null,
  "ORGANIZATION_ID" VARCHAR2(36) not null,
  "FULL_NAME" VARCHAR2(4000) default '' not null,
  "EMAIL" VARCHAR2(4000) default '' not null,
  "IS_ORG_ADMIN" NUMBER(1) default 0 not null constraint profiles_is_org_admin_bool check ("IS_ORG_ADMIN" in (0, 1)),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint profiles_pkey primary key ("ID")
);

create table "PUBLIC_HOLIDAYS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "YEAR" NUMBER(5) not null,
  "HOLIDAY_DATE" DATE not null,
  "NAME" VARCHAR2(4000) not null,
  "IS_MOBILE" NUMBER(1) default 0 not null constraint public_holidays_is_mobile_bool check ("IS_MOBILE" in (0, 1)),
  "COLLECTIVE_AGREEMENT_ID" VARCHAR2(36),
  "IS_RECOVERABLE" NUMBER(1) default 0 not null constraint public_holidays_is_recoverable_bool check ("IS_RECOVERABLE" in (0, 1)),
  "RECOVERY_REASON" VARCHAR2(4000),
  constraint public_holidays_pkey primary key ("ID")
);

create table "REFERENCE_PERIODS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "DEPARTMENT_ID" VARCHAR2(36),
  "LABEL" VARCHAR2(4000) not null,
  "START_DATE" DATE not null,
  "END_DATE" DATE not null,
  "MONTHS" NUMBER(5) not null,
  constraint reference_periods_pkey primary key ("ID")
);

create table "SCHEDULES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "DEPARTMENT_ID" VARCHAR2(36),
  "WEEK_START" DATE not null,
  "LABEL" VARCHAR2(4000),
  "STATUS" VARCHAR2(9) default 'draft' not null
    constraint schedules_status_enum check ("STATUS" in ('draft', 'published')),
  "PUBLISHED_AT" TIMESTAMP(6) WITH TIME ZONE,
  "PUBLISHED_BY" VARCHAR2(36),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint schedules_pkey primary key ("ID"),
  constraint schedules_company_id_departm unique ("COMPANY_ID", "DEPARTMENT_ID", "WEEK_START")
);

create table "SHIFT_TEMPLATES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "NAME" VARCHAR2(4000) not null,
  "START_TIME" VARCHAR2(8) not null,
  "END_TIME" VARCHAR2(8) not null,
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "COLOR" VARCHAR2(4000) default '#017E84' not null,
  "DEPARTMENT_ID" VARCHAR2(36),
  constraint shift_templates_pkey primary key ("ID")
);

create table "SHIFTS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "SCHEDULE_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "SHIFT_DATE" DATE not null,
  "START_TIME" VARCHAR2(8) not null,
  "END_TIME" VARCHAR2(8) not null,
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "LABEL" VARCHAR2(4000),
  "TEMPLATE_ID" VARCHAR2(36),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint shifts_pkey primary key ("ID")
);

create table "TAX_BRACKETS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "TAX_CLASS" VARCHAR2(8) not null
    constraint tax_brackets_tax_class_enum check ("TAX_CLASS" in ('1', '1a', '2')),
  "PERIODICITY" VARCHAR2(8) default 'monthly' not null
    constraint tax_brackets_periodicity_enum check ("PERIODICITY" in ('monthly', 'daily', 'annual')),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "BRACKET_MIN" NUMBER(12,2) not null,
  "BRACKET_MAX" NUMBER(12,2),
  "BASE_TAX" NUMBER(12,2) default 0 not null,
  "RATE_OVER_MIN" NUMBER(7,4) not null,
  "SOURCE" VARCHAR2(4000) default 'ACD' not null,
  "LEGAL_REF" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  constraint tax_brackets_pkey primary key ("ID")
);

create table "TAX_CREDITS" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "CODE" VARCHAR2(4000) not null,
  "LABEL" VARCHAR2(4000) not null,
  "APPLIES_TO_CLASSES" CLOB,
  "INCOME_MIN" NUMBER(12,2),
  "INCOME_MAX" NUMBER(12,2),
  "MONTHLY_AMOUNT" NUMBER(10,2),
  "PRORATED_ON_HOURS" NUMBER(1) default 0 not null constraint tax_credits_prorated_on_hours_bool check ("PRORATED_ON_HOURS" in (0, 1)),
  "VALID_FROM" DATE not null,
  "VALID_TO" DATE,
  "SOURCE" VARCHAR2(4000) default 'ACD' not null,
  "LEGAL_REF" VARCHAR2(4000),
  "NOTE" VARCHAR2(4000),
  constraint tax_credits_pkey primary key ("ID")
);

create table "TIME_ENTRIES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "COMPANY_ID" VARCHAR2(36) not null,
  "EMPLOYEE_ID" VARCHAR2(36) not null,
  "ENTRY_DATE" DATE not null,
  "START_TIME" VARCHAR2(8),
  "END_TIME" VARCHAR2(8),
  "BREAK_MINUTES" NUMBER(5) default 0 not null,
  "WORKED_HOURS" NUMBER(5,2),
  "PLANNED_HOURS" NUMBER(5,2),
  "SUNDAY_HOURS" NUMBER(5,2) default 0 not null,
  "HOLIDAY_HOURS" NUMBER(5,2) default 0 not null,
  "NIGHT_HOURS" NUMBER(5,2) default 0 not null,
  "OVERTIME_HOURS" NUMBER(5,2) default 0 not null,
  "IS_VALIDATED" NUMBER(1) default 0 not null constraint time_entries_is_validated_bool check ("IS_VALIDATED" in (0, 1)),
  "SOURCE" VARCHAR2(4000) default 'manual' not null,
  "NOTE" VARCHAR2(4000),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint time_entries_pkey primary key ("ID"),
  constraint time_entries_employee_id_ent unique ("EMPLOYEE_ID", "ENTRY_DATE")
);

create table "USER_ROLES" (
  "ID" VARCHAR2(36) default LOWER(REGEXP_REPLACE(RAWTOHEX(SYS_GUID()), '(.{8})(.{4})(.{4})(.{4})(.{12})', '\1-\2-\3-\4-\5')) not null,
  "USER_ID" VARCHAR2(36) not null,
  "ORGANIZATION_ID" VARCHAR2(36) not null,
  "COMPANY_ID" VARCHAR2(36),
  "ROLE" VARCHAR2(15) not null
    constraint user_roles_role_enum check ("ROLE" in ('fiduciary_admin', 'manager', 'service_manager', 'employee')),
  "CREATED_AT" TIMESTAMP(6) WITH TIME ZONE default SYSTIMESTAMP not null,
  constraint user_roles_pkey primary key ("ID"),
  constraint user_roles_user_id_company_i unique ("USER_ID", "COMPANY_ID", "ROLE")
);

-- Clés étrangères, posées après toutes les tables.
alter table "ABSENCE_ENTITLEMENTS" add constraint absence_entitlements_absence foreign key ("ABSENCE_TYPE_ID") references "ABSENCE_TYPES" ("ID") on delete cascade;
alter table "ABSENCES" add constraint absences_absence_type_id_fke foreign key ("ABSENCE_TYPE_ID") references "ABSENCE_TYPES" ("ID");
alter table "ABSENCES" add constraint absences_child_id_fkey foreign key ("CHILD_ID") references "EMPLOYEE_CHILDREN" ("ID") on delete set null;
alter table "ABSENCES" add constraint absences_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "ABSENCES" add constraint absences_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "CBA_RULES" add constraint cba_rules_collective_agreeme foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete cascade;
alter table "CBA_SALARY_GRIDS" add constraint cba_salary_grids_collective_ foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID") on delete cascade;
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
alter table "CONTRACT_AMENDMENTS" add constraint contract_amendments_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_AMENDMENTS" add constraint contract_amendments_contract foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_collective_agreemen foreign key ("COLLECTIVE_AGREEMENT_ID") references "COLLECTIVE_AGREEMENTS" ("ID");
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_collective_agreemen foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_bene foreign key ("BENEFIT_TYPE_ID") references "BENEFIT_TYPES" ("ID") on delete set null;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_comp foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_PAY_COMPONENTS" add constraint contract_pay_components_cont foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACT_TERMINATIONS" add constraint contract_terminations_compan foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACT_TERMINATIONS" add constraint contract_terminations_contra foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "CONTRACTS" add constraint contracts_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "CONTRACTS" add constraint contracts_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "CONTRACTS" add constraint contracts_interim_agency_fk foreign key ("INTERIM_AGENCY_ID") references "INTERIM_AGENCIES" ("ID") on delete set null;
alter table "CONTRACTS" add constraint contracts_previous_contract_ foreign key ("PREVIOUS_CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "DEPARTMENTS" add constraint departments_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "DOCUMENTS" add constraint documents_document_type_id_f foreign key ("DOCUMENT_TYPE_ID") references "DOCUMENT_TYPES" ("ID") on delete set null;
alter table "DOCUMENTS" add constraint documents_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEE_CHILDREN" add constraint employee_children_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_CHILDREN" add constraint employee_children_employee_i foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_compan foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_employ foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_eviden foreign key ("EVIDENCE_DOCUMENT_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_employee_i foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEE_STATUSES" add constraint employee_statuses_evidence_d foreign key ("EVIDENCE_DOCUMENT_ID") references "DOCUMENTS" ("ID") on delete set null;
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_company_i foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEE_TAX_CARDS" add constraint employee_tax_cards_employee_ foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "EMPLOYEES" add constraint employees_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "EMPLOYEES" add constraint employees_department_id_fkey foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "EXPORT_LOG" add constraint export_log_organization_id_f foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "HEADCOUNT_SNAPSHOTS" add constraint headcount_snapshots_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "INTERIM_AGENCIES" add constraint interim_agencies_organizatio foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;
alter table "MEAL_VOUCHER_GRANTS" add constraint meal_voucher_grants_company_ foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "MEAL_VOUCHER_GRANTS" add constraint meal_voucher_grants_employee foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_employee_i foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_schedule_i foreign key ("SCHEDULE_ID") references "SCHEDULES" ("ID") on delete set null;
alter table "PREMIUMS" add constraint premiums_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "PREMIUMS" add constraint premiums_contract_id_fkey foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete set null;
alter table "PREMIUMS" add constraint premiums_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "PREMIUMS" add constraint premiums_termination_id_fkey foreign key ("TERMINATION_ID") references "CONTRACT_TERMINATIONS" ("ID") on delete set null;
alter table "PROBATION_EXTENSIONS" add constraint probation_extensions_contrac foreign key ("CONTRACT_ID") references "CONTRACTS" ("ID") on delete cascade;
alter table "PROFILES" add constraint profiles_organization_id_fke foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID");
alter table "REFERENCE_PERIODS" add constraint reference_periods_company_id foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "REFERENCE_PERIODS" add constraint reference_periods_department foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SCHEDULES" add constraint schedules_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SCHEDULES" add constraint schedules_department_id_fkey foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SHIFT_TEMPLATES" add constraint shift_templates_company_id_f foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SHIFT_TEMPLATES" add constraint shift_templates_department_i foreign key ("DEPARTMENT_ID") references "DEPARTMENTS" ("ID") on delete set null;
alter table "SHIFTS" add constraint shifts_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "SHIFTS" add constraint shifts_employee_id_fkey foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "SHIFTS" add constraint shifts_schedule_id_fkey foreign key ("SCHEDULE_ID") references "SCHEDULES" ("ID") on delete cascade;
alter table "SHIFTS" add constraint shifts_template_id_fkey foreign key ("TEMPLATE_ID") references "SHIFT_TEMPLATES" ("ID") on delete set null;
alter table "TIME_ENTRIES" add constraint time_entries_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "TIME_ENTRIES" add constraint time_entries_employee_id_fke foreign key ("EMPLOYEE_ID") references "EMPLOYEES" ("ID") on delete cascade;
alter table "USER_ROLES" add constraint user_roles_company_id_fkey foreign key ("COMPANY_ID") references "COMPANIES" ("ID") on delete cascade;
alter table "USER_ROLES" add constraint user_roles_organization_id_f foreign key ("ORGANIZATION_ID") references "ORGANIZATIONS" ("ID") on delete cascade;

-- Contraintes de validation.
alter table "ABSENCE_ENTITLEMENTS" add constraint entitlement_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "ABSENCES" add constraint absence_range CHECK ((end_date >= start_date));
alter table "COMPANIES" add constraint ccss_matricule_format CHECK (((ccss_matricule IS NULL) OR (ccss_matricule ~ '^[0-9]{13}$'::text)));
alter table "COMPANIES" add constraint companies_reference_period_m CHECK (((reference_period_months >= 1) AND (reference_period_months <= 4)));
alter table "COMPANY_COLLECTIVE_AGREEMENTS" add constraint company_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "COMPANY_RATE_PERIODS" add constraint company_rate_periods_mutuali CHECK (((mutuality_class >= 1) AND (mutuality_class <= 4)));
alter table "COMPANY_RATE_PERIODS" add constraint rate_period_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACT_COLLECTIVE_AGREEMENTS" add constraint contract_cba_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACT_PAY_COMPONENTS" add constraint pay_component_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "CONTRACTS" add constraint cdd_needs_reason CHECK (((kind <> 'cdd'::contract_kind) OR (cdd_reason IS NOT NULL)));
alter table "CONTRACTS" add constraint fixed_term_needs_end CHECK (((kind <> ALL (ARRAY['cdd'::contract_kind, 'seasonal'::contract_kind, 'interim'::contract_kind, 'apprenticeship'::contract_kind])) OR (end_date IS NOT NULL)));
alter table "CONTRACTS" add constraint interim_needs_user_company CHECK (((kind <> 'interim'::contract_kind) OR (user_company_name IS NOT NULL)));
alter table "EMPLOYEE_CHILDREN" add constraint privacy_minimises_data CHECK (((NOT privacy_opt_out) OR ((first_name IS NULL) AND (last_name IS NULL) AND (sex IS NULL) AND (note IS NULL))));
alter table "EMPLOYEE_DISABILITIES" add constraint disability_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "EMPLOYEE_DISABILITIES" add constraint employee_disabilities_rate_p CHECK (((rate_pct > (0)::numeric) AND (rate_pct <= (100)::numeric)));
alter table "EMPLOYEE_STATUSES" add constraint status_range CHECK (((end_date IS NULL) OR (end_date >= start_date)));
alter table "LEGAL_PARAMETERS" add constraint one_value CHECK (((num_nonnulls(value_num, value_text, value_json) = 1) OR ((derived_from_key IS NOT NULL) AND (num_nonnulls(value_num, value_text, value_json) = 0))));
alter table "LEGAL_PARAMETERS" add constraint valid_range CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "MEAL_VOUCHER_GRANTS" add constraint meal_voucher_grants_voucher_ CHECK ((voucher_count >= 0));
alter table "MEAL_VOUCHER_GRANTS" add constraint voucher_period CHECK ((period_end >= period_start));
alter table "OVERTIME_REQUESTS" add constraint overtime_period CHECK ((period_end >= period_start));
alter table "OVERTIME_REQUESTS" add constraint overtime_requests_hours_chec CHECK ((hours > (0)::numeric));
alter table "PREMIUMS" add constraint premiums_amount_check CHECK ((amount >= (0)::numeric));
alter table "REFERENCE_PERIODS" add constraint prl_range CHECK ((end_date > start_date));
alter table "REFERENCE_PERIODS" add constraint reference_periods_months_che CHECK (((months >= 1) AND (months <= 4)));
alter table "TAX_BRACKETS" add constraint bracket_range CHECK (((bracket_max IS NULL) OR (bracket_max > bracket_min)));
alter table "TAX_BRACKETS" add constraint bracket_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));
alter table "TAX_CREDITS" add constraint credit_validity CHECK (((valid_to IS NULL) OR (valid_to > valid_from)));

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

create or replace trigger absence_entitlements_no_overlap
  after insert or update on "ABSENCE_ENTITLEMENTS"
declare
  n number;
begin
  select count(*) into n
    from "ABSENCE_ENTITLEMENTS" a join "ABSENCE_ENTITLEMENTS" b on a."ID" <> b."ID"
   where (a."ABSENCE_TYPE_ID" = b."ABSENCE_TYPE_ID" or (a."ABSENCE_TYPE_ID" is null and b."ABSENCE_TYPE_ID" is null))
     and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
     and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur absence_entitlements : une date ne peut avoir qu''une valeur');
  end if;
end;
/

create or replace trigger company_rate_periods_no_overlap
  after insert or update on "COMPANY_RATE_PERIODS"
declare
  n number;
begin
  select count(*) into n
    from "COMPANY_RATE_PERIODS" a join "COMPANY_RATE_PERIODS" b on a."ID" <> b."ID"
   where (a."COMPANY_ID" = b."COMPANY_ID" or (a."COMPANY_ID" is null and b."COMPANY_ID" is null))
     and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
     and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur company_rate_periods : une date ne peut avoir qu''une valeur');
  end if;
end;
/

create or replace trigger employee_disabilities_no_overlap
  after insert or update on "EMPLOYEE_DISABILITIES"
declare
  n number;
begin
  select count(*) into n
    from "EMPLOYEE_DISABILITIES" a join "EMPLOYEE_DISABILITIES" b on a."ID" <> b."ID"
   where (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
     and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
     and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur employee_disabilities : une date ne peut avoir qu''une valeur');
  end if;
end;
/

create or replace trigger employee_tax_cards_no_overlap
  after insert or update on "EMPLOYEE_TAX_CARDS"
declare
  n number;
begin
  select count(*) into n
    from "EMPLOYEE_TAX_CARDS" a join "EMPLOYEE_TAX_CARDS" b on a."ID" <> b."ID"
   where (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
     and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
     and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur employee_tax_cards : une date ne peut avoir qu''une valeur');
  end if;
end;
/

create or replace trigger legal_parameters_no_overlap
  after insert or update on "LEGAL_PARAMETERS"
declare
  n number;
begin
  select count(*) into n
    from "LEGAL_PARAMETERS" a join "LEGAL_PARAMETERS" b on a."ID" <> b."ID"
   where (a."PARAM_KEY" = b."PARAM_KEY" or (a."PARAM_KEY" is null and b."PARAM_KEY" is null))
     and a."VALID_FROM" < nvl(b."VALID_TO", date '9999-12-31')
     and nvl(a."VALID_TO", date '9999-12-31') > b."VALID_FROM";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur legal_parameters : une date ne peut avoir qu''une valeur');
  end if;
end;
/

create or replace trigger meal_voucher_grants_no_overlap
  after insert or update on "MEAL_VOUCHER_GRANTS"
declare
  n number;
begin
  select count(*) into n
    from "MEAL_VOUCHER_GRANTS" a join "MEAL_VOUCHER_GRANTS" b on a."ID" <> b."ID"
   where (a."EMPLOYEE_ID" = b."EMPLOYEE_ID" or (a."EMPLOYEE_ID" is null and b."EMPLOYEE_ID" is null))
     and a."PERIOD_START" < nvl(b."PERIOD_END", date '9999-12-31')
     and nvl(a."PERIOD_END", date '9999-12-31') > b."PERIOD_START";
  if n > 0 then
    raise_application_error(-20001,
      'Deux periodes se recouvrent sur meal_voucher_grants : une date ne peut avoir qu''une valeur');
  end if;
end;
/


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
