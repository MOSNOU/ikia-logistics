import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getShipment } from "@/lib/shipment/get-shipment";
import { ShipmentSummary } from "@/components/shipment/shipment-summary";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function SupplierShipmentDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getShipment(id, "supplier");
  if (!detail) notFound();
  const { shipment } = detail;

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

      <ShipmentSummary detail={detail} />

      <div className="flex flex-wrap gap-2">
        <Button asChild variant="outline" size="sm">
          <Link href={`/supplier/shipments/${shipment.id}/tracking`}>ردیابی محموله</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/shipments">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
