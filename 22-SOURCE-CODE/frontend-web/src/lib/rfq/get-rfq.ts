import { createClient } from "@/lib/supabase/server";
import type { RfqDetail } from "@/types/database";

export type RfqAudience = "buyer" | "supplier" | "admin";

export async function getRfq(
  requestId: string,
  audience: RfqAudience,
): Promise<RfqDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_rfq"
      : audience === "supplier"
        ? "supplier_get_rfq"
        : "admin_get_rfq";

  const { data, error } = await supabase
    .schema("rfq")
    .rpc(rpc, { p_request_id: requestId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as RfqDetail;
}
