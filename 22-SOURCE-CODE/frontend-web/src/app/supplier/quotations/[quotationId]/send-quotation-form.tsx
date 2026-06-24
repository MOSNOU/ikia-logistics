"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { sendQuotation, type PricingActionState } from "@/lib/pricing/portal-actions";

export function SendQuotationForm({ quotationId }: { quotationId: string }) {
  const [state, formAction, pending] = useActionState<PricingActionState | null, FormData>(
    sendQuotation,
    null,
  );

  return (
    <div className="flex flex-col items-end gap-2">
      <form action={formAction}>
        <input type="hidden" name="quotationId" value={quotationId} />
        <Button type="submit" disabled={pending}>
          {pending ? "در حال ارسال..." : "ارسال به خریدار"}
        </Button>
      </form>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </div>
  );
}
