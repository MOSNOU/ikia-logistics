"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { parseFileRegisterForm } from "./schemas";

const DOC_ENTITY_TYPE = "shipment_document";
const DEFAULT_BUCKET = "app-documents";

export interface FileActionState {
  ok?: boolean;
  error?: string;
  fieldErrors?: Record<string, string>;
}

export interface RegisterFileResult extends FileActionState {
  fileId?: string;
  bucket?: string;
  objectKey?: string;
  uploadUrl?: string;
  uploadToken?: string;
}

function revalidateForDocument(documentId: string) {
  revalidatePath(`/buyer/documents/${documentId}`);
  revalidatePath(`/buyer/documents/${documentId}/files`);
}

export async function registerFileForDocument(
  _prev: RegisterFileResult | null,
  formData: FormData,
): Promise<RegisterFileResult> {
  const documentId = String(formData.get("documentId") ?? "");
  if (!documentId) return { error: "شناسه مدرک نامعتبر" };
  const parsed = parseFileRegisterForm(formData);
  if (!parsed.ok) return { error: parsed.error, fieldErrors: parsed.fieldErrors };
  const { filename, mimeType, sizeBytes, fileType } = parsed.value;

  const supabase = await createClient();
  const { data: regData, error: regError } = await supabase
    .schema("app_storage")
    .rpc("portal_register_file", {
      p_filename: filename,
      p_mime_type: mimeType,
      p_size_bytes: sizeBytes,
      p_bucket: DEFAULT_BUCKET,
      p_file_type: fileType ?? "other",
    });
  if (regError || !regData) {
    console.error("portal_register_file", regError);
    return { error: "ثبت فایل ناموفق بود" };
  }
  const result = regData as {
    file_id: string;
    bucket: string;
    object_key: string;
  };

  const { data: signed, error: signedErr } = await supabase
    .storage
    .from(result.bucket)
    .createSignedUploadUrl(result.object_key);
  if (signedErr || !signed) {
    console.error("createSignedUploadUrl", signedErr);
    return {
      error: "دریافت لینک بارگذاری ناموفق بود",
      fileId: result.file_id,
      bucket: result.bucket,
      objectKey: result.object_key,
    };
  }

  return {
    ok: true,
    fileId: result.file_id,
    bucket: result.bucket,
    objectKey: result.object_key,
    uploadUrl: signed.signedUrl,
    uploadToken: signed.token,
  };
}

export async function finalizeDocumentFile(
  _prev: FileActionState | null,
  formData: FormData,
): Promise<FileActionState> {
  const fileId = String(formData.get("fileId") ?? "");
  const documentId = String(formData.get("documentId") ?? "");
  if (!fileId || !documentId) return { error: "ورودی نامعتبر" };
  const sizeStr = (formData.get("sizeBytes") as string | null)?.trim();
  const checksum = (formData.get("checksum") as string | null)?.trim() || undefined;
  const sizeBytes = sizeStr ? Number.parseInt(sizeStr, 10) : undefined;

  const supabase = await createClient();
  const { error: finalizeErr } = await supabase
    .schema("app_storage")
    .rpc("portal_finalize_file_upload", {
      p_file_id: fileId,
      p_size_bytes: sizeBytes,
      p_checksum: checksum,
    });
  if (finalizeErr) {
    console.error("portal_finalize_file_upload", finalizeErr);
    return { error: "نهایی‌سازی بارگذاری ناموفق بود" };
  }

  const { error: linkErr } = await supabase
    .schema("app_storage")
    .rpc("portal_link_file_to_entity", {
      p_file_id: fileId,
      p_entity_type: DOC_ENTITY_TYPE,
      p_entity_id: documentId,
    });
  if (linkErr) {
    console.error("portal_link_file_to_entity", linkErr);
    return { error: "اتصال فایل به مدرک ناموفق بود" };
  }

  revalidateForDocument(documentId);
  return { ok: true };
}

export async function archiveDocumentFile(
  _prev: FileActionState | null,
  formData: FormData,
): Promise<FileActionState> {
  const fileId = String(formData.get("fileId") ?? "");
  const documentId = String(formData.get("documentId") ?? "");
  const reason = (formData.get("reason") as string | null)?.trim() || undefined;
  if (!fileId || !documentId) return { error: "ورودی نامعتبر" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("app_storage")
    .rpc("portal_archive_file", {
      p_file_id: fileId,
      p_reason: reason,
    });
  if (error) {
    console.error("portal_archive_file", error);
    return { error: "بایگانی فایل ناموفق بود" };
  }
  revalidateForDocument(documentId);
  return { ok: true };
}

export interface CreateVersionResult extends FileActionState {
  versionNumber?: number;
  bucket?: string;
  objectKey?: string;
  uploadUrl?: string;
  uploadToken?: string;
}

export async function createDocumentFileVersion(
  _prev: CreateVersionResult | null,
  formData: FormData,
): Promise<CreateVersionResult> {
  const fileId = String(formData.get("fileId") ?? "");
  const documentId = String(formData.get("documentId") ?? "");
  if (!fileId || !documentId) return { error: "ورودی نامعتبر" };
  const mimeType = (formData.get("mimeType") as string | null)?.trim() || undefined;
  const sizeStr = (formData.get("sizeBytes") as string | null)?.trim();
  const sizeBytes = sizeStr ? Number.parseInt(sizeStr, 10) : undefined;

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("app_storage")
    .rpc("portal_create_file_version", {
      p_file_id: fileId,
      p_mime_type: mimeType,
      p_size_bytes: sizeBytes,
    });
  if (error || !data) {
    console.error("portal_create_file_version", error);
    return { error: "ایجاد نسخه جدید ناموفق بود" };
  }
  const result = data as {
    file_id: string;
    version_number: number;
    bucket: string;
    object_key: string;
  };

  const { data: signed, error: signedErr } = await supabase
    .storage
    .from(result.bucket)
    .createSignedUploadUrl(result.object_key);
  if (signedErr || !signed) {
    console.error("createSignedUploadUrl (version)", signedErr);
    return {
      error: "دریافت لینک بارگذاری ناموفق بود",
      versionNumber: result.version_number,
      bucket: result.bucket,
      objectKey: result.object_key,
    };
  }

  revalidateForDocument(documentId);
  return {
    ok: true,
    versionNumber: result.version_number,
    bucket: result.bucket,
    objectKey: result.object_key,
    uploadUrl: signed.signedUrl,
    uploadToken: signed.token,
  };
}

export interface DocumentFileRow {
  file_id: string;
  association_id: string;
  role: string | null;
  bucket: string;
  object_key: string;
  filename: string;
  mime_type: string | null;
  size_bytes: number | null;
  status: string;
  current_version: number;
  created_at: string;
  updated_at: string;
}

export async function listDocumentFiles(documentId: string): Promise<DocumentFileRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("app_storage")
    .rpc("portal_list_files_for_entity", {
      p_entity_type: DOC_ENTITY_TYPE,
      p_entity_id: documentId,
    });
  if (error) {
    console.error("portal_list_files_for_entity", error);
    return [];
  }
  return (data ?? []) as unknown as DocumentFileRow[];
}
