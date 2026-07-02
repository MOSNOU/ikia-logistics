// Phase K (v1.3) — Session Health (pure).
//
// Combines capability detection, permission health, driver consent, and
// connectivity into an overall readiness verdict for a (future) tracking
// session. Pure: takes inputs, returns a verdict + reasons. Starts nothing.

import type { DeviceCapabilities } from "./capabilities";
import type { GeoPermission } from "./permission-health";
import { hasActiveConsent, type ConsentRecord } from "./consent";
import {
  trackingReducer,
  type TrackingState,
  type TrackingEvent,
} from "./state-machine";

export type SessionHealthLevel = "ready" | "blocked" | "unavailable";

export interface SessionHealthInput {
  capabilities: DeviceCapabilities;
  permission: GeoPermission;
  consent: ConsentRecord | null;
  online: boolean;
}

export interface SessionHealth {
  level: SessionHealthLevel;
  ready: boolean;
  /** Human-readable Persian reasons the session is not ready (empty when ready). */
  reasons: string[];
  /** The readiness state derived through the pure state machine. */
  state: TrackingState;
}

export function computeSessionHealth(input: SessionHealthInput): SessionHealth {
  const { capabilities, permission, consent, online } = input;
  const reasons: string[] = [];

  // Hard unavailability first.
  if (!capabilities.geolocation || permission === "unsupported") {
    return {
      level: "unavailable",
      ready: false,
      reasons: ["دستگاه یا مرورگر از موقعیت‌یابی پشتیبانی نمی‌کند."],
      state: reduce(["CHECK", "UNSUPPORTED"]),
    };
  }
  if (!capabilities.secureContext) {
    reasons.push("زمینه امن (HTTPS) لازم است.");
  }

  // Consent gate.
  const consented = hasActiveConsent(consent);
  if (!consented) {
    reasons.push("رضایت راننده ثبت نشده است.");
  }

  // Permission gate.
  if (permission === "denied") {
    reasons.push("مجوز موقعیت رد شده است.");
  } else if (permission === "prompt" || permission === "unknown") {
    reasons.push("مجوز موقعیت هنوز تأیید نشده است.");
  }

  if (!online) {
    reasons.push("اتصال اینترنت برقرار نیست.");
  }

  // Derive the readiness state through the pure machine.
  const events: TrackingEvent[] = [{ type: "CHECK" }];
  if (!consented) {
    events.push({ type: "CONSENT_MISSING" });
  } else if (permission === "denied") {
    events.push({ type: "PERMISSION_BLOCKED" });
  } else if (permission !== "granted") {
    events.push({ type: "PERMISSION_PENDING" });
  } else {
    events.push({ type: "READY" });
  }
  const state = events.reduce(trackingReducer, "idle" as TrackingState);

  const ready = state === "ready" && online && capabilities.secureContext;
  return {
    level: ready ? "ready" : "blocked",
    ready,
    reasons: ready ? [] : reasons,
    state,
  };
}

function reduce(types: TrackingEvent["type"][]): TrackingState {
  return types.reduce(
    (s, t) => trackingReducer(s, { type: t } as TrackingEvent),
    "idle" as TrackingState,
  );
}
