"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerSubmitRfq,
  buyerCloseRfq,
  buyerCancelRfq,
  type RfqActionState,
} from "@/lib/rfq/buyer-actions";

export function BuyerRfqActions({
  requestId,
  canSubmit,
  canClose,
  canCancel,
}: {
  requestId: string;
  canSubmit: boolean;
  canClose: boolean;
  canCancel: boolean;
}) {
  const [submitState, submitAction, submitPending] =
    useActionState<RfqActionState | null, FormData>(buyerSubmitRfq, null);
  const [closeState, closeAction, closePending] =
    useActionState<RfqActionState | null, FormData>(buyerCloseRfq, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<RfqActionState | null, FormData>(buyerCancelRfq, null);
  const [showCancel, setShowCancel] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        {canSubmit ? (
          <form action={submitAction}>
            <input type="hidden" name="requestId" value={requestId} />
            <Button type="submit" size="sm" disabled={submitPending}>
              {submitPending ? "..." : "ارسال (انتشار)"}
            </Button>
          </form>
        ) : null}

        {canClose ? (
          <form action={closeAction}>
            <input type="hidden" name="requestId" value={requestId} />
            <Button type="submit" size="sm" variant="outline" disabled={closePending}>
              {closePending ? "..." : "بستن"}
            </Button>
          </form>
        ) : null}

        {canCancel ? (
          <Button
            size="sm"
            variant="outline"
            type="button"
            onClick={() => setShowCancel(!showCancel)}
          >
            لغو
          </Button>
        ) : null}
      </div>

      {showCancel ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="requestId" value={requestId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {submitState?.error ? <p className="text-xs text-destructive">{submitState.error}</p> : null}
      {closeState?.error ? <p className="text-xs text-destructive">{closeState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
