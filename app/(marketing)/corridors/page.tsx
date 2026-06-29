import type { Metadata } from "next";
import { Container, Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { ModuleGrid } from "@/components/sections/ModuleGrid";
import { FinalCTA } from "@/components/sections/FinalCTA";
import { CorridorNetworkVisual } from "@/components/sections/Visuals";
import { CORRIDORS, PRODUCT_URLS } from "@/content/siteArchitecture";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "کریدورها و شبکه مراکز لجستیک — iKIA",
  description:
    "اتصال بازار ایران به کریدورهای شمال–جنوب و شرق–غرب، بنادر جنوبی، درگاه‌های مرزی و شبکه ۵۸ مرکز لجستیک.",
  path: "/corridors",
});

const STATS: [string, string][] = [
  ["۲", "کریدور راهبردی"],
  ["۵۸", "مرکز لجستیک"],
  ["۴", "شیوه حمل متصل"],
];

export default function CorridorsPage() {
  return (
    <>
      {/* Hero — native RTL two-column; visual in the first viewport */}
      <section className="relative overflow-hidden bg-gradient-to-b from-soft via-white to-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(46% 54% at 14% 18%, rgba(31,156,224,0.13) 0%, transparent 60%), radial-gradient(42% 48% at 88% 8%, rgba(11,92,173,0.10) 0%, transparent 62%)",
          }}
        />
        <Container className="relative grid items-center gap-12 py-14 lg:min-h-[calc(100vh-102px)] lg:grid-cols-[0.92fr_1.08fr] lg:gap-14 lg:py-16">
          {/* copy — first item renders on the RIGHT in RTL */}
          <div className="text-center lg:text-start">
            <p className="font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-blue" dir="ltr">
              Regional Corridors
            </p>
            <h1 className="mx-auto mt-4 max-w-[560px] text-[clamp(1.9rem,3vw,2.85rem)] font-extrabold leading-[1.18] tracking-tight text-ink lg:mx-0">
              اتصال بازار ایران به کریدورهای منطقه‌ای
            </h1>
            <p className="mx-auto mt-5 max-w-[540px] text-[16px] leading-8 text-muted lg:mx-0">
              ایران به‌عنوان هاب منطقه‌ای روی کریدورهای شمال–جنوب و شرق–غرب، بنادر جنوبی، درگاه‌های مرزی و شبکه ۵۸ مرکز
              لجستیک — همه در یک شبکه زنده و چندوجهی.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start">
              <Button href={PRODUCT_URLS.start} variant="primary" size="lg" className="px-7">
                گفتگو درباره کریدورها
              </Button>
              <Button href="/corridors/instc" variant="light" size="lg" className="px-7">
                کریدور شمال–جنوب
              </Button>
            </div>
            <dl className="mx-auto mt-9 grid max-w-[540px] grid-cols-3 gap-4 border-t border-line pt-6 lg:mx-0">
              {STATS.map(([value, label]) => (
                <div key={label} className="text-center lg:text-start">
                  <dt className="text-[26px] font-extrabold leading-none text-ink">{value}</dt>
                  <dd className="mt-1.5 text-[12px] font-semibold leading-5 text-muted">{label}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* network visual — second item renders on the LEFT in RTL */}
          <div className="mx-auto w-full max-w-xl lg:max-w-none">
            <CorridorNetworkVisual />
          </div>
        </Container>
      </section>

      {/* Corridor architecture — modules (INSTC, East–West, gateways, 58 hubs) */}
      <Section tone="soft">
        <SectionHeading
          eyebrow="Network"
          title="کریدورها و شبکه مراکز"
          subtitle="ایران به‌عنوان هاب منطقه‌ای، روی کریدورهای کلیدی، درگاه‌های مرزی و شبکه مراکز لجستیک."
        />
        <ModuleGrid modules={CORRIDORS} />
      </Section>

      <FinalCTA />
    </>
  );
}
