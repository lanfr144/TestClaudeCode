export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      absences: {
        Row: {
          absence_parente_id: string | null
          certificat_depose_le: string | null
          certificat_document_id: string | null
          certificat_original_recu: boolean
          certificat_original_recu_le: string | null
          certificat_recu: boolean
          certificat_recu_le: string | null
          commentaire: string | null
          cree_le: string
          date_debut: string
          date_fin: string
          decide_le: string | null
          decide_par: string | null
          declare_par_salarie: boolean
          demande_par: string | null
          enfant_id: string | null
          id: string
          nombre_jours: number
          note_decision: string | null
          proposee_par: string | null
          rang_proposition: number
          salarie_id: string
          societe_id: string
          statut: Database["public"]["Enums"]["statut_absence"]
          type_absence_id: string
        }
        Insert: {
          absence_parente_id?: string | null
          certificat_depose_le?: string | null
          certificat_document_id?: string | null
          certificat_original_recu?: boolean
          certificat_original_recu_le?: string | null
          certificat_recu?: boolean
          certificat_recu_le?: string | null
          commentaire?: string | null
          cree_le?: string
          date_debut: string
          date_fin: string
          decide_le?: string | null
          decide_par?: string | null
          declare_par_salarie?: boolean
          demande_par?: string | null
          enfant_id?: string | null
          id?: string
          nombre_jours?: number
          note_decision?: string | null
          proposee_par?: string | null
          rang_proposition?: number
          salarie_id: string
          societe_id: string
          statut?: Database["public"]["Enums"]["statut_absence"]
          type_absence_id: string
        }
        Update: {
          absence_parente_id?: string | null
          certificat_depose_le?: string | null
          certificat_document_id?: string | null
          certificat_original_recu?: boolean
          certificat_original_recu_le?: string | null
          certificat_recu?: boolean
          certificat_recu_le?: string | null
          commentaire?: string | null
          cree_le?: string
          date_debut?: string
          date_fin?: string
          decide_le?: string | null
          decide_par?: string | null
          declare_par_salarie?: boolean
          demande_par?: string | null
          enfant_id?: string | null
          id?: string
          nombre_jours?: number
          note_decision?: string | null
          proposee_par?: string | null
          rang_proposition?: number
          salarie_id?: string
          societe_id?: string
          statut?: Database["public"]["Enums"]["statut_absence"]
          type_absence_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "absence_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "absences_absence_parente_id_fkey"
            columns: ["absence_parente_id"]
            isOneToOne: false
            referencedRelation: "absences"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "absences_absence_type_id_fkey"
            columns: ["type_absence_id"]
            isOneToOne: false
            referencedRelation: "types_absence"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "absences_child_id_fkey"
            columns: ["enfant_id"]
            isOneToOne: false
            referencedRelation: "enfants_salarie"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "absences_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      adresses_salarie: {
        Row: {
          code_postal: string | null
          cree_le: string
          cree_par: string | null
          debut_validite: string
          fin_validite: string
          id: string
          latitude: number | null
          ligne: string | null
          localite: string | null
          longitude: number | null
          note: string | null
          origine: string
          pays: string
          salarie_id: string
          societe_id: string
          supprime_le: string | null
          supprime_par: string | null
          type_adresse: string
        }
        Insert: {
          code_postal?: string | null
          cree_le?: string
          cree_par?: string | null
          debut_validite?: string
          fin_validite?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          note?: string | null
          origine?: string
          pays?: string
          salarie_id: string
          societe_id: string
          supprime_le?: string | null
          supprime_par?: string | null
          type_adresse: string
        }
        Update: {
          code_postal?: string | null
          cree_le?: string
          cree_par?: string | null
          debut_validite?: string
          fin_validite?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          note?: string | null
          origine?: string
          pays?: string
          salarie_id?: string
          societe_id?: string
          supprime_le?: string | null
          supprime_par?: string | null
          type_adresse?: string
        }
        Relationships: [
          {
            foreignKeyName: "adr_appartient_au_salarie"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "adresses_salarie_type_adresse_fkey"
            columns: ["type_adresse"]
            isOneToOne: false
            referencedRelation: "ref_type_adresse"
            referencedColumns: ["code"]
          },
        ]
      }
      agences_interim: {
        Row: {
          code_postal: string | null
          cree_le: string
          id: string
          ligne: string | null
          localite: string | null
          matricule_ccss: string | null
          nom: string
          numero_rcs: string | null
          organisation_id: string
        }
        Insert: {
          code_postal?: string | null
          cree_le?: string
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_ccss?: string | null
          nom: string
          numero_rcs?: string | null
          organisation_id: string
        }
        Update: {
          code_postal?: string | null
          cree_le?: string
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_ccss?: string | null
          nom?: string
          numero_rcs?: string | null
          organisation_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "agences_interim_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
        ]
      }
      alertes_conformite: {
        Row: {
          code_regle: string
          consequence: string | null
          date_echeance: string | null
          detail: string
          etat: Database["public"]["Enums"]["etat_alerte"]
          id: string
          note_traitement: string | null
          reference_legale: string | null
          salarie_id: string | null
          severite: Database["public"]["Enums"]["genre_severite"]
          societe_id: string
          titre: string
          traite_le: string | null
          traite_par: string | null
          vu_la_premiere_fois_le: string
        }
        Insert: {
          code_regle: string
          consequence?: string | null
          date_echeance?: string | null
          detail: string
          etat?: Database["public"]["Enums"]["etat_alerte"]
          id?: string
          note_traitement?: string | null
          reference_legale?: string | null
          salarie_id?: string | null
          severite: Database["public"]["Enums"]["genre_severite"]
          societe_id: string
          titre: string
          traite_le?: string | null
          traite_par?: string | null
          vu_la_premiere_fois_le?: string
        }
        Update: {
          code_regle?: string
          consequence?: string | null
          date_echeance?: string | null
          detail?: string
          etat?: Database["public"]["Enums"]["etat_alerte"]
          id?: string
          note_traitement?: string | null
          reference_legale?: string | null
          salarie_id?: string | null
          severite?: Database["public"]["Enums"]["genre_severite"]
          societe_id?: string
          titre?: string
          traite_le?: string | null
          traite_par?: string | null
          vu_la_premiere_fois_le?: string
        }
        Relationships: [
          {
            foreignKeyName: "alertes_conformite_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alertes_conformite_employee_id_fkey"
            columns: ["salarie_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id"]
          },
        ]
      }
      attributions_titres_repas: {
        Row: {
          attribue_le: string | null
          cree_le: string
          debut_periode: string
          fin_periode: string
          id: string
          nombre_titres: number
          note: string | null
          part_salariale: number
          salarie_id: string
          societe_id: string
          valeur_faciale: number
        }
        Insert: {
          attribue_le?: string | null
          cree_le?: string
          debut_periode: string
          fin_periode: string
          id?: string
          nombre_titres: number
          note?: string | null
          part_salariale?: number
          salarie_id: string
          societe_id: string
          valeur_faciale: number
        }
        Update: {
          attribue_le?: string | null
          cree_le?: string
          debut_periode?: string
          fin_periode?: string
          id?: string
          nombre_titres?: number
          note?: string | null
          part_salariale?: number
          salarie_id?: string
          societe_id?: string
          valeur_faciale?: number
        }
        Relationships: [
          {
            foreignKeyName: "attributions_titres_repas_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "voucher_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
        ]
      }
      avenants_contrat: {
        Row: {
          contrat_id: string
          cree_le: string
          cree_par: string | null
          date_effet: string
          id: string
          modifications: Json
          motif: string
          societe_id: string
        }
        Insert: {
          contrat_id: string
          cree_le?: string
          cree_par?: string | null
          date_effet: string
          id?: string
          modifications: Json
          motif: string
          societe_id: string
        }
        Update: {
          contrat_id?: string
          cree_le?: string
          cree_par?: string | null
          date_effet?: string
          id?: string
          modifications?: Json
          motif?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "avenants_contrat_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "avenants_contrat_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
        ]
      }
      categories_sanction: {
        Row: {
          code: string
          debut_validite: string
          description: string
          fin_validite: string
          libelle: string
          rang: number
        }
        Insert: {
          code: string
          debut_validite?: string
          description: string
          fin_validite?: string
          libelle: string
          rang: number
        }
        Update: {
          code?: string
          debut_validite?: string
          description?: string
          fin_validite?: string
          libelle?: string
          rang?: number
        }
        Relationships: []
      }
      cct_regle_prime: {
        Row: {
          article: string | null
          assiette: string | null
          categorie_visee: string | null
          condition_code: string
          convention_id: string
          debut_validite: string
          fin_validite: string
          id: string
          libelle: string
          montant: number | null
          nature_prime: string
          note: string | null
          seuil_minutes: number
          taux_pct: number | null
          unite: string
          url_source: string
        }
        Insert: {
          article?: string | null
          assiette?: string | null
          categorie_visee?: string | null
          condition_code: string
          convention_id: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle: string
          montant?: number | null
          nature_prime: string
          note?: string | null
          seuil_minutes?: number
          taux_pct?: number | null
          unite: string
          url_source: string
        }
        Update: {
          article?: string | null
          assiette?: string | null
          categorie_visee?: string | null
          condition_code?: string
          convention_id?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle?: string
          montant?: number | null
          nature_prime?: string
          note?: string | null
          seuil_minutes?: number
          taux_pct?: number | null
          unite?: string
          url_source?: string
        }
        Relationships: [
          {
            foreignKeyName: "cct_regle_prime_collective_agreement_id_fkey"
            columns: ["convention_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cct_regle_prime_condition_code_fkey"
            columns: ["condition_code"]
            isOneToOne: false
            referencedRelation: "ref_condition_travail"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "cct_regle_prime_nature_prime_fkey"
            columns: ["nature_prime"]
            isOneToOne: false
            referencedRelation: "ref_nature_prime"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "cct_regle_prime_unite_ref"
            columns: ["unite"]
            isOneToOne: false
            referencedRelation: "ref_unite_prime"
            referencedColumns: ["code"]
          },
        ]
      }
      comptes: {
        Row: {
          compte_auth_id: string | null
          courriel: string
          cree_le: string
          cree_par: string | null
          empreinte_mot_de_passe: string | null
          est_admin: boolean
          id: string
          identifiant: string
          modifie_le: string
          modifie_par: string | null
          nom_complet: string | null
          supprime_le: string | null
          supprime_par: string | null
        }
        Insert: {
          compte_auth_id?: string | null
          courriel: string
          cree_le?: string
          cree_par?: string | null
          empreinte_mot_de_passe?: string | null
          est_admin?: boolean
          id?: string
          identifiant: string
          modifie_le?: string
          modifie_par?: string | null
          nom_complet?: string | null
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Update: {
          compte_auth_id?: string | null
          courriel?: string
          cree_le?: string
          cree_par?: string | null
          empreinte_mot_de_passe?: string | null
          est_admin?: boolean
          id?: string
          identifiant?: string
          modifie_le?: string
          modifie_par?: string | null
          nom_complet?: string | null
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Relationships: []
      }
      contrats: {
        Row: {
          agence_interim_id: string | null
          annee_apprentissage: number | null
          brut_mensuel: number
          categorie: string | null
          clause_exclusivite: boolean
          clause_non_concurrence: boolean
          contrat_precedent_id: string | null
          cree_le: string
          date_debut: string
          date_fin: string
          description_poste: string | null
          duree_essai: number | null
          est_temps_partiel: boolean
          genre: Database["public"]["Enums"]["genre_contrat"]
          heures_hebdomadaires: number
          id: string
          indice_reference: number | null
          intitule_poste: string
          jours_conge_annuel: number | null
          jours_par_semaine: number
          libelle_saison: string | null
          lieu_travail: string | null
          motif_cdd: string | null
          motif_mission: string | null
          niveau_apprentissage: string | null
          nom_societe_utilisateur: string | null
          nombre_renouvellements: number
          pause_minutes: number | null
          periode_reference_mois: number
          repartition_travail: string | null
          salarie_id: string
          signe_le: string | null
          societe_id: string
          statut: Database["public"]["Enums"]["statut_contrat"]
          travail_nuit: boolean
          unite_essai: string | null
          version: number
        }
        Insert: {
          agence_interim_id?: string | null
          annee_apprentissage?: number | null
          brut_mensuel: number
          categorie?: string | null
          clause_exclusivite?: boolean
          clause_non_concurrence?: boolean
          contrat_precedent_id?: string | null
          cree_le?: string
          date_debut: string
          date_fin?: string
          description_poste?: string | null
          duree_essai?: number | null
          est_temps_partiel?: boolean
          genre: Database["public"]["Enums"]["genre_contrat"]
          heures_hebdomadaires?: number
          id?: string
          indice_reference?: number | null
          intitule_poste: string
          jours_conge_annuel?: number | null
          jours_par_semaine?: number
          libelle_saison?: string | null
          lieu_travail?: string | null
          motif_cdd?: string | null
          motif_mission?: string | null
          niveau_apprentissage?: string | null
          nom_societe_utilisateur?: string | null
          nombre_renouvellements?: number
          pause_minutes?: number | null
          periode_reference_mois?: number
          repartition_travail?: string | null
          salarie_id: string
          signe_le?: string | null
          societe_id: string
          statut?: Database["public"]["Enums"]["statut_contrat"]
          travail_nuit?: boolean
          unite_essai?: string | null
          version?: number
        }
        Update: {
          agence_interim_id?: string | null
          annee_apprentissage?: number | null
          brut_mensuel?: number
          categorie?: string | null
          clause_exclusivite?: boolean
          clause_non_concurrence?: boolean
          contrat_precedent_id?: string | null
          cree_le?: string
          date_debut?: string
          date_fin?: string
          description_poste?: string | null
          duree_essai?: number | null
          est_temps_partiel?: boolean
          genre?: Database["public"]["Enums"]["genre_contrat"]
          heures_hebdomadaires?: number
          id?: string
          indice_reference?: number | null
          intitule_poste?: string
          jours_conge_annuel?: number | null
          jours_par_semaine?: number
          libelle_saison?: string | null
          lieu_travail?: string | null
          motif_cdd?: string | null
          motif_mission?: string | null
          niveau_apprentissage?: string | null
          nom_societe_utilisateur?: string | null
          nombre_renouvellements?: number
          pause_minutes?: number | null
          periode_reference_mois?: number
          repartition_travail?: string | null
          salarie_id?: string
          signe_le?: string | null
          societe_id?: string
          statut?: Database["public"]["Enums"]["statut_contrat"]
          travail_nuit?: boolean
          unite_essai?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "contract_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "contrats_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contrats_interim_agency_fk"
            columns: ["agence_interim_id"]
            isOneToOne: false
            referencedRelation: "agences_interim"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contrats_previous_contract_id_fkey"
            columns: ["contrat_precedent_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contrats_unite_essai_ref"
            columns: ["unite_essai"]
            isOneToOne: false
            referencedRelation: "ref_unite_essai"
            referencedColumns: ["code"]
          },
        ]
      }
      controles_adresse: {
        Row: {
          code_postal: string | null
          code_zone: string | null
          controle_le: string
          entite_id: string
          entite_table: string
          id: string
          message: string | null
          pays: string | null
          societe_id: string | null
          statut: string
        }
        Insert: {
          code_postal?: string | null
          code_zone?: string | null
          controle_le?: string
          entite_id: string
          entite_table: string
          id?: string
          message?: string | null
          pays?: string | null
          societe_id?: string | null
          statut: string
        }
        Update: {
          code_postal?: string | null
          code_zone?: string | null
          controle_le?: string
          entite_id?: string
          entite_table?: string
          id?: string
          message?: string | null
          pays?: string | null
          societe_id?: string | null
          statut?: string
        }
        Relationships: [
          {
            foreignKeyName: "controles_adresse_statut_ref"
            columns: ["statut"]
            isOneToOne: false
            referencedRelation: "ref_statut_verification_adresse"
            referencedColumns: ["code"]
          },
        ]
      }
      conventions_collectives: {
        Row: {
          actif: boolean
          categorie_professionnelle: string | null
          code: string
          cree_le: string
          debut_validite: string
          fin_validite: string
          id: string
          nom: string
          organisation_id: string | null
          portee: Database["public"]["Enums"]["portee_convention"]
          remplace_id: string | null
          secteur: string
        }
        Insert: {
          actif?: boolean
          categorie_professionnelle?: string | null
          code: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          nom: string
          organisation_id?: string | null
          portee?: Database["public"]["Enums"]["portee_convention"]
          remplace_id?: string | null
          secteur: string
        }
        Update: {
          actif?: boolean
          categorie_professionnelle?: string | null
          code?: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          nom?: string
          organisation_id?: string | null
          portee?: Database["public"]["Enums"]["portee_convention"]
          remplace_id?: string | null
          secteur?: string
        }
        Relationships: [
          {
            foreignKeyName: "conventions_collectives_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conventions_collectives_supersedes_id_fkey"
            columns: ["remplace_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
        ]
      }
      conventions_de_la_societe: {
        Row: {
          convention_id: string
          cree_le: string
          debut_validite: string
          fin_validite: string
          id: string
          note: string | null
          service_id: string | null
          societe_id: string
        }
        Insert: {
          convention_id: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          note?: string | null
          service_id?: string | null
          societe_id: string
        }
        Update: {
          convention_id?: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          note?: string | null
          service_id?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conventions_de_la_societe_collective_agreement_id_fkey"
            columns: ["convention_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conventions_de_la_societe_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conventions_de_la_societe_department_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      conventions_du_contrat: {
        Row: {
          contrat_id: string
          convention_id: string
          cree_le: string
          debut_validite: string
          fin_validite: string
          id: string
          note: string | null
        }
        Insert: {
          contrat_id: string
          convention_id: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          note?: string | null
        }
        Update: {
          contrat_id?: string
          convention_id?: string
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          note?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "conventions_du_contrat_collective_agreement_id_fkey"
            columns: ["convention_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conventions_du_contrat_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
        ]
      }
      credits_impot: {
        Row: {
          classes_visees: Database["public"]["Enums"]["classe_impot"][] | null
          code: string
          debut_validite: string
          fin_validite: string
          id: string
          libelle: string
          montant_mensuel: number | null
          note: string | null
          proratise_sur_heures: boolean
          reference_legale: string | null
          revenu_max: number | null
          revenu_min: number | null
          source: string
        }
        Insert: {
          classes_visees?: Database["public"]["Enums"]["classe_impot"][] | null
          code: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle: string
          montant_mensuel?: number | null
          note?: string | null
          proratise_sur_heures?: boolean
          reference_legale?: string | null
          revenu_max?: number | null
          revenu_min?: number | null
          source?: string
        }
        Update: {
          classes_visees?: Database["public"]["Enums"]["classe_impot"][] | null
          code?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle?: string
          montant_mensuel?: number | null
          note?: string | null
          proratise_sur_heures?: boolean
          reference_legale?: string | null
          revenu_max?: number | null
          revenu_min?: number | null
          source?: string
        }
        Relationships: []
      }
      creneau_condition: {
        Row: {
          condition_code: string
          constate_par: string | null
          cree_le: string
          creneau_id: string | null
          date_prestation: string
          heure_debut: string
          heure_fin: string
          id: string
          minutes: number | null
          note: string | null
          releve_temps_id: string | null
          salarie_id: string
          site_client_id: string | null
          societe_id: string
          supprime_le: string | null
          supprime_par: string | null
        }
        Insert: {
          condition_code: string
          constate_par?: string | null
          cree_le?: string
          creneau_id?: string | null
          date_prestation: string
          heure_debut: string
          heure_fin: string
          id?: string
          minutes?: number | null
          note?: string | null
          releve_temps_id?: string | null
          salarie_id: string
          site_client_id?: string | null
          societe_id: string
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Update: {
          condition_code?: string
          constate_par?: string | null
          cree_le?: string
          creneau_id?: string | null
          date_prestation?: string
          heure_debut?: string
          heure_fin?: string
          id?: string
          minutes?: number | null
          note?: string | null
          releve_temps_id?: string | null
          salarie_id?: string
          site_client_id?: string | null
          societe_id?: string
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "cc_appartient_au_salarie"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "cc_site_appartient_a_la_societe"
            columns: ["site_client_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "sites_client"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "creneau_condition_condition_code_fkey"
            columns: ["condition_code"]
            isOneToOne: false
            referencedRelation: "ref_condition_travail"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "creneau_condition_shift_id_fkey"
            columns: ["creneau_id"]
            isOneToOne: false
            referencedRelation: "creneaux"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "creneau_condition_time_entry_id_fkey"
            columns: ["releve_temps_id"]
            isOneToOne: false
            referencedRelation: "releves_temps"
            referencedColumns: ["id"]
          },
        ]
      }
      creneaux: {
        Row: {
          cree_le: string
          date_creneau: string
          heure_debut: string
          heure_fin: string
          id: string
          libelle: string | null
          modele_id: string | null
          pause_minutes: number
          planning_id: string
          salarie_id: string
          site_client_id: string | null
          societe_id: string
        }
        Insert: {
          cree_le?: string
          date_creneau: string
          heure_debut: string
          heure_fin: string
          id?: string
          libelle?: string | null
          modele_id?: string | null
          pause_minutes?: number
          planning_id: string
          salarie_id: string
          site_client_id?: string | null
          societe_id: string
        }
        Update: {
          cree_le?: string
          date_creneau?: string
          heure_debut?: string
          heure_fin?: string
          id?: string
          libelle?: string | null
          modele_id?: string | null
          pause_minutes?: number
          planning_id?: string
          salarie_id?: string
          site_client_id?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "creneaux_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "creneaux_template_id_fkey"
            columns: ["modele_id"]
            isOneToOne: false
            referencedRelation: "modeles_creneau"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shift_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "shift_belongs_to_schedules_company"
            columns: ["planning_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "plannings"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "shift_site_belongs_to_company"
            columns: ["site_client_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "sites_client"
            referencedColumns: ["id", "societe_id"]
          },
        ]
      }
      demandes_heures_sup: {
        Row: {
          accepte_par_salarie_le: string | null
          compensation: string
          debut_periode: string
          demande_le: string
          demande_par: string | null
          fin_periode: string
          heures: number
          id: string
          motif: string
          motif_refus: string | null
          note: string | null
          planning_id: string | null
          salarie_id: string
          societe_id: string
          statut: string
          valide_rh_le: string | null
          valide_rh_par: string | null
        }
        Insert: {
          accepte_par_salarie_le?: string | null
          compensation?: string
          debut_periode: string
          demande_le?: string
          demande_par?: string | null
          fin_periode: string
          heures: number
          id?: string
          motif: string
          motif_refus?: string | null
          note?: string | null
          planning_id?: string | null
          salarie_id: string
          societe_id: string
          statut?: string
          valide_rh_le?: string | null
          valide_rh_par?: string | null
        }
        Update: {
          accepte_par_salarie_le?: string | null
          compensation?: string
          debut_periode?: string
          demande_le?: string
          demande_par?: string | null
          fin_periode?: string
          heures?: number
          id?: string
          motif?: string
          motif_refus?: string | null
          note?: string | null
          planning_id?: string | null
          salarie_id?: string
          societe_id?: string
          statut?: string
          valide_rh_le?: string | null
          valide_rh_par?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "demandes_heures_sup_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "demandes_heures_sup_compensation_ref"
            columns: ["compensation"]
            isOneToOne: false
            referencedRelation: "ref_compensation_heures_sup"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "demandes_heures_sup_schedule_id_fkey"
            columns: ["planning_id"]
            isOneToOne: false
            referencedRelation: "plannings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "demandes_heures_sup_statut_ref"
            columns: ["statut"]
            isOneToOne: false
            referencedRelation: "ref_statut_heures_sup"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "overtime_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
        ]
      }
      distances_trajet: {
        Row: {
          calcule_le: string
          calcule_par: string | null
          distance_km: number
          duree_minutes: number | null
          id: string
          note: string | null
          reference_destination: string
          reference_origine: string
          source: string
        }
        Insert: {
          calcule_le?: string
          calcule_par?: string | null
          distance_km: number
          duree_minutes?: number | null
          id?: string
          note?: string | null
          reference_destination: string
          reference_origine: string
          source: string
        }
        Update: {
          calcule_le?: string
          calcule_par?: string | null
          distance_km?: number
          duree_minutes?: number | null
          id?: string
          note?: string | null
          reference_destination?: string
          reference_origine?: string
          source?: string
        }
        Relationships: []
      }
      documents: {
        Row: {
          chemin_stockage: string
          conservation_jusquau: string | null
          cree_le: string
          depose_par: string | null
          emis_le: string | null
          entite_id: string | null
          entite_table: string | null
          expire_le: string | null
          id: string
          nom: string
          remis_le: string | null
          salarie_id: string | null
          sensible: boolean
          societe_id: string
          taille_octets: number | null
          type_document_id: string | null
          type_mime: string | null
        }
        Insert: {
          chemin_stockage: string
          conservation_jusquau?: string | null
          cree_le?: string
          depose_par?: string | null
          emis_le?: string | null
          entite_id?: string | null
          entite_table?: string | null
          expire_le?: string | null
          id?: string
          nom: string
          remis_le?: string | null
          salarie_id?: string | null
          sensible?: boolean
          societe_id: string
          taille_octets?: number | null
          type_document_id?: string | null
          type_mime?: string | null
        }
        Update: {
          chemin_stockage?: string
          conservation_jusquau?: string | null
          cree_le?: string
          depose_par?: string | null
          emis_le?: string | null
          entite_id?: string | null
          entite_table?: string | null
          expire_le?: string | null
          id?: string
          nom?: string
          remis_le?: string | null
          salarie_id?: string | null
          sensible?: boolean
          societe_id?: string
          taille_octets?: number | null
          type_document_id?: string | null
          type_mime?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "documents_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_document_type_id_fkey"
            columns: ["type_document_id"]
            isOneToOne: false
            referencedRelation: "types_document"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_employee_id_fkey"
            columns: ["salarie_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id"]
          },
        ]
      }
      donnees_financieres_societe: {
        Row: {
          chiffre_affaires: number | null
          cree_le: string
          exercice: number
          id: string
          note: string | null
          resultat: number | null
          societe_id: string
          source: string | null
        }
        Insert: {
          chiffre_affaires?: number | null
          cree_le?: string
          exercice: number
          id?: string
          note?: string | null
          resultat?: number | null
          societe_id: string
          source?: string | null
        }
        Update: {
          chiffre_affaires?: number | null
          cree_le?: string
          exercice?: number
          id?: string
          note?: string | null
          resultat?: number | null
          societe_id?: string
          source?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "donnees_financieres_societe_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      droits_absence: {
        Row: {
          debut_validite: string
          degre_parente: number | null
          duree_mois: number | null
          fin_validite: string
          id: string
          jours: number | null
          jours_bloc: number | null
          note: string | null
          note_frequence: string | null
          piece_exigee: boolean
          plafond_carriere_jours: number | null
          reference_legale: string | null
          type_absence_id: string
        }
        Insert: {
          debut_validite?: string
          degre_parente?: number | null
          duree_mois?: number | null
          fin_validite?: string
          id?: string
          jours?: number | null
          jours_bloc?: number | null
          note?: string | null
          note_frequence?: string | null
          piece_exigee?: boolean
          plafond_carriere_jours?: number | null
          reference_legale?: string | null
          type_absence_id: string
        }
        Update: {
          debut_validite?: string
          degre_parente?: number | null
          duree_mois?: number | null
          fin_validite?: string
          id?: string
          jours?: number | null
          jours_bloc?: number | null
          note?: string | null
          note_frequence?: string | null
          piece_exigee?: boolean
          plafond_carriere_jours?: number | null
          reference_legale?: string | null
          type_absence_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "droits_absence_absence_type_id_fkey"
            columns: ["type_absence_id"]
            isOneToOne: false
            referencedRelation: "types_absence"
            referencedColumns: ["id"]
          },
        ]
      }
      elements_remuneration: {
        Row: {
          assiette: string | null
          code: string
          contrat_id: string
          cotisable: boolean
          cree_le: string
          dans_assiette_salaire: boolean
          debut_validite: string
          fin_validite: string
          genre: Database["public"]["Enums"]["genre_element_remuneration"]
          id: string
          imposable: boolean
          libelle: string
          montant: number | null
          note: string | null
          periodicite: string
          societe_id: string
          taux_pct: number | null
          type_avantage_id: string | null
        }
        Insert: {
          assiette?: string | null
          code: string
          contrat_id: string
          cotisable?: boolean
          cree_le?: string
          dans_assiette_salaire?: boolean
          debut_validite?: string
          fin_validite?: string
          genre: Database["public"]["Enums"]["genre_element_remuneration"]
          id?: string
          imposable?: boolean
          libelle: string
          montant?: number | null
          note?: string | null
          periodicite?: string
          societe_id: string
          taux_pct?: number | null
          type_avantage_id?: string | null
        }
        Update: {
          assiette?: string | null
          code?: string
          contrat_id?: string
          cotisable?: boolean
          cree_le?: string
          dans_assiette_salaire?: boolean
          debut_validite?: string
          fin_validite?: string
          genre?: Database["public"]["Enums"]["genre_element_remuneration"]
          id?: string
          imposable?: boolean
          libelle?: string
          montant?: number | null
          note?: string | null
          periodicite?: string
          societe_id?: string
          taux_pct?: number | null
          type_avantage_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "elements_remuneration_benefit_type_id_fkey"
            columns: ["type_avantage_id"]
            isOneToOne: false
            referencedRelation: "types_avantage"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "elements_remuneration_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "elements_remuneration_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
        ]
      }
      enfants_salarie: {
        Row: {
          a_charge: boolean
          cree_le: string
          date_adoption: string | null
          date_naissance: string
          en_situation_handicap: boolean
          id: string
          invitation_evenements: boolean
          lien_parente: string
          nom: string | null
          note: string | null
          prenom: string | null
          refus_partage: boolean
          refus_photos_evenements: boolean
          salarie_id: string
          sexe: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id: string
          taux_handicap_pct: number | null
        }
        Insert: {
          a_charge?: boolean
          cree_le?: string
          date_adoption?: string | null
          date_naissance: string
          en_situation_handicap?: boolean
          id?: string
          invitation_evenements?: boolean
          lien_parente?: string
          nom?: string | null
          note?: string | null
          prenom?: string | null
          refus_partage?: boolean
          refus_photos_evenements?: boolean
          salarie_id: string
          sexe?: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id: string
          taux_handicap_pct?: number | null
        }
        Update: {
          a_charge?: boolean
          cree_le?: string
          date_adoption?: string | null
          date_naissance?: string
          en_situation_handicap?: boolean
          id?: string
          invitation_evenements?: boolean
          lien_parente?: string
          nom?: string | null
          note?: string | null
          prenom?: string | null
          refus_partage?: boolean
          refus_photos_evenements?: boolean
          salarie_id?: string
          sexe?: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id?: string
          taux_handicap_pct?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "child_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "enfants_salarie_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enfants_salarie_lien_ref"
            columns: ["lien_parente"]
            isOneToOne: false
            referencedRelation: "ref_lien_enfant"
            referencedColumns: ["code"]
          },
        ]
      }
      fiche_sante: {
        Row: {
          allergies: string | null
          enfant_id: string | null
          groupe_sanguin: string | null
          id: string
          maj_le: string
          maj_par: string | null
          medecin_telephone: string | null
          medecin_traitant: string | null
          note: string | null
          pathologies: string | null
          salarie_id: string | null
          societe_id: string
          supprime_le: string | null
          supprime_par: string | null
        }
        Insert: {
          allergies?: string | null
          enfant_id?: string | null
          groupe_sanguin?: string | null
          id?: string
          maj_le?: string
          maj_par?: string | null
          medecin_telephone?: string | null
          medecin_traitant?: string | null
          note?: string | null
          pathologies?: string | null
          salarie_id?: string | null
          societe_id: string
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Update: {
          allergies?: string | null
          enfant_id?: string | null
          groupe_sanguin?: string | null
          id?: string
          maj_le?: string
          maj_par?: string | null
          medecin_telephone?: string | null
          medecin_traitant?: string | null
          note?: string | null
          pathologies?: string | null
          salarie_id?: string | null
          societe_id?: string
          supprime_le?: string | null
          supprime_par?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fiche_sante_enfant_id_fkey"
            columns: ["enfant_id"]
            isOneToOne: false
            referencedRelation: "enfants_salarie"
            referencedColumns: ["id"]
          },
        ]
      }
      fiches_retenue_impot: {
        Row: {
          autres_deductions_mensuelles: number
          classe_impot: Database["public"]["Enums"]["classe_impot"]
          credits: Json
          debut_validite: string
          distance_domicile_km: number | null
          emis_le: string | null
          fin_validite: string
          frais_professionnels_mensuels: number | null
          id: string
          indemnite_mensuelle: number
          reference_carte: string | null
          salarie_id: string
          societe_id: string
          taux: number | null
        }
        Insert: {
          autres_deductions_mensuelles?: number
          classe_impot: Database["public"]["Enums"]["classe_impot"]
          credits?: Json
          debut_validite?: string
          distance_domicile_km?: number | null
          emis_le?: string | null
          fin_validite?: string
          frais_professionnels_mensuels?: number | null
          id?: string
          indemnite_mensuelle?: number
          reference_carte?: string | null
          salarie_id: string
          societe_id: string
          taux?: number | null
        }
        Update: {
          autres_deductions_mensuelles?: number
          classe_impot?: Database["public"]["Enums"]["classe_impot"]
          credits?: Json
          debut_validite?: string
          distance_domicile_km?: number | null
          emis_le?: string | null
          fin_validite?: string
          frais_professionnels_mensuels?: number | null
          id?: string
          indemnite_mensuelle?: number
          reference_carte?: string | null
          salarie_id?: string
          societe_id?: string
          taux?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "fiches_retenue_impot_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fiches_retenue_impot_employee_id_fkey"
            columns: ["salarie_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id"]
          },
        ]
      }
      grilles_salaires_convention: {
        Row: {
          anciennete_a_annees: number | null
          anciennete_de_annees: number
          categorie: string
          convention_id: string
          id: string
          indice_reference: number | null
          montant_mensuel: number
        }
        Insert: {
          anciennete_a_annees?: number | null
          anciennete_de_annees?: number
          categorie: string
          convention_id: string
          id?: string
          indice_reference?: number | null
          montant_mensuel: number
        }
        Update: {
          anciennete_a_annees?: number | null
          anciennete_de_annees?: number
          categorie?: string
          convention_id?: string
          id?: string
          indice_reference?: number | null
          montant_mensuel?: number
        }
        Relationships: [
          {
            foreignKeyName: "grilles_salaires_convention_collective_agreement_id_fkey"
            columns: ["convention_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
        ]
      }
      handicaps_salarie: {
        Row: {
          autorite: string | null
          cree_le: string
          debut_validite: string
          fin_validite: string
          id: string
          jours_conge_supplementaires_forces: number | null
          note: string | null
          piece_justificative_id: string | null
          reconnu_le: string | null
          salarie_id: string
          societe_id: string
          taux_pct: number
        }
        Insert: {
          autorite?: string | null
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          jours_conge_supplementaires_forces?: number | null
          note?: string | null
          piece_justificative_id?: string | null
          reconnu_le?: string | null
          salarie_id: string
          societe_id: string
          taux_pct: number
        }
        Update: {
          autorite?: string | null
          cree_le?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          jours_conge_supplementaires_forces?: number | null
          note?: string | null
          piece_justificative_id?: string | null
          reconnu_le?: string | null
          salarie_id?: string
          societe_id?: string
          taux_pct?: number
        }
        Relationships: [
          {
            foreignKeyName: "disability_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "handicaps_salarie_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "handicaps_salarie_evidence_document_id_fkey"
            columns: ["piece_justificative_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
        ]
      }
      journal_acces: {
        Row: {
          action: string
          agent_client: string | null
          auteur_id: string | null
          auteur_libelle: string | null
          entite_id: string | null
          entite_table: string
          est_autonome: boolean
          id: number
          identifiant_requete: string | null
          ip_source: string | null
          nombre_lignes: number | null
          portee: string | null
          salarie_concerne_id: string | null
          societe_id: string | null
          survenu_le: string
        }
        Insert: {
          action: string
          agent_client?: string | null
          auteur_id?: string | null
          auteur_libelle?: string | null
          entite_id?: string | null
          entite_table: string
          est_autonome?: boolean
          id?: never
          identifiant_requete?: string | null
          ip_source?: string | null
          nombre_lignes?: number | null
          portee?: string | null
          salarie_concerne_id?: string | null
          societe_id?: string | null
          survenu_le?: string
        }
        Update: {
          action?: string
          agent_client?: string | null
          auteur_id?: string | null
          auteur_libelle?: string | null
          entite_id?: string | null
          entite_table?: string
          est_autonome?: boolean
          id?: never
          identifiant_requete?: string | null
          ip_source?: string | null
          nombre_lignes?: number | null
          portee?: string | null
          salarie_concerne_id?: string | null
          societe_id?: string | null
          survenu_le?: string
        }
        Relationships: [
          {
            foreignKeyName: "journal_acces_action_ref"
            columns: ["action"]
            isOneToOne: false
            referencedRelation: "ref_action_acces"
            referencedColumns: ["code"]
          },
        ]
      }
      journal_ecritures: {
        Row: {
          action: string
          agent_client: string | null
          ancienne_valeur: Json | null
          auteur_id: string | null
          auteur_libelle: string | null
          entite_id: string | null
          entite_table: string
          id: number
          identifiant_requete: string | null
          ip_source: string | null
          nouvelle_valeur: Json | null
          societe_id: string | null
          survenu_le: string
        }
        Insert: {
          action: string
          agent_client?: string | null
          ancienne_valeur?: Json | null
          auteur_id?: string | null
          auteur_libelle?: string | null
          entite_id?: string | null
          entite_table: string
          id?: number
          identifiant_requete?: string | null
          ip_source?: string | null
          nouvelle_valeur?: Json | null
          societe_id?: string | null
          survenu_le?: string
        }
        Update: {
          action?: string
          agent_client?: string | null
          ancienne_valeur?: Json | null
          auteur_id?: string | null
          auteur_libelle?: string | null
          entite_id?: string | null
          entite_table?: string
          id?: number
          identifiant_requete?: string | null
          ip_source?: string | null
          nouvelle_valeur?: Json | null
          societe_id?: string | null
          survenu_le?: string
        }
        Relationships: []
      }
      journal_exports: {
        Row: {
          agent_client: string | null
          cree_le: string
          demande_par: string | null
          genre_objet: string
          id: string
          identifiant_requete: string | null
          ip_source: string | null
          nombre_lignes: number
          objet_id: string | null
          organisation_id: string
          taille_octets: number
        }
        Insert: {
          agent_client?: string | null
          cree_le?: string
          demande_par?: string | null
          genre_objet: string
          id?: string
          identifiant_requete?: string | null
          ip_source?: string | null
          nombre_lignes?: number
          objet_id?: string | null
          organisation_id: string
          taille_octets?: number
        }
        Update: {
          agent_client?: string | null
          cree_le?: string
          demande_par?: string | null
          genre_objet?: string
          id?: string
          identifiant_requete?: string | null
          ip_source?: string | null
          nombre_lignes?: number
          objet_id?: string | null
          organisation_id?: string
          taille_octets?: number
        }
        Relationships: [
          {
            foreignKeyName: "journal_exports_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "journal_exports_sujet_ref"
            columns: ["genre_objet"]
            isOneToOne: false
            referencedRelation: "ref_sujet_export"
            referencedColumns: ["code"]
          },
        ]
      }
      jours_feries: {
        Row: {
          annee: number
          convention_id: string | null
          date_ferie: string
          est_mobile: boolean
          id: string
          motif_recuperation: string | null
          nom: string
          recuperable: boolean
        }
        Insert: {
          annee: number
          convention_id?: string | null
          date_ferie: string
          est_mobile?: boolean
          id?: string
          motif_recuperation?: string | null
          nom: string
          recuperable?: boolean
        }
        Update: {
          annee?: number
          convention_id?: string | null
          date_ferie?: string
          est_mobile?: boolean
          id?: string
          motif_recuperation?: string | null
          nom?: string
          recuperable?: boolean
        }
        Relationships: []
      }
      modeles_creneau: {
        Row: {
          couleur: string
          heure_debut: string
          heure_fin: string
          id: string
          nom: string
          pause_minutes: number
          service_id: string | null
          societe_id: string
        }
        Insert: {
          couleur?: string
          heure_debut: string
          heure_fin: string
          id?: string
          nom: string
          pause_minutes?: number
          service_id?: string | null
          societe_id: string
        }
        Update: {
          couleur?: string
          heure_debut?: string
          heure_fin?: string
          id?: string
          nom?: string
          pause_minutes?: number
          service_id?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "modeles_creneau_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "modeles_creneau_department_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      organisations: {
        Row: {
          cree_le: string
          genre: Database["public"]["Enums"]["genre_organisation"]
          id: string
          nom: string
        }
        Insert: {
          cree_le?: string
          genre?: Database["public"]["Enums"]["genre_organisation"]
          id?: string
          nom: string
        }
        Update: {
          cree_le?: string
          genre?: Database["public"]["Enums"]["genre_organisation"]
          id?: string
          nom?: string
        }
        Relationships: []
      }
      parametres_attendus: {
        Row: {
          cle_parametre: string
          lu_par: string
          note: string | null
        }
        Insert: {
          cle_parametre: string
          lu_par: string
          note?: string | null
        }
        Update: {
          cle_parametre?: string
          lu_par?: string
          note?: string | null
        }
        Relationships: []
      }
      parametres_legaux: {
        Row: {
          cle_parametre: string
          debut_validite: string
          derive_de_cle: string | null
          facteur_derive: number | null
          famille: Database["public"]["Enums"]["famille_parametre"]
          fin_validite: string
          id: string
          indice_reference: number | null
          libelle: string
          note: string | null
          reference_legale: string | null
          saisi_le: string
          saisi_par: string | null
          source: string
          tolerance_derivation: number
          unite: string | null
          valeur_json: Json | null
          valeur_num: number | null
          valeur_texte: string | null
          valide_le: string | null
          valide_par: string | null
        }
        Insert: {
          cle_parametre: string
          debut_validite?: string
          derive_de_cle?: string | null
          facteur_derive?: number | null
          famille: Database["public"]["Enums"]["famille_parametre"]
          fin_validite?: string
          id?: string
          indice_reference?: number | null
          libelle: string
          note?: string | null
          reference_legale?: string | null
          saisi_le?: string
          saisi_par?: string | null
          source: string
          tolerance_derivation?: number
          unite?: string | null
          valeur_json?: Json | null
          valeur_num?: number | null
          valeur_texte?: string | null
          valide_le?: string | null
          valide_par?: string | null
        }
        Update: {
          cle_parametre?: string
          debut_validite?: string
          derive_de_cle?: string | null
          facteur_derive?: number | null
          famille?: Database["public"]["Enums"]["famille_parametre"]
          fin_validite?: string
          id?: string
          indice_reference?: number | null
          libelle?: string
          note?: string | null
          reference_legale?: string | null
          saisi_le?: string
          saisi_par?: string | null
          source?: string
          tolerance_derivation?: number
          unite?: string | null
          valeur_json?: Json | null
          valeur_num?: number | null
          valeur_texte?: string | null
          valide_le?: string | null
          valide_par?: string | null
        }
        Relationships: []
      }
      periodes_reference: {
        Row: {
          date_debut: string
          date_fin: string
          id: string
          libelle: string
          mois: number
          service_id: string | null
          societe_id: string
        }
        Insert: {
          date_debut: string
          date_fin: string
          id?: string
          libelle: string
          mois: number
          service_id?: string | null
          societe_id: string
        }
        Update: {
          date_debut?: string
          date_fin?: string
          id?: string
          libelle?: string
          mois?: number
          service_id?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "periodes_reference_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "periodes_reference_department_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      periodes_taux_societe: {
        Row: {
          classe_activite: string | null
          classe_mutualite: number | null
          classe_risque_accident: string | null
          cree_le: string
          debut_validite: string
          facteur_accident: number
          fin_validite: string
          id: string
          note: string | null
          societe_id: string
          source: string
        }
        Insert: {
          classe_activite?: string | null
          classe_mutualite?: number | null
          classe_risque_accident?: string | null
          cree_le?: string
          debut_validite?: string
          facteur_accident?: number
          fin_validite?: string
          id?: string
          note?: string | null
          societe_id: string
          source?: string
        }
        Update: {
          classe_activite?: string | null
          classe_mutualite?: number | null
          classe_risque_accident?: string | null
          cree_le?: string
          debut_validite?: string
          facteur_accident?: number
          fin_validite?: string
          id?: string
          note?: string | null
          societe_id?: string
          source?: string
        }
        Relationships: [
          {
            foreignKeyName: "periodes_taux_societe_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      personne_indicateur_secours: {
        Row: {
          cree_le: string
          debut_validite: string
          enfant_id: string | null
          fin_validite: string
          id: string
          indicateur: string
          pose_par: string | null
          precision_lieu: string | null
          salarie_id: string | null
          societe_id: string
        }
        Insert: {
          cree_le?: string
          debut_validite?: string
          enfant_id?: string | null
          fin_validite?: string
          id?: string
          indicateur: string
          pose_par?: string | null
          precision_lieu?: string | null
          salarie_id?: string | null
          societe_id: string
        }
        Update: {
          cree_le?: string
          debut_validite?: string
          enfant_id?: string | null
          fin_validite?: string
          id?: string
          indicateur?: string
          pose_par?: string | null
          precision_lieu?: string | null
          salarie_id?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "personne_indicateur_secours_enfant_id_fkey"
            columns: ["enfant_id"]
            isOneToOne: false
            referencedRelation: "enfants_salarie"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "personne_indicateur_secours_indicateur_fkey"
            columns: ["indicateur"]
            isOneToOne: false
            referencedRelation: "ref_indicateur_secours"
            referencedColumns: ["code"]
          },
        ]
      }
      plannings: {
        Row: {
          cree_le: string
          debut_semaine: string
          id: string
          libelle: string | null
          publie_le: string | null
          publie_par: string | null
          service_id: string | null
          societe_id: string
          statut: Database["public"]["Enums"]["statut_planning"]
        }
        Insert: {
          cree_le?: string
          debut_semaine: string
          id?: string
          libelle?: string | null
          publie_le?: string | null
          publie_par?: string | null
          service_id?: string | null
          societe_id: string
          statut?: Database["public"]["Enums"]["statut_planning"]
        }
        Update: {
          cree_le?: string
          debut_semaine?: string
          id?: string
          libelle?: string | null
          publie_le?: string | null
          publie_par?: string | null
          service_id?: string | null
          societe_id?: string
          statut?: Database["public"]["Enums"]["statut_planning"]
        }
        Relationships: [
          {
            foreignKeyName: "plannings_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plannings_department_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      primes: {
        Row: {
          attribue_le: string
          contrat_id: string | null
          cotisable: boolean
          cree_le: string
          exercice: number
          genre: string
          id: string
          imposable: boolean
          libelle: string
          montant: number
          note: string | null
          part_exoneree_pct: number
          rupture_id: string | null
          salarie_id: string
          societe_id: string
        }
        Insert: {
          attribue_le: string
          contrat_id?: string | null
          cotisable?: boolean
          cree_le?: string
          exercice: number
          genre?: string
          id?: string
          imposable?: boolean
          libelle: string
          montant: number
          note?: string | null
          part_exoneree_pct?: number
          rupture_id?: string | null
          salarie_id: string
          societe_id: string
        }
        Update: {
          attribue_le?: string
          contrat_id?: string | null
          cotisable?: boolean
          cree_le?: string
          exercice?: number
          genre?: string
          id?: string
          imposable?: boolean
          libelle?: string
          montant?: number
          note?: string | null
          part_exoneree_pct?: number
          rupture_id?: string | null
          salarie_id?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "premium_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "primes_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "primes_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "primes_nature_ref"
            columns: ["genre"]
            isOneToOne: false
            referencedRelation: "ref_nature_prime"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "primes_termination_id_fkey"
            columns: ["rupture_id"]
            isOneToOne: false
            referencedRelation: "ruptures_contrat"
            referencedColumns: ["id"]
          },
        ]
      }
      profils: {
        Row: {
          courriel: string
          cree_le: string
          est_admin_organisation: boolean
          id: string
          nom_complet: string
          organisation_id: string
        }
        Insert: {
          courriel?: string
          cree_le?: string
          est_admin_organisation?: boolean
          id: string
          nom_complet?: string
          organisation_id: string
        }
        Update: {
          courriel?: string
          cree_le?: string
          est_admin_organisation?: boolean
          id?: string
          nom_complet?: string
          organisation_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "profils_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
        ]
      }
      prolongations_essai: {
        Row: {
          contrat_id: string
          date_debut: string
          date_fin: string
          id: string
          jours_ajoutes: number
          motif: string
        }
        Insert: {
          contrat_id: string
          date_debut: string
          date_fin: string
          id?: string
          jours_ajoutes: number
          motif?: string
        }
        Update: {
          contrat_id?: string
          date_debut?: string
          date_fin?: string
          id?: string
          jours_ajoutes?: number
          motif?: string
        }
        Relationships: [
          {
            foreignKeyName: "prolongations_essai_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
        ]
      }
      ref_action_acces: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_compensation_heures_sup: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_condition_travail: {
        Row: {
          code: string
          debut_validite: string
          description: string | null
          famille: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          description?: string | null
          famille: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          description?: string | null
          famille?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_indicateur_secours: {
        Row: {
          code: string
          consigne: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
          visible_dispatching: boolean
          visible_secours: boolean
        }
        Insert: {
          code: string
          consigne: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
          visible_dispatching?: boolean
          visible_secours?: boolean
        }
        Update: {
          code?: string
          consigne?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
          visible_dispatching?: boolean
          visible_secours?: boolean
        }
        Relationships: []
      }
      ref_lien_enfant: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_nature_prime: {
        Row: {
          categorie: string
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          lie_aux_conditions: boolean
          note: string | null
          ordre: number
          url_source: string | null
        }
        Insert: {
          categorie?: string
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          lie_aux_conditions?: boolean
          note?: string | null
          ordre?: number
          url_source?: string | null
        }
        Update: {
          categorie?: string
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          lie_aux_conditions?: boolean
          note?: string | null
          ordre?: number
          url_source?: string | null
        }
        Relationships: []
      }
      ref_pays: {
        Row: {
          alpha2: string
          alpha3: string
          debut_validite: string
          fin_validite: string
          frontalier: boolean
          nom: string
        }
        Insert: {
          alpha2: string
          alpha3: string
          debut_validite?: string
          fin_validite?: string
          frontalier?: boolean
          nom: string
        }
        Update: {
          alpha2?: string
          alpha3?: string
          debut_validite?: string
          fin_validite?: string
          frontalier?: boolean
          nom?: string
        }
        Relationships: []
      }
      ref_statut_heures_sup: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_statut_verification_adresse: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_sujet_export: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_type_adresse: {
        Row: {
          code: string
          debut_validite: string
          description: string
          fin_validite: string
          libelle: string
          ordre: number
          sert_au_fiscal: boolean
          sert_aux_tournees: boolean
        }
        Insert: {
          code: string
          debut_validite?: string
          description: string
          fin_validite?: string
          libelle: string
          ordre?: number
          sert_au_fiscal?: boolean
          sert_aux_tournees?: boolean
        }
        Update: {
          code?: string
          debut_validite?: string
          description?: string
          fin_validite?: string
          libelle?: string
          ordre?: number
          sert_au_fiscal?: boolean
          sert_aux_tournees?: boolean
        }
        Relationships: []
      }
      ref_unite_essai: {
        Row: {
          code: string
          debut_validite: string
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      ref_unite_prime: {
        Row: {
          code: string
          debut_validite: string
          description: string | null
          fin_validite: string
          libelle: string
          note: string | null
          ordre: number
        }
        Insert: {
          code: string
          debut_validite?: string
          description?: string | null
          fin_validite?: string
          libelle: string
          note?: string | null
          ordre?: number
        }
        Update: {
          code?: string
          debut_validite?: string
          description?: string | null
          fin_validite?: string
          libelle?: string
          note?: string | null
          ordre?: number
        }
        Relationships: []
      }
      regles_convention: {
        Row: {
          bloc: Database["public"]["Enums"]["bloc_convention"]
          complet: boolean
          convention_id: string
          id: string
          modifie_le: string
          regles: Json
        }
        Insert: {
          bloc: Database["public"]["Enums"]["bloc_convention"]
          complet?: boolean
          convention_id: string
          id?: string
          modifie_le?: string
          regles?: Json
        }
        Update: {
          bloc?: Database["public"]["Enums"]["bloc_convention"]
          complet?: boolean
          convention_id?: string
          id?: string
          modifie_le?: string
          regles?: Json
        }
        Relationships: [
          {
            foreignKeyName: "regles_convention_collective_agreement_id_fkey"
            columns: ["convention_id"]
            isOneToOne: false
            referencedRelation: "conventions_collectives"
            referencedColumns: ["id"]
          },
        ]
      }
      releves_effectif: {
        Row: {
          effectif: number
          id: string
          mois: string
          societe_id: string
        }
        Insert: {
          effectif: number
          id?: string
          mois: string
          societe_id: string
        }
        Update: {
          effectif?: number
          id?: string
          mois?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "releves_effectif_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      releves_temps: {
        Row: {
          cree_le: string
          date_releve: string
          heure_debut: string | null
          heure_fin: string | null
          heures_dimanche: number
          heures_ferie: number
          heures_nuit: number
          heures_prevues: number | null
          heures_supplementaires: number
          heures_travaillees: number | null
          id: string
          note: string | null
          pause_minutes: number
          salarie_id: string
          societe_id: string
          source: string
          valide: boolean
        }
        Insert: {
          cree_le?: string
          date_releve: string
          heure_debut?: string | null
          heure_fin?: string | null
          heures_dimanche?: number
          heures_ferie?: number
          heures_nuit?: number
          heures_prevues?: number | null
          heures_supplementaires?: number
          heures_travaillees?: number | null
          id?: string
          note?: string | null
          pause_minutes?: number
          salarie_id: string
          societe_id: string
          source?: string
          valide?: boolean
        }
        Update: {
          cree_le?: string
          date_releve?: string
          heure_debut?: string | null
          heure_fin?: string | null
          heures_dimanche?: number
          heures_ferie?: number
          heures_nuit?: number
          heures_prevues?: number | null
          heures_supplementaires?: number
          heures_travaillees?: number | null
          id?: string
          note?: string | null
          pause_minutes?: number
          salarie_id?: string
          societe_id?: string
          source?: string
          valide?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "releves_temps_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_entry_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
        ]
      }
      roles_compte: {
        Row: {
          compte_id: string
          cree_le: string
          id: string
          organisation_id: string
          role: Database["public"]["Enums"]["role_application"]
          societe_id: string | null
        }
        Insert: {
          compte_id: string
          cree_le?: string
          id?: string
          organisation_id: string
          role: Database["public"]["Enums"]["role_application"]
          societe_id?: string | null
        }
        Update: {
          compte_id?: string
          cree_le?: string
          id?: string
          organisation_id?: string
          role?: Database["public"]["Enums"]["role_application"]
          societe_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "roles_compte_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "roles_compte_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
        ]
      }
      ruptures_contrat: {
        Row: {
          compensation_renonciation: number | null
          contrat_id: string
          cree_le: string
          debut_preavis: string | null
          faute_grave: boolean
          fin_preavis: string | null
          id: string
          indemnite_mois: number | null
          motif: string
          motif_personnel: boolean
          note_renonciation: string | null
          notifie_le: string
          preavis_renonce: boolean
          renonciation_convenue_le: string | null
          societe_id: string
        }
        Insert: {
          compensation_renonciation?: number | null
          contrat_id: string
          cree_le?: string
          debut_preavis?: string | null
          faute_grave?: boolean
          fin_preavis?: string | null
          id?: string
          indemnite_mois?: number | null
          motif: string
          motif_personnel?: boolean
          note_renonciation?: string | null
          notifie_le: string
          preavis_renonce?: boolean
          renonciation_convenue_le?: string | null
          societe_id: string
        }
        Update: {
          compensation_renonciation?: number | null
          contrat_id?: string
          cree_le?: string
          debut_preavis?: string | null
          faute_grave?: boolean
          fin_preavis?: string | null
          id?: string
          indemnite_mois?: number | null
          motif?: string
          motif_personnel?: boolean
          note_renonciation?: string | null
          notifie_le?: string
          preavis_renonce?: boolean
          renonciation_convenue_le?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ruptures_contrat_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ruptures_contrat_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
        ]
      }
      salaries: {
        Row: {
          code_postal: string | null
          compte_id: string | null
          courriel: string | null
          cree_le: string
          date_debut_carriere: string | null
          date_naissance: string | null
          est_cadre: boolean
          iban_chiffre: string | null
          id: string
          ligne: string | null
          localite: string | null
          matricule_national_chiffre: string | null
          matricule_national_indice: string | null
          nom: string
          pays: string
          prenom: string
          profession: string | null
          qualification: Database["public"]["Enums"]["genre_qualification"]
          refus_photos_societe: boolean
          residence: Database["public"]["Enums"]["genre_residence"]
          service_id: string | null
          sexe: Database["public"]["Enums"]["genre_sexe"]
          sexe_legal: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id: string
          souhaite_confidentialite: boolean
          telephone: string | null
        }
        Insert: {
          code_postal?: string | null
          compte_id?: string | null
          courriel?: string | null
          cree_le?: string
          date_debut_carriere?: string | null
          date_naissance?: string | null
          est_cadre?: boolean
          iban_chiffre?: string | null
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_national_chiffre?: string | null
          matricule_national_indice?: string | null
          nom: string
          pays?: string
          prenom: string
          profession?: string | null
          qualification?: Database["public"]["Enums"]["genre_qualification"]
          refus_photos_societe?: boolean
          residence: Database["public"]["Enums"]["genre_residence"]
          service_id?: string | null
          sexe?: Database["public"]["Enums"]["genre_sexe"]
          sexe_legal?: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id: string
          souhaite_confidentialite?: boolean
          telephone?: string | null
        }
        Update: {
          code_postal?: string | null
          compte_id?: string | null
          courriel?: string | null
          cree_le?: string
          date_debut_carriere?: string | null
          date_naissance?: string | null
          est_cadre?: boolean
          iban_chiffre?: string | null
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_national_chiffre?: string | null
          matricule_national_indice?: string | null
          nom?: string
          pays?: string
          prenom?: string
          profession?: string | null
          qualification?: Database["public"]["Enums"]["genre_qualification"]
          refus_photos_societe?: boolean
          residence?: Database["public"]["Enums"]["genre_residence"]
          service_id?: string | null
          sexe?: Database["public"]["Enums"]["genre_sexe"]
          sexe_legal?: Database["public"]["Enums"]["genre_sexe"] | null
          societe_id?: string
          souhaite_confidentialite?: boolean
          telephone?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "salaries_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "salaries_department_id_fkey"
            columns: ["service_id"]
            isOneToOne: false
            referencedRelation: "services"
            referencedColumns: ["id"]
          },
        ]
      }
      sanctions_salarie: {
        Row: {
          conservation_jusquau: string | null
          conteste_le: string | null
          contrat_avenant_id: string | null
          contrat_id: string | null
          cree_le: string
          cree_par: string | null
          effet_au: string | null
          effet_du: string | null
          faits_connus_le: string
          faits_le: string
          id: string
          issue_contestation: string | null
          modifie_le: string
          modifie_par: string | null
          motif: string
          note: string | null
          notifie_le: string | null
          piece_justificative_id: string | null
          reponse_salarie: string | null
          rupture_id: string | null
          salarie_entendu_le: string | null
          salarie_id: string
          societe_id: string
          supprime_le: string | null
          supprime_par: string | null
          type_sanction: string
        }
        Insert: {
          conservation_jusquau?: string | null
          conteste_le?: string | null
          contrat_avenant_id?: string | null
          contrat_id?: string | null
          cree_le?: string
          cree_par?: string | null
          effet_au?: string | null
          effet_du?: string | null
          faits_connus_le: string
          faits_le: string
          id?: string
          issue_contestation?: string | null
          modifie_le?: string
          modifie_par?: string | null
          motif: string
          note?: string | null
          notifie_le?: string | null
          piece_justificative_id?: string | null
          reponse_salarie?: string | null
          rupture_id?: string | null
          salarie_entendu_le?: string | null
          salarie_id: string
          societe_id: string
          supprime_le?: string | null
          supprime_par?: string | null
          type_sanction: string
        }
        Update: {
          conservation_jusquau?: string | null
          conteste_le?: string | null
          contrat_avenant_id?: string | null
          contrat_id?: string | null
          cree_le?: string
          cree_par?: string | null
          effet_au?: string | null
          effet_du?: string | null
          faits_connus_le?: string
          faits_le?: string
          id?: string
          issue_contestation?: string | null
          modifie_le?: string
          modifie_par?: string | null
          motif?: string
          note?: string | null
          notifie_le?: string | null
          piece_justificative_id?: string | null
          reponse_salarie?: string | null
          rupture_id?: string | null
          salarie_entendu_le?: string | null
          salarie_id?: string
          societe_id?: string
          supprime_le?: string | null
          supprime_par?: string | null
          type_sanction?: string
        }
        Relationships: [
          {
            foreignKeyName: "sanction_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "sanctions_salarie_amendment_contract_id_fkey"
            columns: ["contrat_avenant_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sanctions_salarie_contract_id_fkey"
            columns: ["contrat_id"]
            isOneToOne: false
            referencedRelation: "contrats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sanctions_salarie_evidence_document_id_fkey"
            columns: ["piece_justificative_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sanctions_salarie_sanction_type_fkey"
            columns: ["type_sanction"]
            isOneToOne: false
            referencedRelation: "types_sanction"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "sanctions_salarie_termination_id_fkey"
            columns: ["rupture_id"]
            isOneToOne: false
            referencedRelation: "ruptures_contrat"
            referencedColumns: ["id"]
          },
        ]
      }
      secrets_application: {
        Row: {
          cle: string
          secret: string
        }
        Insert: {
          cle: string
          secret: string
        }
        Update: {
          cle?: string
          secret?: string
        }
        Relationships: []
      }
      services: {
        Row: {
          couverture_soir_min: number | null
          id: string
          nom: string
          societe_id: string
        }
        Insert: {
          couverture_soir_min?: number | null
          id?: string
          nom: string
          societe_id: string
        }
        Update: {
          couverture_soir_min?: number | null
          id?: string
          nom?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "services_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      sinistres_accident_societe: {
        Row: {
          annee: number
          cout: number | null
          id: string
          jours_perdus: number
          nombre_sinistres: number
          note: string | null
          societe_id: string
        }
        Insert: {
          annee: number
          cout?: number | null
          id?: string
          jours_perdus?: number
          nombre_sinistres?: number
          note?: string | null
          societe_id: string
        }
        Update: {
          annee?: number
          cout?: number | null
          id?: string
          jours_perdus?: number
          nombre_sinistres?: number
          note?: string | null
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "sinistres_accident_societe_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      sites_client: {
        Row: {
          actif: boolean
          code_postal: string | null
          cree_le: string
          id: string
          latitude: number | null
          ligne: string | null
          localite: string | null
          longitude: number | null
          nom: string
          nom_client: string | null
          note: string | null
          pays: string
          societe_id: string
        }
        Insert: {
          actif?: boolean
          code_postal?: string | null
          cree_le?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          nom: string
          nom_client?: string | null
          note?: string | null
          pays?: string
          societe_id: string
        }
        Update: {
          actif?: boolean
          code_postal?: string | null
          cree_le?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          nom?: string
          nom_client?: string | null
          note?: string | null
          pays?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "sites_client_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
        ]
      }
      societes: {
        Row: {
          code_nace: string | null
          code_postal: string | null
          cree_le: string
          forme_juridique: string | null
          id: string
          ligne: string | null
          localite: string | null
          matricule_ccss: string | null
          numero_rcs: string | null
          organisation_id: string
          pays: string
          periode_reference_mois: number
          raison_sociale: string
          reference_reglement_interieur: string | null
          reglement_interieur_adopte_le: string | null
          secteur: string | null
        }
        Insert: {
          code_nace?: string | null
          code_postal?: string | null
          cree_le?: string
          forme_juridique?: string | null
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_ccss?: string | null
          numero_rcs?: string | null
          organisation_id: string
          pays?: string
          periode_reference_mois?: number
          raison_sociale: string
          reference_reglement_interieur?: string | null
          reglement_interieur_adopte_le?: string | null
          secteur?: string | null
        }
        Update: {
          code_nace?: string | null
          code_postal?: string | null
          cree_le?: string
          forme_juridique?: string | null
          id?: string
          ligne?: string | null
          localite?: string | null
          matricule_ccss?: string | null
          numero_rcs?: string | null
          organisation_id?: string
          pays?: string
          periode_reference_mois?: number
          raison_sociale?: string
          reference_reglement_interieur?: string | null
          reglement_interieur_adopte_le?: string | null
          secteur?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "societes_organization_id_fkey"
            columns: ["organisation_id"]
            isOneToOne: false
            referencedRelation: "organisations"
            referencedColumns: ["id"]
          },
        ]
      }
      statuts_salarie: {
        Row: {
          credit_heures_mensuel: number | null
          cree_le: string
          date_debut: string
          date_fin: string
          date_naissance_prevue: string | null
          date_naissance_reelle: string | null
          declare_le: string
          genre: Database["public"]["Enums"]["genre_statut_salarie"]
          id: string
          note: string | null
          piece_justificative_id: string | null
          salarie_id: string
          societe_id: string
        }
        Insert: {
          credit_heures_mensuel?: number | null
          cree_le?: string
          date_debut: string
          date_fin?: string
          date_naissance_prevue?: string | null
          date_naissance_reelle?: string | null
          declare_le?: string
          genre: Database["public"]["Enums"]["genre_statut_salarie"]
          id?: string
          note?: string | null
          piece_justificative_id?: string | null
          salarie_id: string
          societe_id: string
        }
        Update: {
          credit_heures_mensuel?: number | null
          cree_le?: string
          date_debut?: string
          date_fin?: string
          date_naissance_prevue?: string | null
          date_naissance_reelle?: string | null
          declare_le?: string
          genre?: Database["public"]["Enums"]["genre_statut_salarie"]
          id?: string
          note?: string | null
          piece_justificative_id?: string | null
          salarie_id?: string
          societe_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "status_belongs_to_employees_company"
            columns: ["salarie_id", "societe_id"]
            isOneToOne: false
            referencedRelation: "salaries"
            referencedColumns: ["id", "societe_id"]
          },
          {
            foreignKeyName: "statuts_salarie_company_id_fkey"
            columns: ["societe_id"]
            isOneToOne: false
            referencedRelation: "societes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "statuts_salarie_evidence_document_id_fkey"
            columns: ["piece_justificative_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
        ]
      }
      tranches_impot: {
        Row: {
          classe_impot: Database["public"]["Enums"]["classe_impot"]
          debut_validite: string
          fin_validite: string
          id: string
          impot_base: number
          note: string | null
          periodicite: Database["public"]["Enums"]["periodicite_impot"]
          reference_legale: string | null
          source: string
          taux_au_dessus_minimum: number
          tranche_max: number | null
          tranche_min: number
        }
        Insert: {
          classe_impot: Database["public"]["Enums"]["classe_impot"]
          debut_validite?: string
          fin_validite?: string
          id?: string
          impot_base?: number
          note?: string | null
          periodicite?: Database["public"]["Enums"]["periodicite_impot"]
          reference_legale?: string | null
          source?: string
          taux_au_dessus_minimum: number
          tranche_max?: number | null
          tranche_min: number
        }
        Update: {
          classe_impot?: Database["public"]["Enums"]["classe_impot"]
          debut_validite?: string
          fin_validite?: string
          id?: string
          impot_base?: number
          note?: string | null
          periodicite?: Database["public"]["Enums"]["periodicite_impot"]
          reference_legale?: string | null
          source?: string
          taux_au_dessus_minimum?: number
          tranche_max?: number | null
          tranche_min?: number
        }
        Relationships: []
      }
      types_absence: {
        Row: {
          categorie: Database["public"]["Enums"]["categorie_absence"]
          certificat_exige: boolean
          code: string
          id: string
          impute_sur_conge: boolean
          libelle: string
          reference_legale: string | null
          remunere: boolean
        }
        Insert: {
          categorie: Database["public"]["Enums"]["categorie_absence"]
          certificat_exige?: boolean
          code: string
          id?: string
          impute_sur_conge?: boolean
          libelle: string
          reference_legale?: string | null
          remunere?: boolean
        }
        Update: {
          categorie?: Database["public"]["Enums"]["categorie_absence"]
          certificat_exige?: boolean
          code?: string
          id?: string
          impute_sur_conge?: boolean
          libelle?: string
          reference_legale?: string | null
          remunere?: boolean
        }
        Relationships: []
      }
      types_avantage: {
        Row: {
          code: string
          cotisable: boolean
          id: string
          imposable: boolean
          libelle: string
          methode_evaluation: string
          note: string | null
          parametres_evaluation: Json
          reference_legale: string | null
        }
        Insert: {
          code: string
          cotisable?: boolean
          id?: string
          imposable?: boolean
          libelle: string
          methode_evaluation: string
          note?: string | null
          parametres_evaluation?: Json
          reference_legale?: string | null
        }
        Update: {
          code?: string
          cotisable?: boolean
          id?: string
          imposable?: boolean
          libelle?: string
          methode_evaluation?: string
          note?: string | null
          parametres_evaluation?: Json
          reference_legale?: string | null
        }
        Relationships: []
      }
      types_document: {
        Row: {
          alerte_jours_avant: number
          code: string
          echelon: Database["public"]["Enums"]["etape_document"]
          id: string
          libelle: string
          note: string | null
          obligatoire: boolean
          reference_legale: string | null
          residences_visees:
            | Database["public"]["Enums"]["genre_residence"][]
            | null
          validite_mois: number | null
        }
        Insert: {
          alerte_jours_avant?: number
          code: string
          echelon?: Database["public"]["Enums"]["etape_document"]
          id?: string
          libelle: string
          note?: string | null
          obligatoire?: boolean
          reference_legale?: string | null
          residences_visees?:
            | Database["public"]["Enums"]["genre_residence"][]
            | null
          validite_mois?: number | null
        }
        Update: {
          alerte_jours_avant?: number
          code?: string
          echelon?: Database["public"]["Enums"]["etape_document"]
          id?: string
          libelle?: string
          note?: string | null
          obligatoire?: boolean
          reference_legale?: string | null
          residences_visees?:
            | Database["public"]["Enums"]["genre_residence"][]
            | null
          validite_mois?: number | null
        }
        Relationships: []
      }
      types_sanction: {
        Row: {
          affecte_paie: boolean
          code: string
          code_categorie: string
          debut_validite: string
          description: string
          fin_validite: string
          libelle: string
          modifie_contrat: boolean
          needs_notice: boolean | null
          note: string | null
          reference_legale: string | null
          reglement_interieur_exige: boolean
          rompt_contrat: boolean
          suspend_presence: boolean
        }
        Insert: {
          affecte_paie?: boolean
          code: string
          code_categorie: string
          debut_validite?: string
          description: string
          fin_validite?: string
          libelle: string
          modifie_contrat?: boolean
          needs_notice?: boolean | null
          note?: string | null
          reference_legale?: string | null
          reglement_interieur_exige?: boolean
          rompt_contrat?: boolean
          suspend_presence?: boolean
        }
        Update: {
          affecte_paie?: boolean
          code?: string
          code_categorie?: string
          debut_validite?: string
          description?: string
          fin_validite?: string
          libelle?: string
          modifie_contrat?: boolean
          needs_notice?: boolean | null
          note?: string | null
          reference_legale?: string | null
          reglement_interieur_exige?: boolean
          rompt_contrat?: boolean
          suspend_presence?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "types_sanction_category_code_fkey"
            columns: ["code_categorie"]
            isOneToOne: false
            referencedRelation: "categories_sanction"
            referencedColumns: ["code"]
          },
        ]
      }
      zones_adresse: {
        Row: {
          code: string
          code_postal_au: number | null
          code_postal_du: number | null
          genre: string
          id: string
          libelle: string
          note: string | null
          pays: string
          source: string
          verifie: boolean
        }
        Insert: {
          code: string
          code_postal_au?: number | null
          code_postal_du?: number | null
          genre: string
          id?: string
          libelle: string
          note?: string | null
          pays: string
          source: string
          verifie?: boolean
        }
        Update: {
          code?: string
          code_postal_au?: number | null
          code_postal_du?: number | null
          genre?: string
          id?: string
          libelle?: string
          note?: string | null
          pays?: string
          source?: string
          verifie?: boolean
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      auth_org_id: { Args: never; Returns: string }
      can_manage_company: { Args: { p_company: string }; Returns: boolean }
      est_admin_organisation: { Args: never; Returns: boolean }
      fn_absence_entitlement: {
        Args: { p_on?: string; p_type: string }
        Returns: {
          debut_validite: string
          degre_parente: number | null
          duree_mois: number | null
          fin_validite: string
          id: string
          jours: number | null
          jours_bloc: number | null
          note: string | null
          note_frequence: string | null
          piece_exigee: boolean
          plafond_carriere_jours: number | null
          reference_legale: string | null
          type_absence_id: string
        }
        SetofOptions: {
          from: "*"
          to: "droits_absence"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_add_parameter_version: {
        Args: {
          p_index_ref?: number
          p_key: string
          p_note?: string
          p_source?: string
          p_valid_from: string
          p_value_json?: Json
          p_value_num?: number
          p_value_text?: string
        }
        Returns: {
          cle_parametre: string
          debut_validite: string
          derive_de_cle: string | null
          facteur_derive: number | null
          famille: Database["public"]["Enums"]["famille_parametre"]
          fin_validite: string
          id: string
          indice_reference: number | null
          libelle: string
          note: string | null
          reference_legale: string | null
          saisi_le: string
          saisi_par: string | null
          source: string
          tolerance_derivation: number
          unite: string | null
          valeur_json: Json | null
          valeur_num: number | null
          valeur_texte: string | null
          valide_le: string | null
          valide_par: string | null
        }
        SetofOptions: {
          from: "*"
          to: "parametres_legaux"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_address_of: { Args: { p_ref: string }; Returns: Json }
      fn_amend_contract: {
        Args: {
          p_changes: Json
          p_contract: string
          p_effective_date: string
          p_reason: string
        }
        Returns: Json
      }
      fn_annual_leave_rule: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_applicable_cbas: {
        Args: { p_contract: string; p_on?: string }
        Returns: {
          code: string
          convention_id: string
          debut_validite: string
          fin_validite: string
          nom: string
          origine: string
          portee: Database["public"]["Enums"]["portee_convention"]
        }[]
      }
      fn_arbitrate: {
        Args: {
          p_cba: number
          p_cba_ref: string
          p_contract: number
          p_higher_is_better?: boolean
          p_label: string
          p_law: number
          p_law_ref: string
        }
        Returns: Json
      }
      fn_audit_conninfo: { Args: never; Returns: string }
      fn_can_terminate: {
        Args: {
          p_contract: string
          p_gross_misconduct?: boolean
          p_on?: string
          p_reason: string
        }
        Returns: Json
      }
      fn_cba_best_num: {
        Args: {
          p_block: Database["public"]["Enums"]["bloc_convention"]
          p_contract: string
          p_higher_is_better?: boolean
          p_on?: string
          p_path: string
        }
        Returns: Json
      }
      fn_cba_by_code: {
        Args: { p_code: string; p_org: string }
        Returns: string
      }
      fn_cba_value: {
        Args: {
          p_block: Database["public"]["Enums"]["bloc_convention"]
          p_cba: string
          p_path: string
        }
        Returns: Json
      }
      fn_chaine_absence: { Args: { p_absence: string }; Returns: Json }
      fn_changer_adresse: {
        Args: {
          p_code_postal: string
          p_effet: string
          p_employee: string
          p_ligne: string
          p_localite: string
          p_pays?: string
          p_type: string
        }
        Returns: Json
      }
      fn_check_app_password: {
        Args: { p_password: string; p_userid: string }
        Returns: boolean
      }
      fn_check_national_id: {
        Args: {
          p_birth?: string
          p_id: string
          p_sex?: Database["public"]["Enums"]["genre_sexe"]
        }
        Returns: Json
      }
      fn_coherence_report: { Args: never; Returns: Json }
      fn_collective_dismissal_counters: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_commute_allowance: {
        Args: { p_km: number; p_on?: string }
        Returns: Json
      }
      fn_company_absenteeism: {
        Args: { p_company: string; p_year: number }
        Returns: Json
      }
      fn_company_rates: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_compliance_scan: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_contract_compliance: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_create_app_user: {
        Args: {
          p_email: string
          p_full_name?: string
          p_is_admin?: boolean
          p_password: string
          p_userid: string
        }
        Returns: Json
      }
      fn_decrypt_field: { Args: { p_cipher: string }; Returns: string }
      fn_delegation_eligibility: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_disability_extra_leave: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_dismissal_protections: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_easter_sunday: { Args: { p_year: number }; Returns: string }
      fn_employee_age: {
        Args: { p_employee: string; p_on?: string }
        Returns: number
      }
      fn_employee_children: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_employee_rows: {
        Args: {
          p_active_on?: string
          p_company?: string
          p_department?: string
          p_employee?: string
          p_fields?: string[]
          p_limit?: number
          p_search?: string
        }
        Returns: Database["public"]["CompositeTypes"]["ligne_salarie"][]
        SetofOptions: {
          from: "*"
          to: "ligne_salarie"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      fn_employee_sensitive: {
        Args: { p_employee: string }
        Returns: {
          iban: string
          matricule_national: string
        }[]
      }
      fn_encrypt_field: { Args: { p_plain: string }; Returns: string }
      fn_end_of_contract_documents: {
        Args: { p_contract: string }
        Returns: Json
      }
      fn_export_company: { Args: { p_company: string }; Returns: Json }
      fn_export_employee: { Args: { p_employee: string }; Returns: Json }
      fn_export_organization: { Args: never; Returns: Json }
      fn_export_referential: { Args: never; Returns: Json }
      fn_export_self: { Args: never; Returns: Json }
      fn_fmt: { Args: { n: number }; Returns: string }
      fn_generate_public_holidays: {
        Args: { p_year: number }
        Returns: {
          annee: number
          convention_id: string | null
          date_ferie: string
          est_mobile: boolean
          id: string
          motif_recuperation: string | null
          nom: string
          recuperable: boolean
        }[]
        SetofOptions: {
          from: "*"
          to: "jours_feries"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      fn_headcount: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_headcount_obligations: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_holiday_summary: {
        Args: { p_cba?: string; p_year: number }
        Returns: Json
      }
      fn_import_referential: {
        Args: { p_document: Json; p_mode?: string }
        Returns: Json
      }
      fn_income_tax: {
        Args: {
          p_class: Database["public"]["Enums"]["classe_impot"]
          p_on?: string
          p_periodicity?: Database["public"]["Enums"]["periodicite_impot"]
          p_taxable: number
        }
        Returns: Json
      }
      fn_indicateurs_affectation: {
        Args: { p_employee: string; p_le?: string }
        Returns: Json
      }
      fn_is_public_holiday: {
        Args: { p_cba?: string; p_date: string }
        Returns: boolean
      }
      fn_is_qualified: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_leave_balance: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_leave_request_impact: {
        Args: {
          p_employee: string
          p_end: string
          p_start: string
          p_type: string
        }
        Returns: Json
      }
      fn_log_access: {
        Args: {
          p_action: string
          p_entity_id: string
          p_entity_table: string
          p_row_count?: number
          p_scope?: string
          p_subject_employee: string
        }
        Returns: undefined
      }
      fn_log_access_autonomous: {
        Args: {
          p_action: string
          p_company: string
          p_entity_id: string
          p_entity_table: string
          p_row_count?: number
          p_scope?: string
          p_subject_employee: string
        }
        Returns: undefined
      }
      fn_luhn_check_digit: { Args: { p_digits: string }; Returns: number }
      fn_make_national_id:
        | { Args: { p_birth: string; p_serial: number }; Returns: string }
        | {
            Args: {
              p_birth: string
              p_serial: number
              p_sex?: Database["public"]["Enums"]["genre_sexe"]
            }
            Returns: string
          }
      fn_meal_voucher_check: { Args: { p_grant: string }; Returns: Json }
      fn_migration_source: { Args: { p_version: string }; Returns: string }
      fn_migrations_list: {
        Args: never
        Returns: {
          nom: string
          taille: number
          version: string
        }[]
      }
      fn_min_salary: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_national_id_birth_date: { Args: { p_id: string }; Returns: string }
      fn_national_id_sex: {
        Args: { p_id: string }
        Returns: Database["public"]["Enums"]["genre_sexe"]
      }
      fn_normaliser_pays: { Args: { p_pays: string }; Returns: string }
      fn_notice_period: {
        Args: {
          p_by_employer: boolean
          p_contract: string
          p_notified_on: string
        }
        Returns: Json
      }
      fn_overtime_approve: {
        Args: { p_as_hr: boolean; p_request: string }
        Returns: {
          accepte_par_salarie_le: string | null
          compensation: string
          debut_periode: string
          demande_le: string
          demande_par: string | null
          fin_periode: string
          heures: number
          id: string
          motif: string
          motif_refus: string | null
          note: string | null
          planning_id: string | null
          salarie_id: string
          societe_id: string
          statut: string
          valide_rh_le: string | null
          valide_rh_par: string | null
        }
        SetofOptions: {
          from: "*"
          to: "demandes_heures_sup"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_overtime_approved_hours: {
        Args: { p_employee: string; p_from: string; p_to: string }
        Returns: number
      }
      fn_overtime_eligibility: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_param: {
        Args: { p_key: string; p_on?: string }
        Returns: {
          cle_parametre: string
          debut_validite: string
          derive_de_cle: string | null
          facteur_derive: number | null
          famille: Database["public"]["Enums"]["famille_parametre"]
          fin_validite: string
          id: string
          indice_reference: number | null
          libelle: string
          note: string | null
          reference_legale: string | null
          saisi_le: string
          saisi_par: string | null
          source: string
          tolerance_derivation: number
          unite: string | null
          valeur_json: Json | null
          valeur_num: number | null
          valeur_texte: string | null
          valide_le: string | null
          valide_par: string | null
        }
        SetofOptions: {
          from: "*"
          to: "parametres_legaux"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_param_num: { Args: { p_key: string; p_on?: string }; Returns: number }
      fn_payload_rows: { Args: { p_payload: Json }; Returns: number }
      fn_person_access_report: {
        Args: { p_employee: string; p_from?: string; p_to?: string }
        Returns: {
          agent: string
          d_ou: string
          detail: string
          nature: string
          quand: string
          qui: string
          qui_id: string
          quoi: string
          requete: string
        }[]
      }
      fn_poser_adresses_depuis_domicile: {
        Args: { p_depuis?: string; p_employee: string }
        Returns: Json
      }
      fn_postal_number: {
        Args: { p_country: string; p_postal: string }
        Returns: number
      }
      fn_premium_caps: {
        Args: { p_company: string; p_year: number }
        Returns: Json
      }
      fn_premium_check: { Args: { p_premium: string }; Returns: Json }
      fn_primes_conditions: {
        Args: { p_au: string; p_du: string; p_employee: string }
        Returns: Json
      }
      fn_probation: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_publish_schedule: { Args: { p_schedule: string }; Returns: Json }
      fn_recalculer_severites: { Args: { p_le?: string }; Returns: Json }
      fn_redact_encrypted: { Args: { p_row: Json }; Returns: Json }
      fn_reference_period_status: {
        Args: { p_company: string; p_on?: string }
        Returns: Json
      }
      fn_referential_gaps: {
        Args: { p_since?: string }
        Returns: {
          cle_parametre: string
          couvert_depuis: string
          couvert_jusqua: string
          couvre_depuis: boolean
          famille: Database["public"]["Enums"]["famille_parametre"]
          jours_manquants: number
          libelle: string
          lu_par: string
          versions: number
        }[]
      }
      fn_referential_holes: {
        Args: never
        Returns: {
          cle_parametre: string
          trou_au: string
          trou_du: string
        }[]
      }
      fn_referential_inconsistencies: {
        Args: { p_on?: string }
        Returns: {
          cle_parametre: string
          cle_source: string
          derive: number
          ecart: number
          libelle: string
          publie: number
          tolerance: number
        }[]
      }
      fn_refuser_absence: {
        Args: {
          p_absence: string
          p_commentaire?: string
          p_motif: string
          p_nouveau_debut: string
          p_nouveau_fin: string
        }
        Returns: Json
      }
      fn_renommer_cles_json: {
        Args: { p_map: Json; p_valeur: Json }
        Returns: Json
      }
      fn_repondre_contre_proposition: {
        Args: { p_absence: string; p_accepte: boolean; p_motif?: string }
        Returns: Json
      }
      fn_request_source: { Args: never; Returns: Json }
      fn_rows_json: {
        Args: { p_column: string; p_table: string; p_value: string }
        Returns: Json
      }
      fn_salary_reference: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_sanction_check: { Args: { p_sanction: string }; Returns: Json }
      fn_schedule_travel: { Args: { p_schedule: string }; Returns: Json }
      fn_schema_catalogue: { Args: never; Returns: Json }
      fn_schema_catalogue_for_admin: { Args: never; Returns: Json }
      fn_seed_demo: { Args: never; Returns: Json }
      fn_set_company_rates: {
        Args: {
          p_accident_factor: number
          p_accident_risk_class?: string
          p_activity_class?: string
          p_company: string
          p_from: string
          p_mutuality_class: number
          p_note?: string
        }
        Returns: {
          classe_activite: string | null
          classe_mutualite: number | null
          classe_risque_accident: string | null
          cree_le: string
          debut_validite: string
          facteur_accident: number
          fin_validite: string
          id: string
          note: string | null
          societe_id: string
          source: string
        }
        SetofOptions: {
          from: "*"
          to: "periodes_taux_societe"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_set_employee_sensitive: {
        Args: { p_employee: string; p_iban: string; p_national_id: string }
        Returns: undefined
      }
      fn_set_travel_distance: {
        Args: {
          p_destination: string
          p_km: number
          p_minutes: number
          p_note?: string
          p_origin: string
          p_source: string
        }
        Returns: Json
      }
      fn_severite_pour_echeance: {
        Args: { p_echeance: string; p_le?: string }
        Returns: Json
      }
      fn_shift_end_ts: {
        Args: { p_date: string; p_end: string; p_start: string }
        Returns: string
      }
      fn_shift_hours: {
        Args: { p_break?: number; p_end: string; p_start: string }
        Returns: number
      }
      fn_shift_start_ts: {
        Args: { p_date: string; p_start: string }
        Returns: string
      }
      fn_shift_travel: { Args: { p_shift: string }; Returns: Json }
      fn_sick_counters: {
        Args: { p_employee: string; p_on?: string }
        Returns: Json
      }
      fn_simulate_collective_dismissal: {
        Args: {
          p_company: string
          p_count: number
          p_date: string
          p_personal_ground?: boolean
        }
        Returns: Json
      }
      fn_time_entry_rows: {
        Args: {
          p_employee: string
          p_from: string
          p_limit?: number
          p_only_validated?: boolean
          p_to: string
        }
        Returns: Database["public"]["CompositeTypes"]["ligne_releve_temps"][]
        SetofOptions: {
          from: "*"
          to: "ligne_releve_temps"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      fn_travel_distance: {
        Args: { p_destination: string; p_origin: string }
        Returns: Json
      }
      fn_valid_national_id: { Args: { p_id: string }; Returns: boolean }
      fn_validate_address: {
        Args: { p_city?: string; p_country: string; p_postal: string }
        Returns: Json
      }
      fn_validate_parameter_version: {
        Args: { p_id: string }
        Returns: {
          cle_parametre: string
          debut_validite: string
          derive_de_cle: string | null
          facteur_derive: number | null
          famille: Database["public"]["Enums"]["famille_parametre"]
          fin_validite: string
          id: string
          indice_reference: number | null
          libelle: string
          note: string | null
          reference_legale: string | null
          saisi_le: string
          saisi_par: string | null
          source: string
          tolerance_derivation: number
          unite: string | null
          valeur_json: Json | null
          valeur_num: number | null
          valeur_texte: string | null
          valide_le: string | null
          valide_par: string | null
        }
        SetofOptions: {
          from: "*"
          to: "parametres_legaux"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_validate_schedule: { Args: { p_schedule: string }; Returns: Json }
      fn_verhoeff_check_digit: { Args: { p_digits: string }; Returns: number }
      fn_verifier_couverture_adresses: {
        Args: { p_depuis?: string; p_employee: string }
        Returns: Json
      }
      has_company_access: { Args: { p_company: string }; Returns: boolean }
      has_role: {
        Args: {
          p_company?: string
          p_role: Database["public"]["Enums"]["role_application"]
        }
        Returns: boolean
      }
      has_shift_in_schedule: { Args: { p_schedule: string }; Returns: boolean }
      is_self_employee: { Args: { p_employee: string }; Returns: boolean }
      schedule_is_published: { Args: { p_schedule: string }; Returns: boolean }
    }
    Enums: {
      bloc_convention:
        | "salary_grid"
        | "worktime"
        | "leave"
        | "premiums"
        | "surcharges"
        | "notice_probation"
        | "custom_holidays"
      categorie_absence:
        | "annual_leave"
        | "sick"
        | "extraordinary"
        | "public_holiday"
        | "unpaid"
        | "compensatory"
      classe_impot: "1" | "1a" | "2"
      etape_document: "pre_hire" | "during_contract" | "end_of_contract"
      etat_alerte: "open" | "handled" | "dismissed"
      famille_parametre:
        | "social"
        | "fiscal"
        | "worktime"
        | "leave"
        | "contract"
        | "effectif"
        | "ccss"
      genre_contrat: "cdi" | "cdd" | "seasonal" | "apprenticeship" | "interim"
      genre_element_remuneration:
        | "fixed"
        | "variable"
        | "benefit_in_kind"
        | "premium"
        | "expense"
      genre_organisation: "fiduciary" | "company"
      genre_qualification: "qualified" | "unqualified"
      genre_residence:
        | "resident"
        | "frontalier_fr"
        | "frontalier_be"
        | "frontalier_de"
        | "frontalier_fra"
        | "frontalier_bel"
        | "frontalier_deu"
      genre_severite: "blocking" | "warning" | "info" | "problem"
      genre_sexe: "male" | "female" | "unspecified"
      genre_statut_salarie:
        | "pregnancy"
        | "maternity_leave"
        | "breastfeeding"
        | "parental_leave"
        | "delegate"
        | "safety_delegate"
        | "equality_delegate"
        | "reemployment_bonus"
        | "company_manager"
        | "protected_other"
      periodicite_impot: "monthly" | "daily" | "annual"
      portee_convention:
        | "secteur"
        | "harassment"
        | "employee_category"
        | "department"
        | "company"
      role_application:
        | "fiduciary_admin"
        | "manager"
        | "service_manager"
        | "employee"
        | "medecine_travail"
        | "rh_urgence"
        | "dispatching"
      statut_absence:
        | "pending"
        | "approved"
        | "refused"
        | "cancelled"
        | "proposed"
      statut_contrat: "draft" | "active" | "ended" | "cancelled"
      statut_planning: "draft" | "publie"
    }
    CompositeTypes: {
      ligne_releve_temps: {
        entry_id: string | null
        salarie_id: string | null
        date_releve: string | null
        heures_travaillees: number | null
        heures_supplementaires: number | null
        heures_nuit: number | null
        heures_dimanche: number | null
        heures_ferie: number | null
        valide: boolean | null
      }
      ligne_salarie: {
        salarie_id: string | null
        societe_id: string | null
        service_id: string | null
        prenom: string | null
        nom: string | null
        courriel: string | null
        telephone: string | null
        date_naissance: string | null
        residence: Database["public"]["Enums"]["genre_residence"] | null
        qualification: Database["public"]["Enums"]["genre_qualification"] | null
        intitule_poste: string | null
        genre_contrat: Database["public"]["Enums"]["genre_contrat"] | null
        date_debut: string | null
        date_fin: string | null
        brut_mensuel: number | null
        heures_hebdomadaires: number | null
        matricule_national: string | null
        iban: string | null
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      bloc_convention: [
        "salary_grid",
        "worktime",
        "leave",
        "premiums",
        "surcharges",
        "notice_probation",
        "custom_holidays",
      ],
      categorie_absence: [
        "annual_leave",
        "sick",
        "extraordinary",
        "public_holiday",
        "unpaid",
        "compensatory",
      ],
      classe_impot: ["1", "1a", "2"],
      etape_document: ["pre_hire", "during_contract", "end_of_contract"],
      etat_alerte: ["open", "handled", "dismissed"],
      famille_parametre: [
        "social",
        "fiscal",
        "worktime",
        "leave",
        "contract",
        "effectif",
        "ccss",
      ],
      genre_contrat: ["cdi", "cdd", "seasonal", "apprenticeship", "interim"],
      genre_element_remuneration: [
        "fixed",
        "variable",
        "benefit_in_kind",
        "premium",
        "expense",
      ],
      genre_organisation: ["fiduciary", "company"],
      genre_qualification: ["qualified", "unqualified"],
      genre_residence: [
        "resident",
        "frontalier_fr",
        "frontalier_be",
        "frontalier_de",
        "frontalier_fra",
        "frontalier_bel",
        "frontalier_deu",
      ],
      genre_severite: ["blocking", "warning", "info", "problem"],
      genre_sexe: ["male", "female", "unspecified"],
      genre_statut_salarie: [
        "pregnancy",
        "maternity_leave",
        "breastfeeding",
        "parental_leave",
        "delegate",
        "safety_delegate",
        "equality_delegate",
        "reemployment_bonus",
        "company_manager",
        "protected_other",
      ],
      periodicite_impot: ["monthly", "daily", "annual"],
      portee_convention: [
        "secteur",
        "harassment",
        "employee_category",
        "department",
        "company",
      ],
      role_application: [
        "fiduciary_admin",
        "manager",
        "service_manager",
        "employee",
        "medecine_travail",
        "rh_urgence",
        "dispatching",
      ],
      statut_absence: [
        "pending",
        "approved",
        "refused",
        "cancelled",
        "proposed",
      ],
      statut_contrat: ["draft", "active", "ended", "cancelled"],
      statut_planning: ["draft", "publie"],
    },
  },
} as const
