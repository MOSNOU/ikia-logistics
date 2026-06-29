import type { Persona } from "@/content/types";
import { PageHero } from "./PageHero";
import { FeatureGrid } from "./FeatureGrid";
import { HowItWorks } from "./HowItWorks";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";

// Reusable persona landing template for /forwarders, /shippers, /enterprise, /carriers.
export function PersonaLanding({ persona }: { persona: Persona }) {
  const isExternal = persona.cta.href.startsWith("http");
  return (
    <>
      <PageHero eyebrow={persona.badge} title={persona.title} subtitle={persona.subtitle}>
        <Button href={persona.cta.href} variant="primary" size="lg" external={isExternal}>
          {persona.cta.label}
        </Button>
        {persona.cta.note ? null : (
          <Button href="/platform" variant="outlineLight" size="lg">
            مشاهده پلتفرم
          </Button>
        )}
      </PageHero>

      {persona.cta.note ? (
        <div className="border-b border-amber-100 bg-amber-50 text-center">
          <p className="mx-auto max-w-3xl px-4 py-3 text-xs font-bold text-amber-800">{persona.cta.note}</p>
        </div>
      ) : null}

      {/* Pain points */}
      <Section tone="light">
        <SectionHeading title="چالش‌هایی که حل می‌کنیم" />
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
          {persona.pains.map((pain, i) => (
            <div
              key={pain.title}
              className="relative rounded-2xl border border-slate-200/80 bg-surface p-7"
            >
              <span className="mb-4 flex h-9 w-9 items-center justify-center rounded-lg bg-accent-600/10 text-sm font-black text-accent-600">
                {(i + 1).toLocaleString("fa-IR")}
              </span>
              <h3 className="mb-2 text-base font-extrabold text-navy-900">{pain.title}</h3>
              <p className="text-sm leading-7 text-slate-500">{pain.desc}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Capabilities.
          TODO(assets): hero/section illustration expected at `persona.image`.
          Wire next/image once the webp is provided in public/images/marketing. */}
      <Section tone="surface">
        <SectionHeading title="قابلیت‌های iKIA برای شما" />
        <FeatureGrid items={persona.capabilities} />
      </Section>

      {/* Workflow */}
      <Section tone="light">
        <SectionHeading title="جریان کار" />
        <HowItWorks steps={persona.steps} />
      </Section>

      {/* CTA */}
      <section className="relative overflow-hidden bg-gradient-to-b from-navy-900 to-navy-950 text-white">
        <div className="relative mx-auto w-full max-w-7xl px-4 py-20 text-center sm:px-6 lg:px-8 md:py-24">
          <h2 className="mx-auto max-w-2xl text-2xl font-black md:text-4xl">{persona.title}</h2>
          <p className="mx-auto mt-4 max-w-xl text-base leading-8 text-slate-300">{persona.subtitle}</p>
          <div className="mt-8 flex justify-center">
            <Button href={persona.cta.href} variant="primary" size="lg" external={isExternal}>
              {persona.cta.label}
            </Button>
          </div>
        </div>
      </section>
    </>
  );
}
