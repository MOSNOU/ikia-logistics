import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { BookingSummaryCard } from "@/components/marketplace/booking-summary-card";
import { BookingEventTimeline } from "@/components/marketplace/booking-event-timeline";
import { BookingActionButtons } from "@/components/marketplace/booking-action-buttons";
import { getBooking } from "@/lib/marketplace/bookings";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerBookingDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getBooking(id, "buyer");
  if (!detail) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات رزرو</h1>
          <p className="text-sm text-muted-foreground">
            نمای خریدار. تأیید یا لغو رزرو از همین صفحه قابل اجراست.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/bookings">بازگشت</Link>
        </Button>
      </div>

      <BookingSummaryCard detail={detail} />
      <BookingActionButtons bookingId={id} audience="buyer" status={detail.booking.status} />
      <BookingEventTimeline events={detail.events} />
    </div>
  );
}
