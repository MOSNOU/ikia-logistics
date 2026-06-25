import Link from "next/link";
import { Button } from "@/components/ui/button";
import { IkiaLogo } from "@/components/marketing/ikia-logo";
import { siteConfig } from "@/lib/config/site";

// CC-57R — Premium public website layout. White header with strong nav
// (only collapses on mobile) + cinematic dark navy footer with four
// disclosure columns. Persian-first, RTL-first.

// CC-64 — Header nav grows to seven items. CC-63's six existing anchors
// stay; «صنایع» (#industries) is added as the entry point to the new
// industry/commodity narrative block. «درباره ما» still points to
// #enterprise-readiness from CC-63.
const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/#platform", label: "پلتفرم" },
  { href: "/#solutions", label: "راهکارها" },
  { href: "/#industries", label: "صنایع" },
  { href: "/#corridors", label: "کریدورها" },
  { href: "/#marketplace", label: "بازار حمل" },
  { href: "/#documents", label: "اسناد و تطبیق" },
  { href: "/#enterprise-readiness", label: "درباره ما" },
];

// CC-64 — Footer platform column extended with the nine new CC-64
// anchors (#industries, #oil-gas, #mining, #agriculture, #retail,
// #transit, #commodities, #scenarios, #differentiation) on top of the
// CC-63 set.
const PLATFORM_LINKS: { href: string; label: string }[] = [
  { href: "/#platform", label: "بخش‌های پلتفرم" },
  { href: "/#how-it-works", label: "نحوه کار پلتفرم" },
  { href: "/#shipment-lifecycle", label: "چرخه عمر محموله" },
  { href: "/#modules", label: "ماژول‌های عملیاتی" },
  { href: "/#market-structure", label: "ساختار بازار" },
  { href: "/#industries", label: "راهکارهای صنعتی" },
  { href: "/#oil-gas", label: "نفت و پتروشیمی" },
  { href: "/#mining", label: "معدن و فلزات" },
  { href: "/#agriculture", label: "کشاورزی و مواد غذایی" },
  { href: "/#retail", label: "کالاهای مصرفی" },
  { href: "/#transit", label: "ترانزیت و کریدورها" },
  { href: "/#commodities", label: "اکوسیستم کالاها" },
  { href: "/#scenarios", label: "سناریوهای عملیاتی" },
  { href: "/#differentiation", label: "تمایز راهبردی" },
  { href: "/#corridors", label: "شبکه کریدورها" },
  { href: "/#why-iran", label: "جایگاه راهبردی ایران" },
  { href: "/#ecosystem", label: "ارزش‌آفرینی اکوسیستم" },
  { href: "/#interaction-model", label: "مدل تعامل اکوسیستم" },
  { href: "/#flywheel", label: "چرخه رشد پلتفرم" },
  { href: "/#documents", label: "اسناد و انطباق" },
  { href: "/#marketplace", label: "بازار حمل و ظرفیت" },
  { href: "/#settlement", label: "تسویه و کنترل اختلاف" },
  { href: "/#control-tower", label: "برج کنترل دیجیتال" },
  { href: "/#data-flow", label: "جریان داده پلتفرم" },
  { href: "/#operating-system", label: "سیستم عامل لجستیک" },
  { href: "/#economics-model", label: "اقتصاد پلتفرم" },
  { href: "/#future", label: "نسل آینده زیرساخت" },
  { href: "/#enterprise-readiness", label: "آمادگی سازمانی" },
];

const COMPANY_LINKS: { href: string; label: string }[] = [
  { href: "/#start", label: "شروع همکاری راهبردی" },
  { href: "/login", label: "ورود به پلتفرم" },
  { href: "/#enterprise-readiness", label: "درباره ما" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* ===================== Header ===================== */}
      <header className="sticky top-0 z-30 border-b border-border-soft bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/80">
        <div className="relative mx-auto flex h-16 max-w-7xl items-center justify-between gap-2 px-4 sm:px-6">
          <Link href="/" aria-label="iKIA Logistics — صفحه اصلی">
            <IkiaLogo variant="header" />
          </Link>
          <nav
            aria-label="فهرست اصلی iKIA"
            className="hidden items-center gap-0.5 lg:flex"
          >
            {NAV_ITEMS.map((n) => (
              <Button
                key={n.href}
                asChild
                variant="ghost"
                size="sm"
                className="text-deep-navy-soft transition-colors hover:bg-brand-50 hover:text-brand-700 focus-visible:bg-brand-50 focus-visible:text-brand-700"
              >
                <Link href={n.href}>{n.label}</Link>
              </Button>
            ))}
          </nav>
          <div className="flex items-center gap-1.5 sm:gap-2">
            <span
              className="hidden items-center rounded-md border border-border-soft px-2 py-1 text-[11px] font-semibold tracking-[0.1em] text-deep-navy-soft sm:inline-flex"
              aria-label="زبان فعلی فارسی"
              title="فارسی"
            >
              FA
            </span>
            <Button
              asChild
              variant="outline"
              size="sm"
              className="hidden border-deep-navy/20 text-deep-navy hover:bg-deep-navy/5 sm:inline-flex"
            >
              <Link href="/#start">درخواست همکاری</Link>
            </Button>
            <Button asChild size="sm">
              <Link href="/login">ورود به پلتفرم</Link>
            </Button>

            {/* CC-60 — server-renderable mobile menu using <details>. No
                "use client", no JS state. Shown under lg, hidden on
                desktop where the inline nav takes over. */}
            <details className="group relative lg:hidden">
              <summary
                aria-label="باز و بستن فهرست ناوبری"
                className="inline-flex h-9 w-9 cursor-pointer list-none items-center justify-center rounded-md border border-border-soft text-deep-navy transition-colors hover:bg-brand-50 hover:text-brand-700 focus-visible:bg-brand-50 focus-visible:text-brand-700 [&::-webkit-details-marker]:hidden"
              >
                <svg
                  aria-hidden
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  className="h-4 w-4 group-open:hidden"
                >
                  <line x1="4" y1="7" x2="20" y2="7" />
                  <line x1="4" y1="12" x2="20" y2="12" />
                  <line x1="4" y1="17" x2="20" y2="17" />
                </svg>
                <svg
                  aria-hidden
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  className="hidden h-4 w-4 group-open:block"
                >
                  <line x1="6" y1="6" x2="18" y2="18" />
                  <line x1="18" y1="6" x2="6" y2="18" />
                </svg>
              </summary>
              <nav
                aria-label="فهرست موبایل iKIA"
                className="absolute end-0 top-full z-40 mt-2 w-72 rounded-2xl border border-border-soft bg-card p-2 shadow-elevated"
              >
                <ul className="flex flex-col">
                  {NAV_ITEMS.map((n) => (
                    <li key={n.href}>
                      <Link
                        href={n.href}
                        className="block rounded-md px-3 py-2 text-sm text-deep-navy-soft transition-colors hover:bg-brand-50 hover:text-brand-700"
                      >
                        {n.label}
                      </Link>
                    </li>
                  ))}
                  <li className="my-2 h-px bg-border-soft" />
                  <li>
                    <Link
                      href="/#start"
                      className="block rounded-md px-3 py-2 text-sm font-medium text-deep-navy transition-colors hover:bg-brand-50 hover:text-brand-700"
                    >
                      درخواست همکاری
                    </Link>
                  </li>
                </ul>
              </nav>
            </details>
          </div>
        </div>
      </header>

      {/* ===================== Main ===================== */}
      <main className="flex-1">{children}</main>

      {/* ===================== Footer ===================== */}
      <footer
        className="border-t border-white/10"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy) 0%, oklch(0.15 0.04 250) 100%)",
        }}
      >
        <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6">
          <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
            {/* Identity column. */}
            <div className="space-y-4 lg:col-span-1">
              <IkiaLogo variant="footer" />
              <p className="text-xs leading-7 text-night-text-muted">
                {siteConfig.taglineFa}. iKIA Logistics پلتفرم یکپارچه‌ای برای
                صاحبان کالا، شرکت‌های حمل‌ونقل و رانندگان است — قابل اعتماد،
                شفاف، و آماده اتصال سازمانی.
              </p>
            </div>

            {/* Platform links. */}
            <div className="space-y-3">
              <div className="text-xs font-bold uppercase tracking-[0.18em] text-night-text">
                پلتفرم
              </div>
              <ul className="space-y-1.5 text-sm text-night-text-muted">
                {PLATFORM_LINKS.map((l) => (
                  <li key={l.href}>
                    <Link href={l.href} className="hover:text-night-text">
                      {l.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            {/* Services links. */}
            <div className="space-y-3">
              <div className="text-xs font-bold uppercase tracking-[0.18em] text-night-text">
                خدمات حمل‌ونقل
              </div>
              <ul className="space-y-1.5 text-sm text-night-text-muted">
                <li>حمل جاده‌ای</li>
                <li>حمل دریایی</li>
                <li>حمل ریلی</li>
                <li>حمل هوایی</li>
                <li>خدمات انبارداری</li>
                <li>ترخیص و انطباق گمرکی</li>
              </ul>
            </div>

            {/* Company / Connect links. */}
            <div className="space-y-3">
              <div className="text-xs font-bold uppercase tracking-[0.18em] text-night-text">
                شرکت و همکاری
              </div>
              <ul className="space-y-1.5 text-sm text-night-text-muted">
                {COMPANY_LINKS.map((l) => (
                  <li key={l.href}>
                    <Link href={l.href} className="hover:text-night-text">
                      {l.label}
                    </Link>
                  </li>
                ))}
              </ul>
              <div className="pt-3">
                <span className="inline-flex items-center gap-2 rounded-full border border-amber-300/30 bg-amber-400/10 px-3 py-1 text-[10px] font-medium text-amber-200">
                  API سازمانی — در نقشه راه
                </span>
              </div>
            </div>
          </div>

          {/* Bottom bar. */}
          <div className="mt-12 flex flex-col items-start justify-between gap-3 border-t border-white/10 pt-6 text-xs text-night-text-muted sm:flex-row sm:items-center">
            <span>
              © {new Date().getFullYear()} {siteConfig.nameFa} ·{" "}
              {siteConfig.nameEn}
            </span>
            <span>سامانه عملیات لجستیک ایران</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
