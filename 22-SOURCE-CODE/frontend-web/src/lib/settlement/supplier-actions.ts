"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface SettlementActionState {
  error?: string;
  ok?: boolean;
}

function revalidateSupplier(id: string) {
  revalidatePath("/supplier/settlements");
  revalidatePath(`/supplier/settlements/${id}`);
  revalidatePath("/admin/settlements");
  revalidatePath(`/admin/settlements/${id}`);
}

export async function supplierConfirmReconciliation(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  const notes = (formData.get("notes") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("supplier_confirm_reconciliation", {
      p_settlement_id: id,
      p_notes: notes,
    });
  if (error) {
    console.error("supplier_confirm_reconciliation", error);
    return { error: "تأیید تطبیق ناموفق بود" };
  }
  revalidateSupplier(id);
  return { ok: true };
}

export async function supplierOpenDispute(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!id) return { error: "شناسه نامعتبر" };
  if (!reason) return { error: "دلیل الزامی است" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("supplier_open_dispute", {
      p_settlement_id: id,
      p_reason: reason,
    });
  if (error) {
    console.error("supplier_open_dispute", error);
    return { error: "ثبت اختلاف ناموفق بود" };
  }
  revalidateSupplier(id);
  revalidatePath("/supplier/disputes");
  return { ok: true };
}
