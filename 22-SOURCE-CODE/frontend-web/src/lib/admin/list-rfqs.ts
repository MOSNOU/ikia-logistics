import { createClient } from "@/lib/supabase/server";
import type { RfqListRow, RfqStatus } from "@/types/database";

export interface ListAdminRfqsParams {
  status?: RfqStatus | null;
  organizationId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminRfqsResult {
  rows: RfqListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminRfqs({
  status = null,
  organizationId = null,
  page = 0,
  pageSize = 25,
}: ListAdminRfqsParams = {}): Promise<ListAdminRfqsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("admin_list_rfqs", {
      p_status: status ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_rfqs", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as RfqListRow[],
    page,
    pageSize,
  };
}
