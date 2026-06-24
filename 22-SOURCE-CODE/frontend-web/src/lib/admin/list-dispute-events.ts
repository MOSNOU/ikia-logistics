import { createClient } from "@/lib/supabase/server";
import type {
  DisputeDecisionRow,
  DisputeEventRow,
  DisputeEvidenceRow,
} from "@/types/database";

export async function listDisputeEvents(
  disputeId: string,
): Promise<DisputeEventRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("admin_list_dispute_events", { p_dispute_id: disputeId });
  if (error) {
    console.error("admin_list_dispute_events", error);
    return [];
  }
  return (data ?? []) as unknown as DisputeEventRow[];
}

export async function listDisputeEvidence(
  disputeId: string,
): Promise<DisputeEvidenceRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("admin_list_dispute_evidence", { p_dispute_id: disputeId });
  if (error) {
    console.error("admin_list_dispute_evidence", error);
    return [];
  }
  return (data ?? []) as unknown as DisputeEvidenceRow[];
}

export async function listDisputeDecisions(
  disputeId: string,
): Promise<DisputeDecisionRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("dispute")
    .rpc("admin_list_decisions", { p_dispute_id: disputeId });
  if (error) {
    console.error("admin_list_decisions", error);
    return [];
  }
  return (data ?? []) as unknown as DisputeDecisionRow[];
}
