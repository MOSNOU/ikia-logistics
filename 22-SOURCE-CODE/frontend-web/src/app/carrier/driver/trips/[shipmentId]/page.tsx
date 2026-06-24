import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DispatchSummaryCard } from "@/components/dispatch/dispatch-summary-card";
import { DispatchStatusBadge } from "@/components/dispatch/dispatch-status-badge";
import { getDispatch } from "@/lib/dispatch/dispatches";
import {
  getTelematicsSnapshot,
  listPositions,
} from "@/lib/telematics/loaders";
import { resolveDispatchForShipment } from "@/lib/telematics/resolve-dispatch";
import { LiveCapturePanel } from "@/app/carrier/tracking/[shipmentId]/report/live-capture-panel";
import {
  EventReport,
  ManualPositionForm,
  SessionControls,
} from "@/app/carrier/tracking/[shipmentId]/report/report-forms";
import { DriverTripTimeline } from "@/components/tracking/driver-trip-timeline";
import { buildDriverTripTimeline } from "@/lib/telematics/build-driver-trip-timeline";

interface PageProps {
  params: Promise<{ shipmentId: string }>;
}

export default async function DriverTripDetailPage({ params }: PageProps) {
  const { shipmentId } = await params;
  const resolved = await resolveDispatchForShipment(shipmentId);

  if (!resolved) {
    return (
      <div className="space-y-5">
        <div>
          <h1 className="text-2xl font-semibold">سفر راننده</h1>
          <p className="text-sm text-muted-foreground mt-1">
            اعزام مرتبط با این محموله برای سازمان شما در دسترس نیست.
          </p>
        </div>
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            ممکن است این سفر هنوز به شما تخصیص داده نشده باشد، لغو شده باشد یا برای سازمان شما قابل مشاهده نباشد.
          </CardContent>
        </Card>
        <Button asChild variant="outline" size="sm" className="w-full sm:w-auto">
          <Link href="/carrier/driver/trips">بازگشت به فهرست سفرها</Link>
        </Button>
      </div>
    );
  }

  const [detail, snapshot, positions] = await Promise.all([
    getDispatch(resolved.dispatchId, "carrier"),
    getTelematicsSnapshot(resolved.dispatchId, "carrier"),
    listPositions(resolved.dispatchId, "carrier", { limit: 10 }),
  ]);

  const sessionGate = snapshot?.recent_events.find(
    (e) => e.event_type === "session_started" || e.event_type === "session_ended",
  );
  const sessionActive = sessionGate?.event_type === "session_started";
  const latest = snapshot?.latest_position ?? null;
  const timelineItems = buildDriverTripTimeline({
    snapshot,
    positions,
    dispatch: detail,
  });

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold">سفر راننده</h1>
          <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
            {detail ? <DispatchStatusBadge status={detail.dispatch.status} /> : null}
            <span>
              نشست تله‌متری:{" "}
              {sessionActive ? (
                <span className="text-emerald-700">فعال</span>
              ) : (
                <span>غیرفعال</span>
              )}
            </span>
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button asChild variant="outline" size="sm" className="w-full sm:w-auto">
            <Link href={`/carrier/tracking/${shipmentId}/map`}>نقشه</Link>
          </Button>
          <Button asChild variant="outline" size="sm" className="w-full sm:w-auto">
            <Link href="/carrier/driver/trips">فهرست سفرها</Link>
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-3 text-xs leading-6 text-muted-foreground">
          <ul className="list-disc pr-5 space-y-0.5">
            <li>موقعیت فقط با کلیک شما ارسال می‌شود.</li>
            <li>ردیابی پس‌زمینه در این نسخه فعال نیست.</li>
            <li>هیچ ارسال خودکار یا دوره‌ای انجام نمی‌شود.</li>
            <li>اگر ارسال ناموفق بود، داده فقط تا زمانی که این صفحه باز است نگه داشته می‌شود.</li>
          </ul>
        </CardContent>
      </Card>

      {detail ? (
        <section className="space-y-2">
          <h2 className="text-base font-semibold">خلاصه اعزام</h2>
          <DispatchSummaryCard detail={detail} />
        </section>
      ) : null}

      <section className="space-y-2">
        <h2 className="text-base font-semibold">آخرین موقعیت</h2>
        <Card>
          <CardContent className="p-4 text-sm space-y-1">
            {latest ? (
              <div className="text-xs leading-6">
                <div dir="ltr" className="font-mono">
                  {Number(latest.latitude).toFixed(5)},{" "}
                  {Number(latest.longitude).toFixed(5)}
                </div>
                <div>زمان گزارش: {latest.reported_at}</div>
                {latest.speed_kmh != null ? (
                  <div>سرعت: {latest.speed_kmh} km/h</div>
                ) : null}
                {latest.heading_degrees != null ? (
                  <div>جهت: {latest.heading_degrees}°</div>
                ) : null}
                <div>منبع: {latest.source ?? "—"}</div>
              </div>
            ) : (
              <p className="text-xs text-muted-foreground">
                هنوز هیچ موقعیتی برای این سفر ثبت نشده است.
              </p>
            )}
          </CardContent>
        </Card>
      </section>

      <section className="space-y-2 scroll-mt-4">
        <h2 className="text-base font-semibold">خط زمانی سفر</h2>
        <p className="text-[11px] text-muted-foreground">
          ترکیب رویدادهای نشست، گزارش‌های موقعیت و تغییرات وضعیت اعزام — جدیدترین مورد در بالا.
        </p>
        <DriverTripTimeline items={timelineItems} anchorId="timeline" />
      </section>

      <section className="space-y-2">
        <h2 className="text-base font-semibold">۱. مدیریت نشست</h2>
        <SessionControls
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
          sessionActive={sessionActive}
        />
      </section>

      <section className="space-y-2">
        <h2 className="text-base font-semibold">۲. ارسال موقعیت زنده</h2>
        <LiveCapturePanel
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <section className="space-y-2">
        <h2 className="text-base font-semibold">۳. ورود دستی مختصات</h2>
        <ManualPositionForm
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <section className="space-y-2">
        <h2 className="text-base font-semibold">۴. ثبت رویداد تله‌متری</h2>
        <EventReport
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <div className="flex flex-wrap gap-2 pt-2">
        <Button asChild variant="outline" size="sm" className="w-full sm:w-auto">
          <Link href={`/carrier/tracking/${shipmentId}/report`}>
            کنسول کامل تله‌متری
          </Link>
        </Button>
        <Button asChild variant="outline" size="sm" className="w-full sm:w-auto">
          <Link href={`/carrier/dispatches/${resolved.dispatchId}`}>
            صفحه اعزام
          </Link>
        </Button>
      </div>
    </div>
  );
}
