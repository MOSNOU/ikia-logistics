import Link from "next/link";
import { Button } from "@/components/ui/button";
import { IkiaLogo } from "@/components/marketing/ikia-logo";
import { siteConfig } from "@/lib/config/site";

// CC-57R — Premium public website layout. White header with strong nav
// (only collapses on mobile) + cinematic dark navy footer with four
// disclosure columns. Persian-first, RTL-first.

const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/", label: "خانه" },
  { href: "/#solutions", label: "راهکارها" },
  { href: "/#transport", label: "خدمات" },
  { href: "/#control-tower", label: "حمل‌ونقل" },
  { href: "/#coverage", label: "زنجیره تأمین" },
  { href: "/#platform", label: "منابع" },
  { href: "/#integration", label: "درباره ما" },
  { href: "/#start", label: "تماس با ما" },
];

const PLATFORM_LINKS: { href: string; label: string }[] = [
  { href: "/#platform", label: "بازار، اعزام، تسویه" },
  { href: "/#control-tower", label: "کنترل‌تاور و رؤیت زنده" },
  { href: "/#solutions", label: "کنسول راننده" },
  { href: "/#transport", label: "خدمات حمل‌ونقل" },
  { href: "/#coverage", label: "پوشش جغرافیایی" },
  { href: "/#integration", label: "اتصال سازمانی" },
];

const COMPANY_LINKS: { href: string; label: string }[] = [
  { href: "/#start", label: "شروع همکاری" },
  { href: "/login", label: "ورود کاربران" },
  { href: "/#integration", label: "نقشه راه API" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* ===================== Header ===================== */}
      <header className="sticky top-0 z-30 border-b border-border-soft bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/80">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6">
          <Link href="/" aria-label="iKIA Logistics — صفحه اصلی">
            <IkiaLogo tone="dark" />
          </Link>
          <nav
            aria-label="فهرست اصلی iKIA"
            className="hidden gap-0.5 lg:flex"
          >
            {NAV_ITEMS.map((n) => (
              <Button
                key={n.href}
                asChild
                variant="ghost"
                size="sm"
                className="text-deep-navy-soft hover:bg-deep-navy/5 hover:text-deep-navy"
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
              <IkiaLogo tone="light" />
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
