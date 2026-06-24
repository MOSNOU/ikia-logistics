"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import {
  parseDocumentForm,
  parseRequirementForm,
} from "./schemas";

export interface TradeDocActionState {
  ok?: boolean;
  error?: string;
  fieldErrors?: Record<string, string>;
}

function revalidateForShipment(shipmentId: string, documentId?: string) {
  revalidatePath("/buyer/shipments");
  revalidatePath(`/buyer/shipments/${shipmentId}`);
  revalidatePath(`/buyer/shipments/${shipmentId}/requirements`);
  revalidatePath("/buyer/documents");
  if (documentId) {
    revalidatePath(`/buyer/documents/${documentId}`);
    revalidatePath(`/buyer/documents/${documentId}/edit`);
    revalidatePath(`/buyer/documents/${documentId}/files`);
  }
  revalidatePath("/supplier/trade-documents");
  revalidatePath(`/supplier/shipments/${shipmentId}`);
  revalidatePath("/admin/documents");
}

export async function upsertDocRequirement(
  _prev: TradeDocActionState | null,
  formData: FormData,
): Promise<TradeDocActionState> {
  const parsed = parseRequirementForm(formData);
  if (!parsed.ok) return { error: parsed.error, fieldErrors: parsed.fieldErrors };
  const { shipmentId, documentKind, requirementLevel, displayNameEn, displayNameFa, notes } =
    parsed.value;

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_doc_requirement", {
      p_shipment_id: shipmentId,
      p_document_kind: documentKind,
      p_requirement_level: requirementLevel,
      p_display_name_en: displayNameEn,
      p_display_name_fa: displayNameFa,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_doc_requirement", error);
    return { error: "ثبت نیازمندی مدرک ناموفق بود" };
  }
  revalidateForShipment(shipmentId);
  return { ok: true };
}

export async function upsertBuyerDocument(
  _prev: TradeDocActionState | null,
  formData: FormData,
): Promise<TradeDocActionState> {
  const parsed = parseDocumentForm(formData);
  if (!parsed.ok) return { error: parsed.error, fieldErrors: parsed.fieldErrors };
  const {
    shipmentId,
    documentKind,
    documentStatus,
    requirementId,
    shipmentItemId,
    externalReference,
    issuedAt,
    expiresAt,
    notes,
    documentId,
  } = parsed.value;

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_document", {
      p_shipment_id: shipmentId,
      p_document_kind: documentKind,
      p_document_status: documentStatus,
      p_requirement_id: requirementId,
      p_shipment_item_id: shipmentItemId,
      p_external_reference: externalReference,
      p_issued_at: issuedAt,
      p_expires_at: expiresAt,
      p_notes: notes,
      p_document_id: documentId,
    });
  if (error) {
    console.error("buyer_upsert_document", error);
    return { error: "ثبت مدرک ناموفق بود" };
  }
  const resultDocId = (typeof data === "string" ? data : documentId) ?? undefined;
  revalidateForShipment(shipmentId, resultDocId);
  return { ok: true };
}

export async function archiveBuyerDocument(
  _prev: TradeDocActionState | null,
  formData: FormData,
): Promise<TradeDocActionState> {
  const shipmentId = String(formData.get("shipmentId") ?? "");
  const documentId = String(formData.get("documentId") ?? "");
  const documentKind = String(formData.get("documentKind") ?? "");
  if (!shipmentId || !documentId || !documentKind) {
    return { error: "ورودی نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_document", {
      p_shipment_id: shipmentId,
      p_document_kind: documentKind as never,
      p_document_status: "archived",
      p_document_id: documentId,
    });
  if (error) {
    console.error("buyer_upsert_document (archive)", error);
    return { error: "بایگانی مدرک ناموفق بود" };
  }
  revalidateForShipment(shipmentId, documentId);
  return { ok: true };
}
