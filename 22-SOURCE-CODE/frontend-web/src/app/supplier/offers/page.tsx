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
import { listSupplierOffers } from "@/lib/offer/list-supplier-offers";
import type { OfferStatus } from "@/types/database";

const STATUS_OPTIONS: { value: OfferStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "withdrawn", label: "پس‌گرفته" },
  { value: "expired", label: "منقضی" },
  { value: "rejected", label: "ردشده" },
  { value: "shortlisted", label: "فهرست کوتاه" },
  { value: "accepted", label: "پذیرفته‌شده" },
];

function statusBadge(s: OfferStatus) {
  switch (s) {
    case "accepted":
      return <Badge variant="success">پذیرفته‌شده</Badge>;
    case "submitted":
    case "shortlisted":
      return <Badge variant="warning">{s === "submitted" ? "ارسال‌شده" : "فهرست کوتاه"}</Badge>;
    case "rejected":
    case "withdrawn":
    case "expired":
      return <Badge variant="danger">{s === "rejected" ? "ردشده" : s === "withdrawn" ? "پس‌گرفته" : "منقضی"}</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function SupplierOffersPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as OfferStatus)
      : null;

  const { rows, pageSize } = await listSupplierOffers({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">پیشنهادهای من</h1>
        <p className="text-sm text-muted-foreground">
          پیشنهادهای ارسال‌شده و پیش‌نویس‌های شما در پاسخ به RFQها.
        </p>
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">وضعیت</label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>پیشنهادی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد پیشنهاد</TableHead>
                <TableHead>RFQ</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>تعداد ردیف</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>ارسال در</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((o) => (
                <TableRow key={o.id}>
                  <TableCell className="font-mono text-xs">{o.offer_code}</TableCell>
                  <TableCell className="font-mono text-xs">{o.rfq_code ?? o.request_id}</TableCell>
                  <TableCell><Badge variant="outline">{o.currency}</Badge></TableCell>
                  <TableCell>{o.item_count ?? 0}</TableCell>
                  <TableCell>{statusBadge(o.status)}</TableCell>
                  <TableCell className="text-xs">{o.submitted_at ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/offers/${o.id}`}>مشاهده</Link>
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
              <Link href={`/supplier/offers?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/supplier/offers?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
