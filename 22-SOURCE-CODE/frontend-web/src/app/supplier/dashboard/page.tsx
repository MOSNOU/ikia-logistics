import { Package, FileText, Truck, FileSignature } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";
import { createClient } from "@/lib/supabase/server";

// CC-73 — Per-request Supabase session via cookies(); must not be
// prerendered.
export const dynamic = "force-dynamic";

interface RecentOfferRow {
  id?: string;
  offer_code?: string;
  status?: string;
  created_at?: string;
}

interface SupplierSummary {
  scope: "supplier" | "no_supplier_context";
  activeOffers: number | null;
  activeContracts: number | null;
  activeShipments: number | null;
  addressableRfqs: number | null;
  recentOffers: RecentOfferRow[];
}

const EMPTY: SupplierSummary = {
  scope: "no_supplier_context",
  activeOffers: null,
  activeContracts: null,
  activeShipments: null,
  addressableRfqs: null,
  recentOffers: [],
};

async function loadSummary(): Promise<SupplierSummary> {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return EMPTY;
  }
  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rpcCall = (supabase.schema("supplier") as any).rpc(
    "portal_get_dashboard_summary",
  );
  const { data, error } = (await rpcCall) as {
    data: Record<string, unknown> | null;
    error: { message: string } | null;
  };
  if (error || !data) return EMPTY;
  return {
    scope: (data.scope === "supplier" ? "supplier" : "no_supplier_context") as SupplierSummary["scope"],
    activeOffers: numberOrNull(data.activeOffers),
    activeContracts: numberOrNull(data.activeContracts),
    activeShipments: numberOrNull(data.activeShipments),
    addressableRfqs: numberOrNull(data.addressableRfqs),
    recentOffers: asArray<RecentOfferRow>(data.recentOffers),
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

export default async function SupplierDashboardPage() {
  const s = await loadSummary();
  const noScope = s.scope === "no_supplier_context";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد تأمین‌کننده</h1>
        <p className="text-sm text-muted-foreground">
          {noScope
            ? "برای مشاهدهٔ داده‌ها، حساب کاربری شما باید به یک سازمان تأمین‌کننده متصل باشد."
            : "پیشنهادها، قراردادها و محموله‌های مرتبط با کسب‌وکار شما."}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="پیشنهادهای فعال" value={toFa(s.activeOffers)} Icon={Package} />
        <StatCard label="قراردادهای فعال" value={toFa(s.activeContracts)} Icon={FileSignature} />
        <StatCard label="محموله‌های جاری" value={toFa(s.activeShipments)} Icon={Truck} />
        <StatCard
          label="RFQ های قابل پاسخ"
          value={toFa(s.addressableRfqs)}
          Icon={FileText}
          hint="درخواست‌هایی که شما روی آن‌ها پیشنهاد ثبت کرده‌اید"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard title="پیشنهادهای اخیر" description="آخرین پیشنهادهای ثبت‌شدهٔ شما">
          {s.recentOffers.length === 0 ? (
            <p className="text-sm text-muted-foreground">پیشنهادی برای نمایش وجود ندارد.</p>
          ) : (
            <ul dir="rtl" className="divide-y divide-border text-sm">
              {s.recentOffers.map((o, i) => (
                <li
                  key={o.id ?? `${i}`}
                  className="flex flex-col gap-1 py-2.5 sm:flex-row sm:items-baseline sm:justify-between"
                >
                  <span className="font-medium text-foreground">
                    {o.offer_code ?? "—"}
                    {o.status ? (
                      <span className="ms-2 rounded bg-muted px-1.5 py-0.5 text-xs text-muted-foreground">
                        {o.status}
                      </span>
                    ) : null}
                  </span>
                  <span className="text-xs text-muted-foreground">{formatTs(o.created_at)}</span>
                </li>
              ))}
            </ul>
          )}
        </DashboardCard>

        <DashboardCard title="درخواست‌های واجد شرایط" description="RFQ های مرتبط با کسب‌وکار شما">
          <p className="text-sm text-muted-foreground">
            فهرست کامل از صفحهٔ «درخواست‌ها» در دسترس است.
          </p>
        </DashboardCard>
      </div>
    </div>
  );
}
