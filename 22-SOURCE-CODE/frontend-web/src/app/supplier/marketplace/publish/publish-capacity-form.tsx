"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  publishCapacity,
  type PublishCapacityState,
} from "@/lib/marketplace/publish-capacity";

const MODES = [
  { value: "road", label: "جاده" },
  { value: "rail", label: "ریل" },
  { value: "sea", label: "دریا" },
  { value: "air", label: "هوا" },
  { value: "multimodal", label: "ترکیبی" },
  { value: "pipeline", label: "خط لوله" },
  { value: "other", label: "سایر" },
];

interface Props {
  carrierOrganizationId: string | null;
}

export function PublishCapacityForm({ carrierOrganizationId }: Props) {
  const [state, action, pending] = useActionState<PublishCapacityState | null, FormData>(
    publishCapacity,
    null,
  );
  const orgMissing = !carrierOrganizationId;

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input
            type="hidden"
            name="carrierOrganizationId"
            value={carrierOrganizationId ?? ""}
          />
          <Field htmlFor="transportMode" label="مود حمل">
            <select
              id="transportMode"
              name="transportMode"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {MODES.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
          </Field>
          <Field htmlFor="capacityUnits" label="ظرفیت (عدد)">
            <Input id="capacityUnits" name="capacityUnits" type="number" min="0" />
          </Field>
          <Field htmlFor="capacityUnitLabel" label="واحد ظرفیت">
            <Input
              id="capacityUnitLabel"
              name="capacityUnitLabel"
              placeholder="TEU / تن / متر مکعب"
            />
          </Field>
          <Field htmlFor="originCountry" label="کشور مبدأ">
            <Input id="originCountry" name="originCountry" dir="ltr" placeholder="IR" />
          </Field>
          <Field htmlFor="originCity" label="شهر مبدأ">
            <Input id="originCity" name="originCity" />
          </Field>
          <Field htmlFor="destinationCountry" label="کشور مقصد">
            <Input id="destinationCountry" name="destinationCountry" dir="ltr" placeholder="DE" />
          </Field>
          <Field htmlFor="destinationCity" label="شهر مقصد">
            <Input id="destinationCity" name="destinationCity" />
          </Field>
          <Field htmlFor="validFrom" label="از تاریخ">
            <Input id="validFrom" name="validFrom" type="date" dir="ltr" />
          </Field>
          <Field htmlFor="validUntil" label="تا تاریخ">
            <Input id="validUntil" name="validUntil" type="date" dir="ltr" />
          </Field>
          <Field htmlFor="notesFa" label="یادداشت (فارسی)" className="md:col-span-2">
            <Input id="notesFa" name="notesFa" />
          </Field>

          {orgMissing ? (
            <p className="md:col-span-2 text-xs text-amber-600">
              سازمان فعال کاربر مشخص نیست؛ پیش از انتشار ظرفیت، عضویت روی یک سازمان حمل‌کننده تنظیم شود.
            </p>
          ) : null}
          {state?.error ? (
            <p className="md:col-span-2 text-xs text-amber-600">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">ظرفیت با موفقیت منتشر شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending || orgMissing}>
              {pending ? "..." : "انتشار ظرفیت"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
