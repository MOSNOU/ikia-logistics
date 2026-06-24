import { createClient } from "@/lib/supabase/server";
import type {
  CapacityMatchRow,
  CarrierMatchRow,
  MatchingSummary,
} from "@/types/database";

export interface FindMatchingResult {
  capacity: CapacityMatchRow[];
  carriers: CarrierMatchRow[];
  available: boolean;
  error?: string;
}

// CC-41: orchestrator that calls find_matching_capacity and find_matching_carriers
// in parallel for a single shipment. Both RPCs share the same visibility gate
// (fn_assert_can_view_shipment), so a denial on one denies the other; we
// surface a single available=false bundle in that case.
export async function findMatchingForShipment(
  shipmentId: string,
  opts: { limit?: number } = {},
): Promise<FindMatchingResult> {
  const supabase = await createClient();
  const limit = opts.limit ?? 25;
  const [cap, car] = await Promise.all([
    supabase
      .schema("marketplace")
      .rpc("find_matching_capacity", { p_shipment_id: shipmentId, p_limit: limit }),
    supabase
      .schema("marketplace")
      .rpc("find_matching_carriers", { p_shipment_id: shipmentId, p_limit: limit }),
  ]);
  if (cap.error || car.error) {
    const err = cap.error ?? car.error;
    console.error("marketplace.find_matching_*", err);
    const code = (err as { code?: string } | null)?.code;
    const error =
      code === "42501"
        ? "اجازه دسترسی به این محموله برای موتور تطبیق وجود ندارد."
        : code === "P0002"
          ? "محموله یافت نشد."
          : "خطا در اجرای موتور تطبیق.";
    return { capacity: [], carriers: [], available: false, error };
  }
  return {
    capacity: (cap.data ?? []) as unknown as CapacityMatchRow[],
    carriers: (car.data ?? []) as unknown as CarrierMatchRow[],
    available: true,
  };
}

// CC-41: admin summary RPC. Returns the derived KPI bundle described in
// marketplace.admin_matching_summary (Q1=A/Q6=A: no persistence, total
// reflects eligible shipments, not historical request counts).
export async function loadAdminMatchingSummary(): Promise<MatchingSummary | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("admin_matching_summary");
  if (error || !data) {
    if (error) console.error("marketplace.admin_matching_summary", error);
    return null;
  }
  return data as unknown as MatchingSummary;
}
