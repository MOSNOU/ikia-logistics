"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface RfqAdminActionState {
  error?: string;
  ok?: boolean;
}

function revalidateAdminRfq(id: string) {
  revalidatePath("/admin/rfqs");
  revalidatePath(`/admin/rfqs/${id}`);
  revalidatePath("/buyer/rfqs");
}

export async function adminForceCloseRfq(
  _prev: RfqAdminActionState | null,
  formData: FormData,
): Promise<RfqAdminActionState> {
  const id = String(formData.get("requestId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("admin_force_close_rfq", { p_request_id: id, p_reason: reason });
  if (error) {
    console.error("admin_force_close_rfq", error);
    return { error: "بستن اضطراری ناموفق بود" };
  }
  revalidateAdminRfq(id);
  return { ok: true };
}

export async function adminForceCancelRfq(
  _prev: RfqAdminActionState | null,
  formData: FormData,
): Promise<RfqAdminActionState> {
  const id = String(formData.get("requestId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("rfq")
    .rpc("admin_force_cancel_rfq", { p_request_id: id, p_reason: reason });
  if (error) {
    console.error("admin_force_cancel_rfq", error);
    return { error: "لغو اضطراری ناموفق بود" };
  }
  revalidateAdminRfq(id);
  return { ok: true };
}
