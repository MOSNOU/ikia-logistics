"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  supplierConfirmReconciliation,
  supplierOpenDispute,
  type SettlementActionState,
} from "@/lib/settlement/supplier-actions";
import type { SettlementStatus } from "@/types/database";

export function SupplierSettlementActions({
  settlementId,
  status,
}: {
  settlementId: string;
  status: SettlementStatus;
}) {
  const [confirmState, confirmAction, confirmPending] =
    useActionState<SettlementActionState | null, FormData>(supplierConfirmReconciliation, null);
  const [disputeState, disputeAction, disputePending] =
    useActionState<SettlementActionState | null, FormData>(supplierOpenDispute, null);
  const [openForm, setOpenForm] = useState<"confirm" | "dispute" | null>(null);

  const canConfirm = status === "released";
  const canDispute = status === "holding" || status === "released";

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        {canConfirm ? (
          <Button
            type="button"
            size="sm"
            onClick={() => setOpenForm(openForm === "confirm" ? null : "confirm")}
          >
            تأیید تطبیق
          </Button>
        ) : null}
        {canDispute ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setOpenForm(openForm === "dispute" ? null : "dispute")}
          >
            ثبت اختلاف
          </Button>
        ) : null}
      </div>

      {openForm === "confirm" ? (
        <form action={confirmAction} className="flex items-end gap-2 w-full max-w-md">
          <input type="hidden" name="settlementId" value={settlementId} />
          <Input name="notes" placeholder="یادداشت (اختیاری)" className="h-9" />
          <Button type="submit" size="sm" disabled={confirmPending}>
            {confirmPending ? "..." : "تأیید"}
          </Button>
        </form>
      ) : null}

      {openForm === "dispute" ? (
        <form action={disputeAction} className="flex items-end gap-2 w-full max-w-md">
          <input type="hidden" name="settlementId" value={settlementId} />
          <Input name="reason" required placeholder="دلیل اختلاف" className="h-9" />
          <Button type="submit" size="sm" variant="outline" disabled={disputePending}>
            {disputePending ? "..." : "ثبت"}
          </Button>
        </form>
      ) : null}

      {confirmState?.error ? <p className="text-xs text-destructive">{confirmState.error}</p> : null}
      {disputeState?.error ? <p className="text-xs text-destructive">{disputeState.error}</p> : null}
    </div>
  );
}
