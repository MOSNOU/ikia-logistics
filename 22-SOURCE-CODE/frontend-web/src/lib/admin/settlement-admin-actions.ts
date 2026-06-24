"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { SettlementStatus } from "@/types/database";

export interface SettlementAdminActionState {
  error?: string;
  ok?: boolean;
}

const ALLOWED_FORCE_STATUSES: SettlementStatus[] = [
  "draft",
  "ready",
  "holding",
  "released",
  "reconciled",
  "disputed",
  "cancelled",
  "voided",
];

export async function adminForceSettlementStatus(
  _prev: SettlementAdminActionState | null,
  formData: FormData,
): Promise<SettlementAdminActionState> {
  const id = String(formData.get("settlementId") ?? "");
  const status = String(formData.get("status") ?? "") as SettlementStatus;
  const reason = (formData.get("reason") as string | null) || undefined;

  if (!id) return { error: "شناسه نامعتبر" };
  if (!ALLOWED_FORCE_STATUSES.includes(status)) {
    return { error: "وضعیت نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("admin_force_settlement_status", {
      p_settlement_id: id,
      p_status: status,
      p_reason: reason,
    });
  if (error) {
    console.error("admin_force_settlement_status", error);
    return { error: "تغییر وضعیت ناموفق بود" };
  }
  revalidatePath("/admin/settlements");
  revalidatePath(`/admin/settlements/${id}`);
  return { ok: true };
}
