import { createClient } from "@/lib/supabase/server";

export interface ResolvedDispatch {
  dispatchId: string;
  bookingRequestId: string;
  buyerOrganizationId: string;
  carrierOrganizationId: string;
}

// Resolves a shipment to its latest non-cancelled dispatch. A shipment can
// have multiple booking_requests; we pick the latest buyer-confirmed booking
// and then its latest non-cancelled dispatch.
//
// RLS-driven: this query runs as the caller (no SECURITY DEFINER), so the
// buyer / carrier / admin RLS policies on booking_requests +
// dispatch_assignments determine visibility.
export async function resolveDispatchForShipment(
  shipmentId: string,
): Promise<ResolvedDispatch | null> {
  const supabase = await createClient();
  const { data: booking, error: bookingErr } = await supabase
    .schema("marketplace")
    .from("booking_requests")
    .select("id, buyer_organization_id, carrier_organization_id")
    .eq("shipment_id", shipmentId)
    .eq("status", "buyer_confirmed")
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (bookingErr || !booking) {
    if (bookingErr) console.error("resolve booking", bookingErr);
    return null;
  }
  const { data: dispatch, error: dispatchErr } = await supabase
    .schema("dispatch")
    .from("dispatch_assignments")
    .select("id, buyer_organization_id, carrier_organization_id, status")
    .eq("booking_request_id", booking.id)
    .neq("status", "cancelled")
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (dispatchErr || !dispatch) {
    if (dispatchErr) console.error("resolve dispatch", dispatchErr);
    return null;
  }
  return {
    dispatchId: dispatch.id,
    bookingRequestId: booking.id,
    buyerOrganizationId: dispatch.buyer_organization_id,
    carrierOrganizationId: dispatch.carrier_organization_id,
  };
}
