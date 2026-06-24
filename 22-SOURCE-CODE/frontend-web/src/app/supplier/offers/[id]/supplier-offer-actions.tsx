"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  supplierSubmitOffer,
  supplierWithdrawOffer,
  type OfferActionState,
} from "@/lib/offer/supplier-actions";

export function SupplierOfferActions({
  offerId,
  canSubmit,
  canWithdraw,
}: {
  offerId: string;
  canSubmit: boolean;
  canWithdraw: boolean;
}) {
  const [submitState, submitAction, submitPending] =
    useActionState<OfferActionState | null, FormData>(supplierSubmitOffer, null);
  const [withdrawState, withdrawAction, withdrawPending] =
    useActionState<OfferActionState | null, FormData>(supplierWithdrawOffer, null);
  const [showWithdraw, setShowWithdraw] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        {canSubmit ? (
          <form action={submitAction}>
            <input type="hidden" name="offerId" value={offerId} />
            <Button type="submit" size="sm" disabled={submitPending}>
              {submitPending ? "..." : "ارسال پیشنهاد"}
            </Button>
          </form>
        ) : null}

        {canWithdraw ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setShowWithdraw(!showWithdraw)}
          >
            پس‌گرفتن
          </Button>
        ) : null}
      </div>

      {showWithdraw ? (
        <form action={withdrawAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="offerId" value={offerId} />
          <Input name="reason" placeholder="دلیل پس‌گرفتن" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={withdrawPending}>
            {withdrawPending ? "..." : "تأیید"}
          </Button>
        </form>
      ) : null}

      {submitState?.error ? <p className="text-xs text-destructive">{submitState.error}</p> : null}
      {withdrawState?.error ? <p className="text-xs text-destructive">{withdrawState.error}</p> : null}
    </div>
  );
}
