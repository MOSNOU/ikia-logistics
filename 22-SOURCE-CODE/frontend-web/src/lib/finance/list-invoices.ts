import { createClient } from "@/lib/supabase/server";
import type { InvoiceStatus, InvoiceSummaryRow } from "@/types/database";

export type InvoiceAudience = "buyer" | "supplier" | "admin";

export interface ListInvoicesParams {
  status?: InvoiceStatus | null;
  page?: number;
  pageSize?: number;
  organizationId?: string | null;
}

export interface ListInvoicesResult {
  rows: InvoiceSummaryRow[];
  page: number;
  pageSize: number;
}

export async function listInvoices(
  audience: InvoiceAudience,
  {
    status = null,
    page = 0,
    pageSize = 25,
    organizationId = null,
  }: ListInvoicesParams = {},
): Promise<ListInvoicesResult> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_list_invoices"
      : audience === "supplier"
        ? "supplier_list_my_invoices"
        : "admin_list_invoices";
  const params: Record<string, unknown> = {
    p_status: status ?? undefined,
    p_limit: pageSize,
    p_offset: page * pageSize,
  };
  if (audience === "admin" && organizationId) {
    params.p_organization_id = organizationId;
  }
  const { data, error } = await supabase.schema("finance").rpc(rpc, params);
  if (error) {
    console.error(rpc, error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as InvoiceSummaryRow[],
    page,
    pageSize,
  };
}
