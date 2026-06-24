import { createClient } from "@/lib/supabase/server";
import type { ShipmentListRow, ShipmentStatus } from "@/types/database";

export interface ListSupplierShipmentsParams {
  status?: ShipmentStatus | null;
  page?: number;
  pageSize?: number;
}

export async function listSupplierShipments({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierShipmentsParams = {}): Promise<{
  rows: ShipmentListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("supplier_list_my_shipments", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_shipments", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ShipmentListRow[],
    page,
    pageSize,
  };
}
