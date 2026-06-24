import { createClient } from "@/lib/supabase/server";
import type { DispatchListRow, DispatchStatus } from "@/types/database";

// CC-50 — Carrier-facing Driver Console trip list.
//
// Strategy:
//   1. Pull the carrier's dispatches via the existing CC-43 RPC
//      dispatch.carrier_list_my_dispatches.
//   2. Batch-resolve each dispatch's shipment_id + lane summary from
//      marketplace.booking_requests + marketplace.capacity_listings.
//
// Everything is RLS-driven — no SECURITY DEFINER and no new RPC contract.
// If a booking is invisible to the carrier (e.g. soft-deleted, foreign org),
// the dispatch still shows but its shipmentId / routeSummary remain null;
// the UI gates the "trip detail" link on shipmentId being set.

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

  const bookingIds = Array.from(
    new Set(dispatches.map((d) => d.booking_request_id).filter(Boolean)),
  );

  interface BookingEnrichment {
    shipmentId: string | null;
    capacityListingId: string | null;
  }
  const bookingById = new Map<string, BookingEnrichment>();

  if (bookingIds.length > 0) {
    const { data: bookings, error: bookingErr } = await supabase
      .schema("marketplace")
      .from("booking_requests")
      .select("id, shipment_id, capacity_listing_id")
      .in("id", bookingIds)
      .is("deleted_at", null);
    if (bookingErr) {
      console.error("driver_trips.booking_requests", bookingErr);
    } else if (bookings) {
      for (const b of bookings as Array<{
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

  return dispatches.map((d) => {
    const booking = bookingById.get(d.booking_request_id);
    const listing = booking?.capacityListingId
      ? listingById.get(booking.capacityListingId)
      : undefined;
    return {
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
  });
}
