import type { Metadata } from "next";
import { Check } from "lucide-react";
import { Container, Section, SectionHeading } from "@/components/ui/Section";
import { FeatureGrid } from "@/components/sections/FeatureGrid";
import { ContactForm } from "@/components/sections/ContactForm";
import { Button } from "@/components/ui/Button";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "شروع همکاری با iKIA",
  description:
    "تیم iKIA آماده گفت‌وگو برای ساخت یک همکاری شفاف، امن و قابل توسعه است؛ برای صاحبان بار، حمل‌کنندگان، مراکز لجستیک و شرکای فناوری.",
  path: "/contact",
});

const TRUST = ["پاسخ‌گویی شفاف", "همکاری امن", "مسیر رشد مشترک"];

const AUDIENCE = [
  {
    icon: "package",
    title: "صاحبان بار",
    desc: "برای مدیریت بهتر سفارش‌ها، کاهش هزینه حمل و دسترسی به شبکه قابل اعتماد حمل‌ونقل.",
  },
  {
    icon: "truck",
    title: "حمل‌کنندگان و ناوگان",
    desc: "برای دریافت بار بیشتر، کاهش خالی‌برگشت و همکاری شفاف با بارفرست‌ها.",
  },
  {
    icon: "hub",
    title: "مراکز لجستیک و انبارها",
    desc: "برای اتصال ظرفیت‌های عملیاتی به یک شبکه دیجیتال و افزایش بهره‌وری.",
  },
  {
    icon: "api",
    title: "شرکای فناوری و سرمایه‌گذاران",
    desc: "برای توسعه سرویس‌های مکمل، API، داده، بیمه، مالی و راهکارهای هوشمند لجستیک.",
  },
];

export default function ContactPage() {
  return (
    <>
      {/* Trust hero — soft green, centered */}
      <section
        className="border-b border-[#bbf7d0]"
        style={{ background: "linear-gradient(180deg, #DCFCE7 0%, #F0FDF4 100%)" }}
      >
        <Container className="flex flex-col items-center py-16 text-center lg:py-20">
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-[#16a34a]" dir="ltr">
            Partnership
          </p>
          <h1 className="mt-3 max-w-2xl text-[clamp(1.7rem,3vw,2.5rem)] font-extrabold leading-[1.2] tracking-tight text-[#14532d]">
            شروع همکاری با iKIA
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-[15px] leading-8 text-[#14532d]/85 sm:text-base">
            اگر صاحب بار، حمل‌کننده، مرکز لجستیک، شریک فناوری یا سرمایه‌گذار هستید، تیم iKIA آماده گفت‌وگو برای ساخت یک
            همکاری شفاف، امن و قابل توسعه است.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            {TRUST.map((t) => (
              <span
                key={t}
                className="inline-flex items-center gap-2 rounded-full border border-[#bbf7d0] bg-white px-4 py-2 text-[13px] font-semibold text-[#14532d] shadow-[0_1px_2px_rgba(20,83,45,0.06)]"
              >
                <Check className="h-4 w-4 text-[#16a34a]" aria-hidden />
                {t}
              </span>
            ))}
          </div>
        </Container>
      </section>

      {/* Who iKIA is for — centered cards */}
      <Section tone="soft">
        <SectionHeading
          title="iKIA برای چه کسانی است؟"
          subtitle="هر همکاری از یک گفت‌وگوی روشن شروع می‌شود؛ مسیر متناسب با نقش خود را انتخاب کنید."
        />
        <FeatureGrid items={AUDIENCE} />
      </Section>

      {/* Partnership request — form + readable CTAs */}
      <Section tone="light">
        <SectionHeading
          title="درخواست همکاری"
          subtitle="فرم زیر را پر کنید؛ تیم iKIA در اولین فرصت با شما در ارتباط خواهد بود."
        />
        <ContactForm />
        <div className="mt-6 flex justify-center">
          <Button href="/platform" variant="outline" size="lg" className="px-7">
            مشاهده پلتفرم
          </Button>
        </div>
      </Section>
    </>
  );
}
