import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DocRequirementForm } from "@/components/trade-document/doc-requirement-form";
import { getShipmentDocumentRequirement } from "@/lib/trade-document/list-document-requirements";

interface PageProps {
  params: Promise<{ id: string; reqId: string }>;
}

export default async function BuyerEditRequirementPage({ params }: PageProps) {
  const { id, reqId } = await params;
  const req = await getShipmentDocumentRequirement(reqId);
  if (!req || req.shipment_id !== id) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ویرایش نیازمندی مدرک</h1>
          <p className="text-sm text-muted-foreground">
            تغییر نوع مدرک، یک نیازمندی جدید ایجاد می‌کند چون قید یکتایی روی (محموله، نوع) است.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${id}/requirements`}>بازگشت</Link>
        </Button>
      </div>

      <DocRequirementForm
        shipmentId={id}
        initial={{
          requirementId: req.id,
          documentKind: req.document_kind,
          requirementLevel: req.requirement_level,
          displayNameEn: req.display_name_en,
          displayNameFa: req.display_name_fa,
          notes: req.notes,
        }}
        submitLabel="ذخیره تغییرات"
      />
    </div>
  );
}
