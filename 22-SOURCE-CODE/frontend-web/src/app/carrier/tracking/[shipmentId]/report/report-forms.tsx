"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  startTelemetrySession,
  endTelemetrySession,
  reportPosition,
  reportTelemetryEvent,
  CARRIER_EVENT_TYPES,
  type TelematicsActionState,
  type CarrierEventType,
} from "@/lib/telematics/carrier-actions";

interface Props {
  shipmentId: string;
  dispatchId: string;
  /** True when the latest session-scoped event is session_started. */
  sessionActive: boolean;
}

const EVENT_LABELS: Record<CarrierEventType, string> = {
  signal_lost: "قطع سیگنال",
  signal_restored: "بازگشت سیگنال",
  position_anomaly: "ناهنجاری موقعیت",
};

function FeedbackInline({ state }: { state: TelematicsActionState | null }) {
  if (!state) return null;
  if (state.error)
    return <span className="text-xs text-amber-600">{state.error}</span>;
  if (state.ok)
    return <span className="text-xs text-emerald-600">انجام شد.</span>;
  return null;
}

function SessionForms({
  shipmentId,
  dispatchId,
  sessionActive,
}: Props) {
  const [startState, startAction, startPending] = useActionState<
    TelematicsActionState | null,
    FormData
  >(startTelemetrySession, null);
  const [endState, endAction, endPending] = useActionState<
    TelematicsActionState | null,
    FormData
  >(endTelemetrySession, null);

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div>
          <div className="text-sm font-medium">شروع و پایان نشست تله‌متری</div>
          <p className="text-xs text-muted-foreground mt-1">
            وضعیت فعلی نشست:{" "}
            {sessionActive ? (
              <span className="text-emerald-700">فعال</span>
            ) : (
              <span>غیرفعال</span>
            )}
          </p>
        </div>

        {!sessionActive ? (
          <form action={startAction} className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
            <input type="hidden" name="dispatchId" value={dispatchId} />
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Field htmlFor="startNotes" label="یادداشت شروع (اختیاری)">
              <Input id="startNotes" name="notes" />
            </Field>
            <Button type="submit" disabled={startPending} className="w-full sm:w-auto">
              {startPending ? "..." : "شروع ردیابی"}
            </Button>
            <FeedbackInline state={startState} />
          </form>
        ) : (
          <form action={endAction} className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
            <input type="hidden" name="dispatchId" value={dispatchId} />
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Field htmlFor="endNotes" label="یادداشت پایان (اختیاری)">
              <Input id="endNotes" name="notes" />
            </Field>
            <Button type="submit" variant="outline" disabled={endPending} className="w-full sm:w-auto">
              {endPending ? "..." : "پایان ردیابی"}
            </Button>
            <FeedbackInline state={endState} />
          </form>
        )}
      </CardContent>
    </Card>
  );
}

function PositionReportForm({
  shipmentId,
  dispatchId,
}: {
  shipmentId: string;
  dispatchId: string;
}) {
  const [state, action, pending] = useActionState<
    TelematicsActionState | null,
    FormData
  >(reportPosition, null);

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div>
          <div className="text-sm font-medium">ورود دستی موقعیت</div>
          <p className="text-xs text-muted-foreground mt-1">
            برای زمانی که دسترسی به GPS دستگاه ممکن نیست — مختصات و فراداده‌ها را مستقیم وارد کنید.
          </p>
        </div>
        <form action={action} className="grid gap-3 sm:grid-cols-2">
          <input type="hidden" name="dispatchId" value={dispatchId} />
          <input type="hidden" name="shipmentId" value={shipmentId} />
          <Field htmlFor="latitude" label="عرض جغرافیایی">
            <Input
              id="latitude"
              name="latitude"
              dir="ltr"
              inputMode="decimal"
              required
            />
          </Field>
          <Field htmlFor="longitude" label="طول جغرافیایی">
            <Input
              id="longitude"
              name="longitude"
              dir="ltr"
              inputMode="decimal"
              required
            />
          </Field>
          <Field htmlFor="speedKmh" label="سرعت (km/h)">
            <Input id="speedKmh" name="speedKmh" dir="ltr" inputMode="decimal" />
          </Field>
          <Field htmlFor="headingDegrees" label="جهت (درجه)">
            <Input
              id="headingDegrees"
              name="headingDegrees"
              dir="ltr"
              inputMode="numeric"
            />
          </Field>
          <Field htmlFor="accuracyMeters" label="دقت (متر)">
            <Input
              id="accuracyMeters"
              name="accuracyMeters"
              dir="ltr"
              inputMode="decimal"
            />
          </Field>
          <Field htmlFor="altitudeMeters" label="ارتفاع (متر)">
            <Input
              id="altitudeMeters"
              name="altitudeMeters"
              dir="ltr"
              inputMode="decimal"
            />
          </Field>
          <Field htmlFor="reportedAt" label="زمان گزارش (در صورت خالی بودن، الان)">
            <Input
              id="reportedAt"
              name="reportedAt"
              type="datetime-local"
              dir="ltr"
            />
          </Field>
          <Field htmlFor="source" label="منبع گزارش (اختیاری)">
            <Input
              id="source"
              name="source"
              dir="ltr"
              defaultValue="carrier_app"
            />
          </Field>
          <div className="sm:col-span-2 flex flex-wrap items-center gap-3">
            <Button type="submit" disabled={pending} className="w-full sm:w-auto">
              {pending ? "..." : "ثبت موقعیت دستی"}
            </Button>
            <FeedbackInline state={state} />
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

function EventReportForm({
  shipmentId,
  dispatchId,
}: {
  shipmentId: string;
  dispatchId: string;
}) {
  const [state, action, pending] = useActionState<
    TelematicsActionState | null,
    FormData
  >(reportTelemetryEvent, null);

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div>
          <div className="text-sm font-medium">گزارش رویداد تله‌متری</div>
          <p className="text-xs text-muted-foreground mt-1">
            برای ثبت قطع/بازگشت سیگنال یا ناهنجاری موقعیت. شروع/پایان نشست از طریق دکمه‌های اختصاصی بالا ثبت می‌شود.
          </p>
        </div>
        <form action={action} className="grid gap-3 sm:grid-cols-2">
          <input type="hidden" name="dispatchId" value={dispatchId} />
          <input type="hidden" name="shipmentId" value={shipmentId} />
          <Field htmlFor="eventType" label="نوع رویداد">
            <select
              id="eventType"
              name="eventType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            >
              <option value="" disabled>
                انتخاب کنید
              </option>
              {CARRIER_EVENT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {EVENT_LABELS[t]}
                </option>
              ))}
            </select>
          </Field>
          <Field htmlFor="reason" label="توضیح (اختیاری)">
            <Input id="reason" name="reason" />
          </Field>
          <div className="sm:col-span-2 flex flex-wrap items-center gap-3">
            <Button type="submit" variant="outline" disabled={pending} className="w-full sm:w-auto">
              {pending ? "..." : "ثبت رویداد"}
            </Button>
            <FeedbackInline state={state} />
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

// Each surface is exported individually so the carrier reporting page can
// interleave the CC-49 live-capture panel between groups without bundling
// every form in one render order. ReportForms is kept as a convenience
// composite for any future caller that wants all four surfaces stacked.

export function SessionControls(props: Props) {
  return <SessionForms {...props} />;
}

export function ManualPositionForm(props: {
  shipmentId: string;
  dispatchId: string;
}) {
  return <PositionReportForm {...props} />;
}

export function EventReport(props: { shipmentId: string; dispatchId: string }) {
  return <EventReportForm {...props} />;
}

export function ReportForms(props: Props) {
  return (
    <div className="space-y-4">
      <SessionControls {...props} />
      <ManualPositionForm
        shipmentId={props.shipmentId}
        dispatchId={props.dispatchId}
      />
      <EventReport
        shipmentId={props.shipmentId}
        dispatchId={props.dispatchId}
      />
    </div>
  );
}
