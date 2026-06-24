"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface DispatchActionState {
  ok?: boolean;
  error?: string;
  dispatchId?: string;
}

function trimOrUndef(v: FormDataEntryValue | null): string | undefined {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length === 0 ? undefined : s;
}

function revalidateAll(dispatchId?: string) {
  revalidatePath("/buyer/dispatches");
  revalidatePath("/carrier/dispatches");
  revalidatePath("/admin/dispatches");
  if (dispatchId) {
    revalidatePath(`/buyer/dispatches/${dispatchId}`);
    revalidatePath(`/carrier/dispatches/${dispatchId}`);
    revalidatePath(`/admin/dispatches/${dispatchId}`);
  }
}

function translateError(code: string | undefined, fallback: string): string {
  if (code === "42501") return "اجازه دسترسی برای این عملیات وجود ندارد.";
  if (code === "P0002") return "اعزام یا منبع مرتبط یافت نشد.";
  if (code === "P0001") return "وضعیت فعلی اجازه این تغییر را نمی‌دهد.";
  if (code === "22023") return "ورودی نامعتبر است.";
  return fallback;
}

export async function createDispatch(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const bookingRequestId = trimOrUndef(formData.get("bookingRequestId"));
  if (!bookingRequestId) return { error: "شناسه رزرو الزامی است." };
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispatch")
    .rpc("carrier_create_dispatch", {
      p_booking_request_id: bookingRequestId,
      p_vehicle_reference: trimOrUndef(formData.get("vehicleReference")),
      p_vehicle_type: trimOrUndef(formData.get("vehicleType")),
      p_driver_name: trimOrUndef(formData.get("driverName")),
      p_driver_phone: trimOrUndef(formData.get("driverPhone")),
      p_planned_pickup_at: trimOrUndef(formData.get("plannedPickupAt")),
      p_notes_fa: trimOrUndef(formData.get("notesFa")),
      p_notes_en: trimOrUndef(formData.get("notesEn")),
    });
  if (error) {
    console.error("carrier_create_dispatch", error);
    return { error: translateError(error.code, "ثبت اعزام ناموفق بود.") };
  }
  const dispatchId = typeof data === "string" ? data : undefined;
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function updateDispatchPlaceholders(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("carrier_update_dispatch_placeholders", {
      p_dispatch_id: dispatchId,
      p_vehicle_reference: trimOrUndef(formData.get("vehicleReference")),
      p_vehicle_type: trimOrUndef(formData.get("vehicleType")),
      p_driver_name: trimOrUndef(formData.get("driverName")),
      p_driver_phone: trimOrUndef(formData.get("driverPhone")),
      p_planned_pickup_at: trimOrUndef(formData.get("plannedPickupAt")),
      p_notes_fa: trimOrUndef(formData.get("notesFa")),
      p_notes_en: trimOrUndef(formData.get("notesEn")),
    });
  if (error) {
    console.error("carrier_update_dispatch_placeholders", error);
    return { error: translateError(error.code, "به‌روزرسانی ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function markDispatchReady(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("carrier_mark_ready", { p_dispatch_id: dispatchId });
  if (error) {
    console.error("carrier_mark_ready", error);
    return { error: translateError(error.code, "علامت‌گذاری ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function releaseDispatch(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const notes = trimOrUndef(formData.get("notes"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("carrier_release_dispatch", { p_dispatch_id: dispatchId, p_notes: notes });
  if (error) {
    console.error("carrier_release_dispatch", error);
    return { error: translateError(error.code, "آزادسازی ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function cancelDispatchAsCarrier(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("carrier_cancel_dispatch", { p_dispatch_id: dispatchId, p_reason: reason });
  if (error) {
    console.error("carrier_cancel_dispatch", error);
    return { error: translateError(error.code, "لغو ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function cancelDispatchAsBuyer(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("buyer_cancel_dispatch", { p_dispatch_id: dispatchId, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_dispatch", error);
    return { error: translateError(error.code, "لغو ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}

export async function cancelDispatchAsAdmin(
  _prev: DispatchActionState | null,
  formData: FormData,
): Promise<DispatchActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("dispatch")
    .rpc("admin_cancel_dispatch", { p_dispatch_id: dispatchId, p_reason: reason });
  if (error) {
    console.error("admin_cancel_dispatch", error);
    return { error: translateError(error.code, "لغو ادمین ناموفق بود.") };
  }
  revalidateAll(dispatchId);
  return { ok: true, dispatchId };
}
