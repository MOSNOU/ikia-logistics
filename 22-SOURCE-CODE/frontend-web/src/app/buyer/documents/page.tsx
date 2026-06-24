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
import { listBuyerTradeDocuments } from "@/lib/trade-document/list-buyer-documents";
import {
  DOC_KIND_OPTIONS,
  DOC_STATUS_OPTIONS,
} from "@/lib/trade-document/labels";
import type {
  ShipmentDocumentKind,
  ShipmentDocumentStatus,
} from "@/types/database";

interface PageProps {
  searchParams: Promise<{
    kind?: string;
    status?: string;
    shipmentId?: string;
    page?: string;
  }>;
}

function statusBadge(s: ShipmentDocumentStatus) {
  switch (s) {
    case "available":
      return <Badge variant="success">موجود</Badge>;
    case "pending":
      return <Badge variant="warning">در انتظار</Badge>;
    case "expired":
    case "rejected":
      return <Badge variant="danger">{s === "expired" ? "منقضی" : "ردشده"}</Badge>;
    case "archived":
      return <Badge variant="outline">بایگانی</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

export default async function BuyerTradeDocumentsPage({ searchParams }: PageProps) {
  const { kind, status, shipmentId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const kindFilter =
    kind && DOC_KIND_OPTIONS.some((o) => o.value === kind)
      ? (kind as ShipmentDocumentKind)
      : null;
  const statusFilter =
    status && DOC_STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as ShipmentDocumentStatus)
      : null;
  const shipFilter = shipmentId?.trim() || null;

  const { rows, pageSize } = await listBuyerTradeDocuments({
    documentKind: kindFilter,
    documentStatus: statusFilter,
    shipmentId: shipFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">مدارک تجاری</h1>
        <p className="text-sm text-muted-foreground">
          نمای یکپارچه روی همه مدارک شیپمنت — فاکتور تجاری، بارنامه، گواهی مبدأ، گواهی بازرسی، اظهارنامه گمرکی و سایر مدارک حمل و تطبیق.
        </p>
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="kind" className="text-sm font-medium">نوع مدرک</label>
          <select
            id="kind"
            name="kind"
            defaultValue={kindFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {DOC_KIND_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">وضعیت</label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {DOC_STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <label htmlFor="shipmentId" className="text-sm font-medium">شناسه شیپمنت</label>
          <input
            id="shipmentId"
            name="shipmentId"
            defaultValue={shipFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>مدرکی برای نمایش وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>شیپمنت</TableHead>
                <TableHead>نوع</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>مرجع خارجی</TableHead>
                <TableHead>صدور</TableHead>
                <TableHead>انقضا</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((d) => (
                <TableRow key={d.id}>
                  <TableCell className="font-mono text-xs">
                    {d.shipments?.shipment_code ?? d.shipment_id}
                  </TableCell>
                  <TableCell><Badge variant="outline">{d.document_kind}</Badge></TableCell>
                  <TableCell>{statusBadge(d.document_status)}</TableCell>
                  <TableCell className="text-xs">{d.external_reference ?? "—"}</TableCell>
                  <TableCell className="text-xs">{d.issued_at ?? "—"}</TableCell>
                  <TableCell className="text-xs">{d.expires_at ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/documents/${d.id}`}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/buyer/documents?kind=${kindFilter ?? ""}&status=${statusFilter ?? ""}&shipmentId=${shipFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/buyer/documents?kind=${kindFilter ?? ""}&status=${statusFilter ?? ""}&shipmentId=${shipFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
