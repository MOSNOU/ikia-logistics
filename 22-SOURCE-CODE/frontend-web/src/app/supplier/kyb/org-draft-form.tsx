"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { updateOrganizationDraft, type KycActionState } from "@/lib/kyc/portal-actions";

interface Defaults {
  legalName: string;
  registrationNumber: string;
  taxId: string;
  countryCode: string;
  incorporatedOn: string;
}

export function OrgDraftForm({
  verificationId,
  defaults,
}: {
  verificationId: string;
  defaults: Defaults;
}) {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    updateOrganizationDraft,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="verificationId" value={verificationId} />

          <Field htmlFor="legalName" label="نام قانونی سازمان" className="md:col-span-2">
            <Input id="legalName" name="legalName" defaultValue={defaults.legalName} />
          </Field>

          <Field htmlFor="registrationNumber" label="شماره ثبت">
            <Input
              id="registrationNumber"
              name="registrationNumber"
              dir="ltr"
              defaultValue={defaults.registrationNumber}
            />
          </Field>

          <Field htmlFor="taxId" label="شناسه مالیاتی">
            <Input id="taxId" name="taxId" dir="ltr" defaultValue={defaults.taxId} />
          </Field>

          <Field htmlFor="countryCode" label="کد کشور (ISO)">
            <Input
              id="countryCode"
              name="countryCode"
              dir="ltr"
              maxLength={2}
              defaultValue={defaults.countryCode}
              placeholder="IR"
            />
          </Field>

          <Field htmlFor="incorporatedOn" label="تاریخ تأسیس">
            <Input
              id="incorporatedOn"
              name="incorporatedOn"
              type="date"
              dir="ltr"
              defaultValue={defaults.incorporatedOn}
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">پیش‌نویس ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ذخیره..." : "ذخیره پیش‌نویس"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
