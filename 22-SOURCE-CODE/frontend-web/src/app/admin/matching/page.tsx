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
import { loadAdminMatchingSummary } from "@/lib/marketplace/find-matching";
import { listAdminShipments } from "@/lib/admin/list-shipments";

export default async function AdminMatchingPage() {
  const [summary, shipments] = await Promise.all([
    loadAdminMatchingSummary(),
    listAdminShipments({ pageSize: 50 }),
  ]);
  const eligible = shipments.rows.filter((s) =>
    ["planned", "booked", "in_transit"].includes(s.status),
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">موتور تطبیق — ادمین</h1>
        <p className="text-sm text-muted-foreground">
          KPI‌های فقط-خواندنی موتور تطبیق. تطبیق روی محاسبه آنی انجام می‌شود؛ هیچ نتیجه‌ای ذخیره نمی‌شود (Q1=A، Q6=A).
        </p>
      </div>

      {!summary ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            خلاصه تطبیق در دسترس نیست.
          </CardContent>
        </Card>
      ) : (
        <>
          <section className="grid gap-3 grid-cols-2 md:grid-cols-4">
            <MarketplaceKpiCard
              label="درخواست‌های تطبیق (مشتق‌شده)"
              value={summary.total_match_requests}
              available
              caption="شمار محموله‌های واجد شرایط"
            />
            <MarketplaceKpiCard
              label="میانگین امتیاز"
              value={Math.round(summary.average_score)}
              available
              caption="بهترین امتیاز هر محموله"
            />
            <MarketplaceKpiCard
              label="بدون تطبیق"
              value={summary.unmatched_shipments}
              available
              tone={summary.unmatched_shipments > 0 ? "warning" : "default"}
            />
            <MarketplaceKpiCard
              label="حمل‌کنندگان برتر"
              value={summary.top_carriers.length}
              available
              caption="در بازه فعلی"
            />
          </section>

          <Card>
            <CardContent className="p-4 space-y-3">
              <div className="text-sm font-medium">حمل‌کنندگان برتر</div>
              {summary.top_carriers.length === 0 ? (
                <TableEmpty>حمل‌کننده‌ای در نتایج برتر نیست.</TableEmpty>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>سازمان حمل‌کننده</TableHead>
                      <TableHead>تعداد تطبیق برتر</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {summary.top_carriers.map((tc) => (
                      <TableRow key={tc.carrier_organization_id}>
                        <TableCell className="font-mono text-xs">
                          {tc.carrier_organization_id}
                        </TableCell>
                        <TableCell className="text-xs tabular-nums">
                          {tc.matches.toLocaleString("fa-IR")}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
              <p className="text-xs text-muted-foreground">
                پنجره واجد شرایط بودن: {summary.eligibility_window}
              </p>
            </CardContent>
          </Card>
        </>
      )}

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">محموله‌های واجد شرایط (نمونه)</h2>
        {eligible.length === 0 ? (
          <TableEmpty>محموله واجد شرایط برای تطبیق وجود ندارد.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>کد</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>مود</TableHead>
                  <TableHead>عملیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {eligible.slice(0, 15).map((s) => (
                  <TableRow key={s.id}>
                    <TableCell className="font-mono text-xs">{s.shipment_code}</TableCell>
                    <TableCell className="text-xs">{s.status}</TableCell>
                    <TableCell className="text-xs">{s.transport_mode ?? "—"}</TableCell>
                    <TableCell>
                      <Button asChild variant="outline" size="sm">
                        <Link href={`/admin/matching/${s.id}`}>مشاهده تطبیق</Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </section>
    </div>
  );
}
