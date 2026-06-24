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
import { listBuyerEvaluations } from "@/lib/evaluation/list-buyer-evaluations";
import type { EvaluationStatus } from "@/types/database";

const STATUS_OPTIONS: { value: EvaluationStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "in_review", label: "در حال بررسی" },
  { value: "completed", label: "تکمیل‌شده" },
  { value: "cancelled", label: "لغوشده" },
];

function statusBadge(s: EvaluationStatus) {
  switch (s) {
    case "completed":
      return <Badge variant="success">تکمیل‌شده</Badge>;
    case "in_review":
      return <Badge variant="warning">در حال بررسی</Badge>;
    case "cancelled":
      return <Badge variant="danger">لغوشده</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; requestId?: string; page?: string }>;
}

export default async function BuyerEvaluationsPage({ searchParams }: PageProps) {
  const { status, requestId, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as EvaluationStatus)
      : null;
  const rfqFilter = requestId?.trim() || null;

  const { rows, pageSize } = await listBuyerEvaluations({
    status: statusFilter,
    requestId: rfqFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">ارزیابی‌ها</h1>
        <p className="text-sm text-muted-foreground">
          ارزیابی‌های ثبت‌شده شما برای پیشنهادهای دریافتی روی RFQها.
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
        <div className="space-y-1">
          <label htmlFor="requestId" className="text-sm font-medium">شناسه RFQ</label>
          <input
            id="requestId"
            name="requestId"
            defaultValue={rfqFilter ?? ""}
            dir="ltr"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm font-mono"
            placeholder="UUID"
          />
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>
          ارزیابی ثبت نشده است. از صفحه RFQ، گزینهٔ «ارزیابی» را برای شروع کلیک کنید.
        </TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>RFQ</TableHead>
                <TableHead>پیشنهاد</TableHead>
                <TableHead>ارزیاب</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>تعداد امتیاز</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs">{r.request_id}</TableCell>
                  <TableCell className="font-mono text-xs">{r.offer_id}</TableCell>
                  <TableCell className="font-mono text-xs">{r.evaluator_user_id ?? "—"}</TableCell>
                  <TableCell>{statusBadge(r.status)}</TableCell>
                  <TableCell>{r.score_count ?? 0}</TableCell>
                  <TableCell className="text-xs">{r.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/evaluations/${r.id}`}>مشاهده</Link>
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
                href={`/buyer/evaluations?status=${statusFilter ?? ""}&requestId=${rfqFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/buyer/evaluations?status=${statusFilter ?? ""}&requestId=${rfqFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
