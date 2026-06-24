import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/types/database";

export type QuoteCaptureRow = Database["pricing"]["Tables"]["quote_captures"]["Row"];

export interface ListQuoteCapturesParams {
  page?: number;
  pageSize?: number;
}

export async function listQuoteCaptures({
  page = 0,
  pageSize = 25,
}: ListQuoteCapturesParams = {}): Promise<QuoteCaptureRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .from("quote_captures")
    .select(
      "id, tenant_id, kind, supplier_id, supplier_organization_id, buyer_organization_id, source_supplier_offer_id, source_executed_contract_id, source_quotation_id, currency_code, snapshot, captured_at, captured_by",
    )
    .order("captured_at", { ascending: false })
    .range(page * pageSize, page * pageSize + pageSize - 1);

  if (error) {
    console.error("list_quote_captures", error);
    return [];
  }
  return (data ?? []) as QuoteCaptureRow[];
}
