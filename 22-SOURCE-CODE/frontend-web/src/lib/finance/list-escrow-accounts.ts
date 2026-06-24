import { createClient } from "@/lib/supabase/server";
import type {
  AdminEscrowAccountRow,
  EscrowStatus,
  OrgEscrowAccountRow,
} from "@/types/database";

export interface ListAdminEscrowParams {
  organizationId?: string | null;
  supplierId?: string | null;
  status?: EscrowStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminEscrowResult {
  rows: AdminEscrowAccountRow[];
  page: number;
  pageSize: number;
}

export async function listAdminEscrowAccounts({
  organizationId = null,
  supplierId = null,
  status = null,
  page = 0,
  pageSize = 25,
}: ListAdminEscrowParams = {}): Promise<ListAdminEscrowResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .rpc("admin_list_escrow_accounts", {
      p_organization_id: organizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_escrow_accounts", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as AdminEscrowAccountRow[],
    page,
    pageSize,
  };
}

// Direct SELECT for buyer/supplier visibility — RLS scopes the rows. No
// dedicated buyer/supplier escrow RPC exists, so we surface the table via
// PostgREST. Returns an empty list if RLS denies, never throws.
export async function listOrgEscrowAccounts(): Promise<OrgEscrowAccountRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("settlement")
    .from("escrow_accounts")
    .select(
      "id, account_code, organization_id, supplier_id, status, currency, available_balance, total_held, total_credited, total_released, created_at, updated_at",
    )
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) {
    console.error("list org escrow accounts", error);
    return [];
  }
  return (data ?? []) as unknown as OrgEscrowAccountRow[];
}
