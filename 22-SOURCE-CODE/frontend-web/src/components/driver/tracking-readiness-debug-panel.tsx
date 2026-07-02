"use client";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DRIVER_TRACKING_FLAGS } from "@/lib/driver/tracking/feature-flags";
import { useTrackingReadiness } from "@/lib/driver/tracking/use-tracking-readiness";
import { CAPABILITY_LABEL } from "@/lib/driver/tracking/capabilities";
import { GEO_PERMISSION_LABEL } from "@/lib/driver/tracking/permission-health";
import {
  TRACKING_STATE_LABEL,
  type TrackingState,
} from "@/lib/driver/tracking/state-machine";
import { hasActiveConsent } from "@/lib/driver/tracking/consent";

// Phase K (v1.3) — DEVELOPMENT-ONLY telemetry debug panel for the background
// tracking readiness architecture. Self-gates on the debugPanel flag (off in
// production builds). Displays capabilities / permission / consent / session
// health / state — and lets a developer toggle the local consent record. It
// starts NO tracking.

function levelVariant(level: string): "success" | "warning" | "danger" | "muted" {
  if (level === "ready") return "success";
  if (level === "blocked") return "warning";
  if (level === "unavailable") return "danger";
  return "muted";
}

export function TrackingReadinessDebugPanel() {
  const {
    capabilities,
    permission,
    consent,
    online,
    health,
    grantConsent,
    revokeConsent,
    refreshPermission,
  } = useTrackingReadiness();

  if (!DRIVER_TRACKING_FLAGS.debugPanel) return null;

  const state: TrackingState = health?.state ?? "idle";

  return (
    <div className="space-y-3 rounded-xl border border-dashed border-amber-400/60 bg-amber-50/40 p-4 dark:bg-amber-900/10">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="text-sm font-semibold">
          پایش آمادگی ردیابی (فقط توسعه)
        </span>
        <div className="flex items-center gap-2">
          <Badge variant="muted">وضعیت ماشین: {TRACKING_STATE_LABEL[state]}</Badge>
          {health ? (
            <Badge variant={levelVariant(health.level)}>
              {health.ready ? "آماده" : "غیرآماده"}
            </Badge>
          ) : null}
        </div>
      </div>

      <p className="text-[11px] leading-6 text-muted-foreground">
        این پنل فقط معماری آمادگی را نشان می‌دهد. هیچ ردیابی پس‌زمینه‌ای اجرا
        نمی‌شود.
      </p>

      {/* Feature flags. */}
      <div className="flex flex-wrap gap-2 text-[11px]">
        <Badge variant={DRIVER_TRACKING_FLAGS.backgroundTracking ? "success" : "muted"}>
          ردیابی پس‌زمینه: خاموش
        </Badge>
        <Badge variant="muted">سرویس‌ورکر: خاموش</Badge>
        <Badge variant="muted">Background Sync: خاموش</Badge>
      </div>

      {/* Session health reasons. */}
      {health && !health.ready ? (
        <ul className="list-disc space-y-1 pe-5 text-[11px] leading-6 text-amber-700 dark:text-amber-300">
          {health.reasons.map((r) => (
            <li key={r}>{r}</li>
          ))}
        </ul>
      ) : null}

      {/* Consent + permission. */}
      <div className="grid grid-cols-2 gap-2 text-[11px]">
        <div>
          رضایت راننده:{" "}
          <span className="font-medium">
            {hasActiveConsent(consent) ? "ثبت‌شده" : "ثبت‌نشده"}
          </span>
        </div>
        <div>
          مجوز موقعیت:{" "}
          <span className="font-medium">{GEO_PERMISSION_LABEL[permission]}</span>
        </div>
        <div>
          اتصال:{" "}
          <span className="font-medium">{online ? "برخط" : "برون‌خط"}</span>
        </div>
      </div>

      {/* Capabilities. */}
      {capabilities ? (
        <div className="flex flex-wrap gap-1.5 text-[11px]">
          {(Object.keys(capabilities) as (keyof typeof capabilities)[]).map((k) => (
            <Badge key={k} variant={capabilities[k] ? "success" : "muted"}>
              {CAPABILITY_LABEL[k]}: {capabilities[k] ? "✓" : "—"}
            </Badge>
          ))}
        </div>
      ) : null}

      {/* Dev controls (local only — persists consent intent, starts nothing). */}
      <div className="flex flex-wrap gap-2">
        <Button type="button" size="sm" onClick={grantConsent}>
          ثبت رضایت (محلی)
        </Button>
        <Button type="button" size="sm" variant="outline" onClick={revokeConsent}>
          لغو رضایت
        </Button>
        <Button
          type="button"
          size="sm"
          variant="outline"
          onClick={refreshPermission}
        >
          بازخوانی مجوز
        </Button>
      </div>
    </div>
  );
}
