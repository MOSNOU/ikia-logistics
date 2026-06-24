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
import { listSupplierSettlements } from "@/lib/settlement/list-supplier-settlements";
import type { SettlementStatus } from "@/types/database";

const STATUS_OPTIONS: { value: SettlementStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "ready", label: "آماده" },
  { value: "holding", label: "در اسکرو" },
  { value: "released", label: "آزادشده" },
  { value: "reconciled", label: "تطبیق‌شده" },
  { value: "disputed", label: "اختلاف" },
  { value: "cancelled", label: "لغوشده" },
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function SupplierSettlementsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as SettlementStatus)
      : null;

  const { rows, pageSize } = await listSupplierSettlements({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">تسویه‌های من</h1>
        <p className="text-sm text-muted-foreground">
          تسویه‌های واردشده برای قراردادها و محموله‌های شما.
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
                <TableHead>ارز</TableHead>
                <TableHead>مبلغ مصوب</TableHead>
                <TableHead>آزادشده</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>اختلاف</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((s) => (
                <TableRow key={s.id}>
                  <TableCell className="font-mono text-xs">{s.settlement_code}</TableCell>
                  <TableCell><Badge variant="outline">{s.currency}</Badge></TableCell>
                  <TableCell>{Number(s.planned_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell>{Number(s.released_amount).toLocaleString("fa-IR")}</TableCell>
                  <TableCell><Badge variant="outline">{s.status}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{s.dispute_status}</Badge></TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/settlements/${s.id}`}>مشاهده</Link>
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
              <Link href={`/supplier/settlements?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/supplier/settlements?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
