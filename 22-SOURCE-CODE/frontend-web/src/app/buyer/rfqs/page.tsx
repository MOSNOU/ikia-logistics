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
import { listBuyerRfqs } from "@/lib/rfq/list-buyer-rfqs";
import type { RfqStatus } from "@/types/database";

const STATUS_OPTIONS: { value: RfqStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "published", label: "منتشرشده" },
  { value: "invited", label: "دعوت‌شده" },
  { value: "closed", label: "بسته‌شده" },
  { value: "cancelled", label: "لغوشده" },
  { value: "expired", label: "منقضی" },
];

function statusBadge(s: RfqStatus) {
  switch (s) {
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    case "submitted":
    case "published":
    case "invited":
      return <Badge variant="warning">{s === "published" ? "منتشرشده" : s === "invited" ? "دعوت‌شده" : "ارسال‌شده"}</Badge>;
    case "closed":
      return <Badge variant="success">بسته‌شده</Badge>;
    case "cancelled":
    case "expired":
      return <Badge variant="danger">{s === "cancelled" ? "لغوشده" : "منقضی"}</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function BuyerRfqsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as RfqStatus)
      : null;

  const { rows, pageSize } = await listBuyerRfqs({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">درخواست‌های خرید (RFQ)</h1>
          <p className="text-sm text-muted-foreground">
            ایجاد و مدیریت RFQها — دعوت تأمین‌کنندگان و دریافت پیشنهاد.
          </p>
        </div>
        <Button asChild>
          <Link href="/buyer/rfqs/new">ایجاد RFQ جدید</Link>
        </Button>
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
        <TableEmpty>RFQی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>مهلت ارسال</TableHead>
                <TableHead>تعداد دعوت</TableHead>
                <TableHead>تعداد ردیف</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs">{r.rfq_code}</TableCell>
                  <TableCell>{r.title}</TableCell>
                  <TableCell>{statusBadge(r.status)}</TableCell>
                  <TableCell className="text-xs">{r.submission_deadline ?? "—"}</TableCell>
                  <TableCell>{r.invitation_count ?? 0}</TableCell>
                  <TableCell>{r.item_count ?? 0}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/rfqs/${r.id}`}>مشاهده</Link>
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
              <Link href={`/buyer/rfqs?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/rfqs?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
