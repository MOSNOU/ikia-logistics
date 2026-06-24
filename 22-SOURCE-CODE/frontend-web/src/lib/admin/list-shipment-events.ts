import { createClient } from "@/lib/supabase/server";
import type { ShipmentEventRow } from "@/types/database";

export async function listShipmentEvents(
  shipmentId: string,
): Promise<ShipmentEventRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("admin_list_shipment_events", { p_shipment_id: shipmentId });
  if (error) {
    console.error("admin_list_shipment_events", error);
    return [];
  }
  return (data ?? []) as unknown as ShipmentEventRow[];
}
