"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { createOrganization, type CreateOrganizationState } from "@/lib/admin/create-organization";
import type { TenantOption } from "@/lib/admin/list-tenants";

const TYPE_OPTIONS = [
  { value: "buyer", label: "خریدار" },
  { value: "supplier", label: "تأمین‌کننده" },
  { value: "carrier", label: "حمل‌کننده" },
  { value: "broker", label: "واسطه" },
  { value: "government", label: "دولتی" },
  { value: "platform", label: "پلتفرم" },
] as const;

const STATUS_OPTIONS = [
  { value: "pending", label: "در حال بررسی" },
  { value: "active", label: "فعال" },
] as const;

export function CreateOrganizationForm({ tenants }: { tenants: TenantOption[] }) {
  const [state, formAction, pending] = useActionState<CreateOrganizationState | null, FormData>(
    createOrganization,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="tenantId" label="تننت">
            <select
              id="tenantId"
              name="tenantId"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب کنید —
              </option>
              {tenants.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.nameFa} ({t.code})
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="type" label="نوع سازمان">
            <select
              id="type"
              name="type"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب —
              </option>
              {TYPE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="code" label="کد سازمان">
            <Input id="code" name="code" required dir="ltr" />
          </Field>

          <Field htmlFor="status" label="وضعیت اولیه">
            <select
              id="status"
              name="status"
              defaultValue="pending"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {STATUS_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="nameFa" label="نام (فارسی)">
            <Input id="nameFa" name="nameFa" required />
          </Field>

          <Field htmlFor="nameEn" label="نام (انگلیسی)">
            <Input id="nameEn" name="nameEn" required dir="ltr" />
          </Field>

          <Field htmlFor="countryCode" label="کد کشور">
            <Input id="countryCode" name="countryCode" defaultValue="IR" maxLength={2} dir="ltr" />
          </Field>

          <Field htmlFor="legalName" label="نام حقوقی (اختیاری)">
            <Input id="legalName" name="legalName" />
          </Field>

          <Field htmlFor="registrationNumber" label="شماره ثبت (اختیاری)">
            <Input id="registrationNumber" name="registrationNumber" dir="ltr" />
          </Field>

          <Field htmlFor="taxId" label="کد اقتصادی (اختیاری)">
            <Input id="taxId" name="taxId" dir="ltr" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ایجاد..." : "ایجاد سازمان"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
