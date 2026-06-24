// CC-57R — Four "photo-like" panel visuals used inside StakeholderSolutionCard.
// Each panel is original CSS+SVG geometry that reads as a designed
// composition rather than a flat icon. Zero external imagery.

/* -----------------------------------------------------------------------
   ControlRoomPanel — multiple monitors with chart hints + status pills.
   Tone: cool blue. Audience: صاحبان کالا.
   -------------------------------------------------------------------- */
export function ControlRoomPanel() {
  return (
    <div
      className="relative h-full w-full overflow-hidden"
      style={{
        background:
          "linear-gradient(135deg, oklch(0.30 0.06 245) 0%, oklch(0.22 0.05 245) 100%)",
      }}
    >
      <svg className="absolute inset-0 h-full w-full" aria-hidden>
        <defs>
          <pattern id="cr-grid" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
            <path d="M 22 0 L 0 0 0 22" fill="none" stroke="oklch(0.78 0.02 250)" strokeWidth="0.6" opacity="0.25" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#cr-grid)" />
        {/* Desk surface. */}
        <rect x="0" y="68%" width="100%" height="32%" fill="oklch(0.18 0.04 250)" opacity="0.85" />
      </svg>
      <div className="relative flex h-full flex-col justify-end gap-3 p-5">
        {/* Three "monitors" floating above the desk. */}
        <div className="flex flex-1 items-end justify-center gap-3 pb-2">
          <Monitor accent="oklch(0.55 0.18 250)" chart="bar" />
          <Monitor accent="oklch(0.65 0.18 145)" chart="line" big />
          <Monitor accent="oklch(0.78 0.18 80)" chart="area" />
        </div>
      </div>
    </div>
  );
}

function Monitor({
  accent,
  chart,
  big = false,
}: {
  accent: string;
  chart: "bar" | "line" | "area";
  big?: boolean;
}) {
  return (
    <div
      className={`rounded-lg border border-white/15 bg-white/5 p-2 backdrop-blur-sm ${
        big ? "h-32 w-44" : "h-24 w-32"
      }`}
    >
      <div className="flex items-center justify-between text-[8px] text-white/70">
        <span className="font-mono">SH-{big ? "204" : "201"}</span>
        <span style={{ color: accent }}>●</span>
      </div>
      <svg viewBox="0 0 100 50" className="mt-1 h-full w-full">
        {chart === "bar" ? (
          <g fill={accent} opacity="0.85">
            <rect x="6" y="20" width="8" height="22" />
            <rect x="20" y="12" width="8" height="30" />
            <rect x="34" y="24" width="8" height="18" />
            <rect x="48" y="8" width="8" height="34" />
            <rect x="62" y="16" width="8" height="26" />
            <rect x="76" y="6" width="8" height="36" />
          </g>
        ) : chart === "line" ? (
          <g>
            <path
              d="M 4 36 L 22 24 L 38 30 L 56 14 L 74 22 L 96 8"
              fill="none"
              stroke={accent}
              strokeWidth="2.4"
              strokeLinecap="round"
            />
            <g fill={accent}>
              <circle cx="22" cy="24" r="2" />
              <circle cx="56" cy="14" r="2" />
              <circle cx="96" cy="8" r="2.6" />
            </g>
          </g>
        ) : (
          <g>
            <path
              d="M 4 40 L 4 28 L 22 32 L 38 18 L 56 26 L 74 14 L 96 20 L 96 40 Z"
              fill={accent}
              opacity="0.35"
            />
            <path
              d="M 4 28 L 22 32 L 38 18 L 56 26 L 74 14 L 96 20"
              fill="none"
              stroke={accent}
              strokeWidth="2"
              strokeLinecap="round"
            />
          </g>
        )}
      </svg>
    </div>
  );
}

/* -----------------------------------------------------------------------
   TruckFleetPanel — three trucks in perspective on a road, sky behind.
   Tone: warm dawn / blue road. Audience: شرکت‌های حمل‌ونقل.
   -------------------------------------------------------------------- */
export function TruckFleetPanel() {
  return (
    <div className="relative h-full w-full overflow-hidden">
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="fleet-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.95 0.04 230)" />
            <stop offset="100%" stopColor="oklch(0.88 0.07 80)" />
          </linearGradient>
          <linearGradient id="fleet-road" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.36 0.04 245)" />
            <stop offset="100%" stopColor="oklch(0.20 0.04 245)" />
          </linearGradient>
        </defs>
        <rect width="320" height="120" fill="url(#fleet-sky)" />
        <rect y="120" width="320" height="80" fill="url(#fleet-road)" />
        {/* Distant mountains. */}
        <path d="M 0 120 L 60 90 L 100 100 L 150 78 L 200 96 L 250 84 L 320 110 L 320 120 L 0 120 Z" fill="oklch(0.30 0.04 240)" opacity="0.7" />
        {/* Road centre dashes. */}
        <line x1="0" y1="160" x2="320" y2="160" stroke="oklch(1 0 0)" strokeWidth="2" strokeDasharray="14 12" opacity="0.7" />
        {/* Three trucks in perspective. */}
        {[
          { x: 30, scale: 1, c: "oklch(0.55 0.18 250)" },
          { x: 140, scale: 0.85, c: "oklch(0.65 0.18 145)" },
          { x: 240, scale: 0.7, c: "oklch(0.78 0.18 80)" },
        ].map((t, i) => (
          <g key={i} transform={`translate(${t.x} 130) scale(${t.scale})`}>
            <rect x="0" y="0" width="50" height="20" rx="2" fill={t.c} />
            <rect x="50" y="4" width="14" height="16" rx="2" fill="oklch(0.30 0.06 245)" />
            <rect x="52" y="6" width="6" height="6" rx="1" fill="oklch(0.85 0.06 230)" />
            <circle cx="10" cy="22" r="4" fill="oklch(0.16 0.02 245)" />
            <circle cx="38" cy="22" r="4" fill="oklch(0.16 0.02 245)" />
            <circle cx="58" cy="22" r="4" fill="oklch(0.16 0.02 245)" />
          </g>
        ))}
      </svg>
    </div>
  );
}

/* -----------------------------------------------------------------------
   DriverMobilePanel — phone tilted, screen shows live capture UI.
   Tone: dusk gradient. Audience: رانندگان.
   -------------------------------------------------------------------- */
export function DriverMobilePanel() {
  return (
    <div className="relative h-full w-full overflow-hidden flex items-center justify-center"
      style={{
        background:
          "radial-gradient(at 70% 30%, oklch(0.60 0.15 230) 0%, oklch(0.30 0.10 245) 65%)",
      }}
    >
      <svg className="absolute inset-0 h-full w-full" aria-hidden>
        <defs>
          <pattern id="dr-dots" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill="oklch(0.96 0.01 250)" opacity="0.3" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#dr-dots)" />
      </svg>
      {/* Phone frame, tilted slightly. */}
      <div
        className="relative rounded-[1.75rem] border border-white/30 bg-white/95 p-2 shadow-2xl backdrop-blur"
        style={{ transform: "rotate(-6deg)", width: "150px", height: "230px" }}
      >
        <div className="mb-1 h-1 w-10 mx-auto rounded-full bg-black/30" />
        <div className="rounded-2xl bg-[oklch(0.97_0.005_250)] p-2 space-y-1.5">
          <div className="rounded-md border border-black/5 bg-white p-1.5">
            <div className="text-[7px] font-semibold text-deep-navy">سفر راننده</div>
            <div className="mt-1 flex gap-1">
              <span className="inline-block rounded-sm bg-emerald-100 px-1 text-[6px] text-emerald-700">فعال</span>
              <span className="inline-block rounded-sm bg-sky-100 px-1 text-[6px] text-sky-700">نشست</span>
            </div>
          </div>
          <div className="rounded-md border border-black/5 bg-white p-1.5">
            <div className="text-[6px] text-deep-navy-soft">موقعیت زنده</div>
            <div className="mt-0.5 font-mono text-[7px] text-deep-navy">35.68920, 51.38900</div>
            <div className="mt-1 h-3 rounded-sm bg-brand-500 text-center text-[6px] leading-3 text-white">
              ارسال موقعیت
            </div>
          </div>
          <div className="rounded-md border border-black/5 bg-white p-1.5">
            <div className="text-[6px] text-deep-navy-soft">خط زمانی</div>
            <div className="mt-0.5 flex gap-1 text-[5.5px]">
              <span className="inline-block rounded-sm bg-sky-100 px-1 text-sky-700">موقعیت</span>
              <span className="inline-block rounded-sm bg-emerald-100 px-1 text-emerald-700">شروع</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* -----------------------------------------------------------------------
   OperationsDashboardPanel — chart panel + status grid on dark surface.
   Tone: deep navy. Audience: کنترل‌تاور و مدیران.
   -------------------------------------------------------------------- */
export function OperationsDashboardPanel() {
  return (
    <div
      className="relative h-full w-full overflow-hidden"
      style={{
        background:
          "linear-gradient(135deg, oklch(0.22 0.05 245) 0%, oklch(0.16 0.04 245) 100%)",
      }}
    >
      <svg className="absolute inset-0 h-full w-full" aria-hidden>
        <defs>
          <pattern id="ops-grid" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
            <path d="M 22 0 L 0 0 0 22" fill="none" stroke="oklch(0.78 0.02 250)" strokeWidth="0.6" opacity="0.25" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#ops-grid)" />
      </svg>
      <div className="relative grid h-full grid-cols-2 gap-3 p-4">
        <div className="flex flex-col gap-2 rounded-lg border border-white/15 bg-white/5 p-3 backdrop-blur">
          <div className="text-[8px] uppercase tracking-[0.15em] text-white/70">عملکرد ناوگان</div>
          <svg viewBox="0 0 120 50" className="h-full w-full">
            <path d="M 4 38 L 22 26 L 40 30 L 60 14 L 80 22 L 100 10 L 118 16" fill="none" stroke="oklch(0.65 0.18 145)" strokeWidth="2.2" strokeLinecap="round" />
            <path d="M 4 38 L 22 26 L 40 30 L 60 14 L 80 22 L 100 10 L 118 16 L 118 50 L 4 50 Z" fill="oklch(0.65 0.18 145)" opacity="0.18" />
          </svg>
        </div>
        <div className="flex flex-col gap-2 rounded-lg border border-white/15 bg-white/5 p-3 backdrop-blur">
          <div className="text-[8px] uppercase tracking-[0.15em] text-white/70">شاخص‌ها</div>
          <div className="grid flex-1 grid-cols-2 gap-1.5">
            {[
              { l: "فعال", v: "۲۸" },
              { l: "در راه", v: "۱۹" },
              { l: "تحویل", v: "۳۲" },
              { l: "تأخیر", v: "۳" },
            ].map((k) => (
              <div key={k.l} className="rounded-md border border-white/10 bg-white/5 p-1.5">
                <div className="text-[7px] text-white/70">{k.l}</div>
                <div className="text-sm font-bold text-white">{k.v}</div>
              </div>
            ))}
          </div>
        </div>
        <div className="col-span-2 flex flex-col gap-1.5 rounded-lg border border-white/15 bg-white/5 p-3 backdrop-blur">
          <div className="text-[8px] uppercase tracking-[0.15em] text-white/70">صف استثناها</div>
          <div className="flex flex-1 flex-col gap-1 text-[8px]">
            {[
              { c: "SH-204-A", t: "تأخیر", v: "warning" },
              { c: "SH-204-B", t: "بازرسی گمرک", v: "info" },
              { c: "SH-204-C", t: "تحویل", v: "success" },
            ].map((r) => (
              <div key={r.c} className="flex items-center justify-between rounded-sm bg-white/5 px-2 py-1">
                <span className="font-mono text-white">{r.c}</span>
                <span
                  className={
                    r.v === "warning"
                      ? "text-amber-300"
                      : r.v === "success"
                        ? "text-emerald-300"
                        : "text-sky-300"
                  }
                >
                  {r.t}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
