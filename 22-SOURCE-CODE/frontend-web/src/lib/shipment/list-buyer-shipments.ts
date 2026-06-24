import { createClient } from "@/lib/supabase/server";
import type { ShipmentListRow, ShipmentStatus } from "@/types/database";

export interface ListBuyerShipmentsParams {
  status?: ShipmentStatus | null;
  executedContractId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListBuyerShipmentsResult {
  rows: ShipmentListRow[];
  page: number;
  pageSize: number;
}

export async function listBuyerShipments({
  status = null,
  executedContractId = null,
  page = 0,
  pageSize = 25,
}: ListBuyerShipmentsParams = {}): Promise<ListBuyerShipmentsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("buyer_list_shipments", {
      p_status: status ?? undefined,
      p_executed_contract_id: executedContractId ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("buyer_list_shipments", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as ShipmentListRow[],
    page,
    pageSize,
  };
}
