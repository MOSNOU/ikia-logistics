"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { submitForReview, type PortalActionState } from "@/lib/supplier/portal-actions";

export function SubmitForReviewForm() {
  const [state, formAction, pending] = useActionState<PortalActionState | null, FormData>(
    submitForReview,
    null,
  );
  return (
    <form action={formAction} className="flex items-center gap-3">
      <Button type="submit" disabled={pending}>
        {pending ? "در حال ارسال..." : "ارسال برای بررسی"}
      </Button>
      {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
      {state?.ok ? <span className="text-xs text-emerald-600">ارسال شد</span> : null}
    </form>
  );
}
