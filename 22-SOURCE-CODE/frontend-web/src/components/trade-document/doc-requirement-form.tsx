"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  type TradeDocActionState,
  upsertDocRequirement,
} from "@/lib/trade-document/actions-buyer";
import { DOC_KIND_OPTIONS } from "@/lib/trade-document/labels";

interface Props {
  shipmentId: string;
  initial?: {
    requirementId?: string;
    documentKind?: string;
    requirementLevel?: string;
    displayNameEn?: string | null;
    displayNameFa?: string | null;
    notes?: string | null;
  };
  submitLabel?: string;
}

export function DocRequirementForm({ shipmentId, initial, submitLabel }: Props) {
  const [state, action, pending] = useActionState<TradeDocActionState | null, FormData>(
    upsertDocRequirement,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="shipmentId" value={shipmentId} />

          <Field htmlFor="documentKind" label="نوع مدرک" error={state?.fieldErrors?.documentKind}>
            <select
              id="documentKind"
              name="documentKind"
              required
              defaultValue={initial?.documentKind ?? ""}
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {DOC_KIND_OPTIONS.filter((o) => o.value !== "").map((k) => (
                <option key={k.value} value={k.value}>{k.label}</option>
              ))}
            </select>
          </Field>

          <Field
            htmlFor="requirementLevel"
            label="سطح نیازمندی"
            error={state?.fieldErrors?.requirementLevel}
          >
            <select
              id="requirementLevel"
              name="requirementLevel"
              defaultValue={initial?.requirementLevel ?? "required"}
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="required">الزامی</option>
              <option value="recommended">پیشنهادی</option>
              <option value="optional">اختیاری</option>
            </select>
          </Field>

          <Field htmlFor="displayNameFa" label="عنوان نمایشی (فارسی)">
            <Input
              id="displayNameFa"
              name="displayNameFa"
              defaultValue={initial?.displayNameFa ?? ""}
            />
          </Field>

          <Field htmlFor="displayNameEn" label="عنوان نمایشی (انگلیسی)">
            <Input
              id="displayNameEn"
              name="displayNameEn"
              dir="ltr"
              defaultValue={initial?.displayNameEn ?? ""}
            />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-2">
            <Input id="notes" name="notes" defaultValue={initial?.notes ?? ""} />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">نیازمندی ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : (submitLabel ?? "ذخیره نیازمندی")}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
