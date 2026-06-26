import { FileText, Package, Truck, FileSignature } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";
import { createClient } from "@/lib/supabase/server";

// CC-73 — Per-request Supabase session via cookies(); must not be
// prerendered.
export const dynamic = "force-dynamic";

interface RecentBookingRow {
  id?: string;
  status?: string;
  created_at?: string;
}

interface BuyerSummary {
  scope: "org" | "no_org_context";
  activeRfqs: number | null;
  openBookings: number | null;
  activeShipments: number | null;
  activeContracts: number | null;
  recentBookings: RecentBookingRow[];
}

const EMPTY: BuyerSummary = {
  scope: "no_org_context",
  activeRfqs: null,
  openBookings: null,
  activeShipments: null,
  activeContracts: null,
  recentBookings: [],
};

async function loadSummary(): Promise<BuyerSummary> {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return EMPTY;
  }
  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rpcCall = (supabase.schema("marketplace") as any).rpc(
    "buyer_get_dashboard_summary",
  );
  const { data, error } = (await rpcCall) as {
    data: Record<string, unknown> | null;
    error: { message: string } | null;
  };
  if (error || !data) return EMPTY;
  return {
    scope: (data.scope === "org" ? "org" : "no_org_context") as BuyerSummary["scope"],
    activeRfqs: numberOrNull(data.activeRfqs),
    openBookings: numberOrNull(data.openBookings),
    activeShipments: numberOrNull(data.activeShipments),
    activeContracts: numberOrNull(data.activeContracts),
    recentBookings: asArray<RecentBookingRow>(data.recentBookings),
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

export default async function BuyerDashboardPage() {
  const s = await loadSummary();
  const noScope = s.scope === "no_org_context";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد خریدار</h1>
        <p className="text-sm text-muted-foreground">
          {noScope
            ? "برای مشاهدهٔ داده‌ها، حساب کاربری شما باید به یک سازمان خریدار متصل باشد."
            : "وضعیت درخواست‌ها، رزروها و محموله‌های سازمان شما."}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="درخواست‌های فعال" value={toFa(s.activeRfqs)} Icon={FileText} />
        <StatCard label="رزروهای باز" value={toFa(s.openBookings)} Icon={Package} />
        <StatCard label="محموله‌های جاری" value={toFa(s.activeShipments)} Icon={Truck} />
        <StatCard label="قراردادهای فعال" value={toFa(s.activeContracts)} Icon={FileSignature} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="رزروهای اخیر" description="آخرین درخواست‌های رزرو ثبت‌شدهٔ سازمان شما">
          {s.recentBookings.length === 0 ? (
            <p className="text-sm text-muted-foreground">رزرو فعالی برای نمایش وجود ندارد.</p>
          ) : (
            <ul dir="rtl" className="divide-y divide-border text-sm">
              {s.recentBookings.map((b, i) => (
                <li
                  key={b.id ?? `${i}`}
                  className="flex flex-col gap-1 py-2.5 sm:flex-row sm:items-baseline sm:justify-between"
                >
                  <span className="font-medium text-foreground">{b.status ?? "—"}</span>
                  <span className="text-xs text-muted-foreground">{formatTs(b.created_at)}</span>
                </li>
              ))}
            </ul>
          )}
        </DashboardCard>

        <DashboardCard title="پیشنهادهای منتظر بررسی" description="پیشنهادهای دریافتی روی RFQ های شما">
          <p className="text-sm text-muted-foreground">
            ارزیابی پیشنهادها از صفحهٔ هر RFQ در دسترس است.
          </p>
        </DashboardCard>
      </div>
    </div>
  );
}
