import { createClient } from "@/lib/supabase/server";
import type { PriceListListRow, PriceListStatus } from "@/types/database";

export interface ListMyPriceListsParams {
  status?: PriceListStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListMyPriceListsResult {
  rows: PriceListListRow[];
  page: number;
  pageSize: number;
}

export async function listMyPriceLists({
  status = null,
  page = 0,
  pageSize = 25,
}: ListMyPriceListsParams = {}): Promise<ListMyPriceListsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("get_my_price_lists", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });

  if (error) {
    console.error("get_my_price_lists", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as PriceListListRow[],
    page,
    pageSize,
  };
}
