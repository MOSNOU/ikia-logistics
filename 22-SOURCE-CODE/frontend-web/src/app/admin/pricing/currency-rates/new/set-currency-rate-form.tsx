"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { setCurrencyRate, type PricingAdminActionState } from "@/lib/admin/pricing-admin-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;

export function SetCurrencyRateForm() {
  const [state, formAction, pending] = useActionState<PricingAdminActionState | null, FormData>(
    setCurrencyRate,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="baseCode" label="ارز مبدا">
            <select
              id="baseCode"
              name="baseCode"
              required
              defaultValue="USD"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="quoteCode" label="ارز مقصد">
            <select
              id="quoteCode"
              name="quoteCode"
              required
              defaultValue="EUR"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="rate" label="نرخ (۱ مبدا = X مقصد)">
            <Input id="rate" name="rate" required type="number" step="0.0000000001" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="source" label="منبع">
            <Input id="source" name="source" defaultValue="manual" dir="ltr" />
          </Field>

          <Field htmlFor="effectiveFrom" label="اعتبار از">
            <Input id="effectiveFrom" name="effectiveFrom" type="datetime-local" dir="ltr" />
          </Field>

          <Field htmlFor="effectiveTo" label="اعتبار تا (اختیاری)">
            <Input id="effectiveTo" name="effectiveTo" type="datetime-local" dir="ltr" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ثبت..." : "ثبت نرخ"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
