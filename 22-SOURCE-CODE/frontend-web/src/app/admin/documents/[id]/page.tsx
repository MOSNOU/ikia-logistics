import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { getAdminTradeDocument } from "@/lib/trade-document/list-admin-documents";
import { DocumentDetailCard } from "@/components/trade-document/document-detail-card";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminTradeDocumentDetailPage({ params }: PageProps) {
  const { id } = await params;
  const doc = await getAdminTradeDocument(id);
  if (!doc) notFound();

  return (
    <div className="space-y-6">
      <DocumentDetailCard doc={doc} audience="admin" />
      <div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/documents">بازگشت به صف</Link>
        </Button>
      </div>
    </div>
  );
}
