"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerCreatePreparation, type ContractActionState } from "@/lib/contract/buyer-actions";

const CURRENCIES = ["IRR", "USD", "EUR"] as const;
const CONTRACT_TYPES = [
  { value: "spot", label: "نقدی" },
  { value: "framework", label: "چارچوبی" },
  { value: "term", label: "بلندمدت" },
  { value: "other", label: "سایر" },
] as const;

export function CreatePreparationForm({ defaultDecisionId }: { defaultDecisionId: string }) {
  const [state, action, pending] = useActionState<ContractActionState | null, FormData>(
    buyerCreatePreparation,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="decisionId" label="شناسه تصمیم (UUID)" className="md:col-span-2">
            <Input
              id="decisionId"
              name="decisionId"
              required
              defaultValue={defaultDecisionId}
              dir="ltr"
            />
          </Field>

          <Field htmlFor="title" label="عنوان قرارداد" className="md:col-span-2">
            <Input id="title" name="title" required />
          </Field>

          <Field htmlFor="currency" label="ارز">
            <select
              id="currency"
              name="currency"
              defaultValue="USD"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="contractType" label="نوع قرارداد">
            <select
              id="contractType"
              name="contractType"
              defaultValue="spot"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {CONTRACT_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="incoterm" label="اینکوترم">
            <Input id="incoterm" name="incoterm" dir="ltr" placeholder="FOB | CIF | EXW" />
          </Field>

          <Field htmlFor="internalNotes" label="یادداشت داخلی" className="md:col-span-2">
            <textarea
              id="internalNotes"
              name="internalNotes"
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={3}
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ایجاد آماده‌سازی"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
