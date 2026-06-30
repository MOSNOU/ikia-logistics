"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

// Phase D5 — operations/admin issue actions.
//
// Thin wrappers over the D1 SECURITY DEFINER RPCs dispatch.admin_ack_driver_issue
// and dispatch.admin_resolve_driver_issue. The RPCs enforce admin / same-tenant
// authorization and the legal status machine (open → acknowledged → resolved)
// internally; these actions add a friendly Persian surface and revalidate the
// operations views. No raw database error is ever returned to the client.
//
// TODO(D-later): drop the `as any` once Supabase types are regenerated for the
// dispatch.admin_* RPCs.

export interface IssueActionResult {
  ok: boolean;
  message: string;
}

function friendlyError(error: { code?: string; message?: string } | null): string {
  const code = error?.code ?? "";
  const msg = (error?.message ?? "").toLowerCase();
  if (code === "P0002" || msg.includes("not found")) {
    return "این مورد یافت نشد.";
  }
  if (code === "42501" || msg.includes("permission") || msg.includes("tenant")) {
    return "شما به این مورد دسترسی ندارید.";
  }
  if (msg.includes("already resolved")) {
    return "این مشکل قبلاً حل‌شده ثبت شده است.";
  }
  if (msg.includes("not open")) {
    return "این مشکل در وضعیت «باز» نیست.";
  }
  return "انجام عملیات ممکن نشد. لطفاً دوباره تلاش کنید.";
}

function revalidate(dispatchId?: string | null) {
  revalidatePath("/admin/driver-trips");
  if (dispatchId) revalidatePath(`/admin/driver-trips/${dispatchId}`);
}

export async function ackDriverIssue(
  issueId: string,
  dispatchId?: string,
): Promise<IssueActionResult> {
  if (!issueId) return { ok: false, message: "شناسه مشکل نامعتبر است." };

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("dispatch") as any).rpc(
    "admin_ack_driver_issue",
    { p_issue_id: issueId },
  );
  if (error) {
    console.error("dispatch.admin_ack_driver_issue", error);
    return { ok: false, message: friendlyError(error) };
  }

  revalidate(dispatchId);
  return { ok: true, message: "دریافت مشکل تأیید شد." };
}

export async function resolveDriverIssue(
  issueId: string,
  note?: string,
  dispatchId?: string,
): Promise<IssueActionResult> {
  if (!issueId) return { ok: false, message: "شناسه مشکل نامعتبر است." };
  const trimmed = (note ?? "").trim();

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase.schema("dispatch") as any).rpc(
    "admin_resolve_driver_issue",
    {
      p_issue_id: issueId,
      p_note: trimmed.length > 0 ? trimmed : null,
    },
  );
  if (error) {
    console.error("dispatch.admin_resolve_driver_issue", error);
    return { ok: false, message: friendlyError(error) };
  }

  revalidate(dispatchId);
  return { ok: true, message: "مشکل به‌عنوان حل‌شده ثبت شد." };
}
