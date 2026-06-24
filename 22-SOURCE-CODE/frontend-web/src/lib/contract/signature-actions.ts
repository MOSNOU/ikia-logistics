"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface SignatureActionState {
  error?: string;
  ok?: boolean;
}

function revalidateSignature(contractId: string) {
  revalidatePath(`/buyer/contracts/${contractId}`);
  revalidatePath(`/supplier/contracts/${contractId}`);
  revalidatePath(`/admin/contracts/${contractId}`);
  revalidatePath("/supplier/contracts");
  revalidatePath("/buyer/contracts");
}

export async function buyerCreateSignatureRequest(
  _prev: SignatureActionState | null,
  formData: FormData,
): Promise<SignatureActionState> {
  const contractId = String(formData.get("contractId") ?? "");
  const partyId = String(formData.get("partyId") ?? "");
  const dueAt = (formData.get("dueAt") as string | null) || undefined;
  const requestedToUser = (formData.get("requestedToUser") as string | null)?.trim() || undefined;
  const requestedToEmail = (formData.get("requestedToEmail") as string | null)?.trim() || undefined;
  if (!contractId) return { error: "شناسه قرارداد نامعتبر" };
  if (!partyId) return { error: "طرف انتخاب نشده است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_create_signature_request", {
      p_contract_id: contractId,
      p_party_id: partyId,
      p_due_at: dueAt,
      p_requested_to_user: requestedToUser,
      p_requested_to_email: requestedToEmail,
    });
  if (error) {
    console.error("buyer_create_signature_request", error);
    return { error: "ایجاد درخواست امضا ناموفق بود" };
  }
  revalidateSignature(contractId);
  return { ok: true };
}

export async function buyerSignSignatureRequest(
  _prev: SignatureActionState | null,
  formData: FormData,
): Promise<SignatureActionState> {
  const signatureRequestId = String(formData.get("signatureRequestId") ?? "");
  const contractId = String(formData.get("contractId") ?? "");
  if (!signatureRequestId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_sign_signature_request", { p_signature_request_id: signatureRequestId });
  if (error) {
    console.error("buyer_sign_signature_request", error);
    return { error: "ثبت امضای خریدار ناموفق بود" };
  }
  if (contractId) revalidateSignature(contractId);
  return { ok: true };
}

export async function buyerDeclineSignatureRequest(
  _prev: SignatureActionState | null,
  formData: FormData,
): Promise<SignatureActionState> {
  const signatureRequestId = String(formData.get("signatureRequestId") ?? "");
  const contractId = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!signatureRequestId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("buyer_decline_signature_request", {
      p_signature_request_id: signatureRequestId,
      p_reason: reason,
    });
  if (error) {
    console.error("buyer_decline_signature_request", error);
    return { error: "رد امضا ناموفق بود" };
  }
  if (contractId) revalidateSignature(contractId);
  return { ok: true };
}

export async function supplierSignSignatureRequest(
  _prev: SignatureActionState | null,
  formData: FormData,
): Promise<SignatureActionState> {
  const signatureRequestId = String(formData.get("signatureRequestId") ?? "");
  const contractId = String(formData.get("contractId") ?? "");
  if (!signatureRequestId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("supplier_sign_signature_request", { p_signature_request_id: signatureRequestId });
  if (error) {
    console.error("supplier_sign_signature_request", error);
    return { error: "ثبت امضای تأمین‌کننده ناموفق بود" };
  }
  if (contractId) revalidateSignature(contractId);
  return { ok: true };
}

export async function supplierDeclineSignatureRequest(
  _prev: SignatureActionState | null,
  formData: FormData,
): Promise<SignatureActionState> {
  const signatureRequestId = String(formData.get("signatureRequestId") ?? "");
  const contractId = String(formData.get("contractId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!signatureRequestId) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("contract")
    .rpc("supplier_decline_signature_request", {
      p_signature_request_id: signatureRequestId,
      p_reason: reason,
    });
  if (error) {
    console.error("supplier_decline_signature_request", error);
    return { error: "رد امضا ناموفق بود" };
  }
  if (contractId) revalidateSignature(contractId);
  return { ok: true };
}
