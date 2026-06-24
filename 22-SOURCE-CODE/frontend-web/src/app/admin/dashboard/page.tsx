import { Building2, Users, Shield, BarChart3 } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";

export default function AdminDashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد مدیریت</h1>
        <p className="text-sm text-muted-foreground">نمای کلی پلتفرم و سازمان‌های فعال.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="سازمان‌ها" value="—" Icon={Building2} />
        <StatCard label="کاربران فعال" value="—" Icon={Users} />
        <StatCard label="نقش‌ها" value="—" Icon={Shield} />
        <StatCard label="تراکنش‌های روزانه" value="—" Icon={BarChart3} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="فعالیت اخیر" description="رخدادهای اخیر در پلتفرم">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
        <DashboardCard title="هشدارهای سیستم" description="موارد نیازمند بررسی">
          <p className="text-sm text-muted-foreground">پس از اتصال به پایگاه داده نمایش داده می‌شود.</p>
        </DashboardCard>
      </div>
    </div>
  );
}
