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
import { Badge } from "@/components/ui/badge";
import { listAdminFinanceExceptions } from "@/lib/finance/list-exceptions";

const KIND_LABEL: Record<string, string> = {
  settlement_held_with_balance: "تسویه بلوکه با مانده",
  settlement_disputed: "تسویه در منازعه",
  escrow_frozen: "حساب امانی فریز",
  escrow_closed_with_balance: "حساب امانی بسته با مانده",
};

export default async function AdminFinanceExceptionsPage() {
  const rows = await listAdminFinanceExceptions();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">صف استثناهای مالی</h1>
          <p className="text-sm text-muted-foreground">
            مواردی که نیاز به بررسی دارند: تسویه‌های بلوکه با مانده، تسویه‌های در منازعه، حساب‌های امانی فریز یا بسته با مانده. این صفحه فقط نمایشی است.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/finance">داشبورد مالی</Link>
        </Button>
      </div>

      {rows.length === 0 ? (
        <TableEmpty>هیچ موردی برای بررسی وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>نوع</TableHead>
                <TableHead>کد موضوع</TableHead>
                <TableHead>سازمان</TableHead>
                <TableHead>تأمین‌کننده</TableHead>
                <TableHead>مبلغ</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={`${r.kind}-${r.subject_id}`}>
                  <TableCell><Badge variant="outline">{KIND_LABEL[r.kind] ?? r.kind}</Badge></TableCell>
                  <TableCell className="font-mono text-xs">{r.subject_code}</TableCell>
                  <TableCell className="font-mono text-xs">{r.organization_id}</TableCell>
                  <TableCell className="font-mono text-xs">{r.supplier_id ?? "—"}</TableCell>
                  <TableCell><AmountCell value={r.amount} currency={r.currency} /></TableCell>
                  <TableCell className="text-xs">{r.status_label}</TableCell>
                  <TableCell className="text-xs">{r.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={r.detail_href}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
