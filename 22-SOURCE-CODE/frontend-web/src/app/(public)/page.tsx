import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CorridorVisual } from "@/components/marketing/corridor-visual";
import { DashboardOverlay } from "@/components/marketing/dashboard-overlay";
import { DriverConsoleMockup } from "@/components/marketing/driver-console-mockup";
import { MarketingImageFrame } from "@/components/marketing/marketing-image-frame";

// CC-57 — iKIA Logistics public landing, complete enterprise OS direction.
//
// Inspiration is abstract only (Forto/Flexport quality benchmark for a B2B
// logistics platform). Zero copied assets, copy, layout, or brand
// expression. Persian-first, RTL-first, static-renderable.
//
// Section flow (11):
//   1. Hero — operating-system positioning + dual CTA (ورود + مشاهده راهکارها)
//   2. Trust strip — five value lines, light card lifted over the dark hero
//   3. Platform overview — six iKIA OS modules
//   4. Solutions — four-role grid (buyer / carrier / driver / control tower)
//   5. Driver deep-dive — phone mockup + explicit-click contract
//   6. Transport modes — domestic / international / transit via Iran
//   7. Visibility & control tower — dashboard overlay + Persian copy
//   8. Documents & compliance — customs, BOL, contracts
//   9. Finance & settlement — escrow, multi-currency, structured reports
//  10. Integration & API — roadmap-marked enterprise connectivity
//  11. Final CTA — «شروع همکاری» close, no demo language
//
// All imagery is image-ready via MarketingImageFrame (see
// public/marketing/README.md) and ships with cinematic CSS/SVG fallbacks.

interface TextItem {
  title: string;
  description: string;
}

const TRUST_ITEMS: TextItem[] = [
  {
    title: "شفافیت حمل",
    description: "وضعیت لحظه‌ای محموله از کارخانه تا مقصد، بدون نقطه کور.",
  },
  {
    title: "کاهش اتلاف زمان",
    description: "از RFQ تا تسویه، در یک سامانه یکپارچه و قابل پیگیری.",
  },
  {
    title: "کنترل‌تاور یکپارچه",
    description: "نمای ادمین برای استثناها، تأخیرها و وضعیت تسویه‌ها.",
  },
  {
    title: "ردیابی راننده",
    description: "اپ راننده با کنترل کامل کاربر و بدون ردیابی پنهان.",
  },
  {
    title: "اسناد و قراردادها",
    description: "اسناد گمرکی، بارنامه و قراردادها در یک محل امن.",
  },
];

const PLATFORM_MODULES: TextItem[] = [
  {
    title: "بازار بار و ظرفیت",
    description:
      "تطبیق هوشمند ظرفیت حمل‌کنندگان با تقاضای بار. کشف ظرفیت‌های فعال، رزرو و تأیید با شفافیت کامل.",
  },
  {
    title: "مدیریت اعزام",
    description:
      "تخصیص خودرو و راننده، اعلام آمادگی، آزادسازی محموله و چرخه عملیات اعزام در یک نما.",
  },
  {
    title: "ردیابی زنده",
    description:
      "موقعیت لحظه‌ای، نقاط عطف، توقف‌ها و خط زمانی سفر — همراه با وضعیت سلامت تله‌متری برای هر سفر.",
  },
  {
    title: "مدیریت اسناد",
    description:
      "نگه‌داری اسناد گمرکی، بیمه، بارنامه و قراردادها با گردش کار درخواست/تأیید و حافظه ممیزی.",
  },
  {
    title: "تسویه و گزارش مالی",
    description:
      "صدور فاکتور، تسویه ساختارمند، حساب امانی و گزارش‌های مالی برای واحد عملیات و مالی.",
  },
  {
    title: "کنترل‌تاور ادمین",
    description:
      "نظارت لحظه‌ای روی محموله‌های فعال، استثناهای عملیاتی و سلامت اتصال راننده‌ها.",
  },
];

const PORTAL_ROLES: TextItem[] = [
  {
    title: "پورتال خریدار",
    description:
      "ثبت RFQ، انتخاب پیشنهاد، انعقاد قرارداد، پیگیری محموله و تسویه. نمای کامل عرضه و تأمین.",
  },
  {
    title: "پورتال حمل‌کننده",
    description:
      "انتشار ظرفیت در بازار، پذیرش رزرو، ایجاد اعزام و گزارش‌گیری از وضعیت سفرها.",
  },
  {
    title: "کنسول راننده",
    description:
      "تجربه موبایل-اول برای راننده: شروع/پایان نشست، ارسال موقعیت با کلیک، خط زمانی سفر.",
  },
  {
    title: "کنترل‌تاور ادمین",
    description:
      "نظارت پلتفرم: محموله‌های فعال، استثناها، تسویه‌های در منازعه و سلامت تله‌متری.",
  },
];

const DRIVER_BULLETS: string[] = [
  "شروع نشست تله‌متری با یک کلیک صریح.",
  "ارسال موقعیت پس از بازبینی توسط راننده — هیچ ارسال خودکار.",
  "خط زمانی سفر شامل نقاط عطف، توقف‌ها و رویدادهای تله‌متری.",
  "تجربه تلاش‌دوباره ایمن در صورت قطع اتصال، بدون از دست رفتن داده.",
];

const TRANSPORT_MODES: TextItem[] = [
  {
    title: "حمل داخلی",
    description:
      "از مراکز صنعتی تا مقصد در سراسر کشور؛ پیگیری جاده‌ای و چندوجهی با اسناد منسجم.",
  },
  {
    title: "حمل بین‌المللی",
    description:
      "واردات و صادرات از مرزهای اصلی شمال‌غرب، شمال و شرق با اسناد گمرکی منسجم.",
  },
  {
    title: "ترانزیت از مسیر ایران",
    description:
      "اتصال کریدورهای شمال-جنوب و شرق-غرب با شفافیت ترانزیتی و نقاط مرزی کلیدی.",
  },
];

const DOC_ITEMS: TextItem[] = [
  {
    title: "اسناد گمرکی",
    description:
      "اظهارنامه واردات، صادرات و ترانزیت با گردش کار درخواست/تأیید و حافظه ممیزی.",
  },
  {
    title: "بارنامه و گواهی مبدأ",
    description:
      "بارنامه‌های حمل و اسناد گواهی مبدأ، در دسترس هر سه نقش عملیاتی پروژه.",
  },
  {
    title: "بیمه و انطباق",
    description:
      "بیمه‌نامه‌های حمل، گواهی انطباق و اسناد بازرسی، با تاریخ‌های انقضای روشن.",
  },
  {
    title: "قرارداد اجراشده",
    description:
      "نگه‌داری قرارداد اجرایی و امضای دیجیتال طرفین در یک منبع واحد قابل پیگیری.",
  },
];

const FINANCE_ITEMS: TextItem[] = [
  {
    title: "فاکتور و یادداشت اعتباری",
    description:
      "صدور فاکتور خریدار و حمل‌کننده، یادداشت‌های اعتباری و یادداشت‌های اصلاحی.",
  },
  {
    title: "حساب امانی و آزادسازی",
    description:
      "نگه‌داری وجه در حساب امانی، آزادسازی مرحله‌ای بر اساس گردش کار توافق‌شده.",
  },
  {
    title: "چندارزی و تبدیل",
    description:
      "پشتیبانی از چندارزی همراه با نرخ‌های تبدیل ثبت‌شده در زمان تسویه.",
  },
  {
    title: "گزارش ساختارمند",
    description:
      "گزارش‌های مالی برای واحد عملیات، مالی و کنترل داخلی — قابل صدور و ممیزی.",
  },
];

const INTEGRATION_ITEMS: TextItem[] = [
  {
    title: "اتصال به ERP / WMS",
    description:
      "نقشه راه: اتصال‌های آینده به سامانه‌های منابع سازمانی و انبارداری.",
  },
  {
    title: "اتصال به سامانه گمرک",
    description:
      "نقشه راه: یکپارچه‌سازی با سامانه‌های گمرک برای جریان مستقیم اسناد.",
  },
  {
    title: "REST API سازمانی",
    description:
      "نقشه راه: ابزار توسعه‌دهنده مستقل برای ادغام شرکای فناوری.",
  },
  {
    title: "احراز هویت سازمانی",
    description:
      "نقشه راه: پشتیبانی از احراز هویت سازمانی (SSO) برای سازمان‌های بزرگ.",
  },
];

export default function HomePage() {
  return (
    <div>
      {/* =====================================================================
          1. Hero — cinematic deep-navy slab with operational overlay.
          ===================================================================== */}
      <section
        className="relative overflow-hidden"
        style={{
          background:
            "radial-gradient(at 80% 20%, var(--color-night-mist) 0%, transparent 55%), linear-gradient(180deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-16 sm:py-24 lg:py-28">
          <div className="grid items-center gap-10 lg:grid-cols-[1.05fr_0.95fr]">
            <div className="space-y-6 text-night-text">
              <Badge
                variant="info"
                className="bg-white/10 text-night-text border-white/15"
              >
                سامانه عملیات لجستیک ایران
              </Badge>
              <h1 className="text-3xl font-semibold leading-snug tracking-tight sm:text-4xl lg:text-5xl">
                سامانه عملیات یکپارچه برای
                <br />
                زنجیره تأمین مدرن ایران.
              </h1>
              <p className="max-w-xl text-base leading-8 text-night-text-muted sm:text-lg">
                iKIA Logistics بازار بار و ظرفیت، مدیریت اعزام، ردیابی زنده،
                اسناد گمرکی و تسویه ساختارمند را در یک پلتفرم واحد گرد می‌آورد.
                مناسب شرکت‌های متوسط و بزرگ — حمل داخلی، بین‌المللی و ترانزیتی.
              </p>
              <div className="flex flex-wrap gap-3">
                <Button asChild size="lg" className="w-full sm:w-auto">
                  <Link href="/login">ورود به پلتفرم</Link>
                </Button>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="w-full border-white/30 bg-transparent text-night-text hover:bg-white/10 hover:text-night-text sm:w-auto"
                >
                  <Link href="#platform">مشاهده راهکارها</Link>
                </Button>
              </div>
              <ul className="flex flex-wrap gap-x-6 gap-y-2 pt-3 text-xs text-night-text-muted">
                <li>• ردیابی صریح با کلیک — بدون ردیابی پس‌زمینه.</li>
                <li>• داده عملیاتی منسجم برای ادمین و مالی.</li>
                <li>• معماری چندمستأجری با کنترل دسترسی نقش‌محور.</li>
              </ul>
            </div>

            <MarketingImageFrame
              src={null /* TODO: drop /marketing/hero-control-tower.webp */}
              alt="نمای کنترل‌تاور عملیات لجستیک"
              className="aspect-[4/3] w-full rounded-3xl border border-white/10"
              fallback={<DashboardOverlay className="h-full w-full" />}
            />
          </div>
        </div>
      </section>

      {/* =====================================================================
          2. Trust strip — light card lifted onto the dark hero fade.
          ===================================================================== */}
      <section className="mx-auto -mt-10 max-w-6xl px-4 relative z-10">
        <div className="rounded-2xl border border-border-soft bg-card p-5 shadow-elevated sm:p-6">
          <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            {TRUST_ITEMS.map((item) => (
              <li key={item.title} className="space-y-1">
                <div className="text-sm font-semibold">{item.title}</div>
                <p className="text-xs leading-6 text-muted-foreground">
                  {item.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          3. Platform overview — light slab, six modules.
          ===================================================================== */}
      <section
        id="platform"
        className="mx-auto max-w-6xl px-4 py-20 sm:py-28 scroll-mt-16"
      >
        <div className="max-w-2xl space-y-3">
          <Badge variant="outline">پلتفرم</Badge>
          <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
            شش بخش، یک تجربه عملیاتی منسجم.
          </h2>
          <p className="text-sm leading-7 text-muted-foreground">
            هر بخش از iKIA Logistics به‌طور مستقل قدرتمند است و در کنار بقیه،
            تصویری کامل از زنجیره تأمین شما می‌سازد.
          </p>
        </div>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {PLATFORM_MODULES.map((m) => (
            <Card
              key={m.title}
              className="border-border-soft shadow-card transition-shadow hover:shadow-elevated"
            >
              <CardContent className="p-5 space-y-2">
                <div className="text-base font-semibold tracking-tight">
                  {m.title}
                </div>
                <p className="text-sm leading-7 text-muted-foreground">
                  {m.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {/* =====================================================================
          4. Solutions — four-role grid on a soft surface.
          ===================================================================== */}
      <section
        id="solutions"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-6xl px-4">
          <div className="max-w-2xl space-y-3">
            <Badge variant="outline">راهکارها</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              یک پلتفرم، چهار نقش، یک حقیقت مشترک.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              iKIA Logistics نقش‌ها را در یک منبع داده مشترک متحد می‌کند تا
              عملیات، تأمین، حمل و نظارت بدون اصطکاک پیش بروند.
            </p>
          </div>
          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            {PORTAL_ROLES.map((role) => (
              <Card key={role.title} className="border-border-soft shadow-card">
                <CardContent className="p-5 space-y-2">
                  <div className="text-base font-semibold tracking-tight">
                    {role.title}
                  </div>
                  <p className="text-sm leading-7 text-muted-foreground">
                    {role.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          5. Driver deep-dive — phone mockup, light slab.
          ===================================================================== */}
      <section
        id="driver"
        className="mx-auto max-w-6xl px-4 py-20 sm:py-28 scroll-mt-16"
      >
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <DriverConsoleMockup className="order-2 lg:order-1" />
          <div className="order-1 space-y-4 lg:order-2">
            <Badge variant="info">اپ راننده</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              راننده در کنترل، نه در نظارت پنهان.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              کنسول راننده iKIA یک تجربه موبایل-اول است که شفافیت کامل به
              راننده می‌دهد. هیچ نشست تله‌متری بدون کلیک شروع نمی‌شود؛ هیچ
              موقعیت بدون تأیید ارسال نمی‌شود.
            </p>
            <ul className="space-y-2 text-sm leading-7">
              {DRIVER_BULLETS.map((b) => (
                <li key={b}>• {b}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          6. Transport modes — dark slab, corridor visual in a glass card.
          ===================================================================== */}
      <section
        id="transport"
        className="scroll-mt-16"
        style={{
          background:
            "radial-gradient(at 20% 100%, var(--color-night-mist) 0%, transparent 55%), linear-gradient(180deg, var(--color-deep-navy-soft) 0%, var(--color-deep-navy) 100%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div className="space-y-4 text-night-text">
              <Badge variant="info" className="bg-white/10 text-night-text border-white/15">
                حمل و ترانزیت
              </Badge>
              <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                از حمل داخلی تا ترانزیت بین‌المللی.
              </h2>
              <p className="text-sm leading-7 text-night-text-muted">
                iKIA Logistics برای جغرافیای واقعی زنجیره تأمین ایران ساخته شده
                است: شبکه جاده‌ای کشور، مرزهای ترانزیتی شمال، شرق و شمال‌غرب،
                و کریدور جنوب از طریق بنادر اصلی.
              </p>
              <div className="grid gap-3 sm:grid-cols-3">
                {TRANSPORT_MODES.map((c) => (
                  <div
                    key={c.title}
                    className="rounded-xl border border-white/10 bg-white/5 p-3 backdrop-blur-md"
                  >
                    <div className="text-sm font-semibold text-night-text">
                      {c.title}
                    </div>
                    <p className="mt-1 text-xs leading-6 text-night-text-muted">
                      {c.description}
                    </p>
                  </div>
                ))}
              </div>
            </div>
            <div
              className="rounded-3xl border border-white/10 bg-card p-3"
              style={{ boxShadow: "var(--shadow-cinematic)" }}
            >
              <CorridorVisual className="block h-auto w-full" />
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          7. Visibility & control tower — light slab; dashboard pops on light.
          ===================================================================== */}
      <section
        id="visibility"
        className="bg-surface-muted py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-6xl px-4">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div className="space-y-4">
              <Badge variant="info">ردیابی و کنترل‌تاور</Badge>
              <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                همه چیز در یک نگاه.
              </h2>
              <p className="text-sm leading-7 text-muted-foreground">
                کنترل‌تاور iKIA وضعیت محموله‌های فعال، نشست‌های تله‌متری راننده،
                تأخیرها و استثناهای روزانه را در یک صفحه گردآوری می‌کند.
                شاخص‌ها لحظه‌ای محاسبه می‌شوند؛ هیچ داده عملیاتی پنهان نمی‌ماند.
              </p>
              <ul className="space-y-2 text-sm leading-7">
                <li>• شاخص‌های فعال: محموله، اعزام، نشست تله‌متری، استثنا.</li>
                <li>• چیپ سلامت تله‌متری برای هر سفر: به‌روز / قدیمی / بدون موقعیت.</li>
                <li>• فهرست محموله‌های اخیر همراه با وضعیت عملیاتی و کریدور.</li>
              </ul>
            </div>
            <MarketingImageFrame
              src={null /* TODO: drop /marketing/port-container-operations.webp */}
              alt="عملیات بنادر و کانتینرها"
              className="aspect-[4/3] w-full rounded-3xl border border-border-soft"
              fallback={<DashboardOverlay className="h-full w-full" />}
            />
          </div>
        </div>
      </section>

      {/* =====================================================================
          8. Documents & compliance — dark slab, four document categories.
          ===================================================================== */}
      <section
        id="documents"
        className="scroll-mt-16"
        style={{
          background:
            "linear-gradient(180deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 100%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <div className="grid items-start gap-10 lg:grid-cols-[1fr_1.2fr]">
            <div className="space-y-4 text-night-text">
              <Badge variant="info" className="bg-white/10 text-night-text border-white/15">
                اسناد و انطباق
              </Badge>
              <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                اسناد عملیاتی، در یک منبع واحد قابل ممیزی.
              </h2>
              <p className="text-sm leading-7 text-night-text-muted">
                iKIA Logistics اسناد گمرکی، بارنامه، بیمه و قرارداد اجراشده را
                با گردش کار درخواست/تأیید و حافظه ممیزی نگه‌داری می‌کند تا
                واحدهای عملیات، انطباق و مالی به یک حقیقت مشترک دسترسی داشته باشند.
              </p>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {DOC_ITEMS.map((d) => (
                <div
                  key={d.title}
                  className="rounded-xl border border-white/10 bg-white/5 p-4 backdrop-blur-md"
                >
                  <div className="text-sm font-semibold text-night-text">
                    {d.title}
                  </div>
                  <p className="mt-1 text-xs leading-6 text-night-text-muted">
                    {d.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          9. Finance & settlement — light slab.
          ===================================================================== */}
      <section
        id="finance"
        className="mx-auto max-w-6xl px-4 py-20 sm:py-28 scroll-mt-16"
      >
        <div className="grid items-start gap-10 lg:grid-cols-[1fr_1.2fr]">
          <div className="space-y-4">
            <Badge variant="outline">مالی و تسویه</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              تسویه ساختارمند، گزارش‌گیری منسجم.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              از صدور فاکتور تا حساب امانی و تسویه نهایی، iKIA چرخه مالی را
              برای واحدهای عملیات و مالی شفاف می‌کند. تمام تراکنش‌ها قابل
              ممیزی، قابل ردگیری و قابل صدور برای گزارش‌های سازمانی هستند.
            </p>
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            {FINANCE_ITEMS.map((f) => (
              <Card key={f.title} className="border-border-soft shadow-card">
                <CardContent className="p-4 space-y-1">
                  <div className="text-sm font-semibold tracking-tight">
                    {f.title}
                  </div>
                  <p className="text-xs leading-6 text-muted-foreground">
                    {f.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          10. Integration & API — dark slab, roadmap-marked items.
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
          <div className="grid items-start gap-10 lg:grid-cols-[1fr_1.2fr]">
            <div className="space-y-4 text-night-text">
              <Badge variant="info" className="bg-white/10 text-night-text border-white/15">
                اتصال سازمانی — نقشه راه
              </Badge>
              <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                آمادگی برای اکوسیستم سازمانی شما.
              </h2>
              <p className="text-sm leading-7 text-night-text-muted">
                iKIA Logistics از پایه برای اتصال با ERP، WMS، سامانه گمرک و
                ابزارهای داخلی شما طراحی شده است. اتصال‌های زیر در نقشه راه
                محصول قرار دارند و به‌تدریج عرضه می‌شوند — بدون وعده‌های
                بی‌پشتوانه.
              </p>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {INTEGRATION_ITEMS.map((i) => (
                <div
                  key={i.title}
                  className="rounded-xl border border-white/10 bg-white/5 p-4 backdrop-blur-md"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="text-sm font-semibold text-night-text">
                      {i.title}
                    </div>
                    <Badge variant="muted" className="bg-white/10 text-night-text-muted border-white/15">
                      در نقشه راه
                    </Badge>
                  </div>
                  <p className="mt-1 text-xs leading-6 text-night-text-muted">
                    {i.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          11. Final CTA — cinematic deep-navy close. No demo language.
          ===================================================================== */}
      <section
        id="start"
        className="scroll-mt-16"
        style={{
          background:
            "linear-gradient(135deg, var(--color-deep-navy) 0%, var(--color-deep-navy-soft) 80%)",
        }}
      >
        <div className="mx-auto max-w-6xl px-4 py-20 sm:py-28">
          <div className="grid items-center gap-8 lg:grid-cols-[1.4fr_1fr]">
            <div className="space-y-3 text-night-text">
              <Badge variant="info" className="bg-white/10 text-night-text border-white/15">
                شروع همکاری
              </Badge>
              <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                زنجیره تأمین خود را با iKIA Logistics شفاف کنید.
              </h2>
              <p className="text-sm leading-7 text-night-text-muted">
                وارد پلتفرم شوید و بازار، اعزام، ردیابی، اسناد و تسویه را در
                یک نمای منسجم تجربه کنید. iKIA برای واحدهای عملیات، تأمین و
                مالی ساخته شده — نه برای جلسه‌های نمایشی.
              </p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row lg:justify-end">
              <Button asChild size="lg" className="w-full sm:w-auto">
                <Link href="/login">ورود به پلتفرم</Link>
              </Button>
              <Button
                asChild
                variant="outline"
                size="lg"
                className="w-full border-white/30 bg-transparent text-night-text hover:bg-white/10 hover:text-night-text sm:w-auto"
              >
                <Link href="#platform">بررسی قابلیت‌ها</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
