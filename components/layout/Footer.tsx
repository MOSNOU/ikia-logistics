import Link from "next/link";
import { ShieldCheck, ArrowLeft } from "lucide-react";
import { LogoNav } from "@/components/Logo";
import { Button } from "@/components/ui/Button";
import { FOOTER_COLUMNS } from "@/content/siteArchitecture";

export function Footer() {
  return (
    <footer className="border-t border-[#E4EAF1] bg-white text-[#061A2F]">
      {/* Trust + partnership band — soft band, prominent professional green */}
      <div className="border-b border-[#E4EAF1] bg-[#F7F9FC]">
        <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 px-4 py-9 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full border border-[#BBF7D0] bg-[#DCFCE7] px-3 py-1.5 text-[12px] font-bold text-[#14532D]">
              <ShieldCheck className="h-4 w-4 text-[#16A34A]" aria-hidden />
              زیرساخت اعتماد برای لجستیک هوشمند ایران
            </span>
            <p className="mt-3 text-[18px] font-extrabold leading-snug text-[#061A2F] sm:text-[20px]">
              آماده همکاری با iKIA هستید؟
            </p>
          </div>
          <div className="flex flex-wrap gap-3">
            <Button href="/contact" variant="green" size="lg" className="px-7">
              شروع همکاری
            </Button>
            <Button href="/platform" variant="outline" size="lg" className="px-7">
              مشاهده پلتفرم
            </Button>
          </div>
        </div>
      </div>

      {/* Main footer — light, dark-navy text */}
      <div className="mx-auto w-full max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 gap-10 sm:grid-cols-3 lg:grid-cols-5">
          {/* brand column — logo sits directly on the white footer, no box */}
          <div className="col-span-2 sm:col-span-3 lg:col-span-1">
            <a href="/" aria-label="iKIA Logistics — خانه" className="inline-flex">
              <LogoNav variant="footer" />
            </a>
            {/* trust phrase with green accent dot */}
            <p className="mt-5 flex items-start gap-2 text-[13.5px] font-semibold leading-7 text-[#061A2F]">
              <span aria-hidden className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-[#16A34A]" />
              زیرساخت اعتماد برای لجستیک هوشمند ایران
            </p>
            <p className="mt-2 max-w-xs text-[13px] leading-7 text-[#5B6B7D]">
              سیستم‌عامل دیجیتال لجستیک برای اتصال صاحبان بار، حمل‌کنندگان، مراکز لجستیک و سازمان‌ها.
            </p>
          </div>

          {FOOTER_COLUMNS.map((group) => (
            <div key={group.key}>
              <h3 className="mb-4 text-[13px] font-bold text-[#061A2F]">{group.label}</h3>
              <ul className="space-y-2.5">
                {group.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="text-[13px] leading-6 text-[#061A2F] transition-colors hover:text-[#0B5CAD]"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-start justify-between gap-3 border-t border-[#E4EAF1] pt-6 sm:flex-row sm:items-center">
          <p className="text-[12px] text-[#5B6B7D]">
            © {new Date().getFullYear()} iKIA Logistic. تمامی حقوق محفوظ است.
          </p>
          <Link
            href="/contact"
            className="inline-flex items-center gap-1.5 text-[12px] font-semibold text-[#16A34A] transition-colors hover:text-[#14532D]"
          >
            ساخته‌شده برای لجستیک شفاف و قابل اتکا
            <ArrowLeft className="h-3.5 w-3.5" aria-hidden />
          </Link>
        </div>
      </div>
    </footer>
  );
}
