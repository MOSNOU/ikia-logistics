import Link from "next/link";
import { Button } from "@/components/ui/button";
import { siteConfig } from "@/lib/config/site";

// CC-56 — Public marketing layout. Refined header with section anchor nav
// (no new routes added) + footer with 3 disclosure columns. Persian/RTL.

const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/#platform", label: "پلتفرم" },
  { href: "/#visibility", label: "ردیابی" },
  { href: "/#driver", label: "اپ راننده" },
  { href: "/#corridor", label: "کریدور" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="sticky top-0 z-30 border-b border-border-soft bg-card/80 backdrop-blur supports-[backdrop-filter]:bg-card/60">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <Link
            href="/"
            className="flex items-center gap-2 text-sm font-semibold tracking-tight"
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
              <Button key={n.href} asChild variant="ghost" size="sm">
                <Link href={n.href}>{n.label}</Link>
              </Button>
            ))}
          </nav>
          <div className="flex items-center gap-2">
            <Button asChild variant="ghost" size="sm">
              <Link href="/login">ورود</Link>
            </Button>
            <Button asChild size="sm">
              <Link href="/#demo">درخواست دمو</Link>
            </Button>
          </div>
        </div>
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-border-soft bg-surface-muted">
        <div className="mx-auto max-w-6xl px-4 py-10">
          <div className="grid gap-8 sm:grid-cols-3">
            <div className="space-y-2">
              <div className="text-sm font-semibold">{siteConfig.nameFa}</div>
              <p className="text-xs leading-6 text-muted-foreground">
                {siteConfig.taglineFa}
              </p>
            </div>
            <div className="space-y-2">
              <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                پلتفرم
              </div>
              <ul className="space-y-1.5 text-sm">
                <li><Link href="/#platform" className="hover:underline">بازار، اعزام، تسویه</Link></li>
                <li><Link href="/#visibility" className="hover:underline">رؤیت و کنترل‌تاور</Link></li>
                <li><Link href="/#driver" className="hover:underline">کنسول راننده</Link></li>
                <li><Link href="/#corridor" className="hover:underline">کریدور و ترانزیت</Link></li>
              </ul>
            </div>
            <div className="space-y-2">
              <div className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                ورود به سامانه
              </div>
              <ul className="space-y-1.5 text-sm">
                <li><Link href="/login" className="hover:underline">ورود کاربران</Link></li>
                <li><Link href="/#demo" className="hover:underline">درخواست دمو</Link></li>
              </ul>
            </div>
          </div>
          <div className="mt-10 flex flex-col items-center justify-between gap-2 border-t border-border-soft pt-6 text-xs text-muted-foreground sm:flex-row">
            <span>© {new Date().getFullYear()} {siteConfig.nameFa}</span>
            <span>سامانه عملیات لجستیک ملی</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
