import { createClient } from "@/lib/supabase/server";
import type { SettlementEventRow } from "@/types/database";

export async function listSettlementEvents(
  settlementId: string,
): Promise<SettlementEventRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .rpc("admin_list_settlement_events", { p_settlement_id: settlementId });
  if (error) {
    console.error("admin_list_settlement_events", error);
    return [];
  }
  return (data ?? []) as unknown as SettlementEventRow[];
}
