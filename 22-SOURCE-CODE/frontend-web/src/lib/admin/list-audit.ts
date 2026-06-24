import { createClient } from "@/lib/supabase/server";
import type { AdminAuditRow } from "@/types/database";

export interface ListAuditParams {
  page?: number;
  pageSize?: number;
  since?: string | null;
}

export interface ListAuditResult {
  rows: AdminAuditRow[];
  page: number;
  pageSize: number;
}

export async function listAdminAuditEvents({
  page = 0,
  pageSize = 50,
  since = null,
}: ListAuditParams = {}): Promise<ListAuditResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("identity")
    .rpc("admin_list_audit_events", {
      p_limit: pageSize,
      p_offset: page * pageSize,
      p_since: since ?? undefined,
    });

  if (error) {
    console.error("admin_list_audit_events", error);
    return { rows: [], page, pageSize };
  }
  return { rows: (data ?? []) as AdminAuditRow[], page, pageSize };
}
