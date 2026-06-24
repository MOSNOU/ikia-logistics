"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { addMyDocument, type PortalActionState } from "@/lib/supplier/portal-actions";

const TYPE_OPTIONS = [
  { value: "license", label: "مجوز" },
  { value: "tax_certificate", label: "گواهی مالیاتی" },
  { value: "registration", label: "ثبت" },
  { value: "iso_certificate", label: "ISO" },
  { value: "bank_letter", label: "گواهی بانک" },
  { value: "other", label: "سایر" },
] as const;

export function AddDocumentForm() {
  const [state, formAction, pending] = useActionState<PortalActionState | null, FormData>(
    addMyDocument,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="documentType" label="نوع مدرک">
            <select
              id="documentType"
              name="documentType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {TYPE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="title" label="عنوان">
            <Input id="title" name="title" required />
          </Field>

          <Field htmlFor="externalReference" label="مرجع خارجی (لینک)">
            <Input id="externalReference" name="externalReference" dir="ltr" />
          </Field>

          <Field htmlFor="issuedAt" label="تاریخ صدور">
            <Input id="issuedAt" name="issuedAt" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="expiresAt" label="تاریخ انقضا">
            <Input id="expiresAt" name="expiresAt" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="description" label="توضیحات" className="md:col-span-2">
            <textarea
              id="description"
              name="description"
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={3}
            />
          </Field>

          {state?.error ? <p className="md:col-span-2 text-xs text-destructive">{state.error}</p> : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال افزودن..." : "افزودن"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
