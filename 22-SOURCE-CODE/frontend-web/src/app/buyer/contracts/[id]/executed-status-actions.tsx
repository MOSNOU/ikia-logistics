"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerMarkPendingSignatures,
  buyerCancelExecutedContract,
  type ContractActionState,
} from "@/lib/contract/buyer-actions";

export function ExecutedStatusActions({
  contractId,
  canMarkPending,
  canCancel,
}: {
  contractId: string;
  canMarkPending: boolean;
  canCancel: boolean;
}) {
  const [pendingState, pendingAction, pendingPending] =
    useActionState<ContractActionState | null, FormData>(buyerMarkPendingSignatures, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<ContractActionState | null, FormData>(buyerCancelExecutedContract, null);
  const [showCancel, setShowCancel] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        {canMarkPending ? (
          <form action={pendingAction}>
            <input type="hidden" name="contractId" value={contractId} />
            <Button type="submit" size="sm" disabled={pendingPending}>
              {pendingPending ? "..." : "انتقال به انتظار امضا"}
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
            لغو قرارداد
          </Button>
        ) : null}
      </div>

      {showCancel ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="contractId" value={contractId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید"}
          </Button>
        </form>
      ) : null}

      {pendingState?.error ? <p className="text-xs text-destructive">{pendingState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
