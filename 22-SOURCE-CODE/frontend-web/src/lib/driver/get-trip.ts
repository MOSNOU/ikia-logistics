import { createClient } from "@/lib/supabase/server";

// Phase D2 — Driver portal UI skeleton (READ-ONLY data wiring).
// Phase G (v1.2) — enriched with last-ping, milestone timestamps, POD kinds,
// and the driver-visible event timeline. All reads are driver-RLS scoped; any
// error degrades gracefully (null trip, or empty lists) — never throws.
//
// Loads a single driver-owned trip via the D1 RPC `dispatch.driver_get_trip`
// plus RLS-scoped SELECTs on dispatch.driver_trip_events / driver_trip_pods
// (both grant SELECT to authenticated and carry a driver-owns RLS policy —
// no migration required for the timeline / POD readiness surfaces).
//
// TODO(v1.x-later): drop the `as any` once Supabase types are regenerated for
// the dispatch.driver_* RPCs and tables.

export interface DriverTripEvent {
  id: string;
  fromStatus: string | null;
  toStatus: string | null;
  reason: string | null;
  createdAt: string | null;
}

// Phase M2 — driver-visible issue row (RLS-scoped), fed to the issue
// intelligence engine on the trip detail page.
export interface DriverTripIssueLite {
  id: string;
  status: string | null;
  category: string | null;
  severity: number | null;
  createdAt: string | null;
  updatedAt: string | null;
}

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
  /** Phase G — last reported position (from telematics via driver_get_trip). */
  lastLatitude: number | null;
  lastLongitude: number | null;
  lastReportedAt: string | null;
  /** Phase G — milestone timestamps for the status stepper (row-level). */
  acceptedAt: string | null;
  completedAt: string | null;
  createdAt: string | null;
  /** Phase D4 — number of PODs attached (driver-RLS scoped). */
  podCount: number;
  /** Convenience flag: at least one POD exists → trip can be completed. */
  hasPod: boolean;
  /** Phase G — POD kinds present (read-only readiness; no upload changes). */
  podKinds: string[];
  /** Phase G — append-only driver trip event ledger (oldest → newest). */
  events: DriverTripEvent[];
  /** Phase M2 — driver-visible issues (RLS-scoped) for the intelligence panel. */
  issues: DriverTripIssueLite[];
}

interface RawDriverTripDetail {
  dispatch_id?: string | null;
  id?: string | null;
  dispatch_status?: string | null;
  execution_status?: string | null;
  route_summary?: string | null;
  vehicle_reference?: string | null;
  driver_name?: string | null;
  planned_pickup_at?: string | null;
  last_latitude?: number | string | null;
  last_longitude?: number | string | null;
  last_reported_at?: string | null;
  accepted_at?: string | null;
  completed_at?: string | null;
  created_at?: string | null;
}

function toNum(v: number | string | null | undefined): number | null {
  if (v == null) return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
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

  // The RPC may return a single row or a one-element set; normalise both.
  const raw = (Array.isArray(data) ? data[0] : data) as
    | RawDriverTripDetail
    | null
    | undefined;
  if (!raw) return null;

  const id = String(raw.dispatch_id ?? raw.id ?? "");
  if (!id) return null;

  // POD rows (kinds + count), the event ledger, and issues — all driver-RLS
  // scoped. Each degrades to an empty list on error.
  const [pods, events, issues] = await Promise.all([
    loadPods(supabase, id),
    loadEvents(supabase, id),
    loadIssues(supabase, id),
  ]);

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
    lastLatitude: toNum(raw.last_latitude),
    lastLongitude: toNum(raw.last_longitude),
    lastReportedAt: raw.last_reported_at ?? null,
    acceptedAt: raw.accepted_at ?? null,
    completedAt: raw.completed_at ?? null,
    createdAt: raw.created_at ?? null,
    podCount: pods.length,
    hasPod: pods.length > 0,
    podKinds: pods,
    events,
    issues,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadPods(supabase: any, dispatchId: string): Promise<string[]> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_pods")
      .select("kind")
      .eq("dispatch_id", dispatchId)
      .order("created_at", { ascending: true });
    if (error) {
      console.error("driver.driver_trip_pods select", error);
      return [];
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ((data ?? []) as any[])
      .map((r) => (r.kind == null ? null : String(r.kind)))
      .filter((k): k is string => k !== null);
  } catch (e) {
    console.error("driver.driver_trip_pods select (threw)", e);
    return [];
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadEvents(supabase: any, dispatchId: string): Promise<DriverTripEvent[]> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_events")
      .select("id, from_status, to_status, reason, created_at")
      .eq("dispatch_id", dispatchId)
      .order("created_at", { ascending: true })
      .limit(200);
    if (error) {
      console.error("driver.driver_trip_events select", error);
      return [];
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ((data ?? []) as any[]).map((r) => ({
      id: String(r.id),
      fromStatus: r.from_status ?? null,
      toStatus: r.to_status ?? null,
      reason: r.reason ?? null,
      createdAt: r.created_at ?? null,
    }));
  } catch (e) {
    console.error("driver.driver_trip_events select (threw)", e);
    return [];
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadIssues(supabase: any, dispatchId: string): Promise<DriverTripIssueLite[]> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_issues")
      .select("id, status, category, severity, reported_at, created_at")
      .eq("dispatch_id", dispatchId)
      .order("reported_at", { ascending: true })
      .limit(200);
    if (error) {
      console.error("driver.driver_trip_issues select", error);
      return [];
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ((data ?? []) as any[]).map((r) => ({
      id: String(r.id),
      status: r.status ?? null,
      category: r.category ?? null,
      severity: r.severity == null ? null : Number(r.severity),
      // driver_trip_issues uses reported_at as the creation time.
      createdAt: r.reported_at ?? r.created_at ?? null,
      updatedAt: r.created_at ?? null,
    }));
  } catch (e) {
    console.error("driver.driver_trip_issues select (threw)", e);
    return [];
  }
}
