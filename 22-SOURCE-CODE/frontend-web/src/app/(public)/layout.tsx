import Link from "next/link";
import { Button } from "@/components/ui/button";
import { siteConfig } from "@/lib/config/site";

// CC-57 — Public marketing layout. Premium dark-aware header (frosted
// glass over both dark and light slabs) and an enterprise-style footer
// with three disclosure columns. No demo-first CTA language. Persian/RTL.

const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/#platform", label: "پلتفرم" },
  { href: "/#solutions", label: "راهکارها" },
  { href: "/#transport", label: "حمل و ترانزیت" },
  { href: "/#finance", label: "مالی و انطباق" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header
        className="sticky top-0 z-30 border-b border-white/10 backdrop-blur supports-[backdrop-filter]:bg-deep-navy/70"
        style={{ background: "color-mix(in oklch, var(--color-deep-navy) 92%, transparent)" }}
      >
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold tracking-tight text-night-text"
          >
            <span
              aria-hidden
              className="inline-block size-6 rounded-md bg-primary text-center text-[11px] font-bold leading-6 text-primary-foreground"
            >
              i
            </span>
            <span>{siteConfig.nameFa}</span>
          </Link>
          <nav className="hidden gap-1 sm:flex" aria-label="فهرست پلتفرم">
            {NAV_ITEMS.map((n) => (
              <Button
                key={n.href}
                asChild
                variant="ghost"
                size="sm"
                className="text-night-text-muted hover:bg-white/10 hover:text-night-text"
              >
                <Link href={n.href}>{n.label}</Link>
              </Button>
            ))}
          </nav>
          <div className="flex items-center gap-2">
            <Button
              asChild
              variant="ghost"
              size="sm"
              className="text-night-text-muted hover:bg-white/10 hover:text-night-text"
            >
              <Link href="/login">ورود</Link>
            </Button>
            <Button asChild size="sm">
              <Link href="/#start">شروع همکاری</Link>
            </Button>
          </div>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer
        className="border-t border-white/10"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy-soft) 0%, var(--color-deep-navy) 100%)",
          color: "var(--color-night-text-muted)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-12">
          <div className="grid gap-8 sm:grid-cols-4">
            <div className="space-y-2 sm:col-span-2">
              <div className="flex items-center gap-2 text-base font-semibold text-night-text">
                <span
                  aria-hidden
                  className="inline-block size-6 rounded-md bg-primary text-center text-[11px] font-bold leading-6 text-primary-foreground"
                >
                  i
                </span>
                <span>{siteConfig.nameFa}</span>
              </div>
              <p className="max-w-md text-xs leading-6">
                {siteConfig.taglineFa}. iKIA Logistics برای واحدهای عملیات،
                تأمین و مالی ساخته شده — قابل اعتماد، شفاف، و آماده اتصال
                سازمانی.
              </p>
            </div>
            <div className="space-y-2">
              <div className="text-xs font-semibold uppercase tracking-wider text-night-text">
                پلتفرم
              </div>
              <ul className="space-y-1.5 text-sm">
                <li><Link href="/#platform" className="hover:text-night-text">بازار، اعزام، تسویه</Link></li>
                <li><Link href="/#visibility" className="hover:text-night-text">رؤیت و کنترل‌تاور</Link></li>
                <li><Link href="/#driver" className="hover:text-night-text">کنسول راننده</Link></li>
                <li><Link href="/#transport" className="hover:text-night-text">حمل و ترانزیت</Link></li>
                <li><Link href="/#documents" className="hover:text-night-text">اسناد و انطباق</Link></li>
                <li><Link href="/#finance" className="hover:text-night-text">مالی و تسویه</Link></li>
                <li><Link href="/#integration" className="hover:text-night-text">اتصال سازمانی</Link></li>
              </ul>
            </div>
            <div className="space-y-2">
              <div className="text-xs font-semibold uppercase tracking-wider text-night-text">
                ورود به سامانه
              </div>
              <ul className="space-y-1.5 text-sm">
                <li><Link href="/login" className="hover:text-night-text">ورود کاربران</Link></li>
                <li><Link href="/#start" className="hover:text-night-text">شروع همکاری</Link></li>
              </ul>
            </div>
          </div>
          <div className="mt-10 flex flex-col items-center justify-between gap-2 border-t border-white/10 pt-6 text-xs sm:flex-row">
            <span>© {new Date().getFullYear()} {siteConfig.nameFa}</span>
            <span>سامانه عملیات لجستیک ملی</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
