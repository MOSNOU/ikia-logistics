import { createClient } from "@/lib/supabase/server";
import type {
  MarketplaceKpiBundle,
  TransportMode,
} from "@/types/database";
import { listAdminShipments } from "@/lib/admin/list-shipments";
import { listBuyerShipments } from "@/lib/shipment/list-buyer-shipments";
import { listSupplierShipments } from "@/lib/shipment/list-supplier-shipments";

export type MarketplaceAudience = "buyer" | "supplier" | "admin";

const TRANSPORT_MODES: TransportMode[] = [
  "road",
  "rail",
  "sea",
  "air",
  "multimodal",
  "pipeline",
  "other",
];

interface AdminCapacitySummary {
  total?: number;
  by_mode?: Array<{ mode: string; count: number }>;
  by_status?: Array<{ status: string; count: number }>;
}

async function buyerCarrierCount(): Promise<{ count: number; available: boolean }> {
  const supabase = await createClient();
  // Buyer-visible directory is public+active only; counting via the RPC keeps
  // the KPI in sync with what the carrier-list page actually surfaces.
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("buyer_list_carriers", { p_limit: 1000, p_offset: 0 });
  if (error) {
    console.error("marketplace.buyer_list_carriers (count)", error);
    return { count: 0, available: false };
  }
  return { count: (data ?? []).length, available: true };
}

async function adminCarrierCount(): Promise<{ count: number; available: boolean }> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("admin_list_carriers", { p_limit: 1000, p_offset: 0 });
  if (error) {
    console.error("marketplace.admin_list_carriers (count)", error);
    return { count: 0, available: false };
  }
  return { count: (data ?? []).length, available: true };
}

async function adminCapacitySummary(): Promise<AdminCapacitySummary | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("admin_capacity_summary");
  if (error || !data) {
    if (error) console.error("marketplace.admin_capacity_summary", error);
    return null;
  }
  return data as unknown as AdminCapacitySummary;
}

async function buyerCapacityCount(): Promise<{ count: number; available: boolean }> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("buyer_list_capacity", { p_limit: 1000, p_offset: 0 });
  if (error) {
    console.error("marketplace.buyer_list_capacity (count)", error);
    return { count: 0, available: false };
  }
  return { count: (data ?? []).length, available: true };
}

async function supplierCapacityCount(
  carrierOrganizationId: string | null,
): Promise<{ count: number; available: boolean }> {
  if (!carrierOrganizationId) return { count: 0, available: false };
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("supplier_list_my_capacity", {
      p_carrier_organization_id: carrierOrganizationId,
      p_limit: 1000,
      p_offset: 0,
    });
  if (error) {
    console.error("marketplace.supplier_list_my_capacity (count)", error);
    return { count: 0, available: false };
  }
  return { count: (data ?? []).length, available: true };
}

export interface MarketplaceKpiInput {
  carrierOrganizationId?: string | null;
}

// CC-40: replaces the CC-38 stub (which used a direct
// `organization.organizations` SELECT and a hard-coded capacityListings=0).
// Carrier and capacity counts now come from marketplace.* RPCs.
// shipmentsByMode + recentShipmentCount continue to draw from the existing
// shipment list loaders since CC-39 introduced no shipment-side surface.
export async function listMarketplaceKpis(
  audience: MarketplaceAudience,
  input: MarketplaceKpiInput = {},
): Promise<MarketplaceKpiBundle> {
  const PAGE = 200;

  if (audience === "admin") {
    const [carriers, summary, shipments] = await Promise.all([
      adminCarrierCount(),
      adminCapacitySummary(),
      listAdminShipments({ pageSize: PAGE }),
    ]);

    const modeCounts = new Map<string, number>();
    for (const s of shipments.rows) {
      const m = s.transport_mode ?? "unknown";
      modeCounts.set(m, (modeCounts.get(m) ?? 0) + 1);
    }
    const shipmentsByMode: MarketplaceKpiBundle["shipmentsByMode"] = TRANSPORT_MODES.map(
      (m) => ({ mode: m, count: modeCounts.get(m) ?? 0 }),
    );
    const unknownCount = modeCounts.get("unknown") ?? 0;
    if (unknownCount > 0) shipmentsByMode.push({ mode: "unknown", count: unknownCount });

    return {
      carriers,
      capacityListings: {
        count: summary?.total ?? 0,
        available: summary !== null,
      },
      shipmentsByMode,
      recentShipmentCount: shipments.rows.length,
      available: carriers.available,
    };
  }

  const shipmentsPromise =
    audience === "buyer"
      ? listBuyerShipments({ pageSize: PAGE })
      : listSupplierShipments({ pageSize: PAGE });

  const [carriers, capacityCount, shipments] = await Promise.all([
    buyerCarrierCount(),
    audience === "buyer"
      ? buyerCapacityCount()
      : supplierCapacityCount(input.carrierOrganizationId ?? null),
    shipmentsPromise,
  ]);

  const modeCounts = new Map<string, number>();
  for (const s of shipments.rows) {
    const m = s.transport_mode ?? "unknown";
    modeCounts.set(m, (modeCounts.get(m) ?? 0) + 1);
  }
  const shipmentsByMode: MarketplaceKpiBundle["shipmentsByMode"] = TRANSPORT_MODES.map(
    (m) => ({ mode: m, count: modeCounts.get(m) ?? 0 }),
  );
  const unknownCount = modeCounts.get("unknown") ?? 0;
  if (unknownCount > 0) shipmentsByMode.push({ mode: "unknown", count: unknownCount });

  return {
    carriers,
    capacityListings: capacityCount,
    shipmentsByMode,
    recentShipmentCount: shipments.rows.length,
    available: carriers.available,
  };
}
