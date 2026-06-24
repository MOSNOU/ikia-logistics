"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export interface BookingActionState {
  ok?: boolean;
  error?: string;
  bookingId?: string;
}

function trimOrUndef(v: FormDataEntryValue | null): string | undefined {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length === 0 ? undefined : s;
}

function revalidateAll(bookingId?: string) {
  revalidatePath("/buyer/bookings");
  revalidatePath("/carrier/bookings");
  revalidatePath("/admin/bookings");
  if (bookingId) {
    revalidatePath(`/buyer/bookings/${bookingId}`);
    revalidatePath(`/carrier/bookings/${bookingId}`);
    revalidatePath(`/admin/bookings/${bookingId}`);
  }
}

function translateError(code: string | undefined, fallback: string): string {
  if (code === "42501") return "اجازه دسترسی برای این عملیات وجود ندارد.";
  if (code === "P0002") return "رزرو یا منبع مرتبط یافت نشد.";
  if (code === "P0001") return "وضعیت فعلی اجازه این تغییر را نمی‌دهد.";
  if (code === "22023") return "ورودی نامعتبر است.";
  return fallback;
}

export async function createBooking(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const shipmentId = trimOrUndef(formData.get("shipmentId"));
  const capacityListingId = trimOrUndef(formData.get("capacityListingId"));
  if (!shipmentId || !capacityListingId) {
    return { error: "شیپمنت و ظرفیت الزامی است." };
  }
  const requestedQuantityRaw = trimOrUndef(formData.get("requestedQuantityUnits"));
  let requestedQuantity: number | undefined;
  if (requestedQuantityRaw) {
    const n = Number.parseFloat(requestedQuantityRaw);
    if (!Number.isFinite(n) || n < 0) {
      return { error: "مقدار ظرفیت نامعتبر است." };
    }
    requestedQuantity = n;
  }
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("buyer_create_booking_request", {
      p_shipment_id: shipmentId,
      p_capacity_listing_id: capacityListingId,
      p_requested_quantity_units: requestedQuantity,
      p_requested_unit_label: trimOrUndef(formData.get("requestedUnitLabel")),
      p_requested_pickup_at: trimOrUndef(formData.get("requestedPickupAt")),
      p_expires_at: trimOrUndef(formData.get("expiresAt")),
      p_notes_fa: trimOrUndef(formData.get("notesFa")),
      p_notes_en: trimOrUndef(formData.get("notesEn")),
    });
  if (error) {
    console.error("buyer_create_booking_request", error);
    return { error: translateError(error.code, "ثبت رزرو ناموفق بود.") };
  }
  const bookingId = typeof data === "string" ? data : undefined;
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}

export async function confirmBooking(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const bookingId = trimOrUndef(formData.get("bookingId"));
  if (!bookingId) return { error: "شناسه رزرو نامعتبر." };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("buyer_confirm_booking", { p_booking_id: bookingId });
  if (error) {
    console.error("buyer_confirm_booking", error);
    return { error: translateError(error.code, "تأیید رزرو ناموفق بود.") };
  }
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}

export async function cancelBookingAsBuyer(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const bookingId = trimOrUndef(formData.get("bookingId"));
  if (!bookingId) return { error: "شناسه رزرو نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("buyer_cancel_booking", { p_booking_id: bookingId, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_booking", error);
    return { error: translateError(error.code, "لغو رزرو ناموفق بود.") };
  }
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}

export async function acceptBookingAsCarrier(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const bookingId = trimOrUndef(formData.get("bookingId"));
  if (!bookingId) return { error: "شناسه رزرو نامعتبر." };
  const notes = trimOrUndef(formData.get("notes"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("carrier_accept_booking", { p_booking_id: bookingId, p_notes: notes });
  if (error) {
    console.error("carrier_accept_booking", error);
    return { error: translateError(error.code, "پذیرش رزرو ناموفق بود.") };
  }
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}

export async function rejectBookingAsCarrier(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const bookingId = trimOrUndef(formData.get("bookingId"));
  if (!bookingId) return { error: "شناسه رزرو نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("carrier_reject_booking", { p_booking_id: bookingId, p_reason: reason });
  if (error) {
    console.error("carrier_reject_booking", error);
    return { error: translateError(error.code, "رد رزرو ناموفق بود.") };
  }
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}

export async function cancelBookingAsAdmin(
  _prev: BookingActionState | null,
  formData: FormData,
): Promise<BookingActionState> {
  const bookingId = trimOrUndef(formData.get("bookingId"));
  if (!bookingId) return { error: "شناسه رزرو نامعتبر." };
  const reason = trimOrUndef(formData.get("reason"));
  const supabase = await createClient();
  const { error } = await supabase
    .schema("marketplace")
    .rpc("admin_cancel_booking", { p_booking_id: bookingId, p_reason: reason });
  if (error) {
    console.error("admin_cancel_booking", error);
    return { error: translateError(error.code, "لغو ادمین ناموفق بود.") };
  }
  revalidateAll(bookingId);
  return { ok: true, bookingId };
}
