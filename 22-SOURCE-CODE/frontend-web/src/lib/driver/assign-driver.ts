"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Phase D (v1.1) — carrier/admin driver assignment server action.
//
// Thin wrapper over the D-B RPC dispatch.carrier_assign_driver. The RPC enforces
// carrier authorization, the dispatch lifecycle gate (assigned/ready/released),
// the pre-start re-assignment guard, and target-driver validation. No raw DB
// error is surfaced; only friendly Persian messages. No direct table writes.
//
// Shaped for React's useActionState (prevState, formData) like the existing
// dispatch action wrappers in @/lib/dispatch/dispatch-actions.
//
// TODO(v1.1-later): drop the `as any` once Supabase types are regenerated.

export interface AssignDriverState {
  ok?: boolean;
  error?: string;
}

function translateError(
  code: string | undefined,
  message: string | undefined,
  fallback: string,
): string {
  const m = (message ?? "").toLowerCase();
  if (code === "42501") return "اجازه دسترسی برای اختصاص راننده وجود ندارد.";
  if (code === "P0002") return "اعزام یا راننده یافت نشد.";
  if (code === "P0001") {
    if (m.includes("started")) {
      return "پس از شروع سفر امکان تغییر راننده وجود ندارد.";
    }
    return "وضعیت فعلی اعزام اجازه اختصاص راننده را نمی‌دهد.";
  }
  if (code === "22004") return "ورودی نامعتبر است.";
  return fallback;
}

export async function assignDriverAction(
  _prev: AssignDriverState | null,
  formData: FormData,
): Promise<AssignDriverState> {
  const dispatchId = String(formData.get("dispatchId") ?? "").trim();
  const driverUserId = String(formData.get("driverUserId") ?? "").trim();
  if (!dispatchId) return { error: "شناسه اعزام نامعتبر است." };
  if (!driverUserId) return { error: "لطفاً یک راننده را انتخاب کنید." };

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("dispatch") as any).rpc(
    "carrier_assign_driver",
    { p_dispatch_id: dispatchId, p_driver_user_id: driverUserId },
  );
  if (error) {
    console.error("dispatch.carrier_assign_driver", error);
    return {
      error: translateError(error.code, error.message, "اختصاص راننده ناموفق بود."),
    };
  }

  revalidatePath("/carrier/dispatches");
  revalidatePath(`/carrier/dispatches/${dispatchId}`);
  revalidatePath("/admin/driver-trips");
  revalidatePath(`/admin/driver-trips/${dispatchId}`);
  return { ok: true };
}
