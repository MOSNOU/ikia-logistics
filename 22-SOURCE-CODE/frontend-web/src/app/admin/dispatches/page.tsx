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
import { DispatchStatusBadge } from "@/components/dispatch/dispatch-status-badge";
import { listDispatches } from "@/lib/dispatch/dispatches";
import type { DispatchStatus } from "@/types/database";

const DISPATCH_STATUSES: DispatchStatus[] = [
  "draft",
  "assigned",
  "ready",
  "released",
  "cancelled",
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function AdminDispatchesPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && DISPATCH_STATUSES.includes(status as DispatchStatus)
      ? (status as DispatchStatus)
      : null;
  const { rows, pageSize } = await listDispatches("admin", { status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">اعزام‌های پلتفرم</h1>
        <p className="text-sm text-muted-foreground">
          نمای ادمین. مشاهده همه اعزام‌ها و امکان لغو فقط برای ادمین (در حالت‌های غیر-نهایی).
        </p>
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <label htmlFor="status" className="text-xs text-muted-foreground">وضعیت</label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            <option value="">همه</option>
            {DISPATCH_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>اعزامی برای نمایش وجود ندارد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>وضعیت</TableHead>
                <TableHead>رزرو</TableHead>
                <TableHead>سازمان خریدار</TableHead>
                <TableHead>سازمان حمل‌کننده</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((d) => (
                <TableRow key={d.id}>
                  <TableCell><DispatchStatusBadge status={d.status} /></TableCell>
                  <TableCell className="font-mono text-xs">{d.booking_request_id}</TableCell>
                  <TableCell className="font-mono text-xs">{d.buyer_organization_id}</TableCell>
                  <TableCell className="font-mono text-xs">{d.carrier_organization_id}</TableCell>
                  <TableCell className="text-xs">{d.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/dispatches/${d.id}`}>مشاهده</Link>
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
              <Link href={`/admin/dispatches?status=${statusFilter ?? ""}&page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/dispatches?status=${statusFilter ?? ""}&page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
