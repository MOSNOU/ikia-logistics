import { createClient } from "@/lib/supabase/server";
import type { DisputeCaseStatus, DisputeListRow } from "@/types/database";

export interface ListSupplierDisputesParams {
  status?: DisputeCaseStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListSupplierDisputesResult {
  rows: DisputeListRow[];
  page: number;
  pageSize: number;
}

export async function listSupplierDisputes({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierDisputesParams = {}): Promise<ListSupplierDisputesResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("supplier_list_my_disputes", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_disputes", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as DisputeListRow[],
    page,
    pageSize,
  };
}
