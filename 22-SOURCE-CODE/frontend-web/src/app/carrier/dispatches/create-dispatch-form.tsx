"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  createDispatch,
  type DispatchActionState,
} from "@/lib/dispatch/dispatch-actions";

export function CreateDispatchForm() {
  const [state, action, pending] = useActionState<DispatchActionState | null, FormData>(
    createDispatch,
    null,
  );
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">ایجاد اعزام جدید</div>
        <p className="text-xs text-muted-foreground">
          شناسه رزرو تأییدشده (buyer_confirmed) را وارد کنید. فیلدهای خودرو و راننده اختیاری‌اند؛ تکمیل همه آن‌ها وضعیت را به‌طور خودکار به «تخصیص‌یافته» منتقل می‌کند.
        </p>
        <form action={action} className="grid gap-3 md:grid-cols-2">
          <Field htmlFor="bookingRequestId" label="شناسه رزرو" className="md:col-span-2">
            <Input id="bookingRequestId" name="bookingRequestId" dir="ltr" required />
          </Field>
          <Field htmlFor="vehicleReference" label="شماره خودرو">
            <Input id="vehicleReference" name="vehicleReference" />
          </Field>
          <Field htmlFor="vehicleType" label="نوع خودرو">
            <Input id="vehicleType" name="vehicleType" />
          </Field>
          <Field htmlFor="driverName" label="نام راننده">
            <Input id="driverName" name="driverName" />
          </Field>
          <Field htmlFor="driverPhone" label="تلفن راننده">
            <Input id="driverPhone" name="driverPhone" dir="ltr" />
          </Field>
          <Field htmlFor="plannedPickupAt" label="زمان برداشت">
            <Input
              id="plannedPickupAt"
              name="plannedPickupAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>
          <Field htmlFor="notesFa" label="یادداشت (فارسی)" className="md:col-span-2">
            <Input id="notesFa" name="notesFa" />
          </Field>
          {state?.error ? (
            <p className="md:col-span-2 text-xs text-amber-600">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">اعزام با موفقیت ثبت شد.</p>
          ) : null}
          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ثبت اعزام"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
