"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// CC-48 — Carrier-only Server Actions over the four CC-45 write RPCs:
//   telematics.carrier_start_telemetry_session
//   telematics.carrier_end_telemetry_session
//   telematics.carrier_report_position
//   telematics.carrier_report_telemetry_event
//
// All validation is defensive: range checks here are the front-line, but the
// SECURITY DEFINER RPC + fn_assert_carrier_for_dispatch_telemetry still gate
// the writes server-side. session_started / session_ended are intentionally
// rejected by the generic event RPC at the database level; we mirror that
// refusal client-side so the surface stays honest.

export interface TelematicsActionState {
  ok?: boolean;
  error?: string;
  ts?: string;
}

// Persian event labels for the carrier-event subset (signal_lost, etc.).
export const CARRIER_EVENT_TYPES = [
  "signal_lost",
  "signal_restored",
  "position_anomaly",
] as const;
export type CarrierEventType = (typeof CARRIER_EVENT_TYPES)[number];

function trimOrUndef(v: FormDataEntryValue | null): string | undefined {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length === 0 ? undefined : s;
}

function numOrUndef(v: FormDataEntryValue | null): number | undefined {
  const s = trimOrUndef(v);
  if (s === undefined) return undefined;
  const n = Number(s);
  return Number.isFinite(n) ? n : undefined;
}

function inRange(n: number | undefined, lo: number, hi: number): boolean {
  if (n === undefined) return true;
  return Number.isFinite(n) && n >= lo && n <= hi;
}

function translateError(code: string | undefined, fallback: string): string {
  if (code === "42501") return "اجازه دسترسی برای این عملیات وجود ندارد.";
  if (code === "P0002") return "اعزام یا منبع مرتبط یافت نشد.";
  if (code === "P0001") return "وضعیت فعلی اجازه این تغییر را نمی‌دهد.";
  if (code === "22023") return "ورودی نامعتبر است.";
  return fallback;
}

function revalidateAll(shipmentId?: string) {
  revalidatePath("/carrier/dispatches");
  revalidatePath("/admin/tracking/live");
  if (shipmentId) {
    revalidatePath(`/carrier/tracking/${shipmentId}/report`);
    revalidatePath(`/carrier/tracking/${shipmentId}/map`);
    revalidatePath(`/admin/tracking/${shipmentId}/map`);
    revalidatePath(`/buyer/tracking/${shipmentId}/map`);
  }
}

export async function startTelemetrySession(
  _prev: TelematicsActionState | null,
  formData: FormData,
): Promise<TelematicsActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  const shipmentId = trimOrUndef(formData.get("shipmentId"));
  if (!dispatchId) return { error: "شناسه اعزام الزامی است." };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("telematics")
    .rpc("carrier_start_telemetry_session", {
      p_dispatch_id: dispatchId,
      p_notes: trimOrUndef(formData.get("notes")),
    });
  if (error) {
    console.error("carrier_start_telemetry_session", error);
    return { error: translateError(error.code, "شروع ردیابی ناموفق بود.") };
  }
  revalidateAll(shipmentId);
  return { ok: true, ts: new Date().toISOString() };
}

export async function endTelemetrySession(
  _prev: TelematicsActionState | null,
  formData: FormData,
): Promise<TelematicsActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  const shipmentId = trimOrUndef(formData.get("shipmentId"));
  if (!dispatchId) return { error: "شناسه اعزام الزامی است." };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("telematics")
    .rpc("carrier_end_telemetry_session", {
      p_dispatch_id: dispatchId,
      p_notes: trimOrUndef(formData.get("notes")),
    });
  if (error) {
    console.error("carrier_end_telemetry_session", error);
    return { error: translateError(error.code, "پایان ردیابی ناموفق بود.") };
  }
  revalidateAll(shipmentId);
  return { ok: true, ts: new Date().toISOString() };
}

export async function reportPosition(
  _prev: TelematicsActionState | null,
  formData: FormData,
): Promise<TelematicsActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  const shipmentId = trimOrUndef(formData.get("shipmentId"));
  if (!dispatchId) return { error: "شناسه اعزام الزامی است." };

  const lat = numOrUndef(formData.get("latitude"));
  const lng = numOrUndef(formData.get("longitude"));
  if (lat === undefined || lng === undefined) {
    return { error: "عرض و طول جغرافیایی الزامی هستند." };
  }
  if (!inRange(lat, -90, 90)) {
    return { error: "عرض جغرافیایی باید بین -۹۰ و ۹۰ باشد." };
  }
  if (!inRange(lng, -180, 180)) {
    return { error: "طول جغرافیایی باید بین -۱۸۰ و ۱۸۰ باشد." };
  }

  const speed = numOrUndef(formData.get("speedKmh"));
  const heading = numOrUndef(formData.get("headingDegrees"));
  const accuracy = numOrUndef(formData.get("accuracyMeters"));
  const altitude = numOrUndef(formData.get("altitudeMeters"));

  if (!inRange(speed, 0, 400)) {
    return { error: "سرعت باید بین ۰ و ۴۰۰ کیلومتر بر ساعت باشد." };
  }
  if (!inRange(heading, 0, 360)) {
    return { error: "جهت باید بین ۰ و ۳۶۰ درجه باشد." };
  }
  if (!inRange(accuracy, 0, 10_000)) {
    return { error: "دقت باید بین ۰ و ۱۰۰۰۰ متر باشد." };
  }
  if (!inRange(altitude, -500, 10_000)) {
    return { error: "ارتفاع باید بین -۵۰۰ و ۱۰۰۰۰ متر باشد." };
  }

  const reportedAtRaw = trimOrUndef(formData.get("reportedAt"));
  const reportedAt = reportedAtRaw
    ? new Date(reportedAtRaw).toISOString()
    : new Date().toISOString();
  if (!Number.isFinite(new Date(reportedAt).getTime())) {
    return { error: "زمان گزارش نامعتبر است." };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("telematics")
    .rpc("carrier_report_position", {
      p_dispatch_id: dispatchId,
      p_latitude: lat,
      p_longitude: lng,
      p_reported_at: reportedAt,
      p_speed_kmh: speed,
      p_heading_degrees:
        heading !== undefined ? Math.round(heading) : undefined,
      p_accuracy_meters: accuracy,
      p_altitude_meters: altitude,
      p_source: trimOrUndef(formData.get("source")) ?? "carrier_app",
    });
  if (error) {
    console.error("carrier_report_position", error);
    return { error: translateError(error.code, "ثبت موقعیت ناموفق بود.") };
  }
  revalidateAll(shipmentId);
  return { ok: true, ts: new Date().toISOString() };
}

export async function reportTelemetryEvent(
  _prev: TelematicsActionState | null,
  formData: FormData,
): Promise<TelematicsActionState> {
  const dispatchId = trimOrUndef(formData.get("dispatchId"));
  const shipmentId = trimOrUndef(formData.get("shipmentId"));
  if (!dispatchId) return { error: "شناسه اعزام الزامی است." };

  const eventType = trimOrUndef(formData.get("eventType")) as
    | CarrierEventType
    | undefined;
  if (!eventType || !CARRIER_EVENT_TYPES.includes(eventType)) {
    return {
      error:
        "نوع رویداد نامعتبر است. مقادیر مجاز: signal_lost / signal_restored / position_anomaly.",
    };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("telematics")
    .rpc("carrier_report_telemetry_event", {
      p_dispatch_id: dispatchId,
      p_event_type: eventType,
      p_reason: trimOrUndef(formData.get("reason")),
    });
  if (error) {
    console.error("carrier_report_telemetry_event", error);
    return { error: translateError(error.code, "ثبت رویداد ناموفق بود.") };
  }
  revalidateAll(shipmentId);
  return { ok: true, ts: new Date().toISOString() };
}
