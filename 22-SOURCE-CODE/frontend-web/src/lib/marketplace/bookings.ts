import { createClient } from "@/lib/supabase/server";
import type {
  BookingDetail,
  BookingListRow,
  BookingStatus,
} from "@/types/database";

export type BookingAudience = "buyer" | "carrier" | "admin";

export interface ListBookingsParams {
  status?: BookingStatus | null;
  page?: number;
  pageSize?: number;
}

export interface ListBookingsResult {
  rows: BookingListRow[];
  page: number;
  pageSize: number;
}

// CC-42: audience-switched booking list. Each audience calls the matching
// SECURITY DEFINER RPC; RLS + per-RPC role gates take care of visibility.
export async function listBookings(
  audience: BookingAudience,
  { status = null, page = 0, pageSize = 25 }: ListBookingsParams = {},
): Promise<ListBookingsResult> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_list_my_bookings"
      : audience === "carrier"
        ? "carrier_list_booking_requests"
        : "admin_list_bookings";
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc(rpc, {
      p_status: status ?? undefined,
      p_limit: pageSize,
      p_offset: page * pageSize,
    });
  if (error) {
    console.error(`marketplace.${rpc}`, error);
    return { rows: [], page, pageSize };
  }
  return {
    rows: (data ?? []) as unknown as BookingListRow[],
    page,
    pageSize,
  };
}

export async function getBooking(
  bookingId: string,
  audience: BookingAudience,
): Promise<BookingDetail | null> {
  const supabase = await createClient();
  const rpc =
    audience === "buyer"
      ? "buyer_get_booking"
      : audience === "carrier"
        ? "carrier_get_booking"
        : "admin_get_booking";
  const { data, error } = await supabase
    .schema("marketplace")
    .rpc(rpc, { p_booking_id: bookingId });
  if (error || !data) {
    if (error) console.error(`marketplace.${rpc}`, error);
    return null;
  }
  return data as unknown as BookingDetail;
}
