import { Package, FileText, Truck, Wallet } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";

export default function SupplierDashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد تأمین‌کننده</h1>
        <p className="text-sm text-muted-foreground">وضعیت کالاها، درخواست‌ها و پیشنهادهای شما.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="کالاهای فعال" value="—" Icon={Package} />
        <StatCard label="RFQ های واجد شرایط" value="—" Icon={FileText} />
        <StatCard label="محموله‌های در راه" value="—" Icon={Truck} />
        <StatCard label="مطالبات معوق" value="—" Icon={Wallet} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="درخواست‌های واجد شرایط" description="RFQ های مرتبط با کالاهای شما">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
        <DashboardCard title="پیشنهادهای فعال" description="پیشنهادهای ارسال‌شده در انتظار تصمیم">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
      </div>
    </div>
  );
}
