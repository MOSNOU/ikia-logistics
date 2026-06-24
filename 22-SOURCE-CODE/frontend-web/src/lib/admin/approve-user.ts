"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { Locale } from "@/types/database";

export interface ApproveUserState {
  error?: string;
  ok?: boolean;
}

export async function approveUser(
  _prev: ApproveUserState | null,
  formData: FormData,
): Promise<ApproveUserState> {
  const userId = String(formData.get("userId") ?? "");
  const tenantId = String(formData.get("tenantId") ?? "");
  const organizationId = String(formData.get("organizationId") ?? "");
  const roleCode = String(formData.get("roleCode") ?? "");
  const fullName = (formData.get("fullName") as string | null) || undefined;
  const locale = ((formData.get("locale") as string | null) || "fa") as Locale;

  if (!userId || !tenantId || !organizationId || !roleCode) {
    return { error: "همه فیلدها الزامی هستند" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("identity")
    .rpc("admin_approve_user", {
      p_user_id: userId,
      p_tenant_id: tenantId,
      p_organization_id: organizationId,
      p_role_code: roleCode,
      p_full_name: fullName,
      p_locale: locale,
    });

  if (error) {
    console.error("admin_approve_user", error);
    return { error: "تأیید کاربر ناموفق بود" };
  }

  revalidatePath(`/admin/users/${userId}`);
  revalidatePath("/admin/users");
  return { ok: true };
}
