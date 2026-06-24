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
import { listBuyerSettlements } from "@/lib/settlement/list-buyer-settlements";
import type { SettlementStatus } from "@/types/database";

const STATUS_OPTIONS: { value: SettlementStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "ready", label: "آماده" },
  { value: "holding", label: "در اسکرو" },
  { value: "released", label: "آزادشده" },
  { value: "reconciled", label: "تطبیق‌شده" },
  { value: "disputed", label: "اختلاف" },
  { value: "cancelled", label: "لغوشده" },
  { value: "voided", label: "ابطال‌شده" },
];

function statusBadge(s: SettlementStatus) {
  switch (s) {
    case "released":
    case "reconciled":
      return <Badge variant="success">{s === "released" ? "آزادشده" : "تطبیق‌شده"}</Badge>;
    case "holding":
    case "ready":
      return <Badge variant="warning">{s === "holding" ? "در اسکرو" : "آماده"}</Badge>;
    case "disputed":
      return <Badge variant="danger">اختلاف</Badge>;
    case "cancelled":
    case "voided":
      return <Badge variant="danger">{s === "cancelled" ? "لغوشده" : "ابطال‌شده"}</Badge>;
    case "draft":
      return <Badge variant="muted">پیش‌نویس</Badge>;
    default:
      return <Badge variant="outline">{s}</Badge>;
  }
}

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function BuyerSettlementsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as SettlementStatus)
      : null;

  const { rows, pageSize } = await listBuyerSettlements({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">تسویه‌ها</h1>
        <p className="text-sm text-muted-foreground">
          تسویه‌های مرتبط با قراردادها و محموله‌های شما.
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
        <TableEmpty>تسویه‌ای یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>ارز</TableHead>
                <TableHead>مبلغ مصوب</TableHead>
                <TableHead>نگه‌داری‌شده</TableHead>
                <TableHead>آزادشده</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((s) => (
                <TableRow key={s.id}>
                  <TableCell className="font-mono text-xs">{s.settlement_code}</TableCell>
                  <TableCell className="font-mono text-xs">{s.supplier_id}</TableCell>
                  <TableCell><Badge variant="outline">{s.currency}</Badge></TableCell>
                  <TableCell>{Number(s.planned_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell>{Number(s.held_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell>{Number(s.released_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell>{statusBadge(s.status)}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/buyer/settlements/${s.id}`}>مشاهده</Link>
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
              <Link href={`/buyer/settlements?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/buyer/settlements?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
