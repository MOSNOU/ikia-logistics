import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { MarketplaceKpiCard } from "@/components/marketplace/marketplace-kpi-card";
import { CarrierCard } from "@/components/marketplace/carrier-card";
import { listMarketplaceKpis } from "@/lib/marketplace/list-marketplace-kpis";
import { listCarriers } from "@/lib/marketplace/list-carriers";

export default async function AdminMarketplacePage() {
  const [kpis, carriers] = await Promise.all([
    listMarketplaceKpis("admin"),
    listCarriers("admin", { pageSize: 12 }),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">مارکت‌پلیس — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای پلتفرمی مارکت‌پلیس حمل‌کنندگان و ظرفیت‌ها.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/marketplace/activity">فعالیت مارکت‌پلیس</Link>
        </Button>
      </div>

      <section className="grid gap-3 grid-cols-2 md:grid-cols-4">
        <MarketplaceKpiCard
          label="حمل‌کنندگان"
          value={kpis.carriers.count}
          available={kpis.carriers.available}
        />
        <MarketplaceKpiCard
          label="ظرفیت‌های ثبت‌شده"
          value={kpis.capacityListings.count}
          available={kpis.capacityListings.available}
          caption="کل ردیف‌های مارکت‌پلیس (هر وضعیت)"
        />
        <MarketplaceKpiCard
          label="شیپمنت‌های اخیر"
          value={kpis.recentShipmentCount}
          available
        />
      </section>

      <Card>
        <CardContent className="p-4 space-y-3">
          <div className="text-sm font-medium">توزیع شیپمنت‌ها بر اساس مود حمل</div>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>مود</TableHead>
                <TableHead>تعداد</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {kpis.shipmentsByMode.map((m) => (
                <TableRow key={String(m.mode)}>
                  <TableCell className="font-mono text-xs">{String(m.mode)}</TableCell>
                  <TableCell className="text-xs tabular-nums">{m.count.toLocaleString("fa-IR")}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">حمل‌کنندگان فعال (نمونه)</h2>
        {carriers.rows.length === 0 ? (
          <TableEmpty>حمل‌کننده‌ای ثبت نشده است.</TableEmpty>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {carriers.rows.map((c) => <CarrierCard key={c.id} carrier={c} />)}
          </div>
        )}
      </section>
    </div>
  );
}
