import { createClient } from "@/lib/supabase/server";
import type { OfferListRow, OfferStatus } from "@/types/database";

export interface ListSupplierOffersParams {
  status?: OfferStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListSupplierOffersResult {
  rows: OfferListRow[];
  page: number;
  pageSize: number;
}

export async function listSupplierOffers({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierOffersParams = {}): Promise<ListSupplierOffersResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("offer")
    .rpc("supplier_list_my_offers", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_offers", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as OfferListRow[],
    page,
    pageSize,
  };
}
