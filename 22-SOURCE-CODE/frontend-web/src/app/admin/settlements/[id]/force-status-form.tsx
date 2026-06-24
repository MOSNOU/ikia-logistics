"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  adminForceSettlementStatus,
  type SettlementAdminActionState,
} from "@/lib/admin/settlement-admin-actions";
import type { SettlementStatus } from "@/types/database";

const STATUS_OPTIONS: { value: SettlementStatus; label: string }[] = [
  { value: "draft", label: "پیش‌نویس" },
  { value: "ready", label: "آماده" },
  { value: "holding", label: "در اسکرو" },
  { value: "released", label: "آزادشده" },
  { value: "reconciled", label: "تطبیق‌شده" },
  { value: "disputed", label: "اختلاف" },
  { value: "cancelled", label: "لغوشده" },
  { value: "voided", label: "ابطال‌شده" },
];

export function ForceStatusForm({
  settlementId,
  currentStatus,
}: {
  settlementId: string;
  currentStatus: SettlementStatus;
}) {
  const [state, action, pending] =
    useActionState<SettlementAdminActionState | null, FormData>(adminForceSettlementStatus, null);
  const [open, setOpen] = useState(false);

  return (
    <div className="flex flex-col items-end gap-2">
      <Button
        type="button"
        size="sm"
        variant="outline"
        onClick={() => setOpen(!open)}
      >
        تغییر اضطراری وضعیت
      </Button>
      {open ? (
        <form action={action} className="flex flex-wrap items-end gap-2 w-full max-w-xl">
          <input type="hidden" name="settlementId" value={settlementId} />
          <select
            name="status"
            required
            defaultValue=""
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            <option value="" disabled>— وضعیت مقصد —</option>
            {STATUS_OPTIONS.filter((o) => o.value !== currentStatus).map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
          <Input name="reason" placeholder="دلیل" className="h-9 min-w-40" />
          <Button type="submit" size="sm" disabled={pending}>
            {pending ? "..." : "اعمال"}
          </Button>
        </form>
      ) : null}
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
      {state?.ok ? <p className="text-xs text-emerald-600">وضعیت به‌روز شد.</p> : null}
    </div>
  );
}
