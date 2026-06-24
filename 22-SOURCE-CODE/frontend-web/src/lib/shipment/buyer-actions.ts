"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  ShipmentDocumentKind,
  ShipmentTransportMode,
} from "@/types/database";

export interface ShipmentActionState {
  error?: string;
  ok?: boolean;
}

function revalidateBuyer(id: string) {
  revalidatePath("/buyer/shipments");
  revalidatePath(`/buyer/shipments/${id}`);
  revalidatePath("/supplier/shipments");
  revalidatePath(`/supplier/shipments/${id}`);
  revalidatePath("/admin/shipments");
  revalidatePath(`/admin/shipments/${id}`);
}

export async function buyerCreateShipment(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const executedContractId = String(formData.get("executedContractId") ?? "");
  const mode = (formData.get("transportMode") as string | null)?.trim() as
    | ShipmentTransportMode
    | undefined;
  const plannedPickup = (formData.get("plannedPickupDate") as string | null) || undefined;
  const plannedDelivery = (formData.get("plannedDeliveryDate") as string | null) || undefined;
  const originCountry = (formData.get("originCountry") as string | null)?.trim() || undefined;
  const originCity = (formData.get("originCity") as string | null)?.trim() || undefined;
  const destinationCountry = (formData.get("destinationCountry") as string | null)?.trim() || undefined;
  const destinationCity = (formData.get("destinationCity") as string | null)?.trim() || undefined;
  const incoterm = (formData.get("incoterm") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;

  if (!executedContractId) return { error: "شناسه قرارداد اجرایی نامعتبر" };

  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("shipment")
    .rpc("buyer_create_shipment", {
      p_executed_contract_id: executedContractId,
      p_transport_mode: mode,
      p_planned_pickup_date: plannedPickup,
      p_planned_delivery_date: plannedDelivery,
      p_origin_country: originCountry,
      p_origin_city: originCity,
      p_destination_country: destinationCountry,
      p_destination_city: destinationCity,
      p_incoterm: incoterm,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_create_shipment", error);
    return { error: "ایجاد محموله ناموفق بود" };
  }
  revalidatePath("/buyer/shipments");
  redirect(`/buyer/shipments/${data}`);
}

export async function buyerUpdateShipment(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_update_shipment", {
      p_shipment_id: id,
      p_carrier_name: (formData.get("carrierName") as string | null) || undefined,
      p_tracking_reference: (formData.get("trackingReference") as string | null) || undefined,
      p_vehicle_reference: (formData.get("vehicleReference") as string | null) || undefined,
      p_notes: (formData.get("notes") as string | null) || undefined,
    });
  if (error) {
    console.error("buyer_update_shipment", error);
    return { error: "ذخیره ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerUpsertDocRequirement(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const shipmentId = String(formData.get("shipmentId") ?? "");
  const docKind = String(formData.get("documentKind") ?? "") as ShipmentDocumentKind;
  const reqLevel = (formData.get("requirementLevel") as string | null)?.trim() || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!shipmentId) return { error: "شناسه محموله نامعتبر" };
  if (!docKind) return { error: "نوع مدرک الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_doc_requirement", {
      p_shipment_id: shipmentId,
      p_document_kind: docKind,
      p_requirement_level: reqLevel as "required" | "recommended" | "optional" | undefined,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_doc_requirement", error);
    return { error: "ثبت نیازمندی مدرک ناموفق بود" };
  }
  revalidateBuyer(shipmentId);
  return { ok: true };
}

export async function buyerUpsertDocument(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const shipmentId = String(formData.get("shipmentId") ?? "");
  const docKind = String(formData.get("documentKind") ?? "") as ShipmentDocumentKind;
  const externalRef = (formData.get("externalReference") as string | null)?.trim() || undefined;
  const issuedAt = (formData.get("issuedAt") as string | null) || undefined;
  const expiresAt = (formData.get("expiresAt") as string | null) || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;
  if (!shipmentId) return { error: "شناسه محموله نامعتبر" };
  if (!docKind) return { error: "نوع مدرک الزامی است" };

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_document", {
      p_shipment_id: shipmentId,
      p_document_kind: docKind,
      p_external_reference: externalRef,
      p_issued_at: issuedAt,
      p_expires_at: expiresAt,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_document", error);
    return { error: "ثبت مدرک ناموفق بود" };
  }
  revalidateBuyer(shipmentId);
  return { ok: true };
}

// =============================================================================
// Status-transition actions
// =============================================================================

export async function buyerMarkPlanned(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_mark_planned", { p_shipment_id: id });
  if (error) {
    console.error("buyer_mark_planned", error);
    return { error: "علامت‌گذاری برنامه‌ریزی‌شده ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerMarkBooked(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  const carrierName = (formData.get("carrierName") as string | null)?.trim() || undefined;
  const trackingReference = (formData.get("trackingReference") as string | null)?.trim() || undefined;
  const vehicleReference = (formData.get("vehicleReference") as string | null)?.trim() || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_mark_booked", {
      p_shipment_id: id,
      p_carrier_name: carrierName,
      p_tracking_reference: trackingReference,
      p_vehicle_reference: vehicleReference,
    });
  if (error) {
    console.error("buyer_mark_booked", error);
    return { error: "ثبت رزرو ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerMarkInTransit(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_mark_in_transit", { p_shipment_id: id });
  if (error) {
    console.error("buyer_mark_in_transit", error);
    return { error: "علامت‌گذاری در حال حمل ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerMarkArrived(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_mark_arrived", { p_shipment_id: id });
  if (error) {
    console.error("buyer_mark_arrived", error);
    return { error: "علامت‌گذاری رسیده ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerMarkDelivered(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_mark_delivered", { p_shipment_id: id });
  if (error) {
    console.error("buyer_mark_delivered", error);
    return { error: "علامت‌گذاری تحویل‌شده ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}

export async function buyerCancelShipment(
  _prev: ShipmentActionState | null,
  formData: FormData,
): Promise<ShipmentActionState> {
  const id = String(formData.get("shipmentId") ?? "");
  const reason = (formData.get("reason") as string | null) || undefined;
  if (!id) return { error: "شناسه نامعتبر" };
  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_cancel_shipment", { p_shipment_id: id, p_reason: reason });
  if (error) {
    console.error("buyer_cancel_shipment", error);
    return { error: "لغو محموله ناموفق بود" };
  }
  revalidateBuyer(id);
  return { ok: true };
}
