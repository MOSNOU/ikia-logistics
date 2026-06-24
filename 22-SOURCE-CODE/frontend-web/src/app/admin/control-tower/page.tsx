import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { ControlTowerKpiTile } from "@/components/control-tower/kpi-tile";
import { loadAdminSummary } from "@/lib/control-tower/loaders";

export default async function AdminControlTowerPage() {
  const summary = await loadAdminSummary();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">برج کنترل عملیاتی — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای فقط-خواندنی پلتفرم. شاخص‌ها روی محاسبه آنی هستند؛ هیچ داده‌ای ذخیره نمی‌شود (Q2=A).
          </p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/control-tower/activity">جریان رویدادها</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/control-tower/exceptions">صف استثناها</Link>
          </Button>
        </div>
      </div>

      {!summary ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            خلاصه ادمین در دسترس نیست.
          </CardContent>
        </Card>
      ) : (
        <section className="grid gap-3 grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          <ControlTowerKpiTile
            label="شیپمنت‌های فعال"
            value={summary.active_shipments}
          />
          <ControlTowerKpiTile
            label="رزروهای در انتظار"
            value={summary.pending_bookings}
            tone={summary.pending_bookings > 0 ? "warning" : "default"}
          />
          <ControlTowerKpiTile
            label="رزروهای تأییدشده"
            value={summary.confirmed_bookings}
            tone="success"
          />
          <ControlTowerKpiTile
            label="اعزام‌های فعال"
            value={summary.active_dispatches}
          />
          <ControlTowerKpiTile
            label="تسویه‌های در منازعه"
            value={summary.disputed_settlements}
            tone={summary.disputed_settlements > 0 ? "danger" : "default"}
          />
          <ControlTowerKpiTile
            label="اختلافات باز"
            value={summary.open_disputes}
            tone={summary.open_disputes > 0 ? "danger" : "default"}
          />
          <ControlTowerKpiTile
            label="استثناهای فعال"
            value={summary.exception_count}
            tone={summary.exception_count > 0 ? "warning" : "default"}
            caption="ترکیب ۵ دسته مشتق‌شده"
          />
        </section>
      )}
    </div>
  );
}
