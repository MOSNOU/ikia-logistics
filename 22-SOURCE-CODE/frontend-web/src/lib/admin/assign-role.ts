"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { RoleScope } from "@/types/database";

export interface AssignRoleState {
  error?: string;
  ok?: boolean;
}

const SCOPE_TYPES: RoleScope[] = ["platform", "tenant", "organization", "business_unit"];

export async function assignRole(
  _prev: AssignRoleState | null,
  formData: FormData,
): Promise<AssignRoleState> {
  const userId = String(formData.get("userId") ?? "");
  const roleCode = String(formData.get("roleCode") ?? "");
  const scopeType = (String(formData.get("scopeType") ?? "organization") as RoleScope);
  const scopeIdRaw = String(formData.get("scopeId") ?? "").trim();
  const scopeId = scopeIdRaw === "" ? undefined : scopeIdRaw;

  if (!userId || !roleCode || !SCOPE_TYPES.includes(scopeType)) {
    return { error: "فیلدهای ضروری معتبر نیستند" };
  }
  if (scopeType !== "platform" && !scopeId) {
    return { error: "شناسه دامنه (scope_id) برای این محدوده الزامی است" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("identity")
    .rpc("admin_assign_role", {
      p_user_id: userId,
      p_role_code: roleCode,
      p_scope_type: scopeType,
      p_scope_id: scopeId,
    });

  if (error) {
    console.error("admin_assign_role", error);
    return { error: "اختصاص نقش ناموفق بود" };
  }

  revalidatePath(`/admin/users/${userId}`);
  return { ok: true };
}
