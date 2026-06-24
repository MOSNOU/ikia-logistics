import { createClient } from "@/lib/supabase/server";
import type {
  ContractPreparationListRow,
  ContractStatus,
  ExecutedContractListRow,
  PreparationStatus,
} from "@/types/database";

export interface ListAdminPreparationsParams {
  status?: PreparationStatus | null;
  organizationId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export async function listAdminPreparations({
  status = null,
  organizationId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminPreparationsParams = {}): Promise<{
  rows: ContractPreparationListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("admin_list_preparations", {
      p_status: status ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_preparations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ContractPreparationListRow[],
    page,
    pageSize,
  };
}

export interface ListAdminExecutedParams {
  status?: ContractStatus | null;
  organizationId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export async function listAdminExecuted({
  status = null,
  organizationId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminExecutedParams = {}): Promise<{
  rows: ExecutedContractListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("admin_list_executed_contracts", {
      p_status: status ?? undefined,
      p_organization_id: organizationId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_executed_contracts", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ExecutedContractListRow[],
    page,
    pageSize,
  };
}
