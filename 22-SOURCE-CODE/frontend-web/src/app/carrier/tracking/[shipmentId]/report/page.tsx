import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  getTelematicsSnapshot,
  listPositions,
} from "@/lib/telematics/loaders";
import { resolveDispatchForShipment } from "@/lib/telematics/resolve-dispatch";
import {
  EventReport,
  ManualPositionForm,
  SessionControls,
} from "./report-forms";
import { LiveCapturePanel } from "./live-capture-panel";

interface PageProps {
  params: Promise<{ shipmentId: string }>;
}

export default async function CarrierTelemetryReportPage({ params }: PageProps) {
  const { shipmentId } = await params;
  const resolved = await resolveDispatchForShipment(shipmentId);

  if (!resolved) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-semibold">گزارش تله‌متری حمل‌کننده</h1>
          <p className="text-sm text-muted-foreground">
            ثبت موقعیت و وقایع تله‌متری برای اعزام تخصیص‌داده‌شده.
          </p>
        </div>
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            اعزام مرتبط با این محموله یافت نشد یا برای سازمان شما قابل مشاهده نیست.
          </CardContent>
        </Card>
      </div>
    );
  }

  const [snapshot, positions] = await Promise.all([
    getTelematicsSnapshot(resolved.dispatchId, "carrier"),
    listPositions(resolved.dispatchId, "carrier", { limit: 10 }),
  ]);

  // Session is "active" when the most recent session-scoped event is
  // session_started. recent_events is ordered DESC by created_at.
  const sessionGate = snapshot?.recent_events.find(
    (e) => e.event_type === "session_started" || e.event_type === "session_ended",
  );
  const sessionActive = sessionGate?.event_type === "session_started";
  const latest = snapshot?.latest_position ?? null;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold">گزارش تله‌متری حمل‌کننده</h1>
          <p className="text-sm text-muted-foreground">
            اعزام: <span className="font-mono text-xs">{resolved.dispatchId}</span>
            {" · "}
            وضعیت نشست:{" "}
            {sessionActive ? (
              <span className="text-emerald-700">فعال</span>
            ) : (
              <span className="text-muted-foreground">غیرفعال</span>
            )}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href={`/carrier/tracking/${shipmentId}/map`}>نقشه</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href={`/carrier/dispatches/${resolved.dispatchId}`}>
              بازگشت به اعزام
            </Link>
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-4 text-xs leading-6 text-muted-foreground">
          <div className="font-medium text-foreground mb-1">قرارداد حریم خصوصی</div>
          <ul className="list-disc pr-5 space-y-0.5">
            <li>موقعیت فقط با کلیک شما ارسال می‌شود.</li>
            <li>ردیابی پس‌زمینه فعال نیست.</li>
            <li>هیچ گزارش دوره‌ای، هیچ ردیابی پنهان و هیچ ذخیره‌سازی محلی روی دستگاه انجام نمی‌شود.</li>
          </ul>
        </CardContent>
      </Card>

      <section className="space-y-3">
        <h2 className="text-base font-semibold">۱. وضعیت فعلی</h2>
        <Card>
          <CardContent className="p-4 space-y-2 text-sm">
            <div className="font-medium">آخرین موقعیت</div>
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
                هنوز هیچ موقعیتی برای این اعزام ثبت نشده است.
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 space-y-2 text-sm">
            <div className="font-medium">رویدادهای اخیر</div>
            {snapshot?.recent_events?.length ? (
              <ul className="space-y-1 text-xs">
                {snapshot.recent_events.slice(0, 10).map((e) => (
                  <li key={e.id} className="flex flex-wrap items-center gap-2">
                    <span className="font-mono">{e.event_type}</span>
                    <span className="text-muted-foreground">{e.created_at}</span>
                    {e.actor_party ? (
                      <span className="text-muted-foreground">
                        ({e.actor_party})
                      </span>
                    ) : null}
                    {e.reason ? <span>— {e.reason}</span> : null}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-xs text-muted-foreground">
                هیچ رویداد تله‌متری ثبت نشده است.
              </p>
            )}
          </CardContent>
        </Card>
      </section>

      <section className="space-y-3">
        <h2 className="text-base font-semibold">۲. مدیریت نشست</h2>
        <SessionControls
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
          sessionActive={sessionActive}
        />
      </section>

      <section className="space-y-3">
        <h2 className="text-base font-semibold">۳. ارسال موقعیت زنده (پیشنهاد شده برای موبایل)</h2>
        <LiveCapturePanel
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <section className="space-y-3">
        <h2 className="text-base font-semibold">۴. ورود دستی مختصات (پشتیبان)</h2>
        <ManualPositionForm
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <section className="space-y-3">
        <h2 className="text-base font-semibold">۵. ثبت رویداد تله‌متری</h2>
        <EventReport
          shipmentId={shipmentId}
          dispatchId={resolved.dispatchId}
        />
      </section>

      <p className="text-xs text-muted-foreground">
        این صفحه فقط برای حمل‌کننده اعزام قابل دسترسی است و تمام نوشتارها از طریق RPCهای امن CC-45 (telematics) انجام می‌شود.
        {" "}
        تعداد نقاط اخیر برای پیش‌نمایش: {positions.length.toLocaleString("fa-IR")}.
      </p>
    </div>
  );
}
