"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerCreateShipment, type ShipmentActionState } from "@/lib/shipment/buyer-actions";

const MODES = [
  { value: "road", label: "جاده" },
  { value: "rail", label: "ریلی" },
  { value: "sea", label: "دریایی" },
  { value: "air", label: "هوایی" },
  { value: "multimodal", label: "ترکیبی" },
  { value: "pipeline", label: "خط لوله" },
  { value: "other", label: "سایر" },
] as const;

export function CreateShipmentForm({ defaultContractId }: { defaultContractId: string }) {
  const [state, action, pending] = useActionState<ShipmentActionState | null, FormData>(
    buyerCreateShipment,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <Field htmlFor="executedContractId" label="شناسه قرارداد اجرایی (UUID)" className="md:col-span-2">
            <Input
              id="executedContractId"
              name="executedContractId"
              required
              defaultValue={defaultContractId}
              dir="ltr"
            />
          </Field>

          <Field htmlFor="transportMode" label="مود حمل">
            <select
              id="transportMode"
              name="transportMode"
              defaultValue="road"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {MODES.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="incoterm" label="اینکوترم">
            <Input id="incoterm" name="incoterm" dir="ltr" placeholder="FOB | CIF | EXW" />
          </Field>

          <Field htmlFor="plannedPickupDate" label="تاریخ بارگیری برنامه‌ریزی‌شده">
            <Input id="plannedPickupDate" name="plannedPickupDate" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="plannedDeliveryDate" label="تاریخ تحویل برنامه‌ریزی‌شده">
            <Input id="plannedDeliveryDate" name="plannedDeliveryDate" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="originCountry" label="کشور مبدأ">
            <Input id="originCountry" name="originCountry" dir="ltr" maxLength={2} placeholder="IR" />
          </Field>

          <Field htmlFor="originCity" label="شهر مبدأ">
            <Input id="originCity" name="originCity" />
          </Field>

          <Field htmlFor="destinationCountry" label="کشور مقصد">
            <Input id="destinationCountry" name="destinationCountry" dir="ltr" maxLength={2} placeholder="DE" />
          </Field>

          <Field htmlFor="destinationCity" label="شهر مقصد">
            <Input id="destinationCity" name="destinationCity" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-2">
            <textarea
              id="notes"
              name="notes"
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={3}
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ایجاد محموله"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
