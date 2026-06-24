import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DispatchSummaryCard } from "@/components/dispatch/dispatch-summary-card";
import { DispatchEventTimeline } from "@/components/dispatch/dispatch-event-timeline";
import { DispatchActionButtons } from "@/components/dispatch/dispatch-action-buttons";
import { getDispatch } from "@/lib/dispatch/dispatches";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerDispatchDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getDispatch(id, "buyer");
  if (!detail) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات اعزام</h1>
          <p className="text-sm text-muted-foreground">
            نمای خریدار. لغو اعزام از همین صفحه قابل اجراست (در حالت‌های غیر-نهایی).
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/dispatches">بازگشت</Link>
        </Button>
      </div>

      <DispatchSummaryCard detail={detail} />
      <DispatchActionButtons detail={detail} audience="buyer" />
      <DispatchEventTimeline events={detail.events} />
    </div>
  );
}
