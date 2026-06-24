import { createClient } from "@/lib/supabase/server";
import type {
  ContractPreparationListRow,
  ContractStatus,
  ExecutedContractListRow,
  PreparationStatus,
  SignatureRequestRow,
  SignatureStatus,
} from "@/types/database";

export interface ListSupplierPreparationsParams {
  status?: PreparationStatus | null;
  page?: number;
  pageSize?: number;
}

export async function listSupplierPreparations({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierPreparationsParams = {}): Promise<{
  rows: ContractPreparationListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("supplier_list_my_preparations", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_preparations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ContractPreparationListRow[],
    page,
    pageSize,
  };
}

export interface ListSupplierExecutedParams {
  status?: ContractStatus | null;
  page?: number;
  pageSize?: number;
}

export async function listSupplierExecuted({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierExecutedParams = {}): Promise<{
  rows: ExecutedContractListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("supplier_list_my_executed_contracts", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_executed_contracts", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ExecutedContractListRow[],
    page,
    pageSize,
  };
}

export async function listSupplierSignatureRequests(
  status: SignatureStatus | null = null,
): Promise<SignatureRequestRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("supplier_list_my_signature_requests", {
      p_status: status ?? undefined,
      p_limit: 200,
      p_offset: 0,
    });
  if (error) {
    console.error("supplier_list_my_signature_requests", error);
    return [];
  }
  return (data ?? []) as unknown as SignatureRequestRow[];
}
