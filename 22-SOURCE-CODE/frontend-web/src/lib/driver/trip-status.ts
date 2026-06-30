// Phase D2 — Driver portal UI skeleton.
//
// The 10 D1 execution statuses in canonical order, with Persian labels.
// Shared by the trip detail status stepper and any future driver views.
// READ-ONLY: this drives display only; no status is mutated in this phase.

export interface DriverTripStatusStep {
  status: string;
  label: string;
}

export const DRIVER_TRIP_STATUSES: readonly DriverTripStatusStep[] = [
  { status: "assigned", label: "اختصاص داده‌شده" },
  { status: "accepted", label: "پذیرفته‌شده" },
  { status: "arrived_at_pickup", label: "رسیدن به بارگیری" },
  { status: "loading_started", label: "شروع بارگیری" },
  { status: "loaded", label: "بارگیری‌شده" },
  { status: "in_transit", label: "در مسیر" },
  { status: "arrived_at_delivery", label: "رسیدن به تحویل" },
  { status: "unloading_started", label: "شروع تخلیه" },
  { status: "delivered", label: "تحویل‌شده" },
  { status: "completed", label: "تکمیل‌شده" },
] as const;

export function driverTripStatusLabel(status: string | null | undefined): string {
  if (!status) return "نامشخص";
  return DRIVER_TRIP_STATUSES.find((s) => s.status === status)?.label ?? status;
}

export function driverTripStatusIndex(status: string | null | undefined): number {
  if (!status) return -1;
  return DRIVER_TRIP_STATUSES.findIndex((s) => s.status === status);
}

// ---------------------------------------------------------------------------
// Phase D3 — next legal workflow action per execution status.
//
// `key` maps to a named server action in `@/lib/driver/trip-actions`.
// `"complete-gated"` = the delivered→completed step, which is intentionally
// disabled in D3 (driver_complete_trip requires a POD that D4 will add).
// `null` = no action (completed, or unknown status).
// ---------------------------------------------------------------------------
export interface DriverNextAction {
  key: string;
  label: string;
}

const DRIVER_NEXT_ACTION: Record<string, DriverNextAction | "complete-gated" | null> = {
  assigned: { key: "accept", label: "پذیرش سفر" },
  accepted: { key: "arrivePickup", label: "رسیدم به محل بارگیری" },
  arrived_at_pickup: { key: "startLoading", label: "شروع بارگیری" },
  loading_started: { key: "confirmLoaded", label: "بارگیری انجام شد" },
  loaded: { key: "startTransit", label: "شروع حرکت" },
  in_transit: { key: "arriveDelivery", label: "رسیدم به محل تخلیه" },
  arrived_at_delivery: { key: "startUnloading", label: "شروع تخلیه" },
  unloading_started: { key: "confirmDelivered", label: "تحویل انجام شد" },
  delivered: "complete-gated",
  completed: null,
};

export function driverNextAction(
  status: string | null | undefined,
): DriverNextAction | "complete-gated" | null {
  // A null/absent execution status means the trip is freshly assigned.
  const s = status ?? "assigned";
  return DRIVER_NEXT_ACTION[s] ?? null;
}
