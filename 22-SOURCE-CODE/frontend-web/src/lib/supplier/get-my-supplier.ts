import { createClient } from "@/lib/supabase/server";
import { getProfile } from "@/lib/auth/get-profile";
import type {
  SupplierRow,
  SupplierCategoryLinkRow,
  SupplierDocumentRow,
} from "@/types/database";

export interface MySupplierBundle {
  supplier: SupplierRow | null;
  categoryLinks: SupplierCategoryLinkRow[];
  documents: SupplierDocumentRow[];
}

export async function getMySupplier(): Promise<MySupplierBundle> {
  const profile = await getProfile();
  const empty: MySupplierBundle = {
    supplier: null,
    categoryLinks: [],
    documents: [],
  };

  if (!profile?.primaryOrganizationId) return empty;

  const supabase = await createClient();
  const { data: supplierRow } = await supabase
    .schema("supplier")
    .from("suppliers")
    .select(
      "id, tenant_id, organization_id, display_name, description, website, contact_email, contact_phone, country_code, established_year, status, verification_status, submitted_at, approved_at, rejected_at, rejected_reason, suspended_at, suspended_reason, verification_set_at, verification_reason, created_at, updated_at, deleted_at, version",
    )
    .eq("organization_id", profile.primaryOrganizationId)
    .is("deleted_at", null)
    .maybeSingle();

  if (!supplierRow) return empty;

  const supplier = supplierRow as SupplierRow;
  const [categories, documents] = await Promise.all([
    supabase
      .schema("supplier")
      .from("supplier_categories")
      .select("id, tenant_id, organization_id, supplier_id, category_id, created_at, updated_at, deleted_at")
      .eq("supplier_id", supplier.id)
      .is("deleted_at", null),
    supabase
      .schema("supplier")
      .from("supplier_documents")
      .select(
        "id, tenant_id, organization_id, supplier_id, document_type, title, description, external_reference, issued_at, expires_at, status, rejection_reason, created_at, updated_at, deleted_at",
      )
      .eq("supplier_id", supplier.id)
      .is("deleted_at", null)
      .order("created_at", { ascending: false }),
  ]);

  return {
    supplier,
    categoryLinks: (categories.data ?? []) as SupplierCategoryLinkRow[],
    documents: (documents.data ?? []) as SupplierDocumentRow[],
  };
}
