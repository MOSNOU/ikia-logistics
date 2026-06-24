import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { CorridorVisual } from "@/components/marketing/corridor-visual";
import { DriverConsoleMockup } from "@/components/marketing/driver-console-mockup";
import { HeroVisual } from "@/components/marketing/hero-visual";
import { VisibilityPanel } from "@/components/marketing/visibility-panel";

// CC-56 — iKIA Logistics public landing page. Persian-first, RTL-first,
// mobile-first. Sections (top-down):
//   1. Hero — premium operating-system positioning + dual CTA.
//   2. Trust strip — five operational value lines.
//   3. Platform modules — six product domains in a uniform card grid.
//   4. Visibility — dashboard mockup + Persian copy on shipment health.
//   5. Driver console — phone mockup + explicit-click telemetry copy.
//   6. Corridor — Iran transit positioning (domestic / int'l / transit).
//   7. Operating system — four-role grid (buyer / carrier / driver / admin).
//   8. Final CTA — demo invitation.
//
// All visuals are original inline SVG or HTML composed from existing
// CC-54 design tokens. Zero external assets, zero raster images, no
// "use client" anywhere.

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

const DRIVER_BULLETS = [
  "شروع نشست تله‌متری با یک کلیک صریح.",
  "ارسال موقعیت پس از بازبینی توسط راننده — هیچ ارسال خودکار.",
  "خط زمانی سفر شامل نقاط عطف، توقف‌ها و رویدادهای تله‌متری.",
  "UX تلاش‌دوباره ایمن در صورت قطع اتصال، بدون از دست رفتن داده‌های وارد شده.",
];

const CORRIDORS: TextItem[] = [
  {
    title: "حمل داخلی",
    description:
      "از تهران، اصفهان و دیگر مراکز صنعتی تا مقصد در سراسر کشور؛ پیگیری جاده‌ای و چندوجهی.",
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

export default function HomePage() {
  return (
    <div className="space-y-24 sm:space-y-32 pb-20">
      {/* ====================================================================
          1. Hero
          ==================================================================== */}
      <section className="relative overflow-hidden">
        <div
          className="absolute inset-0 -z-10"
          style={{
            background:
              "radial-gradient(at 30% 20%, var(--color-brand-100), transparent 55%), radial-gradient(at 75% 10%, var(--color-tracking-soft), transparent 50%)",
          }}
        />
        <div className="mx-auto max-w-6xl px-4 pt-16 sm:pt-24">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div className="space-y-6">
              <Badge variant="info">سامانه عملیات لجستیک ایران</Badge>
              <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl lg:text-5xl">
                زنجیره تأمین شما،
                <br />
                شفاف از کارخانه تا مقصد.
              </h1>
              <p className="max-w-xl text-base leading-8 text-muted-foreground sm:text-lg">
                iKIA Logistics یک سامانه یکپارچه برای صاحبان کالا، شرکت‌های
                حمل‌ونقل و کنترل‌تاور است. ردیابی زنده، مدیریت اسناد، تسویه
                ساختارمند و کنترل عملیاتی روزانه — همگی در یک پلتفرم.
              </p>
              <div className="flex flex-wrap gap-3">
                <Button asChild size="lg" className="w-full sm:w-auto">
                  <Link href="#demo">درخواست دمو</Link>
                </Button>
                <Button asChild variant="outline" size="lg" className="w-full sm:w-auto">
                  <Link href="#platform">مشاهده پلتفرم</Link>
                </Button>
              </div>
              <p className="text-xs text-muted-foreground">
                مناسب شرکت‌های متوسط و بزرگ — حمل داخلی، بین‌المللی و ترانزیتی.
              </p>
            </div>
            <div className="relative">
              <div className="rounded-3xl border border-border-soft bg-card p-3 shadow-elevated">
                <HeroVisual className="block h-auto w-full" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ====================================================================
          2. Trust strip
          ==================================================================== */}
      <section className="mx-auto max-w-6xl px-4">
        <div className="rounded-2xl border border-border-soft bg-surface-muted p-5 sm:p-6">
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

      {/* ====================================================================
          3. Platform modules
          ==================================================================== */}
      <section id="platform" className="mx-auto max-w-6xl px-4 scroll-mt-16">
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

      {/* ====================================================================
          4. Visibility — operational dashboard mockup
          ==================================================================== */}
      <section id="visibility" className="mx-auto max-w-6xl px-4 scroll-mt-16">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <div className="space-y-4">
            <Badge variant="info">ردیابی و رؤیت</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              همه چیز در یک نگاه.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              کنترل‌تاور iKIA وضعیت محموله‌های فعال، نشست‌های تله‌متری راننده،
              تأخیرها و استثناهای روزانه را در یک صفحه گردآوری می‌کند. شاخص‌ها
              لحظه‌ای محاسبه می‌شوند؛ هیچ داده عملیاتی پنهان نمی‌ماند.
            </p>
            <ul className="space-y-2 text-sm leading-7">
              <li>• شاخص‌های فعال: محموله، اعزام، نشست تله‌متری، استثنا.</li>
              <li>• چیپ سلامت تله‌متری برای هر سفر: به‌روز / قدیمی / بدون موقعیت.</li>
              <li>• فهرست محموله‌های اخیر همراه با وضعیت عملیاتی و کریدور.</li>
            </ul>
          </div>
          <VisibilityPanel />
        </div>
      </section>

      {/* ====================================================================
          5. Driver console — phone mockup
          ==================================================================== */}
      <section id="driver" className="mx-auto max-w-6xl px-4 scroll-mt-16">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <DriverConsoleMockup className="order-2 lg:order-1" />
          <div className="order-1 space-y-4 lg:order-2">
            <Badge variant="info">اپ راننده</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              راننده در کنترل، نه در نظارت پنهان.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              کنسول راننده iKIA یک تجربه موبایل-اول است که شفافیت کامل به راننده
              می‌دهد. هیچ نشست تله‌متری بدون کلیک شروع نمی‌شود؛ هیچ موقعیت بدون
              تأیید ارسال نمی‌شود.
            </p>
            <ul className="space-y-2 text-sm leading-7">
              {DRIVER_BULLETS.map((b) => (
                <li key={b}>• {b}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ====================================================================
          6. Corridor — Iran transit positioning
          ==================================================================== */}
      <section id="corridor" className="mx-auto max-w-6xl px-4 scroll-mt-16">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <div className="space-y-4">
            <Badge variant="info">کریدور و ترانزیت</Badge>
            <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
              از حمل داخلی تا ترانزیت بین‌المللی.
            </h2>
            <p className="text-sm leading-7 text-muted-foreground">
              iKIA Logistics برای جغرافیای واقعی زنجیره تأمین ایران ساخته شده است:
              شبکه جاده‌ای کشور، مرزهای ترانزیتی شمال، شرق و شمال‌غرب، و کریدور
              جنوب از طریق بنادر اصلی.
            </p>
            <div className="grid gap-3 sm:grid-cols-3">
              {CORRIDORS.map((c) => (
                <div
                  key={c.title}
                  className="rounded-xl border border-border-soft bg-card p-3"
                >
                  <div className="text-sm font-semibold">{c.title}</div>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {c.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
          <div className="rounded-3xl border border-border-soft bg-card p-3 shadow-elevated">
            <CorridorVisual className="block h-auto w-full" />
          </div>
        </div>
      </section>

      {/* ====================================================================
          7. Operating system — four-role grid
          ==================================================================== */}
      <section id="roles" className="mx-auto max-w-6xl px-4 scroll-mt-16">
        <div className="max-w-2xl space-y-3">
          <Badge variant="outline">سامانه چند نقشی</Badge>
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
            <Card
              key={role.title}
              className="border-border-soft shadow-card"
            >
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
      </section>

      {/* ====================================================================
          8. Final CTA
          ==================================================================== */}
      <section id="demo" className="mx-auto max-w-6xl px-4 scroll-mt-16">
        <Card
          className="border-border-soft shadow-elevated overflow-hidden"
          style={{
            background:
              "linear-gradient(135deg, var(--color-brand-50) 0%, var(--color-surface) 60%)",
          }}
        >
          <CardContent className="p-6 sm:p-10">
            <div className="grid items-center gap-6 lg:grid-cols-[1.4fr_1fr]">
              <div className="space-y-3">
                <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">
                  آماده‌اید iKIA Logistics را در عمل ببینید؟
                </h2>
                <p className="text-sm leading-7 text-muted-foreground">
                  یک جلسه ۳۰ دقیقه‌ای با تیم ما رزرو کنید. در این جلسه پلتفرم را
                  بر اساس سناریوی واقعی شما — حمل داخلی، بین‌المللی یا ترانزیت —
                  نمایش می‌دهیم.
                </p>
              </div>
              <div className="flex flex-col gap-2 sm:flex-row lg:justify-end">
                <Button asChild size="lg" className="w-full sm:w-auto">
                  <Link href="/login">ورود به پلتفرم</Link>
                </Button>
                <Button asChild variant="outline" size="lg" className="w-full sm:w-auto">
                  <Link href="#platform">مرور دوباره پلتفرم</Link>
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
