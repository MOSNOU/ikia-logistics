import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { getDriverTripDetailAdmin } from "@/lib/driver/admin-get-driver-trip-detail";
import { driverTripStatusLabel } from "@/lib/driver/trip-status";
import {
  issueCategoryLabel,
  issueSeverityLabel,
  issueStatusLabel,
  issueStatusBadgeVariant,
  podKindLabel,
} from "@/lib/driver/issue-meta";
import { AdminDriverIssueActions } from "@/components/driver/admin-driver-issue-actions";

// Phase D5 — operations/admin driver trip detail (READ-ONLY summary + issue
// actions). Auth enforced by the admin layout (requireRole platform_admin) and
// again by the SECURITY DEFINER RPC / table RLS.

export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ dispatchId: string }>;
}

function faDateTime(value: string | null): string {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("fa-IR", { dateStyle: "short", timeStyle: "short" });
}

export default async function AdminDriverTripDetailPage({ params }: PageProps) {
  const { dispatchId } = await params;
  const trip = await getDriverTripDetailAdmin(dispatchId);

  if (!trip) {
    return (
      <div className="space-y-6">
        <Card>
          <CardContent className="space-y-3 p-5">
            <h1 className="text-xl font-semibold">سفر یافت نشد</h1>
            <p className="text-sm text-muted-foreground">
              این سفر وجود ندارد یا به آن دسترسی ندارید.
            </p>
            <Button asChild variant="outline" size="sm">
              <Link href="/admin/driver-trips">بازگشت به فهرست</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const hasLocation = trip.lastLatitude != null && trip.lastLongitude != null;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات سفر راننده — ادمین</h1>
          <p className="font-mono text-xs text-muted-foreground">
            {trip.dispatchId}
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/driver-trips">بازگشت به فهرست</Link>
        </Button>
      </div>

      {/* Summary. */}
      <Card>
        <CardContent className="grid gap-4 p-5 sm:grid-cols-2">
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">وضعیت اجرا</span>
            <div>
              <Badge variant="info">
                {driverTripStatusLabel(trip.executionStatus)}
              </Badge>
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">وضعیت اعزام</span>
            <div className="text-sm">{trip.dispatchStatus ?? "—"}</div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">راننده</span>
            <div className="font-mono text-xs">{trip.driverUserId ?? "—"}</div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">سازمان حمل‌کننده</span>
            <div className="font-mono text-xs">
              {trip.carrierOrganizationId ?? "—"}
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">
              برداشت برنامه‌ریزی‌شده
            </span>
            <div className="text-sm">{faDateTime(trip.plannedPickupAt)}</div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">پذیرش / تکمیل</span>
            <div className="text-sm">
              {faDateTime(trip.acceptedAt)} / {faDateTime(trip.completedAt)}
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">مشکلات باز</span>
            <div className="text-sm">
              {trip.openIssueCount.toLocaleString("fa-IR")}
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">اسناد تحویل</span>
            <div className="text-sm">{trip.podCount.toLocaleString("fa-IR")}</div>
          </div>
        </CardContent>
      </Card>

      {/* Last location. */}
      <Card>
        <CardContent className="space-y-2 p-5">
          <h2 className="text-sm font-semibold">آخرین موقعیت گزارش‌شده</h2>
          {hasLocation ? (
            <div className="text-sm text-muted-foreground">
              <div>
                مختصات:{" "}
                <span className="font-mono text-foreground">
                  {trip.lastLatitude}, {trip.lastLongitude}
                </span>
              </div>
              <div>زمان: {faDateTime(trip.lastReportedAt)}</div>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              هنوز موقعیتی برای این سفر گزارش نشده است.
            </p>
          )}
        </CardContent>
      </Card>

      {/* Issues + admin actions. */}
      <Card>
        <CardContent className="space-y-3 p-5">
          <h2 className="text-sm font-semibold">مشکلات گزارش‌شده</h2>
          {trip.issues.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              هیچ مشکلی برای این سفر گزارش نشده است.
            </p>
          ) : (
            <ul className="space-y-3">
              {trip.issues.map((issue) => (
                <li
                  key={issue.id}
                  className="space-y-2 rounded-lg border border-border-soft p-3"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm font-medium">
                        {issueCategoryLabel(issue.category)}
                      </span>
                      <Badge variant={issueStatusBadgeVariant(issue.status)}>
                        {issueStatusLabel(issue.status)}
                      </Badge>
                      <Badge variant="muted">
                        شدت: {issueSeverityLabel(issue.severity)}
                      </Badge>
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {faDateTime(issue.reportedAt)}
                    </span>
                  </div>
                  {issue.description ? (
                    <p className="text-sm leading-7 text-muted-foreground">
                      {issue.description}
                    </p>
                  ) : null}
                  {issue.resolutionNote ? (
                    <p className="text-xs leading-6 text-emerald-600 dark:text-emerald-400">
                      یادداشت حل: {issue.resolutionNote}
                    </p>
                  ) : null}
                  <AdminDriverIssueActions
                    issueId={issue.id}
                    dispatchId={trip.dispatchId}
                    status={issue.status}
                  />
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      {/* PODs. */}
      <Card>
        <CardContent className="space-y-3 p-5">
          <h2 className="text-sm font-semibold">اسناد تحویل</h2>
          {trip.pods.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              هنوز سند تحویلی بارگذاری نشده است.
            </p>
          ) : (
            <ul className="space-y-2">
              {trip.pods.map((pod) => (
                <li
                  key={pod.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-md border border-border-soft p-3 text-sm"
                >
                  <span className="font-medium">{podKindLabel(pod.kind)}</span>
                  <span className="font-mono text-xs text-muted-foreground">
                    {pod.fileId ?? "—"}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {faDateTime(pod.createdAt)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      {/* Event timeline. */}
      <Card>
        <CardContent className="space-y-3 p-5">
          <h2 className="text-sm font-semibold">سابقه رویدادها</h2>
          {trip.events.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              رویدادی برای این سفر ثبت نشده است.
            </p>
          ) : (
            <ol className="space-y-2">
              {trip.events.map((ev) => (
                <li
                  key={ev.id}
                  className="flex flex-wrap items-center justify-between gap-2 border-b border-border-soft pb-2 text-sm last:border-0"
                >
                  <span>
                    {driverTripStatusLabel(ev.fromStatus)} →{" "}
                    <span className="font-medium">
                      {driverTripStatusLabel(ev.toStatus)}
                    </span>
                    {ev.reason ? (
                      <span className="text-xs text-muted-foreground">
                        {" "}
                        ({ev.reason})
                      </span>
                    ) : null}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {faDateTime(ev.createdAt)}
                  </span>
                </li>
              ))}
            </ol>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
