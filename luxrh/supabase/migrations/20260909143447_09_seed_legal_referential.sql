
-- =========================================================================
--  JEU DE DONNÉES INITIAL DU RÉFÉRENTIEL — PRD §7, daté au 09.09.2026.
--  À re-valider sur les sources officielles avant mise en production.
-- =========================================================================
insert into legal_parameters
  (family, param_key, label, value_num, value_text, value_json, unit, valid_from, valid_to, index_ref, source, legal_ref, note)
values
-- ---------- PARAMÈTRES SOCIAUX — indice 992,24, depuis le 01.06.2026 ----------
('social','ssm_monthly_unqualified','SSM mensuel non qualifié, 18 ans et +',2771.33,null,null,'EUR','2026-06-01',null,992.24,'CCSS','art. L.222-9',null),
('social','ssm_monthly_qualified','SSM mensuel qualifié, 18 ans et +',3325.59,null,null,'EUR','2026-06-01',null,992.24,'CCSS','art. L.222-4',null),
('social','ccss_max_monthly','Maximum cotisable mensuel',13856.63,null,null,'EUR','2026-06-01',null,992.24,'CCSS','art. 34 CSS',null),
('social','dependency_allowance_monthly','Abattement dépendance mensuel',692.83,null,null,'EUR','2026-06-01',null,992.24,'CCSS','art. 376 CSS',null),
('social','ref_hours_monthly','Base horaire mensuelle de référence',173,null,null,'h','2026-06-01',null,992.24,'CCSS',null,null),
('social','wage_index','Indice appliqué',992.24,null,null,'points','2026-06-01',null,992.24,'CCSS',null,'Indexation du 1er juin 2026'),

-- ---------- COTISATIONS CCSS ----------
('social','ccss_sickness_kind_employee','Maladie — prestations en nature, salarié',2.80,null,null,'%','2026-01-01',null,null,'CCSS','art. 32 CSS',null),
('social','ccss_sickness_kind_employer','Maladie — prestations en nature, employeur',2.80,null,null,'%','2026-01-01',null,null,'CCSS','art. 32 CSS',null),
('social','ccss_sickness_cash_employee','Maladie — majoration espèces, salarié',0.25,null,null,'%','2026-01-01',null,null,'CCSS','art. 32 CSS',null),
('social','ccss_sickness_cash_employer','Maladie — majoration espèces, employeur',0.25,null,null,'%','2026-01-01',null,null,'CCSS','art. 32 CSS',null),
('social','ccss_pension_employee','Pension, salarié',8.00,null,null,'%','2015-01-01','2026-01-01',null,'CCSS','art. 238 CSS','Taux antérieur, conservé pour les recalculs datés'),
('social','ccss_pension_employee','Pension, salarié',8.50,null,null,'%','2026-01-01',null,null,'CCSS','art. 238 CSS','Passage de 8,00 % à 8,50 % au 01.01.2026'),
('social','ccss_pension_employer','Pension, employeur',8.00,null,null,'%','2015-01-01','2026-01-01',null,'CCSS','art. 238 CSS',null),
('social','ccss_pension_employer','Pension, employeur',8.50,null,null,'%','2026-01-01',null,null,'CCSS','art. 238 CSS',null),
('social','ccss_dependency_employee','Dépendance, salarié',1.40,null,null,'%','2026-01-01',null,null,'CCSS','art. 376 CSS',null),
('social','ccss_family_employer','Prestations familiales, employeur',1.70,null,null,'%','2026-01-01',null,null,'CCSS',null,null),
('social','ccss_health_work_employer','Santé au travail, employeur',0.14,null,null,'%','2026-01-01',null,null,'CCSS',null,null),
('social','ccss_accident_base_employer','Accident — taux de base, facteur 1,00',0.65,null,null,'%','2026-01-01',null,null,'CCSS',null,null),
('social','ccss_employee_total','Total part salariale',12.95,null,null,'%','2026-01-01',null,null,'calculé',null,'2,80 + 0,25 + 8,50 + 1,40'),
('social','mutuality_class_rates','Mutualité des employeurs — taux par classe',null,null,
 '[{"class":1,"rate":0.23},{"class":2,"rate":1.26},{"class":3,"rate":1.86},{"class":4,"rate":2.66}]'::jsonb,
 '%','2026-01-01',null,null,'CCSS',null,'Fourchette 0,23 % à 2,66 % — à re-vérifier à chaque avis annuel'),

-- ---------- TEMPS DE TRAVAIL ----------
('worktime','normal_daily_hours','Durée normale journalière',8,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-5',null),
('worktime','normal_weekly_hours','Durée normale hebdomadaire',40,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-5',null),
('worktime','max_daily_hours','Durée maximale journalière',10,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-12','La durée de travail ne peut excéder 10 heures par jour ni 48 heures par semaine.'),
('worktime','max_weekly_hours','Durée maximale hebdomadaire',48,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-12',null),
('worktime','min_daily_rest_hours','Repos journalier minimum',11,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-16','11 heures consécutives par période de 24 heures.'),
('worktime','min_weekly_rest_hours','Repos hebdomadaire minimum',44,null,null,'h','2009-01-01',null,null,'Legilux','art. L.231-2','44 heures consécutives.'),
('worktime','max_reference_period_months','Période de référence maximale',4,null,null,'mois','2009-01-01',null,null,'Legilux','art. L.211-6',null),
('worktime','break_threshold_hours','Seuil de pause obligatoire',6,null,null,'h','2009-01-01',null,null,'Legilux','art. L.211-16','Durée de la pause renvoyée à la CCT ou au contrat.'),
('worktime','overtime_rest_ratio','Heure supplémentaire — compensation en repos',1.5,null,null,'ratio','2009-01-01',null,null,'Legilux','art. L.211-27','1 h 30 de repos par heure supplémentaire.'),
('worktime','overtime_money_pct','Heure supplémentaire — compensation en argent',140,null,null,'%','2009-01-01',null,null,'Legilux','art. L.211-27',null),
('worktime','sunday_surcharge_pct','Majoration du travail du dimanche',70,null,null,'%','2009-01-01',null,null,'Legilux','art. L.231-7',null),
('worktime','holiday_surcharge_pct','Jour férié travaillé — rémunération totale',300,null,null,'%','2009-01-01',null,null,'Legilux','art. L.232-5',null),
('worktime','night_min_surcharge_if_cba_pct','Travail de nuit — minimum si la CCT en prévoit un',15,null,null,'%','2009-01-01',null,null,'ITM',null,'Aucune majoration légale générale.'),
('worktime','night_window','Plage horaire de nuit',null,'22:00-06:00',null,null,'2009-01-01',null,null,'CCT',null,'À préciser CCT par CCT.'),

-- ---------- CONGÉS ET ABSENCES ----------
('leave','annual_leave_min_days','Congé annuel légal minimum',26,null,null,'jours ouvrables','2023-01-01',null,null,'Legilux','art. L.233-4',null),
('leave','leave_accrual_per_month','Acquisition mensuelle',2.1667,null,null,'jours','2023-01-01',null,null,'Legilux','art. L.233-4','1/12e par mois travaillé, dès la première année.'),
('leave','leave_month_fraction_days','Fraction de mois comptant pour un mois complet',15,null,null,'jours','2023-01-01',null,null,'Legilux','art. L.233-4',null),
('leave','public_holidays_count','Jours fériés légaux',11,null,null,'jours','2023-01-01',null,null,'Legilux','art. L.232-2',null),
('leave','sick_continuation_days','Continuation de salaire par l''employeur',77,null,null,'jours','2019-01-01',null,null,'Legilux','art. L.121-6','Jusqu''à la fin du mois du 77e jour d''incapacité.'),
('leave','sick_reference_months','Période de référence de l''incapacité',18,null,null,'mois','2019-01-01',null,null,'Legilux','art. L.121-6',null),
('leave','sick_certificate_deadline_days','Délai de remise du certificat médical',3,null,null,'jours','2019-01-01',null,null,'Legilux','art. L.121-6 (2)',null),
('leave','dismissal_protection_weeks','Protection contre le licenciement pendant la maladie',26,null,null,'semaines','2019-01-01',null,null,'Legilux','art. L.121-6 (3)',null),
('leave','mutuality_refund_pct','Remboursement de la Mutualité des employeurs',80,null,null,'%','2019-01-01',null,null,'CCSS',null,'100 % pour les 3 premiers mois d''essai, le congé pour raisons familiales et le congé d''accompagnement.'),

-- ---------- CYCLE DE VIE DU CONTRAT ----------
('contract','probation_notice_days_per_week','Préavis d''essai — par semaine d''essai',1,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.121-5','Autant de jours que de semaines d''essai.'),
('contract','probation_notice_days_per_month','Préavis d''essai — par mois d''essai',4,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.121-5',null),
('contract','probation_notice_min_days','Préavis d''essai — minimum',15,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.121-5',null),
('contract','probation_notice_max_days','Préavis d''essai — maximum',30,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.121-5','Plafonné à un mois.'),
('contract','probation_extension_max_days','Prolongation d''essai par maladie — plafond',30,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.121-5','Durée de l''absence, plafonnée à un mois.'),
('contract','notice_dismissal_months','Préavis de licenciement selon l''ancienneté',null,null,
 '[{"from_years":0,"to_years":5,"months":2},{"from_years":5,"to_years":10,"months":4},{"from_years":10,"to_years":null,"months":6}]'::jsonb,
 'mois','2009-01-01',null,null,'Legilux','art. L.124-3',null),
('contract','notice_resignation_ratio','Préavis de démission — fraction du préavis de licenciement',0.5,null,null,'ratio','2009-01-01',null,null,'Legilux','art. L.124-4',null),
('contract','notice_start_day','Point de départ du préavis',15,null,null,'jour du mois','2009-01-01',null,null,'Legilux','art. L.124-3','Le 15 du mois si notifié avant le 15, le 1er du mois suivant sinon.'),
('contract','severance_scale','Indemnité de départ selon l''ancienneté',null,null,
 '[{"from_years":5,"to_years":10,"months":1},{"from_years":10,"to_years":15,"months":2},{"from_years":15,"to_years":20,"months":3},{"from_years":20,"to_years":25,"months":6},{"from_years":25,"to_years":30,"months":9},{"from_years":30,"to_years":null,"months":12}]'::jsonb,
 'mois','2009-01-01',null,null,'Legilux','art. L.124-7',null),
('contract','cdd_max_months','CDD — durée maximale cumulée',24,null,null,'mois','2009-01-01',null,null,'Legilux','art. L.122-4',null),
('contract','cdd_max_renewals','CDD — nombre de renouvellements',2,null,null,'renouvellements','2009-01-01',null,null,'Legilux','art. L.122-4',null),
('contract','cdd_carence_ratio','CDD — délai de carence',0.3333,null,null,'ratio','2009-01-01',null,null,'Legilux','art. L.122-5','Un tiers de la durée du contrat précédent.'),
('contract','cdd_reasons','Motifs de recours au CDD',null,null,
 '["Remplacement d''un salarié absent","Accroissement temporaire d''activité","Emploi à caractère saisonnier","Emploi pour lequel il n''est pas d''usage de recourir au CDI","Exécution d''une tâche occasionnelle et définie","Contrat à durée déterminée d''un salarié en formation","Emploi financé par un dispositif d''aide à l''emploi"]'::jsonb,
 null,'2009-01-01',null,null,'Legilux','art. L.122-1',null),

-- ---------- SEUILS D'EFFECTIF ----------
('headcount','delegation_threshold','Seuil de la délégation du personnel',15,null,null,'salariés','2016-01-01',null,null,'Legilux','art. L.412-1','Effectif apprécié sur les 12 mois précédents, élections tous les 5 ans.'),
('headcount','delegation_approach_threshold','Seuil d''alerte d''approche de la délégation',13,null,null,'salariés','2016-01-01',null,null,'produit',null,'Paramètre de vigilance, non légal.'),
('headcount','delegation_reference_months','Période de référence de l''effectif',12,null,null,'mois','2016-01-01',null,null,'Legilux','art. L.412-1',null),
('headcount','proportional_vote_threshold','Seuil du scrutin proportionnel',100,null,null,'salariés','2016-01-01',null,null,'Legilux','art. L.413-3',null),
('headcount','prior_interview_threshold','Seuil de l''entretien préalable obligatoire',150,null,null,'salariés','2016-01-01',null,null,'Legilux','art. L.124-2',null),
('headcount','released_delegate_threshold','Seuil du premier délégué libéré à temps plein',250,null,null,'salariés','2016-01-01',null,null,'Legilux','art. L.415-5',null),
('headcount','delegation_delegates_scale','Nombre de délégués par tranche d''effectif',null,null,
 '[{"from":15,"to":25,"effective":1,"substitute":1},{"from":26,"to":50,"effective":2,"substitute":2},{"from":51,"to":75,"effective":3,"substitute":3},{"from":76,"to":100,"effective":4,"substitute":4},{"from":101,"to":200,"effective":5,"substitute":5},{"from":201,"to":300,"effective":6,"substitute":6},{"from":301,"to":400,"effective":7,"substitute":7},{"from":401,"to":null,"effective":8,"substitute":8}]'::jsonb,
 null,'2016-01-01',null,null,'Legilux','art. L.412-1','Tranches au-delà de 400 à compléter — question ouverte n°2 du PRD.'),
('headcount','collective_dismissal_30d','Licenciement collectif — seuil sur 30 jours',7,null,null,'licenciements','2009-01-01',null,null,'Legilux','art. L.166-1','Motif non inhérent à la personne du salarié.'),
('headcount','collective_dismissal_90d','Licenciement collectif — seuil sur 90 jours',15,null,null,'licenciements','2009-01-01',null,null,'Legilux','art. L.166-1',null),
('headcount','collective_negotiation_days','Négociation du plan social',15,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.166-2',null),
('headcount','collective_onc_seizure_days','Délai de saisine de l''ONC',3,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.166-2',null),
('headcount','collective_onc_days','Conciliation devant l''ONC',15,null,null,'jours','2009-01-01',null,null,'Legilux','art. L.166-2',null),

-- ---------- PARAMÈTRES DE VIGILANCE (produit, non légaux) ----------
('headcount','vigilance_horizon_days','Horizon du bloc « dans les 30 jours »',30,null,null,'jours','2020-01-01',null,null,'produit',null,null),
('contract','probation_alert_days_1','Alerte essai — première',15,null,null,'jours','2020-01-01',null,null,'produit',null,null),
('contract','probation_alert_days_2','Alerte essai — seconde',5,null,null,'jours','2020-01-01',null,null,'produit',null,null),
('contract','cdd_alert_days_1','Alerte CDD — première',60,null,null,'jours','2020-01-01',null,null,'produit',null,null),
('contract','cdd_alert_days_2','Alerte CDD — seconde',30,null,null,'jours','2020-01-01',null,null,'produit',null,null),

-- ---------- CONSERVATION (RGPD) ----------
('leave','retention_payslips_years','Conservation des fiches de salaire et pièces comptables',10,null,null,'ans','2020-01-01',null,null,'Legilux',null,'À partir de la clôture de l''exercice.'),
('leave','retention_time_register_years','Conservation du registre du temps de travail',10,null,null,'ans','2020-01-01',null,null,'Legilux','art. L.211-29',null);

-- ---------- TYPES D'ABSENCE ----------
insert into absence_types (code, label, category, entitlement_days, legal_ref, frequency_note, requires_certificate, is_paid, counts_against_leave) values
('annual_leave','Congé annuel','annual_leave',null,'art. L.233-4',null,false,true,true),
('sick','Incapacité de travail','sick',null,'art. L.121-6',null,true,true,false),
('marriage','Mariage','extraordinary',3,'art. L.233-16',null,false,true,false),
('death_spouse','Décès du conjoint ou d''un parent au 1er degré','extraordinary',3,'art. L.233-16',null,false,true,false),
('birth','Naissance ou adoption','extraordinary',10,'art. L.233-16','à prendre dans les 2 mois de la naissance',false,true,false),
('death_child','Décès d''un enfant mineur','extraordinary',5,'art. L.233-16',null,false,true,false),
('moving','Déménagement','extraordinary',2,'art. L.233-16','1 fois par 3 ans',false,true,false),
('unpaid','Congé sans solde','unpaid',null,null,null,false,false,false),
('compensatory','Repos compensatoire','compensatory',null,'art. L.211-27',null,false,true,false);

-- ---------- JOURS FÉRIÉS ----------
select fn_generate_public_holidays(g) from generate_series(2025, 2028) g;
