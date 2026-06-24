import { createClient } from "@/lib/supabase/server";
import type {
  ShipmentDocumentKind,
  ShipmentDocumentStatus,
  TradeDocumentRow,
} from "@/types/database";

export interface ListAdminDocumentsParams {
  documentKind?: ShipmentDocumentKind | null;
  documentStatus?: ShipmentDocumentStatus | null;
  organizationId?: string | null;
  shipmentId?: string | null;
  page?: number;
  pageSize?: number;
}

export interface ListAdminDocumentsResult {
  rows: TradeDocumentRow[];
  page: number;
  pageSize: number;
}

const SHIPMENT_DOCUMENT_PROJECTION =
  "id, tenant_id, organization_id, shipment_id, shipment_item_id, requirement_id, document_kind, document_status, external_reference, issued_at, expires_at, notes, metadata, created_at, updated_at, deleted_at, version, shipments(id, shipment_code, status, supplier_id, executed_contract_id, organization_id, transport_mode)";

export async function listAdminTradeDocuments({
  documentKind = null,
  documentStatus = null,
  organizationId = null,
  shipmentId = null,
  page = 0,
  pageSize = 25,
}: ListAdminDocumentsParams = {}): Promise<ListAdminDocumentsResult> {
  const supabase = await createClient();
  let query = supabase
    .schema("shipment")
    .from("shipment_documents")
    .select(SHIPMENT_DOCUMENT_PROJECTION)
    .is("deleted_at", null);
  if (documentKind) query = query.eq("document_kind", documentKind);
  if (documentStatus) query = query.eq("document_status", documentStatus);
  if (organizationId) query = query.eq("organization_id", organizationId);
  if (shipmentId) query = query.eq("shipment_id", shipmentId);
  const { data, error } = await query
    .order("created_at", { ascending: false })
    .range(page * pageSize, page * pageSize + pageSize - 1);
  if (error) {
    console.error("admin list trade documents", error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as TradeDocumentRow[],
    page,
    pageSize,
  };
}

export async function getAdminTradeDocument(
  documentId: string,
): Promise<TradeDocumentRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .from("shipment_documents")
    .select(SHIPMENT_DOCUMENT_PROJECTION)
    .eq("id", documentId)
    .is("deleted_at", null)
    .maybeSingle();
  if (error) {
    console.error("admin get trade document", error);
    return null;
  }
  return (data ?? null) as unknown as TradeDocumentRow | null;
}
