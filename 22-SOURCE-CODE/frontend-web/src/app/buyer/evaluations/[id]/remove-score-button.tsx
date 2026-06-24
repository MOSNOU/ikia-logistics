"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { buyerRemoveScore, type EvaluationActionState } from "@/lib/evaluation/buyer-actions";

export function RemoveScoreButton({
  scoreId,
  evaluationId,
}: {
  scoreId: string;
  evaluationId: string;
}) {
  const [state, action, pending] = useActionState<EvaluationActionState | null, FormData>(
    buyerRemoveScore,
    null,
  );
  return (
    <form action={action}>
      <input type="hidden" name="scoreId" value={scoreId} />
      <input type="hidden" name="evaluationId" value={evaluationId} />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "حذف"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
