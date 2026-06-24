// CC-57R — Dark navy stats strip used between sections to break visual
// rhythm and reinforce trust. Numbers are illustrative; the strip is
// labelled «نمونه نمایشی» so it never reads as an unsupported claim.

interface Stat {
  label: string;
  value: string;
  hint?: string;
}

const STATS: Stat[] = [
  { label: "مسیرهای فعال در شبکه", value: "۲٬۸۰۰+", hint: "داخلی، بین‌المللی، ترانزیتی" },
  { label: "شرکت‌های حمل‌ونقل همکار", value: "۱٬۲۰۰+", hint: "نمونه نمایشی" },
  { label: "سفارش‌های ثبت‌شده", value: "۴۸٬۰۰۰+", hint: "نمونه نمایشی" },
  { label: "پشتیبانی و مانیتورینگ", value: "۲۴/۷", hint: "کنترل‌تاور عملیات" },
];

export function WebsiteStatsStrip() {
  return (
    <section
      aria-label="شاخص‌های نمونه‌ای پلتفرم iKIA"
      style={{
        background:
          "linear-gradient(135deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
      }}
    >
      <div className="mx-auto max-w-6xl px-4 py-10 sm:py-14">
        <div className="grid gap-6 text-night-text sm:grid-cols-2 lg:grid-cols-4">
          {STATS.map((s) => (
            <div
              key={s.label}
              className="relative rounded-2xl border border-white/10 bg-white/5 p-5 backdrop-blur-md"
            >
              <div className="text-3xl font-bold tracking-tight sm:text-4xl">
                {s.value}
              </div>
              <div className="mt-2 text-sm font-medium">{s.label}</div>
              {s.hint ? (
                <div className="mt-1 text-[11px] text-night-text-muted">
                  {s.hint}
                </div>
              ) : null}
              <span
                aria-hidden
                className="absolute inset-x-5 bottom-0 h-px bg-gradient-to-l from-brand-500/60 via-brand-500/20 to-transparent"
              />
            </div>
          ))}
        </div>
        <p className="mt-6 text-[11px] text-night-text-muted">
          ارقام بالا نمایش پلتفرم هستند و به‌صورت نمونه نمایشی ارائه شده‌اند.
        </p>
      </div>
    </section>
  );
}
