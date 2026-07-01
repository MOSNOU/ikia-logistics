import { createClient } from "@/lib/supabase/server";
import { getTelematicsSnapshot } from "@/lib/telematics/loaders";

// Phase H (v1.2, Q5) — compact driver-progress read-back for the carrier
// dispatch detail page. READ-ONLY: POD / open-issue counts come from the
// carrier's own SELECT RLS on the driver_trip_* tables; last-ping comes from the
// existing carrier telemetry snapshot RPC. No migration, no full timeline.
//
// TODO(v1.x-later): drop the `as any` once Supabase types are regenerated.

export interface CarrierTripProgress {
  podCount: number;
  openIssueCount: number;
  lastReportedAt: string | null;
}

export async function getCarrierTripProgress(
  dispatchId: string,
): Promise<CarrierTripProgress> {
  const empty: CarrierTripProgress = {
    podCount: 0,
    openIssueCount: 0,
    lastReportedAt: null,
  };
  if (!dispatchId) return empty;

  const supabase = await createClient();
  const [podCount, openIssueCount, lastReportedAt] = await Promise.all([
    countPods(supabase, dispatchId),
    countOpenIssues(supabase, dispatchId),
    lastPing(dispatchId),
  ]);
  return { podCount, openIssueCount, lastReportedAt };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function countPods(supabase: any, dispatchId: string): Promise<number> {
  try {
    const { count, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_pods")
      .select("id", { count: "exact", head: true })
      .eq("dispatch_id", dispatchId);
    if (error) {
      console.error("carrier.driver_trip_pods count", error);
      return 0;
    }
    return count ?? 0;
  } catch (e) {
    console.error("carrier.driver_trip_pods count (threw)", e);
    return 0;
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function countOpenIssues(supabase: any, dispatchId: string): Promise<number> {
  try {
    const { count, error } = await supabase
      .schema("dispatch")
      .from("driver_trip_issues")
      .select("id", { count: "exact", head: true })
      .eq("dispatch_id", dispatchId)
      .eq("status", "open");
    if (error) {
      console.error("carrier.driver_trip_issues count", error);
      return 0;
    }
    return count ?? 0;
  } catch (e) {
    console.error("carrier.driver_trip_issues count (threw)", e);
    return 0;
  }
}

async function lastPing(dispatchId: string): Promise<string | null> {
  try {
    const snapshot = await getTelematicsSnapshot(dispatchId, "carrier");
    const pos = snapshot?.latest_position as { reported_at?: string } | null;
    return pos?.reported_at ?? null;
  } catch (e) {
    console.error("carrier.telematics snapshot (threw)", e);
    return null;
  }
}
