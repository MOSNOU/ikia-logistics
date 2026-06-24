import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getShipment } from "@/lib/shipment/get-shipment";
import { listShipmentEvents } from "@/lib/admin/list-shipment-events";
import { ShipmentSummary } from "@/components/shipment/shipment-summary";
import { AdminForceActions } from "./admin-force-actions";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminShipmentDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, events] = await Promise.all([
    getShipment(id, "admin"),
    listShipmentEvents(id),
  ]);
  if (!detail) notFound();
  const { shipment } = detail;

  // Merge admin-fetched events into the detail so ShipmentSummary's events
  // section displays them even when the get RPC doesn't bundle them.
  const merged = { ...detail, events: detail.events?.length ? detail.events : events };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">{shipment.shipment_code}</h1>
        <p className="text-sm text-muted-foreground">
          قرارداد: <span className="font-mono text-xs">{shipment.executed_contract_id}</span>
          {" · "}
          <Badge variant="outline">{shipment.transport_mode ?? "—"}</Badge>
          {" · "}
          وضعیت: <Badge variant="outline">{shipment.status}</Badge>
        </p>
      </div>

      <ShipmentSummary detail={merged} />

      <AdminForceActions shipmentId={shipment.id} status={shipment.status} />

      <div className="flex flex-wrap gap-2">
        <Button asChild variant="outline" size="sm">
          <Link href={`/admin/shipments/${shipment.id}/tracking`}>ردیابی محموله</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href={`/admin/tracking/${shipment.id}/map`}>نقشه ردیابی</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/shipments">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
