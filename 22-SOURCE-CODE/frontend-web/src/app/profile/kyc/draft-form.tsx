"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { updatePersonalDraft, type KycActionState } from "@/lib/kyc/portal-actions";

interface Defaults {
  fullLegalName: string;
  nationalIdLast4: string;
  dateOfBirth: string;
  countryCode: string;
}

export function DraftForm({
  verificationId,
  defaults,
}: {
  verificationId: string;
  defaults: Defaults;
}) {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    updatePersonalDraft,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="verificationId" value={verificationId} />

          <Field htmlFor="fullLegalName" label="نام کامل قانونی" className="md:col-span-2">
            <Input id="fullLegalName" name="fullLegalName" defaultValue={defaults.fullLegalName} />
          </Field>

          <Field htmlFor="nationalIdNumber" label="شماره ملی (در صورت تغییر مجدداً وارد کنید)">
            <Input
              id="nationalIdNumber"
              name="nationalIdNumber"
              dir="ltr"
              placeholder={defaults.nationalIdLast4 ? `…${defaults.nationalIdLast4}` : ""}
            />
          </Field>

          <Field htmlFor="dateOfBirth" label="تاریخ تولد">
            <Input
              id="dateOfBirth"
              name="dateOfBirth"
              type="date"
              dir="ltr"
              defaultValue={defaults.dateOfBirth}
            />
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
