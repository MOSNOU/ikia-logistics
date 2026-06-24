import { Badge } from "@/components/ui/badge";

// CC-57 — Cinematic dashboard overlay used as the fallback visual inside
// MarketingImageFrame for the hero and visibility sections. Glass-card
// composition over a deep-navy gradient. No live data; the chips and
// numbers are static marketing illustrations and intentionally non-
// specific (no "120,000 shipments delivered" style claims).

const KPIS: { label: string; value: string }[] = [
  { label: "محموله فعال", value: "۲۸" },
  { label: "نشست تله‌متری", value: "۱۹" },
  { label: "اعزام در راه", value: "۱۲" },
];

interface Item {
  code: string;
  route: string;
  status: { text: string; variant: "info" | "success" | "warning" | "muted" };
  health: { text: string; variant: "info" | "success" | "warning" | "muted" };
}

const ROWS: Item[] = [
  {
    code: "SH-204-A",
    route: "تهران ↘ بندرعباس",
    status: { text: "در راه", variant: "info" },
    health: { text: "به‌روز", variant: "success" },
  },
  {
    code: "SH-204-B",
    route: "اصفهان ↗ تبریز",
    status: { text: "آماده", variant: "warning" },
    health: { text: "قدیمی", variant: "warning" },
  },
  {
    code: "SH-204-C",
    route: "مشهد → سرخس (ترانزیت)",
    status: { text: "تخصیص", variant: "muted" },
    health: { text: "بدون موقعیت", variant: "muted" },
  },
];

export function DashboardOverlay({ className = "" }: { className?: string }) {
  return (
    <div
      className={`relative ${className}`}
      aria-hidden
      style={{
        background:
          "linear-gradient(135deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 60%, var(--color-night-mist) 100%)",
      }}
    >
      {/* Faint grid overlay for the operational feel. */}
      <svg
        className="absolute inset-0 h-full w-full opacity-30"
        aria-hidden
      >
        <defs>
          <pattern
            id="dashboard-grid"
            x="0"
            y="0"
            width="32"
            height="32"
            patternUnits="userSpaceOnUse"
          >
            <path
              d="M 32 0 L 0 0 0 32"
              fill="none"
              stroke="oklch(0.78 0.02 250)"
              strokeWidth="1"
            />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#dashboard-grid)" />
      </svg>

      {/* Glass card. */}
      <div className="relative flex h-full items-center justify-center p-5 sm:p-8">
        <div
          className="w-full max-w-xl rounded-2xl border border-white/10 bg-white/10 p-4 backdrop-blur-md text-right"
          style={{
            boxShadow: "var(--shadow-cinematic)",
          }}
        >
          {/* KPI strip. */}
          <div className="grid grid-cols-3 gap-2">
            {KPIS.map((k) => (
              <div
                key={k.label}
                className="rounded-xl border border-white/10 bg-white/5 p-2 text-center"
              >
                <div className="text-[10px] text-night-text-muted">
                  {k.label}
                </div>
                <div className="mt-1 text-lg font-semibold text-night-text">
                  {k.value}
                </div>
              </div>
            ))}
          </div>

          {/* Shipment rows. */}
          <div className="mt-4 rounded-xl border border-white/10 bg-white/5">
            <div className="border-b border-white/10 px-3 py-2 text-[10px] font-medium text-night-text">
              محموله‌های فعال
            </div>
            <ul className="divide-y divide-white/10">
              {ROWS.map((r) => (
                <li
                  key={r.code}
                  className="flex flex-wrap items-center gap-2 px-3 py-2 text-[10px] text-night-text-muted"
                >
                  <span className="font-mono text-night-text">{r.code}</span>
                  <span>·</span>
                  <span>{r.route}</span>
                  <span className="mr-auto" />
                  <Badge variant={r.status.variant}>{r.status.text}</Badge>
                  <Badge variant={r.health.variant}>{r.health.text}</Badge>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
