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
      absence_entitlements: {
        Row: {
          absence_type_id: string
          block_days: number | null
          career_cap_days: number | null
          days: number | null
          frequency_note: string | null
          id: string
          legal_ref: string | null
          note: string | null
          period_months: number | null
          relationship_degree: number | null
          requires_evidence: boolean
          valid_from: string
          valid_to: string
        }
        Insert: {
          absence_type_id: string
          block_days?: number | null
          career_cap_days?: number | null
          days?: number | null
          frequency_note?: string | null
          id?: string
          legal_ref?: string | null
          note?: string | null
          period_months?: number | null
          relationship_degree?: number | null
          requires_evidence?: boolean
          valid_from?: string
          valid_to?: string
        }
        Update: {
          absence_type_id?: string
          block_days?: number | null
          career_cap_days?: number | null
          days?: number | null
          frequency_note?: string | null
          id?: string
          legal_ref?: string | null
          note?: string | null
          period_months?: number | null
          relationship_degree?: number | null
          requires_evidence?: boolean
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "absence_entitlements_absence_type_id_fkey"
            columns: ["absence_type_id"]
            isOneToOne: false
            referencedRelation: "absence_types"
            referencedColumns: ["id"]
          },
        ]
      }
      absence_types: {
        Row: {
          category: Database["public"]["Enums"]["absence_category"]
          code: string
          counts_against_leave: boolean
          id: string
          is_paid: boolean
          label: string
          legal_ref: string | null
          requires_certificate: boolean
        }
        Insert: {
          category: Database["public"]["Enums"]["absence_category"]
          code: string
          counts_against_leave?: boolean
          id?: string
          is_paid?: boolean
          label: string
          legal_ref?: string | null
          requires_certificate?: boolean
        }
        Update: {
          category?: Database["public"]["Enums"]["absence_category"]
          code?: string
          counts_against_leave?: boolean
          id?: string
          is_paid?: boolean
          label?: string
          legal_ref?: string | null
          requires_certificate?: boolean
        }
        Relationships: []
      }
      absences: {
        Row: {
          absence_parente_id: string | null
          absence_type_id: string
          certificate_document_id: string | null
          certificate_original_received: boolean
          certificate_original_received_at: string | null
          certificate_received: boolean
          certificate_received_at: string | null
          certificate_uploaded_at: string | null
          child_id: string | null
          comment: string | null
          company_id: string
          created_at: string
          days_count: number
          decided_at: string | null
          decided_by: string | null
          decision_note: string | null
          declared_by_employee: boolean
          employee_id: string
          end_date: string
          id: string
          proposee_par: string | null
          rang_proposition: number
          requested_by: string | null
          start_date: string
          status: Database["public"]["Enums"]["absence_status"]
        }
        Insert: {
          absence_parente_id?: string | null
          absence_type_id: string
          certificate_document_id?: string | null
          certificate_original_received?: boolean
          certificate_original_received_at?: string | null
          certificate_received?: boolean
          certificate_received_at?: string | null
          certificate_uploaded_at?: string | null
          child_id?: string | null
          comment?: string | null
          company_id: string
          created_at?: string
          days_count?: number
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          declared_by_employee?: boolean
          employee_id: string
          end_date: string
          id?: string
          proposee_par?: string | null
          rang_proposition?: number
          requested_by?: string | null
          start_date: string
          status?: Database["public"]["Enums"]["absence_status"]
        }
        Update: {
          absence_parente_id?: string | null
          absence_type_id?: string
          certificate_document_id?: string | null
          certificate_original_received?: boolean
          certificate_original_received_at?: string | null
          certificate_received?: boolean
          certificate_received_at?: string | null
          certificate_uploaded_at?: string | null
          child_id?: string | null
          comment?: string | null
          company_id?: string
          created_at?: string
          days_count?: number
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          declared_by_employee?: boolean
          employee_id?: string
          end_date?: string
          id?: string
          proposee_par?: string | null
          rang_proposition?: number
          requested_by?: string | null
          start_date?: string
          status?: Database["public"]["Enums"]["absence_status"]
        }
        Relationships: [
          {
            foreignKeyName: "absence_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
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
            columns: ["absence_type_id"]
            isOneToOne: false
            referencedRelation: "absence_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "absences_child_id_fkey"
            columns: ["child_id"]
            isOneToOne: false
            referencedRelation: "employee_children"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "absences_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      address_checks: {
        Row: {
          checked_at: string
          company_id: string | null
          country: string | null
          entity_id: string
          entity_table: string
          id: string
          message: string | null
          postal_code: string | null
          status: string
          zone_code: string | null
        }
        Insert: {
          checked_at?: string
          company_id?: string | null
          country?: string | null
          entity_id: string
          entity_table: string
          id?: string
          message?: string | null
          postal_code?: string | null
          status: string
          zone_code?: string | null
        }
        Update: {
          checked_at?: string
          company_id?: string | null
          country?: string | null
          entity_id?: string
          entity_table?: string
          id?: string
          message?: string | null
          postal_code?: string | null
          status?: string
          zone_code?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "address_checks_statut_ref"
            columns: ["status"]
            isOneToOne: false
            referencedRelation: "ref_statut_verification_adresse"
            referencedColumns: ["code"]
          },
        ]
      }
      address_zones: {
        Row: {
          code: string
          country: string
          id: string
          is_verified: boolean
          kind: string
          label: string
          note: string | null
          postal_from: number | null
          postal_to: number | null
          source: string
        }
        Insert: {
          code: string
          country: string
          id?: string
          is_verified?: boolean
          kind: string
          label: string
          note?: string | null
          postal_from?: number | null
          postal_to?: number | null
          source: string
        }
        Update: {
          code?: string
          country?: string
          id?: string
          is_verified?: boolean
          kind?: string
          label?: string
          note?: string | null
          postal_from?: number | null
          postal_to?: number | null
          source?: string
        }
        Relationships: []
      }
      adresses_salarie: {
        Row: {
          code_postal: string | null
          company_id: string
          created_at: string
          created_by: string | null
          debut_validite: string
          deleted_at: string | null
          deleted_by: string | null
          employee_id: string
          fin_validite: string
          id: string
          latitude: number | null
          ligne: string | null
          localite: string | null
          longitude: number | null
          note: string | null
          origine: string
          pays: string
          type_adresse: string
        }
        Insert: {
          code_postal?: string | null
          company_id: string
          created_at?: string
          created_by?: string | null
          debut_validite?: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id: string
          fin_validite?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          note?: string | null
          origine?: string
          pays?: string
          type_adresse: string
        }
        Update: {
          code_postal?: string | null
          company_id?: string
          created_at?: string
          created_by?: string | null
          debut_validite?: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id?: string
          fin_validite?: string
          id?: string
          latitude?: number | null
          ligne?: string | null
          localite?: string | null
          longitude?: number | null
          note?: string | null
          origine?: string
          pays?: string
          type_adresse?: string
        }
        Relationships: [
          {
            foreignKeyName: "adr_appartient_au_salarie"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
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
      app_secrets: {
        Row: {
          key: string
          secret: string
        }
        Insert: {
          key: string
          secret: string
        }
        Update: {
          key?: string
          secret?: string
        }
        Relationships: []
      }
      app_users: {
        Row: {
          auth_user_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          deleted_by: string | null
          email: string
          full_name: string | null
          id: string
          is_admin: boolean
          password_hash: string | null
          updated_at: string
          updated_by: string | null
          userid: string
        }
        Insert: {
          auth_user_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          email: string
          full_name?: string | null
          id?: string
          is_admin?: boolean
          password_hash?: string | null
          updated_at?: string
          updated_by?: string | null
          userid: string
        }
        Update: {
          auth_user_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          email?: string
          full_name?: string | null
          id?: string
          is_admin?: boolean
          password_hash?: string | null
          updated_at?: string
          updated_by?: string | null
          userid?: string
        }
        Relationships: []
      }
      audit_log: {
        Row: {
          action: string
          actor_id: string | null
          actor_label: string | null
          company_id: string | null
          entity_id: string | null
          entity_table: string
          id: number
          new_value: Json | null
          occurred_at: string
          old_value: Json | null
          request_id: string | null
          source_ip: string | null
          user_agent: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_label?: string | null
          company_id?: string | null
          entity_id?: string | null
          entity_table: string
          id?: number
          new_value?: Json | null
          occurred_at?: string
          old_value?: Json | null
          request_id?: string | null
          source_ip?: string | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_label?: string | null
          company_id?: string | null
          entity_id?: string | null
          entity_table?: string
          id?: number
          new_value?: Json | null
          occurred_at?: string
          old_value?: Json | null
          request_id?: string | null
          source_ip?: string | null
          user_agent?: string | null
        }
        Relationships: []
      }
      benefit_types: {
        Row: {
          code: string
          id: string
          is_contributory: boolean
          is_taxable: boolean
          label: string
          legal_ref: string | null
          note: string | null
          valuation_method: string
          valuation_params: Json
        }
        Insert: {
          code: string
          id?: string
          is_contributory?: boolean
          is_taxable?: boolean
          label: string
          legal_ref?: string | null
          note?: string | null
          valuation_method: string
          valuation_params?: Json
        }
        Update: {
          code?: string
          id?: string
          is_contributory?: boolean
          is_taxable?: boolean
          label?: string
          legal_ref?: string | null
          note?: string | null
          valuation_method?: string
          valuation_params?: Json
        }
        Relationships: []
      }
      cba_rules: {
        Row: {
          block: Database["public"]["Enums"]["cba_block"]
          collective_agreement_id: string
          id: string
          is_complete: boolean
          rules: Json
          updated_at: string
        }
        Insert: {
          block: Database["public"]["Enums"]["cba_block"]
          collective_agreement_id: string
          id?: string
          is_complete?: boolean
          rules?: Json
          updated_at?: string
        }
        Update: {
          block?: Database["public"]["Enums"]["cba_block"]
          collective_agreement_id?: string
          id?: string
          is_complete?: boolean
          rules?: Json
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cba_rules_collective_agreement_id_fkey"
            columns: ["collective_agreement_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
            referencedColumns: ["id"]
          },
        ]
      }
      cba_salary_grids: {
        Row: {
          category: string
          collective_agreement_id: string
          id: string
          index_ref: number | null
          monthly_amount: number
          seniority_from_years: number
          seniority_to_years: number | null
        }
        Insert: {
          category: string
          collective_agreement_id: string
          id?: string
          index_ref?: number | null
          monthly_amount: number
          seniority_from_years?: number
          seniority_to_years?: number | null
        }
        Update: {
          category?: string
          collective_agreement_id?: string
          id?: string
          index_ref?: number | null
          monthly_amount?: number
          seniority_from_years?: number
          seniority_to_years?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "cba_salary_grids_collective_agreement_id_fkey"
            columns: ["collective_agreement_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
            referencedColumns: ["id"]
          },
        ]
      }
      cct_regle_prime: {
        Row: {
          article: string | null
          assiette: string | null
          categorie_visee: string | null
          collective_agreement_id: string
          condition_code: string
          debut_validite: string
          fin_validite: string
          id: string
          libelle: string
          montant: number | null
          nature_prime: string
          note: string | null
          seuil_minutes: number
          source_url: string
          taux_pct: number | null
          unite: string
        }
        Insert: {
          article?: string | null
          assiette?: string | null
          categorie_visee?: string | null
          collective_agreement_id: string
          condition_code: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle: string
          montant?: number | null
          nature_prime: string
          note?: string | null
          seuil_minutes?: number
          source_url: string
          taux_pct?: number | null
          unite: string
        }
        Update: {
          article?: string | null
          assiette?: string | null
          categorie_visee?: string | null
          collective_agreement_id?: string
          condition_code?: string
          debut_validite?: string
          fin_validite?: string
          id?: string
          libelle?: string
          montant?: number | null
          nature_prime?: string
          note?: string | null
          seuil_minutes?: number
          source_url?: string
          taux_pct?: number | null
          unite?: string
        }
        Relationships: [
          {
            foreignKeyName: "cct_regle_prime_collective_agreement_id_fkey"
            columns: ["collective_agreement_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
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
      client_sites: {
        Row: {
          address_line: string | null
          city: string | null
          client_name: string | null
          company_id: string
          country: string
          created_at: string
          id: string
          is_active: boolean
          latitude: number | null
          longitude: number | null
          name: string
          note: string | null
          postal_code: string | null
        }
        Insert: {
          address_line?: string | null
          city?: string | null
          client_name?: string | null
          company_id: string
          country?: string
          created_at?: string
          id?: string
          is_active?: boolean
          latitude?: number | null
          longitude?: number | null
          name: string
          note?: string | null
          postal_code?: string | null
        }
        Update: {
          address_line?: string | null
          city?: string | null
          client_name?: string | null
          company_id?: string
          country?: string
          created_at?: string
          id?: string
          is_active?: boolean
          latitude?: number | null
          longitude?: number | null
          name?: string
          note?: string | null
          postal_code?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "client_sites_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      collective_agreements: {
        Row: {
          code: string
          created_at: string
          employee_category: string | null
          id: string
          is_active: boolean
          name: string
          organization_id: string | null
          scope: Database["public"]["Enums"]["cba_scope"]
          sector: string
          supersedes_id: string | null
          valid_from: string
          valid_to: string
        }
        Insert: {
          code: string
          created_at?: string
          employee_category?: string | null
          id?: string
          is_active?: boolean
          name: string
          organization_id?: string | null
          scope?: Database["public"]["Enums"]["cba_scope"]
          sector: string
          supersedes_id?: string | null
          valid_from?: string
          valid_to?: string
        }
        Update: {
          code?: string
          created_at?: string
          employee_category?: string | null
          id?: string
          is_active?: boolean
          name?: string
          organization_id?: string | null
          scope?: Database["public"]["Enums"]["cba_scope"]
          sector?: string
          supersedes_id?: string | null
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "collective_agreements_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collective_agreements_supersedes_id_fkey"
            columns: ["supersedes_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
            referencedColumns: ["id"]
          },
        ]
      }
      companies: {
        Row: {
          address_line: string | null
          ccss_matricule: string | null
          city: string | null
          country: string
          created_at: string
          id: string
          internal_rules_adopted_on: string | null
          internal_rules_reference: string | null
          legal_form: string | null
          legal_name: string
          nace_code: string | null
          organization_id: string
          postal_code: string | null
          rcs_number: string | null
          reference_period_months: number
          sector: string | null
        }
        Insert: {
          address_line?: string | null
          ccss_matricule?: string | null
          city?: string | null
          country?: string
          created_at?: string
          id?: string
          internal_rules_adopted_on?: string | null
          internal_rules_reference?: string | null
          legal_form?: string | null
          legal_name: string
          nace_code?: string | null
          organization_id: string
          postal_code?: string | null
          rcs_number?: string | null
          reference_period_months?: number
          sector?: string | null
        }
        Update: {
          address_line?: string | null
          ccss_matricule?: string | null
          city?: string | null
          country?: string
          created_at?: string
          id?: string
          internal_rules_adopted_on?: string | null
          internal_rules_reference?: string | null
          legal_form?: string | null
          legal_name?: string
          nace_code?: string | null
          organization_id?: string
          postal_code?: string | null
          rcs_number?: string | null
          reference_period_months?: number
          sector?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "companies_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      company_accident_claims: {
        Row: {
          claim_count: number
          company_id: string
          cost: number | null
          days_lost: number
          id: string
          note: string | null
          year: number
        }
        Insert: {
          claim_count?: number
          company_id: string
          cost?: number | null
          days_lost?: number
          id?: string
          note?: string | null
          year: number
        }
        Update: {
          claim_count?: number
          company_id?: string
          cost?: number | null
          days_lost?: number
          id?: string
          note?: string | null
          year?: number
        }
        Relationships: [
          {
            foreignKeyName: "company_accident_claims_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      company_collective_agreements: {
        Row: {
          collective_agreement_id: string
          company_id: string
          created_at: string
          department_id: string | null
          id: string
          note: string | null
          valid_from: string
          valid_to: string
        }
        Insert: {
          collective_agreement_id: string
          company_id: string
          created_at?: string
          department_id?: string | null
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string
        }
        Update: {
          collective_agreement_id?: string
          company_id?: string
          created_at?: string
          department_id?: string | null
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "company_collective_agreements_collective_agreement_id_fkey"
            columns: ["collective_agreement_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_collective_agreements_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "company_collective_agreements_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      company_financials: {
        Row: {
          company_id: string
          created_at: string
          fiscal_year: number
          id: string
          note: string | null
          profit: number | null
          revenue: number | null
          source: string | null
        }
        Insert: {
          company_id: string
          created_at?: string
          fiscal_year: number
          id?: string
          note?: string | null
          profit?: number | null
          revenue?: number | null
          source?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string
          fiscal_year?: number
          id?: string
          note?: string | null
          profit?: number | null
          revenue?: number | null
          source?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "company_financials_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      company_rate_periods: {
        Row: {
          accident_factor: number
          accident_risk_class: string | null
          activity_class: string | null
          company_id: string
          created_at: string
          id: string
          mutuality_class: number | null
          note: string | null
          source: string
          valid_from: string
          valid_to: string
        }
        Insert: {
          accident_factor?: number
          accident_risk_class?: string | null
          activity_class?: string | null
          company_id: string
          created_at?: string
          id?: string
          mutuality_class?: number | null
          note?: string | null
          source?: string
          valid_from?: string
          valid_to?: string
        }
        Update: {
          accident_factor?: number
          accident_risk_class?: string | null
          activity_class?: string | null
          company_id?: string
          created_at?: string
          id?: string
          mutuality_class?: number | null
          note?: string | null
          source?: string
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "company_rate_periods_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      compliance_alerts: {
        Row: {
          company_id: string
          consequence: string | null
          detail: string
          due_date: string | null
          employee_id: string | null
          first_seen_at: string
          handled_at: string | null
          handled_by: string | null
          handled_note: string | null
          id: string
          legal_ref: string | null
          rule_code: string
          severity: Database["public"]["Enums"]["severity_kind"]
          state: Database["public"]["Enums"]["alert_state"]
          title: string
        }
        Insert: {
          company_id: string
          consequence?: string | null
          detail: string
          due_date?: string | null
          employee_id?: string | null
          first_seen_at?: string
          handled_at?: string | null
          handled_by?: string | null
          handled_note?: string | null
          id?: string
          legal_ref?: string | null
          rule_code: string
          severity: Database["public"]["Enums"]["severity_kind"]
          state?: Database["public"]["Enums"]["alert_state"]
          title: string
        }
        Update: {
          company_id?: string
          consequence?: string | null
          detail?: string
          due_date?: string | null
          employee_id?: string | null
          first_seen_at?: string
          handled_at?: string | null
          handled_by?: string | null
          handled_note?: string | null
          id?: string
          legal_ref?: string | null
          rule_code?: string
          severity?: Database["public"]["Enums"]["severity_kind"]
          state?: Database["public"]["Enums"]["alert_state"]
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "compliance_alerts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compliance_alerts_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_amendments: {
        Row: {
          changes: Json
          company_id: string
          contract_id: string
          created_at: string
          created_by: string | null
          effective_date: string
          id: string
          reason: string
        }
        Insert: {
          changes: Json
          company_id: string
          contract_id: string
          created_at?: string
          created_by?: string | null
          effective_date: string
          id?: string
          reason: string
        }
        Update: {
          changes?: Json
          company_id?: string
          contract_id?: string
          created_at?: string
          created_by?: string | null
          effective_date?: string
          id?: string
          reason?: string
        }
        Relationships: [
          {
            foreignKeyName: "contract_amendments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_amendments_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_collective_agreements: {
        Row: {
          collective_agreement_id: string
          contract_id: string
          created_at: string
          id: string
          note: string | null
          valid_from: string
          valid_to: string
        }
        Insert: {
          collective_agreement_id: string
          contract_id: string
          created_at?: string
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string
        }
        Update: {
          collective_agreement_id?: string
          contract_id?: string
          created_at?: string
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "contract_collective_agreements_collective_agreement_id_fkey"
            columns: ["collective_agreement_id"]
            isOneToOne: false
            referencedRelation: "collective_agreements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_collective_agreements_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_pay_components: {
        Row: {
          amount: number | null
          basis: string | null
          benefit_type_id: string | null
          code: string
          company_id: string
          contract_id: string
          created_at: string
          id: string
          in_salary_reference: boolean
          is_contributory: boolean
          is_taxable: boolean
          kind: Database["public"]["Enums"]["pay_component_kind"]
          label: string
          note: string | null
          periodicity: string
          rate_pct: number | null
          valid_from: string
          valid_to: string
        }
        Insert: {
          amount?: number | null
          basis?: string | null
          benefit_type_id?: string | null
          code: string
          company_id: string
          contract_id: string
          created_at?: string
          id?: string
          in_salary_reference?: boolean
          is_contributory?: boolean
          is_taxable?: boolean
          kind: Database["public"]["Enums"]["pay_component_kind"]
          label: string
          note?: string | null
          periodicity?: string
          rate_pct?: number | null
          valid_from?: string
          valid_to?: string
        }
        Update: {
          amount?: number | null
          basis?: string | null
          benefit_type_id?: string | null
          code?: string
          company_id?: string
          contract_id?: string
          created_at?: string
          id?: string
          in_salary_reference?: boolean
          is_contributory?: boolean
          is_taxable?: boolean
          kind?: Database["public"]["Enums"]["pay_component_kind"]
          label?: string
          note?: string | null
          periodicity?: string
          rate_pct?: number | null
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "contract_pay_components_benefit_type_id_fkey"
            columns: ["benefit_type_id"]
            isOneToOne: false
            referencedRelation: "benefit_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_pay_components_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_pay_components_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_terminations: {
        Row: {
          company_id: string
          contract_id: string
          created_at: string
          id: string
          is_gross_misconduct: boolean
          is_personal_ground: boolean
          notice_end: string | null
          notice_start: string | null
          notice_waived: boolean
          notified_on: string
          reason: string
          severance_months: number | null
          waiver_agreed_on: string | null
          waiver_compensation: number | null
          waiver_note: string | null
        }
        Insert: {
          company_id: string
          contract_id: string
          created_at?: string
          id?: string
          is_gross_misconduct?: boolean
          is_personal_ground?: boolean
          notice_end?: string | null
          notice_start?: string | null
          notice_waived?: boolean
          notified_on: string
          reason: string
          severance_months?: number | null
          waiver_agreed_on?: string | null
          waiver_compensation?: number | null
          waiver_note?: string | null
        }
        Update: {
          company_id?: string
          contract_id?: string
          created_at?: string
          id?: string
          is_gross_misconduct?: boolean
          is_personal_ground?: boolean
          notice_end?: string | null
          notice_start?: string | null
          notice_waived?: boolean
          notified_on?: string
          reason?: string
          severance_months?: number | null
          waiver_agreed_on?: string | null
          waiver_compensation?: number | null
          waiver_note?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "contract_terminations_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_terminations_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      contracts: {
        Row: {
          annual_leave_days: number | null
          apprenticeship_level: string | null
          apprenticeship_year: number | null
          break_minutes: number | null
          category: string | null
          cdd_reason: string | null
          company_id: string
          created_at: string
          days_per_week: number
          employee_id: string
          end_date: string | null
          exclusivity_clause: boolean
          id: string
          index_ref: number | null
          interim_agency_id: string | null
          is_part_time: boolean
          job_description: string | null
          job_title: string
          kind: Database["public"]["Enums"]["contract_kind"]
          mission_reason: string | null
          monthly_gross: number
          night_work: boolean
          non_compete_clause: boolean
          previous_contract_id: string | null
          probation_length: number | null
          probation_unit: string | null
          reference_period_months: number
          renewal_count: number
          season_label: string | null
          signed_at: string | null
          start_date: string
          status: Database["public"]["Enums"]["contract_status"]
          user_company_name: string | null
          version: number
          weekly_hours: number
          work_distribution: string | null
          work_place: string | null
        }
        Insert: {
          annual_leave_days?: number | null
          apprenticeship_level?: string | null
          apprenticeship_year?: number | null
          break_minutes?: number | null
          category?: string | null
          cdd_reason?: string | null
          company_id: string
          created_at?: string
          days_per_week?: number
          employee_id: string
          end_date?: string | null
          exclusivity_clause?: boolean
          id?: string
          index_ref?: number | null
          interim_agency_id?: string | null
          is_part_time?: boolean
          job_description?: string | null
          job_title: string
          kind: Database["public"]["Enums"]["contract_kind"]
          mission_reason?: string | null
          monthly_gross: number
          night_work?: boolean
          non_compete_clause?: boolean
          previous_contract_id?: string | null
          probation_length?: number | null
          probation_unit?: string | null
          reference_period_months?: number
          renewal_count?: number
          season_label?: string | null
          signed_at?: string | null
          start_date: string
          status?: Database["public"]["Enums"]["contract_status"]
          user_company_name?: string | null
          version?: number
          weekly_hours?: number
          work_distribution?: string | null
          work_place?: string | null
        }
        Update: {
          annual_leave_days?: number | null
          apprenticeship_level?: string | null
          apprenticeship_year?: number | null
          break_minutes?: number | null
          category?: string | null
          cdd_reason?: string | null
          company_id?: string
          created_at?: string
          days_per_week?: number
          employee_id?: string
          end_date?: string | null
          exclusivity_clause?: boolean
          id?: string
          index_ref?: number | null
          interim_agency_id?: string | null
          is_part_time?: boolean
          job_description?: string | null
          job_title?: string
          kind?: Database["public"]["Enums"]["contract_kind"]
          mission_reason?: string | null
          monthly_gross?: number
          night_work?: boolean
          non_compete_clause?: boolean
          previous_contract_id?: string | null
          probation_length?: number | null
          probation_unit?: string | null
          reference_period_months?: number
          renewal_count?: number
          season_label?: string | null
          signed_at?: string | null
          start_date?: string
          status?: Database["public"]["Enums"]["contract_status"]
          user_company_name?: string | null
          version?: number
          weekly_hours?: number
          work_distribution?: string | null
          work_place?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "contract_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "contracts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contracts_interim_agency_fk"
            columns: ["interim_agency_id"]
            isOneToOne: false
            referencedRelation: "interim_agencies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contracts_previous_contract_id_fkey"
            columns: ["previous_contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contracts_unite_essai_ref"
            columns: ["probation_unit"]
            isOneToOne: false
            referencedRelation: "ref_unite_essai"
            referencedColumns: ["code"]
          },
        ]
      }
      creneau_condition: {
        Row: {
          client_site_id: string | null
          company_id: string
          condition_code: string
          constate_par: string | null
          created_at: string
          date_prestation: string
          deleted_at: string | null
          deleted_by: string | null
          employee_id: string
          heure_debut: string
          heure_fin: string
          id: string
          minutes: number | null
          note: string | null
          shift_id: string | null
          time_entry_id: string | null
        }
        Insert: {
          client_site_id?: string | null
          company_id: string
          condition_code: string
          constate_par?: string | null
          created_at?: string
          date_prestation: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id: string
          heure_debut: string
          heure_fin: string
          id?: string
          minutes?: number | null
          note?: string | null
          shift_id?: string | null
          time_entry_id?: string | null
        }
        Update: {
          client_site_id?: string | null
          company_id?: string
          condition_code?: string
          constate_par?: string | null
          created_at?: string
          date_prestation?: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id?: string
          heure_debut?: string
          heure_fin?: string
          id?: string
          minutes?: number | null
          note?: string | null
          shift_id?: string | null
          time_entry_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "cc_appartient_au_salarie"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "cc_site_appartient_a_la_societe"
            columns: ["client_site_id", "company_id"]
            isOneToOne: false
            referencedRelation: "client_sites"
            referencedColumns: ["id", "company_id"]
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
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "creneau_condition_time_entry_id_fkey"
            columns: ["time_entry_id"]
            isOneToOne: false
            referencedRelation: "time_entries"
            referencedColumns: ["id"]
          },
        ]
      }
      data_access_log: {
        Row: {
          action: string
          actor_id: string | null
          actor_label: string | null
          company_id: string | null
          entity_id: string | null
          entity_table: string
          id: number
          is_autonomous: boolean
          occurred_at: string
          request_id: string | null
          row_count: number | null
          scope: string | null
          source_ip: string | null
          subject_employee_id: string | null
          user_agent: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_label?: string | null
          company_id?: string | null
          entity_id?: string | null
          entity_table: string
          id?: never
          is_autonomous?: boolean
          occurred_at?: string
          request_id?: string | null
          row_count?: number | null
          scope?: string | null
          source_ip?: string | null
          subject_employee_id?: string | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_label?: string | null
          company_id?: string | null
          entity_id?: string | null
          entity_table?: string
          id?: never
          is_autonomous?: boolean
          occurred_at?: string
          request_id?: string | null
          row_count?: number | null
          scope?: string | null
          source_ip?: string | null
          subject_employee_id?: string | null
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "data_access_log_action_ref"
            columns: ["action"]
            isOneToOne: false
            referencedRelation: "ref_action_acces"
            referencedColumns: ["code"]
          },
        ]
      }
      departments: {
        Row: {
          company_id: string
          id: string
          min_evening_coverage: number | null
          name: string
        }
        Insert: {
          company_id: string
          id?: string
          min_evening_coverage?: number | null
          name: string
        }
        Update: {
          company_id?: string
          id?: string
          min_evening_coverage?: number | null
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "departments_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      document_types: {
        Row: {
          alert_days_before: number
          applies_to_residency:
            | Database["public"]["Enums"]["residency_kind"][]
            | null
          code: string
          id: string
          is_mandatory: boolean
          label: string
          legal_ref: string | null
          note: string | null
          stage: Database["public"]["Enums"]["document_stage"]
          validity_months: number | null
        }
        Insert: {
          alert_days_before?: number
          applies_to_residency?:
            | Database["public"]["Enums"]["residency_kind"][]
            | null
          code: string
          id?: string
          is_mandatory?: boolean
          label: string
          legal_ref?: string | null
          note?: string | null
          stage?: Database["public"]["Enums"]["document_stage"]
          validity_months?: number | null
        }
        Update: {
          alert_days_before?: number
          applies_to_residency?:
            | Database["public"]["Enums"]["residency_kind"][]
            | null
          code?: string
          id?: string
          is_mandatory?: boolean
          label?: string
          legal_ref?: string | null
          note?: string | null
          stage?: Database["public"]["Enums"]["document_stage"]
          validity_months?: number | null
        }
        Relationships: []
      }
      documents: {
        Row: {
          company_id: string
          created_at: string
          delivered_at: string | null
          document_type_id: string | null
          employee_id: string | null
          entity_id: string | null
          entity_table: string | null
          expires_on: string | null
          id: string
          is_sensitive: boolean
          issued_on: string | null
          mime_type: string | null
          name: string
          retention_until: string | null
          size_bytes: number | null
          storage_path: string
          uploaded_by: string | null
        }
        Insert: {
          company_id: string
          created_at?: string
          delivered_at?: string | null
          document_type_id?: string | null
          employee_id?: string | null
          entity_id?: string | null
          entity_table?: string | null
          expires_on?: string | null
          id?: string
          is_sensitive?: boolean
          issued_on?: string | null
          mime_type?: string | null
          name: string
          retention_until?: string | null
          size_bytes?: number | null
          storage_path: string
          uploaded_by?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string
          delivered_at?: string | null
          document_type_id?: string | null
          employee_id?: string | null
          entity_id?: string | null
          entity_table?: string | null
          expires_on?: string | null
          id?: string
          is_sensitive?: boolean
          issued_on?: string | null
          mime_type?: string | null
          name?: string
          retention_until?: string | null
          size_bytes?: number | null
          storage_path?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "documents_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_document_type_id_fkey"
            columns: ["document_type_id"]
            isOneToOne: false
            referencedRelation: "document_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
        ]
      }
      employee_children: {
        Row: {
          adoption_date: string | null
          birth_date: string
          company_id: string
          created_at: string
          employee_id: string
          en_situation_handicap: boolean
          first_name: string | null
          id: string
          invitation_evenements: boolean
          is_dependent: boolean
          last_name: string | null
          note: string | null
          privacy_opt_out: boolean
          refus_photos_evenements: boolean
          relationship: string
          sex: Database["public"]["Enums"]["sex_kind"] | null
          taux_handicap_pct: number | null
        }
        Insert: {
          adoption_date?: string | null
          birth_date: string
          company_id: string
          created_at?: string
          employee_id: string
          en_situation_handicap?: boolean
          first_name?: string | null
          id?: string
          invitation_evenements?: boolean
          is_dependent?: boolean
          last_name?: string | null
          note?: string | null
          privacy_opt_out?: boolean
          refus_photos_evenements?: boolean
          relationship?: string
          sex?: Database["public"]["Enums"]["sex_kind"] | null
          taux_handicap_pct?: number | null
        }
        Update: {
          adoption_date?: string | null
          birth_date?: string
          company_id?: string
          created_at?: string
          employee_id?: string
          en_situation_handicap?: boolean
          first_name?: string | null
          id?: string
          invitation_evenements?: boolean
          is_dependent?: boolean
          last_name?: string | null
          note?: string | null
          privacy_opt_out?: boolean
          refus_photos_evenements?: boolean
          relationship?: string
          sex?: Database["public"]["Enums"]["sex_kind"] | null
          taux_handicap_pct?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "child_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "employee_children_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_children_lien_ref"
            columns: ["relationship"]
            isOneToOne: false
            referencedRelation: "ref_lien_enfant"
            referencedColumns: ["code"]
          },
        ]
      }
      employee_disabilities: {
        Row: {
          authority: string | null
          company_id: string
          created_at: string
          employee_id: string
          evidence_document_id: string | null
          extra_leave_days_override: number | null
          id: string
          note: string | null
          rate_pct: number
          recognized_on: string | null
          valid_from: string
          valid_to: string
        }
        Insert: {
          authority?: string | null
          company_id: string
          created_at?: string
          employee_id: string
          evidence_document_id?: string | null
          extra_leave_days_override?: number | null
          id?: string
          note?: string | null
          rate_pct: number
          recognized_on?: string | null
          valid_from?: string
          valid_to?: string
        }
        Update: {
          authority?: string | null
          company_id?: string
          created_at?: string
          employee_id?: string
          evidence_document_id?: string | null
          extra_leave_days_override?: number | null
          id?: string
          note?: string | null
          rate_pct?: number
          recognized_on?: string | null
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "disability_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "employee_disabilities_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_disabilities_evidence_document_id_fkey"
            columns: ["evidence_document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
        ]
      }
      employee_sanctions: {
        Row: {
          amendment_contract_id: string | null
          company_id: string
          contest_outcome: string | null
          contested_on: string | null
          contract_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          deleted_by: string | null
          effective_from: string | null
          effective_to: string | null
          employee_heard_on: string | null
          employee_id: string
          employee_response: string | null
          evidence_document_id: string | null
          facts_known_on: string
          facts_on: string
          id: string
          note: string | null
          notified_on: string | null
          reason: string
          retention_until: string | null
          sanction_type: string
          termination_id: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          amendment_contract_id?: string | null
          company_id: string
          contest_outcome?: string | null
          contested_on?: string | null
          contract_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          effective_from?: string | null
          effective_to?: string | null
          employee_heard_on?: string | null
          employee_id: string
          employee_response?: string | null
          evidence_document_id?: string | null
          facts_known_on: string
          facts_on: string
          id?: string
          note?: string | null
          notified_on?: string | null
          reason: string
          retention_until?: string | null
          sanction_type: string
          termination_id?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          amendment_contract_id?: string | null
          company_id?: string
          contest_outcome?: string | null
          contested_on?: string | null
          contract_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          effective_from?: string | null
          effective_to?: string | null
          employee_heard_on?: string | null
          employee_id?: string
          employee_response?: string | null
          evidence_document_id?: string | null
          facts_known_on?: string
          facts_on?: string
          id?: string
          note?: string | null
          notified_on?: string | null
          reason?: string
          retention_until?: string | null
          sanction_type?: string
          termination_id?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "employee_sanctions_amendment_contract_id_fkey"
            columns: ["amendment_contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_sanctions_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_sanctions_evidence_document_id_fkey"
            columns: ["evidence_document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_sanctions_sanction_type_fkey"
            columns: ["sanction_type"]
            isOneToOne: false
            referencedRelation: "sanction_types"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "employee_sanctions_termination_id_fkey"
            columns: ["termination_id"]
            isOneToOne: false
            referencedRelation: "contract_terminations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sanction_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
        ]
      }
      employee_statuses: {
        Row: {
          actual_birth_date: string | null
          company_id: string
          created_at: string
          declared_on: string
          employee_id: string
          end_date: string | null
          evidence_document_id: string | null
          expected_birth_date: string | null
          hours_credit_monthly: number | null
          id: string
          kind: Database["public"]["Enums"]["employee_status_kind"]
          note: string | null
          start_date: string
        }
        Insert: {
          actual_birth_date?: string | null
          company_id: string
          created_at?: string
          declared_on?: string
          employee_id: string
          end_date?: string | null
          evidence_document_id?: string | null
          expected_birth_date?: string | null
          hours_credit_monthly?: number | null
          id?: string
          kind: Database["public"]["Enums"]["employee_status_kind"]
          note?: string | null
          start_date: string
        }
        Update: {
          actual_birth_date?: string | null
          company_id?: string
          created_at?: string
          declared_on?: string
          employee_id?: string
          end_date?: string | null
          evidence_document_id?: string | null
          expected_birth_date?: string | null
          hours_credit_monthly?: number | null
          id?: string
          kind?: Database["public"]["Enums"]["employee_status_kind"]
          note?: string | null
          start_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "employee_statuses_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_statuses_evidence_document_id_fkey"
            columns: ["evidence_document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "status_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
        ]
      }
      employee_tax_cards: {
        Row: {
          card_reference: string | null
          commute_distance_km: number | null
          company_id: string
          credits: Json
          employee_id: string
          id: string
          issued_on: string | null
          monthly_allowance: number
          other_deductions_monthly: number
          professional_expenses_monthly: number | null
          rate: number | null
          tax_class: Database["public"]["Enums"]["tax_class"]
          valid_from: string
          valid_to: string
        }
        Insert: {
          card_reference?: string | null
          commute_distance_km?: number | null
          company_id: string
          credits?: Json
          employee_id: string
          id?: string
          issued_on?: string | null
          monthly_allowance?: number
          other_deductions_monthly?: number
          professional_expenses_monthly?: number | null
          rate?: number | null
          tax_class: Database["public"]["Enums"]["tax_class"]
          valid_from?: string
          valid_to?: string
        }
        Update: {
          card_reference?: string | null
          commute_distance_km?: number | null
          company_id?: string
          credits?: Json
          employee_id?: string
          id?: string
          issued_on?: string | null
          monthly_allowance?: number
          other_deductions_monthly?: number
          professional_expenses_monthly?: number | null
          rate?: number | null
          tax_class?: Database["public"]["Enums"]["tax_class"]
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "employee_tax_cards_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_tax_cards_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
        ]
      }
      employees: {
        Row: {
          address_line: string | null
          birth_date: string | null
          career_start_date: string | null
          city: string | null
          company_id: string
          country: string
          created_at: string
          department_id: string | null
          email: string | null
          first_name: string
          iban_enc: string | null
          id: string
          is_management: boolean
          last_name: string
          national_id_enc: string | null
          national_id_hint: string | null
          phone: string | null
          postal_code: string | null
          profession: string | null
          qualification: Database["public"]["Enums"]["qualification_kind"]
          refus_photos_societe: boolean
          residency: Database["public"]["Enums"]["residency_kind"]
          sex: Database["public"]["Enums"]["sex_kind"]
          sexe_legal: Database["public"]["Enums"]["sex_kind"] | null
          souhaite_confidentialite: boolean
          user_id: string | null
        }
        Insert: {
          address_line?: string | null
          birth_date?: string | null
          career_start_date?: string | null
          city?: string | null
          company_id: string
          country?: string
          created_at?: string
          department_id?: string | null
          email?: string | null
          first_name: string
          iban_enc?: string | null
          id?: string
          is_management?: boolean
          last_name: string
          national_id_enc?: string | null
          national_id_hint?: string | null
          phone?: string | null
          postal_code?: string | null
          profession?: string | null
          qualification?: Database["public"]["Enums"]["qualification_kind"]
          refus_photos_societe?: boolean
          residency: Database["public"]["Enums"]["residency_kind"]
          sex?: Database["public"]["Enums"]["sex_kind"]
          sexe_legal?: Database["public"]["Enums"]["sex_kind"] | null
          souhaite_confidentialite?: boolean
          user_id?: string | null
        }
        Update: {
          address_line?: string | null
          birth_date?: string | null
          career_start_date?: string | null
          city?: string | null
          company_id?: string
          country?: string
          created_at?: string
          department_id?: string | null
          email?: string | null
          first_name?: string
          iban_enc?: string | null
          id?: string
          is_management?: boolean
          last_name?: string
          national_id_enc?: string | null
          national_id_hint?: string | null
          phone?: string | null
          postal_code?: string | null
          profession?: string | null
          qualification?: Database["public"]["Enums"]["qualification_kind"]
          refus_photos_societe?: boolean
          residency?: Database["public"]["Enums"]["residency_kind"]
          sex?: Database["public"]["Enums"]["sex_kind"]
          sexe_legal?: Database["public"]["Enums"]["sex_kind"] | null
          souhaite_confidentialite?: boolean
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "employees_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employees_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      expected_parameters: {
        Row: {
          note: string | null
          param_key: string
          read_by: string
        }
        Insert: {
          note?: string | null
          param_key: string
          read_by: string
        }
        Update: {
          note?: string | null
          param_key?: string
          read_by?: string
        }
        Relationships: []
      }
      export_log: {
        Row: {
          byte_size: number
          created_at: string
          id: string
          organization_id: string
          request_id: string | null
          requested_by: string | null
          row_count: number
          source_ip: string | null
          subject_id: string | null
          subject_kind: string
          user_agent: string | null
        }
        Insert: {
          byte_size?: number
          created_at?: string
          id?: string
          organization_id: string
          request_id?: string | null
          requested_by?: string | null
          row_count?: number
          source_ip?: string | null
          subject_id?: string | null
          subject_kind: string
          user_agent?: string | null
        }
        Update: {
          byte_size?: number
          created_at?: string
          id?: string
          organization_id?: string
          request_id?: string | null
          requested_by?: string | null
          row_count?: number
          source_ip?: string | null
          subject_id?: string | null
          subject_kind?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "export_log_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "export_log_sujet_ref"
            columns: ["subject_kind"]
            isOneToOne: false
            referencedRelation: "ref_sujet_export"
            referencedColumns: ["code"]
          },
        ]
      }
      fiche_sante: {
        Row: {
          allergies: string | null
          company_id: string
          deleted_at: string | null
          deleted_by: string | null
          employee_id: string | null
          enfant_id: string | null
          groupe_sanguin: string | null
          id: string
          maj_le: string
          maj_par: string | null
          medecin_telephone: string | null
          medecin_traitant: string | null
          note: string | null
          pathologies: string | null
        }
        Insert: {
          allergies?: string | null
          company_id: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id?: string | null
          enfant_id?: string | null
          groupe_sanguin?: string | null
          id?: string
          maj_le?: string
          maj_par?: string | null
          medecin_telephone?: string | null
          medecin_traitant?: string | null
          note?: string | null
          pathologies?: string | null
        }
        Update: {
          allergies?: string | null
          company_id?: string
          deleted_at?: string | null
          deleted_by?: string | null
          employee_id?: string | null
          enfant_id?: string | null
          groupe_sanguin?: string | null
          id?: string
          maj_le?: string
          maj_par?: string | null
          medecin_telephone?: string | null
          medecin_traitant?: string | null
          note?: string | null
          pathologies?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fiche_sante_enfant_id_fkey"
            columns: ["enfant_id"]
            isOneToOne: false
            referencedRelation: "employee_children"
            referencedColumns: ["id"]
          },
        ]
      }
      headcount_snapshots: {
        Row: {
          company_id: string
          headcount: number
          id: string
          month: string
        }
        Insert: {
          company_id: string
          headcount: number
          id?: string
          month: string
        }
        Update: {
          company_id?: string
          headcount?: number
          id?: string
          month?: string
        }
        Relationships: [
          {
            foreignKeyName: "headcount_snapshots_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      interim_agencies: {
        Row: {
          address_line: string | null
          ccss_matricule: string | null
          city: string | null
          created_at: string
          id: string
          name: string
          organization_id: string
          postal_code: string | null
          rcs_number: string | null
        }
        Insert: {
          address_line?: string | null
          ccss_matricule?: string | null
          city?: string | null
          created_at?: string
          id?: string
          name: string
          organization_id: string
          postal_code?: string | null
          rcs_number?: string | null
        }
        Update: {
          address_line?: string | null
          ccss_matricule?: string | null
          city?: string | null
          created_at?: string
          id?: string
          name?: string
          organization_id?: string
          postal_code?: string | null
          rcs_number?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "interim_agencies_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      legal_parameters: {
        Row: {
          derivation_tolerance: number
          derived_factor: number | null
          derived_from_key: string | null
          entered_at: string
          entered_by: string | null
          family: Database["public"]["Enums"]["param_family"]
          id: string
          index_ref: number | null
          label: string
          legal_ref: string | null
          note: string | null
          param_key: string
          source: string
          unit: string | null
          valid_from: string
          valid_to: string
          validated_at: string | null
          validated_by: string | null
          value_json: Json | null
          value_num: number | null
          value_text: string | null
        }
        Insert: {
          derivation_tolerance?: number
          derived_factor?: number | null
          derived_from_key?: string | null
          entered_at?: string
          entered_by?: string | null
          family: Database["public"]["Enums"]["param_family"]
          id?: string
          index_ref?: number | null
          label: string
          legal_ref?: string | null
          note?: string | null
          param_key: string
          source: string
          unit?: string | null
          valid_from?: string
          valid_to?: string
          validated_at?: string | null
          validated_by?: string | null
          value_json?: Json | null
          value_num?: number | null
          value_text?: string | null
        }
        Update: {
          derivation_tolerance?: number
          derived_factor?: number | null
          derived_from_key?: string | null
          entered_at?: string
          entered_by?: string | null
          family?: Database["public"]["Enums"]["param_family"]
          id?: string
          index_ref?: number | null
          label?: string
          legal_ref?: string | null
          note?: string | null
          param_key?: string
          source?: string
          unit?: string | null
          valid_from?: string
          valid_to?: string
          validated_at?: string | null
          validated_by?: string | null
          value_json?: Json | null
          value_num?: number | null
          value_text?: string | null
        }
        Relationships: []
      }
      meal_voucher_grants: {
        Row: {
          company_id: string
          created_at: string
          employee_id: string
          employee_share: number
          face_value: number
          granted_on: string | null
          id: string
          note: string | null
          period_end: string
          period_start: string
          voucher_count: number
        }
        Insert: {
          company_id: string
          created_at?: string
          employee_id: string
          employee_share?: number
          face_value: number
          granted_on?: string | null
          id?: string
          note?: string | null
          period_end: string
          period_start: string
          voucher_count: number
        }
        Update: {
          company_id?: string
          created_at?: string
          employee_id?: string
          employee_share?: number
          face_value?: number
          granted_on?: string | null
          id?: string
          note?: string | null
          period_end?: string
          period_start?: string
          voucher_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "meal_voucher_grants_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "voucher_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
        ]
      }
      organizations: {
        Row: {
          created_at: string
          id: string
          kind: Database["public"]["Enums"]["org_kind"]
          name: string
        }
        Insert: {
          created_at?: string
          id?: string
          kind?: Database["public"]["Enums"]["org_kind"]
          name: string
        }
        Update: {
          created_at?: string
          id?: string
          kind?: Database["public"]["Enums"]["org_kind"]
          name?: string
        }
        Relationships: []
      }
      overtime_requests: {
        Row: {
          company_id: string
          compensation: string
          employee_accepted_at: string | null
          employee_id: string
          hours: number
          hr_validated_at: string | null
          hr_validated_by: string | null
          id: string
          note: string | null
          period_end: string
          period_start: string
          reason: string
          rejected_reason: string | null
          requested_at: string
          requested_by: string | null
          schedule_id: string | null
          status: string
        }
        Insert: {
          company_id: string
          compensation?: string
          employee_accepted_at?: string | null
          employee_id: string
          hours: number
          hr_validated_at?: string | null
          hr_validated_by?: string | null
          id?: string
          note?: string | null
          period_end: string
          period_start: string
          reason: string
          rejected_reason?: string | null
          requested_at?: string
          requested_by?: string | null
          schedule_id?: string | null
          status?: string
        }
        Update: {
          company_id?: string
          compensation?: string
          employee_accepted_at?: string | null
          employee_id?: string
          hours?: number
          hr_validated_at?: string | null
          hr_validated_by?: string | null
          id?: string
          note?: string | null
          period_end?: string
          period_start?: string
          reason?: string
          rejected_reason?: string | null
          requested_at?: string
          requested_by?: string | null
          schedule_id?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "overtime_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "overtime_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "overtime_requests_compensation_ref"
            columns: ["compensation"]
            isOneToOne: false
            referencedRelation: "ref_compensation_heures_sup"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "overtime_requests_schedule_id_fkey"
            columns: ["schedule_id"]
            isOneToOne: false
            referencedRelation: "schedules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "overtime_requests_statut_ref"
            columns: ["status"]
            isOneToOne: false
            referencedRelation: "ref_statut_heures_sup"
            referencedColumns: ["code"]
          },
        ]
      }
      personne_indicateur_secours: {
        Row: {
          company_id: string
          created_at: string
          debut_validite: string
          employee_id: string | null
          enfant_id: string | null
          fin_validite: string
          id: string
          indicateur: string
          pose_par: string | null
          precision_lieu: string | null
        }
        Insert: {
          company_id: string
          created_at?: string
          debut_validite?: string
          employee_id?: string | null
          enfant_id?: string | null
          fin_validite?: string
          id?: string
          indicateur: string
          pose_par?: string | null
          precision_lieu?: string | null
        }
        Update: {
          company_id?: string
          created_at?: string
          debut_validite?: string
          employee_id?: string | null
          enfant_id?: string | null
          fin_validite?: string
          id?: string
          indicateur?: string
          pose_par?: string | null
          precision_lieu?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "personne_indicateur_secours_enfant_id_fkey"
            columns: ["enfant_id"]
            isOneToOne: false
            referencedRelation: "employee_children"
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
      premiums: {
        Row: {
          amount: number
          company_id: string
          contract_id: string | null
          created_at: string
          employee_id: string
          exempt_pct: number
          fiscal_year: number
          granted_on: string
          id: string
          is_contributory: boolean
          is_taxable: boolean
          kind: string
          label: string
          note: string | null
          termination_id: string | null
        }
        Insert: {
          amount: number
          company_id: string
          contract_id?: string | null
          created_at?: string
          employee_id: string
          exempt_pct?: number
          fiscal_year: number
          granted_on: string
          id?: string
          is_contributory?: boolean
          is_taxable?: boolean
          kind?: string
          label: string
          note?: string | null
          termination_id?: string | null
        }
        Update: {
          amount?: number
          company_id?: string
          contract_id?: string | null
          created_at?: string
          employee_id?: string
          exempt_pct?: number
          fiscal_year?: number
          granted_on?: string
          id?: string
          is_contributory?: boolean
          is_taxable?: boolean
          kind?: string
          label?: string
          note?: string | null
          termination_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "premium_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "premiums_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "premiums_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "premiums_nature_ref"
            columns: ["kind"]
            isOneToOne: false
            referencedRelation: "ref_nature_prime"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "premiums_termination_id_fkey"
            columns: ["termination_id"]
            isOneToOne: false
            referencedRelation: "contract_terminations"
            referencedColumns: ["id"]
          },
        ]
      }
      probation_extensions: {
        Row: {
          contract_id: string
          days_added: number
          from_date: string
          id: string
          reason: string
          to_date: string
        }
        Insert: {
          contract_id: string
          days_added: number
          from_date: string
          id?: string
          reason?: string
          to_date: string
        }
        Update: {
          contract_id?: string
          days_added?: number
          from_date?: string
          id?: string
          reason?: string
          to_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "probation_extensions_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          email: string
          full_name: string
          id: string
          is_org_admin: boolean
          organization_id: string
        }
        Insert: {
          created_at?: string
          email?: string
          full_name?: string
          id: string
          is_org_admin?: boolean
          organization_id: string
        }
        Update: {
          created_at?: string
          email?: string
          full_name?: string
          id?: string
          is_org_admin?: boolean
          organization_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      public_holidays: {
        Row: {
          collective_agreement_id: string | null
          holiday_date: string
          id: string
          is_mobile: boolean
          is_recoverable: boolean
          name: string
          recovery_reason: string | null
          year: number
        }
        Insert: {
          collective_agreement_id?: string | null
          holiday_date: string
          id?: string
          is_mobile?: boolean
          is_recoverable?: boolean
          name: string
          recovery_reason?: string | null
          year: number
        }
        Update: {
          collective_agreement_id?: string | null
          holiday_date?: string
          id?: string
          is_mobile?: boolean
          is_recoverable?: boolean
          name?: string
          recovery_reason?: string | null
          year?: number
        }
        Relationships: []
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
          source_url: string | null
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
          source_url?: string | null
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
          source_url?: string | null
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
      reference_periods: {
        Row: {
          company_id: string
          department_id: string | null
          end_date: string
          id: string
          label: string
          months: number
          start_date: string
        }
        Insert: {
          company_id: string
          department_id?: string | null
          end_date: string
          id?: string
          label: string
          months: number
          start_date: string
        }
        Update: {
          company_id?: string
          department_id?: string | null
          end_date?: string
          id?: string
          label?: string
          months?: number
          start_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "reference_periods_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reference_periods_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      sanction_categories: {
        Row: {
          code: string
          description: string
          label: string
          rank: number
          valid_from: string
          valid_to: string
        }
        Insert: {
          code: string
          description: string
          label: string
          rank: number
          valid_from?: string
          valid_to?: string
        }
        Update: {
          code?: string
          description?: string
          label?: string
          rank?: number
          valid_from?: string
          valid_to?: string
        }
        Relationships: []
      }
      sanction_types: {
        Row: {
          affects_pay: boolean
          affects_presence: boolean
          category_code: string
          code: string
          description: string
          ends_contract: boolean
          is_contract_change: boolean
          label: string
          legal_ref: string | null
          needs_notice: boolean | null
          note: string | null
          requires_internal_rules: boolean
          valid_from: string
          valid_to: string
        }
        Insert: {
          affects_pay?: boolean
          affects_presence?: boolean
          category_code: string
          code: string
          description: string
          ends_contract?: boolean
          is_contract_change?: boolean
          label: string
          legal_ref?: string | null
          needs_notice?: boolean | null
          note?: string | null
          requires_internal_rules?: boolean
          valid_from?: string
          valid_to?: string
        }
        Update: {
          affects_pay?: boolean
          affects_presence?: boolean
          category_code?: string
          code?: string
          description?: string
          ends_contract?: boolean
          is_contract_change?: boolean
          label?: string
          legal_ref?: string | null
          needs_notice?: boolean | null
          note?: string | null
          requires_internal_rules?: boolean
          valid_from?: string
          valid_to?: string
        }
        Relationships: [
          {
            foreignKeyName: "sanction_types_category_code_fkey"
            columns: ["category_code"]
            isOneToOne: false
            referencedRelation: "sanction_categories"
            referencedColumns: ["code"]
          },
        ]
      }
      schedules: {
        Row: {
          company_id: string
          created_at: string
          department_id: string | null
          id: string
          label: string | null
          published_at: string | null
          published_by: string | null
          status: Database["public"]["Enums"]["schedule_status"]
          week_start: string
        }
        Insert: {
          company_id: string
          created_at?: string
          department_id?: string | null
          id?: string
          label?: string | null
          published_at?: string | null
          published_by?: string | null
          status?: Database["public"]["Enums"]["schedule_status"]
          week_start: string
        }
        Update: {
          company_id?: string
          created_at?: string
          department_id?: string | null
          id?: string
          label?: string | null
          published_at?: string | null
          published_by?: string | null
          status?: Database["public"]["Enums"]["schedule_status"]
          week_start?: string
        }
        Relationships: [
          {
            foreignKeyName: "schedules_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "schedules_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      shift_templates: {
        Row: {
          break_minutes: number
          color: string
          company_id: string
          department_id: string | null
          end_time: string
          id: string
          name: string
          start_time: string
        }
        Insert: {
          break_minutes?: number
          color?: string
          company_id: string
          department_id?: string | null
          end_time: string
          id?: string
          name: string
          start_time: string
        }
        Update: {
          break_minutes?: number
          color?: string
          company_id?: string
          department_id?: string | null
          end_time?: string
          id?: string
          name?: string
          start_time?: string
        }
        Relationships: [
          {
            foreignKeyName: "shift_templates_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shift_templates_department_id_fkey"
            columns: ["department_id"]
            isOneToOne: false
            referencedRelation: "departments"
            referencedColumns: ["id"]
          },
        ]
      }
      shifts: {
        Row: {
          break_minutes: number
          client_site_id: string | null
          company_id: string
          created_at: string
          employee_id: string
          end_time: string
          id: string
          label: string | null
          schedule_id: string
          shift_date: string
          start_time: string
          template_id: string | null
        }
        Insert: {
          break_minutes?: number
          client_site_id?: string | null
          company_id: string
          created_at?: string
          employee_id: string
          end_time: string
          id?: string
          label?: string | null
          schedule_id: string
          shift_date: string
          start_time: string
          template_id?: string | null
        }
        Update: {
          break_minutes?: number
          client_site_id?: string | null
          company_id?: string
          created_at?: string
          employee_id?: string
          end_time?: string
          id?: string
          label?: string | null
          schedule_id?: string
          shift_date?: string
          start_time?: string
          template_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "shift_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "shift_belongs_to_schedules_company"
            columns: ["schedule_id", "company_id"]
            isOneToOne: false
            referencedRelation: "schedules"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "shift_site_belongs_to_company"
            columns: ["client_site_id", "company_id"]
            isOneToOne: false
            referencedRelation: "client_sites"
            referencedColumns: ["id", "company_id"]
          },
          {
            foreignKeyName: "shifts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shifts_template_id_fkey"
            columns: ["template_id"]
            isOneToOne: false
            referencedRelation: "shift_templates"
            referencedColumns: ["id"]
          },
        ]
      }
      tax_brackets: {
        Row: {
          base_tax: number
          bracket_max: number | null
          bracket_min: number
          id: string
          legal_ref: string | null
          note: string | null
          periodicity: Database["public"]["Enums"]["tax_periodicity"]
          rate_over_min: number
          source: string
          tax_class: Database["public"]["Enums"]["tax_class"]
          valid_from: string
          valid_to: string
        }
        Insert: {
          base_tax?: number
          bracket_max?: number | null
          bracket_min: number
          id?: string
          legal_ref?: string | null
          note?: string | null
          periodicity?: Database["public"]["Enums"]["tax_periodicity"]
          rate_over_min: number
          source?: string
          tax_class: Database["public"]["Enums"]["tax_class"]
          valid_from?: string
          valid_to?: string
        }
        Update: {
          base_tax?: number
          bracket_max?: number | null
          bracket_min?: number
          id?: string
          legal_ref?: string | null
          note?: string | null
          periodicity?: Database["public"]["Enums"]["tax_periodicity"]
          rate_over_min?: number
          source?: string
          tax_class?: Database["public"]["Enums"]["tax_class"]
          valid_from?: string
          valid_to?: string
        }
        Relationships: []
      }
      tax_credits: {
        Row: {
          applies_to_classes: Database["public"]["Enums"]["tax_class"][] | null
          code: string
          id: string
          income_max: number | null
          income_min: number | null
          label: string
          legal_ref: string | null
          monthly_amount: number | null
          note: string | null
          prorated_on_hours: boolean
          source: string
          valid_from: string
          valid_to: string
        }
        Insert: {
          applies_to_classes?: Database["public"]["Enums"]["tax_class"][] | null
          code: string
          id?: string
          income_max?: number | null
          income_min?: number | null
          label: string
          legal_ref?: string | null
          monthly_amount?: number | null
          note?: string | null
          prorated_on_hours?: boolean
          source?: string
          valid_from?: string
          valid_to?: string
        }
        Update: {
          applies_to_classes?: Database["public"]["Enums"]["tax_class"][] | null
          code?: string
          id?: string
          income_max?: number | null
          income_min?: number | null
          label?: string
          legal_ref?: string | null
          monthly_amount?: number | null
          note?: string | null
          prorated_on_hours?: boolean
          source?: string
          valid_from?: string
          valid_to?: string
        }
        Relationships: []
      }
      time_entries: {
        Row: {
          break_minutes: number
          company_id: string
          created_at: string
          employee_id: string
          end_time: string | null
          entry_date: string
          holiday_hours: number
          id: string
          is_validated: boolean
          night_hours: number
          note: string | null
          overtime_hours: number
          planned_hours: number | null
          source: string
          start_time: string | null
          sunday_hours: number
          worked_hours: number | null
        }
        Insert: {
          break_minutes?: number
          company_id: string
          created_at?: string
          employee_id: string
          end_time?: string | null
          entry_date: string
          holiday_hours?: number
          id?: string
          is_validated?: boolean
          night_hours?: number
          note?: string | null
          overtime_hours?: number
          planned_hours?: number | null
          source?: string
          start_time?: string | null
          sunday_hours?: number
          worked_hours?: number | null
        }
        Update: {
          break_minutes?: number
          company_id?: string
          created_at?: string
          employee_id?: string
          end_time?: string | null
          entry_date?: string
          holiday_hours?: number
          id?: string
          is_validated?: boolean
          night_hours?: number
          note?: string | null
          overtime_hours?: number
          planned_hours?: number | null
          source?: string
          start_time?: string | null
          sunday_hours?: number
          worked_hours?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "time_entries_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "time_entry_belongs_to_employees_company"
            columns: ["employee_id", "company_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id", "company_id"]
          },
        ]
      }
      travel_distances: {
        Row: {
          computed_at: string
          computed_by: string | null
          destination_ref: string
          distance_km: number
          duration_minutes: number | null
          id: string
          note: string | null
          origin_ref: string
          source: string
        }
        Insert: {
          computed_at?: string
          computed_by?: string | null
          destination_ref: string
          distance_km: number
          duration_minutes?: number | null
          id?: string
          note?: string | null
          origin_ref: string
          source: string
        }
        Update: {
          computed_at?: string
          computed_by?: string | null
          destination_ref?: string
          distance_km?: number
          duration_minutes?: number | null
          id?: string
          note?: string | null
          origin_ref?: string
          source?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          company_id: string | null
          created_at: string
          id: string
          organization_id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          company_id?: string | null
          created_at?: string
          id?: string
          organization_id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          company_id?: string | null
          created_at?: string
          id?: string
          organization_id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      auth_org_id: { Args: never; Returns: string }
      can_manage_company: { Args: { p_company: string }; Returns: boolean }
      fn_absence_entitlement: {
        Args: { p_on?: string; p_type: string }
        Returns: {
          absence_type_id: string
          block_days: number | null
          career_cap_days: number | null
          days: number | null
          frequency_note: string | null
          id: string
          legal_ref: string | null
          note: string | null
          period_months: number | null
          relationship_degree: number | null
          requires_evidence: boolean
          valid_from: string
          valid_to: string
        }
        SetofOptions: {
          from: "*"
          to: "absence_entitlements"
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
          derivation_tolerance: number
          derived_factor: number | null
          derived_from_key: string | null
          entered_at: string
          entered_by: string | null
          family: Database["public"]["Enums"]["param_family"]
          id: string
          index_ref: number | null
          label: string
          legal_ref: string | null
          note: string | null
          param_key: string
          source: string
          unit: string | null
          valid_from: string
          valid_to: string
          validated_at: string | null
          validated_by: string | null
          value_json: Json | null
          value_num: number | null
          value_text: string | null
        }
        SetofOptions: {
          from: "*"
          to: "legal_parameters"
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
          collective_agreement_id: string
          name: string
          origin: string
          scope: Database["public"]["Enums"]["cba_scope"]
          valid_from: string
          valid_to: string
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
          p_block: Database["public"]["Enums"]["cba_block"]
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
          p_block: Database["public"]["Enums"]["cba_block"]
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
          p_sex?: Database["public"]["Enums"]["sex_kind"]
        }
        Returns: Json
      }
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
        Returns: Database["public"]["CompositeTypes"]["employee_row"][]
        SetofOptions: {
          from: "*"
          to: "employee_row"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      fn_employee_sensitive: {
        Args: { p_employee: string }
        Returns: {
          iban: string
          national_id: string
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
          collective_agreement_id: string | null
          holiday_date: string
          id: string
          is_mobile: boolean
          is_recoverable: boolean
          name: string
          recovery_reason: string | null
          year: number
        }[]
        SetofOptions: {
          from: "*"
          to: "public_holidays"
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
          p_class: Database["public"]["Enums"]["tax_class"]
          p_on?: string
          p_periodicity?: Database["public"]["Enums"]["tax_periodicity"]
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
              p_sex?: Database["public"]["Enums"]["sex_kind"]
            }
            Returns: string
          }
      fn_meal_voucher_check: { Args: { p_grant: string }; Returns: Json }
      fn_migration_source: { Args: { p_version: string }; Returns: string }
      fn_migrations_list: {
        Args: never
        Returns: {
          name: string
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
        Returns: Database["public"]["Enums"]["sex_kind"]
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
          company_id: string
          compensation: string
          employee_accepted_at: string | null
          employee_id: string
          hours: number
          hr_validated_at: string | null
          hr_validated_by: string | null
          id: string
          note: string | null
          period_end: string
          period_start: string
          reason: string
          rejected_reason: string | null
          requested_at: string
          requested_by: string | null
          schedule_id: string | null
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "overtime_requests"
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
          derivation_tolerance: number
          derived_factor: number | null
          derived_from_key: string | null
          entered_at: string
          entered_by: string | null
          family: Database["public"]["Enums"]["param_family"]
          id: string
          index_ref: number | null
          label: string
          legal_ref: string | null
          note: string | null
          param_key: string
          source: string
          unit: string | null
          valid_from: string
          valid_to: string
          validated_at: string | null
          validated_by: string | null
          value_json: Json | null
          value_num: number | null
          value_text: string | null
        }
        SetofOptions: {
          from: "*"
          to: "legal_parameters"
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
          covers_since: boolean
          earliest_covered: string
          family: Database["public"]["Enums"]["param_family"]
          gap_days: number
          label: string
          latest_covered: string
          param_key: string
          read_by: string
          versions: number
        }[]
      }
      fn_referential_holes: {
        Args: never
        Returns: {
          gap_from: string
          gap_to: string
          param_key: string
        }[]
      }
      fn_referential_inconsistencies: {
        Args: { p_on?: string }
        Returns: {
          derived: number
          difference: number
          label: string
          param_key: string
          published: number
          source_key: string
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
          accident_factor: number
          accident_risk_class: string | null
          activity_class: string | null
          company_id: string
          created_at: string
          id: string
          mutuality_class: number | null
          note: string | null
          source: string
          valid_from: string
          valid_to: string
        }
        SetofOptions: {
          from: "*"
          to: "company_rate_periods"
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
        Returns: Database["public"]["CompositeTypes"]["time_entry_row"][]
        SetofOptions: {
          from: "*"
          to: "time_entry_row"
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
          derivation_tolerance: number
          derived_factor: number | null
          derived_from_key: string | null
          entered_at: string
          entered_by: string | null
          family: Database["public"]["Enums"]["param_family"]
          id: string
          index_ref: number | null
          label: string
          legal_ref: string | null
          note: string | null
          param_key: string
          source: string
          unit: string | null
          valid_from: string
          valid_to: string
          validated_at: string | null
          validated_by: string | null
          value_json: Json | null
          value_num: number | null
          value_text: string | null
        }
        SetofOptions: {
          from: "*"
          to: "legal_parameters"
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
          p_role: Database["public"]["Enums"]["app_role"]
        }
        Returns: boolean
      }
      has_shift_in_schedule: { Args: { p_schedule: string }; Returns: boolean }
      is_org_admin: { Args: never; Returns: boolean }
      is_self_employee: { Args: { p_employee: string }; Returns: boolean }
      schedule_is_published: { Args: { p_schedule: string }; Returns: boolean }
    }
    Enums: {
      absence_category:
        | "annual_leave"
        | "sick"
        | "extraordinary"
        | "public_holiday"
        | "unpaid"
        | "compensatory"
      absence_status:
        | "pending"
        | "approved"
        | "refused"
        | "cancelled"
        | "proposed"
      alert_state: "open" | "handled" | "dismissed"
      app_role:
        | "fiduciary_admin"
        | "manager"
        | "service_manager"
        | "employee"
        | "medecine_travail"
        | "rh_urgence"
        | "dispatching"
      cba_block:
        | "salary_grid"
        | "worktime"
        | "leave"
        | "premiums"
        | "surcharges"
        | "notice_probation"
        | "custom_holidays"
      cba_scope:
        | "sector"
        | "harassment"
        | "employee_category"
        | "department"
        | "company"
      contract_kind: "cdi" | "cdd" | "seasonal" | "apprenticeship" | "interim"
      contract_status: "draft" | "active" | "ended" | "cancelled"
      document_stage: "pre_hire" | "during_contract" | "end_of_contract"
      employee_status_kind:
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
      org_kind: "fiduciary" | "company"
      param_family:
        | "social"
        | "fiscal"
        | "worktime"
        | "leave"
        | "contract"
        | "headcount"
        | "ccss"
      pay_component_kind:
        | "fixed"
        | "variable"
        | "benefit_in_kind"
        | "premium"
        | "expense"
      qualification_kind: "qualified" | "unqualified"
      residency_kind:
        | "resident"
        | "frontalier_fr"
        | "frontalier_be"
        | "frontalier_de"
        | "frontalier_fra"
        | "frontalier_bel"
        | "frontalier_deu"
      schedule_status: "draft" | "published"
      severity_kind: "blocking" | "warning" | "info" | "problem"
      sex_kind: "male" | "female" | "unspecified"
      tax_class: "1" | "1a" | "2"
      tax_periodicity: "monthly" | "daily" | "annual"
    }
    CompositeTypes: {
      employee_row: {
        employee_id: string | null
        company_id: string | null
        department_id: string | null
        first_name: string | null
        last_name: string | null
        email: string | null
        phone: string | null
        birth_date: string | null
        residency: Database["public"]["Enums"]["residency_kind"] | null
        qualification: Database["public"]["Enums"]["qualification_kind"] | null
        job_title: string | null
        contract_kind: Database["public"]["Enums"]["contract_kind"] | null
        start_date: string | null
        end_date: string | null
        monthly_gross: number | null
        weekly_hours: number | null
        national_id: string | null
        iban: string | null
      }
      time_entry_row: {
        entry_id: string | null
        employee_id: string | null
        entry_date: string | null
        worked_hours: number | null
        overtime_hours: number | null
        night_hours: number | null
        sunday_hours: number | null
        holiday_hours: number | null
        is_validated: boolean | null
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
      absence_category: [
        "annual_leave",
        "sick",
        "extraordinary",
        "public_holiday",
        "unpaid",
        "compensatory",
      ],
      absence_status: [
        "pending",
        "approved",
        "refused",
        "cancelled",
        "proposed",
      ],
      alert_state: ["open", "handled", "dismissed"],
      app_role: [
        "fiduciary_admin",
        "manager",
        "service_manager",
        "employee",
        "medecine_travail",
        "rh_urgence",
        "dispatching",
      ],
      cba_block: [
        "salary_grid",
        "worktime",
        "leave",
        "premiums",
        "surcharges",
        "notice_probation",
        "custom_holidays",
      ],
      cba_scope: [
        "sector",
        "harassment",
        "employee_category",
        "department",
        "company",
      ],
      contract_kind: ["cdi", "cdd", "seasonal", "apprenticeship", "interim"],
      contract_status: ["draft", "active", "ended", "cancelled"],
      document_stage: ["pre_hire", "during_contract", "end_of_contract"],
      employee_status_kind: [
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
      org_kind: ["fiduciary", "company"],
      param_family: [
        "social",
        "fiscal",
        "worktime",
        "leave",
        "contract",
        "headcount",
        "ccss",
      ],
      pay_component_kind: [
        "fixed",
        "variable",
        "benefit_in_kind",
        "premium",
        "expense",
      ],
      qualification_kind: ["qualified", "unqualified"],
      residency_kind: [
        "resident",
        "frontalier_fr",
        "frontalier_be",
        "frontalier_de",
        "frontalier_fra",
        "frontalier_bel",
        "frontalier_deu",
      ],
      schedule_status: ["draft", "published"],
      severity_kind: ["blocking", "warning", "info", "problem"],
      sex_kind: ["male", "female", "unspecified"],
      tax_class: ["1", "1a", "2"],
      tax_periodicity: ["monthly", "daily", "annual"],
    },
  },
} as const
