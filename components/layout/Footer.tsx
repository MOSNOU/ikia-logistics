import Link from "next/link";
import { LogoNav } from "@/components/Logo";
import { FOOTER_COLUMNS } from "@/content/siteArchitecture";

export function Footer() {
  return (
    <footer className="bg-ink text-ondark-muted">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-10 sm:grid-cols-3 lg:grid-cols-5">
          {/* brand column */}
          <div className="col-span-2 sm:col-span-3 lg:col-span-1">
            <div className="mb-4">
              <LogoNav onDark />
            </div>
            <p className="max-w-xs text-[13px] leading-7 text-ondark-muted">
              سیستم‌عامل دیجیتال لجستیک برای اتصال صاحبان بار، حمل‌کنندگان، مراکز لجستیک و سازمان‌ها.
            </p>
          </div>

          {FOOTER_COLUMNS.map((group) => (
            <div key={group.key}>
              <h3 className="mb-4 text-[13px] font-bold text-white">{group.label}</h3>
              <ul className="space-y-2.5">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-[13px] leading-6 text-ondark-muted transition hover:text-white"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-start justify-between gap-3 border-t border-white/10 pt-6 sm:flex-row sm:items-center">
          <p className="text-[12px] text-ondark-muted/70">
            © {new Date().getFullYear()} iKIA Logistic. تمامی حقوق محفوظ است.
          </p>
          <p className="text-[12px] text-ondark-muted/70">ساخته‌شده برای لجستیک شفاف و قابل اتکا.</p>
        </div>
      </div>
    </footer>
  );
}
