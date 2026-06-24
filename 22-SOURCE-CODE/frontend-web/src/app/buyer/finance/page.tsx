import Link from "next/link";
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
import { KpiTile } from "@/components/finance/kpi-tile";
import { AmountCell } from "@/components/finance/amount-cell";
import { FinanceStatusBadge } from "@/components/finance/status-badge";
import { listInvoices } from "@/lib/finance/list-invoices";
import { listBuyerSettlements } from "@/lib/settlement/list-buyer-settlements";
import { listOrgEscrowAccounts } from "@/lib/finance/list-escrow-accounts";
import { computeFinanceKpis } from "@/lib/finance/compute-kpis";

export default async function BuyerFinanceDashboardPage() {
  const [invRes, setRes, escrow] = await Promise.all([
    listInvoices("buyer", { pageSize: 100 }),
    listBuyerSettlements({ pageSize: 100 }),
    listOrgEscrowAccounts(),
  ]);
  const kpis = computeFinanceKpis({
    invoices: invRes.rows,
    settlements: setRes.rows,
    escrowAccounts: escrow,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">داشبورد مالی خریدار</h1>
          <p className="text-sm text-muted-foreground">
            نمای یکپارچه روی فاکتورها، تسویه‌ها و حساب‌های امانی. این صفحه فقط نمایشی است.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/finance/settlements">نمای تسویه‌ها</Link>
        </Button>
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
          <KpiTile label="برنامه‌ریزی‌شده" amount={kpis.settlements.plannedAmount} currency={kpis.currency} />
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
          <TableEmpty>فاکتوری ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد</TableHead>
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

      {escrow.length > 0 ? (
        <section className="space-y-2">
          <h2 className="text-sm font-medium text-muted-foreground">حساب‌های امانی</h2>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد حساب</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>مانده</TableHead>
                  <TableHead>بلوکه</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {escrow.slice(0, 10).map((e) => (
                  <TableRow key={e.id}>
                    <TableCell className="font-mono text-xs">{e.account_code}</TableCell>
                    <TableCell><FinanceStatusBadge status={String(e.status)} domain="escrow" /></TableCell>
                    <TableCell><AmountCell value={e.available_balance} currency={e.currency} /></TableCell>
                    <TableCell><AmountCell value={e.total_held} currency={e.currency} /></TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </section>
      ) : (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            هیچ حساب امانی برای این سازمان قابل مشاهده نیست (یا RLS اجازه دسترسی نمی‌دهد).
          </CardContent>
        </Card>
      )}
    </div>
  );
}
