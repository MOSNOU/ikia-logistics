import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent } from "@/components/ui/card";
import { getMySupplier } from "@/lib/supplier/get-my-supplier";
import { DocumentRowActions } from "./document-row-actions";

export default async function SupplierDocumentsPage() {
  const { supplier, documents } = await getMySupplier();

  if (!supplier) {
    return (
      <div className="mx-auto max-w-2xl">
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            سازمان فعال شما هنوز به‌عنوان تأمین‌کننده ثبت نشده.
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">مدارک</h1>
          <p className="text-sm text-muted-foreground">
            ثبت و مدیریت مدارک تأمین‌کننده (تنها فراداده — بارگذاری فایل در فاز بعدی).
          </p>
        </div>
        <Button asChild>
          <Link href="/supplier/documents/new">افزودن مدرک</Link>
        </Button>
      </div>

      {documents.length === 0 ? (
        <TableEmpty>هنوز مدرکی ثبت نکرده‌اید.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>عنوان</TableHead>
                <TableHead>نوع</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>صادر</TableHead>
                <TableHead>انقضا</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {documents.map((d) => (
                <TableRow key={d.id}>
                  <TableCell>{d.title}</TableCell>
                  <TableCell><Badge variant="outline">{d.document_type}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
                  <TableCell className="text-xs">{d.issued_at ?? "—"}</TableCell>
                  <TableCell className="text-xs">{d.expires_at ?? "—"}</TableCell>
                  <TableCell>
                    {d.status === "pending" ? (
                      <DocumentRowActions documentId={d.id} />
                    ) : (
                      <span className="text-xs text-muted-foreground">قفل‌شده</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
