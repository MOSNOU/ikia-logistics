import { createClient } from "@/lib/supabase/server";
import type { QuotationListRow, QuotationStatus } from "@/types/database";

export interface AdminListQuotationsParams {
  status?: QuotationStatus | null;
  buyerOrganizationId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface AdminListQuotationsResult {
  rows: QuotationListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminQuotations({
  status = null,
  buyerOrganizationId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: AdminListQuotationsParams = {}): Promise<AdminListQuotationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("admin_list_quotations", {
      p_status: status ?? undefined,
      p_buyer_organization_id: buyerOrganizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_quotations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as QuotationListRow[],
    page,
    pageSize,
  };
}
