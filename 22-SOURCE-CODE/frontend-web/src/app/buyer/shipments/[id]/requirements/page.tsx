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
import { DocRequirementForm } from "@/components/trade-document/doc-requirement-form";
import { listShipmentDocumentRequirements } from "@/lib/trade-document/list-document-requirements";
import { docKindLabel } from "@/lib/trade-document/labels";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerShipmentRequirementsPage({ params }: PageProps) {
  const { id } = await params;
  const rows = await listShipmentDocumentRequirements(id);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">نیازمندی‌های مدارک محموله</h1>
          <p className="text-sm text-muted-foreground">
            هر نوع مدرک حداکثر یک نیازمندی فعال دارد. ثبت دوباره برای همان نوع، نیازمندی موجود را به‌روز می‌کند.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${id}`}>بازگشت به محموله</Link>
        </Button>
      </div>

      <DocRequirementForm shipmentId={id} submitLabel="افزودن / به‌روزرسانی نیازمندی" />

      {rows.length === 0 ? (
        <TableEmpty>برای این محموله نیازمندی مدرک ثبت نشده است.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>نوع مدرک</TableHead>
                <TableHead>سطح</TableHead>
                <TableHead>عنوان نمایشی</TableHead>
                <TableHead>یادداشت</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell>{docKindLabel(r.document_kind)}</TableCell>
                  <TableCell><Badge variant="outline">{r.requirement_level}</Badge></TableCell>
                  <TableCell className="text-xs">
                    {r.display_name_fa ?? r.display_name_en ?? "—"}
                  </TableCell>
                  <TableCell className="text-xs">{r.notes ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/shipments/${id}/requirements/${r.id}/edit`}>ویرایش</Link>
                    </Button>
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
