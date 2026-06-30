import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { getTrip } from "@/lib/driver/get-trip";
import {
  DRIVER_TRIP_STATUSES,
  driverTripStatusIndex,
  driverTripStatusLabel,
} from "@/lib/driver/trip-status";
import { TripActionPanel } from "@/components/driver/trip-action-panel";
import { DriverLocationPanel } from "@/components/driver/driver-location-panel";
import { PodUploadPanel } from "@/components/driver/pod-upload-panel";
import { DriverIssuePanel } from "@/components/driver/driver-issue-panel";
import { cn } from "@/lib/utils";

// Phase D5 — driver trip detail. Workflow transition actions are LIVE via
// TripActionPanel (D1 RPCs). Manual GPS send (DriverLocationPanel), POD upload
// (PodUploadPanel) and issue reporting (DriverIssuePanel) are LIVE.

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

  // Placeholder current status when the loader has none yet.
  const currentStatus = trip.status ?? "assigned";
  const currentIndex = driverTripStatusIndex(currentStatus);

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
              <span className="font-mono text-foreground">{trip.dispatchId}</span>
            </div>
            {trip.vehicleReference ? (
              <div>
                خودرو:{" "}
                <span className="font-mono text-foreground">
                  {trip.vehicleReference}
                </span>
              </div>
            ) : null}
            {trip.driverName ? <div>راننده: {trip.driverName}</div> : null}
            {trip.plannedPickupAt ? (
              <div>برداشت برنامه‌ریزی‌شده: {trip.plannedPickupAt}</div>
            ) : null}
          </div>
        </CardContent>
      </Card>

      {/* Status stepper — 10 D1 execution statuses in order. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">وضعیت سفر</h2>
          <ol className="space-y-2">
            {DRIVER_TRIP_STATUSES.map((step, idx) => {
              const isCurrent = idx === currentIndex;
              const isDone = currentIndex > -1 && idx < currentIndex;
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
                </li>
              );
            })}
          </ol>
        </CardContent>
      </Card>

      {/* موقعیت مکانی — manual one-shot GPS send (D4). */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">موقعیت مکانی</h2>
          <DriverLocationPanel dispatchId={trip.dispatchId} />
        </CardContent>
      </Card>

      {/* اسناد تحویل — POD upload (D4). */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">اسناد تحویل</h2>
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

      {/* Live workflow action — only the next legal transition is shown. */}
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

      <Button asChild variant="outline" size="sm" className="h-11 w-full">
        <Link href="/driver">بازگشت به داشبورد</Link>
      </Button>
    </div>
  );
}
