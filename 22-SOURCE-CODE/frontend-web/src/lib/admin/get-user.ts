import { createClient } from "@/lib/supabase/server";
import type { AdminUserRow } from "@/types/database";

export async function getAdminUser(userId: string): Promise<AdminUserRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("identity")
    .rpc("admin_get_user", { p_user_id: userId });

  if (error) {
    console.error("admin_get_user", error);
    return null;
  }
  const rows = (data ?? []) as AdminUserRow[];
  return rows[0] ?? null;
}
