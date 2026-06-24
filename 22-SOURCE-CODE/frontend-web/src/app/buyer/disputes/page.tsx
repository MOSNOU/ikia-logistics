import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listBuyerDisputes } from "@/lib/dispute/list-buyer-disputes";
import type { DisputeCaseStatus } from "@/types/database";
import { OpenDisputeForm } from "./open-dispute-form";

const STATUS_OPTIONS: { value: DisputeCaseStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "opened", label: "بازشده" },
  { value: "under_review", label: "در حال بررسی" },
  { value: "resolved_buyer", label: "حل به نفع خریدار" },
  { value: "resolved_supplier", label: "حل به نفع تأمین‌کننده" },
  { value: "resolved_split", label: "تقسیمی" },
  { value: "withdrawn", label: "پس‌گرفته" },
  { value: "cancelled", label: "لغوشده" },
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function BuyerDisputesPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as DisputeCaseStatus)
      : null;

  const { rows, pageSize } = await listBuyerDisputes({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">اختلاف‌ها</h1>
        <p className="text-sm text-muted-foreground">
          فهرست پرونده‌های اختلاف بازشده توسط شما و وضعیت بررسی هرکدام.
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
        <TableEmpty>پرونده اختلافی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>تسویه</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>مبلغ اختلاف</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((d) => (
                <TableRow key={d.id}>
                  <TableCell className="font-mono text-xs">{d.dispute_code}</TableCell>
                  <TableCell>{d.title}</TableCell>
                  <TableCell className="font-mono text-xs">{d.settlement_id}</TableCell>
                  <TableCell><Badge variant="outline">{d.currency}</Badge></TableCell>
                  <TableCell>{Number(d.amount_in_dispute).toLocaleString("fa-IR")}</TableCell>
                  <TableCell><Badge variant="outline">{d.status}</Badge></TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/disputes/${d.id}`}>مشاهده</Link>
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
              <Link href={`/buyer/disputes?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/disputes?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>

      <Card>
        <CardContent className="p-6">
          <h2 className="text-lg font-semibold mb-3">ثبت اختلاف جدید</h2>
          <p className="text-xs text-muted-foreground mb-3">
            شناسه تسویه (UUID) را وارد کنید — لیست تسویه‌ها در /buyer/settlements قابل دیدن است.
          </p>
          <OpenDisputeForm />
        </CardContent>
      </Card>
    </div>
  );
}
