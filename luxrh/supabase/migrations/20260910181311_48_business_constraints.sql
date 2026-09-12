-- 48 — Contraintes métier au niveau de la base
--
-- Le principe : une règle vérifiée à trois endroits
-- -------------------------------------------------
-- Le front empêche de saisir l'absurde, le moteur refuse de conclure sur
-- l'incohérent, et la base refuse de le stocker. Si l'une des trois couches laisse
-- passer un défaut, les deux autres l'interceptent. Cette migration pose la
-- troisième — la dernière, celle qu'aucun appel d'API ne contourne, pas même un
-- accès direct au SQL.
--
-- Ce que cette migration ne fait PAS
-- ----------------------------------
-- Elle n'inscrit **aucun seuil légal**. Une durée maximale de travail, un plafond
-- de prime, une durée d'essai : tout cela vit dans `legal_parameters`, daté et
-- sourcé, et change sans migration. Une contrainte `check` est figée dans le
-- schéma — y écrire un chiffre de loi serait un bug le jour où la loi change,
-- et une violation de la règle 1 du CLAUDE.md.
--
-- Les contraintes ci-dessous ne portent donc que sur des invariants **structurels** :
-- une fin après un début, une part qui ne dépasse pas son tout, un pourcentage
-- entre 0 et 100, une semaine qui n'a pas huit jours, un état qui s'accorde avec
-- l'horodatage qui l'atteste.
--
-- Toutes ont été vérifiées sans violation contre les données déployées avant
-- d'être écrites ici. Un seul candidat a été écarté — voir la note finale.

-- ===========================================================================
-- 1. Cohérence temporelle : une fin ne précède pas un début
-- ===========================================================================

alter table contracts
  add constraint contract_dates_order
  check (end_date is null or end_date >= start_date);

alter table contract_terminations
  add constraint notice_dates_order
  check (notice_start is null or notice_end is null or notice_end >= notice_start);

alter table employee_tax_cards
  add constraint tax_card_range
  check (valid_to is null or valid_to > valid_from);

alter table documents
  add constraint document_expiry_after_issue
  check (expires_on is null or issued_on is null or expires_on >= issued_on);

alter table cba_salary_grids
  add constraint grid_seniority_order
  check (seniority_to_years is null or seniority_to_years > seniority_from_years);

alter table tax_credits
  add constraint credit_income_order
  check (income_max is null or income_min is null or income_max > income_min);

alter table public_holidays
  add constraint holiday_year_matches_date
  check (extract(year from holiday_date)::int = year);

-- `extract(day …) = 1` plutôt que `date_trunc` : une contrainte check exige une
-- expression immuable, et date_trunc dépend du fuseau dès que l'argument est un
-- timestamptz. Le test du premier jour du mois dit la même chose sans ce risque.
alter table headcount_snapshots
  add constraint headcount_month_is_first_day
  check (extract(day from month)::int = 1);

-- ===========================================================================
-- 2. Quantités : ce qui ne peut pas être négatif
-- ===========================================================================
-- Aucune borne haute ici : un maximum de travail ou de rémunération relève de la
-- loi, donc du référentiel.

alter table contracts
  add constraint contract_quantities_positive
  check (
    weekly_hours > 0
    and days_per_week > 0 and days_per_week <= 7   -- une semaine a sept jours
    and monthly_gross >= 0
    and renewal_count >= 0
    and (break_minutes is null or break_minutes >= 0)
    and (annual_leave_days is null or annual_leave_days >= 0)
    and (probation_length is null or probation_length > 0)
    and (apprenticeship_year is null or apprenticeship_year > 0)
  );

alter table absences
  add constraint absence_days_positive
  check (days_count >= 0);

alter table absence_entitlements
  add constraint entitlement_days_positive
  check (days is null or days >= 0);

alter table shifts
  add constraint shift_break_positive
  check (break_minutes >= 0);

alter table shift_templates
  add constraint template_break_positive
  check (break_minutes >= 0);

alter table time_entries
  add constraint time_entry_hours_positive
  check (
    break_minutes >= 0
    and (worked_hours  is null or worked_hours  >= 0)
    and (planned_hours is null or planned_hours >= 0)
    and sunday_hours >= 0 and holiday_hours >= 0
    and night_hours  >= 0 and overtime_hours >= 0
  );

alter table documents
  add constraint document_size_positive
  check (size_bytes is null or size_bytes >= 0);

alter table contract_terminations
  add constraint waiver_compensation_positive
  check (waiver_compensation is null or waiver_compensation >= 0);

alter table cba_salary_grids
  add constraint grid_amount_positive
  check (monthly_amount > 0);

alter table employee_tax_cards
  add constraint tax_card_amounts_positive
  check (monthly_allowance >= 0
         and (professional_expenses_monthly is null or professional_expenses_monthly >= 0)
         and other_deductions_monthly >= 0
         and (commute_distance_km is null or commute_distance_km >= 0));

alter table headcount_snapshots
  add constraint headcount_positive
  check (headcount >= 0);

alter table company_accident_claims
  add constraint accident_counts_positive
  check (claim_count >= 0 and days_lost >= 0 and (cost is null or cost >= 0));

alter table departments
  add constraint coverage_positive
  check (min_evening_coverage is null or min_evening_coverage >= 0);

-- ===========================================================================
-- 3. Une part ne dépasse pas son tout
-- ===========================================================================

alter table time_entries
  add constraint time_entry_parts_within_worked
  check (
    worked_hours is null
    or (sunday_hours  <= worked_hours
        and holiday_hours  <= worked_hours
        and night_hours    <= worked_hours
        and overtime_hours <= worked_hours)
  );

alter table meal_voucher_grants
  add constraint voucher_share_within_face_value
  check (face_value > 0 and employee_share >= 0 and employee_share <= face_value);

alter table premiums
  add constraint premium_exempt_is_a_percentage
  check (exempt_pct >= 0 and exempt_pct <= 100);

-- ===========================================================================
-- 4. Un état s'accorde avec ce qui l'atteste
-- ===========================================================================
-- Ces trois contraintes portent une règle de gestion, pas un seuil : elles disent
-- qu'un état déclaré doit être adossé au fait qui le fonde.

-- Un planning est publié si et seulement s'il porte un horodatage de publication.
alter table schedules
  add constraint published_iff_timestamp
  check ((status = 'published') = (published_at is not null));

-- Le double accord sur les heures supplémentaires : le salarié ne peut pas avoir
-- accepté ce que les RH n'ont pas validé, et « approuvé » exige les deux.
alter table overtime_requests
  add constraint overtime_acceptance_follows_hr
  check (employee_accepted_at is null or hr_validated_at is not null);

alter table overtime_requests
  add constraint overtime_approved_needs_both_consents
  check (status <> 'approved'
         or (hr_validated_at is not null and employee_accepted_at is not null));

-- Une dispense de préavis est un accord : elle porte sa date.
alter table contract_terminations
  add constraint waiver_needs_agreement_date
  check (not notice_waived or waiver_agreed_on is not null);

-- Une durée d'essai et son unité vont par paire, ou pas du tout.
alter table contracts
  add constraint probation_length_and_unit_together
  check ((probation_length is null) = (probation_unit is null));

-- Un contrat ne se renouvelle pas lui-même.
alter table contracts
  add constraint contract_not_its_own_predecessor
  check (previous_contract_id is null or previous_contract_id <> id);

-- Une vacation a une durée : deux horaires identiques ne décrivent rien.
alter table shifts
  add constraint shift_times_differ
  check (start_time <> end_time);

-- Adresse électronique : forme minimale, sans prétendre valider la boîte.
alter table employees
  add constraint employee_email_shape
  check (email is null
         or email ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$');

-- ===========================================================================
-- 5. L'isolation entre sociétés, imposée par des clés composites
-- ===========================================================================
-- Jusqu'ici, rien n'empêchait *structurellement* d'écrire un contrat dont le
-- company_id désigne une société et dont l'employee_id désigne un salarié d'une
-- autre. RLS interdit de le lire, mais la ligne pouvait exister — et un export,
-- un recalcul ou une migration future l'aurait rencontrée.
--
-- Les clés étrangères composites ci-dessous rendent le cas impossible : la paire
-- (salarié, société) doit exister telle quelle dans employees. La règle 6 du
-- CLAUDE.md — l'isolation est imposée en base — cesse ainsi de reposer sur la
-- seule lecture.
--
-- `on update cascade` : déplacer un salarié d'une société à l'autre entraîne
-- toutes ses lignes, au lieu de les laisser orphelines.
-- `on delete cascade` : identique aux clés simples déjà en place.

alter table employees
  add constraint employees_id_company_uk unique (id, company_id);

alter table schedules
  add constraint schedules_id_company_uk unique (id, company_id);

alter table contracts
  add constraint contract_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table absences
  add constraint absence_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table time_entries
  add constraint time_entry_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table shifts
  add constraint shift_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table shifts
  add constraint shift_belongs_to_schedules_company
  foreign key (schedule_id, company_id) references schedules (id, company_id)
  on update cascade on delete cascade;

alter table employee_children
  add constraint child_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table employee_disabilities
  add constraint disability_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table employee_statuses
  add constraint status_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table premiums
  add constraint premium_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table meal_voucher_grants
  add constraint voucher_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

alter table overtime_requests
  add constraint overtime_belongs_to_employees_company
  foreign key (employee_id, company_id) references employees (id, company_id)
  on update cascade on delete cascade;

-- ===========================================================================
-- Commentaires : une contrainte se documente comme le reste
-- ===========================================================================

comment on constraint published_iff_timestamp on schedules is
  'Un planning publié porte son horodatage, et réciproquement : c''est lui qui fait courir le délai de prévenance.';
comment on constraint overtime_approved_needs_both_consents on overtime_requests is
  'Le double accord : la validation RH seule ne couvre pas les heures, l''acceptation du salarié est requise.';
comment on constraint contract_belongs_to_employees_company on contracts is
  'Isolation structurelle : le contrat et le salarié appartiennent forcément à la même société.';
comment on constraint premium_exempt_is_a_percentage on premiums is
  'Borne d''un pourcentage, non d''un régime : le taux d''exonération lui-même vit dans legal_parameters.';

-- ===========================================================================
-- Le candidat écarté
-- ===========================================================================
-- « Un contrat actif porte une date de signature » — vérifiable, et fondé : un
-- contrat actif non signé est un manquement que le moteur de vigilance signale
-- déjà. Mais 305 lignes du jeu déployé le violent, toutes issues du jeu de
-- démonstration. Poser la contrainte aurait cassé le rechargement des données de
-- démonstration ; la corriger relève du jeu de données, pas du schéma. La règle
-- reste donc portée par le moteur, et par lui seul, jusqu'à ce que fn_seed_demo
-- renseigne signed_at.
--
--   select count(*) from contracts where status = 'active' and signed_at is null;
