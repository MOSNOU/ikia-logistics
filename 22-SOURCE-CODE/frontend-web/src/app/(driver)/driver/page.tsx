import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { listMyTrips } from "@/lib/driver/list-my-trips";
import { driverTripStatusLabel, driverNextAction } from "@/lib/driver/trip-status";

// Phase D2 — driver dashboard (READ-ONLY). Active trip + assigned trips list.
// No mutations: every action either navigates to detail or is a disabled
// placeholder.

const ACTIVE_STATUSES = new Set([
  "assigned",
  "accepted",
  "arrived_at_pickup",
  "loading_started",
  "loaded",
  "in_transit",
  "arrived_at_delivery",
  "unloading_started",
]);

export default async function DriverDashboardPage() {
  const trips = await listMyTrips({ limit: 50 });
  const activeTrip = trips.find((t) => ACTIVE_STATUSES.has(t.status ?? "")) ?? trips[0] ?? null;

  return (
    <div className="space-y-5">
      {/* Header card. */}
      <Card className="border-border-soft shadow-elevated">
        <CardContent className="space-y-2 p-5">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h1 className="text-xl font-semibold tracking-tight">داشبورد راننده</h1>
            <Badge variant="info">
              {trips.length.toLocaleString("fa-IR")} سفر
            </Badge>
          </div>
          <p className="text-sm leading-7 text-muted-foreground">
            سفرهای اختصاص‌یافته به شما. روی هر سفر برای مشاهده جزئیات ضربه بزنید.
          </p>
        </CardContent>
      </Card>

      {trips.length === 0 ? (
        <Card className="border-border-soft">
          <CardContent className="p-4 text-sm text-muted-foreground">
            در حال حاضر سفری به شما اختصاص داده نشده است.
          </CardContent>
        </Card>
      ) : (
        <>
          {/* Active trip card. */}
          {activeTrip ? (
            <Card className="border-border-soft shadow-card">
              <CardContent className="space-y-3 p-4">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-xs font-medium text-muted-foreground">
                    سفر فعال
                  </span>
                  <Badge variant="info">
                    {driverTripStatusLabel(activeTrip.status)}
                  </Badge>
                </div>
                <div className="space-y-1 text-sm">
                  {activeTrip.routeSummary ? (
                    <div className="font-medium">{activeTrip.routeSummary}</div>
                  ) : (
                    <div className="text-xs text-muted-foreground">
                      خلاصه مسیر در دسترس نیست.
                    </div>
                  )}
                  <div className="text-xs leading-6 text-muted-foreground">
                    اعزام:{" "}
                    <span className="font-mono text-foreground">
                      {activeTrip.dispatchId}
                    </span>
                  </div>
                  {(() => {
                    const next = driverNextAction(activeTrip.status);
                    const label =
                      next === "complete-gated"
                        ? "تکمیل سفر (پس از سند تحویل)"
                        : next && next !== null
                          ? next.label
                          : null;
                    return label ? (
                      <div className="text-xs font-medium text-primary">
                        اقدام بعدی: {label}
                      </div>
                    ) : null;
                  })()}
                </div>
                <Button asChild size="sm" className="h-11 w-full">
                  <Link href={`/driver/trips/${activeTrip.dispatchId}`}>
                    باز کردن سفر
                  </Link>
                </Button>
              </CardContent>
            </Card>
          ) : null}

          {/* Quick status summary chip row. */}
          <div className="flex flex-wrap gap-2">
            <Badge variant="muted">
              کل: {trips.length.toLocaleString("fa-IR")}
            </Badge>
            <Badge variant="info">
              فعال:{" "}
              {trips
                .filter((t) => ACTIVE_STATUSES.has(t.status ?? ""))
                .length.toLocaleString("fa-IR")}
            </Badge>
          </div>

          {/* Assigned trips list. */}
          <section className="space-y-2">
            <h2 className="text-sm font-semibold tracking-tight">سفرهای اختصاص‌یافته</h2>
            <ul className="space-y-3">
              {trips.map((t) => (
                <li key={t.dispatchId}>
                  <Card className="border-border-soft shadow-card">
                    <CardContent className="space-y-3 p-4">
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <Badge variant="secondary">
                          {driverTripStatusLabel(t.status)}
                        </Badge>
                        {t.plannedPickupAt ? (
                          <span className="text-[11px] text-muted-foreground">
                            برداشت: {t.plannedPickupAt}
                          </span>
                        ) : null}
                      </div>
                      <div className="space-y-1 text-sm">
                        {t.routeSummary ? (
                          <div className="font-medium">{t.routeSummary}</div>
                        ) : (
                          <div className="text-xs text-muted-foreground">
                            خلاصه مسیر در دسترس نیست.
                          </div>
                        )}
                        <div className="text-xs leading-6 text-muted-foreground">
                          اعزام:{" "}
                          <span className="font-mono text-foreground">
                            {t.dispatchId}
                          </span>
                          {t.vehicleReference ? (
                            <div>
                              خودرو:{" "}
                              <span className="font-mono text-foreground">
                                {t.vehicleReference}
                              </span>
                            </div>
                          ) : null}
                        </div>
                      </div>
                      <Button
                        asChild
                        variant="outline"
                        size="sm"
                        className="h-11 w-full"
                      >
                        <Link href={`/driver/trips/${t.dispatchId}`}>
                          مشاهده جزئیات
                        </Link>
                      </Button>
                    </CardContent>
                  </Card>
                </li>
              ))}
            </ul>
          </section>
        </>
      )}

      <p className="text-[11px] leading-6 text-muted-foreground">
        برای ثبت اقدام روی هر سفر، صفحه جزئیات آن را باز کنید.
      </p>
    </div>
  );
}
