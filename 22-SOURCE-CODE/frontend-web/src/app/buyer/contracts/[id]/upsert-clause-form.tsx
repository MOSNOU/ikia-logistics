"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertClause, type ContractActionState } from "@/lib/contract/buyer-actions";

const CLAUSE_TYPES = [
  { value: "payment", label: "پرداخت" },
  { value: "delivery", label: "تحویل" },
  { value: "inspection", label: "بازرسی" },
  { value: "quality", label: "کیفیت" },
  { value: "documents", label: "مدارک" },
  { value: "force_majeure", label: "فورس ماژور" },
  { value: "dispute_resolution", label: "حل اختلاف" },
  { value: "governing_law", label: "قانون حاکم" },
  { value: "special_conditions", label: "شرایط ویژه" },
  { value: "other", label: "سایر" },
] as const;

export function UpsertClauseForm({ preparationId }: { preparationId: string }) {
  const [state, action, pending] = useActionState<ContractActionState | null, FormData>(
    buyerUpsertClause,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="preparationId" value={preparationId} />

          <Field htmlFor="clauseType" label="نوع بند">
            <select
              id="clauseType"
              name="clauseType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {CLAUSE_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="clauseKey" label="کلید بند">
            <Input id="clauseKey" name="clauseKey" dir="ltr" />
          </Field>

          <Field htmlFor="titleFa" label="عنوان فارسی">
            <Input id="titleFa" name="titleFa" />
          </Field>

          <Field htmlFor="titleEn" label="عنوان انگلیسی">
            <Input id="titleEn" name="titleEn" dir="ltr" />
          </Field>

          <Field htmlFor="bodyFa" label="متن فارسی" className="md:col-span-2">
            <textarea
              id="bodyFa"
              name="bodyFa"
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={3}
            />
          </Field>

          <Field htmlFor="bodyEn" label="متن انگلیسی" className="md:col-span-2">
            <textarea
              id="bodyEn"
              name="bodyEn"
              dir="ltr"
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={3}
            />
          </Field>

          <Field htmlFor="sortOrder" label="ترتیب">
            <Input id="sortOrder" name="sortOrder" type="number" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="isRequired" label="ضروری">
            <input id="isRequired" name="isRequired" type="checkbox" className="h-4 w-4" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">بند ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره بند"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
