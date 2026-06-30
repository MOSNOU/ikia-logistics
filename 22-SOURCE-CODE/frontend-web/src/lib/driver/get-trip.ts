import { createClient } from "@/lib/supabase/server";

// Phase D2 — Driver portal UI skeleton (READ-ONLY data wiring).
//
// Loads a single driver-owned trip via the D1 RPC `dispatch.driver_get_trip`.
//
// TODO(D-later): replace `as any` once Supabase types are regenerated for the
// dispatch.driver_* RPCs. Until then we call the RPC loosely so the generated
// type set never blocks the build. Any error (including an invalid / foreign
// dispatch id) returns null so the page renders a graceful "not found" card.

export interface DriverTripDetail {
  dispatchId: string;
  /** D1 trip execution status (assigned…completed); null until the driver acts. */
  executionStatus: string | null;
  /** Carrier dispatch lifecycle status (draft…released…cancelled). */
  dispatchStatus: string | null;
  /** Back-compat alias of executionStatus for the existing stepper UI. */
  status: string | null;
  routeSummary: string | null;
  vehicleReference: string | null;
  driverName: string | null;
  plannedPickupAt: string | null;
}

interface RawDriverTripDetail {
  dispatch_id?: string | null;
  id?: string | null;
  // driver_get_trip returns dispatch_status + execution_status (not "status").
  dispatch_status?: string | null;
  execution_status?: string | null;
  route_summary?: string | null;
  vehicle_reference?: string | null;
  driver_name?: string | null;
  planned_pickup_at?: string | null;
}

export async function getTrip(dispatchId: string): Promise<DriverTripDetail | null> {
  if (!dispatchId) return null;

  const supabase = await createClient();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase.schema("dispatch") as any).rpc(
    "driver_get_trip",
    { p_dispatch_id: dispatchId },
  );
  if (error) {
    console.error("driver.driver_get_trip", error);
    return null;
  }

  // The RPC may return a single row or a one-element set depending on its
  // definition; normalise both shapes.
  const raw = (Array.isArray(data) ? data[0] : data) as
    | RawDriverTripDetail
    | null
    | undefined;
  if (!raw) return null;

  const id = String(raw.dispatch_id ?? raw.id ?? "");
  if (!id) return null;

  const executionStatus = raw.execution_status ?? null;
  return {
    dispatchId: id,
    executionStatus,
    dispatchStatus: raw.dispatch_status ?? null,
    status: executionStatus,
    routeSummary: raw.route_summary ?? null,
    vehicleReference: raw.vehicle_reference ?? null,
    driverName: raw.driver_name ?? null,
    plannedPickupAt: raw.planned_pickup_at ?? null,
  };
}
