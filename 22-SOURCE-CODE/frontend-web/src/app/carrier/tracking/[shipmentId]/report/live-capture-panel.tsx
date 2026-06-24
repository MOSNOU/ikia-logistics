"use client";

import { useActionState, useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  reportPosition,
  type TelematicsActionState,
} from "@/lib/telematics/carrier-actions";

interface Props {
  shipmentId: string;
  dispatchId: string;
}

interface CapturedFix {
  latitude: number;
  longitude: number;
  accuracy: number;
  reportedAt: string;
  capturedAtClock: number;
}

type CaptureStatus = "idle" | "requesting" | "captured" | "geolocation-error";

function persianGeoError(err: GeolocationPositionError): string {
  switch (err.code) {
    case err.PERMISSION_DENIED:
      return "اجازه دسترسی به موقعیت دستگاه داده نشد. لطفاً از تنظیمات مرورگر/سیستم اجازه را فعال کنید.";
    case err.POSITION_UNAVAILABLE:
      return "موقعیت دستگاه در حال حاضر در دسترس نیست. کمی صبر کنید و مجدداً تلاش نمایید.";
    case err.TIMEOUT:
      return "زمان دریافت موقعیت به پایان رسید. لطفاً مجدداً تلاش کنید.";
    default:
      return err.message || "خطای نامشخص در دریافت موقعیت.";
  }
}

export function LiveCapturePanel({ shipmentId, dispatchId }: Props) {
  const [status, setStatus] = useState<CaptureStatus>("idle");
  const [fix, setFix] = useState<CapturedFix | null>(null);
  const [geoError, setGeoError] = useState<string | null>(null);
  const [state, action, pending] = useActionState<
    TelematicsActionState | null,
    FormData
  >(reportPosition, null);

  // Clear the captured fix on successful submission so the next live report
  // requires a fresh explicit capture click. We intentionally do NOT persist
  // the fix to localStorage / sessionStorage anywhere in this component.
  useEffect(() => {
    if (state?.ok) {
      setFix(null);
      setStatus("idle");
    }
  }, [state?.ok, state?.ts]);

  // Explicit driver action — clears the captured fix (and resets the panel
  // back to idle) when the driver decides to abandon a failed submission.
  // We do NOT clear on submit failure; CC-52 keeps the fix in component
  // state until success or this explicit discard.
  function discard() {
    setFix(null);
    setStatus("idle");
  }

  function capture() {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setStatus("geolocation-error");
      setGeoError("این مرورگر از تعیین موقعیت دستگاه پشتیبانی نمی‌کند.");
      return;
    }
    setStatus("requesting");
    setGeoError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setFix({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
          accuracy: pos.coords.accuracy,
          reportedAt: new Date(pos.timestamp).toISOString(),
          capturedAtClock: Date.now(),
        });
        setStatus("captured");
      },
      (err) => {
        setStatus("geolocation-error");
        setGeoError(persianGeoError(err));
      },
      { enableHighAccuracy: true, timeout: 10_000, maximumAge: 0 },
    );
  }

  return (
    <Card>
      <CardContent className="p-4 space-y-4">
        <div>
          <div className="text-sm font-medium">ارسال سریع موقعیت زنده</div>
          <p className="text-xs text-muted-foreground mt-1">
            با کلیک شما موقعیت فعلی دستگاه دریافت می‌شود؛ قبل از ارسال می‌توانید آن را بازبینی کنید.
          </p>
        </div>

        {status === "idle" || status === "requesting" ? (
          <Button
            type="button"
            className="w-full sm:w-auto"
            onClick={capture}
            disabled={status === "requesting"}
          >
            {status === "requesting" ? "در حال دریافت..." : "گرفتن موقعیت دستگاه"}
          </Button>
        ) : null}

        {status === "geolocation-error" ? (
          <div className="space-y-3">
            <p className="text-xs text-amber-700">{geoError}</p>
            <Button
              type="button"
              variant="outline"
              className="w-full sm:w-auto"
              onClick={capture}
            >
              تلاش مجدد
            </Button>
          </div>
        ) : null}

        {status === "captured" && fix ? (
          <div className="space-y-3">
            <div
              className="rounded-md border bg-muted/30 p-3 text-xs leading-6"
              role="status"
              aria-live="polite"
            >
              <div dir="ltr" className="font-mono">
                {fix.latitude.toFixed(6)}, {fix.longitude.toFixed(6)}
              </div>
              <div>دقت تخمینی: {Math.round(fix.accuracy).toLocaleString("fa-IR")} متر</div>
              <div>زمان نمونه‌برداری: {fix.reportedAt}</div>
              <div className="text-muted-foreground">
                لحظه دریافت در دستگاه:{" "}
                {new Date(fix.capturedAtClock).toLocaleTimeString("fa-IR")}
              </div>
            </div>

            {state?.error ? (
              <div
                role="alert"
                className="rounded-md border border-amber-300 bg-amber-50 p-3 text-xs leading-6 text-amber-900"
              >
                <div className="font-medium">ارسال موقعیت ناموفق بود</div>
                <div>{state.error}</div>
                <div className="mt-1 text-amber-700">
                  داده تا زمانی که این صفحه باز است نگه داشته می‌شود؛ می‌توانید تلاش دوباره
                  کنید یا داده را حذف کنید. هیچ تلاش خودکاری انجام نخواهد شد.
                </div>
              </div>
            ) : null}

            <form action={action} className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <input type="hidden" name="dispatchId" value={dispatchId} />
              <input type="hidden" name="shipmentId" value={shipmentId} />
              <input type="hidden" name="latitude" value={fix.latitude} />
              <input type="hidden" name="longitude" value={fix.longitude} />
              <input
                type="hidden"
                name="accuracyMeters"
                value={Math.round(fix.accuracy)}
              />
              <input type="hidden" name="reportedAt" value={fix.reportedAt} />
              <input type="hidden" name="source" value="carrier_app_live" />
              <Button type="submit" disabled={pending} className="w-full sm:w-auto">
                {pending
                  ? "..."
                  : state?.error
                    ? "تلاش دوباره برای ارسال"
                    : "ارسال این موقعیت"}
              </Button>
              {state?.error ? (
                <Button
                  type="button"
                  variant="outline"
                  onClick={discard}
                  disabled={pending}
                  className="w-full sm:w-auto"
                >
                  حذف این موقعیت
                </Button>
              ) : (
                <Button
                  type="button"
                  variant="outline"
                  onClick={capture}
                  disabled={pending}
                  className="w-full sm:w-auto"
                >
                  دریافت مجدد
                </Button>
              )}
            </form>
          </div>
        ) : null}

        {state?.ok && status === "idle" ? (
          <p className="text-xs text-emerald-700" role="status">
            موقعیت با موفقیت ارسال شد. برای ارسال نمونه بعدی، دکمه «گرفتن موقعیت دستگاه» را بزنید.
          </p>
        ) : null}

        <p className="text-[11px] text-muted-foreground">
          هیچ موقعیتی به‌صورت خودکار، در پس‌زمینه یا به‌طور دوره‌ای ارسال نمی‌شود.
          داده دریافت‌شده تنها در حافظه همین برگه نگهداری می‌شود و در حافظه دستگاه ذخیره نمی‌گردد.
        </p>
      </CardContent>
    </Card>
  );
}
