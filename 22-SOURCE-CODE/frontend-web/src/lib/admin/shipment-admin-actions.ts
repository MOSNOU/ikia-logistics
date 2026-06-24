"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface ShipmentAdminActionState {
  error?: string;
  ok?: boolean;
}

function revalidateAdmin(id: string) {
  revalidatePath("/admin/shipments");
  revalidatePath(`/admin/shipments/${id}`);
  revalidatePath("/buyer/shipments");
  revalidatePath("/supplier/shipments");
}

export async function adminCloseShipment(
  _prev: ShipmentAdminActionState | null,
  formData: FormData,
): Promise<ShipmentAdminActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("admin_close_shipment", { p_shipment_id: id, p_reason: reason });
  if (error) {
    console.error("admin_close_shipment", error);
    return { error: "بستن اضطراری ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}

export async function adminForceCancelShipment(
  _prev: ShipmentAdminActionState | null,
  formData: FormData,
): Promise<ShipmentAdminActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("admin_force_cancel_shipment", { p_shipment_id: id, p_reason: reason });
  if (error) {
    console.error("admin_force_cancel_shipment", error);
    return { error: "لغو اضطراری ناموفق بود" };
  }
  revalidateAdmin(id);
  return { ok: true };
}
