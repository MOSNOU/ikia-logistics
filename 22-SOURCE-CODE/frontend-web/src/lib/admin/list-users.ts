import { createClient } from "@/lib/supabase/server";
import type { AdminUserRow } from "@/types/database";

export interface ListUsersParams {
  page?: number;
  pageSize?: number;
  status?: string | null;
}

export interface ListUsersResult {
  rows: AdminUserRow[];
  page: number;
  pageSize: number;
}

export async function listAdminUsers({
  page = 0,
  pageSize = 25,
  status = null,
}: ListUsersParams = {}): Promise<ListUsersResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("identity")
    .rpc("admin_list_users", {
      p_limit: pageSize,
      p_offset: page * pageSize,
      p_status_filter: status ?? undefined,
    });

  if (error) {
    console.error("admin_list_users", error);
    return { rows: [], page, pageSize };
  }
  return { rows: (data ?? []) as AdminUserRow[], page, pageSize };
}
