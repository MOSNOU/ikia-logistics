import { Truck, Package, ClipboardList, Activity } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";
import { createClient } from "@/lib/supabase/server";

// CC-73 — Per-request Supabase session via cookies(); must not be
// prerendered.
export const dynamic = "force-dynamic";

interface RecentDispatchRow {
  id?: string;
  status?: string;
  created_at?: string;
}

interface CarrierSummary {
  scope: "org" | "no_org_context";
  openBookings: number | null;
  activeDispatches: number | null;
  inTransitShipments: number | null;
  activeCapacity: number | null;
  recentDispatches: RecentDispatchRow[];
}

const EMPTY: CarrierSummary = {
  scope: "no_org_context",
  openBookings: null,
  activeDispatches: null,
  inTransitShipments: null,
  activeCapacity: null,
  recentDispatches: [],
};

async function loadSummary(): Promise<CarrierSummary> {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return EMPTY;
  }
  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rpcCall = (supabase.schema("marketplace") as any).rpc(
    "carrier_get_dashboard_summary",
  );
  const { data, error } = (await rpcCall) as {
    data: Record<string, unknown> | null;
    error: { message: string } | null;
  };
  if (error || !data) return EMPTY;
  return {
    scope: (data.scope === "org" ? "org" : "no_org_context") as CarrierSummary["scope"],
    openBookings: numberOrNull(data.openBookings),
    activeDispatches: numberOrNull(data.activeDispatches),
    inTransitShipments: numberOrNull(data.inTransitShipments),
    activeCapacity: numberOrNull(data.activeCapacity),
    recentDispatches: asArray<RecentDispatchRow>(data.recentDispatches),
  };
}

function numberOrNull(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}
function asArray<T>(v: unknown): T[] {
  if (!Array.isArray(v)) return [];
  return v.filter((r): r is T => typeof r === "object" && r !== null).slice(0, 5);
}

const FA_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];
function toFa(value: number | null): string {
  if (value === null) return "—";
  return value.toLocaleString("en-US").replace(/\d/g, (d) => FA_DIGITS[Number(d)] ?? d);
}
function formatTs(v: string | undefined): string {
  if (!v) return "—";
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return "—";
  return new Intl.DateTimeFormat("fa-IR", { dateStyle: "short", timeStyle: "short" }).format(d);
}

export default async function CarrierDashboardPage() {
  const s = await loadSummary();
  const noScope = s.scope === "no_org_context";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد حمل‌کننده</h1>
        <p className="text-sm text-muted-foreground">
          {noScope
            ? "برای مشاهدهٔ داده‌ها، حساب کاربری شما باید به یک سازمان حمل‌کننده متصل باشد."
            : "وضعیت رزروها، اعزام‌ها و ظرفیت سازمان شما."}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="رزروهای باز" value={toFa(s.openBookings)} Icon={Package} />
        <StatCard label="اعزام‌های فعال" value={toFa(s.activeDispatches)} Icon={ClipboardList} />
        <StatCard label="محموله‌های در مسیر" value={toFa(s.inTransitShipments)} Icon={Truck} />
        <StatCard
          label="ظرفیت منتشرشده"
          value={toFa(s.activeCapacity)}
          Icon={Activity}
          hint="ظرفیت‌های فعال در بازار حمل"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="اعزام‌های اخیر" description="آخرین اعزام‌های ثبت‌شدهٔ شما">
          {s.recentDispatches.length === 0 ? (
            <p className="text-sm text-muted-foreground">اعزامی برای نمایش وجود ندارد.</p>
          ) : (
            <ul dir="rtl" className="divide-y divide-border text-sm">
              {s.recentDispatches.map((d, i) => (
                <li
                  key={d.id ?? `${i}`}
                  className="flex flex-col gap-1 py-2.5 sm:flex-row sm:items-baseline sm:justify-between"
                >
                  <span className="font-medium text-foreground">{d.status ?? "—"}</span>
                  <span className="text-xs text-muted-foreground">{formatTs(d.created_at)}</span>
                </li>
              ))}
            </ul>
          )}
        </DashboardCard>

        <DashboardCard title="بارهای پیشنهادی" description="بارهای متناسب با ناوگان شما">
          <p className="text-sm text-muted-foreground">
            بازار حمل را برای دیدن بارهای جدید بررسی کنید.
          </p>
        </DashboardCard>
      </div>
    </div>
  );
}
