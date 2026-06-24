import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { LiveOpsMapMount } from "@/components/tracking/live-ops-map-mount";
import { listActiveSessions } from "@/lib/telematics/loaders";

export default async function AdminLiveTrackingPage() {
  const sessions = await listActiveSessions({ limit: 200 });
  const locatedCount = sessions.filter(
    (s) => s.latitude != null && s.longitude != null,
  ).length;

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

      {sessions.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            در حال حاضر هیچ نشست تله‌متری فعالی وجود ندارد. پس از شروع نشست از
            دستگاه حمل‌کننده، اعزام در این نقشه ظاهر می‌شود.
          </CardContent>
        </Card>
      ) : locatedCount === 0 ? (
        <Card>
          <CardContent className="p-4 text-sm text-muted-foreground">
            {sessions.length.toLocaleString("fa-IR")} نشست فعال وجود دارد، اما
            هیچ‌کدام هنوز مختصاتی روی نقشه گزارش نکرده‌اند.
          </CardContent>
        </Card>
      ) : (
        <LiveOpsMapMount sessions={sessions} />
      )}
    </div>
  );
}
