import { createClient } from "@/lib/supabase/server";
import type { InvitationStatus, SupplierRfqInvitationRow } from "@/types/database";

export interface ListSupplierRfqsParams {
  status?: InvitationStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListSupplierRfqsResult {
  rows: SupplierRfqInvitationRow[];
  page: number;
  pageSize: number;
}

export async function listSupplierRfqs({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierRfqsParams = {}): Promise<ListSupplierRfqsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("rfq")
    .rpc("supplier_list_rfq_invitations", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_rfq_invitations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as SupplierRfqInvitationRow[],
    page,
    pageSize,
  };
}
