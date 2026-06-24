import { createClient } from "@/lib/supabase/server";
import type {
  AdminSupplierListRow,
  SupplierStatus,
  VerificationStatus,
} from "@/types/database";

export interface ListSuppliersParams {
  page?: number;
  pageSize?: number;
  status?: SupplierStatus | null;
  verification?: VerificationStatus | null;
}

export interface ListSuppliersResult {
  rows: AdminSupplierListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminSuppliers({
  page = 0,
  pageSize = 25,
  status = null,
  verification = null,
}: ListSuppliersParams = {}): Promise<ListSuppliersResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("supplier")
    .rpc("admin_list_suppliers", {
      p_limit: pageSize,
      p_offset: page * pageSize,
      p_status_filter: status ?? undefined,
      p_verification_filter: verification ?? undefined,
    });

  if (error) {
    console.error("admin_list_suppliers", error);
    return { rows: [], page, pageSize };
  }
  return { rows: (data ?? []) as AdminSupplierListRow[], page, pageSize };
}
