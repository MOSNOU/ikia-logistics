import { FileText, Package, Truck, Wallet } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";

export default function BuyerDashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد خریدار</h1>
        <p className="text-sm text-muted-foreground">وضعیت درخواست‌ها، پیشنهادها و محموله‌های شما.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="درخواست‌های باز" value="—" Icon={FileText} />
        <StatCard label="پیشنهادهای جدید" value="—" Icon={Package} />
        <StatCard label="محموله‌های در حال حمل" value="—" Icon={Truck} />
        <StatCard label="موجودی حساب امانی" value="—" Icon={Wallet} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="درخواست‌های اخیر" description="آخرین RFQ های شما">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
        <DashboardCard title="پیشنهادهای دریافتی" description="پیشنهادهای منتظر بررسی">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
      </div>
    </div>
  );
}
