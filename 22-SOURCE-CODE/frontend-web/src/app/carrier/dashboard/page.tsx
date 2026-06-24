import { Truck, Package, Wallet } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";

export default function CarrierDashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد حمل‌کننده</h1>
        <p className="text-sm text-muted-foreground">وضعیت بارها، محموله‌ها و درآمد شما.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="بارهای موجود" value="—" Icon={Package} />
        <StatCard label="محموله‌های فعال" value="—" Icon={Truck} />
        <StatCard label="در حال ردیابی" value="—" Icon={Truck} />
        <StatCard label="درآمد ماه جاری" value="—" Icon={Wallet} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="بارهای پیشنهادی" description="بارهای متناسب با ناوگان شما">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
        <DashboardCard title="محموله‌های در حال انجام" description="وضعیت لحظه‌ای حمل">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
      </div>
    </div>
  );
}
