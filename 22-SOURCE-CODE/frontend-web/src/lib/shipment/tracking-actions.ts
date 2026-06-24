"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type {
  ShipmentMilestoneStatus,
  ShipmentMilestoneType,
  ShipmentStopType,
} from "@/types/database";

export interface TrackingActionState {
  error?: string;
  ok?: boolean;
}

function revalidateTracking(id: string) {
  revalidatePath("/buyer/shipments");
  revalidatePath(`/buyer/shipments/${id}`);
  revalidatePath(`/buyer/shipments/${id}/tracking`);
  revalidatePath(`/supplier/shipments/${id}/tracking`);
  revalidatePath(`/admin/shipments/${id}/tracking`);
}

const MILESTONE_TYPES: ShipmentMilestoneType[] = [
  "booking_confirmed",
  "cargo_ready",
  "pickup_completed",
  "customs_export_cleared",
  "departed_origin",
  "border_crossed",
  "arrived_destination",
  "customs_import_cleared",
  "delivered",
  "closed",
  "other",
];

const MILESTONE_STATUSES: ShipmentMilestoneStatus[] = [
  "pending",
  "in_progress",
  "completed",
  "skipped",
  "blocked",
];

const STOP_TYPES: ShipmentStopType[] = [
  "pickup",
  "loading",
  "border",
  "transshipment",
  "customs",
  "unloading",
  "delivery",
  "other",
];

export async function buyerUpsertMilestone(
  _prev: TrackingActionState | null,
  formData: FormData,
): Promise<TrackingActionState> {
  const shipmentId = String(formData.get("shipmentId") ?? "");
  const milestoneType = String(formData.get("milestoneType") ?? "") as ShipmentMilestoneType;
  const status = (formData.get("status") as string | null) as
    | ShipmentMilestoneStatus
    | null;
  const plannedAt = (formData.get("plannedAt") as string | null) || undefined;
  const completedAt = (formData.get("completedAt") as string | null) || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;

  if (!shipmentId) return { error: "شناسه محموله نامعتبر" };
  if (!MILESTONE_TYPES.includes(milestoneType)) return { error: "نوع نقطه عطف نامعتبر" };
  if (status && !MILESTONE_STATUSES.includes(status)) {
    return { error: "وضعیت نقطه عطف نامعتبر" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_milestone", {
      p_shipment_id: shipmentId,
      p_milestone_type: milestoneType,
      p_status: status ?? undefined,
      p_planned_at: plannedAt,
      p_completed_at: completedAt,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_milestone", error);
    return { error: "ثبت نقطه عطف ناموفق بود" };
  }
  revalidateTracking(shipmentId);
  return { ok: true };
}

export async function buyerUpsertStop(
  _prev: TrackingActionState | null,
  formData: FormData,
): Promise<TrackingActionState> {
  const shipmentId = String(formData.get("shipmentId") ?? "");
  const sequenceRaw = formData.get("sequenceNumber");
  const stopType = String(formData.get("stopType") ?? "") as ShipmentStopType;
  const city = (formData.get("city") as string | null)?.trim() || undefined;
  const country = (formData.get("country") as string | null)?.trim() || undefined;
  const port = (formData.get("port") as string | null)?.trim() || undefined;
  const locationText = (formData.get("locationText") as string | null)?.trim() || undefined;
  const plannedArrivalAt = (formData.get("plannedArrivalAt") as string | null) || undefined;
  const plannedDepartureAt = (formData.get("plannedDepartureAt") as string | null) || undefined;
  const actualArrivalAt = (formData.get("actualArrivalAt") as string | null) || undefined;
  const actualDepartureAt = (formData.get("actualDepartureAt") as string | null) || undefined;
  const notes = (formData.get("notes") as string | null)?.trim() || undefined;

  if (!shipmentId) return { error: "شناسه محموله نامعتبر" };
  if (!STOP_TYPES.includes(stopType)) return { error: "نوع توقف نامعتبر" };
  const sequenceNumber = sequenceRaw ? Number(sequenceRaw) : NaN;
  if (!Number.isFinite(sequenceNumber) || sequenceNumber < 1) {
    return { error: "شماره ترتیب الزامی است و باید ≥ 1 باشد" };
  }

  const supabase = await createClient();
  const { error } = await supabase
    .schema("shipment")
    .rpc("buyer_upsert_stop", {
      p_shipment_id: shipmentId,
      p_sequence_number: sequenceNumber,
      p_stop_type: stopType,
      p_city: city,
      p_country: country,
      p_port: port,
      p_location_text: locationText,
      p_planned_arrival_at: plannedArrivalAt,
      p_planned_departure_at: plannedDepartureAt,
      p_actual_arrival_at: actualArrivalAt,
      p_actual_departure_at: actualDepartureAt,
      p_notes: notes,
    });
  if (error) {
    console.error("buyer_upsert_stop", error);
    return { error: "ثبت توقف ناموفق بود" };
  }
  revalidateTracking(shipmentId);
  return { ok: true };
}
