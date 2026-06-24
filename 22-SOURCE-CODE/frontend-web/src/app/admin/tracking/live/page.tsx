import Link from "next/link";
import { Button } from "@/components/ui/button";
import { LiveOpsMapMount } from "@/components/tracking/live-ops-map-mount";
import { listActiveSessions } from "@/lib/telematics/loaders";

export default async function AdminLiveTrackingPage() {
  const sessions = await listActiveSessions({ limit: 200 });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">نقشه زنده عملیات — ادمین</h1>
          <p className="text-sm text-muted-foreground">
            موقعیت‌های فعلی اعزام‌هایی که نشست تله‌متری فعال دارند. هیچ ETA یا بهینه‌سازی مسیر محاسبه نمی‌شود.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/control-tower">برج کنترل</Link>
        </Button>
      </div>

      <LiveOpsMapMount sessions={sessions} />
    </div>
  );
}
