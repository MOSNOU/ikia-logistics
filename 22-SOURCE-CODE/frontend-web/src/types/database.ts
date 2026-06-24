export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  app_storage: {
    Tables: {
      file_associations: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          entity_id: string
          entity_type: string
          file_id: string
          id: string
          metadata: Json
          organization_id: string
          role: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          entity_id: string
          entity_type: string
          file_id: string
          id?: string
          metadata?: Json
          organization_id: string
          role?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          entity_id?: string
          entity_type?: string
          file_id?: string
          id?: string
          metadata?: Json
          organization_id?: string
          role?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "file_associations_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
        ]
      }
      file_versions: {
        Row: {
          archived_at: string | null
          bucket: string
          checksum: string | null
          created_at: string
          deleted_at: string | null
          file_id: string
          id: string
          metadata: Json
          mime_type: string | null
          object_key: string
          organization_id: string
          size_bytes: number | null
          status: Database["app_storage"]["Enums"]["file_version_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          uploaded_at: string | null
          uploaded_by_user_id: string | null
          version: number
          version_number: number
        }
        Insert: {
          archived_at?: string | null
          bucket: string
          checksum?: string | null
          created_at?: string
          deleted_at?: string | null
          file_id: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          object_key: string
          organization_id: string
          size_bytes?: number | null
          status?: Database["app_storage"]["Enums"]["file_version_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          uploaded_at?: string | null
          uploaded_by_user_id?: string | null
          version?: number
          version_number: number
        }
        Update: {
          archived_at?: string | null
          bucket?: string
          checksum?: string | null
          created_at?: string
          deleted_at?: string | null
          file_id?: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          object_key?: string
          organization_id?: string
          size_bytes?: number | null
          status?: Database["app_storage"]["Enums"]["file_version_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          uploaded_at?: string | null
          uploaded_by_user_id?: string | null
          version?: number
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "file_versions_file_id_fkey"
            columns: ["file_id"]
            isOneToOne: false
            referencedRelation: "files"
            referencedColumns: ["id"]
          },
        ]
      }
      files: {
        Row: {
          archived_at: string | null
          archived_by: string | null
          archived_reason: string | null
          bucket: string
          checksum: string | null
          created_at: string
          current_version: number
          deleted_at: string | null
          extension: string | null
          file_type: Database["app_storage"]["Enums"]["file_type"]
          filename: string
          id: string
          metadata: Json
          mime_type: string | null
          object_key: string
          organization_id: string
          processed_at: string | null
          size_bytes: number | null
          status: Database["app_storage"]["Enums"]["file_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          uploaded_at: string | null
          uploaded_by_user_id: string | null
          version: number
        }
        Insert: {
          archived_at?: string | null
          archived_by?: string | null
          archived_reason?: string | null
          bucket: string
          checksum?: string | null
          created_at?: string
          current_version?: number
          deleted_at?: string | null
          extension?: string | null
          file_type?: Database["app_storage"]["Enums"]["file_type"]
          filename: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          object_key: string
          organization_id: string
          processed_at?: string | null
          size_bytes?: number | null
          status?: Database["app_storage"]["Enums"]["file_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          uploaded_at?: string | null
          uploaded_by_user_id?: string | null
          version?: number
        }
        Update: {
          archived_at?: string | null
          archived_by?: string | null
          archived_reason?: string | null
          bucket?: string
          checksum?: string | null
          created_at?: string
          current_version?: number
          deleted_at?: string | null
          extension?: string | null
          file_type?: Database["app_storage"]["Enums"]["file_type"]
          filename?: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          object_key?: string
          organization_id?: string
          processed_at?: string | null
          size_bytes?: number | null
          status?: Database["app_storage"]["Enums"]["file_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          uploaded_at?: string | null
          uploaded_by_user_id?: string | null
          version?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_force_archive_file: {
        Args: { p_file_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_get_file: { Args: { p_file_id: string }; Returns: Json }
      admin_list_files: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["app_storage"]["Enums"]["file_status"]
        }
        Returns: {
          bucket: string
          created_at: string
          current_version: number
          filename: string
          id: string
          mime_type: string
          object_key: string
          organization_id: string
          status: string
        }[]
      }
      fn_assert_authenticated_member: {
        Args: never
        Returns: {
          organization_id: string
          tenant_id: string
        }[]
      }
      fn_assert_file_owned: { Args: { p_file_id: string }; Returns: undefined }
      fn_audit: {
        Args: { p_action_code: string; p_file_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_caller_can_see_entity: {
        Args: { p_entity_id: string; p_entity_type: string }
        Returns: boolean
      }
      fn_default_object_key: {
        Args: {
          p_file_id: string
          p_filename: string
          p_organization_id: string
        }
        Returns: string
      }
      portal_archive_file: {
        Args: { p_file_id: string; p_reason?: string }
        Returns: undefined
      }
      portal_create_file_version: {
        Args: {
          p_file_id: string
          p_metadata?: Json
          p_mime_type?: string
          p_size_bytes?: number
        }
        Returns: Json
      }
      portal_finalize_file_upload: {
        Args: { p_checksum?: string; p_file_id: string; p_size_bytes?: number }
        Returns: undefined
      }
      portal_get_file_metadata: { Args: { p_file_id: string }; Returns: Json }
      portal_link_file_to_entity: {
        Args: {
          p_entity_id: string
          p_entity_type: string
          p_file_id: string
          p_metadata?: Json
          p_role?: string
        }
        Returns: string
      }
      portal_list_files_for_entity: {
        Args: {
          p_entity_id: string
          p_entity_type: string
          p_limit?: number
          p_offset?: number
        }
        Returns: {
          association_id: string
          bucket: string
          created_at: string
          current_version: number
          file_id: string
          filename: string
          mime_type: string
          object_key: string
          role: string
          size_bytes: number
          status: string
          updated_at: string
        }[]
      }
      portal_list_my_files: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["app_storage"]["Enums"]["file_status"]
        }
        Returns: {
          bucket: string
          created_at: string
          current_version: number
          filename: string
          id: string
          mime_type: string
          object_key: string
          size_bytes: number
          status: string
          updated_at: string
        }[]
      }
      portal_register_file: {
        Args: {
          p_bucket?: string
          p_extension?: string
          p_file_type?: Database["app_storage"]["Enums"]["file_type"]
          p_filename: string
          p_metadata?: Json
          p_mime_type?: string
          p_size_bytes?: number
        }
        Returns: Json
      }
      portal_remove_file_association: {
        Args: { p_association_id: string }
        Returns: undefined
      }
    }
    Enums: {
      file_status: "pending" | "uploaded" | "processed" | "archived"
      file_type: "pdf" | "image" | "doc" | "xlsx" | "txt" | "other"
      file_version_status: "pending" | "uploaded" | "archived" | "superseded"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  audit: {
    Tables: {
      audit_access: {
        Row: {
          access_type: Database["audit"]["Enums"]["access_type"]
          accessed_at: string
          actor_user_id: string | null
          denial_reason: string | null
          id: string
          organization_id: string | null
          request_id: string | null
          resource_id: string | null
          resource_type: string | null
          tenant_id: string | null
        }
        Insert: {
          access_type: Database["audit"]["Enums"]["access_type"]
          accessed_at?: string
          actor_user_id?: string | null
          denial_reason?: string | null
          id?: string
          organization_id?: string | null
          request_id?: string | null
          resource_id?: string | null
          resource_type?: string | null
          tenant_id?: string | null
        }
        Update: {
          access_type?: Database["audit"]["Enums"]["access_type"]
          accessed_at?: string
          actor_user_id?: string | null
          denial_reason?: string | null
          id?: string
          organization_id?: string | null
          request_id?: string | null
          resource_id?: string | null
          resource_type?: string | null
          tenant_id?: string | null
        }
        Relationships: []
      }
      audit_entity: {
        Row: {
          action: Database["audit"]["Enums"]["audit_action"]
          actor_user_id: string | null
          after_state: Json | null
          before_state: Json | null
          changed_at: string
          changed_columns: string[] | null
          entity_id: string
          entity_schema: string
          entity_table: string
          id: string
          organization_id: string | null
          tenant_id: string | null
        }
        Insert: {
          action: Database["audit"]["Enums"]["audit_action"]
          actor_user_id?: string | null
          after_state?: Json | null
          before_state?: Json | null
          changed_at?: string
          changed_columns?: string[] | null
          entity_id: string
          entity_schema: string
          entity_table: string
          id?: string
          organization_id?: string | null
          tenant_id?: string | null
        }
        Update: {
          action?: Database["audit"]["Enums"]["audit_action"]
          actor_user_id?: string | null
          after_state?: Json | null
          before_state?: Json | null
          changed_at?: string
          changed_columns?: string[] | null
          entity_id?: string
          entity_schema?: string
          entity_table?: string
          id?: string
          organization_id?: string | null
          tenant_id?: string | null
        }
        Relationships: []
      }
      audit_event: {
        Row: {
          action_code: string
          actor_user_id: string | null
          id: string
          ip_address: unknown
          occurred_at: string
          organization_id: string | null
          payload: Json | null
          request_id: string | null
          resource_id: string | null
          resource_type: string | null
          tenant_id: string | null
          user_agent: string | null
        }
        Insert: {
          action_code: string
          actor_user_id?: string | null
          id?: string
          ip_address?: unknown
          occurred_at?: string
          organization_id?: string | null
          payload?: Json | null
          request_id?: string | null
          resource_id?: string | null
          resource_type?: string | null
          tenant_id?: string | null
          user_agent?: string | null
        }
        Update: {
          action_code?: string
          actor_user_id?: string | null
          id?: string
          ip_address?: unknown
          occurred_at?: string
          organization_id?: string | null
          payload?: Json | null
          request_id?: string | null
          resource_id?: string | null
          resource_type?: string | null
          tenant_id?: string | null
          user_agent?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      access_type: "read" | "write" | "export" | "denied"
      audit_action: "insert" | "update" | "delete"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  commodity: {
    Tables: {
      categories: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          metadata: Json
          name_en: string
          name_fa: string
          parent_category_id: string | null
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json
          name_en: string
          name_fa: string
          parent_category_id?: string | null
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json
          name_en?: string
          name_fa?: string
          parent_category_id?: string | null
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_category_id_fkey"
            columns: ["parent_category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      product_aliases: {
        Row: {
          alias: string
          alias_type: string
          created_at: string
          id: string
          language: string | null
          product_id: string
        }
        Insert: {
          alias: string
          alias_type?: string
          created_at?: string
          id?: string
          language?: string | null
          product_id: string
        }
        Update: {
          alias?: string
          alias_type?: string
          created_at?: string
          id?: string
          language?: string | null
          product_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_aliases_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_document_requirements: {
        Row: {
          created_at: string
          display_name_en: string | null
          display_name_fa: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          id: string
          is_active: boolean
          notes: string | null
          product_id: string
          requirement_level: Database["commodity"]["Enums"]["document_requirement_level"]
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          id?: string
          is_active?: boolean
          notes?: string | null
          product_id: string
          requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          sort_order?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind?: Database["commodity"]["Enums"]["document_kind"]
          id?: string
          is_active?: boolean
          notes?: string | null
          product_id?: string
          requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_document_requirements_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_specifications: {
        Row: {
          created_at: string
          data_type: Database["commodity"]["Enums"]["spec_data_type"]
          default_value: string | null
          description: string | null
          display_name_en: string
          display_name_fa: string
          enum_values: Json | null
          id: string
          is_active: boolean
          is_required: boolean
          max_value: number | null
          min_value: number | null
          product_id: string
          sort_order: number
          spec_key: string
          unit: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          data_type: Database["commodity"]["Enums"]["spec_data_type"]
          default_value?: string | null
          description?: string | null
          display_name_en: string
          display_name_fa: string
          enum_values?: Json | null
          id?: string
          is_active?: boolean
          is_required?: boolean
          max_value?: number | null
          min_value?: number | null
          product_id: string
          sort_order?: number
          spec_key: string
          unit?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          default_value?: string | null
          description?: string | null
          display_name_en?: string
          display_name_fa?: string
          enum_values?: Json | null
          id?: string
          is_active?: boolean
          is_required?: boolean
          max_value?: number | null
          min_value?: number | null
          product_id?: string
          sort_order?: number
          spec_key?: string
          unit?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_specifications_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          cas_number: string | null
          category_id: string
          code: string
          created_at: string
          description: string | null
          hs_code: string | null
          id: string
          metadata: Json
          name_en: string
          name_fa: string
          physical_form: Database["commodity"]["Enums"]["physical_form"] | null
          slug: string
          status: Database["commodity"]["Enums"]["product_status"]
          unit_of_trade: string | null
          updated_at: string
        }
        Insert: {
          cas_number?: string | null
          category_id: string
          code: string
          created_at?: string
          description?: string | null
          hs_code?: string | null
          id?: string
          metadata?: Json
          name_en: string
          name_fa: string
          physical_form?: Database["commodity"]["Enums"]["physical_form"] | null
          slug: string
          status?: Database["commodity"]["Enums"]["product_status"]
          unit_of_trade?: string | null
          updated_at?: string
        }
        Update: {
          cas_number?: string | null
          category_id?: string
          code?: string
          created_at?: string
          description?: string | null
          hs_code?: string | null
          id?: string
          metadata?: Json
          name_en?: string
          name_fa?: string
          physical_form?: Database["commodity"]["Enums"]["physical_form"] | null
          slug?: string
          status?: Database["commodity"]["Enums"]["product_status"]
          unit_of_trade?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_product_capabilities: {
        Row: {
          capability_status: Database["commodity"]["Enums"]["capability_status"]
          capacity_unit: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          incoterms: Json
          metadata: Json
          minimum_order_quantity: number | null
          monthly_capacity: number | null
          moq_unit: string | null
          notes: string | null
          organization_id: string
          origin_city: string | null
          origin_country: string | null
          payment_terms_text: string | null
          product_id: string
          supplier_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          capability_status?: Database["commodity"]["Enums"]["capability_status"]
          capacity_unit?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          incoterms?: Json
          metadata?: Json
          minimum_order_quantity?: number | null
          monthly_capacity?: number | null
          moq_unit?: string | null
          notes?: string | null
          organization_id: string
          origin_city?: string | null
          origin_country?: string | null
          payment_terms_text?: string | null
          product_id: string
          supplier_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          capability_status?: Database["commodity"]["Enums"]["capability_status"]
          capacity_unit?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          incoterms?: Json
          metadata?: Json
          minimum_order_quantity?: number | null
          monthly_capacity?: number | null
          moq_unit?: string | null
          notes?: string | null
          organization_id?: string
          origin_city?: string | null
          origin_country?: string | null
          payment_terms_text?: string | null
          product_id?: string
          supplier_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_product_capabilities_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_create_category: {
        Args: {
          p_code: string
          p_description?: string
          p_name_en: string
          p_name_fa: string
          p_parent_category_id?: string
          p_sort_order?: number
        }
        Returns: string
      }
      admin_create_product: {
        Args: {
          p_cas_number?: string
          p_category_id: string
          p_code: string
          p_description?: string
          p_hs_code?: string
          p_name_en: string
          p_name_fa: string
          p_physical_form?: Database["commodity"]["Enums"]["physical_form"]
          p_slug: string
          p_status?: Database["commodity"]["Enums"]["product_status"]
          p_unit_of_trade?: string
        }
        Returns: string
      }
      admin_get_product: {
        Args: { p_product_id: string }
        Returns: {
          cas_number: string
          category_code: string
          category_id: string
          code: string
          created_at: string
          description: string
          hs_code: string
          id: string
          metadata: Json
          name_en: string
          name_fa: string
          physical_form: string
          slug: string
          status: string
          unit_of_trade: string
          updated_at: string
        }[]
      }
      admin_list_categories: {
        Args: { p_active?: boolean }
        Returns: {
          code: string
          id: string
          is_active: boolean
          name_en: string
          name_fa: string
          parent_category_id: string
          product_count: number
          sort_order: number
        }[]
      }
      admin_list_products: {
        Args: {
          p_category_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["commodity"]["Enums"]["product_status"]
        }
        Returns: {
          category_code: string
          category_id: string
          code: string
          created_at: string
          doc_req_count: number
          hs_code: string
          id: string
          name_en: string
          name_fa: string
          slug: string
          spec_count: number
          status: string
          updated_at: string
        }[]
      }
      admin_list_supplier_capabilities: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_product_id?: string
          p_status?: Database["commodity"]["Enums"]["capability_status"]
          p_supplier_id?: string
        }
        Returns: {
          capability_status: string
          capacity_unit: string
          created_at: string
          id: string
          monthly_capacity: number
          organization_id: string
          origin_country: string
          product_code: string
          product_id: string
          product_name_en: string
          supplier_id: string
          updated_at: string
        }[]
      }
      admin_remove_product_document_requirement: {
        Args: { p_doc_req_id: string }
        Returns: undefined
      }
      admin_remove_product_specification: {
        Args: { p_spec_id: string }
        Returns: undefined
      }
      admin_set_capability_status: {
        Args: {
          p_capability_id: string
          p_status: Database["commodity"]["Enums"]["capability_status"]
        }
        Returns: undefined
      }
      admin_update_category: {
        Args: {
          p_category_id: string
          p_description?: string
          p_is_active?: boolean
          p_name_en?: string
          p_name_fa?: string
          p_sort_order?: number
        }
        Returns: undefined
      }
      admin_update_product: {
        Args: {
          p_cas_number?: string
          p_description?: string
          p_hs_code?: string
          p_name_en?: string
          p_name_fa?: string
          p_physical_form?: Database["commodity"]["Enums"]["physical_form"]
          p_product_id: string
          p_status?: Database["commodity"]["Enums"]["product_status"]
          p_unit_of_trade?: string
        }
        Returns: undefined
      }
      admin_upsert_product_document_requirement: {
        Args: {
          p_display_name_en?: string
          p_display_name_fa?: string
          p_document_kind: Database["commodity"]["Enums"]["document_kind"]
          p_notes?: string
          p_product_id: string
          p_requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          p_sort_order?: number
        }
        Returns: string
      }
      admin_upsert_product_specification: {
        Args: {
          p_data_type: Database["commodity"]["Enums"]["spec_data_type"]
          p_default_value?: string
          p_description?: string
          p_display_name_en: string
          p_display_name_fa: string
          p_enum_values?: Json
          p_is_required?: boolean
          p_max_value?: number
          p_min_value?: number
          p_product_id: string
          p_sort_order?: number
          p_spec_key: string
          p_unit?: string
        }
        Returns: string
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_resource_id: string
          p_supplier_id?: string
        }
        Returns: undefined
      }
      portal_get_product: {
        Args: { p_product_id: string }
        Returns: {
          cas_number: string
          category_code: string
          category_id: string
          code: string
          description: string
          document_requirements: Json
          hs_code: string
          id: string
          name_en: string
          name_fa: string
          physical_form: string
          slug: string
          specifications: Json
          status: string
          unit_of_trade: string
        }[]
      }
      portal_list_categories: {
        Args: never
        Returns: {
          code: string
          id: string
          name_en: string
          name_fa: string
          parent_category_id: string
          sort_order: number
        }[]
      }
      portal_list_products: {
        Args: { p_category_id?: string }
        Returns: {
          category_code: string
          category_id: string
          code: string
          hs_code: string
          id: string
          name_en: string
          name_fa: string
          physical_form: string
          slug: string
          unit_of_trade: string
        }[]
      }
      portal_remove_my_capability: {
        Args: { p_product_id: string }
        Returns: undefined
      }
      portal_upsert_my_capability: {
        Args: {
          p_capability_status?: Database["commodity"]["Enums"]["capability_status"]
          p_capacity_unit?: string
          p_incoterms?: Json
          p_minimum_order_quantity?: number
          p_monthly_capacity?: number
          p_moq_unit?: string
          p_notes?: string
          p_origin_city?: string
          p_origin_country?: string
          p_payment_terms_text?: string
          p_product_id: string
        }
        Returns: string
      }
    }
    Enums: {
      capability_status: "active" | "paused" | "suspended" | "withdrawn"
      document_kind:
        | "tds"
        | "msds_sds"
        | "coa"
        | "product_sheet"
        | "packing_list"
        | "certificate_of_origin"
        | "inspection_certificate"
        | "quality_certificate"
        | "customs_document"
        | "other"
      document_requirement_level: "mandatory" | "recommended" | "optional"
      physical_form:
        | "solid"
        | "liquid"
        | "gas"
        | "granule"
        | "powder"
        | "viscous"
        | "pellet"
        | "sheet"
        | "bar"
        | "other"
      product_status: "draft" | "active" | "inactive" | "deprecated"
      spec_data_type:
        | "number"
        | "integer"
        | "text"
        | "enum"
        | "boolean"
        | "range"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  contract: {
    Tables: {
      contract_parties: {
        Row: {
          contract_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          display_name: string
          id: string
          is_required_signer: boolean
          metadata: Json
          organization_id: string
          party_organization_id: string | null
          party_supplier_id: string | null
          party_type: Database["contract"]["Enums"]["party_type"]
          party_user_id: string | null
          role_title: string | null
          signer_role: string | null
          signing_order: number
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          contract_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name: string
          id?: string
          is_required_signer?: boolean
          metadata?: Json
          organization_id: string
          party_organization_id?: string | null
          party_supplier_id?: string | null
          party_type: Database["contract"]["Enums"]["party_type"]
          party_user_id?: string | null
          role_title?: string | null
          signer_role?: string | null
          signing_order?: number
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          contract_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name?: string
          id?: string
          is_required_signer?: boolean
          metadata?: Json
          organization_id?: string
          party_organization_id?: string | null
          party_supplier_id?: string | null
          party_type?: Database["contract"]["Enums"]["party_type"]
          party_user_id?: string | null
          role_title?: string | null
          signer_role?: string | null
          signing_order?: number
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "contract_parties_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_preparation_clauses: {
        Row: {
          body_en: string | null
          body_fa: string | null
          clause_key: string | null
          clause_type: Database["contract"]["Enums"]["preparation_clause_type"]
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          is_required: boolean
          metadata: Json
          organization_id: string
          preparation_id: string
          sort_order: number
          source: string | null
          tenant_id: string
          title_en: string | null
          title_fa: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          body_en?: string | null
          body_fa?: string | null
          clause_key?: string | null
          clause_type: Database["contract"]["Enums"]["preparation_clause_type"]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          is_required?: boolean
          metadata?: Json
          organization_id: string
          preparation_id: string
          sort_order?: number
          source?: string | null
          tenant_id: string
          title_en?: string | null
          title_fa?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          body_en?: string | null
          body_fa?: string | null
          clause_key?: string | null
          clause_type?: Database["contract"]["Enums"]["preparation_clause_type"]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          is_required?: boolean
          metadata?: Json
          organization_id?: string
          preparation_id?: string
          sort_order?: number
          source?: string | null
          tenant_id?: string
          title_en?: string | null
          title_fa?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "contract_preparation_clauses_preparation_id_fkey"
            columns: ["preparation_id"]
            isOneToOne: false
            referencedRelation: "contract_preparations"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_preparation_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          from_status:
            | Database["contract"]["Enums"]["preparation_status"]
            | null
          id: string
          organization_id: string
          payload: Json
          preparation_id: string
          reason: string | null
          tenant_id: string
          to_status: Database["contract"]["Enums"]["preparation_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?:
            | Database["contract"]["Enums"]["preparation_status"]
            | null
          id?: string
          organization_id: string
          payload?: Json
          preparation_id: string
          reason?: string | null
          tenant_id: string
          to_status: Database["contract"]["Enums"]["preparation_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?:
            | Database["contract"]["Enums"]["preparation_status"]
            | null
          id?: string
          organization_id?: string
          payload?: Json
          preparation_id?: string
          reason?: string | null
          tenant_id?: string
          to_status?: Database["contract"]["Enums"]["preparation_status"]
        }
        Relationships: [
          {
            foreignKeyName: "contract_preparation_events_preparation_id_fkey"
            columns: ["preparation_id"]
            isOneToOne: false
            referencedRelation: "contract_preparations"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_preparation_items: {
        Row: {
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          delivery_lead_time_text: string | null
          delivery_window_end: string | null
          delivery_window_start: string | null
          id: string
          metadata: Json
          notes: string | null
          offer_item_id: string
          organization_id: string
          origin_city: string | null
          origin_country: string | null
          packaging: string | null
          preparation_id: string
          product_id: string
          quantity: number | null
          quantity_unit: string | null
          request_item_id: string
          sort_order: number
          tenant_id: string
          total_price: number | null
          unit_price: number | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_item_id: string
          organization_id: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          preparation_id: string
          product_id: string
          quantity?: number | null
          quantity_unit?: string | null
          request_item_id: string
          sort_order?: number
          tenant_id: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_item_id?: string
          organization_id?: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          preparation_id?: string
          product_id?: string
          quantity?: number | null
          quantity_unit?: string | null
          request_item_id?: string
          sort_order?: number
          tenant_id?: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "contract_preparation_items_preparation_id_fkey"
            columns: ["preparation_id"]
            isOneToOne: false
            referencedRelation: "contract_preparations"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_preparation_snapshots: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          notes: string | null
          organization_id: string
          preparation_id: string
          snapshot_data: Json
          snapshot_type: Database["contract"]["Enums"]["preparation_snapshot_type"]
          tenant_id: string
          title: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id: string
          preparation_id: string
          snapshot_data?: Json
          snapshot_type: Database["contract"]["Enums"]["preparation_snapshot_type"]
          tenant_id: string
          title: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id?: string
          preparation_id?: string
          snapshot_data?: Json
          snapshot_type?: Database["contract"]["Enums"]["preparation_snapshot_type"]
          tenant_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "contract_preparation_snapshots_preparation_id_fkey"
            columns: ["preparation_id"]
            isOneToOne: false
            referencedRelation: "contract_preparations"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_preparations: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          contract_type: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at: string
          created_by: string | null
          currency: string
          decision_id: string
          deleted_at: string | null
          delivery_city: string | null
          delivery_country: string | null
          delivery_location_text: string | null
          delivery_port: string | null
          delivery_terms_text: string | null
          dispute_resolution_text: string | null
          governing_law_text: string | null
          id: string
          incoterm: string | null
          inspection_terms_text: string | null
          internal_notes: string | null
          metadata: Json
          offer_id: string
          organization_id: string
          payment_terms_text: string | null
          preparation_code: string
          prepared_by: string | null
          ready_at: string | null
          ready_by: string | null
          request_id: string
          special_conditions_text: string | null
          status: Database["contract"]["Enums"]["preparation_status"]
          submitted_for_review_at: string | null
          submitted_for_review_by: string | null
          superseded_at: string | null
          superseded_by: string | null
          superseded_reason: string | null
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at?: string
          created_by?: string | null
          currency?: string
          decision_id: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          delivery_terms_text?: string | null
          dispute_resolution_text?: string | null
          governing_law_text?: string | null
          id?: string
          incoterm?: string | null
          inspection_terms_text?: string | null
          internal_notes?: string | null
          metadata?: Json
          offer_id: string
          organization_id: string
          payment_terms_text?: string | null
          preparation_code: string
          prepared_by?: string | null
          ready_at?: string | null
          ready_by?: string | null
          request_id: string
          special_conditions_text?: string | null
          status?: Database["contract"]["Enums"]["preparation_status"]
          submitted_for_review_at?: string | null
          submitted_for_review_by?: string | null
          superseded_at?: string | null
          superseded_by?: string | null
          superseded_reason?: string | null
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at?: string
          created_by?: string | null
          currency?: string
          decision_id?: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          delivery_terms_text?: string | null
          dispute_resolution_text?: string | null
          governing_law_text?: string | null
          id?: string
          incoterm?: string | null
          inspection_terms_text?: string | null
          internal_notes?: string | null
          metadata?: Json
          offer_id?: string
          organization_id?: string
          payment_terms_text?: string | null
          preparation_code?: string
          prepared_by?: string | null
          ready_at?: string | null
          ready_by?: string | null
          request_id?: string
          special_conditions_text?: string | null
          status?: Database["contract"]["Enums"]["preparation_status"]
          submitted_for_review_at?: string | null
          submitted_for_review_by?: string | null
          superseded_at?: string | null
          superseded_by?: string | null
          superseded_reason?: string | null
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      contract_signature_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          contract_id: string
          created_at: string
          event_type: string
          from_status: Database["contract"]["Enums"]["signature_status"] | null
          id: string
          metadata: Json
          organization_id: string
          reason: string | null
          signature_request_id: string
          tenant_id: string
          to_status: Database["contract"]["Enums"]["signature_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          contract_id: string
          created_at?: string
          event_type: string
          from_status?: Database["contract"]["Enums"]["signature_status"] | null
          id?: string
          metadata?: Json
          organization_id: string
          reason?: string | null
          signature_request_id: string
          tenant_id: string
          to_status: Database["contract"]["Enums"]["signature_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          contract_id?: string
          created_at?: string
          event_type?: string
          from_status?: Database["contract"]["Enums"]["signature_status"] | null
          id?: string
          metadata?: Json
          organization_id?: string
          reason?: string | null
          signature_request_id?: string
          tenant_id?: string
          to_status?: Database["contract"]["Enums"]["signature_status"]
        }
        Relationships: [
          {
            foreignKeyName: "contract_signature_events_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_signature_events_signature_request_id_fkey"
            columns: ["signature_request_id"]
            isOneToOne: false
            referencedRelation: "contract_signature_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      contract_signature_requests: {
        Row: {
          cancelled_at: string | null
          cancelled_reason: string | null
          completed_at: string | null
          contract_id: string
          created_at: string
          created_by: string | null
          decline_reason: string | null
          declined_at: string | null
          deleted_at: string | null
          due_at: string | null
          id: string
          metadata: Json
          organization_id: string
          party_id: string
          requested_at: string
          requested_to_email: string | null
          requested_to_user: string | null
          signed_at: string | null
          status: Database["contract"]["Enums"]["signature_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
          viewed_at: string | null
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_reason?: string | null
          completed_at?: string | null
          contract_id: string
          created_at?: string
          created_by?: string | null
          decline_reason?: string | null
          declined_at?: string | null
          deleted_at?: string | null
          due_at?: string | null
          id?: string
          metadata?: Json
          organization_id: string
          party_id: string
          requested_at?: string
          requested_to_email?: string | null
          requested_to_user?: string | null
          signed_at?: string | null
          status?: Database["contract"]["Enums"]["signature_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          viewed_at?: string | null
        }
        Update: {
          cancelled_at?: string | null
          cancelled_reason?: string | null
          completed_at?: string | null
          contract_id?: string
          created_at?: string
          created_by?: string | null
          decline_reason?: string | null
          declined_at?: string | null
          deleted_at?: string | null
          due_at?: string | null
          id?: string
          metadata?: Json
          organization_id?: string
          party_id?: string
          requested_at?: string
          requested_to_email?: string | null
          requested_to_user?: string | null
          signed_at?: string | null
          status?: Database["contract"]["Enums"]["signature_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          viewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "contract_signature_requests_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contract_signature_requests_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contract_parties"
            referencedColumns: ["id"]
          },
        ]
      }
      executed_contract_clauses: {
        Row: {
          body_en: string | null
          body_fa: string | null
          clause_key: string | null
          clause_type: Database["contract"]["Enums"]["preparation_clause_type"]
          contract_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          is_required: boolean
          metadata: Json
          organization_id: string
          preparation_clause_id: string | null
          sort_order: number
          source: string | null
          tenant_id: string
          title_en: string | null
          title_fa: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          body_en?: string | null
          body_fa?: string | null
          clause_key?: string | null
          clause_type: Database["contract"]["Enums"]["preparation_clause_type"]
          contract_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          is_required?: boolean
          metadata?: Json
          organization_id: string
          preparation_clause_id?: string | null
          sort_order?: number
          source?: string | null
          tenant_id: string
          title_en?: string | null
          title_fa?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          body_en?: string | null
          body_fa?: string | null
          clause_key?: string | null
          clause_type?: Database["contract"]["Enums"]["preparation_clause_type"]
          contract_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          is_required?: boolean
          metadata?: Json
          organization_id?: string
          preparation_clause_id?: string | null
          sort_order?: number
          source?: string | null
          tenant_id?: string
          title_en?: string | null
          title_fa?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "executed_contract_clauses_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "executed_contract_clauses_preparation_clause_id_fkey"
            columns: ["preparation_clause_id"]
            isOneToOne: false
            referencedRelation: "contract_preparation_clauses"
            referencedColumns: ["id"]
          },
        ]
      }
      executed_contract_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          contract_id: string
          created_at: string
          from_status: Database["contract"]["Enums"]["contract_status"] | null
          id: string
          organization_id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["contract"]["Enums"]["contract_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          contract_id: string
          created_at?: string
          from_status?: Database["contract"]["Enums"]["contract_status"] | null
          id?: string
          organization_id: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["contract"]["Enums"]["contract_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          contract_id?: string
          created_at?: string
          from_status?: Database["contract"]["Enums"]["contract_status"] | null
          id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["contract"]["Enums"]["contract_status"]
        }
        Relationships: [
          {
            foreignKeyName: "executed_contract_events_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      executed_contract_items: {
        Row: {
          contract_id: string
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          delivery_lead_time_text: string | null
          delivery_window_end: string | null
          delivery_window_start: string | null
          id: string
          metadata: Json
          notes: string | null
          offer_item_id: string | null
          organization_id: string
          origin_city: string | null
          origin_country: string | null
          packaging: string | null
          preparation_item_id: string | null
          product_id: string
          quantity: number | null
          quantity_unit: string | null
          request_item_id: string | null
          sort_order: number
          tenant_id: string
          total_price: number | null
          unit_price: number | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          contract_id: string
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_item_id?: string | null
          organization_id: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          preparation_item_id?: string | null
          product_id: string
          quantity?: number | null
          quantity_unit?: string | null
          request_item_id?: string | null
          sort_order?: number
          tenant_id: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          contract_id?: string
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_item_id?: string | null
          organization_id?: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          preparation_item_id?: string | null
          product_id?: string
          quantity?: number | null
          quantity_unit?: string | null
          request_item_id?: string | null
          sort_order?: number
          tenant_id?: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "executed_contract_items_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "executed_contract_items_preparation_item_id_fkey"
            columns: ["preparation_item_id"]
            isOneToOne: false
            referencedRelation: "contract_preparation_items"
            referencedColumns: ["id"]
          },
        ]
      }
      executed_contract_snapshots: {
        Row: {
          contract_id: string
          created_at: string
          created_by: string | null
          id: string
          notes: string | null
          organization_id: string
          snapshot_data: Json
          snapshot_type: Database["contract"]["Enums"]["executed_snapshot_type"]
          tenant_id: string
          title: string
        }
        Insert: {
          contract_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id: string
          snapshot_data?: Json
          snapshot_type: Database["contract"]["Enums"]["executed_snapshot_type"]
          tenant_id: string
          title: string
        }
        Update: {
          contract_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id?: string
          snapshot_data?: Json
          snapshot_type?: Database["contract"]["Enums"]["executed_snapshot_type"]
          tenant_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "executed_contract_snapshots_contract_id_fkey"
            columns: ["contract_id"]
            isOneToOne: false
            referencedRelation: "executed_contracts"
            referencedColumns: ["id"]
          },
        ]
      }
      executed_contracts: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          contract_code: string
          contract_type: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at: string
          created_by: string | null
          currency: string
          decision_id: string
          deleted_at: string | null
          delivery_city: string | null
          delivery_country: string | null
          delivery_location_text: string | null
          delivery_port: string | null
          delivery_terms_text: string | null
          dispute_resolution_text: string | null
          effective_date: string | null
          executed_at: string | null
          executed_by: string | null
          expiry_date: string | null
          governing_law_text: string | null
          id: string
          incoterm: string | null
          inspection_terms_text: string | null
          internal_notes: string | null
          metadata: Json
          offer_id: string
          organization_id: string
          payment_terms_text: string | null
          pending_signatures_at: string | null
          pending_signatures_by: string | null
          preparation_id: string
          request_id: string
          special_conditions_text: string | null
          status: Database["contract"]["Enums"]["contract_status"]
          superseded_at: string | null
          superseded_by: string | null
          superseded_reason: string | null
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          version: number
          voided_at: string | null
          voided_by: string | null
          voided_reason: string | null
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          contract_code: string
          contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at?: string
          created_by?: string | null
          currency?: string
          decision_id: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          delivery_terms_text?: string | null
          dispute_resolution_text?: string | null
          effective_date?: string | null
          executed_at?: string | null
          executed_by?: string | null
          expiry_date?: string | null
          governing_law_text?: string | null
          id?: string
          incoterm?: string | null
          inspection_terms_text?: string | null
          internal_notes?: string | null
          metadata?: Json
          offer_id: string
          organization_id: string
          payment_terms_text?: string | null
          pending_signatures_at?: string | null
          pending_signatures_by?: string | null
          preparation_id: string
          request_id: string
          special_conditions_text?: string | null
          status?: Database["contract"]["Enums"]["contract_status"]
          superseded_at?: string | null
          superseded_by?: string | null
          superseded_reason?: string | null
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          contract_code?: string
          contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          created_at?: string
          created_by?: string | null
          currency?: string
          decision_id?: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          delivery_terms_text?: string | null
          dispute_resolution_text?: string | null
          effective_date?: string | null
          executed_at?: string | null
          executed_by?: string | null
          expiry_date?: string | null
          governing_law_text?: string | null
          id?: string
          incoterm?: string | null
          inspection_terms_text?: string | null
          internal_notes?: string | null
          metadata?: Json
          offer_id?: string
          organization_id?: string
          payment_terms_text?: string | null
          pending_signatures_at?: string | null
          pending_signatures_by?: string | null
          preparation_id?: string
          request_id?: string
          special_conditions_text?: string | null
          status?: Database["contract"]["Enums"]["contract_status"]
          superseded_at?: string | null
          superseded_by?: string | null
          superseded_reason?: string | null
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "executed_contracts_preparation_id_fkey"
            columns: ["preparation_id"]
            isOneToOne: false
            referencedRelation: "contract_preparations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_force_cancel_contract: {
        Args: { p_contract_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_force_cancel_preparation: {
        Args: { p_preparation_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_get_executed_contract: {
        Args: { p_contract_id: string }
        Returns: Json
      }
      admin_get_preparation: {
        Args: { p_preparation_id: string }
        Returns: Json
      }
      admin_list_executed_contract_events: {
        Args: { p_contract_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_executed_contracts: {
        Args: {
          p_limit?: number
          p_offer_id?: string
          p_offset?: number
          p_request_id?: string
          p_status?: Database["contract"]["Enums"]["contract_status"]
          p_supplier_id?: string
        }
        Returns: {
          contract_code: string
          created_at: string
          id: string
          offer_id: string
          organization_id: string
          request_id: string
          status: string
          supplier_id: string
          title: string
          updated_at: string
        }[]
      }
      admin_list_preparation_events: {
        Args: { p_preparation_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_preparations: {
        Args: {
          p_limit?: number
          p_offer_id?: string
          p_offset?: number
          p_request_id?: string
          p_status?: Database["contract"]["Enums"]["preparation_status"]
          p_supplier_id?: string
        }
        Returns: {
          created_at: string
          decision_id: string
          id: string
          offer_id: string
          organization_id: string
          preparation_code: string
          request_id: string
          status: string
          supplier_id: string
          title: string
          updated_at: string
        }[]
      }
      admin_list_signature_events: {
        Args: { p_contract_id?: string; p_signature_request_id?: string }
        Returns: {
          actor_user_id: string
          contract_id: string
          created_at: string
          event_type: string
          from_status: string
          id: string
          reason: string
          signature_request_id: string
          to_status: string
        }[]
      }
      admin_supersede_contract: {
        Args: { p_contract_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_supersede_preparation: {
        Args: { p_preparation_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_void_contract: {
        Args: { p_contract_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_add_party: {
        Args: {
          p_contract_id: string
          p_display_name: string
          p_is_required_signer?: boolean
          p_party_organization_id?: string
          p_party_supplier_id?: string
          p_party_type: Database["contract"]["Enums"]["party_type"]
          p_party_user_id?: string
          p_role_title?: string
          p_signer_role?: string
          p_signing_order?: number
        }
        Returns: string
      }
      buyer_cancel_executed_contract: {
        Args: { p_contract_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_cancel_preparation: {
        Args: { p_preparation_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_create_executed_contract: {
        Args: {
          p_effective_date?: string
          p_expiry_date?: string
          p_preparation_id: string
          p_title?: string
        }
        Returns: string
      }
      buyer_create_executed_snapshot: {
        Args: {
          p_contract_id: string
          p_notes?: string
          p_snapshot_data?: Json
          p_snapshot_type: Database["contract"]["Enums"]["executed_snapshot_type"]
          p_title: string
        }
        Returns: string
      }
      buyer_create_preparation: {
        Args: {
          p_contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          p_currency?: string
          p_decision_id: string
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_delivery_terms_text?: string
          p_dispute_resolution_text?: string
          p_governing_law_text?: string
          p_incoterm?: string
          p_inspection_terms_text?: string
          p_internal_notes?: string
          p_payment_terms_text?: string
          p_special_conditions_text?: string
          p_title: string
        }
        Returns: string
      }
      buyer_create_signature_request: {
        Args: {
          p_contract_id: string
          p_due_at?: string
          p_party_id: string
          p_requested_to_email?: string
          p_requested_to_user?: string
        }
        Returns: string
      }
      buyer_create_snapshot: {
        Args: {
          p_notes?: string
          p_preparation_id: string
          p_snapshot_data?: Json
          p_snapshot_type: Database["contract"]["Enums"]["preparation_snapshot_type"]
          p_title: string
        }
        Returns: string
      }
      buyer_decline_signature_request: {
        Args: { p_reason?: string; p_signature_request_id: string }
        Returns: undefined
      }
      buyer_get_executed_contract: {
        Args: { p_contract_id: string }
        Returns: Json
      }
      buyer_get_preparation: {
        Args: { p_preparation_id: string }
        Returns: Json
      }
      buyer_list_executed_contracts: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["contract"]["Enums"]["contract_status"]
        }
        Returns: {
          contract_code: string
          created_at: string
          id: string
          offer_id: string
          preparation_id: string
          request_id: string
          status: string
          supplier_id: string
          title: string
          updated_at: string
        }[]
      }
      buyer_list_preparation_events: {
        Args: { p_preparation_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      buyer_list_preparations: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["contract"]["Enums"]["preparation_status"]
        }
        Returns: {
          created_at: string
          decision_id: string
          id: string
          offer_id: string
          preparation_code: string
          request_id: string
          status: string
          supplier_id: string
          title: string
          updated_at: string
        }[]
      }
      buyer_mark_pending_signatures: {
        Args: { p_contract_id: string }
        Returns: undefined
      }
      buyer_mark_ready_for_contract: {
        Args: { p_preparation_id: string }
        Returns: undefined
      }
      buyer_move_to_under_review: {
        Args: { p_preparation_id: string }
        Returns: undefined
      }
      buyer_remove_clause: { Args: { p_clause_id: string }; Returns: undefined }
      buyer_sign_signature_request: {
        Args: { p_metadata?: Json; p_signature_request_id: string }
        Returns: undefined
      }
      buyer_update_executed_contract: {
        Args: {
          p_contract_id: string
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_delivery_terms_text?: string
          p_dispute_resolution_text?: string
          p_effective_date?: string
          p_expiry_date?: string
          p_governing_law_text?: string
          p_incoterm?: string
          p_inspection_terms_text?: string
          p_internal_notes?: string
          p_payment_terms_text?: string
          p_special_conditions_text?: string
          p_title?: string
        }
        Returns: undefined
      }
      buyer_update_preparation: {
        Args: {
          p_contract_type?: Database["contract"]["Enums"]["preparation_contract_type"]
          p_currency?: string
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_delivery_terms_text?: string
          p_dispute_resolution_text?: string
          p_governing_law_text?: string
          p_incoterm?: string
          p_inspection_terms_text?: string
          p_internal_notes?: string
          p_payment_terms_text?: string
          p_preparation_id: string
          p_special_conditions_text?: string
          p_title?: string
        }
        Returns: undefined
      }
      buyer_upsert_clause: {
        Args: {
          p_body_en?: string
          p_body_fa?: string
          p_clause_key?: string
          p_clause_type: Database["contract"]["Enums"]["preparation_clause_type"]
          p_is_required?: boolean
          p_preparation_id: string
          p_sort_order?: number
          p_source?: string
          p_title_en?: string
          p_title_fa?: string
        }
        Returns: string
      }
      fn_assert_buyer_for_decision: {
        Args: { p_decision_id: string }
        Returns: {
          buyer_org_id: string
          decision_status: Database["evaluation"]["Enums"]["decision_status"]
          offer_id: string
          request_id: string
          supplier_id: string
          supplier_organization_id: string
        }[]
      }
      fn_assert_buyer_for_preparation: {
        Args: { p_preparation_id: string }
        Returns: {
          buyer_org_id: string
          decision_id: string
          offer_id: string
          prep_status: Database["contract"]["Enums"]["preparation_status"]
          request_id: string
          supplier_id: string
          supplier_organization_id: string
        }[]
      }
      fn_assert_buyer_for_signature: {
        Args: { p_signature_request_id: string }
        Returns: {
          contract_id: string
          party_id: string
          party_type: Database["contract"]["Enums"]["party_type"]
          signature_request_id: string
          status: Database["contract"]["Enums"]["signature_status"]
        }[]
      }
      fn_assert_executed_contract_editable: {
        Args: { p_contract_id: string }
        Returns: undefined
      }
      fn_assert_executed_contract_owned: {
        Args: { p_contract_id: string }
        Returns: undefined
      }
      fn_assert_preparation_editable: {
        Args: { p_preparation_id: string }
        Returns: undefined
      }
      fn_assert_preparation_owned: {
        Args: { p_preparation_id: string }
        Returns: undefined
      }
      fn_assert_supplier_for_signature: {
        Args: { p_signature_request_id: string }
        Returns: {
          contract_id: string
          party_id: string
          party_type: Database["contract"]["Enums"]["party_type"]
          signature_request_id: string
          status: Database["contract"]["Enums"]["signature_status"]
        }[]
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_preparation_id: string
        }
        Returns: undefined
      }
      fn_audit_contract: {
        Args: { p_action_code: string; p_contract_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_next_contract_code: { Args: { p_tenant_id: string }; Returns: string }
      fn_next_preparation_code: {
        Args: { p_tenant_id: string }
        Returns: string
      }
      fn_record_executed_contract_event: {
        Args: {
          p_contract_id: string
          p_from: Database["contract"]["Enums"]["contract_status"]
          p_payload?: Json
          p_reason?: string
          p_to: Database["contract"]["Enums"]["contract_status"]
        }
        Returns: undefined
      }
      fn_record_preparation_event: {
        Args: {
          p_from: Database["contract"]["Enums"]["preparation_status"]
          p_payload?: Json
          p_preparation_id: string
          p_reason?: string
          p_to: Database["contract"]["Enums"]["preparation_status"]
        }
        Returns: undefined
      }
      fn_record_signature_event: {
        Args: {
          p_event_type: string
          p_from: Database["contract"]["Enums"]["signature_status"]
          p_metadata?: Json
          p_reason?: string
          p_signature_request_id: string
          p_to: Database["contract"]["Enums"]["signature_status"]
        }
        Returns: undefined
      }
      fn_try_promote_to_executed: {
        Args: { p_contract_id: string }
        Returns: undefined
      }
      supplier_decline_signature_request: {
        Args: { p_reason?: string; p_signature_request_id: string }
        Returns: undefined
      }
      supplier_get_my_executed_contract: {
        Args: { p_contract_id: string }
        Returns: Json
      }
      supplier_get_my_preparation: {
        Args: { p_preparation_id: string }
        Returns: Json
      }
      supplier_list_my_executed_contracts: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["contract"]["Enums"]["contract_status"]
        }
        Returns: {
          contract_code: string
          created_at: string
          id: string
          offer_id: string
          request_id: string
          status: string
          title: string
          updated_at: string
        }[]
      }
      supplier_list_my_preparations: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["contract"]["Enums"]["preparation_status"]
        }
        Returns: {
          created_at: string
          id: string
          offer_id: string
          preparation_code: string
          request_id: string
          status: string
          title: string
          updated_at: string
        }[]
      }
      supplier_list_my_signature_requests: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["contract"]["Enums"]["signature_status"]
        }
        Returns: {
          contract_id: string
          due_at: string
          id: string
          party_id: string
          requested_at: string
          status: string
        }[]
      }
      supplier_sign_signature_request: {
        Args: { p_metadata?: Json; p_signature_request_id: string }
        Returns: undefined
      }
      supplier_view_signature_request: {
        Args: { p_signature_request_id: string }
        Returns: undefined
      }
    }
    Enums: {
      contract_status:
        | "draft_execution"
        | "pending_signatures"
        | "partially_signed"
        | "executed"
        | "cancelled"
        | "voided"
        | "superseded"
      executed_snapshot_type:
        | "initial_from_preparation"
        | "pending_signature_snapshot"
        | "executed_snapshot"
        | "voided_snapshot"
      party_type: "buyer" | "supplier" | "platform" | "witness" | "other"
      preparation_clause_type:
        | "payment"
        | "delivery"
        | "inspection"
        | "quality"
        | "documents"
        | "force_majeure"
        | "dispute_resolution"
        | "governing_law"
        | "special_conditions"
        | "other"
      preparation_contract_type: "spot" | "framework" | "term" | "other"
      preparation_snapshot_type:
        | "initial_from_offer"
        | "review_snapshot"
        | "ready_for_contract_snapshot"
      preparation_status:
        | "draft"
        | "under_review"
        | "ready_for_contract"
        | "cancelled"
        | "superseded"
      signature_status:
        | "pending"
        | "viewed"
        | "signed"
        | "declined"
        | "cancelled"
        | "expired"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  dispatch: {
    Tables: {
      dispatch_assignments: {
        Row: {
          assigned_at: string | null
          assigned_by: string | null
          booking_request_id: string
          buyer_organization_id: string
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          carrier_organization_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          driver_name: string | null
          driver_phone: string | null
          id: string
          notes_en: string | null
          notes_fa: string | null
          planned_pickup_at: string | null
          ready_at: string | null
          ready_by: string | null
          released_at: string | null
          released_by: string | null
          status: Database["dispatch"]["Enums"]["dispatch_status"]
          tenant_id: string
          updated_at: string
          vehicle_reference: string | null
          vehicle_type: string | null
          version: number
        }
        Insert: {
          assigned_at?: string | null
          assigned_by?: string | null
          booking_request_id: string
          buyer_organization_id: string
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          carrier_organization_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          driver_name?: string | null
          driver_phone?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          planned_pickup_at?: string | null
          ready_at?: string | null
          ready_by?: string | null
          released_at?: string | null
          released_by?: string | null
          status?: Database["dispatch"]["Enums"]["dispatch_status"]
          tenant_id: string
          updated_at?: string
          vehicle_reference?: string | null
          vehicle_type?: string | null
          version?: number
        }
        Update: {
          assigned_at?: string | null
          assigned_by?: string | null
          booking_request_id?: string
          buyer_organization_id?: string
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          carrier_organization_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          driver_name?: string | null
          driver_phone?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          planned_pickup_at?: string | null
          ready_at?: string | null
          ready_by?: string | null
          released_at?: string | null
          released_by?: string | null
          status?: Database["dispatch"]["Enums"]["dispatch_status"]
          tenant_id?: string
          updated_at?: string
          vehicle_reference?: string | null
          vehicle_type?: string | null
          version?: number
        }
        Relationships: []
      }
      dispatch_events: {
        Row: {
          actor_organization_id: string | null
          actor_party: string
          actor_user_id: string | null
          created_at: string
          dispatch_id: string
          event_type: string
          from_status: Database["dispatch"]["Enums"]["dispatch_status"] | null
          id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_party: string
          actor_user_id?: string | null
          created_at?: string
          dispatch_id: string
          event_type: string
          from_status?: Database["dispatch"]["Enums"]["dispatch_status"] | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_party?: string
          actor_user_id?: string | null
          created_at?: string
          dispatch_id?: string
          event_type?: string
          from_status?: Database["dispatch"]["Enums"]["dispatch_status"] | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Relationships: [
          {
            foreignKeyName: "dispatch_events_dispatch_id_fkey"
            columns: ["dispatch_id"]
            isOneToOne: false
            referencedRelation: "dispatch_assignments"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_cancel_dispatch: {
        Args: { p_dispatch_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_get_dispatch: { Args: { p_dispatch_id: string }; Returns: Json }
      admin_list_dispatches: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Returns: {
          booking_request_id: string
          buyer_organization_id: string
          carrier_organization_id: string
          created_at: string
          driver_name: string
          id: string
          planned_pickup_at: string
          status: Database["dispatch"]["Enums"]["dispatch_status"]
          updated_at: string
          vehicle_reference: string
        }[]
      }
      buyer_cancel_dispatch: {
        Args: { p_dispatch_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_get_dispatch: { Args: { p_dispatch_id: string }; Returns: Json }
      buyer_list_my_dispatches: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Returns: {
          booking_request_id: string
          buyer_organization_id: string
          carrier_organization_id: string
          created_at: string
          id: string
          planned_pickup_at: string
          status: Database["dispatch"]["Enums"]["dispatch_status"]
          updated_at: string
        }[]
      }
      carrier_cancel_dispatch: {
        Args: { p_dispatch_id: string; p_reason?: string }
        Returns: undefined
      }
      carrier_create_dispatch: {
        Args: {
          p_booking_request_id: string
          p_driver_name?: string
          p_driver_phone?: string
          p_notes_en?: string
          p_notes_fa?: string
          p_planned_pickup_at?: string
          p_vehicle_reference?: string
          p_vehicle_type?: string
        }
        Returns: string
      }
      carrier_get_dispatch: { Args: { p_dispatch_id: string }; Returns: Json }
      carrier_list_my_dispatches: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Returns: {
          booking_request_id: string
          buyer_organization_id: string
          carrier_organization_id: string
          created_at: string
          driver_name: string
          id: string
          planned_pickup_at: string
          status: Database["dispatch"]["Enums"]["dispatch_status"]
          updated_at: string
          vehicle_reference: string
        }[]
      }
      carrier_mark_ready: {
        Args: { p_dispatch_id: string }
        Returns: undefined
      }
      carrier_release_dispatch: {
        Args: { p_dispatch_id: string; p_notes?: string }
        Returns: undefined
      }
      carrier_update_dispatch_placeholders: {
        Args: {
          p_dispatch_id: string
          p_driver_name?: string
          p_driver_phone?: string
          p_notes_en?: string
          p_notes_fa?: string
          p_planned_pickup_at?: string
          p_vehicle_reference?: string
          p_vehicle_type?: string
        }
        Returns: undefined
      }
      fn_assert_buyer_for_dispatch: {
        Args: { p_dispatch_id: string }
        Returns: Database["dispatch"]["Enums"]["dispatch_status"]
      }
      fn_assert_can_view_dispatch: {
        Args: { p_dispatch_id: string }
        Returns: undefined
      }
      fn_assert_carrier_for_booking: {
        Args: { p_booking_id: string }
        Returns: undefined
      }
      fn_assert_carrier_for_dispatch: {
        Args: { p_dispatch_id: string }
        Returns: Database["dispatch"]["Enums"]["dispatch_status"]
      }
      fn_audit: {
        Args: { p_action_code: string; p_dispatch_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_record_dispatch_event: {
        Args: {
          p_actor_party: string
          p_dispatch_id: string
          p_event_type: string
          p_from: Database["dispatch"]["Enums"]["dispatch_status"]
          p_payload?: Json
          p_reason?: string
          p_to: Database["dispatch"]["Enums"]["dispatch_status"]
        }
        Returns: string
      }
    }
    Enums: {
      dispatch_status: "draft" | "assigned" | "ready" | "released" | "cancelled"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  dispute: {
    Tables: {
      dispute_decisions: {
        Row: {
          buyer_share_amount: number
          created_at: string
          decided_by: string | null
          dispute_id: string
          fee_share_amount: number
          id: string
          mediator_notes: string | null
          metadata: Json
          organization_id: string
          outcome: Database["dispute"]["Enums"]["decision_outcome"]
          reason: string | null
          settlement_action: Database["dispute"]["Enums"]["settlement_action"]
          supplier_share_amount: number
          tenant_id: string
          voided_at: string | null
          voided_by: string | null
          voided_reason: string | null
        }
        Insert: {
          buyer_share_amount?: number
          created_at?: string
          decided_by?: string | null
          dispute_id: string
          fee_share_amount?: number
          id?: string
          mediator_notes?: string | null
          metadata?: Json
          organization_id: string
          outcome: Database["dispute"]["Enums"]["decision_outcome"]
          reason?: string | null
          settlement_action: Database["dispute"]["Enums"]["settlement_action"]
          supplier_share_amount?: number
          tenant_id: string
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Update: {
          buyer_share_amount?: number
          created_at?: string
          decided_by?: string | null
          dispute_id?: string
          fee_share_amount?: number
          id?: string
          mediator_notes?: string | null
          metadata?: Json
          organization_id?: string
          outcome?: Database["dispute"]["Enums"]["decision_outcome"]
          reason?: string | null
          settlement_action?: Database["dispute"]["Enums"]["settlement_action"]
          supplier_share_amount?: number
          tenant_id?: string
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dispute_decisions_dispute_id_fkey"
            columns: ["dispute_id"]
            isOneToOne: false
            referencedRelation: "disputes"
            referencedColumns: ["id"]
          },
        ]
      }
      dispute_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          dispute_id: string
          event_type: string
          from_status:
            | Database["dispute"]["Enums"]["dispute_case_status"]
            | null
          id: string
          organization_id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["dispute"]["Enums"]["dispute_case_status"] | null
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          dispute_id: string
          event_type: string
          from_status?:
            | Database["dispute"]["Enums"]["dispute_case_status"]
            | null
          id?: string
          organization_id: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status?: Database["dispute"]["Enums"]["dispute_case_status"] | null
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          dispute_id?: string
          event_type?: string
          from_status?:
            | Database["dispute"]["Enums"]["dispute_case_status"]
            | null
          id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["dispute"]["Enums"]["dispute_case_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "dispute_events_dispute_id_fkey"
            columns: ["dispute_id"]
            isOneToOne: false
            referencedRelation: "disputes"
            referencedColumns: ["id"]
          },
        ]
      }
      dispute_evidence: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          dispute_id: string
          evidence_kind: Database["dispute"]["Enums"]["evidence_kind"]
          id: string
          metadata: Json
          narrative: string | null
          organization_id: string
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          sort_order: number
          status: Database["dispute"]["Enums"]["evidence_status"]
          submitter_organization_id: string | null
          submitter_party_role: Database["dispute"]["Enums"]["party_role"]
          submitter_supplier_id: string | null
          submitter_user_id: string | null
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          dispute_id: string
          evidence_kind?: Database["dispute"]["Enums"]["evidence_kind"]
          id?: string
          metadata?: Json
          narrative?: string | null
          organization_id: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sort_order?: number
          status?: Database["dispute"]["Enums"]["evidence_status"]
          submitter_organization_id?: string | null
          submitter_party_role: Database["dispute"]["Enums"]["party_role"]
          submitter_supplier_id?: string | null
          submitter_user_id?: string | null
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          dispute_id?: string
          evidence_kind?: Database["dispute"]["Enums"]["evidence_kind"]
          id?: string
          metadata?: Json
          narrative?: string | null
          organization_id?: string
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sort_order?: number
          status?: Database["dispute"]["Enums"]["evidence_status"]
          submitter_organization_id?: string | null
          submitter_party_role?: Database["dispute"]["Enums"]["party_role"]
          submitter_supplier_id?: string | null
          submitter_user_id?: string | null
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "dispute_evidence_dispute_id_fkey"
            columns: ["dispute_id"]
            isOneToOne: false
            referencedRelation: "disputes"
            referencedColumns: ["id"]
          },
        ]
      }
      dispute_participants: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          display_name: string
          dispute_id: string
          id: string
          metadata: Json
          notes: string | null
          organization_id: string
          party_organization_id: string | null
          party_role: Database["dispute"]["Enums"]["party_role"]
          party_supplier_id: string | null
          party_user_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name: string
          dispute_id: string
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id: string
          party_organization_id?: string | null
          party_role: Database["dispute"]["Enums"]["party_role"]
          party_supplier_id?: string | null
          party_user_id?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name?: string
          dispute_id?: string
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id?: string
          party_organization_id?: string | null
          party_role?: Database["dispute"]["Enums"]["party_role"]
          party_supplier_id?: string | null
          party_user_id?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "dispute_participants_dispute_id_fkey"
            columns: ["dispute_id"]
            isOneToOne: false
            referencedRelation: "disputes"
            referencedColumns: ["id"]
          },
        ]
      }
      disputes: {
        Row: {
          amount_in_dispute: number | null
          assigned_at: string | null
          assigned_mediator_id: string | null
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          description: string | null
          dispute_code: string
          executed_contract_id: string | null
          id: string
          metadata: Json
          opened_at: string
          opened_by_party: string
          opened_by_user_id: string | null
          organization_id: string
          resolved_at: string | null
          resolved_by: string | null
          review_started_at: string | null
          review_started_by: string | null
          settlement_id: string
          shipment_id: string | null
          status: Database["dispute"]["Enums"]["dispute_case_status"]
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          version: number
          withdrawn_at: string | null
          withdrawn_by: string | null
          withdrawn_reason: string | null
        }
        Insert: {
          amount_in_dispute?: number | null
          assigned_at?: string | null
          assigned_mediator_id?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          description?: string | null
          dispute_code: string
          executed_contract_id?: string | null
          id?: string
          metadata?: Json
          opened_at?: string
          opened_by_party: string
          opened_by_user_id?: string | null
          organization_id: string
          resolved_at?: string | null
          resolved_by?: string | null
          review_started_at?: string | null
          review_started_by?: string | null
          settlement_id: string
          shipment_id?: string | null
          status?: Database["dispute"]["Enums"]["dispute_case_status"]
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          withdrawn_at?: string | null
          withdrawn_by?: string | null
          withdrawn_reason?: string | null
        }
        Update: {
          amount_in_dispute?: number | null
          assigned_at?: string | null
          assigned_mediator_id?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          description?: string | null
          dispute_code?: string
          executed_contract_id?: string | null
          id?: string
          metadata?: Json
          opened_at?: string
          opened_by_party?: string
          opened_by_user_id?: string | null
          organization_id?: string
          resolved_at?: string | null
          resolved_by?: string | null
          review_started_at?: string | null
          review_started_by?: string | null
          settlement_id?: string
          shipment_id?: string | null
          status?: Database["dispute"]["Enums"]["dispute_case_status"]
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          withdrawn_at?: string | null
          withdrawn_by?: string | null
          withdrawn_reason?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_add_participant: {
        Args: {
          p_display_name: string
          p_dispute_id: string
          p_notes?: string
          p_organization_id?: string
          p_party_role: Database["dispute"]["Enums"]["party_role"]
          p_supplier_id?: string
          p_user_id?: string
        }
        Returns: string
      }
      admin_assign_mediator: {
        Args: { p_dispute_id: string; p_mediator_user_id: string }
        Returns: undefined
      }
      admin_cancel_dispute: {
        Args: { p_dispute_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_force_dispute_status: {
        Args: {
          p_dispute_id: string
          p_reason?: string
          p_status: Database["dispute"]["Enums"]["dispute_case_status"]
        }
        Returns: undefined
      }
      admin_get_dispute: { Args: { p_dispute_id: string }; Returns: Json }
      admin_list_decisions: {
        Args: { p_dispute_id: string }
        Returns: {
          buyer_share_amount: number
          created_at: string
          id: string
          outcome: string
          settlement_action: string
          supplier_share_amount: number
          voided_at: string
        }[]
      }
      admin_list_dispute_events: {
        Args: { p_dispute_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          event_type: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_dispute_evidence: {
        Args: {
          p_dispute_id: string
          p_status?: Database["dispute"]["Enums"]["evidence_status"]
        }
        Returns: {
          created_at: string
          evidence_kind: string
          id: string
          status: string
          submitter_party_role: string
          title: string
        }[]
      }
      admin_list_disputes: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["dispute"]["Enums"]["dispute_case_status"]
          p_supplier_id?: string
        }
        Returns: {
          amount_in_dispute: number
          created_at: string
          currency: string
          dispute_code: string
          id: string
          opened_by_party: string
          organization_id: string
          settlement_id: string
          status: string
          supplier_id: string
          title: string
        }[]
      }
      admin_record_decision: {
        Args: {
          p_buyer_share_amount?: number
          p_dispute_id: string
          p_fee_share_amount?: number
          p_mediator_notes?: string
          p_outcome: Database["dispute"]["Enums"]["decision_outcome"]
          p_reason?: string
          p_settlement_action: Database["dispute"]["Enums"]["settlement_action"]
          p_supplier_share_amount?: number
        }
        Returns: string
      }
      admin_review_evidence: {
        Args: {
          p_evidence_id: string
          p_notes?: string
          p_status: Database["dispute"]["Enums"]["evidence_status"]
        }
        Returns: undefined
      }
      admin_start_review: { Args: { p_dispute_id: string }; Returns: undefined }
      admin_void_decision: {
        Args: { p_decision_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_get_dispute: { Args: { p_dispute_id: string }; Returns: Json }
      buyer_list_disputes: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_settlement_id?: string
          p_status?: Database["dispute"]["Enums"]["dispute_case_status"]
        }
        Returns: {
          amount_in_dispute: number
          created_at: string
          currency: string
          dispute_code: string
          id: string
          opened_by_party: string
          settlement_id: string
          status: string
          supplier_id: string
          title: string
          updated_at: string
        }[]
      }
      buyer_open_dispute: {
        Args: {
          p_amount_in_dispute?: number
          p_description?: string
          p_settlement_id: string
          p_title: string
        }
        Returns: string
      }
      buyer_submit_evidence: {
        Args: {
          p_dispute_id: string
          p_evidence_kind: Database["dispute"]["Enums"]["evidence_kind"]
          p_metadata?: Json
          p_narrative?: string
          p_title: string
        }
        Returns: string
      }
      buyer_withdraw_dispute: {
        Args: { p_dispute_id: string; p_reason?: string }
        Returns: undefined
      }
      fn_apply_decision_to_settlement: {
        Args: { p_dispute_id: string }
        Returns: undefined
      }
      fn_assert_buyer_for_dispute: {
        Args: { p_dispute_id: string }
        Returns: Database["dispute"]["Enums"]["dispute_case_status"]
      }
      fn_assert_dispute_open_for_submission: {
        Args: { p_dispute_id: string }
        Returns: undefined
      }
      fn_assert_supplier_for_dispute: {
        Args: { p_dispute_id: string }
        Returns: Database["dispute"]["Enums"]["dispute_case_status"]
      }
      fn_audit: {
        Args: { p_action_code: string; p_dispute_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_next_dispute_code: { Args: { p_tenant_id: string }; Returns: string }
      fn_record_dispute_event: {
        Args: {
          p_dispute_id: string
          p_event_type: string
          p_from: Database["dispute"]["Enums"]["dispute_case_status"]
          p_payload?: Json
          p_reason?: string
          p_to: Database["dispute"]["Enums"]["dispute_case_status"]
        }
        Returns: undefined
      }
      supplier_get_my_dispute: { Args: { p_dispute_id: string }; Returns: Json }
      supplier_list_my_disputes: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["dispute"]["Enums"]["dispute_case_status"]
        }
        Returns: {
          amount_in_dispute: number
          created_at: string
          currency: string
          dispute_code: string
          id: string
          opened_by_party: string
          settlement_id: string
          status: string
          title: string
          updated_at: string
        }[]
      }
      supplier_submit_evidence: {
        Args: {
          p_dispute_id: string
          p_evidence_kind: Database["dispute"]["Enums"]["evidence_kind"]
          p_metadata?: Json
          p_narrative?: string
          p_title: string
        }
        Returns: string
      }
      supplier_withdraw_dispute: {
        Args: { p_dispute_id: string; p_reason?: string }
        Returns: undefined
      }
    }
    Enums: {
      decision_outcome:
        | "favor_buyer"
        | "favor_supplier"
        | "split"
        | "no_action"
        | "withdrawn"
      dispute_case_status:
        | "opened"
        | "under_review"
        | "resolved_buyer"
        | "resolved_supplier"
        | "resolved_split"
        | "withdrawn"
        | "cancelled"
      evidence_kind:
        | "narrative"
        | "document"
        | "financial"
        | "photo"
        | "communication_log"
        | "inspection_report"
        | "other"
      evidence_status: "submitted" | "accepted" | "rejected" | "withdrawn"
      party_role:
        | "buyer"
        | "supplier"
        | "platform_admin"
        | "mediator"
        | "observer"
      settlement_action:
        | "release_to_supplier"
        | "reverse_to_buyer"
        | "split"
        | "no_change"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  evaluation: {
    Tables: {
      offer_comparison_snapshots: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          notes: string | null
          organization_id: string
          request_id: string
          snapshot_data: Json
          tenant_id: string
          title: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id: string
          request_id: string
          snapshot_data?: Json
          tenant_id: string
          title: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          notes?: string | null
          organization_id?: string
          request_id?: string
          snapshot_data?: Json
          tenant_id?: string
          title?: string
        }
        Relationships: []
      }
      offer_decision_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          decision_id: string
          from_status: Database["evaluation"]["Enums"]["decision_status"] | null
          id: string
          offer_id: string
          organization_id: string
          payload: Json
          reason: string | null
          request_id: string
          tenant_id: string
          to_status: Database["evaluation"]["Enums"]["decision_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          decision_id: string
          from_status?:
            | Database["evaluation"]["Enums"]["decision_status"]
            | null
          id?: string
          offer_id: string
          organization_id: string
          payload?: Json
          reason?: string | null
          request_id: string
          tenant_id: string
          to_status: Database["evaluation"]["Enums"]["decision_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          decision_id?: string
          from_status?:
            | Database["evaluation"]["Enums"]["decision_status"]
            | null
          id?: string
          offer_id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          request_id?: string
          tenant_id?: string
          to_status?: Database["evaluation"]["Enums"]["decision_status"]
        }
        Relationships: [
          {
            foreignKeyName: "offer_decision_events_decision_id_fkey"
            columns: ["decision_id"]
            isOneToOne: false
            referencedRelation: "offer_decisions"
            referencedColumns: ["id"]
          },
        ]
      }
      offer_decisions: {
        Row: {
          created_at: string
          created_by: string | null
          decided_at: string
          decided_by: string | null
          decision_notes: string | null
          decision_status: Database["evaluation"]["Enums"]["decision_status"]
          deleted_at: string | null
          id: string
          metadata: Json
          offer_id: string
          organization_id: string
          reason: string | null
          request_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          decided_at?: string
          decided_by?: string | null
          decision_notes?: string | null
          decision_status: Database["evaluation"]["Enums"]["decision_status"]
          deleted_at?: string | null
          id?: string
          metadata?: Json
          offer_id: string
          organization_id: string
          reason?: string | null
          request_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          decided_at?: string
          decided_by?: string | null
          decision_notes?: string | null
          decision_status?: Database["evaluation"]["Enums"]["decision_status"]
          deleted_at?: string | null
          id?: string
          metadata?: Json
          offer_id?: string
          organization_id?: string
          reason?: string | null
          request_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      offer_evaluation_scores: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          dimension: string
          evaluation_id: string
          id: string
          max_score: number | null
          metadata: Json
          notes: string | null
          organization_id: string
          score_value: number | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
          weight: number | null
          weighted_score: number | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          dimension: string
          evaluation_id: string
          id?: string
          max_score?: number | null
          metadata?: Json
          notes?: string | null
          organization_id: string
          score_value?: number | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          weight?: number | null
          weighted_score?: number | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          dimension?: string
          evaluation_id?: string
          id?: string
          max_score?: number | null
          metadata?: Json
          notes?: string | null
          organization_id?: string
          score_value?: number | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          weight?: number | null
          weighted_score?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "offer_evaluation_scores_evaluation_id_fkey"
            columns: ["evaluation_id"]
            isOneToOne: false
            referencedRelation: "offer_evaluations"
            referencedColumns: ["id"]
          },
        ]
      }
      offer_evaluations: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          commercial_notes: string | null
          completed_at: string | null
          completed_by: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          evaluator_user_id: string
          id: string
          metadata: Json
          offer_id: string
          organization_id: string
          overall_notes: string | null
          request_id: string
          risk_notes: string | null
          status: Database["evaluation"]["Enums"]["evaluation_status"]
          technical_notes: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          commercial_notes?: string | null
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evaluator_user_id: string
          id?: string
          metadata?: Json
          offer_id: string
          organization_id: string
          overall_notes?: string | null
          request_id: string
          risk_notes?: string | null
          status?: Database["evaluation"]["Enums"]["evaluation_status"]
          technical_notes?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          commercial_notes?: string | null
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evaluator_user_id?: string
          id?: string
          metadata?: Json
          offer_id?: string
          organization_id?: string
          overall_notes?: string | null
          request_id?: string
          risk_notes?: string | null
          status?: Database["evaluation"]["Enums"]["evaluation_status"]
          technical_notes?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_get_decision: { Args: { p_decision_id: string }; Returns: Json }
      admin_get_evaluation: { Args: { p_evaluation_id: string }; Returns: Json }
      admin_list_decision_events: {
        Args: { p_decision_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_decisions: {
        Args: {
          p_limit?: number
          p_offer_id?: string
          p_offset?: number
          p_request_id?: string
          p_status?: Database["evaluation"]["Enums"]["decision_status"]
        }
        Returns: {
          decided_at: string
          decided_by: string
          decision_status: string
          id: string
          offer_id: string
          organization_id: string
          request_id: string
        }[]
      }
      admin_list_evaluations: {
        Args: {
          p_limit?: number
          p_offer_id?: string
          p_offset?: number
          p_request_id?: string
          p_status?: Database["evaluation"]["Enums"]["evaluation_status"]
        }
        Returns: {
          created_at: string
          evaluator_user_id: string
          id: string
          offer_id: string
          organization_id: string
          request_id: string
          status: string
          updated_at: string
        }[]
      }
      buyer_cancel_evaluation: {
        Args: { p_evaluation_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_complete_evaluation: {
        Args: { p_evaluation_id: string }
        Returns: undefined
      }
      buyer_create_comparison_snapshot: {
        Args: {
          p_notes?: string
          p_request_id: string
          p_snapshot_data?: Json
          p_title: string
        }
        Returns: string
      }
      buyer_create_evaluation: {
        Args: {
          p_commercial_notes?: string
          p_evaluator_user_id?: string
          p_offer_id: string
          p_overall_notes?: string
          p_risk_notes?: string
          p_technical_notes?: string
        }
        Returns: string
      }
      buyer_get_evaluation: { Args: { p_evaluation_id: string }; Returns: Json }
      buyer_list_evaluations: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["evaluation"]["Enums"]["evaluation_status"]
        }
        Returns: {
          created_at: string
          evaluator_user_id: string
          id: string
          offer_id: string
          request_id: string
          score_count: number
          status: string
          updated_at: string
        }[]
      }
      buyer_reject_offer: {
        Args: { p_notes?: string; p_offer_id: string; p_reason?: string }
        Returns: string
      }
      buyer_remove_score: { Args: { p_score_id: string }; Returns: undefined }
      buyer_select_for_contract: {
        Args: { p_notes?: string; p_offer_id: string; p_reason?: string }
        Returns: string
      }
      buyer_shortlist_offer: {
        Args: { p_notes?: string; p_offer_id: string; p_reason?: string }
        Returns: string
      }
      buyer_update_evaluation: {
        Args: {
          p_commercial_notes?: string
          p_evaluation_id: string
          p_overall_notes?: string
          p_risk_notes?: string
          p_technical_notes?: string
        }
        Returns: undefined
      }
      buyer_upsert_score: {
        Args: {
          p_dimension: string
          p_evaluation_id: string
          p_max_score?: number
          p_notes?: string
          p_score_value?: number
          p_weight?: number
          p_weighted_score?: number
        }
        Returns: string
      }
      fn_assert_buyer_for_offer: {
        Args: { p_offer_id: string }
        Returns: {
          buyer_org_id: string
          request_id: string
        }[]
      }
      fn_assert_buyer_for_request: {
        Args: { p_request_id: string }
        Returns: string
      }
      fn_assert_evaluation_editable: {
        Args: { p_evaluation_id: string }
        Returns: undefined
      }
      fn_assert_evaluation_owned: {
        Args: { p_evaluation_id: string }
        Returns: undefined
      }
      fn_assert_offer_actionable: {
        Args: { p_offer_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: { p_action_code: string; p_payload?: Json; p_resource_id: string }
        Returns: undefined
      }
      fn_record_decision: {
        Args: {
          p_notes?: string
          p_offer_id: string
          p_reason?: string
          p_status: Database["evaluation"]["Enums"]["decision_status"]
        }
        Returns: string
      }
      fn_record_decision_event: {
        Args: {
          p_decision_id: string
          p_from: Database["evaluation"]["Enums"]["decision_status"]
          p_offer_id: string
          p_payload?: Json
          p_reason?: string
          p_request_id: string
          p_to: Database["evaluation"]["Enums"]["decision_status"]
        }
        Returns: undefined
      }
      fn_sync_offer_status_for_decision: {
        Args: {
          p_offer_id: string
          p_status: Database["evaluation"]["Enums"]["decision_status"]
        }
        Returns: undefined
      }
      supplier_get_my_decision: {
        Args: { p_decision_id: string }
        Returns: Json
      }
      supplier_list_my_decisions: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["evaluation"]["Enums"]["decision_status"]
        }
        Returns: {
          decided_at: string
          decision_status: string
          id: string
          offer_id: string
          reason: string
          request_id: string
          updated_at: string
        }[]
      }
    }
    Enums: {
      decision_status: "shortlisted" | "rejected" | "selected_for_contract"
      evaluation_status: "draft" | "in_review" | "completed" | "cancelled"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  finance: {
    Tables: {
      invoice_items: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string
          executed_contract_item_id: string | null
          id: string
          invoice_id: string
          metadata: Json
          organization_id: string
          quantity: number
          quantity_unit: string | null
          shipment_item_id: string | null
          sort_order: number
          tax_rate: number
          tenant_id: string
          total: number
          unit_price: number
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description: string
          executed_contract_item_id?: string | null
          id?: string
          invoice_id: string
          metadata?: Json
          organization_id: string
          quantity?: number
          quantity_unit?: string | null
          shipment_item_id?: string | null
          sort_order?: number
          tax_rate?: number
          tenant_id: string
          total?: number
          unit_price?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string
          executed_contract_item_id?: string | null
          id?: string
          invoice_id?: string
          metadata?: Json
          organization_id?: string
          quantity?: number
          quantity_unit?: string | null
          shipment_item_id?: string | null
          sort_order?: number
          tax_rate?: number
          tenant_id?: string
          total?: number
          unit_price?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "invoice_items_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      invoice_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          from_status: Database["finance"]["Enums"]["invoice_status"] | null
          id: string
          invoice_id: string
          organization_id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["finance"]["Enums"]["invoice_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["finance"]["Enums"]["invoice_status"] | null
          id?: string
          invoice_id: string
          organization_id: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["finance"]["Enums"]["invoice_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["finance"]["Enums"]["invoice_status"] | null
          id?: string
          invoice_id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["finance"]["Enums"]["invoice_status"]
        }
        Relationships: [
          {
            foreignKeyName: "invoice_status_events_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      invoices: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          due_date: string | null
          executed_contract_id: string | null
          fees_amount: number
          id: string
          invoice_code: string
          invoice_date: string | null
          issued_at: string | null
          issued_by: string | null
          metadata: Json
          notes: string | null
          organization_id: string
          paid_amount: number
          paid_at: string | null
          payment_terms_text: string | null
          sent_at: string | null
          sent_by: string | null
          shipment_id: string | null
          status: Database["finance"]["Enums"]["invoice_status"]
          subtotal_amount: number
          supplier_id: string
          supplier_organization_id: string | null
          tax_amount: number
          taxes_and_fees: Json
          tenant_id: string
          total_amount: number
          updated_at: string
          updated_by: string | null
          version: number
          voided_at: string | null
          voided_by: string | null
          voided_reason: string | null
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          due_date?: string | null
          executed_contract_id?: string | null
          fees_amount?: number
          id?: string
          invoice_code: string
          invoice_date?: string | null
          issued_at?: string | null
          issued_by?: string | null
          metadata?: Json
          notes?: string | null
          organization_id: string
          paid_amount?: number
          paid_at?: string | null
          payment_terms_text?: string | null
          sent_at?: string | null
          sent_by?: string | null
          shipment_id?: string | null
          status?: Database["finance"]["Enums"]["invoice_status"]
          subtotal_amount?: number
          supplier_id: string
          supplier_organization_id?: string | null
          tax_amount?: number
          taxes_and_fees?: Json
          tenant_id: string
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          due_date?: string | null
          executed_contract_id?: string | null
          fees_amount?: number
          id?: string
          invoice_code?: string
          invoice_date?: string | null
          issued_at?: string | null
          issued_by?: string | null
          metadata?: Json
          notes?: string | null
          organization_id?: string
          paid_amount?: number
          paid_at?: string | null
          payment_terms_text?: string | null
          sent_at?: string | null
          sent_by?: string | null
          shipment_id?: string | null
          status?: Database["finance"]["Enums"]["invoice_status"]
          subtotal_amount?: number
          supplier_id?: string
          supplier_organization_id?: string | null
          tax_amount?: number
          taxes_and_fees?: Json
          tenant_id?: string
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Relationships: []
      }
      payment_methods: {
        Row: {
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          display_name: string
          id: string
          is_active: boolean
          metadata: Json
          method_type: Database["finance"]["Enums"]["payment_method_type"]
          organization_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          display_name: string
          id?: string
          is_active?: boolean
          metadata?: Json
          method_type: Database["finance"]["Enums"]["payment_method_type"]
          organization_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          display_name?: string
          id?: string
          is_active?: boolean
          metadata?: Json
          method_type?: Database["finance"]["Enums"]["payment_method_type"]
          organization_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      payment_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          from_status: Database["finance"]["Enums"]["payment_status"] | null
          id: string
          invoice_id: string
          organization_id: string
          payload: Json
          payment_id: string
          reason: string | null
          tenant_id: string
          to_status: Database["finance"]["Enums"]["payment_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["finance"]["Enums"]["payment_status"] | null
          id?: string
          invoice_id: string
          organization_id: string
          payload?: Json
          payment_id: string
          reason?: string | null
          tenant_id: string
          to_status: Database["finance"]["Enums"]["payment_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["finance"]["Enums"]["payment_status"] | null
          id?: string
          invoice_id?: string
          organization_id?: string
          payload?: Json
          payment_id?: string
          reason?: string | null
          tenant_id?: string
          to_status?: Database["finance"]["Enums"]["payment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "payment_status_events_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_status_events_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          cancelled_at: string | null
          cancelled_reason: string | null
          completed_at: string | null
          created_at: string
          currency: string
          deleted_at: string | null
          failed_at: string | null
          failed_reason: string | null
          id: string
          invoice_id: string
          metadata: Json
          notes: string | null
          organization_id: string
          paid_amount: number
          payment_date: string | null
          payment_method_id: string | null
          recorded_by_party: string
          recorded_by_user_id: string | null
          refunded_at: string | null
          refunded_reason: string | null
          status: Database["finance"]["Enums"]["payment_status"]
          tenant_id: string
          transaction_reference: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_reason?: string | null
          completed_at?: string | null
          created_at?: string
          currency: string
          deleted_at?: string | null
          failed_at?: string | null
          failed_reason?: string | null
          id?: string
          invoice_id: string
          metadata?: Json
          notes?: string | null
          organization_id: string
          paid_amount: number
          payment_date?: string | null
          payment_method_id?: string | null
          recorded_by_party?: string
          recorded_by_user_id?: string | null
          refunded_at?: string | null
          refunded_reason?: string | null
          status?: Database["finance"]["Enums"]["payment_status"]
          tenant_id: string
          transaction_reference?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          cancelled_at?: string | null
          cancelled_reason?: string | null
          completed_at?: string | null
          created_at?: string
          currency?: string
          deleted_at?: string | null
          failed_at?: string | null
          failed_reason?: string | null
          id?: string
          invoice_id?: string
          metadata?: Json
          notes?: string | null
          organization_id?: string
          paid_amount?: number
          payment_date?: string | null
          payment_method_id?: string | null
          recorded_by_party?: string
          recorded_by_user_id?: string | null
          refunded_at?: string | null
          refunded_reason?: string | null
          status?: Database["finance"]["Enums"]["payment_status"]
          tenant_id?: string
          transaction_reference?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_payment_method_id_fkey"
            columns: ["payment_method_id"]
            isOneToOne: false
            referencedRelation: "payment_methods"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_force_invoice_status: {
        Args: {
          p_invoice_id: string
          p_reason?: string
          p_status: Database["finance"]["Enums"]["invoice_status"]
        }
        Returns: undefined
      }
      admin_get_invoice: { Args: { p_invoice_id: string }; Returns: Json }
      admin_list_invoice_events: {
        Args: { p_invoice_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_invoices: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["finance"]["Enums"]["invoice_status"]
          p_supplier_id?: string
        }
        Returns: {
          created_at: string
          currency: string
          id: string
          invoice_code: string
          organization_id: string
          paid_amount: number
          status: string
          supplier_id: string
          total_amount: number
        }[]
      }
      admin_list_payment_events: {
        Args: { p_invoice_id?: string; p_payment_id?: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          invoice_id: string
          payment_id: string
          reason: string
          to_status: string
        }[]
      }
      admin_void_invoice: {
        Args: { p_invoice_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_cancel_invoice: {
        Args: { p_invoice_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_create_draft_invoice: {
        Args: {
          p_currency?: string
          p_due_date?: string
          p_executed_contract_id?: string
          p_invoice_date?: string
          p_notes?: string
          p_payment_terms_text?: string
          p_shipment_id?: string
        }
        Returns: string
      }
      buyer_get_invoice: { Args: { p_invoice_id: string }; Returns: Json }
      buyer_issue_invoice: {
        Args: { p_invoice_id: string }
        Returns: undefined
      }
      buyer_list_invoices: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["finance"]["Enums"]["invoice_status"]
        }
        Returns: {
          created_at: string
          currency: string
          due_date: string
          executed_contract_id: string
          id: string
          invoice_code: string
          invoice_date: string
          paid_amount: number
          shipment_id: string
          status: string
          supplier_id: string
          total_amount: number
          updated_at: string
        }[]
      }
      buyer_list_payment_methods: {
        Args: {
          p_active_only?: boolean
          p_method_type?: Database["finance"]["Enums"]["payment_method_type"]
        }
        Returns: {
          created_at: string
          currency: string
          display_name: string
          id: string
          is_active: boolean
          method_type: string
          updated_at: string
        }[]
      }
      buyer_mark_overdue: { Args: { p_invoice_id: string }; Returns: undefined }
      buyer_record_payment: {
        Args: {
          p_invoice_id: string
          p_notes?: string
          p_paid_amount: number
          p_payment_date?: string
          p_payment_method_id?: string
          p_status?: Database["finance"]["Enums"]["payment_status"]
          p_transaction_reference?: string
        }
        Returns: string
      }
      buyer_refund_payment: {
        Args: { p_payment_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_remove_invoice_item: {
        Args: { p_item_id: string }
        Returns: undefined
      }
      buyer_send_invoice: { Args: { p_invoice_id: string }; Returns: undefined }
      buyer_update_invoice: {
        Args: {
          p_currency?: string
          p_due_date?: string
          p_fees_amount?: number
          p_invoice_date?: string
          p_invoice_id: string
          p_notes?: string
          p_payment_terms_text?: string
          p_taxes_and_fees?: Json
        }
        Returns: undefined
      }
      buyer_upsert_invoice_item: {
        Args: {
          p_description: string
          p_executed_contract_item_id?: string
          p_invoice_id: string
          p_item_id?: string
          p_quantity?: number
          p_quantity_unit?: string
          p_shipment_item_id?: string
          p_sort_order?: number
          p_tax_rate?: number
          p_unit_price?: number
        }
        Returns: string
      }
      buyer_upsert_payment_method: {
        Args: {
          p_currency?: string
          p_display_name: string
          p_is_active?: boolean
          p_metadata?: Json
          p_method_id?: string
          p_method_type: Database["finance"]["Enums"]["payment_method_type"]
        }
        Returns: string
      }
      fn_assert_buyer_for_invoice: {
        Args: { p_invoice_id: string }
        Returns: Database["finance"]["Enums"]["invoice_status"]
      }
      fn_assert_invoice_editable: {
        Args: { p_invoice_id: string }
        Returns: undefined
      }
      fn_assert_invoice_payable: {
        Args: { p_invoice_id: string }
        Returns: Database["finance"]["Enums"]["invoice_status"]
      }
      fn_audit: {
        Args: { p_action_code: string; p_invoice_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_next_invoice_code: { Args: { p_tenant_id: string }; Returns: string }
      fn_promote_invoice_after_payment: {
        Args: { p_invoice_id: string }
        Returns: undefined
      }
      fn_recompute_invoice_totals: {
        Args: { p_invoice_id: string }
        Returns: undefined
      }
      fn_record_invoice_event: {
        Args: {
          p_from: Database["finance"]["Enums"]["invoice_status"]
          p_invoice_id: string
          p_payload?: Json
          p_reason?: string
          p_to: Database["finance"]["Enums"]["invoice_status"]
        }
        Returns: undefined
      }
      fn_record_payment_event: {
        Args: {
          p_from: Database["finance"]["Enums"]["payment_status"]
          p_payload?: Json
          p_payment_id: string
          p_reason?: string
          p_to: Database["finance"]["Enums"]["payment_status"]
        }
        Returns: undefined
      }
      supplier_get_my_invoice: { Args: { p_invoice_id: string }; Returns: Json }
      supplier_list_my_invoices: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["finance"]["Enums"]["invoice_status"]
        }
        Returns: {
          created_at: string
          currency: string
          due_date: string
          executed_contract_id: string
          id: string
          invoice_code: string
          invoice_date: string
          paid_amount: number
          shipment_id: string
          status: string
          total_amount: number
          updated_at: string
        }[]
      }
      supplier_list_my_payments: {
        Args: {
          p_invoice_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["finance"]["Enums"]["payment_status"]
        }
        Returns: {
          created_at: string
          currency: string
          id: string
          invoice_id: string
          paid_amount: number
          payment_date: string
          recorded_by_party: string
          status: string
        }[]
      }
      supplier_record_payment_receipt: {
        Args: {
          p_invoice_id: string
          p_notes?: string
          p_paid_amount: number
          p_payment_date?: string
          p_transaction_reference?: string
        }
        Returns: string
      }
    }
    Enums: {
      invoice_status:
        | "draft"
        | "issued"
        | "sent"
        | "due"
        | "paid"
        | "partial"
        | "overdue"
        | "cancelled"
        | "voided"
      payment_method_type:
        | "bank_transfer"
        | "credit_card"
        | "paypal"
        | "wire"
        | "check"
        | "other"
      payment_status:
        | "pending"
        | "processing"
        | "completed"
        | "failed"
        | "refunded"
        | "cancelled"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  identity: {
    Tables: {
      permissions: {
        Row: {
          action: string
          code: string
          created_at: string
          description: string | null
          domain: string
          id: string
          label_en: string | null
          label_fa: string | null
        }
        Insert: {
          action: string
          code: string
          created_at?: string
          description?: string | null
          domain: string
          id?: string
          label_en?: string | null
          label_fa?: string | null
        }
        Update: {
          action?: string
          code?: string
          created_at?: string
          description?: string | null
          domain?: string
          id?: string
          label_en?: string | null
          label_fa?: string | null
        }
        Relationships: []
      }
      role_permissions: {
        Row: {
          created_at: string
          permission_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          permission_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_system: boolean
          label_en: string
          label_fa: string
          scope: Database["identity"]["Enums"]["role_scope"]
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_system?: boolean
          label_en: string
          label_fa: string
          scope: Database["identity"]["Enums"]["role_scope"]
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_system?: boolean
          label_en?: string
          label_fa?: string
          scope?: Database["identity"]["Enums"]["role_scope"]
          updated_at?: string
        }
        Relationships: []
      }
      tenants: {
        Row: {
          code: string
          country_code: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          name_en: string
          name_fa: string
          status: Database["identity"]["Enums"]["tenant_status"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          code: string
          country_code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          name_en: string
          name_fa: string
          status?: Database["identity"]["Enums"]["tenant_status"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          code?: string
          country_code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          name_en?: string
          name_fa?: string
          status?: Database["identity"]["Enums"]["tenant_status"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          full_name: string | null
          id: string
          locale: Database["identity"]["Enums"]["locale"]
          phone_e164: string | null
          primary_organization_id: string | null
          status: Database["identity"]["Enums"]["user_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          full_name?: string | null
          id: string
          locale?: Database["identity"]["Enums"]["locale"]
          phone_e164?: string | null
          primary_organization_id?: string | null
          status?: Database["identity"]["Enums"]["user_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          full_name?: string | null
          id?: string
          locale?: Database["identity"]["Enums"]["locale"]
          phone_e164?: string | null
          primary_organization_id?: string | null
          status?: Database["identity"]["Enums"]["user_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "user_profiles_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          granted_at: string
          granted_by: string | null
          id: string
          revoked_at: string | null
          role_id: string
          scope_id: string | null
          scope_type: Database["identity"]["Enums"]["role_scope"]
          updated_at: string
          updated_by: string | null
          user_id: string
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          granted_at?: string
          granted_by?: string | null
          id?: string
          revoked_at?: string | null
          role_id: string
          scope_id?: string | null
          scope_type: Database["identity"]["Enums"]["role_scope"]
          updated_at?: string
          updated_by?: string | null
          user_id: string
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          granted_at?: string
          granted_by?: string | null
          id?: string
          revoked_at?: string | null
          role_id?: string
          scope_id?: string | null
          scope_type?: Database["identity"]["Enums"]["role_scope"]
          updated_at?: string
          updated_by?: string | null
          user_id?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "user_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_add_membership: {
        Args: {
          p_organization_id: string
          p_role_code: string
          p_user_id: string
        }
        Returns: string
      }
      admin_approve_user: {
        Args: {
          p_full_name?: string
          p_locale?: Database["identity"]["Enums"]["locale"]
          p_organization_id: string
          p_role_code: string
          p_tenant_id: string
          p_user_id: string
        }
        Returns: undefined
      }
      admin_assign_role: {
        Args: {
          p_role_code: string
          p_scope_id?: string
          p_scope_type?: Database["identity"]["Enums"]["role_scope"]
          p_user_id: string
        }
        Returns: undefined
      }
      admin_create_organization: {
        Args: {
          p_code: string
          p_country_code?: string
          p_legal_name?: string
          p_name_en: string
          p_name_fa: string
          p_registration_number?: string
          p_status?: Database["organization"]["Enums"]["organization_status"]
          p_tax_id?: string
          p_tenant_id: string
          p_type: Database["organization"]["Enums"]["organization_type"]
        }
        Returns: string
      }
      admin_get_user: {
        Args: { p_user_id: string }
        Returns: {
          email: string
          email_created_at: string
          full_name: string
          has_profile: boolean
          primary_organization_id: string
          status: string
          tenant_id: string
          user_id: string
        }[]
      }
      admin_list_audit_events: {
        Args: { p_limit?: number; p_offset?: number; p_since?: string }
        Returns: {
          action_code: string
          actor_user_id: string
          id: string
          ip_address: unknown
          occurred_at: string
          organization_id: string
          payload: Json
          resource_id: string
          resource_type: string
          tenant_id: string
        }[]
      }
      admin_list_users: {
        Args: { p_limit?: number; p_offset?: number; p_status_filter?: string }
        Returns: {
          email: string
          email_created_at: string
          full_name: string
          has_profile: boolean
          primary_organization_id: string
          status: string
          tenant_id: string
          user_id: string
        }[]
      }
      admin_set_user_status: {
        Args: {
          p_status: Database["identity"]["Enums"]["user_status"]
          p_user_id: string
        }
        Returns: undefined
      }
      current_organization_id: { Args: never; Returns: string }
      current_tenant_id: { Args: never; Returns: string }
      current_user_id: { Args: never; Returns: string }
      custom_access_token_hook: { Args: { event: Json }; Returns: Json }
      has_role: { Args: { p_code: string }; Returns: boolean }
      is_platform_admin: { Args: never; Returns: boolean }
      record_logout: { Args: never; Returns: undefined }
      user_role_codes: { Args: { p_user_id: string }; Returns: string[] }
    }
    Enums: {
      locale: "fa" | "en"
      role_scope: "platform" | "tenant" | "organization" | "business_unit"
      tenant_status: "active" | "pending" | "suspended" | "closed"
      user_status: "active" | "pending" | "suspended" | "deactivated"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  kyc: {
    Tables: {
      documents: {
        Row: {
          bucket: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          document_kind: Database["kyc"]["Enums"]["kyc_document_kind"]
          expires_on: string | null
          id: string
          issued_on: string | null
          mime_type: string | null
          organization_verification_id: string | null
          personal_verification_id: string | null
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          size_bytes: number | null
          status: Database["kyc"]["Enums"]["kyc_document_status"]
          storage_path: string | null
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          title: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          bucket?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind: Database["kyc"]["Enums"]["kyc_document_kind"]
          expires_on?: string | null
          id?: string
          issued_on?: string | null
          mime_type?: string | null
          organization_verification_id?: string | null
          personal_verification_id?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          size_bytes?: number | null
          status?: Database["kyc"]["Enums"]["kyc_document_status"]
          storage_path?: string | null
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          title?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          bucket?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind?: Database["kyc"]["Enums"]["kyc_document_kind"]
          expires_on?: string | null
          id?: string
          issued_on?: string | null
          mime_type?: string | null
          organization_verification_id?: string | null
          personal_verification_id?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          size_bytes?: number | null
          status?: Database["kyc"]["Enums"]["kyc_document_status"]
          storage_path?: string | null
          subject_type?: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id?: string
          title?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "documents_organization_verification_id_fkey"
            columns: ["organization_verification_id"]
            isOneToOne: false
            referencedRelation: "organization_verifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_personal_verification_id_fkey"
            columns: ["personal_verification_id"]
            isOneToOne: false
            referencedRelation: "personal_verifications"
            referencedColumns: ["id"]
          },
        ]
      }
      events: {
        Row: {
          actor_user_id: string | null
          event_kind: Database["kyc"]["Enums"]["kyc_event_kind"]
          id: string
          occurred_at: string
          organization_id: string | null
          organization_verification_id: string | null
          payload: Json
          personal_verification_id: string | null
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          user_id: string | null
        }
        Insert: {
          actor_user_id?: string | null
          event_kind: Database["kyc"]["Enums"]["kyc_event_kind"]
          id?: string
          occurred_at?: string
          organization_id?: string | null
          organization_verification_id?: string | null
          payload?: Json
          personal_verification_id?: string | null
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          user_id?: string | null
        }
        Update: {
          actor_user_id?: string | null
          event_kind?: Database["kyc"]["Enums"]["kyc_event_kind"]
          id?: string
          occurred_at?: string
          organization_id?: string | null
          organization_verification_id?: string | null
          payload?: Json
          personal_verification_id?: string | null
          subject_type?: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "events_organization_verification_id_fkey"
            columns: ["organization_verification_id"]
            isOneToOne: false
            referencedRelation: "organization_verifications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "events_personal_verification_id_fkey"
            columns: ["personal_verification_id"]
            isOneToOne: false
            referencedRelation: "personal_verifications"
            referencedColumns: ["id"]
          },
        ]
      }
      organization_verifications: {
        Row: {
          approved_at: string | null
          attempt_no: number
          authorized_signatory_user_id: string | null
          country_code: string | null
          created_at: string
          decision_reason: string | null
          deleted_at: string | null
          expires_at: string | null
          id: string
          incorporated_on: string | null
          legal_name: string | null
          organization_id: string
          registration_number: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at: string | null
          tax_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          approved_at?: string | null
          attempt_no?: number
          authorized_signatory_user_id?: string | null
          country_code?: string | null
          created_at?: string
          decision_reason?: string | null
          deleted_at?: string | null
          expires_at?: string | null
          id?: string
          incorporated_on?: string | null
          legal_name?: string | null
          organization_id: string
          registration_number?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at?: string | null
          tax_id?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          approved_at?: string | null
          attempt_no?: number
          authorized_signatory_user_id?: string | null
          country_code?: string | null
          created_at?: string
          decision_reason?: string | null
          deleted_at?: string | null
          expires_at?: string | null
          id?: string
          incorporated_on?: string | null
          legal_name?: string | null
          organization_id?: string
          registration_number?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at?: string | null
          tax_id?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      personal_verifications: {
        Row: {
          approved_at: string | null
          attempt_no: number
          country_code: string | null
          created_at: string
          date_of_birth: string | null
          decision_reason: string | null
          deleted_at: string | null
          expires_at: string | null
          full_legal_name: string | null
          id: string
          national_id_last4: string | null
          national_id_number_hash: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          user_id: string
          version: number
        }
        Insert: {
          approved_at?: string | null
          attempt_no?: number
          country_code?: string | null
          created_at?: string
          date_of_birth?: string | null
          decision_reason?: string | null
          deleted_at?: string | null
          expires_at?: string | null
          full_legal_name?: string | null
          id?: string
          national_id_last4?: string | null
          national_id_number_hash?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          user_id: string
          version?: number
        }
        Update: {
          approved_at?: string | null
          attempt_no?: number
          country_code?: string | null
          created_at?: string
          date_of_birth?: string | null
          decision_reason?: string | null
          deleted_at?: string | null
          expires_at?: string | null
          full_legal_name?: string | null
          id?: string
          national_id_last4?: string | null
          national_id_number_hash?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string
          version?: number
        }
        Relationships: []
      }
      risk_flags: {
        Row: {
          code: string
          created_at: string
          deleted_at: string | null
          detail: string | null
          id: string
          organization_id: string | null
          raised_at: string
          raised_by: string | null
          resolution_note: string | null
          resolved_at: string | null
          resolved_by: string | null
          severity: Database["kyc"]["Enums"]["kyc_risk_severity"]
          source: string
          status: Database["kyc"]["Enums"]["kyc_risk_status"]
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          user_id: string | null
          version: number
        }
        Insert: {
          code: string
          created_at?: string
          deleted_at?: string | null
          detail?: string | null
          id?: string
          organization_id?: string | null
          raised_at?: string
          raised_by?: string | null
          resolution_note?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          severity: Database["kyc"]["Enums"]["kyc_risk_severity"]
          source?: string
          status?: Database["kyc"]["Enums"]["kyc_risk_status"]
          subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string | null
          version?: number
        }
        Update: {
          code?: string
          created_at?: string
          deleted_at?: string | null
          detail?: string | null
          id?: string
          organization_id?: string | null
          raised_at?: string
          raised_by?: string | null
          resolution_note?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          severity?: Database["kyc"]["Enums"]["kyc_risk_severity"]
          source?: string
          status?: Database["kyc"]["Enums"]["kyc_risk_status"]
          subject_type?: Database["kyc"]["Enums"]["kyc_subject_type"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string | null
          version?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_approve_verification: {
        Args: {
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_validity_months?: number
          p_verification_id: string
        }
        Returns: undefined
      }
      admin_assign_verification: {
        Args: {
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_verification_id: string
        }
        Returns: undefined
      }
      admin_decide_document: {
        Args: {
          p_decision: Database["kyc"]["Enums"]["kyc_document_status"]
          p_document_id: string
          p_reason?: string
        }
        Returns: undefined
      }
      admin_get_verification: {
        Args: {
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_verification_id: string
        }
        Returns: Json
      }
      admin_list_verifications: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status_filter?: Database["kyc"]["Enums"]["kyc_status"]
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
        }
        Returns: {
          approved_at: string
          attempt_no: number
          created_at: string
          expires_at: string
          id: string
          reviewed_at: string
          status: string
          subject_id: string
          subject_type: string
          submitted_at: string
          tenant_id: string
        }[]
      }
      admin_raise_risk_flag: {
        Args: {
          p_code?: string
          p_detail?: string
          p_organization_id?: string
          p_severity?: Database["kyc"]["Enums"]["kyc_risk_severity"]
          p_source?: string
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_user_id?: string
        }
        Returns: string
      }
      admin_reject_verification: {
        Args: {
          p_reason: string
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_verification_id: string
        }
        Returns: undefined
      }
      admin_request_info: {
        Args: {
          p_reason: string
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_verification_id: string
        }
        Returns: undefined
      }
      admin_resolve_risk_flag: {
        Args: {
          p_flag_id: string
          p_note?: string
          p_status: Database["kyc"]["Enums"]["kyc_risk_status"]
        }
        Returns: undefined
      }
      attach_document: {
        Args: {
          p_document_kind: Database["kyc"]["Enums"]["kyc_document_kind"]
          p_expires_on?: string
          p_issued_on?: string
          p_mime_type?: string
          p_size_bytes?: number
          p_storage_path: string
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_title?: string
          p_verification_id: string
        }
        Returns: string
      }
      expire_due_verifications: { Args: never; Returns: number }
      fn_assert_admin: { Args: never; Returns: undefined }
      fn_assert_organization_subject: {
        Args: { p_verification_id: string }
        Returns: {
          approved_at: string | null
          attempt_no: number
          authorized_signatory_user_id: string | null
          country_code: string | null
          created_at: string
          decision_reason: string | null
          deleted_at: string | null
          expires_at: string | null
          id: string
          incorporated_on: string | null
          legal_name: string | null
          organization_id: string
          registration_number: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at: string | null
          tax_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "organization_verifications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_assert_personal_subject: {
        Args: { p_verification_id: string }
        Returns: {
          approved_at: string | null
          attempt_no: number
          country_code: string | null
          created_at: string
          date_of_birth: string | null
          decision_reason: string | null
          deleted_at: string | null
          expires_at: string | null
          full_legal_name: string | null
          id: string
          national_id_last4: string | null
          national_id_number_hash: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["kyc"]["Enums"]["kyc_status"]
          submitted_at: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          user_id: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "personal_verifications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_resource_id: string
          p_tenant_id: string
        }
        Returns: undefined
      }
      fn_hash_national_id: { Args: { p_raw: string }; Returns: string }
      fn_record_event: {
        Args: {
          p_event_kind: Database["kyc"]["Enums"]["kyc_event_kind"]
          p_organization_id: string
          p_organization_verification_id: string
          p_payload?: Json
          p_personal_verification_id: string
          p_subject_type: Database["kyc"]["Enums"]["kyc_subject_type"]
          p_tenant_id: string
          p_user_id: string
        }
        Returns: string
      }
      get_my_organization_verification: {
        Args: { p_organization_id: string }
        Returns: Json
      }
      get_my_personal_verification: { Args: never; Returns: Json }
      is_organization_verified: {
        Args: { p_organization_id: string }
        Returns: boolean
      }
      is_personal_verified: { Args: { p_user_id: string }; Returns: boolean }
      start_organization_verification: {
        Args: { p_organization_id: string }
        Returns: string
      }
      start_personal_verification: { Args: never; Returns: string }
      submit_organization_verification: {
        Args: { p_id: string }
        Returns: undefined
      }
      submit_personal_verification: {
        Args: { p_id: string }
        Returns: undefined
      }
      update_organization_draft: {
        Args: {
          p_country_code?: string
          p_id: string
          p_incorporated_on?: string
          p_legal_name?: string
          p_registration_number?: string
          p_tax_id?: string
        }
        Returns: undefined
      }
      update_personal_draft: {
        Args: {
          p_country_code?: string
          p_date_of_birth?: string
          p_full_legal_name?: string
          p_id: string
          p_national_id_number?: string
        }
        Returns: undefined
      }
    }
    Enums: {
      kyc_document_kind:
        | "national_id_card"
        | "passport"
        | "driver_license"
        | "proof_of_address"
        | "company_registration"
        | "tax_certificate"
        | "articles_of_association"
        | "authorized_signatory_letter"
        | "ownership_disclosure"
        | "other"
      kyc_document_status: "pending" | "accepted" | "rejected" | "superseded"
      kyc_event_kind:
        | "submitted"
        | "assigned"
        | "info_requested"
        | "resubmitted"
        | "approved"
        | "rejected"
        | "expired"
        | "risk_flag_raised"
        | "risk_flag_resolved"
        | "document_attached"
        | "document_decision"
      kyc_risk_severity: "info" | "low" | "medium" | "high" | "critical"
      kyc_risk_status: "open" | "acknowledged" | "mitigated" | "dismissed"
      kyc_status:
        | "not_started"
        | "draft"
        | "submitted"
        | "in_review"
        | "info_requested"
        | "approved"
        | "rejected"
        | "expired"
      kyc_subject_type: "person" | "organization"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  marketplace: {
    Tables: {
      booking_events: {
        Row: {
          actor_organization_id: string | null
          actor_party: string
          actor_user_id: string | null
          booking_request_id: string
          created_at: string
          event_type: string
          from_status: Database["marketplace"]["Enums"]["booking_status"] | null
          id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["marketplace"]["Enums"]["booking_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_party: string
          actor_user_id?: string | null
          booking_request_id: string
          created_at?: string
          event_type: string
          from_status?:
            | Database["marketplace"]["Enums"]["booking_status"]
            | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["marketplace"]["Enums"]["booking_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_party?: string
          actor_user_id?: string | null
          booking_request_id?: string
          created_at?: string
          event_type?: string
          from_status?:
            | Database["marketplace"]["Enums"]["booking_status"]
            | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["marketplace"]["Enums"]["booking_status"]
        }
        Relationships: [
          {
            foreignKeyName: "booking_events_booking_request_id_fkey"
            columns: ["booking_request_id"]
            isOneToOne: false
            referencedRelation: "booking_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      booking_requests: {
        Row: {
          buyer_organization_id: string
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          capacity_listing_id: string
          carrier_organization_id: string
          confirmed_at: string | null
          confirmed_by: string | null
          created_at: string
          deleted_at: string | null
          expires_at: string | null
          id: string
          notes_en: string | null
          notes_fa: string | null
          requested_by: string | null
          requested_pickup_at: string | null
          requested_quantity_units: number | null
          requested_unit_label: string | null
          responded_at: string | null
          responded_by: string | null
          shipment_id: string
          status: Database["marketplace"]["Enums"]["booking_status"]
          tenant_id: string
          updated_at: string
          version: number
        }
        Insert: {
          buyer_organization_id: string
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          capacity_listing_id: string
          carrier_organization_id: string
          confirmed_at?: string | null
          confirmed_by?: string | null
          created_at?: string
          deleted_at?: string | null
          expires_at?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          requested_by?: string | null
          requested_pickup_at?: string | null
          requested_quantity_units?: number | null
          requested_unit_label?: string | null
          responded_at?: string | null
          responded_by?: string | null
          shipment_id: string
          status?: Database["marketplace"]["Enums"]["booking_status"]
          tenant_id: string
          updated_at?: string
          version?: number
        }
        Update: {
          buyer_organization_id?: string
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          capacity_listing_id?: string
          carrier_organization_id?: string
          confirmed_at?: string | null
          confirmed_by?: string | null
          created_at?: string
          deleted_at?: string | null
          expires_at?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          requested_by?: string | null
          requested_pickup_at?: string | null
          requested_quantity_units?: number | null
          requested_unit_label?: string | null
          responded_at?: string | null
          responded_by?: string | null
          shipment_id?: string
          status?: Database["marketplace"]["Enums"]["booking_status"]
          tenant_id?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "booking_requests_capacity_listing_id_fkey"
            columns: ["capacity_listing_id"]
            isOneToOne: false
            referencedRelation: "capacity_listings"
            referencedColumns: ["id"]
          },
        ]
      }
      capacity_listings: {
        Row: {
          capacity_unit_label: string | null
          capacity_units: number | null
          carrier_organization_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          destination_city: string | null
          destination_country_code: string | null
          id: string
          notes_en: string | null
          notes_fa: string | null
          origin_city: string | null
          origin_country_code: string | null
          published_by_user_id: string | null
          status: Database["marketplace"]["Enums"]["capacity_status"]
          tenant_id: string
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          updated_at: string
          updated_by: string | null
          valid_from: string | null
          valid_until: string | null
        }
        Insert: {
          capacity_unit_label?: string | null
          capacity_units?: number | null
          carrier_organization_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          destination_city?: string | null
          destination_country_code?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          origin_city?: string | null
          origin_country_code?: string | null
          published_by_user_id?: string | null
          status?: Database["marketplace"]["Enums"]["capacity_status"]
          tenant_id: string
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          updated_at?: string
          updated_by?: string | null
          valid_from?: string | null
          valid_until?: string | null
        }
        Update: {
          capacity_unit_label?: string | null
          capacity_units?: number | null
          carrier_organization_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          destination_city?: string | null
          destination_country_code?: string | null
          id?: string
          notes_en?: string | null
          notes_fa?: string | null
          origin_city?: string | null
          origin_country_code?: string | null
          published_by_user_id?: string | null
          status?: Database["marketplace"]["Enums"]["capacity_status"]
          tenant_id?: string
          transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
          updated_at?: string
          updated_by?: string | null
          valid_from?: string | null
          valid_until?: string | null
        }
        Relationships: []
      }
      capacity_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          capacity_listing_id: string
          created_at: string
          from_status:
            | Database["marketplace"]["Enums"]["capacity_status"]
            | null
          id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          capacity_listing_id: string
          created_at?: string
          from_status?:
            | Database["marketplace"]["Enums"]["capacity_status"]
            | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          capacity_listing_id?: string
          created_at?: string
          from_status?:
            | Database["marketplace"]["Enums"]["capacity_status"]
            | null
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Relationships: [
          {
            foreignKeyName: "capacity_status_events_capacity_listing_id_fkey"
            columns: ["capacity_listing_id"]
            isOneToOne: false
            referencedRelation: "capacity_listings"
            referencedColumns: ["id"]
          },
        ]
      }
      carrier_directory_visibility: {
        Row: {
          carrier_organization_id: string
          created_at: string
          created_by: string | null
          is_public: boolean
          published_at: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          carrier_organization_id: string
          created_at?: string
          created_by?: string | null
          is_public?: boolean
          published_at?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          carrier_organization_id?: string
          created_at?: string
          created_by?: string | null
          is_public?: boolean
          published_at?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      carrier_profiles: {
        Row: {
          bio_en: string | null
          bio_fa: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          display_name_en: string | null
          display_name_fa: string | null
          fleet_size_hint: number | null
          id: string
          organization_id: string
          service_country_codes: string[]
          status: Database["marketplace"]["Enums"]["carrier_profile_status"]
          tenant_id: string
          transport_modes: Database["shipment"]["Enums"]["transport_mode"][]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          bio_en?: string | null
          bio_fa?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          fleet_size_hint?: number | null
          id?: string
          organization_id: string
          service_country_codes?: string[]
          status?: Database["marketplace"]["Enums"]["carrier_profile_status"]
          tenant_id: string
          transport_modes?: Database["shipment"]["Enums"]["transport_mode"][]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          bio_en?: string | null
          bio_fa?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          fleet_size_hint?: number | null
          id?: string
          organization_id?: string
          service_country_codes?: string[]
          status?: Database["marketplace"]["Enums"]["carrier_profile_status"]
          tenant_id?: string
          transport_modes?: Database["shipment"]["Enums"]["transport_mode"][]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_archive_capacity: {
        Args: { p_listing_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_cancel_booking: {
        Args: { p_booking_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_capacity_summary: { Args: never; Returns: Json }
      admin_get_booking: { Args: { p_booking_id: string }; Returns: Json }
      admin_get_carrier: { Args: { p_carrier_id: string }; Returns: Json }
      admin_list_activity: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          actor_user_id: string
          capacity_listing_id: string
          carrier_organization_id: string
          created_at: string
          event_id: string
          from_status: Database["marketplace"]["Enums"]["capacity_status"]
          reason: string
          to_status: Database["marketplace"]["Enums"]["capacity_status"]
        }[]
      }
      admin_list_bookings: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["marketplace"]["Enums"]["booking_status"]
        }
        Returns: {
          buyer_organization_id: string
          capacity_listing_id: string
          carrier_organization_id: string
          created_at: string
          expires_at: string
          id: string
          requested_pickup_at: string
          shipment_id: string
          status: Database["marketplace"]["Enums"]["booking_status"]
          updated_at: string
        }[]
      }
      admin_list_capacity: {
        Args: {
          p_carrier_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Returns: {
          carrier_name_en: string
          carrier_name_fa: string
          carrier_organization_id: string
          created_at: string
          destination_city: string
          destination_country_code: string
          id: string
          origin_city: string
          origin_country_code: string
          status: Database["marketplace"]["Enums"]["capacity_status"]
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          valid_from: string
          valid_until: string
        }[]
      }
      admin_list_carriers: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_search?: string
          p_status?: Database["marketplace"]["Enums"]["carrier_profile_status"]
        }
        Returns: {
          code: string
          created_at: string
          id: string
          is_public: boolean
          name_en: string
          name_fa: string
          organization_id: string
          service_country_codes: string[]
          status: Database["marketplace"]["Enums"]["carrier_profile_status"]
          transport_modes: Database["shipment"]["Enums"]["transport_mode"][]
        }[]
      }
      admin_matching_summary: { Args: never; Returns: Json }
      buyer_cancel_booking: {
        Args: { p_booking_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_confirm_booking: {
        Args: { p_booking_id: string }
        Returns: undefined
      }
      buyer_create_booking_request: {
        Args: {
          p_capacity_listing_id: string
          p_expires_at?: string
          p_notes_en?: string
          p_notes_fa?: string
          p_requested_pickup_at?: string
          p_requested_quantity_units?: number
          p_requested_unit_label?: string
          p_shipment_id: string
        }
        Returns: string
      }
      buyer_get_booking: { Args: { p_booking_id: string }; Returns: Json }
      buyer_get_carrier: { Args: { p_carrier_id: string }; Returns: Json }
      buyer_list_capacity: {
        Args: {
          p_carrier_id?: string
          p_destination_country?: string
          p_limit?: number
          p_offset?: number
          p_origin_country?: string
          p_transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
        }
        Returns: {
          capacity_unit_label: string
          capacity_units: number
          carrier_name_en: string
          carrier_name_fa: string
          carrier_organization_id: string
          created_at: string
          destination_city: string
          destination_country_code: string
          id: string
          origin_city: string
          origin_country_code: string
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          valid_from: string
          valid_until: string
        }[]
      }
      buyer_list_carriers: {
        Args: {
          p_country?: string
          p_limit?: number
          p_offset?: number
          p_search?: string
          p_transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
        }
        Returns: {
          code: string
          country_code: string
          created_at: string
          display_name_en: string
          display_name_fa: string
          id: string
          name_en: string
          name_fa: string
          organization_id: string
          service_country_codes: string[]
          status: Database["marketplace"]["Enums"]["carrier_profile_status"]
          transport_modes: Database["shipment"]["Enums"]["transport_mode"][]
        }[]
      }
      buyer_list_my_bookings: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["marketplace"]["Enums"]["booking_status"]
        }
        Returns: {
          buyer_organization_id: string
          capacity_listing_id: string
          carrier_organization_id: string
          created_at: string
          expires_at: string
          id: string
          requested_pickup_at: string
          shipment_id: string
          status: Database["marketplace"]["Enums"]["booking_status"]
          updated_at: string
        }[]
      }
      carrier_accept_booking: {
        Args: { p_booking_id: string; p_notes?: string }
        Returns: undefined
      }
      carrier_get_booking: { Args: { p_booking_id: string }; Returns: Json }
      carrier_list_booking_requests: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["marketplace"]["Enums"]["booking_status"]
        }
        Returns: {
          buyer_organization_id: string
          capacity_listing_id: string
          carrier_organization_id: string
          created_at: string
          expires_at: string
          id: string
          requested_pickup_at: string
          shipment_id: string
          status: Database["marketplace"]["Enums"]["booking_status"]
          updated_at: string
        }[]
      }
      carrier_reject_booking: {
        Args: { p_booking_id: string; p_reason?: string }
        Returns: undefined
      }
      carrier_set_directory_visibility: {
        Args: { p_is_public: boolean; p_organization_id: string }
        Returns: undefined
      }
      carrier_upsert_profile: {
        Args: {
          p_bio_en?: string
          p_bio_fa?: string
          p_display_name_en?: string
          p_display_name_fa?: string
          p_fleet_size_hint?: number
          p_organization_id: string
          p_profile_id?: string
          p_service_country_codes?: string[]
          p_status?: Database["marketplace"]["Enums"]["carrier_profile_status"]
          p_transport_modes?: Database["shipment"]["Enums"]["transport_mode"][]
        }
        Returns: string
      }
      find_matching_capacity: {
        Args: { p_limit?: number; p_shipment_id: string }
        Returns: {
          capacity_listing_id: string
          carrier_name: string
          carrier_organization_id: string
          destination_country_code: string
          origin_country_code: string
          score: number
          score_breakdown: Json
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          valid_from: string
          valid_until: string
        }[]
      }
      find_matching_carriers: {
        Args: { p_limit?: number; p_shipment_id: string }
        Returns: {
          best_listing_id: string
          carrier_name: string
          carrier_organization_id: string
          score: number
          score_breakdown: Json
        }[]
      }
      fn_assert_buyer_for_booking: {
        Args: { p_booking_id: string }
        Returns: Database["marketplace"]["Enums"]["booking_status"]
      }
      fn_assert_can_view_booking: {
        Args: { p_booking_id: string }
        Returns: undefined
      }
      fn_assert_can_view_shipment: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      fn_assert_carrier_actor: {
        Args: { p_org_id: string }
        Returns: undefined
      }
      fn_assert_carrier_for_booking: {
        Args: { p_booking_id: string }
        Returns: Database["marketplace"]["Enums"]["booking_status"]
      }
      fn_assert_carrier_org_type: {
        Args: { p_org_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_resource_id: string
          p_resource_type?: string
        }
        Returns: undefined
      }
      fn_booking_audit: {
        Args: { p_action_code: string; p_booking_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_profile_completeness: {
        Args: { p_profile_id: string }
        Returns: number
      }
      fn_record_booking_event: {
        Args: {
          p_actor_party: string
          p_booking_id: string
          p_event_type: string
          p_from: Database["marketplace"]["Enums"]["booking_status"]
          p_payload?: Json
          p_reason?: string
          p_to: Database["marketplace"]["Enums"]["booking_status"]
        }
        Returns: string
      }
      fn_record_capacity_event: {
        Args: {
          p_from: Database["marketplace"]["Enums"]["capacity_status"]
          p_listing_id: string
          p_payload?: Json
          p_reason?: string
          p_to: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Returns: undefined
      }
      fn_score_capacity_for_shipment: {
        Args: { p_listing_id: string; p_shipment_id: string }
        Returns: {
          score: number
          score_breakdown: Json
        }[]
      }
      supplier_archive_capacity: {
        Args: { p_listing_id: string; p_reason?: string }
        Returns: undefined
      }
      supplier_list_my_capacity: {
        Args: {
          p_carrier_organization_id: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["marketplace"]["Enums"]["capacity_status"]
        }
        Returns: {
          capacity_unit_label: string
          capacity_units: number
          carrier_organization_id: string
          created_at: string
          destination_city: string
          destination_country_code: string
          id: string
          origin_city: string
          origin_country_code: string
          status: Database["marketplace"]["Enums"]["capacity_status"]
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          updated_at: string
          valid_from: string
          valid_until: string
        }[]
      }
      supplier_publish_capacity: {
        Args: {
          p_capacity_units?: number
          p_carrier_organization_id: string
          p_destination_city?: string
          p_destination_country?: string
          p_notes_en?: string
          p_notes_fa?: string
          p_origin_city?: string
          p_origin_country?: string
          p_transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          p_unit_label?: string
          p_valid_from?: string
          p_valid_until?: string
        }
        Returns: string
      }
      supplier_update_capacity: {
        Args: {
          p_capacity_units?: number
          p_destination_city?: string
          p_destination_country?: string
          p_listing_id: string
          p_notes_en?: string
          p_notes_fa?: string
          p_origin_city?: string
          p_origin_country?: string
          p_transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
          p_unit_label?: string
          p_valid_from?: string
          p_valid_until?: string
        }
        Returns: undefined
      }
    }
    Enums: {
      booking_status:
        | "draft"
        | "pending_carrier"
        | "carrier_accepted"
        | "carrier_rejected"
        | "buyer_confirmed"
        | "buyer_cancelled"
        | "expired"
      capacity_status: "draft" | "active" | "reserved" | "expired" | "archived"
      carrier_profile_status: "draft" | "active" | "suspended" | "archived"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  notify: {
    Tables: {
      delivery_attempts: {
        Row: {
          attempt_number: number
          attempted_at: string | null
          channel: Database["notify"]["Enums"]["channel_type"]
          created_at: string
          delivered_at: string | null
          external_reference: string | null
          failed_at: string | null
          failure_reason: string | null
          id: string
          notification_id: string
          organization_id: string | null
          payload: Json
          status: Database["notify"]["Enums"]["delivery_status"]
          tenant_id: string
        }
        Insert: {
          attempt_number?: number
          attempted_at?: string | null
          channel: Database["notify"]["Enums"]["channel_type"]
          created_at?: string
          delivered_at?: string | null
          external_reference?: string | null
          failed_at?: string | null
          failure_reason?: string | null
          id?: string
          notification_id: string
          organization_id?: string | null
          payload?: Json
          status?: Database["notify"]["Enums"]["delivery_status"]
          tenant_id: string
        }
        Update: {
          attempt_number?: number
          attempted_at?: string | null
          channel?: Database["notify"]["Enums"]["channel_type"]
          created_at?: string
          delivered_at?: string | null
          external_reference?: string | null
          failed_at?: string | null
          failure_reason?: string | null
          id?: string
          notification_id?: string
          organization_id?: string | null
          payload?: Json
          status?: Database["notify"]["Enums"]["delivery_status"]
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "delivery_attempts_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: false
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      materialization_audit: {
        Row: {
          created_at: string
          id: string
          metadata: Json
          notes: string | null
          notifications_created: number
          organization_id: string | null
          recipients_resolved: number
          source_entity_id: string | null
          source_entity_type: string | null
          source_event_id: string | null
          source_event_type: string | null
          template_code: string | null
          tenant_id: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          metadata?: Json
          notes?: string | null
          notifications_created?: number
          organization_id?: string | null
          recipients_resolved?: number
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_event_id?: string | null
          source_event_type?: string | null
          template_code?: string | null
          tenant_id?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          metadata?: Json
          notes?: string | null
          notifications_created?: number
          organization_id?: string | null
          recipients_resolved?: number
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_event_id?: string | null
          source_event_type?: string | null
          template_code?: string | null
          tenant_id?: string | null
        }
        Relationships: []
      }
      notification_templates: {
        Row: {
          action_url_template: string | null
          body_en: string
          body_fa: string
          category: Database["notify"]["Enums"]["notification_category"]
          created_at: string
          created_by: string | null
          default_channels: Database["notify"]["Enums"]["channel_type"][]
          default_priority: Database["notify"]["Enums"]["notification_priority"]
          deleted_at: string | null
          event_type_filter: string | null
          id: string
          metadata: Json
          organization_id: string | null
          status: Database["notify"]["Enums"]["template_status"]
          template_code: string
          tenant_id: string | null
          title_en: string
          title_fa: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          action_url_template?: string | null
          body_en: string
          body_fa: string
          category: Database["notify"]["Enums"]["notification_category"]
          created_at?: string
          created_by?: string | null
          default_channels?: Database["notify"]["Enums"]["channel_type"][]
          default_priority?: Database["notify"]["Enums"]["notification_priority"]
          deleted_at?: string | null
          event_type_filter?: string | null
          id?: string
          metadata?: Json
          organization_id?: string | null
          status?: Database["notify"]["Enums"]["template_status"]
          template_code: string
          tenant_id?: string | null
          title_en: string
          title_fa: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          action_url_template?: string | null
          body_en?: string
          body_fa?: string
          category?: Database["notify"]["Enums"]["notification_category"]
          created_at?: string
          created_by?: string | null
          default_channels?: Database["notify"]["Enums"]["channel_type"][]
          default_priority?: Database["notify"]["Enums"]["notification_priority"]
          deleted_at?: string | null
          event_type_filter?: string | null
          id?: string
          metadata?: Json
          organization_id?: string | null
          status?: Database["notify"]["Enums"]["template_status"]
          template_code?: string
          tenant_id?: string | null
          title_en?: string
          title_fa?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      notifications: {
        Row: {
          action_url: string | null
          archived_at: string | null
          body_en: string | null
          body_fa: string | null
          category: Database["notify"]["Enums"]["notification_category"]
          created_at: string
          deleted_at: string | null
          dismissed_at: string | null
          id: string
          organization_id: string | null
          payload: Json
          priority: Database["notify"]["Enums"]["notification_priority"]
          read_at: string | null
          read_by: string | null
          recipient_party: string | null
          recipient_role_hint: string | null
          recipient_user_id: string
          source_entity_id: string | null
          source_entity_type: string | null
          source_event_id: string | null
          source_event_type: string | null
          status: Database["notify"]["Enums"]["notification_status"]
          template_code: string | null
          tenant_id: string
          title_en: string
          title_fa: string
          version: number
        }
        Insert: {
          action_url?: string | null
          archived_at?: string | null
          body_en?: string | null
          body_fa?: string | null
          category: Database["notify"]["Enums"]["notification_category"]
          created_at?: string
          deleted_at?: string | null
          dismissed_at?: string | null
          id?: string
          organization_id?: string | null
          payload?: Json
          priority?: Database["notify"]["Enums"]["notification_priority"]
          read_at?: string | null
          read_by?: string | null
          recipient_party?: string | null
          recipient_role_hint?: string | null
          recipient_user_id: string
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_event_id?: string | null
          source_event_type?: string | null
          status?: Database["notify"]["Enums"]["notification_status"]
          template_code?: string | null
          tenant_id: string
          title_en: string
          title_fa: string
          version?: number
        }
        Update: {
          action_url?: string | null
          archived_at?: string | null
          body_en?: string | null
          body_fa?: string | null
          category?: Database["notify"]["Enums"]["notification_category"]
          created_at?: string
          deleted_at?: string | null
          dismissed_at?: string | null
          id?: string
          organization_id?: string | null
          payload?: Json
          priority?: Database["notify"]["Enums"]["notification_priority"]
          read_at?: string | null
          read_by?: string | null
          recipient_party?: string | null
          recipient_role_hint?: string | null
          recipient_user_id?: string
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_event_id?: string | null
          source_event_type?: string | null
          status?: Database["notify"]["Enums"]["notification_status"]
          template_code?: string | null
          tenant_id?: string
          title_en?: string
          title_fa?: string
          version?: number
        }
        Relationships: []
      }
      user_preferences: {
        Row: {
          category: Database["notify"]["Enums"]["notification_category"]
          channel: Database["notify"]["Enums"]["channel_type"]
          created_at: string
          deleted_at: string | null
          enabled: boolean
          id: string
          metadata: Json
          organization_id: string | null
          quiet_hours_end: string | null
          quiet_hours_start: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          user_id: string
          version: number
        }
        Insert: {
          category: Database["notify"]["Enums"]["notification_category"]
          channel: Database["notify"]["Enums"]["channel_type"]
          created_at?: string
          deleted_at?: string | null
          enabled?: boolean
          id?: string
          metadata?: Json
          organization_id?: string | null
          quiet_hours_end?: string | null
          quiet_hours_start?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          user_id: string
          version?: number
        }
        Update: {
          category?: Database["notify"]["Enums"]["notification_category"]
          channel?: Database["notify"]["Enums"]["channel_type"]
          created_at?: string
          deleted_at?: string | null
          enabled?: boolean
          id?: string
          metadata?: Json
          organization_id?: string | null
          quiet_hours_end?: string | null
          quiet_hours_start?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string
          version?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_list_delivery_attempts: {
        Args: {
          p_channel?: Database["notify"]["Enums"]["channel_type"]
          p_limit?: number
          p_notification_id?: string
          p_offset?: number
          p_status?: Database["notify"]["Enums"]["delivery_status"]
        }
        Returns: {
          attempted_at: string
          channel: string
          created_at: string
          delivered_at: string
          failure_reason: string
          id: string
          notification_id: string
          status: string
        }[]
      }
      admin_list_notifications: {
        Args: {
          p_category?: Database["notify"]["Enums"]["notification_category"]
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_recipient_user_id?: string
        }
        Returns: {
          category: string
          created_at: string
          id: string
          organization_id: string
          recipient_user_id: string
          source_event_type: string
          status: string
          title_en: string
        }[]
      }
      admin_list_templates: {
        Args: {
          p_category?: Database["notify"]["Enums"]["notification_category"]
          p_status?: Database["notify"]["Enums"]["template_status"]
        }
        Returns: {
          category: string
          default_priority: string
          id: string
          organization_id: string
          status: string
          template_code: string
          title_en: string
        }[]
      }
      admin_upsert_template: {
        Args: {
          p_action_url_template?: string
          p_body_en: string
          p_body_fa: string
          p_category: Database["notify"]["Enums"]["notification_category"]
          p_default_channels?: Database["notify"]["Enums"]["channel_type"][]
          p_default_priority?: Database["notify"]["Enums"]["notification_priority"]
          p_event_type_filter?: string
          p_organization_id?: string
          p_template_code: string
          p_tenant_id?: string
          p_title_en: string
          p_title_fa: string
        }
        Returns: string
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_notification_id: string
          p_payload?: Json
        }
        Returns: undefined
      }
      fn_materialize_event: {
        Args: {
          p_category: Database["notify"]["Enums"]["notification_category"]
          p_payload: Json
          p_source_entity_id: string
          p_source_entity_type: string
          p_source_event_id: string
          p_source_event_type: string
          p_tenant_id: string
        }
        Returns: undefined
      }
      fn_resolve_recipients: {
        Args: {
          p_category: Database["notify"]["Enums"]["notification_category"]
          p_entity_id: string
          p_entity_type: string
        }
        Returns: {
          organization_id: string
          recipient_party: string
          recipient_role_hint: string
          recipient_user_id: string
        }[]
      }
      fn_resolve_template: {
        Args: {
          p_category: Database["notify"]["Enums"]["notification_category"]
          p_template_code: string
          p_tenant_id: string
        }
        Returns: {
          action_url_template: string | null
          body_en: string
          body_fa: string
          category: Database["notify"]["Enums"]["notification_category"]
          created_at: string
          created_by: string | null
          default_channels: Database["notify"]["Enums"]["channel_type"][]
          default_priority: Database["notify"]["Enums"]["notification_priority"]
          deleted_at: string | null
          event_type_filter: string | null
          id: string
          metadata: Json
          organization_id: string | null
          status: Database["notify"]["Enums"]["template_status"]
          template_code: string
          tenant_id: string | null
          title_en: string
          title_fa: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "notification_templates"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_substitute_action_url: {
        Args: { p_entity_id: string; p_template: string }
        Returns: string
      }
      portal_archive_notification: {
        Args: { p_notification_id: string }
        Returns: undefined
      }
      portal_get_notification: {
        Args: { p_notification_id: string }
        Returns: Json
      }
      portal_list_my_notifications: {
        Args: {
          p_category?: Database["notify"]["Enums"]["notification_category"]
          p_limit?: number
          p_offset?: number
          p_status?: Database["notify"]["Enums"]["notification_status"]
        }
        Returns: {
          action_url: string
          body_en: string
          body_fa: string
          category: string
          created_at: string
          id: string
          priority: string
          read_at: string
          source_entity_id: string
          source_entity_type: string
          source_event_type: string
          status: string
          title_en: string
          title_fa: string
        }[]
      }
      portal_mark_all_read: {
        Args: {
          p_category?: Database["notify"]["Enums"]["notification_category"]
        }
        Returns: number
      }
      portal_mark_read: {
        Args: { p_notification_id: string }
        Returns: undefined
      }
      portal_unread_count: {
        Args: {
          p_category?: Database["notify"]["Enums"]["notification_category"]
        }
        Returns: number
      }
      portal_upsert_preferences: {
        Args: {
          p_category: Database["notify"]["Enums"]["notification_category"]
          p_channel: Database["notify"]["Enums"]["channel_type"]
          p_enabled: boolean
          p_organization_id?: string
          p_quiet_hours_end?: string
          p_quiet_hours_start?: string
        }
        Returns: string
      }
    }
    Enums: {
      channel_type: "in_app" | "email" | "sms" | "push" | "webhook"
      delivery_status:
        | "pending"
        | "sent"
        | "delivered"
        | "failed"
        | "skipped"
        | "suppressed"
      notification_category:
        | "rfq"
        | "offer"
        | "evaluation"
        | "contract"
        | "shipment"
        | "finance"
        | "settlement"
        | "dispute"
        | "supplier_admin"
        | "platform"
        | "other"
      notification_priority: "low" | "normal" | "high" | "urgent"
      notification_status: "unread" | "read" | "archived" | "dismissed"
      template_status: "draft" | "active" | "deprecated"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  offer: {
    Tables: {
      supplier_offer_document_commitments: {
        Row: {
          commitment_status: Database["offer"]["Enums"]["commitment_status"]
          created_at: string
          created_by: string | null
          deleted_at: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          expected_available_date: string | null
          id: string
          metadata: Json
          notes: string | null
          offer_id: string
          offer_item_id: string | null
          organization_id: string
          request_doc_req_id: string | null
          supplier_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          commitment_status?: Database["offer"]["Enums"]["commitment_status"]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          expected_available_date?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_id: string
          offer_item_id?: string | null
          organization_id: string
          request_doc_req_id?: string | null
          supplier_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          commitment_status?: Database["offer"]["Enums"]["commitment_status"]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind?: Database["commodity"]["Enums"]["document_kind"]
          expected_available_date?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_id?: string
          offer_item_id?: string | null
          organization_id?: string
          request_doc_req_id?: string | null
          supplier_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_offer_document_commitments_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "supplier_offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supplier_offer_document_commitments_offer_item_id_fkey"
            columns: ["offer_item_id"]
            isOneToOne: false
            referencedRelation: "supplier_offer_items"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_offer_item_specifications: {
        Row: {
          compliance_status: Database["offer"]["Enums"]["compliance_status"]
          created_at: string
          created_by: string | null
          data_type: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at: string | null
          deviation_text: string | null
          display_name_en: string | null
          display_name_fa: string | null
          id: string
          max_value: number | null
          min_value: number | null
          notes: string | null
          offer_id: string
          offer_item_id: string
          offered_value: string | null
          organization_id: string
          request_item_spec_id: string | null
          sort_order: number
          spec_key: string
          supplier_id: string
          tenant_id: string
          unit: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          compliance_status?: Database["offer"]["Enums"]["compliance_status"]
          created_at?: string
          created_by?: string | null
          data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at?: string | null
          deviation_text?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          id?: string
          max_value?: number | null
          min_value?: number | null
          notes?: string | null
          offer_id: string
          offer_item_id: string
          offered_value?: string | null
          organization_id: string
          request_item_spec_id?: string | null
          sort_order?: number
          spec_key: string
          supplier_id: string
          tenant_id: string
          unit?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          compliance_status?: Database["offer"]["Enums"]["compliance_status"]
          created_at?: string
          created_by?: string | null
          data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at?: string | null
          deviation_text?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          id?: string
          max_value?: number | null
          min_value?: number | null
          notes?: string | null
          offer_id?: string
          offer_item_id?: string
          offered_value?: string | null
          organization_id?: string
          request_item_spec_id?: string | null
          sort_order?: number
          spec_key?: string
          supplier_id?: string
          tenant_id?: string
          unit?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_offer_item_specifications_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "supplier_offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supplier_offer_item_specifications_offer_item_id_fkey"
            columns: ["offer_item_id"]
            isOneToOne: false
            referencedRelation: "supplier_offer_items"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_offer_items: {
        Row: {
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          delivery_lead_time_text: string | null
          delivery_window_end: string | null
          delivery_window_start: string | null
          id: string
          metadata: Json
          notes: string | null
          offer_id: string
          offered_quantity: number | null
          organization_id: string
          origin_city: string | null
          origin_country: string | null
          packaging: string | null
          product_id: string
          quantity_unit: string | null
          request_item_id: string
          sort_order: number
          supplier_id: string
          tenant_id: string
          total_price: number | null
          unit_price: number | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_id: string
          offered_quantity?: number | null
          organization_id: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          product_id: string
          quantity_unit?: string | null
          request_item_id: string
          sort_order?: number
          supplier_id: string
          tenant_id: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          delivery_lead_time_text?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          offer_id?: string
          offered_quantity?: number | null
          organization_id?: string
          origin_city?: string | null
          origin_country?: string | null
          packaging?: string | null
          product_id?: string
          quantity_unit?: string | null
          request_item_id?: string
          sort_order?: number
          supplier_id?: string
          tenant_id?: string
          total_price?: number | null
          unit_price?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_offer_items_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "supplier_offers"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_offer_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          from_status: Database["offer"]["Enums"]["offer_status"] | null
          id: string
          offer_id: string
          organization_id: string
          payload: Json
          reason: string | null
          tenant_id: string
          to_status: Database["offer"]["Enums"]["offer_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["offer"]["Enums"]["offer_status"] | null
          id?: string
          offer_id: string
          organization_id: string
          payload?: Json
          reason?: string | null
          tenant_id: string
          to_status: Database["offer"]["Enums"]["offer_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["offer"]["Enums"]["offer_status"] | null
          id?: string
          offer_id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
          to_status?: Database["offer"]["Enums"]["offer_status"]
        }
        Relationships: [
          {
            foreignKeyName: "supplier_offer_status_events_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "supplier_offers"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_offers: {
        Row: {
          accepted_at: string | null
          accepted_by: string | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          delivery_city: string | null
          delivery_country: string | null
          delivery_lead_time_text: string | null
          delivery_location_text: string | null
          delivery_port: string | null
          id: string
          incoterm: string | null
          metadata: Json
          offer_code: string
          organization_id: string
          payment_terms_text: string | null
          rejected_at: string | null
          rejected_by: string | null
          rejected_reason: string | null
          request_id: string
          shortlisted_at: string | null
          shortlisted_by: string | null
          status: Database["offer"]["Enums"]["offer_status"]
          submitted_at: string | null
          submitted_by: string | null
          supplier_id: string
          supplier_notes: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          validity_until: string | null
          version: number
          withdrawn_at: string | null
          withdrawn_by: string | null
          withdrawn_reason: string | null
        }
        Insert: {
          accepted_at?: string | null
          accepted_by?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_lead_time_text?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          id?: string
          incoterm?: string | null
          metadata?: Json
          offer_code: string
          organization_id: string
          payment_terms_text?: string | null
          rejected_at?: string | null
          rejected_by?: string | null
          rejected_reason?: string | null
          request_id: string
          shortlisted_at?: string | null
          shortlisted_by?: string | null
          status?: Database["offer"]["Enums"]["offer_status"]
          submitted_at?: string | null
          submitted_by?: string | null
          supplier_id: string
          supplier_notes?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          validity_until?: string | null
          version?: number
          withdrawn_at?: string | null
          withdrawn_by?: string | null
          withdrawn_reason?: string | null
        }
        Update: {
          accepted_at?: string | null
          accepted_by?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_lead_time_text?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          id?: string
          incoterm?: string | null
          metadata?: Json
          offer_code?: string
          organization_id?: string
          payment_terms_text?: string | null
          rejected_at?: string | null
          rejected_by?: string | null
          rejected_reason?: string | null
          request_id?: string
          shortlisted_at?: string | null
          shortlisted_by?: string | null
          status?: Database["offer"]["Enums"]["offer_status"]
          submitted_at?: string | null
          submitted_by?: string | null
          supplier_id?: string
          supplier_notes?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          validity_until?: string | null
          version?: number
          withdrawn_at?: string | null
          withdrawn_by?: string | null
          withdrawn_reason?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_force_status_change: {
        Args: {
          p_offer_id: string
          p_reason?: string
          p_status: Database["offer"]["Enums"]["offer_status"]
        }
        Returns: undefined
      }
      admin_get_offer: { Args: { p_offer_id: string }; Returns: Json }
      admin_list_offer_status_events: {
        Args: { p_offer_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_offers: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["offer"]["Enums"]["offer_status"]
          p_supplier_id?: string
        }
        Returns: {
          created_at: string
          currency: string
          id: string
          offer_code: string
          organization_id: string
          request_id: string
          status: string
          submitted_at: string
          supplier_id: string
        }[]
      }
      buyer_get_offer: { Args: { p_offer_id: string }; Returns: Json }
      buyer_list_received_offers: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["offer"]["Enums"]["offer_status"]
        }
        Returns: {
          currency: string
          id: string
          item_count: number
          offer_code: string
          request_id: string
          rfq_code: string
          rfq_title: string
          status: string
          submitted_at: string
          supplier_id: string
          supplier_org_id: string
          updated_at: string
          validity_until: string
        }[]
      }
      fn_assert_offer_editable: {
        Args: { p_offer_id: string }
        Returns: undefined
      }
      fn_assert_offer_supplier_owned: {
        Args: { p_offer_id: string }
        Returns: undefined
      }
      fn_assert_supplier_invited_to_rfq: {
        Args: { p_request_id: string; p_supplier_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: { p_action_code: string; p_offer_id: string; p_payload?: Json }
        Returns: undefined
      }
      fn_record_status_event: {
        Args: {
          p_from: Database["offer"]["Enums"]["offer_status"]
          p_offer_id: string
          p_payload?: Json
          p_reason?: string
          p_to: Database["offer"]["Enums"]["offer_status"]
        }
        Returns: undefined
      }
      supplier_create_draft_offer: {
        Args: {
          p_currency?: string
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_lead_time_text?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_incoterm?: string
          p_payment_terms_text?: string
          p_request_id: string
          p_supplier_notes?: string
          p_validity_until?: string
        }
        Returns: string
      }
      supplier_get_my_offer: { Args: { p_offer_id: string }; Returns: Json }
      supplier_list_my_offers: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["offer"]["Enums"]["offer_status"]
        }
        Returns: {
          currency: string
          id: string
          item_count: number
          offer_code: string
          request_id: string
          rfq_code: string
          rfq_title: string
          status: string
          submitted_at: string
          updated_at: string
          validity_until: string
        }[]
      }
      supplier_remove_doc_commitment: {
        Args: { p_commitment_id: string }
        Returns: undefined
      }
      supplier_remove_offer_item: {
        Args: { p_offer_item_id: string }
        Returns: undefined
      }
      supplier_remove_spec_response: {
        Args: { p_response_id: string }
        Returns: undefined
      }
      supplier_submit_my_offer: {
        Args: { p_offer_id: string }
        Returns: undefined
      }
      supplier_update_my_offer: {
        Args: {
          p_currency?: string
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_lead_time_text?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_incoterm?: string
          p_offer_id: string
          p_payment_terms_text?: string
          p_supplier_notes?: string
          p_validity_until?: string
        }
        Returns: undefined
      }
      supplier_upsert_doc_commitment: {
        Args: {
          p_commitment_status?: Database["offer"]["Enums"]["commitment_status"]
          p_document_kind?: Database["commodity"]["Enums"]["document_kind"]
          p_expected_available_date?: string
          p_notes?: string
          p_offer_id: string
          p_offer_item_id?: string
          p_request_doc_req_id?: string
        }
        Returns: string
      }
      supplier_upsert_offer_item: {
        Args: {
          p_currency?: string
          p_delivery_lead_time_text?: string
          p_delivery_window_end?: string
          p_delivery_window_start?: string
          p_notes?: string
          p_offer_id: string
          p_offer_item_id?: string
          p_offered_quantity?: number
          p_origin_city?: string
          p_origin_country?: string
          p_packaging?: string
          p_quantity_unit?: string
          p_request_item_id?: string
          p_sort_order?: number
          p_total_price?: number
          p_unit_price?: number
        }
        Returns: string
      }
      supplier_upsert_spec_response: {
        Args: {
          p_compliance_status?: Database["offer"]["Enums"]["compliance_status"]
          p_data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          p_deviation_text?: string
          p_display_name_en?: string
          p_display_name_fa?: string
          p_max_value?: number
          p_min_value?: number
          p_notes?: string
          p_offer_item_id: string
          p_offered_value?: string
          p_request_item_spec_id?: string
          p_sort_order?: number
          p_spec_key: string
          p_unit?: string
        }
        Returns: string
      }
      supplier_withdraw_my_offer: {
        Args: { p_offer_id: string; p_reason?: string }
        Returns: undefined
      }
    }
    Enums: {
      commitment_status:
        | "committed"
        | "with_caveat"
        | "cannot_provide"
        | "conditional"
      compliance_status:
        | "compliant"
        | "deviation"
        | "not_applicable"
        | "pending"
      offer_status:
        | "draft"
        | "submitted"
        | "withdrawn"
        | "expired"
        | "rejected"
        | "shortlisted"
        | "accepted"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  organization: {
    Tables: {
      business_units: {
        Row: {
          code: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          name_en: string
          name_fa: string
          organization_id: string
          parent_business_unit_id: string | null
          status: Database["organization"]["Enums"]["business_unit_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          code: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          name_en: string
          name_fa: string
          organization_id: string
          parent_business_unit_id?: string | null
          status?: Database["organization"]["Enums"]["business_unit_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          name_en?: string
          name_fa?: string
          organization_id?: string
          parent_business_unit_id?: string | null
          status?: Database["organization"]["Enums"]["business_unit_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "business_units_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_units_parent_business_unit_id_fkey"
            columns: ["parent_business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
        ]
      }
      memberships: {
        Row: {
          business_unit_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          joined_at: string | null
          organization_id: string
          role_id: string
          status: Database["organization"]["Enums"]["membership_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          user_id: string
          version: number
        }
        Insert: {
          business_unit_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          joined_at?: string | null
          organization_id: string
          role_id: string
          status?: Database["organization"]["Enums"]["membership_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          user_id: string
          version?: number
        }
        Update: {
          business_unit_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          joined_at?: string | null
          organization_id?: string
          role_id?: string
          status?: Database["organization"]["Enums"]["membership_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "memberships_business_unit_id_fkey"
            columns: ["business_unit_id"]
            isOneToOne: false
            referencedRelation: "business_units"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "memberships_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      organizations: {
        Row: {
          code: string
          country_code: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          legal_name: string | null
          name_en: string
          name_fa: string
          parent_organization_id: string | null
          registration_number: string | null
          status: Database["organization"]["Enums"]["organization_status"]
          tax_id: string | null
          tenant_id: string
          type: Database["organization"]["Enums"]["organization_type"]
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          code: string
          country_code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          legal_name?: string | null
          name_en: string
          name_fa: string
          parent_organization_id?: string | null
          registration_number?: string | null
          status?: Database["organization"]["Enums"]["organization_status"]
          tax_id?: string | null
          tenant_id: string
          type: Database["organization"]["Enums"]["organization_type"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          code?: string
          country_code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          legal_name?: string | null
          name_en?: string
          name_fa?: string
          parent_organization_id?: string | null
          registration_number?: string | null
          status?: Database["organization"]["Enums"]["organization_status"]
          tax_id?: string | null
          tenant_id?: string
          type?: Database["organization"]["Enums"]["organization_type"]
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "organizations_parent_organization_id_fkey"
            columns: ["parent_organization_id"]
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
      [_ in never]: never
    }
    Enums: {
      business_unit_status: "active" | "suspended" | "closed"
      membership_status: "active" | "invited" | "suspended" | "revoked"
      organization_status: "active" | "pending" | "suspended" | "closed"
      organization_type:
        | "buyer"
        | "supplier"
        | "carrier"
        | "broker"
        | "government"
        | "platform"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  pricing: {
    Tables: {
      currencies: {
        Row: {
          code: string
          created_at: string
          is_active: boolean
          minor_unit_digits: number
          name_en: string
          name_fa: string
          numeric_code: number | null
        }
        Insert: {
          code: string
          created_at?: string
          is_active?: boolean
          minor_unit_digits?: number
          name_en: string
          name_fa: string
          numeric_code?: number | null
        }
        Update: {
          code?: string
          created_at?: string
          is_active?: boolean
          minor_unit_digits?: number
          name_en?: string
          name_fa?: string
          numeric_code?: number | null
        }
        Relationships: []
      }
      currency_rates: {
        Row: {
          base_code: string
          created_at: string
          created_by: string | null
          effective_from: string
          effective_to: string | null
          id: string
          quote_code: string
          rate: number
          source: string
        }
        Insert: {
          base_code: string
          created_at?: string
          created_by?: string | null
          effective_from: string
          effective_to?: string | null
          id?: string
          quote_code: string
          rate: number
          source?: string
        }
        Update: {
          base_code?: string
          created_at?: string
          created_by?: string | null
          effective_from?: string
          effective_to?: string | null
          id?: string
          quote_code?: string
          rate?: number
          source?: string
        }
        Relationships: [
          {
            foreignKeyName: "currency_rates_base_code_fkey"
            columns: ["base_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "currency_rates_quote_code_fkey"
            columns: ["quote_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      discount_rules: {
        Row: {
          active: boolean
          amount: number | null
          application: Database["pricing"]["Enums"]["discount_application"]
          code: string
          created_at: string
          created_by: string | null
          currency_code: string | null
          deleted_at: string | null
          effective_from: string | null
          effective_to: string | null
          id: string
          kind: Database["pricing"]["Enums"]["discount_kind"]
          metadata: Json
          name_en: string
          name_fa: string
          supplier_id: string
          tenant_id: string
          threshold_qty: number | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          active?: boolean
          amount?: number | null
          application: Database["pricing"]["Enums"]["discount_application"]
          code: string
          created_at?: string
          created_by?: string | null
          currency_code?: string | null
          deleted_at?: string | null
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          kind: Database["pricing"]["Enums"]["discount_kind"]
          metadata?: Json
          name_en: string
          name_fa: string
          supplier_id: string
          tenant_id: string
          threshold_qty?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          active?: boolean
          amount?: number | null
          application?: Database["pricing"]["Enums"]["discount_application"]
          code?: string
          created_at?: string
          created_by?: string | null
          currency_code?: string | null
          deleted_at?: string | null
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          kind?: Database["pricing"]["Enums"]["discount_kind"]
          metadata?: Json
          name_en?: string
          name_fa?: string
          supplier_id?: string
          tenant_id?: string
          threshold_qty?: number | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "discount_rules_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      events: {
        Row: {
          actor_user_id: string | null
          discount_rule_id: string | null
          event_kind: Database["pricing"]["Enums"]["pricing_event_kind"]
          id: string
          occurred_at: string
          payload: Json
          price_list_id: string | null
          quotation_id: string | null
          tenant_id: string
        }
        Insert: {
          actor_user_id?: string | null
          discount_rule_id?: string | null
          event_kind: Database["pricing"]["Enums"]["pricing_event_kind"]
          id?: string
          occurred_at?: string
          payload?: Json
          price_list_id?: string | null
          quotation_id?: string | null
          tenant_id: string
        }
        Update: {
          actor_user_id?: string | null
          discount_rule_id?: string | null
          event_kind?: Database["pricing"]["Enums"]["pricing_event_kind"]
          id?: string
          occurred_at?: string
          payload?: Json
          price_list_id?: string | null
          quotation_id?: string | null
          tenant_id?: string
        }
        Relationships: []
      }
      price_list_items: {
        Row: {
          created_at: string
          id: string
          max_order_quantity: number | null
          min_order_quantity: number | null
          notes: string | null
          price_list_id: string
          product_id: string
          tenant_id: string
          unit_of_measure: string
          unit_price: number
          updated_at: string
          version: number
        }
        Insert: {
          created_at?: string
          id?: string
          max_order_quantity?: number | null
          min_order_quantity?: number | null
          notes?: string | null
          price_list_id: string
          product_id: string
          tenant_id: string
          unit_of_measure: string
          unit_price: number
          updated_at?: string
          version?: number
        }
        Update: {
          created_at?: string
          id?: string
          max_order_quantity?: number | null
          min_order_quantity?: number | null
          notes?: string | null
          price_list_id?: string
          product_id?: string
          tenant_id?: string
          unit_of_measure?: string
          unit_price?: number
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "price_list_items_price_list_id_fkey"
            columns: ["price_list_id"]
            isOneToOne: false
            referencedRelation: "price_lists"
            referencedColumns: ["id"]
          },
        ]
      }
      price_lists: {
        Row: {
          code: string
          created_at: string
          created_by: string | null
          currency_code: string
          deleted_at: string | null
          description: string | null
          effective_from: string | null
          effective_to: string | null
          id: string
          metadata: Json
          name_en: string
          name_fa: string
          organization_id: string
          status: Database["pricing"]["Enums"]["price_list_status"]
          supplier_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          code: string
          created_at?: string
          created_by?: string | null
          currency_code: string
          deleted_at?: string | null
          description?: string | null
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          metadata?: Json
          name_en: string
          name_fa: string
          organization_id: string
          status?: Database["pricing"]["Enums"]["price_list_status"]
          supplier_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string | null
          currency_code?: string
          deleted_at?: string | null
          description?: string | null
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          metadata?: Json
          name_en?: string
          name_fa?: string
          organization_id?: string
          status?: Database["pricing"]["Enums"]["price_list_status"]
          supplier_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "price_lists_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      quotation_items: {
        Row: {
          created_at: string
          discount_amount: number
          id: string
          line_total: number
          notes: string | null
          position: number
          product_id: string
          quantity: number
          quotation_id: string
          tenant_id: string
          unit_of_measure: string
          unit_price: number
        }
        Insert: {
          created_at?: string
          discount_amount?: number
          id?: string
          line_total: number
          notes?: string | null
          position?: number
          product_id: string
          quantity: number
          quotation_id: string
          tenant_id: string
          unit_of_measure: string
          unit_price: number
        }
        Update: {
          created_at?: string
          discount_amount?: number
          id?: string
          line_total?: number
          notes?: string | null
          position?: number
          product_id?: string
          quantity?: number
          quotation_id?: string
          tenant_id?: string
          unit_of_measure?: string
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "quotation_items_quotation_id_fkey"
            columns: ["quotation_id"]
            isOneToOne: false
            referencedRelation: "quotations"
            referencedColumns: ["id"]
          },
        ]
      }
      quotations: {
        Row: {
          buyer_organization_id: string
          created_at: string
          created_by: string | null
          currency_code: string
          decision_reason: string | null
          deleted_at: string | null
          discount_amount: number
          id: string
          metadata: Json
          notes_en: string | null
          notes_fa: string | null
          quotation_code: string
          responded_at: string | null
          response_actor_user_id: string | null
          rfq_request_id: string | null
          sent_at: string | null
          status: Database["pricing"]["Enums"]["quotation_status"]
          subtotal_amount: number
          supplier_id: string
          supplier_organization_id: string
          tenant_id: string
          total_amount: number
          updated_at: string
          updated_by: string | null
          valid_from: string | null
          valid_until: string | null
          version: number
        }
        Insert: {
          buyer_organization_id: string
          created_at?: string
          created_by?: string | null
          currency_code: string
          decision_reason?: string | null
          deleted_at?: string | null
          discount_amount?: number
          id?: string
          metadata?: Json
          notes_en?: string | null
          notes_fa?: string | null
          quotation_code: string
          responded_at?: string | null
          response_actor_user_id?: string | null
          rfq_request_id?: string | null
          sent_at?: string | null
          status?: Database["pricing"]["Enums"]["quotation_status"]
          subtotal_amount?: number
          supplier_id: string
          supplier_organization_id: string
          tenant_id: string
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          valid_from?: string | null
          valid_until?: string | null
          version?: number
        }
        Update: {
          buyer_organization_id?: string
          created_at?: string
          created_by?: string | null
          currency_code?: string
          decision_reason?: string | null
          deleted_at?: string | null
          discount_amount?: number
          id?: string
          metadata?: Json
          notes_en?: string | null
          notes_fa?: string | null
          quotation_code?: string
          responded_at?: string | null
          response_actor_user_id?: string | null
          rfq_request_id?: string | null
          sent_at?: string | null
          status?: Database["pricing"]["Enums"]["quotation_status"]
          subtotal_amount?: number
          supplier_id?: string
          supplier_organization_id?: string
          tenant_id?: string
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          valid_from?: string | null
          valid_until?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "quotations_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
        ]
      }
      quote_captures: {
        Row: {
          buyer_organization_id: string
          captured_at: string
          captured_by: string | null
          currency_code: string
          id: string
          kind: Database["pricing"]["Enums"]["quote_capture_kind"]
          snapshot: Json
          source_executed_contract_id: string | null
          source_quotation_id: string | null
          source_supplier_offer_id: string | null
          supplier_id: string
          supplier_organization_id: string
          tenant_id: string
        }
        Insert: {
          buyer_organization_id: string
          captured_at?: string
          captured_by?: string | null
          currency_code: string
          id?: string
          kind: Database["pricing"]["Enums"]["quote_capture_kind"]
          snapshot: Json
          source_executed_contract_id?: string | null
          source_quotation_id?: string | null
          source_supplier_offer_id?: string | null
          supplier_id: string
          supplier_organization_id: string
          tenant_id: string
        }
        Update: {
          buyer_organization_id?: string
          captured_at?: string
          captured_by?: string | null
          currency_code?: string
          id?: string
          kind?: Database["pricing"]["Enums"]["quote_capture_kind"]
          snapshot?: Json
          source_executed_contract_id?: string | null
          source_quotation_id?: string | null
          source_supplier_offer_id?: string | null
          supplier_id?: string
          supplier_organization_id?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quote_captures_currency_code_fkey"
            columns: ["currency_code"]
            isOneToOne: false
            referencedRelation: "currencies"
            referencedColumns: ["code"]
          },
          {
            foreignKeyName: "quote_captures_source_quotation_id_fkey"
            columns: ["source_quotation_id"]
            isOneToOne: false
            referencedRelation: "quotations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_capture_quote: {
        Args: {
          p_buyer_organization_id: string
          p_currency_code: string
          p_kind: Database["pricing"]["Enums"]["quote_capture_kind"]
          p_snapshot: Json
          p_source_executed_contract_id?: string
          p_source_quotation_id?: string
          p_source_supplier_offer_id?: string
          p_supplier_id: string
        }
        Returns: string
      }
      admin_expire_due_quotations: { Args: never; Returns: number }
      admin_list_price_lists: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["pricing"]["Enums"]["price_list_status"]
          p_supplier_id?: string
        }
        Returns: {
          code: string
          created_at: string
          currency_code: string
          effective_from: string
          id: string
          name_en: string
          organization_id: string
          status: string
          supplier_id: string
          tenant_id: string
        }[]
      }
      admin_list_quotations: {
        Args: {
          p_buyer_organization_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["pricing"]["Enums"]["quotation_status"]
          p_supplier_id?: string
        }
        Returns: {
          buyer_organization_id: string
          created_at: string
          currency_code: string
          id: string
          quotation_code: string
          sent_at: string
          status: string
          supplier_id: string
          tenant_id: string
          total_amount: number
          valid_until: string
        }[]
      }
      admin_set_currency_rate: {
        Args: {
          p_base_code: string
          p_effective_from?: string
          p_effective_to?: string
          p_quote_code: string
          p_rate: number
          p_source?: string
        }
        Returns: string
      }
      compute_quote_totals: {
        Args: { p_quotation_id: string }
        Returns: undefined
      }
      convert_amount: {
        Args: {
          p_amount: number
          p_as_of?: string
          p_from_code: string
          p_to_code: string
        }
        Returns: number
      }
      fn_assert_admin: { Args: never; Returns: undefined }
      fn_assert_buyer_member: {
        Args: { p_organization_id: string }
        Returns: undefined
      }
      fn_assert_supplier_member: {
        Args: { p_supplier_id: string }
        Returns: Database["supplier"]["Tables"]["suppliers"]["Row"]
        SetofOptions: {
          from: "*"
          to: "suppliers"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_resource_id: string
          p_tenant_id: string
        }
        Returns: undefined
      }
      fn_record_event: {
        Args: {
          p_discount_rule_id: string
          p_event_kind: Database["pricing"]["Enums"]["pricing_event_kind"]
          p_payload?: Json
          p_price_list_id: string
          p_quotation_id: string
          p_tenant_id: string
        }
        Returns: string
      }
      get_active_unit_price: {
        Args: {
          p_as_of?: string
          p_currency_code: string
          p_product_id: string
          p_supplier_id: string
        }
        Returns: number
      }
      get_my_price_lists: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["pricing"]["Enums"]["price_list_status"]
        }
        Returns: {
          code: string
          created_at: string
          currency_code: string
          effective_from: string
          effective_to: string
          id: string
          name_en: string
          name_fa: string
          organization_id: string
          status: string
          supplier_id: string
        }[]
      }
      get_quotation: { Args: { p_id: string }; Returns: Json }
      list_currency_rates: {
        Args: { p_as_of?: string; p_base_code?: string; p_quote_code?: string }
        Returns: {
          base_code: string
          created_at: string
          effective_from: string
          effective_to: string
          id: string
          quote_code: string
          rate: number
          source: string
        }[]
      }
      portal_accept_quotation: { Args: { p_id: string }; Returns: undefined }
      portal_add_quotation_item: {
        Args: {
          p_discount_amount?: number
          p_notes?: string
          p_position?: number
          p_product_id: string
          p_quantity: number
          p_quotation_id: string
          p_unit_price: number
          p_uom: string
        }
        Returns: string
      }
      portal_archive_price_list: {
        Args: { p_id: string; p_reason?: string }
        Returns: undefined
      }
      portal_create_price_list: {
        Args: {
          p_code: string
          p_currency_code: string
          p_description?: string
          p_name_en: string
          p_name_fa: string
          p_supplier_id: string
        }
        Returns: string
      }
      portal_create_quotation: {
        Args: {
          p_buyer_organization_id: string
          p_currency_code: string
          p_quotation_code: string
          p_rfq_request_id?: string
          p_supplier_id: string
          p_valid_until?: string
        }
        Returns: string
      }
      portal_list_my_quotations: {
        Args: {
          p_buyer_organization_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["pricing"]["Enums"]["quotation_status"]
        }
        Returns: {
          buyer_organization_id: string
          created_at: string
          currency_code: string
          id: string
          quotation_code: string
          sent_at: string
          status: string
          supplier_id: string
          total_amount: number
          valid_until: string
        }[]
      }
      portal_pause_price_list: {
        Args: { p_id: string; p_reason?: string }
        Returns: undefined
      }
      portal_publish_price_list: {
        Args: { p_effective_from?: string; p_id: string }
        Returns: undefined
      }
      portal_reject_quotation: {
        Args: { p_id: string; p_reason?: string }
        Returns: undefined
      }
      portal_send_quotation: { Args: { p_id: string }; Returns: undefined }
      portal_upsert_price_list_item: {
        Args: {
          p_max_qty?: number
          p_min_qty?: number
          p_notes?: string
          p_price_list_id: string
          p_product_id: string
          p_unit_price: number
          p_uom: string
        }
        Returns: string
      }
    }
    Enums: {
      discount_application:
        | "percent_off"
        | "fixed_amount_off"
        | "unit_price_override"
      discount_kind: "volume_tier" | "contract_term" | "manual"
      price_list_status: "draft" | "active" | "paused" | "archived"
      pricing_event_kind:
        | "price_list_created"
        | "price_list_published"
        | "price_list_paused"
        | "price_list_archived"
        | "price_list_item_updated"
        | "quotation_drafted"
        | "quotation_sent"
        | "quotation_accepted"
        | "quotation_rejected"
        | "quotation_expired"
        | "quotation_withdrawn"
        | "quote_captured"
        | "currency_rate_set"
        | "discount_rule_published"
      quotation_status:
        | "draft"
        | "sent"
        | "accepted"
        | "rejected"
        | "expired"
        | "withdrawn"
      quote_capture_kind:
        | "offer_submission"
        | "contract_execution"
        | "manual_audit"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      control_tower_admin_activity: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          actor_party: string
          created_at: string
          event_id: string
          from_status: string
          organization_id: string
          source_domain: string
          source_event: string
          subject_id: string
          to_status: string
        }[]
      }
      control_tower_admin_exceptions: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          age_hours: number
          category: string
          created_at: string
          detail_href: string
          organization_id: string
          severity: string
          subject_code: string
          subject_id: string
          subject_type: string
        }[]
      }
      control_tower_admin_summary: { Args: never; Returns: Json }
      control_tower_buyer_summary: { Args: never; Returns: Json }
      control_tower_carrier_summary: { Args: never; Returns: Json }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  rfq: {
    Tables: {
      request_document_requirements: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          display_name_en: string | null
          display_name_fa: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          id: string
          is_active: boolean
          notes: string | null
          organization_id: string
          request_id: string
          request_item_id: string | null
          requirement_level: Database["commodity"]["Enums"]["document_requirement_level"]
          scope: Database["rfq"]["Enums"]["document_scope"]
          sort_order: number
          source_doc_req_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind: Database["commodity"]["Enums"]["document_kind"]
          id?: string
          is_active?: boolean
          notes?: string | null
          organization_id: string
          request_id: string
          request_item_id?: string | null
          requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          scope?: Database["rfq"]["Enums"]["document_scope"]
          sort_order?: number
          source_doc_req_id?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind?: Database["commodity"]["Enums"]["document_kind"]
          id?: string
          is_active?: boolean
          notes?: string | null
          organization_id?: string
          request_id?: string
          request_item_id?: string | null
          requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          scope?: Database["rfq"]["Enums"]["document_scope"]
          sort_order?: number
          source_doc_req_id?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "request_document_requirements_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "request_document_requirements_request_item_id_fkey"
            columns: ["request_item_id"]
            isOneToOne: false
            referencedRelation: "request_items"
            referencedColumns: ["id"]
          },
        ]
      }
      request_item_specifications: {
        Row: {
          created_at: string
          created_by: string | null
          data_type: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at: string | null
          display_name_en: string | null
          display_name_fa: string | null
          id: string
          is_required: boolean
          max_value: number | null
          min_value: number | null
          notes: string | null
          organization_id: string
          product_specification_id: string | null
          request_id: string
          request_item_id: string
          requested_value: string | null
          sort_order: number
          spec_key: string
          tenant_id: string
          tolerance_text: string | null
          unit: string | null
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          id?: string
          is_required?: boolean
          max_value?: number | null
          min_value?: number | null
          notes?: string | null
          organization_id: string
          product_specification_id?: string | null
          request_id: string
          request_item_id: string
          requested_value?: string | null
          sort_order?: number
          spec_key: string
          tenant_id: string
          tolerance_text?: string | null
          unit?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          id?: string
          is_required?: boolean
          max_value?: number | null
          min_value?: number | null
          notes?: string | null
          organization_id?: string
          product_specification_id?: string | null
          request_id?: string
          request_item_id?: string
          requested_value?: string | null
          sort_order?: number
          spec_key?: string
          tenant_id?: string
          tolerance_text?: string | null
          unit?: string | null
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "request_item_specifications_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "request_item_specifications_request_item_id_fkey"
            columns: ["request_item_id"]
            isOneToOne: false
            referencedRelation: "request_items"
            referencedColumns: ["id"]
          },
        ]
      }
      request_items: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          delivery_window_end: string | null
          delivery_window_start: string | null
          id: string
          metadata: Json
          notes: string | null
          organization_id: string
          origin_country_preference: string | null
          origin_preference_notes: string | null
          packaging_preference: string | null
          product_id: string
          quantity: number | null
          quantity_unit: string | null
          request_id: string
          sort_order: number
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id: string
          origin_country_preference?: string | null
          origin_preference_notes?: string | null
          packaging_preference?: string | null
          product_id: string
          quantity?: number | null
          quantity_unit?: string | null
          request_id: string
          sort_order?: number
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivery_window_end?: string | null
          delivery_window_start?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id?: string
          origin_country_preference?: string | null
          origin_preference_notes?: string | null
          packaging_preference?: string | null
          product_id?: string
          quantity?: number | null
          quantity_unit?: string | null
          request_id?: string
          sort_order?: number
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "request_items_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
        ]
      }
      request_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          from_status: Database["rfq"]["Enums"]["request_status"] | null
          id: string
          organization_id: string
          payload: Json
          reason: string | null
          request_id: string
          tenant_id: string
          to_status: Database["rfq"]["Enums"]["request_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["rfq"]["Enums"]["request_status"] | null
          id?: string
          organization_id: string
          payload?: Json
          reason?: string | null
          request_id: string
          tenant_id: string
          to_status: Database["rfq"]["Enums"]["request_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          from_status?: Database["rfq"]["Enums"]["request_status"] | null
          id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          request_id?: string
          tenant_id?: string
          to_status?: Database["rfq"]["Enums"]["request_status"]
        }
        Relationships: [
          {
            foreignKeyName: "request_status_events_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
        ]
      }
      request_supplier_invitations: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          invited_at: string
          message: string | null
          metadata: Json
          organization_id: string
          request_id: string
          responded_at: string | null
          status: Database["rfq"]["Enums"]["invitation_status"]
          supplier_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
          viewed_at: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          invited_at?: string
          message?: string | null
          metadata?: Json
          organization_id: string
          request_id: string
          responded_at?: string | null
          status?: Database["rfq"]["Enums"]["invitation_status"]
          supplier_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          viewed_at?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          invited_at?: string
          message?: string | null
          metadata?: Json
          organization_id?: string
          request_id?: string
          responded_at?: string | null
          status?: Database["rfq"]["Enums"]["invitation_status"]
          supplier_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          viewed_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "request_supplier_invitations_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "requests"
            referencedColumns: ["id"]
          },
        ]
      }
      requests: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          closed_at: string | null
          closed_by: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          delivery_city: string | null
          delivery_country: string | null
          delivery_location_text: string | null
          delivery_port: string | null
          description: string | null
          expired_at: string | null
          id: string
          internal_notes: string | null
          invited_at: string | null
          metadata: Json
          organization_id: string
          payment_terms_text: string | null
          preferred_currency: string
          preferred_incoterms: Json
          published_at: string | null
          requester_user_id: string
          rfq_code: string
          status: Database["rfq"]["Enums"]["request_status"]
          submission_deadline: string | null
          submitted_at: string | null
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          validity_until: string | null
          version: number
          visibility: Database["rfq"]["Enums"]["visibility_model"]
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          closed_at?: string | null
          closed_by?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          description?: string | null
          expired_at?: string | null
          id?: string
          internal_notes?: string | null
          invited_at?: string | null
          metadata?: Json
          organization_id: string
          payment_terms_text?: string | null
          preferred_currency?: string
          preferred_incoterms?: Json
          published_at?: string | null
          requester_user_id: string
          rfq_code: string
          status?: Database["rfq"]["Enums"]["request_status"]
          submission_deadline?: string | null
          submitted_at?: string | null
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          validity_until?: string | null
          version?: number
          visibility?: Database["rfq"]["Enums"]["visibility_model"]
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          closed_at?: string | null
          closed_by?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivery_city?: string | null
          delivery_country?: string | null
          delivery_location_text?: string | null
          delivery_port?: string | null
          description?: string | null
          expired_at?: string | null
          id?: string
          internal_notes?: string | null
          invited_at?: string | null
          metadata?: Json
          organization_id?: string
          payment_terms_text?: string | null
          preferred_currency?: string
          preferred_incoterms?: Json
          published_at?: string | null
          requester_user_id?: string
          rfq_code?: string
          status?: Database["rfq"]["Enums"]["request_status"]
          submission_deadline?: string | null
          submitted_at?: string | null
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          validity_until?: string | null
          version?: number
          visibility?: Database["rfq"]["Enums"]["visibility_model"]
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_force_cancel_rfq: {
        Args: { p_reason?: string; p_request_id: string }
        Returns: undefined
      }
      admin_force_close_rfq: {
        Args: { p_reason?: string; p_request_id: string }
        Returns: undefined
      }
      admin_get_rfq: { Args: { p_request_id: string }; Returns: Json }
      admin_list_invitations: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_request_id?: string
          p_status?: Database["rfq"]["Enums"]["invitation_status"]
          p_supplier_id?: string
        }
        Returns: {
          id: string
          invited_at: string
          request_id: string
          responded_at: string
          status: string
          supplier_id: string
          viewed_at: string
        }[]
      }
      admin_list_rfqs: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["rfq"]["Enums"]["request_status"]
        }
        Returns: {
          created_at: string
          id: string
          invitation_count: number
          organization_id: string
          rfq_code: string
          status: string
          submission_deadline: string
          title: string
          updated_at: string
        }[]
      }
      buyer_cancel_rfq: {
        Args: { p_reason?: string; p_request_id: string }
        Returns: undefined
      }
      buyer_close_rfq: { Args: { p_request_id: string }; Returns: undefined }
      buyer_create_rfq: {
        Args: {
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_description?: string
          p_payment_terms_text?: string
          p_preferred_currency?: string
          p_preferred_incoterms?: Json
          p_submission_deadline?: string
          p_title: string
          p_validity_until?: string
          p_visibility?: Database["rfq"]["Enums"]["visibility_model"]
        }
        Returns: string
      }
      buyer_get_rfq: { Args: { p_request_id: string }; Returns: Json }
      buyer_invite_suppliers: {
        Args: {
          p_message?: string
          p_request_id: string
          p_supplier_ids: string[]
        }
        Returns: number
      }
      buyer_list_rfqs: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["rfq"]["Enums"]["request_status"]
        }
        Returns: {
          created_at: string
          id: string
          invitation_count: number
          item_count: number
          rfq_code: string
          status: string
          submission_deadline: string
          title: string
          updated_at: string
          validity_until: string
          visibility: string
        }[]
      }
      buyer_remove_doc_requirement: {
        Args: { p_doc_req_id: string }
        Returns: undefined
      }
      buyer_remove_item_specification: {
        Args: { p_spec_id: string }
        Returns: undefined
      }
      buyer_remove_rfq_item: { Args: { p_item_id: string }; Returns: undefined }
      buyer_submit_rfq: { Args: { p_request_id: string }; Returns: undefined }
      buyer_update_rfq: {
        Args: {
          p_delivery_city?: string
          p_delivery_country?: string
          p_delivery_location_text?: string
          p_delivery_port?: string
          p_description?: string
          p_internal_notes?: string
          p_payment_terms_text?: string
          p_preferred_currency?: string
          p_preferred_incoterms?: Json
          p_request_id: string
          p_submission_deadline?: string
          p_title?: string
          p_validity_until?: string
          p_visibility?: Database["rfq"]["Enums"]["visibility_model"]
        }
        Returns: undefined
      }
      buyer_upsert_doc_requirement: {
        Args: {
          p_display_name_en?: string
          p_display_name_fa?: string
          p_document_kind?: Database["commodity"]["Enums"]["document_kind"]
          p_notes?: string
          p_request_id: string
          p_request_item_id?: string
          p_requirement_level?: Database["commodity"]["Enums"]["document_requirement_level"]
          p_sort_order?: number
          p_source_doc_req_id?: string
        }
        Returns: string
      }
      buyer_upsert_item_specification: {
        Args: {
          p_data_type?: Database["commodity"]["Enums"]["spec_data_type"]
          p_display_name_en?: string
          p_display_name_fa?: string
          p_is_required?: boolean
          p_max_value?: number
          p_min_value?: number
          p_notes?: string
          p_product_specification_id?: string
          p_request_item_id: string
          p_requested_value?: string
          p_sort_order?: number
          p_spec_key: string
          p_tolerance_text?: string
          p_unit?: string
        }
        Returns: string
      }
      buyer_upsert_rfq_item: {
        Args: {
          p_delivery_window_end?: string
          p_delivery_window_start?: string
          p_item_id?: string
          p_notes?: string
          p_origin_country_preference?: string
          p_origin_preference_notes?: string
          p_packaging_preference?: string
          p_product_id?: string
          p_quantity?: number
          p_quantity_unit?: string
          p_request_id: string
          p_sort_order?: number
        }
        Returns: string
      }
      fn_assert_request_buyer_owned: {
        Args: { p_request_id: string }
        Returns: undefined
      }
      fn_assert_request_editable: {
        Args: { p_request_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: { p_action_code: string; p_payload?: Json; p_request_id: string }
        Returns: undefined
      }
      fn_buyer_organization_id: { Args: never; Returns: string }
      fn_record_status_event: {
        Args: {
          p_from: Database["rfq"]["Enums"]["request_status"]
          p_payload?: Json
          p_reason?: string
          p_request_id: string
          p_to: Database["rfq"]["Enums"]["request_status"]
        }
        Returns: undefined
      }
      fn_supplier_can_see_request: {
        Args: { p_request_id: string }
        Returns: boolean
      }
      supplier_get_rfq: { Args: { p_request_id: string }; Returns: Json }
      supplier_list_rfq_invitations: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["rfq"]["Enums"]["invitation_status"]
        }
        Returns: {
          invitation_id: string
          invitation_status: string
          invited_at: string
          request_id: string
          request_status: string
          rfq_code: string
          submission_deadline: string
          title: string
        }[]
      }
    }
    Enums: {
      document_scope: "request" | "item"
      invitation_status:
        | "invited"
        | "viewed"
        | "accepted"
        | "declined"
        | "withdrawn"
        | "expired"
      request_status:
        | "draft"
        | "submitted"
        | "published"
        | "invited"
        | "closed"
        | "cancelled"
        | "expired"
      visibility_model: "private_invited" | "organization" | "public"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  settlement: {
    Tables: {
      escrow_accounts: {
        Row: {
          account_code: string
          activated_at: string | null
          available_balance: number
          closed_at: string | null
          closed_by: string | null
          closed_reason: string | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          frozen_at: string | null
          frozen_by: string | null
          frozen_reason: string | null
          id: string
          metadata: Json
          opened_at: string
          opened_by: string | null
          organization_id: string
          status: Database["settlement"]["Enums"]["escrow_status"]
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          total_credited: number
          total_debited: number
          total_held: number
          total_released: number
          updated_at: string
          updated_by: string | null
          version: number
          voided_at: string | null
          voided_by: string | null
          voided_reason: string | null
        }
        Insert: {
          account_code: string
          activated_at?: string | null
          available_balance?: number
          closed_at?: string | null
          closed_by?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          frozen_at?: string | null
          frozen_by?: string | null
          frozen_reason?: string | null
          id?: string
          metadata?: Json
          opened_at?: string
          opened_by?: string | null
          organization_id: string
          status?: Database["settlement"]["Enums"]["escrow_status"]
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          total_credited?: number
          total_debited?: number
          total_held?: number
          total_released?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Update: {
          account_code?: string
          activated_at?: string | null
          available_balance?: number
          closed_at?: string | null
          closed_by?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          frozen_at?: string | null
          frozen_by?: string | null
          frozen_reason?: string | null
          id?: string
          metadata?: Json
          opened_at?: string
          opened_by?: string | null
          organization_id?: string
          status?: Database["settlement"]["Enums"]["escrow_status"]
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          total_credited?: number
          total_debited?: number
          total_held?: number
          total_released?: number
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Relationships: []
      }
      escrow_entries: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          amount: number
          created_at: string
          currency: string
          entry_type: Database["settlement"]["Enums"]["escrow_entry_type"]
          escrow_account_id: string
          finance_payment_id: string | null
          id: string
          metadata: Json
          notes: string | null
          organization_id: string
          reference_kind: string | null
          settlement_id: string | null
          tenant_id: string
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          amount: number
          created_at?: string
          currency: string
          entry_type: Database["settlement"]["Enums"]["escrow_entry_type"]
          escrow_account_id: string
          finance_payment_id?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id: string
          reference_kind?: string | null
          settlement_id?: string | null
          tenant_id: string
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          amount?: number
          created_at?: string
          currency?: string
          entry_type?: Database["settlement"]["Enums"]["escrow_entry_type"]
          escrow_account_id?: string
          finance_payment_id?: string | null
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id?: string
          reference_kind?: string | null
          settlement_id?: string | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "escrow_entries_escrow_account_id_fkey"
            columns: ["escrow_account_id"]
            isOneToOne: false
            referencedRelation: "escrow_accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "escrow_entries_settlement_fk"
            columns: ["settlement_id"]
            isOneToOne: false
            referencedRelation: "settlements"
            referencedColumns: ["id"]
          },
        ]
      }
      escrow_status_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          escrow_account_id: string
          from_status: Database["settlement"]["Enums"]["escrow_status"] | null
          id: string
          metadata: Json
          organization_id: string
          reason: string | null
          tenant_id: string
          to_status: Database["settlement"]["Enums"]["escrow_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          escrow_account_id: string
          from_status?: Database["settlement"]["Enums"]["escrow_status"] | null
          id?: string
          metadata?: Json
          organization_id: string
          reason?: string | null
          tenant_id: string
          to_status: Database["settlement"]["Enums"]["escrow_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          escrow_account_id?: string
          from_status?: Database["settlement"]["Enums"]["escrow_status"] | null
          id?: string
          metadata?: Json
          organization_id?: string
          reason?: string | null
          tenant_id?: string
          to_status?: Database["settlement"]["Enums"]["escrow_status"]
        }
        Relationships: [
          {
            foreignKeyName: "escrow_status_events_escrow_account_id_fkey"
            columns: ["escrow_account_id"]
            isOneToOne: false
            referencedRelation: "escrow_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      settlement_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          event_type: string
          from_status:
            | Database["settlement"]["Enums"]["settlement_status"]
            | null
          id: string
          organization_id: string
          payload: Json
          reason: string | null
          settlement_id: string
          tenant_id: string
          to_status: Database["settlement"]["Enums"]["settlement_status"]
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          event_type: string
          from_status?:
            | Database["settlement"]["Enums"]["settlement_status"]
            | null
          id?: string
          organization_id: string
          payload?: Json
          reason?: string | null
          settlement_id: string
          tenant_id: string
          to_status: Database["settlement"]["Enums"]["settlement_status"]
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          event_type?: string
          from_status?:
            | Database["settlement"]["Enums"]["settlement_status"]
            | null
          id?: string
          organization_id?: string
          payload?: Json
          reason?: string | null
          settlement_id?: string
          tenant_id?: string
          to_status?: Database["settlement"]["Enums"]["settlement_status"]
        }
        Relationships: [
          {
            foreignKeyName: "settlement_events_settlement_id_fkey"
            columns: ["settlement_id"]
            isOneToOne: false
            referencedRelation: "settlements"
            referencedColumns: ["id"]
          },
        ]
      }
      settlement_items: {
        Row: {
          amount: number
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string
          fees_amount: number
          finance_invoice_id: string | null
          finance_payment_id: string | null
          id: string
          metadata: Json
          net_amount: number
          organization_id: string
          platform_fee_amount: number
          settlement_id: string
          sort_order: number
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          amount?: number
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description: string
          fees_amount?: number
          finance_invoice_id?: string | null
          finance_payment_id?: string | null
          id?: string
          metadata?: Json
          net_amount?: number
          organization_id: string
          platform_fee_amount?: number
          settlement_id: string
          sort_order?: number
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          amount?: number
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string
          fees_amount?: number
          finance_invoice_id?: string | null
          finance_payment_id?: string | null
          id?: string
          metadata?: Json
          net_amount?: number
          organization_id?: string
          platform_fee_amount?: number
          settlement_id?: string
          sort_order?: number
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "settlement_items_settlement_id_fkey"
            columns: ["settlement_id"]
            isOneToOne: false
            referencedRelation: "settlements"
            referencedColumns: ["id"]
          },
        ]
      }
      settlements: {
        Row: {
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          dispute_opened_by_party: string | null
          dispute_reason: string | null
          dispute_status: Database["settlement"]["Enums"]["dispute_status"]
          disputed_at: string | null
          disputed_by: string | null
          escrow_account_id: string | null
          executed_contract_id: string | null
          fees_amount: number
          held_amount: number
          hold_at: string | null
          hold_by: string | null
          id: string
          metadata: Json
          net_to_supplier_amount: number
          notes: string | null
          organization_id: string
          planned_amount: number
          platform_fee_amount: number
          ready_at: string | null
          ready_by: string | null
          reconciled_amount: number
          reconciled_at: string | null
          reconciled_by: string | null
          release_reason: string | null
          released_amount: number
          released_at: string | null
          released_by: string | null
          settlement_code: string
          settlement_terms_text: string | null
          shipment_id: string | null
          status: Database["settlement"]["Enums"]["settlement_status"]
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
          voided_at: string | null
          voided_by: string | null
          voided_reason: string | null
        }
        Insert: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          dispute_opened_by_party?: string | null
          dispute_reason?: string | null
          dispute_status?: Database["settlement"]["Enums"]["dispute_status"]
          disputed_at?: string | null
          disputed_by?: string | null
          escrow_account_id?: string | null
          executed_contract_id?: string | null
          fees_amount?: number
          held_amount?: number
          hold_at?: string | null
          hold_by?: string | null
          id?: string
          metadata?: Json
          net_to_supplier_amount?: number
          notes?: string | null
          organization_id: string
          planned_amount?: number
          platform_fee_amount?: number
          ready_at?: string | null
          ready_by?: string | null
          reconciled_amount?: number
          reconciled_at?: string | null
          reconciled_by?: string | null
          release_reason?: string | null
          released_amount?: number
          released_at?: string | null
          released_by?: string | null
          settlement_code: string
          settlement_terms_text?: string | null
          shipment_id?: string | null
          status?: Database["settlement"]["Enums"]["settlement_status"]
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Update: {
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          dispute_opened_by_party?: string | null
          dispute_reason?: string | null
          dispute_status?: Database["settlement"]["Enums"]["dispute_status"]
          disputed_at?: string | null
          disputed_by?: string | null
          escrow_account_id?: string | null
          executed_contract_id?: string | null
          fees_amount?: number
          held_amount?: number
          hold_at?: string | null
          hold_by?: string | null
          id?: string
          metadata?: Json
          net_to_supplier_amount?: number
          notes?: string | null
          organization_id?: string
          planned_amount?: number
          platform_fee_amount?: number
          ready_at?: string | null
          ready_by?: string | null
          reconciled_amount?: number
          reconciled_at?: string | null
          reconciled_by?: string | null
          release_reason?: string | null
          released_amount?: number
          released_at?: string | null
          released_by?: string | null
          settlement_code?: string
          settlement_terms_text?: string | null
          shipment_id?: string | null
          status?: Database["settlement"]["Enums"]["settlement_status"]
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          voided_at?: string | null
          voided_by?: string | null
          voided_reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "settlements_escrow_account_id_fkey"
            columns: ["escrow_account_id"]
            isOneToOne: false
            referencedRelation: "escrow_accounts"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_close_escrow_account: {
        Args: { p_account_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_force_settlement_status: {
        Args: {
          p_reason?: string
          p_settlement_id: string
          p_status: Database["settlement"]["Enums"]["settlement_status"]
        }
        Returns: undefined
      }
      admin_freeze_escrow_account: {
        Args: { p_account_id: string; p_reason?: string }
        Returns: undefined
      }
      admin_get_escrow_account: {
        Args: { p_account_id: string }
        Returns: Json
      }
      admin_get_settlement: { Args: { p_settlement_id: string }; Returns: Json }
      admin_list_escrow_accounts: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["settlement"]["Enums"]["escrow_status"]
          p_supplier_id?: string
        }
        Returns: {
          account_code: string
          available_balance: number
          created_at: string
          currency: string
          id: string
          organization_id: string
          status: string
          supplier_id: string
          total_credited: number
          total_held: number
          total_released: number
        }[]
      }
      admin_list_settlement_events: {
        Args: { p_settlement_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          event_type: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_settlements: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_organization_id?: string
          p_status?: Database["settlement"]["Enums"]["settlement_status"]
          p_supplier_id?: string
        }
        Returns: {
          created_at: string
          currency: string
          dispute_status: string
          id: string
          organization_id: string
          planned_amount: number
          released_amount: number
          settlement_code: string
          status: string
          supplier_id: string
        }[]
      }
      admin_unfreeze_escrow_account: {
        Args: { p_account_id: string; p_reason?: string }
        Returns: undefined
      }
      buyer_cancel_settlement: {
        Args: { p_reason?: string; p_settlement_id: string }
        Returns: undefined
      }
      buyer_create_draft_settlement: {
        Args: {
          p_currency?: string
          p_escrow_account_id?: string
          p_executed_contract_id?: string
          p_notes?: string
          p_settlement_terms?: string
          p_shipment_id?: string
        }
        Returns: string
      }
      buyer_get_settlement: { Args: { p_settlement_id: string }; Returns: Json }
      buyer_hold_settlement: {
        Args: { p_settlement_id: string }
        Returns: undefined
      }
      buyer_list_settlements: {
        Args: {
          p_escrow_account_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["settlement"]["Enums"]["settlement_status"]
        }
        Returns: {
          created_at: string
          currency: string
          escrow_account_id: string
          executed_contract_id: string
          held_amount: number
          id: string
          planned_amount: number
          released_amount: number
          settlement_code: string
          shipment_id: string
          status: string
          supplier_id: string
          updated_at: string
        }[]
      }
      buyer_mark_settlement_ready: {
        Args: { p_settlement_id: string }
        Returns: undefined
      }
      buyer_open_escrow_account: {
        Args: { p_currency?: string; p_metadata?: Json; p_supplier_id: string }
        Returns: string
      }
      buyer_release_settlement: {
        Args: { p_reason?: string; p_settlement_id: string }
        Returns: undefined
      }
      buyer_remove_settlement_item: {
        Args: { p_item_id: string }
        Returns: undefined
      }
      buyer_update_settlement: {
        Args: {
          p_currency?: string
          p_escrow_account_id?: string
          p_notes?: string
          p_settlement_id: string
          p_settlement_terms?: string
        }
        Returns: undefined
      }
      buyer_upsert_settlement_item: {
        Args: {
          p_amount?: number
          p_description: string
          p_fees_amount?: number
          p_finance_invoice_id?: string
          p_finance_payment_id?: string
          p_item_id?: string
          p_platform_fee_amount?: number
          p_settlement_id: string
          p_sort_order?: number
        }
        Returns: string
      }
      fn_assert_buyer_for_escrow: {
        Args: { p_account_id: string }
        Returns: Database["settlement"]["Enums"]["escrow_status"]
      }
      fn_assert_buyer_for_settlement: {
        Args: { p_settlement_id: string }
        Returns: Database["settlement"]["Enums"]["settlement_status"]
      }
      fn_assert_settlement_editable: {
        Args: { p_settlement_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: {
          p_action_code: string
          p_payload?: Json
          p_resource_id: string
          p_resource_type?: string
        }
        Returns: undefined
      }
      fn_next_escrow_code: { Args: { p_tenant_id: string }; Returns: string }
      fn_next_settlement_code: {
        Args: { p_tenant_id: string }
        Returns: string
      }
      fn_recompute_escrow_balances: {
        Args: { p_account_id: string }
        Returns: undefined
      }
      fn_recompute_settlement_totals: {
        Args: { p_settlement_id: string }
        Returns: undefined
      }
      fn_record_escrow_entry: {
        Args: {
          p_account_id: string
          p_amount: number
          p_entry_type: Database["settlement"]["Enums"]["escrow_entry_type"]
          p_metadata?: Json
          p_notes?: string
          p_payment_id?: string
          p_reference_kind?: string
          p_settlement_id?: string
        }
        Returns: string
      }
      fn_record_escrow_status_event: {
        Args: {
          p_account_id: string
          p_from: Database["settlement"]["Enums"]["escrow_status"]
          p_metadata?: Json
          p_reason?: string
          p_to: Database["settlement"]["Enums"]["escrow_status"]
        }
        Returns: undefined
      }
      fn_record_settlement_event: {
        Args: {
          p_event_type: string
          p_from: Database["settlement"]["Enums"]["settlement_status"]
          p_payload?: Json
          p_reason?: string
          p_settlement_id: string
          p_to: Database["settlement"]["Enums"]["settlement_status"]
        }
        Returns: undefined
      }
      supplier_confirm_reconciliation: {
        Args: { p_notes?: string; p_settlement_id: string }
        Returns: undefined
      }
      supplier_get_my_settlement: {
        Args: { p_settlement_id: string }
        Returns: Json
      }
      supplier_list_my_settlements: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["settlement"]["Enums"]["settlement_status"]
        }
        Returns: {
          created_at: string
          currency: string
          dispute_status: string
          executed_contract_id: string
          id: string
          planned_amount: number
          released_amount: number
          settlement_code: string
          shipment_id: string
          status: string
          updated_at: string
        }[]
      }
      supplier_open_dispute: {
        Args: { p_reason: string; p_settlement_id: string }
        Returns: undefined
      }
    }
    Enums: {
      dispute_status:
        | "none"
        | "opened"
        | "under_review"
        | "resolved_buyer"
        | "resolved_supplier"
        | "withdrawn"
      escrow_entry_type:
        | "credit"
        | "debit"
        | "hold"
        | "release"
        | "reverse"
        | "adjustment"
      escrow_status: "open" | "active" | "frozen" | "closed" | "voided"
      settlement_status:
        | "draft"
        | "ready"
        | "holding"
        | "released"
        | "reconciled"
        | "disputed"
        | "cancelled"
        | "voided"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  shipment: {
    Tables: {
      shipment_document_requirements: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          display_name_en: string | null
          display_name_fa: string | null
          document_kind: Database["shipment"]["Enums"]["document_kind"]
          id: string
          metadata: Json
          notes: string | null
          organization_id: string
          requirement_level: Database["shipment"]["Enums"]["requirement_level"]
          shipment_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind: Database["shipment"]["Enums"]["document_kind"]
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id: string
          requirement_level?: Database["shipment"]["Enums"]["requirement_level"]
          shipment_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          display_name_en?: string | null
          display_name_fa?: string | null
          document_kind?: Database["shipment"]["Enums"]["document_kind"]
          id?: string
          metadata?: Json
          notes?: string | null
          organization_id?: string
          requirement_level?: Database["shipment"]["Enums"]["requirement_level"]
          shipment_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "shipment_document_requirements_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_documents: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          document_kind: Database["shipment"]["Enums"]["document_kind"]
          document_status: Database["shipment"]["Enums"]["document_status"]
          expires_at: string | null
          external_reference: string | null
          id: string
          issued_at: string | null
          metadata: Json
          notes: string | null
          organization_id: string
          requirement_id: string | null
          shipment_id: string
          shipment_item_id: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind: Database["shipment"]["Enums"]["document_kind"]
          document_status?: Database["shipment"]["Enums"]["document_status"]
          expires_at?: string | null
          external_reference?: string | null
          id?: string
          issued_at?: string | null
          metadata?: Json
          notes?: string | null
          organization_id: string
          requirement_id?: string | null
          shipment_id: string
          shipment_item_id?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          document_kind?: Database["shipment"]["Enums"]["document_kind"]
          document_status?: Database["shipment"]["Enums"]["document_status"]
          expires_at?: string | null
          external_reference?: string | null
          id?: string
          issued_at?: string | null
          metadata?: Json
          notes?: string | null
          organization_id?: string
          requirement_id?: string | null
          shipment_id?: string
          shipment_item_id?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "shipment_documents_requirement_id_fkey"
            columns: ["requirement_id"]
            isOneToOne: false
            referencedRelation: "shipment_document_requirements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shipment_documents_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shipment_documents_shipment_item_id_fkey"
            columns: ["shipment_item_id"]
            isOneToOne: false
            referencedRelation: "shipment_items"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_events: {
        Row: {
          actor_organization_id: string | null
          actor_user_id: string | null
          created_at: string
          event_type: string
          from_status: Database["shipment"]["Enums"]["shipment_status"] | null
          id: string
          metadata: Json
          organization_id: string
          reason: string | null
          shipment_id: string
          tenant_id: string
          to_status: Database["shipment"]["Enums"]["shipment_status"] | null
        }
        Insert: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          event_type: string
          from_status?: Database["shipment"]["Enums"]["shipment_status"] | null
          id?: string
          metadata?: Json
          organization_id: string
          reason?: string | null
          shipment_id: string
          tenant_id: string
          to_status?: Database["shipment"]["Enums"]["shipment_status"] | null
        }
        Update: {
          actor_organization_id?: string | null
          actor_user_id?: string | null
          created_at?: string
          event_type?: string
          from_status?: Database["shipment"]["Enums"]["shipment_status"] | null
          id?: string
          metadata?: Json
          organization_id?: string
          reason?: string | null
          shipment_id?: string
          tenant_id?: string
          to_status?: Database["shipment"]["Enums"]["shipment_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "shipment_events_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_items: {
        Row: {
          batch_number: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          executed_contract_item_id: string | null
          gross_weight: number | null
          id: string
          metadata: Json
          net_weight: number | null
          notes: string | null
          organization_id: string
          packaging: string | null
          product_id: string
          quantity: number | null
          quantity_unit: string | null
          shipment_id: string
          sort_order: number
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
          volume: number | null
        }
        Insert: {
          batch_number?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          executed_contract_item_id?: string | null
          gross_weight?: number | null
          id?: string
          metadata?: Json
          net_weight?: number | null
          notes?: string | null
          organization_id: string
          packaging?: string | null
          product_id: string
          quantity?: number | null
          quantity_unit?: string | null
          shipment_id: string
          sort_order?: number
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          volume?: number | null
        }
        Update: {
          batch_number?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          executed_contract_item_id?: string | null
          gross_weight?: number | null
          id?: string
          metadata?: Json
          net_weight?: number | null
          notes?: string | null
          organization_id?: string
          packaging?: string | null
          product_id?: string
          quantity?: number | null
          quantity_unit?: string | null
          shipment_id?: string
          sort_order?: number
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
          volume?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "shipment_items_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_milestones: {
        Row: {
          completed_at: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          metadata: Json
          milestone_type: Database["shipment"]["Enums"]["milestone_type"]
          notes: string | null
          organization_id: string
          planned_at: string | null
          shipment_id: string
          status: Database["shipment"]["Enums"]["milestone_status"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          metadata?: Json
          milestone_type: Database["shipment"]["Enums"]["milestone_type"]
          notes?: string | null
          organization_id: string
          planned_at?: string | null
          shipment_id: string
          status?: Database["shipment"]["Enums"]["milestone_status"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          metadata?: Json
          milestone_type?: Database["shipment"]["Enums"]["milestone_type"]
          notes?: string | null
          organization_id?: string
          planned_at?: string | null
          shipment_id?: string
          status?: Database["shipment"]["Enums"]["milestone_status"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "shipment_milestones_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipment_stops: {
        Row: {
          actual_arrival_at: string | null
          actual_departure_at: string | null
          city: string | null
          country: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          location_text: string | null
          metadata: Json
          notes: string | null
          organization_id: string
          planned_arrival_at: string | null
          planned_departure_at: string | null
          port: string | null
          sequence_number: number
          shipment_id: string
          stop_type: Database["shipment"]["Enums"]["stop_type"]
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          actual_arrival_at?: string | null
          actual_departure_at?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          location_text?: string | null
          metadata?: Json
          notes?: string | null
          organization_id: string
          planned_arrival_at?: string | null
          planned_departure_at?: string | null
          port?: string | null
          sequence_number: number
          shipment_id: string
          stop_type: Database["shipment"]["Enums"]["stop_type"]
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          actual_arrival_at?: string | null
          actual_departure_at?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          location_text?: string | null
          metadata?: Json
          notes?: string | null
          organization_id?: string
          planned_arrival_at?: string | null
          planned_departure_at?: string | null
          port?: string | null
          sequence_number?: number
          shipment_id?: string
          stop_type?: Database["shipment"]["Enums"]["stop_type"]
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "shipment_stops_shipment_id_fkey"
            columns: ["shipment_id"]
            isOneToOne: false
            referencedRelation: "shipments"
            referencedColumns: ["id"]
          },
        ]
      }
      shipments: {
        Row: {
          actual_delivery_date: string | null
          actual_pickup_date: string | null
          arrived_at: string | null
          arrived_by: string | null
          booked_at: string | null
          booked_by: string | null
          cancelled_at: string | null
          cancelled_by: string | null
          cancelled_reason: string | null
          carrier_name: string | null
          carrier_organization_id: string | null
          closed_at: string | null
          closed_by: string | null
          closed_reason: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          delivered_at: string | null
          delivered_by: string | null
          destination_city: string | null
          destination_country: string | null
          destination_location_text: string | null
          destination_port: string | null
          executed_contract_id: string
          id: string
          in_transit_at: string | null
          in_transit_by: string | null
          incoterm: string | null
          metadata: Json
          notes: string | null
          offer_id: string
          organization_id: string
          origin_city: string | null
          origin_country: string | null
          origin_location_text: string | null
          origin_port: string | null
          planned_at: string | null
          planned_by: string | null
          planned_delivery_date: string | null
          planned_pickup_date: string | null
          request_id: string
          shipment_code: string
          status: Database["shipment"]["Enums"]["shipment_status"]
          supplier_id: string
          supplier_organization_id: string | null
          tenant_id: string
          tracking_reference: string | null
          transport_mode: Database["shipment"]["Enums"]["transport_mode"]
          updated_at: string
          updated_by: string | null
          vehicle_reference: string | null
          version: number
        }
        Insert: {
          actual_delivery_date?: string | null
          actual_pickup_date?: string | null
          arrived_at?: string | null
          arrived_by?: string | null
          booked_at?: string | null
          booked_by?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          carrier_name?: string | null
          carrier_organization_id?: string | null
          closed_at?: string | null
          closed_by?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivered_at?: string | null
          delivered_by?: string | null
          destination_city?: string | null
          destination_country?: string | null
          destination_location_text?: string | null
          destination_port?: string | null
          executed_contract_id: string
          id?: string
          in_transit_at?: string | null
          in_transit_by?: string | null
          incoterm?: string | null
          metadata?: Json
          notes?: string | null
          offer_id: string
          organization_id: string
          origin_city?: string | null
          origin_country?: string | null
          origin_location_text?: string | null
          origin_port?: string | null
          planned_at?: string | null
          planned_by?: string | null
          planned_delivery_date?: string | null
          planned_pickup_date?: string | null
          request_id: string
          shipment_code: string
          status?: Database["shipment"]["Enums"]["shipment_status"]
          supplier_id: string
          supplier_organization_id?: string | null
          tenant_id: string
          tracking_reference?: string | null
          transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
          updated_at?: string
          updated_by?: string | null
          vehicle_reference?: string | null
          version?: number
        }
        Update: {
          actual_delivery_date?: string | null
          actual_pickup_date?: string | null
          arrived_at?: string | null
          arrived_by?: string | null
          booked_at?: string | null
          booked_by?: string | null
          cancelled_at?: string | null
          cancelled_by?: string | null
          cancelled_reason?: string | null
          carrier_name?: string | null
          carrier_organization_id?: string | null
          closed_at?: string | null
          closed_by?: string | null
          closed_reason?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivered_at?: string | null
          delivered_by?: string | null
          destination_city?: string | null
          destination_country?: string | null
          destination_location_text?: string | null
          destination_port?: string | null
          executed_contract_id?: string
          id?: string
          in_transit_at?: string | null
          in_transit_by?: string | null
          incoterm?: string | null
          metadata?: Json
          notes?: string | null
          offer_id?: string
          organization_id?: string
          origin_city?: string | null
          origin_country?: string | null
          origin_location_text?: string | null
          origin_port?: string | null
          planned_at?: string | null
          planned_by?: string | null
          planned_delivery_date?: string | null
          planned_pickup_date?: string | null
          request_id?: string
          shipment_code?: string
          status?: Database["shipment"]["Enums"]["shipment_status"]
          supplier_id?: string
          supplier_organization_id?: string | null
          tenant_id?: string
          tracking_reference?: string | null
          transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
          updated_at?: string
          updated_by?: string | null
          vehicle_reference?: string | null
          version?: number
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_close_shipment: {
        Args: { p_reason?: string; p_shipment_id: string }
        Returns: undefined
      }
      admin_force_cancel_shipment: {
        Args: { p_reason?: string; p_shipment_id: string }
        Returns: undefined
      }
      admin_get_shipment: { Args: { p_shipment_id: string }; Returns: Json }
      admin_list_shipment_events: {
        Args: { p_shipment_id: string }
        Returns: {
          actor_user_id: string
          created_at: string
          event_type: string
          from_status: string
          id: string
          reason: string
          to_status: string
        }[]
      }
      admin_list_shipments: {
        Args: {
          p_executed_contract_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["shipment"]["Enums"]["shipment_status"]
          p_supplier_id?: string
        }
        Returns: {
          created_at: string
          executed_contract_id: string
          id: string
          organization_id: string
          shipment_code: string
          status: string
          supplier_id: string
          transport_mode: string
          updated_at: string
        }[]
      }
      buyer_cancel_shipment: {
        Args: { p_reason?: string; p_shipment_id: string }
        Returns: undefined
      }
      buyer_create_shipment: {
        Args: {
          p_destination_city?: string
          p_destination_country?: string
          p_destination_location_text?: string
          p_destination_port?: string
          p_executed_contract_id: string
          p_incoterm?: string
          p_notes?: string
          p_origin_city?: string
          p_origin_country?: string
          p_origin_location_text?: string
          p_origin_port?: string
          p_planned_delivery_date?: string
          p_planned_pickup_date?: string
          p_transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
        }
        Returns: string
      }
      buyer_get_shipment: { Args: { p_shipment_id: string }; Returns: Json }
      buyer_list_shipments: {
        Args: {
          p_executed_contract_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: Database["shipment"]["Enums"]["shipment_status"]
        }
        Returns: {
          created_at: string
          executed_contract_id: string
          id: string
          shipment_code: string
          status: string
          supplier_id: string
          transport_mode: string
          updated_at: string
        }[]
      }
      buyer_mark_arrived: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      buyer_mark_booked: {
        Args: {
          p_carrier_name?: string
          p_carrier_organization_id?: string
          p_shipment_id: string
          p_tracking_reference?: string
          p_vehicle_reference?: string
        }
        Returns: undefined
      }
      buyer_mark_delivered: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      buyer_mark_in_transit: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      buyer_mark_planned: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      buyer_update_shipment: {
        Args: {
          p_carrier_name?: string
          p_carrier_organization_id?: string
          p_destination_city?: string
          p_destination_country?: string
          p_destination_location_text?: string
          p_destination_port?: string
          p_incoterm?: string
          p_notes?: string
          p_origin_city?: string
          p_origin_country?: string
          p_origin_location_text?: string
          p_origin_port?: string
          p_planned_delivery_date?: string
          p_planned_pickup_date?: string
          p_shipment_id: string
          p_tracking_reference?: string
          p_transport_mode?: Database["shipment"]["Enums"]["transport_mode"]
          p_vehicle_reference?: string
        }
        Returns: undefined
      }
      buyer_upsert_doc_requirement: {
        Args: {
          p_display_name_en?: string
          p_display_name_fa?: string
          p_document_kind: Database["shipment"]["Enums"]["document_kind"]
          p_notes?: string
          p_requirement_level?: Database["shipment"]["Enums"]["requirement_level"]
          p_shipment_id: string
        }
        Returns: string
      }
      buyer_upsert_document: {
        Args: {
          p_document_id?: string
          p_document_kind: Database["shipment"]["Enums"]["document_kind"]
          p_document_status?: Database["shipment"]["Enums"]["document_status"]
          p_expires_at?: string
          p_external_reference?: string
          p_issued_at?: string
          p_notes?: string
          p_requirement_id?: string
          p_shipment_id: string
          p_shipment_item_id?: string
        }
        Returns: string
      }
      buyer_upsert_milestone: {
        Args: {
          p_completed_at?: string
          p_milestone_type: Database["shipment"]["Enums"]["milestone_type"]
          p_notes?: string
          p_planned_at?: string
          p_shipment_id: string
          p_status?: Database["shipment"]["Enums"]["milestone_status"]
        }
        Returns: string
      }
      buyer_upsert_stop: {
        Args: {
          p_actual_arrival_at?: string
          p_actual_departure_at?: string
          p_city?: string
          p_country?: string
          p_location_text?: string
          p_notes?: string
          p_planned_arrival_at?: string
          p_planned_departure_at?: string
          p_port?: string
          p_sequence_number: number
          p_shipment_id: string
          p_stop_type: Database["shipment"]["Enums"]["stop_type"]
        }
        Returns: string
      }
      fn_assert_buyer_for_contract: {
        Args: { p_contract_id: string }
        Returns: {
          buyer_org_id: string
          contract_status: Database["contract"]["Enums"]["contract_status"]
          offer_id: string
          request_id: string
          supplier_id: string
          supplier_organization_id: string
        }[]
      }
      fn_assert_shipment_editable: {
        Args: { p_shipment_id: string; p_strict?: boolean }
        Returns: Database["shipment"]["Enums"]["shipment_status"]
      }
      fn_assert_shipment_owned: {
        Args: { p_shipment_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: { p_action_code: string; p_payload?: Json; p_shipment_id: string }
        Returns: undefined
      }
      fn_next_shipment_code: { Args: { p_tenant_id: string }; Returns: string }
      fn_record_shipment_event: {
        Args: {
          p_event_type: string
          p_from: Database["shipment"]["Enums"]["shipment_status"]
          p_metadata?: Json
          p_reason?: string
          p_shipment_id: string
          p_to: Database["shipment"]["Enums"]["shipment_status"]
        }
        Returns: undefined
      }
      supplier_get_my_shipment: {
        Args: { p_shipment_id: string }
        Returns: Json
      }
      supplier_list_my_shipments: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: Database["shipment"]["Enums"]["shipment_status"]
        }
        Returns: {
          created_at: string
          executed_contract_id: string
          id: string
          shipment_code: string
          status: string
          transport_mode: string
          updated_at: string
        }[]
      }
    }
    Enums: {
      document_kind:
        | "bill_of_lading"
        | "cmr"
        | "rail_waybill"
        | "airway_bill"
        | "packing_list"
        | "certificate_of_origin"
        | "inspection_certificate"
        | "customs_declaration"
        | "delivery_order"
        | "proof_of_delivery"
        | "other"
      document_status:
        | "pending"
        | "available"
        | "expired"
        | "rejected"
        | "archived"
      milestone_status:
        | "pending"
        | "in_progress"
        | "completed"
        | "skipped"
        | "blocked"
      milestone_type:
        | "booking_confirmed"
        | "cargo_ready"
        | "pickup_completed"
        | "customs_export_cleared"
        | "departed_origin"
        | "border_crossed"
        | "arrived_destination"
        | "customs_import_cleared"
        | "delivered"
        | "closed"
        | "other"
      requirement_level: "required" | "recommended" | "optional"
      shipment_status:
        | "draft"
        | "planned"
        | "booked"
        | "in_transit"
        | "arrived"
        | "delivered"
        | "cancelled"
        | "closed"
      stop_type:
        | "pickup"
        | "loading"
        | "border"
        | "transshipment"
        | "customs"
        | "unloading"
        | "delivery"
        | "other"
      transport_mode:
        | "road"
        | "rail"
        | "sea"
        | "air"
        | "multimodal"
        | "pipeline"
        | "other"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  supplier: {
    Tables: {
      categories: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name_en: string
          name_fa: string
          parent_category_id: string | null
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name_en: string
          name_fa: string
          parent_category_id?: string | null
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name_en?: string
          name_fa?: string
          parent_category_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_category_id_fkey"
            columns: ["parent_category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_categories: {
        Row: {
          category_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          organization_id: string
          supplier_id: string
          tenant_id: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          category_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          organization_id: string
          supplier_id: string
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          category_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          organization_id?: string
          supplier_id?: string
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supplier_categories_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      supplier_documents: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          document_type: Database["supplier"]["Enums"]["document_type"]
          expires_at: string | null
          external_reference: string | null
          id: string
          issued_at: string | null
          organization_id: string
          rejection_reason: string | null
          status: Database["supplier"]["Enums"]["document_status"]
          supplier_id: string
          tenant_id: string
          title: string
          updated_at: string
          updated_by: string | null
          verified_at: string | null
          verified_by: string | null
          version: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          document_type: Database["supplier"]["Enums"]["document_type"]
          expires_at?: string | null
          external_reference?: string | null
          id?: string
          issued_at?: string | null
          organization_id: string
          rejection_reason?: string | null
          status?: Database["supplier"]["Enums"]["document_status"]
          supplier_id: string
          tenant_id: string
          title: string
          updated_at?: string
          updated_by?: string | null
          verified_at?: string | null
          verified_by?: string | null
          version?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          document_type?: Database["supplier"]["Enums"]["document_type"]
          expires_at?: string | null
          external_reference?: string | null
          id?: string
          issued_at?: string | null
          organization_id?: string
          rejection_reason?: string | null
          status?: Database["supplier"]["Enums"]["document_status"]
          supplier_id?: string
          tenant_id?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          verified_at?: string | null
          verified_by?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "supplier_documents_supplier_id_fkey"
            columns: ["supplier_id"]
            isOneToOne: false
            referencedRelation: "suppliers"
            referencedColumns: ["id"]
          },
        ]
      }
      suppliers: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          contact_email: string | null
          contact_phone: string | null
          country_code: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          display_name: string | null
          established_year: number | null
          id: string
          organization_id: string
          rejected_at: string | null
          rejected_by: string | null
          rejected_reason: string | null
          status: Database["supplier"]["Enums"]["supplier_status"]
          submitted_at: string | null
          submitted_by: string | null
          suspended_at: string | null
          suspended_by: string | null
          suspended_reason: string | null
          tenant_id: string
          updated_at: string
          updated_by: string | null
          verification_reason: string | null
          verification_set_at: string | null
          verification_set_by: string | null
          verification_status: Database["supplier"]["Enums"]["verification_status"]
          version: number
          website: string | null
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          contact_email?: string | null
          contact_phone?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          display_name?: string | null
          established_year?: number | null
          id?: string
          organization_id: string
          rejected_at?: string | null
          rejected_by?: string | null
          rejected_reason?: string | null
          status?: Database["supplier"]["Enums"]["supplier_status"]
          submitted_at?: string | null
          submitted_by?: string | null
          suspended_at?: string | null
          suspended_by?: string | null
          suspended_reason?: string | null
          tenant_id: string
          updated_at?: string
          updated_by?: string | null
          verification_reason?: string | null
          verification_set_at?: string | null
          verification_set_by?: string | null
          verification_status?: Database["supplier"]["Enums"]["verification_status"]
          version?: number
          website?: string | null
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          contact_email?: string | null
          contact_phone?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          display_name?: string | null
          established_year?: number | null
          id?: string
          organization_id?: string
          rejected_at?: string | null
          rejected_by?: string | null
          rejected_reason?: string | null
          status?: Database["supplier"]["Enums"]["supplier_status"]
          submitted_at?: string | null
          submitted_by?: string | null
          suspended_at?: string | null
          suspended_by?: string | null
          suspended_reason?: string | null
          tenant_id?: string
          updated_at?: string
          updated_by?: string | null
          verification_reason?: string | null
          verification_set_at?: string | null
          verification_set_by?: string | null
          verification_status?: Database["supplier"]["Enums"]["verification_status"]
          version?: number
          website?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_approve_supplier: {
        Args: { p_supplier_id: string }
        Returns: undefined
      }
      admin_get_supplier: {
        Args: { p_supplier_id: string }
        Returns: {
          approved_at: string
          category_count: number
          contact_email: string
          contact_phone: string
          country_code: string
          created_at: string
          description: string
          display_name: string
          document_count: number
          established_year: number
          organization_code: string
          organization_id: string
          organization_name_en: string
          organization_name_fa: string
          rejected_at: string
          rejected_reason: string
          status: string
          submitted_at: string
          supplier_id: string
          suspended_at: string
          suspended_reason: string
          updated_at: string
          verification_reason: string
          verification_set_at: string
          verification_status: string
          website: string
        }[]
      }
      admin_list_suppliers: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status_filter?: Database["supplier"]["Enums"]["supplier_status"]
          p_verification_filter?: Database["supplier"]["Enums"]["verification_status"]
        }
        Returns: {
          category_count: number
          created_at: string
          display_name: string
          document_count: number
          organization_code: string
          organization_id: string
          organization_name_en: string
          organization_name_fa: string
          status: string
          supplier_id: string
          updated_at: string
          verification_status: string
        }[]
      }
      admin_reactivate_supplier: {
        Args: { p_supplier_id: string }
        Returns: undefined
      }
      admin_reject_supplier: {
        Args: { p_reason?: string; p_supplier_id: string }
        Returns: undefined
      }
      admin_set_document_status: {
        Args: {
          p_document_id: string
          p_reason?: string
          p_status: Database["supplier"]["Enums"]["document_status"]
        }
        Returns: undefined
      }
      admin_set_verification_status: {
        Args: {
          p_reason?: string
          p_status: Database["supplier"]["Enums"]["verification_status"]
          p_supplier_id: string
        }
        Returns: undefined
      }
      admin_start_review: {
        Args: { p_supplier_id: string }
        Returns: undefined
      }
      admin_suspend_supplier: {
        Args: { p_reason?: string; p_supplier_id: string }
        Returns: undefined
      }
      fn_audit: {
        Args: { p_action_code: string; p_payload?: Json; p_supplier_id: string }
        Returns: undefined
      }
      fn_portal_supplier_id: { Args: never; Returns: string }
      portal_add_my_category: {
        Args: { p_category_id: string }
        Returns: undefined
      }
      portal_add_my_document: {
        Args: {
          p_description?: string
          p_document_type: Database["supplier"]["Enums"]["document_type"]
          p_expires_at?: string
          p_external_reference?: string
          p_issued_at?: string
          p_title: string
        }
        Returns: string
      }
      portal_remove_my_category: {
        Args: { p_category_id: string }
        Returns: undefined
      }
      portal_remove_my_document: {
        Args: { p_document_id: string }
        Returns: undefined
      }
      portal_submit_my_profile_for_review: { Args: never; Returns: undefined }
      portal_upsert_my_profile: {
        Args: {
          p_contact_email?: string
          p_contact_phone?: string
          p_country_code?: string
          p_description?: string
          p_display_name?: string
          p_established_year?: number
          p_website?: string
        }
        Returns: undefined
      }
    }
    Enums: {
      document_status: "pending" | "verified" | "rejected" | "expired"
      document_type:
        | "license"
        | "tax_certificate"
        | "registration"
        | "iso_certificate"
        | "bank_letter"
        | "other"
      supplier_status:
        | "draft"
        | "submitted"
        | "under_review"
        | "approved"
        | "suspended"
        | "rejected"
      verification_status:
        | "unverified"
        | "pending"
        | "verified"
        | "expired"
        | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  telematics: {
    Tables: {
      position_reports: {
        Row: {
          accuracy_meters: number | null
          altitude_meters: number | null
          carrier_organization_id: string
          created_at: string
          dispatch_id: string
          heading_degrees: number | null
          id: string
          latitude: number
          longitude: number
          payload: Json
          received_at: string
          reported_at: string
          reported_by: string | null
          source: string
          speed_kmh: number | null
          tenant_id: string
        }
        Insert: {
          accuracy_meters?: number | null
          altitude_meters?: number | null
          carrier_organization_id: string
          created_at?: string
          dispatch_id: string
          heading_degrees?: number | null
          id?: string
          latitude: number
          longitude: number
          payload?: Json
          received_at?: string
          reported_at: string
          reported_by?: string | null
          source?: string
          speed_kmh?: number | null
          tenant_id: string
        }
        Update: {
          accuracy_meters?: number | null
          altitude_meters?: number | null
          carrier_organization_id?: string
          created_at?: string
          dispatch_id?: string
          heading_degrees?: number | null
          id?: string
          latitude?: number
          longitude?: number
          payload?: Json
          received_at?: string
          reported_at?: string
          reported_by?: string | null
          source?: string
          speed_kmh?: number | null
          tenant_id?: string
        }
        Relationships: []
      }
      telemetry_events: {
        Row: {
          actor_party: string
          actor_user_id: string | null
          carrier_organization_id: string
          created_at: string
          dispatch_id: string
          event_type: Database["telematics"]["Enums"]["telemetry_event_type"]
          id: string
          payload: Json
          reason: string | null
          tenant_id: string
        }
        Insert: {
          actor_party: string
          actor_user_id?: string | null
          carrier_organization_id: string
          created_at?: string
          dispatch_id: string
          event_type: Database["telematics"]["Enums"]["telemetry_event_type"]
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id: string
        }
        Update: {
          actor_party?: string
          actor_user_id?: string | null
          carrier_organization_id?: string
          created_at?: string
          dispatch_id?: string
          event_type?: Database["telematics"]["Enums"]["telemetry_event_type"]
          id?: string
          payload?: Json
          reason?: string | null
          tenant_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_get_telemetry_snapshot: {
        Args: { p_dispatch_id: string }
        Returns: Json
      }
      admin_list_active_sessions: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          age_minutes: number
          carrier_organization_id: string
          dispatch_id: string
          last_position_at: string
          latitude: number
          longitude: number
          session_started_at: string
        }[]
      }
      admin_list_positions: {
        Args: {
          p_dispatch_id: string
          p_limit?: number
          p_offset?: number
          p_since?: string
        }
        Returns: {
          dispatch_id: string
          heading_degrees: number
          id: string
          latitude: number
          longitude: number
          received_at: string
          reported_at: string
          source: string
          speed_kmh: number
        }[]
      }
      buyer_get_telemetry_snapshot: {
        Args: { p_dispatch_id: string }
        Returns: Json
      }
      buyer_list_positions: {
        Args: {
          p_dispatch_id: string
          p_limit?: number
          p_offset?: number
          p_since?: string
        }
        Returns: {
          dispatch_id: string
          heading_degrees: number
          id: string
          latitude: number
          longitude: number
          reported_at: string
          source: string
          speed_kmh: number
        }[]
      }
      carrier_end_telemetry_session: {
        Args: { p_dispatch_id: string; p_notes?: string }
        Returns: string
      }
      carrier_get_telemetry_snapshot: {
        Args: { p_dispatch_id: string }
        Returns: Json
      }
      carrier_list_my_positions: {
        Args: { p_dispatch_id: string; p_limit?: number; p_offset?: number }
        Returns: {
          dispatch_id: string
          heading_degrees: number
          id: string
          latitude: number
          longitude: number
          received_at: string
          reported_at: string
          source: string
          speed_kmh: number
        }[]
      }
      carrier_report_position: {
        Args: {
          p_accuracy_meters?: number
          p_altitude_meters?: number
          p_dispatch_id: string
          p_heading_degrees?: number
          p_latitude: number
          p_longitude: number
          p_reported_at: string
          p_source?: string
          p_speed_kmh?: number
        }
        Returns: string
      }
      carrier_report_positions_batch: {
        Args: { p_dispatch_id: string; p_positions: Json; p_source?: string }
        Returns: number
      }
      carrier_report_telemetry_event: {
        Args: {
          p_dispatch_id: string
          p_event_type: Database["telematics"]["Enums"]["telemetry_event_type"]
          p_payload?: Json
          p_reason?: string
        }
        Returns: string
      }
      carrier_start_telemetry_session: {
        Args: { p_dispatch_id: string; p_notes?: string }
        Returns: string
      }
      fn_assert_can_view_telemetry: {
        Args: { p_dispatch_id: string }
        Returns: undefined
      }
      fn_assert_carrier_for_dispatch_telemetry: {
        Args: { p_dispatch_id: string }
        Returns: undefined
      }
      fn_record_telemetry_event: {
        Args: {
          p_actor_party: string
          p_dispatch_id: string
          p_event_type: Database["telematics"]["Enums"]["telemetry_event_type"]
          p_payload?: Json
          p_reason?: string
        }
        Returns: string
      }
    }
    Enums: {
      telemetry_event_type:
        | "session_started"
        | "session_ended"
        | "signal_lost"
        | "signal_restored"
        | "position_anomaly"
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
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
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  app_storage: {
    Enums: {
      file_status: ["pending", "uploaded", "processed", "archived"],
      file_type: ["pdf", "image", "doc", "xlsx", "txt", "other"],
      file_version_status: ["pending", "uploaded", "archived", "superseded"],
    },
  },
  audit: {
    Enums: {
      access_type: ["read", "write", "export", "denied"],
      audit_action: ["insert", "update", "delete"],
    },
  },
  commodity: {
    Enums: {
      capability_status: ["active", "paused", "suspended", "withdrawn"],
      document_kind: [
        "tds",
        "msds_sds",
        "coa",
        "product_sheet",
        "packing_list",
        "certificate_of_origin",
        "inspection_certificate",
        "quality_certificate",
        "customs_document",
        "other",
      ],
      document_requirement_level: ["mandatory", "recommended", "optional"],
      physical_form: [
        "solid",
        "liquid",
        "gas",
        "granule",
        "powder",
        "viscous",
        "pellet",
        "sheet",
        "bar",
        "other",
      ],
      product_status: ["draft", "active", "inactive", "deprecated"],
      spec_data_type: ["number", "integer", "text", "enum", "boolean", "range"],
    },
  },
  contract: {
    Enums: {
      contract_status: [
        "draft_execution",
        "pending_signatures",
        "partially_signed",
        "executed",
        "cancelled",
        "voided",
        "superseded",
      ],
      executed_snapshot_type: [
        "initial_from_preparation",
        "pending_signature_snapshot",
        "executed_snapshot",
        "voided_snapshot",
      ],
      party_type: ["buyer", "supplier", "platform", "witness", "other"],
      preparation_clause_type: [
        "payment",
        "delivery",
        "inspection",
        "quality",
        "documents",
        "force_majeure",
        "dispute_resolution",
        "governing_law",
        "special_conditions",
        "other",
      ],
      preparation_contract_type: ["spot", "framework", "term", "other"],
      preparation_snapshot_type: [
        "initial_from_offer",
        "review_snapshot",
        "ready_for_contract_snapshot",
      ],
      preparation_status: [
        "draft",
        "under_review",
        "ready_for_contract",
        "cancelled",
        "superseded",
      ],
      signature_status: [
        "pending",
        "viewed",
        "signed",
        "declined",
        "cancelled",
        "expired",
      ],
    },
  },
  dispatch: {
    Enums: {
      dispatch_status: ["draft", "assigned", "ready", "released", "cancelled"],
    },
  },
  dispute: {
    Enums: {
      decision_outcome: [
        "favor_buyer",
        "favor_supplier",
        "split",
        "no_action",
        "withdrawn",
      ],
      dispute_case_status: [
        "opened",
        "under_review",
        "resolved_buyer",
        "resolved_supplier",
        "resolved_split",
        "withdrawn",
        "cancelled",
      ],
      evidence_kind: [
        "narrative",
        "document",
        "financial",
        "photo",
        "communication_log",
        "inspection_report",
        "other",
      ],
      evidence_status: ["submitted", "accepted", "rejected", "withdrawn"],
      party_role: [
        "buyer",
        "supplier",
        "platform_admin",
        "mediator",
        "observer",
      ],
      settlement_action: [
        "release_to_supplier",
        "reverse_to_buyer",
        "split",
        "no_change",
      ],
    },
  },
  evaluation: {
    Enums: {
      decision_status: ["shortlisted", "rejected", "selected_for_contract"],
      evaluation_status: ["draft", "in_review", "completed", "cancelled"],
    },
  },
  finance: {
    Enums: {
      invoice_status: [
        "draft",
        "issued",
        "sent",
        "due",
        "paid",
        "partial",
        "overdue",
        "cancelled",
        "voided",
      ],
      payment_method_type: [
        "bank_transfer",
        "credit_card",
        "paypal",
        "wire",
        "check",
        "other",
      ],
      payment_status: [
        "pending",
        "processing",
        "completed",
        "failed",
        "refunded",
        "cancelled",
      ],
    },
  },
  identity: {
    Enums: {
      locale: ["fa", "en"],
      role_scope: ["platform", "tenant", "organization", "business_unit"],
      tenant_status: ["active", "pending", "suspended", "closed"],
      user_status: ["active", "pending", "suspended", "deactivated"],
    },
  },
  kyc: {
    Enums: {
      kyc_document_kind: [
        "national_id_card",
        "passport",
        "driver_license",
        "proof_of_address",
        "company_registration",
        "tax_certificate",
        "articles_of_association",
        "authorized_signatory_letter",
        "ownership_disclosure",
        "other",
      ],
      kyc_document_status: ["pending", "accepted", "rejected", "superseded"],
      kyc_event_kind: [
        "submitted",
        "assigned",
        "info_requested",
        "resubmitted",
        "approved",
        "rejected",
        "expired",
        "risk_flag_raised",
        "risk_flag_resolved",
        "document_attached",
        "document_decision",
      ],
      kyc_risk_severity: ["info", "low", "medium", "high", "critical"],
      kyc_risk_status: ["open", "acknowledged", "mitigated", "dismissed"],
      kyc_status: [
        "not_started",
        "draft",
        "submitted",
        "in_review",
        "info_requested",
        "approved",
        "rejected",
        "expired",
      ],
      kyc_subject_type: ["person", "organization"],
    },
  },
  marketplace: {
    Enums: {
      booking_status: [
        "draft",
        "pending_carrier",
        "carrier_accepted",
        "carrier_rejected",
        "buyer_confirmed",
        "buyer_cancelled",
        "expired",
      ],
      capacity_status: ["draft", "active", "reserved", "expired", "archived"],
      carrier_profile_status: ["draft", "active", "suspended", "archived"],
    },
  },
  notify: {
    Enums: {
      channel_type: ["in_app", "email", "sms", "push", "webhook"],
      delivery_status: [
        "pending",
        "sent",
        "delivered",
        "failed",
        "skipped",
        "suppressed",
      ],
      notification_category: [
        "rfq",
        "offer",
        "evaluation",
        "contract",
        "shipment",
        "finance",
        "settlement",
        "dispute",
        "supplier_admin",
        "platform",
        "other",
      ],
      notification_priority: ["low", "normal", "high", "urgent"],
      notification_status: ["unread", "read", "archived", "dismissed"],
      template_status: ["draft", "active", "deprecated"],
    },
  },
  offer: {
    Enums: {
      commitment_status: [
        "committed",
        "with_caveat",
        "cannot_provide",
        "conditional",
      ],
      compliance_status: [
        "compliant",
        "deviation",
        "not_applicable",
        "pending",
      ],
      offer_status: [
        "draft",
        "submitted",
        "withdrawn",
        "expired",
        "rejected",
        "shortlisted",
        "accepted",
      ],
    },
  },
  organization: {
    Enums: {
      business_unit_status: ["active", "suspended", "closed"],
      membership_status: ["active", "invited", "suspended", "revoked"],
      organization_status: ["active", "pending", "suspended", "closed"],
      organization_type: [
        "buyer",
        "supplier",
        "carrier",
        "broker",
        "government",
        "platform",
      ],
    },
  },
  pricing: {
    Enums: {
      discount_application: [
        "percent_off",
        "fixed_amount_off",
        "unit_price_override",
      ],
      discount_kind: ["volume_tier", "contract_term", "manual"],
      price_list_status: ["draft", "active", "paused", "archived"],
      pricing_event_kind: [
        "price_list_created",
        "price_list_published",
        "price_list_paused",
        "price_list_archived",
        "price_list_item_updated",
        "quotation_drafted",
        "quotation_sent",
        "quotation_accepted",
        "quotation_rejected",
        "quotation_expired",
        "quotation_withdrawn",
        "quote_captured",
        "currency_rate_set",
        "discount_rule_published",
      ],
      quotation_status: [
        "draft",
        "sent",
        "accepted",
        "rejected",
        "expired",
        "withdrawn",
      ],
      quote_capture_kind: [
        "offer_submission",
        "contract_execution",
        "manual_audit",
      ],
    },
  },
  public: {
    Enums: {},
  },
  rfq: {
    Enums: {
      document_scope: ["request", "item"],
      invitation_status: [
        "invited",
        "viewed",
        "accepted",
        "declined",
        "withdrawn",
        "expired",
      ],
      request_status: [
        "draft",
        "submitted",
        "published",
        "invited",
        "closed",
        "cancelled",
        "expired",
      ],
      visibility_model: ["private_invited", "organization", "public"],
    },
  },
  settlement: {
    Enums: {
      dispute_status: [
        "none",
        "opened",
        "under_review",
        "resolved_buyer",
        "resolved_supplier",
        "withdrawn",
      ],
      escrow_entry_type: [
        "credit",
        "debit",
        "hold",
        "release",
        "reverse",
        "adjustment",
      ],
      escrow_status: ["open", "active", "frozen", "closed", "voided"],
      settlement_status: [
        "draft",
        "ready",
        "holding",
        "released",
        "reconciled",
        "disputed",
        "cancelled",
        "voided",
      ],
    },
  },
  shipment: {
    Enums: {
      document_kind: [
        "bill_of_lading",
        "cmr",
        "rail_waybill",
        "airway_bill",
        "packing_list",
        "certificate_of_origin",
        "inspection_certificate",
        "customs_declaration",
        "delivery_order",
        "proof_of_delivery",
        "other",
      ],
      document_status: [
        "pending",
        "available",
        "expired",
        "rejected",
        "archived",
      ],
      milestone_status: [
        "pending",
        "in_progress",
        "completed",
        "skipped",
        "blocked",
      ],
      milestone_type: [
        "booking_confirmed",
        "cargo_ready",
        "pickup_completed",
        "customs_export_cleared",
        "departed_origin",
        "border_crossed",
        "arrived_destination",
        "customs_import_cleared",
        "delivered",
        "closed",
        "other",
      ],
      requirement_level: ["required", "recommended", "optional"],
      shipment_status: [
        "draft",
        "planned",
        "booked",
        "in_transit",
        "arrived",
        "delivered",
        "cancelled",
        "closed",
      ],
      stop_type: [
        "pickup",
        "loading",
        "border",
        "transshipment",
        "customs",
        "unloading",
        "delivery",
        "other",
      ],
      transport_mode: [
        "road",
        "rail",
        "sea",
        "air",
        "multimodal",
        "pipeline",
        "other",
      ],
    },
  },
  supplier: {
    Enums: {
      document_status: ["pending", "verified", "rejected", "expired"],
      document_type: [
        "license",
        "tax_certificate",
        "registration",
        "iso_certificate",
        "bank_letter",
        "other",
      ],
      supplier_status: [
        "draft",
        "submitted",
        "under_review",
        "approved",
        "suspended",
        "rejected",
      ],
      verification_status: [
        "unverified",
        "pending",
        "verified",
        "expired",
        "rejected",
      ],
    },
  },
  telematics: {
    Enums: {
      telemetry_event_type: [
        "session_started",
        "session_ended",
        "signal_lost",
        "signal_restored",
        "position_anomaly",
      ],
    },
  },
} as const



// CC-21: backward-compat aliases moved to a sidecar so future
// `supabase gen types` runs can overwrite this file safely.
export * from "./database.compat";
