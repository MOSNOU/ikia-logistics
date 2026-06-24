"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertStop, type TrackingActionState } from "@/lib/shipment/tracking-actions";

const STOP_TYPES = [
  { value: "pickup", label: "بارگیری" },
  { value: "loading", label: "تخلیه/بارگیری" },
  { value: "border", label: "مرز" },
  { value: "transshipment", label: "انتقال" },
  { value: "customs", label: "گمرک" },
  { value: "unloading", label: "تخلیه" },
  { value: "delivery", label: "تحویل" },
  { value: "other", label: "سایر" },
] as const;

export function UpsertStopForm({ shipmentId }: { shipmentId: string }) {
  const [state, action, pending] = useActionState<TrackingActionState | null, FormData>(
    buyerUpsertStop,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="shipmentId" value={shipmentId} />

          <Field htmlFor="sequenceNumber" label="شماره ترتیب">
            <Input
              id="sequenceNumber"
              name="sequenceNumber"
              type="number"
              min={1}
              required
              dir="ltr"
            />
          </Field>

          <Field htmlFor="stopType" label="نوع توقف">
            <select
              id="stopType"
              name="stopType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {STOP_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="city" label="شهر">
            <Input id="city" name="city" />
          </Field>

          <Field htmlFor="country" label="کشور (ISO)">
            <Input id="country" name="country" dir="ltr" maxLength={2} placeholder="IR" />
          </Field>

          <Field htmlFor="port" label="بندر / مرز">
            <Input id="port" name="port" />
          </Field>

          <Field htmlFor="locationText" label="نشانی متنی">
            <Input id="locationText" name="locationText" />
          </Field>

          <Field htmlFor="plannedArrivalAt" label="ورود برنامه‌ریزی‌شده">
            <Input
              id="plannedArrivalAt"
              name="plannedArrivalAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>

          <Field htmlFor="actualArrivalAt" label="ورود واقعی">
            <Input
              id="actualArrivalAt"
              name="actualArrivalAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>

          <Field htmlFor="plannedDepartureAt" label="خروج برنامه‌ریزی‌شده">
            <Input
              id="plannedDepartureAt"
              name="plannedDepartureAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>

          <Field htmlFor="actualDepartureAt" label="خروج واقعی">
            <Input
              id="actualDepartureAt"
              name="actualDepartureAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-3">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">توقف ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره توقف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
