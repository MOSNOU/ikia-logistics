"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { sendDriverPosition } from "@/lib/driver/trip-actions";

// Phase D4 — manual, one-shot GPS position send.
//
// The driver explicitly taps a button; a single fix is captured via
// getCurrentPosition and sent. There is NO watchPosition, NO background /
// periodic tracking, NO offline queue and NO service worker.

type Feedback = { ok: boolean; message: string };

function geoErrorMessage(err: GeolocationPositionError): string {
  switch (err.code) {
    case err.PERMISSION_DENIED:
      return "دسترسی به موقعیت مکانی توسط شما رد شد.";
    case err.POSITION_UNAVAILABLE:
      return "امکان دریافت موقعیت فعلی وجود ندارد.";
    case err.TIMEOUT:
      return "دریافت موقعیت بیش از حد طول کشید.";
    default:
      return "امکان دریافت موقعیت فعلی وجود ندارد.";
  }
}

export function DriverLocationPanel({ dispatchId }: { dispatchId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<Feedback | null>(null);

  const disabled = pending || busy;

  function handleClick() {
    setFeedback(null);
    setStatus(null);

    if (typeof navigator === "undefined" || !("geolocation" in navigator)) {
      setFeedback({
        ok: false,
        message: "مرورگر شما از موقعیت مکانی پشتیبانی نمی‌کند.",
      });
      return;
    }

    setBusy(true);
    setStatus("در حال دریافت موقعیت…");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const reportedAt = new Date(pos.timestamp).toISOString();
        setStatus("در حال ارسال موقعیت…");
        startTransition(async () => {
          const res = await sendDriverPosition(dispatchId, {
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude,
            accuracyMeters: pos.coords.accuracy,
            reportedAt,
          });
          setBusy(false);
          setStatus(null);
          setFeedback(res);
          if (res.ok) router.refresh();
        });
      },
      (err) => {
        setBusy(false);
        setStatus(null);
        setFeedback({ ok: false, message: geoErrorMessage(err) });
      },
      { enableHighAccuracy: true, timeout: 15_000, maximumAge: 0 },
    );
  }

  return (
    <div className="space-y-3">
      <p className="text-xs leading-6 text-muted-foreground">
        با اجازه شما، موقعیت فعلی فقط برای همین سفر ارسال می‌شود.
      </p>
      <Button
        type="button"
        onClick={handleClick}
        disabled={disabled}
        className="h-12 w-full text-base font-semibold"
      >
        {disabled ? (status ?? "در حال ارسال موقعیت…") : "ارسال موقعیت فعلی"}
      </Button>
      {feedback ? (
        <p
          role="status"
          className={cn(
            "text-center text-xs leading-6",
            feedback.ok
              ? "text-emerald-600 dark:text-emerald-400"
              : "text-destructive",
          )}
        >
          {feedback.message}
        </p>
      ) : null}
    </div>
  );
}
