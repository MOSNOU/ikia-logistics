import type { ContentPage } from "./types";

export const SERVICE_ROAD_FREIGHT: ContentPage = {
  slug: "road-freight",
  eyebrow: "خدمات",
  title: "حمل جاده‌ای",
  subtitle: "تمرکز نخست بر حمل بار جاده‌ای داخلی؛ ساده، شفاف و قابل اتکا.",
  intro:
    "iKIA کار را با حمل جاده‌ای داخلی آغاز می‌کند. مسیر آزمایشی نخست به‌صورت پایلوت انتخاب می‌شود (برای مثال تهران ↔ مشهد) و سپس پوشش به سایر مسیرهای اصلی گسترش می‌یابد.",
  capabilities: [
    { icon: "truck", title: "حمل داخلی", desc: "پشتیبانی از بارهای جاده‌ای میان شهرهای کشور." },
    { icon: "route", title: "مسیرمحور", desc: "تمرکز اولیه بر یک کریدور پایلوت و توسعه تدریجی." },
    { icon: "repeat", title: "کاهش خالی‌برگشت", desc: "اتصال بار برگشت به ناوگان برای بهره‌وری بیشتر." },
    { icon: "pin", title: "پیگیری وضعیت", desc: "شفافیت وضعیت محموله در طول مسیر." },
  ],
  note: "کریدور پایلوت بسته به توافق‌های عملیاتی نهایی می‌شود؛ مسیرها در مسیر توسعه‌اند.",
  seo: {
    title: "حمل جاده‌ای — iKIA",
    description: "خدمات حمل جاده‌ای داخلی iKIA با تمرکز بر کریدور پایلوت و کاهش خالی‌برگشت.",
  },
};

export const SERVICE_LOAD_MANAGEMENT: ContentPage = {
  slug: "load-management",
  eyebrow: "خدمات",
  title: "مدیریت و ثبت بار",
  subtitle: "چرخه عمر بار از ثبت تا تخصیص و تحویل، در یک جریان منسجم.",
  intro:
    "از ایجاد بار و جمع‌آوری پیشنهادها تا تخصیص و دنبال‌کردن چرخه عمر محموله، همه در یک نقطه مدیریت می‌شود.",
  capabilities: [
    { icon: "register", title: "ایجاد بار", desc: "ثبت سریع مشخصات بار و الزامات حمل." },
    { icon: "offer", title: "جمع‌آوری پیشنهاد", desc: "دریافت و مقایسه پیشنهادها در یک نما." },
    { icon: "assign", title: "تخصیص", desc: "واگذاری بار به فورواردر/کریر منتخب." },
    { icon: "lifecycle", title: "چرخه عمر", desc: "پیگیری وضعیت بار تا تحویل نهایی." },
  ],
  seo: {
    title: "مدیریت و ثبت بار — iKIA",
    description: "مدیریت چرخه عمر بار در iKIA: ایجاد بار، جمع‌آوری پیشنهاد، تخصیص و پیگیری تا تحویل.",
  },
};

export const SERVICE_COMPLIANCE: ContentPage = {
  slug: "compliance",
  eyebrow: "خدمات",
  title: "اسناد و انطباق مقرراتی",
  subtitle: "مدیریت مدارک، آگاهی از مقررات و نگه‌داری سوابق قابل ممیزی.",
  intro:
    "iKIA کمک می‌کند مدارک هر محموله منظم بماند و سوابق لازم برای انطباق و ممیزی در دسترس باشد.",
  capabilities: [
    { icon: "documents", title: "مدیریت اسناد", desc: "نگه‌داری منظم مدارک بار و حمل." },
    { icon: "compliance", title: "آگاهی مقرراتی", desc: "چارچوبی برای رعایت الزامات حمل." },
    { icon: "audit", title: "ردگیری ممیزی", desc: "سوابق قابل پیگیری برای حسابرسی." },
    { icon: "lock", title: "دسترسی کنترل‌شده", desc: "مشاهده اسناد بر اساس نقش کاربر." },
  ],
  seo: {
    title: "اسناد و انطباق مقرراتی — iKIA",
    description: "مدیریت اسناد، آگاهی مقرراتی و سوابق قابل ممیزی برای حمل بار در iKIA.",
  },
};

export const SERVICE_ANALYTICS: ContentPage = {
  slug: "analytics",
  eyebrow: "خدمات",
  title: "گزارش‌ها و تحلیل داده",
  subtitle: "داشبوردها و بینش عملیاتی برای تصمیم‌گیری بهتر.",
  intro:
    "گزارش‌های iKIA به مدیران کمک می‌کند عملکرد حمل، هزینه‌ها و شاخص‌های کلیدی را روشن ببینند. این بخش گام‌به‌گام غنی‌تر می‌شود.",
  capabilities: [
    { icon: "analytics", title: "داشبورد عملیاتی", desc: "نمای کلی از وضعیت و عملکرد حمل." },
    { icon: "trending", title: "شاخص‌های کلیدی", desc: "سنجش بهره‌وری، هزینه و زمان تحویل." },
    { icon: "insight", title: "بینش عملیاتی", desc: "کشف گلوگاه‌ها و فرصت‌های بهبود." },
    { icon: "report", title: "گزارش‌گیری", desc: "خروجی‌های ساخت‌یافته برای مدیریت." },
  ],
  seo: {
    title: "گزارش‌ها و تحلیل داده — iKIA",
    description: "داشبوردها، شاخص‌های کلیدی و بینش عملیاتی iKIA برای مدیریت بهتر حمل‌ونقل.",
  },
};

export const SERVICE_PAGES: Record<string, ContentPage> = {
  "road-freight": SERVICE_ROAD_FREIGHT,
  "load-management": SERVICE_LOAD_MANAGEMENT,
  compliance: SERVICE_COMPLIANCE,
  analytics: SERVICE_ANALYTICS,
};

export const SERVICES_OVERVIEW: ContentPage = {
  slug: "services",
  eyebrow: "خدمات iKIA",
  title: "خدمات لجستیک iKIA",
  subtitle: "از حمل جاده‌ای تا مدیریت بار، انطباق و تحلیل داده.",
  intro:
    "مجموعه خدمات iKIA برای پوشش چرخه کامل حمل بار طراحی شده است؛ از ثبت و تخصیص تا اسناد و گزارش‌گیری.",
  capabilities: [
    { icon: "truck", title: "حمل جاده‌ای", desc: "حمل بار داخلی با تمرکز بر کریدور پایلوت." },
    { icon: "register", title: "مدیریت و ثبت بار", desc: "چرخه عمر بار از ثبت تا تحویل." },
    { icon: "documents", title: "اسناد و انطباق", desc: "مدارک و سوابق قابل ممیزی." },
    { icon: "analytics", title: "گزارش و تحلیل", desc: "داشبورد و شاخص‌های عملیاتی." },
  ],
  seo: {
    title: "خدمات iKIA",
    description: "خدمات لجستیک iKIA: حمل جاده‌ای، مدیریت بار، اسناد و انطباق، گزارش و تحلیل داده.",
  },
};
