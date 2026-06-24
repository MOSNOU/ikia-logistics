import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { MarketplaceKpiCard } from "@/components/marketplace/marketplace-kpi-card";
import { listMarketplaceKpis } from "@/lib/marketplace/list-marketplace-kpis";
import { getProfile } from "@/lib/auth/get-profile";

export default async function SupplierMarketplacePage() {
  const profile = await getProfile();
  const carrierOrganizationId = profile?.primaryOrganizationId ?? null;
  const kpis = await listMarketplaceKpis("supplier", { carrierOrganizationId });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">مارکت‌پلیس — تأمین‌کننده</h1>
        <p className="text-sm text-muted-foreground">
          نمای سازمان شما در مارکت‌پلیس حمل‌کنندگان. شمارش ظرفیت‌های منتشرشده بر اساس سازمان فعال کاربر محاسبه می‌شود.
        </p>
      </div>

      <section className="grid gap-3 grid-cols-2 md:grid-cols-4">
        <MarketplaceKpiCard
          label="ظرفیت‌های منتشرشده شما"
          value={kpis.capacityListings.count}
          available={kpis.capacityListings.available}
          caption={
            kpis.capacityListings.available
              ? undefined
              : "سازمان فعال شما از نوع حمل‌کننده نیست"
          }
        />
        <MarketplaceKpiCard
          label="حمل‌کنندگان عمومی پلتفرم"
          value={kpis.carriers.count}
          available={kpis.carriers.available}
        />
        <MarketplaceKpiCard
          label="شیپمنت‌های اخیر شما"
          value={kpis.recentShipmentCount}
          available
        />
      </section>

      <Card>
        <CardContent className="p-4 text-xs text-muted-foreground space-y-1">
          <div>• «انتشار ظرفیت» اکنون با RPC marketplace.supplier_publish_capacity فعال است. ارسال موفق، یک ظرفیت با وضعیت «در دسترس» ایجاد می‌کند.</div>
          <div>• اگر سازمان فعال شما از نوع حمل‌کننده نباشد یا نقش carrier_admin روی آن نداشته باشید، پیام خطای واضح در فرم نمایش داده می‌شود.</div>
        </CardContent>
      </Card>

      <div className="flex gap-2">
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/marketplace/capacity">ظرفیت‌های من</Link>
        </Button>
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/marketplace/publish">انتشار ظرفیت</Link>
        </Button>
      </div>
    </div>
  );
}
