"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { DocumentType } from "@/types/database";

export interface PortalActionState {
  error?: string;
  ok?: boolean;
}

const DOC_TYPES: DocumentType[] = [
  "license",
  "tax_certificate",
  "registration",
  "iso_certificate",
  "bank_letter",
  "other",
];

export async function upsertMyProfile(
  _prev: PortalActionState | null,
  formData: FormData,
): Promise<PortalActionState> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_upsert_my_profile", {
      p_display_name: (formData.get("displayName") as string | null) || null,
      p_description: (formData.get("description") as string | null) || null,
      p_website: (formData.get("website") as string | null) || null,
      p_contact_email: (formData.get("contactEmail") as string | null) || null,
      p_contact_phone: (formData.get("contactPhone") as string | null) || null,
      p_country_code: (formData.get("countryCode") as string | null) || null,
      p_established_year: formData.get("establishedYear")
        ? Number(formData.get("establishedYear"))
        : null,
    });

  if (error) {
    console.error("portal_upsert_my_profile", error);
    return { error: "ذخیره پروفایل ناموفق بود" };
  }

  revalidatePath("/supplier/profile");
  redirect("/supplier/profile");
}

export async function submitForReview(
  _prev: PortalActionState | null,
  _formData: FormData,
): Promise<PortalActionState> {
  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_submit_my_profile_for_review");

  if (error) {
    console.error("portal_submit_my_profile_for_review", error);
    return { error: "ارسال برای بررسی ناموفق بود" };
  }

  revalidatePath("/supplier/profile");
  return { ok: true };
}

export async function addMyCategory(
  _prev: PortalActionState | null,
  formData: FormData,
): Promise<PortalActionState> {
  const categoryId = String(formData.get("categoryId") ?? "");
  if (!categoryId) return { error: "دسته‌بندی نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_add_my_category", { p_category_id: categoryId });

  if (error) {
    console.error("portal_add_my_category", error);
    return { error: "افزودن دسته‌بندی ناموفق بود" };
  }
  revalidatePath("/supplier/categories");
  return { ok: true };
}

export async function removeMyCategory(
  _prev: PortalActionState | null,
  formData: FormData,
): Promise<PortalActionState> {
  const categoryId = String(formData.get("categoryId") ?? "");
  if (!categoryId) return { error: "دسته‌بندی نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_remove_my_category", { p_category_id: categoryId });

  if (error) {
    console.error("portal_remove_my_category", error);
    return { error: "حذف دسته‌بندی ناموفق بود" };
  }
  revalidatePath("/supplier/categories");
  return { ok: true };
}

export async function addMyDocument(
  _prev: PortalActionState | null,
  formData: FormData,
): Promise<PortalActionState> {
  const documentType = String(formData.get("documentType") ?? "") as DocumentType;
  const title = String(formData.get("title") ?? "").trim();
  const description = (formData.get("description") as string | null) || null;
  const externalReference = (formData.get("externalReference") as string | null) || null;
  const issuedAt = (formData.get("issuedAt") as string | null) || null;
  const expiresAt = (formData.get("expiresAt") as string | null) || null;

  if (!DOC_TYPES.includes(documentType) || !title) {
    return { error: "ورودی نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_add_my_document", {
      p_document_type: documentType,
      p_title: title,
      p_description: description,
      p_external_reference: externalReference,
      p_issued_at: issuedAt,
      p_expires_at: expiresAt,
    });

  if (error) {
    console.error("portal_add_my_document", error);
    return { error: "افزودن مدرک ناموفق بود" };
  }
  revalidatePath("/supplier/documents");
  redirect("/supplier/documents");
}

export async function removeMyDocument(
  _prev: PortalActionState | null,
  formData: FormData,
): Promise<PortalActionState> {
  const documentId = String(formData.get("documentId") ?? "");
  if (!documentId) return { error: "شناسه مدرک نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("supplier")
    .rpc("portal_remove_my_document", { p_document_id: documentId });

  if (error) {
    console.error("portal_remove_my_document", error);
    return { error: "حذف مدرک ناموفق بود" };
  }
  revalidatePath("/supplier/documents");
  return { ok: true };
}
