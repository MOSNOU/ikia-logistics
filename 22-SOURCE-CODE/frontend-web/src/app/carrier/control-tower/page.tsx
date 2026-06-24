import { Card, CardContent } from "@/components/ui/card";
import { ControlTowerKpiTile } from "@/components/control-tower/kpi-tile";
import { loadCarrierSummary } from "@/lib/control-tower/loaders";

export default async function CarrierControlTowerPage() {
  const summary = await loadCarrierSummary();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">برج کنترل حمل‌کننده</h1>
        <p className="text-sm text-muted-foreground">
          نمای فقط-خواندنی وضعیت عملیاتی سازمان حمل‌کننده شما.
        </p>
      </div>

      {!summary ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            خلاصه برج کنترل در دسترس نیست.
          </CardContent>
        </Card>
      ) : (
        <section className="grid gap-3 grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          <ControlTowerKpiTile
            label="درخواست‌های در انتظار"
            value={summary.incoming_pending}
            tone={summary.incoming_pending > 0 ? "warning" : "default"}
          />
          <ControlTowerKpiTile
            label="رزروهای پذیرفته/تأییدشده"
            value={summary.accepted_bookings}
            tone="success"
          />
          <ControlTowerKpiTile
            label="اعزام‌های فعال"
            value={summary.active_dispatches}
          />
          <ControlTowerKpiTile
            label="اعزام‌های آماده برداشت"
            value={summary.ready_dispatches}
            tone="success"
          />
          <ControlTowerKpiTile
            label="آزاد شده — ۷ روز اخیر"
            value={summary.released_recently}
          />
          <ControlTowerKpiTile
            label="رد — ۷ روز اخیر"
            value={summary.rejected_recently}
            tone={summary.rejected_recently > 0 ? "warning" : "default"}
          />
        </section>
      )}
    </div>
  );
}
