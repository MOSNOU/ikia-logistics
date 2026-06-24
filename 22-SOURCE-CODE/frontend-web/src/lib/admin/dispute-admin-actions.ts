"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  DecisionOutcome,
  DisputeSettlementAction,
  EvidenceStatus,
} from "@/types/database";

export interface DisputeAdminActionState {
  error?: string;
  ok?: boolean;
}

function revalidateAdminDispute(id: string) {
  revalidatePath("/admin/disputes");
  revalidatePath(`/admin/disputes/${id}`);
  revalidatePath("/buyer/disputes");
  revalidatePath("/supplier/disputes");
}

export async function adminStartReview(
  _prev: DisputeAdminActionState | null,
  formData: FormData,
): Promise<DisputeAdminActionState> {
  const id = String(formData.get("disputeId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("admin_start_review", { p_dispute_id: id });
  if (error) {
    console.error("admin_start_review", error);
    return { error: "شروع بررسی ناموفق بود" };
  }
  revalidateAdminDispute(id);
  return { ok: true };
}

export async function adminReviewEvidence(
  _prev: DisputeAdminActionState | null,
  formData: FormData,
): Promise<DisputeAdminActionState> {
  const evidenceId = String(formData.get("evidenceId") ?? "");
  const status = String(formData.get("status") ?? "") as EvidenceStatus;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  const disputeId = String(formData.get("disputeId") ?? "");

  if (!evidenceId) return { error: "شناسه مدرک نامعتبر" };
  if (status !== "accepted" && status !== "rejected" && status !== "withdrawn") {
    return { error: "وضعیت نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("admin_review_evidence", {
      p_evidence_id: evidenceId,
      p_status: status,
      p_notes: notes,
    });
  if (error) {
    console.error("admin_review_evidence", error);
    return { error: "بررسی مدرک ناموفق بود" };
  }
  if (disputeId) revalidateAdminDispute(disputeId);
  return { ok: true };
}

export async function adminRecordDecision(
  _prev: DisputeAdminActionState | null,
  formData: FormData,
): Promise<DisputeAdminActionState> {
  const disputeId = String(formData.get("disputeId") ?? "");
  const outcome = String(formData.get("outcome") ?? "") as DecisionOutcome;
  const settlementAction = String(
    formData.get("settlementAction") ?? "",
  ) as DisputeSettlementAction;
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  const mediatorNotes = (formData.get("mediatorNotes") as string | null)?.trim() || undefined;
  const buyerShareRaw = formData.get("buyerShare");
  const supplierShareRaw = formData.get("supplierShare");
  const feeShareRaw = formData.get("feeShare");
  const buyerShare = buyerShareRaw ? Number(buyerShareRaw) : undefined;
  const supplierShare = supplierShareRaw ? Number(supplierShareRaw) : undefined;
  const feeShare = feeShareRaw ? Number(feeShareRaw) : undefined;

  if (!disputeId) return { error: "شناسه نامعتبر" };
  if (
    outcome !== "favor_buyer" &&
    outcome !== "favor_supplier" &&
    outcome !== "split" &&
    outcome !== "no_action" &&
    outcome !== "withdrawn"
  ) {
    return { error: "نتیجه نامعتبر" };
  }
  if (
    settlementAction !== "release_to_supplier" &&
    settlementAction !== "reverse_to_buyer" &&
    settlementAction !== "split" &&
    settlementAction !== "no_change"
  ) {
    return { error: "اقدام تسویه نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("admin_record_decision", {
      p_dispute_id: disputeId,
      p_outcome: outcome,
      p_settlement_action: settlementAction,
      p_reason: reason,
      p_mediator_notes: mediatorNotes,
      p_buyer_share_amount: buyerShare,
      p_supplier_share_amount: supplierShare,
      p_fee_share_amount: feeShare,
    });
  if (error) {
    console.error("admin_record_decision", error);
    return { error: "ثبت تصمیم ناموفق بود" };
  }
  revalidateAdminDispute(disputeId);
  return { ok: true };
}

export async function adminCancelDispute(
  _prev: DisputeAdminActionState | null,
  formData: FormData,
): Promise<DisputeAdminActionState> {
  const id = String(formData.get("disputeId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispute")
    .rpc("admin_cancel_dispute", { p_dispute_id: id, p_reason: reason });
  if (error) {
    console.error("admin_cancel_dispute", error);
    return { error: "لغو ناموفق بود" };
  }
  revalidateAdminDispute(id);
  return { ok: true };
}
