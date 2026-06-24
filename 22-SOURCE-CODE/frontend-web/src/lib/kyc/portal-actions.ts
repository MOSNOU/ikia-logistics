"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { KycDocumentKind, KycSubjectType } from "@/types/database";

export interface KycActionState {
  error?: string;
  ok?: boolean;
}

// =============================================================================
// Personal KYC actions
// =============================================================================

export async function startPersonal(
  _prev: KycActionState | null,
  _formData: FormData,
): Promise<KycActionState> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("start_personal_verification");
  if (error) {
    console.error("start_personal_verification", error);
    return { error: "شروع احراز هویت ناموفق بود" };
  }
  revalidatePath("/profile/kyc");
  return { ok: true };
}

export async function updatePersonalDraft(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const id = String(formData.get("verificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("update_personal_draft", {
      p_id: id,
      p_full_legal_name: (formData.get("fullLegalName") as string | null) || undefined,
      p_national_id_number: (formData.get("nationalIdNumber") as string | null) || undefined,
      p_date_of_birth: (formData.get("dateOfBirth") as string | null) || undefined,
      p_country_code: (formData.get("countryCode") as string | null) || undefined,
    });
  if (error) {
    console.error("update_personal_draft", error);
    return { error: "ذخیره پیش‌نویس ناموفق بود" };
  }
  revalidatePath("/profile/kyc");
  return { ok: true };
}

export async function submitPersonal(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const id = String(formData.get("verificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("submit_personal_verification", { p_id: id });
  if (error) {
    console.error("submit_personal_verification", error);
    return { error: "ارسال برای بررسی ناموفق بود" };
  }
  revalidatePath("/profile/kyc");
  return { ok: true };
}

// =============================================================================
// Organization KYB actions
// =============================================================================

export async function startOrganization(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const organizationId = String(formData.get("organizationId") ?? "");
  if (!organizationId) return { error: "سازمان نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("start_organization_verification", { p_organization_id: organizationId });
  if (error) {
    console.error("start_organization_verification", error);
    return { error: "شروع احراز سازمان ناموفق بود" };
  }
  revalidatePath("/supplier/kyb");
  return { ok: true };
}

export async function updateOrganizationDraft(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const id = String(formData.get("verificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("update_organization_draft", {
      p_id: id,
      p_legal_name: (formData.get("legalName") as string | null) || undefined,
      p_registration_number: (formData.get("registrationNumber") as string | null) || undefined,
      p_tax_id: (formData.get("taxId") as string | null) || undefined,
      p_country_code: (formData.get("countryCode") as string | null) || undefined,
      p_incorporated_on: (formData.get("incorporatedOn") as string | null) || undefined,
    });
  if (error) {
    console.error("update_organization_draft", error);
    return { error: "ذخیره پیش‌نویس ناموفق بود" };
  }
  revalidatePath("/supplier/kyb");
  return { ok: true };
}

export async function submitOrganization(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const id = String(formData.get("verificationId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("submit_organization_verification", { p_id: id });
  if (error) {
    console.error("submit_organization_verification", error);
    return { error: "ارسال برای بررسی ناموفق بود" };
  }
  revalidatePath("/supplier/kyb");
  return { ok: true };
}

// =============================================================================
// Shared: attach a document (metadata-only per Q4=A).
// =============================================================================

export async function attachDocument(
  _prev: KycActionState | null,
  formData: FormData,
): Promise<KycActionState> {
  const verificationId = String(formData.get("verificationId") ?? "");
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const documentKind = String(formData.get("documentKind") ?? "") as KycDocumentKind;
  const storagePath = String(formData.get("storagePath") ?? "").trim();
  const title = (formData.get("title") as string | null)?.trim() || undefined;
  const mimeType = (formData.get("mimeType") as string | null)?.trim() || undefined;
  const issuedOn = (formData.get("issuedOn") as string | null) || undefined;
  const expiresOn = (formData.get("expiresOn") as string | null) || undefined;

  if (!verificationId || !subjectType || !documentKind || !storagePath) {
    return { error: "ورودی نامعتبر" };
  }
  if (subjectType !== "person" && subjectType !== "organization") {
    return { error: "نوع موضوع نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("attach_document", {
      p_verification_id: verificationId,
      p_subject_type: subjectType,
      p_document_kind: documentKind,
      p_storage_path: storagePath,
      p_title: title,
      p_mime_type: mimeType,
      p_issued_on: issuedOn,
      p_expires_on: expiresOn,
    });
  if (error) {
    console.error("attach_document", error);
    return { error: "افزودن مدرک ناموفق بود" };
  }
  revalidatePath(subjectType === "person" ? "/profile/kyc" : "/supplier/kyb");
  return { ok: true };
}
