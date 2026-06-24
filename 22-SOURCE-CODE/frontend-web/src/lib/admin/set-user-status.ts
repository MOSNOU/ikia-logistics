"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { UserStatus } from "@/types/database";

export interface SetUserStatusState {
  error?: string;
  ok?: boolean;
}

const VALID: UserStatus[] = ["active", "pending", "suspended", "deactivated"];

export async function setUserStatus(
  _prev: SetUserStatusState | null,
  formData: FormData,
): Promise<SetUserStatusState> {
  const userId = String(formData.get("userId") ?? "");
  const status = String(formData.get("status") ?? "") as UserStatus;

  if (!userId || !VALID.includes(status)) {
    return { error: "مقدار وضعیت نامعتبر است" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("identity")
    .rpc("admin_set_user_status", { p_user_id: userId, p_status: status });

  if (error) {
    console.error("admin_set_user_status", error);
    return { error: "تغییر وضعیت ناموفق بود" };
  }

  revalidatePath(`/admin/users/${userId}`);
  revalidatePath("/admin/users");
  return { ok: true };
}
