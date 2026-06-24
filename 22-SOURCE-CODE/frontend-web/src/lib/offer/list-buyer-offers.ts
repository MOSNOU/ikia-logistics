import { createClient } from "@/lib/supabase/server";
import type { OfferListRow, OfferStatus } from "@/types/database";

export interface ListBuyerOffersParams {
  status?: OfferStatus | null;
  requestId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerOffersResult {
  rows: OfferListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerReceivedOffers({
  status = null,
  requestId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerOffersParams = {}): Promise<ListBuyerOffersResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("offer")
    .rpc("buyer_list_received_offers", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_received_offers", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as OfferListRow[],
    page,
    pageSize,
  };
}
