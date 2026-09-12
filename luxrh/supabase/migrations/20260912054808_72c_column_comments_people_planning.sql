-- 72c — Commentaires de colonnes : personnes, santé, planning, référentiel
--
-- Fin de la série ouverte par la migration 72. Après celle-ci, les 836 colonnes
-- des 76 tables portent un commentaire.

set search_path = public;

-- ====================================================== personnes

comment on column employees.first_name is 'Prénom usuel du salarié. Distinct de l''état civil complet : c''est ce qui s''affiche et s''imprime.';
comment on column employees.last_name is 'Nom de famille. Sert au tri et à la recherche ; un index trigramme le rend cherchable en approximation.';
comment on column employees.birth_date is 'Date de naissance. Nulle tant qu''elle n''est pas connue — au stade de la candidature, par exemple. Sert au calcul des majorations liées à l''âge et au contrôle de cohérence du matricule.';
comment on column employees.email is 'Adresse personnelle du salarié. Distincte de celle du compte applicatif : tous les salariés n''ont pas de compte, et l''adresse de contact survit à la fin du contrat.';
comment on column employees.phone is 'Téléphone de contact. Utilisé par le dispatching ; l''accès en est restreint comme toute donnée de contact personnel.';

comment on column employee_statuses.start_date is 'Premier jour du statut, inclus. Un statut protégé — grossesse, délégation, congé parental — ouvre des protections qui commencent ce jour-là.';
comment on column employee_statuses.end_date is 'Dernier jour du statut, INCLUS. Nulle tant que le statut court.';
comment on column employee_statuses.evidence_document_id is 'Pièce justifiant le statut : certificat, procès-verbal d''élection. Une protection invoquée sans pièce ne tient pas devant l''ITM.';
comment on column employee_statuses.note is 'Précisions sur la portée du statut et sur ce qu''il interdit à l''employeur.';

comment on column employee_disabilities.note is 'Éléments de contexte sur la reconnaissance du handicap. Donnée sensible au sens de l''article 9 du RGPD : l''accès en est restreint, et sa lecture journalisée.';

comment on column employee_children.first_name is 'Prénom de l''enfant. Nul quand seul le nombre d''enfants importe pour un droit et que l''identité n''a pas à être connue — la minimisation vaut aussi ici.';
comment on column employee_children.last_name is 'Nom de l''enfant, s''il diffère de celui du parent.';
comment on column employee_children.sex is 'Sexe de l''enfant, tel que déclaré. Aucun droit n''en dépend ; la colonne existe pour les documents administratifs qui l''exigent.';
comment on column employee_children.birth_date is 'Date de naissance. Fonde les droits liés aux enfants — congé parental, boni, classe d''impôt — et le déclenchement de leur extinction.';
comment on column employee_children.taux_handicap_pct is 'Taux de handicap reconnu, en pourcentage. Donnée de santé : accès restreint, lecture journalisée. Nul si aucun handicap n''est reconnu.';
comment on column employee_children.note is 'Précisions utiles au dossier familial. Jamais de donnée de santé : celles-ci vont en fiche_sante, qui porte les restrictions adéquates.';

comment on column employee_tax_cards.issued_on is 'Date d''émission de la fiche de retenue par l''administration. Distincte de la période de validité : une fiche peut être émise après le début de la période qu''elle couvre.';

-- ====================================================== santé et secours

comment on column fiche_sante.enfant_id is 'Enfant concerné quand la fiche porte sur un enfant et non sur le salarié. Exclusif de la fiche du salarié : une ligne concerne l''un ou l''autre.';
comment on column fiche_sante.pathologies is 'Pathologies déclarées. Donnée de santé au sens de l''article 9 du RGPD, sous le régime d''accès le plus strict : le dispatching n''y a jamais accès, il ne voit que des indicateurs dérivés et anonymisés.';
comment on column fiche_sante.medecin_traitant is 'Médecin traitant, pour le cas d''urgence. Donnée de santé.';
comment on column fiche_sante.medecin_telephone is 'Téléphone du médecin traitant, appelable en urgence.';
comment on column fiche_sante.groupe_sanguin is 'Groupe sanguin déclaré. Donnée de santé, transmise aux secours et à personne d''autre.';
comment on column fiche_sante.note is 'Consignes de prise en charge : allergies et conduite à tenir, traitement d''urgence disponible sur la personne — adrénaline pour une allergie aux piqûres, antihistaminique, mèche de cautérisation. C''est ce que les secours doivent savoir en arrivant.';
comment on column fiche_sante.maj_le is 'Date de dernière mise à jour de la fiche. Une consigne de secours périmée est dangereuse : l''ancienneté de la fiche doit être visible.';
comment on column fiche_sante.maj_par is 'Compte ayant mis la fiche à jour. Sur une donnée de santé, toute écriture est attribuable et journalisée.';

comment on column personne_indicateur_secours.enfant_id is 'Enfant concerné quand l''indicateur porte sur un enfant. Exclusif de la personne salariée.';
comment on column personne_indicateur_secours.indicateur is 'Indicateur de secours, parmi ref_indicateur_secours. C''est la forme ANONYMISÉE de l''information médicale : un booléen dérivé, sans diagnostic. Le dispatching voit l''indicateur, jamais la pathologie qui le fonde.';
comment on column personne_indicateur_secours.pose_par is 'Compte ayant posé l''indicateur, à partir de la fiche de santé. La dérivation est un acte : elle a un auteur et une date.';

-- ====================================================== planning et temps

comment on column schedules.label is 'Intitulé du planning, pour s''y retrouver entre plusieurs semaines ou équipes. Sans effet sur le calcul.';

comment on column shifts.schedule_id is 'Planning auquel le créneau appartient. Un créneau n''existe pas hors d''un planning : c''est le planning qui porte le statut brouillon ou publié.';
comment on column shifts.shift_date is 'Jour du créneau. Un créneau qui déborde sur le lendemain porte la date de son début.';
comment on column shifts.start_time is 'Heure de début. Avec la durée, détermine les majorations de nuit, de dimanche et de jour férié.';
comment on column shifts.label is 'Précision sur le créneau : chantier, tournée, remplacement. Affichée au salarié.';

comment on column shift_templates.name is 'Nom du modèle de créneau, pour le réutiliser lors de la construction d''un planning.';
comment on column shift_templates.start_time is 'Heure de début du modèle.';
comment on column shift_templates.end_time is 'Heure de fin du modèle. Peut être antérieure à start_time : le créneau franchit alors minuit.';
comment on column shift_templates.break_minutes is 'Pause en minutes, déduite du temps de travail effectif. Le seuil légal au-delà duquel une pause est obligatoire vient du référentiel daté, jamais d''une valeur écrite ici.';

comment on column time_entries.entry_date is 'Jour du relevé. Un relevé par jour et par salarié : c''est la maille de tous les compteurs.';
comment on column time_entries.start_time is 'Heure de début relevée. Nulle pour un relevé saisi en durée seule, sans horaires.';
comment on column time_entries.end_time is 'Heure de fin relevée. Nulle dans le même cas que start_time — les deux vont ensemble.';
comment on column time_entries.break_minutes is 'Pause en minutes, déduite du temps de travail effectif de la journée.';
comment on column time_entries.note is 'Circonstances du relevé : dépassement, incident, rattrapage. Ce qu''un contrôle voudra comprendre.';

comment on column reference_periods.label is 'Intitulé de la période de référence, pour l''identifier dans les écrans de suivi.';
comment on column reference_periods.start_date is 'Premier jour de la période de référence, inclus. C''est sur cette période que la durée moyenne de travail doit être respectée.';
comment on column reference_periods.end_date is 'Dernier jour de la période, INCLUS. Sa longueur maximale est fixée par le référentiel légal et par la convention, jamais écrite en dur.';

comment on column overtime_requests.period_start is 'Premier jour de la période couverte par la demande, inclus.';
comment on column overtime_requests.period_end is 'Dernier jour de la période, INCLUS.';
comment on column overtime_requests.hours is 'Nombre d''heures supplémentaires demandées sur la période.';
comment on column overtime_requests.reason is 'Motif du recours aux heures supplémentaires, obligatoire. L''ITM peut le demander : les heures supplémentaires ne sont pas de droit.';
comment on column overtime_requests.requested_by is 'Compte à l''origine de la demande, généralement l''employeur.';
comment on column overtime_requests.requested_at is 'Horodatage du dépôt. Le délai de notification se compte à partir de là.';
comment on column overtime_requests.hr_validated_by is 'Compte ayant validé côté ressources humaines, avant transmission éventuelle à l''ITM.';
comment on column overtime_requests.note is 'Précisions sur les circonstances ou sur la compensation retenue.';

comment on column meal_voucher_grants.period_start is 'Premier jour de la période d''attribution, inclus.';
comment on column meal_voucher_grants.period_end is 'Dernier jour de la période, INCLUS.';
comment on column meal_voucher_grants.granted_on is 'Date de remise effective des titres. Distincte de la période qu''ils couvrent.';
comment on column meal_voucher_grants.note is 'Précisions sur le calcul du nombre de titres, notamment les jours d''absence déduits.';

-- ====================================================== sociétés, sites, trajets

comment on column companies.legal_name is 'Raison sociale, telle qu''inscrite au registre de commerce. C''est ce nom qui figure sur les contrats et les bulletins.';
comment on column companies.country is 'Pays du siège, en code ISO 3166-1 alpha-3. Le projet utilise partout l''alpha-3, y compris là où l''alpha-2 suffirait : un seul format évite les conversions silencieuses.';
comment on column companies.internal_rules_reference is 'Référence et date d''adoption du règlement intérieur. Une sanction lourde n''est valable que si elle y figure : sans cette référence, le moteur le signale.';

comment on column departments.name is 'Nom du service. Sert au périmètre de dispatching et à la résolution conventionnelle, qui peut se faire par service.';

comment on column company_financials.fiscal_year is 'Exercice comptable concerné, en année pleine.';
comment on column company_financials.revenue is 'Chiffre d''affaires de l''exercice, en euros. Sert aux seuils qui dépendent de la taille de l''entreprise.';
comment on column company_financials.note is 'Origine du chiffre : comptes déposés, estimation, déclaration. Un seuil calculé sur une estimation ne se traite pas comme un seuil calculé sur des comptes.';

comment on column company_accident_claims.year is 'Année de survenance des sinistres, pour le calcul du bonus-malus accident du travail.';
comment on column company_accident_claims.cost is 'Coût des sinistres de l''année, en euros. Entre dans la détermination de la classe de risque et donc du taux de cotisation accident.';
comment on column company_accident_claims.note is 'Précisions sur les sinistres retenus ou exclus.';

comment on column company_rate_periods.note is 'Origine du taux appliqué sur la période : notification de l''organisme, classe de risque, régularisation.';

comment on column client_sites.name is 'Nom du site client, tel qu''il apparaît sur les plannings et les ordres de mission.';
comment on column client_sites.country is 'Pays du site, en code ISO 3166-1 alpha-3.';
comment on column client_sites.longitude is 'Longitude en degrés décimaux, obtenue par géocodage. Avec la latitude, permet de calculer la distance depuis l''adresse du salarié.';
comment on column client_sites.is_active is 'Faux quand le site n''est plus desservi. Le site reste en base : les plannings passés le nomment encore.';
comment on column client_sites.note is 'Consignes d''accès et contraintes du site. Lues par qui s''y rend, pas par le moteur.';

comment on column travel_distances.destination_ref is 'Référence de la destination : site client, société, ou adresse saisie. Le trajet se calcule depuis une adresse du salarié vers cette destination.';
comment on column travel_distances.distance_km is 'Distance routière en kilomètres, telle que renvoyée par le service d''itinéraire. Ce n''est pas la distance à vol d''oiseau : c''est celle qui fonde l''indemnité.';
comment on column travel_distances.duration_minutes is 'Durée estimée du trajet. Indicative : elle sert à construire les tournées, pas à rémunérer.';
comment on column travel_distances.computed_by is 'Compte ayant déclenché le calcul. Un appel à un service externe se trace : il a un coût et il expose une adresse.';
comment on column travel_distances.note is 'Circonstances du calcul : date, service interrogé, correction manuelle éventuelle.';

-- ====================================================== documents et alertes

comment on column documents.name is 'Nom du document tel que présenté à l''utilisateur. Distinct du nom du fichier stocké.';
comment on column documents.mime_type is 'Type MIME déclaré à l''envoi. Sert à choisir la visionneuse ; il ne remplace pas un contrôle du contenu.';
comment on column documents.size_bytes is 'Taille du fichier en octets, pour les quotas et l''affichage.';
comment on column documents.uploaded_by is 'Compte ayant déposé le document.';
comment on column documents.document_type_id is 'Type de document, parmi document_types. Détermine la durée de conservation et le caractère obligatoire de la pièce.';

comment on column document_types.code is 'Code du type de document, stable, utilisé par le moteur de conformité pour vérifier qu''une pièce obligatoire est présente.';
comment on column document_types.label is 'Libellé du type de document à l''écran.';
comment on column document_types.note is 'Fondement de l''obligation et durée de conservation attendue.';

comment on column compliance_alerts.title is 'Intitulé court de l''alerte, tel qu''il apparaît dans la liste de vigilance.';
comment on column compliance_alerts.detail is 'Explication complète : ce qui manque, pourquoi c''est exigé, et ce qu''il faut faire. Une alerte qui ne dit pas quoi faire ne sera pas traitée.';
comment on column compliance_alerts.handled_by is 'Compte ayant traité l''alerte. Nul tant qu''elle est ouverte.';
comment on column compliance_alerts.handled_at is 'Date de traitement. Avec handled_by, permet de mesurer le délai de réaction — la sévérité CCSS s''appuie dessus.';

-- ====================================================== référentiel légal

comment on column legal_parameters.label is 'Intitulé du paramètre en français, pour les écrans de référentiel. Le code machine est param_key.';
comment on column legal_parameters.note is 'Précisions d''interprétation : ce que la valeur recouvre exactement, et ce qu''elle ne recouvre pas.';
comment on column legal_parameters.entered_at is 'Date de saisie de la valeur dans LuxRH. Distincte de sa date d''entrée en vigueur : une valeur peut être saisie avec retard, ou par anticipation.';
comment on column legal_parameters.validated_at is 'Date de validation par un second regard. Nulle tant que la valeur n''a pas été relue — une valeur légale non validée reste utilisable, mais elle est signalée.';

comment on column expected_parameters.param_key is 'Clé d''un paramètre que le moteur attend. Sans cette table, fn_referential_gaps ne voyait pas les clés entièrement absentes : elle ne pouvait signaler que les périodes trouées.';
comment on column expected_parameters.note is 'À quoi sert le paramètre et ce qui se casse en son absence. Ce qui permet de hiérarchiser les trous à combler.';

comment on column tax_brackets.tax_class is 'Classe d''impôt à laquelle le barème s''applique. Le passage à la classe unique prévu pour 2027 se traduira par de nouvelles lignes datées, pas par une modification des anciennes.';
comment on column tax_brackets.periodicity is 'Périodicité du barème : mensuel, annuel. Un barème mensuel n''est pas le douzième d''un barème annuel.';
comment on column tax_brackets.source is 'Publication d''origine du barème. Sans source, un barème ne se vérifie pas — et la règle 7 du projet interdit de l''inventer.';
comment on column tax_brackets.note is 'Précisions sur la tranche : arrondis, cas particuliers, articulation avec les crédits.';

comment on column tax_credits.code is 'Code du crédit d''impôt, stable, repris par le calcul de la retenue.';
comment on column tax_credits.label is 'Libellé du crédit tel qu''il apparaît sur le bulletin.';
comment on column tax_credits.monthly_amount is 'Montant mensuel du crédit, en euros. Nul quand le crédit ne se traduit pas par un montant fixe.';
comment on column tax_credits.source is 'Publication d''origine du montant. Obligatoire pour la même raison que sur tax_brackets.';
comment on column tax_credits.note is 'Conditions d''octroi et cumul avec les autres crédits.';

comment on column benefit_types.code is 'Code de l''avantage en nature, stable, utilisé par la paie.';
comment on column benefit_types.label is 'Libellé de l''avantage à l''écran et sur le bulletin.';
comment on column benefit_types.note is 'Mode d''évaluation de l''avantage et texte qui le fonde.';

comment on column public_holidays.year is 'Année du jour férié. Les fériés mobiles changent de date chaque année : une ligne par année.';
comment on column public_holidays.holiday_date is 'Date du jour férié. Un férié travaillé ouvre une majoration dont le taux vient du référentiel daté.';
comment on column public_holidays.name is 'Nom du jour férié, affiché sur les plannings.';

-- ====================================================== tables de domaine

comment on column ref_pays.alpha3 is 'Code ISO 3166-1 alpha-3 du pays. C''est la clé primaire et le format utilisé PARTOUT dans le schéma — une colonne char(2) avait déjà fait rejeter « LUX », le projet a tranché pour l''alpha-3 partout.';
comment on column ref_pays.alpha2 is 'Code ISO 3166-1 alpha-2, conservé pour dialoguer avec les services externes qui ne connaissent que celui-là. Jamais utilisé comme clé.';
comment on column ref_pays.nom is 'Nom du pays en français, pour l''affichage.';
comment on column ref_pays.frontalier is 'Vrai si le pays ouvre le régime de travailleur frontalier au Luxembourg. Commande le traitement fiscal et l''affiliation.';

comment on column ref_type_adresse.code is 'Code du type d''adresse : domicile légal, résidence effective, correspondance, facturation.';
comment on column ref_type_adresse.libelle is 'Libellé du type d''adresse à l''écran.';
comment on column ref_type_adresse.description is 'Ce à quoi ce type d''adresse sert, et pourquoi il ne se confond pas avec les autres. Le domicile légal fonde la fiscalité ; la résidence effective fonde les trajets.';
comment on column ref_type_adresse.sert_aux_tournees is 'Vrai si ce type d''adresse est celui d''où partent les calculs de distance. Un seul type sert de point de départ : sans cela, deux calculs donneraient deux résultats.';

comment on column ref_condition_travail.code is 'Code de la condition matérielle de travail : pénibilité, insalubrité, danger.';
comment on column ref_condition_travail.libelle is 'Libellé de la condition à l''écran.';
comment on column ref_condition_travail.description is 'Ce que la condition recouvre concrètement, pour que le constat sur le terrain soit reproductible d''un chef d''équipe à l''autre.';
comment on column ref_condition_travail.note is 'Conventions qui reconnaissent cette condition et articles correspondants.';

comment on column ref_nature_prime.code is 'Code de la nature de prime.';
comment on column ref_nature_prime.libelle is 'Libellé de la nature de prime à l''écran.';
comment on column ref_nature_prime.categorie is 'Regroupement de la nature de prime, pour les états de synthèse.';
comment on column ref_nature_prime.note is 'Traitement fiscal et social de cette nature de prime, et texte qui le fonde.';

comment on column ref_unite_prime.code is 'Code de l''unité à laquelle la prime se rapporte : heure exposée, jour, mois, prestation.';
comment on column ref_unite_prime.libelle is 'Libellé de l''unité à l''écran.';
comment on column ref_unite_prime.description is 'Comment le temps relevé se convertit en montant pour cette unité.';
comment on column ref_unite_prime.note is 'Précisions d''application, notamment sur les seuils et les arrondis.';

comment on column ref_indicateur_secours.code is 'Code de l''indicateur de secours. Forme ANONYMISÉE d''une information médicale : l''indicateur dit qu''il faut agir, jamais de quelle pathologie il s''agit.';
comment on column ref_indicateur_secours.libelle is 'Libellé de l''indicateur, tel que le voit le dispatching.';
comment on column ref_indicateur_secours.visible_secours is 'Vrai si l''indicateur peut être transmis aux secours. Certains indicateurs servent à l''organisation du travail et ne doivent pas sortir de ce cadre.';
comment on column ref_indicateur_secours.note is 'Conduite à tenir associée, et limite de ce que l''indicateur autorise à divulguer.';

comment on column ref_lien_enfant.code is 'Code du lien entre l''adulte et l''enfant : filiation, adoption, garde, recueil.';
comment on column ref_lien_enfant.libelle is 'Libellé du lien à l''écran.';
comment on column ref_lien_enfant.note is 'Droits que ce lien ouvre ou n''ouvre pas — tous les liens ne donnent pas les mêmes droits familiaux.';

comment on column ref_action_acces.code is 'Code de l''action journalisée dans le registre des accès : lecture, déchiffrement, export.';
comment on column ref_action_acces.libelle is 'Libellé de l''action à l''écran du registre.';
comment on column ref_action_acces.note is 'Ce que l''action recouvre exactement, pour que le registre se lise sans ambiguïté lors d''un contrôle.';

comment on column ref_sujet_export.code is 'Code du sujet d''un export : salarié, société, fiduciaire, référentiel.';
comment on column ref_sujet_export.libelle is 'Libellé du sujet à l''écran.';
comment on column ref_sujet_export.note is 'Périmètre exact de ce sujet d''export et fondement juridique du droit correspondant.';

comment on column ref_statut_verification_adresse.code is 'Code du résultat de vérification d''adresse.';
comment on column ref_statut_verification_adresse.libelle is 'Libellé du résultat à l''écran.';
comment on column ref_statut_verification_adresse.note is 'Ce que le statut implique : bloquant, à corriger, ou simplement hors périmètre de vérification.';

comment on column ref_statut_heures_sup.code is 'Code du statut d''une demande d''heures supplémentaires.';
comment on column ref_statut_heures_sup.libelle is 'Libellé du statut à l''écran.';
comment on column ref_statut_heures_sup.note is 'Ce qui fait passer une demande dans ce statut, et qui en a le pouvoir.';

comment on column ref_compensation_heures_sup.code is 'Code du mode de compensation des heures supplémentaires : repos ou argent.';
comment on column ref_compensation_heures_sup.libelle is 'Libellé du mode de compensation à l''écran.';
comment on column ref_compensation_heures_sup.note is 'Règle applicable : le repos compensatoire est le principe, la compensation en argent l''exception encadrée.';

comment on column ref_unite_essai.code is 'Code de l''unité de durée de la période d''essai : jours, semaines, mois.';
comment on column ref_unite_essai.libelle is 'Libellé de l''unité à l''écran.';
comment on column ref_unite_essai.note is 'Durées minimales et maximales exprimées dans cette unité, et texte qui les fixe.';
