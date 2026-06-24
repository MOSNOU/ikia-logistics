"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { addQuotationItem, type PricingActionState } from "@/lib/pricing/portal-actions";

export function AddItemForm({ quotationId }: { quotationId: string }) {
  const [state, formAction, pending] = useActionState<PricingActionState | null, FormData>(
    addQuotationItem,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="quotationId" value={quotationId} />

          <Field htmlFor="productId" label="شناسه کالا (UUID)" className="md:col-span-2">
            <Input id="productId" name="productId" required dir="ltr" />
          </Field>

          <Field htmlFor="uom" label="واحد">
            <Input id="uom" name="uom" required dir="ltr" placeholder="kg" />
          </Field>

          <Field htmlFor="quantity" label="تعداد">
            <Input id="quantity" name="quantity" required type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="unitPrice" label="قیمت واحد">
            <Input id="unitPrice" name="unitPrice" required type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="discount" label="تخفیف">
            <Input id="discount" name="discount" type="number" step="0.0001" min="0" defaultValue={0} dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-3">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">ردیف اضافه شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال افزودن..." : "افزودن ردیف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
