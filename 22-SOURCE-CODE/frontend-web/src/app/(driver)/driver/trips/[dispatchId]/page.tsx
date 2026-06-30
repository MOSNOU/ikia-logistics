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
import { cn } from "@/lib/utils";

// Phase D3 — driver trip detail. Workflow transition actions are LIVE via
// TripActionPanel (D1 RPCs). GPS / POD / issue sections remain D4+ placeholders.

interface PageProps {
  params: Promise<{ dispatchId: string }>;
}

const D4_HINT = "در فاز D4 فعال می‌شود";
const LATER_HINT = "در فاز بعدی فعال می‌شود";

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

      {/* موقعیت مکانی — placeholder. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">موقعیت مکانی</h2>
          <p className="text-xs leading-6 text-muted-foreground">
            ارسال موقعیت در این نسخه فعال نیست. هیچ ارسال خودکار یا پس‌زمینه‌ای
            انجام نمی‌شود.
          </p>
          <Button disabled size="sm" className="h-11 w-full">
            ارسال موقعیت — {D4_HINT}
          </Button>
        </CardContent>
      </Card>

      {/* اسناد تحویل — placeholder. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">اسناد تحویل</h2>
          <p className="text-xs leading-6 text-muted-foreground">
            بارگذاری مدارک تحویل (POD) در فاز بعد اضافه می‌شود.
          </p>
          <Button disabled variant="outline" size="sm" className="h-11 w-full">
            بارگذاری سند تحویل — {D4_HINT}
          </Button>
        </CardContent>
      </Card>

      {/* گزارش مشکل — placeholder. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">گزارش مشکل</h2>
          <p className="text-xs leading-6 text-muted-foreground">
            ثبت مشکل یا تأخیر در فاز بعد فعال می‌شود.
          </p>
          <Button disabled variant="outline" size="sm" className="h-11 w-full">
            گزارش مشکل — {LATER_HINT}
          </Button>
        </CardContent>
      </Card>

      {/* Live workflow action — only the next legal transition is shown. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">اقدام بعدی سفر</h2>
          <TripActionPanel dispatchId={trip.dispatchId} executionStatus={trip.executionStatus} />
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
