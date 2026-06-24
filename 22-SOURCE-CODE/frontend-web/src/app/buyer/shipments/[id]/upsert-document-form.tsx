"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertDocument, type ShipmentActionState } from "@/lib/shipment/buyer-actions";

const DOC_KINDS = [
  { value: "bill_of_lading", label: "بارنامه" },
  { value: "cmr", label: "CMR" },
  { value: "rail_waybill", label: "بارنامه ریلی" },
  { value: "airway_bill", label: "بارنامه هوایی" },
  { value: "packing_list", label: "فهرست بسته‌بندی" },
  { value: "certificate_of_origin", label: "گواهی مبدأ" },
  { value: "inspection_certificate", label: "گواهی بازرسی" },
  { value: "customs_declaration", label: "اظهارنامه گمرکی" },
  { value: "delivery_order", label: "دستور تحویل" },
  { value: "proof_of_delivery", label: "اثبات تحویل" },
  { value: "other", label: "سایر" },
] as const;

export function UpsertDocumentForm({ shipmentId }: { shipmentId: string }) {
  const [state, action, pending] = useActionState<ShipmentActionState | null, FormData>(
    buyerUpsertDocument,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="shipmentId" value={shipmentId} />

          <Field htmlFor="documentKind" label="نوع مدرک">
            <select
              id="documentKind"
              name="documentKind"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {DOC_KINDS.map((k) => (
                <option key={k.value} value={k.value}>{k.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="externalReference" label="مرجع خارجی" className="md:col-span-2">
            <Input id="externalReference" name="externalReference" dir="ltr" placeholder="BL/AWB number" />
          </Field>

          <Field htmlFor="issuedAt" label="تاریخ صدور">
            <Input id="issuedAt" name="issuedAt" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="expiresAt" label="تاریخ انقضا">
            <Input id="expiresAt" name="expiresAt" type="date" dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">مدرک ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره مدرک"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
