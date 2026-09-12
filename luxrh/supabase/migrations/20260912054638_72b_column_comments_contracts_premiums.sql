-- 72b — Commentaires de colonnes : contrats, conventions, primes
--
-- Suite de la migration 72. Découpée pour rester lisible, et parce qu'une
-- migration de commentaires n'a aucune raison d'être atomique avec les autres.

set search_path = public;

-- ====================================================== contrats

comment on column contracts.job_title is 'Intitulé du poste tel qu''il figure au contrat. Mention obligatoire : il fonde la classification conventionnelle, et donc le salaire minimum applicable.';
comment on column contracts.job_description is 'Description des fonctions. Sa précision détermine ce qu''un changement de tâches doit faire passer par un avenant plutôt que par une simple instruction.';
comment on column contracts.start_date is 'Prise d''effet du contrat, jour inclus. Point de départ de l''ancienneté, de la période d''essai et du droit à congé.';
comment on column contracts.end_date is 'Dernier jour du contrat, INCLUS. Nulle pour un contrat à durée indéterminée en cours. Un avenant clôt le contrat précédent la veille de sa prise d''effet.';

comment on column contract_amendments.reason is 'Motif de l''avenant, obligatoire. Un avenant sans motif est refusé par le moteur : c''est la pièce qui explique, des années après, pourquoi le contrat a changé.';

comment on column contract_pay_components.code is 'Code de l''élément de rémunération : prime, indemnité, avantage. Stable, repris par la paie.';
comment on column contract_pay_components.label is 'Libellé de l''élément tel qu''il apparaît sur le bulletin.';
comment on column contract_pay_components.amount is 'Montant en euros. Nul quand l''élément se calcule au lieu d''être forfaitaire — un zéro dirait autre chose.';
comment on column contract_pay_components.is_taxable is 'Vrai si l''élément entre dans l''assiette imposable. Une prime exonérée mal marquée fausse la retenue à la source.';
comment on column contract_pay_components.is_contributory is 'Vrai si l''élément entre dans l''assiette des cotisations sociales. Indépendant de is_taxable : les deux assiettes ne coïncident pas.';
comment on column contract_pay_components.note is 'Fondement de l''élément : article de convention, usage, accord individuel. Ce qui permet de le défendre ou de le supprimer.';

comment on column contract_terminations.reason is 'Motif de la rupture, obligatoire. Détermine le préavis, l''indemnité de départ et la possibilité de contester.';
comment on column contract_terminations.waiver_agreed_on is 'Date de l''accord de renonciation au préavis, s''il y en a un. Nulle en l''absence d''accord : le préavis court alors en entier.';
comment on column contract_terminations.waiver_note is 'Contenu de l''accord de renonciation, dans les termes convenus. Une renonciation se prouve.';

comment on column probation_extensions.from_date is 'Premier jour de la prolongation d''essai, inclus.';
comment on column probation_extensions.to_date is 'Dernier jour de la prolongation, INCLUS. La durée totale d''essai reste plafonnée par la loi et par la convention : le moteur vérifie le cumul, pas seulement cette ligne.';
comment on column probation_extensions.reason is 'Motif de la prolongation. L''essai ne se prolonge pas par convenance : il faut une cause, généralement une suspension du contrat.';

comment on column interim_agencies.name is 'Raison sociale de l''agence d''intérim, telle qu''elle figure au contrat de mise à disposition.';
comment on column interim_agencies.ccss_matricule is 'Matricule CCSS de l''agence. C''est elle qui déclare le salarié, pas l''entreprise utilisatrice.';
comment on column interim_agencies.rcs_number is 'Numéro au registre de commerce. Permet de vérifier qu''une agence est autorisée avant de lui confier une mission.';

-- ====================================================== conventions collectives

comment on column collective_agreements.name is 'Intitulé officiel de la convention, tel que publié par l''ITM.';
comment on column collective_agreements.sector is 'Secteur couvert. Sert à proposer la bonne convention lors du rattachement d''une société, jamais à l''imposer.';
comment on column collective_agreements.is_active is 'Faux quand la convention est dénoncée ou remplacée. Elle reste en base : une paie ancienne doit encore pouvoir citer la convention qui la fondait.';

comment on column company_collective_agreements.note is 'Circonstances du rattachement de la société à la convention : adhésion, extension, usage. Ce qui permet de le contester.';
comment on column contract_collective_agreements.note is 'Circonstances du rattachement au niveau du contrat, quand il déroge à celui de la société.';

comment on column cba_salary_grids.category is 'Catégorie professionnelle de la grille, dans les termes de la convention. C''est elle qui relie un poste à un minimum conventionnel.';
comment on column cba_salary_grids.monthly_amount is 'Salaire mensuel minimum de la catégorie, en euros, à l''indice de référence de la convention. Le moteur l''indexe avant de le comparer au salaire réel.';

-- ====================================================== primes et conditions de travail

comment on column premiums.kind is 'Nature de la prime. Détermine son régime fiscal et social, et le plafond légal qui s''y applique le cas échéant.';
comment on column premiums.label is 'Libellé de la prime sur le bulletin.';
comment on column premiums.amount is 'Montant en euros pour la période. Le plafond d''exonération éventuel est vérifié par le moteur et non par une contrainte : il est daté.';
comment on column premiums.is_taxable is 'Vrai si la prime entre dans l''assiette imposable, une fois le plafond d''exonération dépassé.';
comment on column premiums.is_contributory is 'Vrai si la prime entre dans l''assiette des cotisations. Distinct du régime fiscal.';
comment on column premiums.note is 'Fondement de la prime et calcul retenu. Une prime sans justification écrite se conteste mal.';

comment on column cct_regle_prime.condition_code is 'Condition matérielle ouvrant droit à la prime, parmi ref_condition_travail : pénibilité, insalubrité, danger. Ces primes ne sont pas prévues par la loi générale — ce sont les conventions sectorielles qui les fixent.';
comment on column cct_regle_prime.nature_prime is 'Nature de la prime, parmi ref_nature_prime. Détermine son traitement fiscal et social.';
comment on column cct_regle_prime.libelle is 'Intitulé de la règle tel qu''il apparaît dans la convention. Repris dans le détail du calcul, pour que le montant soit rattachable à son article.';
comment on column cct_regle_prime.montant is 'Montant forfaitaire en euros, par unité. Exclusif de taux_pct : une règle est soit un forfait, soit un pourcentage, jamais les deux.';
comment on column cct_regle_prime.assiette is 'Base sur laquelle s''applique le pourcentage : salaire mensuel ou salaire horaire. Obligatoire dès qu''un taux est fixé ; une assiette que le moteur ne sait pas résoudre ressort en « non calculable » plutôt qu''en zéro.';
comment on column cct_regle_prime.categorie_visee is 'Catégorie professionnelle à laquelle la règle se limite. Nulle si la règle vaut pour tous les salariés couverts par la convention.';
comment on column cct_regle_prime.note is 'Précisions d''application : cumul, proratisation, exclusions. Ce que l''article dit et que les colonnes ne portent pas.';

comment on column creneau_condition.client_site_id is 'Site client où la condition a été constatée. Nul pour une condition constatée dans les locaux de l''employeur.';
comment on column creneau_condition.condition_code is 'Condition constatée, parmi ref_condition_travail. C''est le constat qui ouvre le droit, pas le poste : un même salarié peut être exposé un jour et pas le lendemain.';
comment on column creneau_condition.date_prestation is 'Jour de la prestation. La règle conventionnelle applicable est celle en vigueur ce jour-là, pas celle d''aujourd''hui.';
comment on column creneau_condition.heure_debut is 'Heure de début d''exposition. Avec heure_fin, donne la durée qui sert au seuil et à la conversion en montant.';
comment on column creneau_condition.heure_fin is 'Heure de fin d''exposition. Un créneau ne franchit pas minuit : une exposition de nuit se saisit en deux créneaux.';
comment on column creneau_condition.constate_par is 'Compte ayant constaté la condition. Une prime de pénibilité repose sur un constat : il a un auteur.';
comment on column creneau_condition.note is 'Circonstances du constat. Utile en cas de contestation, jamais utilisée par le calcul.';

-- ====================================================== sanctions disciplinaires

comment on column sanction_categories.code is 'Code de la catégorie de sanction : mineure, lourde, rupture. Trois catégories, qui commandent la procédure exigée.';
comment on column sanction_categories.label is 'Libellé de la catégorie à l''écran.';
comment on column sanction_categories.description is 'Ce que la catégorie implique en matière de procédure, d''entretien préalable et de recours. C''est la colonne que lit un gestionnaire avant de choisir.';

comment on column sanction_types.code is 'Code du type de sanction, stable. Huit types répartis dans les trois catégories.';
comment on column sanction_types.category_code is 'Catégorie de rattachement, parmi sanction_categories. Détermine la procédure et les délais.';
comment on column sanction_types.label is 'Libellé du type de sanction à l''écran.';
comment on column sanction_types.description is 'Portée exacte de la sanction et conditions de validité. Une sanction lourde suppose notamment qu''elle figure dans les textes internes de l''entreprise.';
comment on column sanction_types.affects_presence is 'Vrai si la sanction suspend la présence du salarié — mise à pied. Le planning doit alors cesser de l''affecter sur la période.';
comment on column sanction_types.ends_contract is 'Vrai si la sanction met fin au contrat. Déclenche le circuit de rupture : préavis, indemnités, documents de fin de contrat.';
comment on column sanction_types.note is 'Références et précisions sur l''usage du type. Ce qui permet de vérifier qu''on applique la bonne sanction.';

comment on column employee_sanctions.sanction_type is 'Type de sanction prononcée, parmi sanction_types.';
comment on column employee_sanctions.effective_from is 'Premier jour d''effet, inclus. Nul pour une sanction sans effet daté, comme un avertissement.';
comment on column employee_sanctions.effective_to is 'Dernier jour d''effet, INCLUS. Une mise à pied a une fin ; un avertissement n''en a pas.';
comment on column employee_sanctions.reason is 'Faits reprochés, obligatoires. Une sanction sans motif écrit est contestable de ce seul fait.';
comment on column employee_sanctions.evidence_document_id is 'Pièce au dossier : lettre de notification, compte rendu d''entretien. Ce qui prouve que la procédure a été suivie.';
comment on column employee_sanctions.employee_response is 'Observations du salarié. Le droit de répondre fait partie de la procédure : la réponse se conserve, même si elle ne change pas la décision.';
comment on column employee_sanctions.contested_on is 'Date de contestation par le salarié. Nulle tant qu''il n''a pas contesté.';
comment on column employee_sanctions.contest_outcome is 'Issue de la contestation : maintien, réduction, retrait. Une sanction retirée reste en base, avec son issue — l''effacer réécrirait l''histoire.';
comment on column employee_sanctions.note is 'Suites internes : suivi, accompagnement, rappel à l''ordre ultérieur.';
comment on column employee_sanctions.updated_by is 'Compte auteur de la dernière modification. Sur une sanction, chaque retouche doit rester attribuable.';
