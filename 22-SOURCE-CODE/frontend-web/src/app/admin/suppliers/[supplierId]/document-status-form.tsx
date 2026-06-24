"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { setDocumentStatus, type AdminSupplierActionState } from "@/lib/admin/supplier-lifecycle";
import type { DocumentStatus } from "@/types/database";

const OPTIONS: { value: DocumentStatus; label: string }[] = [
  { value: "pending", label: "در انتظار" },
  { value: "verified", label: "تأییدشده" },
  { value: "rejected", label: "ردشده" },
  { value: "expired", label: "منقضی" },
];

export function DocumentStatusForm({
  documentId,
  supplierId,
  currentStatus,
}: {
  documentId: string;
  supplierId: string;
  currentStatus: DocumentStatus;
}) {
  const [state, formAction, pending] = useActionState<AdminSupplierActionState | null, FormData>(
    setDocumentStatus,
    null,
  );
  return (
    <form action={formAction} className="flex items-center gap-1">
      <input type="hidden" name="documentId" value={documentId} />
      <input type="hidden" name="supplierId" value={supplierId} />
      <select
        name="documentStatus"
        defaultValue={currentStatus}
        className="h-7 rounded-md border border-input bg-background px-2 text-xs"
      >
        {OPTIONS.map((o) => (
          <option key={o.value} value={o.value}>{o.label}</option>
        ))}
      </select>
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "ذخیره"}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
    </form>
  );
}
