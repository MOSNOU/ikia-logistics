"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertRfqItem, type RfqActionState } from "@/lib/rfq/buyer-actions";

export function UpsertItemForm({ requestId }: { requestId: string }) {
  const [state, action, pending] = useActionState<RfqActionState | null, FormData>(
    buyerUpsertRfqItem,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="requestId" value={requestId} />

          <Field htmlFor="productId" label="شناسه کالا (UUID)" className="md:col-span-2">
            <Input id="productId" name="productId" dir="ltr" />
          </Field>

          <Field htmlFor="quantityUnit" label="واحد">
            <Input id="quantityUnit" name="quantityUnit" dir="ltr" placeholder="kg" />
          </Field>

          <Field htmlFor="quantity" label="تعداد">
            <Input id="quantity" name="quantity" type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-2">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">ردیف ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره ردیف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
