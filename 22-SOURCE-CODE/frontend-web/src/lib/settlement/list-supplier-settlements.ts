import { createClient } from "@/lib/supabase/server";
import type {
  SettlementStatus,
  SupplierSettlementListRow,
} from "@/types/database";

export interface ListSupplierSettlementsParams {
  status?: SettlementStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListSupplierSettlementsResult {
  rows: SupplierSettlementListRow[];
  page: number;
  pageSize: number;
}

export async function listSupplierSettlements({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierSettlementsParams = {}): Promise<ListSupplierSettlementsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .rpc("supplier_list_my_settlements", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_settlements", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as SupplierSettlementListRow[],
    page,
    pageSize,
  };
}
