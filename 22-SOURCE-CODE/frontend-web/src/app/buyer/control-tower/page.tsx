import { Card, CardContent } from "@/components/ui/card";
import { ControlTowerKpiTile } from "@/components/control-tower/kpi-tile";
import { loadBuyerSummary } from "@/lib/control-tower/loaders";

export default async function BuyerControlTowerPage() {
  const summary = await loadBuyerSummary();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">برج کنترل خریدار</h1>
        <p className="text-sm text-muted-foreground">
          نمای فقط-خواندنی وضعیت عملیاتی سازمان شما. شاخص‌ها روی محاسبه آنی هستند؛ هیچ داده‌ای ذخیره نمی‌شود.
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
            label="شیپمنت‌های فعال"
            value={summary.active_shipments}
            caption="در حال آماده‌سازی / حمل"
          />
          <ControlTowerKpiTile
            label="رزروهای در انتظار"
            value={summary.pending_bookings}
            tone={summary.pending_bookings > 0 ? "warning" : "default"}
            caption="در انتظار حمل‌کننده یا تأیید"
          />
          <ControlTowerKpiTile
            label="رزروهای تأییدشده"
            value={summary.confirmed_bookings}
            tone="success"
          />
          <ControlTowerKpiTile
            label="اعزام‌های فعال"
            value={summary.active_dispatches}
            caption="پیش‌نویس / تخصیص / آماده"
          />
          <ControlTowerKpiTile
            label="اعزام‌های آماده برداشت"
            value={summary.ready_dispatches}
            tone="success"
          />
          <ControlTowerKpiTile
            label="لغوهای ۷ روز اخیر"
            value={summary.recent_cancellations}
            tone={summary.recent_cancellations > 0 ? "warning" : "default"}
          />
        </section>
      )}
    </div>
  );
}
