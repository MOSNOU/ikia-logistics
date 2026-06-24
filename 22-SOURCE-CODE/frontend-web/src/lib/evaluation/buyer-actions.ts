"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface EvaluationActionState {
  error?: string;
  ok?: boolean;
  evaluationId?: string;
}

function revalidateEvaluation(id: string) {
  revalidatePath("/buyer/evaluations");
  revalidatePath(`/buyer/evaluations/${id}`);
  revalidatePath("/admin/evaluations");
  revalidatePath(`/admin/evaluations/${id}`);
}

export async function buyerCreateEvaluation(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const offerId = String(formData.get("offerId") ?? "");
  const evaluatorUserId = (formData.get("evaluatorUserId") as string | null)?.trim() || undefined;
  const overallNotes = (formData.get("overallNotes") as string | null)?.trim() || undefined;
  if (!offerId) return { error: "شناسه پیشنهاد نامعتبر" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc("buyer_create_evaluation", {
      p_offer_id: offerId,
      p_evaluator_user_id: evaluatorUserId,
      p_overall_notes: overallNotes,
    });
  if (error) {
    console.error("buyer_create_evaluation", error);
    return { error: "ایجاد ارزیابی ناموفق بود" };
  }
  revalidatePath("/buyer/evaluations");
  redirect(`/buyer/evaluations/${data}`);
}

export async function buyerUpdateEvaluation(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const id = String(formData.get("evaluationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_update_evaluation", {
      p_evaluation_id: id,
      p_overall_notes: (formData.get("overallNotes") as string | null) || undefined,
      p_commercial_notes: (formData.get("commercialNotes") as string | null) || undefined,
      p_technical_notes: (formData.get("technicalNotes") as string | null) || undefined,
      p_risk_notes: (formData.get("riskNotes") as string | null) || undefined,
    });
  if (error) {
    console.error("buyer_update_evaluation", error);
    return { error: "به‌روزرسانی ارزیابی ناموفق بود" };
  }
  revalidateEvaluation(id);
  return { ok: true };
}

export async function buyerUpsertScore(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const evaluationId = String(formData.get("evaluationId") ?? "");
  const dimension = String(formData.get("dimension") ?? "").trim();
  const scoreValueRaw = formData.get("scoreValue");
  const maxScoreRaw = formData.get("maxScore");
  const weightRaw = formData.get("weight");
  const weightedRaw = formData.get("weightedScore");
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;

  if (!evaluationId) return { error: "شناسه ارزیابی نامعتبر" };
  if (!dimension) return { error: "بعد امتیاز الزامی است" };

  const scoreValue = scoreValueRaw ? Number(scoreValueRaw) : undefined;
  const maxScore = maxScoreRaw ? Number(maxScoreRaw) : undefined;
  const weight = weightRaw ? Number(weightRaw) : undefined;
  const weighted = weightedRaw ? Number(weightedRaw) : undefined;

  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_upsert_score", {
      p_evaluation_id: evaluationId,
      p_dimension: dimension,
      p_score_value: scoreValue,
      p_max_score: maxScore,
      p_weight: weight,
      p_weighted_score: weighted,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_score", error);
    return { error: "ذخیره امتیاز ناموفق بود" };
  }
  revalidateEvaluation(evaluationId);
  return { ok: true };
}

export async function buyerRemoveScore(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const scoreId = String(formData.get("scoreId") ?? "");
  const evaluationId = String(formData.get("evaluationId") ?? "");
  if (!scoreId) return { error: "شناسه امتیاز نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_remove_score", { p_score_id: scoreId });
  if (error) {
    console.error("buyer_remove_score", error);
    return { error: "حذف امتیاز ناموفق بود" };
  }
  if (evaluationId) revalidateEvaluation(evaluationId);
  return { ok: true };
}

export async function buyerCompleteEvaluation(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const id = String(formData.get("evaluationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_complete_evaluation", { p_evaluation_id: id });
  if (error) {
    console.error("buyer_complete_evaluation", error);
    return { error: "تکمیل ارزیابی ناموفق بود" };
  }
  revalidateEvaluation(id);
  return { ok: true };
}

export async function buyerCancelEvaluation(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const id = String(formData.get("evaluationId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_cancel_evaluation", { p_evaluation_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_evaluation", error);
    return { error: "لغو ارزیابی ناموفق بود" };
  }
  revalidateEvaluation(id);
  return { ok: true };
}

// =============================================================================
// Decision actions — target the OFFER directly, not the evaluation.
// =============================================================================

function revalidateAfterDecision(evaluationId: string) {
  revalidatePath("/buyer/evaluations");
  revalidatePath(`/buyer/evaluations/${evaluationId}`);
  revalidatePath("/buyer/rfqs");
  revalidatePath("/admin/evaluations");
  revalidatePath(`/admin/evaluations/${evaluationId}`);
}

export async function buyerShortlistOffer(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const offerId = String(formData.get("offerId") ?? "");
  const evaluationId = String(formData.get("evaluationId") ?? "");
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!offerId) return { error: "شناسه پیشنهاد نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_shortlist_offer", { p_offer_id: offerId, p_reason: reason, p_notes: notes });
  if (error) {
    console.error("buyer_shortlist_offer", error);
    return { error: "افزودن به فهرست کوتاه ناموفق بود" };
  }
  if (evaluationId) revalidateAfterDecision(evaluationId);
  return { ok: true };
}

export async function buyerSelectForContract(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const offerId = String(formData.get("offerId") ?? "");
  const evaluationId = String(formData.get("evaluationId") ?? "");
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!offerId) return { error: "شناسه پیشنهاد نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_select_for_contract", { p_offer_id: offerId, p_reason: reason, p_notes: notes });
  if (error) {
    console.error("buyer_select_for_contract", error);
    return { error: "انتخاب برای قرارداد ناموفق بود" };
  }
  if (evaluationId) revalidateAfterDecision(evaluationId);
  return { ok: true };
}

export async function buyerRejectOffer(
  _prev: EvaluationActionState | null,
  formData: FormData,
): Promise<EvaluationActionState> {
  const offerId = String(formData.get("offerId") ?? "");
  const evaluationId = String(formData.get("evaluationId") ?? "");
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!offerId) return { error: "شناسه پیشنهاد نامعتبر" };
  if (!reason) return { error: "دلیل رد الزامی است" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("evaluation")
    .rpc("buyer_reject_offer", { p_offer_id: offerId, p_reason: reason, p_notes: notes });
  if (error) {
    console.error("buyer_reject_offer", error);
    return { error: "رد پیشنهاد ناموفق بود" };
  }
  if (evaluationId) revalidateAfterDecision(evaluationId);
  return { ok: true };
}
