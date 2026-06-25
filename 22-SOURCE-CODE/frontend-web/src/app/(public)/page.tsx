import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { MarketingImageFill } from "@/components/marketing/marketing-image-fill";
import { MarketingMarquee } from "@/components/marketing/marketing-marquee";
import { MarketingScreenshot } from "@/components/marketing/marketing-screenshot";
import { PremiumSectionHeader } from "@/components/marketing/premium-section-header";
import { StakeholderSolutionCard } from "@/components/marketing/stakeholder-solution-card";
import { TransportServiceCard } from "@/components/marketing/transport-service-card";

// CC-63 — Platform Operating Model & End-to-End Journey.
//
// Persian-first, RTL-first, mobile-first, static-renderable.
//
// 23 sections (CC-62 set − 3 retired + 7 new + 1 CTA refresh):
//   1.  Hero
//   2.  Trusted national OS intro
//   3.  Solutions (#solutions)
//   4.  Platform Capabilities (#platform)
//   5.  Logistics Market Structure (#market-structure)
//   6.  CC-63 A — How iKIA Works (#how-it-works)
//   7.  CC-63 B — Shipment Lifecycle (#shipment-lifecycle)
//   8.  CC-63 D — Platform Modules (#modules)
//   9.  National Corridor Network (#corridors)
//  10.  Why Iran (#why-iran)
//  11.  Ecosystem Value Creation (#ecosystem)
//  12.  CC-63 C — Ecosystem Interaction Map (#interaction-model)
//  13.  Platform Flywheel (#flywheel)
//  14.  Documents & Compliance (#documents)
//  15.  Carrier Marketplace (#marketplace)
//  16.  Settlement & Dispute (#settlement)
//  17.  CC-63 E — Digital Control Tower Narrative (#control-tower)   ← dark slab
//  18.  CC-63 F — Data Flow (#data-flow)
//  19.  Operating System Positioning (#operating-system)
//  20.  Revenue Architecture (#economics-model)
//  21.  Investment Readiness Narrative (#future)
//  22.  CC-63 G — Enterprise Readiness (#enterprise-readiness)
//  23.  CC-63 H — Final CTA Refresh (#start)
//
// CC-61's #executive and #trust sections are retired; CC-62's
// #stakeholders is retired. Their themes are now carried by CC-63
// Sections E, G, and C respectively, with operational-journey framing.

interface TextItem {
  title: string;
  description: string;
}

const HERO_HIGHLIGHTS: { label: string; tone: "blue" | "green" | "amber" | "navy" }[] = [
  { label: "حمل چندوجهی یکپارچه", tone: "blue" },
  { label: "کنترل‌تاور لحظه‌ای", tone: "green" },
  { label: "اسناد گمرکی و انطباق", tone: "amber" },
  { label: "تسویه ساختارمند", tone: "navy" },
];

const HIGHLIGHT_TONES = {
  blue: "border-brand-100 bg-brand-50 text-brand-700",
  green: "border-emerald-100 bg-emerald-50 text-emerald-700",
  amber: "border-amber-200 bg-amber-50 text-amber-800",
  navy: "border-deep-navy/10 bg-deep-navy/5 text-deep-navy",
} as const;

const HERO_COVERAGE_CHIPS: string[] = ["داخلی", "بین‌المللی", "ترانزیت"];

const TRUST_METRICS: { label: string; value: string; hint: string }[] = [
  { label: "حمل چندوجهی", value: "۴", hint: "جاده‌ای، دریایی، ریلی، هوایی" },
  { label: "سطح کریدور", value: "۳", hint: "داخلی، بین‌المللی، ترانزیت" },
  { label: "نقش‌های عملیاتی", value: "۴", hint: "خریدار، حمل‌کننده، راننده، ادمین" },
  { label: "حافظه ممیزی", value: "۱۰۰٪", hint: "هر تغییر وضعیت و تراکنش" },
];

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
    alt: "نمای تحلیل عملیاتی برای صاحبان کالا",
    badge: "صاحبان کالا",
    title: "از سفارش تا تحویل، تحت کنترل کامل",
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
      "بازار ظرفیت همراه با چرخه اعزام عملیاتی — از پذیرش رزرو تا آزادسازی محموله و گزارش‌گیری از سفرها.",
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
      "تجربه موبایل-اول برای راننده — هیچ نشست تله‌متری بدون کلیک شروع نمی‌شود؛ هیچ موقعیت بدون تأیید ارسال نمی‌شود.",
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

const PLATFORM_MODULES: TextItem[] = [
  { title: "بازار بار و ظرفیت", description: "تطبیق ساختارمند ظرفیت حمل‌کنندگان با تقاضای بار، در یک بازار شفاف و قابل پیگیری." },
  { title: "مدیریت اعزام", description: "تخصیص خودرو و راننده، اعلام آمادگی، آزادسازی محموله و چرخه اعزام در یک نما." },
  { title: "ردیابی زنده و کنترل‌تاور", description: "موقعیت، نقاط عطف، توقف‌ها و خط زمانی سفر — به همراه شاخص‌های زنده عملیات." },
  { title: "مدیریت اسناد", description: "نگه‌داری اسناد گمرکی، بیمه، بارنامه و قرارداد اجراشده با حافظه ممیزی." },
  { title: "تسویه و گزارش مالی", description: "صدور فاکتور، حساب امانی، آزادسازی مرحله‌ای و گزارش‌های قابل ممیزی." },
  { title: "گزارش‌ها و تحلیل‌ها", description: "تحلیل عملکرد ناوگان، مسیرها، استثناها و چرخه مالی برای تصمیم‌سازی." },
];

const MARKET_STRUCTURE: TextItem[] = [
  { title: "حمل داخلی", description: "شبکه‌ای گسترده از حمل‌کنندگان مستقل با هماهنگی محدود — پراکندگی ظرفیت، شفافیت اندک در قیمت‌گذاری و گزارش‌گیری عملیاتی غیرساختارمند." },
  { title: "حمل بین‌المللی", description: "گردش کاری پیچیده میان فورواردرها، کریرهای دریایی و هوایی، با اسناد گمرکی متعدد و انطباق چندلایه در مرزها و بنادر." },
  { title: "ترانزیت", description: "هماهنگی چندوجهی در کریدورهای منطقه‌ای با ذی‌نفعان متعدد در مرزها، انبارها و سامانه‌های گمرکی متفاوت — بدون یک منبع داده مشترک." },
  { title: "لجستیک چندوجهی", description: "انتقال محموله میان شیوه‌های مختلف حمل با شکاف داده‌ای، ناهماهنگی زمان‌بندی و چالش انتقال مسئولیت بین ذی‌نفعان." },
];

// =============================================================================
// CC-63 SECTION A — How iKIA Works (#how-it-works) — 6 process steps
// =============================================================================
const HOW_IT_WORKS_STEPS: { num: string; title: string; description: string }[] = [
  { num: "۰۱", title: "ثبت نیاز حمل", description: "صاحب کالا نیاز حمل خود را با مشخصات کامل بار، مبدأ، مقصد و زمان‌بندی ثبت می‌کند." },
  { num: "۰۲", title: "کشف ظرفیت", description: "پلتفرم ظرفیت‌های موجود حمل‌کنندگان همکار را در همه شیوه‌های حمل در دسترس قرار می‌دهد." },
  { num: "۰۳", title: "تطبیق هوشمند", description: "موتور تطبیق، گزینه‌های متناسب با مشخصات بار را شناسایی و رتبه‌بندی می‌کند." },
  { num: "۰۴", title: "رزرو و هماهنگی", description: "طرفین گزینه نهایی را تأیید می‌کنند و قرارداد دیجیتال منعقد می‌شود." },
  { num: "۰۵", title: "اجرای عملیات", description: "حمل‌کننده اعزام را برنامه‌ریزی می‌کند، راننده تخصیص می‌یابد و محموله حرکت می‌کند." },
  { num: "۰۶", title: "رؤیت و کنترل", description: "وضعیت لحظه‌ای محموله در سطح کریدور برای همه ذی‌نفعان قابل پیگیری است." },
];

// =============================================================================
// CC-63 SECTION B — Shipment Lifecycle (#shipment-lifecycle) — 8 states
// =============================================================================
const SHIPMENT_LIFECYCLE: { num: string; en: string; label: string; description: string }[] = [
  { num: "۰۱", en: "Draft", label: "پیش‌نویس", description: "نیاز حمل توسط صاحب کالا در حال آماده‌سازی است." },
  { num: "۰۲", en: "Published", label: "منتشرشده", description: "نیاز حمل آماده دریافت پیشنهاد از حمل‌کنندگان است." },
  { num: "۰۳", en: "Matched", label: "تطبیق‌یافته", description: "گزینه‌های ظرفیت متناسب شناسایی و رتبه‌بندی شده‌اند." },
  { num: "۰۴", en: "Booked", label: "رزروشده", description: "طرفین گزینه را تأیید کرده‌اند و قرارداد دیجیتال منعقد شده." },
  { num: "۰۵", en: "Dispatched", label: "اعزام‌شده", description: "حمل‌کننده خودرو و راننده را تخصیص داده و آماده حرکت است." },
  { num: "۰۶", en: "In Transit", label: "در حال حمل", description: "محموله در مسیر است و موقعیت آن لحظه‌ای پیگیری می‌شود." },
  { num: "۰۷", en: "Delivered", label: "تحویل‌شده", description: "محموله در مقصد تحویل داده شده و اسناد تحویل ثبت شده‌اند." },
  { num: "۰۸", en: "Closed", label: "بسته‌شده", description: "تسویه نهایی انجام شده و چرخه مالی محموله بسته شده است." },
];

// =============================================================================
// CC-63 SECTION D — Platform Modules (#modules) — 8 modules
// =============================================================================
const OPERATING_MODULES: { en: string; title: string; description: string }[] = [
  { en: "Marketplace", title: "بازار حمل", description: "اتصال بار به ظرفیت در یک بازار شفاف چندوجهی." },
  { en: "Matching Engine", title: "موتور تطبیق", description: "شناسایی هوشمند بهترین گزینه ظرفیت برای هر بار." },
  { en: "Booking", title: "رزرو", description: "گردش کار تأیید و انعقاد قرارداد دیجیتال طرفین." },
  { en: "Dispatch", title: "اعزام", description: "تخصیص خودرو، راننده و برنامه‌ریزی اجرای حمل." },
  { en: "Control Tower", title: "برج کنترل", description: "دید لحظه‌ای بر همه عملیات و مدیریت استثناها." },
  { en: "Settlement", title: "تسویه", description: "صدور فاکتور، حساب امانی و آزادسازی مرحله‌ای." },
  { en: "Compliance", title: "انطباق", description: "اسناد گمرکی، بارنامه و گردش کار درخواست/تأیید." },
  { en: "Analytics", title: "تحلیل", description: "داشبوردهای تصمیم‌سازی و گزارش‌های ساختارمند." },
];

const CORRIDORS: { tag: string; title: string; description: string }[] = [
  { tag: "شمال – جنوب", title: "کریدور شمال–جنوب", description: "اتصال روسیه، آسیای میانه و قفقاز به خلیج فارس و اقیانوس هند از طریق شبکه ریلی، جاده‌ای و دریایی ایران." },
  { tag: "شرق – غرب", title: "کریدور شرق–غرب", description: "اتصال چین و آسیای میانه به اروپا با عبور از مرزهای شرقی و شمال‌غربی ایران، با مسیرهای ریلی و جاده‌ای." },
  { tag: "ترانزیت چندوجهی", title: "کریدور چین–آسیای میانه–ایران–اروپا", description: "مسیر کوتاه‌تر ترانزیتی بین چین و اروپا با استفاده از زیرساخت ریلی و جاده‌ای متصل به ایران." },
  { tag: "خلیج فارس – اروپا", title: "کریدور خلیج فارس–قفقاز–اروپا", description: "اتصال بنادر اصلی جنوب کشور به بازارهای قفقاز و اروپا با هماهنگی چندوجهی اسناد و گردش کار گمرکی." },
];

const WHY_IRAN: TextItem[] = [
  { title: "دسترسی به بازارهای منطقه", description: "موقعیت ایران در دسترسی به بازارهای پرجمعیت آسیای میانه، قفقاز، خلیج فارس و خاورمیانه." },
  { title: "اتصال چندوجهی", description: "زیرساخت جاده‌ای، ریلی، دریایی و هوایی برای حمل چندوجهی در سراسر کشور و کریدورهای ترانزیتی." },
  { title: "موقعیت ژئوپلیتیک", description: "گذرگاه راهبردی بین قاره آسیا و اروپا با اتصال به شبکه‌های تجارت بین‌المللی." },
  { title: "دسترسی به آب‌های آزاد", description: "بنادر اصلی در سواحل جنوبی با اتصال به اقیانوس هند، خلیج فارس و دریای عمان." },
  { title: "ظرفیت ترانزیتی", description: "زیرساخت لجستیکی ملی برای جابجایی محموله بین مرزهای کشور و کریدورهای منطقه‌ای." },
];

const ECOSYSTEM_STAKEHOLDERS: { badge: string; title: string; description: string }[] = [
  { badge: "صاحب کالا", title: "شفافیت و کنترل کامل عملیات", description: "کاهش زمان هماهنگی، دید کامل بر محموله و گزارش‌گیری ساختارمند برای واحدهای عملیات و مالی." },
  { badge: "فورواردر", title: "گردش کار دیجیتال اسناد", description: "اظهارنامه، بارنامه و گواهی‌ها در یک منبع، با مدیریت یکپارچه چندین محموله و اطلاع‌رسانی خودکار." },
  { badge: "کریر", title: "دسترسی ساختارمند به تقاضا", description: "انتشار ظرفیت، پذیرش رزرو و چرخه پرداخت قابل پیش‌بینی برای شرکت‌های حمل‌ونقل." },
  { badge: "راننده", title: "کنسول موبایل با کنترل کامل", description: "اپ راننده با شفافیت سفر، بدون ردیابی پنهان و با ارسال موقعیت تنها با تأیید صریح کاربر." },
  { badge: "اپراتور", title: "معماری سازمانی برای مدیران عملیات", description: "دید کامل بر استثناها، تأخیرها و عملکرد ناوگان — برای واحدهای عملیات سازمانی." },
  { badge: "نهادهای حاکمیتی", title: "داده ساختارمند برای سیاست‌گذاری", description: "داده‌های لجستیکی ساختارمند برای رصد جریان تجارت، توسعه کریدورها و ارزیابی عملکرد ملی." },
];

// =============================================================================
// CC-63 SECTION C — Ecosystem Interaction Map (#interaction-model)
// 7 participants surrounding iKIA Platform hub. Split commercial vs
// infrastructure for the two rows.
// =============================================================================
const COMMERCIAL_PARTICIPANTS: { en: string; title: string; description: string }[] = [
  { en: "Cargo Owner", title: "صاحب کالا", description: "نقطه شروع جریان: ثبت نیاز حمل و انتخاب گزینه." },
  { en: "Forwarder", title: "فورواردر", description: "هماهنگی اسناد گمرکی، انطباق و ترخیص." },
  { en: "Carrier", title: "کریر", description: "ظرفیت حمل و چرخه اعزام عملیاتی." },
  { en: "Driver", title: "راننده", description: "اجرای زنده حمل با کنسول موبایل اختصاصی." },
];

const INFRASTRUCTURE_PARTICIPANTS: { en: string; title: string; description: string }[] = [
  { en: "Customs", title: "گمرک", description: "گردش کار اظهارنامه و تأیید ترخیص." },
  { en: "Port", title: "بنادر", description: "اتصال داده‌ای به جریان عملیاتی بنادر اصلی." },
  { en: "Railway", title: "راه‌آهن", description: "شبکه ریلی ملی برای کریدورهای ترانزیتی." },
];

const FLYWHEEL_STEPS: { num: string; title: string; description: string }[] = [
  { num: "۰۱", title: "صاحبان کالا", description: "ورود صاحبان کالای بیشتر به پلتفرم — تقاضای ساختارمند ایجاد می‌شود." },
  { num: "۰۲", title: "فرصت‌های حمل", description: "حجم تقاضای بار افزایش می‌یابد و کریدورهای فعال متنوع‌تر می‌شوند." },
  { num: "۰۳", title: "کریرها", description: "حمل‌کنندگان بیشتری به ظرفیت پلتفرم می‌پیوندند تا به این تقاضا پاسخ دهند." },
  { num: "۰۴", title: "ظرفیت بیشتر", description: "گزینه‌های ظرفیت متنوع‌تر — جاده، دریا، ریل، هوا — در دسترس قرار می‌گیرد." },
  { num: "۰۵", title: "تطبیق بهتر", description: "تطبیق هوشمندتر بار و ظرفیت با کیفیت بالاتر رخ می‌دهد." },
  { num: "۰۶", title: "هزینه کمتر", description: "بهره‌وری بهتر، هزینه عملیاتی کمتر برای ذی‌نفعان به دنبال دارد." },
  { num: "۰۷", title: "رشد تقاضا", description: "تجربه عملیاتی بهتر، تقاضای بیشتری برای پلتفرم ایجاد می‌کند — و چرخه ادامه می‌یابد." },
];

const DOCUMENT_BULLETS: TextItem[] = [
  { title: "اسناد گمرکی", description: "اظهارنامه واردات، صادرات و ترانزیت با گردش کار درخواست/تأیید." },
  { title: "بارنامه و گواهی مبدأ", description: "بارنامه‌های حمل و گواهی مبدأ، در دسترس هر سه نقش عملیاتی." },
  { title: "بیمه و انطباق", description: "بیمه‌نامه‌های حمل، گواهی انطباق و اسناد بازرسی با تاریخ‌های روشن." },
  { title: "قرارداد اجراشده", description: "قرارداد اجرایی و امضای دیجیتال طرفین در یک منبع واحد." },
];

const TRANSPORT_SERVICES: {
  src: string;
  alt: string;
  title: string;
  description: string;
  tags: string[];
}[] = [
  { src: "/marketing/14-road-freight-service-card-clean.png", alt: "خدمات حمل جاده‌ای iKIA", title: "حمل جاده‌ای", description: "ستون اصلی حمل داخلی و کریدورهای ترانزیتی، با اعزام منسجم و ردیابی زنده در سطح مسیر.", tags: ["داخلی", "چندوجهی", "اعزام"] },
  { src: "/marketing/13-sea-freight-service-card-clean.png", alt: "خدمات حمل دریایی iKIA", title: "حمل دریایی", description: "هماهنگی محموله‌های کانتینری از بنادر اصلی جنوب کشور تا مقصد نهایی، با اسناد گمرکی منسجم.", tags: ["کانتینر", "بنادر", "صادرات/واردات"] },
  { src: "/marketing/12-rail-freight-service-card-clean.png", alt: "خدمات حمل ریلی iKIA", title: "حمل ریلی", description: "گزینه کارآمد برای حجم بالا در مسیرهای ریلی داخلی و کریدورهای ترانزیتی شرق-غرب.", tags: ["حجمی", "ترانزیت", "کریدور ریلی"] },
  { src: "/marketing/11-air-freight-service-card-clean.png", alt: "خدمات حمل هوایی iKIA", title: "حمل هوایی", description: "گزینه سریع برای محموله‌های ارزشمند یا حساس به زمان، با مدیریت کامل اسناد گمرکی.", tags: ["سریع", "ارزشمند", "اسناد گمرکی"] },
  { src: "/marketing/10-warehouse-service-card-clean.png", alt: "خدمات انبارداری iKIA", title: "خدمات انبارداری", description: "هماهنگی انبار، انبارهای ترانزیتی و عملیات تجمیع/توزیع محموله در شبکه iKIA.", tags: ["انبار", "تجمیع", "توزیع"] },
];

const SETTLEMENT_BULLETS: string[] = [
  "صدور فاکتور خریدار و حمل‌کننده با حافظه ممیزی.",
  "حساب امانی با آزادسازی مرحله‌ای بر اساس وضعیت تحویل.",
  "گردش کار اختلاف با ثبت شواهد و تصمیم‌گیری ساختارمند.",
  "پشتیبانی از چندارزی و ثبت نرخ تبدیل در زمان تسویه.",
  "گزارش‌های مالی قابل صدور برای واحد مالی و کنترل داخلی.",
];

// =============================================================================
// CC-63 SECTION E — Digital Control Tower Narrative (#control-tower)
// Pure narrative, no screenshots. 4 narrative pillars.
// =============================================================================
const CONTROL_TOWER_PILLARS: TextItem[] = [
  {
    title: "منبع واحد حقیقت",
    description:
      "یک نسخه از داده‌های عملیاتی برای همه ذی‌نفعان زنجیره تأمین — بدون نسخه‌های متناقض و بدون نیاز به آشتی دستی داده.",
  },
  {
    title: "دید عملیاتی",
    description:
      "نمای زنده از وضعیت محموله‌ها، ناوگان، نشست‌های تله‌متری و گردش اسناد — برای واحدهای عملیات، تأمین و مالی.",
  },
  {
    title: "مدیریت استثنا",
    description:
      "شناسایی هوشمند، اولویت‌بندی خودکار و گردش کار ساختارمند برای رفع استثناهای عملیاتی روزانه.",
  },
  {
    title: "هماهنگی بین‌مرزی",
    description:
      "هماهنگی یکپارچه برای محموله‌های ترانزیتی در کریدورهای منطقه‌ای، با اسناد و انطباق منسجم در سراسر مرزها.",
  },
];

// =============================================================================
// CC-63 SECTION F — Data Flow (#data-flow) — 6 stages
// =============================================================================
const DATA_FLOW_STAGES: { num: string; en: string; title: string; description: string }[] = [
  { num: "۰۱", en: "Orders", title: "سفارش‌ها", description: "درخواست‌های حمل، RFQها و قراردادهای منعقد شده — نقطه شروع جریان." },
  { num: "۰۲", en: "Documents", title: "اسناد", description: "اظهارنامه گمرکی، بارنامه، بیمه و قراردادها در یک منبع منسجم." },
  { num: "۰۳", en: "Operations", title: "عملیات", description: "اعزام، حرکت محموله، رویدادهای راننده، توقف‌ها و تحویل." },
  { num: "۰۴", en: "Events", title: "رویدادها", description: "هر تغییر وضعیت در یک حافظه ممیزی ساختارمند ثبت می‌شود." },
  { num: "۰۵", en: "Analytics", title: "تحلیل", description: "داده خام به شاخص‌های قابل تحلیل و گزارش‌های اجرایی تبدیل می‌شود." },
  { num: "۰۶", en: "Decision Making", title: "تصمیم‌سازی", description: "گزارش‌ها و داشبوردها به مدیران اجرایی قدرت تصمیم‌سازی می‌دهند." },
];

const OS_NOT_PILLARS: TextItem[] = [
  { title: "نه فقط یک بازار حمل", description: "تطبیق بار و ظرفیت بدون چرخه اجرا، اسناد، تسویه و انطباق، تنها بخشی از تصویر است." },
  { title: "نه فقط یک TMS", description: "نرم‌افزار مدیریت حمل بدون اتصال به اکوسیستم بازار و سامانه‌های نهادهای حاکمیتی، محدود می‌ماند." },
  { title: "نه فقط یک ابزار ردیابی", description: "ردیابی موقعیت بدون چرخه عملیاتی کامل، صرفاً یک لایه قابلیت نمایش است، نه یک سیستم عامل." },
];

const OS_PILLARS: string[] = [
  "ادغام بازار حمل، اجرای عملیات، رؤیت لحظه‌ای، اسناد و تسویه در یک پلتفرم واحد.",
  "معماری چندمستأجری برای پشتیبانی همزمان از ده‌ها سازمان با جداسازی نقش‌محور داده.",
  "معماری انطباق‌محور با حافظه ممیزی کامل برای واحدهای عملیات، مالی و حسابرسی.",
  "زیرساخت دیجیتال ملی برای کریدورهای داخلی، بین‌المللی و ترانزیتی منطقه.",
];

const REVENUE_BLOCKS: { num: string; title: string; description: string }[] = [
  { num: "۰۱", title: "اشتراک سازمانی", description: "دسترسی پایه‌ای سازمان‌ها به پلتفرم با ساختار اشتراک سالانه برای صاحبان کالا و حمل‌کنندگان." },
  { num: "۰۲", title: "خدمات بازار حمل", description: "گردش کار بازار ظرفیت، رزرو و چرخه اعزام برای ذی‌نفعان حمل‌ونقل با ساختار خدمات‌محور." },
  { num: "۰۳", title: "خدمات ارزش افزوده", description: "خدمات تخصصی مانند ترخیص، بیمه، انبارداری و سایر خدمات کناری زنجیره تأمین." },
  { num: "۰۴", title: "تحلیل و گزارش", description: "داشبوردهای تحلیلی پیشرفته و گزارش‌های ساختارمند سازمانی برای مدیران اجرایی." },
  { num: "۰۵", title: "خدمات یکپارچه‌سازی", description: "اتصال سازمانی به ERP، WMS، CRM و سامانه‌های گمرکی برای مشتریان سازمانی بزرگ." },
];

const FUTURE_THEMES: { num: string; title: string; description: string }[] = [
  { num: "۰۱", title: "دیجیتالی‌سازی", description: "حذف کاغذبازی، تبدیل گردش کار به فرایند ساختارمند، دیجیتال و قابل ممیزی." },
  { num: "۰۲", title: "شفافیت", description: "دسترسی به داده‌های لحظه‌ای برای همه ذی‌نفعان عملیاتی روی یک منبع داده مشترک." },
  { num: "۰۳", title: "هماهنگی", description: "اتصال ساختارمند ذی‌نفعان متعدد روی یک پلتفرم برای حذف اصطکاک هماهنگی." },
  { num: "۰۴", title: "مقیاس‌پذیری", description: "معماری چندمستأجری برای پشتیبانی از رشد همزمان حجم تراکنش و تعداد سازمان‌ها." },
  { num: "۰۵", title: "رشد اکوسیستم", description: "بستر بازی برای ادغام خدمات ارزش افزوده، شرکای استراتژیک و یکپارچه‌سازی‌های آینده." },
];

// =============================================================================
// CC-63 SECTION G — Enterprise Readiness (#enterprise-readiness) — 5 pillars
// Business language only — no technical implementation details.
// =============================================================================
const ENTERPRISE_PILLARS: { num: string; title: string; description: string }[] = [
  {
    num: "۰۱",
    title: "چندمستأجری",
    description:
      "جداسازی کامل داده‌های سازمان‌ها با کنترل دسترسی نقش‌محور و جریان عملیاتی مستقل برای هر مستأجر.",
  },
  {
    num: "۰۲",
    title: "امنیت",
    description:
      "معماری امنیتی چندلایه با حفاظت از داده در حین انتقال و نگه‌داری، و کنترل دسترسی سازمانی.",
  },
  {
    num: "۰۳",
    title: "انطباق",
    description:
      "انطباق با الزامات گمرکی، مالیاتی و حقوقی کشور — همراه با گردش کار درخواست/تأیید برای اسناد حساس.",
  },
  {
    num: "۰۴",
    title: "مقیاس‌پذیری",
    description:
      "معماری برای رشد همزمان حجم تراکنش و تعداد سازمان‌های همکار — بدون افت کیفیت عملیاتی.",
  },
  {
    num: "۰۵",
    title: "قابلیت حسابرسی",
    description:
      "حافظه کامل ممیزی برای رویدادها، اسناد و تراکنش‌ها — قابل صدور برای حسابرسی داخلی و خارجی.",
  },
];

// =============================================================================
// CC-64 SECTION A — Industry Solutions Hub (#industries) — 6 cards
// =============================================================================
const INDUSTRY_HUB: {
  num: string;
  en: string;
  title: string;
  description: string;
  anchor: string;
}[] = [
  {
    num: "۰۱",
    en: "Oil & Petrochemical",
    title: "نفت و پتروشیمی",
    description:
      "صادرات محصولات پتروشیمی، حمل تانکر، حمل ریلی شیمیایی و عملیات بندری — با اسناد گمرکی منسجم.",
    anchor: "#oil-gas",
  },
  {
    num: "۰۲",
    en: "Mining & Metals",
    title: "معدن و فلزات",
    description:
      "سنگ آهن، کنسانتره، فولاد، مس و آلومینیوم — حمل حجیم چندوجهی تا بنادر صادراتی.",
    anchor: "#mining",
  },
  {
    num: "۰۳",
    en: "Agriculture & Food",
    title: "کشاورزی و مواد غذایی",
    description:
      "غلات، نهاده‌ها، کود و محصولات فاسدشدنی — با هماهنگی زنجیره توزیع و رؤیت لحظه‌ای.",
    anchor: "#agriculture",
  },
  {
    num: "۰۴",
    en: "FMCG & Retail",
    title: "کالاهای مصرفی",
    description:
      "توزیع منطقه‌ای، Cross-Dock، حمل شهری و تأمین فروشگاه‌ها در شبکه ملی.",
    anchor: "#retail",
  },
  {
    num: "۰۵",
    en: "International Trade",
    title: "تجارت بین‌المللی",
    description:
      "هماهنگی واردات و صادرات با گردش کار گمرکی، اسناد بین‌المللی و انطباق چندلایه.",
    anchor: "#commodities",
  },
  {
    num: "۰۶",
    en: "Transit & Corridors",
    title: "ترانزیت و کریدورها",
    description:
      "عملیات ترانزیتی چندوجهی در کریدورهای منطقه‌ای — اتصال شرق به غرب و شمال به جنوب.",
    anchor: "#transit",
  },
];

// =============================================================================
// CC-64 SECTION B — Oil & Petrochemical (#oil-gas) — 5 content pillars
// =============================================================================
const OIL_GAS_PILLARS: TextItem[] = [
  {
    title: "صادرات محصولات پتروشیمی",
    description:
      "هماهنگی صادرات محموله‌های پتروشیمی از مبدأ تولید تا بنادر و مقاصد بین‌المللی، با گردش کار اسناد یکپارچه.",
  },
  {
    title: "حمل مخازن و تانکر",
    description:
      "اعزام تانکر و مخازن ویژه با ثبت ساختارمند بارگیری، حمل و تخلیه — همراه با چرخه اعزام منسجم.",
  },
  {
    title: "حمل ریلی مواد شیمیایی",
    description:
      "اتصال داده‌ای به شبکه ریلی برای حمل حجمی مواد شیمیایی در مسیرهای داخلی و ترانزیتی.",
  },
  {
    title: "حمل دریایی و بندری",
    description:
      "هماهنگی محموله‌های کانتینری و فله از بنادر اصلی جنوب کشور تا مقاصد صادراتی.",
  },
  {
    title: "مدیریت اسناد صادراتی",
    description:
      "اظهارنامه‌های صادراتی، گواهی مبدأ، بازرسی و انطباق گمرکی در یک منبع واحد قابل ممیزی.",
  },
];

// =============================================================================
// CC-64 SECTION C — Mining & Metals (#mining) — commodities + focus areas
// =============================================================================
const MINING_COMMODITIES: { en: string; title: string }[] = [
  { en: "Iron Ore", title: "سنگ آهن" },
  { en: "Concentrate", title: "کنسانتره" },
  { en: "Steel", title: "فولاد" },
  { en: "Copper", title: "مس" },
  { en: "Aluminum", title: "آلومینیوم" },
];

const MINING_FOCUS: TextItem[] = [
  {
    title: "حمل حجیم",
    description:
      "هماهنگی حمل بارهای حجمی و سنگین از معدن و کارخانه تا انبارها و بنادر صادراتی.",
  },
  {
    title: "حمل ریلی",
    description:
      "اتصال شبکه ریلی ملی برای حمل کارآمد و کم‌هزینه محموله‌های حجمی در مسافت‌های طولانی.",
  },
  {
    title: "بنادر صادراتی",
    description:
      "هماهنگی محموله‌های صادراتی با اپراتورهای بنادر اصلی و مسیرهای دریایی منطقه.",
  },
  {
    title: "زنجیره تأمین چندوجهی",
    description:
      "ترکیب جاده، ریل و دریا روی یک منبع داده مشترک، با خط زمانی پیوسته محموله.",
  },
];

// =============================================================================
// CC-64 SECTION D — Agriculture & Food (#agriculture) — 5 items
// =============================================================================
const AGRICULTURE_ITEMS: { en: string; title: string; description: string }[] = [
  {
    en: "Grains",
    title: "غلات",
    description: "هماهنگی حمل گندم، جو و ذرت از مبدأ تولید تا انبارهای منطقه‌ای و مراکز توزیع.",
  },
  {
    en: "Inputs",
    title: "نهاده‌ها",
    description: "تأمین و توزیع نهاده‌های کشاورزی برای فصل‌های کاشت و برداشت در سراسر کشور.",
  },
  {
    en: "Fertilizers",
    title: "کود",
    description: "هماهنگی حمل کودهای شیمیایی از کارخانه به مراکز توزیع کشاورزی.",
  },
  {
    en: "Perishables",
    title: "محصولات فاسدشدنی",
    description: "دید لحظه‌ای بر زنجیره حمل محصولات حساس به زمان، با هماهنگی سفت‌وسخت زمانی.",
  },
  {
    en: "Distribution Chain",
    title: "زنجیره توزیع",
    description: "نمای یکپارچه از مبدأ تا مصرف‌کننده در شبکه‌ای از انبارها و حمل‌کنندگان همکار.",
  },
];

// =============================================================================
// CC-64 SECTION E — FMCG & Retail (#retail) — 5 pillars
// =============================================================================
const RETAIL_PILLARS: { en: string; title: string; description: string }[] = [
  {
    en: "Regional Distribution",
    title: "توزیع منطقه‌ای",
    description: "هماهنگی توزیع کالا میان مراکز توزیع منطقه‌ای و حمل‌کنندگان همکار.",
  },
  {
    en: "Warehousing",
    title: "انبار",
    description: "هماهنگی انبارهای مرکزی و منطقه‌ای، عملیات تجمیع و آماده‌سازی محموله.",
  },
  {
    en: "Cross-Dock",
    title: "Cross-Dock",
    description: "گردش کار Cross-Dock برای انتقال سریع محموله بدون نگه‌داری بلندمدت در انبار.",
  },
  {
    en: "Urban Delivery",
    title: "حمل شهری",
    description: "تأمین جریان حمل شهری از مراکز توزیع منطقه‌ای تا فروشگاه‌ها و نقاط مصرف.",
  },
  {
    en: "Store Replenishment",
    title: "تأمین فروشگاه‌ها",
    description: "هماهنگی تأمین دوره‌ای فروشگاه‌ها بر اساس برنامه سفارش و کسری انبار.",
  },
];

// =============================================================================
// CC-64 SECTION F — Transit Corridors (#transit) — 4 corridor cards
// =============================================================================
const TRANSIT_CORRIDOR_CARDS: { en: string; title: string; description: string }[] = [
  {
    en: "China → Central Asia → Iran → Europe",
    title: "چین → آسیای مرکزی → ایران → اروپا",
    description:
      "کریدور شرق-غرب — مسیر کوتاه‌تر ترانزیتی برای محموله‌های کانتینری و حجیم میان شرق آسیا و اروپا.",
  },
  {
    en: "India → Iran → CIS",
    title: "هند → ایران → CIS",
    description:
      "کریدور جنوب-شمال — اتصال هند به بازارهای CIS از مسیر بنادر جنوبی و شبکه ریلی-جاده‌ای داخلی.",
  },
  {
    en: "Persian Gulf → Caucasus → Europe",
    title: "خلیج فارس → قفقاز → اروپا",
    description:
      "اتصال بنادر اصلی جنوب به بازارهای قفقاز و اروپا با هماهنگی چندوجهی اسناد و گمرک.",
  },
  {
    en: "North-South",
    title: "شمال–جنوب",
    description:
      "کریدور بنیادی شمال به جنوب — اتصال آسیای مرکزی به خلیج فارس و اقیانوس هند از مسیر ایران.",
  },
];

// =============================================================================
// CC-64 SECTION G — Commodity Ecosystem (#commodities) — 4 taxonomy groups
// =============================================================================
const COMMODITY_TAXONOMY: {
  group: string;
  en: string;
  description: string;
  items: { en: string; fa: string }[];
}[] = [
  {
    group: "انرژی",
    en: "Energy",
    description:
      "محموله‌های انرژی، فرآورده‌های هیدروکربنی و کودهای پایه برای زنجیره صادرات.",
    items: [
      { en: "LPG", fa: "گاز مایع" },
      { en: "LNG", fa: "گاز طبیعی مایع" },
      { en: "Bitumen", fa: "قیر" },
      { en: "Methanol", fa: "متانول" },
      { en: "Urea", fa: "اوره" },
    ],
  },
  {
    group: "فلزات",
    en: "Metals",
    description: "محصولات فلزی پایه با تقاضای صنعتی و صادراتی پایدار.",
    items: [
      { en: "Steel", fa: "فولاد" },
      { en: "Copper", fa: "مس" },
      { en: "Aluminum", fa: "آلومینیوم" },
    ],
  },
  {
    group: "کشاورزی",
    en: "Agriculture",
    description: "محصولات کشاورزی پایه با چرخه‌های فصلی حمل و توزیع.",
    items: [
      { en: "Wheat", fa: "گندم" },
      { en: "Corn", fa: "ذرت" },
      { en: "Barley", fa: "جو" },
    ],
  },
  {
    group: "صنعتی",
    en: "Industrial",
    description: "محصولات معدنی و صنعتی پایه برای صنایع ساخت‌وساز و فرآوری.",
    items: [
      { en: "Cement", fa: "سیمان" },
      { en: "Clinker", fa: "کلینکر" },
      { en: "Sulfur", fa: "گوگرد" },
    ],
  },
];

// =============================================================================
// CC-64 SECTION H — Operational Scenarios (#scenarios) — 4 scenarios.
// Each follows Problem → Coordination → Execution → Visibility.
// =============================================================================
const SCENARIO_STAGES = [
  { key: "problem", label: "مسئله" },
  { key: "coordination", label: "هماهنگی" },
  { key: "execution", label: "اجرا" },
  { key: "visibility", label: "رؤیت" },
] as const;

const SCENARIOS: {
  num: string;
  en: string;
  title: string;
  problem: string;
  coordination: string;
  execution: string;
  visibility: string;
}[] = [
  {
    num: "۰۱",
    en: "Petrochemical Export",
    title: "صادرات پتروشیمی",
    problem: "محموله شیمیایی با مقصد صادراتی، الزامات گمرکی پیچیده و چندین ذی‌نفع.",
    coordination: "هماهنگی صاحب بار، فورواردر، حمل‌کننده ریلی و اپراتور بندری روی یک منبع.",
    execution: "اعزام تانکر یا کانتینر، تحویل به ریل، انتقال به بندر و بارگیری روی کشتی.",
    visibility: "پیگیری زنده وضعیت محموله از مبدأ تولید تا تخلیه در مقصد صادراتی.",
  },
  {
    num: "۰۲",
    en: "International Transit",
    title: "ترانزیت بین‌المللی",
    problem: "محموله ترانزیتی با عبور از چند مرز و سامانه گمرکی متفاوت.",
    coordination: "هماهنگی فورواردرهای دو مرز با اظهارنامه‌های ترانزیت و گواهی‌های مبدأ.",
    execution: "حمل جاده‌ای یا ریلی در کریدور، توقف در گمرک و عبور به کشور بعدی.",
    visibility: "نمای زنده عبور از مرزها، توقف‌ها و رویدادهای ترخیص در کنترل‌تاور.",
  },
  {
    num: "۰۳",
    en: "Nationwide Distribution",
    title: "توزیع سراسری کالا",
    problem: "توزیع گسترده کالا از چند انبار مرکزی به صدها فروشگاه در سراسر کشور.",
    coordination: "هماهنگی برنامه‌های توزیع، Cross-Dock و سفارش‌های روزانه شعب.",
    execution: "بارگیری از انبارهای مرکزی، حمل به انبارهای منطقه‌ای و توزیع شهری.",
    visibility: "گزارش پوشش توزیع، کسری انبار و عملکرد فروشگاه برای واحد عملیات.",
  },
  {
    num: "۰۴",
    en: "Multimodal Shipment",
    title: "حمل چندوجهی",
    problem: "محموله‌ای که برای رسیدن به مقصد به ترکیبی از جاده، ریل و دریا نیاز دارد.",
    coordination: "هماهنگی زمان‌بندی میان حمل‌کننده جاده، اپراتور ریل و کریر دریایی.",
    execution: "حمل تا ترمینال ریلی، انتقال به قطار، تحویل به بندر و بارگیری کشتی.",
    visibility: "خط زمانی پیوسته محموله در همه شیوه‌های حمل، با نقاط انتقال مسئولیت.",
  },
];

// =============================================================================
// CC-64 SECTION I — Strategic Differentiation (#differentiation)
// Comparison grid: 3 "Not" categories vs the iKIA "But" pillars.
// =============================================================================
const NOT_CATEGORIES: { en: string; title: string; description: string }[] = [
  {
    en: "Freight Marketplace",
    title: "بازار حمل ساده",
    description:
      "تطبیق بار و ظرفیت به‌تنهایی فقط بخشی از فرایند است — بدون اجرا، اسناد، تسویه و نظارت ملی.",
  },
  {
    en: "Traditional TMS",
    title: "TMS سنتی",
    description:
      "نرم‌افزار مدیریت حمل سنتی برای یک سازمان طراحی شده، نه برای اکوسیستم چندمستأجری در سطح ملی.",
  },
  {
    en: "Forwarder Software",
    title: "نرم‌افزار فورواردری",
    description:
      "ابزارهای فورواردری بر گردش کار اسناد یک ذی‌نفع تمرکز دارند، نه بر هماهنگی سراسر بازیگران زنجیره تأمین.",
  },
];

const BUT_PILLARS: string[] = [
  "ادغام بازار حمل، اجرای عملیات، رؤیت، اسناد و تسویه در یک پلتفرم واحد ملی.",
  "اتصال ساختارمند صاحبان کالا، فورواردرها، حمل‌کنندگان، رانندگان و زیرساخت گمرکی-بندری-ریلی.",
  "حافظه ممیزی کامل برای واحدهای عملیات، انطباق، مالی و حسابرسی سازمانی.",
  "معماری چندمستأجری برای پشتیبانی همزمان از ده‌ها سازمان روی یک منبع داده مشترک.",
  "زیرساخت دیجیتال ملی برای کریدورهای داخلی، بین‌المللی و ترانزیتی منطقه.",
];

// =============================================================================
// Shared inline ↓ arrow used between process cards (A / B / F).
// Inline SVG; no library; no animation.
// =============================================================================
function FlowArrow() {
  return (
    <div className="flex justify-center py-1" aria-hidden>
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        className="h-5 w-5 text-brand-500"
      >
        <line x1="12" y1="4" x2="12" y2="20" />
        <polyline points="6 14 12 20 18 14" />
      </svg>
    </div>
  );
}

export default function HomePage() {
  return (
    <div className="bg-background">
      {/* =====================================================================
          1. HERO — image 03 (corrected; iKIA logo already on truck curtain).
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
        <div className="relative mx-auto max-w-7xl px-4 py-14 sm:py-20 lg:py-24">
          <div className="grid items-center gap-10 lg:grid-cols-[1.05fr_1.15fr]">
            <div className="space-y-6 text-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-brand-100 bg-brand-50 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-brand-700">
                <span className="inline-block size-1.5 rounded-full bg-brand-500" />
                سامانه عملیات لجستیک ایران
              </div>
              <h1 className="text-3xl font-bold leading-snug tracking-tight text-deep-navy sm:text-4xl lg:text-5xl">
                سیستم عامل دیجیتال لجستیک ایران
              </h1>
              <p className="max-w-xl text-base leading-8 text-deep-navy-soft sm:text-lg">
                iKIA Logistics جریان حمل، اسناد، ظرفیت، قرارداد، ردیابی، تسویه
                و کنترل عملیات را در یک پلتفرم یکپارچه برای حمل‌ونقل داخلی،
                بین‌المللی و ترانزیت متصل می‌کند.
              </p>
              <div className="flex flex-wrap gap-3">
                <Button asChild size="lg" className="w-full sm:w-auto">
                  <Link href="/login">شروع همکاری</Link>
                </Button>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="w-full border-deep-navy/20 text-deep-navy hover:bg-deep-navy/5 sm:w-auto"
                >
                  <Link href="#how-it-works">پلتفرم چگونه کار می‌کند</Link>
                </Button>
              </div>
              <ul
                aria-label="پوشش جغرافیایی"
                className="flex flex-wrap items-center gap-2 pt-1"
              >
                <li className="text-[11px] font-semibold tracking-[0.15em] text-deep-navy-soft">
                  پوشش
                </li>
                {HERO_COVERAGE_CHIPS.map((c) => (
                  <li
                    key={c}
                    className="inline-flex items-center gap-1.5 rounded-full border border-deep-navy/10 bg-white px-3 py-1 text-[11px] font-medium text-deep-navy shadow-card"
                  >
                    <span
                      aria-hidden
                      className="inline-block size-1.5 rounded-full bg-brand-500"
                    />
                    {c}
                  </li>
                ))}
              </ul>
              <ul className="flex flex-wrap gap-2 pt-2">
                {HERO_HIGHLIGHTS.map((h) => (
                  <li
                    key={h.label}
                    className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium ${HIGHLIGHT_TONES[h.tone]}`}
                  >
                    <span
                      aria-hidden
                      className="inline-block size-1.5 rounded-full bg-current"
                    />
                    {h.label}
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
          2. TRUSTED LOGISTICS OPERATING SYSTEM INTRO.
          ===================================================================== */}
      <section className="bg-surface-muted py-16 sm:py-20">
        <div className="mx-auto max-w-7xl px-4">
          <div className="grid gap-8 lg:grid-cols-[1.2fr_1fr] lg:items-center">
            <div className="space-y-4 text-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-deep-navy/10 bg-white px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-deep-navy">
                سامانه ملی لجستیک
              </div>
              <h2 className="text-3xl font-bold leading-snug tracking-tight text-deep-navy sm:text-4xl">
                یک پلتفرم ملی برای زنجیره تأمین مدرن ایران.
              </h2>
              <p className="text-base leading-8 text-deep-navy-soft sm:text-lg sm:leading-9">
                iKIA Logistics چهار نقش عملیاتی — صاحب کالا، شرکت حمل‌ونقل،
                راننده و مدیر کنترل‌تاور — را روی یک منبع داده مشترک متصل
                می‌کند. حافظه ممیزی کامل، کنترل دسترسی نقش‌محور و میزبانی روی
                زیرساخت داخلی، تضمین امنیت، انطباق و شفافیت عملیاتی روزانه است.
              </p>
            </div>
            <ul className="grid gap-3 sm:grid-cols-2">
              {TRUST_METRICS.map((m) => (
                <li
                  key={m.label}
                  className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card"
                >
                  <div className="text-3xl font-bold tracking-tight text-deep-navy sm:text-4xl">
                    {m.value}
                  </div>
                  <div className="mt-1 text-sm font-semibold text-deep-navy">
                    {m.label}
                  </div>
                  <div className="mt-1 text-[11px] leading-6 text-muted-foreground">
                    {m.hint}
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          3. SOLUTIONS (#solutions)
          ===================================================================== */}
      <section id="solutions" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="راهکارها"
            title="iKIA چه کسانی را به هم متصل می‌کند؟"
            intro="یک منبع داده مشترک برای صاحبان کالا، شرکت‌های حمل‌ونقل، رانندگان و مدیران کنترل‌تاور — همه روی یک سیستم عامل."
          />
          <MarketingScreenshot
            src="/marketing/19-smart-integration-ikia-os-card.png"
            alt="نمای ادغام هوشمند iKIA OS — اتصال صاحبان کالا، حمل‌کنندگان، رانندگان و کنترل‌تاور"
            width={1536}
            height={1024}
            className="mt-10"
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
          4. PLATFORM CAPABILITIES (#platform)
          ===================================================================== */}
      <section id="platform" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="پلتفرم iKIA OS"
            title="شش بخش، یک سیستم عامل لجستیک کامل"
            intro="هر بخش از iKIA Logistics به‌تنهایی قدرتمند است و در کنار بقیه، یک پلتفرم عملیاتی یکپارچه می‌سازد."
          />
          <MarketingScreenshot
            src="/marketing/02-global-control-tower-dashboard-clean.png"
            alt="داشبورد سراسری iKIA OS — کنترل‌تاور و بخش‌های پلتفرم"
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
          5. LOGISTICS MARKET STRUCTURE (#market-structure)
          ===================================================================== */}
      <section id="market-structure" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="ساختار بازار"
            title="ساختار بازار لجستیک و حمل‌ونقل"
            intro="بازار لجستیک از پراکندگی عملیاتی، شکاف داده‌ای میان ذی‌نفعان و پیچیدگی هماهنگی رنج می‌برد. iKIA Logistics برای حل این چالش طراحی شده است."
          />
          <div className="mt-10 grid gap-4 sm:grid-cols-2">
            {MARKET_STRUCTURE.map((m, idx) => (
              <article
                key={m.title}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-6 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    بخش {String(idx + 1).padStart(2, "0")}
                  </div>
                  <span className="rounded-full bg-brand-50 px-3 py-1 text-[10px] font-medium text-brand-700">
                    پراکندگی عملیاتی
                  </span>
                </div>
                <h3 className="mt-3 text-lg font-bold tracking-tight text-deep-navy">
                  {m.title}
                </h3>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  {m.description}
                </p>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* =====================================================================
          6. CC-63 SECTION A — HOW iKIA WORKS (#how-it-works)
          6 process cards with inline ↓ arrows. Static. No animation.
          ===================================================================== */}
      <section id="how-it-works" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="نحوه کار پلتفرم"
            title="پلتفرم iKIA چگونه کار می‌کند؟"
            intro="شش گام منسجم برای تبدیل یک نیاز حمل به عملیات شفاف، قابل پیگیری و قابل تسویه — از ثبت نیاز تا رؤیت لحظه‌ای."
          />
          <ol className="mt-10 mx-auto max-w-2xl space-y-3">
            {HOW_IT_WORKS_STEPS.map((step, idx) => (
              <li key={step.num}>
                <div className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated">
                  <div className="flex items-center justify-between gap-3">
                    <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                      گام {step.num}
                    </div>
                    <div className="inline-flex size-8 items-center justify-center rounded-full bg-brand-500 text-xs font-bold text-white">
                      {step.num}
                    </div>
                  </div>
                  <h3 className="mt-2 text-base font-bold tracking-tight text-deep-navy">
                    {step.title}
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {step.description}
                  </p>
                </div>
                {idx < HOW_IT_WORKS_STEPS.length - 1 ? <FlowArrow /> : null}
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* =====================================================================
          7. CC-63 SECTION B — SHIPMENT LIFECYCLE (#shipment-lifecycle)
          8 states with inline ↓ arrows.
          ===================================================================== */}
      <section id="shipment-lifecycle" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="چرخه عمر محموله"
            title="چرخه عمر یک محموله"
            intro="هر محموله در iKIA Logistics مسیر مشخصی را طی می‌کند — از پیش‌نویس تا تسویه نهایی، با وضعیت روشن در هر مرحله و حافظه ممیزی کامل."
          />
          <ol className="mt-10 mx-auto max-w-2xl space-y-3">
            {SHIPMENT_LIFECYCLE.map((state, idx) => (
              <li key={state.num}>
                <div className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated">
                  <div className="flex items-center justify-between gap-3">
                    <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                      وضعیت {state.num}
                    </div>
                    <span
                      dir="ltr"
                      className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                    >
                      {state.en}
                    </span>
                  </div>
                  <h3 className="mt-2 text-base font-bold tracking-tight text-deep-navy">
                    {state.label}
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {state.description}
                  </p>
                </div>
                {idx < SHIPMENT_LIFECYCLE.length - 1 ? <FlowArrow /> : null}
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* =====================================================================
          8. CC-63 SECTION D — PLATFORM MODULES (#modules)
          8 operating modules. Purpose only — no jargon.
          ===================================================================== */}
      <section id="modules" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="ماژول‌های عملیاتی"
            title="ماژول‌های عملیاتی پلتفرم"
            intro="هشت ماژول هسته‌ای iKIA Logistics — هر یک با هدف عملیاتی روشن، طراحی‌شده برای کار مستقل و درعین‌حال کاملاً یکپارچه با بقیه."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {OPERATING_MODULES.map((m, idx) => (
              <li
                key={m.en}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    {String(idx + 1).padStart(2, "0")}
                  </div>
                  <span
                    dir="ltr"
                    className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                  >
                    {m.en}
                  </span>
                </div>
                <h3 className="mt-3 text-base font-bold tracking-tight text-deep-navy">
                  {m.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {m.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          9. NATIONAL CORRIDOR NETWORK (#corridors)
          ===================================================================== */}
      <section id="corridors" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="شبکه کریدورهای راهبردی"
            title="شبکه کریدورهای راهبردی متصل به ایران"
            intro="iKIA Logistics لایه عملیاتی دیجیتال برای کریدورهای ترانزیتی متصل به ایران است — اتصال شرق به غرب و شمال به جنوب با حمل چندوجهی و گردش کار گمرکی منسجم."
          />
          <MarketingScreenshot
            src="/marketing/15-east-west-north-south-iran-corridors.png"
            alt="شبکه کریدورهای راهبردی متصل به ایران — شرق-غرب و شمال-جنوب"
            width={1535}
            height={1024}
            className="mt-10"
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2">
            {CORRIDORS.map((c, idx) => (
              <li
                key={c.title}
                className="rounded-2xl border border-border-soft bg-card p-6 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    کریدور {String(idx + 1).padStart(2, "0")}
                  </div>
                  <div className="rounded-full bg-brand-50 px-3 py-1 text-[10px] font-medium text-brand-700">
                    {c.tag}
                  </div>
                </div>
                <h3 className="mt-3 text-lg font-bold tracking-tight text-deep-navy">
                  {c.title}
                </h3>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  {c.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          10. WHY IRAN (#why-iran)
          ===================================================================== */}
      <section id="why-iran" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="جایگاه راهبردی"
            title="ایران؛ گره اتصال تجارت منطقه‌ای"
            intro="موقعیت جغرافیایی منحصربه‌فرد ایران، آن را به یکی از کلیدی‌ترین گره‌های لجستیکی منطقه تبدیل کرده است."
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1fr_1.05fr]">
            <MarketingScreenshot
              src="/marketing/09-iran-live-route-map-clean.png"
              alt="جایگاه راهبردی ایران در شبکه تجارت منطقه‌ای"
              width={1536}
              height={1024}
            />
            <ul className="grid gap-3 sm:grid-cols-2">
              {WHY_IRAN.map((p, idx) => (
                <li
                  key={p.title}
                  className={`rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card ${
                    idx === WHY_IRAN.length - 1 ? "sm:col-span-2" : ""
                  }`}
                >
                  <div className="text-sm font-bold text-deep-navy">{p.title}</div>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {p.description}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION A — INDUSTRY SOLUTIONS HUB (#industries)
          Enterprise card grid linking to dedicated industry sections below.
          ===================================================================== */}
      <section id="industries" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="راهکارهای صنعتی"
            title="راهکارهای تخصصی برای صنایع مختلف"
            intro="iKIA برای صنایع مختلف با الگوهای عملیاتی، الزامات انطباقی و جریان‌های لجستیکی متفاوت طراحی شده است."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {INDUSTRY_HUB.map((i) => (
              <li key={i.en}>
                <Link
                  href={i.anchor}
                  className="group flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
                >
                  <div className="flex items-center justify-between">
                    <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                      {i.num}
                    </div>
                    <span
                      dir="ltr"
                      className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                    >
                      {i.en}
                    </span>
                  </div>
                  <h3 className="mt-3 text-base font-bold tracking-tight text-deep-navy group-hover:text-brand-700">
                    {i.title}
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {i.description}
                  </p>
                  <span className="mt-4 inline-flex items-center gap-1 text-[11px] font-semibold text-brand-700">
                    مشاهده جزئیات
                    <span aria-hidden>←</span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION B — OIL & PETROCHEMICAL (#oil-gas)
          Image (17) on the right, 5 pillars on the left.
          ===================================================================== */}
      <section id="oil-gas" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="نفت و پتروشیمی"
            title="زنجیره تأمین نفت، گاز و پتروشیمی"
            intro="هماهنگی صادرات، حمل تانکر، حمل ریلی شیمیایی و عملیات بندری در یک پلتفرم واحد — با گردش کار اسناد صادراتی منسجم."
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1fr_1.1fr]">
            <ul className="space-y-3 text-right">
              {OIL_GAS_PILLARS.map((p) => (
                <li
                  key={p.title}
                  className="rounded-2xl border border-border-soft bg-card p-4 shadow-card"
                >
                  <div className="flex items-start gap-2">
                    <span
                      aria-hidden
                      className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-brand-500"
                    />
                    <div>
                      <div className="text-sm font-bold text-deep-navy">{p.title}</div>
                      <p className="mt-1 text-xs leading-6 text-muted-foreground">
                        {p.description}
                      </p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
            <MarketingScreenshot
              src="/marketing/17-smart-logistics-control-center.png"
              alt="کنترل‌تاور هوشمند iKIA برای زنجیره تأمین نفت، گاز و پتروشیمی"
              width={1535}
              height={1024}
            />
          </div>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION C — MINING & METALS (#mining)
          Commodity badges row + 4 focus cards.
          ===================================================================== */}
      <section id="mining" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="معدن و فلزات"
            title="اکوسیستم لجستیک معدن و صنایع معدنی"
            intro="هماهنگی حمل حجیم سنگ آهن، کنسانتره، فولاد، مس و آلومینیوم در یک زنجیره تأمین چندوجهی متصل به بنادر صادراتی."
          />
          <ul className="mt-10 flex flex-wrap gap-2">
            {MINING_COMMODITIES.map((c) => (
              <li
                key={c.en}
                className="inline-flex items-center gap-2 rounded-full border border-brand-100 bg-brand-50 px-3 py-1.5 text-xs font-medium text-brand-700"
              >
                <span aria-hidden className="size-1.5 rounded-full bg-brand-500" />
                <span>{c.title}</span>
                <span
                  dir="ltr"
                  className="font-mono text-[10px] text-brand-700/70"
                >
                  {c.en}
                </span>
              </li>
            ))}
          </ul>
          <ul className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {MINING_FOCUS.map((f) => (
              <li
                key={f.title}
                className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="text-sm font-bold text-deep-navy">{f.title}</div>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {f.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION D — AGRICULTURE & FOOD (#agriculture)
          5 item cards.
          ===================================================================== */}
      <section id="agriculture" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="کشاورزی و مواد غذایی"
            title="لجستیک محصولات کشاورزی و غذایی"
            intro="هماهنگی زنجیره تأمین کشاورزی — از غلات و نهاده‌ها تا کود و محصولات فاسدشدنی — با تمرکز بر رؤیت و هماهنگی."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5">
            {AGRICULTURE_ITEMS.map((a) => (
              <li
                key={a.en}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <span
                  dir="ltr"
                  className="self-end rounded-full bg-deep-navy/5 px-2 py-0.5 font-mono text-[10px] text-deep-navy"
                >
                  {a.en}
                </span>
                <h3 className="mt-3 text-sm font-bold tracking-tight text-deep-navy">
                  {a.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {a.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION E — FMCG & RETAIL (#retail)
          5 pillar cards.
          ===================================================================== */}
      <section id="retail" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="کالاهای مصرفی و خرده‌فروشی"
            title="شبکه توزیع و خرده‌فروشی"
            intro="هماهنگی شبکه توزیع منطقه‌ای، انبارها، Cross-Dock و حمل شهری برای تأمین جریان پایدار فروشگاه‌ها."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5">
            {RETAIL_PILLARS.map((p, idx) => (
              <li
                key={p.en}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    {String(idx + 1).padStart(2, "0")}
                  </div>
                  <span
                    dir="ltr"
                    className="rounded-full bg-deep-navy/5 px-2 py-0.5 font-mono text-[10px] text-deep-navy"
                  >
                    {p.en}
                  </span>
                </div>
                <h3 className="mt-3 text-sm font-bold tracking-tight text-deep-navy">
                  {p.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {p.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION F — TRANSIT CORRIDORS (#transit)
          4 corridor cards (2×2 grid).
          ===================================================================== */}
      <section id="transit" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="ترانزیت بین‌المللی"
            title="عملیات ترانزیتی و کریدورهای بین‌المللی"
            intro="هماهنگی محموله‌های ترانزیتی در چهار کریدور بنیادی منطقه — از اتصال شرق به غرب تا شمال به جنوب — با اسناد یکپارچه و رؤیت پیوسته."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2">
            {TRANSIT_CORRIDOR_CARDS.map((c, idx) => (
              <li
                key={c.title}
                className="rounded-2xl border border-border-soft bg-card p-6 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    کریدور {String(idx + 1).padStart(2, "0")}
                  </div>
                  <span
                    dir="ltr"
                    className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                  >
                    {c.en}
                  </span>
                </div>
                <h3 className="mt-3 text-base font-bold tracking-tight text-deep-navy">
                  {c.title}
                </h3>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  {c.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION G — COMMODITY ECOSYSTEM (#commodities)
          Enterprise taxonomy: 4 group cards, each with EN/FA chips.
          ===================================================================== */}
      <section id="commodities" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="اکوسیستم کالاها"
            title="اکوسیستم کالاها"
            intro="دسته‌بندی سازمانی محموله‌های پشتیبانی‌شده — تاکسونومی پلتفرم برای هم‌راستاسازی صنایع، نه فهرست بازار حمل."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {COMMODITY_TAXONOMY.map((group, idx) => (
              <li
                key={group.en}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    گروه {String(idx + 1).padStart(2, "0")}
                  </div>
                  <span
                    dir="ltr"
                    className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                  >
                    {group.en}
                  </span>
                </div>
                <h3 className="mt-3 text-base font-bold tracking-tight text-deep-navy">
                  {group.group}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {group.description}
                </p>
                <ul className="mt-3 flex flex-wrap gap-1.5">
                  {group.items.map((item) => (
                    <li
                      key={item.en}
                      className="inline-flex items-center gap-1.5 rounded-full border border-brand-100 bg-brand-50 px-2 py-0.5 text-[11px] text-brand-700"
                    >
                      <span dir="ltr" className="font-mono">
                        {item.en}
                      </span>
                      <span className="text-deep-navy-soft">·</span>
                      <span>{item.fa}</span>
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION H — OPERATIONAL SCENARIOS (#scenarios)
          4 cards; each card walks Problem → Coordination → Execution → Visibility.
          ===================================================================== */}
      <section id="scenarios" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="سناریوهای عملیاتی"
            title="نمونه سناریوهای عملیاتی"
            intro="چهار الگوی عملیاتی پرتکرار — هر یک با چرخه روشن از مسئله تا رؤیت — برای نشان دادن نحوه کار پلتفرم در شرایط واقعی."
          />
          <ul className="mt-10 grid gap-5 sm:grid-cols-2">
            {SCENARIOS.map((s) => (
              <li
                key={s.en}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-6 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="flex items-center justify-between">
                  <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                    سناریو {s.num}
                  </div>
                  <span
                    dir="ltr"
                    className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                  >
                    {s.en}
                  </span>
                </div>
                <h3 className="mt-3 text-lg font-bold tracking-tight text-deep-navy">
                  {s.title}
                </h3>
                <ol className="mt-4 space-y-2">
                  {SCENARIO_STAGES.map((stage, sIdx) => (
                    <li key={stage.key}>
                      <div className="rounded-xl border border-border-soft bg-surface-muted/60 p-3">
                        <div className="flex items-center justify-between">
                          <div className="inline-flex items-center gap-2 text-[10px] font-bold uppercase tracking-[0.18em] text-brand-700">
                            <span className="inline-flex size-5 items-center justify-center rounded-full bg-brand-500 text-[10px] font-bold text-white">
                              {sIdx + 1}
                            </span>
                            {stage.label}
                          </div>
                        </div>
                        <p className="mt-1.5 text-xs leading-6 text-deep-navy">
                          {s[stage.key]}
                        </p>
                      </div>
                      {sIdx < SCENARIO_STAGES.length - 1 ? <FlowArrow /> : null}
                    </li>
                  ))}
                </ol>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          CC-64 SECTION I — STRATEGIC DIFFERENTIATION (#differentiation)
          Comparison grid: 3 Not categories vs the But pillars.
          ===================================================================== */}
      <section id="differentiation" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="تمایز راهبردی"
            title="فراتر از یک سامانه حمل"
            intro="iKIA Logistics در دسته‌بندی محصولات سنتی بازار حمل نمی‌گنجد — این پلتفرم سیستم عامل لجستیک ملی است، نه یک ابزار."
          />
          <div className="mt-10 grid gap-6 lg:grid-cols-[1fr_1.1fr]">
            <div>
              <div className="text-[11px] font-bold uppercase tracking-[0.18em] text-deep-navy-soft">
                iKIA این موارد نیست
              </div>
              <ul className="mt-4 space-y-3">
                {NOT_CATEGORIES.map((n) => (
                  <li
                    key={n.en}
                    className="rounded-2xl border border-deep-navy/10 bg-card p-4 text-right shadow-card"
                  >
                    <div className="flex items-center justify-between">
                      <span className="inline-flex items-center gap-1.5 rounded-full border border-deep-navy/10 bg-deep-navy/5 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-deep-navy">
                        <span aria-hidden>×</span>
                        نه
                      </span>
                      <span
                        dir="ltr"
                        className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                      >
                        {n.en}
                      </span>
                    </div>
                    <div className="mt-2 text-sm font-bold text-deep-navy">
                      {n.title}
                    </div>
                    <p className="mt-1 text-xs leading-6 text-muted-foreground">
                      {n.description}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
            <div
              className="rounded-3xl border-2 border-brand-500 p-6 text-right shadow-elevated"
              style={{
                background:
                  "linear-gradient(135deg, var(--color-brand-50) 0%, var(--color-surface) 80%)",
              }}
            >
              <div className="flex items-center justify-between">
                <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-500 px-2.5 py-1 text-[10px] font-bold tracking-[0.18em] text-white">
                  <span aria-hidden>✓</span>
                  بلکه
                </span>
                <span
                  dir="ltr"
                  className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                >
                  National Logistics Operating System
                </span>
              </div>
              <h3 className="mt-3 text-2xl font-bold tracking-tight text-deep-navy sm:text-3xl">
                سیستم عامل لجستیک ملی
              </h3>
              <p className="mt-2 text-sm leading-7 text-deep-navy-soft">
                یک پلتفرم واحد که بازار، اجرا، رؤیت، اسناد و تسویه را روی یک
                منبع داده مشترک متصل می‌کند — برای کل اکوسیستم زنجیره تأمین ملی.
              </p>
              <ul className="mt-4 space-y-3">
                {BUT_PILLARS.map((p) => (
                  <li
                    key={p}
                    className="flex items-start gap-2 text-sm leading-7 text-deep-navy"
                  >
                    <span
                      aria-hidden
                      className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-brand-500"
                    />
                    <span>{p}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          11. ECOSYSTEM VALUE CREATION (#ecosystem)
          ===================================================================== */}
      <section id="ecosystem" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="ارزش‌آفرینی اکوسیستم"
            title="ارزش‌آفرینی برای همه بازیگران زنجیره"
            intro="اکوسیستم iKIA Logistics ارزش متمایز برای هر یک از ذی‌نفعان زنجیره تأمین ایجاد می‌کند — از صاحبان کالا تا نهادهای حاکمیتی."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ECOSYSTEM_STAKEHOLDERS.map((s) => (
              <li
                key={s.badge}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="inline-flex items-center self-end gap-2 rounded-full bg-brand-50 px-3 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
                  {s.badge}
                </div>
                <h3 className="mt-3 text-base font-bold tracking-tight text-deep-navy">
                  {s.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {s.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          12. CC-63 SECTION C — ECOSYSTEM INTERACTION MAP (#interaction-model)
          Hub-and-spoke: iKIA Platform at the center with 7 participants
          arranged as commercial (top) + infrastructure (bottom).
          ===================================================================== */}
      <section id="interaction-model" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="مدل تعامل"
            title="تعامل بازیگران در پلتفرم"
            intro="iKIA Platform مرکز هماهنگی میان همه ذی‌نفعان زنجیره تأمین است — جریان داده‌ای منسجم میان طرفین تجاری و زیرساخت ملی روی یک منبع داده مشترک."
          />
          <div className="mt-10 space-y-6">
            {/* Commercial participants — top row (4 cards). */}
            <div>
              <div className="mb-3 text-[11px] font-bold uppercase tracking-[0.18em] text-deep-navy-soft">
                طرفین تجاری
              </div>
              <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {COMMERCIAL_PARTICIPANTS.map((p) => (
                  <li
                    key={p.en}
                    className="rounded-2xl border border-border-soft bg-card p-4 text-right shadow-card"
                  >
                    <div className="flex items-center justify-between">
                      <span
                        dir="ltr"
                        className="rounded-full bg-deep-navy/5 px-2 py-0.5 font-mono text-[10px] text-deep-navy"
                      >
                        {p.en}
                      </span>
                    </div>
                    <h3 className="mt-2 text-sm font-bold text-deep-navy">{p.title}</h3>
                    <p className="mt-1 text-xs leading-6 text-muted-foreground">
                      {p.description}
                    </p>
                  </li>
                ))}
              </ul>
            </div>

            {/* iKIA Platform — center hub card. */}
            <div
              className="mx-auto max-w-3xl rounded-3xl border-2 border-brand-500 p-6 text-center text-deep-navy shadow-elevated"
              style={{
                background:
                  "linear-gradient(135deg, var(--color-brand-50) 0%, var(--color-surface) 80%)",
              }}
            >
              <div className="inline-flex items-center gap-2 rounded-full bg-brand-500 px-3 py-1 text-[10px] font-bold tracking-[0.18em] text-white">
                مرکز هماهنگی
              </div>
              <h3 dir="ltr" className="mt-3 text-3xl font-bold tracking-tight">
                iKIA Platform
              </h3>
              <p className="mt-2 text-sm leading-7 text-deep-navy-soft">
                سیستم عامل ملی لجستیک — اتصال طرفین تجاری به زیرساخت گمرکی،
                بندری و ریلی روی یک منبع داده مشترک.
              </p>
            </div>

            {/* Infrastructure participants — bottom row (3 cards). */}
            <div>
              <div className="mb-3 text-[11px] font-bold uppercase tracking-[0.18em] text-deep-navy-soft">
                زیرساخت ملی
              </div>
              <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {INFRASTRUCTURE_PARTICIPANTS.map((p) => (
                  <li
                    key={p.en}
                    className="rounded-2xl border border-emerald-100 bg-card p-4 text-right shadow-card"
                  >
                    <div className="flex items-center justify-between">
                      <span
                        dir="ltr"
                        className="rounded-full bg-emerald-50 px-2 py-0.5 font-mono text-[10px] text-emerald-700"
                      >
                        {p.en}
                      </span>
                    </div>
                    <h3 className="mt-2 text-sm font-bold text-deep-navy">{p.title}</h3>
                    <p className="mt-1 text-xs leading-6 text-muted-foreground">
                      {p.description}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          13. PLATFORM FLYWHEEL (#flywheel)
          ===================================================================== */}
      <section id="flywheel" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="چرخه رشد"
            title="چرخه رشد پلتفرم"
            intro="iKIA Logistics از طریق یک چرخه خودتقویت‌کننده، ارزش متراکم برای تمام بازیگران زنجیره تأمین ایجاد می‌کند. هر مرحله، پایه مرحله بعد است."
          />
          <ol className="mt-10 mx-auto max-w-2xl space-y-3">
            {FLYWHEEL_STEPS.map((step, idx) => (
              <li key={step.num}>
                <div className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated">
                  <div className="flex items-center justify-between gap-3">
                    <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                      مرحله {step.num}
                    </div>
                    <div className="inline-flex size-8 items-center justify-center rounded-full bg-brand-500 text-xs font-bold text-white">
                      {step.num}
                    </div>
                  </div>
                  <h3 className="mt-2 text-base font-bold tracking-tight text-deep-navy">
                    {step.title}
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {step.description}
                  </p>
                </div>
                {idx < FLYWHEEL_STEPS.length - 1 ? <FlowArrow /> : null}
              </li>
            ))}
          </ol>
          <p className="mt-8 mx-auto max-w-2xl rounded-2xl border border-emerald-100 bg-emerald-50/60 p-4 text-right text-sm leading-7 text-emerald-800">
            این چرخه به ابتدای خود بازمی‌گردد — رشد تقاضا، صاحبان کالای بیشتری
            را وارد می‌کند و چرخه با شدت بیشتری ادامه می‌یابد.
          </p>
        </div>
      </section>

      {/* =====================================================================
          14. DOCUMENTS & COMPLIANCE (#documents)
          ===================================================================== */}
      <section id="documents" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="اسناد و تطبیق"
            title="اسناد گمرکی، تطبیق و انطباق در یک منبع منسجم"
            intro="iKIA Logistics اظهارنامه، بارنامه، بیمه و قرارداد اجراشده را با گردش کار درخواست/تأیید و حافظه ممیزی نگه‌داری می‌کند تا واحدهای عملیات، انطباق و مالی به یک حقیقت مشترک دسترسی داشته باشند."
          />
          <div className="mt-10 grid gap-6 lg:grid-cols-2">
            <MarketingScreenshot
              src="/marketing/18-security-accuracy-commitment-logistics.png"
              alt="امنیت، دقت و تعهد عملیاتی در iKIA Logistics"
              width={1536}
              height={1024}
            />
            <MarketingScreenshot
              src="/marketing/16-international-logistics-port-card.png"
              alt="خدمات بین‌المللی و ترخیص گمرکی iKIA"
              width={1535}
              height={1024}
            />
          </div>
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {DOCUMENT_BULLETS.map((d) => (
              <li
                key={d.title}
                className="rounded-2xl border border-border-soft bg-card p-4 text-right shadow-card"
              >
                <div className="text-sm font-bold text-deep-navy">{d.title}</div>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {d.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          15. CARRIER MARKETPLACE AND CAPACITY (#marketplace)
          ===================================================================== */}
      <section id="marketplace" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="بازار حمل"
            title="بازار ظرفیت حمل‌ونقل چندوجهی"
            intro="انتشار ظرفیت، پذیرش رزرو و چرخه اعزام منسجم در پنج شیوه حمل — از جاده‌ای و دریایی تا ریلی، هوایی و انبارداری."
          />
          {/* CC-65 — TRANSPORT_SERVICES rendered as a CSS marquee strip
              instead of a static grid. Pure CSS animation (see
              `.ikia-marquee-track` in globals.css); no client JS. */}
          <MarketingMarquee
            ariaLabel="نوار اسلاید خدمات حمل‌ونقل iKIA"
            className="mt-10"
            cardWidthClassName="w-[280px] sm:w-[320px] lg:w-[360px]"
          >
            {TRANSPORT_SERVICES.map((s) => (
              <TransportServiceCard
                key={s.title}
                visual={
                  <MarketingImageFill
                    src={s.src}
                    alt={s.alt}
                    sizes="(max-width: 640px) 280px, (max-width: 1024px) 320px, 360px"
                  />
                }
                title={s.title}
                description={s.description}
                tags={s.tags}
              />
            ))}
          </MarketingMarquee>
        </div>
      </section>

      {/* =====================================================================
          16. SETTLEMENT AND DISPUTE CONTROL (#settlement)
          ===================================================================== */}
      <section id="settlement" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="تسویه و کنترل اختلاف"
            title="تسویه ساختارمند با حساب امانی و گردش کار اختلاف"
            intro="از صدور فاکتور تا حساب امانی و گردش کار اختلاف، iKIA چرخه مالی را برای واحدهای عملیات و مالی قابل ممیزی می‌کند."
          />
          <div className="mt-10 grid items-center gap-8 lg:grid-cols-[1.1fr_1fr]">
            <MarketingScreenshot
              src="/marketing/04-enterprise-control-room-analytics-clean.png"
              alt="نمای تحلیل سازمانی iKIA برای واحد مالی و عملیات"
              width={1672}
              height={941}
            />
            <ul className="space-y-3 text-right">
              {SETTLEMENT_BULLETS.map((b) => (
                <li
                  key={b}
                  className="flex items-start gap-2 rounded-xl border border-border-soft bg-card p-3 shadow-card"
                >
                  <span
                    aria-hidden
                    className="mt-1.5 inline-block size-1.5 shrink-0 rounded-full bg-brand-500"
                  />
                  <span className="text-sm leading-7 text-deep-navy">{b}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* =====================================================================
          17. CC-63 SECTION E — DIGITAL CONTROL TOWER NARRATIVE (#control-tower)
          Dark slab. Pure narrative, no screenshots, 4 pillars.
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
            eyebrow="برج کنترل دیجیتال"
            title="برج کنترل دیجیتال زنجیره تأمین"
            intro="iKIA Control Tower یک منبع واحد حقیقت برای همه ذی‌نفعان زنجیره تأمین است — برای دیدن، تصمیم گرفتن و عمل کردن، در سطح ملی و کریدور."
            tone="dark"
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2">
            {CONTROL_TOWER_PILLARS.map((p, idx) => (
              <li
                key={p.title}
                className="rounded-2xl border border-white/10 bg-white/5 p-5 text-right backdrop-blur-md"
              >
                <div className="text-[10px] font-bold tracking-[0.18em] text-brand-100">
                  پایه {String(idx + 1).padStart(2, "0")}
                </div>
                <h3 className="mt-2 text-lg font-bold tracking-tight text-night-text">
                  {p.title}
                </h3>
                <p className="mt-2 text-sm leading-7 text-night-text-muted">
                  {p.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          18. CC-63 SECTION F — DATA FLOW (#data-flow) — 6 stages
          ===================================================================== */}
      <section id="data-flow" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="جریان داده"
            title="جریان داده در پلتفرم"
            intro="داده در iKIA Logistics از سفارش تا تصمیم‌سازی، در یک جریان منسجم و قابل ممیزی حرکت می‌کند — هر مرحله ورودی مرحله بعد است."
          />
          <ol className="mt-10 mx-auto max-w-2xl space-y-3">
            {DATA_FLOW_STAGES.map((stage, idx) => (
              <li key={stage.num}>
                <div className="rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated">
                  <div className="flex items-center justify-between gap-3">
                    <div className="text-[10px] font-bold tracking-[0.18em] text-brand-700">
                      مرحله {stage.num}
                    </div>
                    <span
                      dir="ltr"
                      className="rounded-full bg-deep-navy/5 px-2.5 py-0.5 font-mono text-[10px] text-deep-navy"
                    >
                      {stage.en}
                    </span>
                  </div>
                  <h3 className="mt-2 text-base font-bold tracking-tight text-deep-navy">
                    {stage.title}
                  </h3>
                  <p className="mt-1 text-xs leading-6 text-muted-foreground">
                    {stage.description}
                  </p>
                </div>
                {idx < DATA_FLOW_STAGES.length - 1 ? <FlowArrow /> : null}
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* =====================================================================
          19. OPERATING SYSTEM POSITIONING (#operating-system)
          ===================================================================== */}
      <section id="operating-system" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="جایگاه پلتفرم"
            title="فراتر از یک بازار حمل"
            intro="iKIA Logistics فقط یک نرم‌افزار حمل، بازار ظرفیت یا ابزار ردیابی نیست. این پلتفرم، سیستم عامل لجستیک ملی برای کل چرخه عملیاتی زنجیره تأمین است."
          />
          <div className="mt-10 grid gap-8 lg:grid-cols-[1fr_1.15fr]">
            <div>
              <div className="text-[11px] font-bold uppercase tracking-[0.18em] text-deep-navy-soft">
                نه فقط این موارد
              </div>
              <ul className="mt-4 space-y-3">
                {OS_NOT_PILLARS.map((n) => (
                  <li
                    key={n.title}
                    className="rounded-2xl border border-deep-navy/10 bg-card p-4 text-right shadow-card"
                  >
                    <div className="text-sm font-bold text-deep-navy">{n.title}</div>
                    <p className="mt-1 text-xs leading-6 text-muted-foreground">
                      {n.description}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
            <div
              className="rounded-3xl border border-brand-100 p-6 text-right shadow-elevated"
              style={{
                background:
                  "linear-gradient(135deg, var(--color-brand-50) 0%, var(--color-surface) 80%)",
              }}
            >
              <div className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-700">
                بلکه این هست
              </div>
              <h3 className="mt-2 text-2xl font-bold tracking-tight text-deep-navy sm:text-3xl">
                سیستم عامل لجستیک ملی
              </h3>
              <ul className="mt-4 space-y-3">
                {OS_PILLARS.map((p) => (
                  <li
                    key={p}
                    className="flex items-start gap-2 text-sm leading-7 text-deep-navy"
                  >
                    <span
                      aria-hidden
                      className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-brand-500"
                    />
                    <span>{p}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* =====================================================================
          20. REVENUE ARCHITECTURE (#economics-model)
          ===================================================================== */}
      <section id="economics-model" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="اقتصاد پلتفرم"
            title="معماری اقتصادی پلتفرم"
            intro="iKIA Logistics بر اساس یک مدل اقتصاد پلتفرم چندلایه طراحی شده که ارزش پایدار از طریق پنج جریان مرتبط ایجاد می‌کند — بدون پیش‌بینی مالی یا ادعای رقمی."
          />
          <ol className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            {REVENUE_BLOCKS.map((b) => (
              <li
                key={b.num}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="inline-flex items-center self-end gap-2 rounded-full bg-brand-50 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
                  {b.num}
                </div>
                <h3 className="mt-3 text-sm font-bold tracking-tight text-deep-navy">
                  {b.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {b.description}
                </p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* =====================================================================
          21. INVESTMENT READINESS NARRATIVE (#future)
          ===================================================================== */}
      <section id="future" className="bg-surface-muted py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="نسل آینده زیرساخت"
            title="زیرساخت دیجیتال نسل آینده لجستیک"
            intro="iKIA Logistics زیرساختی است که هم‌اکنون عملیاتی است و برای رشد در پنج محور کلیدی طراحی شده — همگی برای ارزش بلندمدت اکوسیستم."
          />
          <ol className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            {FUTURE_THEMES.map((t) => (
              <li
                key={t.num}
                className="flex h-full flex-col rounded-2xl border border-brand-100 bg-white p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="inline-flex items-center self-end gap-2 rounded-full bg-brand-500 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-white">
                  محور {t.num}
                </div>
                <h3 className="mt-3 text-sm font-bold tracking-tight text-deep-navy">
                  {t.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {t.description}
                </p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* =====================================================================
          22. CC-63 SECTION G — ENTERPRISE READINESS (#enterprise-readiness)
          Business language only. 5 pillars.
          ===================================================================== */}
      <section id="enterprise-readiness" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <PremiumSectionHeader
            eyebrow="آمادگی سازمانی"
            title="آماده برای عملیات در مقیاس سازمانی"
            intro="iKIA Logistics از پایه برای سازمان‌هایی طراحی شده که به امنیت، انطباق و قابلیت مقیاس‌پذیری بالا نیاز دارند — همراه با حافظه ممیزی کامل و معماری چندمستأجری."
          />
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            {ENTERPRISE_PILLARS.map((p) => (
              <li
                key={p.num}
                className="flex h-full flex-col rounded-2xl border border-border-soft bg-card p-5 text-right shadow-card transition-shadow hover:shadow-elevated"
              >
                <div className="inline-flex items-center self-end gap-2 rounded-full bg-brand-50 px-2.5 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
                  {p.num}
                </div>
                <h3 className="mt-3 text-sm font-bold tracking-tight text-deep-navy">
                  {p.title}
                </h3>
                <p className="mt-1 text-xs leading-6 text-muted-foreground">
                  {p.description}
                </p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* =====================================================================
          23. CC-63 SECTION H — FINAL CTA REFRESH (#start)
          Same image / same routes. New headline + new subhead.
          ===================================================================== */}
      <section id="start" className="py-20 sm:py-28 scroll-mt-16">
        <div className="mx-auto max-w-7xl px-4">
          <div
            className="relative overflow-hidden rounded-3xl border border-border-soft"
            style={{ boxShadow: "var(--shadow-elevated)" }}
          >
            <div className="relative aspect-[4/5] w-full sm:aspect-[16/9] lg:aspect-[16/7]">
              <MarketingImageFill
                src="/marketing/01-hero-multimodal-transport-clean.png"
                alt="نمای چندوجهی پایانی iKIA — جاده، دریا، ریل و هوا"
                sizes="(max-width: 1024px) 100vw, 1200px"
              />
              <div
                aria-hidden
                className="absolute inset-0"
                style={{
                  background:
                    "linear-gradient(90deg, oklch(0.18 0.04 250 / 0.88) 0%, oklch(0.18 0.04 250 / 0.55) 65%, transparent 100%)",
                }}
              />
              <div className="absolute inset-0 flex items-center">
                <div className="mx-auto w-full max-w-7xl px-6 sm:px-10">
                  <div className="max-w-3xl space-y-4 text-right text-night-text">
                    <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-night-text backdrop-blur-md">
                      گفت‌وگوی راهبردی
                    </div>
                    <h2 className="text-2xl font-bold leading-snug tracking-tight sm:text-3xl lg:text-4xl">
                      زیرساخت دیجیتال برای نسل جدید لجستیک
                    </h2>
                    <p className="text-sm leading-7 text-night-text-muted sm:text-base sm:leading-8">
                      iKIA Logistics برای صنایع راهبردی، کریدورهای ترانزیتی و
                      اکوسیستم کالاهای ملی طراحی شده است. وارد گفت‌وگوی همکاری
                      شوید و عملیات سازمانی خود را در یک پلتفرم واحد یکپارچه
                      کنید.
                    </p>
                    <div className="flex flex-wrap gap-2 pt-1">
                      <Button asChild size="lg" className="w-full sm:w-auto">
                        <Link href="/login">درخواست جلسه معرفی</Link>
                      </Button>
                      <Button
                        asChild
                        variant="outline"
                        size="lg"
                        className="w-full border-white/30 bg-transparent text-night-text hover:bg-white/10 hover:text-night-text sm:w-auto"
                      >
                        <Link href="/login">شروع همکاری راهبردی</Link>
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
