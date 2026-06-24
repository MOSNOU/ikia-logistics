import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { KpiCard } from "@/components/executive/kpi-card";
import { OperationsTimeline } from "@/components/executive/operations-timeline";
import { RiskPanel } from "@/components/executive/risk-panel";
import { ActionLinkGrid } from "@/components/executive/action-link-grid";
import { loadBuyerExecutiveDashboard } from "@/lib/executive/load-buyer-executive-dashboard";
import { getProfile } from "@/lib/auth/get-profile";

export default async function BuyerExecutiveDashboardPage() {
  const profile = await getProfile();
  const bundle = await loadBuyerExecutiveDashboard({
    primaryOrganizationId: profile?.primaryOrganizationId ?? null,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد اجرایی — خریدار</h1>
        <p className="text-sm text-muted-foreground">
          نمای فقط-خواندنی وضعیت سازمان شما. RFQ، پیشنهادها، ارزیابی، قرارداد، شیپمنت، تسویه، اختلاف، KYC و اعلان‌ها در یک نگاه.
        </p>
      </div>

      {bundle.unavailableSections.length > 0 ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground space-y-1">
            {bundle.unavailableSections.map((u) => <div key={u}>• {u}</div>)}
          </CardContent>
        </Card>
      ) : null}

      <section className="space-y-2">
        <h2 className="text-sm font-medium text-muted-foreground">شاخص‌های کلیدی</h2>
        <div className="grid gap-3 grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          {bundle.kpis.map((k) => <KpiCard key={k.id} kpi={k} />)}
        </div>
      </section>

      <OperationsTimeline steps={bundle.pipeline} />

      <RiskPanel items={bundle.risks} />

      <Card>
        <CardContent className="p-4 space-y-3">
          <div className="text-sm font-medium">فعالیت اخیر</div>
          {bundle.activity.length === 0 ? (
            <TableEmpty>فعالیتی برای نمایش وجود ندارد.</TableEmpty>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>دسته</TableHead>
                  <TableHead>موضوع</TableHead>
                  <TableHead>توضیح</TableHead>
                  <TableHead>زمان</TableHead>
                  <TableHead>عملیات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {bundle.activity.map((a) => (
                  <TableRow key={a.id}>
                    <TableCell><Badge variant="outline">{a.category}</Badge></TableCell>
                    <TableCell className="font-mono text-xs">{a.subject}</TableCell>
                    <TableCell className="text-xs">{a.description}</TableCell>
                    <TableCell className="text-xs">{a.created_at}</TableCell>
                    <TableCell>
                      {a.href ? (
                        <Link href={a.href} className="text-xs underline text-muted-foreground">
                          مشاهده
                        </Link>
                      ) : null}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <ActionLinkGrid links={bundle.quickLinks} />
    </div>
  );
}
