import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DocumentUpsertForm } from "@/components/trade-document/document-upsert-form";
import { getShipmentDocumentRequirement } from "@/lib/trade-document/list-document-requirements";

interface PageProps {
  searchParams: Promise<{ shipmentId?: string; requirementId?: string }>;
}

export default async function BuyerNewDocumentPage({ searchParams }: PageProps) {
  const { shipmentId, requirementId } = await searchParams;

  let resolvedShipmentId = shipmentId ?? null;
  let initialKind: string | undefined;

  if (requirementId) {
    const req = await getShipmentDocumentRequirement(requirementId);
    if (!req) notFound();
    resolvedShipmentId = req.shipment_id;
    initialKind = req.document_kind;
  }

  if (!resolvedShipmentId) {
    redirect("/buyer/shipments");
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ثبت مدرک جدید</h1>
          <p className="text-sm text-muted-foreground">
            مدرک به محموله مرتبط می‌شود. در صورت تمایل می‌توانید آن را به یک نیازمندی یا آیتم محموله گره بزنید.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${resolvedShipmentId}`}>بازگشت به محموله</Link>
        </Button>
      </div>

      <DocumentUpsertForm
        shipmentId={resolvedShipmentId}
        initial={{
          documentKind: initialKind,
          requirementId: requirementId ?? null,
        }}
        submitLabel="ثبت مدرک"
      />
    </div>
  );
}
