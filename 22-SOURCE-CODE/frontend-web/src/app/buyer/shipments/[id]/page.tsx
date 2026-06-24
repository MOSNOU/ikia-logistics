import Link from "next/link";
import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getShipment } from "@/lib/shipment/get-shipment";
import { ShipmentSummary } from "@/components/shipment/shipment-summary";
import { ShipmentStatusActions } from "./shipment-status-actions";
import { UpsertDocRequirementForm } from "./upsert-doc-requirement-form";
import { UpsertDocumentForm } from "./upsert-document-form";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerShipmentDetailPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getShipment(id, "buyer");
  if (!detail) notFound();
  const { shipment } = detail;

  const editable = shipment.status === "draft" || shipment.status === "planned" || shipment.status === "booked";

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{shipment.shipment_code}</h1>
          <p className="text-sm text-muted-foreground">
            قرارداد:{" "}
            <Link
              href={`/buyer/contracts/${shipment.executed_contract_id}`}
              className="font-mono text-xs underline"
            >
              {shipment.executed_contract_id}
            </Link>
            {" · "}
            <Badge variant="outline">{shipment.transport_mode ?? "—"}</Badge>
            {" · "}
            وضعیت: <Badge variant="outline">{shipment.status}</Badge>
          </p>
        </div>
        <ShipmentStatusActions shipmentId={shipment.id} status={shipment.status} />
      </div>

      <ShipmentSummary detail={detail} />

      {editable ? (
        <>
          <div>
            <h2 className="text-lg font-semibold mb-3">افزودن نیازمندی مدرک</h2>
            <UpsertDocRequirementForm shipmentId={shipment.id} />
          </div>
          <div>
            <h2 className="text-lg font-semibold mb-3">افزودن مدرک</h2>
            <UpsertDocumentForm shipmentId={shipment.id} />
          </div>
        </>
      ) : null}

      <div className="flex flex-wrap gap-2">
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${shipment.id}/tracking`}>ردیابی محموله</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/tracking/${shipment.id}/map`}>نقشه ردیابی</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/shipments">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
