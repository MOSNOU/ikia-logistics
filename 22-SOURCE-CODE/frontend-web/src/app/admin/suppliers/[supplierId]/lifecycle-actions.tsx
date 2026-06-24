"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import {
  startReview,
  approveSupplier,
  rejectSupplier,
  suspendSupplier,
  reactivateSupplier,
  type AdminSupplierActionState,
} from "@/lib/admin/supplier-lifecycle";
import type { SupplierStatus } from "@/types/database";

interface Props {
  supplierId: string;
  status: SupplierStatus;
}

export function LifecycleActions({ supplierId, status }: Props) {
  return (
    <div className="flex flex-wrap gap-3">
      {status === "submitted" ? (
        <ActionForm action={startReview} supplierId={supplierId} label="شروع بررسی" />
      ) : null}
      {status === "under_review" ? (
        <>
          <ActionForm action={approveSupplier} supplierId={supplierId} label="تأیید" />
          <ReasonForm action={rejectSupplier} supplierId={supplierId} label="رد" />
        </>
      ) : null}
      {status === "approved" ? (
        <ReasonForm action={suspendSupplier} supplierId={supplierId} label="تعلیق" />
      ) : null}
      {status === "suspended" ? (
        <ActionForm
          action={reactivateSupplier}
          supplierId={supplierId}
          label="فعال‌سازی مجدد"
        />
      ) : null}
      {status === "draft" || status === "rejected" ? (
        <p className="text-xs text-muted-foreground">
          در این وضعیت اقدام مدیر در این فاز موجود نیست.
        </p>
      ) : null}
    </div>
  );
}

interface ActionFormProps {
  action: (prev: AdminSupplierActionState | null, fd: FormData) => Promise<AdminSupplierActionState>;
  supplierId: string;
  label: string;
}

function ActionForm({ action, supplierId, label }: ActionFormProps) {
  const [state, formAction, pending] = useActionState<AdminSupplierActionState | null, FormData>(
    action,
    null,
  );
  return (
    <form action={formAction} className="inline-flex items-center gap-2">
      <input type="hidden" name="supplierId" value={supplierId} />
      <Button type="submit" size="sm" disabled={pending}>
        {pending ? "..." : label}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
    </form>
  );
}

function ReasonForm({ action, supplierId, label }: ActionFormProps) {
  const [state, formAction, pending] = useActionState<AdminSupplierActionState | null, FormData>(
    action,
    null,
  );
  return (
    <form action={formAction} className="inline-flex items-center gap-2">
      <input type="hidden" name="supplierId" value={supplierId} />
      <input
        type="text"
        name="reason"
        placeholder="دلیل (اختیاری)"
        className="h-8 rounded-md border border-input bg-background px-2 text-xs"
      />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : label}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
    </form>
  );
}
