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
import {
  driverTripStatusLabel,
  DRIVER_TRIP_STATUSES,
} from "@/lib/driver/trip-status";
import { faRelativeTime } from "@/lib/driver/relative-time";
import { stallLabel, stallBadgeVariant } from "@/lib/driver/trip-progress";
import {
  tripHealth,
  TRIP_HEALTH_LABEL,
  tripHealthBadgeVariant,
} from "@/lib/driver/trip-intelligence";

// Phase D5 — operations/admin driver trip overview (READ-ONLY).
// Phase H (v1.2) — progress columns (vehicle, last-ping age, POD readiness,
// stall) + lightweight status / stalled-only filters. Auth is enforced by the
// admin layout (requireRole platform_admin) and again by the SECURITY DEFINER
// RPC. Filters are plain GET query params; no client JS.

export const dynamic = "force-dynamic";

function shortId(value: string | null): string {
  if (!value) return "—";
  return value.length > 8 ? `${value.slice(0, 8)}…` : value;
}

const KNOWN_STATUSES = new Set(DRIVER_TRIP_STATUSES.map((s) => s.status));

interface PageProps {
  searchParams: Promise<{ status?: string; stalled?: string }>;
}

export default async function AdminDriverTripsPage({ searchParams }: PageProps) {
  const sp = await searchParams;
  const statusFilter =
    sp.status && KNOWN_STATUSES.has(sp.status) ? sp.status : null;
  const stalledOnly = sp.stalled === "1";

  let trips = await listDriverTripStatuses({
    executionStatus: statusFilter,
    limit: 100,
  });
  if (stalledOnly) trips = trips.filter((t) => t.stall !== null);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">سفرهای رانندگان — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای فقط-خواندنی پیشرفت سفرها: وضعیت اجرا، خودرو، آخرین موقعیت، سند
            تحویل، مشکلات باز و وضعیت پایش.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/control-tower">برج کنترل</Link>
        </Button>
      </div>

      {/* Lightweight filters (status + stalled-only), plain GET form. */}
      <Card>
        <CardContent className="p-4">
          <form method="get" className="flex flex-wrap items-end gap-3">
            <label className="space-y-1">
              <span className="block text-xs font-medium text-muted-foreground">
                وضعیت اجرا
              </span>
              <select
                name="status"
                defaultValue={statusFilter ?? ""}
                className="h-10 rounded-md border border-input bg-background px-3 text-sm"
              >
                <option value="">همه</option>
                {DRIVER_TRIP_STATUSES.map((s) => (
                  <option key={s.status} value={s.status}>
                    {s.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex items-center gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                name="stalled"
                value="1"
                defaultChecked={stalledOnly}
                className="h-4 w-4"
              />
              فقط سفرهای دارای هشدار پایش
            </label>
            <Button type="submit" size="sm">
              اعمال فیلتر
            </Button>
            {statusFilter || stalledOnly ? (
              <Button asChild variant="outline" size="sm">
                <Link href="/admin/driver-trips">حذف فیلتر</Link>
              </Button>
            ) : null}
          </form>
        </CardContent>
      </Card>

      {trips.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            {statusFilter || stalledOnly
              ? "سفری با این فیلتر یافت نشد."
              : "در حال حاضر سفری با راننده اختصاص‌یافته وجود ندارد."}
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
                  <TableHead>خودرو</TableHead>
                  <TableHead>وضعیت اجرا</TableHead>
                  <TableHead>آخرین موقعیت</TableHead>
                  <TableHead>سند تحویل</TableHead>
                  <TableHead>مشکلات باز</TableHead>
                  <TableHead>پایش</TableHead>
                  <TableHead>سلامت</TableHead>
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
                    <TableCell className="text-xs">
                      {t.vehicleReference ?? "—"}
                    </TableCell>
                    <TableCell>
                      <Badge variant="info">
                        {driverTripStatusLabel(t.executionStatus)}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {t.lastReportedAt ? faRelativeTime(t.lastReportedAt) : "—"}
                    </TableCell>
                    <TableCell>
                      {t.hasPod ? (
                        <Badge variant="success">
                          {t.podCount.toLocaleString("fa-IR")}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted-foreground">—</span>
                      )}
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
                    <TableCell>
                      {t.stall ? (
                        <Badge variant={stallBadgeVariant(t.stall)}>
                          {stallLabel(t.stall)}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted-foreground">
                          عادی
                        </span>
                      )}
                    </TableCell>
                    <TableCell>
                      {(() => {
                        const health = tripHealth({
                          executionStatus: t.executionStatus,
                          dispatchStatus: t.dispatchStatus,
                          stall: t.stall,
                          openIssueCount: t.openIssueCount,
                          hasPod: t.hasPod,
                        });
                        return (
                          <Badge variant={tripHealthBadgeVariant(health)}>
                            {TRIP_HEALTH_LABEL[health]}
                          </Badge>
                        );
                      })()}
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
