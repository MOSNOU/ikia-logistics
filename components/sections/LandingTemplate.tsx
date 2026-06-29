import type { ModuleEntry } from "@/content/modules/types";
import { STATUS_META } from "@/content/modules/types";
import { Container, Section, SectionHeading, Eyebrow } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { FeatureGrid } from "./FeatureGrid";
import { HowItWorks } from "./HowItWorks";
import { FinalCTA } from "./FinalCTA";
import {
  ControlTowerVisual,
  VisibilityVisual,
  DocumentComplianceVisual,
  CorridorNetworkVisual,
} from "./Visuals";
import { Check } from "lucide-react";
import { PRODUCT_URLS } from "@/content/siteArchitecture";

function VisualFor({ module }: { module: ModuleEntry }) {
  switch (module.key) {
    case "visibility":
      return <VisibilityVisual />;
    case "documents-compliance":
    case "customs":
      return <DocumentComplianceVisual />;
    case "instc":
    case "east-west":
    case "corridor-mgmt":
      return <CorridorNetworkVisual />;
    default:
      return <ControlTowerVisual />;
  }
}

// Flexport-style product landing page. Two-column hero with product visual,
// feature band, problem/solution split, capabilities, workflow timeline, CTA.
export function LandingTemplate({ module }: { module: ModuleEntry }) {
  const status = STATUS_META[module.status];
  const d = module.detail;

  return (
    <>
      {/* A. Hero — two column with product visual */}
      <section className="relative overflow-hidden bg-gradient-to-b from-soft via-white to-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(48% 55% at 88% 5%, rgba(31,156,224,0.10) 0%, transparent 60%)" }}
        />
        <Container className="relative grid items-center gap-12 py-14 lg:min-h-[calc(100vh-102px)] lg:grid-cols-[0.92fr_1.08fr] lg:gap-14 lg:py-16">
          {/* copy — first item renders on the RIGHT in RTL */}
          <div className="text-center lg:text-start">
            <div className="mb-4 flex items-center justify-center gap-2.5 lg:justify-start">
              <span className="font-mono text-[11px] font-bold uppercase tracking-[0.2em] text-blue" dir="ltr">
                {module.enTitle}
              </span>
              {module.status !== "current" ? (
                <span className={`rounded-md px-2 py-0.5 text-[10px] font-semibold ${status.tone}`}>{status.label}</span>
              ) : null}
            </div>
            <h1 className="mx-auto max-w-[520px] text-[clamp(1.9rem,3vw,2.85rem)] font-extrabold leading-[1.18] tracking-tight text-ink lg:mx-0">
              {module.faTitle}
            </h1>
            <p className="mx-auto mt-5 max-w-[540px] text-[16px] leading-8 text-muted lg:mx-0">{module.value}</p>
            <div className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start">
              <Button href={PRODUCT_URLS.start} variant="primary" size="lg" className="px-7">
                {module.cta}
              </Button>
              <Button href="/platform" variant="light" size="lg" className="px-7">
                مشاهده پلتفرم
              </Button>
            </div>
          </div>

          {/* product visual — second item renders on the LEFT in RTL */}
          <div className="mx-auto w-full max-w-xl lg:max-w-none">
            <VisualFor module={module} />
          </div>
        </Container>
      </section>

      {/* B. Feature overview band */}
      <section className="border-y border-line bg-white">
        <Container className="flex flex-col items-start justify-between gap-5 py-7 sm:flex-row sm:items-center">
          <p className="max-w-2xl text-[15px] leading-7 text-muted">{module.solution}</p>
          <div className="flex flex-wrap items-center gap-2">
            {module.targetUsers.map((u) => (
              <span key={u} className="rounded-full bg-soft px-3 py-1 text-[12px] font-medium text-ink ring-1 ring-line">
                {u}
              </span>
            ))}
          </div>
        </Container>
      </section>

      {d ? (
        <>
          {/* C. Problem / solution split */}
          <Section tone="soft">
            <div className="grid gap-8 lg:grid-cols-2 lg:gap-12">
              <div>
                <Eyebrow>Challenge</Eyebrow>
                <h2 className="mt-3 text-[clamp(1.5rem,2.6vw,2rem)] font-bold leading-[1.2] tracking-tight text-ink">
                  چالش‌هایی که حل می‌کنیم
                </h2>
                <ul className="mt-6 divide-y divide-line/70">
                  {d.pains.map((pain) => (
                    <li key={pain.title} className="flex gap-3.5 py-4 first:pt-0">
                      <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-ikia/70" aria-hidden />
                      <span>
                        <span className="block text-[15px] font-bold text-ink">{pain.title}</span>
                        <span className="mt-1 block text-[13px] leading-6 text-muted">{pain.desc}</span>
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="lg:pt-12">
                <div className="rounded-3xl border border-line bg-white p-7 shadow-[0_1px_2px_rgba(6,26,47,0.04)]">
                  <Eyebrow>iKIA</Eyebrow>
                  <h3 className="mt-2 text-[18px] font-bold text-ink">راهکار iKIA</h3>
                  <p className="mt-2.5 text-[14px] leading-7 text-muted">{module.solution}</p>
                  <ul className="mt-5 space-y-2.5">
                    {d.capabilities.slice(0, 4).map((c) => (
                      <li key={c.title} className="flex items-center gap-2.5 text-[14px] text-ink">
                        <span className="flex h-6 w-6 items-center justify-center rounded-md bg-green/10 text-green">
                          <Check className="h-3.5 w-3.5" aria-hidden />
                        </span>
                        {c.title}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          </Section>

          {/* D. Capabilities */}
          <Section tone="light">
            <SectionHeading eyebrow="Capabilities" title="قابلیت‌های iKIA" />
            <FeatureGrid items={d.capabilities} />
          </Section>

          {/* E. Workflow timeline */}
          <Section tone="soft">
            <SectionHeading eyebrow="Workflow" title="جریان کار" />
            <HowItWorks steps={d.steps} />
          </Section>
        </>
      ) : (
        <Section tone="soft">
          <div className="mx-auto max-w-2xl rounded-3xl border border-line bg-white p-8 text-center">
            <p className="text-[15px] leading-8 text-muted">{module.solution}</p>
            <div className="mt-6 flex justify-center">
              <Button href={PRODUCT_URLS.start} variant="primary" size="md">
                {module.cta}
              </Button>
            </div>
          </div>
        </Section>
      )}

      <FinalCTA
        title={module.cta}
        subtitle={`${module.faTitle} بخشی از سیستم‌عامل دیجیتال لجستیک iKIA است. برای گفتگو با تیم ما تماس بگیرید.`}
      />
    </>
  );
}

export const ModuleLandingPage = LandingTemplate;
export const ServiceLandingPage = LandingTemplate;
export const SolutionLandingPage = LandingTemplate;
export const CorridorLandingPage = LandingTemplate;
export const PlatformFeaturePage = LandingTemplate;
