import { createClient } from "@/lib/supabase/server";

// Phase D2 — Driver portal UI skeleton (READ-ONLY data wiring).
//
// Loads the signed-in driver's own trips via the D1 RPC
// `dispatch.driver_list_my_trips`. This is the driver-scoped source — do NOT
// confuse it with the carrier-scoped `listDriverTrips` (telematics), which is
// scoped to a carrier org, not to the authenticated driver.
//
// TODO(D-later): replace `as any` once Supabase types are regenerated for the
// dispatch.driver_* RPCs. Until then we call the RPC loosely so the generated
// type set (which does not yet include driver_list_my_trips) never blocks the
// build. Any error returns [] so the UI shows its empty state.

export interface DriverTripRow {
  dispatchId: string;
  shipmentId: string | null;
  status: string | null;
  routeSummary: string | null;
  vehicleReference: string | null;
  plannedPickupAt: string | null;
}

interface RawDriverTripRow {
  dispatch_id?: string | null;
  id?: string | null;
  shipment_id?: string | null;
  status?: string | null;
  route_summary?: string | null;
  vehicle_reference?: string | null;
  planned_pickup_at?: string | null;
}

export interface ListMyTripsParams {
  limit?: number;
  offset?: number;
}

export async function listMyTrips({
  limit = 50,
  offset = 0,
}: ListMyTripsParams = {}): Promise<DriverTripRow[]> {
  const supabase = await createClient();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase.schema("dispatch") as any).rpc(
    "driver_list_my_trips",
    { p_limit: limit, p_offset: offset },
  );
  if (error) {
    console.error("driver.driver_list_my_trips", error);
    return [];
  }

  const rows = (Array.isArray(data) ? data : []) as RawDriverTripRow[];
  return rows.map((r): DriverTripRow => ({
    dispatchId: String(r.dispatch_id ?? r.id ?? ""),
    shipmentId: r.shipment_id ?? null,
    status: r.status ?? null,
    routeSummary: r.route_summary ?? null,
    vehicleReference: r.vehicle_reference ?? null,
    plannedPickupAt: r.planned_pickup_at ?? null,
  }));
}
