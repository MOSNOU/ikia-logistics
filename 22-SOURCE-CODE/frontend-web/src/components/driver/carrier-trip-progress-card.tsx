import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { driverTripStatusLabel } from "@/lib/driver/trip-status";
import { faRelativeTime } from "@/lib/driver/relative-time";
import type { CarrierTripProgress } from "@/lib/driver/carrier-trip-progress";

// Phase H (v1.2, Q5) — compact carrier-facing driver progress read-back. Shows
// status, driver, vehicle, last-ping age, POD readiness, and open issue count.
// READ-ONLY; no full timeline (that stays on the admin/driver surfaces).

function shortId(value: string | null): string {
  if (!value) return "—";
  return value.length > 8 ? `${value.slice(0, 8)}…` : value;
}

export function CarrierTripProgressCard({
  executionStatus,
  driverName,
  driverUserId,
  vehicleReference,
  progress,
}: {
  executionStatus: string | null;
  driverName: string | null;
  driverUserId: string | null;
  vehicleReference: string | null;
  progress: CarrierTripProgress;
}) {
  const driver = driverName || shortId(driverUserId);

  return (
    <Card>
      <CardContent className="space-y-3 p-5">
        <div className="text-sm font-medium">پیشرفت راننده</div>
        <div className="grid gap-4 sm:grid-cols-3">
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">وضعیت اجرا</span>
            <div>
              <Badge variant="info">
                {driverTripStatusLabel(executionStatus)}
              </Badge>
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">راننده</span>
            <div className="text-sm">{driver}</div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">خودرو</span>
            <div className="text-sm">{vehicleReference ?? "—"}</div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">آخرین موقعیت</span>
            <div className="text-sm">
              {progress.lastReportedAt
                ? faRelativeTime(progress.lastReportedAt)
                : "ثبت نشده"}
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">سند تحویل</span>
            <div>
              {progress.podCount > 0 ? (
                <Badge variant="success">
                  ثبت‌شده ({progress.podCount.toLocaleString("fa-IR")})
                </Badge>
              ) : (
                <Badge variant="warning">ثبت نشده</Badge>
              )}
            </div>
          </div>
          <div className="space-y-1">
            <span className="text-xs text-muted-foreground">مشکلات باز</span>
            <div className="text-sm">
              {progress.openIssueCount.toLocaleString("fa-IR")}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
