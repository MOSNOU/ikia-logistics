import { createClient } from "@/lib/supabase/server";
import type {
  BuyerSettlementListRow,
  SettlementStatus,
} from "@/types/database";

export interface ListBuyerSettlementsParams {
  status?: SettlementStatus | null;
  escrowAccountId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerSettlementsResult {
  rows: BuyerSettlementListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerSettlements({
  status = null,
  escrowAccountId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerSettlementsParams = {}): Promise<ListBuyerSettlementsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .rpc("buyer_list_settlements", {
      p_status: status ?? undefined,
      p_escrow_account_id: escrowAccountId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_settlements", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as BuyerSettlementListRow[],
    page,
    pageSize,
  };
}
