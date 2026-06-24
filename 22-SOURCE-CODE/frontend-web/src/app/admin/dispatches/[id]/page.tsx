import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DispatchSummaryCard } from "@/components/dispatch/dispatch-summary-card";
import { DispatchEventTimeline } from "@/components/dispatch/dispatch-event-timeline";
import { DispatchActionButtons } from "@/components/dispatch/dispatch-action-buttons";
import { getDispatch } from "@/lib/dispatch/dispatches";
import { resolveShipmentForDispatch } from "@/lib/telematics/resolve-shipment";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminDispatchDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, shipmentId] = await Promise.all([
    getDispatch(id, "admin"),
    resolveShipmentForDispatch(id),
  ]);
  if (!detail) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات اعزام — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای فقط-خواندنی. اقدام ادمین فقط لغو در حالت‌های غیر-نهایی است.
          </p>
        </div>
        <div className="flex gap-2">
          {shipmentId ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/tracking/${shipmentId}/map`}>نقشه ردیابی</Link>
            </Button>
          ) : null}
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/dispatches">بازگشت</Link>
          </Button>
        </div>
      </div>

      <DispatchSummaryCard detail={detail} />
      <DispatchActionButtons detail={detail} audience="admin" />
      <DispatchEventTimeline events={detail.events} />
    </div>
  );
}
