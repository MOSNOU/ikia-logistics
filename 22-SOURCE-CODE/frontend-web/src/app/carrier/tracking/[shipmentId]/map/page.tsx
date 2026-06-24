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

  let body: React.ReactNode;
  if (!resolved) {
    body = (
      <Card>
        <CardContent className="p-4 text-sm text-muted-foreground">
          اعزام مرتبط با این محموله یافت نشد یا برای سازمان شما قابل مشاهده نیست.
        </CardContent>
      </Card>
    );
  } else {
    const [snapshot, positions] = await Promise.all([
      getTelematicsSnapshot(resolved.dispatchId, "carrier"),
      listPositions(resolved.dispatchId, "carrier", { limit: 500 }),
    ]);
    if (positions.length === 0 && !snapshot?.latest_position) {
      body = (
        <Card>
          <CardContent className="space-y-2 p-4 text-sm text-muted-foreground">
            <p>
              برای این اعزام هنوز گزارش موقعیتی ارسال نشده است. پس از آغاز
              نشست تله‌متری از دستگاه حمل‌کننده، نقشه بارگذاری می‌شود.
            </p>
            <p className="text-xs">
              اعزام: <span className="font-mono">{resolved.dispatchId}</span>
            </p>
          </CardContent>
        </Card>
      );
    } else {
      body = <DispatchMapMount snapshot={snapshot} positions={positions} />;
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">نقشه ردیابی محموله</h1>
          <p className="text-sm text-muted-foreground">
            نمای موقعیت‌های ارسالی توسط دستگاه حمل‌کننده. این صفحه فقط نمایشی است؛ تغییری در اعزام یا محموله ایجاد نمی‌کند.
          </p>
        </div>
        <div className="flex gap-2">
          {resolved ? (
            <Button asChild size="sm">
              <Link href={`/carrier/tracking/${shipmentId}/report`}>
                گزارش تله‌متری
              </Link>
            </Button>
          ) : null}
          <Button asChild variant="outline" size="sm">
            <Link href={`/carrier/dispatches${resolved ? "/" + resolved.dispatchId : ""}`}>
              بازگشت به اعزام
            </Link>
          </Button>
        </div>
      </div>

      {body}
    </div>
  );
}
