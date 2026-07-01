import { createClient } from "@/lib/supabase/server";
import { deriveStall, type StallLevel } from "@/lib/driver/trip-progress";

// Phase D5 — operations/admin visibility over driver trips (READ-ONLY).
// Phase H (v1.2) — enriched with vehicle, POD readiness, and a derived stall
// indicator. The base list comes from the SECURITY DEFINER RPC
// dispatch.admin_list_driver_trip_statuses; vehicle / updated_at and POD counts
// are batched RLS reads (platform_admin / ops can SELECT via existing policies).
// No migration. Any error returns [] / degrades to unenriched rows.
//
// TODO(D-later): drop the `as any` once Supabase types are regenerated.

export interface DriverTripStatusRow {
  dispatchId: string;
  carrierOrganizationId: string | null;
  driverUserId: string | null;
  dispatchStatus: string | null;
  executionStatus: string | null;
  lastLatitude: number | null;
  lastLongitude: number | null;
  lastReportedAt: string | null;
  openIssueCount: number;
  plannedPickupAt: string | null;
  createdAt: string | null;
  /** Phase H additions. */
  vehicleReference: string | null;
  updatedAt: string | null;
  podCount: number;
  hasPod: boolean;
  stall: StallLevel;
}

interface RawRow {
  dispatch_id?: string | null;
  carrier_organization_id?: string | null;
  driver_user_id?: string | null;
  dispatch_status?: string | null;
  execution_status?: string | null;
  last_latitude?: number | string | null;
  last_longitude?: number | string | null;
  last_reported_at?: string | null;
  open_issue_count?: number | string | null;
  planned_pickup_at?: string | null;
  created_at?: string | null;
}

export interface ListDriverTripStatusesParams {
  organizationId?: string | null;
  executionStatus?: string | null;
  limit?: number;
  offset?: number;
}

function toNum(v: number | string | null | undefined): number | null {
  if (v == null) return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

export async function listDriverTripStatuses({
  organizationId = null,
  executionStatus = null,
  limit = 100,
  offset = 0,
}: ListDriverTripStatusesParams = {}): Promise<DriverTripStatusRow[]> {
  const supabase = await createClient();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase.schema("dispatch") as any).rpc(
    "admin_list_driver_trip_statuses",
    {
      p_organization_id: organizationId,
      p_status: executionStatus,
      p_limit: limit,
      p_offset: offset,
    },
  );
  if (error) {
    console.error("dispatch.admin_list_driver_trip_statuses", error);
    return [];
  }

  const rows = (Array.isArray(data) ? data : []) as RawRow[];
  const ids = rows
    .map((r) => String(r.dispatch_id ?? ""))
    .filter((id) => id.length > 0);

  // Batched enrichment (two reads regardless of row count).
  const [vehicleById, podCountById] = await Promise.all([
    loadVehicleAndUpdated(supabase, ids),
    loadPodCounts(supabase, ids),
  ]);

  return rows
    .map((r) => {
      const id = String(r.dispatch_id ?? "");
      if (!id) return null;
      const enrich = vehicleById.get(id);
      const updatedAt = enrich?.updatedAt ?? null;
      const executionStatus = r.execution_status ?? null;
      const dispatchStatus = r.dispatch_status ?? null;
      const lastReportedAt = r.last_reported_at ?? null;
      const createdAt = r.created_at ?? null;
      const podCount = podCountById.get(id) ?? 0;
      return {
        dispatchId: id,
        carrierOrganizationId: r.carrier_organization_id ?? null,
        driverUserId: r.driver_user_id ?? null,
        dispatchStatus,
        executionStatus,
        lastLatitude: toNum(r.last_latitude),
        lastLongitude: toNum(r.last_longitude),
        lastReportedAt,
        openIssueCount: toNum(r.open_issue_count) ?? 0,
        plannedPickupAt: r.planned_pickup_at ?? null,
        createdAt,
        vehicleReference: enrich?.vehicleReference ?? null,
        updatedAt,
        podCount,
        hasPod: podCount > 0,
        stall: deriveStall({
          executionStatus,
          dispatchStatus,
          lastReportedAt,
          updatedAt,
          createdAt,
        }),
      } satisfies DriverTripStatusRow;
    })
    .filter((r): r is DriverTripStatusRow => r !== null);
}

interface VehicleEnrich {
  vehicleReference: string | null;
  updatedAt: string | null;
}

async function loadVehicleAndUpdated(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  ids: string[],
): Promise<Map<string, VehicleEnrich>> {
  const map = new Map<string, VehicleEnrich>();
  if (ids.length === 0) return map;
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("dispatch_assignments")
      .select("id, vehicle_reference, updated_at")
      .in("id", ids);
    if (error) {
      console.error("dispatch.dispatch_assignments enrich", error);
      return map;
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    for (const r of (data ?? []) as any[]) {
      map.set(String(r.id), {
        vehicleReference: r.vehicle_reference ?? null,
        updatedAt: r.updated_at ?? null,
      });
    }
  } catch (e) {
    console.error("dispatch.dispatch_assignments enrich (threw)", e);
  }
  return map;
}

async function loadPodCounts(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  ids: string[],
): Promise<Map<string, number>> {
  const map = new Map<string, number>();
  if (ids.length === 0) return map;
  try {
    const { data, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_pods")
      .select("dispatch_id")
      .in("dispatch_id", ids);
    if (error) {
      console.error("dispatch.driver_trip_pods count", error);
      return map;
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    for (const r of (data ?? []) as any[]) {
      const k = String(r.dispatch_id);
      map.set(k, (map.get(k) ?? 0) + 1);
    }
  } catch (e) {
    console.error("dispatch.driver_trip_pods count (threw)", e);
  }
  return map;
}
