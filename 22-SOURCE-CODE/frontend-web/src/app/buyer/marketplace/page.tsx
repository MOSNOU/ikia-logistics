import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { MarketplaceKpiCard } from "@/components/marketplace/marketplace-kpi-card";
import { listMarketplaceKpis } from "@/lib/marketplace/list-marketplace-kpis";

export default async function BuyerMarketplacePage() {
  const kpis = await listMarketplaceKpis("buyer");

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">مارکت‌پلیس حمل‌کنندگان</h1>
        <p className="text-sm text-muted-foreground">
          نمای فقط-خواندنی مارکت‌پلیس. کشف حمل‌کنندگان و ظرفیت‌های موجود از این جا.
        </p>
      </div>

      <section className="grid gap-3 grid-cols-2 md:grid-cols-4">
        <MarketplaceKpiCard
          label="حمل‌کنندگان عمومی"
          value={kpis.carriers.count}
          available={kpis.carriers.available}
          caption="پروفایل‌های فعال با نمایش عمومی"
        />
        <MarketplaceKpiCard
          label="ظرفیت‌های قابل مشاهده"
          value={kpis.capacityListings.count}
          available={kpis.capacityListings.available}
          caption="فعال و در محدوده اعتبار"
        />
        <MarketplaceKpiCard
          label="شیپمنت‌های اخیر"
          value={kpis.recentShipmentCount}
          available
          caption="مرتبط با سازمان شما"
        />
      </section>

      <Card>
        <CardContent className="p-4 text-xs text-muted-foreground">
          فقط حمل‌کنندگانی که پروفایل خود را عمومی کرده‌اند و یک پروفایل فعال دارند در این نما دیده می‌شوند. ظرفیت‌ها زمانی در فهرست بازار قرار می‌گیرند که توسط حمل‌کننده منتشر و در محدوده تاریخ اعتبار باشند.
        </CardContent>
      </Card>

      <div className="flex gap-2">
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/marketplace/carriers">فهرست حمل‌کنندگان</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href="/buyer/marketplace/capacity">ظرفیت‌های موجود</Link>
        </Button>
      </div>
    </div>
  );
}
