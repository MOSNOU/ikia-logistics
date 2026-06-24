import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DispatchStatusBadge } from "@/components/dispatch/dispatch-status-badge";
import { DriverTripTelemetryStatus } from "@/components/tracking/driver-trip-telemetry-status";
import { listDriverTrips } from "@/lib/telematics/list-driver-trips";

export default async function DriverTripsListPage() {
  const trips = await listDriverTrips({ limit: 50 });

  return (
    <div className="space-y-5">
      {/* CC-54 hero — premium elevated card with shipment count chip. */}
      <Card className="border-border-soft shadow-elevated">
        <CardContent className="p-5 space-y-2">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h1 className="text-2xl font-semibold tracking-tight">
              کنسول راننده — سفرها
            </h1>
            <Badge variant="info">
              {trips.length.toLocaleString("fa-IR")} سفر
            </Badge>
          </div>
          <p className="text-sm leading-7 text-muted-foreground">
            فهرست اعزام‌های فعال شما. روی هر سفر برای مشاهده جزئیات و ابزار ردیابی
            ضربه بزنید.
          </p>
        </CardContent>
      </Card>

      {/* CC-54 secondary surface — muted banner for the safety contract. */}
      <Card className="bg-surface-muted border-border-soft shadow-none">
        <CardContent className="p-3 text-xs leading-6 text-muted-foreground">
          <ul className="list-disc pr-5 space-y-0.5">
            <li>موقعیت فقط با کلیک شما ارسال می‌شود.</li>
            <li>ردیابی پس‌زمینه در این نسخه فعال نیست.</li>
            <li>هیچ ارسال خودکار یا دوره‌ای انجام نمی‌شود.</li>
          </ul>
        </CardContent>
      </Card>

      {trips.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            هیچ سفری به شما اختصاص داده نشده است. پس از تخصیص اعزام توسط خریدار،
            سفرها در این صفحه ظاهر می‌شوند.
          </CardContent>
        </Card>
      ) : (
        <ul className="space-y-3">
          {trips.map((t) => (
            <li key={t.dispatchId}>
              <Card className="border-border-soft shadow-card">
                <CardContent className="p-4 space-y-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <DispatchStatusBadge status={t.status} />
                    {t.transportMode ? (
                      <span className="text-[11px] text-muted-foreground">
                        حمل: {t.transportMode}
                      </span>
                    ) : null}
                  </div>

                  <div className="space-y-1 text-sm">
                    {t.routeSummary ? (
                      <div className="font-medium">{t.routeSummary}</div>
                    ) : (
                      <div className="text-muted-foreground text-xs">
                        خلاصه مسیر در دسترس نیست.
                      </div>
                    )}
                    <div className="text-xs leading-6 text-muted-foreground">
                      <div>
                        اعزام:{" "}
                        <span className="font-mono text-foreground">{t.dispatchId}</span>
                      </div>
                      {t.shipmentId ? (
                        <div>
                          محموله:{" "}
                          <span className="font-mono text-foreground">
                            {t.shipmentId}
                          </span>
                        </div>
                      ) : (
                        <div>محموله مرتبط برای سازمان شما قابل مشاهده نیست.</div>
                      )}
                      {t.plannedPickupAt ? (
                        <div>برداشت برنامه‌ریزی‌شده: {t.plannedPickupAt}</div>
                      ) : null}
                      {t.vehicleReference ? (
                        <div>
                          خودرو:{" "}
                          <span className="font-mono text-foreground">
                            {t.vehicleReference}
                          </span>
                        </div>
                      ) : null}
                      {t.driverName ? <div>راننده: {t.driverName}</div> : null}
                    </div>
                  </div>

                  {/* CC-55 — compact telemetry health row.
                      Reads only from already-loaded DriverTrip fields (CC-53
                      batch RPC); no per-trip fetch. */}
                  <DriverTripTelemetryStatus
                    sessionActive={t.sessionActive}
                    stalenessStatus={t.stalenessStatus}
                    lastPositionAt={t.lastPositionAt ?? null}
                    lastEventType={t.lastEventType ?? null}
                    positionCount={t.positionCount}
                    eventCount={t.eventCount}
                  />

                  <div className="grid grid-cols-1 gap-2 sm:flex sm:flex-wrap sm:gap-2">
                    {t.shipmentId ? (
                      <>
                        <Button asChild size="sm" className="w-full sm:w-auto">
                          <Link href={`/carrier/driver/trips/${t.shipmentId}`}>
                            باز کردن سفر
                          </Link>
                        </Button>
                        <Button
                          asChild
                          variant="outline"
                          size="sm"
                          className="w-full sm:w-auto"
                        >
                          <Link href={`/carrier/tracking/${t.shipmentId}/report`}>
                            گزارش تله‌متری
                          </Link>
                        </Button>
                        <Button
                          asChild
                          variant="outline"
                          size="sm"
                          className="w-full sm:w-auto"
                        >
                          <Link href={`/carrier/tracking/${t.shipmentId}/map`}>
                            نقشه
                          </Link>
                        </Button>
                      </>
                    ) : null}
                    <Button
                      asChild
                      variant="outline"
                      size="sm"
                      className="w-full sm:w-auto"
                    >
                      <Link href={`/carrier/dispatches/${t.dispatchId}`}>
                        صفحه اعزام
                      </Link>
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </li>
          ))}
        </ul>
      )}

      <p className="text-[11px] text-muted-foreground">
        داده‌ها از طریق RPCهای CC-43 (dispatch) و CC-39 (marketplace) با اعمال RLS بارگذاری می‌شوند.
        {" "}
        تعداد سفرهای نمایش‌داده‌شده: {trips.length.toLocaleString("fa-IR")}.
      </p>
    </div>
  );
}
