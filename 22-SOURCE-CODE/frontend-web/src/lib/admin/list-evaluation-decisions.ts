import { createClient } from "@/lib/supabase/server";
import type {
  DecisionStatus,
  EvaluationDecisionListRow,
  EvaluationDecisionEventRow,
} from "@/types/database";

export interface ListAdminDecisionsParams {
  status?: DecisionStatus | null;
  requestId?: string | null;
  offerId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminDecisionsResult {
  rows: EvaluationDecisionListRow[];
  page: number;
  pageSize: number;
}

export async function listAdminEvaluationDecisions({
  status = null,
  requestId = null,
  offerId = null,
  page = 0,
  pageSize = 25,
}: ListAdminDecisionsParams = {}): Promise<ListAdminDecisionsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc("admin_list_decisions", {
      p_status: status ?? undefined,
      p_request_id: requestId ?? undefined,
      p_offer_id: offerId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_decisions", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as EvaluationDecisionListRow[],
    page,
    pageSize,
  };
}

export async function listAdminDecisionEvents(
  decisionId: string,
): Promise<EvaluationDecisionEventRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc("admin_list_decision_events", { p_decision_id: decisionId });
  if (error) {
    console.error("admin_list_decision_events", error);
    return [];
  }
  return (data ?? []) as unknown as EvaluationDecisionEventRow[];
}
