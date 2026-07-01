import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DispatchSummaryCard } from "@/components/dispatch/dispatch-summary-card";
import { DispatchEventTimeline } from "@/components/dispatch/dispatch-event-timeline";
import { DispatchActionButtons } from "@/components/dispatch/dispatch-action-buttons";
import { AssignDriverPanel } from "@/components/driver/assign-driver-panel";
import { CarrierTripProgressCard } from "@/components/driver/carrier-trip-progress-card";
import { getDispatch } from "@/lib/dispatch/dispatches";
import { listAssignableDrivers } from "@/lib/driver/list-assignable-drivers";
import { getCarrierTripProgress } from "@/lib/driver/carrier-trip-progress";
import { resolveShipmentForDispatch } from "@/lib/telematics/resolve-shipment";

interface PageProps {
  params: Promise<{ id: string }>;
}

// Driver assignment (v1.1) is offered while the dispatch is in a pre-execution
// lifecycle state — matching the dispatch.carrier_assign_driver RPC gate.
const ASSIGNABLE_STATUSES = new Set(["assigned", "ready", "released"]);

export default async function CarrierDispatchDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, shipmentId] = await Promise.all([
    getDispatch(id, "carrier"),
    resolveShipmentForDispatch(id),
  ]);
  if (!detail) notFound();

  // Real driver assignment (v1.1). detail.dispatch is to_jsonb(dispatch_assignments),
  // so driver_user_id / execution_status are present at runtime (typed loosely).
  const canAssignDriver = ASSIGNABLE_STATUSES.has(detail.dispatch.status);
  const assignableDrivers = canAssignDriver ? await listAssignableDrivers(id) : [];
  const currentDriverUserId =
    (detail.dispatch.driver_user_id as string | null | undefined) ?? null;
  const executionStatus =
    (detail.dispatch.execution_status as string | null | undefined) ?? null;

  // Compact driver-progress read-back once a driver is assigned (Phase H, Q5).
  const progress = currentDriverUserId
    ? await getCarrierTripProgress(id)
    : null;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات اعزام</h1>
          <p className="text-sm text-muted-foreground">
            نمای حمل‌کننده. مشخصات خودرو/راننده، اعلام آمادگی و آزادسازی از همین صفحه.
          </p>
        </div>
        <div className="flex gap-2">
          {shipmentId ? (
            <>
              <Button asChild size="sm">
                <Link href={`/carrier/driver/trips/${shipmentId}`}>
                  کنسول راننده
                </Link>
              </Button>
              <Button asChild variant="outline" size="sm">
                <Link href={`/carrier/tracking/${shipmentId}/report`}>
                  گزارش تله‌متری
                </Link>
              </Button>
              <Button asChild variant="outline" size="sm">
                <Link href={`/carrier/tracking/${shipmentId}/map`}>نقشه ردیابی</Link>
              </Button>
            </>
          ) : null}
          <Button asChild variant="outline" size="sm">
            <Link href="/carrier/dispatches">بازگشت</Link>
          </Button>
        </div>
      </div>

      <DispatchSummaryCard detail={detail} />
      {progress ? (
        <CarrierTripProgressCard
          executionStatus={executionStatus}
          driverName={
            (detail.dispatch.driver_name as string | null | undefined) ?? null
          }
          driverUserId={currentDriverUserId}
          vehicleReference={
            (detail.dispatch.vehicle_reference as string | null | undefined) ??
            null
          }
          progress={progress}
        />
      ) : null}
      <DispatchActionButtons detail={detail} audience="carrier" />
      {canAssignDriver ? (
        <AssignDriverPanel
          dispatchId={detail.dispatch.id}
          drivers={assignableDrivers}
          currentDriverUserId={currentDriverUserId}
          executionStatus={executionStatus}
        />
      ) : null}
      <DispatchEventTimeline events={detail.events} />
    </div>
  );
}
