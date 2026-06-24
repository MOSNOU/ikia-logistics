import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CapacityCard } from "@/components/marketplace/capacity-card";
import { listCapacity } from "@/lib/marketplace/list-capacity";
import { getProfile } from "@/lib/auth/get-profile";

export default async function SupplierCapacityPage() {
  const profile = await getProfile();
  const carrierOrganizationId = profile?.primaryOrganizationId ?? null;
  const { rows, available, note } = await listCapacity("supplier", {
    carrierOrganizationId,
    pageSize: 50,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">ظرفیت‌های منتشرشده من</h1>
          <p className="text-sm text-muted-foreground">
            ظرفیت‌های ثبت‌شده روی سازمان فعال شما. وضعیت‌ها مستقیماً از مارکت‌پلیس بک‌اند خوانده می‌شود.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/marketplace">بازگشت</Link>
        </Button>
      </div>

      {!available ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">{note}</CardContent>
        </Card>
      ) : rows.length === 0 ? (
        <Card>
          <CardContent className="p-4 text-xs text-muted-foreground">
            هنوز ظرفیتی منتشر نکرده‌اید. از طریق «انتشار ظرفیت» اولین ردیف را ثبت کنید.
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {rows.map((c) => <CapacityCard key={c.id} listing={c} />)}
        </div>
      )}
    </div>
  );
}
