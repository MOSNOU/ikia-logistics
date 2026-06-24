"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { upsertPriceListItem, type PricingActionState } from "@/lib/pricing/portal-actions";

export function UpsertItemForm({ priceListId }: { priceListId: string }) {
  const [state, formAction, pending] = useActionState<PricingActionState | null, FormData>(
    upsertPriceListItem,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="priceListId" value={priceListId} />

          <Field htmlFor="productId" label="شناسه کالا (UUID)" className="md:col-span-2">
            <Input id="productId" name="productId" required dir="ltr" />
          </Field>

          <Field htmlFor="uom" label="واحد">
            <Input id="uom" name="uom" required dir="ltr" placeholder="kg" />
          </Field>

          <Field htmlFor="unitPrice" label="قیمت واحد">
            <Input id="unitPrice" name="unitPrice" required type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="minQty" label="حداقل سفارش">
            <Input id="minQty" name="minQty" type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="maxQty" label="حداکثر سفارش">
            <Input id="maxQty" name="maxQty" type="number" step="0.0001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-3">
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
              {pending ? "در حال ذخیره..." : "ذخیره ردیف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
