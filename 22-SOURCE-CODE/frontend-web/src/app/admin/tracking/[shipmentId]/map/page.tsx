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

export default async function AdminTrackingMapPage({ params }: PageProps) {
  const { shipmentId } = await params;
  const resolved = await resolveDispatchForShipment(shipmentId);

  let body: React.ReactNode;
  if (!resolved) {
    body = (
      <Card>
        <CardContent className="p-4 text-sm text-muted-foreground">
          اعزامی برای این محموله ثبت نشده است. پس از تأیید رزرو و ایجاد اعزام
          توسط حمل‌کننده، نقشه ردیابی در دسترس قرار می‌گیرد.
        </CardContent>
      </Card>
    );
  } else {
    const [snapshot, positions] = await Promise.all([
      getTelematicsSnapshot(resolved.dispatchId, "admin"),
      listPositions(resolved.dispatchId, "admin", { limit: 1000 }),
    ]);
    if (positions.length === 0 && !snapshot?.latest_position) {
      body = (
        <Card>
          <CardContent className="space-y-2 p-4 text-sm text-muted-foreground">
            <p>
              برای اعزام مرتبط با این محموله هنوز گزارش موقعیتی ثبت نشده است.
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
          <h1 className="text-2xl font-semibold">نقشه ردیابی محموله — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            نمای فقط-خواندنی ادمین. داده‌ها از CC-45 تله‌متری روی OpenStreetMap رندر می‌شوند.
          </p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm">
            <Link href="/admin/tracking/live">نقشه زنده</Link>
          </Button>
          <Button asChild variant="outline" size="sm">
            <Link href={`/admin/shipments/${shipmentId}/tracking`}>تایم‌لاین</Link>
          </Button>
        </div>
      </div>

      {body}
    </div>
  );
}
