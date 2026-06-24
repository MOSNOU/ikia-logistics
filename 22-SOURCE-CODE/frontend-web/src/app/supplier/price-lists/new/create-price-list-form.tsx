"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { createPriceList, type PricingActionState } from "@/lib/pricing/portal-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;

export function CreatePriceListForm({ supplierId }: { supplierId: string }) {
  const [state, formAction, pending] = useActionState<PricingActionState | null, FormData>(
    createPriceList,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="supplierId" value={supplierId} />

          <Field htmlFor="code" label="کد فهرست">
            <Input id="code" name="code" required dir="ltr" />
          </Field>

          <Field htmlFor="currencyCode" label="ارز">
            <select
              id="currencyCode"
              name="currencyCode"
              required
              defaultValue="USD"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="nameFa" label="عنوان فارسی">
            <Input id="nameFa" name="nameFa" required />
          </Field>

          <Field htmlFor="nameEn" label="عنوان انگلیسی">
            <Input id="nameEn" name="nameEn" required dir="ltr" />
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
              {pending ? "در حال ایجاد..." : "ایجاد فهرست"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
