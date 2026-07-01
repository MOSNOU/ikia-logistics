"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Field } from "@/components/forms/field";
import {
  assignDriverAction,
  type AssignDriverState,
} from "@/lib/driver/assign-driver";
import type { AssignableDriver } from "@/lib/driver/list-assignable-drivers";

// Phase D (v1.1) — minimal carrier/admin driver-assignment panel. Persian RTL.
// Uses the useActionState + <form action> pattern of the existing dispatch
// action components. The server RPC remains the source of truth (lifecycle gate
// + pre-start guard); this only surfaces a friendly Persian error if it rejects.

interface Props {
  dispatchId: string;
  drivers: AssignableDriver[];
  currentDriverUserId: string | null;
  /** Trip execution status; once past 'assigned' the driver is locked. */
  executionStatus: string | null;
}

export function AssignDriverPanel({
  dispatchId,
  drivers,
  currentDriverUserId,
  executionStatus,
}: Props) {
  const [state, action, pending] = useActionState<AssignDriverState | null, FormData>(
    assignDriverAction,
    null,
  );

  const started = executionStatus != null && executionStatus !== "assigned";
  const currentName = currentDriverUserId
    ? (drivers.find((d) => d.driverUserId === currentDriverUserId)?.fullName ??
      currentDriverUserId)
    : null;

  return (
    <Card>
      <CardContent className="space-y-4 p-4">
        <div className="text-sm font-medium">اختصاص راننده</div>
        <p className="text-xs leading-6 text-muted-foreground">
          راننده فعال ناوگان را برای این اعزام انتخاب کنید. پس از شروع سفر، راننده
          قابل تغییر نیست.
        </p>

        <div className="text-xs text-muted-foreground">
          راننده فعلی:{" "}
          <span className="font-medium text-foreground">{currentName ?? "—"}</span>
        </div>

        {drivers.length === 0 ? (
          <p className="text-xs text-muted-foreground">
            راننده فعالی برای این ناوگان یافت نشد
          </p>
        ) : started ? (
          <p className="text-xs text-muted-foreground">
            این سفر آغاز شده است؛ تغییر راننده ممکن نیست.
          </p>
        ) : (
          <form action={action} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={dispatchId} />
            <Field htmlFor="driverUserId" label="راننده" className="min-w-[220px] flex-1">
              <select
                id="driverUserId"
                name="driverUserId"
                defaultValue={currentDriverUserId ?? ""}
                disabled={pending}
                className="h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
              >
                <option value="" disabled>
                  انتخاب راننده…
                </option>
                {drivers.map((d) => (
                  <option key={d.driverUserId} value={d.driverUserId}>
                    {d.fullName ?? d.driverUserId}
                  </option>
                ))}
              </select>
            </Field>
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "اختصاص راننده"}
            </Button>
            {state?.error ? (
              <span className="text-xs text-amber-600">{state.error}</span>
            ) : null}
            {state?.ok ? (
              <span className="text-xs text-emerald-600">راننده اختصاص یافت.</span>
            ) : null}
          </form>
        )}
      </CardContent>
    </Card>
  );
}
