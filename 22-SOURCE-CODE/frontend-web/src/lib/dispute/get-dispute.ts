import { createClient } from "@/lib/supabase/server";
import type { DisputeDetail } from "@/types/database";

export type DisputeAudience = "buyer" | "supplier" | "admin";

export async function getDispute(
  disputeId: string,
  audience: DisputeAudience,
): Promise<DisputeDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_dispute"
      : audience === "supplier"
        ? "supplier_get_my_dispute"
        : "admin_get_dispute";

  const { data, error } = await supabase
    .schema("dispute")
    .rpc(rpc, { p_dispute_id: disputeId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as DisputeDetail;
}
