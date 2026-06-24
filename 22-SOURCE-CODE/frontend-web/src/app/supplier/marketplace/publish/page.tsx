import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { getProfile } from "@/lib/auth/get-profile";
import { PublishCapacityForm } from "./publish-capacity-form";

export default async function SupplierPublishCapacityPage() {
  const profile = await getProfile();
  const carrierOrganizationId = profile?.primaryOrganizationId ?? null;

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">انتشار ظرفیت</h1>
          <p className="text-sm text-muted-foreground">
            ثبت ظرفیت قابل عرضه. ارسال فرم با موفقیت، یک ردیف فعال در ظرفیت‌های منتشرشده ایجاد می‌کند.
          </p>
        </div>
        <Button asChild variant="outline" size="sm">
          <Link href="/supplier/marketplace">بازگشت</Link>
        </Button>
      </div>

      <Card>
        <CardContent className="p-4 text-xs text-muted-foreground">
          توجه: انتشار ظرفیت روی سازمان حمل‌کننده انجام می‌شود. اگر سازمان فعال شما از نوع حمل‌کننده نیست یا نقش carrier_admin ندارید، پیام خطای مشخص نمایش داده می‌شود.
        </CardContent>
      </Card>

      <PublishCapacityForm carrierOrganizationId={carrierOrganizationId} />
    </div>
  );
}
