import { createClient } from "@/lib/supabase/server";
import type {
  TelematicsActiveSession,
  TelematicsPosition,
  TelematicsSnapshot,
} from "@/types/database";

export type TelematicsAudience = "buyer" | "carrier" | "admin";

interface SnapshotPayload {
  dispatch_id: string;
  latest_position: TelematicsPosition | null;
  recent_events: TelematicsSnapshot["recent_events"];
}

export async function getTelematicsSnapshot(
  dispatchId: string,
  audience: TelematicsAudience,
): Promise<TelematicsSnapshot | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_telemetry_snapshot"
      : audience === "carrier"
        ? "carrier_get_telemetry_snapshot"
        : "admin_get_telemetry_snapshot";
  const { data, error } = await supabase
    .schema("telematics")
    .rpc(rpc, { p_dispatch_id: dispatchId });
  if (error || !data) {
    if (error) console.error(`telematics.${rpc}`, error);
    return null;
  }
  return data as unknown as SnapshotPayload;
}

export interface ListPositionsParams {
  since?: string | null;
  limit?: number;
  offset?: number;
}

export async function listPositions(
  dispatchId: string,
  audience: TelematicsAudience,
  { since = null, limit = 500, offset = 0 }: ListPositionsParams = {},
): Promise<TelematicsPosition[]> {
  const supabase = await createClient();
  if (audience === "carrier") {
    const { data, error } = await supabase
      .schema("telematics")
      .rpc("carrier_list_my_positions", {
        p_dispatch_id: dispatchId,
        p_limit: limit,
        p_offset: offset,
      });
    if (error) {
      console.error("telematics.carrier_list_my_positions", error);
      return [];
    }
    return (data ?? []) as unknown as TelematicsPosition[];
  }
  const rpc = audience === "buyer" ? "buyer_list_positions" : "admin_list_positions";
  const { data, error } = await supabase
    .schema("telematics")
    .rpc(rpc, {
      p_dispatch_id: dispatchId,
      p_since: since ?? undefined,
      p_limit: limit,
      p_offset: offset,
    });
  if (error) {
    console.error(`telematics.${rpc}`, error);
    return [];
  }
  return (data ?? []) as unknown as TelematicsPosition[];
}

export async function listActiveSessions({
  limit = 100,
  offset = 0,
}: { limit?: number; offset?: number } = {}): Promise<TelematicsActiveSession[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("telematics")
    .rpc("admin_list_active_sessions", { p_limit: limit, p_offset: offset });
  if (error) {
    console.error("telematics.admin_list_active_sessions", error);
    return [];
  }
  return (data ?? []) as unknown as TelematicsActiveSession[];
}
