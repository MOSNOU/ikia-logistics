import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DocumentFileList } from "@/components/trade-document/document-file-list";
import { DocumentFileUpload } from "@/components/trade-document/document-file-upload";
import { getBuyerTradeDocument } from "@/lib/trade-document/list-buyer-documents";
import { listDocumentFiles } from "@/lib/trade-document/actions-files";
import { docKindLabel } from "@/lib/trade-document/labels";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerDocumentFilesPage({ params }: PageProps) {
  const { id } = await params;
  const doc = await getBuyerTradeDocument(id);
  if (!doc) notFound();
  const files = await listDocumentFiles(id);
  const headFile = files.find((f) => f.status !== "archived");

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">فایل‌های مدرک</h1>
          <p className="text-sm text-muted-foreground">
            مدرک: {docKindLabel(doc.document_kind)}
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/documents/${id}`}>بازگشت به مدرک</Link>
        </Button>
      </div>

      <Card>
        <CardContent className="p-6 text-sm text-muted-foreground">
          بارگذاری مستقیم به Supabase Storage از طریق Signed URL انجام می‌شود. متادیتای فایل از طریق Server Actions ثبت می‌شود.
        </CardContent>
      </Card>

      <DocumentFileUpload documentId={id} />

      {headFile ? (
        <div>
          <h2 className="text-lg font-medium">افزودن نسخه جدید برای فایل فعال</h2>
          <p className="text-xs text-muted-foreground mb-3">
            نسخه فعلی به وضعیت «superseded» منتقل می‌شود.
          </p>
          <DocumentFileUpload documentId={id} existingFileId={headFile.file_id} />
        </div>
      ) : null}

      <h2 className="text-lg font-medium">فایل‌های پیوست‌شده</h2>
      <DocumentFileList documentId={id} files={files} />
    </div>
  );
}
