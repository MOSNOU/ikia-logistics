import { Badge } from "@/components/ui/badge";

// CC-56 — Operational dashboard mockup for the public landing's
// "visibility" section. Uses CC-54 elevated card + CC-55-style telemetry
// chips so the marketing visual matches what the product actually ships.
// Pure HTML + CSS via Tailwind tokens; no live data.

const KPIS = [
  { label: "محموله‌های فعال", value: "۱۲۸" },
  { label: "اعزام‌های در راه", value: "۹۳" },
  { label: "نشست‌های فعال", value: "۴۱" },
  { label: "استثنای باز", value: "۳" },
] as const;

const SHIPMENTS = [
  {
    code: "SH-13-A2",
    route: "تهران — مشهد",
    badges: [
      { text: "در راه", variant: "info" as const },
      { text: "به‌روز", variant: "success" as const },
    ],
  },
  {
    code: "SH-13-A1",
    route: "اصفهان — بندرعباس",
    badges: [
      { text: "آماده برداشت", variant: "warning" as const },
      { text: "بدون موقعیت", variant: "muted" as const },
    ],
  },
  {
    code: "SH-13-B1",
    route: "تبریز — آستارا (ترانزیت)",
    badges: [
      { text: "در راه", variant: "info" as const },
      { text: "قدیمی", variant: "warning" as const },
    ],
  },
] as const;

export function VisibilityPanel({ className = "" }: { className?: string }) {
  return (
    <div
      className={`rounded-2xl border border-border-soft bg-card shadow-elevated p-4 sm:p-6 ${className}`}
      aria-hidden
    >
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {KPIS.map((k) => (
          <div
            key={k.label}
            className="rounded-xl border border-border-soft bg-surface-muted p-3"
          >
            <div className="text-[11px] text-muted-foreground">{k.label}</div>
            <div className="mt-1 text-2xl font-semibold tracking-tight">
              {k.value}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 rounded-xl border border-border-soft bg-card">
        <div className="border-b border-border-soft p-3 text-xs font-medium">
          محموله‌های اخیر
        </div>
        <ul className="divide-y divide-border-soft">
          {SHIPMENTS.map((s) => (
            <li key={s.code} className="flex flex-wrap items-center gap-2 p-3 text-xs">
              <span className="font-mono text-foreground">{s.code}</span>
              <span className="text-muted-foreground">·</span>
              <span>{s.route}</span>
              <span className="mr-auto" />
              {s.badges.map((b) => (
                <Badge key={b.text} variant={b.variant}>
                  {b.text}
                </Badge>
              ))}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
