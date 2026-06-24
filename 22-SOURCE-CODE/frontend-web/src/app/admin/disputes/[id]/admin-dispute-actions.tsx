"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  adminStartReview,
  adminRecordDecision,
  adminCancelDispute,
  type DisputeAdminActionState,
} from "@/lib/admin/dispute-admin-actions";
import type { DisputeCaseStatus } from "@/types/database";

const OUTCOMES = [
  { value: "favor_buyer", label: "به نفع خریدار" },
  { value: "favor_supplier", label: "به نفع تأمین‌کننده" },
  { value: "split", label: "تقسیمی" },
  { value: "no_action", label: "بدون اقدام" },
  { value: "withdrawn", label: "پس‌گرفتن" },
] as const;

const SETTLEMENT_ACTIONS = [
  { value: "release_to_supplier", label: "آزادسازی به تأمین‌کننده" },
  { value: "reverse_to_buyer", label: "بازگرداندن به خریدار" },
  { value: "split", label: "تقسیم بین طرفین" },
  { value: "no_change", label: "بدون تغییر" },
] as const;

export function AdminDisputeActions({
  disputeId,
  status,
}: {
  disputeId: string;
  status: DisputeCaseStatus;
}) {
  const [startState, startAction, startPending] =
    useActionState<DisputeAdminActionState | null, FormData>(adminStartReview, null);
  const [decideState, decideAction, decidePending] =
    useActionState<DisputeAdminActionState | null, FormData>(adminRecordDecision, null);
  const [cancelState, cancelAction, cancelPending] =
    useActionState<DisputeAdminActionState | null, FormData>(adminCancelDispute, null);
  const [openForm, setOpenForm] = useState<"decision" | "cancel" | null>(null);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-2xl">
      <div className="flex flex-wrap gap-2">
        {status === "opened" ? (
          <form action={startAction}>
            <input type="hidden" name="disputeId" value={disputeId} />
            <Button type="submit" size="sm" disabled={startPending}>
              {startPending ? "..." : "شروع بررسی"}
            </Button>
          </form>
        ) : null}

        {status === "under_review" ? (
          <Button
            size="sm"
            type="button"
            onClick={() => setOpenForm(openForm === "decision" ? null : "decision")}
          >
            ثبت تصمیم
          </Button>
        ) : null}

        {status === "opened" || status === "under_review" ? (
          <Button
            size="sm"
            variant="outline"
            type="button"
            onClick={() => setOpenForm(openForm === "cancel" ? null : "cancel")}
          >
            لغو پرونده
          </Button>
        ) : null}
      </div>

      {openForm === "decision" ? (
        <form action={decideAction} className="grid gap-2 w-full md:grid-cols-2">
          <input type="hidden" name="disputeId" value={disputeId} />
          <select
            name="outcome"
            required
            defaultValue=""
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            <option value="" disabled>— نتیجه —</option>
            {OUTCOMES.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
          <select
            name="settlementAction"
            required
            defaultValue=""
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            <option value="" disabled>— اقدام تسویه —</option>
            {SETTLEMENT_ACTIONS.map((s) => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
          <Input name="buyerShare" type="number" step="0.01" min="0" placeholder="سهم خریدار" className="h-9" dir="ltr" />
          <Input name="supplierShare" type="number" step="0.01" min="0" placeholder="سهم تأمین‌کننده" className="h-9" dir="ltr" />
          <Input name="feeShare" type="number" step="0.01" min="0" placeholder="سهم کارمزد" className="h-9" dir="ltr" />
          <Input name="reason" placeholder="دلیل کوتاه" className="h-9" />
          <Input name="mediatorNotes" placeholder="یادداشت میانجی" className="h-9 md:col-span-2" />
          <div className="md:col-span-2">
            <Button type="submit" size="sm" disabled={decidePending}>
              {decidePending ? "..." : "ثبت تصمیم"}
            </Button>
          </div>
        </form>
      ) : null}

      {openForm === "cancel" ? (
        <form action={cancelAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="disputeId" value={disputeId} />
          <Input name="reason" placeholder="دلیل لغو" className="h-9 flex-1" />
          <Button type="submit" size="sm" variant="outline" disabled={cancelPending}>
            {cancelPending ? "..." : "تأیید لغو"}
          </Button>
        </form>
      ) : null}

      {startState?.error ? <p className="text-xs text-destructive">{startState.error}</p> : null}
      {decideState?.error ? <p className="text-xs text-destructive">{decideState.error}</p> : null}
      {cancelState?.error ? <p className="text-xs text-destructive">{cancelState.error}</p> : null}
    </div>
  );
}
