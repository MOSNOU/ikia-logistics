import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { MarketingImageFill } from "@/components/marketing/marketing-image-fill";
import { MarketingScreenshot } from "@/components/marketing/marketing-screenshot";
import { PremiumSectionHeader } from "@/components/marketing/premium-section-header";
import {
  ServiceImageSlider,
  type ServiceSlide,
} from "@/components/marketing/service-image-slider";
import { StakeholderSolutionCard } from "@/components/marketing/stakeholder-solution-card";

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

// CC-66C — Removed HERO_HIGHLIGHTS, HIGHLIGHT_TONES, HERO_COVERAGE_CHIPS.
// The fullscreen cinematic hero no longer renders the highlight chips or
// coverage chip strip, so the data arrays are dead.

// CC-Phase3 — Trust strip realigned to the design guide §13 operational
// metrics: 24/7 visibility · 4 modes · 8 lifecycle states · 1 OS.
const TRUST_METRICS: { label: string; value: string; hint: string }[] = [
  { label: "رؤیت لحظه‌ای", value: "۲۴/۷", hint: "نمای زنده محموله، اسناد و وضعیت عملیات" },
  { label: "شیوه حمل متصل", value: "۴", hint: "جاده‌ای، دریایی، ریلی و هوایی" },
  { label: "وضعیت چرخه عمر", value: "۸", hint: "از پیش‌نویس تا تسویه" },
  { label: "سیستم عامل لجستیک", value: "۱", hint: "بازار، اجرا، اسناد و تسویه یکپارچه" },
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

// CC-68 — Platform modules realigned to the 6 product capabilities
// expected by the rebuilt #platform section. Each carries an English
// code chip used in the new product-card layout.
const PLATFORM_MODULES: { en: string; title: string; description: string }[] = [
  {
    en: "Control Tower",
    title: "کنترل‌تاور",
    description: "دید لحظه‌ای بر محموله، اعزام، نشست تله‌متری و استثنا — روی یک منبع داده مشترک.",
  },
  {
    en: "Freight Marketplace",
    title: "بازار حمل",
    description: "تطبیق ساختارمند ظرفیت حمل‌کنندگان با تقاضای بار، در پنج شیوه حمل و در یک بازار شفاف.",
  },
  {
    en: "Documents & Compliance",
    title: "اسناد و تطبیق",
    description: "اظهارنامه، بارنامه، بیمه و گواهی‌های انطباق با گردش کار درخواست/تأیید و حافظه ممیزی.",
  },
  {
    en: "Route Intelligence",
    title: "هوش مسیر",
    description: "تحلیل کریدورها، مسیرها و رفتار ناوگان برای تصمیم‌سازی عملیاتی و تأخیرشناسی.",
  },
  {
    en: "Settlement",
    title: "تسویه و صورتحساب",
    description: "صدور فاکتور، حساب امانی و آزادسازی مرحله‌ای — همراه با گردش کار اختلاف.",
  },
  {
    en: "Partner Portal",
    title: "پرتال همکاران",
    description: "پرتال اختصاصی برای حمل‌کنندگان، فورواردرها و رانندگان — با کنترل دسترسی نقش‌محور.",
  },
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

// CC-68 — Status tone for each lifecycle stage. Index aligns with
// SHIPMENT_LIFECYCLE. Translucent chips read cleanly on the new
// .ikia-section-dark navy backdrop.
const LIFECYCLE_TONES: { dot: string; chip: string }[] = [
  { dot: "bg-slate-400",   chip: "border-white/15 bg-white/10 text-slate-200" },        // Draft
  { dot: "bg-sky-400",     chip: "border-sky-400/30 bg-sky-400/10 text-sky-200" },      // Published
  { dot: "bg-sky-400",     chip: "border-sky-400/30 bg-sky-400/10 text-sky-200" },      // Matched
  { dot: "bg-indigo-400",  chip: "border-indigo-400/30 bg-indigo-400/10 text-indigo-200" }, // Booked
  { dot: "bg-cyan-400",    chip: "border-cyan-400/30 bg-cyan-400/10 text-cyan-200" },   // Dispatched
  { dot: "bg-amber-400",   chip: "border-amber-400/30 bg-amber-400/10 text-amber-200" },// In Transit
  { dot: "bg-emerald-400", chip: "border-emerald-400/30 bg-emerald-400/10 text-emerald-200" }, // Delivered
  { dot: "bg-emerald-500", chip: "border-emerald-500/30 bg-emerald-500/15 text-emerald-100" }, // Closed
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

// CC-66B — Service slides for the auto-advancing marketplace slider.
// Replaces the previous TRANSPORT_SERVICES array and its now-retired
// 10–14 PNG references. All 5 v2 images are used, in the order requested
// by the brief: warehousing → air → rail → sea → road.
const SERVICE_ICON_CLASS = "h-7 w-7";

const SERVICE_SLIDES: ServiceSlide[] = [
  {
    image: "/marketing/service-warehousing-v2.png",
    alt: "نمای انبار و عملیات انبارداری iKIA Logistics",
    title: "خدمات انبارداری",
    description:
      "ظرفیت انبار، آماده‌سازی سفارش، کنترل موجودی و اتصال به جریان حمل در یک زنجیره عملیاتی.",
    pills: ["انبار اختصاصی", "کنترل موجودی", "آماده‌سازی سفارش"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <path d="M3 9.5 12 4l9 5.5V21H3z" />
        <path d="M8 21v-6h8v6" />
        <path d="M8 13h8" />
      </svg>
    ),
  },
  {
    image: "/marketing/service-air-freight-v2.png",
    alt: "محموله هوایی در فرودگاه — خدمات حمل هوایی iKIA Logistics",
    title: "حمل هوایی",
    description:
      "راهکار سریع برای محموله‌های حساس، زمان‌محور و ارزشمند با کنترل وضعیت و اسناد.",
    pills: ["زمان تحویل کوتاه", "محموله حساس", "ردیابی وضعیت"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <path d="M21 12c0-1-.6-2-1.5-2H15L10 3H8l2.5 7H6l-2-2H2.5L4 12l-1.5 2H4l2-2h4.5L8 19h2l5-7h4.5c.9 0 1.5-1 1.5-2z" />
      </svg>
    ),
  },
  {
    image: "/marketing/service-rail-freight-v2.png",
    alt: "قطار باری در کریدور ریلی — خدمات حمل ریلی iKIA Logistics",
    title: "حمل ریلی",
    description:
      "حمل پایدار، اقتصادی و مناسب مسیرهای پرتکرار، سنگین و کریدوری در شبکه ریلی.",
    pills: ["ظرفیت بالا", "مسیر کریدوری", "هزینه بهینه"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <rect x="5" y="3" width="14" height="14" rx="3" />
        <path d="M5 11h14" />
        <circle cx="9" cy="14.5" r="1" />
        <circle cx="15" cy="14.5" r="1" />
        <path d="M7 21l2-3M17 21l-2-3" />
      </svg>
    ),
  },
  {
    image: "/marketing/service-sea-freight-v2.png",
    alt: "کشتی کانتینری در بندر — خدمات حمل دریایی iKIA Logistics",
    title: "حمل دریایی",
    description:
      "مدیریت جریان کانتینری و فله برای تجارت بین‌المللی، بنادر و زنجیره اسناد.",
    pills: ["کانتینری", "فله", "اسناد بندری"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <path d="M12 3v8" />
        <path d="M6 11h12l-2 6H8z" />
        <path d="M3 19c2 1 4 1 6 0s4-1 6 0 4 1 6 0" />
      </svg>
    ),
  },
  {
    image: "/marketing/service-road-freight-v2.png",
    alt: "ناوگان جاده‌ای iKIA در کریدور حمل — خدمات حمل جاده‌ای",
    title: "حمل جاده‌ای",
    description:
      "اتصال ناوگان، راننده، بارنامه، مسیر و تحویل نهایی برای حمل داخلی و بین‌المللی.",
    pills: ["داخلی", "بین‌المللی", "تحویل نهایی"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <rect x="2" y="7" width="12" height="9" rx="1.5" />
        <path d="M14 10h4l3 4v2h-7z" />
        <circle cx="7" cy="18" r="2" />
        <circle cx="17" cy="18" r="2" />
      </svg>
    ),
  },
  // CC-Phase2 — 6th slide added per design guide §12. Reuses image 18
  // (security/accuracy/commitment) since there is no dedicated customs
  // image yet; the overlay copy makes the customs framing explicit.
  {
    image: "/marketing/18-security-accuracy-commitment-logistics.png",
    alt: "اسناد و انطباق گمرکی iKIA — خدمات گمرک و تطبیق",
    title: "گمرک و تطبیق",
    description:
      "مدیریت اظهارنامه، گواهی مبدأ، انطباق گمرکی و گردش کار اسناد بین‌المللی در یک منبع.",
    pills: ["اظهارنامه", "گواهی مبدأ", "ترخیص"],
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={SERVICE_ICON_CLASS}
        aria-hidden
      >
        <path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z" />
        <path d="M9 12l2 2 4-4" />
      </svg>
    ),
  },
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
// CC-Phase2 — Industries hub (consolidated). The 5 dedicated CC-64
// industry sections (#oil-gas, #mining, #agriculture, #retail,
// #transit) have been folded into this single hub of 6 compact cards
// per the design guide §15. The hub now uses an inline line icon per
// industry. No external links — cards are self-contained.
// =============================================================================
const INDUSTRY_ICON_CLASS = "h-6 w-6";

const INDUSTRY_HUB: {
  num: string;
  en: string;
  title: string;
  description: string;
  icon: React.ReactNode;
}[] = [
  {
    num: "۰۱",
    en: "Steel & Mining",
    title: "فولاد و معدن",
    description:
      "حمل حجمی سنگ آهن، کنسانتره، فولاد، مس و آلومینیوم در کریدورهای داخلی و صادراتی.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <path d="M3 20l5-9 3 5 4-7 6 11z" />
        <circle cx="14" cy="6" r="1.5" />
      </svg>
    ),
  },
  {
    num: "۰۲",
    en: "Oil & Petrochemical",
    title: "نفت و پتروشیمی",
    description:
      "صادرات پتروشیمی، حمل تانکر و عملیات بندری با گردش کار اسناد و انطباق گمرکی.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <path d="M12 3c2.5 4 4 6.5 4 9a4 4 0 1 1-8 0c0-2.5 1.5-5 4-9z" />
      </svg>
    ),
  },
  {
    num: "۰۳",
    en: "Agriculture & Food",
    title: "کشاورزی و مواد غذایی",
    description:
      "هماهنگی حمل غلات، نهاده‌ها، کود و محصولات فاسدشدنی در زنجیره توزیع ملی.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <path d="M12 21V8" />
        <path d="M8 8l4-4 4 4" />
        <path d="M7 12c2 0 4 1 5 3" />
        <path d="M17 12c-2 0-4 1-5 3" />
        <path d="M7 17c2 0 4 1 5 3" />
        <path d="M17 17c-2 0-4 1-5 3" />
      </svg>
    ),
  },
  {
    num: "۰۴",
    en: "FMCG & Retail",
    title: "کالاهای مصرفی",
    description:
      "توزیع منطقه‌ای، Cross-Dock، حمل شهری و تأمین فروشگاه‌ها در شبکه ملی.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <path d="M4 9h16l-1 11H5z" />
        <path d="M9 9V6a3 3 0 1 1 6 0v3" />
      </svg>
    ),
  },
  {
    num: "۰۵",
    en: "Industrial Projects",
    title: "پروژه‌های صنعتی",
    description:
      "حمل تجهیزات حجمی، سازه‌ها و محموله‌های پروژه‌ای با هماهنگی چندوجهی و انطباق.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <path d="M3 21h18" />
        <path d="M5 21V11l5-3v13" />
        <path d="M10 21V8l5-3v16" />
        <path d="M15 21V5l5-2v18" />
        <path d="M7 14h1M7 17h1M12 11h1M12 14h1M12 17h1M17 8h1M17 11h1M17 14h1M17 17h1" />
      </svg>
    ),
  },
  {
    num: "۰۶",
    en: "Export & Import",
    title: "صادرات و واردات",
    description:
      "هماهنگی واردات و صادرات با گمرک، اسناد بین‌المللی و انطباق چندلایه در مرزها.",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={INDUSTRY_ICON_CLASS} aria-hidden>
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18" />
        <path d="M12 3a13 13 0 0 1 0 18a13 13 0 0 1 0-18z" />
      </svg>
    ),
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
    <div className="bg-ikia-premium-page">
      {/* =====================================================================
          CC-66C — Fullscreen cinematic hero.
          • Edge-to-edge image at /marketing/01-hero-fullscreen-clean.png.
          • Sits directly below the sticky 64-px header.
          • Subtle navy gradient + bottom porcelain fade for premium depth.
          • Minimal text overlay (no chips, no metrics, no widgets) — extra
            data overlays will land in a later CC.
          ===================================================================== */}
      <section
        aria-labelledby="hero-headline"
        className="relative isolate ikia-hero-bottom-fade overflow-hidden min-h-[72vh] lg:min-h-[calc(100vh-64px)]"
      >
        <Image
          src="/marketing/01-hero-fullscreen-clean.png"
          alt="ناوگان چندوجهی iKIA Logistics — کریدور ملی حمل‌ونقل ایران"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center"
        />
        {/* Side-to-side overlay: deepest at the right (Persian start edge),
            fading toward the left for image clarity. */}
        <div
          aria-hidden
          className="absolute inset-0"
          style={{
            background:
              "linear-gradient(270deg, rgba(2, 6, 23, 0.62) 0%, rgba(15, 23, 42, 0.30) 42%, rgba(15, 23, 42, 0.08) 100%)",
          }}
        />
        {/* CC-66D — Hero content moved to the visual right (items-start in
            RTL = inline-start = right edge), wrapped in a localized glass
            text card so the headline pops without over-darkening the
            whole image. Brighter typography + green/red CTAs. */}
        <div className="relative mx-auto flex h-full min-h-[72vh] max-w-7xl flex-col items-start justify-center px-4 py-20 sm:px-6 lg:min-h-[calc(100vh-64px)] lg:py-28">
          <div className="w-full max-w-xl rounded-[2rem] border border-white/15 bg-slate-950/25 p-5 text-right shadow-2xl shadow-slate-950/30 backdrop-blur-[2px] sm:p-7">
            <div className="space-y-5">
              <div className="inline-flex items-center gap-2 rounded-full border border-white/30 bg-slate-950/30 px-3 py-1 text-[11px] font-semibold tracking-[0.15em] text-white backdrop-blur-md">
                <span aria-hidden className="inline-block size-1.5 rounded-full bg-emerald-400" />
                سامانه عملیات لجستیک ایران
              </div>
              <h1
                id="hero-headline"
                className="text-3xl font-extrabold leading-snug tracking-tight text-white sm:text-5xl lg:text-6xl"
                style={{ textShadow: "0 4px 32px rgba(0, 0, 0, 0.75)" }}
              >
                سامانه عملیاتی لجستیک برای کنترل حمل، اسناد و زنجیره تأمین
              </h1>
              <p
                className="max-w-lg text-base leading-8 text-white/90 sm:text-lg"
                style={{ textShadow: "0 2px 18px rgba(0, 0, 0, 0.7)" }}
              >
                از ثبت سفارش تا تخصیص ناوگان، رهگیری، اسناد گمرکی، تطبیق و تسویه
                — همه در یک پلتفرم واحد برای بازار ایران و کریدورهای منطقه‌ای.
              </p>
              <div className="flex flex-wrap gap-3 pt-2">
                <Button
                  asChild
                  size="lg"
                  className="w-full bg-gradient-to-l from-emerald-600 via-green-500 to-lime-400 text-white shadow-lg shadow-emerald-950/30 hover:from-emerald-700 hover:via-green-600 hover:to-lime-500 sm:w-auto"
                >
                  <Link href="/#start">درخواست جلسه معرفی</Link>
                </Button>
                <Button
                  asChild
                  size="lg"
                  className="w-full border border-red-300/60 bg-gradient-to-l from-red-700 via-rose-600 to-orange-500 text-white shadow-lg shadow-red-950/25 hover:from-red-800 hover:via-rose-700 hover:to-orange-600 sm:w-auto"
                >
                  <Link href="/login">ورود به پلتفرم</Link>
                </Button>
              </div>
            </div>
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
              <p className="text-sm font-semibold leading-7 text-deep-navy/80">
                طراحی‌شده برای شرکت‌های صنعتی، بازرگانی، حمل‌ونقل و فعالان
                کریدورهای منطقه‌ای.
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
            title="یک پلتفرم عملیاتی برای کنترل کل زنجیره حمل"
            intro="شش بخش هسته‌ای — هر یک مستقل و قدرتمند؛ در کنار هم یک سیستم عامل لجستیک ملی برای صنایع، فورواردرها و حمل‌کنندگان."
          />
          <MarketingScreenshot
            src="/marketing/02-global-control-tower-dashboard-clean.png"
            alt="داشبورد سراسری iKIA OS — کنترل‌تاور و بخش‌های پلتفرم"
            width={1535}
            height={1024}
            className="mt-10"
          />
          {/* CC-Phase3 — Each platform module card now ends with a
              «مشاهده ←» text link routing to the most relevant existing
              section anchor, and lifts on hover via .ikia-hover-lift. */}
          <ul className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {PLATFORM_MODULES.map((m, idx) => {
              const moduleHref: Record<string, string> = {
                "Control Tower": "#control-tower",
                "Freight Marketplace": "#marketplace",
                "Documents & Compliance": "#documents",
                "Route Intelligence": "#corridors",
                "Settlement": "#settlement",
                "Partner Portal": "#solutions",
              };
              const href = moduleHref[m.en] ?? "#platform";
              return (
                <li key={m.en}>
                  <article className="bg-ikia-product-card ikia-hover-lift flex h-full flex-col p-6 text-right">
                    <div className="flex items-center justify-between">
                      <div className="text-[10px] font-bold tracking-[0.22em] text-sky-700">
                        ماژول {String(idx + 1).padStart(2, "0")}
                      </div>
                      <span
                        dir="ltr"
                        className="rounded-full border border-sky-200 bg-sky-50 px-2.5 py-0.5 font-mono text-[10px] font-semibold text-sky-700"
                      >
                        {m.en}
                      </span>
                    </div>
                    <h3 className="mt-3 text-lg font-extrabold tracking-tight text-deep-navy">
                      {m.title}
                    </h3>
                    <p className="mt-2 text-sm leading-7 text-slate-600">
                      {m.description}
                    </p>
                    <Link
                      href={href}
                      className="mt-4 inline-flex items-center gap-1 text-[12px] font-semibold text-sky-700 transition-colors hover:text-sky-900"
                    >
                      مشاهده
                      <span aria-hidden>←</span>
                    </Link>
                  </article>
                </li>
              );
            })}
          </ul>
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
      {/* CC-Phase2 — Lifecycle simplified to a clean 8-state timeline
          rail. The dashboard chrome, route row, doc compliance row, and
          metric strip moved to #control-tower (the standalone product
          dashboard section) per design guide §11. Section stays dark
          for rhythm but reads leaner. */}
      <section
        id="shipment-lifecycle"
        className="ikia-section-dark py-20 sm:py-28 scroll-mt-16"
      >
        <div className="mx-auto max-w-7xl px-4">
          <div className="grid gap-10 lg:grid-cols-[1fr_1.4fr] lg:items-start lg:gap-16">
            {/* Right column — narrative + CTA. */}
            <div className="space-y-5 text-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-sky-400/30 bg-sky-400/10 px-3 py-1 text-[11px] font-semibold tracking-[0.22em] text-sky-200">
                <span aria-hidden className="inline-block size-1.5 rounded-full bg-sky-400" />
                Shipment Lifecycle
              </div>
              <h2 className="text-3xl font-extrabold leading-snug tracking-tight text-night-text sm:text-4xl lg:text-[44px]">
                هر محموله، یک خط حرکت روشن از پیش‌نویس تا تسویه
              </h2>
              <p className="max-w-xl text-base leading-8 text-night-text-muted sm:text-lg sm:leading-9">
                هر محموله در iKIA Logistics از طریق هشت وضعیت قابل پیگیری
                مدیریت می‌شود — روی یک منبع داده مشترک، با گردش کار شفاف برای
                واحدهای عملیات، انطباق و مالی.
              </p>
              <div className="flex flex-wrap gap-3 pt-2">
                <Button
                  asChild
                  size="lg"
                  className="bg-gradient-to-l from-emerald-600 via-green-500 to-lime-400 text-white shadow-lg shadow-emerald-950/30 hover:from-emerald-700 hover:via-green-600 hover:to-lime-500"
                >
                  <Link href="/#start">درخواست جلسه معرفی</Link>
                </Button>
                <Button
                  asChild
                  size="lg"
                  variant="outline"
                  className="border-white/30 bg-white/5 text-night-text backdrop-blur hover:border-sky-300 hover:bg-white/10 hover:text-night-text"
                >
                  <Link href="#control-tower">برج کنترل دیجیتال</Link>
                </Button>
              </div>
            </div>

            {/* Left column — clean 8-state timeline rail (only). */}
            <div className="ikia-product-card-dark p-5 sm:p-6">
              <div className="mb-5 flex items-center justify-between gap-3">
                <div
                  dir="ltr"
                  className="font-mono text-[10px] font-bold uppercase tracking-[0.22em] text-night-text-muted"
                >
                  Shipment Lifecycle · ۸ مرحله
                </div>
                <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-400/30 bg-sky-400/10 px-2 py-0.5 text-[10px] font-semibold text-sky-200">
                  هشت وضعیت
                </span>
              </div>
              <ol className="relative space-y-2.5">
                {SHIPMENT_LIFECYCLE.map((state, idx) => {
                  const tone =
                    LIFECYCLE_TONES[idx] ?? LIFECYCLE_TONES[0]!;
                  const isLast = idx === SHIPMENT_LIFECYCLE.length - 1;
                  return (
                    <li key={state.num} className="relative ps-9">
                      {!isLast ? (
                        <span
                          aria-hidden
                          className="absolute start-[10px] top-5 h-[calc(100%+0.25rem)] w-px bg-white/10"
                        />
                      ) : null}
                      <span
                        aria-hidden
                        className={`absolute start-1.5 top-[14px] size-3 rounded-full ring-4 ring-[#0E2640] ${tone.dot}`}
                      />
                      <div className="rounded-xl border border-white/10 bg-white/[0.03] p-3 text-right">
                        <div className="flex items-center justify-between gap-2">
                          <div className="text-[10px] font-bold tracking-[0.2em] text-night-text-muted">
                            مرحله {state.num}
                          </div>
                          <span
                            dir="ltr"
                            className={`ikia-status-pill ${tone.chip}`}
                          >
                            {state.en}
                          </span>
                        </div>
                        <div className="mt-1.5 text-sm font-bold text-night-text">
                          {state.label}
                        </div>
                        <p className="mt-0.5 text-[11px] leading-6 text-night-text-muted">
                          {state.description}
                        </p>
                      </div>
                    </li>
                  );
                })}
              </ol>
            </div>
          </div>
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

          {/* CC-Phase3 — Stylized inline-SVG regional corridor network.
              No image, no library; pure SVG + Tailwind. ایران sits at
              the centre with 4 regional nodes (ترکیه · قفقاز ·
              آسیای میانه · خلیج فارس) and route lines. */}
          <div className="mt-10 bg-ikia-product-card p-6 sm:p-8">
            <div className="mb-4 flex items-center justify-between gap-3">
              <div
                dir="ltr"
                className="font-mono text-[10px] font-bold uppercase tracking-[0.22em] text-sky-700"
              >
                Regional Corridor Network
              </div>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-200 bg-sky-50 px-2.5 py-0.5 text-[10px] font-bold text-sky-700">
                <span aria-hidden className="size-1.5 rounded-full bg-sky-500" />
                ۵ گره منطقه‌ای
              </span>
            </div>
            <svg
              viewBox="0 0 600 320"
              role="img"
              aria-label="نقشه شماتیک کریدورهای منطقه‌ای متصل به ایران"
              className="block h-auto w-full"
            >
              {/* Decorative grid. */}
              <defs>
                <pattern id="ikia-corridor-grid" width="40" height="40" patternUnits="userSpaceOnUse">
                  <path d="M40 0H0V40" fill="none" stroke="rgba(15, 23, 42, 0.05)" strokeWidth="1" />
                </pattern>
                <radialGradient id="ikia-corridor-iran-glow" cx="50%" cy="50%" r="50%">
                  <stop offset="0%" stopColor="#1F9CE0" stopOpacity="0.45" />
                  <stop offset="100%" stopColor="#1F9CE0" stopOpacity="0" />
                </radialGradient>
              </defs>
              <rect x="0" y="0" width="600" height="320" fill="url(#ikia-corridor-grid)" />

              {/* Iran glow halo. */}
              <circle cx="300" cy="180" r="90" fill="url(#ikia-corridor-iran-glow)" />

              {/* Route lines — Iran ↔ each regional node.
                  Solid for active corridors, dashed for emerging. */}
              <line x1="300" y1="180" x2="120" y2="90"  stroke="#0B6FB5" strokeWidth="2" strokeLinecap="round" />
              <line x1="300" y1="180" x2="220" y2="50"  stroke="#0B6FB5" strokeWidth="2" strokeLinecap="round" />
              <line x1="300" y1="180" x2="500" y2="110" stroke="#0B6FB5" strokeWidth="2" strokeLinecap="round" strokeDasharray="6 4" />
              <line x1="300" y1="180" x2="380" y2="280" stroke="#0B6FB5" strokeWidth="2" strokeLinecap="round" />

              {/* Cross routes — Turkey ↔ Caucasus, Central Asia ↔ Gulf. */}
              <path
                d="M120 90 Q 170 30 220 50"
                fill="none"
                stroke="#1F9CE0"
                strokeWidth="1.5"
                strokeDasharray="4 4"
                strokeLinecap="round"
                opacity="0.65"
              />
              <path
                d="M500 110 Q 470 200 380 280"
                fill="none"
                stroke="#1F9CE0"
                strokeWidth="1.5"
                strokeDasharray="4 4"
                strokeLinecap="round"
                opacity="0.55"
              />

              {/* Nodes — outer ring + inner dot. */}
              {/* Iran (central, larger). */}
              <circle cx="300" cy="180" r="38" fill="#0B6FB5" />
              <circle cx="300" cy="180" r="38" fill="none" stroke="#1F9CE0" strokeWidth="3" strokeOpacity="0.5" />
              <text x="300" y="178" textAnchor="middle" fill="#FFFFFF" fontSize="18" fontWeight="800">ایران</text>
              <text x="300" y="196" textAnchor="middle" fill="#E8F0F8" fontSize="9" fontFamily="monospace" letterSpacing="2">HUB</text>

              {/* Turkey (west). */}
              <circle cx="120" cy="90" r="22" fill="#FFFFFF" stroke="#0B6FB5" strokeWidth="2" />
              <text x="120" y="94" textAnchor="middle" fill="#0A1B2E" fontSize="12" fontWeight="700">ترکیه</text>

              {/* Caucasus (north-west). */}
              <circle cx="220" cy="50" r="22" fill="#FFFFFF" stroke="#0B6FB5" strokeWidth="2" />
              <text x="220" y="54" textAnchor="middle" fill="#0A1B2E" fontSize="12" fontWeight="700">قفقاز</text>

              {/* Central Asia (east). */}
              <circle cx="500" cy="110" r="26" fill="#FFFFFF" stroke="#0B6FB5" strokeWidth="2" />
              <text x="500" y="108" textAnchor="middle" fill="#0A1B2E" fontSize="11" fontWeight="700">آسیای</text>
              <text x="500" y="122" textAnchor="middle" fill="#0A1B2E" fontSize="11" fontWeight="700">میانه</text>

              {/* Persian Gulf (south). */}
              <circle cx="380" cy="280" r="26" fill="#FFFFFF" stroke="#0B6FB5" strokeWidth="2" />
              <text x="380" y="278" textAnchor="middle" fill="#0A1B2E" fontSize="11" fontWeight="700">خلیج</text>
              <text x="380" y="292" textAnchor="middle" fill="#0A1B2E" fontSize="11" fontWeight="700">فارس</text>

              {/* Direction tag chips along key routes. */}
              <g transform="translate(165, 130)">
                <rect x="-30" y="-10" width="60" height="20" rx="10" fill="#0A1B2E" />
                <text x="0" y="4" textAnchor="middle" fill="#E8F0F8" fontSize="10" fontWeight="700">شمال–غرب</text>
              </g>
              <g transform="translate(420, 130)">
                <rect x="-32" y="-10" width="64" height="20" rx="10" fill="#0A1B2E" />
                <text x="0" y="4" textAnchor="middle" fill="#E8F0F8" fontSize="10" fontWeight="700">شرق</text>
              </g>
              <g transform="translate(340, 230)">
                <rect x="-30" y="-10" width="60" height="20" rx="10" fill="#0A1B2E" />
                <text x="0" y="4" textAnchor="middle" fill="#E8F0F8" fontSize="10" fontWeight="700">جنوب</text>
              </g>
            </svg>
            <div className="mt-3 flex flex-wrap items-center gap-3 text-[11px] text-slate-600">
              <span className="inline-flex items-center gap-1.5">
                <span aria-hidden className="inline-block h-px w-6 bg-[#0B6FB5]" />
                کریدور فعال
              </span>
              <span className="inline-flex items-center gap-1.5">
                <span
                  aria-hidden
                  className="inline-block h-px w-6"
                  style={{
                    backgroundImage:
                      "linear-gradient(to right, #0B6FB5 50%, transparent 0%)",
                    backgroundSize: "6px 1px",
                    backgroundRepeat: "repeat-x",
                  }}
                />
                مسیر در حال توسعه
              </span>
              <span className="inline-flex items-center gap-1.5">
                <span aria-hidden className="inline-block size-1.5 rounded-full bg-[#1F9CE0]" />
                گره عملیاتی
              </span>
            </div>
          </div>

          <ul className="mt-10 grid gap-4 sm:grid-cols-2">
            {CORRIDORS.map((c, idx) => (
              <li
                key={c.title}
                className="ikia-hover-lift rounded-2xl border border-border-soft bg-card p-6 text-right shadow-card"
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
          CC-Phase2 — INDUSTRIES HUB (#industries)
          Consolidates the prior CC-64 dedicated industry sections
          (#oil-gas, #mining, #agriculture, #retail, #transit) into a
          single compact 6-card grid per the design guide §15. Each card
          is self-contained (icon + Persian title + 1-line description)
          and uses the .ikia-hover-lift utility from Phase 1.
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
                <article className="bg-ikia-product-card ikia-hover-lift flex h-full flex-col p-6 text-right">
                  <div className="flex items-center justify-between">
                    <div className="inline-flex size-10 items-center justify-center rounded-xl border border-sky-200 bg-sky-50 text-sky-700">
                      {i.icon}
                    </div>
                    <span
                      dir="ltr"
                      className="rounded-full border border-sky-200 bg-sky-50 px-2.5 py-0.5 font-mono text-[10px] font-semibold text-sky-700"
                    >
                      {i.en}
                    </span>
                  </div>
                  <h3 className="mt-4 text-lg font-extrabold tracking-tight text-deep-navy">
                    {i.title}
                  </h3>
                  <p className="mt-2 text-sm leading-7 text-slate-600">
                    {i.description}
                  </p>
                </article>
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
          {/* CC-66B — Auto-advancing fullscreen slider. Right-to-left
              motion every 4 s, continuous loop, pauses on hover/focus,
              honors prefers-reduced-motion. Replaces the previous CSS
              marquee strip and the older 10–14 service card PNGs. */}
          <div className="mt-10">
            <ServiceImageSlider
              ariaLabel="اسلاید خدمات حمل‌ونقل iKIA Logistics"
              intervalMs={4000}
              slides={SERVICE_SLIDES}
            />
          </div>
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
          CC-Phase2 — PRODUCT DASHBOARD signature section (#control-tower).
          Per design guide §10: chrome bar with Shipment ID + Live chip,
          condensed timeline highlights, route/corridor row, document
          compliance row, and metric chip strip. The CC-63 narrative
          pillars become the right column; dashboard mock is the left
          column. Same dark navy backdrop as before.
          ===================================================================== */}
      <section
        id="control-tower"
        className="ikia-section-dark scroll-mt-16"
      >
        <div className="mx-auto max-w-7xl px-4 py-20 sm:py-28">
          <div className="grid gap-10 lg:grid-cols-[1fr_1.4fr] lg:items-start lg:gap-16">
            {/* Right column — narrative + CTAs. */}
            <div className="space-y-5 text-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-sky-400/30 bg-sky-400/10 px-3 py-1 text-[11px] font-semibold tracking-[0.22em] text-sky-200">
                <span aria-hidden className="inline-block size-1.5 rounded-full bg-sky-400" />
                Control Tower
              </div>
              <h2 className="text-3xl font-extrabold leading-snug tracking-tight text-night-text sm:text-4xl lg:text-[44px]">
                برج کنترل دیجیتال زنجیره تأمین
              </h2>
              <p className="max-w-xl text-base leading-8 text-night-text-muted sm:text-lg sm:leading-9">
                iKIA Control Tower یک منبع واحد حقیقت برای همه ذی‌نفعان زنجیره
                تأمین است — برای دیدن، تصمیم گرفتن و عمل کردن، در سطح ملی و
                کریدور.
              </p>
              <ul className="grid gap-3 pt-1 sm:grid-cols-2">
                {CONTROL_TOWER_PILLARS.map((p, idx) => (
                  <li
                    key={p.title}
                    className="rounded-xl border border-white/10 bg-white/[0.04] p-3 text-right backdrop-blur-sm"
                  >
                    <div className="text-[10px] font-bold tracking-[0.2em] text-sky-200/80">
                      پایه {String(idx + 1).padStart(2, "0")}
                    </div>
                    <div className="mt-1 text-sm font-bold text-night-text">
                      {p.title}
                    </div>
                    <p className="mt-1 text-[11px] leading-6 text-night-text-muted">
                      {p.description}
                    </p>
                  </li>
                ))}
              </ul>
              <div className="flex flex-wrap gap-3 pt-2">
                <Button
                  asChild
                  size="lg"
                  className="bg-gradient-to-l from-emerald-600 via-green-500 to-lime-400 text-white shadow-lg shadow-emerald-950/30 hover:from-emerald-700 hover:via-green-600 hover:to-lime-500"
                >
                  <Link href="/#start">درخواست جلسه معرفی</Link>
                </Button>
                <Button
                  asChild
                  size="lg"
                  variant="outline"
                  className="border-white/30 bg-white/5 text-night-text backdrop-blur hover:border-sky-300 hover:bg-white/10 hover:text-night-text"
                >
                  <Link href="/login">ورود به پلتفرم</Link>
                </Button>
              </div>
            </div>

            {/* Left column — product dashboard mockup with chrome,
                condensed timeline highlights, route, docs, metrics. */}
            <div className="ikia-product-card-dark relative">
              {/* Chrome bar. */}
              <div className="flex items-center justify-between gap-3 border-b border-white/10 px-5 py-3">
                <div className="flex items-center gap-2">
                  <span aria-hidden className="size-2 rounded-full bg-red-400/70" />
                  <span aria-hidden className="size-2 rounded-full bg-amber-400/70" />
                  <span aria-hidden className="size-2 rounded-full bg-emerald-400/70" />
                  <span
                    dir="ltr"
                    className="ms-3 font-mono text-[11px] text-sky-300/80"
                  >
                    iKIA OS · Shipment SH-2026-08471
                  </span>
                </div>
                <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-2.5 py-0.5 text-[10px] font-bold text-emerald-200">
                  <span aria-hidden className="size-1.5 rounded-full bg-emerald-400" />
                  Live
                </span>
              </div>

              <div className="space-y-5 p-5 sm:p-6">
                {/* Condensed timeline — 4 highlighted milestone chips. */}
                <div>
                  <div className="mb-3 flex items-center justify-between gap-3">
                    <div
                      dir="ltr"
                      className="font-mono text-[10px] font-bold uppercase tracking-[0.22em] text-night-text-muted"
                    >
                      Timeline · Highlights
                    </div>
                    <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-400/30 bg-sky-400/10 px-2 py-0.5 text-[10px] font-semibold text-sky-200">
                      در حال حمل
                    </span>
                  </div>
                  <ul className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                    {[
                      { en: "Booked", fa: "رزرو", tone: "border-indigo-400/30 bg-indigo-400/10 text-indigo-200", done: true },
                      { en: "Dispatched", fa: "اعزام", tone: "border-cyan-400/30 bg-cyan-400/10 text-cyan-200", done: true },
                      { en: "In Transit", fa: "در مسیر", tone: "border-amber-400/30 bg-amber-400/10 text-amber-200", done: false },
                      { en: "Delivered", fa: "تحویل", tone: "border-emerald-400/30 bg-emerald-400/10 text-emerald-200", done: false },
                    ].map((m) => (
                      <li
                        key={m.en}
                        className={`flex flex-col items-center rounded-lg border p-2 text-center ${m.tone}`}
                      >
                        <span dir="ltr" className="font-mono text-[10px] font-semibold">
                          {m.done ? `✓ ${m.en}` : m.en}
                        </span>
                        <span className="mt-0.5 text-[11px] font-bold text-night-text">
                          {m.fa}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Route / corridor row. */}
                <div className="rounded-xl border border-white/10 bg-white/[0.03] p-4">
                  <div className="flex items-center justify-between gap-3">
                    <div
                      dir="ltr"
                      className="font-mono text-[10px] font-bold uppercase tracking-[0.22em] text-night-text-muted"
                    >
                      Route · Corridor
                    </div>
                    <span className="inline-flex items-center gap-1.5 rounded-full border border-cyan-400/30 bg-cyan-400/10 px-2 py-0.5 text-[10px] font-semibold text-cyan-200">
                      شمال–جنوب
                    </span>
                  </div>
                  <div className="mt-3 flex items-center justify-between gap-2 text-sm text-night-text">
                    <span className="font-bold">تهران</span>
                    <span
                      aria-hidden
                      className="flex-1 mx-3 h-px bg-gradient-to-l from-cyan-400/0 via-cyan-400/60 to-cyan-400/0"
                    />
                    <span aria-hidden className="text-sky-300">●</span>
                    <span
                      aria-hidden
                      className="flex-1 mx-3 h-px bg-gradient-to-l from-cyan-400/0 via-cyan-400/30 to-cyan-400/0"
                    />
                    <span className="font-bold">بندرعباس</span>
                  </div>
                  <div className="mt-2 flex items-center justify-between text-[11px] text-night-text-muted">
                    <span>۱٬۳۱۰ کیلومتر</span>
                    <span>ETA · ۲ روز ۴ ساعت</span>
                  </div>
                </div>

                {/* Document compliance row. */}
                <div className="rounded-xl border border-white/10 bg-white/[0.03] p-4">
                  <div className="flex items-center justify-between gap-3">
                    <div
                      dir="ltr"
                      className="font-mono text-[10px] font-bold uppercase tracking-[0.22em] text-night-text-muted"
                    >
                      Documents · Compliance
                    </div>
                    <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-2 py-0.5 text-[10px] font-semibold text-emerald-200">
                      ۴ از ۴ تأیید
                    </span>
                  </div>
                  <ul className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
                    {[
                      { fa: "اظهارنامه", en: "Customs" },
                      { fa: "بارنامه", en: "BoL" },
                      { fa: "بیمه", en: "Insurance" },
                      { fa: "گواهی مبدأ", en: "Origin" },
                    ].map((doc) => (
                      <li
                        key={doc.en}
                        className="flex flex-col items-center rounded-lg border border-emerald-400/20 bg-emerald-400/[0.06] p-2 text-center"
                      >
                        <span className="text-[11px] font-semibold text-night-text">
                          {doc.fa}
                        </span>
                        <span
                          dir="ltr"
                          className="font-mono text-[9px] text-emerald-200"
                        >
                          ✓ {doc.en}
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Metric chip strip. */}
                <ul className="grid grid-cols-3 gap-2">
                  {[
                    { fa: "میانگین زمان تحویل", value: "۲٫۴ روز", tone: "text-emerald-200" },
                    { fa: "نرخ تطبیق ظرفیت", value: "٪۹۴", tone: "text-sky-200" },
                    { fa: "تأخیر فعال", value: "۰ مورد", tone: "text-amber-200" },
                  ].map((m) => (
                    <li
                      key={m.fa}
                      className="rounded-xl border border-white/10 bg-white/[0.04] p-3 text-center"
                    >
                      <div className={`text-base font-extrabold ${m.tone}`}>{m.value}</div>
                      <div className="mt-0.5 text-[10px] text-night-text-muted">{m.fa}</div>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
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
          {/* CC-67 — Final conversion banner. Layered navy product
              background (.bg-ikia-cta-banner) instead of the previous
              muddy photo overlay. Green primary + red secondary mirror
              the new hero CTA palette for visual consistency. */}
          <div
            className="relative overflow-hidden rounded-[1.5rem] border border-white/10 shadow-2xl shadow-slate-950/30 bg-ikia-cta-banner"
          >
            <div className="relative grid gap-8 px-6 py-12 sm:px-10 sm:py-16 lg:grid-cols-[1.2fr_1fr] lg:items-center lg:gap-12 lg:px-14 lg:py-20">
              <div className="space-y-5 text-right text-night-text">
                <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[11px] font-semibold tracking-[0.2em] text-night-text backdrop-blur-md">
                  <span aria-hidden className="inline-block size-1.5 rounded-full bg-emerald-400" />
                  گفت‌وگوی راهبردی
                </div>
                <h2 className="text-2xl font-extrabold leading-snug tracking-tight sm:text-3xl lg:text-4xl">
                  زنجیره حمل خود را روی یک پلتفرم واحد ببینید و کنترل کنید
                </h2>
                <p className="max-w-2xl text-sm leading-7 text-night-text-muted sm:text-base sm:leading-8">
                  بازار حمل، اجرای عملیات، رؤیت لحظه‌ای، اسناد گمرکی و تسویه —
                  در یک پلتفرم یکپارچه برای صنایع راهبردی، کریدورهای ترانزیتی و
                  اکوسیستم کالاهای ملی.
                </p>
                <div className="flex flex-wrap gap-3 pt-2">
                  <Button
                    asChild
                    size="lg"
                    className="w-full bg-gradient-to-l from-emerald-600 via-green-500 to-lime-400 text-white shadow-lg shadow-emerald-950/30 hover:from-emerald-700 hover:via-green-600 hover:to-lime-500 sm:w-auto"
                  >
                    <Link href="/login">درخواست جلسه معرفی</Link>
                  </Button>
                  <Button
                    asChild
                    size="lg"
                    className="w-full border border-red-300/60 bg-gradient-to-l from-red-700 via-rose-600 to-orange-500 text-white shadow-lg shadow-red-950/25 hover:from-red-800 hover:via-rose-700 hover:to-orange-600 sm:w-auto"
                  >
                    <Link href="/login">شروع همکاری</Link>
                  </Button>
                </div>
              </div>
              {/* Right column (RTL inline-end) — compact product-stat
                  badges. No screenshots, no widgets — just three crisp
                  capability anchors. */}
              <ul className="grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
                {[
                  { fa: "بازار حمل چندوجهی", en: "Multimodal marketplace" },
                  { fa: "برج کنترل و رؤیت", en: "Control tower" },
                  { fa: "اسناد و تسویه دیجیتال", en: "Docs & settlement" },
                ].map((cap) => (
                  <li
                    key={cap.en}
                    className="ikia-hover-lift rounded-xl border border-white/10 bg-white/[0.06] p-3 text-right text-night-text backdrop-blur-sm"
                  >
                    <div className="text-sm font-bold">{cap.fa}</div>
                    <div
                      dir="ltr"
                      className="mt-0.5 font-mono text-[10px] text-night-text-muted"
                    >
                      {cap.en}
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
