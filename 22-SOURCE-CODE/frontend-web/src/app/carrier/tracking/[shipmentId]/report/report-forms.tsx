"use client";

import { useActionState, useState } from "react";
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
        <div className="text-sm font-medium">مدیریت نشست تله‌متری</div>

        {!sessionActive ? (
          <form action={startAction} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={dispatchId} />
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Field htmlFor="startNotes" label="یادداشت شروع (اختیاری)">
              <Input id="startNotes" name="notes" />
            </Field>
            <Button type="submit" disabled={startPending}>
              {startPending ? "..." : "شروع ردیابی"}
            </Button>
            <FeedbackInline state={startState} />
          </form>
        ) : (
          <p className="text-xs text-muted-foreground">
            نشست تله‌متری در حال حاضر فعال است. برای شروع نشست جدید، ابتدا نشست فعلی را پایان دهید.
          </p>
        )}

        {sessionActive ? (
          <form action={endAction} className="flex flex-wrap items-end gap-3">
            <input type="hidden" name="dispatchId" value={dispatchId} />
            <input type="hidden" name="shipmentId" value={shipmentId} />
            <Field htmlFor="endNotes" label="یادداشت پایان (اختیاری)">
              <Input id="endNotes" name="notes" />
            </Field>
            <Button type="submit" variant="outline" disabled={endPending}>
              {endPending ? "..." : "پایان ردیابی"}
            </Button>
            <FeedbackInline state={endState} />
          </form>
        ) : null}
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
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [geoStatus, setGeoStatus] = useState<string | null>(null);
  const [geoBusy, setGeoBusy] = useState(false);

  function fillFromBrowser() {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setGeoStatus("مرورگر از تعیین موقعیت پشتیبانی نمی‌کند.");
      return;
    }
    setGeoBusy(true);
    setGeoStatus(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLatitude(String(pos.coords.latitude));
        setLongitude(String(pos.coords.longitude));
        setGeoStatus(
          `موقعیت دستگاه با دقت ${Math.round(pos.coords.accuracy)} متر بارگذاری شد.`,
        );
        setGeoBusy(false);
      },
      (err) => {
        setGeoStatus(`خطا در تعیین موقعیت: ${err.message}`);
        setGeoBusy(false);
      },
      { enableHighAccuracy: false, timeout: 8_000, maximumAge: 30_000 },
    );
  }

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div className="text-sm font-medium">ثبت موقعیت دستی</div>
        <form action={action} className="grid gap-3 md:grid-cols-2">
          <input type="hidden" name="dispatchId" value={dispatchId} />
          <input type="hidden" name="shipmentId" value={shipmentId} />
          <Field htmlFor="latitude" label="عرض جغرافیایی">
            <Input
              id="latitude"
              name="latitude"
              dir="ltr"
              inputMode="decimal"
              value={latitude}
              onChange={(e) => setLatitude(e.target.value)}
              required
            />
          </Field>
          <Field htmlFor="longitude" label="طول جغرافیایی">
            <Input
              id="longitude"
              name="longitude"
              dir="ltr"
              inputMode="decimal"
              value={longitude}
              onChange={(e) => setLongitude(e.target.value)}
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
          <div className="md:col-span-2 flex flex-wrap items-center gap-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ثبت موقعیت فعلی"}
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={fillFromBrowser}
              disabled={geoBusy}
            >
              {geoBusy ? "..." : "استفاده از موقعیت مرورگر"}
            </Button>
            <FeedbackInline state={state} />
            {geoStatus ? (
              <span className="text-xs text-muted-foreground">{geoStatus}</span>
            ) : null}
          </div>
        </form>
        <p className="text-xs text-muted-foreground">
          دکمه «استفاده از موقعیت مرورگر» تنها با کلیک شما اجرا می‌شود و هیچ ردیابی پس‌زمینه‌ای انجام نمی‌شود.
        </p>
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
        <div className="text-sm font-medium">ثبت رویداد تله‌متری</div>
        <form action={action} className="grid gap-3 md:grid-cols-2">
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
          <div className="md:col-span-2 flex flex-wrap items-center gap-3">
            <Button type="submit" variant="outline" disabled={pending}>
              {pending ? "..." : "ثبت رویداد"}
            </Button>
            <FeedbackInline state={state} />
          </div>
        </form>
        <p className="text-xs text-muted-foreground">
          رویدادهای شروع/پایان نشست فقط از طریق دکمه‌های اختصاصی بالا ثبت می‌شوند و در این فهرست در دسترس نیستند.
        </p>
      </CardContent>
    </Card>
  );
}

export function ReportForms(props: Props) {
  return (
    <div className="space-y-4">
      <SessionForms {...props} />
      <PositionReportForm
        shipmentId={props.shipmentId}
        dispatchId={props.dispatchId}
      />
      <EventReportForm
        shipmentId={props.shipmentId}
        dispatchId={props.dispatchId}
      />
    </div>
  );
}
