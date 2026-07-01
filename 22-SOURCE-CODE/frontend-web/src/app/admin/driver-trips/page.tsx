import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listDriverTripStatuses } from "@/lib/driver/admin-list-driver-trip-statuses";
import { driverTripStatusLabel } from "@/lib/driver/trip-status";

// Phase D5 — operations/admin driver trip overview (READ-ONLY).
//
// One row per driver-assigned dispatch: execution status, last reported
// position time, open-issue count. POD counts are surfaced on the detail page
// (the list RPC returns issue counts only). Auth is enforced by the admin
// layout (requireRole platform_admin) and again by the SECURITY DEFINER RPC.

export const dynamic = "force-dynamic";

function faDateTime(value: string | null): string {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("fa-IR", {
    dateStyle: "short",
    timeStyle: "short",
  });
}

function shortId(value: string | null): string {
  if (!value) return "—";
  return value.length > 8 ? `${value.slice(0, 8)}…` : value;
}

export default async function AdminDriverTripsPage() {
  const trips = await listDriverTripStatuses({ limit: 100 });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">سفرهای رانندگان — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای فقط-خواندنی وضعیت اجرای سفرها، آخرین موقعیت گزارش‌شده و مشکلات باز
            گزارش‌شده توسط رانندگان.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/control-tower">برج کنترل</Link>
        </Button>
      </div>

      {trips.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            در حال حاضر سفری با راننده اختصاص‌یافته وجود ندارد.
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>اعزام</TableHead>
                  <TableHead>راننده</TableHead>
                  <TableHead>وضعیت اجرا</TableHead>
                  <TableHead>آخرین موقعیت</TableHead>
                  <TableHead>مشکلات باز</TableHead>
                  <TableHead className="text-end">جزئیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {trips.map((t) => (
                  <TableRow key={t.dispatchId}>
                    <TableCell className="font-mono text-xs">
                      {shortId(t.dispatchId)}
                    </TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {shortId(t.driverUserId)}
                    </TableCell>
                    <TableCell>
                      <Badge variant="info">
                        {driverTripStatusLabel(t.executionStatus)}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {faDateTime(t.lastReportedAt)}
                    </TableCell>
                    <TableCell>
                      {t.openIssueCount > 0 ? (
                        <Badge variant="warning">
                          {t.openIssueCount.toLocaleString("fa-IR")}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted-foreground">
                          {(0).toLocaleString("fa-IR")}
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="text-end">
                      <Button asChild variant="outline" size="sm">
                        <Link href={`/admin/driver-trips/${t.dispatchId}`}>
                          مشاهده
                        </Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
