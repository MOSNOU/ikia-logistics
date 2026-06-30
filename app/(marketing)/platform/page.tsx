import type { Metadata } from "next";
import { Container, Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { ModuleGrid } from "@/components/sections/ModuleGrid";
import { ControlTower } from "@/components/sections/ControlTower";
import { FinalCTA } from "@/components/sections/FinalCTA";
import { PlatformOverviewVisual } from "@/components/sections/Visuals";
import { PLATFORM, PRODUCT_URLS } from "@/content/siteArchitecture";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "پلتفرم iKIA — سیستم‌عامل دیجیتال لجستیک",
  description:
    "هسته مشترک iKIA: برج کنترل، رهگیری لحظه‌ای، مدیریت سفارش، اسناد و انطباق و یکپارچه‌سازی سامانه‌ها در یک پلتفرم واحد.",
  path: "/platform",
});

// Platform modules surfaced on the overview grid (core capabilities first).
const CORE = PLATFORM.filter((m) =>
  ["control-tower", "visibility", "order-management", "documents-compliance", "integrations"].includes(m.key),
);
const ENGINE = PLATFORM.filter((m) =>
  ["booking", "smart-matching", "dynamic-pricing", "workflow-engine", "notifications", "analytics"].includes(m.key),
);

export default function PlatformPage() {
  return (
    <>
      {/* Hero — native RTL two-column; product visual in the first viewport */}
      <section className="relative overflow-hidden bg-gradient-to-b from-soft via-white to-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            background:
              "radial-gradient(46% 54% at 14% 18%, rgba(31,156,224,0.13) 0%, transparent 60%), radial-gradient(42% 48% at 88% 8%, rgba(11,92,173,0.10) 0%, transparent 62%)",
          }}
        />
        <Container className="relative grid items-center gap-12 py-14 lg:grid-cols-[0.95fr_1.05fr] lg:gap-14 lg:py-16">
          {/* copy — right in RTL */}
          <div className="text-center lg:text-start">
            <p className="font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-blue" dir="ltr">
              The Platform
            </p>
            <h1 className="mx-auto mt-4 max-w-[560px] text-[clamp(1.9rem,3vw,2.85rem)] font-extrabold leading-[1.18] tracking-tight text-ink lg:mx-0">
              یک پلتفرم واحد برای کل عملیات لجستیک
            </h1>
            <p className="mx-auto mt-5 max-w-[540px] text-[16px] leading-8 text-muted lg:mx-0">
              همه ماژول‌های iKIA روی یک هسته مشترک کار می‌کنند؛ از مدیریت سفارش و رهگیری لحظه‌ای تا اسناد، انطباق و
              اتصال سامانه‌ها — بدون گسست بین مراحل.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start">
              <Button href={PRODUCT_URLS.start} variant="primary" size="lg" className="px-7">
                شروع همکاری
              </Button>
              <Button href="/platform/control-tower" variant="light" size="lg" className="px-7">
                برج کنترل
              </Button>
            </div>
          </div>

          {/* platform visual — left in RTL */}
          <div className="mx-auto w-full max-w-xl lg:max-w-none">
            <PlatformOverviewVisual />
          </div>
        </Container>
      </section>

      {/* Core capabilities */}
      <Section tone="soft">
        <SectionHeading
          eyebrow="Core"
          title="قابلیت‌های کلیدی پلتفرم"
          subtitle="پایه‌های عملیاتی iKIA که امروز در دسترس‌اند و گام‌به‌گام گسترش می‌یابند."
        />
        <ModuleGrid modules={CORE} featuredCount={1} />
      </Section>

      <ControlTower />

      {/* Engine modules */}
      <Section tone="light">
        <SectionHeading
          eyebrow="Engine"
          title="موتور عملیاتی پلتفرم"
          subtitle="رزرو ظرفیت، تخصیص هوشمند، قیمت‌گذاری پویا، موتور فرایند، اعلان‌ها و گزارش‌ها."
        />
        <ModuleGrid modules={ENGINE} />
      </Section>

      <FinalCTA />
    </>
  );
}
