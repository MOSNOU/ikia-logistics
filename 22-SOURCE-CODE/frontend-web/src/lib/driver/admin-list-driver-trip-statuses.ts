import { createClient } from "@/lib/supabase/server";

// Phase D5 — operations/admin visibility over driver trips (READ-ONLY).
//
// Wraps the D1 RPC dispatch.admin_list_driver_trip_statuses, which is
// SECURITY DEFINER and authorizes the caller (platform_admin / operations_user
// or same-tenant) internally. Any error returns [] so the page renders an
// empty-state instead of crashing.
//
// TODO(D-later): drop the `as any` once Supabase types are regenerated for the
// dispatch.admin_* RPCs.

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
  return rows
    .map((r) => {
      const id = String(r.dispatch_id ?? "");
      if (!id) return null;
      return {
        dispatchId: id,
        carrierOrganizationId: r.carrier_organization_id ?? null,
        driverUserId: r.driver_user_id ?? null,
        dispatchStatus: r.dispatch_status ?? null,
        executionStatus: r.execution_status ?? null,
        lastLatitude: toNum(r.last_latitude),
        lastLongitude: toNum(r.last_longitude),
        lastReportedAt: r.last_reported_at ?? null,
        openIssueCount: toNum(r.open_issue_count) ?? 0,
        plannedPickupAt: r.planned_pickup_at ?? null,
        createdAt: r.created_at ?? null,
      } satisfies DriverTripStatusRow;
    })
    .filter((r): r is DriverTripStatusRow => r !== null);
}
