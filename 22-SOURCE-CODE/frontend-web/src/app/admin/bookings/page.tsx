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
import { BookingStatusBadge } from "@/components/marketplace/booking-status-badge";
import { listBookings } from "@/lib/marketplace/bookings";
import type { BookingStatus } from "@/types/database";

const BOOKING_STATUSES: BookingStatus[] = [
  "draft",
  "pending_carrier",
  "carrier_accepted",
  "carrier_rejected",
  "buyer_confirmed",
  "buyer_cancelled",
  "expired",
];

interface PageProps {
  searchParams: Promise<{ status?: string; page?: string }>;
}

export default async function AdminBookingsPage({ searchParams }: PageProps) {
  const { status, page: pageParam } = await searchParams;
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && BOOKING_STATUSES.includes(status as BookingStatus)
      ? (status as BookingStatus)
      : null;
  const { rows, pageSize } = await listBookings("admin", { status: statusFilter, page });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">رزروهای پلتفرم</h1>
        <p className="text-sm text-muted-foreground">
          نمای ادمین. مشاهده همه رزروهای مارکت‌پلیس و امکان لغو فقط برای ادمین.
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
            {BOOKING_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>رزروی پیدا نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>وضعیت</TableHead>
                <TableHead>شیپمنت</TableHead>
                <TableHead>سازمان خریدار</TableHead>
                <TableHead>سازمان حمل‌کننده</TableHead>
                <TableHead>به‌روزرسانی</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((b) => (
                <TableRow key={b.id}>
                  <TableCell><BookingStatusBadge status={b.status} /></TableCell>
                  <TableCell className="font-mono text-xs">{b.shipment_id}</TableCell>
                  <TableCell className="font-mono text-xs">{b.buyer_organization_id}</TableCell>
                  <TableCell className="font-mono text-xs">{b.carrier_organization_id}</TableCell>
                  <TableCell className="text-xs">{b.updated_at}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/bookings/${b.id}`}>مشاهده</Link>
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
              <Link href={`/admin/bookings?status=${statusFilter ?? ""}&page=${page - 1}`}>قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link href={`/admin/bookings?status=${statusFilter ?? ""}&page=${page + 1}`}>بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
