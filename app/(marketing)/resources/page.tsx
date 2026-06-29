import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Container, Section } from "@/components/ui/Section";
import { Icon } from "@/components/ui/icons";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "منابع و دانش لجستیک دیجیتال — iKIA",
  description:
    "محتوای آموزشی، راهنماها، پرسش‌های متداول و به‌روزرسانی‌های iKIA برای آشنایی بهتر با پلتفرم و آینده لجستیک هوشمند.",
  path: "/resources",
});

const RESOURCES = [
  {
    href: "/value-added/customs",
    icon: "customs",
    title: "راهنماهای مرزی و گمرکی",
    desc: "آشنایی با مسیرهای مرزی، تشریفات گمرکی و اسناد موردنیاز برای حمل‌ونقل بین‌المللی.",
  },
  {
    href: "/developers",
    icon: "developers",
    title: "توسعه‌دهندگان و API",
    desc: "راهنمای اتصال سامانه‌ها، شرکای عملیاتی و سرویس‌های نرم‌افزاری به پلتفرم iKIA.",
  },
  {
    href: "/resources/faq",
    icon: "insight",
    title: "سؤالات متداول",
    desc: "پاسخ ساده به پرسش‌های رایج درباره همکاری، ثبت سفارش، ردیابی، اسناد و خدمات پلتفرم.",
  },
  {
    href: "/resources/blog",
    icon: "documents",
    title: "وبلاگ",
    desc: "یادداشت‌ها، تحلیل‌ها و خبرهای مرتبط با لجستیک هوشمند، کریدورها و تحول دیجیتال حمل‌ونقل.",
  },
];

export default function ResourcesPage() {
  return (
    <>
      {/* Calm knowledge-hub hero — subtle blue/green accent */}
      <section className="relative overflow-hidden border-b border-line bg-gradient-to-b from-soft to-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(42% 55% at 84% 0%, rgba(31,156,224,0.10) 0%, transparent 60%), radial-gradient(40% 50% at 12% 100%, rgba(22,163,74,0.08) 0%, transparent 62%)",
          }}
        />
        <Container className="relative py-16 text-center lg:py-20">
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-blue" dir="ltr">
            Resources
          </p>
          <h1 className="mx-auto mt-3 max-w-2xl text-[clamp(1.7rem,3vw,2.5rem)] font-extrabold leading-[1.2] tracking-tight text-ink">
            منابع و دانش لجستیک دیجیتال
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-[15px] leading-8 text-muted sm:text-base">
            اینجا محتوای آموزشی، راهنماها، پرسش‌های متداول و به‌روزرسانی‌های iKIA برای آشنایی بهتر با پلتفرم و آینده لجستیک
            هوشمند قرار می‌گیرد.
          </p>
        </Container>
      </section>

      {/* Centered resource cards */}
      <Section tone="light">
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          {RESOURCES.map((r) => (
            <Link
              key={r.href}
              href={r.href}
              className="group flex h-full flex-col items-center rounded-[24px] border border-line bg-white p-7 text-center shadow-[0_1px_2px_rgba(6,26,47,0.04)] transition-all duration-200 hover:-translate-y-0.5 hover:border-blue/25 hover:shadow-[0_18px_44px_-22px_rgba(6,26,47,0.22)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue/30"
            >
              <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue/[0.07] text-blue ring-1 ring-blue/10 transition-colors group-hover:bg-blue group-hover:text-white">
                <Icon name={r.icon} className="h-6 w-6" />
              </span>
              <h3 className="mt-5 text-[18px] font-extrabold leading-snug text-ink">{r.title}</h3>
              <p className="mt-2.5 flex-1 text-[14px] leading-7 text-muted">{r.desc}</p>
              <span className="mt-5 inline-flex items-center gap-1.5 text-[13px] font-bold text-blue">
                مشاهده
                <ArrowLeft className="h-4 w-4 transition-transform group-hover:-translate-x-1" aria-hidden />
              </span>
            </Link>
          ))}
        </div>
      </Section>
    </>
  );
}
