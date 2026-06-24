"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { createQuotation, type PricingActionState } from "@/lib/pricing/portal-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;

export function CreateQuotationForm({ supplierId }: { supplierId: string }) {
  const [state, formAction, pending] = useActionState<PricingActionState | null, FormData>(
    createQuotation,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="supplierId" value={supplierId} />

          <Field htmlFor="quotationCode" label="کد پیشنهاد">
            <Input id="quotationCode" name="quotationCode" required dir="ltr" />
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

          <Field htmlFor="buyerOrganizationId" label="شناسه سازمان خریدار" className="md:col-span-2">
            <Input id="buyerOrganizationId" name="buyerOrganizationId" required dir="ltr" />
          </Field>

          <Field htmlFor="rfqRequestId" label="شناسه RFQ (اختیاری)">
            <Input id="rfqRequestId" name="rfqRequestId" dir="ltr" />
          </Field>

          <Field htmlFor="validUntil" label="اعتبار تا">
            <Input id="validUntil" name="validUntil" type="datetime-local" dir="ltr" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ایجاد..." : "ایجاد پیشنهاد"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
