set search_path = public;

create table if not exists renommage_colonnes (ancien text primary key, nouveau text not null);
truncate renommage_colonnes;
insert into renommage_colonnes (ancien, nouveau) values
  ('absence_type_id', 'type_absence_id'),
  ('accident_factor', 'facteur_accident'),
  ('accident_risk_class', 'classe_risque_accident'),
  ('activity_class', 'classe_activite'),
  ('actor_id', 'auteur_id'),
  ('actor_label', 'auteur_libelle'),
  ('actual_birth_date', 'date_naissance_reelle'),
  ('address_line', 'ligne'),
  ('adoption_date', 'date_adoption'),
  ('affects_pay', 'affecte_paie'),
  ('affects_presence', 'suspend_presence'),
  ('alert_days_before', 'alerte_jours_avant'),
  ('amendment_contract_id', 'contrat_avenant_id'),
  ('annual_leave_days', 'jours_conge_annuel'),
  ('applies_to_classes', 'classes_visees'),
  ('applies_to_residency', 'residences_visees'),
  ('apprenticeship_level', 'niveau_apprentissage'),
  ('apprenticeship_year', 'annee_apprentissage'),
  ('auth_user_id', 'compte_auth_id'),
  ('base_tax', 'impot_base'),
  ('benefit_type_id', 'type_avantage_id'),
  ('birth_date', 'date_naissance'),
  ('block_days', 'jours_bloc'),
  ('bracket_max', 'tranche_max'),
  ('bracket_min', 'tranche_min'),
  ('break_minutes', 'pause_minutes'),
  ('byte_size', 'taille_octets'),
  ('card_reference', 'reference_carte'),
  ('career_cap_days', 'plafond_carriere_jours'),
  ('career_start_date', 'date_debut_carriere'),
  ('category_code', 'code_categorie'),
  ('ccss_matricule', 'matricule_ccss'),
  ('cdd_reason', 'motif_cdd'),
  ('certificate_document_id', 'certificat_document_id'),
  ('certificate_original_received', 'certificat_original_recu'),
  ('certificate_original_received_at', 'certificat_original_recu_le'),
  ('certificate_received', 'certificat_recu'),
  ('certificate_received_at', 'certificat_recu_le'),
  ('certificate_uploaded_at', 'certificat_depose_le'),
  ('checked_at', 'controle_le'),
  ('child_id', 'enfant_id'),
  ('claim_count', 'nombre_sinistres'),
  ('client_name', 'nom_client'),
  ('client_site_id', 'site_client_id'),
  ('collective_agreement_id', 'convention_id'),
  ('commute_distance_km', 'distance_domicile_km'),
  ('company_id', 'societe_id'),
  ('computed_at', 'calcule_le'),
  ('computed_by', 'calcule_par'),
  ('contest_outcome', 'issue_contestation'),
  ('contested_on', 'conteste_le'),
  ('contract_id', 'contrat_id'),
  ('counts_against_leave', 'impute_sur_conge'),
  ('covers_since', 'couvre_depuis'),
  ('created_at', 'cree_le'),
  ('created_by', 'cree_par'),
  ('days_added', 'jours_ajoutes'),
  ('days_count', 'nombre_jours'),
  ('days_lost', 'jours_perdus'),
  ('days_per_week', 'jours_par_semaine'),
  ('decided_at', 'decide_le'),
  ('decided_by', 'decide_par'),
  ('decision_note', 'note_decision'),
  ('declared_by_employee', 'declare_par_salarie'),
  ('declared_on', 'declare_le'),
  ('deleted_at', 'supprime_le'),
  ('deleted_by', 'supprime_par'),
  ('delivered_at', 'remis_le'),
  ('department_id', 'service_id'),
  ('derivation_tolerance', 'tolerance_derivation'),
  ('derived_factor', 'facteur_derive'),
  ('derived_from_key', 'derive_de_cle'),
  ('destination_ref', 'reference_destination'),
  ('document_type_id', 'type_document_id'),
  ('due_date', 'date_echeance'),
  ('duration_minutes', 'duree_minutes'),
  ('earliest_covered', 'couvert_depuis'),
  ('effective_date', 'date_effet'),
  ('effective_from', 'effet_du'),
  ('effective_to', 'effet_au'),
  ('employee_accepted_at', 'accepte_par_salarie_le'),
  ('employee_category', 'categorie_professionnelle'),
  ('employee_heard_on', 'salarie_entendu_le'),
  ('employee_id', 'salarie_id'),
  ('employee_response', 'reponse_salarie'),
  ('employee_share', 'part_salariale'),
  ('end_date', 'date_fin'),
  ('end_time', 'heure_fin'),
  ('ends_contract', 'rompt_contrat'),
  ('entered_at', 'saisi_le'),
  ('entered_by', 'saisi_par'),
  ('entity_id', 'entite_id'),
  ('entity_table', 'entite_table'),
  ('entry_date', 'date_releve'),
  ('evidence_document_id', 'piece_justificative_id'),
  ('exclusivity_clause', 'clause_exclusivite'),
  ('exempt_pct', 'part_exoneree_pct'),
  ('expected_birth_date', 'date_naissance_prevue'),
  ('expires_on', 'expire_le'),
  ('extra_leave_days_override', 'jours_conge_supplementaires_forces'),
  ('face_value', 'valeur_faciale'),
  ('facts_known_on', 'faits_connus_le'),
  ('facts_on', 'faits_le'),
  ('first_name', 'prenom'),
  ('first_seen_at', 'vu_la_premiere_fois_le'),
  ('fiscal_year', 'exercice'),
  ('frequency_note', 'note_frequence'),
  ('from_date', 'date_debut'),
  ('full_name', 'nom_complet'),
  ('gap_days', 'jours_manquants'),
  ('gap_from', 'trou_du'),
  ('gap_to', 'trou_au'),
  ('granted_on', 'attribue_le'),
  ('handled_at', 'traite_le'),
  ('handled_by', 'traite_par'),
  ('handled_note', 'note_traitement'),
  ('holiday_date', 'date_ferie'),
  ('holiday_hours', 'heures_ferie'),
  ('hours_credit_monthly', 'credit_heures_mensuel'),
  ('hr_validated_at', 'valide_rh_le'),
  ('hr_validated_by', 'valide_rh_par'),
  ('iban_enc', 'iban_chiffre'),
  ('in_salary_reference', 'dans_assiette_salaire'),
  ('income_max', 'revenu_max'),
  ('income_min', 'revenu_min'),
  ('index_ref', 'indice_reference'),
  ('interim_agency_id', 'agence_interim_id'),
  ('internal_rules_adopted_on', 'reglement_interieur_adopte_le'),
  ('internal_rules_reference', 'reference_reglement_interieur'),
  ('is_active', 'actif'),
  ('is_admin', 'est_admin'),
  ('is_autonomous', 'est_autonome'),
  ('is_complete', 'complet'),
  ('is_contract_change', 'modifie_contrat'),
  ('is_contributory', 'cotisable'),
  ('is_dependent', 'a_charge'),
  ('is_gross_misconduct', 'faute_grave'),
  ('is_management', 'est_cadre'),
  ('is_mandatory', 'obligatoire'),
  ('is_mobile', 'est_mobile'),
  ('is_org_admin', 'est_admin_organisation'),
  ('is_paid', 'remunere'),
  ('is_part_time', 'est_temps_partiel'),
  ('is_personal_ground', 'motif_personnel'),
  ('is_recoverable', 'recuperable'),
  ('is_sensitive', 'sensible'),
  ('is_taxable', 'imposable'),
  ('is_validated', 'valide'),
  ('is_verified', 'verifie'),
  ('issued_on', 'emis_le'),
  ('job_description', 'description_poste'),
  ('job_title', 'intitule_poste'),
  ('last_name', 'nom'),
  ('legal_form', 'forme_juridique'),
  ('legal_name', 'raison_sociale'),
  ('legal_ref', 'reference_legale'),
  ('mime_type', 'type_mime'),
  ('min_evening_coverage', 'couverture_soir_min'),
  ('mission_reason', 'motif_mission'),
  ('monthly_allowance', 'indemnite_mensuelle'),
  ('monthly_amount', 'montant_mensuel'),
  ('monthly_gross', 'brut_mensuel'),
  ('mutuality_class', 'classe_mutualite'),
  ('nace_code', 'code_nace'),
  ('national_id', 'matricule_national'),
  ('national_id_enc', 'matricule_national_chiffre'),
  ('national_id_hint', 'matricule_national_indice'),
  ('new_value', 'nouvelle_valeur'),
  ('night_hours', 'heures_nuit'),
  ('night_work', 'travail_nuit'),
  ('non_compete_clause', 'clause_non_concurrence'),
  ('notice_end', 'fin_preavis'),
  ('notice_start', 'debut_preavis'),
  ('notice_waived', 'preavis_renonce'),
  ('notified_on', 'notifie_le'),
  ('occurred_at', 'survenu_le'),
  ('old_value', 'ancienne_valeur'),
  ('organization_id', 'organisation_id'),
  ('origin_ref', 'reference_origine'),
  ('other_deductions_monthly', 'autres_deductions_mensuelles'),
  ('overtime_hours', 'heures_supplementaires'),
  ('param_key', 'cle_parametre'),
  ('password_hash', 'empreinte_mot_de_passe'),
  ('period_end', 'fin_periode'),
  ('period_months', 'duree_mois'),
  ('period_start', 'debut_periode'),
  ('planned_hours', 'heures_prevues'),
  ('postal_code', 'code_postal'),
  ('postal_from', 'code_postal_du'),
  ('postal_to', 'code_postal_au'),
  ('previous_contract_id', 'contrat_precedent_id'),
  ('privacy_opt_out', 'refus_partage'),
  ('probation_length', 'duree_essai'),
  ('probation_unit', 'unite_essai'),
  ('professional_expenses_monthly', 'frais_professionnels_mensuels'),
  ('prorated_on_hours', 'proratise_sur_heures'),
  ('published_at', 'publie_le'),
  ('published_by', 'publie_par'),
  ('rate_over_min', 'taux_au_dessus_minimum'),
  ('rate_pct', 'taux_pct'),
  ('rcs_number', 'numero_rcs'),
  ('read_by', 'lu_par'),
  ('recognized_on', 'reconnu_le'),
  ('recovery_reason', 'motif_recuperation'),
  ('reference_period_months', 'periode_reference_mois'),
  ('rejected_reason', 'motif_refus'),
  ('relationship_degree', 'degre_parente'),
  ('renewal_count', 'nombre_renouvellements'),
  ('request_id', 'identifiant_requete'),
  ('requested_at', 'demande_le'),
  ('requested_by', 'demande_par'),
  ('requires_certificate', 'certificat_exige'),
  ('requires_evidence', 'piece_exigee'),
  ('requires_internal_rules', 'reglement_interieur_exige'),
  ('retention_until', 'conservation_jusquau'),
  ('row_count', 'nombre_lignes'),
  ('rule_code', 'code_regle'),
  ('sanction_type', 'type_sanction'),
  ('schedule_id', 'planning_id'),
  ('season_label', 'libelle_saison'),
  ('seniority_from_years', 'anciennete_de_annees'),
  ('seniority_to_years', 'anciennete_a_annees'),
  ('severance_months', 'indemnite_mois'),
  ('shift_date', 'date_creneau'),
  ('shift_id', 'creneau_id'),
  ('signed_at', 'signe_le'),
  ('size_bytes', 'taille_octets'),
  ('source_ip', 'ip_source'),
  ('source_key', 'cle_source'),
  ('source_url', 'url_source'),
  ('start_date', 'date_debut'),
  ('start_time', 'heure_debut'),
  ('storage_path', 'chemin_stockage'),
  ('subject_employee_id', 'salarie_concerne_id'),
  ('subject_id', 'objet_id'),
  ('subject_kind', 'genre_objet'),
  ('sunday_hours', 'heures_dimanche'),
  ('supersedes_id', 'remplace_id'),
  ('template_id', 'modele_id'),
  ('termination_id', 'rupture_id'),
  ('time_entry_id', 'releve_temps_id'),
  ('to_date', 'date_fin'),
  ('updated_at', 'modifie_le'),
  ('updated_by', 'modifie_par'),
  ('uploaded_by', 'depose_par'),
  ('user_agent', 'agent_client'),
  ('user_company_name', 'nom_societe_utilisateur'),
  ('user_id', 'compte_id'),
  ('valid_from', 'debut_validite'),
  ('valid_to', 'fin_validite'),
  ('validated_at', 'valide_le'),
  ('validated_by', 'valide_par'),
  ('validity_months', 'validite_mois'),
  ('valuation_method', 'methode_evaluation'),
  ('valuation_params', 'parametres_evaluation'),
  ('value_json', 'valeur_json'),
  ('value_num', 'valeur_num'),
  ('value_text', 'valeur_texte'),
  ('voucher_count', 'nombre_titres'),
  ('waiver_agreed_on', 'renonciation_convenue_le'),
  ('waiver_compensation', 'compensation_renonciation'),
  ('waiver_note', 'note_renonciation'),
  ('week_start', 'debut_semaine'),
  ('weekly_hours', 'heures_hebdomadaires'),
  ('work_distribution', 'repartition_travail'),
  ('work_place', 'lieu_travail'),
  ('worked_hours', 'heures_travaillees'),
  ('zone_code', 'code_zone'),
  ('absence_category', 'categorie_absence'),
  ('absence_status', 'statut_absence'),
  ('alert_state', 'etat_alerte'),
  ('app_role', 'role_application'),
  ('cba_block', 'bloc_convention'),
  ('cba_scope', 'portee_convention'),
  ('contract_kind', 'genre_contrat'),
  ('contract_status', 'statut_contrat'),
  ('document_stage', 'etape_document'),
  ('employee_status_kind', 'genre_statut_salarie'),
  ('org_kind', 'genre_organisation'),
  ('param_family', 'famille_parametre'),
  ('pay_component_kind', 'genre_element_remuneration'),
  ('qualification_kind', 'genre_qualification'),
  ('residency_kind', 'genre_residence'),
  ('schedule_status', 'statut_planning'),
  ('severity_kind', 'genre_severite'),
  ('sex_kind', 'genre_sexe'),
  ('tax_class', 'classe_impot'),
  ('tax_periodicity', 'periodicite_impot');

do $types$
declare r record;
begin
  for r in
    select t.typname as ancien, m.nouveau
    from renommage_colonnes m
    join pg_type t on t.typname = m.ancien and t.typtype = 'e'
    join pg_namespace n on n.oid = t.typnamespace and n.nspname = 'public'
  loop
    execute format('alter type public.%I rename to %I', r.ancien, r.nouveau);
  end loop;
end $types$;

do $colonnes$
declare
  r       record;
  v_faits int := 0;
begin
  for r in
    select c.relname as tbl, a.attname as ancien, m.nouveau
    from renommage_colonnes m
    join pg_attribute a on a.attname = m.ancien and a.attnum > 0 and not a.attisdropped
    join pg_class c on c.oid = a.attrelid and c.relkind = 'r'
    join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
    where c.relname <> 'renommage_colonnes'
    order by c.relname, a.attnum
  loop
    execute format('alter table public.%I rename column %I to %I',
                   r.tbl, r.ancien, r.nouveau);
    v_faits := v_faits + 1;
  end loop;
  raise notice '% colonne(s) renommee(s).', v_faits;
end $colonnes$;

do $fonctions$
declare
  f            record;
  p            record;
  v_def        text;
  v_avant      text;
  v_droits     text[];
  v_g          text;
  v_touchees   int := 0;
  v_recreees   int := 0;
begin
  for f in
    select p2.oid, p2.proname, p2.proacl,
           pg_get_function_identity_arguments(p2.oid) as args
    from pg_proc p2
    join pg_namespace n on n.oid = p2.pronamespace and n.nspname = 'public'
    where p2.prokind = 'f'
      and not exists (select 1 from pg_depend d where d.objid = p2.oid and d.deptype = 'e')
  loop
    v_def := pg_get_functiondef(f.oid);
    v_avant := v_def;
    for p in select * from renommage_colonnes loop
      v_def := regexp_replace(v_def, '\m' || p.ancien || '\M', p.nouveau, 'g');
    end loop;

    -- ROW_COUNT est un mot-cle de GET DIAGNOSTICS, pas une colonne. Le journal
    -- des acces porte une colonne du meme nom : la substitution l'atteignait
    -- aussi et produisait « unrecognized GET DIAGNOSTICS item ». On restitue le
    -- mot-cle la ou il est un mot-cle.
    v_def := regexp_replace(v_def,
               '(get\s+diagnostics\s+[a-zA-Z_0-9]+\s*=\s*)nombre_lignes',
               '\1row_count', 'gi');

    if v_def is distinct from v_avant then
      begin
        execute v_def;
      exception when others then
        select coalesce(array_agg(
                 format('grant execute on function public.%I(%s) to %I',
                        f.proname, f.args, a.grantee::regrole::text)), '{}')
          into v_droits
        from aclexplode(f.proacl) a
        where a.privilege_type = 'EXECUTE' and a.grantee <> 0;

        execute format('drop function public.%I(%s)', f.proname, f.args);
        execute v_def;

        execute format('revoke execute on function public.%I(%s) from public',
                       f.proname, f.args);
        foreach v_g in array v_droits loop
          execute v_g;
        end loop;
        v_recreees := v_recreees + 1;
      end;
      v_touchees := v_touchees + 1;
    end if;
  end loop;
  raise notice '% fonction(s) reconstruite(s), dont % recreees.', v_touchees, v_recreees;
end $fonctions$;

drop table renommage_colonnes;
