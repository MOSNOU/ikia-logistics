import { createClient } from "@/lib/supabase/server";
import type {
  ShipmentStatus,
  SupplierShipmentDocSummary,
} from "@/types/database";

export interface ListSupplierDocsParams {
  status?: ShipmentStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListSupplierDocsResult {
  rows: SupplierShipmentDocSummary[];
  page: number;
  pageSize: number;
}

// Supplier RLS on shipment_documents may not permit cross-shipment SELECT.
// Surface supplier's shipments via the existing RPC and link to the
// per-shipment view (which CC-31 already wires) for full document inspection.
export async function listSupplierTradeDocuments({
  status = null,
  page = 0,
  pageSize = 25,
}: ListSupplierDocsParams = {}): Promise<ListSupplierDocsResult> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("supplier_list_my_shipments", {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error("supplier_list_my_shipments (trade-documents)", error);
    return { rows: [], page, pageSize };
  }
  const rows = ((data ?? []) as unknown as Array<{
    id: string;
    shipment_code: string;
    status: ShipmentStatus;
    transport_mode: string | null;
    executed_contract_id: string;
    updated_at: string;
  }>).map<SupplierShipmentDocSummary>((s) => ({
    shipment_id: s.id,
    shipment_code: s.shipment_code,
    status: s.status,
    transport_mode: (s.transport_mode ?? null) as
      | SupplierShipmentDocSummary["transport_mode"],
    executed_contract_id: s.executed_contract_id,
    updated_at: s.updated_at,
  }));
  return { rows, page, pageSize };
}
