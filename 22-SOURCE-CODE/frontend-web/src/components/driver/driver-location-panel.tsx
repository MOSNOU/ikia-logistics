"use client";

import { useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { sendDriverPosition } from "@/lib/driver/trip-actions";
import {
  LIVE_STATUS_LABEL,
  WEAK_RETRY_MS,
  deriveSpeedKmh,
  hasMoved,
  isAccurate,
  pickCadenceMs,
  retryDelayMs,
  type LiveStatus,
} from "@/lib/driver/location-session";

// Phase D4 — manual one-shot GPS send.
// Phase J (v1.3) — additive Smart Live Tracking: an explicit opt-in foreground
// session that sends periodic fixes with speed-aware cadence, an accuracy
// filter, near-duplicate dedupe, and in-memory retry/backoff. FOREGROUND ONLY —
// it runs while this tab is open; NO watchPosition-background, NO service
// worker, NO offline/IndexedDB persistence. Stops on Stop or unmount.

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

const GEO_OPTS: PositionOptions = {
  enableHighAccuracy: true,
  timeout: 15_000,
  maximumAge: 0,
};

export function DriverLocationPanel({ dispatchId }: { dispatchId: string }) {
  const router = useRouter();

  // --- One-shot (D4) -------------------------------------------------------
  const [pending, startTransition] = useTransition();
  const [busy, setBusy] = useState(false);
  const [oneShotStatus, setOneShotStatus] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<Feedback | null>(null);
  const oneShotDisabled = pending || busy;

  function handleOneShot() {
    setFeedback(null);
    setOneShotStatus(null);
    if (typeof navigator === "undefined" || !("geolocation" in navigator)) {
      setFeedback({ ok: false, message: "مرورگر شما از موقعیت مکانی پشتیبانی نمی‌کند." });
      return;
    }
    setBusy(true);
    setOneShotStatus("در حال دریافت موقعیت…");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setOneShotStatus("در حال ارسال موقعیت…");
        startTransition(async () => {
          const res = await sendDriverPosition(dispatchId, {
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude,
            accuracyMeters: pos.coords.accuracy,
            reportedAt: new Date(pos.timestamp).toISOString(),
          });
          setBusy(false);
          setOneShotStatus(null);
          setFeedback(res);
          if (res.ok) router.refresh();
        });
      },
      (err) => {
        setBusy(false);
        setOneShotStatus(null);
        setFeedback({ ok: false, message: geoErrorMessage(err) });
      },
      GEO_OPTS,
    );
  }

  // --- Smart live session (Phase J) ---------------------------------------
  const [live, setLive] = useState(false);
  const [status, setStatus] = useState<LiveStatus>("stopped");
  const [liveError, setLiveError] = useState<string | null>(null);
  const [lastSentAt, setLastSentAt] = useState<string | null>(null);

  const runningRef = useRef(false);
  const timerRef = useRef<number | null>(null);
  const lastSentRef = useRef<{ lat: number; lon: number; t: number } | null>(null);
  const lastFixRef = useRef<{ lat: number; lon: number; t: number } | null>(null);
  const retryRef = useRef(0);

  function clearTimer() {
    if (timerRef.current != null) {
      window.clearTimeout(timerRef.current);
      timerRef.current = null;
    }
  }

  function schedule(ms: number) {
    clearTimer();
    timerRef.current = window.setTimeout(tick, ms);
  }

  function stopSession(message?: string) {
    runningRef.current = false;
    clearTimer();
    setLive(false);
    setStatus("stopped");
    if (message) setLiveError(message);
  }

  async function sendFix(pos: GeolocationPosition) {
    if (!runningRef.current) return;
    const lat = pos.coords.latitude;
    const lon = pos.coords.longitude;
    const acc = pos.coords.accuracy ?? null;
    const t = pos.timestamp;

    // Accuracy filter — do not send a poor fix; retry sooner.
    if (!isAccurate(acc)) {
      setStatus("weak");
      schedule(WEAK_RETRY_MS);
      return;
    }

    // Speed: prefer the device value, else derive from the previous fix.
    const reported = pos.coords.speed;
    const speedKmh =
      reported != null && Number.isFinite(reported)
        ? reported * 3.6
        : lastFixRef.current
          ? deriveSpeedKmh(lastFixRef.current, { lat, lon, t })
          : null;
    lastFixRef.current = { lat, lon, t };

    // Dedupe vs the last SENT fix — no new info → idle at "stopped" cadence.
    const moved = hasMoved(
      lastSentRef.current ? { lat: lastSentRef.current.lat, lon: lastSentRef.current.lon } : null,
      { lat, lon },
    );
    if (!moved) {
      setStatus("sending");
      schedule(pickCadenceMs(speedKmh, false));
      return;
    }

    const res = await sendDriverPosition(dispatchId, {
      latitude: lat,
      longitude: lon,
      accuracyMeters: acc,
      reportedAt: new Date(t).toISOString(),
    });
    if (!runningRef.current) return;

    if (res.ok) {
      lastSentRef.current = { lat, lon, t };
      retryRef.current = 0;
      setStatus("sending");
      setLastSentAt(new Date(t).toISOString());
      schedule(pickCadenceMs(speedKmh, true));
    } else {
      retryRef.current += 1;
      setStatus("retrying");
      schedule(retryDelayMs(retryRef.current));
    }
  }

  function tick() {
    if (!runningRef.current) return;
    if (typeof navigator === "undefined" || !("geolocation" in navigator)) {
      stopSession("مرورگر شما از موقعیت مکانی پشتیبانی نمی‌کند.");
      return;
    }
    setStatus("waiting");
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        void sendFix(pos);
      },
      (err) => {
        if (!runningRef.current) return;
        if (err.code === err.PERMISSION_DENIED) {
          stopSession(geoErrorMessage(err));
          return;
        }
        retryRef.current += 1;
        setStatus("retrying");
        schedule(retryDelayMs(retryRef.current));
      },
      GEO_OPTS,
    );
  }

  function startSession() {
    setLiveError(null);
    if (typeof navigator === "undefined" || !("geolocation" in navigator)) {
      setLiveError("مرورگر شما از موقعیت مکانی پشتیبانی نمی‌کند.");
      return;
    }
    runningRef.current = true;
    retryRef.current = 0;
    lastSentRef.current = null;
    lastFixRef.current = null;
    setLive(true);
    tick(); // capture the first fix immediately
  }

  // Stop the session if the component unmounts (navigation away). Inline the
  // timer clear so the effect has no external deps.
  useEffect(() => {
    return () => {
      runningRef.current = false;
      if (timerRef.current != null) window.clearTimeout(timerRef.current);
    };
  }, []);

  const statusTone =
    status === "sending"
      ? "text-emerald-600 dark:text-emerald-400"
      : status === "stopped"
        ? "text-muted-foreground"
        : "text-amber-600";

  return (
    <div className="space-y-4">
      {/* One-shot manual send. */}
      <div className="space-y-3">
        <p className="text-xs leading-6 text-muted-foreground">
          با اجازه شما، موقعیت فعلی فقط برای همین سفر ارسال می‌شود.
        </p>
        <Button
          type="button"
          onClick={handleOneShot}
          disabled={oneShotDisabled}
          className="h-12 w-full text-base font-semibold"
        >
          {oneShotDisabled ? (oneShotStatus ?? "در حال ارسال موقعیت…") : "ارسال موقعیت فعلی"}
        </Button>
        {feedback ? (
          <p
            role="status"
            className={cn(
              "text-center text-xs leading-6",
              feedback.ok ? "text-emerald-600 dark:text-emerald-400" : "text-destructive",
            )}
          >
            {feedback.message}
          </p>
        ) : null}
      </div>

      {/* Smart live tracking (opt-in, foreground only). */}
      <div className="space-y-3 border-t border-border-soft pt-4">
        <div className="flex items-center justify-between gap-2">
          <span className="text-sm font-medium">ارسال زنده موقعیت</span>
          <span role="status" className={cn("text-xs font-medium", statusTone)}>
            {LIVE_STATUS_LABEL[status]}
          </span>
        </div>
        <p className="text-[11px] leading-6 text-muted-foreground">
          فقط تا زمانی که این صفحه باز است و شما شروع کنید، موقعیت به‌صورت دوره‌ای
          ارسال می‌شود. در پس‌زمینه اجرا نمی‌شود.
        </p>
        {live ? (
          <Button
            type="button"
            variant="outline"
            onClick={() => stopSession()}
            className="h-12 w-full text-base font-semibold"
          >
            توقف ارسال زنده
          </Button>
        ) : (
          <Button
            type="button"
            onClick={startSession}
            className="h-12 w-full text-base font-semibold"
          >
            شروع ارسال زنده
          </Button>
        )}
        {lastSentAt ? (
          <p className="text-center text-[11px] leading-6 text-muted-foreground">
            آخرین ارسال موفق:{" "}
            {new Date(lastSentAt).toLocaleTimeString("fa-IR", {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        ) : null}
        {liveError ? (
          <p role="status" className="text-center text-xs leading-6 text-destructive">
            {liveError}
          </p>
        ) : null}
      </div>
    </div>
  );
}
