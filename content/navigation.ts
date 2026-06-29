// Central navigation + external destination model for the marketing site.
// Consumed by Navbar, MegaMenu, MobileNav and Footer so menu arrays are
// never duplicated across components.

export type NavLink = {
  label: string;
  href: string;
  desc?: string;
  external?: boolean;
};

export type NavGroup = {
  key: string;
  label: string;
  href?: string; // optional landing/overview page for the group
  links: NavLink[];
};

// External product destinations. Kept in one place so the carrier/app
// subdomains can be swapped in once those deployments are live. For now the
// CTAs resolve to the existing in-app routes so nothing is broken pre-launch.
export const PRODUCT_URLS = {
  login: "/login", // existing auth route in this workspace
  register: "/login", // onboarding currently shares the login screen
  // Architectural targets (post-split):
  appLogin: "https://app.ikialogistic.com/login",
  appRegister: "https://app.ikialogistic.com/register",
  carrierApp: "https://carrier.ikialogistic.com",
} as const;

export const MEGA_MENU: NavGroup[] = [
  {
    key: "platform",
    label: "پلتفرم",
    href: "/platform",
    links: [
      { label: "نمای کلی پلتفرم", href: "/platform", desc: "سیستم‌عامل دیجیتال لجستیک iKIA" },
      { label: "چطور کار می‌کند", href: "/platform/how-it-works", desc: "از ثبت بار تا تأیید تحویل" },
      { label: "داشبورد و ردیابی لحظه‌ای", href: "/platform/tracking", desc: "نمای زنده وضعیت محموله‌ها" },
      { label: "تخصیص هوشمند بار", href: "/platform/matching", desc: "اتصال بار به ظرفیت مناسب" },
      { label: "تسویه مالی و امنیت", href: "/platform/payments", desc: "آمادگی تسویه و کنترل مالی" },
    ],
  },
  {
    key: "services",
    label: "خدمات",
    href: "/services",
    links: [
      { label: "حمل جاده‌ای", href: "/services/road-freight", desc: "حمل بار داخلی، مسیر به مسیر" },
      { label: "مدیریت و ثبت بار", href: "/services/load-management", desc: "چرخه عمر بار از ثبت تا تخصیص" },
      { label: "اسناد و انطباق مقرراتی", href: "/services/compliance", desc: "مدارک، سوابق و ردگیری ممیزی" },
      { label: "گزارش‌ها و تحلیل داده", href: "/services/analytics", desc: "بینش عملیاتی و شاخص‌های کلیدی" },
    ],
  },
  {
    key: "solutions",
    label: "راهکارها",
    // No single overview route; this group routes directly to persona pages.
    links: [
      { label: "برای فورواردرها", href: "/forwarders", desc: "یافتن بار و مدیریت چند محموله" },
      { label: "برای صاحبان بار / شیپرها", href: "/shippers", desc: "ثبت بار و قیمت شفاف" },
      { label: "برای سازمان‌ها و شرکت‌ها", href: "/enterprise", desc: "حمل سازمانی و گزارش مدیریتی" },
      { label: "برای کریرها و ناوگان", href: "/carriers", desc: "اپ موبایل و بارهای نزدیک" },
    ],
  },
  {
    key: "resources",
    label: "منابع",
    href: "/resources",
    links: [
      { label: "وبلاگ", href: "/resources/blog", desc: "یادداشت‌ها و اخبار iKIA" },
      { label: "راهنماها و مطالعات موردی", href: "/resources/guides", desc: "راهنمای کاربردی صنعت" },
      { label: "مستندات", href: "/resources/docs", desc: "مرجع فنی و محصول" },
      { label: "سوالات متداول", href: "/resources/faq", desc: "پاسخ پرسش‌های رایج" },
    ],
  },
];

// Simple top-level links shown next to the mega-menu triggers.
export const SIMPLE_NAV: NavLink[] = [{ label: "درباره ما", href: "/about" }];

export const FOOTER_GROUPS: NavGroup[] = [
  ...MEGA_MENU,
  {
    key: "company",
    label: "شرکت",
    links: [
      { label: "درباره ما", href: "/about" },
      { label: "تماس با ما", href: "/contact" },
      { label: "قوانین و مقررات", href: "/legal/terms" },
      { label: "حریم خصوصی", href: "/legal/privacy" },
    ],
  },
];
