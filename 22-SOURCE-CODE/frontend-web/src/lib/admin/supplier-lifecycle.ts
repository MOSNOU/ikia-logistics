"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  DocumentStatus,
  VerificationStatus,
} from "@/types/database";

export interface AdminSupplierActionState {
  error?: string;
  ok?: boolean;
}

async function callRpc<T extends string>(
  fnName:
    | "admin_start_review"
    | "admin_approve_supplier"
    | "admin_reject_supplier"
    | "admin_suspend_supplier"
    | "admin_reactivate_supplier"
    | "admin_set_verification_status"
    | "admin_set_document_status",
  args: Record<string, unknown>,
  errorLabel: T,
): Promise<AdminSupplierActionState> {
  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("supplier").rpc as any)(fnName, args);
  if (error) {
    console.error(errorLabel, error);
    return { error: "عملیات ناموفق بود" };
  }
  return { ok: true };
}

export async function startReview(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  if (!supplierId) return { error: "شناسه نامعتبر" };
  const result = await callRpc("admin_start_review", { p_supplier_id: supplierId }, "start_review");
  revalidatePath(`/admin/suppliers/${supplierId}`);
  revalidatePath("/admin/suppliers");
  return result;
}

export async function approveSupplier(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  if (!supplierId) return { error: "شناسه نامعتبر" };
  const result = await callRpc("admin_approve_supplier", { p_supplier_id: supplierId }, "approve");
  revalidatePath(`/admin/suppliers/${supplierId}`);
  revalidatePath("/admin/suppliers");
  return result;
}

export async function rejectSupplier(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  const reason = (formData.get("reason") as string | null) || null;
  if (!supplierId) return { error: "شناسه نامعتبر" };
  const result = await callRpc(
    "admin_reject_supplier",
    { p_supplier_id: supplierId, p_reason: reason },
    "reject",
  );
  revalidatePath(`/admin/suppliers/${supplierId}`);
  revalidatePath("/admin/suppliers");
  return result;
}

export async function suspendSupplier(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  const reason = (formData.get("reason") as string | null) || null;
  if (!supplierId) return { error: "شناسه نامعتبر" };
  const result = await callRpc(
    "admin_suspend_supplier",
    { p_supplier_id: supplierId, p_reason: reason },
    "suspend",
  );
  revalidatePath(`/admin/suppliers/${supplierId}`);
  revalidatePath("/admin/suppliers");
  return result;
}

export async function reactivateSupplier(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  if (!supplierId) return { error: "شناسه نامعتبر" };
  const result = await callRpc("admin_reactivate_supplier", { p_supplier_id: supplierId }, "reactivate");
  revalidatePath(`/admin/suppliers/${supplierId}`);
  revalidatePath("/admin/suppliers");
  return result;
}

export async function setVerificationStatus(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const supplierId = String(formData.get("supplierId") ?? "");
  const status = String(formData.get("verificationStatus") ?? "") as VerificationStatus;
  const reason = (formData.get("reason") as string | null) || null;
  if (!supplierId || !status) return { error: "ورودی نامعتبر" };
  const result = await callRpc(
    "admin_set_verification_status",
    { p_supplier_id: supplierId, p_status: status, p_reason: reason },
    "verification",
  );
  revalidatePath(`/admin/suppliers/${supplierId}`);
  return result;
}

export async function setDocumentStatus(
  _prev: AdminSupplierActionState | null,
  formData: FormData,
): Promise<AdminSupplierActionState> {
  const documentId = String(formData.get("documentId") ?? "");
  const supplierId = String(formData.get("supplierId") ?? "");
  const status = String(formData.get("documentStatus") ?? "") as DocumentStatus;
  const reason = (formData.get("reason") as string | null) || null;
  if (!documentId || !status) return { error: "ورودی نامعتبر" };
  const result = await callRpc(
    "admin_set_document_status",
    { p_document_id: documentId, p_status: status, p_reason: reason },
    "doc-status",
  );
  if (supplierId) revalidatePath(`/admin/suppliers/${supplierId}`);
  return result;
}
