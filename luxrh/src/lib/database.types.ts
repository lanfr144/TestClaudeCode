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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
          requested_by: string | null
          start_date: string
          status: Database["public"]["Enums"]["absence_status"]
        }
        Insert: {
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
          requested_by?: string | null
          start_date: string
          status?: Database["public"]["Enums"]["absence_status"]
        }
        Update: {
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
          requested_by?: string | null
          start_date?: string
          status?: Database["public"]["Enums"]["absence_status"]
        }
        Relationships: [
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
          {
            foreignKeyName: "absences_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
          valid_to: string | null
        }
        Insert: {
          collective_agreement_id: string
          company_id: string
          created_at?: string
          department_id?: string | null
          id?: string
          note?: string | null
          valid_from: string
          valid_to?: string | null
        }
        Update: {
          collective_agreement_id?: string
          company_id?: string
          created_at?: string
          department_id?: string | null
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string | null
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
          valid_to: string | null
        }
        Insert: {
          collective_agreement_id: string
          contract_id: string
          created_at?: string
          id?: string
          note?: string | null
          valid_from: string
          valid_to?: string | null
        }
        Update: {
          collective_agreement_id?: string
          contract_id?: string
          created_at?: string
          id?: string
          note?: string | null
          valid_from?: string
          valid_to?: string | null
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
            foreignKeyName: "contracts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contracts_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
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
          first_name: string | null
          id: string
          is_dependent: boolean
          last_name: string | null
          note: string | null
          privacy_opt_out: boolean
          relationship: string
          sex: Database["public"]["Enums"]["sex_kind"] | null
        }
        Insert: {
          adoption_date?: string | null
          birth_date: string
          company_id: string
          created_at?: string
          employee_id: string
          first_name?: string | null
          id?: string
          is_dependent?: boolean
          last_name?: string | null
          note?: string | null
          privacy_opt_out?: boolean
          relationship?: string
          sex?: Database["public"]["Enums"]["sex_kind"] | null
        }
        Update: {
          adoption_date?: string | null
          birth_date?: string
          company_id?: string
          created_at?: string
          employee_id?: string
          first_name?: string | null
          id?: string
          is_dependent?: boolean
          last_name?: string | null
          note?: string | null
          privacy_opt_out?: boolean
          relationship?: string
          sex?: Database["public"]["Enums"]["sex_kind"] | null
        }
        Relationships: [
          {
            foreignKeyName: "employee_children_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_children_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "employee_disabilities_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_disabilities_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
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
            foreignKeyName: "employee_statuses_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "employee_statuses_evidence_document_id_fkey"
            columns: ["evidence_document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
          residency: Database["public"]["Enums"]["residency_kind"]
          sex: Database["public"]["Enums"]["sex_kind"]
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
          residency: Database["public"]["Enums"]["residency_kind"]
          sex?: Database["public"]["Enums"]["sex_kind"]
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
          residency?: Database["public"]["Enums"]["residency_kind"]
          sex?: Database["public"]["Enums"]["sex_kind"]
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
            foreignKeyName: "meal_voucher_grants_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
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
            foreignKeyName: "overtime_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "overtime_requests_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "overtime_requests_schedule_id_fkey"
            columns: ["schedule_id"]
            isOneToOne: false
            referencedRelation: "schedules"
            referencedColumns: ["id"]
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
            foreignKeyName: "premiums_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
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
            foreignKeyName: "shifts_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shifts_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shifts_schedule_id_fkey"
            columns: ["schedule_id"]
            isOneToOne: false
            referencedRelation: "schedules"
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
          valid_to: string | null
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
          valid_from: string
          valid_to?: string | null
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
          valid_to?: string | null
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
            foreignKeyName: "time_entries_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "employees"
            referencedColumns: ["id"]
          },
        ]
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
          valid_to: string | null
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
          valid_to: string | null
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
      fn_cba_value: {
        Args: {
          p_block: Database["public"]["Enums"]["cba_block"]
          p_cba: string
          p_path: string
        }
        Returns: Json
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
      fn_income_tax: {
        Args: {
          p_class: Database["public"]["Enums"]["tax_class"]
          p_on?: string
          p_periodicity?: Database["public"]["Enums"]["tax_periodicity"]
          p_taxable: number
        }
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
      fn_min_salary: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_national_id_birth_date: { Args: { p_id: string }; Returns: string }
      fn_national_id_sex: {
        Args: { p_id: string }
        Returns: Database["public"]["Enums"]["sex_kind"]
      }
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
          valid_to: string | null
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
      fn_premium_caps: {
        Args: { p_company: string; p_year: number }
        Returns: Json
      }
      fn_premium_check: { Args: { p_premium: string }; Returns: Json }
      fn_probation: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
      fn_publish_schedule: { Args: { p_schedule: string }; Returns: Json }
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
      fn_salary_reference: {
        Args: { p_contract: string; p_on?: string }
        Returns: Json
      }
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
          valid_to: string | null
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
      fn_valid_national_id: { Args: { p_id: string }; Returns: boolean }
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
          valid_to: string | null
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
      absence_status: "pending" | "approved" | "refused" | "cancelled"
      alert_state: "open" | "handled" | "dismissed"
      app_role: "fiduciary_admin" | "manager" | "service_manager" | "employee"
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
      schedule_status: "draft" | "published"
      severity_kind: "blocking" | "warning" | "info"
      sex_kind: "male" | "female" | "unspecified"
      tax_class: "1" | "1a" | "2"
      tax_periodicity: "monthly" | "daily" | "annual"
    }
    CompositeTypes: {
      [_ in never]: never
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
      absence_status: ["pending", "approved", "refused", "cancelled"],
      alert_state: ["open", "handled", "dismissed"],
      app_role: ["fiduciary_admin", "manager", "service_manager", "employee"],
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
      ],
      schedule_status: ["draft", "published"],
      severity_kind: ["blocking", "warning", "info"],
      sex_kind: ["male", "female", "unspecified"],
      tax_class: ["1", "1a", "2"],
      tax_periodicity: ["monthly", "daily", "annual"],
    },
  },
} as const
