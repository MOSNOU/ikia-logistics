import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DispatchMapMount } from "@/components/tracking/dispatch-map-mount";
import {
  getTelematicsSnapshot,
  listPositions,
} from "@/lib/telematics/loaders";
import { resolveDispatchForShipment } from "@/lib/telematics/resolve-dispatch";

interface PageProps {
  params: Promise<{ shipmentId: string }>;
}

export default async function CarrierTrackingMapPage({ params }: PageProps) {
  const { shipmentId } = await params;
  const resolved = await resolveDispatchForShipment(shipmentId);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">نقشه ردیابی محموله</h1>
          <p className="text-sm text-muted-foreground">
            نمای موقعیت‌های ارسالی توسط دستگاه حمل‌کننده. این صفحه فقط نمایشی است؛ تغییری در اعزام یا محموله ایجاد نمی‌کند.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/carrier/dispatches${resolved ? "/" + resolved.dispatchId : ""}`}>
            بازگشت به اعزام
          </Link>
        </Button>
      </div>

      {!resolved ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            اعزام مرتبط با این محموله یافت نشد یا برای سازمان شما قابل مشاهده نیست.
          </CardContent>
        </Card>
      ) : (
        await (async () => {
          const [snapshot, positions] = await Promise.all([
            getTelematicsSnapshot(resolved.dispatchId, "carrier"),
            listPositions(resolved.dispatchId, "carrier", { limit: 500 }),
          ]);
          return <DispatchMapMount snapshot={snapshot} positions={positions} />;
        })()
      )}
    </div>
  );
}
