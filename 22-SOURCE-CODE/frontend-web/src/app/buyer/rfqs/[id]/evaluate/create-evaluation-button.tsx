"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import {
  buyerCreateEvaluation,
  type EvaluationActionState,
} from "@/lib/evaluation/buyer-actions";

export function CreateEvaluationButton({ offerId }: { offerId: string }) {
  const [state, action, pending] = useActionState<EvaluationActionState | null, FormData>(
    buyerCreateEvaluation,
    null,
  );

  return (
    <form action={action} className="flex flex-col items-end gap-1">
      <input type="hidden" name="offerId" value={offerId} />
      <Button type="submit" size="sm" disabled={pending}>
        {pending ? "..." : "ایجاد ارزیابی"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
