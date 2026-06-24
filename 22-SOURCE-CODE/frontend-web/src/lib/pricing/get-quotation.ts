import { createClient } from "@/lib/supabase/server";
import type { QuotationDetail } from "@/types/database";

export async function getQuotation(quotationId: string): Promise<QuotationDetail | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("pricing")
    .rpc("get_quotation", { p_id: quotationId });

  if (error) {
    console.error("get_quotation", error);
    return null;
  }
  if (!data) return null;
  return data as unknown as QuotationDetail;
}
