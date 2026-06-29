import type { ReactNode } from "react";
import { MapPin, Truck, FileText, Check, Clock, ShieldCheck, Radio, GitBranch, PackageCheck } from "lucide-react";

// -----------------------------------------------------------------------------
// ProductMockupFrame — a polished light "app window" used to host product UI.
// -----------------------------------------------------------------------------
export function ProductMockupFrame({
  label = "iKIA OS",
  children,
  className = "",
}: {
  label?: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`relative ${className}`}>
      <div className="absolute -inset-4 -z-10 rounded-[2.25rem] bg-blue/[0.06] blur-2xl" aria-hidden />
      <div className="overflow-hidden rounded-2xl border border-line bg-white shadow-[0_28px_64px_-28px_rgba(6,26,47,0.30)]">
        <div className="flex items-center justify-between border-b border-line bg-soft/70 px-4 py-2.5">
          <div className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-full bg-line" />
            <span className="h-2.5 w-2.5 rounded-full bg-line" />
            <span className="h-2.5 w-2.5 rounded-full bg-line" />
          </div>
          <span className="font-mono text-[11px] font-semibold text-muted" dir="ltr">
            {label}
          </span>
          <span className="inline-flex items-center gap-1 rounded-full bg-green/10 px-2 py-0.5 text-[10px] font-semibold text-green">
            <span className="h-1.5 w-1.5 rounded-full bg-green" /> Live
          </span>
        </div>
        <div className="p-4">{children}</div>
      </div>
    </div>
  );
}

export function PlatformOverviewVisual() {
  const shipments = [
    { code: "IK-7841", route: "تهران → بندرعباس", status: "در مسیر", tone: "bg-blue/10 text-blue", progress: "72%" },
    { code: "IK-7838", route: "آستارا → تهران", status: "نیازمند سند", tone: "bg-orange/10 text-orange", progress: "48%" },
    { code: "IK-7829", route: "مشهد → سرخس", status: "تحویل امروز", tone: "bg-green/10 text-green", progress: "91%" },
  ];

  return (
    <div className="relative" dir="rtl">
      <div className="absolute inset-0 -z-10 rounded-[2.5rem] bg-[radial-gradient(circle_at_24%_18%,rgba(31,156,224,0.18),transparent_34%),radial-gradient(circle_at_82%_74%,rgba(11,92,173,0.14),transparent_40%)] blur-xl sm:-inset-6" />
      <div className="overflow-hidden rounded-[28px] border border-line bg-white shadow-[0_34px_90px_-34px_rgba(6,26,47,0.38)]">
        <div className="flex h-12 min-w-0 items-center justify-between gap-3 border-b border-line bg-[#fbfcfe] px-4">
          <div className="flex items-center gap-2" dir="ltr">
            <span className="h-2.5 w-2.5 rounded-full bg-[#ff6b6b]" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#f5c451]" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#18c37e]" />
            <span className="ms-3 max-w-[128px] overflow-hidden text-ellipsis whitespace-nowrap rounded-full bg-soft px-2.5 py-1 font-mono text-[10px] font-semibold text-muted sm:max-w-none">
              app.ikia.logistics/platform
            </span>
          </div>
          <span className="inline-flex items-center gap-1.5 rounded-full bg-green/10 px-2.5 py-1 text-[11px] font-bold text-green">
            <span className="h-1.5 w-1.5 rounded-full bg-green" />
            Live network
          </span>
        </div>

        <div className="grid min-h-[430px] grid-cols-[0.82fr_1.18fr] bg-white max-sm:grid-cols-1">
          <aside className="border-l border-line bg-soft/70 p-4 max-sm:border-b max-sm:border-l-0">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <p className="font-mono text-[10px] font-bold uppercase tracking-[0.18em] text-blue" dir="ltr">
                  Control Tower
                </p>
                <h3 className="mt-1 text-[15px] font-extrabold text-ink">نمای عملیات زنده</h3>
              </div>
              <span className="rounded-lg bg-white px-2.5 py-1 text-[11px] font-bold text-ink ring-1 ring-line">۳ هشدار</span>
            </div>

            <div className="space-y-2.5">
              {shipments.map((s) => (
                <div key={s.code} className="rounded-2xl border border-line bg-white p-3 shadow-[0_10px_26px_-22px_rgba(6,26,47,0.30)]">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-mono text-[11px] font-bold text-ink" dir="ltr">{s.code}</span>
                    <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${s.tone}`}>{s.status}</span>
                  </div>
                  <p className="mt-2 text-[12px] font-medium text-muted">{s.route}</p>
                  <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-soft-2">
                    <div className="h-full rounded-full bg-gradient-to-l from-blue-bright to-blue" style={{ width: s.progress }} />
                  </div>
                </div>
              ))}
            </div>
          </aside>

          <main className="p-4">
            <div className="grid grid-cols-3 gap-2.5">
              {[
                { l: "OTIF", v: "۹۴٪", icon: ShieldCheck, c: "text-green" },
                { l: "Active loads", v: "۲۴۸", icon: PackageCheck, c: "text-blue" },
                { l: "Exceptions", v: "۱۲", icon: Radio, c: "text-orange" },
              ].map((m) => (
                <div key={m.l} className="rounded-2xl border border-line bg-white p-3 shadow-[0_10px_24px_-22px_rgba(6,26,47,0.35)]">
                  <div className="mb-2 flex h-8 w-8 items-center justify-center rounded-xl bg-soft text-blue">
                    <m.icon className="h-4 w-4" aria-hidden />
                  </div>
                  <div className={`text-[20px] font-black leading-none ${m.c}`}>{m.v}</div>
                  <div className="mt-1 font-mono text-[9px] font-bold uppercase tracking-[0.12em] text-muted" dir="ltr">{m.l}</div>
                </div>
              ))}
            </div>

            <div className="mt-3.5 rounded-2xl border border-line bg-gradient-to-br from-soft to-white p-4">
              <div className="mb-3 flex items-center justify-between">
                <span className="text-[13px] font-extrabold text-ink">وضعیت کریدورهای فعال</span>
                <span className="rounded-full bg-white px-2 py-0.5 text-[10px] font-bold text-blue ring-1 ring-line">Real-time ETA</span>
              </div>
              <div className="relative h-36 overflow-hidden rounded-xl bg-white ring-1 ring-line">
                <div
                  aria-hidden
                  className="absolute inset-0 opacity-60"
                  style={{
                    backgroundImage:
                      "linear-gradient(rgba(6,26,47,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(6,26,47,0.06) 1px, transparent 1px)",
                    backgroundSize: "24px 24px",
                  }}
                />
                <svg viewBox="0 0 420 160" className="relative h-full w-full">
                  <path d="M34 116 C 96 52, 168 110, 236 58 S 342 40, 390 84" fill="none" stroke="#0B5CAD" strokeWidth="3" strokeLinecap="round" />
                  <path d="M72 36 C 134 62, 188 82, 254 112 S 350 124, 392 58" fill="none" stroke="#1F9CE0" strokeWidth="2" strokeDasharray="5 6" strokeLinecap="round" />
                  {[
                    [34, 116, "#15C26B"],
                    [142, 88, "#0B5CAD"],
                    [236, 58, "#0B5CAD"],
                    [336, 54, "#F5A623"],
                    [390, 84, "#0B5CAD"],
                  ].map(([cx, cy, fill], i) => (
                    <g key={i}>
                      <circle cx={cx} cy={cy} r="10" fill={String(fill)} opacity="0.14" />
                      <circle cx={cx} cy={cy} r="4.5" fill={String(fill)} />
                    </g>
                  ))}
                </svg>
              </div>
            </div>

            <div className="mt-3.5 grid grid-cols-2 gap-2.5">
              <div className="rounded-2xl border border-line bg-white p-3">
                <div className="mb-2 flex items-center gap-2 text-[12px] font-bold text-ink">
                  <FileText className="h-4 w-4 text-blue" aria-hidden />
                  وضعیت اسناد
                </div>
                <div className="space-y-1.5">
                  {["بارنامه", "بیمه", "اظهارنامه"].map((d, i) => (
                    <div key={d} className="flex items-center justify-between text-[11px]">
                      <span className="text-muted">{d}</span>
                      <span className={i === 2 ? "text-orange" : "text-green"}>{i === 2 ? "در انتظار" : "تأیید"}</span>
                    </div>
                  ))}
                </div>
              </div>
              <div className="rounded-2xl border border-line bg-white p-3">
                <div className="mb-2 flex items-center gap-2 text-[12px] font-bold text-ink">
                  <GitBranch className="h-4 w-4 text-blue" aria-hidden />
                  اتصال‌ها
                </div>
                <div className="space-y-2">
                  <div className="h-1.5 rounded-full bg-soft-2"><div className="h-full w-[86%] rounded-full bg-blue" /></div>
                  <p className="text-[11px] leading-5 text-muted">API، راننده، فورواردر و صاحب بار روی یک جریان مشترک.</p>
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}

function RouteRow() {
  return (
    <div className="rounded-xl border border-line bg-soft px-4 py-3">
      <div className="mb-2.5 flex items-center justify-between text-[11px] font-semibold">
        <span className="font-mono text-ink" dir="ltr">
          SH-2026-08471
        </span>
        <span className="rounded-full bg-blue/10 px-2 py-0.5 text-blue">North–South</span>
      </div>
      <div className="flex items-center gap-2">
        <div className="flex flex-col items-center">
          <MapPin className="h-4 w-4 text-blue" aria-hidden />
          <span className="mt-1 text-[10px] text-muted">تهران</span>
        </div>
        <div className="relative h-1.5 flex-1 rounded-full bg-soft-2">
          <div className="absolute inset-y-0 right-0 w-[62%] rounded-full bg-gradient-to-l from-blue-bright to-blue" />
          <div className="absolute top-1/2 right-[62%] flex h-6 w-6 -translate-y-1/2 translate-x-1/2 items-center justify-center rounded-full bg-white shadow ring-1 ring-line">
            <Truck className="h-3.5 w-3.5 text-blue" aria-hidden />
          </div>
        </div>
        <div className="flex flex-col items-center">
          <MapPin className="h-4 w-4 text-muted" aria-hidden />
          <span className="mt-1 text-[10px] text-muted">بندرعباس</span>
        </div>
      </div>
    </div>
  );
}

function Metrics({
  items,
}: {
  items: { l: string; v: string; c?: string }[];
}) {
  return (
    <div className="grid grid-cols-3 gap-2.5">
      {items.map((m) => (
        <div key={m.l} className="rounded-xl border border-line bg-white px-3 py-3 text-center">
          <div className={`text-[17px] font-bold ${m.c ?? "text-ink"}`}>{m.v}</div>
          <div className="mt-0.5 text-[10px] text-muted">{m.l}</div>
        </div>
      ))}
    </div>
  );
}

// -----------------------------------------------------------------------------
// ControlTowerVisual — shipment overview (route + list + metrics).
// -----------------------------------------------------------------------------
export function ControlTowerVisual() {
  const rows = [
    { code: "SH-2026-08471", status: "در مسیر", tone: "bg-blue/10 text-blue" },
    { code: "SH-2026-08470", status: "تحویل‌شده", tone: "bg-green/10 text-green" },
    { code: "SH-2026-08468", status: "در انتظار تسویه", tone: "bg-orange/10 text-orange" },
  ];
  return (
    <ProductMockupFrame label="iKIA OS · Control Tower">
      <div className="space-y-3.5">
        <RouteRow />
        <div className="space-y-2">
          {rows.map((r) => (
            <div
              key={r.code}
              className="flex items-center justify-between rounded-lg border border-line bg-white px-3 py-2"
            >
              <span className="font-mono text-[12px] text-muted" dir="ltr">
                {r.code}
              </span>
              <span className={`rounded-full px-2.5 py-0.5 text-[10px] font-semibold ${r.tone}`}>{r.status}</span>
            </div>
          ))}
        </div>
        <Metrics
          items={[
            { l: "زمان تحویل", v: "۱۸h", c: "text-blue" },
            { l: "تطبیق ظرفیت", v: "۹۴٪", c: "text-green" },
            { l: "تأخیر فعال", v: "۲", c: "text-ink" },
          ]}
        />
      </div>
    </ProductMockupFrame>
  );
}

// -----------------------------------------------------------------------------
// VisibilityVisual — live map + tracking metrics.
// -----------------------------------------------------------------------------
export function VisibilityVisual() {
  return (
    <ProductMockupFrame label="iKIA OS · Live Visibility">
      <div className="space-y-3.5">
        <div className="relative h-40 overflow-hidden rounded-xl border border-line bg-gradient-to-br from-soft to-soft-2">
          <div
            aria-hidden
            className="absolute inset-0 opacity-[0.5]"
            style={{
              backgroundImage:
                "linear-gradient(rgba(6,26,47,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(6,26,47,0.06) 1px, transparent 1px)",
              backgroundSize: "26px 26px",
            }}
          />
          <svg viewBox="0 0 320 160" className="relative h-full w-full">
            <path d="M40 120 C 110 60, 190 150, 280 40" fill="none" stroke="#0b5cad" strokeWidth="2.5" strokeDasharray="4 5" />
            <circle cx="40" cy="120" r="5" fill="#15c26b" />
            <circle cx="280" cy="40" r="5" fill="#0b5cad" />
            <g>
              <circle cx="178" cy="98" r="9" fill="#0b5cad" opacity="0.18" />
              <circle cx="178" cy="98" r="4.5" fill="#0b5cad" />
            </g>
          </svg>
          <span className="absolute bottom-2 left-3 rounded-full bg-white/90 px-2 py-0.5 text-[10px] font-semibold text-blue ring-1 ring-line">
            ۶۲٪ مسیر طی شده
          </span>
        </div>
        <Metrics
          items={[
            { l: "سرعت", v: "۷۸", c: "text-ink" },
            { l: "ETA", v: "۲٫۴ روز", c: "text-blue" },
            { l: "آخرین به‌روزرسانی", v: "۲m", c: "text-green" },
          ]}
        />
      </div>
    </ProductMockupFrame>
  );
}

// -----------------------------------------------------------------------------
// DocumentComplianceVisual — document tiles + compliance progress.
// -----------------------------------------------------------------------------
export function DocumentComplianceVisual() {
  const docs = [
    { name: "اظهارنامه", ok: true },
    { name: "بارنامه", ok: true },
    { name: "بیمه", ok: true },
    { name: "گواهی مبدأ", ok: false },
  ];
  return (
    <ProductMockupFrame label="iKIA OS · Documents">
      <div className="space-y-3.5">
        <div className="grid grid-cols-2 gap-2.5">
          {docs.map((d) => (
            <div key={d.name} className="flex items-center gap-2.5 rounded-xl border border-line bg-white px-3 py-2.5">
              <span
                className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-lg ${
                  d.ok ? "bg-green/10 text-green" : "bg-orange/10 text-orange"
                }`}
              >
                {d.ok ? <Check className="h-4 w-4" aria-hidden /> : <Clock className="h-4 w-4" aria-hidden />}
              </span>
              <span className="min-w-0">
                <span className="flex items-center gap-1.5 text-[12px] font-semibold text-ink">
                  <FileText className="h-3.5 w-3.5 text-muted" aria-hidden />
                  {d.name}
                </span>
                <span className={`text-[10px] ${d.ok ? "text-green" : "text-orange"}`}>
                  {d.ok ? "تأیید شده" : "در انتظار"}
                </span>
              </span>
            </div>
          ))}
        </div>
        <div className="rounded-xl border border-line bg-soft px-4 py-3">
          <div className="mb-2 flex items-center justify-between text-[11px] font-semibold text-muted">
            <span>وضعیت تطبیق</span>
            <span className="text-ink">۳ از ۴ تأیید</span>
          </div>
          <div className="h-1.5 w-full overflow-hidden rounded-full bg-soft-2">
            <div className="h-full w-[75%] rounded-full bg-gradient-to-l from-blue-bright to-blue" />
          </div>
        </div>
      </div>
    </ProductMockupFrame>
  );
}

// -----------------------------------------------------------------------------
// CorridorNetworkVisual — regional node network (dark card, reused by homepage
// and corridor pages).
// -----------------------------------------------------------------------------
const NODES = [
  { id: "iran", label: "ایران", x: 200, y: 132, hub: true },
  { id: "turkey", label: "ترکیه", x: 64, y: 78 },
  { id: "caucasus", label: "قفقاز", x: 200, y: 40 },
  { id: "central-asia", label: "آسیای میانه", x: 336, y: 80 },
  { id: "gulf", label: "خلیج فارس", x: 200, y: 222 },
];
const LINKS = [
  { from: "iran", to: "gulf", active: true },
  { from: "iran", to: "central-asia", active: true },
  { from: "iran", to: "caucasus", active: false },
  { from: "iran", to: "turkey", active: false },
];
const nodeById = (id: string) => NODES.find((n) => n.id === id)!;

export function CorridorNetworkVisual() {
  return (
    <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-ink p-6 shadow-[0_28px_64px_-28px_rgba(6,26,47,0.45)]">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.06]"
        style={{
          backgroundImage:
            "linear-gradient(rgba(255,255,255,1) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,1) 1px, transparent 1px)",
          backgroundSize: "40px 40px",
        }}
      />
      <svg viewBox="0 0 400 260" className="relative w-full" role="img" aria-label="شبکه کریدورهای منطقه‌ای iKIA">
        {LINKS.map((l) => {
          const a = nodeById(l.from);
          const b = nodeById(l.to);
          return (
            <line
              key={`${l.from}-${l.to}`}
              x1={a.x}
              y1={a.y}
              x2={b.x}
              y2={b.y}
              stroke={l.active ? "#1F9CE0" : "#9FB4C9"}
              strokeWidth={l.active ? 2.5 : 1.5}
              strokeDasharray={l.active ? "0" : "5 5"}
              opacity={l.active ? 0.9 : 0.45}
            />
          );
        })}
        {NODES.map((n) => (
          <g key={n.id}>
            <circle cx={n.x} cy={n.y} r={n.hub ? 9 : 6} fill={n.hub ? "#15C26B" : "#1F9CE0"} />
            <circle cx={n.x} cy={n.y} r={n.hub ? 16 : 12} fill="none" stroke={n.hub ? "#15C26B" : "#1F9CE0"} strokeOpacity="0.3" />
            <text x={n.x} y={n.y - (n.hub ? 22 : 18)} textAnchor="middle" fontSize="12" fontWeight="700" fill="#E8F0F8">
              {n.label}
            </text>
          </g>
        ))}
      </svg>
      <div className="mt-4 flex items-center justify-center gap-5 text-[11px] text-ondark-muted">
        <span className="inline-flex items-center gap-1.5">
          <span className="h-0.5 w-5 rounded bg-blue-bright" /> مسیر فعال
        </span>
        <span className="inline-flex items-center gap-1.5">
          <span className="h-0.5 w-5 rounded border-t border-dashed border-ondark-muted" /> در مسیر توسعه
        </span>
      </div>
    </div>
  );
}

// Generic fallback visual for modules without a bespoke mockup.
export function GenericModuleVisual({ items }: { items: { l: string; v: string }[] }) {
  return (
    <ProductMockupFrame label="iKIA OS">
      <div className="space-y-3.5">
        <RouteRow />
        <Metrics items={items.slice(0, 3).map((it) => ({ l: it.l, v: it.v, c: "text-blue" }))} />
      </div>
    </ProductMockupFrame>
  );
}
