// Phase 1 hand-written Database types. Covers identity + organization tables
// that the frontend reads. Regenerate via:
//   supabase gen types typescript --local \
//     --schema public --schema identity --schema organization \
//     > src/types/database.ts
// after applying CC-03 migrations to a live Supabase instance.

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type RoleScope = "platform" | "tenant" | "organization" | "business_unit";
export type OrganizationType = "buyer" | "supplier" | "carrier" | "broker" | "government" | "platform";
export type OrganizationStatus = "active" | "pending" | "suspended" | "closed";
export type UserStatus = "active" | "pending" | "suspended" | "deactivated";
export type TenantStatus = "active" | "pending" | "suspended" | "closed";
export type Locale = "fa" | "en";
export type MembershipStatus = "active" | "invited" | "suspended" | "revoked";

export type SupplierStatus =
  | "draft"
  | "submitted"
  | "under_review"
  | "approved"
  | "suspended"
  | "rejected";
export type VerificationStatus =
  | "unverified"
  | "pending"
  | "verified"
  | "expired"
  | "rejected";
export type DocumentType =
  | "license"
  | "tax_certificate"
  | "registration"
  | "iso_certificate"
  | "bank_letter"
  | "other";
export type DocumentStatus = "pending" | "verified" | "rejected" | "expired";

interface IdentityTenantsRow {
  id: string;
  code: string;
  name_fa: string;
  name_en: string;
  country_code: string;
  status: TenantStatus;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

interface IdentityUserProfilesRow {
  id: string;
  tenant_id: string;
  primary_organization_id: string | null;
  full_name: string | null;
  locale: Locale;
  avatar_url: string | null;
  phone_e164: string | null;
  status: UserStatus;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

interface IdentityRolesRow {
  id: string;
  code: string;
  scope: RoleScope;
  label_fa: string;
  label_en: string;
  description: string | null;
  is_system: boolean;
  created_at: string;
  updated_at: string;
}

interface IdentityPermissionsRow {
  id: string;
  code: string;
  domain: string;
  action: string;
  label_fa: string | null;
  label_en: string | null;
  description: string | null;
  created_at: string;
}

interface IdentityRolePermissionsRow {
  role_id: string;
  permission_id: string;
  created_at: string;
}

interface IdentityUserRolesRow {
  id: string;
  user_id: string;
  role_id: string;
  scope_type: RoleScope;
  scope_id: string | null;
  granted_by: string | null;
  granted_at: string;
  revoked_at: string | null;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

interface OrganizationOrganizationsRow {
  id: string;
  tenant_id: string;
  code: string;
  name_fa: string;
  name_en: string;
  legal_name: string | null;
  registration_number: string | null;
  tax_id: string | null;
  type: OrganizationType;
  parent_organization_id: string | null;
  status: OrganizationStatus;
  country_code: string;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

interface OrganizationMembershipsRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  user_id: string;
  role_id: string;
  business_unit_id: string | null;
  status: MembershipStatus;
  joined_at: string | null;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

type Identifiable<T> = { Row: T; Insert: Partial<T> & { id?: string }; Update: Partial<T>; Relationships: [] };

export type AdminUserStatus = UserStatus | "pending_profile";

export interface AdminUserRow {
  user_id: string;
  email: string;
  email_created_at: string;
  full_name: string | null;
  tenant_id: string | null;
  primary_organization_id: string | null;
  status: AdminUserStatus;
  has_profile: boolean;
}

export interface AdminAuditRow {
  id: string;
  occurred_at: string;
  action_code: string;
  actor_user_id: string | null;
  tenant_id: string | null;
  organization_id: string | null;
  resource_type: string | null;
  resource_id: string | null;
  ip_address: string | null;
  payload: Json;
}

export interface SupplierRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  display_name: string | null;
  description: string | null;
  website: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  country_code: string | null;
  established_year: number | null;
  status: SupplierStatus;
  verification_status: VerificationStatus;
  submitted_at: string | null;
  approved_at: string | null;
  rejected_at: string | null;
  rejected_reason: string | null;
  suspended_at: string | null;
  suspended_reason: string | null;
  verification_set_at: string | null;
  verification_reason: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

export interface SupplierCategoryRow {
  id: string;
  code: string;
  name_fa: string;
  name_en: string;
  description: string | null;
  parent_category_id: string | null;
  is_active: boolean;
}

export interface SupplierCategoryLinkRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  supplier_id: string;
  category_id: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

export interface SupplierDocumentRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  supplier_id: string;
  document_type: DocumentType;
  title: string;
  description: string | null;
  external_reference: string | null;
  issued_at: string | null;
  expires_at: string | null;
  status: DocumentStatus;
  rejection_reason: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

export interface AdminSupplierListRow {
  supplier_id: string;
  organization_id: string;
  organization_code: string;
  organization_name_fa: string;
  organization_name_en: string;
  display_name: string | null;
  status: SupplierStatus;
  verification_status: VerificationStatus;
  category_count: number;
  document_count: number;
  created_at: string;
  updated_at: string;
}

export interface AdminSupplierDetailRow extends AdminSupplierListRow {
  description: string | null;
  website: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  country_code: string | null;
  established_year: number | null;
  submitted_at: string | null;
  approved_at: string | null;
  rejected_at: string | null;
  rejected_reason: string | null;
  suspended_at: string | null;
  suspended_reason: string | null;
  verification_set_at: string | null;
  verification_reason: string | null;
}

export interface Database {
  public: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
  identity: {
    Tables: {
      tenants: Identifiable<IdentityTenantsRow>;
      user_profiles: Identifiable<IdentityUserProfilesRow>;
      roles: Identifiable<IdentityRolesRow>;
      permissions: Identifiable<IdentityPermissionsRow>;
      role_permissions: Identifiable<IdentityRolePermissionsRow>;
      user_roles: Identifiable<IdentityUserRolesRow>;
    };
    Views: Record<string, never>;
    Functions: {
      record_logout: {
        Args: Record<string, never>;
        Returns: undefined;
      };
      admin_list_users: {
        Args: { p_limit?: number; p_offset?: number; p_status_filter?: string | null };
        Returns: AdminUserRow[];
      };
      admin_get_user: {
        Args: { p_user_id: string };
        Returns: AdminUserRow[];
      };
      admin_list_audit_events: {
        Args: { p_limit?: number; p_offset?: number; p_since?: string | null };
        Returns: AdminAuditRow[];
      };
      admin_create_organization: {
        Args: {
          p_tenant_id: string;
          p_code: string;
          p_name_fa: string;
          p_name_en: string;
          p_type: OrganizationType;
          p_status?: OrganizationStatus;
          p_country_code?: string;
          p_legal_name?: string | null;
          p_registration_number?: string | null;
          p_tax_id?: string | null;
        };
        Returns: string;
      };
      admin_add_membership: {
        Args: { p_organization_id: string; p_user_id: string; p_role_code: string };
        Returns: string;
      };
      admin_approve_user: {
        Args: {
          p_user_id: string;
          p_tenant_id: string;
          p_organization_id: string;
          p_role_code: string;
          p_full_name?: string | null;
          p_locale?: Locale;
        };
        Returns: undefined;
      };
      admin_set_user_status: {
        Args: { p_user_id: string; p_status: UserStatus };
        Returns: undefined;
      };
      admin_assign_role: {
        Args: {
          p_user_id: string;
          p_role_code: string;
          p_scope_type?: RoleScope;
          p_scope_id?: string | null;
        };
        Returns: undefined;
      };
    };
    Enums: {
      tenant_status: TenantStatus;
      user_status: UserStatus;
      locale: Locale;
      role_scope: RoleScope;
    };
    CompositeTypes: Record<string, never>;
  };
  organization: {
    Tables: {
      organizations: Identifiable<OrganizationOrganizationsRow>;
      memberships: Identifiable<OrganizationMembershipsRow>;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      organization_type: OrganizationType;
      organization_status: OrganizationStatus;
      membership_status: MembershipStatus;
    };
    CompositeTypes: Record<string, never>;
  };
  supplier: {
    Tables: {
      suppliers: Identifiable<SupplierRow>;
      categories: Identifiable<SupplierCategoryRow>;
      supplier_categories: Identifiable<SupplierCategoryLinkRow>;
      supplier_documents: Identifiable<SupplierDocumentRow>;
    };
    Views: Record<string, never>;
    Functions: {
      admin_list_suppliers: {
        Args: {
          p_limit?: number;
          p_offset?: number;
          p_status_filter?: SupplierStatus | null;
          p_verification_filter?: VerificationStatus | null;
        };
        Returns: AdminSupplierListRow[];
      };
      admin_get_supplier: {
        Args: { p_supplier_id: string };
        Returns: AdminSupplierDetailRow[];
      };
      admin_start_review: { Args: { p_supplier_id: string }; Returns: undefined };
      admin_approve_supplier: { Args: { p_supplier_id: string }; Returns: undefined };
      admin_reject_supplier: {
        Args: { p_supplier_id: string; p_reason?: string | null };
        Returns: undefined;
      };
      admin_suspend_supplier: {
        Args: { p_supplier_id: string; p_reason?: string | null };
        Returns: undefined;
      };
      admin_reactivate_supplier: { Args: { p_supplier_id: string }; Returns: undefined };
      admin_set_verification_status: {
        Args: {
          p_supplier_id: string;
          p_status: VerificationStatus;
          p_reason?: string | null;
        };
        Returns: undefined;
      };
      admin_set_document_status: {
        Args: {
          p_document_id: string;
          p_status: DocumentStatus;
          p_reason?: string | null;
        };
        Returns: undefined;
      };
      portal_upsert_my_profile: {
        Args: {
          p_display_name?: string | null;
          p_description?: string | null;
          p_website?: string | null;
          p_contact_email?: string | null;
          p_contact_phone?: string | null;
          p_country_code?: string | null;
          p_established_year?: number | null;
        };
        Returns: undefined;
      };
      portal_add_my_category: { Args: { p_category_id: string }; Returns: undefined };
      portal_remove_my_category: { Args: { p_category_id: string }; Returns: undefined };
      portal_add_my_document: {
        Args: {
          p_document_type: DocumentType;
          p_title: string;
          p_description?: string | null;
          p_external_reference?: string | null;
          p_issued_at?: string | null;
          p_expires_at?: string | null;
        };
        Returns: string;
      };
      portal_remove_my_document: { Args: { p_document_id: string }; Returns: undefined };
      portal_submit_my_profile_for_review: {
        Args: Record<string, never>;
        Returns: undefined;
      };
    };
    Enums: {
      supplier_status: SupplierStatus;
      verification_status: VerificationStatus;
      document_type: DocumentType;
      document_status: DocumentStatus;
    };
    CompositeTypes: Record<string, never>;
  };
}
