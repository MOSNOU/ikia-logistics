import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getTracking } from "@/lib/shipment/get-tracking";
import { TrackingTimeline } from "@/components/shipment/tracking-timeline";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierShipmentTrackingPage({ params }: PageProps) {
  const { id } = await params;
  const bundle = await getTracking(id, "supplier");
  if (!bundle) notFound();

  const { shipment, milestones, stops, timeline } = bundle;

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
        <Button asChild variant="outline" size="sm">
          <Link href={`/supplier/shipments/${id}`}>بازگشت به محموله</Link>
        </Button>
      </div>

      <TrackingTimeline
        timeline={timeline}
        milestones={milestones}
        stops={stops}
        audience="supplier"
      />
    </div>
  );
}
