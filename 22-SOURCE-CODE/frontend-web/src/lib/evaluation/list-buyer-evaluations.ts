import { createClient } from "@/lib/supabase/server";
import type {
  EvaluationListRow,
  EvaluationStatus,
} from "@/types/database";

export interface ListBuyerEvaluationsParams {
  status?: EvaluationStatus | null;
  requestId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerEvaluationsResult {
  rows: EvaluationListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerEvaluations({
  status = null,
  requestId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerEvaluationsParams = {}): Promise<ListBuyerEvaluationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc("buyer_list_evaluations", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_evaluations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as EvaluationListRow[],
    page,
    pageSize,
  };
}
