import type { Metadata } from "next";
import Link from "next/link";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "منابع iKIA",
  description: "وبلاگ، راهنماها، مستندات و سوالات متداول iKIA.",
  path: "/resources",
});

const ITEMS = [
  { href: "/resources/blog", title: "وبلاگ", desc: "یادداشت‌ها و اخبار iKIA" },
  { href: "/resources/guides", title: "راهنماها و مطالعات موردی", desc: "راهنمای کاربردی صنعت" },
  { href: "/resources/docs", title: "مستندات", desc: "مرجع فنی و محصول" },
  { href: "/resources/faq", title: "سوالات متداول", desc: "پاسخ پرسش‌های رایج" },
];

export default function ResourcesPage() {
  return (
    <>
      <PageHero eyebrow="منابع" title="منابع و راهنماها" subtitle="هر آنچه برای شناخت بهتر iKIA لازم دارید." />
      <Section tone="light">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-2xl border border-slate-200 bg-white p-6 transition hover:-translate-y-0.5 hover:border-[#06b6d4] hover:shadow-md"
            >
              <h3 className="text-base font-black text-[#1e3a5f]">{item.title}</h3>
              <p className="mt-2 text-xs leading-7 text-slate-500">{item.desc}</p>
            </Link>
          ))}
        </div>
      </Section>
    </>
  );
}
