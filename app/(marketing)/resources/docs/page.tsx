import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "مستندات iKIA",
  description: "مرجع فنی و محصول iKIA — در مسیر توسعه.",
  path: "/resources/docs",
});

export default function DocsPage() {
  return (
    <>
      <PageHero eyebrow="مستندات" title="مستندات محصول و فنی" subtitle="مرجع استفاده از iKIA." />
      <Section tone="light" className="text-center">
        <div className="mx-auto max-w-xl rounded-2xl border border-slate-200 bg-slate-50 p-8">
          <p className="text-sm leading-8 text-slate-600">
            مستندات فنی و محصول iKIA در مسیر توسعه است. با پایدارتر شدن قابلیت‌ها، مرجع رسمی در این بخش در دسترس
            قرار می‌گیرد.
          </p>
          <div className="mt-6">
            <Button href="/contact" variant="outline" size="md">
              درخواست دسترسی زودهنگام
            </Button>
          </div>
        </div>
      </Section>
    </>
  );
}
