import type {
  DispatchDetail,
  DispatchStatus,
  TelematicsEvent,
  TelematicsPosition,
  TelematicsSnapshot,
} from "@/types/database";

// CC-51 — Pure server-side composer that normalizes the data already loaded
// by the CC-50 driver trip detail page into a single chronological timeline.
// No new RPC calls. No new fetches. Inputs are the existing CC-43 dispatch
// detail and CC-45/CC-46 telematics snapshot + position list — pass them
// straight through.

export type DriverTripTimelineItemType =
  | "session_started"
  | "session_ended"
  | "position_reported"
  | "signal_lost"
  | "signal_restored"
  | "position_anomaly"
  | "dispatch_status"
  | "unknown_telemetry_event";

export interface DriverTripTimelineItem {
  key: string;
  type: DriverTripTimelineItemType;
  titleFa: string;
  descriptionFa?: string;
  timestamp: string;
  meta?: {
    latitude?: number | null;
    longitude?: number | null;
    accuracyMeters?: number | null;
    speedKmh?: number | null;
    headingDegrees?: number | null;
    source?: string | null;
    eventReason?: string | null;
    dispatchStatusFrom?: DispatchStatus | null;
    dispatchStatusTo?: DispatchStatus | null;
    actorParty?: string | null;
  };
}

const TELEMETRY_TITLES: Record<DriverTripTimelineItemType, string> = {
  session_started: "شروع نشست تله‌متری",
  session_ended: "پایان نشست تله‌متری",
  position_reported: "ثبت موقعیت",
  signal_lost: "قطع سیگنال",
  signal_restored: "بازگشت سیگنال",
  position_anomaly: "ناهنجاری موقعیت",
  dispatch_status: "تغییر وضعیت اعزام",
  unknown_telemetry_event: "رویداد تله‌متری",
};

const DISPATCH_STATUS_FA: Record<DispatchStatus, string> = {
  draft: "پیش‌نویس",
  assigned: "تخصیص‌یافته",
  ready: "آماده برداشت",
  released: "آزاد شده",
  cancelled: "لغوشده",
};

export const TELEMETRY_SOURCE_FA: Record<string, string> = {
  carrier_app: "اپلیکیشن حمل‌کننده",
  carrier_app_live: "اپلیکیشن حمل‌کننده (موقعیت زنده)",
  manual: "ورود دستی",
  gps_device: "دستگاه GPS",
  unknown: "نامشخص",
};

export function persianSourceLabel(source: string | null | undefined): string {
  if (!source) return "نامشخص";
  return TELEMETRY_SOURCE_FA[source] ?? source;
}

function mapTelemetryEventType(t: string): DriverTripTimelineItemType {
  switch (t) {
    case "session_started":
    case "session_ended":
    case "signal_lost":
    case "signal_restored":
    case "position_anomaly":
      return t;
    default:
      return "unknown_telemetry_event";
  }
}

function fromEvent(e: TelematicsEvent): DriverTripTimelineItem {
  const type = mapTelemetryEventType(e.event_type);
  return {
    key: `event:${e.id}`,
    type,
    titleFa: TELEMETRY_TITLES[type],
    descriptionFa:
      type === "unknown_telemetry_event"
        ? `نوع رویداد: ${e.event_type}`
        : undefined,
    timestamp: e.created_at,
    meta: {
      eventReason: e.reason ?? null,
      actorParty: e.actor_party ?? null,
    },
  };
}

function fromPosition(p: TelematicsPosition): DriverTripTimelineItem {
  const lat =
    typeof p.latitude === "number" ? p.latitude : Number(p.latitude);
  const lng =
    typeof p.longitude === "number" ? p.longitude : Number(p.longitude);
  const parts: string[] = [];
  if (Number.isFinite(lat) && Number.isFinite(lng)) {
    parts.push(`${lat.toFixed(5)}، ${lng.toFixed(5)}`);
  }
  if (p.speed_kmh != null) parts.push(`سرعت ${p.speed_kmh} km/h`);
  if (p.heading_degrees != null) parts.push(`جهت ${p.heading_degrees}°`);
  return {
    key: `position:${p.id}`,
    type: "position_reported",
    titleFa: TELEMETRY_TITLES.position_reported,
    descriptionFa: parts.length > 0 ? parts.join(" · ") : undefined,
    timestamp: p.reported_at,
    meta: {
      latitude: Number.isFinite(lat) ? lat : null,
      longitude: Number.isFinite(lng) ? lng : null,
      speedKmh: p.speed_kmh ?? null,
      headingDegrees: p.heading_degrees ?? null,
      source: p.source ?? null,
    },
  };
}

function fromDispatchEvent(
  e: DispatchDetail["events"][number],
): DriverTripTimelineItem {
  const from = e.from_status ? DISPATCH_STATUS_FA[e.from_status] : null;
  const to = DISPATCH_STATUS_FA[e.to_status] ?? e.to_status;
  const descParts: string[] = [];
  if (from) {
    descParts.push(`از «${from}» به «${to}»`);
  } else {
    descParts.push(`وضعیت: «${to}»`);
  }
  if (e.reason) descParts.push(`دلیل: ${e.reason}`);
  return {
    key: `dispatch:${e.id}`,
    type: "dispatch_status",
    titleFa: TELEMETRY_TITLES.dispatch_status,
    descriptionFa: descParts.join(" · "),
    timestamp: e.created_at,
    meta: {
      dispatchStatusFrom: e.from_status ?? null,
      dispatchStatusTo: e.to_status,
      actorParty: e.actor_party ?? null,
      eventReason: e.reason ?? null,
    },
  };
}

export interface BuildDriverTripTimelineInput {
  snapshot: TelematicsSnapshot | null;
  positions: TelematicsPosition[];
  dispatch: DispatchDetail | null;
}

// Compose a single chronological array (newest first). Position-reports are
// often very frequent — callers can pass an already-windowed slice of
// positions (e.g. limit: 10) and the timeline cap below is a defensive belt.
export function buildDriverTripTimeline(
  { snapshot, positions, dispatch }: BuildDriverTripTimelineInput,
  { maxItems = 60 }: { maxItems?: number } = {},
): DriverTripTimelineItem[] {
  const items: DriverTripTimelineItem[] = [];

  if (snapshot?.recent_events?.length) {
    for (const e of snapshot.recent_events) items.push(fromEvent(e));
  }
  for (const p of positions) items.push(fromPosition(p));
  if (dispatch?.events?.length) {
    for (const e of dispatch.events) items.push(fromDispatchEvent(e));
  }

  // De-dupe by key (defensive; the same item should never appear twice
  // because keys are namespaced by source).
  const seen = new Set<string>();
  const deduped = items.filter((i) => {
    if (seen.has(i.key)) return false;
    seen.add(i.key);
    return true;
  });

  // Sort newest first; ties keep insertion order.
  deduped.sort((a, b) => {
    const ta = Date.parse(a.timestamp) || 0;
    const tb = Date.parse(b.timestamp) || 0;
    return tb - ta;
  });

  return deduped.slice(0, maxItems);
}
