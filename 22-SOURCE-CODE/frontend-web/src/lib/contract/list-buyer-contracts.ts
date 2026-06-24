import { createClient } from "@/lib/supabase/server";
import type {
  ContractPreparationListRow,
  ContractStatus,
  ExecutedContractListRow,
  PreparationStatus,
} from "@/types/database";

export interface ListBuyerPreparationsParams {
  status?: PreparationStatus | null;
  requestId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerPreparationsResult {
  rows: ContractPreparationListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerPreparations({
  status = null,
  requestId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerPreparationsParams = {}): Promise<ListBuyerPreparationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("buyer_list_preparations", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_preparations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ContractPreparationListRow[],
    page,
    pageSize,
  };
}

export interface ListBuyerExecutedParams {
  status?: ContractStatus | null;
  requestId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerExecutedResult {
  rows: ExecutedContractListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerExecuted({
  status = null,
  requestId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerExecutedParams = {}): Promise<ListBuyerExecutedResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("contract")
    .rpc("buyer_list_executed_contracts", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_executed_contracts", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ExecutedContractListRow[],
    page,
    pageSize,
  };
}
