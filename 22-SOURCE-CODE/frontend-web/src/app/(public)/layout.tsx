import Link from "next/link";
import { Button } from "@/components/ui/button";
import { IkiaLogo } from "@/components/marketing/ikia-logo";
import { siteConfig } from "@/lib/config/site";

// CC-57R — Premium public website layout. White header with strong nav
// (only collapses on mobile) + cinematic dark navy footer with four
// disclosure columns. Persian-first, RTL-first.

// CC-68 — Header nav reordered to match the global freight-platform IA:
//   پلتفرم / خدمات حمل / راهکارها / کریدورها / بازار حمل /
//   اسناد و تطبیق / درباره ما
// All hrefs still match real section IDs on the homepage. «خدمات حمل»
// → #marketplace (service slider); «بازار حمل» → #commodities (cargo
// taxonomy). The «صنایع» entry stays in the footer.
const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/#platform", label: "پلتفرم" },
  { href: "/#marketplace", label: "خدمات حمل" },
  { href: "/#solutions", label: "راهکارها" },
  { href: "/#corridors", label: "کریدورها" },
  { href: "/#commodities", label: "بازار حمل" },
  { href: "/#documents", label: "اسناد و تطبیق" },
  { href: "/#enterprise-readiness", label: "درباره ما" },
];

// CC-Phase1 — Slim footer columns to ~5 links each per brief §17.
// Every href still resolves to a real homepage section ID; no routes
// or anchors changed.
const FOOTER_PLATFORM: { href: string; label: string }[] = [
  { href: "/#platform", label: "پلتفرم" },
  { href: "/#control-tower", label: "کنترل‌تاور" },
  { href: "/#shipment-lifecycle", label: "چرخه عمر محموله" },
  { href: "/#modules", label: "ماژول‌های عملیاتی" },
  { href: "/#operating-system", label: "سیستم عامل لجستیک" },
];

const FOOTER_SERVICES: { href: string; label: string }[] = [
  { href: "/#marketplace", label: "خدمات حمل چندوجهی" },
  { href: "/#documents", label: "گمرک و اسناد" },
  { href: "/#settlement", label: "تسویه و صورتحساب" },
  { href: "/#corridors", label: "ترانزیت و کریدورها" },
];

const FOOTER_RESOURCES: { href: string; label: string }[] = [
  { href: "/#industries", label: "راهکارهای صنعتی" },
  { href: "/#commodities", label: "بازار کالاها" },
  { href: "/#scenarios", label: "سناریوهای عملیاتی" },
  { href: "/#market-structure", label: "ساختار بازار" },
  { href: "/#why-iran", label: "جایگاه راهبردی ایران" },
];

const FOOTER_COMPANY: { href: string; label: string }[] = [
  { href: "/#enterprise-readiness", label: "درباره ما" },
  { href: "/#start", label: "درخواست جلسه معرفی" },
  { href: "/#platform", label: "مشاهده پلتفرم" },
  { href: "/#future", label: "نسل آینده زیرساخت" },
  { href: "/#economics-model", label: "اقتصاد پلتفرم" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* ===================== CC-68 Announcement strip ===================== */}
      <div className="ikia-announcement">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-2 px-4 py-2 text-center text-[11px] leading-5 sm:flex-row sm:px-6 sm:text-right">
          <span className="text-night-text">
            زیرساخت دیجیتال لجستیک، حمل، اسناد و زنجیره تأمین برای بازار ایران و
            کریدورهای منطقه‌ای
          </span>
          <Link
            href="/#platform"
            className="inline-flex items-center gap-1 font-semibold text-sky-300 transition-colors hover:text-sky-200"
          >
            مشاهده توانمندی‌ها
            <span aria-hidden>←</span>
          </Link>
        </div>
      </div>

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
              <Link href="/#start">درخواست جلسه معرفی</Link>
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

      {/* ===================== CC-68 Footer ===================== */}
      <footer
        className="border-t border-white/10"
        style={{ backgroundColor: "var(--color-ikia-midnight)" }}
      >
        <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:py-16">
          {/* Brand row — logo + short description on top, decoupled
              from the link columns for a cleaner Flexport-style top. */}
          <div className="grid gap-8 lg:grid-cols-[1.2fr_2fr] lg:items-start lg:gap-16">
            <div className="space-y-4 text-right">
              <IkiaLogo variant="footer" />
              <p className="max-w-md text-sm leading-7 text-night-text-muted">
                iKIA Logistics زیرساخت دیجیتال لجستیک، اسناد، بازار حمل و
                کنترل عملیات برای صنایع راهبردی، کریدورهای ترانزیتی و
                اکوسیستم تجارت منطقه‌ای ایران است.
              </p>
            </div>

            {/* 4-column link grid. Stacks 2-col on tablet, 4-col on lg+. */}
            <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
              <div className="space-y-3 text-right">
                <div className="ikia-footer-heading">پلتفرم</div>
                <ul className="space-y-1.5 text-sm text-night-text-muted">
                  {FOOTER_PLATFORM.map((l) => (
                    <li key={l.href}>
                      <Link
                        href={l.href}
                        className="transition-colors hover:text-night-text"
                      >
                        {l.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>

              <div className="space-y-3 text-right">
                <div className="ikia-footer-heading">خدمات</div>
                <ul className="space-y-1.5 text-sm text-night-text-muted">
                  {FOOTER_SERVICES.map((l) => (
                    <li key={l.href}>
                      <Link
                        href={l.href}
                        className="transition-colors hover:text-night-text"
                      >
                        {l.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>

              <div className="space-y-3 text-right">
                <div className="ikia-footer-heading">منابع</div>
                <ul className="space-y-1.5 text-sm text-night-text-muted">
                  {FOOTER_RESOURCES.map((l) => (
                    <li key={l.href}>
                      <Link
                        href={l.href}
                        className="transition-colors hover:text-night-text"
                      >
                        {l.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>

              <div className="space-y-3 text-right">
                <div className="ikia-footer-heading">شرکت</div>
                <ul className="space-y-1.5 text-sm text-night-text-muted">
                  {FOOTER_COMPANY.map((l) => (
                    <li key={l.href}>
                      <Link
                        href={l.href}
                        className="transition-colors hover:text-night-text"
                      >
                        {l.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>

          {/* Bottom legal row. */}
          <div className="mt-12 flex flex-col items-start justify-between gap-3 border-t border-white/10 pt-6 text-xs text-night-text-muted sm:flex-row sm:items-center">
            <span>
              © {new Date().getFullYear()} {siteConfig.nameFa} ·{" "}
              {siteConfig.nameEn}
            </span>
            <span className="flex items-center gap-4">
              <span>سامانه عملیات لجستیک ایران</span>
              <span aria-hidden className="opacity-40">·</span>
              <span dir="ltr">FA</span>
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
}
