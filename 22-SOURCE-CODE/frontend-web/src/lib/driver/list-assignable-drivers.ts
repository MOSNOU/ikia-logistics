import { createClient } from "@/lib/supabase/server";

// Phase D (v1.1) — assignable-driver pick-list for the carrier assign-driver UI.
//
// Wraps the D-B RPC dispatch.carrier_list_assignable_drivers, which is
// SECURITY DEFINER and authorizes the caller (carrier_admin / organization_admin
// on the dispatch's carrier org, or platform_admin). READ-ONLY; any error
// returns [] so the panel renders its empty state instead of crashing.
//
// TODO(v1.1-later): drop the `as any` once Supabase types are regenerated for
// the dispatch.carrier_assign_driver / carrier_list_assignable_drivers RPCs.

export interface AssignableDriver {
  driverUserId: string;
  fullName: string | null;
}

interface RawAssignableDriver {
  driver_user_id?: string | null;
  full_name?: string | null;
  organization_id?: string | null;
}

export async function listAssignableDrivers(
  dispatchId: string,
): Promise<AssignableDriver[]> {
  if (!dispatchId) return [];

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase.schema("dispatch") as any).rpc(
    "carrier_list_assignable_drivers",
    { p_dispatch_id: dispatchId },
  );
  if (error) {
    console.error("dispatch.carrier_list_assignable_drivers", error);
    return [];
  }

  const rows = (Array.isArray(data) ? data : []) as RawAssignableDriver[];
  return rows
    .map((r) => ({
      driverUserId: String(r.driver_user_id ?? ""),
      fullName: r.full_name ?? null,
    }))
    .filter((r) => r.driverUserId.length > 0);
}
