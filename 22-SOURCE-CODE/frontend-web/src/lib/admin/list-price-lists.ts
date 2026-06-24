import { createClient } from "@/lib/supabase/server";
import type { PriceListListRow, PriceListStatus } from "@/types/database";

export interface AdminListPriceListsParams {
  supplierId?: string | null;
  status?: PriceListStatus | null;
  page?: number;
  pageSize?: number;
}

export interface AdminListPriceListsResult {
  rows: PriceListListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminPriceLists({
  supplierId = null,
  status = null,
  page = 0,
  pageSize = 25,
}: AdminListPriceListsParams = {}): Promise<AdminListPriceListsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("admin_list_price_lists", {
      p_supplier_id: supplierId ?? undefined,
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_price_lists", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as PriceListListRow[],
    page,
    pageSize,
  };
}
