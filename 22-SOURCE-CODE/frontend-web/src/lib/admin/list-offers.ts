import { createClient } from "@/lib/supabase/server";
import type { OfferListRow, OfferStatus } from "@/types/database";

export interface ListAdminOffersParams {
  status?: OfferStatus | null;
  requestId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminOffersResult {
  rows: OfferListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminOffers({
  status = null,
  requestId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminOffersParams = {}): Promise<ListAdminOffersResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("offer")
    .rpc("admin_list_offers", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_offers", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as OfferListRow[],
    page,
    pageSize,
  };
}
