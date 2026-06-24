import { createClient } from "@/lib/supabase/server";
import type { EvaluationDetail } from "@/types/database";

export type EvaluationAudience = "buyer" | "admin";

export async function getEvaluation(
  evaluationId: string,
  audience: EvaluationAudience,
): Promise<EvaluationDetail | null> {
  const supabase = await createClient();
  const rpc = audience === "buyer" ? "buyer_get_evaluation" : "admin_get_evaluation";
  const { data, error } = await supabase
    .schema("evaluation")
    .rpc(rpc, { p_evaluation_id: evaluationId });
  if (error) {
    console.error(rpc, error);
    return null;
  }
  if (!data) return null;
  return data as unknown as EvaluationDetail;
}
