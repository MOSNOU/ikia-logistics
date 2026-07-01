import { createClient } from "@/lib/supabase/server";

// Phase D5 — operations/admin driver trip detail (READ-ONLY).
//
// Combines the D1 RPC dispatch.admin_get_driver_trip_detail (summary scalars:
// statuses, last position, open-issue / POD counts) with direct SELECTs of the
// issue list, POD list and event timeline. The D1 RLS SELECT policies on
// dispatch.driver_trip_{issues,pods,events} already authorize platform_admin /
// operations_user (and same-tenant carrier ops), so the lists are scoped by the
// database. Any error degrades to null / empty arrays — never throws.
//
// TODO(D-later): drop the `as any` casts once Supabase types are regenerated
// for the dispatch.admin_* RPCs and the driver_trip_* tables.

export interface DriverTripIssue {
  id: string;
  category: string | null;
  status: string | null;
  severity: number | null;
  description: string | null;
  reportedAt: string | null;
  acknowledgedAt: string | null;
  resolvedAt: string | null;
  resolutionNote: string | null;
}

export interface DriverTripPod {
  id: string;
  fileId: string | null;
  kind: string | null;
  createdAt: string | null;
}

export interface DriverTripEvent {
  id: string;
  fromStatus: string | null;
  toStatus: string | null;
  reason: string | null;
  createdAt: string | null;
}

export interface DriverTripDetailAdmin {
  dispatchId: string;
  carrierOrganizationId: string | null;
  driverUserId: string | null;
  dispatchStatus: string | null;
  executionStatus: string | null;
  lastLatitude: number | null;
  lastLongitude: number | null;
  lastReportedAt: string | null;
  openIssueCount: number;
  podCount: number;
  plannedPickupAt: string | null;
  acceptedAt: string | null;
  completedAt: string | null;
  createdAt: string | null;
  /** Phase H — vehicle + last status-progress time (for the progress block). */
  vehicleReference: string | null;
  updatedAt: string | null;
  issues: DriverTripIssue[];
  pods: DriverTripPod[];
  events: DriverTripEvent[];
}

interface RawSummary {
  dispatch_id?: string | null;
  carrier_organization_id?: string | null;
  driver_user_id?: string | null;
  dispatch_status?: string | null;
  execution_status?: string | null;
  last_latitude?: number | string | null;
  last_longitude?: number | string | null;
  last_reported_at?: string | null;
  open_issue_count?: number | string | null;
  pod_count?: number | string | null;
  planned_pickup_at?: string | null;
  accepted_at?: string | null;
  completed_at?: string | null;
  created_at?: string | null;
}

function toNum(v: number | string | null | undefined): number | null {
  if (v == null) return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

export async function getDriverTripDetailAdmin(
  dispatchId: string,
): Promise<DriverTripDetailAdmin | null> {
  if (!dispatchId) return null;

  const supabase = await createClient();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase.schema("dispatch") as any).rpc(
    "admin_get_driver_trip_detail",
    { p_dispatch_id: dispatchId },
  );
  if (error) {
    console.error("dispatch.admin_get_driver_trip_detail", error);
    return null;
  }
  const raw = (Array.isArray(data) ? data[0] : data) as
    | RawSummary
    | null
    | undefined;
  if (!raw) return null;
  const id = String(raw.dispatch_id ?? "");
  if (!id) return null;

  // Issue / POD / event lists + vehicle/updated_at via the admin's own SELECT
  // RLS. Each read is isolated — any failure degrades rather than failing.
  const [issues, pods, events, meta] = await Promise.all([
    loadIssues(supabase, id),
    loadPods(supabase, id),
    loadEvents(supabase, id),
    loadMeta(supabase, id),
  ]);

  return {
    dispatchId: id,
    carrierOrganizationId: raw.carrier_organization_id ?? null,
    driverUserId: raw.driver_user_id ?? null,
    dispatchStatus: raw.dispatch_status ?? null,
    executionStatus: raw.execution_status ?? null,
    lastLatitude: toNum(raw.last_latitude),
    lastLongitude: toNum(raw.last_longitude),
    lastReportedAt: raw.last_reported_at ?? null,
    openIssueCount: toNum(raw.open_issue_count) ?? 0,
    podCount: toNum(raw.pod_count) ?? 0,
    plannedPickupAt: raw.planned_pickup_at ?? null,
    acceptedAt: raw.accepted_at ?? null,
    completedAt: raw.completed_at ?? null,
    createdAt: raw.created_at ?? null,
    vehicleReference: meta.vehicleReference,
    updatedAt: meta.updatedAt,
    issues,
    pods,
    events,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadMeta(
  supabase: any,
  dispatchId: string,
): Promise<{ vehicleReference: string | null; updatedAt: string | null }> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("dispatch_assignments")
      .select("vehicle_reference, updated_at")
      .eq("id", dispatchId)
      .maybeSingle();
    if (error) {
      console.error("dispatch.dispatch_assignments meta", error);
      return { vehicleReference: null, updatedAt: null };
    }
    return {
      vehicleReference: data?.vehicle_reference ?? null,
      updatedAt: data?.updated_at ?? null,
    };
  } catch (e) {
    console.error("dispatch.dispatch_assignments meta (threw)", e);
    return { vehicleReference: null, updatedAt: null };
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadIssues(supabase: any, dispatchId: string): Promise<DriverTripIssue[]> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_issues")
      .select(
        "id, category, status, severity, description, reported_at, acknowledged_at, resolved_at, resolution_note",
      )
      .eq("dispatch_id", dispatchId)
      .order("reported_at", { ascending: false });
    if (error) {
      console.error("dispatch.driver_trip_issues select", error);
      return [];
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ((data ?? []) as any[]).map((r) => ({
      id: String(r.id),
      category: r.category ?? null,
      status: r.status ?? null,
      severity: toNum(r.severity),
      description: r.description ?? null,
      reportedAt: r.reported_at ?? null,
      acknowledgedAt: r.acknowledged_at ?? null,
      resolvedAt: r.resolved_at ?? null,
      resolutionNote: r.resolution_note ?? null,
    }));
  } catch (e) {
    console.error("dispatch.driver_trip_issues select (threw)", e);
    return [];
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadPods(supabase: any, dispatchId: string): Promise<DriverTripPod[]> {
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_pods")
      .select("id, file_id, kind, created_at")
      .eq("dispatch_id", dispatchId)
      .order("created_at", { ascending: false });
    if (error) {
      console.error("dispatch.driver_trip_pods select", error);
      return [];
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return ((data ?? []) as any[]).map((r) => ({
      id: String(r.id),
      fileId: r.file_id ?? null,
      kind: r.kind ?? null,
      createdAt: r.created_at ?? null,
    }));
  } catch (e) {
    console.error("dispatch.driver_trip_pods select (threw)", e);
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
      .order("created_at", { ascending: false })
      .limit(100);
    if (error) {
      console.error("dispatch.driver_trip_events select", error);
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
    console.error("dispatch.driver_trip_events select (threw)", e);
    return [];
  }
}
