import type { Metadata } from "next";
import { Hero } from "@/components/sections/Hero";
import { PersonaCTA } from "@/components/sections/PersonaCTA";
import { FeatureGrid } from "@/components/sections/FeatureGrid";
import { HowItWorks } from "@/components/sections/HowItWorks";
import { StatsBand } from "@/components/sections/StatsBand";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { PLATFORM_OVERVIEW } from "@/content/platform";
import { PRODUCT_URLS } from "@/content/navigation";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "iKIA Logistics | سیستم‌عامل دیجیتال لجستیک",
  description:
    "iKIA صاحبان بار، فورواردرها و کریرها را در یک زیرساخت واحد به هم وصل می‌کند: تخصیص هوشمند بار، ردیابی لحظه‌ای، اسناد و آمادگی تسویه مالی.",
  path: "/",
});

const STATS = [
  { value: "۹۰۰+", label: "کیلومتر کریدور پایلوت" },
  { value: "۳۰٪", label: "هدف کاهش هزینه" },
  { value: "۴۰٪", label: "هدف کاهش خالی‌برگشت" },
  { value: "۲۴h", label: "آماده‌سازی تسویه" },
];

export default function HomePage() {
  return (
    <>
      <Hero />

      <Section tone="surface" id="personas">
        <SectionHeading
          eyebrow="راهکارها"
          title="iKIA برای چه کسانی ساخته شده است؟"
          subtitle="مسیر خود را انتخاب کنید و راهکار متناسب با نقش‌تان را ببینید."
        />
        <PersonaCTA />
      </Section>

      <Section tone="light">
        <SectionHeading
          eyebrow="پلتفرم"
          title="قابلیت‌های کلیدی پلتفرم"
          subtitle="زیرساختی که گام‌به‌گام در حال توسعه است و امروز پایه‌های عملیاتی آن آماده شده."
        />
        <FeatureGrid items={PLATFORM_OVERVIEW.capabilities} />
        <div className="mt-12 text-center">
          <Button href="/platform" variant="outline" size="md">
            مشاهده کامل پلتفرم
          </Button>
        </div>
      </Section>

      <Section tone="surface">
        <SectionHeading
          eyebrow="فرایند"
          title="چطور کار می‌کند"
          subtitle="از ثبت نیاز حمل تا تحویل و تسویه، در چهار گام روشن."
        />
        <HowItWorks
          steps={[
            { title: "ثبت نیاز حمل", desc: "مشخصات بار و مسیر را وارد کنید." },
            { title: "دریافت پیشنهاد", desc: "پیشنهادهای شفاف را مقایسه کنید." },
            { title: "تخصیص و شروع سفر", desc: "بار تخصیص می‌یابد و سفر آغاز می‌شود." },
            { title: "رهگیری، تحویل و تسویه", desc: "وضعیت را تا تحویل و تسویه دنبال کنید." },
          ]}
        />
      </Section>

      <Section tone="dark">
        <SectionHeading
          invert
          eyebrow="مقیاس و اعتماد"
          title="ساخته‌شده برای رشد"
          subtitle="اعداد زیر اهداف مرحله پایلوت هستند و در مسیر توسعه قرار دارند."
        />
        <StatsBand stats={STATS} />
      </Section>

      <section className="relative overflow-hidden bg-gradient-to-b from-navy-900 to-navy-950 text-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(50% 80% at 75% 0%, rgba(11,92,173,0.30) 0%, transparent 70%)" }}
        />
        <div className="relative mx-auto w-full max-w-7xl px-4 py-20 text-center sm:px-6 lg:px-8 md:py-24">
          <h2 className="text-3xl font-black md:text-5xl">آماده‌اید شروع کنید؟</h2>
          <p className="mx-auto mt-5 max-w-xl text-base leading-8 text-slate-300 md:text-lg">
            ثبت‌نام رایگان — بدون نیاز به قرارداد. همین حالا iKIA را امتحان کنید.
          </p>
          <div className="mt-9 flex flex-wrap justify-center gap-3">
            <Button href={PRODUCT_URLS.register} variant="primary" size="lg">
              شروع کنید — رایگان
            </Button>
            <Button href="/contact" variant="outlineLight" size="lg">
              تماس با ما
            </Button>
          </div>
        </div>
      </section>
    </>
  );
}
