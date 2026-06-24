import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ActivityFeed } from "@/components/marketplace/activity-feed";
import { listMarketplaceActivity } from "@/lib/marketplace/list-marketplace-activity";

export default async function AdminMarketplaceActivityPage() {
  const rows = await listMarketplaceActivity();

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">فعالیت مارکت‌پلیس</h1>
          <p className="text-sm text-muted-foreground">
            رویدادهای اخیر مارکت‌پلیس از روی لجر marketplace.capacity_status_events. شامل انتشار و بایگانی ظرفیت.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/admin/marketplace">بازگشت</Link>
        </Button>
      </div>

      <ActivityFeed rows={rows} title="فعالیت اخیر" />
    </div>
  );
}
