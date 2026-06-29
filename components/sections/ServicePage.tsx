import { AlertTriangle } from "lucide-react";
import type { ContentPage } from "@/content/types";
import { PageHero } from "./PageHero";
import { FeatureGrid } from "./FeatureGrid";
import { HowItWorks } from "./HowItWorks";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { PRODUCT_URLS } from "@/content/navigation";

// Reusable template for /platform/* and /services/* content pages.
export function ServicePage({ content }: { content: ContentPage }) {
  return (
    <>
      <PageHero eyebrow={content.eyebrow} title={content.title} subtitle={content.subtitle}>
        <Button href={PRODUCT_URLS.register} variant="light" size="md">
          شروع کنید
        </Button>
        <Button href="/contact" variant="outlineLight" size="md">
          تماس با ما
        </Button>
      </PageHero>

      <Section tone="light">
        <p className="mx-auto max-w-3xl text-center text-base leading-9 text-slate-600 md:text-lg">{content.intro}</p>
        {content.note ? (
          <div className="mx-auto mt-8 flex max-w-2xl items-start gap-3 rounded-xl border border-amber-200 bg-amber-50 px-5 py-4 text-sm leading-7 text-amber-800">
            <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-500" aria-hidden />
            <span>{content.note}</span>
          </div>
        ) : null}
      </Section>

      <Section tone="surface">
        <SectionHeading title="قابلیت‌ها" />
        <FeatureGrid items={content.capabilities} />
      </Section>

      {content.steps && content.steps.length > 0 ? (
        <Section tone="light">
          <SectionHeading title="چطور پیش می‌رود" />
          <HowItWorks steps={content.steps} />
        </Section>
      ) : null}

      <FinalCTA />
    </>
  );
}

function FinalCTA() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-navy-900 to-navy-950 text-white">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{ background: "radial-gradient(50% 80% at 80% 0%, rgba(11,92,173,0.30) 0%, transparent 70%)" }}
      />
      <div className="relative mx-auto w-full max-w-7xl px-4 py-20 text-center sm:px-6 lg:px-8 md:py-24">
        <h2 className="text-2xl font-black md:text-4xl">آماده شروع هستید؟</h2>
        <p className="mx-auto mt-4 max-w-xl text-base leading-8 text-slate-300">
          همین حالا iKIA را امتحان کنید یا برای گفتگو با تیم ما تماس بگیرید.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <Button href={PRODUCT_URLS.register} variant="primary" size="lg">
            شروع کنید
          </Button>
          <Button href="/contact" variant="outlineLight" size="lg">
            تماس با ما
          </Button>
        </div>
      </div>
    </section>
  );
}
