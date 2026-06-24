import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { MarketingScreenshot } from "@/components/marketing/marketing-screenshot";
import { PremiumSectionHeader } from "@/components/marketing/premium-section-header";
import { WebsiteStatsStrip } from "@/components/marketing/website-stats-strip";

// CC-57RI — iKIA Logistics public website wired to the real marketing
// screenshots placed under /public/marketing/. Light-dominant body with
// one dark operational slab (Control Tower). All images go through
// next/image so the browser receives optimised WebP/AVIF at the right
// viewport size and lazy-loads everything below the fold automatically.
//
// Image mapping:
//   01-hero-multimodal-transport       → Hero (priority, above the fold)
//   02-stakeholder-solutions           → Solutions section
//   03-control-tower-live-map          → Control Tower section (primary)
//   04-transport-services              → Transport Services section
//   05-ikia-os-platform-modules        → Platform Overview section
//   06-coverage-corridors-iran-transit → Coverage section
//   07-integration-api-ecosystem       → Integration section
//   08-clean-hero-kpi-dashboard        → Control Tower section (secondary)
//   09-supply-chain-process-flow       → Process Flow section (primary)
//   10-end-to-end-supply-chain-workflow → Process Flow section (secondary)
//
// All 10 images are used. No external URLs. No package additions. Static
// page render preserved.

interface TextItem {
  title: string;
  description: string;
}

const HERO_VALUE_CARDS: {
  title: string;
  description: string;
  tone: "blue" | "green" | "amber" | "navy";
}[] = [
  {
    title: "پوشش سراسری",
    description: "شبکه فعال در کریدورهای داخلی، بین‌المللی و ترانزیتی.",
    tone: "blue",
  },
  {
    title: "شفافیت لحظه‌ای",
    description: "وضعیت محموله، نشست تله‌متری و رویدادهای سفر در یک نمای زنده.",
    tone: "green",
  },
  {
    title: "بهره‌وری عملیاتی",
    description: "از RFQ تا تسویه — چرخه‌ای منسجم با حافظه ممیزی کامل.",
    tone: "navy",
  },
  {
    title: "امنیت و انطباق",
    description: "کنترل دسترسی نقش‌محور، اسناد گمرکی و قرارداد اجراشده.",
    tone: "amber",
  },
];

const VALUE_TONES = {
  blue: { bg: "bg-brand-50", border: "border-brand-100", text: "text-brand-700" },
  green: { bg: "bg-emerald-50", border: "border-emerald-100", text: "text-emerald-700" },
  amber: { bg: "bg-amber-50", border: "border-amber-200", text: "text-amber-800" },
  navy: { bg: "bg-deep-navy/5", border: "border-deep-navy/10", text: "text-deep-navy" },
} as const;

const STAKEHOLDER_KEYPOINTS: TextItem[] = [
  {
    title: "صاحبان کالا",
    description: "ثبت سفارش، انعقاد قرارداد و پیگیری تحویل در یک نما.",
  },
  {
    title: "شرکت‌های حمل‌ونقل",
    description: "انتشار ظرفیت، پذیرش رزرو و مدیریت چرخه اعزام.",
  },
  {
    title: "رانندگان",
    description: "کنسول موبایل با کنترل کامل و بدون ردیابی پنهان.",
  },
  {
    title: "کنترل‌تاور و مدیران",
    description: "دید عملیاتی لحظه‌ای روی محموله‌ها، نشست‌ها و استثناها.",
  },
];

const TRANSPORT_CHIPS: string[] = [
  "حمل جاده‌ای",
  "حمل دریایی",
  "حمل ریلی",
  "حمل هوایی",
  "خدمات انبارداری",
  "ترخیص و انطباق گمرکی",
];

const COVERAGE_CHIPS: string[] = [
  "حمل داخلی",
  "حمل بین‌المللی",
  "ترانزیت از مسیر ایران",
  "کریدور شمال-جنوب",
  "کریدور شرق-غرب",
];

const INTEGRATION_CHIPS: { label: string; roadmap?: boolean }[] = [
  { label: "اتصال به ERP و WMS", roadmap: true },
  { label: "اتصال به سامانه گمرک", roadmap: true },
  { label: "REST API سازمانی", roadmap: true },
  { label: "احراز هویت سازمانی (SSO)", roadmap: true },
  { label: "Webhookها و رویدادهای عملیاتی", roadmap: true },
];

const PROCESS_HIGHLIGHTS: TextItem[] = [
  {
    title: "از سفارش تا تسویه",
    description: "گردش کاری منسجم برای ثبت تقاضا، انتخاب پیشنهاد و انعقاد قرارداد.",
  },
  {
    title: "اجرا و رؤیت زنده",
    description: "اعزام، ردیابی، اسناد گمرکی و رویدادهای سفر در یک خط زمانی.",
  },
  {
    title: "تسویه ساختارمند",
    description: "صدور فاکتور، حساب امانی، آزادسازی و گزارش‌های قابل ممیزی.",
  },
];

export default function HomePage() {
  return (
    <div className="bg-background">
      {/* =====================================================================
          1. Hero — image 01 (multimodal transport).
          ===================================================================== */}
      <section className="relative overflow-hidden bg-gradient-to-b from-brand-50/50 via-background to-background">
        <div
          aria-hidden
          className="absolute inset-y-0 left-0 w-1/2 opacity-30"
          style={{
            background:
              "radial-gradient(circle at 30% 50%, var(--color-brand-100) 0, transparent 60%)",
          }}
        />
        <div className="relative mx-auto max-w-6xl px-4 py-12 sm:py-20 lg:py-24">
          <div className="grid items-center gap-10 lg:grid-cols-[1.05fr_1.15fr]">
            <div className="space-y-6 text-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-brand-100 bg-brand-50 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-brand-700">
                <span className="inline-block size-1.5 rounded-full bg-brand-500" />
                سامانه عملیات لجستیک ایران
              </div>
              <h1 className="text-3xl font-bold leading-snug tracking-tight text-deep-navy sm:text-4xl lg:text-5xl">
                سیستم‌عامل لجستیک ایران
                <br />
                برای زنجیره‌های تأمین مدرن.
              </h1>
              <p className="max-w-xl text-base leading-8 text-deep-navy-soft sm:text-lg">
                ترکیب فناوری، تجربه عملیاتی و شبکه گسترده حمل‌ونقل جاده‌ای،
                دریایی، ریلی و هوایی برای کنترل، شفافیت و بهره‌وری زنجیره
                تأمین — در یک پلتفرم واحد.
              </p>
              <div className="flex flex-wrap gap-3">
                <Button asChild size="lg" className="w-full sm:w-auto">
                  <Link href="/login">ورود به پلتفرم</Link>
                </Button>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="w-full border-deep-navy/20 text-deep-navy hover:bg-deep-navy/5 sm:w-auto"
                >
                  <Link href="#solutions">مشاهده راهکارها</Link>
                </Button>
              </div>
              <ul className="flex flex-wrap gap-x-5 gap-y-2 pt-2 text-xs text-deep-navy-soft">
                <li className="flex items-center gap-1.5">
                  <span className="inline-block size-1.5 rounded-full bg-emerald-500" />
                  ردیابی صریح با کلیک
                </li>
                <li className="flex items-center gap-1.5">
                  <span className="inline-block size-1.5 rounded-full bg-brand-500" />
                  داده عملیاتی منسجم
                </li>
                <li className="flex items-center gap-1.5">
                  <span className="inline-block size-1.5 rounded-full bg-amber-500" />
                  معماری چندمستأجری
                </li>
              </ul>
            </div>
            <MarketingScreenshot
              src="/marketing/01-hero-multimodal-transport.png"
              alt="نمای چندوجهی حمل‌ونقل — جاده، دریا، ریل و هوا در پلتفرم iKIA"
              width={1672}
              height={941}
              priority
              sizes="(max-width: 1024px) 100vw, 720px"
              className="w-full"
            />
          </div>

          {/* Hero value cards. */}
          <ul className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {HERO_VALUE_CARDS.map((v) => {
              const t = VALUE_TONES[v.tone];
              return (
                <li
                  key={v.title}
                  className={`flex items-start gap-3 rounded-2xl border ${t.border} ${t.bg} p-4`}
                >
                  <span
                    aria-hidden
                    className={`mt-1 inline-block size-2 shrink-0 rounded-full ${t.text.replace("text-", "bg-")}`}
                  />
                  <div className="text-right">
                    <div className={`text-sm font-bold ${t.text}`}>{v.title}</div>
                    <p className="mt-1 text-xs leading-6 text-deep-navy-soft">
                      {v.description}
                    </p>
                  </div>
                </li>
              );
            })}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          2. Stakeholder Solutions — image 02 + brief keypoints.
          ===================================================================== */}
      <section id="solutions" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-6xl px-4">
          <PremiumSectionHeader
            eyebrow="راهکارها"
            title="راهکارهای جامع برای همه بازیگران زنجیره تأمین"
            intro="یک پلتفرم برای صاحبان کالا، شرکت‌های حمل‌ونقل، رانندگان و مدیران کنترل‌تاور — همه روی یک منبع داده مشترک."
          />
          <MarketingScreenshot
            src="/marketing/02-stakeholder-solutions.png"
            alt="راهکارهای iKIA برای صاحبان کالا، شرکت‌های حمل‌ونقل، رانندگان و مدیران کنترل‌تاور"
            width={1672}
            height={941}
            className="mt-10"
          />
          <ul className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {STAKEHOLDER_KEYPOINTS.map((k) => (
              <li
                key={k.title}
                className="rounded-2xl border border-border-soft bg-card p-4 text-right shadow-card"
              >
                <div className="text-sm font-bold text-deep-navy">{k.title}</div>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {k.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          3. Stats strip — navy break.
          ===================================================================== */}
      <WebsiteStatsStrip />

      {/* =====================================================================
          4. Control Tower — image 03 (primary) + image 08 (secondary).
          ===================================================================== */}
      <section
        id="control-tower"
        className="scroll-mt-16"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <PremiumSectionHeader
            eyebrow="کنترل‌تاور"
            title="دید عملیاتی لحظه‌ای روی محموله‌ها، مسیرها و عملکرد ناوگان"
            intro="نقشه زنده، شاخص‌های عملیاتی و کارت محموله در یک نمای واحد — برای واحد عملیات، تأمین و مالی."
            tone="dark"
          />
          <MarketingScreenshot
            src="/marketing/03-control-tower-live-map.png"
            alt="نقشه زنده کنترل‌تاور iKIA با مسیرهای فعال در ایران"
            width={1672}
            height={941}
            className="mt-10"
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1.1fr_1fr]">
            <MarketingScreenshot
              src="/marketing/08-clean-hero-kpi-dashboard.png"
              alt="داشبورد شاخص‌های عملیاتی iKIA"
              width={1536}
              height={1024}
              caption="شاخص‌های عملیاتی به‌صورت لحظه‌ای محاسبه و در یک داشبورد قابل ممیزی نمایش داده می‌شوند."
            />
            <div className="space-y-3 text-right text-night-text">
              <h3 className="text-xl font-bold tracking-tight">
                داشبورد شاخص‌ها در کنار نقشه عملیاتی
              </h3>
              <p className="text-sm leading-7 text-night-text-muted">
                شاخص‌های فعال شامل تعداد محموله، اعزام، نشست تله‌متری و
                استثناهای روزانه به‌صورت لحظه‌ای محاسبه می‌شوند. خروجی این
                داشبورد قابل صدور برای واحد مالی و کنترل داخلی است.
              </p>
              <ul className="mt-3 space-y-2 text-sm text-night-text-muted">
                <li className="flex items-start gap-2">
                  <span className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-emerald-400" />
                  چیپ سلامت تله‌متری برای هر سفر: به‌روز / قدیمی / بدون موقعیت.
                </li>
                <li className="flex items-start gap-2">
                  <span className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-sky-400" />
                  صف استثناها با اولویت‌بندی و گردش کار رفع.
                </li>
                <li className="flex items-start gap-2">
                  <span className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-amber-300" />
                  هشدارهای کنترل‌تاور برای تأخیر، بازرسی و رویدادهای مهم.
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          5. Transport Services — image 04.
          ===================================================================== */}
      <section id="transport" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-6xl px-4">
          <PremiumSectionHeader
            eyebrow="خدمات حمل‌ونقل"
            title="خدمات حمل‌ونقل و زنجیره تأمین"
            intro="iKIA Logistics از حمل جاده‌ای و دریایی تا ریلی، هوایی و انبارداری را در یک پلتفرم واحد گرد می‌آورد. خدمات کناری مانند ترخیص و بیمه هم در همین نما در دسترس شما هستند."
          />
          <MarketingScreenshot
            src="/marketing/04-transport-services.png"
            alt="نمای خدمات حمل‌ونقل iKIA — جاده، دریا، ریل، هوا و انبارداری"
            width={1672}
            height={941}
            className="mt-10"
          />
          <ul className="mt-8 flex flex-wrap justify-center gap-2">
            {TRANSPORT_CHIPS.map((t) => (
              <li
                key={t}
                className="rounded-full border border-brand-100 bg-brand-50 px-4 py-1.5 text-xs font-medium text-brand-700"
              >
                {t}
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          6. Platform Overview — image 05.
          ===================================================================== */}
      <section
        id="platform"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-6xl px-4">
          <PremiumSectionHeader
            eyebrow="پلتفرم"
            title="iKIA OS — شش بخش، یک تجربه عملیاتی منسجم"
            intro="هر بخش از iKIA Logistics به‌طور مستقل قدرتمند است و در کنار بقیه، یک سیستم‌عامل لجستیک کامل می‌سازد."
          />
          <MarketingScreenshot
            src="/marketing/05-ikia-os-platform-modules.png"
            alt="بخش‌های پلتفرم iKIA — بازار، اعزام، ردیابی، کنترل‌تاور، اسناد و تسویه"
            width={1535}
            height={1024}
            className="mt-10"
          />
        </div>
      </section>

      {/* =====================================================================
          7. Supply Chain Process / Workflow — images 09 + 10.
          ===================================================================== */}
      <section id="process" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-6xl px-4">
          <PremiumSectionHeader
            eyebrow="گردش کار زنجیره تأمین"
            title="از سفارش تا تحویل، یک گردش کار منسجم"
            intro="iKIA Logistics چرخه زنجیره تأمین را در یک سلسله‌مراتب عملیاتی شفاف می‌چیند — از ثبت تقاضا تا تسویه نهایی، با حافظه ممیزی کامل."
          />
          <div className="mt-10 grid gap-6 lg:grid-cols-2">
            <MarketingScreenshot
              src="/marketing/09-supply-chain-process-flow.png"
              alt="نمودار گردش کار زنجیره تأمین در iKIA Logistics"
              width={1536}
              height={1024}
              caption="چرخه عملیاتی iKIA — مراحل اصلی از سفارش تا تحویل."
            />
            <MarketingScreenshot
              src="/marketing/10-end-to-end-supply-chain-workflow.png"
              alt="نمای انتها به انتها از گردش کار زنجیره تأمین iKIA"
              width={1536}
              height={1024}
              caption="نمای انتها به انتها — اتصال خریدار، حمل‌کننده، راننده و کنترل‌تاور."
            />
          </div>
          <div className="mt-10 grid gap-4 sm:grid-cols-3">
            {PROCESS_HIGHLIGHTS.map((p) => (
              <div
                key={p.title}
                className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card"
              >
                <div className="text-sm font-bold text-deep-navy">{p.title}</div>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {p.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          8. Coverage / corridors — image 06.
          ===================================================================== */}
      <section
        id="coverage"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-6xl px-4">
          <PremiumSectionHeader
            eyebrow="پوشش و کریدورها"
            title="آماده برای کریدورهای داخلی، بین‌المللی و ترانزیتی"
            intro="iKIA Logistics برای جغرافیای واقعی زنجیره تأمین ایران ساخته شده است — از شبکه جاده‌ای داخلی تا مرزهای ترانزیتی شمال، شرق و شمال‌غرب و کریدور جنوب از طریق بنادر اصلی."
          />
          <MarketingScreenshot
            src="/marketing/06-coverage-corridors-iran-transit.png"
            alt="نقشه پوشش iKIA — کریدورهای داخلی، بین‌المللی و ترانزیتی از مسیر ایران"
            width={1536}
            height={1024}
            className="mt-10"
          />
          <ul className="mt-8 flex flex-wrap justify-center gap-2">
            {COVERAGE_CHIPS.map((c) => (
              <li
                key={c}
                className="rounded-full border border-emerald-100 bg-emerald-50 px-4 py-1.5 text-xs font-medium text-emerald-700"
              >
                {c}
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          9. Integration / API ecosystem — image 07.
          ===================================================================== */}
      <section
        id="integration"
        className="scroll-mt-16"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy-soft) 0%, var(--color-deep-navy) 100%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <PremiumSectionHeader
            eyebrow="اتصال سازمانی — نقشه راه"
            title="آمادگی برای اکوسیستم سازمانی شما"
            intro="iKIA Logistics از پایه برای اتصال با ERP، WMS، سامانه گمرک و ابزارهای داخلی شما طراحی شده است. اتصال‌های زیر در نقشه راه محصول قرار دارند و به‌تدریج عرضه می‌شوند."
            tone="dark"
          />
          <MarketingScreenshot
            src="/marketing/07-integration-api-ecosystem.png"
            alt="اکوسیستم اتصال سازمانی iKIA — ERP، WMS، گمرک و API"
            width={1536}
            height={1024}
            className="mt-10"
          />
          <ul className="mt-8 flex flex-wrap justify-center gap-2">
            {INTEGRATION_CHIPS.map((i) => (
              <li
                key={i.label}
                className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-4 py-1.5 text-xs font-medium text-night-text backdrop-blur-md"
              >
                <span>{i.label}</span>
                {i.roadmap ? (
                  <span className="rounded-full border border-amber-300/40 bg-amber-400/15 px-2 py-0.5 text-[10px] text-amber-200">
                    در نقشه راه
                  </span>
                ) : null}
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          10. Final CTA — light close, no demo language.
          ===================================================================== */}
      <section id="start" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-6xl px-4">
          <Card
            className="overflow-hidden border-border-soft"
            style={{
              background:
                "linear-gradient(135deg, var(--color-brand-50) 0%, oklch(0.985 0.005 250) 60%)",
              boxShadow: "var(--shadow-elevated)",
            }}
          >
            <CardContent className="p-8 sm:p-12">
              <div className="grid items-center gap-8 lg:grid-cols-[1.4fr_1fr]">
                <div className="space-y-3">
                  <div className="inline-flex items-center gap-2 rounded-full bg-brand-500/10 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-brand-700">
                    شروع همکاری
                  </div>
                  <h2 className="text-2xl font-bold tracking-tight text-deep-navy sm:text-3xl">
                    کنترل یکپارچه زنجیره تأمین خود را با iKIA Logistics آغاز کنید.
                  </h2>
                  <p className="text-sm leading-7 text-deep-navy-soft sm:text-base">
                    وارد پلتفرم شوید و بازار، اعزام، ردیابی، اسناد و تسویه را در
                    یک نمای منسجم تجربه کنید. iKIA برای واحدهای عملیات، تأمین
                    و مالی ساخته شده است.
                  </p>
                </div>
                <div className="flex flex-col gap-3 sm:flex-row lg:justify-end">
                  <Button asChild size="lg" className="w-full sm:w-auto">
                    <Link href="/login">ورود به پلتفرم</Link>
                  </Button>
                  <Button
                    asChild
                    variant="outline"
                    size="lg"
                    className="w-full border-deep-navy/20 text-deep-navy hover:bg-deep-navy/5 sm:w-auto"
                  >
                    <Link href="#solutions">مشاهده راهکارها</Link>
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>
    </div>
  );
}
