"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  cancelDispatchAsAdmin,
  cancelDispatchAsBuyer,
  cancelDispatchAsCarrier,
  markDispatchReady,
  releaseDispatch,
  updateDispatchPlaceholders,
  type DispatchActionState,
} from "@/lib/dispatch/dispatch-actions";
import type { DispatchDetail, DispatchStatus } from "@/types/database";

interface Props {
  detail: DispatchDetail;
  audience: "buyer" | "carrier" | "admin";
}

const TERMINAL: DispatchStatus[] = ["released", "cancelled"];

function CarrierActions({ detail }: { detail: DispatchDetail }) {
  const d = detail.dispatch;
  const [updateState, updateAction, updatePending] = useActionState<
    DispatchActionState | null,
    FormData
  >(updateDispatchPlaceholders, null);
  const [readyState, readyAction, readyPending] = useActionState<
    DispatchActionState | null,
    FormData
  >(markDispatchReady, null);
  const [releaseState, releaseAction, releasePending] = useActionState<
    DispatchActionState | null,
    FormData
  >(releaseDispatch, null);
  const [cancelState, cancelAction, cancelPending] = useActionState<
    DispatchActionState | null,
    FormData
  >(cancelDispatchAsCarrier, null);

  const canUpdate = d.status === "draft" || d.status === "assigned";
  const canMarkReady = d.status === "assigned";
  const canRelease = d.status === "ready";
  const canCancel = !TERMINAL.includes(d.status);

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات حمل‌کننده</div>

        {canUpdate ? (
          <form action={updateAction} className="grid gap-3 md:grid-cols-2">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Field htmlFor="vehicleReference" label="شماره خودرو">
              <Input
                id="vehicleReference"
                name="vehicleReference"
                defaultValue={d.vehicle_reference ?? ""}
              />
            </Field>
            <Field htmlFor="vehicleType" label="نوع خودرو">
              <Input
                id="vehicleType"
                name="vehicleType"
                defaultValue={d.vehicle_type ?? ""}
              />
            </Field>
            <Field htmlFor="driverName" label="نام راننده">
              <Input
                id="driverName"
                name="driverName"
                defaultValue={d.driver_name ?? ""}
              />
            </Field>
            <Field htmlFor="driverPhone" label="تلفن راننده">
              <Input
                id="driverPhone"
                name="driverPhone"
                dir="ltr"
                defaultValue={d.driver_phone ?? ""}
              />
            </Field>
            <Field htmlFor="plannedPickupAt" label="زمان برداشت">
              <Input
                id="plannedPickupAt"
                name="plannedPickupAt"
                type="datetime-local"
                dir="ltr"
              />
            </Field>
            <div className="md:col-span-2 flex items-center gap-3">
              <Button type="submit" variant="outline" disabled={updatePending}>
                {updatePending ? "..." : "ذخیره مشخصات"}
              </Button>
              {updateState?.error ? (
                <span className="text-xs text-amber-600">{updateState.error}</span>
              ) : null}
              {updateState?.ok ? (
                <span className="text-xs text-emerald-600">ذخیره شد.</span>
              ) : null}
            </div>
          </form>
        ) : null}

        {canMarkReady ? (
          <form action={readyAction} className="flex items-end gap-3">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Button type="submit" disabled={readyPending}>
              {readyPending ? "..." : "اعلام آمادگی"}
            </Button>
            {readyState?.error ? (
              <span className="text-xs text-amber-600">{readyState.error}</span>
            ) : null}
            {readyState?.ok ? (
              <span className="text-xs text-emerald-600">اعلام شد.</span>
            ) : null}
          </form>
        ) : null}

        {canRelease ? (
          <form action={releaseAction} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Field htmlFor="notes" label="یادداشت آزادسازی (اختیاری)">
              <Input id="notes" name="notes" />
            </Field>
            <Button type="submit" disabled={releasePending}>
              {releasePending ? "..." : "آزادسازی"}
            </Button>
            {releaseState?.error ? (
              <span className="text-xs text-amber-600">{releaseState.error}</span>
            ) : null}
            {releaseState?.ok ? (
              <span className="text-xs text-emerald-600">آزاد شد.</span>
            ) : null}
          </form>
        ) : null}

        {canCancel ? (
          <form action={cancelAction} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Field htmlFor="reason" label="دلیل لغو (اختیاری)">
              <Input id="reason" name="reason" />
            </Field>
            <Button type="submit" variant="outline" disabled={cancelPending}>
              {cancelPending ? "..." : "لغو اعزام"}
            </Button>
            {cancelState?.error ? (
              <span className="text-xs text-amber-600">{cancelState.error}</span>
            ) : null}
            {cancelState?.ok ? (
              <span className="text-xs text-emerald-600">لغو شد.</span>
            ) : null}
          </form>
        ) : null}

        {!canUpdate && !canMarkReady && !canRelease && !canCancel ? (
          <p className="text-xs text-muted-foreground">
            اعزام در وضعیت پایانی است؛ اقدام دیگری ممکن نیست.
          </p>
        ) : null}
      </CardContent>
    </Card>
  );
}

function BuyerActions({ detail }: { detail: DispatchDetail }) {
  const d = detail.dispatch;
  const [state, action, pending] = useActionState<DispatchActionState | null, FormData>(
    cancelDispatchAsBuyer,
    null,
  );
  const canCancel = !TERMINAL.includes(d.status);
  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات خریدار</div>
        {!canCancel ? (
          <p className="text-xs text-muted-foreground">
            اعزام در وضعیت پایانی است؛ اقدامی برای خریدار قابل اجرا نیست.
          </p>
        ) : (
          <form action={action} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Field htmlFor="reason" label="دلیل لغو (اختیاری)">
              <Input id="reason" name="reason" />
            </Field>
            <Button type="submit" variant="outline" disabled={pending}>
              {pending ? "..." : "لغو اعزام"}
            </Button>
            {state?.error ? (
              <span className="text-xs text-amber-600">{state.error}</span>
            ) : null}
            {state?.ok ? (
              <span className="text-xs text-emerald-600">لغو شد.</span>
            ) : null}
          </form>
        )}
      </CardContent>
    </Card>
  );
}

function AdminActions({ detail }: { detail: DispatchDetail }) {
  const d = detail.dispatch;
  const [state, action, pending] = useActionState<DispatchActionState | null, FormData>(
    cancelDispatchAsAdmin,
    null,
  );
  const canCancel = !TERMINAL.includes(d.status);
  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">اقدامات ادمین (فقط لغو)</div>
        {!canCancel ? (
          <p className="text-xs text-muted-foreground">
            اعزام در وضعیت پایانی است؛ امکان لغو ادمین وجود ندارد.
          </p>
        ) : (
          <form action={action} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={d.id} />
            <Field htmlFor="reason" label="دلیل لغو ادمین">
              <Input id="reason" name="reason" required />
            </Field>
            <Button type="submit" variant="outline" disabled={pending}>
              {pending ? "..." : "لغو با تصمیم ادمین"}
            </Button>
            {state?.error ? (
              <span className="text-xs text-amber-600">{state.error}</span>
            ) : null}
            {state?.ok ? (
              <span className="text-xs text-emerald-600">لغو شد.</span>
            ) : null}
          </form>
        )}
      </CardContent>
    </Card>
  );
}

export function DispatchActionButtons({ detail, audience }: Props) {
  if (audience === "carrier") return <CarrierActions detail={detail} />;
  if (audience === "buyer") return <BuyerActions detail={detail} />;
  return <AdminActions detail={detail} />;
}
