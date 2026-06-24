"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  acceptQuotation,
  rejectQuotation,
  type PricingActionState,
} from "@/lib/pricing/portal-actions";

export function ResponseActions({ quotationId }: { quotationId: string }) {
  const [acceptState, acceptAction, acceptPending] =
    useActionState<PricingActionState | null, FormData>(acceptQuotation, null);
  const [rejectState, rejectAction, rejectPending] =
    useActionState<PricingActionState | null, FormData>(rejectQuotation, null);
  const [showReject, setShowReject] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        <form action={acceptAction}>
          <input type="hidden" name="quotationId" value={quotationId} />
          <Button type="submit" disabled={acceptPending}>
            {acceptPending ? "..." : "پذیرفتن"}
          </Button>
        </form>

        {!showReject ? (
          <Button type="button" variant="outline" onClick={() => setShowReject(true)}>
            رد کردن
          </Button>
        ) : (
          <form action={rejectAction} className="flex items-end gap-2">
            <input type="hidden" name="quotationId" value={quotationId} />
            <Input
              name="reason"
              required
              placeholder="دلیل رد"
              className="h-9"
            />
            <Button type="submit" variant="outline" disabled={rejectPending}>
              {rejectPending ? "..." : "تأیید رد"}
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setShowReject(false)}
            >
              لغو
            </Button>
          </form>
        )}
      </div>

      {acceptState?.error ? (
        <p className="text-xs text-destructive">{acceptState.error}</p>
      ) : null}
      {rejectState?.error ? (
        <p className="text-xs text-destructive">{rejectState.error}</p>
      ) : null}
    </div>
  );
}
