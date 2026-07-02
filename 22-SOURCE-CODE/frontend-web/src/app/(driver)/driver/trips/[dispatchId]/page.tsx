import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { getTrip } from "@/lib/driver/get-trip";
import {
  DRIVER_TRIP_STATUSES,
  driverTripStatusIndex,
  driverTripStatusLabel,
  stepTimestampFromEvents,
} from "@/lib/driver/trip-status";
import { faShortDateTime, faRelativeTime } from "@/lib/driver/relative-time";
import { tripProgressPercent } from "@/lib/driver/trip-intelligence";
import { TripActionPanel } from "@/components/driver/trip-action-panel";
import { DriverLocationPanel } from "@/components/driver/driver-location-panel";
import { PodUploadPanel } from "@/components/driver/pod-upload-panel";
import { PodReadinessPanel } from "@/components/driver/pod-readiness-panel";
import { DriverIssuePanel } from "@/components/driver/driver-issue-panel";
import { TripTimeline } from "@/components/driver/trip-timeline";
import { TrackingReadinessDebugPanel } from "@/components/driver/tracking-readiness-debug-panel";
import { cn } from "@/lib/utils";

// Phase G (v1.2) — driver trip detail. Primary next-action surfaced first for
// mobile; status stepper carries milestone timestamps (event ledger, fallback
// row timestamps); last-ping age, read-only POD readiness, and the driver event
// timeline are shown. Live actions: transitions, GPS, POD upload, issue report.

export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ dispatchId: string }>;
}

export default async function DriverTripDetailPage({ params }: PageProps) {
  const { dispatchId } = await params;
  const trip = await getTrip(dispatchId);

  // Graceful "not found / no access" — never crash on an invalid id.
  if (!trip) {
    return (
      <div className="space-y-4">
        <Card className="border-border-soft">
          <CardContent className="space-y-3 p-5">
            <h1 className="text-lg font-semibold tracking-tight">سفر یافت نشد</h1>
            <p className="text-sm leading-7 text-muted-foreground">
              این سفر وجود ندارد یا به شما اختصاص داده نشده است.
            </p>
            <Button asChild variant="outline" size="sm" className="h-11">
              <Link href="/driver">بازگشت به داشبورد</Link>
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const currentStatus = trip.status ?? "assigned";
  const currentIndex = driverTripStatusIndex(currentStatus);

  // Milestone timestamp per step: event ledger first, then row fallbacks (Q7).
  const stepTimestamp = (status: string): string | null => {
    const fromEvents = stepTimestampFromEvents(trip.events, status);
    if (fromEvents) return fromEvents;
    if (status === "assigned") return trip.createdAt;
    if (status === "accepted") return trip.acceptedAt;
    if (status === "completed") return trip.completedAt;
    return null;
  };

  const hasLastPing = trip.lastLatitude != null && trip.lastLongitude != null;

  return (
    <div className="space-y-5">
      {/* Trip header. */}
      <Card className="border-border-soft shadow-elevated">
        <CardContent className="space-y-2 p-5">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h1 className="text-lg font-semibold tracking-tight">جزئیات سفر</h1>
            <Badge variant="info">{driverTripStatusLabel(currentStatus)}</Badge>
          </div>
          {trip.routeSummary ? (
            <div className="text-sm font-medium">{trip.routeSummary}</div>
          ) : (
            <div className="text-xs text-muted-foreground">
              خلاصه مسیر در دسترس نیست.
            </div>
          )}
          <div className="text-xs leading-6 text-muted-foreground">
            <div>
              اعزام:{" "}
              <span className="break-all font-mono text-foreground">
                {trip.dispatchId}
              </span>
            </div>
            {trip.vehicleReference ? (
              <div>
                خودرو:{" "}
                <span className="break-all font-mono text-foreground">
                  {trip.vehicleReference}
                </span>
              </div>
            ) : null}
            {trip.driverName ? <div>راننده: {trip.driverName}</div> : null}
            {trip.plannedPickupAt ? (
              <div>برداشت برنامه‌ریزی‌شده: {faShortDateTime(trip.plannedPickupAt)}</div>
            ) : null}
          </div>
        </CardContent>
      </Card>

      {/* Primary action — surfaced first on mobile. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">اقدام بعدی سفر</h2>
          <TripActionPanel
            dispatchId={trip.dispatchId}
            executionStatus={trip.executionStatus}
            hasPod={trip.hasPod}
          />
          <p className="text-[11px] leading-6 text-muted-foreground">
            فقط اقدام مجاز برای وضعیت فعلی نمایش داده می‌شود.
          </p>
        </CardContent>
      </Card>

      {/* Status stepper — 10 D1 execution statuses with milestone timestamps. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="text-sm font-semibold tracking-tight">وضعیت سفر</h2>
            <span className="text-xs font-medium text-muted-foreground">
              پیشرفت: {tripProgressPercent(currentStatus).toLocaleString("fa-IR")}٪
            </span>
          </div>
          {/* Progress bar (read-only). */}
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
            <div
              className="h-full rounded-full bg-primary transition-all"
              style={{ width: `${tripProgressPercent(currentStatus)}%` }}
            />
          </div>
          <ol className="space-y-2">
            {DRIVER_TRIP_STATUSES.map((step, idx) => {
              const isCurrent = idx === currentIndex;
              const isDone = currentIndex > -1 && idx < currentIndex;
              const ts = isDone || isCurrent ? stepTimestamp(step.status) : null;
              return (
                <li key={step.status} className="flex items-center gap-3">
                  <span
                    className={cn(
                      "flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[11px] font-semibold",
                      isCurrent
                        ? "bg-primary text-primary-foreground"
                        : isDone
                          ? "bg-sky-100 text-sky-900 dark:bg-sky-900/30 dark:text-sky-200"
                          : "bg-muted text-muted-foreground",
                    )}
                  >
                    {(idx + 1).toLocaleString("fa-IR")}
                  </span>
                  <div className="min-w-0 flex-1">
                    <span
                      className={cn(
                        "text-sm",
                        isCurrent
                          ? "font-semibold text-foreground"
                          : "text-muted-foreground",
                      )}
                    >
                      {step.label}
                    </span>
                    {ts ? (
                      <div className="text-[11px] leading-5 text-muted-foreground">
                        {faShortDateTime(ts)}
                      </div>
                    ) : null}
                  </div>
                </li>
              );
            })}
          </ol>
        </CardContent>
      </Card>

      {/* سابقه سفر — driver-visible event timeline. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">سابقه سفر</h2>
          <TripTimeline events={trip.events} />
        </CardContent>
      </Card>

      {/* موقعیت مکانی — manual one-shot GPS send (D4) + last-ping age. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">موقعیت مکانی</h2>
          <div className="text-xs text-muted-foreground">
            آخرین ارسال موقعیت:{" "}
            <span className="font-medium text-foreground">
              {hasLastPing ? faRelativeTime(trip.lastReportedAt) : "ثبت نشده"}
            </span>
          </div>
          <DriverLocationPanel dispatchId={trip.dispatchId} />
        </CardContent>
      </Card>

      {/* اسناد تحویل — read-only readiness (G) + POD upload (D4). */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">اسناد تحویل</h2>
          <PodReadinessPanel
            podCount={trip.podCount}
            podKinds={trip.podKinds}
            hasPod={trip.hasPod}
          />
          <PodUploadPanel dispatchId={trip.dispatchId} />
        </CardContent>
      </Card>

      {/* گزارش مشکل — issue reporting (D5). */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">گزارش مشکل</h2>
          <DriverIssuePanel dispatchId={trip.dispatchId} />
        </CardContent>
      </Card>

      {/* Phase K — background tracking readiness (development builds only). */}
      {process.env.NODE_ENV !== "production" ? (
        <TrackingReadinessDebugPanel />
      ) : null}

      <Button asChild variant="outline" size="sm" className="h-11 w-full">
        <Link href="/driver">بازگشت به داشبورد</Link>
      </Button>
    </div>
  );
}
