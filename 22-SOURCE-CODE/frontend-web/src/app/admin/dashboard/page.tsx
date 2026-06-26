import { Building2, Users, Factory, BarChart3 } from "lucide-react";
import { StatCard } from "@/components/data-display/stat-card";
import { DashboardCard } from "@/components/data-display/dashboard-card";
import { createClient } from "@/lib/supabase/server";

// CC-72 — The page reads a per-request Supabase session via cookies()
// and must not be cached/prerendered. At local build time the env vars
// may be absent and the loader would return the empty fallback, which
// could otherwise be baked into a static prerender.
export const dynamic = "force-dynamic";

// CC-72 — Admin dashboard server component.
//
// The four StatCards and the "Recent activity" card used to render
// hardcoded "—" placeholders. They are now wired to a single narrow
// SECURITY DEFINER RPC (`identity.admin_get_dashboard_summary`) added
// by migration 0042. The RPC enforces platform_admin internally; any
// non-admin caller is blocked at the database layer with errcode 42501.
//
// Failure mode: if the RPC errors (e.g. transient network or
// permissions hiccup) we fall back to "—" / empty list so the page
// always renders. Internal error details never reach the UI.

interface RecentAuditEventRow {
  id?: string;
  occurred_at?: string;
  action_code?: string;
  resource_type?: string | null;
  organization_id?: string | null;
}

interface DashboardSummary {
  organizationsCount: number | null;
  activeUsersCount: number | null;
  suppliersCount: number | null;
  recentAuditEventsCount: number | null;
  recentAuditEvents: RecentAuditEventRow[];
}

const EMPTY: DashboardSummary = {
  organizationsCount: null,
  activeUsersCount: null,
  suppliersCount: null,
  recentAuditEventsCount: null,
  recentAuditEvents: [],
};

async function loadSummary(): Promise<DashboardSummary> {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return EMPTY;
  }

  const supabase = await createClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rpcCall = (supabase.schema("identity") as any).rpc(
    "admin_get_dashboard_summary",
  );
  const { data, error } = (await rpcCall) as {
    data: Record<string, unknown> | null;
    error: { message: string } | null;
  };

  if (error || !data) {
    return EMPTY;
  }

  return {
    organizationsCount: numberOrNull(data.organizationsCount),
    activeUsersCount: numberOrNull(data.activeUsersCount),
    suppliersCount: numberOrNull(data.suppliersCount),
    recentAuditEventsCount: numberOrNull(data.recentAuditEventsCount),
    recentAuditEvents: asAuditArray(data.recentAuditEvents),
  };
}

function numberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function asAuditArray(value: unknown): RecentAuditEventRow[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((row): row is RecentAuditEventRow => typeof row === "object" && row !== null)
    .slice(0, 5);
}

const FA_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];
function toFa(value: number | null): string {
  if (value === null) return "—";
  return value
    .toLocaleString("en-US")
    .replace(/\d/g, (d) => FA_DIGITS[Number(d)] ?? d);
}

function formatOccurredAt(value: string | undefined): string {
  if (!value) return "—";
  try {
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "—";
    // Persian locale, short date + time.
    return new Intl.DateTimeFormat("fa-IR", {
      dateStyle: "short",
      timeStyle: "short",
    }).format(d);
  } catch {
    return "—";
  }
}

export default async function AdminDashboardPage() {
  const summary = await loadSummary();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">داشبورد مدیریت</h1>
        <p className="text-sm text-muted-foreground">
          نمای کلی پلتفرم، سازمان‌های فعال و رخدادهای اخیر.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="سازمان‌ها"
          value={toFa(summary.organizationsCount)}
          Icon={Building2}
        />
        <StatCard
          label="کاربران فعال"
          value={toFa(summary.activeUsersCount)}
          Icon={Users}
        />
        <StatCard
          label="تأمین‌کنندگان"
          value={toFa(summary.suppliersCount)}
          Icon={Factory}
        />
        <StatCard
          label="رخدادها (۲۴ ساعت)"
          value={toFa(summary.recentAuditEventsCount)}
          Icon={BarChart3}
          hint="مجموع رخدادهای ممیزی در ۲۴ ساعت اخیر"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <DashboardCard
          title="فعالیت اخیر"
          description="آخرین رخدادهای ممیزی در پلتفرم"
        >
          {summary.recentAuditEvents.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              رخدادی برای نمایش وجود ندارد.
            </p>
          ) : (
            <ul
              dir="rtl"
              className="divide-y divide-border text-sm"
            >
              {summary.recentAuditEvents.map((e, idx) => (
                <li
                  key={e.id ?? `${idx}`}
                  className="flex flex-col gap-1 py-2.5 sm:flex-row sm:items-baseline sm:justify-between"
                >
                  <div className="font-medium text-foreground">
                    {e.action_code ?? "—"}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    {e.resource_type ? (
                      <span className="rounded bg-muted px-1.5 py-0.5">
                        {e.resource_type}
                      </span>
                    ) : null}
                    <span>{formatOccurredAt(e.occurred_at)}</span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </DashboardCard>

        <DashboardCard
          title="هشدارهای سیستم"
          description="موارد نیازمند بررسی"
        >
          <p className="text-sm text-muted-foreground">
            هشداری برای نمایش وجود ندارد.
          </p>
        </DashboardCard>
      </div>
    </div>
  );
}
