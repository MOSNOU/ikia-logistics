// Phase K (v1.3) — Tracking State Machine (pure, architecture-only).
//
// Models the lifecycle a future background-tracking session would move through.
// It is a pure reducer with NO side effects and executes NO tracking. v1.3 only
// ever drives it up to `ready` (readiness); `active`/`paused` are reserved for a
// later phase and are never dispatched here.

export type TrackingState =
  | "idle"
  | "checking"
  | "unsupported"
  | "needs_consent"
  | "needs_permission"
  | "ready"
  | "active" // reserved for a future phase — not driven in v1.3
  | "paused" // reserved for a future phase — not driven in v1.3
  | "error";

export type TrackingEvent =
  | { type: "CHECK" }
  | { type: "UNSUPPORTED" }
  | { type: "CONSENT_MISSING" }
  | { type: "PERMISSION_BLOCKED" }
  | { type: "PERMISSION_PENDING" }
  | { type: "READY" }
  | { type: "START" } // future phase
  | { type: "PAUSE" } // future phase
  | { type: "RESUME" } // future phase
  | { type: "STOP" }
  | { type: "ERROR" };

export function trackingReducer(
  state: TrackingState,
  event: TrackingEvent,
): TrackingState {
  switch (event.type) {
    case "CHECK":
      return "checking";
    case "UNSUPPORTED":
      return "unsupported";
    case "CONSENT_MISSING":
      return "needs_consent";
    case "PERMISSION_BLOCKED":
    case "PERMISSION_PENDING":
      return "needs_permission";
    case "READY":
      return "ready";
    case "START":
      // Only meaningful once ready; reserved for a future phase.
      return state === "ready" ? "active" : state;
    case "PAUSE":
      return state === "active" ? "paused" : state;
    case "RESUME":
      return state === "paused" ? "active" : state;
    case "STOP":
      return "ready";
    case "ERROR":
      return "error";
    default:
      return state;
  }
}

export const TRACKING_STATE_LABEL: Record<TrackingState, string> = {
  idle: "آماده‌به‌کار",
  checking: "در حال بررسی",
  unsupported: "پشتیبانی‌نشده",
  needs_consent: "نیازمند رضایت راننده",
  needs_permission: "نیازمند مجوز موقعیت",
  ready: "آماده",
  active: "فعال",
  paused: "موقتاً متوقف",
  error: "خطا",
};
