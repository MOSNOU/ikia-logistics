import { createClient } from "@/lib/supabase/server";
import type { ShipmentDetail } from "@/types/database";

export type ShipmentAudience = "buyer" | "supplier" | "admin";

export async function getShipment(
  shipmentId: string,
  audience: ShipmentAudience,
): Promise<ShipmentDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_shipment"
      : audience === "supplier"
        ? "supplier_get_my_shipment"
        : "admin_get_shipment";
  const { data, error } = await supabase
    .schema("shipment")
    .rpc(rpc, { p_shipment_id: shipmentId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as ShipmentDetail;
}
