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
import { KpiTile } from "@/components/finance/kpi-tile";
import { AmountCell } from "@/components/finance/amount-cell";
import { FinanceStatusBadge } from "@/components/finance/status-badge";
import { listInvoices } from "@/lib/finance/list-invoices";
import { listAdminSettlements } from "@/lib/admin/list-settlements";
import { listAdminEscrowAccounts } from "@/lib/finance/list-escrow-accounts";
import { computeFinanceKpis } from "@/lib/finance/compute-kpis";

export default async function AdminFinanceDashboardPage() {
  const [invRes, setRes, escRes] = await Promise.all([
    listInvoices("admin", { pageSize: 100 }),
    listAdminSettlements({ pageSize: 100 }),
    listAdminEscrowAccounts({ pageSize: 100 }),
  ]);
  const kpis = computeFinanceKpis({
    invoices: invRes.rows,
    settlements: setRes.rows,
    escrowAccounts: escRes.rows,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">داشبورد مالی ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای کلی فاکتورها، تسویه‌ها و حساب‌های امانی همه سازمان‌ها. فقط نمایشی.
          </p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/finance/settlements">تسویه‌ها</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/finance/exceptions">صف استثناها</Link>
          </Button>
        </div>
      </div>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">درآمد / فاکتور</h2>
        <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
          <KpiTile label="مجموع فاکتورها" amount={kpis.invoices.totalAmount} currency={kpis.currency} caption={`${kpis.invoices.count} فاکتور`} />
          <KpiTile label="پرداخت‌شده" amount={kpis.invoices.paidAmount} currency={kpis.currency} tone="success" />
          <KpiTile label="مانده پرداخت‌نشده" amount={kpis.invoices.outstandingAmount} currency={kpis.currency} tone="warning" />
          <KpiTile label="گذشته از موعد" count={kpis.invoices.overdueCount} tone={kpis.invoices.overdueCount > 0 ? "danger" : "default"} />
        </div>
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">تسویه</h2>
        <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
          <KpiTile label="تعداد تسویه" count={kpis.settlements.count} />
          <KpiTile label="برنامه" amount={kpis.settlements.plannedAmount} currency={kpis.currency} />
          <KpiTile label="بلوکه" amount={kpis.settlements.heldAmount} currency={kpis.currency} tone={kpis.settlements.holdCount > 0 ? "warning" : "default"} />
          <KpiTile label="آزاد شده" amount={kpis.settlements.releasedAmount} currency={kpis.currency} tone="success" />
        </div>
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">حساب امانی</h2>
        <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
          <KpiTile label="تعداد حساب" count={kpis.escrow.accountCount} />
          <KpiTile label="مانده در دسترس" amount={kpis.escrow.availableBalance} currency={kpis.currency} />
          <KpiTile label="بلوکه‌شده" amount={kpis.escrow.totalHeld} currency={kpis.currency} />
          <KpiTile label="فریز‌شده" count={kpis.escrow.frozenCount} tone={kpis.escrow.frozenCount > 0 ? "danger" : "default"} />
        </div>
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">فاکتورهای اخیر</h2>
        {invRes.rows.length === 0 ? (
          <TableEmpty>فاکتوری یافت نشد.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد</TableHead>
                  <TableHead>سازمان</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>کل</TableHead>
                  <TableHead>پرداخت‌شده</TableHead>
                  <TableHead>موعد</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invRes.rows.slice(0, 10).map((i) => (
                  <TableRow key={i.id}>
                    <TableCell className="font-mono text-xs">{i.invoice_code}</TableCell>
                    <TableCell className="font-mono text-xs">{i.organization_id ?? "—"}</TableCell>
                    <TableCell><FinanceStatusBadge status={String(i.status)} domain="invoice" /></TableCell>
                    <TableCell><AmountCell value={i.total_amount} currency={i.currency} /></TableCell>
                    <TableCell><AmountCell value={i.paid_amount} currency={i.currency} /></TableCell>
                    <TableCell className="text-xs">{i.due_date ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </section>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">حساب‌های امانی فعال</h2>
        {escRes.rows.length === 0 ? (
          <TableEmpty>حساب امانی موجود نیست.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد حساب</TableHead>
                  <TableHead>سازمان</TableHead>
                  <TableHead>تأمین‌کننده</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>مانده</TableHead>
                  <TableHead>بلوکه</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {escRes.rows.slice(0, 15).map((e) => (
                  <TableRow key={e.id} id={`escrow-${e.id}`}>
                    <TableCell className="font-mono text-xs">{e.account_code}</TableCell>
                    <TableCell className="font-mono text-xs">{e.organization_id}</TableCell>
                    <TableCell className="font-mono text-xs">{e.supplier_id ?? "—"}</TableCell>
                    <TableCell><FinanceStatusBadge status={String(e.status)} domain="escrow" /></TableCell>
                    <TableCell><AmountCell value={e.available_balance} currency={e.currency} /></TableCell>
                    <TableCell><AmountCell value={e.total_held} currency={e.currency} /></TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </section>
    </div>
  );
}
