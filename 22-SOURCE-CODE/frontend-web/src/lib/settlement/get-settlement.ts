import { createClient } from "@/lib/supabase/server";
import type { SettlementDetail } from "@/types/database";

export type SettlementAudience = "buyer" | "supplier" | "admin";

export async function getSettlement(
  settlementId: string,
  audience: SettlementAudience,
): Promise<SettlementDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_settlement"
      : audience === "supplier"
        ? "supplier_get_my_settlement"
        : "admin_get_settlement";

  const { data, error } = await supabase
    .schema("settlement")
    .rpc(rpc, { p_settlement_id: settlementId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as SettlementDetail;
}
