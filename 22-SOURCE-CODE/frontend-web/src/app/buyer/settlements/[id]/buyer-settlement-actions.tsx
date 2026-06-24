"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerMarkReady,
  buyerHold,
  buyerRelease,
  buyerCancel,
  type SettlementActionState,
} from "@/lib/settlement/buyer-actions";
import type { SettlementStatus } from "@/types/database";

export function BuyerSettlementActions({
  settlementId,
  status,
}: {
  settlementId: string;
  status: SettlementStatus;
}) {
  const [readyState, readyAction, readyPending] =
    useActionState<SettlementActionState | null, FormData>(buyerMarkReady, null);
  const [holdState, holdAction, holdPending] =
    useActionState<SettlementActionState | null, FormData>(buyerHold, null);
  const [releaseState, releaseAction, releasePending] =
    useActionState<SettlementActionState | null, FormData>(buyerRelease, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<SettlementActionState | null, FormData>(buyerCancel, null);
  const [openForm, setOpenForm] = useState<"release" | "cancel" | null>(null);

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        {status === "draft" ? (
          <form action={readyAction}>
            <input type="hidden" name="settlementId" value={settlementId} />
            <Button type="submit" size="sm" disabled={readyPending}>
              {readyPending ? "..." : "آماده برای اسکرو"}
            </Button>
          </form>
        ) : null}

        {status === "ready" ? (
          <form action={holdAction}>
            <input type="hidden" name="settlementId" value={settlementId} />
            <Button type="submit" size="sm" disabled={holdPending}>
              {holdPending ? "..." : "نگه‌داری در اسکرو"}
            </Button>
          </form>
        ) : null}

        {status === "holding" ? (
          <Button
            size="sm"
            type="button"
            onClick={() => setOpenForm(openForm === "release" ? null : "release")}
          >
            آزادسازی
          </Button>
        ) : null}

        {(status === "draft" || status === "ready") ? (
          <Button
            size="sm"
            variant="outline"
            type="button"
            onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
          >
            لغو
          </Button>
        ) : null}
      </div>

      {openForm === "release" ? (
        <form action={releaseAction} className="flex items-end gap-2 w-full max-w-md">
          <input type="hidden" name="settlementId" value={settlementId} />
          <Input name="reason" placeholder="یادداشت آزادسازی" className="h-9" />
          <Button type="submit" size="sm" disabled={releasePending}>
            {releasePending ? "..." : "تأیید آزادسازی"}
          </Button>
        </form>
      ) : null}

      {openForm === "cancel" ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full max-w-md">
          <input type="hidden" name="settlementId" value={settlementId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {readyState?.error ? <p className="text-xs text-destructive">{readyState.error}</p> : null}
      {holdState?.error ? <p className="text-xs text-destructive">{holdState.error}</p> : null}
      {releaseState?.error ? <p className="text-xs text-destructive">{releaseState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
