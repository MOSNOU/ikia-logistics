import { createClient } from "@/lib/supabase/server";
import type {
  ControlTowerActivityRow,
  ControlTowerAdminSummary,
  ControlTowerBuyerSummary,
  ControlTowerCarrierSummary,
  ControlTowerExceptionRow,
} from "@/types/database";

export async function loadBuyerSummary(): Promise<ControlTowerBuyerSummary | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("public")
    .rpc("control_tower_buyer_summary");
  if (error || !data) {
    if (error) console.error("control_tower_buyer_summary", error);
    return null;
  }
  return data as unknown as ControlTowerBuyerSummary;
}

export async function loadCarrierSummary(): Promise<ControlTowerCarrierSummary | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("public")
    .rpc("control_tower_carrier_summary");
  if (error || !data) {
    if (error) console.error("control_tower_carrier_summary", error);
    return null;
  }
  return data as unknown as ControlTowerCarrierSummary;
}

export async function loadAdminSummary(): Promise<ControlTowerAdminSummary | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("public")
    .rpc("control_tower_admin_summary");
  if (error || !data) {
    if (error) console.error("control_tower_admin_summary", error);
    return null;
  }
  return data as unknown as ControlTowerAdminSummary;
}

export async function loadAdminActivity({
  limit = 50,
  offset = 0,
}: { limit?: number; offset?: number } = {}): Promise<ControlTowerActivityRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("public")
    .rpc("control_tower_admin_activity", { p_limit: limit, p_offset: offset });
  if (error) {
    console.error("control_tower_admin_activity", error);
    return [];
  }
  return (data ?? []) as unknown as ControlTowerActivityRow[];
}

export async function loadAdminExceptions({
  limit = 100,
  offset = 0,
}: { limit?: number; offset?: number } = {}): Promise<ControlTowerExceptionRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("public")
    .rpc("control_tower_admin_exceptions", { p_limit: limit, p_offset: offset });
  if (error) {
    console.error("control_tower_admin_exceptions", error);
    return [];
  }
  return (data ?? []) as unknown as ControlTowerExceptionRow[];
}
