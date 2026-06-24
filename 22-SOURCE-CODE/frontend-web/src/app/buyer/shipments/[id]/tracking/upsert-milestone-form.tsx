"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertMilestone, type TrackingActionState } from "@/lib/shipment/tracking-actions";

const MILESTONE_TYPES = [
  { value: "booking_confirmed", label: "تأیید رزرو" },
  { value: "cargo_ready", label: "بار آماده" },
  { value: "pickup_completed", label: "بارگیری انجام شد" },
  { value: "customs_export_cleared", label: "ترخیص گمرکی صادرات" },
  { value: "departed_origin", label: "خروج از مبدأ" },
  { value: "border_crossed", label: "عبور از مرز" },
  { value: "arrived_destination", label: "ورود به مقصد" },
  { value: "customs_import_cleared", label: "ترخیص گمرکی واردات" },
  { value: "delivered", label: "تحویل‌شده" },
  { value: "closed", label: "بسته‌شده" },
  { value: "other", label: "سایر" },
] as const;

const STATUSES = [
  { value: "pending", label: "در انتظار" },
  { value: "in_progress", label: "در حال انجام" },
  { value: "completed", label: "تکمیل‌شده" },
  { value: "skipped", label: "رد شده" },
  { value: "blocked", label: "مسدود شده" },
] as const;

export function UpsertMilestoneForm({ shipmentId }: { shipmentId: string }) {
  const [state, action, pending] = useActionState<TrackingActionState | null, FormData>(
    buyerUpsertMilestone,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="shipmentId" value={shipmentId} />

          <Field htmlFor="milestoneType" label="نوع نقطه عطف">
            <select
              id="milestoneType"
              name="milestoneType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {MILESTONE_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="status" label="وضعیت">
            <select
              id="status"
              name="status"
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="">— خودکار —</option>
              {STATUSES.map((s) => (
                <option key={s.value} value={s.value}>{s.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="plannedAt" label="زمان برنامه‌ریزی‌شده">
            <Input id="plannedAt" name="plannedAt" type="datetime-local" dir="ltr" />
          </Field>

          <Field htmlFor="completedAt" label="زمان تکمیل">
            <Input id="completedAt" name="completedAt" type="datetime-local" dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-2">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">نقطه عطف ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره نقطه عطف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
