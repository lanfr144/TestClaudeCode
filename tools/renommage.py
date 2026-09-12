"""Le dictionnaire de renommage anglais → français, et rien d'autre.

    luxrh-py/.venv/Scripts/python tools/renommage.py            # vérifie et résume
    luxrh-py/.venv/Scripts/python tools/renommage.py --json     # écrit schema/renommage.json

Pourquoi ce fichier existe séparément
--------------------------------------
Le renommage touche 57 tables, environ 340 colonnes et 5 300 occurrences réparties
sur 66 fichiers. La partie mécanique — réécrire — est facile et se vérifie. La
partie difficile est de **décider des noms**, et cette décision doit être lisible,
relisible et corrigeable sans toucher au code qui l'applique.

D'où ce fichier : il ne contient que des noms. L'outil qui s'en sert est
`tools/renommer.py`.

La règle de nommage suivie
---------------------------
Celle des tables déjà écrites en français par le projet — `adresses_salarie`,
`fiche_sante`, `creneau_condition`, `cct_regle_prime`, `personne_indicateur_secours`,
`ref_type_adresse` :

- **nom d'abord, qualificatif ensuite** : `date_debut` et non `debut_date` ;
- **pluriel pour les tables**, singulier pour les colonnes ;
- **pas d'accent, pas de cédille** dans un identifiant : `societes`, `salaries`,
  `creneaux`. Les accents vivent dans les commentaires et les libellés, jamais dans
  un nom d'objet — Oracle et MySQL ne les traitent pas de la même façon, et un
  identifiant accentué demande des guillemets partout ;
- **on garde le terme métier consacré** quand il existe : `cct`, `ccss`, `iban`,
  `nace`, `rcs`, `cdd`. Traduire un sigle ne le rend pas plus clair ;
- **`_id` reste `_id`** : c'est une convention de suffixe, pas un mot anglais.

Ce qui n'est PAS renommé
-------------------------
Les 18 tables déjà françaises, et les colonnes déjà françaises qu'elles portent.
Les noms de colonnes système de PostgreSQL. Les tables du schéma `auth`, qui
appartiennent à la plateforme.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent

# ============================================================ tables

TABLES: dict[str, str] = {
    # — organisation et comptes
    "organizations":                   "organisations",
    "companies":                       "societes",
    "departments":                     "services",
    "profiles":                        "profils",
    "app_users":                       "comptes",
    "user_roles":                      "roles_compte",
    "app_secrets":                     "secrets_application",

    # — personnes
    "employees":                       "salaries",
    "employee_children":               "enfants_salarie",
    "employee_disabilities":           "handicaps_salarie",
    "employee_statuses":               "statuts_salarie",
    "employee_tax_cards":              "fiches_retenue_impot",
    "employee_sanctions":              "sanctions_salarie",
    "sanction_categories":             "categories_sanction",
    "sanction_types":                  "types_sanction",

    # — contrats
    "contracts":                       "contrats",
    "contract_amendments":             "avenants_contrat",
    "contract_pay_components":         "elements_remuneration",
    "contract_terminations":           "ruptures_contrat",
    "contract_collective_agreements":  "conventions_du_contrat",
    "probation_extensions":            "prolongations_essai",
    "interim_agencies":                "agences_interim",

    # — conventions collectives
    "collective_agreements":           "conventions_collectives",
    "company_collective_agreements":   "conventions_de_la_societe",
    "cba_rules":                       "regles_convention",
    "cba_salary_grids":                "grilles_salaires_convention",

    # — temps et planning
    "schedules":                       "plannings",
    "shifts":                          "creneaux",
    "shift_templates":                 "modeles_creneau",
    "time_entries":                    "releves_temps",
    "reference_periods":               "periodes_reference",
    "overtime_requests":               "demandes_heures_sup",
    "public_holidays":                 "jours_feries",

    # — absences
    "absences":                        "absences",
    "absence_types":                   "types_absence",
    "absence_entitlements":            "droits_absence",

    # — rémunération
    "premiums":                        "primes",
    "benefit_types":                   "types_avantage",
    "meal_voucher_grants":             "attributions_titres_repas",

    # — référentiel légal et fiscal
    "legal_parameters":                "parametres_legaux",
    "expected_parameters":             "parametres_attendus",
    "tax_brackets":                    "tranches_impot",
    "tax_credits":                     "credits_impot",

    # — cotisations et sinistres
    "company_rate_periods":            "periodes_taux_societe",
    "company_accident_claims":         "sinistres_accident_societe",
    "company_financials":              "donnees_financieres_societe",
    "headcount_snapshots":             "releves_effectif",

    # — conformité et documents
    "compliance_alerts":               "alertes_conformite",
    "documents":                       "documents",
    "document_types":                  "types_document",

    # — adresses et déplacements
    "address_zones":                   "zones_adresse",
    "address_checks":                  "controles_adresse",
    "client_sites":                    "sites_client",
    "travel_distances":                "distances_trajet",

    # — journaux
    "audit_log":                       "journal_ecritures",
    "data_access_log":                 "journal_acces",
    "export_log":                      "journal_exports",
}

# ============================================================ colonnes
#
# Deux mécanismes. Le dictionnaire ci-dessous traite les noms **exacts**. Ce qu'il
# ne couvre pas est composé à partir des TERMES, segment par segment.
#
# Une colonne reste en anglais si aucun des deux ne la connaît : l'outil le dit
# plutôt que de traduire au hasard.

COLONNES: dict[str, str] = {
    # — identité et clés
    "id":                        "id",
    "organization_id":           "organisation_id",
    "company_id":                "societe_id",
    "department_id":             "service_id",
    "employee_id":               "salarie_id",
    "contract_id":               "contrat_id",
    "collective_agreement_id":   "convention_id",
    "absence_type_id":           "type_absence_id",
    "benefit_type_id":           "type_avantage_id",
    "document_type_id":          "type_document_id",
    "client_site_id":            "site_client_id",
    "schedule_id":               "planning_id",
    "shift_id":                  "creneau_id",
    "template_id":               "modele_id",
    "time_entry_id":             "releve_temps_id",
    "termination_id":            "rupture_id",
    "interim_agency_id":         "agence_interim_id",
    "previous_contract_id":      "contrat_precedent_id",
    "amendment_contract_id":     "contrat_avenant_id",
    "certificate_document_id":   "certificat_document_id",
    "evidence_document_id":      "piece_justificative_id",
    "subject_employee_id":       "salarie_concerne_id",
    "subject_id":                "objet_id",
    "entity_id":                 "entite_id",
    "entity_table":              "entite_table",
    "child_id":                  "enfant_id",
    "user_id":                   "compte_id",
    "auth_user_id":              "compte_auth_id",
    "actor_id":                  "auteur_id",
    "actor_label":               "auteur_libelle",
    "supersedes_id":             "remplace_id",
    "origin_ref":                "reference_origine",
    "destination_ref":           "reference_destination",
    "derived_from_key":          "derive_de_cle",
    "param_key":                 "cle_parametre",
    "rule_code":                 "code_regle",
    "zone_code":                 "code_zone",
    "category_code":             "code_categorie",
    "nace_code":                 "code_nace",
    "card_reference":            "reference_carte",

    # — horodatage et auteurs
    "created_at":                "cree_le",
    "created_by":                "cree_par",
    "updated_at":                "modifie_le",
    "updated_by":                "modifie_par",
    "deleted_at":                "supprime_le",
    "deleted_by":                "supprime_par",
    "occurred_at":               "survenu_le",
    "checked_at":                "controle_le",
    "computed_at":               "calcule_le",
    "computed_by":               "calcule_par",
    "decided_at":                "decide_le",
    "decided_by":                "decide_par",
    "handled_at":                "traite_le",
    "handled_by":                "traite_par",
    "handled_note":              "note_traitement",
    "published_at":              "publie_le",
    "published_by":              "publie_par",
    "requested_at":              "demande_le",
    "requested_by":              "demande_par",
    "entered_at":                "saisi_le",
    "entered_by":                "saisi_par",
    "validated_at":              "valide_le",
    "validated_by":              "valide_par",
    "uploaded_by":               "depose_par",
    "read_by":                   "lu_par",
    "signed_at":                 "signe_le",
    "delivered_at":              "remis_le",
    "first_seen_at":             "vu_la_premiere_fois_le",
    "hr_validated_at":           "valide_rh_le",
    "hr_validated_by":           "valide_rh_par",
    "certificate_uploaded_at":   "certificat_depose_le",
    "certificate_received_at":   "certificat_recu_le",
    "certificate_original_received_at": "certificat_original_recu_le",
    "certificate_received":      "certificat_recu",
    "certificate_original_received": "certificat_original_recu",
    "employee_accepted_at":      "accepte_par_salarie_le",

    # — périodes et dates
    "valid_from":                "debut_validite",
    "valid_to":                  "fin_validite",
    "start_date":                "date_debut",
    "end_date":                  "date_fin",
    "start_time":                "heure_debut",
    "end_time":                  "heure_fin",
    "from_date":                 "date_debut",
    "to_date":                   "date_fin",
    "effective_date":            "date_effet",
    "effective_from":            "effet_du",
    "effective_to":              "effet_au",
    "due_date":                  "date_echeance",
    "birth_date":                "date_naissance",
    "actual_birth_date":         "date_naissance_reelle",
    "expected_birth_date":       "date_naissance_prevue",
    "adoption_date":             "date_adoption",
    "holiday_date":              "date_ferie",
    "shift_date":                "date_creneau",
    "entry_date":                "date_releve",
    "issued_on":                 "emis_le",
    "granted_on":                "attribue_le",
    "declared_on":               "declare_le",
    "notified_on":               "notifie_le",
    "recognized_on":             "reconnu_le",
    "contested_on":              "conteste_le",
    "prorated_on_hours":         "proratise_sur_heures",
    "employee_heard_on":         "salarie_entendu_le",
    "facts_on":                  "faits_le",
    "facts_known_on":            "faits_connus_le",
    "internal_rules_adopted_on": "reglement_interieur_adopte_le",
    "waiver_agreed_on":          "renonciation_convenue_le",
    "expires_on":                "expire_le",
    "retention_until":           "conservation_jusquau",
    "period_start":              "debut_periode",
    "period_end":                "fin_periode",
    "week_start":                "debut_semaine",
    "notice_start":              "debut_preavis",
    "notice_end":                "fin_preavis",
    "career_start_date":         "date_debut_carriere",
    "season_label":              "libelle_saison",
    "year":                      "annee",
    "month":                     "mois",
    "months":                    "mois",
    "period_months":             "duree_mois",
    "validity_months":           "validite_mois",
    "severance_months":          "indemnite_mois",
    "reference_period_months":   "periode_reference_mois",
    "fiscal_year":               "exercice",

    # — identité des personnes
    "first_name":                "prenom",
    "last_name":                 "nom",
    "full_name":                 "nom_complet",
    "sex":                       "sexe",
    "email":                     "courriel",
    "phone":                     "telephone",
    "national_id_enc":           "matricule_national_chiffre",
    "national_id_hint":          "matricule_national_indice",
    "iban_enc":                  "iban_chiffre",
    "userid":                    "identifiant",
    "password_hash":             "empreinte_mot_de_passe",
    "is_admin":                  "est_admin",
    "is_org_admin":              "est_admin_organisation",
    "role":                      "role",
    "relationship":              "lien_parente",
    "relationship_degree":       "degre_parente",
    "is_dependent":              "a_charge",

    # — adresses
    "address_line":              "ligne",
    "postal_code":               "code_postal",
    "postal_from":               "code_postal_du",
    "postal_to":                 "code_postal_au",
    "city":                      "localite",
    "country":                   "pays",
    "latitude":                  "latitude",
    "longitude":                 "longitude",
    "residency":                 "residence",
    "work_place":                "lieu_travail",
    "commute_distance_km":       "distance_domicile_km",
    "distance_km":               "distance_km",
    "duration_minutes":          "duree_minutes",
    "client_name":               "nom_client",

    # — société
    "legal_name":                "raison_sociale",
    "legal_form":                "forme_juridique",
    "rcs_number":                "numero_rcs",
    "ccss_matricule":            "matricule_ccss",
    "internal_rules_reference":  "reference_reglement_interieur",
    "revenue":                   "chiffre_affaires",
    "profit":                    "resultat",
    "headcount":                 "effectif",
    "activity_class":            "classe_activite",
    "accident_risk_class":       "classe_risque_accident",
    "accident_factor":           "facteur_accident",
    "derived_factor":            "facteur_derive",
    "derivation_tolerance":      "tolerance_derivation",
    "mutuality_class":           "classe_mutualite",
    "employee_share":            "part_salariale",
    "claim_count":               "nombre_sinistres",
    "cost":                      "cout",

    # — contrat
    "job_title":                 "intitule_poste",
    "job_description":           "description_poste",
    "profession":                "profession",
    "qualification":             "qualification",
    "employee_category":         "categorie_professionnelle",
    "monthly_gross":             "brut_mensuel",
    "weekly_hours":              "heures_hebdomadaires",
    "days_per_week":             "jours_par_semaine",
    "is_part_time":              "est_temps_partiel",
    "work_distribution":         "repartition_travail",
    "probation_length":          "duree_essai",
    "probation_unit":            "unite_essai",
    "cdd_reason":                "motif_cdd",
    "renewal_count":             "nombre_renouvellements",
    "non_compete_clause":        "clause_non_concurrence",
    "exclusivity_clause":        "clause_exclusivite",
    "is_management":             "est_cadre",
    "is_autonomous":             "est_autonome",
    "is_mobile":                 "est_mobile",
    "mission_reason":            "motif_mission",
    "apprenticeship_level":      "niveau_apprentissage",
    "apprenticeship_year":       "annee_apprentissage",
    "index_ref":                 "indice_reference",
    "in_salary_reference":       "dans_assiette_salaire",
    "seniority_from_years":      "anciennete_de_annees",
    "seniority_to_years":        "anciennete_a_annees",
    "version":                   "version",
    "notice_waived":             "preavis_renonce",
    "waiver_note":               "note_renonciation",
    "waiver_compensation":       "compensation_renonciation",
    "is_personal_ground":        "motif_personnel",
    "is_gross_misconduct":       "faute_grave",
    "is_recoverable":            "recuperable",
    "recovery_reason":           "motif_recuperation",

    # — rémunération
    "amount":                    "montant",
    "monthly_amount":            "montant_mensuel",
    "monthly_allowance":         "indemnite_mensuelle",
    "face_value":                "valeur_faciale",
    "voucher_count":             "nombre_titres",
    "is_taxable":                "imposable",
    "is_contributory":           "cotisable",
    "exempt_pct":                "part_exoneree_pct",
    "rate":                      "taux",
    "rate_pct":                  "taux_pct",
    "rate_over_min":             "taux_au_dessus_minimum",
    "base_tax":                  "impot_base",
    "basis":                     "assiette",
    "bracket_min":               "tranche_min",
    "bracket_max":               "tranche_max",
    "income_min":                "revenu_min",
    "income_max":                "revenu_max",
    "tax_class":                 "classe_impot",
    "periodicity":               "periodicite",
    "credits":                   "credits",
    "other_deductions_monthly":  "autres_deductions_mensuelles",
    "professional_expenses_monthly": "frais_professionnels_mensuels",
    "hours_credit_monthly":      "credit_heures_mensuel",
    "valuation_method":          "methode_evaluation",
    "valuation_params":          "parametres_evaluation",
    "compensation":              "compensation",
    "applies_to_classes":        "classes_visees",
    "applies_to_residency":      "residences_visees",

    # — temps
    "hours":                     "heures",
    "planned_hours":             "heures_prevues",
    "worked_hours":              "heures_travaillees",
    "overtime_hours":            "heures_supplementaires",
    "night_hours":               "heures_nuit",
    "sunday_hours":              "heures_dimanche",
    "holiday_hours":             "heures_ferie",
    "night_work":                "travail_nuit",
    "break_minutes":             "pause_minutes",
    "minutes":                   "minutes",
    "min_evening_coverage":      "couverture_soir_min",
    "days":                      "jours",
    "days_count":                "nombre_jours",
    "days_added":                "jours_ajoutes",
    "days_lost":                 "jours_perdus",
    "block_days":                "jours_bloc",
    "career_cap_days":           "plafond_carriere_jours",
    "annual_leave_days":         "jours_conge_annuel",
    "extra_leave_days_override": "jours_conge_supplementaires_forces",
    "alert_days_before":         "alerte_jours_avant",
    "counts_against_leave":      "impute_sur_conge",

    # — absences et sanctions
    "status":                    "statut",
    "state":                     "etat",
    "reason":                    "motif",
    "rejected_reason":           "motif_refus",
    "decision_note":             "note_decision",
    "declared_by_employee":      "declare_par_salarie",
    "requires_certificate":      "certificat_exige",
    "requires_evidence":         "piece_exigee",
    "requires_internal_rules":   "reglement_interieur_exige",
    "sanction_type":             "type_sanction",
    "employee_response":         "reponse_salarie",
    "contest_outcome":           "issue_contestation",
    "affects_presence":          "suspend_presence",
    "affects_pay":               "affecte_paie",
    "ends_contract":             "rompt_contrat",
    "is_contract_change":        "modifie_contrat",
    "needs_notice":              "preavis_du",
    "is_mandatory":              "obligatoire",
    "is_paid":                   "remunere",
    "is_sensitive":              "sensible",
    "is_verified":               "verifie",
    "is_validated":              "valide",
    "is_complete":               "complet",
    "is_active":                 "actif",

    # — conformité, journaux, documents
    "severity":                  "severite",
    "title":                     "titre",
    "detail":                    "detail",
    "consequence":               "consequence",
    "message":                   "message",
    "comment":                   "commentaire",
    "action":                    "action",
    "changes":                   "modifications",
    "old_value":                 "ancienne_valeur",
    "new_value":                 "nouvelle_valeur",
    "row_count":                 "nombre_lignes",
    "byte_size":                 "taille_octets",
    "size_bytes":                "taille_octets",
    "mime_type":                 "type_mime",
    "storage_path":              "chemin_stockage",
    "source_ip":                 "ip_source",
    "user_agent":                "agent_client",
    "request_id":                "identifiant_requete",
    "subject_kind":              "genre_objet",
    "user_company_name":         "nom_societe_utilisateur",
    "privacy_opt_out":           "refus_partage",

    # — référentiel
    "label":                     "libelle",
    "name":                      "nom",
    "code":                      "code",
    "key":                       "cle",
    "kind":                      "genre",
    "description":               "description",
    "note":                      "note",
    "source":                    "source",
    "source_url":                "url_source",
    "legal_ref":                 "reference_legale",
    "article":                   "article",
    "authority":                 "autorite",
    "sector":                    "secteur",
    "scope":                     "portee",
    "block":                     "bloc",
    "rules":                     "regles",
    "rank":                      "rang",
    "stage":                     "echelon",
    "unit":                      "unite",
    "color":                     "couleur",
    "secret":                    "secret",
    "frequency_note":            "note_frequence",
    "value_num":                 "valeur_num",
    "value_text":                "valeur_texte",
    "value_json":                "valeur_json",
    "family":                    "famille",
    "category":                  "categorie",
    "allergies":                 "allergies",
}


def verifier() -> int:
    """Confronte le dictionnaire au catalogue : rien d'oublié, rien d'inventé."""
    catalogue = json.loads((RACINE / "schema" / "catalogue.json").read_text(encoding="utf-8"))
    tables_base = {t["name"] for t in catalogue["tables"]}
    colonnes_base = {c["name"] for t in catalogue["tables"] for c in t["columns"]}

    inconnues_t = sorted(set(TABLES) - tables_base)
    inconnues_c = sorted(set(COLONNES) - colonnes_base)
    deja_fr = ("ref_", "cct_", "adresses_", "fiche_", "creneau_", "personne_")
    manquantes_t = sorted(t for t in tables_base
                          if not t.startswith(deja_fr) and t not in TABLES)
    manquantes_c = sorted(c for c in colonnes_base if c not in COLONNES)

    # Deux noms français identiques pour deux objets différents : collision.
    collisions = [v for v in set(TABLES.values())
                  if list(TABLES.values()).count(v) > 1]

    # Le risque le plus sournois : deux colonnes DIFFÉRENTES d'une MÊME table
    # traduites par le même nom. `from_date` et `start_date` deviennent tous deux
    # `date_debut` — inoffensif tant qu'ils ne cohabitent pas, fatal sinon. Le
    # dictionnaire ne peut pas le voir seul : il faut le confronter au catalogue.
    for table in catalogue["tables"]:
        vus: dict[str, str] = {}
        for colonne in table["columns"]:
            ancien = colonne["name"]
            nouveau = COLONNES.get(ancien, ancien)
            if nouveau in vus and vus[nouveau] != ancien:
                collisions.append(
                    f"{table['name']} : {vus[nouveau]} et {ancien} "
                    f"deviendraient tous deux {nouveau}")
            vus[nouveau] = ancien

    print(f"Tables   : {len(TABLES)} traduites, {len(tables_base) - len(TABLES)} "
          f"déjà françaises ou hors périmètre")
    print(f"Colonnes : {len(COLONNES)} traduites sur {len(colonnes_base)} distinctes")

    souci = 0
    for nom, liste in (("table absente de la base", inconnues_t),
                       ("colonne absente de la base", inconnues_c),
                       ("table anglaise sans traduction", manquantes_t),
                       ("nom français en double", collisions)):
        if liste:
            souci += len(liste)
            print(f"\n{len(liste)} {nom} :")
            for x in liste:
                print(f"  - {x}")

    if manquantes_c:
        # Celles-là ne sont pas forcément un défaut : beaucoup sont déjà françaises.
        anglaises = [c for c in manquantes_c if not _semble_francais(c)]
        print(f"\n{len(manquantes_c)} colonne(s) hors dictionnaire, "
              f"dont {len(anglaises)} qui ne semblent pas françaises :")
        for x in anglaises:
            print(f"  - {x}")
        souci += len(anglaises)

    print()
    print("Dictionnaire complet et cohérent." if souci == 0
          else f"{souci} point(s) à reprendre avant de lancer le renommage.")
    return 0 if souci == 0 else 1


_MOTS_FR = (
    "debut", "fin", "validite", "libelle", "ordre", "note", "code", "type", "nature",
    "taux", "heure", "date", "maj", "par", "le", "salarie", "enfant", "pays", "unite",
    "prime", "condition", "adresse", "ligne", "localite", "postal", "sante", "secours",
    "indicateur", "visible", "dispatching", "pose", "constate", "prestation", "montant",
    "assiette", "categorie", "famille", "seuil", "minutes", "sexe", "legal", "origine",
    "consigne", "precision", "lieu", "groupe", "sanguin", "pathologies", "medecin",
    "telephone", "traitant", "handicap", "situation", "rang", "proposition", "parente",
    "refus", "photos", "societe", "evenements", "invitation", "souhaite",
    "confidentialite", "proposee", "sert", "fiscal", "tournees", "alpha2", "alpha3",
    "frontalier", "nom", "lie", "aux", "conditions", "visee", "compensation",
)


def _semble_francais(nom: str) -> bool:
    return any(seg in _MOTS_FR for seg in nom.split("_"))


def main() -> int:
    code = verifier()
    if "--json" in sys.argv:
        cible = RACINE / "schema" / "renommage.json"
        cible.write_text(
            json.dumps({"tables": TABLES, "colonnes": COLONNES},
                       ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8", newline="\n")
        print(f"{cible} écrit.")
    return code


if __name__ == "__main__":
    sys.exit(main())
