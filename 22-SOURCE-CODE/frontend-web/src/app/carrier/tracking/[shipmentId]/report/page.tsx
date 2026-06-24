import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  getTelematicsSnapshot,
  listPositions,
} from "@/lib/telematics/loaders";
import { resolveDispatchForShipment } from "@/lib/telematics/resolve-dispatch";
import { ReportForms } from "./report-forms";

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

  // Session is "active" when the most recent session_started has no later
  // session_ended. recent_events is ordered DESC by created_at, so we walk
  // forward (newest first) and take the first session-scoped event.
  const sessionGate = snapshot?.recent_events.find(
    (e) => e.event_type === "session_started" || e.event_type === "session_ended",
  );
  const sessionActive = sessionGate?.event_type === "session_started";
  const latest = snapshot?.latest_position ?? null;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
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
        <div className="flex gap-2">
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

      <ReportForms
        shipmentId={shipmentId}
        dispatchId={resolved.dispatchId}
        sessionActive={sessionActive}
      />

      <p className="text-xs text-muted-foreground">
        این صفحه فقط برای حمل‌کننده اعزام قابل دسترسی است و تمام نوشتارها از طریق RPCهای امن CC-45 (telematics) انجام می‌شود.
        {" "}
        تعداد نقاط اخیر برای پیش‌نمایش: {positions.length.toLocaleString("fa-IR")}.
      </p>
    </div>
  );
}
