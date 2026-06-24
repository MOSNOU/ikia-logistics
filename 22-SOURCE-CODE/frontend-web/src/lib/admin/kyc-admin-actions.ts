"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  KycSubjectType,
  KycDocumentStatus,
  KycRiskSeverity,
  KycRiskStatus,
} from "@/types/database";

export interface KycAdminActionState {
  error?: string;
  ok?: boolean;
}

function detailPath(subjectType: KycSubjectType, id: string) {
  return `/admin/kyc/${subjectType}/${id}`;
}

export async function assignVerification(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const id = String(formData.get("verificationId") ?? "");
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  if (!id || (subjectType !== "person" && subjectType !== "organization")) {
    return { error: "ورودی نامعتبر" };
  }
  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_assign_verification", {
      p_verification_id: id,
      p_subject_type: subjectType,
    });
  if (error) {
    console.error("admin_assign_verification", error);
    return { error: "ارجاع ناموفق بود" };
  }
  revalidatePath(detailPath(subjectType, id));
  revalidatePath("/admin/kyc");
  return { ok: true };
}

export async function requestInfo(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const id = String(formData.get("verificationId") ?? "");
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const reason = String(formData.get("reason") ?? "").trim();
  if (!id || (subjectType !== "person" && subjectType !== "organization")) {
    return { error: "ورودی نامعتبر" };
  }
  if (!reason) return { error: "دلیل الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_request_info", {
      p_verification_id: id,
      p_subject_type: subjectType,
      p_reason: reason,
    });
  if (error) {
    console.error("admin_request_info", error);
    return { error: "درخواست اطلاعات ناموفق بود" };
  }
  revalidatePath(detailPath(subjectType, id));
  revalidatePath("/admin/kyc");
  return { ok: true };
}

export async function approveVerification(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const id = String(formData.get("verificationId") ?? "");
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const monthsRaw = formData.get("validityMonths");
  const validityMonths = monthsRaw ? Number(monthsRaw) : 12;

  if (!id || (subjectType !== "person" && subjectType !== "organization")) {
    return { error: "ورودی نامعتبر" };
  }
  if (!Number.isFinite(validityMonths) || validityMonths <= 0) {
    return { error: "اعتبار نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_approve_verification", {
      p_verification_id: id,
      p_subject_type: subjectType,
      p_validity_months: validityMonths,
    });
  if (error) {
    console.error("admin_approve_verification", error);
    return { error: "تأیید ناموفق بود" };
  }
  revalidatePath(detailPath(subjectType, id));
  revalidatePath("/admin/kyc");
  return { ok: true };
}

export async function rejectVerification(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const id = String(formData.get("verificationId") ?? "");
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const reason = String(formData.get("reason") ?? "").trim();

  if (!id || (subjectType !== "person" && subjectType !== "organization")) {
    return { error: "ورودی نامعتبر" };
  }
  if (!reason) return { error: "دلیل الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_reject_verification", {
      p_verification_id: id,
      p_subject_type: subjectType,
      p_reason: reason,
    });
  if (error) {
    console.error("admin_reject_verification", error);
    return { error: "رد ناموفق بود" };
  }
  revalidatePath(detailPath(subjectType, id));
  revalidatePath("/admin/kyc");
  return { ok: true };
}

export async function decideDocument(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const documentId = String(formData.get("documentId") ?? "");
  const decision = String(formData.get("decision") ?? "") as KycDocumentStatus;
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  // The detail-page redirect target — we revalidate the verification detail.
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const verificationId = String(formData.get("verificationId") ?? "");

  if (!documentId) return { error: "شناسه مدرک نامعتبر" };
  if (decision !== "accepted" && decision !== "rejected" && decision !== "superseded") {
    return { error: "تصمیم نامعتبر" };
  }
  if (decision === "rejected" && !reason) {
    return { error: "دلیل رد الزامی است" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_decide_document", {
      p_document_id: documentId,
      p_decision: decision,
      p_reason: reason,
    });
  if (error) {
    console.error("admin_decide_document", error);
    return { error: "تصمیم‌گیری مدرک ناموفق بود" };
  }
  if (verificationId && (subjectType === "person" || subjectType === "organization")) {
    revalidatePath(detailPath(subjectType, verificationId));
  }
  return { ok: true };
}

export async function raiseRiskFlag(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;
  const userId = (formData.get("userId") as string | null) || undefined;
  const organizationId = (formData.get("organizationId") as string | null) || undefined;
  const code = String(formData.get("code") ?? "").trim();
  const severity = (String(formData.get("severity") ?? "medium") as KycRiskSeverity);
  const source = (formData.get("source") as string | null)?.trim() || "manual";
  const detail = (formData.get("detail") as string | null)?.trim() || undefined;
  const verificationId = (formData.get("verificationId") as string | null) || undefined;

  if (subjectType !== "person" && subjectType !== "organization") {
    return { error: "نوع موضوع نامعتبر" };
  }
  if (!code) return { error: "کد الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_raise_risk_flag", {
      p_subject_type: subjectType,
      p_user_id: userId,
      p_organization_id: organizationId,
      p_code: code,
      p_severity: severity,
      p_detail: detail,
      p_source: source,
    });
  if (error) {
    console.error("admin_raise_risk_flag", error);
    return { error: "ثبت پرچم ریسک ناموفق بود" };
  }
  if (verificationId) {
    revalidatePath(detailPath(subjectType, verificationId));
  }
  return { ok: true };
}

export async function resolveRiskFlag(
  _prev: KycAdminActionState | null,
  formData: FormData,
): Promise<KycAdminActionState> {
  const flagId = String(formData.get("flagId") ?? "");
  const status = String(formData.get("status") ?? "") as KycRiskStatus;
  const note = (formData.get("note") as string | null)?.trim() || undefined;
  const verificationId = (formData.get("verificationId") as string | null) || undefined;
  const subjectType = String(formData.get("subjectType") ?? "") as KycSubjectType;

  if (!flagId) return { error: "شناسه پرچم نامعتبر" };
  if (status !== "acknowledged" && status !== "mitigated" && status !== "dismissed") {
    return { error: "وضعیت نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("kyc")
    .rpc("admin_resolve_risk_flag", {
      p_flag_id: flagId,
      p_status: status,
      p_note: note,
    });
  if (error) {
    console.error("admin_resolve_risk_flag", error);
    return { error: "حل پرچم ناموفق بود" };
  }
  if (verificationId && (subjectType === "person" || subjectType === "organization")) {
    revalidatePath(detailPath(subjectType, verificationId));
  }
  return { ok: true };
}
