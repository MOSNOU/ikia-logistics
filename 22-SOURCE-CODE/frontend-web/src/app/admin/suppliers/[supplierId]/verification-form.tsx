"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { setVerificationStatus, type AdminSupplierActionState } from "@/lib/admin/supplier-lifecycle";
import type { VerificationStatus } from "@/types/database";

const OPTIONS: { value: VerificationStatus; label: string }[] = [
  { value: "unverified", label: "احرازنشده" },
  { value: "pending", label: "در حال احراز" },
  { value: "verified", label: "احرازشده" },
  { value: "expired", label: "منقضی" },
  { value: "rejected", label: "ردشده" },
];

export function VerificationForm({
  supplierId,
  currentStatus,
}: {
  supplierId: string;
  currentStatus: VerificationStatus;
}) {
  const [state, formAction, pending] = useActionState<AdminSupplierActionState | null, FormData>(
    setVerificationStatus,
    null,
  );
  return (
    <form action={formAction} className="flex flex-wrap items-end gap-3">
      <input type="hidden" name="supplierId" value={supplierId} />
      <div className="space-y-1">
        <label htmlFor="verificationStatus" className="text-sm font-medium">وضعیت احراز</label>
        <select
          id="verificationStatus"
          name="verificationStatus"
          defaultValue={currentStatus}
          className="h-9 rounded-md border border-input bg-background px-2 text-sm"
        >
          {OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
      </div>
      <input
        type="text"
        name="reason"
        placeholder="دلیل (اختیاری)"
        className="h-9 rounded-md border border-input bg-background px-2 text-sm"
      />
      <Button type="submit" disabled={pending}>
        {pending ? "در حال اعمال..." : "ذخیره"}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
      {state?.ok ? <span className="text-xs text-emerald-600">به‌روزرسانی شد</span> : null}
    </form>
  );
}
