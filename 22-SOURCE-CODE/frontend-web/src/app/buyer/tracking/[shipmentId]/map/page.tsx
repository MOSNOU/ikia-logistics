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

export default async function BuyerTrackingMapPage({ params }: PageProps) {
  const { shipmentId } = await params;
  const resolved = await resolveDispatchForShipment(shipmentId);

  let body: React.ReactNode;
  if (!resolved) {
    body = (
      <Card>
        <CardContent className="p-4 text-sm text-muted-foreground">
          هنوز اعزام فعالی برای این محموله ثبت نشده است. پس از تأیید رزرو و
          ایجاد اعزام، داده‌های تله‌متری در دسترس قرار می‌گیرد.
        </CardContent>
      </Card>
    );
  } else {
    const [snapshot, positions] = await Promise.all([
      getTelematicsSnapshot(resolved.dispatchId, "buyer"),
      listPositions(resolved.dispatchId, "buyer", { limit: 500 }),
    ]);
    if (positions.length === 0 && !snapshot?.latest_position) {
      body = (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            اعزام برای این محموله ثبت شده است، اما حمل‌کننده هنوز هیچ گزارش
            موقعیتی ارسال نکرده است. پس از شروع نشست تله‌متری، نقشه به‌روزرسانی
            می‌شود.
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
            نمای موقعیت‌های ثبت‌شده توسط حمل‌کننده. نقشه روی OpenStreetMap رندر می‌شود؛ هیچ تخمین زمان یا بهینه‌سازی مسیر انجام نمی‌شود.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href={`/buyer/shipments/${shipmentId}/tracking`}>تایم‌لاین</Link>
        </Button>
      </div>

      {body}
    </div>
  );
}
