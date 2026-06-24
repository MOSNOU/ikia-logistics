import { createClient } from "@/lib/supabase/server";
import type { DisputeCaseStatus, DisputeListRow } from "@/types/database";

export interface ListBuyerDisputesParams {
  status?: DisputeCaseStatus | null;
  settlementId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerDisputesResult {
  rows: DisputeListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerDisputes({
  status = null,
  settlementId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerDisputesParams = {}): Promise<ListBuyerDisputesResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("buyer_list_disputes", {
      p_status: status ?? undefined,
      p_settlement_id: settlementId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_disputes", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as DisputeListRow[],
    page,
    pageSize,
  };
}
