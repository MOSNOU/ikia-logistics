"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { EvidenceKind } from "@/types/database";

export interface DisputeActionState {
  error?: string;
  ok?: boolean;
}

function revalidateBuyerDispute(id: string) {
  revalidatePath("/buyer/disputes");
  revalidatePath(`/buyer/disputes/${id}`);
  revalidatePath("/admin/disputes");
  revalidatePath(`/admin/disputes/${id}`);
}

export async function buyerOpenDispute(
  _prev: DisputeActionState | null,
  formData: FormData,
): Promise<DisputeActionState> {
  const settlementId = String(formData.get("settlementId") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const description = (formData.get("description") as string | null)?.trim() || undefined;
  const amountRaw = formData.get("amountInDispute");
  const amount = amountRaw ? Number(amountRaw) : undefined;

  if (!settlementId) return { error: "شناسه تسویه نامعتبر" };
  if (!title) return { error: "عنوان الزامی است" };
  if (amount !== undefined && (!Number.isFinite(amount) || amount < 0)) {
    return { error: "مبلغ نامعتبر" };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("buyer_open_dispute", {
      p_settlement_id: settlementId,
      p_title: title,
      p_description: description,
      p_amount_in_dispute: amount,
    });
  if (error) {
    console.error("buyer_open_dispute", error);
    return { error: "ثبت اختلاف ناموفق بود" };
  }
  revalidatePath("/buyer/disputes");
  redirect(`/buyer/disputes/${data}`);
}

export async function buyerSubmitEvidence(
  _prev: DisputeActionState | null,
  formData: FormData,
): Promise<DisputeActionState> {
  const disputeId = String(formData.get("disputeId") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const kind = String(formData.get("evidenceKind") ?? "") as EvidenceKind;
  const narrative = (formData.get("narrative") as string | null)?.trim() || undefined;
  if (!disputeId) return { error: "شناسه نامعتبر" };
  if (!title) return { error: "عنوان الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("buyer_submit_evidence", {
      p_dispute_id: disputeId,
      p_evidence_kind: kind,
      p_title: title,
      p_narrative: narrative,
    });
  if (error) {
    console.error("buyer_submit_evidence", error);
    return { error: "ثبت مدرک ناموفق بود" };
  }
  revalidateBuyerDispute(disputeId);
  return { ok: true };
}

export async function buyerWithdrawDispute(
  _prev: DisputeActionState | null,
  formData: FormData,
): Promise<DisputeActionState> {
  const id = String(formData.get("disputeId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("buyer_withdraw_dispute", { p_dispute_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_withdraw_dispute", error);
    return { error: "پس‌گرفتن ناموفق بود" };
  }
  revalidateBuyerDispute(id);
  return { ok: true };
}
