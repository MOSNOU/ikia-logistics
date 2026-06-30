import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Container, Section } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { FAQAccordion } from "@/components/sections/FAQAccordion";
import { FAQ_ITEMS } from "@/content/faq";
import { buildMetadata } from "@/lib/seo";

const base = buildMetadata({
  title: "سؤالات متداول iKIA",
  description:
    "پاسخ به پرسش‌های رایج درباره پلتفرم iKIA، حمل‌ونقل هوشمند، صاحبان بار، حمل‌کنندگان، رانندگان، اسناد، ردیابی و همکاری سازمانی.",
  path: "/resources/faq",
});

export const metadata: Metadata = {
  ...base,
  title: { absolute: "سؤالات متداول iKIA | لجستیک هوشمند و حمل‌ونقل دیجیتال" },
};

// FAQPage structured data — built from the same visible questions/answers.
const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQ_ITEMS.map((item) => ({
    "@type": "Question",
    name: item.q,
    acceptedAnswer: { "@type": "Answer", text: item.a },
  })),
};

export default function FAQPage() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />

      {/* Light hero — consistent with the resources knowledge hub */}
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
            FAQ
          </p>
          <h1 className="mx-auto mt-3 max-w-2xl text-[clamp(1.7rem,3vw,2.5rem)] font-extrabold leading-[1.2] tracking-tight text-ink">
            سؤالات متداول iKIA
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-[15px] leading-8 text-muted sm:text-base">
            پاسخ به پرسش‌های رایج درباره پلتفرم iKIA؛ از حمل‌ونقل هوشمند و صاحبان بار و حمل‌کنندگان تا اسناد، ردیابی،
            کریدورها و همکاری سازمانی.
          </p>
        </Container>
      </section>

      <Section tone="light">
        <FAQAccordion items={FAQ_ITEMS} />

        {/* Soft CTA to contact */}
        <div className="mx-auto mt-10 flex max-w-3xl flex-col items-center justify-between gap-4 rounded-2xl border border-line bg-soft px-6 py-6 text-center sm:flex-row sm:text-start">
          <div>
            <p className="text-[15px] font-bold text-ink">پاسخ پرسش‌تان را پیدا نکردید؟</p>
            <p className="mt-1 text-[13.5px] leading-7 text-muted">تیم iKIA آماده گفتگو درباره نیاز و همکاری شماست.</p>
          </div>
          <Button href="/contact" variant="primary" size="md" className="shrink-0">
            تماس و همکاری
            <ArrowLeft className="h-4 w-4" aria-hidden />
          </Button>
        </div>

        <div className="mt-8 text-center">
          <Link href="/resources" className="inline-flex items-center gap-1.5 text-[13px] font-bold text-blue hover:gap-2.5 transition-all">
            بازگشت به منابع
            <ArrowLeft className="h-4 w-4" aria-hidden />
          </Link>
        </div>
      </Section>
    </>
  );
}
