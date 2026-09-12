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

create table `ref_bloc_convention` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_bloc_convention_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('salary_grid', 'salary_grid', 1);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('worktime', 'worktime', 2);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('leave', 'leave', 3);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('premiums', 'premiums', 4);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('surcharges', 'surcharges', 5);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('notice_probation', 'notice_probation', 6);
insert into `ref_bloc_convention` (`code`, `label`, `sort_order`) values ('custom_holidays', 'custom_holidays', 7);

create table `ref_categorie_absence` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_categorie_absence_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('annual_leave', 'annual_leave', 1);
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('sick', 'sick', 2);
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('extraordinary', 'extraordinary', 3);
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('public_holiday', 'public_holiday', 4);
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('unpaid', 'unpaid', 5);
insert into `ref_categorie_absence` (`code`, `label`, `sort_order`) values ('compensatory', 'compensatory', 6);

create table `ref_classe_impot` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_classe_impot_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_classe_impot` (`code`, `label`, `sort_order`) values ('1', '1', 1);
insert into `ref_classe_impot` (`code`, `label`, `sort_order`) values ('1a', '1a', 2);
insert into `ref_classe_impot` (`code`, `label`, `sort_order`) values ('2', '2', 3);

create table `ref_etape_document` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_etape_document_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_etape_document` (`code`, `label`, `sort_order`) values ('pre_hire', 'pre_hire', 1);
insert into `ref_etape_document` (`code`, `label`, `sort_order`) values ('during_contract', 'during_contract', 2);
insert into `ref_etape_document` (`code`, `label`, `sort_order`) values ('end_of_contract', 'end_of_contract', 3);

create table `ref_etat_alerte` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_etat_alerte_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_etat_alerte` (`code`, `label`, `sort_order`) values ('open', 'open', 1);
insert into `ref_etat_alerte` (`code`, `label`, `sort_order`) values ('handled', 'handled', 2);
insert into `ref_etat_alerte` (`code`, `label`, `sort_order`) values ('dismissed', 'dismissed', 3);

create table `ref_famille_parametre` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_famille_parametre_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('social', 'social', 1);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('fiscal', 'fiscal', 2);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('worktime', 'worktime', 3);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('leave', 'leave', 4);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('contract', 'contract', 5);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('effectif', 'effectif', 6);
insert into `ref_famille_parametre` (`code`, `label`, `sort_order`) values ('ccss', 'ccss', 7);

create table `ref_genre_contrat` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_contrat_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_contrat` (`code`, `label`, `sort_order`) values ('cdi', 'cdi', 1);
insert into `ref_genre_contrat` (`code`, `label`, `sort_order`) values ('cdd', 'cdd', 2);
insert into `ref_genre_contrat` (`code`, `label`, `sort_order`) values ('seasonal', 'seasonal', 3);
insert into `ref_genre_contrat` (`code`, `label`, `sort_order`) values ('apprenticeship', 'apprenticeship', 4);
insert into `ref_genre_contrat` (`code`, `label`, `sort_order`) values ('interim', 'interim', 5);

create table `ref_genre_element_remuneration` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_element_remune_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_element_remuneration` (`code`, `label`, `sort_order`) values ('fixed', 'fixed', 1);
insert into `ref_genre_element_remuneration` (`code`, `label`, `sort_order`) values ('variable', 'variable', 2);
insert into `ref_genre_element_remuneration` (`code`, `label`, `sort_order`) values ('benefit_in_kind', 'benefit_in_kind', 3);
insert into `ref_genre_element_remuneration` (`code`, `label`, `sort_order`) values ('premium', 'premium', 4);
insert into `ref_genre_element_remuneration` (`code`, `label`, `sort_order`) values ('expense', 'expense', 5);

create table `ref_genre_organisation` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_organisation_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_organisation` (`code`, `label`, `sort_order`) values ('fiduciary', 'fiduciary', 1);
insert into `ref_genre_organisation` (`code`, `label`, `sort_order`) values ('company', 'company', 2);

create table `ref_genre_qualification` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_qualification_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_qualification` (`code`, `label`, `sort_order`) values ('qualified', 'qualified', 1);
insert into `ref_genre_qualification` (`code`, `label`, `sort_order`) values ('unqualified', 'unqualified', 2);

create table `ref_genre_residence` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_residence_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('resident', 'resident', 1);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_fr', 'frontalier_fr', 2);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_be', 'frontalier_be', 3);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_de', 'frontalier_de', 4);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_fra', 'frontalier_fra', 5);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_bel', 'frontalier_bel', 6);
insert into `ref_genre_residence` (`code`, `label`, `sort_order`) values ('frontalier_deu', 'frontalier_deu', 7);

create table `ref_genre_severite` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_severite_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_severite` (`code`, `label`, `sort_order`) values ('blocking', 'blocking', 1);
insert into `ref_genre_severite` (`code`, `label`, `sort_order`) values ('warning', 'warning', 2);
insert into `ref_genre_severite` (`code`, `label`, `sort_order`) values ('info', 'info', 3);
insert into `ref_genre_severite` (`code`, `label`, `sort_order`) values ('problem', 'problem', 4);

create table `ref_genre_sexe` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_sexe_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_sexe` (`code`, `label`, `sort_order`) values ('male', 'male', 1);
insert into `ref_genre_sexe` (`code`, `label`, `sort_order`) values ('female', 'female', 2);
insert into `ref_genre_sexe` (`code`, `label`, `sort_order`) values ('unspecified', 'unspecified', 3);

create table `ref_genre_statut_salarie` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_genre_statut_salarie_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('pregnancy', 'pregnancy', 1);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('maternity_leave', 'maternity_leave', 2);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('breastfeeding', 'breastfeeding', 3);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('parental_leave', 'parental_leave', 4);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('delegate', 'delegate', 5);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('safety_delegate', 'safety_delegate', 6);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('equality_delegate', 'equality_delegate', 7);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('reemployment_bonus', 'reemployment_bonus', 8);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('company_manager', 'company_manager', 9);
insert into `ref_genre_statut_salarie` (`code`, `label`, `sort_order`) values ('protected_other', 'protected_other', 10);

create table `ref_periodicite_impot` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_periodicite_impot_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_periodicite_impot` (`code`, `label`, `sort_order`) values ('monthly', 'monthly', 1);
insert into `ref_periodicite_impot` (`code`, `label`, `sort_order`) values ('daily', 'daily', 2);
insert into `ref_periodicite_impot` (`code`, `label`, `sort_order`) values ('annual', 'annual', 3);

create table `ref_portee_convention` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_portee_convention_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_portee_convention` (`code`, `label`, `sort_order`) values ('secteur', 'secteur', 1);
insert into `ref_portee_convention` (`code`, `label`, `sort_order`) values ('harassment', 'harassment', 2);
insert into `ref_portee_convention` (`code`, `label`, `sort_order`) values ('employee_category', 'employee_category', 3);
insert into `ref_portee_convention` (`code`, `label`, `sort_order`) values ('department', 'department', 4);
insert into `ref_portee_convention` (`code`, `label`, `sort_order`) values ('company', 'company', 5);

create table `ref_role_application` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_role_application_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('fiduciary_admin', 'fiduciary_admin', 1);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('manager', 'manager', 2);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('service_manager', 'service_manager', 3);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('employee', 'employee', 4);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('medecine_travail', 'medecine_travail', 5);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('rh_urgence', 'rh_urgence', 6);
insert into `ref_role_application` (`code`, `label`, `sort_order`) values ('dispatching', 'dispatching', 7);

create table `ref_statut_absence` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_statut_absence_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_statut_absence` (`code`, `label`, `sort_order`) values ('pending', 'pending', 1);
insert into `ref_statut_absence` (`code`, `label`, `sort_order`) values ('approved', 'approved', 2);
insert into `ref_statut_absence` (`code`, `label`, `sort_order`) values ('refused', 'refused', 3);
insert into `ref_statut_absence` (`code`, `label`, `sort_order`) values ('cancelled', 'cancelled', 4);
insert into `ref_statut_absence` (`code`, `label`, `sort_order`) values ('proposed', 'proposed', 5);

create table `ref_statut_contrat` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_statut_contrat_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_statut_contrat` (`code`, `label`, `sort_order`) values ('draft', 'draft', 1);
insert into `ref_statut_contrat` (`code`, `label`, `sort_order`) values ('active', 'active', 2);
insert into `ref_statut_contrat` (`code`, `label`, `sort_order`) values ('ended', 'ended', 3);
insert into `ref_statut_contrat` (`code`, `label`, `sort_order`) values ('cancelled', 'cancelled', 4);

create table `ref_statut_planning` (
  `code` VARCHAR(64) not null,
  `label` VARCHAR(200),
  `sort_order` SMALLINT,
  `valid_from` DATE default '1900-01-01',
  `valid_to` DATE,
  constraint ref_statut_planning_pk primary key (`code`)
) engine=InnoDB default charset=utf8mb4;
insert into `ref_statut_planning` (`code`, `label`, `sort_order`) values ('draft', 'draft', 1);
insert into `ref_statut_planning` (`code`, `label`, `sort_order`) values ('publie', 'publie', 2);


create table `absences` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `type_absence_id` CHAR(36) not null,
  `date_debut` DATE not null,
  `date_fin` DATE not null,
  `nombre_jours` DECIMAL(5,2) default 0 not null,
  `statut` VARCHAR(64) default 'pending' not null,
  `commentaire` TEXT,
  `certificat_recu` TINYINT(1) default 0 not null,
  `certificat_recu_le` DATE,
  `certificat_document_id` CHAR(36),
  `demande_par` CHAR(36),
  `decide_par` CHAR(36),
  `decide_le` DATETIME(6),
  `note_decision` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `declare_par_salarie` TINYINT(1) default 0 not null,
  `certificat_depose_le` DATETIME(6),
  `certificat_original_recu` TINYINT(1) default 0 not null,
  `certificat_original_recu_le` DATE,
  `enfant_id` CHAR(36),
  `absence_parente_id` CHAR(36),
  `proposee_par` TEXT,
  `rang_proposition` SMALLINT default 0 not null,
  constraint absences_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `adresses_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
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
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `cree_par` CHAR(36),
  `supprime_le` DATETIME(6),
  `supprime_par` CHAR(36),
  constraint adresses_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `agences_interim` (
  `id` CHAR(36) default (UUID()) not null,
  `organisation_id` CHAR(36) not null,
  `nom` TEXT not null,
  `matricule_ccss` TEXT,
  `numero_rcs` TEXT,
  `ligne` TEXT,
  `code_postal` TEXT,
  `localite` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint agences_interim_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `alertes_conformite` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36),
  `code_regle` TEXT not null,
  `titre` TEXT not null,
  `detail` TEXT not null,
  `consequence` TEXT,
  `reference_legale` TEXT,
  `severite` VARCHAR(64) not null,
  `date_echeance` DATE,
  `etat` VARCHAR(64) default 'open' not null,
  `traite_par` CHAR(36),
  `traite_le` DATETIME(6),
  `note_traitement` TEXT,
  `vu_la_premiere_fois_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint alertes_conformite_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `attributions_titres_repas` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `debut_periode` DATE not null,
  `fin_periode` DATE not null,
  `nombre_titres` INT not null,
  `valeur_faciale` DECIMAL(6,2) not null,
  `part_salariale` DECIMAL(6,2) default 0 not null,
  `attribue_le` DATE,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint attributions_titres_repas_pk primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `avenants_contrat` (
  `id` CHAR(36) default (UUID()) not null,
  `contrat_id` CHAR(36) not null,
  `societe_id` CHAR(36) not null,
  `date_effet` DATE not null,
  `motif` TEXT not null,
  `modifications` JSON not null,
  `cree_par` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint avenants_contrat_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `categories_sanction` (
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `rang` SMALLINT not null,
  `description` TEXT not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  constraint categories_sanction_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `cct_regle_prime` (
  `id` CHAR(36) default (UUID()) not null,
  `convention_id` CHAR(36) not null,
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
  `url_source` TEXT not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  constraint cct_regle_prime_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `comptes` (
  `id` CHAR(36) default (UUID()) not null,
  `identifiant` TEXT not null,
  `courriel` TEXT not null,
  `nom_complet` TEXT,
  `empreinte_mot_de_passe` TEXT,
  `est_admin` TINYINT(1) default 0 not null,
  `compte_auth_id` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `cree_par` CHAR(36),
  `modifie_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `modifie_par` CHAR(36),
  `supprime_le` DATETIME(6),
  `supprime_par` CHAR(36),
  constraint comptes_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `contrats` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `genre` VARCHAR(64) not null,
  `statut` VARCHAR(64) default 'draft' not null,
  `intitule_poste` TEXT not null,
  `description_poste` TEXT,
  `lieu_travail` TEXT,
  `categorie` TEXT,
  `date_debut` DATE not null,
  `date_fin` DATE,
  `motif_cdd` TEXT,
  `nombre_renouvellements` SMALLINT default 0 not null,
  `contrat_precedent_id` CHAR(36),
  `brut_mensuel` DECIMAL(10,2) not null,
  `indice_reference` DECIMAL(8,2),
  `heures_hebdomadaires` DECIMAL(5,2) default 40 not null,
  `jours_par_semaine` DECIMAL(3,1) default 5 not null,
  `repartition_travail` TEXT,
  `periode_reference_mois` SMALLINT default 4 not null,
  `travail_nuit` TINYINT(1) default 0 not null,
  `jours_conge_annuel` DECIMAL(5,2),
  `pause_minutes` SMALLINT,
  `clause_non_concurrence` TINYINT(1) default 0 not null,
  `clause_exclusivite` TINYINT(1) default 0 not null,
  `duree_essai` INT,
  `unite_essai` TEXT,
  `version` SMALLINT default 1 not null,
  `signe_le` DATE,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `est_temps_partiel` TINYINT(1) default 0 not null,
  `niveau_apprentissage` TEXT,
  `annee_apprentissage` SMALLINT,
  `libelle_saison` TEXT,
  `agence_interim_id` CHAR(36),
  `nom_societe_utilisateur` TEXT,
  `motif_mission` TEXT,
  constraint contrats_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `controles_adresse` (
  `id` CHAR(36) default (UUID()) not null,
  `entite_table` VARCHAR(255) not null,
  `entite_id` CHAR(36) not null,
  `societe_id` CHAR(36),
  `pays` CHAR(3),
  `code_postal` TEXT,
  `statut` TEXT not null,
  `code_zone` TEXT,
  `message` TEXT,
  `controle_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint controles_adresse_pkey primary key (`id`),
  constraint address_check_unique unique (`entite_table`, `entite_id`)
) engine=InnoDB default charset=utf8mb4;

create table `conventions_collectives` (
  `id` CHAR(36) default (UUID()) not null,
  `organisation_id` CHAR(36),
  `code` TEXT not null,
  `nom` TEXT not null,
  `secteur` TEXT not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `actif` TINYINT(1) default 0 not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `portee` VARCHAR(64) default 'secteur' not null,
  `remplace_id` CHAR(36),
  `categorie_professionnelle` TEXT,
  constraint conventions_collectives_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `conventions_de_la_societe` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `convention_id` CHAR(36) not null,
  `service_id` CHAR(36),
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint conventions_de_la_societe_pk primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `conventions_du_contrat` (
  `id` CHAR(36) default (UUID()) not null,
  `contrat_id` CHAR(36) not null,
  `convention_id` CHAR(36) not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint conventions_du_contrat_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `credits_impot` (
  `id` CHAR(36) default (UUID()) not null,
  `code` TEXT not null,
  `libelle` TEXT not null,
  `classes_visees` JSON,
  `revenu_min` DECIMAL(12,2),
  `revenu_max` DECIMAL(12,2),
  `montant_mensuel` DECIMAL(10,2),
  `proratise_sur_heures` TINYINT(1) default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `source` TEXT default 'ACD' not null,
  `reference_legale` TEXT,
  `note` TEXT,
  constraint credits_impot_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `creneau_condition` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `creneau_id` CHAR(36),
  `releve_temps_id` CHAR(36),
  `site_client_id` CHAR(36),
  `condition_code` TEXT not null,
  `date_prestation` DATE not null,
  `heure_debut` TIME not null,
  `heure_fin` TIME not null,
  `minutes` INT,
  `constate_par` CHAR(36),
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `supprime_le` DATETIME(6),
  `supprime_par` CHAR(36),
  constraint creneau_condition_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `creneaux` (
  `id` CHAR(36) default (UUID()) not null,
  `planning_id` CHAR(36) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `date_creneau` DATE not null,
  `heure_debut` TIME not null,
  `heure_fin` TIME not null,
  `pause_minutes` SMALLINT default 0 not null,
  `libelle` TEXT,
  `modele_id` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `site_client_id` CHAR(36),
  constraint creneaux_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `demandes_heures_sup` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `planning_id` CHAR(36),
  `debut_periode` DATE not null,
  `fin_periode` DATE not null,
  `heures` DECIMAL(6,2) not null,
  `motif` TEXT not null,
  `statut` TEXT default 'requested' not null,
  `demande_par` CHAR(36),
  `demande_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `valide_rh_par` CHAR(36),
  `valide_rh_le` DATETIME(6),
  `accepte_par_salarie_le` DATETIME(6),
  `motif_refus` TEXT,
  `compensation` TEXT default 'money' not null,
  `note` TEXT,
  constraint demandes_heures_sup_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `distances_trajet` (
  `id` CHAR(36) default (UUID()) not null,
  `reference_origine` VARCHAR(255) not null,
  `reference_destination` VARCHAR(255) not null,
  `distance_km` DECIMAL(8,2) not null,
  `duree_minutes` INT,
  `source` TEXT not null,
  `calcule_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `calcule_par` CHAR(36),
  `note` TEXT,
  constraint distances_trajet_pkey primary key (`id`),
  constraint travel_distance_unique unique (`reference_origine`, `reference_destination`)
) engine=InnoDB default charset=utf8mb4;

create table `documents` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36),
  `entite_table` TEXT,
  `entite_id` CHAR(36),
  `nom` TEXT not null,
  `chemin_stockage` TEXT not null,
  `type_mime` TEXT,
  `taille_octets` BIGINT,
  `conservation_jusquau` DATE,
  `sensible` TINYINT(1) default 0 not null,
  `depose_par` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `type_document_id` CHAR(36),
  `emis_le` DATE,
  `expire_le` DATE,
  `remis_le` DATE,
  constraint documents_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `donnees_financieres_societe` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `exercice` SMALLINT not null,
  `resultat` DECIMAL(14,2),
  `chiffre_affaires` DECIMAL(14,2),
  `source` TEXT,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint donnees_financieres_societe_ primary key (`id`),
  constraint donnees_financieres_societe_ unique (`societe_id`, `exercice`)
) engine=InnoDB default charset=utf8mb4;

create table `droits_absence` (
  `id` CHAR(36) default (UUID()) not null,
  `type_absence_id` CHAR(36) not null,
  `jours` DECIMAL(5,1),
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `reference_legale` TEXT,
  `note_frequence` TEXT,
  `plafond_carriere_jours` DECIMAL(6,1),
  `jours_bloc` DECIMAL(5,1),
  `duree_mois` INT,
  `degre_parente` SMALLINT,
  `piece_exigee` TINYINT(1) default 0 not null,
  `note` TEXT,
  constraint droits_absence_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `elements_remuneration` (
  `id` CHAR(36) default (UUID()) not null,
  `contrat_id` CHAR(36) not null,
  `societe_id` CHAR(36) not null,
  `genre` VARCHAR(64) not null,
  `code` TEXT not null,
  `libelle` TEXT not null,
  `montant` DECIMAL(10,2),
  `taux_pct` DECIMAL(6,3),
  `assiette` TEXT,
  `periodicite` TEXT default 'monthly' not null,
  `dans_assiette_salaire` TINYINT(1) default 0 not null,
  `imposable` TINYINT(1) default 1 not null,
  `cotisable` TINYINT(1) default 1 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `type_avantage_id` CHAR(36),
  constraint elements_remuneration_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `enfants_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `prenom` TEXT,
  `nom` TEXT,
  `sexe` VARCHAR(64),
  `date_naissance` DATE not null,
  `lien_parente` TEXT default 'child' not null,
  `a_charge` TINYINT(1) default 1 not null,
  `refus_partage` TINYINT(1) default 0 not null,
  `date_adoption` DATE,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `refus_photos_evenements` TINYINT(1) default 0 not null,
  `invitation_evenements` TINYINT(1) default 0 not null,
  `en_situation_handicap` TINYINT(1) default 0 not null,
  `taux_handicap_pct` DECIMAL(5,2),
  constraint enfants_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `fiche_sante` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36),
  `enfant_id` CHAR(36),
  `allergies` TEXT,
  `pathologies` TEXT,
  `medecin_traitant` TEXT,
  `medecin_telephone` TEXT,
  `groupe_sanguin` TEXT,
  `note` TEXT,
  `maj_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `maj_par` CHAR(36),
  `supprime_le` DATETIME(6),
  `supprime_par` CHAR(36),
  constraint fiche_sante_pkey primary key (`id`),
  constraint fs_une_par_personne unique (`salarie_id`, `enfant_id`)
) engine=InnoDB default charset=utf8mb4;

create table `fiches_retenue_impot` (
  `id` CHAR(36) default (UUID()) not null,
  `salarie_id` CHAR(36) not null,
  `societe_id` CHAR(36) not null,
  `classe_impot` VARCHAR(64) not null,
  `taux` DECIMAL(6,4),
  `indemnite_mensuelle` DECIMAL(10,2) default 0 not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `credits` JSON default '[]' not null,
  `distance_domicile_km` DECIMAL(6,1),
  `frais_professionnels_mensuels` DECIMAL(10,2),
  `autres_deductions_mensuelles` DECIMAL(10,2) default 0 not null,
  `reference_carte` TEXT,
  `emis_le` DATE,
  constraint fiches_retenue_impot_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `grilles_salaires_convention` (
  `id` CHAR(36) default (UUID()) not null,
  `convention_id` CHAR(36) not null,
  `categorie` TEXT not null,
  `anciennete_de_annees` DECIMAL(4,1) default 0 not null,
  `anciennete_a_annees` DECIMAL(4,1),
  `montant_mensuel` DECIMAL(10,2) not null,
  `indice_reference` DECIMAL(8,2),
  constraint grilles_salaires_convention_ primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `handicaps_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `taux_pct` DECIMAL(5,2) not null,
  `reconnu_le` DATE,
  `autorite` TEXT,
  `jours_conge_supplementaires_forces` DECIMAL(4,1),
  `piece_justificative_id` CHAR(36),
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint handicaps_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `journal_acces` (
  `id` BIGINT not null,
  `survenu_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `auteur_id` CHAR(36),
  `auteur_libelle` TEXT,
  `societe_id` CHAR(36),
  `salarie_concerne_id` CHAR(36),
  `entite_table` TEXT not null,
  `entite_id` CHAR(36),
  `action` TEXT not null,
  `portee` TEXT,
  `nombre_lignes` INT,
  `ip_source` TEXT,
  `agent_client` TEXT,
  `identifiant_requete` TEXT,
  `est_autonome` TINYINT(1) default 0 not null,
  constraint journal_acces_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `journal_ecritures` (
  `id` BIGINT not null,
  `survenu_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `auteur_id` CHAR(36),
  `auteur_libelle` TEXT,
  `societe_id` CHAR(36),
  `entite_table` TEXT not null,
  `entite_id` CHAR(36),
  `action` TEXT not null,
  `ancienne_valeur` JSON,
  `nouvelle_valeur` JSON,
  `ip_source` TEXT,
  `agent_client` TEXT,
  `identifiant_requete` TEXT,
  constraint journal_ecritures_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `journal_exports` (
  `id` CHAR(36) default (UUID()) not null,
  `organisation_id` CHAR(36) not null,
  `demande_par` CHAR(36),
  `genre_objet` TEXT not null,
  `objet_id` CHAR(36),
  `nombre_lignes` INT default 0 not null,
  `taille_octets` INT default 0 not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `ip_source` TEXT,
  `agent_client` TEXT,
  `identifiant_requete` TEXT,
  constraint journal_exports_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `jours_feries` (
  `id` CHAR(36) default (UUID()) not null,
  `annee` SMALLINT not null,
  `date_ferie` DATE not null,
  `nom` TEXT not null,
  `est_mobile` TINYINT(1) default 0 not null,
  `convention_id` CHAR(36),
  `recuperable` TINYINT(1) default 0 not null,
  `motif_recuperation` TEXT,
  constraint jours_feries_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `modeles_creneau` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `nom` TEXT not null,
  `heure_debut` TIME not null,
  `heure_fin` TIME not null,
  `pause_minutes` SMALLINT default 0 not null,
  `couleur` TEXT default '#017E84' not null,
  `service_id` CHAR(36),
  constraint modeles_creneau_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `organisations` (
  `id` CHAR(36) default (UUID()) not null,
  `nom` TEXT not null,
  `genre` VARCHAR(64) default 'fiduciary' not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint organisations_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `parametres_attendus` (
  `cle_parametre` VARCHAR(255) not null,
  `lu_par` TEXT not null,
  `note` TEXT,
  constraint parametres_attendus_pkey primary key (`cle_parametre`)
) engine=InnoDB default charset=utf8mb4;

create table `parametres_legaux` (
  `id` CHAR(36) default (UUID()) not null,
  `famille` VARCHAR(64) not null,
  `cle_parametre` TEXT not null,
  `libelle` TEXT not null,
  `valeur_num` DECIMAL(30,10),
  `valeur_texte` TEXT,
  `valeur_json` JSON,
  `unite` TEXT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `indice_reference` DECIMAL(8,2),
  `source` TEXT not null,
  `reference_legale` TEXT,
  `note` TEXT,
  `saisi_par` CHAR(36),
  `saisi_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `valide_par` CHAR(36),
  `valide_le` DATETIME(6),
  `derive_de_cle` TEXT,
  `facteur_derive` DECIMAL(30,10),
  `tolerance_derivation` DECIMAL(30,10) default 0.02 not null,
  constraint parametres_legaux_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `periodes_reference` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `service_id` CHAR(36),
  `libelle` TEXT not null,
  `date_debut` DATE not null,
  `date_fin` DATE not null,
  `mois` SMALLINT not null,
  constraint periodes_reference_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `periodes_taux_societe` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `classe_activite` TEXT,
  `classe_risque_accident` TEXT,
  `facteur_accident` DECIMAL(5,2) default 1.00 not null,
  `classe_mutualite` SMALLINT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `source` TEXT default 'CCSS' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint periodes_taux_societe_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `personne_indicateur_secours` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36),
  `enfant_id` CHAR(36),
  `indicateur` VARCHAR(255) not null,
  `precision_lieu` TEXT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `pose_par` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint personne_indicateur_secours_ primary key (`id`),
  constraint pis_unique unique (`salarie_id`, `enfant_id`, `indicateur`, `debut_validite`)
) engine=InnoDB default charset=utf8mb4;

create table `plannings` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `service_id` CHAR(36),
  `debut_semaine` DATE not null,
  `libelle` TEXT,
  `statut` VARCHAR(64) default 'draft' not null,
  `publie_le` DATETIME(6),
  `publie_par` CHAR(36),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint plannings_pkey primary key (`id`),
  constraint plannings_company_id_departm unique (`societe_id`, `service_id`, `debut_semaine`),
  constraint plannings_id_company_uk unique (`id`, `societe_id`)
) engine=InnoDB default charset=utf8mb4;

create table `primes` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `contrat_id` CHAR(36),
  `rupture_id` CHAR(36),
  `genre` TEXT default 'other' not null,
  `libelle` TEXT not null,
  `montant` DECIMAL(12,2) not null,
  `attribue_le` DATE not null,
  `exercice` SMALLINT not null,
  `imposable` TINYINT(1) default 1 not null,
  `cotisable` TINYINT(1) default 1 not null,
  `part_exoneree_pct` DECIMAL(6,3) default 0 not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint primes_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `profils` (
  `id` CHAR(36) not null,
  `organisation_id` CHAR(36) not null,
  `nom_complet` TEXT default '' not null,
  `courriel` TEXT default '' not null,
  `est_admin_organisation` TINYINT(1) default 0 not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint profils_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `prolongations_essai` (
  `id` CHAR(36) default (UUID()) not null,
  `contrat_id` CHAR(36) not null,
  `date_debut` DATE not null,
  `date_fin` DATE not null,
  `jours_ajoutes` INT not null,
  `motif` TEXT default 'incapacité de travail' not null,
  constraint prolongations_essai_pkey primary key (`id`)
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
  `url_source` TEXT,
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

create table `regles_convention` (
  `id` CHAR(36) default (UUID()) not null,
  `convention_id` CHAR(36) not null,
  `bloc` VARCHAR(64) not null,
  `regles` JSON default '{}' not null,
  `complet` TINYINT(1) default 0 not null,
  `modifie_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint regles_convention_pkey primary key (`id`),
  constraint regles_convention_collective unique (`convention_id`, `bloc`)
) engine=InnoDB default charset=utf8mb4;

create table `releves_effectif` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `mois` DATE not null,
  `effectif` DECIMAL(8,2) not null,
  constraint releves_effectif_pkey primary key (`id`),
  constraint releves_effectif_company_id_ unique (`societe_id`, `mois`)
) engine=InnoDB default charset=utf8mb4;

create table `releves_temps` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `date_releve` DATE not null,
  `heure_debut` TIME,
  `heure_fin` TIME,
  `pause_minutes` SMALLINT default 0 not null,
  `heures_travaillees` DECIMAL(5,2),
  `heures_prevues` DECIMAL(5,2),
  `heures_dimanche` DECIMAL(5,2) default 0 not null,
  `heures_ferie` DECIMAL(5,2) default 0 not null,
  `heures_nuit` DECIMAL(5,2) default 0 not null,
  `heures_supplementaires` DECIMAL(5,2) default 0 not null,
  `valide` TINYINT(1) default 0 not null,
  `source` TEXT default 'manual' not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint releves_temps_pkey primary key (`id`),
  constraint releves_temps_employee_id_en unique (`salarie_id`, `date_releve`)
) engine=InnoDB default charset=utf8mb4;

create table `roles_compte` (
  `id` CHAR(36) default (UUID()) not null,
  `compte_id` CHAR(36) not null,
  `organisation_id` CHAR(36) not null,
  `societe_id` CHAR(36),
  `role` VARCHAR(64) not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint roles_compte_pkey primary key (`id`),
  constraint roles_compte_user_id_company unique (`compte_id`, `societe_id`, `role`)
) engine=InnoDB default charset=utf8mb4;

create table `ruptures_contrat` (
  `id` CHAR(36) default (UUID()) not null,
  `contrat_id` CHAR(36) not null,
  `societe_id` CHAR(36) not null,
  `motif` TEXT not null,
  `motif_personnel` TINYINT(1) default 1 not null,
  `notifie_le` DATE not null,
  `debut_preavis` DATE,
  `fin_preavis` DATE,
  `indemnite_mois` DECIMAL(4,1),
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `preavis_renonce` TINYINT(1) default 0 not null,
  `renonciation_convenue_le` DATE,
  `compensation_renonciation` DECIMAL(12,2),
  `note_renonciation` TEXT,
  `faute_grave` TINYINT(1) default 0 not null,
  constraint ruptures_contrat_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `salaries` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `compte_id` CHAR(36),
  `service_id` CHAR(36),
  `prenom` TEXT not null,
  `nom` TEXT not null,
  `date_naissance` DATE,
  `residence` VARCHAR(64) not null,
  `qualification` VARCHAR(64) default 'unqualified' not null,
  `ligne` TEXT,
  `code_postal` TEXT,
  `localite` TEXT,
  `pays` TEXT default 'LU' not null,
  `courriel` TEXT,
  `telephone` TEXT,
  `matricule_national_chiffre` LONGBLOB,
  `iban_chiffre` LONGBLOB,
  `matricule_national_indice` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `sexe` VARCHAR(64) default 'unspecified' not null,
  `date_debut_carriere` DATE,
  `profession` TEXT,
  `est_cadre` TINYINT(1) default 0 not null,
  `sexe_legal` VARCHAR(64),
  `refus_photos_societe` TINYINT(1) default 0 not null,
  `souhaite_confidentialite` TINYINT(1) default 0 not null,
  constraint salaries_pkey primary key (`id`),
  constraint salaries_id_company_uk unique (`id`, `societe_id`)
) engine=InnoDB default charset=utf8mb4;

create table `sanctions_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `contrat_id` CHAR(36),
  `type_sanction` TEXT not null,
  `faits_le` DATE not null,
  `faits_connus_le` DATE not null,
  `notifie_le` DATE,
  `effet_du` DATE,
  `effet_au` DATE,
  `motif` TEXT not null,
  `piece_justificative_id` CHAR(36),
  `rupture_id` CHAR(36),
  `contrat_avenant_id` CHAR(36),
  `salarie_entendu_le` DATE,
  `reponse_salarie` TEXT,
  `conteste_le` DATE,
  `issue_contestation` TEXT,
  `note` TEXT,
  `conservation_jusquau` DATE,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `cree_par` CHAR(36),
  `modifie_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `modifie_par` CHAR(36),
  `supprime_le` DATETIME(6),
  `supprime_par` CHAR(36),
  constraint sanctions_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `secrets_application` (
  `cle` VARCHAR(255) not null,
  `secret` TEXT not null,
  constraint secrets_application_pkey primary key (`cle`)
) engine=InnoDB default charset=utf8mb4;

create table `services` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `nom` TEXT not null,
  `couverture_soir_min` SMALLINT,
  constraint services_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `sinistres_accident_societe` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `annee` SMALLINT not null,
  `nombre_sinistres` INT default 0 not null,
  `jours_perdus` INT default 0 not null,
  `cout` DECIMAL(12,2),
  `note` TEXT,
  constraint sinistres_accident_societe_p primary key (`id`),
  constraint sinistres_accident_societe_c unique (`societe_id`, `annee`)
) engine=InnoDB default charset=utf8mb4;

create table `sites_client` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `nom` TEXT not null,
  `nom_client` TEXT,
  `ligne` TEXT,
  `code_postal` TEXT,
  `localite` TEXT,
  `pays` TEXT default 'LU' not null,
  `latitude` DECIMAL(9,6),
  `longitude` DECIMAL(9,6),
  `actif` TINYINT(1) default 1 not null,
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint sites_client_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `societes` (
  `id` CHAR(36) default (UUID()) not null,
  `organisation_id` CHAR(36) not null,
  `raison_sociale` TEXT not null,
  `forme_juridique` TEXT,
  `numero_rcs` TEXT,
  `matricule_ccss` TEXT,
  `ligne` TEXT,
  `code_postal` TEXT,
  `localite` TEXT,
  `pays` TEXT default 'LU' not null,
  `code_nace` TEXT,
  `secteur` TEXT,
  `periode_reference_mois` SMALLINT default 4 not null,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  `reglement_interieur_adopte_le` DATE,
  `reference_reglement_interieur` TEXT,
  constraint societes_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `statuts_salarie` (
  `id` CHAR(36) default (UUID()) not null,
  `societe_id` CHAR(36) not null,
  `salarie_id` CHAR(36) not null,
  `genre` VARCHAR(64) not null,
  `declare_le` DATE default CURRENT_DATE not null,
  `date_debut` DATE not null,
  `date_fin` DATE,
  `date_naissance_prevue` DATE,
  `date_naissance_reelle` DATE,
  `piece_justificative_id` CHAR(36),
  `credit_heures_mensuel` DECIMAL(5,1),
  `note` TEXT,
  `cree_le` DATETIME(6) default CURRENT_TIMESTAMP(6) not null,
  constraint statuts_salarie_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `tranches_impot` (
  `id` CHAR(36) default (UUID()) not null,
  `classe_impot` VARCHAR(64) not null,
  `periodicite` VARCHAR(64) default 'monthly' not null,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  `tranche_min` DECIMAL(12,2) not null,
  `tranche_max` DECIMAL(12,2),
  `impot_base` DECIMAL(12,2) default 0 not null,
  `taux_au_dessus_minimum` DECIMAL(7,4) not null,
  `source` TEXT default 'ACD' not null,
  `reference_legale` TEXT,
  `note` TEXT,
  constraint tranches_impot_pkey primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

create table `types_absence` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `categorie` VARCHAR(64) not null,
  `reference_legale` TEXT,
  `certificat_exige` TINYINT(1) default 0 not null,
  `remunere` TINYINT(1) default 1 not null,
  `impute_sur_conge` TINYINT(1) default 0 not null,
  constraint types_absence_pkey primary key (`id`),
  constraint types_absence_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `types_avantage` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `methode_evaluation` TEXT not null,
  `imposable` TINYINT(1) default 1 not null,
  `cotisable` TINYINT(1) default 1 not null,
  `parametres_evaluation` JSON default '{}' not null,
  `reference_legale` TEXT,
  `note` TEXT,
  constraint types_avantage_pkey primary key (`id`),
  constraint types_avantage_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `types_document` (
  `id` CHAR(36) default (UUID()) not null,
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `echelon` VARCHAR(64) default 'during_contract' not null,
  `validite_mois` INT,
  `obligatoire` TINYINT(1) default 0 not null,
  `residences_visees` JSON,
  `alerte_jours_avant` INT default 30 not null,
  `reference_legale` TEXT,
  `note` TEXT,
  constraint types_document_pkey primary key (`id`),
  constraint types_document_code_key unique (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `types_sanction` (
  `code` VARCHAR(255) not null,
  `code_categorie` TEXT not null,
  `libelle` TEXT not null,
  `description` TEXT not null,
  `suspend_presence` TINYINT(1) default 0 not null,
  `affecte_paie` TINYINT(1) default 0 not null,
  `reglement_interieur_exige` TINYINT(1) default 0 not null,
  `modifie_contrat` TINYINT(1) default 0 not null,
  `rompt_contrat` TINYINT(1) default 0 not null,
  `needs_notice` TINYINT(1),
  `reference_legale` TEXT,
  `note` TEXT,
  `debut_validite` DATE default '1970-01-01' not null,
  `fin_validite` DATE default '2037-12-31' not null,
  constraint types_sanction_pkey primary key (`code`)
) engine=InnoDB default charset=utf8mb4;

create table `zones_adresse` (
  `id` CHAR(36) default (UUID()) not null,
  `pays` CHAR(3) not null,
  `genre` TEXT not null,
  `code` VARCHAR(255) not null,
  `libelle` TEXT not null,
  `code_postal_du` INT,
  `code_postal_au` INT,
  `verifie` TINYINT(1) default 0 not null,
  `source` TEXT not null,
  `note` TEXT,
  constraint zones_adresse_pkey primary key (`id`),
  constraint address_zone_unique unique (`pays`, `code`)
) engine=InnoDB default charset=utf8mb4;

-- Clés étrangères, posées après toutes les tables.
alter table `absences` add constraint absences_statut_ref foreign key (`statut`) references `ref_statut_absence` (`code`);
alter table `alertes_conformite` add constraint alertes_conformite_severite_ foreign key (`severite`) references `ref_genre_severite` (`code`);
alter table `alertes_conformite` add constraint alertes_conformite_etat_ref foreign key (`etat`) references `ref_etat_alerte` (`code`);
alter table `contrats` add constraint contrats_genre_ref foreign key (`genre`) references `ref_genre_contrat` (`code`);
alter table `contrats` add constraint contrats_statut_ref foreign key (`statut`) references `ref_statut_contrat` (`code`);
alter table `conventions_collectives` add constraint conventions_collec_portee_re foreign key (`portee`) references `ref_portee_convention` (`code`);
alter table `elements_remuneration` add constraint elements_remunerat_genre_ref foreign key (`genre`) references `ref_genre_element_remuneration` (`code`);
alter table `enfants_salarie` add constraint enfants_salarie_sexe_ref foreign key (`sexe`) references `ref_genre_sexe` (`code`);
alter table `fiches_retenue_impot` add constraint fiches_retenue_imp_classe_im foreign key (`classe_impot`) references `ref_classe_impot` (`code`);
alter table `organisations` add constraint organisations_genre_ref foreign key (`genre`) references `ref_genre_organisation` (`code`);
alter table `parametres_legaux` add constraint parametres_legaux_famille_re foreign key (`famille`) references `ref_famille_parametre` (`code`);
alter table `plannings` add constraint plannings_statut_ref foreign key (`statut`) references `ref_statut_planning` (`code`);
alter table `regles_convention` add constraint regles_convention_bloc_ref foreign key (`bloc`) references `ref_bloc_convention` (`code`);
alter table `roles_compte` add constraint roles_compte_role_ref foreign key (`role`) references `ref_role_application` (`code`);
alter table `salaries` add constraint salaries_residence_ref foreign key (`residence`) references `ref_genre_residence` (`code`);
alter table `salaries` add constraint salaries_qualification_ref foreign key (`qualification`) references `ref_genre_qualification` (`code`);
alter table `salaries` add constraint salaries_sexe_ref foreign key (`sexe`) references `ref_genre_sexe` (`code`);
alter table `salaries` add constraint salaries_sexe_legal_ref foreign key (`sexe_legal`) references `ref_genre_sexe` (`code`);
alter table `statuts_salarie` add constraint statuts_salarie_genre_ref foreign key (`genre`) references `ref_genre_statut_salarie` (`code`);
alter table `tranches_impot` add constraint tranches_impot_classe_impot_ foreign key (`classe_impot`) references `ref_classe_impot` (`code`);
alter table `tranches_impot` add constraint tranches_impot_periodicite_r foreign key (`periodicite`) references `ref_periodicite_impot` (`code`);
alter table `types_absence` add constraint types_absence_categorie_ref foreign key (`categorie`) references `ref_categorie_absence` (`code`);
alter table `types_document` add constraint types_document_echelon_ref foreign key (`echelon`) references `ref_etape_document` (`code`);

alter table `absences` add constraint absence_belongs_to_employees foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `absences` add constraint absences_absence_parente_id_ foreign key (`absence_parente_id`) references `absences` (`id`) on delete set null;
alter table `absences` add constraint absences_absence_type_id_fke foreign key (`type_absence_id`) references `types_absence` (`id`);
alter table `absences` add constraint absences_child_id_fkey foreign key (`enfant_id`) references `enfants_salarie` (`id`) on delete set null;
alter table `absences` add constraint absences_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `absences` add constraint absences_decided_by_fkey foreign key (`decide_par`) references `app_users` (`id`);
alter table `absences` add constraint absences_requested_by_fkey foreign key (`demande_par`) references `app_users` (`id`);
alter table `adresses_salarie` add constraint adr_appartient_au_salarie foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `adresses_salarie` add constraint adresses_salarie_type_adress foreign key (`type_adresse`) references `ref_type_adresse` (`code`);
alter table `agences_interim` add constraint agences_interim_organization foreign key (`organisation_id`) references `organisations` (`id`) on delete cascade;
alter table `alertes_conformite` add constraint alertes_conformite_company_i foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `alertes_conformite` add constraint alertes_conformite_employee_ foreign key (`salarie_id`) references `salaries` (`id`) on delete set null;
alter table `alertes_conformite` add constraint alertes_conformite_handled_b foreign key (`traite_par`) references `app_users` (`id`);
alter table `attributions_titres_repas` add constraint attributions_titres_repas_co foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `attributions_titres_repas` add constraint voucher_belongs_to_employees foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `avenants_contrat` add constraint avenants_contrat_company_id_ foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `avenants_contrat` add constraint avenants_contrat_contract_id foreign key (`contrat_id`) references `contrats` (`id`) on delete cascade;
alter table `avenants_contrat` add constraint avenants_contrat_created_by_ foreign key (`cree_par`) references `app_users` (`id`);
alter table `cct_regle_prime` add constraint cct_regle_prime_collective_a foreign key (`convention_id`) references `conventions_collectives` (`id`) on delete cascade;
alter table `cct_regle_prime` add constraint cct_regle_prime_condition_co foreign key (`condition_code`) references `ref_condition_travail` (`code`);
alter table `cct_regle_prime` add constraint cct_regle_prime_nature_prime foreign key (`nature_prime`) references `ref_nature_prime` (`code`);
alter table `cct_regle_prime` add constraint cct_regle_prime_unite_ref foreign key (`unite`) references `ref_unite_prime` (`code`);
alter table `contrats` add constraint contract_belongs_to_employee foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `contrats` add constraint contrats_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `contrats` add constraint contrats_interim_agency_fk foreign key (`agence_interim_id`) references `agences_interim` (`id`) on delete set null;
alter table `contrats` add constraint contrats_previous_contract_i foreign key (`contrat_precedent_id`) references `contrats` (`id`) on delete set null;
alter table `contrats` add constraint contrats_unite_essai_ref foreign key (`unite_essai`) references `ref_unite_essai` (`code`);
alter table `controles_adresse` add constraint controles_adresse_statut_ref foreign key (`statut`) references `ref_statut_verification_adresse` (`code`);
alter table `conventions_collectives` add constraint conventions_collectives_orga foreign key (`organisation_id`) references `organisations` (`id`) on delete cascade;
alter table `conventions_collectives` add constraint conventions_collectives_supe foreign key (`remplace_id`) references `conventions_collectives` (`id`) on delete set null;
alter table `conventions_de_la_societe` add constraint conventions_de_la_societe_co foreign key (`convention_id`) references `conventions_collectives` (`id`);
alter table `conventions_de_la_societe` add constraint conventions_de_la_societe_co foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `conventions_de_la_societe` add constraint conventions_de_la_societe_de foreign key (`service_id`) references `services` (`id`) on delete cascade;
alter table `conventions_du_contrat` add constraint conventions_du_contrat_colle foreign key (`convention_id`) references `conventions_collectives` (`id`);
alter table `conventions_du_contrat` add constraint conventions_du_contrat_contr foreign key (`contrat_id`) references `contrats` (`id`) on delete cascade;
alter table `creneau_condition` add constraint cc_appartient_au_salarie foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `creneau_condition` add constraint cc_site_appartient_a_la_soci foreign key (`site_client_id`, `societe_id`) references `sites_client` (`id`, `societe_id`) on delete set null;
alter table `creneau_condition` add constraint creneau_condition_condition_ foreign key (`condition_code`) references `ref_condition_travail` (`code`);
alter table `creneau_condition` add constraint creneau_condition_shift_id_f foreign key (`creneau_id`) references `creneaux` (`id`) on delete cascade;
alter table `creneau_condition` add constraint creneau_condition_time_entry foreign key (`releve_temps_id`) references `releves_temps` (`id`) on delete cascade;
alter table `creneaux` add constraint creneaux_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `creneaux` add constraint creneaux_template_id_fkey foreign key (`modele_id`) references `modeles_creneau` (`id`) on delete set null;
alter table `creneaux` add constraint shift_belongs_to_employees_c foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `creneaux` add constraint shift_belongs_to_schedules_c foreign key (`planning_id`, `societe_id`) references `plannings` (`id`, `societe_id`) on delete cascade;
alter table `creneaux` add constraint shift_site_belongs_to_compan foreign key (`site_client_id`, `societe_id`) references `sites_client` (`id`, `societe_id`) on delete set null;
alter table `demandes_heures_sup` add constraint demandes_heures_sup_company_ foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `demandes_heures_sup` add constraint demandes_heures_sup_compensa foreign key (`compensation`) references `ref_compensation_heures_sup` (`code`);
alter table `demandes_heures_sup` add constraint demandes_heures_sup_hr_valid foreign key (`valide_rh_par`) references `app_users` (`id`);
alter table `demandes_heures_sup` add constraint demandes_heures_sup_requeste foreign key (`demande_par`) references `app_users` (`id`);
alter table `demandes_heures_sup` add constraint demandes_heures_sup_schedule foreign key (`planning_id`) references `plannings` (`id`) on delete set null;
alter table `demandes_heures_sup` add constraint demandes_heures_sup_statut_r foreign key (`statut`) references `ref_statut_heures_sup` (`code`);
alter table `demandes_heures_sup` add constraint overtime_belongs_to_employee foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `documents` add constraint documents_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `documents` add constraint documents_document_type_id_f foreign key (`type_document_id`) references `types_document` (`id`) on delete set null;
alter table `documents` add constraint documents_employee_id_fkey foreign key (`salarie_id`) references `salaries` (`id`) on delete cascade;
alter table `documents` add constraint documents_uploaded_by_fkey foreign key (`depose_par`) references `app_users` (`id`);
alter table `donnees_financieres_societe` add constraint donnees_financieres_societe_ foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `droits_absence` add constraint droits_absence_absence_type_ foreign key (`type_absence_id`) references `types_absence` (`id`) on delete cascade;
alter table `elements_remuneration` add constraint elements_remuneration_benefi foreign key (`type_avantage_id`) references `types_avantage` (`id`) on delete set null;
alter table `elements_remuneration` add constraint elements_remuneration_compan foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `elements_remuneration` add constraint elements_remuneration_contra foreign key (`contrat_id`) references `contrats` (`id`) on delete cascade;
alter table `enfants_salarie` add constraint child_belongs_to_employees_c foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `enfants_salarie` add constraint enfants_salarie_company_id_f foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `enfants_salarie` add constraint enfants_salarie_lien_ref foreign key (`lien_parente`) references `ref_lien_enfant` (`code`);
alter table `fiche_sante` add constraint fiche_sante_enfant_id_fkey foreign key (`enfant_id`) references `enfants_salarie` (`id`) on delete cascade;
alter table `fiches_retenue_impot` add constraint fiches_retenue_impot_company foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `fiches_retenue_impot` add constraint fiches_retenue_impot_employe foreign key (`salarie_id`) references `salaries` (`id`) on delete cascade;
alter table `grilles_salaires_convention` add constraint grilles_salaires_convention_ foreign key (`convention_id`) references `conventions_collectives` (`id`) on delete cascade;
alter table `handicaps_salarie` add constraint disability_belongs_to_employ foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `handicaps_salarie` add constraint handicaps_salarie_company_id foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `handicaps_salarie` add constraint handicaps_salarie_evidence_d foreign key (`piece_justificative_id`) references `documents` (`id`) on delete set null;
alter table `journal_acces` add constraint journal_acces_action_ref foreign key (`action`) references `ref_action_acces` (`code`);
alter table `journal_exports` add constraint journal_exports_organization foreign key (`organisation_id`) references `organisations` (`id`) on delete cascade;
alter table `journal_exports` add constraint journal_exports_requested_by foreign key (`demande_par`) references `app_users` (`id`);
alter table `journal_exports` add constraint journal_exports_sujet_ref foreign key (`genre_objet`) references `ref_sujet_export` (`code`);
alter table `modeles_creneau` add constraint modeles_creneau_company_id_f foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `modeles_creneau` add constraint modeles_creneau_department_i foreign key (`service_id`) references `services` (`id`) on delete set null;
alter table `parametres_legaux` add constraint parametres_legaux_entered_by foreign key (`saisi_par`) references `app_users` (`id`);
alter table `parametres_legaux` add constraint parametres_legaux_validated_ foreign key (`valide_par`) references `app_users` (`id`);
alter table `periodes_reference` add constraint periodes_reference_company_i foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `periodes_reference` add constraint periodes_reference_departmen foreign key (`service_id`) references `services` (`id`) on delete set null;
alter table `periodes_taux_societe` add constraint periodes_taux_societe_compan foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `personne_indicateur_secours` add constraint personne_indicateur_secours_ foreign key (`enfant_id`) references `enfants_salarie` (`id`) on delete cascade;
alter table `personne_indicateur_secours` add constraint personne_indicateur_secours_ foreign key (`indicateur`) references `ref_indicateur_secours` (`code`);
alter table `plannings` add constraint plannings_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `plannings` add constraint plannings_department_id_fkey foreign key (`service_id`) references `services` (`id`) on delete set null;
alter table `plannings` add constraint plannings_published_by_fkey foreign key (`publie_par`) references `app_users` (`id`);
alter table `primes` add constraint premium_belongs_to_employees foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `primes` add constraint primes_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `primes` add constraint primes_contract_id_fkey foreign key (`contrat_id`) references `contrats` (`id`) on delete set null;
alter table `primes` add constraint primes_nature_ref foreign key (`genre`) references `ref_nature_prime` (`code`);
alter table `primes` add constraint primes_termination_id_fkey foreign key (`rupture_id`) references `ruptures_contrat` (`id`) on delete set null;
alter table `profils` add constraint profils_id_fkey foreign key (`id`) references `app_users` (`id`) on delete cascade;
alter table `profils` add constraint profils_organization_id_fkey foreign key (`organisation_id`) references `organisations` (`id`);
alter table `prolongations_essai` add constraint prolongations_essai_contract foreign key (`contrat_id`) references `contrats` (`id`) on delete cascade;
alter table `regles_convention` add constraint regles_convention_collective foreign key (`convention_id`) references `conventions_collectives` (`id`) on delete cascade;
alter table `releves_effectif` add constraint releves_effectif_company_id_ foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `releves_temps` add constraint releves_temps_company_id_fke foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `releves_temps` add constraint time_entry_belongs_to_employ foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `roles_compte` add constraint roles_compte_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `roles_compte` add constraint roles_compte_organization_id foreign key (`organisation_id`) references `organisations` (`id`) on delete cascade;
alter table `roles_compte` add constraint roles_compte_user_id_fkey foreign key (`compte_id`) references `app_users` (`id`) on delete cascade;
alter table `ruptures_contrat` add constraint ruptures_contrat_company_id_ foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `ruptures_contrat` add constraint ruptures_contrat_contract_id foreign key (`contrat_id`) references `contrats` (`id`) on delete cascade;
alter table `salaries` add constraint salaries_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `salaries` add constraint salaries_department_id_fkey foreign key (`service_id`) references `services` (`id`) on delete set null;
alter table `salaries` add constraint salaries_user_id_fkey foreign key (`compte_id`) references `app_users` (`id`) on delete set null;
alter table `sanctions_salarie` add constraint sanction_belongs_to_employee foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `sanctions_salarie` add constraint sanctions_salarie_amendment_ foreign key (`contrat_avenant_id`) references `contrats` (`id`) on delete set null;
alter table `sanctions_salarie` add constraint sanctions_salarie_contract_i foreign key (`contrat_id`) references `contrats` (`id`) on delete set null;
alter table `sanctions_salarie` add constraint sanctions_salarie_evidence_d foreign key (`piece_justificative_id`) references `documents` (`id`) on delete set null;
alter table `sanctions_salarie` add constraint sanctions_salarie_sanction_t foreign key (`type_sanction`) references `types_sanction` (`code`);
alter table `sanctions_salarie` add constraint sanctions_salarie_terminatio foreign key (`rupture_id`) references `ruptures_contrat` (`id`) on delete set null;
alter table `services` add constraint services_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `sinistres_accident_societe` add constraint sinistres_accident_societe_c foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `sites_client` add constraint sites_client_company_id_fkey foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `societes` add constraint societes_organization_id_fke foreign key (`organisation_id`) references `organisations` (`id`) on delete cascade;
alter table `statuts_salarie` add constraint status_belongs_to_employees_ foreign key (`salarie_id`, `societe_id`) references `salaries` (`id`, `societe_id`) on delete cascade;
alter table `statuts_salarie` add constraint statuts_salarie_company_id_f foreign key (`societe_id`) references `societes` (`id`) on delete cascade;
alter table `statuts_salarie` add constraint statuts_salarie_evidence_doc foreign key (`piece_justificative_id`) references `documents` (`id`) on delete set null;
alter table `types_sanction` add constraint types_sanction_category_code foreign key (`code_categorie`) references `categories_sanction` (`code`);

-- Contraintes de validation.
alter table `absences` add constraint absence_days_positive CHECK ((nombre_jours >= (0)::numeric));
alter table `absences` add constraint absence_pas_sa_propre_parent CHECK (((absence_parente_id IS NULL) OR (absence_parente_id <> id)));
alter table `absences` add constraint absence_range CHECK ((date_fin >= date_debut));
alter table `adresses_salarie` add constraint adr_a_une_adresse CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table `adresses_salarie` add constraint adr_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table `adresses_salarie` add constraint adr_periode CHECK ((fin_validite > debut_validite));
alter table `attributions_titres_repas` add constraint attributions_titres_repas_vo CHECK ((nombre_titres >= 0));
alter table `attributions_titres_repas` add constraint voucher_period CHECK ((fin_periode >= debut_periode));
alter table `attributions_titres_repas` add constraint voucher_share_within_face_va CHECK (((valeur_faciale > (0)::numeric) AND (part_salariale >= (0)::numeric) AND (part_salariale <= valeur_faciale)));
alter table `categories_sanction` add constraint categories_sanction_periode_ CHECK ((fin_validite > debut_validite));
alter table `categories_sanction` add constraint sanction_category_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `cct_regle_prime` add constraint crp_periode CHECK ((fin_validite > debut_validite));
alter table `cct_regle_prime` add constraint crp_seuil_positif CHECK ((seuil_minutes >= 0));
alter table `cct_regle_prime` add constraint crp_source_non_vide CHECK ((btrim(url_source) <> ''::text));
alter table `cct_regle_prime` add constraint crp_taux_exige_assiette CHECK (((taux_pct IS NULL) OR (assiette IS NOT NULL)));
alter table `cct_regle_prime` add constraint crp_taux_ou_montant CHECK ((num_nonnulls(taux_pct, montant) = 1));
alter table `comptes` add constraint app_user_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table `comptes` add constraint app_user_email_shape CHECK ((courriel ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text));
alter table `comptes` add constraint app_user_userid_shape CHECK ((identifiant ~ '^[a-z0-9._-]{3,64}$'::text));
alter table `contrats` add constraint cdd_needs_reason CHECK (((genre <> 'cdd'::genre_contrat) OR (motif_cdd IS NOT NULL)));
alter table `contrats` add constraint contract_dates_order CHECK (((date_fin IS NULL) OR (date_fin >= date_debut)));
alter table `contrats` add constraint contract_not_its_own_predece CHECK (((contrat_precedent_id IS NULL) OR (contrat_precedent_id <> id)));
alter table `contrats` add constraint contract_quantities_positive CHECK (((heures_hebdomadaires > (0)::numeric) AND (jours_par_semaine > (0)::numeric) AND (jours_par_semaine <= (7)::numeric) AND (brut_mensuel >= (0)::numeric) AND (nombre_renouvellements >= 0) AND ((pause_minutes IS NULL) OR (pause_minutes >= 0)) AND ((jours_conge_annuel IS NULL) OR (jours_conge_annuel >= (0)::numeric)) AND ((duree_essai IS NULL) OR (duree_essai > 0)) AND ((annee_apprentissage IS NULL) OR (annee_apprentissage > 0))));
alter table `contrats` add constraint fixed_term_needs_end CHECK (((genre <> ALL (ARRAY['cdd'::genre_contrat, 'seasonal'::genre_contrat, 'interim'::genre_contrat, 'apprenticeship'::genre_contrat])) OR (date_fin IS NOT NULL)));
alter table `contrats` add constraint interim_needs_user_company CHECK (((genre <> 'interim'::genre_contrat) OR (nom_societe_utilisateur IS NOT NULL)));
alter table `contrats` add constraint probation_length_and_unit_to CHECK (((duree_essai IS NULL) = (unite_essai IS NULL)));
alter table `conventions_collectives` add constraint conventions_collectives_peri CHECK ((fin_validite > debut_validite));
alter table `conventions_de_la_societe` add constraint company_cba_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `conventions_de_la_societe` add constraint conventions_de_la_societe_pe CHECK ((fin_validite > debut_validite));
alter table `conventions_du_contrat` add constraint contract_cba_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `conventions_du_contrat` add constraint conventions_du_contrat_perio CHECK ((fin_validite > debut_validite));
alter table `credits_impot` add constraint credit_income_order CHECK (((revenu_max IS NULL) OR (revenu_min IS NULL) OR (revenu_max > revenu_min)));
alter table `credits_impot` add constraint credit_validity CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `credits_impot` add constraint credits_impot_periode_valide CHECK ((fin_validite > debut_validite));
alter table `creneau_condition` add constraint cc_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table `creneau_condition` add constraint cc_heures_differentes CHECK ((heure_debut <> heure_fin));
alter table `creneau_condition` add constraint cc_rattachement CHECK (((creneau_id IS NOT NULL) OR (releve_temps_id IS NOT NULL)));
alter table `creneaux` add constraint shift_break_positive CHECK ((pause_minutes >= 0));
alter table `creneaux` add constraint shift_times_differ CHECK ((heure_debut <> heure_fin));
alter table `demandes_heures_sup` add constraint demandes_heures_sup_hours_ch CHECK ((heures > (0)::numeric));
alter table `demandes_heures_sup` add constraint overtime_acceptance_follows_ CHECK (((accepte_par_salarie_le IS NULL) OR (valide_rh_le IS NOT NULL)));
alter table `demandes_heures_sup` add constraint overtime_approved_needs_both CHECK (((statut <> 'approved'::text) OR ((valide_rh_le IS NOT NULL) AND (accepte_par_salarie_le IS NOT NULL))));
alter table `demandes_heures_sup` add constraint overtime_period CHECK ((fin_periode >= debut_periode));
alter table `distances_trajet` add constraint travel_distance_positive CHECK ((distance_km >= (0)::numeric));
alter table `distances_trajet` add constraint travel_distance_refs_differ CHECK ((reference_origine <> reference_destination));
alter table `documents` add constraint document_expiry_after_issue CHECK (((expire_le IS NULL) OR (emis_le IS NULL) OR (expire_le >= emis_le)));
alter table `documents` add constraint document_size_positive CHECK (((taille_octets IS NULL) OR (taille_octets >= 0)));
alter table `droits_absence` add constraint droits_absence_periode_valid CHECK ((fin_validite > debut_validite));
alter table `droits_absence` add constraint entitlement_days_positive CHECK (((jours IS NULL) OR (jours >= (0)::numeric)));
alter table `droits_absence` add constraint entitlement_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `elements_remuneration` add constraint elements_remuneration_period CHECK ((fin_validite > debut_validite));
alter table `elements_remuneration` add constraint pay_component_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `enfants_salarie` add constraint ec_taux_exige_handicap CHECK (((taux_handicap_pct IS NULL) OR en_situation_handicap));
alter table `enfants_salarie` add constraint ec_taux_handicap CHECK (((taux_handicap_pct IS NULL) OR ((taux_handicap_pct > (0)::numeric) AND (taux_handicap_pct <= (100)::numeric))));
alter table `enfants_salarie` add constraint privacy_minimises_data CHECK (((NOT refus_partage) OR ((prenom IS NULL) AND (nom IS NULL) AND (sexe IS NULL) AND (note IS NULL))));
alter table `fiche_sante` add constraint fs_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table `fiche_sante` add constraint fs_personne CHECK ((num_nonnulls(salarie_id, enfant_id) = 1));
alter table `fiches_retenue_impot` add constraint fiches_retenue_impot_periode CHECK ((fin_validite > debut_validite));
alter table `fiches_retenue_impot` add constraint tax_card_amounts_positive CHECK (((indemnite_mensuelle >= (0)::numeric) AND ((frais_professionnels_mensuels IS NULL) OR (frais_professionnels_mensuels >= (0)::numeric)) AND (autres_deductions_mensuelles >= (0)::numeric) AND ((distance_domicile_km IS NULL) OR (distance_domicile_km >= (0)::numeric))));
alter table `fiches_retenue_impot` add constraint tax_card_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `grilles_salaires_convention` add constraint grid_amount_positive CHECK ((montant_mensuel > (0)::numeric));
alter table `grilles_salaires_convention` add constraint grid_seniority_order CHECK (((anciennete_a_annees IS NULL) OR (anciennete_a_annees > anciennete_de_annees)));
alter table `handicaps_salarie` add constraint disability_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `handicaps_salarie` add constraint handicaps_salarie_periode_va CHECK ((fin_validite > debut_validite));
alter table `handicaps_salarie` add constraint handicaps_salarie_rate_pct_c CHECK (((taux_pct > (0)::numeric) AND (taux_pct <= (100)::numeric)));
alter table `jours_feries` add constraint holiday_year_matches_date CHECK (((EXTRACT(year FROM date_ferie))::integer = annee));
alter table `modeles_creneau` add constraint template_break_positive CHECK ((pause_minutes >= 0));
alter table `parametres_legaux` add constraint one_value CHECK (((num_nonnulls(valeur_num, valeur_texte, valeur_json) = 1) OR ((derive_de_cle IS NOT NULL) AND (num_nonnulls(valeur_num, valeur_texte, valeur_json) = 0))));
alter table `parametres_legaux` add constraint parametres_legaux_periode_va CHECK ((fin_validite > debut_validite));
alter table `parametres_legaux` add constraint valid_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `periodes_reference` add constraint periodes_reference_months_po CHECK ((mois >= 1));
alter table `periodes_reference` add constraint prl_range CHECK ((date_fin > date_debut));
alter table `periodes_taux_societe` add constraint periodes_taux_societe_mutual CHECK ((classe_mutualite >= 1));
alter table `periodes_taux_societe` add constraint periodes_taux_societe_period CHECK ((fin_validite > debut_validite));
alter table `periodes_taux_societe` add constraint rate_period_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `personne_indicateur_secours` add constraint pis_periode CHECK ((fin_validite > debut_validite));
alter table `personne_indicateur_secours` add constraint pis_personne CHECK ((num_nonnulls(salarie_id, enfant_id) = 1));
alter table `plannings` add constraint published_iff_timestamp CHECK (((statut = 'publie'::statut_planning) = (publie_le IS NOT NULL)));
alter table `primes` add constraint premium_exempt_is_a_percenta CHECK (((part_exoneree_pct >= (0)::numeric) AND (part_exoneree_pct <= (100)::numeric)));
alter table `primes` add constraint primes_amount_check CHECK ((montant >= (0)::numeric));
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
alter table `releves_effectif` add constraint headcount_month_is_first_day CHECK (((EXTRACT(day FROM mois))::integer = 1));
alter table `releves_effectif` add constraint headcount_positive CHECK ((effectif >= (0)::numeric));
alter table `releves_temps` add constraint time_entry_hours_positive CHECK (((pause_minutes >= 0) AND ((heures_travaillees IS NULL) OR (heures_travaillees >= (0)::numeric)) AND ((heures_prevues IS NULL) OR (heures_prevues >= (0)::numeric)) AND (heures_dimanche >= (0)::numeric) AND (heures_ferie >= (0)::numeric) AND (heures_nuit >= (0)::numeric) AND (heures_supplementaires >= (0)::numeric)));
alter table `releves_temps` add constraint time_entry_parts_within_work CHECK (((heures_travaillees IS NULL) OR ((heures_dimanche <= heures_travaillees) AND (heures_ferie <= heures_travaillees) AND (heures_nuit <= heures_travaillees) AND (heures_supplementaires <= heures_travaillees))));
alter table `ruptures_contrat` add constraint notice_dates_order CHECK (((debut_preavis IS NULL) OR (fin_preavis IS NULL) OR (fin_preavis >= debut_preavis)));
alter table `ruptures_contrat` add constraint waiver_compensation_positive CHECK (((compensation_renonciation IS NULL) OR (compensation_renonciation >= (0)::numeric)));
alter table `ruptures_contrat` add constraint waiver_needs_agreement_date CHECK (((NOT preavis_renonce) OR (renonciation_convenue_le IS NOT NULL)));
alter table `salaries` add constraint employee_email_shape CHECK (((courriel IS NULL) OR (courriel ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'::text)));
alter table `sanctions_salarie` add constraint sanction_dates_order CHECK (((effet_au IS NULL) OR (effet_du IS NULL) OR (effet_au >= effet_du)));
alter table `sanctions_salarie` add constraint sanction_deleted_pair CHECK (((supprime_le IS NULL) = (supprime_par IS NULL)));
alter table `sanctions_salarie` add constraint sanction_known_after_facts CHECK ((faits_connus_le >= faits_le));
alter table `sanctions_salarie` add constraint sanction_notified_after_know CHECK (((notifie_le IS NULL) OR (notifie_le >= faits_connus_le)));
alter table `services` add constraint coverage_positive CHECK (((couverture_soir_min IS NULL) OR (couverture_soir_min >= 0)));
alter table `sinistres_accident_societe` add constraint accident_counts_positive CHECK (((nombre_sinistres >= 0) AND (jours_perdus >= 0) AND ((cout IS NULL) OR (cout >= (0)::numeric))));
alter table `sites_client` add constraint client_site_has_an_address CHECK (((ligne IS NOT NULL) OR ((code_postal IS NOT NULL) AND (localite IS NOT NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL))));
alter table `societes` add constraint ccss_matricule_format CHECK (((matricule_ccss IS NULL) OR (matricule_ccss ~ '^[0-9]{13}$'::text)));
alter table `societes` add constraint societes_reference_period_po CHECK ((periode_reference_mois >= 1));
alter table `statuts_salarie` add constraint status_range CHECK (((date_fin IS NULL) OR (date_fin >= date_debut)));
alter table `tranches_impot` add constraint bracket_range CHECK (((tranche_max IS NULL) OR (tranche_max > tranche_min)));
alter table `tranches_impot` add constraint bracket_validity CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `tranches_impot` add constraint tranches_impot_periode_valid CHECK ((fin_validite > debut_validite));
alter table `types_sanction` add constraint sanction_type_range CHECK (((fin_validite IS NULL) OR (fin_validite > debut_validite)));
alter table `types_sanction` add constraint types_sanction_periode_valid CHECK ((fin_validite > debut_validite));
alter table `zones_adresse` add constraint address_zone_range CHECK (((code_postal_au IS NULL) OR (code_postal_du IS NULL) OR (code_postal_au >= code_postal_du)));
alter table `zones_adresse` add constraint address_zone_verified_needs_ CHECK (((NOT verifie) OR ((code_postal_du IS NOT NULL) AND (code_postal_au IS NOT NULL))));

-- ------------------------------------------------------------------
-- COMMENTAIRES — 75 table(s) et 836 colonne(s).
-- Repris tels quels du schéma PostgreSQL, qui fait foi.
-- ------------------------------------------------------------------
comment on table `absences` is 'Absence d''un salarié : congé, maladie, congé extraordinaire. Le moteur en contrôle le droit, l''imputation et les justificatifs.';
comment on column `absences`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `absences`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `absences`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `absences`.`type_absence_id` is 'Type d''absence demandé. Détermine les pièces exigées, le délai de certificat et l''imputation sur les compteurs.';
comment on column `absences`.`date_debut` is 'Premier jour d''absence, inclus. Jour entier : une absence d''une demi-journée se compte par days_count, pas par les bornes.';
comment on column `absences`.`date_fin` is 'Dernier jour d''absence, INCLUS — contrairement aux bornes de validité du référentiel, qui sont exclusives. Une absence d''un seul jour porte la même date en début et en fin.';
comment on column `absences`.`nombre_jours` is 'Jours décomptés, calculés hors fériés et jours non ouvrés — pas la simple différence de dates.';
comment on column `absences`.`statut` is 'Où en est la demande : proposé, en attente, validé, refusé, annulé. Un refus n''est jamais un point final — il doit s''accompagner d''une contre-proposition, chaînée par absence_parente_id.';
comment on column `absences`.`commentaire` is 'Motif ou précision donnée par le demandeur. Visible du salarié comme du gestionnaire : ce n''est pas une note interne.';
comment on column `absences`.`certificat_recu` is 'Vrai dès réception du certificat, sous quelque forme que ce soit.';
comment on column `absences`.`certificat_recu_le` is 'Date de réception du certificat, original ou copie. C''est elle qui arrête le décompte du délai CCSS, pas la date d''émission du certificat.';
comment on column `absences`.`certificat_document_id` is 'Pièce justificative rattachée. Sans clé étrangère stricte vers un document supprimé : l''absence reste lisible même si la pièce a été purgée.';
comment on column `absences`.`demande_par` is 'Compte à l''origine de la demande. Peut différer du salarié : un gestionnaire saisit pour un salarié sans accès, et il faut savoir qui a saisi.';
comment on column `absences`.`decide_par` is 'Auteur de la décision d''acceptation ou de refus.';
comment on column `absences`.`decide_le` is 'Horodatage de la décision. Avec decided_by, répond à « qui a tranché, et quand » — une validation d''absence est un acte opposable.';
comment on column `absences`.`note_decision` is 'Motivation de la décision, restituée au salarié.';
comment on column `absences`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `absences`.`declare_par_salarie` is 'Vrai si la déclaration vient de l''espace salarié, faux si elle est saisie par les RH.';
comment on column `absences`.`certificat_depose_le` is 'Dépôt numérique du certificat par le salarié.';
comment on column `absences`.`certificat_original_recu` is 'Réception de l''original papier, exigée séparément du dépôt numérique.';
comment on column `absences`.`certificat_original_recu_le` is 'Date de réception de l''ORIGINAL papier. Distincte de la copie : la CCSS exige l''original, et seule cette date solde l''obligation.';
comment on column `absences`.`enfant_id` is 'Enfant concerné, pour un congé lié à un enfant.';
comment on column `absences`.`absence_parente_id` is 'Proposition que celle-ci remplace. Chaîne la demande initiale et les contre-propositions successives : c''est l''historique de la négociation, lisible dans les deux sens.';
comment on column `absences`.`proposee_par` is 'Qui a formulé cette proposition : « salarie » pour la demande initiale, « employeur » pour une contre-proposition.';
comment on column `absences`.`rang_proposition` is 'Profondeur dans la chaîne. Zéro pour la demande initiale. Borné, pour qu''une négociation sans fin ne soit pas possible.';
comment on table `adresses_salarie` is 'Les quatre adresses du salarié, historisées. Chaque type doit couvrir toute la période sans trou ni recouvrement, depuis la candidature jusqu''à bien après le départ : une erreur de salaire découverte plus tard suppose de pouvoir écrire à la personne.';
comment on column `adresses_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `adresses_salarie`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `adresses_salarie`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
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
comment on column `adresses_salarie`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `adresses_salarie`.`cree_par` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `adresses_salarie`.`supprime_le` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `adresses_salarie`.`supprime_par` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `agences_interim` is 'Agence de travail intérimaire, employeur juridique d''un salarié en mission chez une société utilisatrice.';
comment on column `agences_interim`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `agences_interim`.`organisation_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `agences_interim`.`nom` is 'Raison sociale de l''agence d''intérim, telle qu''elle figure au contrat de mise à disposition.';
comment on column `agences_interim`.`matricule_ccss` is 'Matricule CCSS de l''agence. C''est elle qui déclare le salarié, pas l''entreprise utilisatrice.';
comment on column `agences_interim`.`numero_rcs` is 'Numéro au registre de commerce. Permet de vérifier qu''une agence est autorisée avant de lui confier une mission.';
comment on column `agences_interim`.`ligne` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `agences_interim`.`code_postal` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `agences_interim`.`localite` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `agences_interim`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `alertes_conformite` is 'Constats du moteur de vigilance. Chaque alerte porte son article : c''est ce qui distingue un avertissement d''une injonction opaque.';
comment on column `alertes_conformite`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `alertes_conformite`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `alertes_conformite`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `alertes_conformite`.`code_regle` is 'Code stable de la règle, pour suivre une alerte à travers les scans successifs.';
comment on column `alertes_conformite`.`titre` is 'Intitulé court de l''alerte, tel qu''il apparaît dans la liste de vigilance.';
comment on column `alertes_conformite`.`detail` is 'Explication complète : ce qui manque, pourquoi c''est exigé, et ce qu''il faut faire. Une alerte qui ne dit pas quoi faire ne sera pas traitée.';
comment on column `alertes_conformite`.`consequence` is 'Ce qui arrive si rien n''est fait — sanction, requalification, nullité.';
comment on column `alertes_conformite`.`reference_legale` is 'Article qui fonde le constat.';
comment on column `alertes_conformite`.`severite` is 'Gravité, qui commande le tri et la couleur à l''écran.';
comment on column `alertes_conformite`.`date_echeance` is 'Échéance à laquelle le manquement devient effectif.';
comment on column `alertes_conformite`.`etat` is 'État de traitement : ouverte, traitée, écartée.';
comment on column `alertes_conformite`.`traite_par` is 'Compte ayant traité l''alerte. Nul tant qu''elle est ouverte.';
comment on column `alertes_conformite`.`traite_le` is 'Date de traitement. Avec handled_by, permet de mesurer le délai de réaction — la sévérité CCSS s''appuie dessus.';
comment on column `alertes_conformite`.`note_traitement` is 'Justification de la prise en charge ou de la mise à l''écart.';
comment on column `alertes_conformite`.`vu_la_premiere_fois_le` is 'Première apparition du constat, conservée même si l''alerte réapparaît.';
comment on table `attributions_titres_repas` is 'Attribution de chèques-repas sur une période. La valeur faciale et la participation salariale sont contrôlées contre les limites du référentiel.';
comment on column `attributions_titres_repas`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `attributions_titres_repas`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `attributions_titres_repas`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `attributions_titres_repas`.`debut_periode` is 'Premier jour de la période d''attribution, inclus.';
comment on column `attributions_titres_repas`.`fin_periode` is 'Dernier jour de la période, INCLUS.';
comment on column `attributions_titres_repas`.`nombre_titres` is 'Nombre de chèques attribués sur la période.';
comment on column `attributions_titres_repas`.`valeur_faciale` is 'Valeur faciale du chèque.';
comment on column `attributions_titres_repas`.`part_salariale` is 'Part supportée par le salarié : c''est elle qui conditionne le régime fiscal de l''avantage.';
comment on column `attributions_titres_repas`.`attribue_le` is 'Date de remise effective des titres. Distincte de la période qu''ils couvrent.';
comment on column `attributions_titres_repas`.`note` is 'Précisions sur le calcul du nombre de titres, notamment les jours d''absence déduits.';
comment on column `attributions_titres_repas`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `avenants_contrat` is 'Avenant. Conserve ce qui a changé et à partir de quand, sans écraser l''état antérieur du contrat.';
comment on column `avenants_contrat`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `avenants_contrat`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `avenants_contrat`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `avenants_contrat`.`date_effet` is 'Prise d''effet, qui peut différer de la signature.';
comment on column `avenants_contrat`.`motif` is 'Motif de l''avenant, obligatoire. Un avenant sans motif est refusé par le moteur : c''est la pièce qui explique, des années après, pourquoi le contrat a changé.';
comment on column `avenants_contrat`.`modifications` is 'Différentiel appliqué, en jsonb : ce que l''avenant modifie, et rien d''autre.';
comment on column `avenants_contrat`.`cree_par` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `avenants_contrat`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `categories_sanction` is 'Les trois degrés de la sanction disciplinaire. Table de référence datée plutôt qu''énumération : un degré peut être renommé, ajouté ou retiré par DML, sans migration ni indisponibilité.';
comment on column `categories_sanction`.`code` is 'Code de la catégorie de sanction : mineure, lourde, rupture. Trois catégories, qui commandent la procédure exigée.';
comment on column `categories_sanction`.`libelle` is 'Libellé de la catégorie à l''écran.';
comment on column `categories_sanction`.`rang` is 'Gravité croissante. Sert à ordonner, jamais à décider : c''est le type de sanction qui porte les règles.';
comment on column `categories_sanction`.`description` is 'Ce que la catégorie implique en matière de procédure, d''entretien préalable et de recours. C''est la colonne que lit un gestionnaire avant de choisir.';
comment on column `categories_sanction`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `categories_sanction`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `cct_regle_prime` is 'Règle de prime de condition telle que la convention collective la fixe. Aucune valeur légale générale ici : la loi ne définit pas ces primes, seules les CCT le font. Une règle sans source_url est refusée — elle ne pourrait pas être vérifiée.';
comment on column `cct_regle_prime`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `cct_regle_prime`.`convention_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
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
comment on column `cct_regle_prime`.`url_source` is 'Lien vers le texte déposé — les conventions luxembourgeoises sont publiées par l''ITM. Obligatoire.';
comment on column `cct_regle_prime`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `cct_regle_prime`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `cct_regle_prime`.`note` is 'Précisions d''application : cumul, proratisation, exclusions. Ce que l''article dit et que les colonnes ne portent pas.';
comment on table `comptes` is 'Comptes applicatifs. Point d''ancrage commun aux trois moteurs : sur PostgreSQL elle reflète auth.users et password_hash reste nul, l''authentification appartenant à Supabase ; sur Oracle et MySQL elle porte le mot de passe et devient la table d''identité vers laquelle pointent les clés étrangères d''auteur.';
comment on column `comptes`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `comptes`.`identifiant` is 'Identifiant de connexion, en minuscules. Unique parmi les comptes vivants seulement : un identifiant libéré par une suppression logique peut être réattribué.';
comment on column `comptes`.`courriel` is 'Adresse de connexion et de notification. Unique : c''est elle qui identifie le compte pour la récupération de mot de passe.';
comment on column `comptes`.`nom_complet` is 'Nom affiché du compte. Modifiable par l''intéressé en libre-service, contrairement aux données d''identité du dossier salarié.';
comment on column `comptes`.`empreinte_mot_de_passe` is 'Empreinte bcrypt du mot de passe. NUL sur PostgreSQL/Supabase, où Auth détient le secret. Jamais le mot de passe en clair, à aucun moment.';
comment on column `comptes`.`est_admin` is 'Administrateur : seul habilité à lire le catalogue du schéma et à créer d''autres comptes.';
comment on column `comptes`.`compte_auth_id` is 'Compte auth.users correspondant, quand l''application tourne sur Supabase. Nul sur une cible autonome.';
comment on column `comptes`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `comptes`.`cree_par` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `comptes`.`modifie_le` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column `comptes`.`modifie_par` is 'Compte auteur de la dernière modification. Sur une table de comptes, savoir qui a changé quoi n''est pas optionnel.';
comment on column `comptes`.`supprime_le` is 'Suppression logique : la ligne reste, les clés étrangères qui la référencent tiennent, et le journal demeure lisible. Un compte parti doit encore pouvoir répondre de ce qu''il a fait.';
comment on column `comptes`.`supprime_par` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `contrats` is 'Contrat de travail. Le brouillon vit ici dès la première étape de l''assistant : c''est cette ligne que le moteur évalue, pas un objet en mémoire du navigateur.';
comment on column `contrats`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `contrats`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `contrats`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `contrats`.`genre` is 'Type de contrat : CDI, CDD, apprentissage, saisonnier, intérim, étudiant. Commande les clauses obligatoires et les contrôles.';
comment on column `contrats`.`statut` is 'Brouillon, actif, terminé. Un brouillon n''engage rien mais se contrôle déjà.';
comment on column `contrats`.`intitule_poste` is 'Intitulé du poste tel qu''il figure au contrat. Mention obligatoire : il fonde la classification conventionnelle, et donc le salaire minimum applicable.';
comment on column `contrats`.`description_poste` is 'Description des fonctions. Sa précision détermine ce qu''un changement de tâches doit faire passer par un avenant plutôt que par une simple instruction.';
comment on column `contrats`.`lieu_travail` is 'Lieu d''exécution convenu. Mention obligatoire au contrat.';
comment on column `contrats`.`categorie` is 'Catégorie professionnelle, clé d''entrée dans la grille salariale conventionnelle.';
comment on column `contrats`.`date_debut` is 'Prise d''effet du contrat, jour inclus. Point de départ de l''ancienneté, de la période d''essai et du droit à congé.';
comment on column `contrats`.`date_fin` is 'Dernier jour du contrat, INCLUS. Nulle pour un contrat à durée indéterminée en cours. Un avenant clôt le contrat précédent la veille de sa prise d''effet.';
comment on column `contrats`.`motif_cdd` is 'Motif de recours au CDD. Un CDD sans motif licite est requalifiable.';
comment on column `contrats`.`nombre_renouvellements` is 'Nombre de renouvellements déjà consommés, borné par la loi.';
comment on column `contrats`.`contrat_precedent_id` is 'Contrat que celui-ci renouvelle, pour reconstituer la chaîne et l''ancienneté.';
comment on column `contrats`.`brut_mensuel` is 'Salaire mensuel brut convenu, hors éléments variables portés par contract_pay_components.';
comment on column `contrats`.`indice_reference` is 'Cote d''indice à la signature, pour distinguer une hausse réelle d''une indexation.';
comment on column `contrats`.`heures_hebdomadaires` is 'Durée hebdomadaire convenue. Sous le plein temps, is_part_time devient vrai.';
comment on column `contrats`.`jours_par_semaine` is 'Nombre de jours travaillés par semaine, décimal pour les rythmes irréguliers.';
comment on column `contrats`.`repartition_travail` is 'Répartition convenue de l''horaire. Mention obligatoire au contrat pour un temps partiel.';
comment on column `contrats`.`periode_reference_mois` is 'Période de référence propre au contrat, si elle déroge à celle de la société.';
comment on column `contrats`.`travail_nuit` is 'Vrai si le poste comporte du travail de nuit, qui ouvre ses propres protections.';
comment on column `contrats`.`jours_conge_annuel` is 'Congé annuel convenu lorsqu''il dépasse le minimum légal. Nul renvoie au droit commun.';
comment on column `contrats`.`pause_minutes` is 'Pause convenue par journée de travail.';
comment on column `contrats`.`clause_non_concurrence` is 'Présence d''une clause de non-concurrence, dont la validité est soumise à conditions.';
comment on column `contrats`.`clause_exclusivite` is 'Présence d''une clause d''exclusivité.';
comment on column `contrats`.`duree_essai` is 'Durée de la période d''essai, exprimée dans l''unité portée par probation_unit.';
comment on column `contrats`.`unite_essai` is 'Unité de la période d''essai : mois ou semaines. Les bornes légales diffèrent selon l''unité.';
comment on column `contrats`.`version` is 'Version du contrat, incrémentée par les avenants.';
comment on column `contrats`.`signe_le` is 'Date de signature. Un contrat actif sans date de signature est un manquement.';
comment on column `contrats`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `contrats`.`est_temps_partiel` is 'Temps partiel, tenu à jour par le déclencheur fn_sync_part_time — ne pas écrire à la main.';
comment on column `contrats`.`niveau_apprentissage` is 'Niveau de la formation, pour un contrat d''apprentissage.';
comment on column `contrats`.`annee_apprentissage` is 'Année du cycle d''apprentissage, qui commande l''indemnité.';
comment on column `contrats`.`libelle_saison` is 'Saison couverte, pour un contrat saisonnier.';
comment on column `contrats`.`agence_interim_id` is 'Agence d''intérim employeuse, pour un contrat de mission.';
comment on column `contrats`.`nom_societe_utilisateur` is 'Société utilisatrice chez qui la mission s''exécute.';
comment on column `contrats`.`motif_mission` is 'Motif de recours à l''intérim, soumis aux mêmes exigences que le motif de CDD.';
comment on table `controles_adresse` is 'Dernier verdict de validation d''adresse par objet. Une adresse « unknown » y reste visible : c''est ce qui permet de la reprendre plus tard, plutôt que de la croire vérifiée.';
comment on column `controles_adresse`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `controles_adresse`.`entite_table` is 'Table de la ligne vérifiée — employees, companies, client_sites. Le contrôle d''adresse est le même pour toutes ; cette colonne dit d''où vient celle-ci.';
comment on column `controles_adresse`.`entite_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `controles_adresse`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `controles_adresse`.`pays` is 'Code pays ISO 3166-1 alpha-3.';
comment on column `controles_adresse`.`code_postal` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `controles_adresse`.`statut` is 'Résultat du contrôle, parmi ref_statut_verification_adresse : vérifiée, incohérente, hors périmètre, non vérifiable. « Non vérifiable » est un résultat, pas un échec : LuxRH ne couvre que le Luxembourg et les zones frontalières déclarées.';
comment on column `controles_adresse`.`code_zone` is 'Zone reconnue pour cette adresse : Luxembourg, ou zone frontalière déclarée. Détermine le régime de frontalier et les barèmes applicables.';
comment on column `controles_adresse`.`message` is 'Explication du résultat, destinée à l''humain qui corrigera. Une adresse rejetée sans motif ne se corrige pas.';
comment on column `controles_adresse`.`controle_le` is 'Date du contrôle. Un référentiel postal évolue : un contrôle ancien ne vaut pas contrôle actuel.';
comment on table `conventions_collectives` is 'Convention collective de travail. Sectorielle et partagée, ou propre à une organisation.';
comment on column `conventions_collectives`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `conventions_collectives`.`organisation_id` is 'Nul pour une convention sectorielle partagée par toutes les organisations.';
comment on column `conventions_collectives`.`code` is 'Code court, clé naturelle utilisée par l''export et l''import du référentiel.';
comment on column `conventions_collectives`.`nom` is 'Intitulé officiel de la convention, tel que publié par l''ITM.';
comment on column `conventions_collectives`.`secteur` is 'Secteur couvert. Sert à proposer la bonne convention lors du rattachement d''une société, jamais à l''imposer.';
comment on column `conventions_collectives`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `conventions_collectives`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `conventions_collectives`.`actif` is 'Faux quand la convention est dénoncée ou remplacée. Elle reste en base : une paie ancienne doit encore pouvoir citer la convention qui la fondait.';
comment on column `conventions_collectives`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `conventions_collectives`.`portee` is 'Portée : sectorielle, d''entreprise, ou d''établissement.';
comment on column `conventions_collectives`.`remplace_id` is 'Convention que celle-ci remplace, pour suivre les renouvellements.';
comment on column `conventions_collectives`.`categorie_professionnelle` is 'Catégorie de personnel visée lorsque la convention ne couvre pas tout l''effectif.';
comment on table `conventions_de_la_societe` is 'Rattachement d''une société, ou d''un de ses services, à une convention collective, sur une période donnée. Une société peut en appliquer plusieurs simultanément.';
comment on column `conventions_de_la_societe`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `conventions_de_la_societe`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `conventions_de_la_societe`.`convention_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `conventions_de_la_societe`.`service_id` is 'Nul si la convention couvre toute la société.';
comment on column `conventions_de_la_societe`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `conventions_de_la_societe`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `conventions_de_la_societe`.`note` is 'Circonstances du rattachement de la société à la convention : adhésion, extension, usage. Ce qui permet de le contester.';
comment on column `conventions_de_la_societe`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `conventions_du_contrat` is 'Conventions applicables à un contrat donné, sur une période. Plusieurs conventions peuvent se cumuler ; le moteur retient la disposition la plus favorable et dit laquelle a gagné.';
comment on column `conventions_du_contrat`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `conventions_du_contrat`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `conventions_du_contrat`.`convention_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `conventions_du_contrat`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `conventions_du_contrat`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `conventions_du_contrat`.`note` is 'Circonstances du rattachement au niveau du contrat, quand il déroge à celui de la société.';
comment on column `conventions_du_contrat`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `credits_impot` is 'Crédits d''impôt, avec leur plage de revenu et les classes auxquelles ils s''appliquent.';
comment on column `credits_impot`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `credits_impot`.`code` is 'Code du crédit d''impôt, stable, repris par le calcul de la retenue.';
comment on column `credits_impot`.`libelle` is 'Libellé du crédit tel qu''il apparaît sur le bulletin.';
comment on column `credits_impot`.`classes_visees` is 'Classes d''impôt ouvrant droit au crédit.';
comment on column `credits_impot`.`revenu_min` is 'Revenu à partir duquel le crédit est ouvert.';
comment on column `credits_impot`.`revenu_max` is 'Revenu au-delà duquel le crédit s''éteint.';
comment on column `credits_impot`.`montant_mensuel` is 'Montant mensuel du crédit, en euros. Nul quand le crédit ne se traduit pas par un montant fixe.';
comment on column `credits_impot`.`proratise_sur_heures` is 'Vrai si le crédit se réduit au prorata du temps de travail.';
comment on column `credits_impot`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `credits_impot`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `credits_impot`.`source` is 'Publication d''origine du montant. Obligatoire pour la même raison que sur tax_brackets.';
comment on column `credits_impot`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `credits_impot`.`note` is 'Conditions d''octroi et cumul avec les autres crédits.';
comment on table `creneau_condition` is 'Créneau réellement travaillé sous une condition ouvrant droit à prime : qui, quand, où, de quelle heure à quelle heure. C''est ce relevé qui rend la prime calculable — sans lui, la règle conventionnelle reste lettre morte.';
comment on column `creneau_condition`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `creneau_condition`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `creneau_condition`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `creneau_condition`.`creneau_id` is 'Vacation planifiée. Le créneau se saisit au planning, puis se confirme au registre du temps.';
comment on column `creneau_condition`.`releve_temps_id` is 'Journée du registre du temps. C''est elle qui fait foi pour le paiement, le planning n''étant qu''une prévision.';
comment on column `creneau_condition`.`site_client_id` is 'Site client où la condition a été constatée. Nul pour une condition constatée dans les locaux de l''employeur.';
comment on column `creneau_condition`.`condition_code` is 'Condition constatée, parmi ref_condition_travail. C''est le constat qui ouvre le droit, pas le poste : un même salarié peut être exposé un jour et pas le lendemain.';
comment on column `creneau_condition`.`date_prestation` is 'Jour de la prestation. La règle conventionnelle applicable est celle en vigueur ce jour-là, pas celle d''aujourd''hui.';
comment on column `creneau_condition`.`heure_debut` is 'Heure de début d''exposition. Avec heure_fin, donne la durée qui sert au seuil et à la conversion en montant.';
comment on column `creneau_condition`.`heure_fin` is 'Heure de fin d''exposition. Un créneau ne franchit pas minuit : une exposition de nuit se saisit en deux créneaux.';
comment on column `creneau_condition`.`minutes` is 'Durée exposée, calculée par la base. Un créneau qui franchit minuit est compté correctement.';
comment on column `creneau_condition`.`constate_par` is 'Compte ayant constaté la condition. Une prime de pénibilité repose sur un constat : il a un auteur.';
comment on column `creneau_condition`.`note` is 'Circonstances du constat. Utile en cas de contestation, jamais utilisée par le calcul.';
comment on column `creneau_condition`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `creneau_condition`.`supprime_le` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `creneau_condition`.`supprime_par` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `creneaux` is 'Vacation planifiée : un salarié, une date, des horaires. C''est l''unité que le moteur contrôle contre les repos et les durées maximales.';
comment on column `creneaux`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `creneaux`.`planning_id` is 'Planning auquel le créneau appartient. Un créneau n''existe pas hors d''un planning : c''est le planning qui porte le statut brouillon ou publié.';
comment on column `creneaux`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `creneaux`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `creneaux`.`date_creneau` is 'Jour du créneau. Un créneau qui déborde sur le lendemain porte la date de son début.';
comment on column `creneaux`.`heure_debut` is 'Heure de début. Avec la durée, détermine les majorations de nuit, de dimanche et de jour férié.';
comment on column `creneaux`.`heure_fin` is 'Heure de fin. Antérieure à start_time pour une vacation qui franchit minuit — fn_shift_end_ts résout le cas.';
comment on column `creneaux`.`pause_minutes` is 'Pause de la vacation, déduite des heures travaillées.';
comment on column `creneaux`.`libelle` is 'Précision sur le créneau : chantier, tournée, remplacement. Affichée au salarié.';
comment on column `creneaux`.`modele_id` is 'Modèle dont la vacation est issue, s''il y en a un.';
comment on column `creneaux`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `creneaux`.`site_client_id` is 'Lieu d''exécution de la vacation. Nul signifie « au siège de la société » — c''est le cas courant, et c''est aussi la référence à laquelle un dépassement se mesure.';
comment on table `demandes_heures_sup` is 'Demande d''heures supplémentaires. Elle exige un double accord : validation RH et acceptation du salarié.';
comment on column `demandes_heures_sup`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `demandes_heures_sup`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `demandes_heures_sup`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `demandes_heures_sup`.`planning_id` is 'Planning auquel la demande se rattache, s''il y en a un.';
comment on column `demandes_heures_sup`.`debut_periode` is 'Premier jour de la période couverte par la demande, inclus.';
comment on column `demandes_heures_sup`.`fin_periode` is 'Dernier jour de la période, INCLUS.';
comment on column `demandes_heures_sup`.`heures` is 'Nombre d''heures supplémentaires demandées sur la période.';
comment on column `demandes_heures_sup`.`motif` is 'Motif du recours aux heures supplémentaires, obligatoire. L''ITM peut le demander : les heures supplémentaires ne sont pas de droit.';
comment on column `demandes_heures_sup`.`statut` is 'État de la demande. hr_approved ne suffit pas : tant que le salarié n''a pas accepté, les heures ne sont pas couvertes.';
comment on column `demandes_heures_sup`.`demande_par` is 'Compte à l''origine de la demande, généralement l''employeur.';
comment on column `demandes_heures_sup`.`demande_le` is 'Horodatage du dépôt. Le délai de notification se compte à partir de là.';
comment on column `demandes_heures_sup`.`valide_rh_par` is 'Compte ayant validé côté ressources humaines, avant transmission éventuelle à l''ITM.';
comment on column `demandes_heures_sup`.`valide_rh_le` is 'Horodatage de la validation RH.';
comment on column `demandes_heures_sup`.`accepte_par_salarie_le` is 'Horodatage de l''acceptation par le salarié.';
comment on column `demandes_heures_sup`.`motif_refus` is 'Motif du refus, restitué à l''auteur de la demande.';
comment on column `demandes_heures_sup`.`compensation` is 'Mode de compensation retenu : repos compensateur ou paiement majoré.';
comment on column `demandes_heures_sup`.`note` is 'Précisions sur les circonstances ou sur la compensation retenue.';
comment on table `distances_trajet` is 'Distances routières mises en cache. Une adresse n''est transmise au service tiers qu''au premier calcul d''un couple ; les plannings suivants lisent cette table.';
comment on column `distances_trajet`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `distances_trajet`.`reference_origine` is 'Référence de l''origine, sous la forme « employee:<uuid> », « company:<uuid> » ou « site:<uuid> ». Aucune adresse n''est recopiée ici.';
comment on column `distances_trajet`.`reference_destination` is 'Référence de la destination : site client, société, ou adresse saisie. Le trajet se calcule depuis une adresse du salarié vers cette destination.';
comment on column `distances_trajet`.`distance_km` is 'Distance routière en kilomètres, telle que renvoyée par le service d''itinéraire. Ce n''est pas la distance à vol d''oiseau : c''est celle qui fonde l''indemnité.';
comment on column `distances_trajet`.`duree_minutes` is 'Durée estimée du trajet. Indicative : elle sert à construire les tournées, pas à rémunérer.';
comment on column `distances_trajet`.`source` is 'Origine de la mesure : nom du service consulté, ou « manuel » si la distance a été saisie. Une distance sans source ne doit pas servir à payer.';
comment on column `distances_trajet`.`calcule_le` is 'Date du calcul. Une adresse change ; une distance vieille de trois ans mérite d''être revérifiée.';
comment on column `distances_trajet`.`calcule_par` is 'Compte ayant déclenché le calcul. Un appel à un service externe se trace : il a un coût et il expose une adresse.';
comment on column `distances_trajet`.`note` is 'Circonstances du calcul : date, service interrogé, correction manuelle éventuelle.';
comment on table `documents` is 'Pièces déposées, rattachées à un salarié, à un contrat ou à une société. Le fichier vit dans le stockage ; cette table porte les métadonnées et la durée de conservation.';
comment on column `documents`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `documents`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `documents`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `documents`.`entite_table` is 'Table de l''objet rattaché, lorsque la pièce ne vise pas directement un salarié.';
comment on column `documents`.`entite_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `documents`.`nom` is 'Nom du document tel que présenté à l''utilisateur. Distinct du nom du fichier stocké.';
comment on column `documents`.`chemin_stockage` is 'Chemin dans le bucket de stockage. L''accès au fichier obéit aux mêmes règles que la ligne.';
comment on column `documents`.`type_mime` is 'Type MIME déclaré à l''envoi. Sert à choisir la visionneuse ; il ne remplace pas un contrôle du contenu.';
comment on column `documents`.`taille_octets` is 'Taille du fichier en octets, pour les quotas et l''affichage.';
comment on column `documents`.`conservation_jusquau` is 'Date au-delà de laquelle la pièce ne doit plus être conservée (RGPD, limitation de conservation).';
comment on column `documents`.`sensible` is 'Vrai pour une pièce de catégorie particulière (santé, handicap) : accès et conservation restreints.';
comment on column `documents`.`depose_par` is 'Compte ayant déposé le document.';
comment on column `documents`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `documents`.`type_document_id` is 'Type de document, parmi document_types. Détermine la durée de conservation et le caractère obligatoire de la pièce.';
comment on column `documents`.`emis_le` is 'Date de délivrance par l''autorité émettrice.';
comment on column `documents`.`expire_le` is 'Fin de validité de la pièce elle-même, qui déclenche l''alerte d''échéance.';
comment on column `documents`.`remis_le` is 'Date de remise au salarié, pour les pièces de fin de contrat.';
comment on table `donnees_financieres_societe` is 'Résultats annuels de la société. Sert au calcul de l''enveloppe des primes participatives, plafonnée sur le bénéfice de l''exercice précédent.';
comment on column `donnees_financieres_societe`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `donnees_financieres_societe`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `donnees_financieres_societe`.`exercice` is 'Exercice comptable concerné, en année pleine.';
comment on column `donnees_financieres_societe`.`resultat` is 'Bénéfice de l''exercice, assiette du plafond d''enveloppe.';
comment on column `donnees_financieres_societe`.`chiffre_affaires` is 'Chiffre d''affaires de l''exercice, en euros. Sert aux seuils qui dépendent de la taille de l''entreprise.';
comment on column `donnees_financieres_societe`.`source` is 'Origine du chiffre : comptes annuels, situation intermédiaire.';
comment on column `donnees_financieres_societe`.`note` is 'Origine du chiffre : comptes déposés, estimation, déclaration. Un seuil calculé sur une estimation ne se traite pas comme un seuil calculé sur des comptes.';
comment on column `donnees_financieres_societe`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `droits_absence` is 'Droit ouvert par motif d''absence, daté. Un congé extraordinaire dont la durée change au fil des réformes porte ici plusieurs versions successives.';
comment on column `droits_absence`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `droits_absence`.`type_absence_id` is 'Type d''absence auquel ce droit se rapporte. Le droit est daté : un même type peut ouvrir un nombre de jours différent selon la période.';
comment on column `droits_absence`.`jours` is 'Nombre de jours ouverts par événement.';
comment on column `droits_absence`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `droits_absence`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `droits_absence`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `droits_absence`.`note_frequence` is 'Condition de renouvellement exprimée en clair quand elle ne se réduit pas à un nombre.';
comment on column `droits_absence`.`plafond_carriere_jours` is 'Plafond sur toute la carrière, lorsque le droit n''est pas renouvelable indéfiniment.';
comment on column `droits_absence`.`jours_bloc` is 'Durée du bloc indivisible lorsque le droit doit être pris d''un seul tenant.';
comment on column `droits_absence`.`duree_mois` is 'Fenêtre glissante sur laquelle le droit se reconstitue.';
comment on column `droits_absence`.`degre_parente` is 'Degré de parenté exigé, pour les congés liés à un événement familial.';
comment on column `droits_absence`.`piece_exigee` is 'Vrai si un justificatif conditionne l''ouverture du droit.';
comment on column `droits_absence`.`note` is 'Précision sur l''origine du droit : disposition conventionnelle, usage d''entreprise, circonstance particulière. Lue par un humain, jamais par le moteur.';
comment on table `elements_remuneration` is 'Éléments de rémunération autres que le brut de base : primes récurrentes, avantages, indemnités.';
comment on column `elements_remuneration`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `elements_remuneration`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `elements_remuneration`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `elements_remuneration`.`genre` is 'Nature de l''élément, qui commande son traitement fiscal et social.';
comment on column `elements_remuneration`.`code` is 'Code de l''élément de rémunération : prime, indemnité, avantage. Stable, repris par la paie.';
comment on column `elements_remuneration`.`libelle` is 'Libellé de l''élément tel qu''il apparaît sur le bulletin.';
comment on column `elements_remuneration`.`montant` is 'Montant en euros. Nul quand l''élément se calcule au lieu d''être forfaitaire — un zéro dirait autre chose.';
comment on column `elements_remuneration`.`taux_pct` is 'Taux, pour un élément exprimé en pourcentage plutôt qu''en montant.';
comment on column `elements_remuneration`.`assiette` is 'Assiette à laquelle le taux s''applique.';
comment on column `elements_remuneration`.`periodicite` is 'Périodicité de versement.';
comment on column `elements_remuneration`.`dans_assiette_salaire` is 'Vrai si l''élément entre dans le salaire de référence servant au calcul des indemnités.';
comment on column `elements_remuneration`.`imposable` is 'Vrai si l''élément entre dans l''assiette imposable. Une prime exonérée mal marquée fausse la retenue à la source.';
comment on column `elements_remuneration`.`cotisable` is 'Vrai si l''élément entre dans l''assiette des cotisations sociales. Indépendant de is_taxable : les deux assiettes ne coïncident pas.';
comment on column `elements_remuneration`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `elements_remuneration`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `elements_remuneration`.`note` is 'Fondement de l''élément : article de convention, usage, accord individuel. Ce qui permet de le défendre ou de le supprimer.';
comment on column `elements_remuneration`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `elements_remuneration`.`type_avantage_id` is 'Avantage en nature du catalogue, lorsque l''élément en est un.';
comment on table `enfants_salarie` is 'Enfants du salarié. Données de catégorie familiale, collectées pour les droits qui en dépendent ; le salarié peut refuser leur usage — voir privacy_opt_out.';
comment on column `enfants_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `enfants_salarie`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `enfants_salarie`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `enfants_salarie`.`prenom` is 'Prénom de l''enfant. Nul quand seul le nombre d''enfants importe pour un droit et que l''identité n''a pas à être connue — la minimisation vaut aussi ici.';
comment on column `enfants_salarie`.`nom` is 'Nom de l''enfant, s''il diffère de celui du parent.';
comment on column `enfants_salarie`.`sexe` is 'Sexe de l''enfant, tel que déclaré. Aucun droit n''en dépend ; la colonne existe pour les documents administratifs qui l''exigent.';
comment on column `enfants_salarie`.`date_naissance` is 'Date de naissance. Fonde les droits liés aux enfants — congé parental, boni, classe d''impôt — et le déclenchement de leur extinction.';
comment on column `enfants_salarie`.`lien_parente` is 'Lien : enfant, enfant adopté, enfant du conjoint.';
comment on column `enfants_salarie`.`a_charge` is 'Vrai si l''enfant est à charge au sens des droits ouverts.';
comment on column `enfants_salarie`.`refus_partage` is 'Vrai si le salarié refuse que l''enfant soit pris en compte. Le moteur cesse alors d''en tirer un droit, sans effacer la ligne.';
comment on column `enfants_salarie`.`date_adoption` is 'Date de l''adoption, qui ouvre ses propres droits, distincts de ceux liés à la naissance.';
comment on column `enfants_salarie`.`note` is 'Précisions utiles au dossier familial. Jamais de donnée de santé : celles-ci vont en fiche_sante, qui porte les restrictions adéquates.';
comment on column `enfants_salarie`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `enfants_salarie`.`refus_photos_evenements` is 'L''enfant ne doit pas apparaître sur les photos des événements familiaux de la société.';
comment on column `enfants_salarie`.`invitation_evenements` is 'L''enfant est convié aux événements de la société — Saint-Nicolas, journée des familles — avec ses parents.';
comment on column `enfants_salarie`.`en_situation_handicap` is 'Situation de handicap. DONNÉE DE SANTÉ : même régime d''accès que la fiche santé.';
comment on column `enfants_salarie`.`taux_handicap_pct` is 'Taux de handicap reconnu, en pourcentage. Donnée de santé : accès restreint, lecture journalisée. Nul si aucun handicap n''est reconnu.';
comment on table `fiche_sante` is 'Fiche santé d''un salarié ou d''un de ses enfants. DONNÉE DE SANTÉ au sens de l''article 9 du RGPD : accès réservé à la personne, à la médecine du travail et aux RH d''urgence. Le dispatching n''y accède jamais — il lit les indicateurs dérivés.';
comment on column `fiche_sante`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `fiche_sante`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `fiche_sante`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `fiche_sante`.`enfant_id` is 'Enfant concerné quand la fiche porte sur un enfant et non sur le salarié. Exclusif de la fiche du salarié : une ligne concerne l''un ou l''autre.';
comment on column `fiche_sante`.`allergies` is 'Donnée brute. Ne jamais exposer au planning : c''est l''indicateur dérivé qui circule.';
comment on column `fiche_sante`.`pathologies` is 'Pathologies déclarées. Donnée de santé au sens de l''article 9 du RGPD, sous le régime d''accès le plus strict : le dispatching n''y a jamais accès, il ne voit que des indicateurs dérivés et anonymisés.';
comment on column `fiche_sante`.`medecin_traitant` is 'Médecin traitant, pour le cas d''urgence. Donnée de santé.';
comment on column `fiche_sante`.`medecin_telephone` is 'Téléphone du médecin traitant, appelable en urgence.';
comment on column `fiche_sante`.`groupe_sanguin` is 'Groupe sanguin déclaré. Donnée de santé, transmise aux secours et à personne d''autre.';
comment on column `fiche_sante`.`note` is 'Consignes de prise en charge : allergies et conduite à tenir, traitement d''urgence disponible sur la personne — adrénaline pour une allergie aux piqûres, antihistaminique, mèche de cautérisation. C''est ce que les secours doivent savoir en arrivant.';
comment on column `fiche_sante`.`maj_le` is 'Date de dernière mise à jour de la fiche. Une consigne de secours périmée est dangereuse : l''ancienneté de la fiche doit être visible.';
comment on column `fiche_sante`.`maj_par` is 'Compte ayant mis la fiche à jour. Sur une donnée de santé, toute écriture est attribuable et journalisée.';
comment on column `fiche_sante`.`supprime_le` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `fiche_sante`.`supprime_par` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `fiches_retenue_impot` is 'Fiche de retenue d''impôt du salarié, datée. Donnée d''entrée du calcul brut vers net.';
comment on column `fiches_retenue_impot`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `fiches_retenue_impot`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `fiches_retenue_impot`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `fiches_retenue_impot`.`classe_impot` is 'Classe d''impôt portée par la fiche.';
comment on column `fiches_retenue_impot`.`taux` is 'Taux de retenue inscrit sur la fiche, lorsqu''un taux est fixé plutôt qu''un barème.';
comment on column `fiches_retenue_impot`.`indemnite_mensuelle` is 'Abattement mensuel inscrit sur la fiche.';
comment on column `fiches_retenue_impot`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `fiches_retenue_impot`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `fiches_retenue_impot`.`credits` is 'Crédits d''impôt portés par la fiche, structurés.';
comment on column `fiches_retenue_impot`.`distance_domicile_km` is 'Distance domicile-travail déclarée, base de l''abattement kilométrique.';
comment on column `fiches_retenue_impot`.`frais_professionnels_mensuels` is 'Frais professionnels mensuels retenus.';
comment on column `fiches_retenue_impot`.`autres_deductions_mensuelles` is 'Autres déductions mensuelles portées par la fiche.';
comment on column `fiches_retenue_impot`.`reference_carte` is 'Référence de la fiche délivrée par l''administration.';
comment on column `fiches_retenue_impot`.`emis_le` is 'Date d''émission de la fiche de retenue par l''administration. Distincte de la période de validité : une fiche peut être émise après le début de la période qu''elle couvre.';
comment on table `grilles_salaires_convention` is 'Grille de salaires conventionnelle : montant minimal par catégorie et par ancienneté.';
comment on column `grilles_salaires_convention`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `grilles_salaires_convention`.`convention_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `grilles_salaires_convention`.`categorie` is 'Catégorie professionnelle de la grille, dans les termes de la convention. C''est elle qui relie un poste à un minimum conventionnel.';
comment on column `grilles_salaires_convention`.`anciennete_de_annees` is 'Ancienneté à partir de laquelle l''échelon s''applique.';
comment on column `grilles_salaires_convention`.`anciennete_a_annees` is 'Ancienneté au-delà de laquelle l''échelon cesse. Nul pour le dernier échelon.';
comment on column `grilles_salaires_convention`.`montant_mensuel` is 'Salaire mensuel minimum de la catégorie, en euros, à l''indice de référence de la convention. Le moteur l''indexe avant de le comparer au salaire réel.';
comment on column `grilles_salaires_convention`.`indice_reference` is 'Cote d''indice à laquelle le montant est exprimé, pour le réindexer correctement.';
comment on table `handicaps_salarie` is 'Reconnaissance de travailleur handicapé. Donnée de santé au sens du RGPD : accès restreint et finalité limitée aux droits qui en découlent.';
comment on column `handicaps_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `handicaps_salarie`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `handicaps_salarie`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `handicaps_salarie`.`taux_pct` is 'Taux d''incapacité reconnu.';
comment on column `handicaps_salarie`.`reconnu_le` is 'Date de la décision de reconnaissance.';
comment on column `handicaps_salarie`.`autorite` is 'Autorité ayant prononcé la reconnaissance.';
comment on column `handicaps_salarie`.`jours_conge_supplementaires_forces` is 'Jours de congé supplémentaires imposés par la décision, lorsqu''ils diffèrent du droit commun.';
comment on column `handicaps_salarie`.`piece_justificative_id` is 'Pièce justificative, rangée dans documents avec le drapeau is_sensitive.';
comment on column `handicaps_salarie`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `handicaps_salarie`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `handicaps_salarie`.`note` is 'Éléments de contexte sur la reconnaissance du handicap. Donnée sensible au sens de l''article 9 du RGPD : l''accès en est restreint, et sa lecture journalisée.';
comment on column `handicaps_salarie`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `journal_acces` is 'Journal des consultations de données personnelles. Complète audit_log, qui ne voit que les écritures : ici sont tracés les accès en LECTURE aux données sensibles, les déchiffrements et les téléchargements de pièces. Répond aux questions qui / quoi / quand / d''où pour une personne donnée.';
comment on column `journal_acces`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `journal_acces`.`survenu_le` is 'Horodatage de la LECTURE. Ce journal répond au « quand » de l''article 15 du RGPD : à quel moment les données d''une personne ont été consultées.';
comment on column `journal_acces`.`auteur_id` is 'Compte ayant lu. Répond au « par qui ». Renseigné par le serveur à partir de la session, jamais déclaré par l''appelant.';
comment on column `journal_acces`.`auteur_libelle` is 'Nom de l''auteur figé au moment de l''accès : la trace reste lisible après suppression du compte.';
comment on column `journal_acces`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `journal_acces`.`salarie_concerne_id` is 'La personne DONT les données ont été vues — à ne pas confondre avec actor_id, qui est celle qui les a vues.';
comment on column `journal_acces`.`entite_table` is 'Table lue. Répond au « quoi », avec la ligne visée et les colonnes effectivement renvoyées.';
comment on column `journal_acces`.`entite_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `journal_acces`.`action` is 'READ consultation, DECRYPT déchiffrement d''une donnée sensible, EXPORT extraction, DOWNLOAD téléchargement d''une pièce.';
comment on column `journal_acces`.`portee` is 'Ce qui a été vu, en clair : « matricule national, IBAN », « dossier complet ». Jamais la valeur elle-même.';
comment on column `journal_acces`.`nombre_lignes` is 'Nombre de lignes effectivement renvoyées à l''appelant. Une consultation qui ne renvoie rien reste une consultation et se journalise.';
comment on column `journal_acces`.`ip_source` is 'Adresse IP d''origine, lue dans les en-têtes transmis par la passerelle. Répond au « d''où ».';
comment on column `journal_acces`.`agent_client` is 'Agent déclaré par le client. Indicatif seulement : un agent se falsifie, il complète l''IP sans la remplacer.';
comment on column `journal_acces`.`identifiant_requete` is 'Identifiant de la requête, pour rapprocher une ligne de ce journal des traces de la passerelle lors d''une investigation.';
comment on column `journal_acces`.`est_autonome` is 'Vrai si la trace a été écrite hors de la transaction appelante, et survit donc à son annulation. Faux si dblink n''était pas configuré : la trace est alors aussi fragile que l''opération qu''elle décrit.';
comment on table `journal_ecritures` is 'Journal des écritures, alimenté par le déclencheur fn_audit. Conservé pour la traçabilité et la preuve, jamais modifié par l''application.';
comment on column `journal_ecritures`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `journal_ecritures`.`survenu_le` is 'Horodatage de l''écriture auditée, posé par la base au moment du déclencheur. Ce n''est pas une date saisie : elle ne se retouche pas.';
comment on column `journal_ecritures`.`auteur_id` is 'Compte auteur de l''écriture. Nul pour une opération de maintenance exécutée hors session applicative — cas rare, qui doit rester visible plutôt que d''être attribué à tort.';
comment on column `journal_ecritures`.`auteur_libelle` is 'Nom de l''auteur figé au moment du fait : le journal reste lisible après suppression du compte.';
comment on column `journal_ecritures`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `journal_ecritures`.`entite_table` is 'Nom de la table concernée : le journal est polymorphe, sans clé étrangère.';
comment on column `journal_ecritures`.`entite_id` is 'Identifiant de la ligne visée par l''événement, dans la table que nomme la colonne voisine. Volontairement sans clé étrangère : le journal doit survivre à la suppression de ce qu''il relate.';
comment on column `journal_ecritures`.`action` is 'Nature de l''écriture : insert, update, delete. La suppression enregistrée ici est logique ; une ligne n''est jamais retirée de la base.';
comment on column `journal_ecritures`.`ancienne_valeur` is 'État de la ligne avant écriture, en jsonb. Nul pour une insertion.';
comment on column `journal_ecritures`.`nouvelle_valeur` is 'État de la ligne après écriture. Nul pour une suppression.';
comment on column `journal_ecritures`.`ip_source` is 'Adresse d''origine de la requête, telle que rapportée par les en-têtes HTTP. Donnée déclarative : elle situe, elle ne prouve pas.';
comment on column `journal_ecritures`.`agent_client` is 'Agent utilisateur de l''appelant, tronqué à 400 caractères.';
comment on column `journal_ecritures`.`identifiant_requete` is 'Identifiant de requête, pour recouper une trace avec les journaux d''infrastructure.';
comment on table `journal_exports` is 'Registre des exports de portabilité. Trace qui a exporté quoi, quand, et pour quel volume — pièce de conformité au droit d''accès et à la portabilité (RGPD art. 15 et 20).';
comment on column `journal_exports`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `journal_exports`.`organisation_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `journal_exports`.`demande_par` is 'Compte ayant demandé l''export. Un export de données personnelles est un traitement : il a un demandeur nommé.';
comment on column `journal_exports`.`genre_objet` is 'Nature du sujet exporté : self, employee, company, organization ou referential.';
comment on column `journal_exports`.`objet_id` is 'Ligne concernée par l''export, dans la table que désigne subject_kind. Nulle pour un export qui ne vise pas une ligne unique, comme le référentiel.';
comment on column `journal_exports`.`nombre_lignes` is 'Nombre d''objets contenus dans l''export, à des fins de contrôle de volume.';
comment on column `journal_exports`.`taille_octets` is 'Taille de l''enveloppe produite, en octets.';
comment on column `journal_exports`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `journal_exports`.`ip_source` is 'Adresse d''origine de la demande d''export.';
comment on column `journal_exports`.`agent_client` is 'Agent utilisateur de l''appelant.';
comment on column `journal_exports`.`identifiant_requete` is 'Identifiant de requête, pour recoupement.';
comment on table `jours_feries` is 'Jours fériés légaux d''une année, complétés le cas échéant par les jours conventionnels.';
comment on column `jours_feries`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `jours_feries`.`annee` is 'Année du jour férié. Les fériés mobiles changent de date chaque année : une ligne par année.';
comment on column `jours_feries`.`date_ferie` is 'Date du jour férié. Un férié travaillé ouvre une majoration dont le taux vient du référentiel daté.';
comment on column `jours_feries`.`nom` is 'Nom du jour férié, affiché sur les plannings.';
comment on column `jours_feries`.`est_mobile` is 'Vrai pour un férié dont la date suit le calendrier pascal, calculé par fn_easter_sunday.';
comment on column `jours_feries`.`convention_id` is 'Renseigné pour un jour chômé d''origine conventionnelle, nul pour un férié légal.';
comment on column `jours_feries`.`recuperable` is 'Vrai si le férié tombant un jour non ouvré ouvre droit à récupération.';
comment on column `jours_feries`.`motif_recuperation` is 'Motif de la récupération, cité dans l''alerte.';
comment on table `modeles_creneau` is 'Modèle de vacation réutilisable, pour éviter de ressaisir les horaires courants.';
comment on column `modeles_creneau`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `modeles_creneau`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `modeles_creneau`.`nom` is 'Nom du modèle de créneau, pour le réutiliser lors de la construction d''un planning.';
comment on column `modeles_creneau`.`heure_debut` is 'Heure de début du modèle.';
comment on column `modeles_creneau`.`heure_fin` is 'Heure de fin du modèle. Peut être antérieure à start_time : le créneau franchit alors minuit.';
comment on column `modeles_creneau`.`pause_minutes` is 'Pause en minutes, déduite du temps de travail effectif. Le seuil légal au-delà duquel une pause est obligatoire vient du référentiel daté, jamais d''une valeur écrite ici.';
comment on column `modeles_creneau`.`couleur` is 'Couleur d''affichage dans le planning. Confort d''usage, sans effet métier.';
comment on column `modeles_creneau`.`service_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on table `organisations` is 'Fiduciaire ou entreprise unique. Racine de l''isolation : toute donnée appartient, directement ou par sa société, à une organisation.';
comment on column `organisations`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `organisations`.`nom` is 'Raison sociale de la fiduciaire ou de l''entreprise.';
comment on column `organisations`.`genre` is 'Distingue une fiduciaire gérant plusieurs sociétés clientes d''une entreprise gérant la sienne.';
comment on column `organisations`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `parametres_attendus` is 'Clés de legal_parameters que le moteur lit. Sert à fn_referential_gaps pour signaler une clé attendue dont aucune version n''est chargée. Ne porte aucune valeur légale.';
comment on column `parametres_attendus`.`cle_parametre` is 'Clé d''un paramètre que le moteur attend. Sans cette table, fn_referential_gaps ne voyait pas les clés entièrement absentes : elle ne pouvait signaler que les périodes trouées.';
comment on column `parametres_attendus`.`lu_par` is 'Fonction(s) du moteur qui lisent la clé, relevées dans le code des migrations.';
comment on column `parametres_attendus`.`note` is 'À quoi sert le paramètre et ce qui se casse en son absence. Ce qui permet de hiérarchiser les trous à combler.';
comment on table `parametres_legaux` is 'Le référentiel. Tout seuil, taux ou durée légale du droit du travail luxembourgeois vit ici, jamais dans le code. Chaque valeur porte sa plage de validité, sa source et son article ; une contrainte d''exclusion GiST interdit deux versions qui se chevauchent pour une même clé.';
comment on column `parametres_legaux`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `parametres_legaux`.`famille` is 'Famille du paramètre : elle regroupe les clés par domaine et guide la détection des trous du référentiel.';
comment on column `parametres_legaux`.`cle_parametre` is 'Clé stable du paramètre. C''est elle que le moteur interroge, jamais l''identifiant technique.';
comment on column `parametres_legaux`.`libelle` is 'Intitulé du paramètre en français, pour les écrans de référentiel. Le code machine est param_key.';
comment on column `parametres_legaux`.`valeur_num` is 'Valeur numérique. Une seule des trois colonnes value_* est renseignée.';
comment on column `parametres_legaux`.`valeur_texte` is 'Valeur textuelle, pour un paramètre qui n''est pas un nombre.';
comment on column `parametres_legaux`.`valeur_json` is 'Valeur structurée, pour un barème ou une table à plusieurs entrées.';
comment on column `parametres_legaux`.`unite` is 'Unité de la valeur (EUR, heures, jours, pourcentage...) — sans elle un nombre ne veut rien dire.';
comment on column `parametres_legaux`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `parametres_legaux`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `parametres_legaux`.`indice_reference` is 'Cote d''application de l''indice des prix au moment de la valeur, pour les montants indexés.';
comment on column `parametres_legaux`.`source` is 'Origine publique de la valeur (Mémorial, STATEC, CCSS...). Obligatoire : un paramètre sans source ne doit pas exister.';
comment on column `parametres_legaux`.`reference_legale` is 'Article du Code du travail ou du texte qui fonde la valeur. C''est lui que les alertes citent à l''utilisateur.';
comment on column `parametres_legaux`.`note` is 'Précisions d''interprétation : ce que la valeur recouvre exactement, et ce qu''elle ne recouvre pas.';
comment on column `parametres_legaux`.`saisi_par` is 'Auteur de la saisie.';
comment on column `parametres_legaux`.`saisi_le` is 'Date de saisie de la valeur dans LuxRH. Distincte de sa date d''entrée en vigueur : une valeur peut être saisie avec retard, ou par anticipation.';
comment on column `parametres_legaux`.`valide_par` is 'Relecteur ayant validé la version. Nul tant que la valeur n''a pas été contrôlée.';
comment on column `parametres_legaux`.`valide_le` is 'Date de validation par un second regard. Nulle tant que la valeur n''a pas été relue — une valeur légale non validée reste utilisable, mais elle est signalée.';
comment on column `parametres_legaux`.`derive_de_cle` is 'Clé du paramètre dont celui-ci se déduit. La dérivation sert de contrôle de cohérence, pas de source.';
comment on column `parametres_legaux`.`facteur_derive` is 'Facteur appliqué au paramètre d''origine pour obtenir celui-ci.';
comment on column `parametres_legaux`.`tolerance_derivation` is 'Écart admis entre la valeur saisie et la valeur dérivée avant signalement d''une incohérence.';
comment on table `periodes_reference` is 'Période de référence sur laquelle la durée de travail se calcule en moyenne. Définie par société ou par service.';
comment on column `periodes_reference`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `periodes_reference`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `periodes_reference`.`service_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column `periodes_reference`.`libelle` is 'Intitulé de la période de référence, pour l''identifier dans les écrans de suivi.';
comment on column `periodes_reference`.`date_debut` is 'Premier jour de la période de référence, inclus. C''est sur cette période que la durée moyenne de travail doit être respectée.';
comment on column `periodes_reference`.`date_fin` is 'Dernier jour de la période, INCLUS. Sa longueur maximale est fixée par le référentiel légal et par la convention, jamais écrite en dur.';
comment on column `periodes_reference`.`mois` is 'Longueur de la période. Une période plus longue qu''un mois suppose un fondement conventionnel.';
comment on table `periodes_taux_societe` is 'Historique des taux propres à la société : classe de mutualité, facteur accident, classe d''activité. Un recalcul lit le taux en vigueur à la date du calcul.';
comment on column `periodes_taux_societe`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `periodes_taux_societe`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `periodes_taux_societe`.`classe_activite` is 'Classe d''activité déclarée à la CCSS.';
comment on column `periodes_taux_societe`.`classe_risque_accident` is 'Classe de risque accident attribuée à la société.';
comment on column `periodes_taux_societe`.`facteur_accident` is 'Facteur bonus-malus de l''assurance accident.';
comment on column `periodes_taux_societe`.`classe_mutualite` is 'Classe de la Mutualité des employeurs, qui commande le taux de cotisation.';
comment on column `periodes_taux_societe`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `periodes_taux_societe`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `periodes_taux_societe`.`source` is 'Origine du taux : courrier CCSS, décision de classement. Obligatoire.';
comment on column `periodes_taux_societe`.`note` is 'Origine du taux appliqué sur la période : notification de l''organisme, classe de risque, régularisation.';
comment on column `periodes_taux_societe`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `personne_indicateur_secours` is 'Indicateurs de secours portés par une personne. Dérivés de la fiche santé par la médecine du travail : ils circulent là où la donnée brute ne va pas. C''est ce qui permet au dispatching d''écarter une affectation sans savoir pourquoi.';
comment on column `personne_indicateur_secours`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `personne_indicateur_secours`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `personne_indicateur_secours`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `personne_indicateur_secours`.`enfant_id` is 'Enfant concerné quand l''indicateur porte sur un enfant. Exclusif de la personne salariée.';
comment on column `personne_indicateur_secours`.`indicateur` is 'Indicateur de secours, parmi ref_indicateur_secours. C''est la forme ANONYMISÉE de l''information médicale : un booléen dérivé, sans diagnostic. Le dispatching voit l''indicateur, jamais la pathologie qui le fonde.';
comment on column `personne_indicateur_secours`.`precision_lieu` is 'Précision d''affectation quand l''indicateur en appelle une — un type de lieu, un environnement. Jamais une pathologie.';
comment on column `personne_indicateur_secours`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01, jamais NULL.';
comment on column `personne_indicateur_secours`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Une validité sans fin connue porte la date sentinelle 2037-12-31, jamais NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `personne_indicateur_secours`.`pose_par` is 'Compte ayant posé l''indicateur, à partir de la fiche de santé. La dérivation est un acte : elle a un auteur et une date.';
comment on column `personne_indicateur_secours`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `plannings` is 'Planning hebdomadaire d''une société ou d''un service. Tant qu''il n''est pas publié, il n''est opposable à personne.';
comment on column `plannings`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `plannings`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `plannings`.`service_id` is 'Service de rattachement. Sert au périmètre de dispatching et à la résolution des conventions collectives, qui peuvent s''appliquer par service.';
comment on column `plannings`.`debut_semaine` is 'Lundi de la semaine couverte.';
comment on column `plannings`.`libelle` is 'Intitulé du planning, pour s''y retrouver entre plusieurs semaines ou équipes. Sans effet sur le calcul.';
comment on column `plannings`.`statut` is 'Brouillon ou publié. La publication passe par fn_publish_schedule, qui refuse un planning non conforme.';
comment on column `plannings`.`publie_le` is 'Horodatage de la publication, qui fait courir le délai de prévenance.';
comment on column `plannings`.`publie_par` is 'Auteur de la publication.';
comment on column `plannings`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `primes` is 'Primes versées, dont les primes participatives soumises à un double plafond : enveloppe société et plafond individuel.';
comment on column `primes`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `primes`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `primes`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `primes`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `primes`.`rupture_id` is 'Rupture à laquelle la prime se rattache, pour une indemnité de départ.';
comment on column `primes`.`genre` is 'Nature de la prime. Détermine son régime fiscal et social, et le plafond légal qui s''y applique le cas échéant.';
comment on column `primes`.`libelle` is 'Libellé de la prime sur le bulletin.';
comment on column `primes`.`montant` is 'Montant en euros pour la période. Le plafond d''exonération éventuel est vérifié par le moteur et non par une contrainte : il est daté.';
comment on column `primes`.`attribue_le` is 'Date d''attribution.';
comment on column `primes`.`exercice` is 'Exercice d''imputation, qui détermine l''enveloppe et les plafonds applicables.';
comment on column `primes`.`imposable` is 'Vrai si la prime entre dans l''assiette imposable, une fois le plafond d''exonération dépassé.';
comment on column `primes`.`cotisable` is 'Vrai si la prime entre dans l''assiette des cotisations. Distinct du régime fiscal.';
comment on column `primes`.`part_exoneree_pct` is 'Fraction exonérée de la prime, selon son régime.';
comment on column `primes`.`note` is 'Fondement de la prime et calcul retenu. Une prime sans justification écrite se conteste mal.';
comment on column `primes`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `profils` is 'Compte utilisateur applicatif, en miroir de auth.users. Alimenté par le déclencheur handle_new_user à l''inscription.';
comment on column `profils`.`id` is 'Identique à auth.users.id : le profil ne porte pas d''identité propre.';
comment on column `profils`.`organisation_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `profils`.`nom_complet` is 'Nom affiché de l''utilisateur dans l''interface. Doublon assumé de app_users.full_name : profiles est la vue applicative, app_users la table de comptes portable vers un autre SGBD.';
comment on column `profils`.`courriel` is 'Recopié depuis auth.users pour l''affichage. L''authentification ne s''appuie jamais sur cette copie.';
comment on column `profils`.`est_admin_organisation` is 'Administrateur de l''organisation : seul habilité à charger un référentiel et à exporter la fiduciaire entière.';
comment on column `profils`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `prolongations_essai` is 'Prolongation d''une période d''essai, suspendue par une absence. Trace la durée ajoutée et son motif.';
comment on column `prolongations_essai`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `prolongations_essai`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `prolongations_essai`.`date_debut` is 'Premier jour de la prolongation d''essai, inclus.';
comment on column `prolongations_essai`.`date_fin` is 'Dernier jour de la prolongation, INCLUS. La durée totale d''essai reste plafonnée par la loi et par la convention : le moteur vérifie le cumul, pas seulement cette ligne.';
comment on column `prolongations_essai`.`jours_ajoutes` is 'Jours ajoutés à l''essai du fait de la suspension.';
comment on column `prolongations_essai`.`motif` is 'Motif de la prolongation. L''essai ne se prolonge pas par convenance : il faut une cause, généralement une suspension du contrat.';
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
comment on column `ref_nature_prime`.`url_source` is 'Lien vers la convention collective qui fixe le taux et les conditions. Une prime conventionnelle sans source n''est pas vérifiable.';
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
comment on table `regles_convention` is 'Contenu d''une convention, bloc par bloc, en jsonb. C''est ce que le moteur compare à la loi pour retenir la disposition la plus favorable.';
comment on column `regles_convention`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `regles_convention`.`convention_id` is 'Convention collective visée. Le rattachement peut se faire au niveau de la société, du service ou du contrat ; fn_applicable_cbas résout les trois.';
comment on column `regles_convention`.`bloc` is 'Domaine couvert par le bloc (temps de travail, congés, préavis, rémunération...).';
comment on column `regles_convention`.`regles` is 'Clauses du bloc, structurées. Une clause absente n''est pas une clause nulle : elle est inconnue.';
comment on column `regles_convention`.`complet` is 'Faux tant que le bloc n''a pas été entièrement saisi : le moteur sait alors qu''il ne peut pas conclure sur ce domaine.';
comment on column `regles_convention`.`modifie_le` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on table `releves_effectif` is 'Effectif mensuel figé. Sert au calcul de la moyenne sur douze mois, qui déclenche les obligations de seuil (délégation, travailleurs handicapés).';
comment on column `releves_effectif`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `releves_effectif`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `releves_effectif`.`mois` is 'Premier jour du mois observé.';
comment on column `releves_effectif`.`effectif` is 'Effectif en équivalents temps plein, d''où le type décimal.';
comment on table `releves_temps` is 'Registre du temps réellement travaillé, distinct du planning. C''est lui qui fait foi pour les majorations et les heures supplémentaires.';
comment on column `releves_temps`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `releves_temps`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `releves_temps`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `releves_temps`.`date_releve` is 'Jour du relevé. Un relevé par jour et par salarié : c''est la maille de tous les compteurs.';
comment on column `releves_temps`.`heure_debut` is 'Heure de début relevée. Nulle pour un relevé saisi en durée seule, sans horaires.';
comment on column `releves_temps`.`heure_fin` is 'Heure de fin relevée. Nulle dans le même cas que start_time — les deux vont ensemble.';
comment on column `releves_temps`.`pause_minutes` is 'Pause en minutes, déduite du temps de travail effectif de la journée.';
comment on column `releves_temps`.`heures_travaillees` is 'Heures effectivement travaillées, pause déduite.';
comment on column `releves_temps`.`heures_prevues` is 'Heures planifiées pour la même journée, pour mesurer l''écart.';
comment on column `releves_temps`.`heures_dimanche` is 'Part travaillée un dimanche, qui ouvre sa propre majoration.';
comment on column `releves_temps`.`heures_ferie` is 'Part travaillée un jour férié.';
comment on column `releves_temps`.`heures_nuit` is 'Part travaillée en période de nuit.';
comment on column `releves_temps`.`heures_supplementaires` is 'Heures supplémentaires retenues sur la journée.';
comment on column `releves_temps`.`valide` is 'Vrai une fois la journée validée. Une journée non validée ne nourrit aucun calcul définitif.';
comment on column `releves_temps`.`source` is 'Origine de la saisie : pointage, saisie manuelle, report du planning.';
comment on column `releves_temps`.`note` is 'Circonstances du relevé : dépassement, incident, rattrapage. Ce qu''un contrôle voudra comprendre.';
comment on column `releves_temps`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `roles_compte` is 'Habilitations. Une ligne par couple utilisateur/périmètre ; c''est la table que lisent tous les prédicats RLS.';
comment on column `roles_compte`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `roles_compte`.`compte_id` is 'Compte auquel le rôle est attribué. Un compte peut porter plusieurs rôles ; c''est le plus permissif qui s''applique, et les politiques RLS lisent cette table, jamais une valeur transmise par le client.';
comment on column `roles_compte`.`organisation_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `roles_compte`.`societe_id` is 'Nul pour un rôle qui porte sur toute l''organisation. Renseigné pour un rôle limité à une société.';
comment on column `roles_compte`.`role` is 'Rôle applicatif. Le rôle employee restreint l''utilisateur à son propre dossier.';
comment on column `roles_compte`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `ruptures_contrat` is 'Rupture du contrat : motif, préavis, indemnités. Le moteur contrôle la licéité avant que la rupture ne soit enregistrée.';
comment on column `ruptures_contrat`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `ruptures_contrat`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `ruptures_contrat`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `ruptures_contrat`.`motif` is 'Motif de la rupture, obligatoire. Détermine le préavis, l''indemnité de départ et la possibilité de contester.';
comment on column `ruptures_contrat`.`motif_personnel` is 'Vrai pour un motif personnel, faux pour un motif économique — la distinction commande la procédure de licenciement collectif.';
comment on column `ruptures_contrat`.`notifie_le` is 'Date de notification, point de départ du préavis.';
comment on column `ruptures_contrat`.`debut_preavis` is 'Début effectif du préavis, qui suit des règles de calendrier propres.';
comment on column `ruptures_contrat`.`fin_preavis` is 'Fin du préavis.';
comment on column `ruptures_contrat`.`indemnite_mois` is 'Indemnité de départ, exprimée en mois de salaire de référence.';
comment on column `ruptures_contrat`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `ruptures_contrat`.`preavis_renonce` is 'Vrai si les parties ont convenu de dispenser le préavis.';
comment on column `ruptures_contrat`.`renonciation_convenue_le` is 'Date de l''accord de renonciation au préavis, s''il y en a un. Nulle en l''absence d''accord : le préavis court alors en entier.';
comment on column `ruptures_contrat`.`compensation_renonciation` is 'Contrepartie financière de la dispense de préavis.';
comment on column `ruptures_contrat`.`note_renonciation` is 'Contenu de l''accord de renonciation, dans les termes convenus. Une renonciation se prouve.';
comment on column `ruptures_contrat`.`faute_grave` is 'Faute grave : supprime le préavis, sous conditions strictes de procédure.';
comment on table `salaries` is 'Salarié. Les deux données les plus sensibles — matricule national et IBAN — ne sont pas stockées en clair : voir national_id_enc et iban_enc.';
comment on column `salaries`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `salaries`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `salaries`.`compte_id` is 'Compte applicatif du salarié, s''il accède à son espace personnel. Nul sinon.';
comment on column `salaries`.`service_id` is 'Service de rattachement, qui commande le planning et parfois la convention applicable.';
comment on column `salaries`.`prenom` is 'Prénom usuel du salarié. Distinct de l''état civil complet : c''est ce qui s''affiche et s''imprime.';
comment on column `salaries`.`nom` is 'Nom de famille. Sert au tri et à la recherche ; un index trigramme le rend cherchable en approximation.';
comment on column `salaries`.`date_naissance` is 'Date de naissance. Nulle tant qu''elle n''est pas connue — au stade de la candidature, par exemple. Sert au calcul des majorations liées à l''âge et au contrôle de cohérence du matricule.';
comment on column `salaries`.`residence` is 'Résident ou frontalier, et de quel pays. Détermine les pièces exigées et le traitement fiscal.';
comment on column `salaries`.`qualification` is 'Qualifié ou non qualifié : détermine le salaire social minimum applicable.';
comment on column `salaries`.`ligne` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `salaries`.`code_postal` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `salaries`.`localite` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `salaries`.`pays` is 'Code pays ISO 3166-1 alpha-3 — LUX, FRA, BEL, DEU.';
comment on column `salaries`.`courriel` is 'Adresse personnelle du salarié. Distincte de celle du compte applicatif : tous les salariés n''ont pas de compte, et l''adresse de contact survit à la fin du contrat.';
comment on column `salaries`.`telephone` is 'Téléphone de contact. Utilisé par le dispatching ; l''accès en est restreint comme toute donnée de contact personnel.';
comment on column `salaries`.`matricule_national_chiffre` is 'Matricule national CHIFFRÉ (pgcrypto). Ne jamais lire directement : fn_employee_sensitive contrôle l''accès et déchiffre.';
comment on column `salaries`.`iban_chiffre` is 'IBAN CHIFFRÉ. Même règle d''accès que le matricule.';
comment on column `salaries`.`matricule_national_indice` is 'Fragment non identifiant du matricule, affichable pour reconnaître une fiche sans exposer la donnée.';
comment on column `salaries`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `salaries`.`sexe` is 'Sexe déclaré par le salarié, librement. Modifiable par lui depuis son espace. À ne pas confondre avec sexe_legal, qui est dérivé et non déclaratif. Sera renommé sexe_declare lors du passage au français.';
comment on column `salaries`.`date_debut_carriere` is 'Début de carrière professionnelle, distinct de l''entrée dans la société. Sert à l''acquisition de la qualification par l''ancienneté.';
comment on column `salaries`.`profession` is 'Profession déclarée, distincte de l''intitulé de poste porté par le contrat.';
comment on column `salaries`.`est_cadre` is 'Vrai pour le personnel de direction, exclu de certains droits collectifs.';
comment on column `salaries`.`sexe_legal` is 'Sexe juridique, DÉRIVÉ du matricule national : parité du numéro d''ordre (position 11). Recalculé à chaque écriture — toute valeur soumise est ignorée, la dérivation fait foi. Nul tant qu''aucun matricule n''est enregistré. Le salarié y a accès (RGPD art. 15) mais ne peut pas le modifier.';
comment on column `salaries`.`refus_photos_societe` is 'Le salarié refuse d''apparaître sur les photos de la société. Consentement au sens du RGPD : révocable à tout moment, et sans justification à fournir.';
comment on column `salaries`.`souhaite_confidentialite` is 'Le salarié souhaite ne pas apparaître — annuaire, trombinoscope, communications. Distinct du droit à l''effacement, qui porte sur la donnée elle-même.';
comment on table `sanctions_salarie` is 'Sanctions disciplinaires prononcées. Donnée personnelle sensible au sens du RGPD : accès restreint aux gestionnaires et à la personne concernée, conservation bornée par retention_until, suppression logique pour que le dossier reste cohérent après effacement.';
comment on column `sanctions_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `sanctions_salarie`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `sanctions_salarie`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `sanctions_salarie`.`contrat_id` is 'Contrat concerné. Un salarié peut avoir plusieurs contrats successifs — un seul en cours à la fois — et un avenant crée un nouveau contrat chaîné au précédent. Ce qui se rattache ici vaut pour cette version-là du contrat.';
comment on column `sanctions_salarie`.`type_sanction` is 'Type de sanction prononcée, parmi sanction_types.';
comment on column `sanctions_salarie`.`faits_le` is 'Date des faits reprochés.';
comment on column `sanctions_salarie`.`faits_connus_le` is 'Date à laquelle l''employeur en a eu connaissance. C''est elle, et non la date des faits, qui fait courir le délai de notification.';
comment on column `sanctions_salarie`.`notifie_le` is 'Date de notification au salarié. Une sanction non notifiée n''existe pas à son égard.';
comment on column `sanctions_salarie`.`effet_du` is 'Premier jour d''effet, inclus. Nul pour une sanction sans effet daté, comme un avertissement.';
comment on column `sanctions_salarie`.`effet_au` is 'Dernier jour d''effet, INCLUS. Une mise à pied a une fin ; un avertissement n''en a pas.';
comment on column `sanctions_salarie`.`motif` is 'Faits reprochés, obligatoires. Une sanction sans motif écrit est contestable de ce seul fait.';
comment on column `sanctions_salarie`.`piece_justificative_id` is 'Pièce au dossier : lettre de notification, compte rendu d''entretien. Ce qui prouve que la procédure a été suivie.';
comment on column `sanctions_salarie`.`rupture_id` is 'Rupture correspondante, quand la sanction est un licenciement. Les deux lignes décrivent le même fait sous deux angles.';
comment on column `sanctions_salarie`.`contrat_avenant_id` is 'Avenant produit par la sanction, quand elle modifie le contrat — rétrogradation, mutation.';
comment on column `sanctions_salarie`.`salarie_entendu_le` is 'Date à laquelle le salarié a été entendu. L''entretien préalable est requis au-delà d''un seuil d''effectif que le moteur lit dans le référentiel.';
comment on column `sanctions_salarie`.`reponse_salarie` is 'Observations du salarié. Le droit de répondre fait partie de la procédure : la réponse se conserve, même si elle ne change pas la décision.';
comment on column `sanctions_salarie`.`conteste_le` is 'Date de contestation par le salarié. Nulle tant qu''il n''a pas contesté.';
comment on column `sanctions_salarie`.`issue_contestation` is 'Issue de la contestation : maintien, réduction, retrait. Une sanction retirée reste en base, avec son issue — l''effacer réécrirait l''histoire.';
comment on column `sanctions_salarie`.`note` is 'Suites internes : suivi, accompagnement, rappel à l''ordre ultérieur.';
comment on column `sanctions_salarie`.`conservation_jusquau` is 'Date au-delà de laquelle la sanction ne doit plus être conservée. Un dossier disciplinaire ne se garde pas indéfiniment.';
comment on column `sanctions_salarie`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `sanctions_salarie`.`cree_par` is 'Compte ayant créé la ligne. Renseigné par la couche serveur, jamais par le client — une identité déclarée par l''appelant ne prouve rien.';
comment on column `sanctions_salarie`.`modifie_le` is 'Horodatage de la dernière modification, tenu par un déclencheur. Comme created_at, c''est une donnée d''audit et non une date métier.';
comment on column `sanctions_salarie`.`modifie_par` is 'Compte auteur de la dernière modification. Sur une sanction, chaque retouche doit rester attribuable.';
comment on column `sanctions_salarie`.`supprime_le` is 'Date de suppression logique. Non nulle, la ligne est supprimée du point de vue de l''application et exclue par les politiques RLS ; elle reste en base pour que l''intégrité référentielle des écritures passées tienne. Une paie de 2024 doit pouvoir encore nommer le salarié qu''elle a payé.';
comment on column `sanctions_salarie`.`supprime_par` is 'Compte ayant prononcé la suppression logique. Une suppression est une décision : elle a un auteur, qui doit rester connu après coup.';
comment on table `secrets_application` is 'Clés de chiffrement du moteur. RLS active et VOLONTAIREMENT sans aucune politique : aucune ligne n''est donc accessible par l''API REST. Seules les fonctions security definer fn_encrypt_field et fn_decrypt_field y accèdent, et ces deux fonctions ne sont exécutables par personne hors du moteur.';
comment on column `secrets_application`.`cle` is 'Nom du secret. La table porte RLS active et VOLONTAIREMENT aucune politique : aucune ligne n''est accessible par l''API REST, seules les fonctions security definer du moteur y accèdent.';
comment on column `secrets_application`.`secret` is 'Valeur du secret. Voir la remarque sur la table : elle n''est lisible par personne à travers l''API. Un secret qui vit dans la base qu''il protège reste un compromis assumé et documenté.';
comment on table `services` is 'Service ou établissement d''une société. Porte un planning et, le cas échéant, sa propre convention collective.';
comment on column `services`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `services`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `services`.`nom` is 'Nom du service. Sert au périmètre de dispatching et à la résolution conventionnelle, qui peut se faire par service.';
comment on column `services`.`couverture_soir_min` is 'Effectif minimal exigé en soirée. Contrainte d''exploitation, vérifiée à la validation d''un planning.';
comment on table `sinistres_accident_societe` is 'Sinistralité accident déclarée par exercice. Alimente le suivi du facteur bonus-malus.';
comment on column `sinistres_accident_societe`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `sinistres_accident_societe`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `sinistres_accident_societe`.`annee` is 'Année de survenance des sinistres, pour le calcul du bonus-malus accident du travail.';
comment on column `sinistres_accident_societe`.`nombre_sinistres` is 'Nombre de sinistres déclarés.';
comment on column `sinistres_accident_societe`.`jours_perdus` is 'Journées de travail perdues sur l''exercice.';
comment on column `sinistres_accident_societe`.`cout` is 'Coût des sinistres de l''année, en euros. Entre dans la détermination de la classe de risque et donc du taux de cotisation accident.';
comment on column `sinistres_accident_societe`.`note` is 'Précisions sur les sinistres retenus ou exclus.';
comment on table `sites_client` is 'Lieu où une vacation peut s''exécuter hors du siège : chantier, site client, antenne. Porte l''adresse qui sert au calcul de distance.';
comment on column `sites_client`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `sites_client`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `sites_client`.`nom` is 'Nom du site client, tel qu''il apparaît sur les plannings et les ordres de mission.';
comment on column `sites_client`.`nom_client` is 'Nom du client donneur d''ordre, distinct du nom du site.';
comment on column `sites_client`.`ligne` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `sites_client`.`code_postal` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `sites_client`.`localite` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `sites_client`.`pays` is 'Pays du site, en code ISO 3166-1 alpha-3.';
comment on column `sites_client`.`latitude` is 'Coordonnée, si elle est connue : elle évite de transmettre une adresse en clair au service de distance.';
comment on column `sites_client`.`longitude` is 'Longitude en degrés décimaux, obtenue par géocodage. Avec la latitude, permet de calculer la distance depuis l''adresse du salarié.';
comment on column `sites_client`.`actif` is 'Faux quand le site n''est plus desservi. Le site reste en base : les plannings passés le nomment encore.';
comment on column `sites_client`.`note` is 'Consignes d''accès et contraintes du site. Lues par qui s''y rend, pas par le moteur.';
comment on column `sites_client`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `societes` is 'Société employeuse. Deuxième clé d''isolation après l''organisation : la quasi-totalité des tables métier porte un company_id.';
comment on column `societes`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `societes`.`organisation_id` is 'Fiduciaire propriétaire de la ligne. C''est la clé d''isolation : les politiques RLS la comparent à celle du demandeur, et aucune requête ne franchit cette frontière. L''isolation est imposée en base, jamais dans l''interface.';
comment on column `societes`.`raison_sociale` is 'Raison sociale, telle qu''inscrite au registre de commerce. C''est ce nom qui figure sur les contrats et les bulletins.';
comment on column `societes`.`forme_juridique` is 'Forme juridique (Sàrl, SA, etc.). Sans effet sur le moteur, utile aux documents.';
comment on column `societes`.`numero_rcs` is 'Numéro au Registre de commerce et des sociétés.';
comment on column `societes`.`matricule_ccss` is 'Matricule CCSS de l''employeur. Validé par fn_check_national_id (longueur, date encodée, clés de Luhn et de Verhoeff).';
comment on column `societes`.`ligne` is 'Rue et numéro. Une seule ligne : le découpage rue/numéro varie trop d''un pays à l''autre pour être imposé ici.';
comment on column `societes`.`code_postal` is 'Code postal de l''adresse. Confronté au référentiel des localités par fn_check_address : un code qui ne correspond pas à la localité est signalé, non corrigé d''office.';
comment on column `societes`.`localite` is 'Localité de l''adresse, telle qu''elle doit figurer sur un courrier.';
comment on column `societes`.`pays` is 'Pays du siège, en code ISO 3166-1 alpha-3. Le projet utilise partout l''alpha-3, y compris là où l''alpha-2 suffirait : un seul format évite les conversions silencieuses.';
comment on column `societes`.`code_nace` is 'Code d''activité NACE, base du rattachement sectoriel et de la classe de risque accident.';
comment on column `societes`.`secteur` is 'Secteur déclaré. Sert au rapprochement avec les conventions collectives sectorielles.';
comment on column `societes`.`periode_reference_mois` is 'Durée par défaut de la période de référence pour le calcul du temps de travail, si aucune période explicite n''est définie.';
comment on column `societes`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on column `societes`.`reglement_interieur_adopte_le` is 'Date d''adoption des textes internes de l''entreprise. Sans eux, aucune sanction lourde n''est valable — le moteur le vérifie.';
comment on column `societes`.`reference_reglement_interieur` is 'Référence et date d''adoption du règlement intérieur. Une sanction lourde n''est valable que si elle y figure : sans cette référence, le moteur le signale.';
comment on table `statuts_salarie` is 'Statuts protégés : grossesse, suites de couches, mandat de délégué. Ils conditionnent la protection contre le licenciement.';
comment on column `statuts_salarie`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `statuts_salarie`.`societe_id` is 'Société à laquelle la ligne se rattache. Porte l''isolation RLS au niveau employeur, sous celle de la fiduciaire : un gestionnaire n''accède qu''aux sociétés de son périmètre.';
comment on column `statuts_salarie`.`salarie_id` is 'Salarié concerné. La ligne suit le salarié et non son contrat : elle survit à un avenant, à un changement de société au sein du groupe, et à la fin du contrat.';
comment on column `statuts_salarie`.`genre` is 'Nature du statut, qui commande la protection applicable.';
comment on column `statuts_salarie`.`declare_le` is 'Date à laquelle l''employeur a été informé. C''est elle, et non le fait lui-même, qui déclenche la protection.';
comment on column `statuts_salarie`.`date_debut` is 'Premier jour du statut, inclus. Un statut protégé — grossesse, délégation, congé parental — ouvre des protections qui commencent ce jour-là.';
comment on column `statuts_salarie`.`date_fin` is 'Dernier jour du statut, INCLUS. Nulle tant que le statut court.';
comment on column `statuts_salarie`.`date_naissance_prevue` is 'Date présumée de l''accouchement, qui borne la période protégée.';
comment on column `statuts_salarie`.`date_naissance_reelle` is 'Date réelle, qui rectifie la borne une fois connue.';
comment on column `statuts_salarie`.`piece_justificative_id` is 'Pièce justifiant le statut : certificat, procès-verbal d''élection. Une protection invoquée sans pièce ne tient pas devant l''ITM.';
comment on column `statuts_salarie`.`credit_heures_mensuel` is 'Crédit d''heures mensuel attaché au mandat, pour les délégués.';
comment on column `statuts_salarie`.`note` is 'Précisions sur la portée du statut et sur ce qu''il interdit à l''employeur.';
comment on column `statuts_salarie`.`cree_le` is 'Horodatage de création de la ligne, posé par la base. Ce n''est pas une date métier : la date à laquelle un fait est survenu est portée par une colonne qui le nomme. Sert à l''audit et à l''ordonnancement, pas au calcul.';
comment on table `tranches_impot` is 'Barème de l''impôt sur les traitements et salaires, par classe et par périodicité. Table structurellement prête ; son chargement relève de la V2 brut vers net.';
comment on column `tranches_impot`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `tranches_impot`.`classe_impot` is 'Classe d''impôt à laquelle le barème s''applique. Le passage à la classe unique prévu pour 2027 se traduira par de nouvelles lignes datées, pas par une modification des anciennes.';
comment on column `tranches_impot`.`periodicite` is 'Périodicité du barème : mensuel, annuel. Un barème mensuel n''est pas le douzième d''un barème annuel.';
comment on column `tranches_impot`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `tranches_impot`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on column `tranches_impot`.`tranche_min` is 'Borne basse de la tranche.';
comment on column `tranches_impot`.`tranche_max` is 'Borne haute. Nul pour la dernière tranche.';
comment on column `tranches_impot`.`impot_base` is 'Impôt cumulé dû à la borne basse de la tranche.';
comment on column `tranches_impot`.`taux_au_dessus_minimum` is 'Taux appliqué à la fraction du revenu dépassant la borne basse.';
comment on column `tranches_impot`.`source` is 'Publication d''origine du barème. Sans source, un barème ne se vérifie pas — et la règle 7 du projet interdit de l''inventer.';
comment on column `tranches_impot`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `tranches_impot`.`note` is 'Précisions sur la tranche : arrondis, cas particuliers, articulation avec les crédits.';
comment on table `types_absence` is 'Catalogue des motifs d''absence : congés, maladie, congés extraordinaires, absences non rémunérées.';
comment on column `types_absence`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `types_absence`.`code` is 'Code stable du type d''absence, utilisé par le moteur et par les deux interfaces. Il ne change jamais : c''est le libellé qui se retouche, pas le code.';
comment on column `types_absence`.`libelle` is 'Libellé affiché du type d''absence, en français. Destiné à l''écran, jamais à une comparaison.';
comment on column `types_absence`.`categorie` is 'Famille d''absence, qui commande le traitement par le moteur.';
comment on column `types_absence`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `types_absence`.`certificat_exige` is 'Vrai si un justificatif est exigé pour que l''absence soit régulière.';
comment on column `types_absence`.`remunere` is 'Vrai si l''absence est rémunérée par l''employeur.';
comment on column `types_absence`.`impute_sur_conge` is 'Vrai si l''absence s''impute sur le solde de congé annuel.';
comment on table `types_avantage` is 'Catalogue des avantages en nature et de leur méthode d''évaluation.';
comment on column `types_avantage`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `types_avantage`.`code` is 'Code de l''avantage en nature, stable, utilisé par la paie.';
comment on column `types_avantage`.`libelle` is 'Libellé de l''avantage à l''écran et sur le bulletin.';
comment on column `types_avantage`.`methode_evaluation` is 'Méthode d''évaluation : forfait, pourcentage, barème.';
comment on column `types_avantage`.`imposable` is 'Vrai si l''avantage entre dans l''assiette imposable.';
comment on column `types_avantage`.`cotisable` is 'Vrai si l''avantage entre dans l''assiette cotisable.';
comment on column `types_avantage`.`parametres_evaluation` is 'Paramètres de la méthode. Les valeurs légales elles-mêmes restent dans legal_parameters.';
comment on column `types_avantage`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `types_avantage`.`note` is 'Mode d''évaluation de l''avantage et texte qui le fonde.';
comment on table `types_document` is 'Catalogue des pièces attendues d''un salarié ou d''un contrat, avec leur durée de validité et le préavis d''alerte avant échéance.';
comment on column `types_document`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `types_document`.`code` is 'Code du type de document, stable, utilisé par le moteur de conformité pour vérifier qu''une pièce obligatoire est présente.';
comment on column `types_document`.`libelle` is 'Libellé du type de document à l''écran.';
comment on column `types_document`.`echelon` is 'Moment du cycle de vie où la pièce est attendue : embauche, cours de contrat, ou fin de contrat.';
comment on column `types_document`.`validite_mois` is 'Durée de validité en mois. Nul pour une pièce qui ne périme pas.';
comment on column `types_document`.`obligatoire` is 'Vrai si l''absence de la pièce constitue un manquement, et non un simple oubli.';
comment on column `types_document`.`residences_visees` is 'Statuts de résidence concernés : une autorisation de travail ne vise pas un résident.';
comment on column `types_document`.`alerte_jours_avant` is 'Délai d''anticipation de l''alerte avant expiration.';
comment on column `types_document`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `types_document`.`note` is 'Fondement de l''obligation et durée de conservation attendue.';
comment on table `types_sanction` is 'Catalogue des sanctions applicables, daté. Chaque type porte ses effets — présence, rémunération, contrat — et ce qu''il exige de l''employeur. Le moteur lit ces drapeaux ; il ne les devine pas.';
comment on column `types_sanction`.`code` is 'Code du type de sanction, stable. Huit types répartis dans les trois catégories.';
comment on column `types_sanction`.`code_categorie` is 'Catégorie de rattachement, parmi sanction_categories. Détermine la procédure et les délais.';
comment on column `types_sanction`.`libelle` is 'Libellé du type de sanction à l''écran.';
comment on column `types_sanction`.`description` is 'Portée exacte de la sanction et conditions de validité. Une sanction lourde suppose notamment qu''elle figure dans les textes internes de l''entreprise.';
comment on column `types_sanction`.`suspend_presence` is 'Vrai si la sanction suspend la présence du salarié — mise à pied. Le planning doit alors cesser de l''affecter sur la période.';
comment on column `types_sanction`.`affecte_paie` is 'Vrai si la rémunération est suspendue ou réduite. Distingue la mise à pied disciplinaire de la conservatoire, qui maintient le salaire.';
comment on column `types_sanction`.`reglement_interieur_exige` is 'Vrai si la sanction n''est valable qu''à condition de figurer dans les textes internes de l''entreprise. C''est le cas de toutes les sanctions lourdes.';
comment on column `types_sanction`.`modifie_contrat` is 'Vrai si la sanction modifie le contrat. Elle passe alors par fn_amend_contract et, si la baisse de rémunération est substantielle, requiert l''''accord du salarié ou une procédure propre.';
comment on column `types_sanction`.`rompt_contrat` is 'Vrai si la sanction met fin au contrat. Déclenche le circuit de rupture : préavis, indemnités, documents de fin de contrat.';
comment on column `types_sanction`.`needs_notice` is 'Vrai si un préavis est dû, faux s''''il ne l''''est pas, nul si la question ne se pose pas. Le calcul du préavis lui-même reste à fn_notice_period.';
comment on column `types_sanction`.`reference_legale` is 'Référence du texte qui fonde la valeur : article du Code du travail, article de convention, arrêté. Sans elle, un chiffre ne se vérifie pas — et la règle 7 du projet interdit d''inventer une valeur légale.';
comment on column `types_sanction`.`note` is 'Références et précisions sur l''usage du type. Ce qui permet de vérifier qu''on applique la bonne sanction.';
comment on column `types_sanction`.`debut_validite` is 'Début de validité, borne basse INCLUSIVE : la ligne vaut dès ce jour. Une validité de toujours porte la date sentinelle 1970-01-01.';
comment on column `types_sanction`.`fin_validite` is 'Fin de validité, borne haute EXCLUSIVE : la ligne vaut jusqu''à la veille. Jamais nulle — une validité sans fin connue porte la date sentinelle 2037-12-31, pas NULL. Pour clore une période, y inscrire le premier jour où la ligne ne vaut plus, puis insérer la suivante à cette même date.';
comment on table `zones_adresse` is 'Zones géographiques dans lesquelles une adresse est acceptée. Hors de ces zones, la saisie est refusée : l''outil ne prétend pas couvrir des adresses qu''il ne sait pas vérifier.';
comment on column `zones_adresse`.`id` is 'Identifiant technique de la ligne. UUID et non séquence : le modèle doit pouvoir être exporté, réimporté et fusionné entre deux bases sans lien de base à base et sans collision de numéros. Aucun sens métier, jamais montré à un utilisateur, jamais utilisé comme clé de rapprochement dans un export — ce sont les clés naturelles qui servent à cela.';
comment on column `zones_adresse`.`pays` is 'Code pays ISO 3166-1 alpha-3. Trois lettres partout dans l''application.';
comment on column `zones_adresse`.`genre` is 'Nature de la zone : pays, région frontalière, plage de codes postaux. Détermine comment les bornes se lisent.';
comment on column `zones_adresse`.`code` is 'Code de la zone, repris par address_checks.zone_code et par les barèmes qui s''y réfèrent.';
comment on column `zones_adresse`.`libelle` is 'Nom lisible de la zone, pour l''affichage et les messages de contrôle.';
comment on column `zones_adresse`.`code_postal_du` is 'Borne basse du code postal, une fois le préfixe pays retiré. Nulle quand le pays n''admet pas de découpage postal fiable — voir is_verified.';
comment on column `zones_adresse`.`code_postal_au` is 'Borne haute INCLUSE de la plage de codes postaux couverte. Nulle si la zone ne se décrit pas par une plage.';
comment on column `zones_adresse`.`verifie` is 'Vrai si les bornes postales sont établies et vérifiables. Faux pour une zone déclarée sans correspondance postale fiable : la validation répond alors « indéterminé » plutôt que d''accepter à tort.';
comment on column `zones_adresse`.`source` is 'D''où viennent les bornes. Une zone sans source n''a rien à faire ici.';
comment on column `zones_adresse`.`note` is 'Origine de la délimitation : convention, accord frontalier, choix de paramétrage. Ce qui permet de la contester.';
comment on table `ref_bloc_convention` is 'Table de référence issue du type énuméré PostgreSQL bloc_convention.';
comment on table `ref_categorie_absence` is 'Table de référence issue du type énuméré PostgreSQL categorie_absence.';
comment on table `ref_classe_impot` is 'Table de référence issue du type énuméré PostgreSQL classe_impot.';
comment on table `ref_etape_document` is 'Table de référence issue du type énuméré PostgreSQL etape_document.';
comment on table `ref_etat_alerte` is 'Table de référence issue du type énuméré PostgreSQL etat_alerte.';
comment on table `ref_famille_parametre` is 'Table de référence issue du type énuméré PostgreSQL famille_parametre.';
comment on table `ref_genre_contrat` is 'Table de référence issue du type énuméré PostgreSQL genre_contrat.';
comment on table `ref_genre_element_remuneration` is 'Table de référence issue du type énuméré PostgreSQL genre_element_remuneration.';
comment on table `ref_genre_organisation` is 'Table de référence issue du type énuméré PostgreSQL genre_organisation.';
comment on table `ref_genre_qualification` is 'Table de référence issue du type énuméré PostgreSQL genre_qualification.';
comment on table `ref_genre_residence` is 'Table de référence issue du type énuméré PostgreSQL genre_residence.';
comment on table `ref_genre_severite` is 'Table de référence issue du type énuméré PostgreSQL genre_severite.';
comment on table `ref_genre_sexe` is 'Table de référence issue du type énuméré PostgreSQL genre_sexe.';
comment on table `ref_genre_statut_salarie` is 'Table de référence issue du type énuméré PostgreSQL genre_statut_salarie.';
comment on table `ref_periodicite_impot` is 'Table de référence issue du type énuméré PostgreSQL periodicite_impot.';
comment on table `ref_portee_convention` is 'Table de référence issue du type énuméré PostgreSQL portee_convention.';
comment on table `ref_role_application` is 'Table de référence issue du type énuméré PostgreSQL role_application.';
comment on table `ref_statut_absence` is 'Table de référence issue du type énuméré PostgreSQL statut_absence.';
comment on table `ref_statut_contrat` is 'Table de référence issue du type énuméré PostgreSQL statut_contrat.';
comment on table `ref_statut_planning` is 'Table de référence issue du type énuméré PostgreSQL statut_planning.';

-- CONTRAINTES D'EXCLUSION — sans équivalent hors PostgreSQL.
--
-- Elles interdisent le recouvrement de deux périodes de validité. C'est ce
-- qui garantit qu'un paramètre légal n'a qu'une valeur à une date donnée ;
-- sans elles, un calcul de paie peut lire deux taux pour le même jour.
-- Un déclencheur les remplace ci-dessous, table par table.

delimiter $$
create trigger adresses_salarie_no_overlap_insert after insert on `adresses_salarie`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `adresses_salarie` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id` and new.`type_adresse` <=> b.`type_adresse`
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
       and new.`salarie_id` <=> b.`salarie_id` and new.`type_adresse` <=> b.`type_adresse`
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
create trigger attributions_titres_repa_no_overlap_insert after insert on `attributions_titres_repas`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `attributions_titres_repas` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_periode` < ifnull(b.`fin_periode`, '9999-12-31')
       and ifnull(new.`fin_periode`, '9999-12-31') > b.`debut_periode`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur attributions_titres_repas';
  end if;
end$$
create trigger attributions_titres_repa_no_overlap_update after update on `attributions_titres_repas`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `attributions_titres_repas` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_periode` < ifnull(b.`fin_periode`, '9999-12-31')
       and ifnull(new.`fin_periode`, '9999-12-31') > b.`debut_periode`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur attributions_titres_repas';
  end if;
end$$
delimiter ;

delimiter $$
create trigger contrats_no_overlap_insert after insert on `contrats`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `contrats` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`date_debut` < ifnull(b.`date_fin`, '9999-12-31')
       and ifnull(new.`date_fin`, '9999-12-31') > b.`date_debut`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur contrats';
  end if;
end$$
create trigger contrats_no_overlap_update after update on `contrats`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `contrats` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`date_debut` < ifnull(b.`date_fin`, '9999-12-31')
       and ifnull(new.`date_fin`, '9999-12-31') > b.`date_debut`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur contrats';
  end if;
end$$
delimiter ;

delimiter $$
create trigger droits_absence_no_overlap_insert after insert on `droits_absence`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `droits_absence` b
     where b.`id` <> new.`id`
       and new.`type_absence_id` <=> b.`type_absence_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur droits_absence';
  end if;
end$$
create trigger droits_absence_no_overlap_update after update on `droits_absence`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `droits_absence` b
     where b.`id` <> new.`id`
       and new.`type_absence_id` <=> b.`type_absence_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur droits_absence';
  end if;
end$$
delimiter ;

delimiter $$
create trigger fiches_retenue_impot_no_overlap_insert after insert on `fiches_retenue_impot`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `fiches_retenue_impot` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur fiches_retenue_impot';
  end if;
end$$
create trigger fiches_retenue_impot_no_overlap_update after update on `fiches_retenue_impot`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `fiches_retenue_impot` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur fiches_retenue_impot';
  end if;
end$$
delimiter ;

delimiter $$
create trigger handicaps_salarie_no_overlap_insert after insert on `handicaps_salarie`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `handicaps_salarie` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur handicaps_salarie';
  end if;
end$$
create trigger handicaps_salarie_no_overlap_update after update on `handicaps_salarie`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `handicaps_salarie` b
     where b.`id` <> new.`id`
       and new.`salarie_id` <=> b.`salarie_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur handicaps_salarie';
  end if;
end$$
delimiter ;

delimiter $$
create trigger parametres_legaux_no_overlap_insert after insert on `parametres_legaux`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `parametres_legaux` b
     where b.`id` <> new.`id`
       and new.`cle_parametre` <=> b.`cle_parametre`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur parametres_legaux';
  end if;
end$$
create trigger parametres_legaux_no_overlap_update after update on `parametres_legaux`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `parametres_legaux` b
     where b.`id` <> new.`id`
       and new.`cle_parametre` <=> b.`cle_parametre`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur parametres_legaux';
  end if;
end$$
delimiter ;

delimiter $$
create trigger periodes_taux_societe_no_overlap_insert after insert on `periodes_taux_societe`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `periodes_taux_societe` b
     where b.`id` <> new.`id`
       and new.`societe_id` <=> b.`societe_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur periodes_taux_societe';
  end if;
end$$
create trigger periodes_taux_societe_no_overlap_update after update on `periodes_taux_societe`
for each row begin
  declare v_conflit int;
  select exists (
    select 1
      from `periodes_taux_societe` b
     where b.`id` <> new.`id`
       and new.`societe_id` <=> b.`societe_id`
       and new.`debut_validite` < ifnull(b.`fin_validite`, '9999-12-31')
       and ifnull(new.`fin_validite`, '9999-12-31') > b.`debut_validite`
  ) into v_conflit;
  if v_conflit then
    signal sqlstate '45000'
      set message_text = 'Deux periodes se recouvrent sur periodes_taux_societe';
  end if;
end$$
delimiter ;


