import { createClient } from "@/lib/supabase/server";
import type {
  ShipmentDocumentKind,
} from "@/types/database";

export interface DocRequirementRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  shipment_id: string;
  document_kind: ShipmentDocumentKind;
  requirement_level: "required" | "recommended" | "optional";
  display_name_en: string | null;
  display_name_fa: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

const PROJECTION =
  "id, tenant_id, organization_id, shipment_id, document_kind, requirement_level, display_name_en, display_name_fa, notes, created_at, updated_at, deleted_at";

export async function listShipmentDocumentRequirements(
  shipmentId: string,
): Promise<DocRequirementRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .from("shipment_document_requirements")
    .select(PROJECTION)
    .eq("shipment_id", shipmentId)
    .is("deleted_at", null)
    .order("document_kind", { ascending: true });
  if (error) {
    console.error("list document requirements", error);
    return [];
  }
  return (data ?? []) as unknown as DocRequirementRow[];
}

export async function getShipmentDocumentRequirement(
  requirementId: string,
): Promise<DocRequirementRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .from("shipment_document_requirements")
    .select(PROJECTION)
    .eq("id", requirementId)
    .is("deleted_at", null)
    .maybeSingle();
  if (error) {
    console.error("get document requirement", error);
    return null;
  }
  return (data ?? null) as unknown as DocRequirementRow | null;
}
