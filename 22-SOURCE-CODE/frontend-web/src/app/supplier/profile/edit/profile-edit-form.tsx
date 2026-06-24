"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { upsertMyProfile, type PortalActionState } from "@/lib/supplier/portal-actions";

interface Defaults {
  displayName: string | null;
  description: string | null;
  website: string | null;
  contactEmail: string | null;
  contactPhone: string | null;
  countryCode: string | null;
  establishedYear: number | null;
}

export function ProfileEditForm({ defaults }: { defaults: Defaults }) {
  const [state, formAction, pending] = useActionState<PortalActionState | null, FormData>(
    upsertMyProfile,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="displayName" label="نام نمایش">
            <Input id="displayName" name="displayName" defaultValue={defaults.displayName ?? ""} />
          </Field>

          <Field htmlFor="countryCode" label="کد کشور">
            <Input
              id="countryCode"
              name="countryCode"
              maxLength={2}
              defaultValue={defaults.countryCode ?? "IR"}
              dir="ltr"
            />
          </Field>

          <Field htmlFor="contactEmail" label="ایمیل تماس">
            <Input id="contactEmail" name="contactEmail" type="email"
              defaultValue={defaults.contactEmail ?? ""} dir="ltr" />
          </Field>

          <Field htmlFor="contactPhone" label="تلفن">
            <Input id="contactPhone" name="contactPhone"
              defaultValue={defaults.contactPhone ?? ""} dir="ltr" />
          </Field>

          <Field htmlFor="website" label="وب‌سایت">
            <Input id="website" name="website"
              defaultValue={defaults.website ?? ""} dir="ltr" />
          </Field>

          <Field htmlFor="establishedYear" label="سال تأسیس">
            <Input
              id="establishedYear"
              name="establishedYear"
              type="number"
              min={1800}
              max={2100}
              defaultValue={defaults.establishedYear ?? ""}
              dir="ltr"
            />
          </Field>

          <Field htmlFor="description" label="توضیحات" className="md:col-span-2">
            <textarea
              id="description"
              name="description"
              defaultValue={defaults.description ?? ""}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={4}
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ذخیره..." : "ذخیره"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
