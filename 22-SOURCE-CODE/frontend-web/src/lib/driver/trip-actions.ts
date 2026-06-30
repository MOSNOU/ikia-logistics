"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Phase D3 — Driver trip workflow transition Server Actions.
//
// Thin wrappers over the D1 SECURITY DEFINER transition RPCs (dispatch schema).
// All authorization (driver role, trip ownership, "dispatch released", legal
// from→to transition, POD-required-for-complete) is enforced inside the RPC;
// these actions add a friendly Persian surface and revalidate the driver views.
//
// No raw database errors are ever returned to the client. GPS, POD upload and
// issue reporting are NOT implemented here (D4 / later).
//
// TODO(D-later): drop the `as any` once Supabase types are regenerated for the
// dispatch.driver_* RPCs.

export interface TripActionResult {
  ok: boolean;
  message: string;
}

function friendlyError(error: { code?: string; message?: string } | null): string {
  const code = error?.code ?? "";
  const msg = (error?.message ?? "").toLowerCase();
  if (code === "42501" || msg.includes("permission") || msg.includes("driver role") || msg.includes("owns")) {
    return "شما به این سفر دسترسی ندارید.";
  }
  if (msg.includes("invalid transition")) {
    return "این عملیات برای وضعیت فعلی سفر مجاز نیست.";
  }
  if (msg.includes("pod")) {
    return "برای تکمیل سفر ابتدا باید سند تحویل بارگذاری شود.";
  }
  if (msg.includes("released")) {
    return "این سفر هنوز برای اجرا آزاد نشده است.";
  }
  return "انجام عملیات ممکن نشد. لطفاً دوباره تلاش کنید.";
}

async function callTransition(dispatchId: string, rpc: string): Promise<TripActionResult> {
  if (!dispatchId) return { ok: false, message: "شناسه سفر نامعتبر است." };

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("dispatch") as any).rpc(rpc, {
    p_dispatch_id: dispatchId,
  });

  if (error) {
    console.error(`driver.${rpc}`, error);
    return { ok: false, message: friendlyError(error) };
  }

  revalidatePath("/driver");
  revalidatePath(`/driver/trips/${dispatchId}`);
  return { ok: true, message: "وضعیت سفر به‌روزرسانی شد." };
}

export async function acceptTrip(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_accept_trip");
}
export async function arrivePickup(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_arrive_pickup");
}
export async function startLoading(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_start_loading");
}
export async function confirmLoaded(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_confirm_loaded");
}
export async function startTransit(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_start_transit");
}
export async function arriveDelivery(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_arrive_delivery");
}
export async function startUnloading(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_start_unloading");
}
export async function confirmDelivered(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_confirm_delivered");
}

// driver_complete_trip is POD-gated in D1. In D4 it is surfaced via the trip
// action panel ONCE a POD exists (TripActionPanel reads hasPod). It still
// handles the POD-required error gracefully if the server disagrees.
export async function completeTrip(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_complete_trip");
}

// ---------------------------------------------------------------------------
// Phase D4 — manual GPS position send + POD upload.
// ---------------------------------------------------------------------------

const POD_BUCKET = "app-documents";
const POD_MAX_BYTES = 10 * 1024 * 1024; // 10 MiB
const POD_ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
]);

function podFileType(mimeType: string): "image" | "pdf" | "other" {
  if (mimeType.startsWith("image/")) return "image";
  if (mimeType === "application/pdf") return "pdf";
  return "other";
}

// Manual, one-shot GPS position send. NO background tracking / watchPosition;
// the client captures a single fix and calls this. The D1 RPC asserts the trip
// is owned and in an ACTIVE execution status.
export async function sendDriverPosition(
  dispatchId: string,
  payload: {
    latitude: number;
    longitude: number;
    accuracyMeters?: number | null;
    reportedAt: string;
  },
): Promise<TripActionResult> {
  if (!dispatchId) return { ok: false, message: "شناسه سفر نامعتبر است." };
  if (
    !Number.isFinite(payload.latitude) ||
    !Number.isFinite(payload.longitude)
  ) {
    return { ok: false, message: "موقعیت دریافت‌شده نامعتبر است." };
  }

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("dispatch") as any).rpc(
    "driver_send_position", // TODO(D-later): typed once Supabase types regenerated
    {
      p_dispatch_id: dispatchId,
      p_latitude: payload.latitude,
      p_longitude: payload.longitude,
      p_reported_at: payload.reportedAt,
      p_accuracy_meters: payload.accuracyMeters ?? null,
    },
  );

  if (error) {
    console.error("driver.driver_send_position", error);
    return { ok: false, message: friendlyError(error) };
  }

  revalidatePath("/driver");
  revalidatePath(`/driver/trips/${dispatchId}`);
  return { ok: true, message: "موقعیت با موفقیت ثبت شد." };
}

export interface RegisterPodResult {
  ok: boolean;
  message?: string;
  fileId?: string;
  bucket?: string;
  objectKey?: string;
  uploadUrl?: string;
  uploadToken?: string;
}

// Step 1+2 of the POD upload: register the file row (app_storage) and mint a
// signed upload URL. Reuses the existing private "app-documents" bucket — there
// is no dedicated `pod` bucket yet (recommended later infra task).
export async function registerPodUpload(
  dispatchId: string,
  input: { filename: string; mimeType: string; sizeBytes: number },
): Promise<RegisterPodResult> {
  if (!dispatchId) return { ok: false, message: "شناسه سفر نامعتبر است." };
  if (!POD_ALLOWED_MIME.has(input.mimeType)) {
    return {
      ok: false,
      message: "نوع فایل پشتیبانی نمی‌شود. تصویر یا PDF بارگذاری کنید.",
    };
  }
  if (
    !Number.isFinite(input.sizeBytes) ||
    input.sizeBytes <= 0 ||
    input.sizeBytes > POD_MAX_BYTES
  ) {
    return {
      ok: false,
      message: "حجم فایل بیش از حد مجاز است (حداکثر ۱۰ مگابایت).",
    };
  }

  const supabase = await createClient();
  const { data: regData, error: regError } = await supabase
    .schema("app_storage")
    .rpc("portal_register_file", {
      p_filename: input.filename,
      p_mime_type: input.mimeType,
      p_size_bytes: input.sizeBytes,
      p_bucket: POD_BUCKET,
      p_file_type: podFileType(input.mimeType),
    });
  if (regError || !regData) {
    console.error("portal_register_file (pod)", regError);
    return { ok: false, message: "ثبت فایل ناموفق بود." };
  }
  const result = regData as {
    file_id: string;
    bucket: string;
    object_key: string;
  };

  const { data: signed, error: signedErr } = await supabase.storage
    .from(result.bucket)
    .createSignedUploadUrl(result.object_key);
  if (signedErr || !signed) {
    console.error("createSignedUploadUrl (pod)", signedErr);
    return { ok: false, message: "دریافت لینک بارگذاری ناموفق بود." };
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

// Step 4 of the POD upload: finalize the uploaded bytes then attach the file as
// a POD to the dispatch. The D1 RPC validates the uploader == auth.uid() and
// that the driver owns the released dispatch.
export async function finalizeAndAttachPod(
  dispatchId: string,
  fileId: string,
  sizeBytes: number,
  kind: string,
): Promise<TripActionResult> {
  if (!dispatchId || !fileId) {
    return { ok: false, message: "ورودی نامعتبر است." };
  }

  const supabase = await createClient();
  const { error: finalizeErr } = await supabase
    .schema("app_storage")
    .rpc("portal_finalize_file_upload", {
      p_file_id: fileId,
      p_size_bytes: sizeBytes,
    });
  if (finalizeErr) {
    console.error("portal_finalize_file_upload (pod)", finalizeErr);
    return { ok: false, message: "نهایی‌سازی بارگذاری ناموفق بود." };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error: attachErr } = await (supabase.schema("dispatch") as any).rpc(
    "driver_attach_pod", // TODO(D-later): typed once Supabase types regenerated
    {
      p_dispatch_id: dispatchId,
      p_file_id: fileId,
      p_kind: kind,
    },
  );
  if (attachErr) {
    console.error("driver.driver_attach_pod", attachErr);
    return { ok: false, message: friendlyError(attachErr) };
  }

  revalidatePath("/driver");
  revalidatePath(`/driver/trips/${dispatchId}`);
  return { ok: true, message: "سند تحویل با موفقیت ثبت شد." };
}
