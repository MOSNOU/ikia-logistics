"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerShortlistOffer,
  buyerSelectForContract,
  buyerRejectOffer,
  type EvaluationActionState,
} from "@/lib/evaluation/buyer-actions";

export function DecisionActions({
  offerId,
  evaluationId,
}: {
  offerId: string;
  evaluationId: string;
}) {
  const [shortState, shortAction, shortPending] =
    useActionState<EvaluationActionState | null, FormData>(buyerShortlistOffer, null);
  const [selectState, selectAction, selectPending] =
    useActionState<EvaluationActionState | null, FormData>(buyerSelectForContract, null);
  const [rejectState, rejectAction, rejectPending] =
    useActionState<EvaluationActionState | null, FormData>(buyerRejectOffer, null);
  const [openForm, setOpenForm] = useState<"shortlist" | "select" | "reject" | null>(null);

  const sharedHidden = (
    <>
      <input type="hidden" name="offerId" value={offerId} />
      <input type="hidden" name="evaluationId" value={evaluationId} />
    </>
  );

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        <Button
          type="button"
          size="sm"
          onClick={() => setOpenForm(openForm === "shortlist" ? null : "shortlist")}
        >
          فهرست کوتاه
        </Button>
        <Button
          type="button"
          size="sm"
          onClick={() => setOpenForm(openForm === "select" ? null : "select")}
        >
          انتخاب برای قرارداد
        </Button>
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={() => setOpenForm(openForm === "reject" ? null : "reject")}
        >
          رد پیشنهاد
        </Button>
      </div>

      {openForm === "shortlist" ? (
        <form action={shortAction} className="flex flex-wrap items-end gap-2 w-full max-w-2xl">
          {sharedHidden}
          <Input name="reason" placeholder="دلیل" className="h-9 flex-1" />
          <Input name="notes" placeholder="یادداشت" className="h-9 flex-1" />
          <Button type="submit" size="sm" disabled={shortPending}>
            {shortPending ? "..." : "تأیید فهرست کوتاه"}
          </Button>
        </form>
      ) : null}

      {openForm === "select" ? (
        <form action={selectAction} className="flex flex-wrap items-end gap-2 w-full max-w-2xl">
          {sharedHidden}
          <Input name="reason" placeholder="دلیل" className="h-9 flex-1" />
          <Input name="notes" placeholder="یادداشت" className="h-9 flex-1" />
          <Button type="submit" size="sm" disabled={selectPending}>
            {selectPending ? "..." : "تأیید انتخاب برای قرارداد"}
          </Button>
        </form>
      ) : null}

      {openForm === "reject" ? (
        <form action={rejectAction} className="flex flex-wrap items-end gap-2 w-full max-w-2xl">
          {sharedHidden}
          <Input name="reason" required placeholder="دلیل رد (الزامی)" className="h-9 flex-1" />
          <Input name="notes" placeholder="یادداشت" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={rejectPending}>
            {rejectPending ? "..." : "تأیید رد"}
          </Button>
        </form>
      ) : null}

      {shortState?.error ? <p className="text-xs text-destructive">{shortState.error}</p> : null}
      {selectState?.error ? <p className="text-xs text-destructive">{selectState.error}</p> : null}
      {rejectState?.error ? <p className="text-xs text-destructive">{rejectState.error}</p> : null}
    </div>
  );
}
