import { createClient } from "@/lib/supabase/server";
import type { QuotationListRow, QuotationStatus } from "@/types/database";

export interface ListMyQuotationsParams {
  status?: QuotationStatus | null;
  buyerOrganizationId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListMyQuotationsResult {
  rows: QuotationListRow[];
  page: number;
  pageSize: number;
}

export async function listMyQuotations({
  status = null,
  buyerOrganizationId = null,
  page = 0,
  pageSize = 25,
}: ListMyQuotationsParams = {}): Promise<ListMyQuotationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("portal_list_my_quotations", {
      p_status: status ?? undefined,
      p_buyer_organization_id: buyerOrganizationId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });

  if (error) {
    console.error("portal_list_my_quotations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as QuotationListRow[],
    page,
    pageSize,
  };
}
