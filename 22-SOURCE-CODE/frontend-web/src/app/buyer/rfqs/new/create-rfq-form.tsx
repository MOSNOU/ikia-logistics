"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerCreateRfq, type RfqActionState } from "@/lib/rfq/buyer-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;

export function CreateRfqForm() {
  const [state, action, pending] = useActionState<RfqActionState | null, FormData>(
    buyerCreateRfq,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="title" label="عنوان" className="md:col-span-2">
            <Input id="title" name="title" required />
          </Field>

          <Field htmlFor="preferredCurrency" label="ارز ترجیحی">
            <select
              id="preferredCurrency"
              name="preferredCurrency"
              defaultValue="USD"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="submissionDeadline" label="مهلت ارسال پیشنهاد">
            <Input id="submissionDeadline" name="submissionDeadline" type="datetime-local" dir="ltr" />
          </Field>

          <Field htmlFor="deliveryCountry" label="کشور تحویل (ISO)">
            <Input id="deliveryCountry" name="deliveryCountry" dir="ltr" maxLength={2} placeholder="IR" />
          </Field>

          <Field htmlFor="deliveryCity" label="شهر تحویل">
            <Input id="deliveryCity" name="deliveryCity" />
          </Field>

          <Field htmlFor="paymentTermsText" label="شرایط پرداخت" className="md:col-span-2">
            <Input id="paymentTermsText" name="paymentTermsText" />
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
              {pending ? "در حال ایجاد..." : "ایجاد RFQ"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
