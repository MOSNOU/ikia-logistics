import type { Metadata } from "next";
import { Check } from "lucide-react";
import { Container, Section, SectionHeading } from "@/components/ui/Section";
import { FeatureGrid } from "@/components/sections/FeatureGrid";
import { Button } from "@/components/ui/Button";
import { LogoSphere } from "@/components/Logo";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "درباره iKIA Logistic",
  description:
    "iKIA Logistic زیرساخت اعتماد برای لجستیک ایران است؛ پلتفرمی برای شفافیت، اطمینان و کنترل در حمل‌ونقل بار.",
  path: "/about",
});

const TRUST = ["شفافیت در مسیر", "اعتماد در همکاری", "کنترل در عملیات"];

const ADVANTAGES = [
  {
    icon: "matching",
    title: "حذف واسطه‌های غیرضروری",
    desc: "ارتباط مستقیم‌تر میان بارفرست و حمل‌کننده، با فرآیندی شفاف و قابل پیگیری.",
  },
  {
    icon: "repeat",
    title: "کاهش خالی‌برگشت",
    desc: "اتصال بار برگشت به ظرفیت خالی ناوگان برای افزایش درآمد و بهره‌وری.",
  },
  {
    icon: "tracking",
    title: "شفافیت در قیمت و مسیر",
    desc: "نمایش بهتر وضعیت بار، مسیر، هزینه و مراحل حمل برای تصمیم‌گیری مطمئن‌تر.",
  },
  {
    icon: "finance",
    title: "اعتماد در همکاری",
    desc: "زیرساختی برای همکاری امن، قابل پیگیری و مبتنی بر داده میان همه بازیگران لجستیک.",
  },
];

export default function AboutPage() {
  return (
    <>
      {/* Trust hero — calm green, centered, premium globe brand visual */}
      <section
        className="border-b border-[#bbf7d0]"
        style={{ background: "linear-gradient(180deg, #DCFCE7 0%, #F0FDF4 100%)" }}
      >
        <Container className="flex flex-col items-center py-16 text-center lg:py-[88px]">
          <div className="relative mb-7">
            <div aria-hidden className="brand-glow absolute -inset-7 -z-10 rounded-full bg-[#16a34a]/25 blur-3xl" />
            <div className="brand-float">
              <LogoSphere size={158} />
            </div>
          </div>
          <p className="font-mono text-[11px] font-bold uppercase tracking-[0.22em] text-[#16a34a]" dir="ltr">
            Trust Infrastructure
          </p>
          <h1 className="mt-3 max-w-2xl text-[clamp(1.7rem,3vw,2.5rem)] font-extrabold leading-[1.2] tracking-tight text-[#14532d]">
            زیرساخت اعتماد برای لجستیک ایران
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-[15px] leading-8 text-[#14532d]/85 sm:text-base">
            iKIA Logistic با هدف ایجاد شفافیت، اطمینان و کنترل در جریان حمل‌ونقل ساخته شده است؛ پلتفرمی که بارفرست،
            حمل‌کننده، مراکز لجستیک و شرکای عملیاتی را در یک بستر قابل اعتماد به هم متصل می‌کند.
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

      {/* داستان ما */}
      <Section tone="light">
        <SectionHeading
          title="داستان ما"
          subtitle="چرا iKIA را می‌سازیم و چه چیزی را برای صنعت لجستیک ساده‌تر می‌کنیم."
        />
        <div className="mx-auto max-w-3xl space-y-5 text-center text-[15px] leading-9 text-muted sm:text-base sm:leading-10">
          <p>
            صنعت حمل‌ونقل جاده‌ای و لجستیک ایران سال‌ها با چالش‌هایی مانند هزینه‌های بالای واسطه‌گری، نبود شفافیت در
            قیمت‌گذاری، خالی‌برگشت کامیون‌ها و دشواری ردیابی محموله‌ها روبه‌رو بوده است.
          </p>
          <p>
            <strong className="font-bold text-ink">iKIA Logistic</strong> برای پاسخ به همین نیاز شکل گرفت: ساخت یک
            زیرساخت دیجیتال قابل اعتماد که حمل بار را ساده‌تر، شفاف‌تر، ارزان‌تر و قابل مدیریت‌تر کند.
          </p>
          <p>
            ما به‌جای وعده‌های بزرگ، از قابلیت‌های واقعی شروع می‌کنیم؛ از مدیریت سفارش و ردیابی لحظه‌ای تا اتصال به شبکه
            حمل، مراکز لجستیک، اسناد، کریدورها و خدمات ارزش‌افزوده.
          </p>
        </div>
      </Section>

      {/* مزایای ما — centered cards */}
      <Section tone="soft">
        <SectionHeading title="مزایای ما" subtitle="آنچه iKIA برای صاحبان بار و شرکای لجستیک ساده‌تر می‌کند." />
        <FeatureGrid items={ADVANTAGES} />
      </Section>

      {/* CTA — trust green, readable buttons */}
      <section className="relative overflow-hidden bg-gradient-to-b from-ink to-ink-2 text-white">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{ background: "radial-gradient(50% 80% at 80% 0%, rgba(22,163,74,0.22) 0%, transparent 70%)" }}
        />
        <Container className="relative py-20 text-center lg:py-24">
          <h2 className="text-[clamp(1.6rem,3vw,2.4rem)] font-extrabold leading-[1.2]">با ما همراه شوید</h2>
          <p className="mx-auto mt-4 max-w-2xl text-[15px] leading-8 text-ondark-muted sm:text-base">
            اگر صاحب بار، حمل‌کننده، مرکز لجستیک یا شریک فناوری هستید، iKIA بستری برای همکاری شفاف، امن و قابل توسعه فراهم
            می‌کند.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <Button href="/contact" variant="green" size="lg" className="px-7">
              شروع همکاری
            </Button>
            <Button href="/platform" variant="outlineLight" size="lg" className="px-7">
              مشاهده پلتفرم
            </Button>
          </div>
        </Container>
      </section>
    </>
  );
}
