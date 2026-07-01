import { hoursSince } from "@/lib/driver/relative-time";

// Phase H (v1.2, Q4) — frontend/loader-derived "stall" heuristic for driver
// trip progress. No DB field, no migration: computed from the last GPS ping and
// the last status-progress timestamp (dispatch_assignments.updated_at).
//
//   warning  — no GPS ping for ≥ 3h
//   critical — no GPS ping AND no status progress for ≥ 6h
//
// Terminal / cancelled trips are never "stalled".

export type StallLevel = "critical" | "warning" | null;

const TERMINAL_EXEC = new Set(["completed"]);

export interface StallInput {
  executionStatus: string | null;
  dispatchStatus: string | null;
  lastReportedAt: string | null;
  updatedAt: string | null;
  createdAt?: string | null;
}

export function deriveStall(input: StallInput, now?: Date): StallLevel {
  if (input.dispatchStatus === "cancelled") return null;
  if (input.executionStatus && TERMINAL_EXEC.has(input.executionStatus)) return null;

  // "Time since we last heard a ping": the ping age, or — when there has never
  // been a ping — how long since the trip last changed / was created.
  const pingH =
    hoursSince(input.lastReportedAt, now) ??
    hoursSince(input.updatedAt, now) ??
    hoursSince(input.createdAt, now);
  const statusH =
    hoursSince(input.updatedAt, now) ?? hoursSince(input.createdAt, now);

  if (pingH == null) return null;
  if (pingH >= 6 && (statusH ?? 0) >= 6) return "critical";
  if (pingH >= 3) return "warning";
  return null;
}

export function stallLabel(level: StallLevel): string {
  if (level === "critical") return "بحرانی";
  if (level === "warning") return "هشدار";
  return "عادی";
}

export function stallBadgeVariant(
  level: StallLevel,
): "danger" | "warning" | "success" {
  if (level === "critical") return "danger";
  if (level === "warning") return "warning";
  return "success";
}
