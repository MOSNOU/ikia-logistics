"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { OfferStatus } from "@/types/database";

export interface OfferAdminActionState {
  error?: string;
  ok?: boolean;
}

const ALLOWED_FORCE_STATUSES: OfferStatus[] = [
  "draft",
  "submitted",
  "withdrawn",
  "expired",
  "rejected",
  "shortlisted",
  "accepted",
];

export async function adminForceOfferStatus(
  _prev: OfferAdminActionState | null,
  formData: FormData,
): Promise<OfferAdminActionState> {
  const id = String(formData.get("offerId") ?? "");
  const status = String(formData.get("status") ?? "") as OfferStatus;
  const reason = (formData.get("reason") as string | null) || undefined;

  if (!id) return { error: "شناسه نامعتبر" };
  if (!ALLOWED_FORCE_STATUSES.includes(status)) {
    return { error: "وضعیت نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("offer")
    .rpc("admin_force_status_change", {
      p_offer_id: id,
      p_status: status,
      p_reason: reason,
    });
  if (error) {
    console.error("admin_force_status_change", error);
    return { error: "تغییر وضعیت ناموفق بود" };
  }
  revalidatePath("/admin/offers");
  revalidatePath(`/admin/offers/${id}`);
  return { ok: true };
}
