import Link from "next/link";
import { notFound } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  MatchingCapacityTable,
  MatchingCarriersTable,
} from "@/components/marketplace/matching-results";
import { findMatchingForShipment } from "@/lib/marketplace/find-matching";
import { getShipment } from "@/lib/shipment/get-shipment";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function BuyerShipmentMatchingPage({ params }: PageProps) {
  const { id } = await params;
  const detail = await getShipment(id, "buyer");
  if (!detail) notFound();
  const s = detail.shipment;
  const result = await findMatchingForShipment(id, { limit: 25 });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">تطبیق ظرفیت — {s.shipment_code}</h1>
          <p className="text-sm text-muted-foreground">
            توصیه فقط-خواندنی. این صفحه حمل‌کننده اختصاص نمی‌دهد، ظرفیت رزرو نمی‌کند و محموله را تغییر نمی‌دهد.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${id}`}>بازگشت به محموله</Link>
        </Button>
      </div>

      <Card>
        <CardContent className="p-6 grid gap-3 md:grid-cols-4 text-sm">
          <div>
            <div className="text-muted-foreground">کد</div>
            <div className="font-mono text-xs">{s.shipment_code}</div>
          </div>
          <div>
            <div className="text-muted-foreground">وضعیت</div>
            <Badge variant="outline">{s.status}</Badge>
          </div>
          <div>
            <div className="text-muted-foreground">مود</div>
            <div>{s.transport_mode ?? "—"}</div>
          </div>
          <div>
            <div className="text-muted-foreground">برداشت برنامه‌ریزی‌شده</div>
            <div className="text-xs">
              {(s as { planned_pickup_date?: string | null }).planned_pickup_date ?? "—"}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">مبدأ</div>
            <div className="text-xs">
              {(s as { origin_city?: string | null }).origin_city ?? "—"}
              {" · "}
              {(s as { origin_country?: string | null }).origin_country ?? "—"}
            </div>
          </div>
          <div>
            <div className="text-muted-foreground">مقصد</div>
            <div className="text-xs">
              {(s as { destination_city?: string | null }).destination_city ?? "—"}
              {" · "}
              {(s as { destination_country?: string | null }).destination_country ?? "—"}
            </div>
          </div>
        </CardContent>
      </Card>

      {!result.available ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            {result.error ?? "موتور تطبیق در دسترس نیست."}
          </CardContent>
        </Card>
      ) : (
        <>
          <MatchingCapacityTable rows={result.capacity} />
          <MatchingCarriersTable rows={result.carriers} />
        </>
      )}
    </div>
  );
}
