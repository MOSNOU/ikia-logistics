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
import { listSupplierExecuted } from "@/lib/contract/list-supplier-contracts";
import type { ContractStatus } from "@/types/database";

const STATUS_OPTIONS: { value: ContractStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft_execution", label: "پیش‌نویس اجرایی" },
  { value: "pending_signatures", label: "انتظار امضا" },
  { value: "partially_signed", label: "بخشی امضاشده" },
  { value: "executed", label: "اجرا شده" },
  { value: "cancelled", label: "لغوشده" },
  { value: "voided", label: "ابطال‌شده" },
  { value: "superseded", label: "جایگزین شده" },
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function SupplierContractsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as ContractStatus)
      : null;

  const { rows, pageSize } = await listSupplierExecuted({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">قراردادهای من</h1>
        <p className="text-sm text-muted-foreground">
          قراردادهای اجرایی که شما به‌عنوان تأمین‌کننده طرف آن هستید — درخواست‌های امضا و وضعیت اجرا.
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
        <TableEmpty>قراردادی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>RFQ</TableHead>
                <TableHead>پیشنهاد</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((c) => (
                <TableRow key={c.id}>
                  <TableCell className="font-mono text-xs">{c.contract_code}</TableCell>
                  <TableCell>{c.title}</TableCell>
                  <TableCell className="font-mono text-xs">{c.request_id}</TableCell>
                  <TableCell className="font-mono text-xs">{c.offer_id}</TableCell>
                  <TableCell><Badge variant="outline">{c.status}</Badge></TableCell>
                  <TableCell className="text-xs">{c.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/contracts/${c.id}`}>مشاهده</Link>
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
              <Link href={`/supplier/contracts?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/supplier/contracts?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
