"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  ContractClauseType,
  ContractPartyType,
  PreparationContractType,
} from "@/types/database";

export interface ContractActionState {
  error?: string;
  ok?: boolean;
}

function revalidatePrep(id: string) {
  revalidatePath("/buyer/contracts");
  revalidatePath(`/buyer/contracts/${id}`);
  revalidatePath("/admin/contracts");
  revalidatePath(`/admin/contracts/${id}`);
}

function revalidateExec(id: string) {
  revalidatePath("/buyer/contracts");
  revalidatePath(`/buyer/contracts/${id}`);
  revalidatePath("/supplier/contracts");
  revalidatePath(`/supplier/contracts/${id}`);
  revalidatePath("/admin/contracts");
  revalidatePath(`/admin/contracts/${id}`);
}

// =============================================================================
// Preparation lifecycle
// =============================================================================

export async function buyerCreatePreparation(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const decisionId = String(formData.get("decisionId") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const currency = (formData.get("currency") as string | null)?.trim() || undefined;
  const contractType =
    (formData.get("contractType") as string | null)?.trim() as PreparationContractType | undefined;
  const incoterm = (formData.get("incoterm") as string | null)?.trim() || undefined;
  const internalNotes = (formData.get("internalNotes") as string | null)?.trim() || undefined;
  if (!decisionId) return { error: "شناسه تصمیم نامعتبر" };
  if (!title) return { error: "عنوان الزامی است" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("buyer_create_preparation", {
      p_decision_id: decisionId,
      p_title: title,
      p_currency: currency,
      p_contract_type: contractType,
      p_incoterm: incoterm,
      p_internal_notes: internalNotes,
    });
  if (error) {
    console.error("buyer_create_preparation", error);
    return { error: "ایجاد آماده‌سازی قرارداد ناموفق بود" };
  }
  revalidatePath("/buyer/contracts");
  redirect(`/buyer/contracts/${data}`);
}

export async function buyerUpdatePreparation(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("preparationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_update_preparation", {
      p_preparation_id: id,
      p_title: (formData.get("title") as string | null) || undefined,
      p_currency: (formData.get("currency") as string | null) || undefined,
      p_incoterm: (formData.get("incoterm") as string | null) || undefined,
      p_delivery_country: (formData.get("deliveryCountry") as string | null) || undefined,
      p_delivery_city: (formData.get("deliveryCity") as string | null) || undefined,
      p_delivery_terms_text: (formData.get("deliveryTermsText") as string | null) || undefined,
      p_payment_terms_text: (formData.get("paymentTermsText") as string | null) || undefined,
      p_inspection_terms_text: (formData.get("inspectionTermsText") as string | null) || undefined,
      p_dispute_resolution_text: (formData.get("disputeResolutionText") as string | null) || undefined,
      p_governing_law_text: (formData.get("governingLawText") as string | null) || undefined,
      p_special_conditions_text: (formData.get("specialConditionsText") as string | null) || undefined,
      p_internal_notes: (formData.get("internalNotes") as string | null) || undefined,
    });
  if (error) {
    console.error("buyer_update_preparation", error);
    return { error: "ذخیره ناموفق بود" };
  }
  revalidatePrep(id);
  return { ok: true };
}

export async function buyerAddParty(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const preparationId = String(formData.get("preparationId") ?? "");
  const displayName = String(formData.get("displayName") ?? "").trim();
  const partyType = String(formData.get("partyType") ?? "") as ContractPartyType;
  const roleTitle = (formData.get("roleTitle") as string | null)?.trim() || undefined;
  const isRequired = formData.get("isRequiredSigner") === "on";
  const signingOrderRaw = formData.get("signingOrder");
  const signingOrder = signingOrderRaw ? Number(signingOrderRaw) : undefined;
  if (!preparationId) return { error: "شناسه نامعتبر" };
  if (!displayName) return { error: "نام طرف الزامی است" };
  if (!["buyer", "supplier", "platform", "witness", "other"].includes(partyType)) {
    return { error: "نوع طرف نامعتبر" };
  }
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_add_party", {
      p_contract_id: preparationId,
      p_display_name: displayName,
      p_party_type: partyType,
      p_role_title: roleTitle,
      p_is_required_signer: isRequired,
      p_signing_order: signingOrder,
    });
  if (error) {
    console.error("buyer_add_party", error);
    return { error: "افزودن طرف ناموفق بود" };
  }
  revalidatePrep(preparationId);
  return { ok: true };
}

export async function buyerUpsertClause(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const preparationId = String(formData.get("preparationId") ?? "");
  const clauseType = String(formData.get("clauseType") ?? "") as ContractClauseType;
  const titleFa = (formData.get("titleFa") as string | null)?.trim() || undefined;
  const titleEn = (formData.get("titleEn") as string | null)?.trim() || undefined;
  const bodyFa = (formData.get("bodyFa") as string | null)?.trim() || undefined;
  const bodyEn = (formData.get("bodyEn") as string | null)?.trim() || undefined;
  const clauseKey = (formData.get("clauseKey") as string | null)?.trim() || undefined;
  const sortOrderRaw = formData.get("sortOrder");
  const sortOrder = sortOrderRaw ? Number(sortOrderRaw) : undefined;
  const isRequired = formData.get("isRequired") === "on";
  if (!preparationId) return { error: "شناسه نامعتبر" };
  if (!clauseType) return { error: "نوع بند الزامی است" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_upsert_clause", {
      p_preparation_id: preparationId,
      p_clause_type: clauseType,
      p_title_fa: titleFa,
      p_title_en: titleEn,
      p_body_fa: bodyFa,
      p_body_en: bodyEn,
      p_clause_key: clauseKey,
      p_sort_order: sortOrder,
      p_is_required: isRequired,
    });
  if (error) {
    console.error("buyer_upsert_clause", error);
    return { error: "ذخیره بند ناموفق بود" };
  }
  revalidatePrep(preparationId);
  return { ok: true };
}

export async function buyerRemoveClause(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const clauseId = String(formData.get("clauseId") ?? "");
  const preparationId = String(formData.get("preparationId") ?? "");
  if (!clauseId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_remove_clause", { p_clause_id: clauseId });
  if (error) {
    console.error("buyer_remove_clause", error);
    return { error: "حذف بند ناموفق بود" };
  }
  if (preparationId) revalidatePrep(preparationId);
  return { ok: true };
}

export async function buyerMoveToUnderReview(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("preparationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_move_to_under_review", { p_preparation_id: id });
  if (error) {
    console.error("buyer_move_to_under_review", error);
    return { error: "انتقال به وضعیت بررسی ناموفق بود" };
  }
  revalidatePrep(id);
  return { ok: true };
}

export async function buyerMarkReady(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("preparationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_mark_ready_for_contract", { p_preparation_id: id });
  if (error) {
    console.error("buyer_mark_ready_for_contract", error);
    return { error: "آماده‌سازی برای قرارداد ناموفق بود" };
  }
  revalidatePrep(id);
  return { ok: true };
}

export async function buyerPromoteToExecuted(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const preparationId = String(formData.get("preparationId") ?? "");
  const title = (formData.get("title") as string | null)?.trim() || undefined;
  const effectiveDate = (formData.get("effectiveDate") as string | null) || undefined;
  const expiryDate = (formData.get("expiryDate") as string | null) || undefined;
  if (!preparationId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("buyer_create_executed_contract", {
      p_preparation_id: preparationId,
      p_title: title,
      p_effective_date: effectiveDate,
      p_expiry_date: expiryDate,
    });
  if (error) {
    console.error("buyer_create_executed_contract", error);
    return { error: "ایجاد قرارداد اجرایی ناموفق بود" };
  }
  revalidatePrep(preparationId);
  revalidatePath("/buyer/contracts");
  redirect(`/buyer/contracts/${data}`);
}

export async function buyerCancelPreparation(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("preparationId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_cancel_preparation", { p_preparation_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_preparation", error);
    return { error: "لغو ناموفق بود" };
  }
  revalidatePrep(id);
  return { ok: true };
}

// =============================================================================
// Executed contract lifecycle
// =============================================================================

export async function buyerMarkPendingSignatures(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("contractId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_mark_pending_signatures", { p_contract_id: id });
  if (error) {
    console.error("buyer_mark_pending_signatures", error);
    return { error: "انتقال به انتظار امضا ناموفق بود" };
  }
  revalidateExec(id);
  return { ok: true };
}

export async function buyerCancelExecutedContract(
  _prev: ContractActionState | null,
  formData: FormData,
): Promise<ContractActionState> {
  const id = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_cancel_executed_contract", { p_contract_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_executed_contract", error);
    return { error: "لغو قرارداد ناموفق بود" };
  }
  revalidateExec(id);
  return { ok: true };
}
