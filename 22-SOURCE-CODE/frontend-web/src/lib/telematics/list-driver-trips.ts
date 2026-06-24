import { createClient } from "@/lib/supabase/server";
import type {
  DispatchListRow,
  DispatchStatus,
  TelematicsCarrierSessionStatus,
  TelematicsStalenessStatus,
} from "@/types/database";

// CC-50 / CC-55 — Carrier-facing Driver Console trip list.
//
// Strategy:
//   1. Pull the carrier's dispatches via the existing CC-43 RPC
//      dispatch.carrier_list_my_dispatches.
//   2. Batch-resolve each dispatch's shipment_id + lane summary from
//      marketplace.booking_requests + marketplace.capacity_listings.
//   3. CC-55: in parallel with the booking fetch, call the CC-53 batch RPC
//      telematics.carrier_list_my_telemetry_session_statuses with the same
//      dispatch ids — one RPC call regardless of trip count. No per-trip
//      carrier_get_telemetry_snapshot fan-out. If the batch RPC errors,
//      the loader still returns the dispatch rows; telemetry fields stay
//      undefined and the UI renders «نامشخص».
//
// Everything is RLS-driven — no SECURITY DEFINER bypass and no new RPC
// contract. If a booking is invisible to the carrier (e.g. soft-deleted,
// foreign org), the dispatch still shows but its shipmentId / routeSummary
// remain null; the UI gates the "trip detail" link on shipmentId being set.

export interface DriverTrip {
  dispatchId: string;
  bookingRequestId: string;
  shipmentId: string | null;
  status: DispatchStatus;
  vehicleReference: string | null;
  driverName: string | null;
  plannedPickupAt: string | null;
  routeSummary: string | null;
  transportMode: string | null;
  // CC-55 telemetry session status (optional — present only when the
  // CC-53 batch RPC succeeds for this dispatch).
  sessionActive?: boolean;
  latestSessionStartedAt?: string | null;
  latestSessionEndedAt?: string | null;
  lastPositionAt?: string | null;
  lastLatitude?: number | null;
  lastLongitude?: number | null;
  lastAccuracyMeters?: number | null;
  lastSource?: string | null;
  lastEventType?: string | null;
  lastEventAt?: string | null;
  positionCount?: number;
  eventCount?: number;
  stalenessStatus?: TelematicsStalenessStatus;
}

export interface ListDriverTripsParams {
  limit?: number;
  offset?: number;
  status?: DispatchStatus | null;
}

export async function listDriverTrips({
  limit = 50,
  offset = 0,
  status = null,
}: ListDriverTripsParams = {}): Promise<DriverTrip[]> {
  const supabase = await createClient();

  const { data: dispatchesData, error: dispatchErr } = await supabase
    .schema("dispatch")
    .rpc("carrier_list_my_dispatches", {
      p_status: status ?? undefined,
      p_limit: limit,
      p_offset: offset,
    });
  if (dispatchErr) {
    console.error("driver_trips.carrier_list_my_dispatches", dispatchErr);
    return [];
  }

  const dispatches = ((dispatchesData ?? []) as unknown as DispatchListRow[]) ?? [];
  if (dispatches.length === 0) return [];

  const dispatchIds = dispatches.map((d) => d.id);
  const bookingIds = Array.from(
    new Set(dispatches.map((d) => d.booking_request_id).filter(Boolean)),
  );

  interface BookingEnrichment {
    shipmentId: string | null;
    capacityListingId: string | null;
  }
  const bookingById = new Map<string, BookingEnrichment>();
  const telemetryById = new Map<string, TelematicsCarrierSessionStatus>();

  // CC-55: run the booking fetch and the telemetry batch RPC in parallel —
  // both depend only on inputs we already have (booking ids / dispatch ids).
  // Each promise is independently fault-tolerant: a failure of either does
  // not block the other or the rest of the list rendering.
  const [bookingResult, telemetryResult] = await Promise.all([
    bookingIds.length > 0
      ? supabase
          .schema("marketplace")
          .from("booking_requests")
          .select("id, shipment_id, capacity_listing_id")
          .in("id", bookingIds)
          .is("deleted_at", null)
      : Promise.resolve({ data: null, error: null }),
    supabase
      .schema("telematics")
      .rpc("carrier_list_my_telemetry_session_statuses", {
        p_dispatch_ids: dispatchIds,
        p_limit: dispatchIds.length,
        p_offset: 0,
      }),
  ]);

  if (bookingResult.error) {
    console.error("driver_trips.booking_requests", bookingResult.error);
  } else if (bookingResult.data) {
    for (const b of bookingResult.data as Array<{
      id: string;
      shipment_id: string | null;
      capacity_listing_id: string | null;
    }>) {
      bookingById.set(b.id, {
        shipmentId: b.shipment_id ?? null,
        capacityListingId: b.capacity_listing_id ?? null,
      });
    }
  }

  if (telemetryResult.error) {
    // Graceful degradation: list still renders, telemetry fields stay
    // undefined and the UI renders «نامشخص».
    console.error(
      "driver_trips.carrier_list_my_telemetry_session_statuses",
      telemetryResult.error,
    );
  } else if (telemetryResult.data) {
    for (const t of telemetryResult.data as unknown as TelematicsCarrierSessionStatus[]) {
      telemetryById.set(t.dispatch_id, t);
    }
  }

  interface ListingEnrichment {
    transportMode: string | null;
    originCity: string | null;
    originCountry: string | null;
    destinationCity: string | null;
    destinationCountry: string | null;
  }
  const listingById = new Map<string, ListingEnrichment>();
  const listingIds = Array.from(
    new Set(
      Array.from(bookingById.values())
        .map((b) => b.capacityListingId)
        .filter((v): v is string => Boolean(v)),
    ),
  );
  if (listingIds.length > 0) {
    const { data: listings, error: listingErr } = await supabase
      .schema("marketplace")
      .from("capacity_listings")
      .select(
        "id, transport_mode, origin_country_code, origin_city, destination_country_code, destination_city",
      )
      .in("id", listingIds);
    if (listingErr) {
      console.error("driver_trips.capacity_listings", listingErr);
    } else if (listings) {
      for (const l of listings as Array<{
        id: string;
        transport_mode: string | null;
        origin_country_code: string | null;
        origin_city: string | null;
        destination_country_code: string | null;
        destination_city: string | null;
      }>) {
        listingById.set(l.id, {
          transportMode: l.transport_mode,
          originCity: l.origin_city,
          originCountry: l.origin_country_code,
          destinationCity: l.destination_city,
          destinationCountry: l.destination_country_code,
        });
      }
    }
  }

  function formatRoute(l: ListingEnrichment | undefined): string | null {
    if (!l) return null;
    const from = [l.originCity, l.originCountry?.toUpperCase()]
      .filter(Boolean)
      .join(", ");
    const to = [l.destinationCity, l.destinationCountry?.toUpperCase()]
      .filter(Boolean)
      .join(", ");
    if (!from && !to) return null;
    return `${from || "—"} → ${to || "—"}`;
  }

  return dispatches.map((d): DriverTrip => {
    const booking = bookingById.get(d.booking_request_id);
    const listing = booking?.capacityListingId
      ? listingById.get(booking.capacityListingId)
      : undefined;
    const tele = telemetryById.get(d.id);

    const base: DriverTrip = {
      dispatchId: d.id,
      bookingRequestId: d.booking_request_id,
      shipmentId: booking?.shipmentId ?? null,
      status: d.status,
      vehicleReference: d.vehicle_reference ?? null,
      driverName: d.driver_name ?? null,
      plannedPickupAt: d.planned_pickup_at ?? null,
      routeSummary: formatRoute(listing),
      transportMode: listing?.transportMode ?? null,
    };

    if (!tele) return base;

    return {
      ...base,
      sessionActive: tele.session_active,
      latestSessionStartedAt: tele.latest_session_started_at,
      latestSessionEndedAt: tele.latest_session_ended_at,
      lastPositionAt: tele.last_position_at,
      lastLatitude:
        tele.last_latitude != null ? Number(tele.last_latitude) : null,
      lastLongitude:
        tele.last_longitude != null ? Number(tele.last_longitude) : null,
      lastAccuracyMeters:
        tele.last_accuracy_meters != null
          ? Number(tele.last_accuracy_meters)
          : null,
      lastSource: tele.last_source,
      lastEventType: tele.last_event_type,
      lastEventAt: tele.last_event_at,
      positionCount:
        tele.position_count != null ? Number(tele.position_count) : 0,
      eventCount: tele.event_count != null ? Number(tele.event_count) : 0,
      stalenessStatus: tele.staleness_status,
    };
  });
}
