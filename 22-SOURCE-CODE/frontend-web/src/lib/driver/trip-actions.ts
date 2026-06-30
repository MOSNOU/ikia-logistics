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

// driver_complete_trip is POD-gated in D1 and is intentionally NOT wired into
// the D3 UI (the panel renders a disabled "complete after POD" button). This
// action exists for completeness and handles the POD-required error gracefully;
// it will be surfaced in D4 once POD upload lands.
export async function completeTrip(dispatchId: string): Promise<TripActionResult> {
  return callTransition(dispatchId, "driver_complete_trip");
}
