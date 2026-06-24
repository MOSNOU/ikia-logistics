import { createClient } from "@/lib/supabase/server";

// Reverse of resolveDispatchForShipment: given a dispatch_id, returns the
// shipment_id of the booking_request the dispatch was created from. RLS-driven
// (no SECURITY DEFINER) — the caller only sees the shipment if the dispatch
// + its booking_request are visible under their existing role policies.
//
// Returns null when the dispatch is missing, soft-deleted, or its booking
// request has no shipment_id wired (CC-42 booking_requests.shipment_id is
// nullable for ad-hoc bookings).
export async function resolveShipmentForDispatch(
  dispatchId: string,
): Promise<string | null> {
  const supabase = await createClient();
  const { data: dispatch, error: dispatchErr } = await supabase
    .schema("dispatch")
    .from("dispatch_assignments")
    .select("booking_request_id")
    .eq("id", dispatchId)
    .is("deleted_at", null)
    .maybeSingle();
  if (dispatchErr || !dispatch) {
    if (dispatchErr) console.error("resolve dispatch → booking", dispatchErr);
    return null;
  }
  const { data: booking, error: bookingErr } = await supabase
    .schema("marketplace")
    .from("booking_requests")
    .select("shipment_id")
    .eq("id", dispatch.booking_request_id)
    .is("deleted_at", null)
    .maybeSingle();
  if (bookingErr || !booking) {
    if (bookingErr) console.error("resolve booking → shipment", bookingErr);
    return null;
  }
  return booking.shipment_id ?? null;
}
