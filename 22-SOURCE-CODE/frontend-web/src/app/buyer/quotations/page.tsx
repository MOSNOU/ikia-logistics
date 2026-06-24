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
import { listMyQuotations } from "@/lib/pricing/list-my-quotations";
import type { QuotationStatus } from "@/types/database";

const STATUS_OPTIONS: { value: QuotationStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "sent", label: "ارسال‌شده" },
  { value: "accepted", label: "پذیرفته‌شده" },
  { value: "rejected", label: "ردشده" },
  { value: "expired", label: "منقضی" },
];

function statusBadge(s: QuotationStatus) {
  switch (s) {
    case "accepted":
      return <Badge variant="success">پذیرفته‌شده</Badge>;
    case "sent":
      return <Badge variant="warning">ارسال‌شده</Badge>;
    case "rejected":
    case "withdrawn":
      return <Badge variant="danger">{s === "rejected" ? "ردشده" : "پس‌گرفته"}</Badge>;
    case "expired":
      return <Badge variant="outline">منقضی</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function BuyerQuotationsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as QuotationStatus)
      : null;

  const { rows, pageSize } = await listMyQuotations({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">پیشنهادهای دریافتی</h1>
        <p className="text-sm text-muted-foreground">
          پیشنهادهای قیمت دریافت‌شده از تأمین‌کنندگان — پذیرش یا رد.
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
        <TableEmpty>هیچ پیشنهادی دریافت نکرده‌اید.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>مبلغ کل</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>اعتبار تا</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((q) => (
                <TableRow key={q.id}>
                  <TableCell className="font-mono text-xs">{q.quotation_code}</TableCell>
                  <TableCell className="font-mono text-xs">{q.supplier_id}</TableCell>
                  <TableCell><Badge variant="outline">{q.currency_code}</Badge></TableCell>
                  <TableCell>{Number(q.total_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell>{statusBadge(q.status)}</TableCell>
                  <TableCell className="text-xs">{q.valid_until ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/quotations/${q.id}`}>مشاهده</Link>
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
              <Link href={`/buyer/quotations?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/quotations?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
