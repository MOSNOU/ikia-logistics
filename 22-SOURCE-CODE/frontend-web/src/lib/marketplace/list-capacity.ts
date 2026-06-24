import { createClient } from "@/lib/supabase/server";
import type {
  CapacityListing,
  CapacityStatus,
  TransportMode,
} from "@/types/database";

export type CapacityAudience = "buyer" | "supplier" | "admin";

export interface ListCapacityParams {
  transportMode?: TransportMode | null;
  originCountry?: string | null;
  destinationCountry?: string | null;
  carrierId?: string | null;
  status?: CapacityStatus | null;
  carrierOrganizationId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListCapacityResult {
  rows: CapacityListing[];
  available: boolean;
  note: string;
}

// CC-40: backed by marketplace.buyer_list_capacity (buyers see active + public
// only) / marketplace.supplier_list_my_capacity (carrier-org owners) /
// marketplace.admin_list_capacity (cross-tenant). Supplier audience requires
// a carrier_organization_id; absent it the call short-circuits to an empty
// list with a Persian explanation rather than failing the page.
export async function listCapacity(
  audience: CapacityAudience = "buyer",
  {
    transportMode = null,
    originCountry = null,
    destinationCountry = null,
    carrierId = null,
    status = null,
    carrierOrganizationId = null,
    page = 0,
    pageSize = 25,
  }: ListCapacityParams = {},
): Promise<ListCapacityResult> {
  const supabase = await createClient();

  if (audience === "admin") {
    const { data, error } = await supabase
      .schema("marketplace")
      .rpc("admin_list_capacity", {
        p_status: status ?? undefined,
        p_carrier_id: carrierId ?? undefined,
        p_limit: pageSize,
        p_offset: page * pageSize,
      });
    if (error) {
      console.error("marketplace.admin_list_capacity", error);
      return {
        rows: [],
        available: false,
        note: "خطا در دریافت فهرست ظرفیت‌ها.",
      };
    }
    return {
      rows: (data ?? []) as unknown as CapacityListing[],
      available: true,
      note: "",
    };
  }

  if (audience === "supplier") {
    if (!carrierOrganizationId) {
      return {
        rows: [],
        available: false,
        note: "برای نمایش ظرفیت‌های منتشرشده، سازمان حمل‌کننده در دسترس نیست.",
      };
    }
    const { data, error } = await supabase
      .schema("marketplace")
      .rpc("supplier_list_my_capacity", {
        p_carrier_organization_id: carrierOrganizationId,
        p_status: status ?? undefined,
        p_limit: pageSize,
        p_offset: page * pageSize,
      });
    if (error) {
      console.error("marketplace.supplier_list_my_capacity", error);
      return {
        rows: [],
        available: false,
        note: "خطا در دریافت ظرفیت‌های شما.",
      };
    }
    return {
      rows: (data ?? []) as unknown as CapacityListing[],
      available: true,
      note: "",
    };
  }

  const { data, error } = await supabase
    .schema("marketplace")
    .rpc("buyer_list_capacity", {
      p_transport_mode: transportMode ?? undefined,
      p_origin_country: originCountry ?? undefined,
      p_destination_country: destinationCountry ?? undefined,
      p_carrier_id: carrierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("marketplace.buyer_list_capacity", error);
    return {
      rows: [],
      available: false,
      note: "خطا در دریافت فهرست ظرفیت‌ها.",
    };
  }
  return {
    rows: (data ?? []) as unknown as CapacityListing[],
    available: true,
    note: "",
  };
}
