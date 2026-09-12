-- 47 — Commentaires sur les tables et les colonnes
--
-- Le schéma se documente lui-même : `\d+` sous psql, l'explorateur Supabase et
-- tout générateur de schéma lisent ces commentaires. Une seule table en portait un
-- avant cette migration (`employee_children`), plus `app_secrets` ajoutée en 45.
--
-- Règle de rédaction : on dit ce que la colonne *signifie* et d'où elle vient, pas
-- ce que son type dit déjà. Aucune valeur légale n'est citée en dur — les seuils
-- vivent dans `legal_parameters`, datés et sourcés.

-- ===========================================================================
-- Organisation, accès, traçabilité
-- ===========================================================================

comment on table organizations is $c$Fiduciaire ou entreprise unique. Racine de l'isolation : toute donnée appartient, directement ou par sa société, à une organisation.$c$;
comment on column organizations.kind is $c$Distingue une fiduciaire gérant plusieurs sociétés clientes d'une entreprise gérant la sienne.$c$;
comment on column organizations.name is $c$Raison sociale de la fiduciaire ou de l'entreprise.$c$;

comment on table profiles is $c$Compte utilisateur applicatif, en miroir de auth.users. Alimenté par le déclencheur handle_new_user à l'inscription.$c$;
comment on column profiles.id is $c$Identique à auth.users.id : le profil ne porte pas d'identité propre.$c$;
comment on column profiles.is_org_admin is $c$Administrateur de l'organisation : seul habilité à charger un référentiel et à exporter la fiduciaire entière.$c$;
comment on column profiles.email is $c$Recopié depuis auth.users pour l'affichage. L'authentification ne s'appuie jamais sur cette copie.$c$;

comment on table user_roles is $c$Habilitations. Une ligne par couple utilisateur/périmètre ; c'est la table que lisent tous les prédicats RLS.$c$;
comment on column user_roles.company_id is $c$Nul pour un rôle qui porte sur toute l'organisation. Renseigné pour un rôle limité à une société.$c$;
comment on column user_roles.role is $c$Rôle applicatif. Le rôle employee restreint l'utilisateur à son propre dossier.$c$;

comment on table companies is $c$Société employeuse. Deuxième clé d'isolation après l'organisation : la quasi-totalité des tables métier porte un company_id.$c$;
comment on column companies.ccss_matricule is $c$Matricule CCSS de l'employeur. Validé par fn_check_national_id (longueur, date encodée, clés de Luhn et de Verhoeff).$c$;
comment on column companies.rcs_number is $c$Numéro au Registre de commerce et des sociétés.$c$;
comment on column companies.nace_code is $c$Code d'activité NACE, base du rattachement sectoriel et de la classe de risque accident.$c$;
comment on column companies.legal_form is $c$Forme juridique (Sàrl, SA, etc.). Sans effet sur le moteur, utile aux documents.$c$;
comment on column companies.reference_period_months is $c$Durée par défaut de la période de référence pour le calcul du temps de travail, si aucune période explicite n'est définie.$c$;
comment on column companies.sector is $c$Secteur déclaré. Sert au rapprochement avec les conventions collectives sectorielles.$c$;

comment on table departments is $c$Service ou établissement d'une société. Porte un planning et, le cas échéant, sa propre convention collective.$c$;
comment on column departments.min_evening_coverage is $c$Effectif minimal exigé en soirée. Contrainte d'exploitation, vérifiée à la validation d'un planning.$c$;

comment on table audit_log is $c$Journal des écritures, alimenté par le déclencheur fn_audit. Conservé pour la traçabilité et la preuve, jamais modifié par l'application.$c$;
comment on column audit_log.actor_label is $c$Nom de l'auteur figé au moment du fait : le journal reste lisible après suppression du compte.$c$;
comment on column audit_log.old_value is $c$État de la ligne avant écriture, en jsonb. Nul pour une insertion.$c$;
comment on column audit_log.new_value is $c$État de la ligne après écriture. Nul pour une suppression.$c$;
comment on column audit_log.entity_table is $c$Nom de la table concernée : le journal est polymorphe, sans clé étrangère.$c$;

comment on table export_log is $c$Registre des exports de portabilité. Trace qui a exporté quoi, quand, et pour quel volume — pièce de conformité au droit d'accès et à la portabilité (RGPD art. 15 et 20).$c$;
comment on column export_log.subject_kind is $c$Nature du sujet exporté : self, employee, company, organization ou referential.$c$;
comment on column export_log.row_count is $c$Nombre d'objets contenus dans l'export, à des fins de contrôle de volume.$c$;
comment on column export_log.byte_size is $c$Taille de l'enveloppe produite, en octets.$c$;

-- ===========================================================================
-- Référentiel légal daté
-- ===========================================================================

comment on table legal_parameters is $c$Le référentiel. Tout seuil, taux ou durée légale du droit du travail luxembourgeois vit ici, jamais dans le code. Chaque valeur porte sa plage de validité, sa source et son article ; une contrainte d'exclusion GiST interdit deux versions qui se chevauchent pour une même clé.$c$;
comment on column legal_parameters.param_key is $c$Clé stable du paramètre. C'est elle que le moteur interroge, jamais l'identifiant technique.$c$;
comment on column legal_parameters.family is $c$Famille du paramètre : elle regroupe les clés par domaine et guide la détection des trous du référentiel.$c$;
comment on column legal_parameters.valid_from is $c$Premier jour d'application. Un calcul lit la version en vigueur à la date du calcul, pas la dernière connue.$c$;
comment on column legal_parameters.valid_to is $c$Dernier jour d'application, exclu. Nul tant que la version est en vigueur.$c$;
comment on column legal_parameters.source is $c$Origine publique de la valeur (Mémorial, STATEC, CCSS...). Obligatoire : un paramètre sans source ne doit pas exister.$c$;
comment on column legal_parameters.legal_ref is $c$Article du Code du travail ou du texte qui fonde la valeur. C'est lui que les alertes citent à l'utilisateur.$c$;
comment on column legal_parameters.index_ref is $c$Cote d'application de l'indice des prix au moment de la valeur, pour les montants indexés.$c$;
comment on column legal_parameters.value_num is $c$Valeur numérique. Une seule des trois colonnes value_* est renseignée.$c$;
comment on column legal_parameters.value_text is $c$Valeur textuelle, pour un paramètre qui n'est pas un nombre.$c$;
comment on column legal_parameters.value_json is $c$Valeur structurée, pour un barème ou une table à plusieurs entrées.$c$;
comment on column legal_parameters.derived_from_key is $c$Clé du paramètre dont celui-ci se déduit. La dérivation sert de contrôle de cohérence, pas de source.$c$;
comment on column legal_parameters.derived_factor is $c$Facteur appliqué au paramètre d'origine pour obtenir celui-ci.$c$;
comment on column legal_parameters.derivation_tolerance is $c$Écart admis entre la valeur saisie et la valeur dérivée avant signalement d'une incohérence.$c$;
comment on column legal_parameters.entered_by is $c$Auteur de la saisie.$c$;
comment on column legal_parameters.validated_by is $c$Relecteur ayant validé la version. Nul tant que la valeur n'a pas été contrôlée.$c$;
comment on column legal_parameters.unit is $c$Unité de la valeur (EUR, heures, jours, pourcentage...) — sans elle un nombre ne veut rien dire.$c$;

comment on table collective_agreements is $c$Convention collective de travail. Sectorielle et partagée, ou propre à une organisation.$c$;
comment on column collective_agreements.scope is $c$Portée : sectorielle, d'entreprise, ou d'établissement.$c$;
comment on column collective_agreements.organization_id is $c$Nul pour une convention sectorielle partagée par toutes les organisations.$c$;
comment on column collective_agreements.supersedes_id is $c$Convention que celle-ci remplace, pour suivre les renouvellements.$c$;
comment on column collective_agreements.employee_category is $c$Catégorie de personnel visée lorsque la convention ne couvre pas tout l'effectif.$c$;
comment on column collective_agreements.code is $c$Code court, clé naturelle utilisée par l'export et l'import du référentiel.$c$;

comment on table cba_rules is $c$Contenu d'une convention, bloc par bloc, en jsonb. C'est ce que le moteur compare à la loi pour retenir la disposition la plus favorable.$c$;
comment on column cba_rules.block is $c$Domaine couvert par le bloc (temps de travail, congés, préavis, rémunération...).$c$;
comment on column cba_rules.is_complete is $c$Faux tant que le bloc n'a pas été entièrement saisi : le moteur sait alors qu'il ne peut pas conclure sur ce domaine.$c$;
comment on column cba_rules.rules is $c$Clauses du bloc, structurées. Une clause absente n'est pas une clause nulle : elle est inconnue.$c$;

comment on table cba_salary_grids is $c$Grille de salaires conventionnelle : montant minimal par catégorie et par ancienneté.$c$;
comment on column cba_salary_grids.seniority_from_years is $c$Ancienneté à partir de laquelle l'échelon s'applique.$c$;
comment on column cba_salary_grids.seniority_to_years is $c$Ancienneté au-delà de laquelle l'échelon cesse. Nul pour le dernier échelon.$c$;
comment on column cba_salary_grids.index_ref is $c$Cote d'indice à laquelle le montant est exprimé, pour le réindexer correctement.$c$;

comment on table absence_types is $c$Catalogue des motifs d'absence : congés, maladie, congés extraordinaires, absences non rémunérées.$c$;
comment on column absence_types.counts_against_leave is $c$Vrai si l'absence s'impute sur le solde de congé annuel.$c$;
comment on column absence_types.requires_certificate is $c$Vrai si un justificatif est exigé pour que l'absence soit régulière.$c$;
comment on column absence_types.is_paid is $c$Vrai si l'absence est rémunérée par l'employeur.$c$;
comment on column absence_types.category is $c$Famille d'absence, qui commande le traitement par le moteur.$c$;

comment on table absence_entitlements is $c$Droit ouvert par motif d'absence, daté. Un congé extraordinaire dont la durée change au fil des réformes porte ici plusieurs versions successives.$c$;
comment on column absence_entitlements.days is $c$Nombre de jours ouverts par événement.$c$;
comment on column absence_entitlements.career_cap_days is $c$Plafond sur toute la carrière, lorsque le droit n'est pas renouvelable indéfiniment.$c$;
comment on column absence_entitlements.block_days is $c$Durée du bloc indivisible lorsque le droit doit être pris d'un seul tenant.$c$;
comment on column absence_entitlements.period_months is $c$Fenêtre glissante sur laquelle le droit se reconstitue.$c$;
comment on column absence_entitlements.relationship_degree is $c$Degré de parenté exigé, pour les congés liés à un événement familial.$c$;
comment on column absence_entitlements.frequency_note is $c$Condition de renouvellement exprimée en clair quand elle ne se réduit pas à un nombre.$c$;
comment on column absence_entitlements.requires_evidence is $c$Vrai si un justificatif conditionne l'ouverture du droit.$c$;

comment on table document_types is $c$Catalogue des pièces attendues d'un salarié ou d'un contrat, avec leur durée de validité et le préavis d'alerte avant échéance.$c$;
comment on column document_types.stage is $c$Moment du cycle de vie où la pièce est attendue : embauche, cours de contrat, ou fin de contrat.$c$;
comment on column document_types.validity_months is $c$Durée de validité en mois. Nul pour une pièce qui ne périme pas.$c$;
comment on column document_types.applies_to_residency is $c$Statuts de résidence concernés : une autorisation de travail ne vise pas un résident.$c$;
comment on column document_types.alert_days_before is $c$Délai d'anticipation de l'alerte avant expiration.$c$;
comment on column document_types.is_mandatory is $c$Vrai si l'absence de la pièce constitue un manquement, et non un simple oubli.$c$;

comment on table benefit_types is $c$Catalogue des avantages en nature et de leur méthode d'évaluation.$c$;
comment on column benefit_types.valuation_method is $c$Méthode d'évaluation : forfait, pourcentage, barème.$c$;
comment on column benefit_types.valuation_params is $c$Paramètres de la méthode. Les valeurs légales elles-mêmes restent dans legal_parameters.$c$;
comment on column benefit_types.is_taxable is $c$Vrai si l'avantage entre dans l'assiette imposable.$c$;
comment on column benefit_types.is_contributory is $c$Vrai si l'avantage entre dans l'assiette cotisable.$c$;

comment on table public_holidays is $c$Jours fériés légaux d'une année, complétés le cas échéant par les jours conventionnels.$c$;
comment on column public_holidays.is_mobile is $c$Vrai pour un férié dont la date suit le calendrier pascal, calculé par fn_easter_sunday.$c$;
comment on column public_holidays.collective_agreement_id is $c$Renseigné pour un jour chômé d'origine conventionnelle, nul pour un férié légal.$c$;
comment on column public_holidays.is_recoverable is $c$Vrai si le férié tombant un jour non ouvré ouvre droit à récupération.$c$;
comment on column public_holidays.recovery_reason is $c$Motif de la récupération, cité dans l'alerte.$c$;

comment on table tax_brackets is $c$Barème de l'impôt sur les traitements et salaires, par classe et par périodicité. Table structurellement prête ; son chargement relève de la V2 brut vers net.$c$;
comment on column tax_brackets.bracket_min is $c$Borne basse de la tranche.$c$;
comment on column tax_brackets.bracket_max is $c$Borne haute. Nul pour la dernière tranche.$c$;
comment on column tax_brackets.base_tax is $c$Impôt cumulé dû à la borne basse de la tranche.$c$;
comment on column tax_brackets.rate_over_min is $c$Taux appliqué à la fraction du revenu dépassant la borne basse.$c$;

comment on table tax_credits is $c$Crédits d'impôt, avec leur plage de revenu et les classes auxquelles ils s'appliquent.$c$;
comment on column tax_credits.prorated_on_hours is $c$Vrai si le crédit se réduit au prorata du temps de travail.$c$;
comment on column tax_credits.applies_to_classes is $c$Classes d'impôt ouvrant droit au crédit.$c$;
comment on column tax_credits.income_min is $c$Revenu à partir duquel le crédit est ouvert.$c$;
comment on column tax_credits.income_max is $c$Revenu au-delà duquel le crédit s'éteint.$c$;

-- ===========================================================================
-- Rattachements et données propres à la société
-- ===========================================================================

comment on table company_collective_agreements is $c$Rattachement d'une société, ou d'un de ses services, à une convention collective, sur une période donnée. Une société peut en appliquer plusieurs simultanément.$c$;
comment on column company_collective_agreements.department_id is $c$Nul si la convention couvre toute la société.$c$;

comment on table company_rate_periods is $c$Historique des taux propres à la société : classe de mutualité, facteur accident, classe d'activité. Un recalcul lit le taux en vigueur à la date du calcul.$c$;
comment on column company_rate_periods.mutuality_class is $c$Classe de la Mutualité des employeurs, qui commande le taux de cotisation.$c$;
comment on column company_rate_periods.accident_factor is $c$Facteur bonus-malus de l'assurance accident.$c$;
comment on column company_rate_periods.accident_risk_class is $c$Classe de risque accident attribuée à la société.$c$;
comment on column company_rate_periods.activity_class is $c$Classe d'activité déclarée à la CCSS.$c$;
comment on column company_rate_periods.source is $c$Origine du taux : courrier CCSS, décision de classement. Obligatoire.$c$;

comment on table company_financials is $c$Résultats annuels de la société. Sert au calcul de l'enveloppe des primes participatives, plafonnée sur le bénéfice de l'exercice précédent.$c$;
comment on column company_financials.profit is $c$Bénéfice de l'exercice, assiette du plafond d'enveloppe.$c$;
comment on column company_financials.source is $c$Origine du chiffre : comptes annuels, situation intermédiaire.$c$;

comment on table company_accident_claims is $c$Sinistralité accident déclarée par exercice. Alimente le suivi du facteur bonus-malus.$c$;
comment on column company_accident_claims.days_lost is $c$Journées de travail perdues sur l'exercice.$c$;
comment on column company_accident_claims.claim_count is $c$Nombre de sinistres déclarés.$c$;

comment on table interim_agencies is $c$Agence de travail intérimaire, employeur juridique d'un salarié en mission chez une société utilisatrice.$c$;

comment on table headcount_snapshots is $c$Effectif mensuel figé. Sert au calcul de la moyenne sur douze mois, qui déclenche les obligations de seuil (délégation, travailleurs handicapés).$c$;
comment on column headcount_snapshots.headcount is $c$Effectif en équivalents temps plein, d'où le type décimal.$c$;
comment on column headcount_snapshots.month is $c$Premier jour du mois observé.$c$;

comment on table reference_periods is $c$Période de référence sur laquelle la durée de travail se calcule en moyenne. Définie par société ou par service.$c$;
comment on column reference_periods.months is $c$Longueur de la période. Une période plus longue qu'un mois suppose un fondement conventionnel.$c$;

-- ===========================================================================
-- Salariés
-- ===========================================================================

comment on table employees is $c$Salarié. Les deux données les plus sensibles — matricule national et IBAN — ne sont pas stockées en clair : voir national_id_enc et iban_enc.$c$;
comment on column employees.user_id is $c$Compte applicatif du salarié, s'il accède à son espace personnel. Nul sinon.$c$;
comment on column employees.national_id_enc is $c$Matricule national CHIFFRÉ (pgcrypto). Ne jamais lire directement : fn_employee_sensitive contrôle l'accès et déchiffre.$c$;
comment on column employees.iban_enc is $c$IBAN CHIFFRÉ. Même règle d'accès que le matricule.$c$;
comment on column employees.national_id_hint is $c$Fragment non identifiant du matricule, affichable pour reconnaître une fiche sans exposer la donnée.$c$;
comment on column employees.residency is $c$Résident ou frontalier, et de quel pays. Détermine les pièces exigées et le traitement fiscal.$c$;
comment on column employees.qualification is $c$Qualifié ou non qualifié : détermine le salaire social minimum applicable.$c$;
comment on column employees.career_start_date is $c$Début de carrière professionnelle, distinct de l'entrée dans la société. Sert à l'acquisition de la qualification par l'ancienneté.$c$;
comment on column employees.is_management is $c$Vrai pour le personnel de direction, exclu de certains droits collectifs.$c$;
comment on column employees.sex is $c$Sexe déclaré. Utilisé pour la validation du matricule national, qui l'encode.$c$;
comment on column employees.profession is $c$Profession déclarée, distincte de l'intitulé de poste porté par le contrat.$c$;
comment on column employees.department_id is $c$Service de rattachement, qui commande le planning et parfois la convention applicable.$c$;

comment on table employee_children is $c$Enfants du salarié. Données de catégorie familiale, collectées pour les droits qui en dépendent ; le salarié peut refuser leur usage — voir privacy_opt_out.$c$;
comment on column employee_children.privacy_opt_out is $c$Vrai si le salarié refuse que l'enfant soit pris en compte. Le moteur cesse alors d'en tirer un droit, sans effacer la ligne.$c$;
comment on column employee_children.is_dependent is $c$Vrai si l'enfant est à charge au sens des droits ouverts.$c$;
comment on column employee_children.relationship is $c$Lien : enfant, enfant adopté, enfant du conjoint.$c$;
comment on column employee_children.adoption_date is $c$Date de l'adoption, qui ouvre ses propres droits, distincts de ceux liés à la naissance.$c$;

comment on table employee_disabilities is $c$Reconnaissance de travailleur handicapé. Donnée de santé au sens du RGPD : accès restreint et finalité limitée aux droits qui en découlent.$c$;
comment on column employee_disabilities.rate_pct is $c$Taux d'incapacité reconnu.$c$;
comment on column employee_disabilities.recognized_on is $c$Date de la décision de reconnaissance.$c$;
comment on column employee_disabilities.authority is $c$Autorité ayant prononcé la reconnaissance.$c$;
comment on column employee_disabilities.extra_leave_days_override is $c$Jours de congé supplémentaires imposés par la décision, lorsqu'ils diffèrent du droit commun.$c$;
comment on column employee_disabilities.evidence_document_id is $c$Pièce justificative, rangée dans documents avec le drapeau is_sensitive.$c$;

comment on table employee_statuses is $c$Statuts protégés : grossesse, suites de couches, mandat de délégué. Ils conditionnent la protection contre le licenciement.$c$;
comment on column employee_statuses.kind is $c$Nature du statut, qui commande la protection applicable.$c$;
comment on column employee_statuses.declared_on is $c$Date à laquelle l'employeur a été informé. C'est elle, et non le fait lui-même, qui déclenche la protection.$c$;
comment on column employee_statuses.expected_birth_date is $c$Date présumée de l'accouchement, qui borne la période protégée.$c$;
comment on column employee_statuses.actual_birth_date is $c$Date réelle, qui rectifie la borne une fois connue.$c$;
comment on column employee_statuses.hours_credit_monthly is $c$Crédit d'heures mensuel attaché au mandat, pour les délégués.$c$;

comment on table employee_tax_cards is $c$Fiche de retenue d'impôt du salarié, datée. Donnée d'entrée du calcul brut vers net.$c$;
comment on column employee_tax_cards.tax_class is $c$Classe d'impôt portée par la fiche.$c$;
comment on column employee_tax_cards.rate is $c$Taux de retenue inscrit sur la fiche, lorsqu'un taux est fixé plutôt qu'un barème.$c$;
comment on column employee_tax_cards.monthly_allowance is $c$Abattement mensuel inscrit sur la fiche.$c$;
comment on column employee_tax_cards.credits is $c$Crédits d'impôt portés par la fiche, structurés.$c$;
comment on column employee_tax_cards.commute_distance_km is $c$Distance domicile-travail déclarée, base de l'abattement kilométrique.$c$;
comment on column employee_tax_cards.card_reference is $c$Référence de la fiche délivrée par l'administration.$c$;
comment on column employee_tax_cards.professional_expenses_monthly is $c$Frais professionnels mensuels retenus.$c$;
comment on column employee_tax_cards.other_deductions_monthly is $c$Autres déductions mensuelles portées par la fiche.$c$;

-- ===========================================================================
-- Contrats
-- ===========================================================================

comment on table contracts is $c$Contrat de travail. Le brouillon vit ici dès la première étape de l'assistant : c'est cette ligne que le moteur évalue, pas un objet en mémoire du navigateur.$c$;
comment on column contracts.kind is $c$Type de contrat : CDI, CDD, apprentissage, saisonnier, intérim, étudiant. Commande les clauses obligatoires et les contrôles.$c$;
comment on column contracts.status is $c$Brouillon, actif, terminé. Un brouillon n'engage rien mais se contrôle déjà.$c$;
comment on column contracts.cdd_reason is $c$Motif de recours au CDD. Un CDD sans motif licite est requalifiable.$c$;
comment on column contracts.renewal_count is $c$Nombre de renouvellements déjà consommés, borné par la loi.$c$;
comment on column contracts.previous_contract_id is $c$Contrat que celui-ci renouvelle, pour reconstituer la chaîne et l'ancienneté.$c$;
comment on column contracts.monthly_gross is $c$Salaire mensuel brut convenu, hors éléments variables portés par contract_pay_components.$c$;
comment on column contracts.index_ref is $c$Cote d'indice à la signature, pour distinguer une hausse réelle d'une indexation.$c$;
comment on column contracts.weekly_hours is $c$Durée hebdomadaire convenue. Sous le plein temps, is_part_time devient vrai.$c$;
comment on column contracts.is_part_time is $c$Temps partiel, tenu à jour par le déclencheur fn_sync_part_time — ne pas écrire à la main.$c$;
comment on column contracts.days_per_week is $c$Nombre de jours travaillés par semaine, décimal pour les rythmes irréguliers.$c$;
comment on column contracts.work_distribution is $c$Répartition convenue de l'horaire. Mention obligatoire au contrat pour un temps partiel.$c$;
comment on column contracts.reference_period_months is $c$Période de référence propre au contrat, si elle déroge à celle de la société.$c$;
comment on column contracts.night_work is $c$Vrai si le poste comporte du travail de nuit, qui ouvre ses propres protections.$c$;
comment on column contracts.annual_leave_days is $c$Congé annuel convenu lorsqu'il dépasse le minimum légal. Nul renvoie au droit commun.$c$;
comment on column contracts.break_minutes is $c$Pause convenue par journée de travail.$c$;
comment on column contracts.non_compete_clause is $c$Présence d'une clause de non-concurrence, dont la validité est soumise à conditions.$c$;
comment on column contracts.exclusivity_clause is $c$Présence d'une clause d'exclusivité.$c$;
comment on column contracts.probation_length is $c$Durée de la période d'essai, exprimée dans l'unité portée par probation_unit.$c$;
comment on column contracts.probation_unit is $c$Unité de la période d'essai : mois ou semaines. Les bornes légales diffèrent selon l'unité.$c$;
comment on column contracts.version is $c$Version du contrat, incrémentée par les avenants.$c$;
comment on column contracts.signed_at is $c$Date de signature. Un contrat actif sans date de signature est un manquement.$c$;
comment on column contracts.apprenticeship_level is $c$Niveau de la formation, pour un contrat d'apprentissage.$c$;
comment on column contracts.apprenticeship_year is $c$Année du cycle d'apprentissage, qui commande l'indemnité.$c$;
comment on column contracts.season_label is $c$Saison couverte, pour un contrat saisonnier.$c$;
comment on column contracts.interim_agency_id is $c$Agence d'intérim employeuse, pour un contrat de mission.$c$;
comment on column contracts.user_company_name is $c$Société utilisatrice chez qui la mission s'exécute.$c$;
comment on column contracts.mission_reason is $c$Motif de recours à l'intérim, soumis aux mêmes exigences que le motif de CDD.$c$;
comment on column contracts.category is $c$Catégorie professionnelle, clé d'entrée dans la grille salariale conventionnelle.$c$;
comment on column contracts.work_place is $c$Lieu d'exécution convenu. Mention obligatoire au contrat.$c$;

comment on table contract_amendments is $c$Avenant. Conserve ce qui a changé et à partir de quand, sans écraser l'état antérieur du contrat.$c$;
comment on column contract_amendments.changes is $c$Différentiel appliqué, en jsonb : ce que l'avenant modifie, et rien d'autre.$c$;
comment on column contract_amendments.effective_date is $c$Prise d'effet, qui peut différer de la signature.$c$;

comment on table contract_collective_agreements is $c$Conventions applicables à un contrat donné, sur une période. Plusieurs conventions peuvent se cumuler ; le moteur retient la disposition la plus favorable et dit laquelle a gagné.$c$;

comment on table contract_pay_components is $c$Éléments de rémunération autres que le brut de base : primes récurrentes, avantages, indemnités.$c$;
comment on column contract_pay_components.kind is $c$Nature de l'élément, qui commande son traitement fiscal et social.$c$;
comment on column contract_pay_components.in_salary_reference is $c$Vrai si l'élément entre dans le salaire de référence servant au calcul des indemnités.$c$;
comment on column contract_pay_components.rate_pct is $c$Taux, pour un élément exprimé en pourcentage plutôt qu'en montant.$c$;
comment on column contract_pay_components.basis is $c$Assiette à laquelle le taux s'applique.$c$;
comment on column contract_pay_components.periodicity is $c$Périodicité de versement.$c$;
comment on column contract_pay_components.benefit_type_id is $c$Avantage en nature du catalogue, lorsque l'élément en est un.$c$;

comment on table contract_terminations is $c$Rupture du contrat : motif, préavis, indemnités. Le moteur contrôle la licéité avant que la rupture ne soit enregistrée.$c$;
comment on column contract_terminations.is_personal_ground is $c$Vrai pour un motif personnel, faux pour un motif économique — la distinction commande la procédure de licenciement collectif.$c$;
comment on column contract_terminations.is_gross_misconduct is $c$Faute grave : supprime le préavis, sous conditions strictes de procédure.$c$;
comment on column contract_terminations.notified_on is $c$Date de notification, point de départ du préavis.$c$;
comment on column contract_terminations.notice_start is $c$Début effectif du préavis, qui suit des règles de calendrier propres.$c$;
comment on column contract_terminations.notice_end is $c$Fin du préavis.$c$;
comment on column contract_terminations.severance_months is $c$Indemnité de départ, exprimée en mois de salaire de référence.$c$;
comment on column contract_terminations.notice_waived is $c$Vrai si les parties ont convenu de dispenser le préavis.$c$;
comment on column contract_terminations.waiver_compensation is $c$Contrepartie financière de la dispense de préavis.$c$;

comment on table probation_extensions is $c$Prolongation d'une période d'essai, suspendue par une absence. Trace la durée ajoutée et son motif.$c$;
comment on column probation_extensions.days_added is $c$Jours ajoutés à l'essai du fait de la suspension.$c$;

comment on table premiums is $c$Primes versées, dont les primes participatives soumises à un double plafond : enveloppe société et plafond individuel.$c$;
comment on column premiums.exempt_pct is $c$Fraction exonérée de la prime, selon son régime.$c$;
comment on column premiums.fiscal_year is $c$Exercice d'imputation, qui détermine l'enveloppe et les plafonds applicables.$c$;
comment on column premiums.termination_id is $c$Rupture à laquelle la prime se rattache, pour une indemnité de départ.$c$;
comment on column premiums.granted_on is $c$Date d'attribution.$c$;

comment on table meal_voucher_grants is $c$Attribution de chèques-repas sur une période. La valeur faciale et la participation salariale sont contrôlées contre les limites du référentiel.$c$;
comment on column meal_voucher_grants.face_value is $c$Valeur faciale du chèque.$c$;
comment on column meal_voucher_grants.employee_share is $c$Part supportée par le salarié : c'est elle qui conditionne le régime fiscal de l'avantage.$c$;
comment on column meal_voucher_grants.voucher_count is $c$Nombre de chèques attribués sur la période.$c$;

-- ===========================================================================
-- Temps de travail
-- ===========================================================================

comment on table schedules is $c$Planning hebdomadaire d'une société ou d'un service. Tant qu'il n'est pas publié, il n'est opposable à personne.$c$;
comment on column schedules.week_start is $c$Lundi de la semaine couverte.$c$;
comment on column schedules.status is $c$Brouillon ou publié. La publication passe par fn_publish_schedule, qui refuse un planning non conforme.$c$;
comment on column schedules.published_at is $c$Horodatage de la publication, qui fait courir le délai de prévenance.$c$;
comment on column schedules.published_by is $c$Auteur de la publication.$c$;

comment on table shift_templates is $c$Modèle de vacation réutilisable, pour éviter de ressaisir les horaires courants.$c$;
comment on column shift_templates.color is $c$Couleur d'affichage dans le planning. Confort d'usage, sans effet métier.$c$;

comment on table shifts is $c$Vacation planifiée : un salarié, une date, des horaires. C'est l'unité que le moteur contrôle contre les repos et les durées maximales.$c$;
comment on column shifts.end_time is $c$Heure de fin. Antérieure à start_time pour une vacation qui franchit minuit — fn_shift_end_ts résout le cas.$c$;
comment on column shifts.break_minutes is $c$Pause de la vacation, déduite des heures travaillées.$c$;
comment on column shifts.template_id is $c$Modèle dont la vacation est issue, s'il y en a un.$c$;

comment on table time_entries is $c$Registre du temps réellement travaillé, distinct du planning. C'est lui qui fait foi pour les majorations et les heures supplémentaires.$c$;
comment on column time_entries.worked_hours is $c$Heures effectivement travaillées, pause déduite.$c$;
comment on column time_entries.planned_hours is $c$Heures planifiées pour la même journée, pour mesurer l'écart.$c$;
comment on column time_entries.sunday_hours is $c$Part travaillée un dimanche, qui ouvre sa propre majoration.$c$;
comment on column time_entries.holiday_hours is $c$Part travaillée un jour férié.$c$;
comment on column time_entries.night_hours is $c$Part travaillée en période de nuit.$c$;
comment on column time_entries.overtime_hours is $c$Heures supplémentaires retenues sur la journée.$c$;
comment on column time_entries.is_validated is $c$Vrai une fois la journée validée. Une journée non validée ne nourrit aucun calcul définitif.$c$;
comment on column time_entries.source is $c$Origine de la saisie : pointage, saisie manuelle, report du planning.$c$;

comment on table overtime_requests is $c$Demande d'heures supplémentaires. Elle exige un double accord : validation RH et acceptation du salarié.$c$;
comment on column overtime_requests.status is $c$État de la demande. hr_approved ne suffit pas : tant que le salarié n'a pas accepté, les heures ne sont pas couvertes.$c$;
comment on column overtime_requests.hr_validated_at is $c$Horodatage de la validation RH.$c$;
comment on column overtime_requests.employee_accepted_at is $c$Horodatage de l'acceptation par le salarié.$c$;
comment on column overtime_requests.compensation is $c$Mode de compensation retenu : repos compensateur ou paiement majoré.$c$;
comment on column overtime_requests.rejected_reason is $c$Motif du refus, restitué à l'auteur de la demande.$c$;
comment on column overtime_requests.schedule_id is $c$Planning auquel la demande se rattache, s'il y en a un.$c$;

-- ===========================================================================
-- Absences, documents, vigilance
-- ===========================================================================

comment on table absences is $c$Absence d'un salarié : congé, maladie, congé extraordinaire. Le moteur en contrôle le droit, l'imputation et les justificatifs.$c$;
comment on column absences.days_count is $c$Jours décomptés, calculés hors fériés et jours non ouvrés — pas la simple différence de dates.$c$;
comment on column absences.declared_by_employee is $c$Vrai si la déclaration vient de l'espace salarié, faux si elle est saisie par les RH.$c$;
comment on column absences.certificate_received is $c$Vrai dès réception du certificat, sous quelque forme que ce soit.$c$;
comment on column absences.certificate_uploaded_at is $c$Dépôt numérique du certificat par le salarié.$c$;
comment on column absences.certificate_original_received is $c$Réception de l'original papier, exigée séparément du dépôt numérique.$c$;
comment on column absences.child_id is $c$Enfant concerné, pour un congé lié à un enfant.$c$;
comment on column absences.decided_by is $c$Auteur de la décision d'acceptation ou de refus.$c$;
comment on column absences.decision_note is $c$Motivation de la décision, restituée au salarié.$c$;

comment on table documents is $c$Pièces déposées, rattachées à un salarié, à un contrat ou à une société. Le fichier vit dans le stockage ; cette table porte les métadonnées et la durée de conservation.$c$;
comment on column documents.storage_path is $c$Chemin dans le bucket de stockage. L'accès au fichier obéit aux mêmes règles que la ligne.$c$;
comment on column documents.is_sensitive is $c$Vrai pour une pièce de catégorie particulière (santé, handicap) : accès et conservation restreints.$c$;
comment on column documents.retention_until is $c$Date au-delà de laquelle la pièce ne doit plus être conservée (RGPD, limitation de conservation).$c$;
comment on column documents.expires_on is $c$Fin de validité de la pièce elle-même, qui déclenche l'alerte d'échéance.$c$;
comment on column documents.issued_on is $c$Date de délivrance par l'autorité émettrice.$c$;
comment on column documents.delivered_at is $c$Date de remise au salarié, pour les pièces de fin de contrat.$c$;
comment on column documents.entity_table is $c$Table de l'objet rattaché, lorsque la pièce ne vise pas directement un salarié.$c$;

comment on table compliance_alerts is $c$Constats du moteur de vigilance. Chaque alerte porte son article : c'est ce qui distingue un avertissement d'une injonction opaque.$c$;
comment on column compliance_alerts.rule_code is $c$Code stable de la règle, pour suivre une alerte à travers les scans successifs.$c$;
comment on column compliance_alerts.consequence is $c$Ce qui arrive si rien n'est fait — sanction, requalification, nullité.$c$;
comment on column compliance_alerts.legal_ref is $c$Article qui fonde le constat.$c$;
comment on column compliance_alerts.severity is $c$Gravité, qui commande le tri et la couleur à l'écran.$c$;
comment on column compliance_alerts.state is $c$État de traitement : ouverte, traitée, écartée.$c$;
comment on column compliance_alerts.due_date is $c$Échéance à laquelle le manquement devient effectif.$c$;
comment on column compliance_alerts.first_seen_at is $c$Première apparition du constat, conservée même si l'alerte réapparaît.$c$;
comment on column compliance_alerts.handled_note is $c$Justification de la prise en charge ou de la mise à l'écart.$c$;
