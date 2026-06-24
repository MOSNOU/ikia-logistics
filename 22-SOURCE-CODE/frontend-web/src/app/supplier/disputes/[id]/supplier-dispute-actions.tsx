"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  supplierSubmitEvidence,
  supplierWithdrawDispute,
  type DisputeActionState,
} from "@/lib/dispute/supplier-actions";

const KINDS = [
  { value: "narrative", label: "روایت" },
  { value: "document", label: "سند" },
  { value: "financial", label: "مالی" },
  { value: "photo", label: "تصویر" },
  { value: "communication_log", label: "ارتباطات" },
  { value: "inspection_report", label: "گزارش بازرسی" },
  { value: "other", label: "سایر" },
] as const;

export function SupplierDisputeActions({
  disputeId,
  canSubmit,
  canWithdraw,
}: {
  disputeId: string;
  canSubmit: boolean;
  canWithdraw: boolean;
}) {
  const [submitState, submitAction, submitPending] =
    useActionState<DisputeActionState | null, FormData>(supplierSubmitEvidence, null);
  const [withdrawState, withdrawAction, withdrawPending] =
    useActionState<DisputeActionState | null, FormData>(supplierWithdrawDispute, null);
  const [openForm, setOpenForm] = useState<"submit" | "withdraw" | null>(null);

  return (
    <div className="flex flex-col items-end gap-2 w-full max-w-xl">
      <div className="flex flex-wrap gap-2">
        {canSubmit ? (
          <Button
            type="button"
            size="sm"
            onClick={() => setOpenForm(openForm === "submit" ? null : "submit")}
          >
            ثبت مدرک
          </Button>
        ) : null}
        {canWithdraw ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setOpenForm(openForm === "withdraw" ? null : "withdraw")}
          >
            پس‌گرفتن
          </Button>
        ) : null}
      </div>

      {openForm === "submit" ? (
        <form action={submitAction} className="grid gap-2 w-full md:grid-cols-3">
          <input type="hidden" name="disputeId" value={disputeId} />
          <Input name="title" required placeholder="عنوان مدرک" className="h-9" />
          <select
            name="evidenceKind"
            required
            defaultValue=""
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            <option value="" disabled>— نوع —</option>
            {KINDS.map((k) => (
              <option key={k.value} value={k.value}>{k.label}</option>
            ))}
          </select>
          <Input name="narrative" placeholder="شرح کوتاه" className="h-9" />
          <div className="md:col-span-3">
            <Button type="submit" size="sm" disabled={submitPending}>
              {submitPending ? "..." : "ثبت مدرک"}
            </Button>
          </div>
        </form>
      ) : null}

      {openForm === "withdraw" ? (
        <form action={withdrawAction} className="flex items-end gap-2 w-full">
          <input type="hidden" name="disputeId" value={disputeId} />
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
