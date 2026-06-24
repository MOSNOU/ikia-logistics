import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { getBuyerTradeDocument } from "@/lib/trade-document/list-buyer-documents";
import { DocumentDetailCard } from "@/components/trade-document/document-detail-card";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerTradeDocumentDetailPage({ params }: PageProps) {
  const { id } = await params;
  const doc = await getBuyerTradeDocument(id);
  if (!doc) notFound();

  return (
    <div className="space-y-6">
      <DocumentDetailCard doc={doc} audience="buyer" />
      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/documents">بازگشت به فهرست</Link>
        </Button>
      </div>
    </div>
  );
}
