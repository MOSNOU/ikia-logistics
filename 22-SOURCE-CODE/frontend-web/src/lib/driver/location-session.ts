// Phase J (v1.3) — Smart Live Tracking: pure, framework-agnostic helpers for
// the foreground GPS session. NO background execution, NO service worker, NO
// offline/IndexedDB persistence — the session only runs while the trip detail
// tab is open and the driver has explicitly started it. The orchestration
// (timers + geolocation) lives in the client component; this module holds the
// deterministic, testable pieces (cadence, accuracy filter, dedupe, backoff).

export type LiveStatus = "stopped" | "waiting" | "sending" | "weak" | "retrying";

export const LIVE_STATUS_LABEL: Record<LiveStatus, string> = {
  stopped: "متوقف شده",
  waiting: "منتظر موقعیت",
  sending: "در حال ارسال زنده",
  weak: "موقعیت ضعیف",
  retrying: "تلاش مجدد",
};

// --- Tuning constants (Q5) -------------------------------------------------
/** Fixes worse than this horizontal accuracy (metres) are not sent. */
export const ACCURACY_MAX_M = 100;
/** Fixes within this distance (metres) of the last SENT fix are deduped. */
export const DEDUPE_M = 15;
/** Speed bands (km/h). */
export const MOVING_KMH = 20;
export const STOPPED_KMH = 3;
/** Smart cadence per movement state (ms). */
export const CADENCE_MS = {
  moving: 18_000, // road speed → 15–20s
  low: 45_000, // low speed → 45s
  stopped: 120_000, // stopped / no movement → 2 min
} as const;
/** After a low-accuracy fix, retry sooner to get a better one. */
export const WEAK_RETRY_MS = 20_000;
/** In-memory retry/backoff schedule for failed sends / geo errors. */
export const RETRY_BACKOFF_MS = [3_000, 6_000, 12_000, 20_000] as const;

export interface LatLng {
  lat: number;
  lon: number;
}

/** Great-circle distance in metres. */
export function haversineMeters(a: LatLng, b: LatLng): number {
  const R = 6_371_000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Derive speed (km/h) between two timestamped fixes; null if not derivable. */
export function deriveSpeedKmh(
  prev: { lat: number; lon: number; t: number },
  next: { lat: number; lon: number; t: number },
): number | null {
  const dtSec = (next.t - prev.t) / 1000;
  if (!Number.isFinite(dtSec) || dtSec <= 0) return null;
  const meters = haversineMeters(prev, next);
  return (meters / dtSec) * 3.6;
}

/** Whether the new fix is far enough from the last sent fix to be worth sending. */
export function hasMoved(lastSent: LatLng | null, next: LatLng): boolean {
  if (!lastSent) return true;
  return haversineMeters(lastSent, next) >= DEDUPE_M;
}

/** Whether a fix's accuracy is good enough to send. */
export function isAccurate(accuracyMeters: number | null | undefined): boolean {
  if (accuracyMeters == null) return true; // unknown accuracy — accept
  return accuracyMeters <= ACCURACY_MAX_M;
}

/** Smart cadence (ms) until the next fix, from speed + whether we moved. */
export function pickCadenceMs(
  speedKmh: number | null,
  moved: boolean,
): number {
  if (!moved) return CADENCE_MS.stopped;
  if (speedKmh == null) return CADENCE_MS.low;
  if (speedKmh >= MOVING_KMH) return CADENCE_MS.moving;
  if (speedKmh < STOPPED_KMH) return CADENCE_MS.stopped;
  return CADENCE_MS.low;
}

/** Backoff delay (ms) for the Nth consecutive failure (attempt starts at 1). */
export function retryDelayMs(attempt: number): number {
  const i = Math.min(Math.max(attempt, 1) - 1, RETRY_BACKOFF_MS.length - 1);
  return RETRY_BACKOFF_MS[i]!;
}
