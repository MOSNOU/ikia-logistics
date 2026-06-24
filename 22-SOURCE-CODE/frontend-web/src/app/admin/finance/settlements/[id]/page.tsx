import Link from "next/link";
import { notFound } from "next/navigation";
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
import { SettlementSummaryCard } from "@/components/finance/settlement-summary-card";
import { FinanceStatusBadge } from "@/components/finance/status-badge";
import { getSettlement } from "@/lib/settlement/get-settlement";
import { listSettlementEvents } from "@/lib/admin/list-settlement-events";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function AdminFinanceSettlementDetailPage({ params }: PageProps) {
  const { id } = await params;
  const [detail, events] = await Promise.all([
    getSettlement(id, "admin"),
    listSettlementEvents(id),
  ]);
  if (!detail) notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">جزئیات تسویه — ادمین</h1>
          <p className="text-sm text-muted-foreground">نمای فقط-خواندنی مالی. برای عملیات از نمای عملیاتی استفاده کنید.</p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/finance/settlements">بازگشت</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href={`/admin/settlements/${id}`}>نمای عملیاتی</Link>
          </Button>
        </div>
      </div>

      <SettlementSummaryCard detail={detail} />

      <Card>
        <CardContent className="p-6 space-y-3">
          <h2 className="text-sm font-medium">تاریخچه رویدادها</h2>
          {events.length === 0 ? (
            <TableEmpty>رویدادی ثبت نشده است.</TableEmpty>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>رویداد</TableHead>
                  <TableHead>از</TableHead>
                  <TableHead>به</TableHead>
                  <TableHead>دلیل</TableHead>
                  <TableHead>زمان</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {events.map((e) => (
                  <TableRow key={e.id}>
                    <TableCell className="text-xs">{e.event_type}</TableCell>
                    <TableCell>{e.from_status ? <FinanceStatusBadge status={e.from_status} domain="settlement" /> : "—"}</TableCell>
                    <TableCell>{e.to_status ? <FinanceStatusBadge status={e.to_status} domain="settlement" /> : "—"}</TableCell>
                    <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                    <TableCell className="text-xs">{e.created_at}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
