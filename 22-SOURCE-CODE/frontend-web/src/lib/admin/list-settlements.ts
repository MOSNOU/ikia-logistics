import { createClient } from "@/lib/supabase/server";
import type {
  AdminSettlementListRow,
  SettlementStatus,
} from "@/types/database";

export interface ListAdminSettlementsParams {
  status?: SettlementStatus | null;
  organizationId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminSettlementsResult {
  rows: AdminSettlementListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminSettlements({
  status = null,
  organizationId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminSettlementsParams = {}): Promise<ListAdminSettlementsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .rpc("admin_list_settlements", {
      p_status: status ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_settlements", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as AdminSettlementListRow[],
    page,
    pageSize,
  };
}
