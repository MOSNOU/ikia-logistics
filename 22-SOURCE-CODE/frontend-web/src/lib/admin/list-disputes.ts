import { createClient } from "@/lib/supabase/server";
import type { DisputeCaseStatus, DisputeListRow } from "@/types/database";

export interface ListAdminDisputesParams {
  status?: DisputeCaseStatus | null;
  organizationId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminDisputesResult {
  rows: DisputeListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminDisputes({
  status = null,
  organizationId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminDisputesParams = {}): Promise<ListAdminDisputesResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("admin_list_disputes", {
      p_status: status ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_disputes", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as DisputeListRow[],
    page,
    pageSize,
  };
}
