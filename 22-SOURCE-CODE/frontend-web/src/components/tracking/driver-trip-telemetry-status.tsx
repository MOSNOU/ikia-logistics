import { Badge } from "@/components/ui/badge";
import type { TelematicsStalenessStatus } from "@/types/database";

// CC-55 — Compact Persian/RTL telemetry health chip cluster for the driver
// trips list. Pure presentational: zero state, no fetches, no actions, no
// "use client". Reusable by future carrier/admin surfaces that show
// per-dispatch telemetry summaries.
//
// All fields are optional. When the CC-53 batch RPC fails for the parent
// loader, every field arrives undefined and the component renders the
// single «نامشخص» badge — never an empty space, never an error.

interface Props {
  sessionActive?: boolean;
  stalenessStatus?: TelematicsStalenessStatus;
  lastPositionAt?: string | null;
  lastEventType?: string | null;
  positionCount?: number;
  eventCount?: number;
}

interface StalenessVisual {
  text: string;
  variant: "success" | "warning" | "muted";
}

const STALENESS_VISUAL: Record<TelematicsStalenessStatus, StalenessVisual> = {
  fresh: { text: "به‌روز", variant: "success" },
  stale: { text: "قدیمی", variant: "warning" },
  missing: { text: "بدون موقعیت", variant: "muted" },
};

export function DriverTripTelemetryStatus({
  sessionActive,
  stalenessStatus,
  lastPositionAt,
  lastEventType,
  positionCount,
  eventCount,
}: Props) {
  const hasAny =
    sessionActive !== undefined ||
    stalenessStatus !== undefined ||
    lastPositionAt != null ||
    lastEventType != null ||
    positionCount !== undefined ||
    eventCount !== undefined;

  if (!hasAny) {
    return (
      <div className="flex flex-wrap items-center gap-2">
        <Badge variant="muted">تله‌متری: نامشخص</Badge>
      </div>
    );
  }

  const staleness = stalenessStatus
    ? STALENESS_VISUAL[stalenessStatus]
    : null;

  return (
    <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-[11px] leading-6 text-muted-foreground">
      {sessionActive !== undefined ? (
        sessionActive ? (
          <Badge variant="info">نشست فعال</Badge>
        ) : (
          <Badge variant="muted">نشست غیرفعال</Badge>
        )
      ) : null}
      {staleness ? (
        <Badge variant={staleness.variant}>{staleness.text}</Badge>
      ) : null}
      {lastPositionAt ? (
        <span>
          آخرین موقعیت:{" "}
          <span dir="ltr" className="font-mono text-foreground">
            {lastPositionAt}
          </span>
        </span>
      ) : null}
      {lastEventType ? (
        <span>
          آخرین رویداد:{" "}
          <span className="font-mono text-foreground">{lastEventType}</span>
        </span>
      ) : null}
      {positionCount !== undefined && eventCount !== undefined ? (
        <span>
          {positionCount.toLocaleString("fa-IR")} نقطه ·{" "}
          {eventCount.toLocaleString("fa-IR")} رویداد
        </span>
      ) : null}
    </div>
  );
}
