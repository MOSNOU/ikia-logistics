import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getTracking } from "@/lib/shipment/get-tracking";
import { TrackingTimeline } from "@/components/shipment/tracking-timeline";
import { UpsertMilestoneForm } from "./upsert-milestone-form";
import { UpsertStopForm } from "./upsert-stop-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

const EDITABLE_STATUSES = ["draft", "planned", "booked", "in_transit", "arrived"] as const;

export default async function BuyerShipmentTrackingPage({ params }: PageProps) {
  const { id } = await params;
  const bundle = await getTracking(id, "buyer");
  if (!bundle) notFound();

  const { shipment, milestones, stops, timeline } = bundle;
  const editable = (EDITABLE_STATUSES as readonly string[]).includes(shipment.status);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ردیابی محموله — {shipment.shipment_code}</h1>
          <p className="text-sm text-muted-foreground">
            <Badge variant="outline">{shipment.status}</Badge>
            {" · "}
            <Badge variant="outline">{shipment.transport_mode ?? "—"}</Badge>
          </p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href={`/buyer/tracking/${id}/map`}>نقشه</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href={`/buyer/shipments/${id}`}>بازگشت به محموله</Link>
          </Button>
        </div>
      </div>

      <TrackingTimeline
        timeline={timeline}
        milestones={milestones}
        stops={stops}
        audience="buyer"
      />

      {editable ? (
        <>
          <div>
            <h2 className="text-lg font-semibold mb-3">افزودن / به‌روزرسانی نقطه عطف</h2>
            <UpsertMilestoneForm shipmentId={id} />
          </div>
          <div>
            <h2 className="text-lg font-semibold mb-3">افزودن / به‌روزرسانی توقف</h2>
            <UpsertStopForm shipmentId={id} />
          </div>
        </>
      ) : (
        <p className="text-sm text-muted-foreground">
          محموله در وضعیت <Badge variant="outline">{shipment.status}</Badge> — ویرایش ردیابی امکان‌پذیر نیست.
        </p>
      )}
    </div>
  );
}
