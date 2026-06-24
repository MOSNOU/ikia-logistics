"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { EvidenceKind } from "@/types/database";

export interface DisputeActionState {
  error?: string;
  ok?: boolean;
}

function revalidateSupplierDispute(id: string) {
  revalidatePath("/supplier/disputes");
  revalidatePath(`/supplier/disputes/${id}`);
  revalidatePath("/admin/disputes");
  revalidatePath(`/admin/disputes/${id}`);
}

export async function supplierSubmitEvidence(
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
    .rpc("supplier_submit_evidence", {
      p_dispute_id: disputeId,
      p_evidence_kind: kind,
      p_title: title,
      p_narrative: narrative,
    });
  if (error) {
    console.error("supplier_submit_evidence", error);
    return { error: "ثبت مدرک ناموفق بود" };
  }
  revalidateSupplierDispute(disputeId);
  return { ok: true };
}

export async function supplierWithdrawDispute(
  _prev: DisputeActionState | null,
  formData: FormData,
): Promise<DisputeActionState> {
  const id = String(formData.get("disputeId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("supplier_withdraw_dispute", { p_dispute_id: id, p_reason: reason });
  if (error) {
    console.error("supplier_withdraw_dispute", error);
    return { error: "پس‌گرفتن ناموفق بود" };
  }
  revalidateSupplierDispute(id);
  return { ok: true };
}
