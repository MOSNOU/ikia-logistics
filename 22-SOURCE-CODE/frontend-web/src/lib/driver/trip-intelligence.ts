import { driverTripStatusIndex, DRIVER_TRIP_STATUSES } from "@/lib/driver/trip-status";
import type { StallLevel } from "@/lib/driver/trip-progress";

// Phase L (v1.3) — Operational Trip Intelligence: pure, read-only derivations
// over data already loaded elsewhere (execution status, stall signal, open
// issues, POD readiness). NO route deviation, NO geofence, NO DB — those are
// deferred to v1.4. These are deterministic, testable helpers only.

/** Progress through the 10-status lifecycle, 0–100. */
export function tripProgressPercent(status: string | null | undefined): number {
  if (status === "completed") return 100;
  const idx = driverTripStatusIndex(status);
  if (idx < 0) return 0;
  const last = DRIVER_TRIP_STATUSES.length - 1;
  return Math.round((idx / last) * 100);
}

export type TripHealthLevel = "done" | "on_track" | "attention" | "at_risk";

export interface TripHealthInput {
  executionStatus: string | null;
  dispatchStatus: string | null;
  stall: StallLevel;
  openIssueCount: number;
  hasPod: boolean;
}

/**
 * Composite operational health for a trip, from signals already derived
 * upstream (no new data). Precedence: done → at_risk → attention → on_track.
 */
export function tripHealth(input: TripHealthInput): TripHealthLevel {
  const { executionStatus, dispatchStatus, stall, openIssueCount, hasPod } = input;

  if (executionStatus === "completed") return "done";

  // Critical stall, or an open issue on a cancelled dispatch → at risk.
  if (stall === "critical") return "at_risk";

  // Warnings that warrant operational attention.
  if (
    stall === "warning" ||
    openIssueCount > 0 ||
    (executionStatus === "delivered" && !hasPod) // delivered but no POD yet
  ) {
    return "attention";
  }

  return "on_track";
}

export const TRIP_HEALTH_LABEL: Record<TripHealthLevel, string> = {
  done: "تکمیل‌شده",
  on_track: "در مسیر عادی",
  attention: "نیازمند توجه",
  at_risk: "در معرض خطر",
};

export function tripHealthBadgeVariant(
  level: TripHealthLevel,
): "success" | "info" | "warning" | "danger" {
  switch (level) {
    case "done":
      return "success";
    case "on_track":
      return "info";
    case "attention":
      return "warning";
    case "at_risk":
      return "danger";
  }
}
