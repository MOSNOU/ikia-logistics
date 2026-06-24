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
import { listSupplierRfqs } from "@/lib/rfq/list-supplier-rfqs";
import type { InvitationStatus } from "@/types/database";

const STATUS_OPTIONS: { value: InvitationStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "invited", label: "دعوت‌شده" },
  { value: "viewed", label: "دیده‌شده" },
  { value: "accepted", label: "پذیرفته‌شده" },
  { value: "declined", label: "نپذیرفته" },
  { value: "withdrawn", label: "پس‌گرفته" },
  { value: "expired", label: "منقضی" },
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function SupplierRfqsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as InvitationStatus)
      : null;

  const { rows, pageSize } = await listSupplierRfqs({ status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">RFQهای قابل‌مشاهده</h1>
        <p className="text-sm text-muted-foreground">
          درخواست‌های خریدی که برای شما دعوت ارسال شده — مشاهده و ارسال پیشنهاد.
        </p>
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">وضعیت دعوت</label>
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
        <TableEmpty>هیچ دعوت RFQی یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>کد RFQ</TableHead>
                <TableHead>عنوان</TableHead>
                <TableHead>وضعیت RFQ</TableHead>
                <TableHead>وضعیت دعوت</TableHead>
                <TableHead>مهلت ارسال</TableHead>
                <TableHead>دعوت در</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.invitation_id}>
                  <TableCell className="font-mono text-xs">{r.rfq_code}</TableCell>
                  <TableCell>{r.title}</TableCell>
                  <TableCell><Badge variant="outline">{r.request_status}</Badge></TableCell>
                  <TableCell><Badge variant="outline">{r.invitation_status}</Badge></TableCell>
                  <TableCell className="text-xs">{r.submission_deadline ?? "—"}</TableCell>
                  <TableCell className="text-xs">{r.invited_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/supplier/rfqs/${r.request_id}`}>مشاهده</Link>
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
              <Link href={`/supplier/rfqs?status=${statusFilter ?? ""}&page=${page - 1}`}>
                قبلی
              </Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/supplier/rfqs?status=${statusFilter ?? ""}&page=${page + 1}`}>
                بعدی
              </Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
