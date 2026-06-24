"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface SettlementActionState {
  error?: string;
  ok?: boolean;
}

function revalidateBuyer(id: string) {
  revalidatePath("/buyer/settlements");
  revalidatePath(`/buyer/settlements/${id}`);
  revalidatePath("/admin/settlements");
  revalidatePath(`/admin/settlements/${id}`);
}

export async function buyerMarkReady(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("buyer_mark_settlement_ready", { p_settlement_id: id });
  if (error) {
    console.error("buyer_mark_settlement_ready", error);
    return { error: "علامت‌گذاری آماده ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerHold(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("buyer_hold_settlement", { p_settlement_id: id });
  if (error) {
    console.error("buyer_hold_settlement", error);
    return { error: "نگه‌داری در اسکرو ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerRelease(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("buyer_release_settlement", { p_settlement_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_release_settlement", error);
    return { error: "آزادسازی ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerCancel(
  _prev: SettlementActionState | null,
  formData: FormData,
): Promise<SettlementActionState> {
  const id = String(formData.get("settlementId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("settlement")
    .rpc("buyer_cancel_settlement", { p_settlement_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_settlement", error);
    return { error: "لغو ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}
