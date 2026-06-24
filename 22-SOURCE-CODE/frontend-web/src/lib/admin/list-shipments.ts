import { createClient } from "@/lib/supabase/server";
import type { ShipmentListRow, ShipmentStatus } from "@/types/database";

export interface ListAdminShipmentsParams {
  status?: ShipmentStatus | null;
  executedContractId?: string | null;
  supplierId?: string | null;
  page?: number;
  pageSize?: number;
}

export async function listAdminShipments({
  status = null,
  executedContractId = null,
  supplierId = null,
  page = 0,
  pageSize = 25,
}: ListAdminShipmentsParams = {}): Promise<{
  rows: ShipmentListRow[];
  page: number;
  pageSize: number;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("admin_list_shipments", {
      p_status: status ?? undefined,
      p_executed_contract_id: executedContractId ?? undefined,
      p_supplier_id: supplierId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("admin_list_shipments", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ShipmentListRow[],
    page,
    pageSize,
  };
}
