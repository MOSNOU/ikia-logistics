// Phase K (v1.3) — Background Tracking Readiness: feature flags.
//
// This phase builds ARCHITECTURE ONLY. Every background capability is OFF and
// must stay off until a future phase explicitly enables it. No flag here turns
// on real background execution, a service worker, Background Sync, or push.

export interface DriverTrackingFlags {
  /** Real continuous/background tracking. NOT implemented in v1.3. */
  backgroundTracking: boolean;
  /** Service worker + Background Sync. Out of scope for v1.3. */
  backgroundSync: boolean;
  /** Push notifications. Out of scope for v1.3. */
  pushNotifications: boolean;
  /** Development-only telemetry debug panel. */
  debugPanel: boolean;
}

const isProduction = process.env.NODE_ENV === "production";

export const DRIVER_TRACKING_FLAGS: DriverTrackingFlags = {
  backgroundTracking: false,
  backgroundSync: false,
  pushNotifications: false,
  // Debug panel is available only outside production builds.
  debugPanel: !isProduction,
};
