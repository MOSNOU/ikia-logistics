"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import {
  supplierCreateDraftOffer,
  type OfferActionState,
} from "@/lib/offer/supplier-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;

export function DraftOfferButton({ requestId }: { requestId: string }) {
  const [state, action, pending] = useActionState<OfferActionState | null, FormData>(
    supplierCreateDraftOffer,
    null,
  );

  return (
    <form action={action} className="flex items-end gap-2">
      <input type="hidden" name="requestId" value={requestId} />
      <select
        name="currency"
        defaultValue="USD"
        className="h-9 rounded-md border border-input bg-background px-2 text-sm"
      >
        {CURRENCIES.map((c) => (
          <option key={c} value={c}>{c}</option>
        ))}
      </select>
      <Button type="submit" disabled={pending}>
        {pending ? "در حال ایجاد..." : "ایجاد پیش‌نویس پیشنهاد"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
