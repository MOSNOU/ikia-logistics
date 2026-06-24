"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerMoveToUnderReview,
  buyerMarkReady,
  buyerPromoteToExecuted,
  buyerCancelPreparation,
  type ContractActionState,
} from "@/lib/contract/buyer-actions";

export function PreparationStatusActions({
  preparationId,
  canMoveToReview,
  canMarkReady,
  canPromote,
  canCancel,
}: {
  preparationId: string;
  canMoveToReview: boolean;
  canMarkReady: boolean;
  canPromote: boolean;
  canCancel: boolean;
}) {
  const [reviewState, reviewAction, reviewPending] =
    useActionState<ContractActionState | null, FormData>(buyerMoveToUnderReview, null);
  const [readyState, readyAction, readyPending] =
    useActionState<ContractActionState | null, FormData>(buyerMarkReady, null);
  const [promoteState, promoteAction, promotePending] =
    useActionState<ContractActionState | null, FormData>(buyerPromoteToExecuted, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<ContractActionState | null, FormData>(buyerCancelPreparation, null);
  const [openForm, setOpenForm] = useState<"promote" | "cancel" | null>(null);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-md">
      <div className="flex flex-wrap gap-2">
        {canMoveToReview ? (
          <form action={reviewAction}>
            <input type="hidden" name="preparationId" value={preparationId} />
            <Button type="submit" size="sm" variant="outline" disabled={reviewPending}>
              {reviewPending ? "..." : "انتقال به بررسی"}
            </Button>
          </form>
        ) : null}
        {canMarkReady ? (
          <form action={readyAction}>
            <input type="hidden" name="preparationId" value={preparationId} />
            <Button type="submit" size="sm" disabled={readyPending}>
              {readyPending ? "..." : "آماده برای قرارداد"}
            </Button>
          </form>
        ) : null}
        {canPromote ? (
          <Button
            type="button"
            size="sm"
            onClick={() => setOpenForm(openForm === "promote" ? null : "promote")}
          >
            ایجاد قرارداد اجرایی
          </Button>
        ) : null}
        {canCancel ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
          >
            لغو
          </Button>
        ) : null}
      </div>

      {openForm === "promote" ? (
        <form action={promoteAction} className="grid gap-2 w-full md:grid-cols-3">
          <input type="hidden" name="preparationId" value={preparationId} />
          <Input name="title" placeholder="عنوان قرارداد (اختیاری)" className="h-9 md:col-span-3" />
          <Input name="effectiveDate" type="date" dir="ltr" placeholder="تاریخ شروع" className="h-9" />
          <Input name="expiryDate" type="date" dir="ltr" placeholder="تاریخ انقضا" className="h-9" />
          <Button type="submit" size="sm" disabled={promotePending}>
            {promotePending ? "..." : "تأیید ایجاد"}
          </Button>
        </form>
      ) : null}

      {openForm === "cancel" ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="preparationId" value={preparationId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {reviewState?.error ? <p className="text-xs text-destructive">{reviewState.error}</p> : null}
      {readyState?.error ? <p className="text-xs text-destructive">{readyState.error}</p> : null}
      {promoteState?.error ? <p className="text-xs text-destructive">{promoteState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
