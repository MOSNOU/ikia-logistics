import Link from "next/link";
import { LogoNav } from "@/components/Logo";
import { FOOTER_GROUPS } from "@/content/navigation";

export function Footer() {
  return (
    <footer className="bg-navy-950 text-slate-300">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-10 sm:grid-cols-3 lg:grid-cols-6">
          {/* brand column */}
          <div className="col-span-2 sm:col-span-3 lg:col-span-1">
            <div className="mb-4 [&_*]:!text-white">
              <LogoNav onDark />
            </div>
            <p className="max-w-xs text-sm leading-7 text-slate-400">
              سیستم‌عامل دیجیتال لجستیک برای اتصال صاحبان بار، فورواردرها، کریرها و سازمان‌ها.
            </p>
          </div>

          {FOOTER_GROUPS.map((group) => (
            <div key={group.key}>
              <h3 className="mb-4 text-sm font-black text-white">{group.label}</h3>
              <ul className="space-y-2.5">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-sm leading-6 text-slate-400 transition hover:text-brand-400"
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
          <p className="text-xs text-slate-500">© {new Date().getFullYear()} iKIA Logistics. تمامی حقوق محفوظ است.</p>
          <p className="text-xs text-slate-500">ساخته‌شده برای لجستیک شفاف و قابل اتکا.</p>
        </div>
      </div>
    </footer>
  );
}
