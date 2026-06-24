import Link from "next/link";
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
import { AmountCell } from "@/components/finance/amount-cell";
import { FinanceStatusBadge } from "@/components/finance/status-badge";
import { listAdminSettlements } from "@/lib/admin/list-settlements";

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function AdminFinanceSettlementsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const { rows, pageSize } = await listAdminSettlements({
    status: (status as never) || null,
    page,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">تسویه‌ها — نمای ادمین</h1>
          <p className="text-sm text-muted-foreground">
            تسویه‌های همه سازمان‌ها. برای فهرست عملیاتی به{" "}
            <Link className="underline" href="/admin/settlements">/admin/settlements</Link> مراجعه کنید.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/finance">داشبورد مالی</Link>
        </Button>
      </div>

      {rows.length === 0 ? (
        <TableEmpty>تسویه‌ای برای نمایش وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>سازمان</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>منازعه</TableHead>
                <TableHead>برنامه</TableHead>
                <TableHead>آزادشده</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs">{r.settlement_code}</TableCell>
                  <TableCell className="font-mono text-xs">{r.organization_id}</TableCell>
                  <TableCell className="font-mono text-xs">{r.supplier_id}</TableCell>
                  <TableCell><FinanceStatusBadge status={r.status} domain="settlement" /></TableCell>
                  <TableCell className="text-xs">{r.dispute_status}</TableCell>
                  <TableCell><AmountCell value={r.planned_amount} currency={r.currency} /></TableCell>
                  <TableCell><AmountCell value={r.released_amount} currency={r.currency} /></TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/finance/settlements/${r.id}`}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <div className="flex justify-between text-xs text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/finance/settlements?status=${status ?? ""}&page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/finance/settlements?status=${status ?? ""}&page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
