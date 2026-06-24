"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerCompleteEvaluation,
  buyerCancelEvaluation,
  type EvaluationActionState,
} from "@/lib/evaluation/buyer-actions";

export function EvaluationStatusActions({
  evaluationId,
  canComplete,
  canCancel,
}: {
  evaluationId: string;
  canComplete: boolean;
  canCancel: boolean;
}) {
  const [completeState, completeAction, completePending] =
    useActionState<EvaluationActionState | null, FormData>(buyerCompleteEvaluation, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<EvaluationActionState | null, FormData>(buyerCancelEvaluation, null);
  const [showCancel, setShowCancel] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        {canComplete ? (
          <form action={completeAction}>
            <input type="hidden" name="evaluationId" value={evaluationId} />
            <Button type="submit" size="sm" disabled={completePending}>
              {completePending ? "..." : "تکمیل ارزیابی"}
            </Button>
          </form>
        ) : null}
        {canCancel ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setShowCancel(!showCancel)}
          >
            لغو ارزیابی
          </Button>
        ) : null}
      </div>

      {showCancel ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="evaluationId" value={evaluationId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {completeState?.error ? <p className="text-xs text-destructive">{completeState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
