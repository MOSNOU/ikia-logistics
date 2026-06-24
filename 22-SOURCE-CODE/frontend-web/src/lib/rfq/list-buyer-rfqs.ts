import { createClient } from "@/lib/supabase/server";
import type { RfqListRow, RfqStatus } from "@/types/database";

export interface ListBuyerRfqsParams {
  status?: RfqStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerRfqsResult {
  rows: RfqListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerRfqs({
  status = null,
  page = 0,
  pageSize = 25,
}: ListBuyerRfqsParams = {}): Promise<ListBuyerRfqsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("buyer_list_rfqs", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_rfqs", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as RfqListRow[],
    page,
    pageSize,
  };
}
