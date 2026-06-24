import { createClient } from "@/lib/supabase/server";
import type {
  EvaluationListRow,
  EvaluationStatus,
} from "@/types/database";

export interface ListAdminEvaluationsParams {
  status?: EvaluationStatus | null;
  requestId?: string | null;
  offerId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminEvaluationsResult {
  rows: EvaluationListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminEvaluations({
  status = null,
  requestId = null,
  offerId = null,
  page = 0,
  pageSize = 25,
}: ListAdminEvaluationsParams = {}): Promise<ListAdminEvaluationsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc("admin_list_evaluations", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_offer_id: offerId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_evaluations", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as EvaluationListRow[],
    page,
    pageSize,
  };
}
