import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { DocumentUpsertForm } from "@/components/trade-document/document-upsert-form";
import { getBuyerTradeDocument } from "@/lib/trade-document/list-buyer-documents";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerEditDocumentPage({ params }: PageProps) {
  const { id } = await params;
  const doc = await getBuyerTradeDocument(id);
  if (!doc) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ویرایش مدرک</h1>
          <p className="text-sm text-muted-foreground">
            تغییرات روی همین ردیف مدرک ذخیره می‌شود؛ تاریخ‌ها و وضعیت قابل به‌روزرسانی است.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/documents/${id}`}>بازگشت</Link>
        </Button>
      </div>

      <DocumentUpsertForm
        shipmentId={doc.shipment_id}
        documentId={doc.id}
        initial={{
          documentKind: doc.document_kind,
          documentStatus: doc.document_status,
          requirementId: doc.requirement_id,
          shipmentItemId: doc.shipment_item_id,
          externalReference: doc.external_reference,
          issuedAt: doc.issued_at,
          expiresAt: doc.expires_at,
          notes: doc.notes,
        }}
        submitLabel="ذخیره تغییرات"
      />

      <div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/documents/${id}/files`}>مدیریت فایل‌ها</Link>
        </Button>
      </div>
    </div>
  );
}
