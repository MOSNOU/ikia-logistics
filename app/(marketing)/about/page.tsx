import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { FeatureGrid } from "@/components/sections/FeatureGrid";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "درباره iKIA Logistics",
  description:
    "iKIA Logistics پلتفرمی بنیان‌گذاری‌شده و مأموریت‌محور برای حمل‌ونقل هوشمند بار است؛ در مرحله پیش‌بذری و اعتبارسنجی مفهوم.",
  path: "/about",
});

const ADVANTAGES = [
  { icon: "matching", title: "حذف واسطه", desc: "ارتباط مستقیم بارفرست و حمل‌کننده، بدون زنجیره دلالی." },
  { icon: "repeat", title: "کاهش خالی‌برگشت", desc: "اتصال بار برگشت به ناوگان برای درآمد و بهره‌وری بیشتر." },
  { icon: "tracking", title: "شفافیت", desc: "پیگیری وضعیت بار و شفافیت در قیمت‌گذاری." },
  { icon: "reliability", title: "اتکاپذیری", desc: "زیرساختی که گام‌به‌گام و واقع‌بینانه ساخته می‌شود." },
];

export default function AboutPage() {
  return (
    <>
      <PageHero
        eyebrow="درباره ما"
        title="iKIA Logistics"
        subtitle="سیستم‌عامل دیجیتال لجستیک؛ بنیان‌گذاری‌شده، مأموریت‌محور و در مرحله پیش‌بذری."
      />

      <Section tone="light">
        <SectionHeading title="داستان ما" center={false} />
        <div className="space-y-4 text-sm leading-9 text-slate-600 sm:text-base">
          <p>
            صنعت حمل‌ونقل جاده‌ای ایران با چالش‌های بزرگی روبه‌روست:
            <strong className="text-[#1e3a5f]"> هزینه‌های بالای واسطه‌گری، خالی‌برگشت کامیون‌ها و نبود شفافیت</strong> در
            قیمت‌گذاری.
          </p>
          <p>
            <strong className="text-[#1e3a5f]">iKIA Logistics</strong> برای حل این مشکلات شکل گرفت؛ با این باور که فناوری
            می‌تواند حمل بار را <strong className="text-[#0e7490]">ساده‌تر، ارزان‌تر و شفاف‌تر</strong> کند.
          </p>
          <p>
            ما در مرحله پیش‌بذری و اعتبارسنجی مفهوم هستیم. به‌جای وعده‌های بزرگ، زیرساخت را گام‌به‌گام می‌سازیم و تنها از
            قابلیت‌هایی که واقعاً آماده‌اند صحبت می‌کنیم.
          </p>
        </div>
      </Section>

      <Section tone="surface">
        <SectionHeading title="مزایای ما" />
        <FeatureGrid items={ADVANTAGES} />
      </Section>

      <Section tone="brand" className="text-center">
        <h2 className="text-xl font-black sm:text-2xl">با ما همراه شوید</h2>
        <p className="mx-auto mt-3 max-w-xl text-sm leading-8 text-slate-200">
          اگر صاحب بار، فورواردر یا کریر هستید، خوشحال می‌شویم از شما بشنویم.
        </p>
        <div className="mt-6 flex justify-center">
          <Button href="/contact" variant="light" size="lg">
            تماس با ما
          </Button>
        </div>
      </Section>
    </>
  );
}
