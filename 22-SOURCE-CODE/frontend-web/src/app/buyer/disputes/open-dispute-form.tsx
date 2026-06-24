"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { buyerOpenDispute, type DisputeActionState } from "@/lib/dispute/buyer-actions";

export function OpenDisputeForm() {
  const [state, action, pending] = useActionState<DisputeActionState | null, FormData>(
    buyerOpenDispute,
    null,
  );

  return (
    <form action={action} className="grid gap-4 md:grid-cols-2">
      <Field htmlFor="settlementId" label="شناسه تسویه">
        <Input id="settlementId" name="settlementId" required dir="ltr" />
      </Field>

      <Field htmlFor="title" label="عنوان">
        <Input id="title" name="title" required />
      </Field>

      <Field htmlFor="amountInDispute" label="مبلغ اختلاف">
        <Input id="amountInDispute" name="amountInDispute" type="number" step="0.01" min="0" dir="ltr" />
      </Field>

      <Field htmlFor="description" label="توضیحات" className="md:col-span-2">
        <textarea
          id="description"
          name="description"
          className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
          rows={3}
        />
      </Field>

      {state?.error ? (
        <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
      ) : null}

      <div className="md:col-span-2">
        <Button type="submit" disabled={pending}>
          {pending ? "در حال ثبت..." : "ثبت اختلاف"}
        </Button>
      </div>
    </form>
  );
}
