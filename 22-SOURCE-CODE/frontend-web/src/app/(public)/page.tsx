import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { MarketingImageFill } from "@/components/marketing/marketing-image-fill";
import { MarketingScreenshot } from "@/components/marketing/marketing-screenshot";
import { PremiumSectionHeader } from "@/components/marketing/premium-section-header";
import { StakeholderSolutionCard } from "@/components/marketing/stakeholder-solution-card";
import { SupplyChainProcessStepper } from "@/components/marketing/supply-chain-process-stepper";
import { TransportServiceCard } from "@/components/marketing/transport-service-card";
import { WebsiteStatsStrip } from "@/components/marketing/website-stats-strip";

// CC-58 — iKIA Logistics public website wired to all 19 marketing
// screenshots under /public/marketing/. Persian-first, RTL-first,
// mobile-first, static-renderable.
//
// Image assignment (all 19 used):
//   03 → Hero (above the fold, priority)
//   04 / 05 / 06 / 07 → Stakeholder Solutions (4 audience cards)
//   14 / 13 / 12 / 11 / 10 / 16 → Transport Services (6 mode cards)
//   02 → Platform Modules section visual
//   17 + 08 → Control Tower (primary + secondary)
//   15 + 09 → Iran Corridor Coverage (primary + secondary)
//   19 → Integration / API ecosystem
//   18 → Trust / Security / Compliance
//   01 → Final CTA cinematic banner
//
// The Supply Chain Process section uses an inline SVG/HTML stepper
// (SupplyChainProcessStepper) because none of the 19 images depicts a
// workflow diagram.

const HERO_TRUST_PILLS: { label: string; tone: "blue" | "green" | "amber" | "navy" }[] = [
  { label: "کنترل و شفافیت لحظه‌ای", tone: "blue" },
  { label: "پوشش چندوجهی حمل‌ونقل", tone: "green" },
  { label: "امنیت و انطباق", tone: "amber" },
  { label: "گزارش‌گیری و تصمیم‌سازی", tone: "navy" },
];

const PILL_TONES = {
  blue: "border-brand-100 bg-brand-50 text-brand-700",
  green: "border-emerald-100 bg-emerald-50 text-emerald-700",
  amber: "border-amber-200 bg-amber-50 text-amber-800",
  navy: "border-deep-navy/10 bg-deep-navy/5 text-deep-navy",
} as const;

const STAKEHOLDERS: {
  src: string;
  alt: string;
  badge: string;
  title: string;
  description: string;
  bullets: string[];
}[] = [
  {
    src: "/marketing/04-enterprise-control-room-analytics-clean.png",
    alt: "نمای تحلیل سازمانی برای صاحبان کالا",
    badge: "صاحبان کالا",
    title: "مدیریت یکپارچه سفارش تا تسویه",
    description:
      "از ثبت RFQ و انتخاب پیشنهاد تا انعقاد قرارداد و پیگیری تحویل — همگی روی یک منبع داده مشترک و قابل ممیزی.",
    bullets: [
      "ثبت درخواست، ارزیابی پیشنهاد و انعقاد قرارداد در یک گردش کار.",
      "پیگیری زنده وضعیت محموله و سلامت تله‌متری برای هر سفر.",
      "گزارش‌گیری ساختارمند برای واحد عملیات و واحد مالی.",
    ],
  },
  {
    src: "/marketing/05-ikia-road-fleet-trucks-clean.png",
    alt: "ناوگان حمل جاده‌ای شرکت‌های حمل‌ونقل همکار iKIA",
    badge: "شرکت‌های حمل‌ونقل",
    title: "انتشار ظرفیت، پذیرش رزرو و چرخه اعزام منسجم",
    description:
      "بازار ظرفیت همراه با چرخه عملیاتی اعزام — از پذیرش رزرو تا آزادسازی محموله و گزارش‌گیری از سفرها.",
    bullets: [
      "انتشار ظرفیت در بازار با اعتبار زمانی و کریدور هدف.",
      "ساخت اعزام با تخصیص خودرو و راننده در چند مرحله ساده.",
      "گزارش‌گیری از سفرها، تأخیرها و سلامت ناوگان.",
    ],
  },
  {
    src: "/marketing/06-driver-cabin-mobile-tracking-clean.png",
    alt: "اپ راننده iKIA با ردیابی موبایل از داخل کابین",
    badge: "رانندگان",
    title: "کنسول موبایل با کنترل کامل کاربر",
    description:
      "تجربه موبایل‌محور برای راننده — هیچ نشست تله‌متری بدون کلیک شروع نمی‌شود؛ هیچ موقعیت بدون تأیید ارسال نمی‌شود.",
    bullets: [
      "شروع و پایان نشست تله‌متری با کلیک صریح راننده.",
      "ارسال موقعیت با بازبینی پیش از ارسال، بدون ردیابی پس‌زمینه.",
      "خط زمانی سفر شامل نقاط عطف، توقف‌ها و رویدادها.",
    ],
  },
  {
    src: "/marketing/07-logistics-control-center-monitoring-clean.png",
    alt: "نمای کنترل‌تاور لجستیک iKIA برای مدیران عملیات",
    badge: "مدیران کنترل‌تاور",
    title: "نظارت یکپارچه و گزارش‌گیری اجرایی",
    description:
      "دید عملیاتی لحظه‌ای روی محموله‌های فعال، نشست‌های تله‌متری، استثناها و وضعیت تسویه — برای مدیریت و کنترل داخلی.",
    bullets: [
      "شاخص‌های زنده برای محموله، اعزام، نشست و استثنا.",
      "صف استثناها با اولویت‌بندی و گردش کار رفع.",
      "گزارش‌گیری اجرایی برای مدیریت و کنترل داخلی.",
    ],
  },
];

const TRANSPORT_SERVICES: {
  src: string;
  alt: string;
  title: string;
  description: string;
  tags: string[];
}[] = [
  {
    src: "/marketing/14-road-freight-service-card-clean.png",
    alt: "خدمات حمل جاده‌ای iKIA",
    title: "حمل جاده‌ای",
    description:
      "ستون اصلی حمل داخلی و کریدورهای ترانزیتی، با اعزام منسجم و ردیابی زنده در سطح مسیر.",
    tags: ["داخلی", "چندوجهی", "اعزام"],
  },
  {
    src: "/marketing/13-sea-freight-service-card-clean.png",
    alt: "خدمات حمل دریایی iKIA",
    title: "حمل دریایی",
    description:
      "هماهنگی محموله‌های کانتینری از بنادر اصلی جنوب کشور تا مقصد نهایی، با اسناد گمرکی منسجم.",
    tags: ["کانتینر", "بنادر", "صادرات/واردات"],
  },
  {
    src: "/marketing/12-rail-freight-service-card-clean.png",
    alt: "خدمات حمل ریلی iKIA",
    title: "حمل ریلی",
    description:
      "گزینه کارآمد برای حجم بالا در مسیرهای ریلی داخلی و کریدورهای ترانزیتی شرق-غرب.",
    tags: ["حجمی", "ترانزیت", "کریدور ریلی"],
  },
  {
    src: "/marketing/11-air-freight-service-card-clean.png",
    alt: "خدمات حمل هوایی iKIA",
    title: "حمل هوایی",
    description:
      "گزینه سریع برای محموله‌های ارزشمند یا حساس به زمان، با مدیریت کامل اسناد گمرکی.",
    tags: ["سریع", "ارزشمند", "اسناد گمرکی"],
  },
  {
    src: "/marketing/10-warehouse-service-card-clean.png",
    alt: "خدمات انبارداری iKIA",
    title: "خدمات انبارداری",
    description:
      "هماهنگی انبار، انبارهای ترانزیتی و عملیات تجمیع/توزیع محموله در شبکه iKIA.",
    tags: ["انبار", "تجمیع", "توزیع"],
  },
  {
    src: "/marketing/16-international-logistics-port-card.png",
    alt: "خدمات بین‌المللی، ترخیص و بیمه iKIA",
    title: "ترخیص، بیمه و خدمات پشتیبان",
    description:
      "خدمات کناری زنجیره تأمین — ترخیص گمرکی، بیمه‌نامه و گردش کار انطباق در یک نما.",
    tags: ["ترخیص", "بیمه", "انطباق"],
  },
];

const PLATFORM_MODULES: { title: string; description: string }[] = [
  {
    title: "بازار بار و ظرفیت",
    description:
      "تطبیق ساختارمند ظرفیت حمل‌کنندگان با تقاضای بار، در یک بازار شفاف و قابل پیگیری.",
  },
  {
    title: "مدیریت اعزام",
    description:
      "تخصیص خودرو و راننده، اعلام آمادگی، آزادسازی محموله و چرخه اعزام در یک نما.",
  },
  {
    title: "ردیابی زنده و کنترل‌تاور",
    description:
      "موقعیت، نقاط عطف، توقف‌ها و خط زمانی سفر — به همراه شاخص‌های زنده عملیات.",
  },
  {
    title: "مدیریت اسناد",
    description:
      "نگه‌داری اسناد گمرکی، بیمه، بارنامه و قرارداد اجراشده با حافظه ممیزی.",
  },
  {
    title: "تسویه و گزارش مالی",
    description:
      "صدور فاکتور، حساب امانی، آزادسازی مرحله‌ای و گزارش‌های قابل ممیزی.",
  },
  {
    title: "گزارش‌ها و تحلیل‌ها",
    description:
      "تحلیل عملکرد ناوگان، مسیرها، استثناها و چرخه مالی برای تصمیم‌سازی.",
  },
];

const CONTROL_TOWER_BULLETS: string[] = [
  "ردیابی لحظه‌ای محموله‌های فعال و وضعیت کریدور.",
  "هشدارهای عملیاتی برای تأخیر، استثنا و بازرسی.",
  "وضعیت مسیر، نقاط توقف و سلامت تله‌متری در هر سفر.",
  "ارزیابی عملکرد پیمانکاران و ناوگان همکار.",
  "داشبوردهای مدیریتی برای واحد عملیات، تأمین و مالی.",
];

const INTEGRATIONS: { label: string; roadmap?: boolean }[] = [
  { label: "ERP (سامانه‌های منابع سازمانی)", roadmap: true },
  { label: "WMS (سامانه مدیریت انبار)", roadmap: true },
  { label: "TMS (سامانه مدیریت حمل‌ونقل)", roadmap: true },
  { label: "CRM (مدیریت ارتباط با مشتری)", roadmap: true },
  { label: "سامانه گمرک ایران", roadmap: true },
  { label: "سامانه‌های گزارش‌گیری سازمانی", roadmap: true },
];

const TRUST_PILLARS: { title: string; description: string; tone: "blue" | "green" | "amber" }[] = [
  {
    title: "امنیت داده",
    description: "ذخیره‌سازی ساختارمند با کنترل دسترسی نقش‌محور و رمزنگاری در حین انتقال.",
    tone: "blue",
  },
  {
    title: "ممیزی عملیات",
    description: "حافظه ممیزی برای هر تغییر وضعیت، رویداد سفر و تراکنش مالی.",
    tone: "green",
  },
  {
    title: "مدیریت اسناد",
    description: "نگه‌داری ساختارمند اسناد گمرکی، بیمه و قرارداد اجراشده.",
    tone: "blue",
  },
  {
    title: "کاهش خطای انسانی",
    description: "گردش کار خودکار، تأییدهای چندمرحله‌ای و اعتبارسنجی داده.",
    tone: "amber",
  },
  {
    title: "کنترل دسترسی",
    description: "نقش‌های جداشده برای صاحب کالا، حمل‌کننده، راننده و ادمین.",
    tone: "green",
  },
  {
    title: "انطباق عملیاتی",
    description: "گردش کار درخواست/تأیید برای اسناد و قراردادهای حساس.",
    tone: "blue",
  },
];

const TRUST_TONE_MAP = {
  blue: "border-brand-100 bg-brand-50/60 text-brand-700",
  green: "border-emerald-100 bg-emerald-50/60 text-emerald-700",
  amber: "border-amber-200 bg-amber-50/60 text-amber-800",
} as const;

export default function HomePage() {
  return (
    <div className="bg-background">
      {/* =====================================================================
          1. HERO — image 03 (with iKIA logo).
          ===================================================================== */}
      <section className="relative overflow-hidden bg-gradient-to-b from-brand-50/60 via-background to-background">
        <div
          aria-hidden
          className="absolute inset-y-0 left-0 w-1/2 opacity-30"
          style={{
            background:
              "radial-gradient(circle at 30% 50%, var(--color-brand-100) 0, transparent 60%)",
          }}
        />
        <div className="relative mx-auto max-w-7xl px-4 py-12 sm:py-20 lg:py-24">
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
                اتصال صاحبان کالا، شرکت‌های حمل‌ونقل، رانندگان و مدیران عملیات
                روی یک منبع داده مشترک. ردیابی لحظه‌ای، مدیریت اسناد، اعزام،
                تسویه و گزارش‌گیری در یک پلتفرم واحد — آماده برای پوشش حمل
                جاده‌ای، دریایی، ریلی، هوایی و انبارداری در کریدورهای داخلی،
                بین‌المللی و ترانزیتی از مسیر ایران.
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
              <ul className="flex flex-wrap gap-2 pt-2">
                {HERO_TRUST_PILLS.map((p) => (
                  <li
                    key={p.label}
                    className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium ${PILL_TONES[p.tone]}`}
                  >
                    <span
                      aria-hidden
                      className="inline-block size-1.5 rounded-full bg-current"
                    />
                    {p.label}
                  </li>
                ))}
              </ul>
            </div>
            <MarketingScreenshot
              src="/marketing/03-hero-multimodal-with-ikia-logo-clean.png"
              alt="نمای چندوجهی حمل‌ونقل iKIA — جاده، دریا، ریل و هوا روی یک پلتفرم واحد"
              width={1536}
              height={1024}
              priority
              sizes="(max-width: 1024px) 100vw, 720px"
              className="w-full"
            />
          </div>
        </div>
      </section>

      {/* =====================================================================
          2. STAKEHOLDER SOLUTIONS — images 04, 05, 06, 07.
          ===================================================================== */}
      <section id="solutions" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="راهکارها"
            title="راهکارهای جامع برای همه بازیگران زنجیره تأمین"
            intro="iKIA Logistics برای صاحبان کالا، شرکت‌های حمل‌ونقل، رانندگان و مدیران کنترل‌تاور یک تجربه یکپارچه می‌سازد — همه روی یک منبع داده مشترک."
          />
          <div className="mt-10 grid gap-5 sm:grid-cols-2">
            {STAKEHOLDERS.map((s) => (
              <StakeholderSolutionCard
                key={s.title}
                visual={
                  <MarketingImageFill
                    src={s.src}
                    alt={s.alt}
                    sizes="(max-width: 640px) 100vw, 50vw"
                  />
                }
                badge={s.badge}
                title={s.title}
                description={s.description}
                bullets={s.bullets}
              />
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          3. STATS STRIP — navy break.
          ===================================================================== */}
      <WebsiteStatsStrip />

      {/* =====================================================================
          4. TRANSPORT SERVICES — images 10, 11, 12, 13, 14, 16.
          ===================================================================== */}
      <section id="services" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="خدمات حمل‌ونقل"
            title="خدمات یکپارچه حمل‌ونقل و زنجیره تأمین"
            intro="از حمل جاده‌ای و دریایی تا ریلی، هوایی و انبارداری — همراه با خدمات کناری ترخیص، بیمه و انطباق گمرکی. همه روی یک پلتفرم واحد."
          />
          <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {TRANSPORT_SERVICES.map((s) => (
              <TransportServiceCard
                key={s.title}
                visual={
                  <MarketingImageFill
                    src={s.src}
                    alt={s.alt}
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                  />
                }
                title={s.title}
                description={s.description}
                tags={s.tags}
              />
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          5. PLATFORM OVERVIEW — image 02 + 6 module cards.
          ===================================================================== */}
      <section
        id="platform"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="پلتفرم iKIA OS"
            title="شش بخش، یک تجربه عملیاتی منسجم"
            intro="هر بخش از iKIA Logistics به‌طور مستقل قدرتمند است و در کنار بقیه، یک سیستم‌عامل لجستیک کامل می‌سازد."
          />
          <MarketingScreenshot
            src="/marketing/02-global-control-tower-dashboard-clean.png"
            alt="نمای داشبورد سراسری iKIA OS — کنترل‌تاور و بخش‌های پلتفرم"
            width={1535}
            height={1024}
            className="mt-10"
          />
          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {PLATFORM_MODULES.map((m, idx) => (
              <Card
                key={m.title}
                className="border-border-soft shadow-card transition-shadow hover:shadow-elevated"
              >
                <CardContent className="p-5 space-y-2 text-right">
                  <div className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
                    {String(idx + 1).padStart(2, "0")}
                  </div>
                  <div className="text-base font-bold tracking-tight text-deep-navy">
                    {m.title}
                  </div>
                  <p className="text-sm leading-7 text-muted-foreground">
                    {m.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          6. CONTROL TOWER / LIVE VISIBILITY — images 17 + 08 (dark slab).
          ===================================================================== */}
      <section
        id="control-tower"
        className="scroll-mt-16"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
        }}
      >
        <div className="mx-auto max-w-7xl px-4 py-20 sm:py-28">
          <PremiumSectionHeader
            eyebrow="کنترل‌تاور"
            title="کنترل‌تاور عملیاتی برای پایش محموله‌ها، مسیرها و عملکرد ناوگان"
            intro="کنترل‌تاور iKIA وضعیت زنده محموله‌ها، نشست‌های تله‌متری، تأخیرها و استثناهای روزانه را در یک نمای واحد گرد می‌آورد. شاخص‌ها لحظه‌ای محاسبه می‌شوند؛ هیچ داده عملیاتی پنهان نمی‌ماند."
            tone="dark"
          />
          <MarketingScreenshot
            src="/marketing/17-smart-logistics-control-center.png"
            alt="کنترل‌تاور هوشمند لجستیک iKIA با نمای کامل عملیات"
            width={1536}
            height={1024}
            className="mt-10"
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1.05fr_1fr]">
            <MarketingScreenshot
              src="/marketing/08-operations-control-room-dashboard-clean.png"
              alt="اتاق کنترل عملیات iKIA — داشبورد شاخص‌ها"
              width={1672}
              height={941}
              caption="نمای داشبورد عملیات با شاخص‌های زنده و وضعیت ناوگان."
            />
            <div className="space-y-3 text-right text-night-text">
              <h3 className="text-xl font-bold tracking-tight">
                دید عملیاتی لحظه‌ای، در کنار شاخص‌های اجرایی
              </h3>
              <p className="text-sm leading-7 text-night-text-muted">
                ترکیب نقشه عملیاتی با داشبورد شاخص‌ها، تصویری کامل از وضعیت
                ناوگان، محموله‌های در راه و استثناهای روزانه ارائه می‌دهد.
              </p>
              <ul className="mt-3 space-y-2 text-sm text-night-text-muted">
                {CONTROL_TOWER_BULLETS.map((b) => (
                  <li key={b} className="flex items-start gap-2">
                    <span
                      aria-hidden
                      className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-emerald-400"
                    />
                    <span>{b}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          7. IRAN CORRIDOR COVERAGE — images 15 + 09.
          ===================================================================== */}
      <section id="corridors" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="پوشش جغرافیایی"
            title="پوشش کریدورهای داخلی، بین‌المللی و ترانزیتی از مسیر ایران"
            intro="iKIA Logistics برای جغرافیای واقعی زنجیره تأمین ایران ساخته شده است — از شبکه جاده‌ای داخلی و مرزهای ترانزیتی شمال، شرق و شمال‌غرب تا کریدور جنوب از طریق بنادر اصلی."
          />
          <MarketingScreenshot
            src="/marketing/15-east-west-north-south-iran-corridors.png"
            alt="کریدورهای شرق-غرب و شمال-جنوب از مسیر ایران"
            width={1535}
            height={1024}
            className="mt-10"
          />
          <div className="mt-10 grid gap-6 lg:grid-cols-[1.05fr_1fr]">
            <div className="space-y-3 text-right">
              <div className="grid gap-4 sm:grid-cols-2">
                <article className="rounded-2xl border border-brand-100 bg-brand-50/50 p-5 shadow-card">
                  <div className="inline-flex items-center gap-2 rounded-full bg-brand-500/15 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
                    کریدور شرق به غرب
                  </div>
                  <h3 className="mt-2 text-base font-bold text-deep-navy">
                    از چین و آسیای مرکزی به اروپا از مسیر ایران
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-deep-navy-soft">
                    اتصال کریدور شرقی به مرزهای غربی و شمال‌غربی برای ترانزیت
                    صادرات و واردات با اسناد گمرکی منسجم.
                  </p>
                </article>
                <article className="rounded-2xl border border-emerald-100 bg-emerald-50/50 p-5 shadow-card">
                  <div className="inline-flex items-center gap-2 rounded-full bg-emerald-500/15 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-emerald-700">
                    کریدور شمال به جنوب
                  </div>
                  <h3 className="mt-2 text-base font-bold text-deep-navy">
                    از روسیه و قفقاز به خلیج فارس و اقیانوس هند
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-deep-navy-soft">
                    مسیر استراتژیک از مرزهای شمالی تا بنادر اصلی جنوب کشور با
                    قابلیت چندوجهی جاده‌ای و ریلی.
                  </p>
                </article>
              </div>
              <ul className="mt-2 flex flex-wrap gap-2">
                {["داخلی", "بین‌المللی", "ترانزیتی", "چندوجهی"].map((t) => (
                  <li
                    key={t}
                    className="rounded-full border border-deep-navy/10 bg-deep-navy/5 px-3 py-1 text-[11px] font-medium text-deep-navy"
                  >
                    {t}
                  </li>
                ))}
              </ul>
            </div>
            <MarketingScreenshot
              src="/marketing/09-iran-live-route-map-clean.png"
              alt="نقشه زنده مسیرها در ایران — وضعیت محموله‌های در راه"
              width={1536}
              height={1024}
              caption="نقشه زنده وضعیت محموله‌ها در سطح کشور و کریدورهای ترانزیتی."
            />
          </div>
        </div>
      </section>

      {/* =====================================================================
          8. SUPPLY CHAIN PROCESS — inline stepper (no workflow image
          available in the 19-image inventory).
          ===================================================================== */}
      <section
        id="process"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="گردش کار زنجیره تأمین"
            title="از ثبت درخواست تا تحویل و تسویه، در یک گردش کار منسجم"
            intro="iKIA Logistics چرخه زنجیره تأمین را در یک سلسله‌مراتب عملیاتی شفاف می‌چیند — با حافظه ممیزی کامل در هر مرحله."
          />
          <SupplyChainProcessStepper className="mt-10" />
        </div>
      </section>

      {/* =====================================================================
          9. INTEGRATION / API ECOSYSTEM — image 19.
          ===================================================================== */}
      <section id="integration" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="اتصال سازمانی"
            title="آمادگی برای اکوسیستم سازمانی شما"
            intro="iKIA Logistics از پایه برای اتصال با ERP، WMS، TMS، CRM، سامانه گمرک و ابزارهای داخلی سازمان شما طراحی شده است. موارد زیر در نقشه راه محصول قرار دارند و به‌تدریج عرضه می‌شوند."
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1.15fr_1fr]">
            <MarketingScreenshot
              src="/marketing/19-smart-integration-ikia-os-card.png"
              alt="اکوسیستم اتصال سازمانی iKIA OS — ERP، WMS، گمرک و API"
              width={1536}
              height={1024}
            />
            <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
              {INTEGRATIONS.map((i) => (
                <li
                  key={i.label}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-2xl border border-border-soft bg-card p-3 text-right shadow-card"
                >
                  <span className="text-sm font-medium text-deep-navy">
                    {i.label}
                  </span>
                  {i.roadmap ? (
                    <span className="rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-[10px] font-medium text-amber-800">
                      در نقشه راه
                    </span>
                  ) : null}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          10. TRUST / SECURITY / COMPLIANCE — image 18.
          ===================================================================== */}
      <section
        id="trust"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="امنیت و انطباق"
            title="طراحی برای اعتماد، دقت و انطباق عملیاتی"
            intro="iKIA Logistics با کنترل دسترسی نقش‌محور، حافظه ممیزی کامل و مدیریت اسناد ساختارمند، ریسک عملیاتی شما را کاهش می‌دهد."
          />
          <div className="mt-10 grid gap-6 lg:grid-cols-[1fr_1.05fr]">
            <MarketingScreenshot
              src="/marketing/18-security-accuracy-commitment-logistics.png"
              alt="امنیت، دقت و تعهد عملیاتی در iKIA Logistics"
              width={1536}
              height={1024}
            />
            <ul className="grid gap-3 sm:grid-cols-2">
              {TRUST_PILLARS.map((p) => (
                <li
                  key={p.title}
                  className={`rounded-2xl border p-4 text-right ${TRUST_TONE_MAP[p.tone]}`}
                >
                  <div className="text-sm font-bold text-deep-navy">
                    {p.title}
                  </div>
                  <p className="mt-1 text-xs leading-6 text-deep-navy-soft">
                    {p.description}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          11. FINAL CTA — image 01 as cinematic banner.
          ===================================================================== */}
      <section id="start" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <div
            className="relative overflow-hidden rounded-3xl border border-border-soft"
            style={{ boxShadow: "var(--shadow-elevated)" }}
          >
            {/* Cinematic banner image. */}
            <div className="relative aspect-[16/7] w-full">
              <MarketingImageFill
                src="/marketing/01-hero-multimodal-transport-clean.png"
                alt="نمای چندوجهی پایانی iKIA — جاده، دریا، ریل و هوا"
                sizes="(max-width: 1024px) 100vw, 1200px"
              />
              {/* Dark gradient for text contrast. */}
              <div
                aria-hidden
                className="absolute inset-0"
                style={{
                  background:
                    "linear-gradient(90deg, oklch(0.18 0.04 250 / 0.85) 0%, oklch(0.18 0.04 250 / 0.55) 60%, transparent 100%)",
                }}
              />
              <div className="absolute inset-0 flex items-center">
                <div className="mx-auto w-full max-w-7xl px-6 sm:px-10">
                  <div className="max-w-2xl space-y-3 text-right text-night-text">
                    <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-night-text backdrop-blur-md">
                      شروع همکاری
                    </div>
                    <h2 className="text-2xl font-bold leading-snug tracking-tight sm:text-3xl lg:text-4xl">
                      برای ساخت زنجیره تأمین شفاف، قابل کنترل و آماده رشد،
                      iKIA Logistics را وارد عملیات روزانه خود کنید.
                    </h2>
                    <div className="flex flex-wrap gap-2 pt-2">
                      <Button asChild size="lg" className="w-full sm:w-auto">
                        <Link href="/login">ورود به پلتفرم</Link>
                      </Button>
                      <Button
                        asChild
                        variant="outline"
                        size="lg"
                        className="w-full border-white/30 bg-transparent text-night-text hover:bg-white/10 hover:text-night-text sm:w-auto"
                      >
                        <Link href="#solutions">مشاهده راهکارها</Link>
                      </Button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
