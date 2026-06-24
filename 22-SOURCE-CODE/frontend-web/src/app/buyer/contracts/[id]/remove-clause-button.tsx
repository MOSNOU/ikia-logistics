"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { buyerRemoveClause, type ContractActionState } from "@/lib/contract/buyer-actions";

export function RemoveClauseButton({
  clauseId,
  preparationId,
}: {
  clauseId: string;
  preparationId: string;
}) {
  const [state, action, pending] = useActionState<ContractActionState | null, FormData>(
    buyerRemoveClause,
    null,
  );
  return (
    <form action={action}>
      <input type="hidden" name="clauseId" value={clauseId} />
      <input type="hidden" name="preparationId" value={preparationId} />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "حذف"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
