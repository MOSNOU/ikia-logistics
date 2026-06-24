import { createClient } from "@/lib/supabase/server";
import type {
  AdminSupplierDetailRow,
  SupplierCategoryLinkRow,
  SupplierDocumentRow,
} from "@/types/database";

export interface AdminSupplierDetail {
  supplier: AdminSupplierDetailRow | null;
  categoryLinks: SupplierCategoryLinkRow[];
  documents: SupplierDocumentRow[];
}

export async function getAdminSupplier(supplierId: string): Promise<AdminSupplierDetail> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .schema("supplier")
    .rpc("admin_get_supplier", { p_supplier_id: supplierId });
  if (error) {
    console.error("admin_get_supplier", error);
    return { supplier: null, categoryLinks: [], documents: [] };
  }
  // The RPC returns a flat row shape; we then enrich `supplier` with
  // documents/categories from the two queries below. The unknown-cast is
  // intentional and tracked here so future RPC changes are picked up by
  // the schema-drift tripwire (082_cc21_schema_drift_guard.sql).
  const supplier = ((data ?? []) as unknown as AdminSupplierDetailRow[])[0] ?? null;
  if (!supplier) {
    return { supplier: null, categoryLinks: [], documents: [] };
  }

  const [categories, documents] = await Promise.all([
    supabase
      .schema("supplier")
      .from("supplier_categories")
      .select("id, tenant_id, organization_id, supplier_id, category_id, created_at, updated_at, deleted_at")
      .eq("supplier_id", supplierId)
      .is("deleted_at", null),
    supabase
      .schema("supplier")
      .from("supplier_documents")
      .select(
        "id, tenant_id, organization_id, supplier_id, document_type, title, description, external_reference, issued_at, expires_at, status, rejection_reason, created_at, updated_at, deleted_at",
      )
      .eq("supplier_id", supplierId)
      .is("deleted_at", null)
      .order("created_at", { ascending: false }),
  ]);

  return {
    supplier,
    categoryLinks: (categories.data ?? []) as SupplierCategoryLinkRow[],
    documents: (documents.data ?? []) as SupplierDocumentRow[],
  };
}
