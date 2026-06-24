import { Badge } from "@/components/ui/badge";

// CC-57R — Dark control-tower map + side shipment card + bottom KPI row.
// Original abstract Iran-shaped land mass with stylized corridor lines
// from the south port up to the north / east / west and a delivered marker
// near the centre. Static SVG, server-renderable.

interface MapNode {
  cx: number;
  cy: number;
  label: string;
  variant: "origin" | "active" | "delivered" | "transit";
}

const NODES: MapNode[] = [
  { cx: 380, cy: 380, label: "بندرعباس", variant: "origin" },
  { cx: 360, cy: 280, label: "اصفهان", variant: "active" },
  { cx: 320, cy: 200, label: "تهران", variant: "active" },
  { cx: 440, cy: 178, label: "مشهد", variant: "transit" },
  { cx: 200, cy: 160, label: "تبریز", variant: "delivered" },
];

const KPIS: { label: string; value: string; tone: "info" | "success" | "warning" }[] = [
  { label: "محموله‌های فعال", value: "۲۸", tone: "info" },
  { label: "در مسیر", value: "۱۹", tone: "info" },
  { label: "تحویل امروز", value: "۳۲", tone: "success" },
  { label: "تأخیر احتمالی", value: "۳", tone: "warning" },
  { label: "وضعیت کلی", value: "پایدار", tone: "success" },
];

export function ControlTowerMapVisual({ className = "" }: { className?: string }) {
  return (
    <div className={`${className}`}>
      <div className="grid gap-5 lg:grid-cols-[1.6fr_1fr]">
        {/* Map panel. */}
        <div
          className="relative overflow-hidden rounded-3xl border border-white/10"
          style={{ boxShadow: "var(--shadow-cinematic)" }}
        >
          <svg
            viewBox="0 0 640 440"
            role="img"
            aria-label="نمای کنترل‌تاور با مسیر فعال از بندرعباس به سمت شمال و شرق"
            className="block h-full w-full"
            preserveAspectRatio="xMidYMid slice"
            style={{
              background:
                "linear-gradient(135deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
            }}
          >
            <defs>
              <pattern
                id="map-grid"
                x="0"
                y="0"
                width="28"
                height="28"
                patternUnits="userSpaceOnUse"
              >
                <path
                  d="M 28 0 L 0 0 0 28"
                  fill="none"
                  stroke="oklch(0.78 0.02 250)"
                  strokeWidth="0.6"
                  opacity="0.25"
                />
              </pattern>
              <linearGradient id="iran-land" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="oklch(0.30 0.05 250)" />
                <stop offset="100%" stopColor="oklch(0.24 0.05 250)" />
              </linearGradient>
              <linearGradient id="route-blue" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="oklch(0.55 0.18 250)" stopOpacity="0.9" />
                <stop offset="100%" stopColor="oklch(0.65 0.18 240)" stopOpacity="0.9" />
              </linearGradient>
              <radialGradient id="origin-glow" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stopColor="oklch(0.78 0.18 80)" stopOpacity="0.6" />
                <stop offset="100%" stopColor="oklch(0.78 0.18 80)" stopOpacity="0" />
              </radialGradient>
            </defs>

            <rect width="640" height="440" fill="url(#map-grid)" />

            {/* Abstract Iran land mass — original simplified outline. */}
            <path
              d="M 160 150 Q 200 110 270 110 L 410 100 Q 470 95 510 130
                 Q 540 170 530 220 Q 525 280 480 320 L 440 360
                 Q 410 400 360 405 Q 290 410 250 380 Q 200 360 175 320
                 Q 145 280 140 230 Q 138 180 160 150 Z"
              fill="url(#iran-land)"
              stroke="oklch(0.78 0.02 250)"
              strokeWidth="1.2"
              opacity="0.92"
            />

            {/* Sea (Persian Gulf hint) at the bottom. */}
            <path
              d="M 220 410 Q 320 440 480 410 L 640 440 L 0 440 L 0 420 Z"
              fill="oklch(0.40 0.13 240)"
              opacity="0.55"
            />

            {/* Origin pulse at بندرعباس. */}
            <circle cx="380" cy="380" r="50" fill="url(#origin-glow)" />

            {/* Routes from origin to multiple corridors. */}
            <g
              fill="none"
              stroke="url(#route-blue)"
              strokeWidth="2.4"
              strokeLinecap="round"
            >
              {/* South → centre */}
              <path d="M 380 380 Q 380 330 360 280" />
              {/* Centre → north */}
              <path d="M 360 280 Q 340 240 320 200" />
              {/* Centre → north-east */}
              <path d="M 360 280 Q 400 240 440 178" />
              {/* North → north-west delivered */}
              <path d="M 320 200 Q 260 180 200 160" />
            </g>
            {/* Active dashed accent line on the main corridor. */}
            <path
              d="M 380 380 Q 380 330 360 280 Q 340 240 320 200"
              fill="none"
              stroke="oklch(0.78 0.18 80)"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeDasharray="6 8"
              opacity="0.85"
            />

            {/* Nodes + labels. */}
            <g fontFamily="inherit" fontSize="12">
              {NODES.map((n) => {
                const fill =
                  n.variant === "origin"
                    ? "oklch(0.78 0.18 80)"
                    : n.variant === "delivered"
                      ? "oklch(0.65 0.18 145)"
                      : n.variant === "transit"
                        ? "oklch(0.6 0.10 200)"
                        : "oklch(0.55 0.18 250)";
                return (
                  <g key={n.label}>
                    <circle
                      cx={n.cx}
                      cy={n.cy}
                      r="7"
                      fill="oklch(1 0 0)"
                      stroke={fill}
                      strokeWidth="2"
                    />
                    <circle cx={n.cx} cy={n.cy} r="3.2" fill={fill} />
                    <text
                      x={n.cx + 14}
                      y={n.cy + 4}
                      fill="oklch(0.96 0.01 250)"
                      style={{ paintOrder: "stroke" }}
                      stroke="oklch(0.21 0.04 250)"
                      strokeWidth="3"
                    >
                      {n.label}
                    </text>
                    <text
                      x={n.cx + 14}
                      y={n.cy + 4}
                      fill="oklch(0.96 0.01 250)"
                    >
                      {n.label}
                    </text>
                  </g>
                );
              })}
            </g>
          </svg>

          {/* Operational legend pinned to the bottom-left. */}
          <div
            className="absolute bottom-3 left-3 rounded-xl border border-white/15 bg-white/10 p-3 backdrop-blur-md text-night-text"
            aria-hidden
          >
            <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-night-text-muted">
              راهنما
            </div>
            <div className="mt-1 flex flex-col gap-1 text-[11px]">
              <span className="flex items-center gap-1.5">
                <span className="inline-block size-2 rounded-full bg-[oklch(0.78_0.18_80)]" />
                مبدأ فعال
              </span>
              <span className="flex items-center gap-1.5">
                <span className="inline-block size-2 rounded-full bg-[oklch(0.55_0.18_250)]" />
                در حال حمل
              </span>
              <span className="flex items-center gap-1.5">
                <span className="inline-block size-2 rounded-full bg-[oklch(0.65_0.18_145)]" />
                تحویل‌شده
              </span>
            </div>
          </div>
        </div>

        {/* Shipment info card. */}
        <div className="space-y-4">
          <div
            className="rounded-2xl border border-border-soft bg-card p-5 text-right"
            style={{ boxShadow: "var(--shadow-elevated)" }}
          >
            <div className="flex items-center justify-between gap-2">
              <Badge variant="info">در حال حمل</Badge>
              <span className="text-xs text-muted-foreground">پیگیری زنده</span>
            </div>
            <div className="mt-3 text-xs text-muted-foreground">شماره محموله</div>
            <div className="text-lg font-bold tracking-tight text-deep-navy">
              SH-204-A
            </div>
            <dl className="mt-4 space-y-2.5 text-xs">
              <div className="flex justify-between gap-3">
                <dt className="text-muted-foreground">مبدأ</dt>
                <dd className="font-medium">بندر شهید رجایی</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="text-muted-foreground">مقصد</dt>
                <dd className="font-medium">تهران</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="text-muted-foreground">نوع بار</dt>
                <dd className="font-medium">کانتینر یخچالی</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="text-muted-foreground">حامل</dt>
                <dd className="font-medium">حمل‌کننده همکار</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="text-muted-foreground">زمان تخمینی</dt>
                <dd className="font-medium">۱۸ ساعت</dd>
              </div>
            </dl>
            <div className="mt-4 flex items-center gap-1.5 text-[11px] text-emerald-700">
              <span className="inline-block size-1.5 rounded-full bg-emerald-500" />
              نشست تله‌متری فعال — به‌روز
            </div>
          </div>
          <div
            className="rounded-2xl border border-white/10 p-4 text-night-text"
            style={{
              background:
                "linear-gradient(135deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
            }}
          >
            <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-night-text-muted">
              کنترل‌تاور — وضعیت کلی
            </div>
            <div className="mt-2 text-sm leading-7">
              عملیات روزانه پایدار است. سه محموله احتمال تأخیر دارند و توسط
              تیم کنترل‌تاور پیگیری می‌شوند.
            </div>
          </div>
        </div>
      </div>

      {/* Bottom KPI row. */}
      <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-5">
        {KPIS.map((k) => (
          <div
            key={k.label}
            className="rounded-2xl border border-white/10 p-4 text-night-text"
            style={{
              background:
                "linear-gradient(135deg, var(--color-deep-navy-soft) 0%, var(--color-deep-navy) 100%)",
            }}
          >
            <div className="text-[11px] text-night-text-muted">{k.label}</div>
            <div
              className={`mt-1 text-2xl font-bold tracking-tight ${
                k.tone === "success"
                  ? "text-emerald-300"
                  : k.tone === "warning"
                    ? "text-amber-300"
                    : "text-night-text"
              }`}
            >
              {k.value}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
