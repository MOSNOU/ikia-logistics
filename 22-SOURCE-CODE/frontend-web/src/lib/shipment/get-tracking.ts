import type {
  ShipmentDetail,
  ShipmentEventRow,
  ShipmentMilestoneRow,
  ShipmentStopRow,
  TrackingTimelineRow,
} from "@/types/database";
import { getShipment, type ShipmentAudience } from "./get-shipment";
import { listShipmentEvents } from "@/lib/admin/list-shipment-events";

export interface TrackingBundle {
  shipment: ShipmentDetail["shipment"];
  milestones: ShipmentMilestoneRow[];
  stops: ShipmentStopRow[];
  events: ShipmentEventRow[];
  timeline: TrackingTimelineRow[];
}

// Build the chronological merge used by the timeline (Q3=A).
function buildTimeline(
  milestones: ShipmentMilestoneRow[],
  stops: ShipmentStopRow[],
  events: ShipmentEventRow[],
): TrackingTimelineRow[] {
  const rows: TrackingTimelineRow[] = [];

  for (const m of milestones) {
    const at = m.completed_at ?? m.planned_at ?? m.created_at;
    rows.push({
      kind: "milestone",
      id: m.id,
      at,
      label: m.milestone_type,
      status: m.status,
      notes: m.notes,
      raw_milestone: m,
    });
  }

  for (const s of stops) {
    const at =
      s.actual_arrival_at ??
      s.planned_arrival_at ??
      s.actual_departure_at ??
      s.planned_departure_at ??
      s.created_at;
    rows.push({
      kind: "stop",
      id: s.id,
      at,
      label: s.stop_type,
      notes: s.notes,
      raw_stop: s,
    });
  }

  for (const e of events) {
    rows.push({
      kind: "status_event",
      id: e.id,
      at: e.created_at,
      label: e.event_type,
      status: e.to_status ?? undefined,
      notes: e.reason,
      actor_user_id: e.actor_user_id,
      raw_event: e,
    });
  }

  rows.sort((a, b) => {
    const ax = a.at ? new Date(a.at).getTime() : 0;
    const bx = b.at ? new Date(b.at).getTime() : 0;
    return ax - bx;
  });

  return rows;
}

export async function getTracking(
  shipmentId: string,
  audience: ShipmentAudience,
): Promise<TrackingBundle | null> {
  const detail = await getShipment(shipmentId, audience);
  if (!detail) return null;

  const milestones = (detail.milestones ?? []) as ShipmentMilestoneRow[];
  const stops = (detail.stops ?? []) as ShipmentStopRow[];

  // Admin gets full event audit via the dedicated admin RPC even if the
  // get_shipment jsonb didn't bundle them.
  let events: ShipmentEventRow[] = (detail.events ?? []) as ShipmentEventRow[];
  if (audience === "admin" && events.length === 0) {
    events = await listShipmentEvents(shipmentId);
  }

  const timeline = buildTimeline(milestones, stops, events);

  return {
    shipment: detail.shipment,
    milestones,
    stops,
    events,
    timeline,
  };
}
