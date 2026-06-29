import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "راهنماها و مطالعات موردی",
  description: "راهنماهای کاربردی و مطالعات موردی iKIA — در حال آماده‌سازی.",
  path: "/resources/guides",
});

export default function GuidesPage() {
  return (
    <>
      <PageHero
        eyebrow="راهنماها"
        title="راهنماها و مطالعات موردی"
        subtitle="محتوای کاربردی برای استفاده بهتر از iKIA."
      />
      <Section tone="light" className="text-center">
        <div className="mx-auto max-w-xl rounded-2xl border border-slate-200 bg-slate-50 p-8">
          <p className="text-sm leading-8 text-slate-600">
            این بخش در حال آماده‌سازی است. به‌زودی راهنماهای گام‌به‌گام و مطالعات موردی مسیرهای پایلوت را اینجا
            منتشر می‌کنیم.
          </p>
          <div className="mt-6">
            <Button href="/contact" variant="outline" size="md">
              پیشنهاد موضوع راهنما
            </Button>
          </div>
        </div>
      </Section>
    </>
  );
}
