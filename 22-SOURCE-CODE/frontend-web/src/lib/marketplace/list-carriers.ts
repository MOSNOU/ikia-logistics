import { createClient } from "@/lib/supabase/server";
import type {
  CarrierProfileStatus,
  CarrierSummary,
  TransportMode,
} from "@/types/database";

export type CarrierAudience = "buyer" | "admin";

export interface ListCarriersParams {
  countryCode?: string | null;
  transportMode?: TransportMode | null;
  search?: string | null;
  status?: CarrierProfileStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListCarriersResult {
  rows: CarrierSummary[];
  page: number;
  pageSize: number;
}

// CC-40: backed by marketplace.buyer_list_carriers (buyer/supplier audience —
// public + active carriers only) or marketplace.admin_list_carriers (admin
// audience — sees all carriers regardless of visibility/status).
export async function listCarriers(
  audience: CarrierAudience = "buyer",
  {
    countryCode = null,
    transportMode = null,
    search = null,
    status = null,
    page = 0,
    pageSize = 25,
  }: ListCarriersParams = {},
): Promise<ListCarriersResult> {
  const supabase = await createClient();

  if (audience === "admin") {
    const { data, error } = await supabase
      .schema("marketplace")
      .rpc("admin_list_carriers", {
        p_status: status ?? undefined,
        p_search: search ?? undefined,
        p_limit: pageSize,
        p_offset: page * pageSize,
      });
    if (error) {
      console.error("marketplace.admin_list_carriers", error);
      return { rows: [], page, pageSize };
    }
    return {
      rows: (data ?? []) as unknown as CarrierSummary[],
      page,
      pageSize,
    };
  }

  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("buyer_list_carriers", {
      p_country: countryCode ?? undefined,
      p_transport_mode: transportMode ?? undefined,
      p_search: search ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("marketplace.buyer_list_carriers", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as CarrierSummary[],
    page,
    pageSize,
  };
}

export async function getCarrier(
  carrierId: string,
  audience: CarrierAudience = "buyer",
): Promise<CarrierSummary | null> {
  const supabase = await createClient();
  const rpc = audience === "admin" ? "admin_get_carrier" : "buyer_get_carrier";
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc(rpc, { p_carrier_id: carrierId });
  if (error || !data) {
    if (error) console.error(`marketplace.${rpc}`, error);
    return null;
  }
  return data as unknown as CarrierSummary;
}
