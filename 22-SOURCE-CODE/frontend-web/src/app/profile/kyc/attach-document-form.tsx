"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { attachDocument, type KycActionState } from "@/lib/kyc/portal-actions";
import type { KycSubjectType } from "@/types/database";

const PERSONAL_KINDS = [
  { value: "national_id_card", label: "کارت ملی" },
  { value: "passport", label: "گذرنامه" },
  { value: "driver_license", label: "گواهی‌نامه" },
  { value: "proof_of_address", label: "اثبات سکونت" },
  { value: "other", label: "سایر" },
] as const;

const ORG_KINDS = [
  { value: "company_registration", label: "ثبت شرکت" },
  { value: "tax_certificate", label: "گواهی مالیاتی" },
  { value: "articles_of_association", label: "اساسنامه" },
  { value: "authorized_signatory_letter", label: "نامه امضاء مجاز" },
  { value: "ownership_disclosure", label: "افشای مالکیت" },
  { value: "other", label: "سایر" },
] as const;

export function AttachDocumentForm({
  verificationId,
  subjectType,
}: {
  verificationId: string;
  subjectType: KycSubjectType;
}) {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    attachDocument,
    null,
  );
  const kinds = subjectType === "person" ? PERSONAL_KINDS : ORG_KINDS;

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="verificationId" value={verificationId} />
          <input type="hidden" name="subjectType" value={subjectType} />

          <Field htmlFor="documentKind" label="نوع مدرک">
            <select
              id="documentKind"
              name="documentKind"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {kinds.map((k) => (
                <option key={k.value} value={k.value}>{k.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="title" label="عنوان">
            <Input id="title" name="title" />
          </Field>

          <Field htmlFor="storagePath" label="مسیر فایل (kyc-private/…)" className="md:col-span-2">
            <Input id="storagePath" name="storagePath" required dir="ltr" />
          </Field>

          <Field htmlFor="mimeType" label="نوع MIME">
            <Input id="mimeType" name="mimeType" dir="ltr" placeholder="application/pdf" />
          </Field>

          <Field htmlFor="issuedOn" label="تاریخ صدور">
            <Input id="issuedOn" name="issuedOn" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="expiresOn" label="تاریخ انقضا" className="md:col-span-2">
            <Input id="expiresOn" name="expiresOn" type="date" dir="ltr" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">مدرک افزوده شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال افزودن..." : "افزودن مدرک"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
