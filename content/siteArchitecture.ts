import type { ModuleEntry, ModuleStatus } from "./modules/types";
import { FREIGHT } from "./modules/freight";
import { PLATFORM } from "./modules/platform";
import { VALUE_ADDED } from "./modules/valueAdded";
import { SOLUTIONS } from "./modules/solutions";
import { CORRIDORS } from "./modules/corridors";

// ---------------------------------------------------------------------------
// Module registry
// ---------------------------------------------------------------------------
export { FREIGHT, PLATFORM, VALUE_ADDED, SOLUTIONS, CORRIDORS };

// Developer / API ecosystem (single entry; rendered via the landing template).
export const DEVELOPERS: ModuleEntry = {
  key: "developers",
  faTitle: "توسعه‌دهندگان و API",
  enTitle: "Developer Platform",
  value: "اتصال سامانه‌ها و شرکا به پلتفرم iKIA با APIهای استاندارد.",
  pain: "اتصال به جریان عملیات لجستیک بدون API استاندارد دشوار است.",
  solution: "iKIA با APIها و ابزار توسعه، اتصال سریع و امن را فراهم می‌کند.",
  status: "strategic-future",
  targetUsers: ["توسعه‌دهندگان", "سازمان‌ها", "شرکا"],
  route: "/developers",
  icon: "developers",
  cta: "گفتگو با تیم فنی",
  category: "platform",
  detail: {
    pains: [
      { title: "نبود API استاندارد", desc: "اتصال سامانه‌ها بدون چارچوب سخت است." },
      { title: "ورود دستی داده", desc: "انتقال دستی، کند و خطاپذیر است." },
      { title: "امنیت اتصال", desc: "کنترل دسترسی شرکا پیچیده است." },
    ],
    capabilities: [
      { icon: "api", title: "REST API", desc: "دسترسی برنامه‌نویسی به عملیات." },
      { icon: "workflow", title: "وب‌هوک رویداد", desc: "اطلاع‌رسانی رویدادها." },
      { icon: "developers", title: "مستندات و SDK", desc: "ابزار اتصال برای تیم فنی." },
      { icon: "lock", title: "کلید و دسترسی", desc: "امنیت و کنترل دقیق." },
    ],
    steps: [
      { title: "ثبت", desc: "دسترسی و کلید دریافت می‌شود." },
      { title: "آزمایش", desc: "اتصال در محیط آزمایش." },
      { title: "اتصال", desc: "همگام‌سازی داده و رویداد." },
      { title: "عملیات", desc: "اجرا در محیط واقعی." },
    ],
    controls: [
      { title: "کنترل دسترسی", desc: "مجوز دقیق هر اتصال." },
      { title: "پایش مصرف", desc: "نظارت بر استفاده." },
      { title: "سوابق فراخوان", desc: "ثبت رویدادهای API." },
    ],
  },
};

export const ALL_MODULES: ModuleEntry[] = [
  ...FREIGHT,
  ...PLATFORM,
  ...VALUE_ADDED,
  ...SOLUTIONS,
  ...CORRIDORS,
  DEVELOPERS,
];

export function moduleByKey(key: string): ModuleEntry | undefined {
  return ALL_MODULES.find((m) => m.key === key);
}
export function moduleByRoute(route: string): ModuleEntry | undefined {
  return ALL_MODULES.find((m) => m.route === route);
}
function pick(list: ModuleEntry[], keys: string[]): ModuleEntry[] {
  return keys.map((k) => list.find((m) => m.key === k)).filter(Boolean) as ModuleEntry[];
}

// ---------------------------------------------------------------------------
// External / product destinations (no /login in public marketing per brief)
// ---------------------------------------------------------------------------
export const PRODUCT_URLS = {
  platform: "/platform",
  start: "/contact", // «شروع همکاری»
  demo: "/contact",
} as const;

// ---------------------------------------------------------------------------
// Navigation model
// ---------------------------------------------------------------------------
export type NavLink = { label: string; href: string; desc?: string; status?: ModuleStatus };
export type NavGroup = {
  key: string;
  label: string;
  overviewHref?: string;
  overviewLabel?: string;
  links: NavLink[];
};

const toLinks = (mods: ModuleEntry[]): NavLink[] =>
  mods.map((m) => ({ label: m.faTitle, href: m.route, desc: m.value, status: m.status }));

export const MEGA_MENU: NavGroup[] = [
  {
    key: "platform",
    label: "پلتفرم",
    overviewHref: "/platform",
    overviewLabel: "نمای کلی پلتفرم",
    links: toLinks(pick(PLATFORM, [
      "control-tower",
      "visibility",
      "order-management",
      "documents-compliance",
      "integrations",
    ])),
  },
  {
    key: "freight",
    label: "خدمات حمل",
    links: toLinks(pick(FREIGHT, ["road", "rail", "ocean", "air", "multimodal", "corridor-mgmt"])),
  },
  {
    key: "solutions",
    label: "راهکارها",
    links: toLinks(pick(SOLUTIONS, [
      "shippers",
      "forwarders",
      "carriers",
      "logistics-hubs",
      "enterprise",
      "government",
    ])),
  },
  {
    key: "value-added",
    label: "خدمات ارزش‌افزوده",
    links: toLinks(pick(VALUE_ADDED, ["warehousing", "insurance", "finance", "customs", "data-ai"])),
  },
  {
    key: "corridors",
    label: "کریدورها",
    overviewHref: "/corridors",
    overviewLabel: "شبکه کریدورها و مراکز",
    links: toLinks(pick(CORRIDORS, ["instc", "east-west", "border-gateways", "hub-network"])),
  },
  {
    key: "resources",
    label: "منابع",
    overviewHref: "/resources",
    overviewLabel: "همه منابع",
    links: [
      { label: "توسعه‌دهندگان و API", href: "/developers", desc: "اتصال به پلتفرم با API" },
      { label: "وبلاگ", href: "/resources/blog", desc: "یادداشت‌ها و اخبار iKIA" },
      { label: "سوالات متداول", href: "/resources/faq", desc: "پاسخ پرسش‌های رایج" },
      { label: "درباره ما", href: "/about", desc: "iKIA و مأموریت آن" },
    ],
  },
];

export const SIMPLE_NAV: NavLink[] = [{ label: "درباره ما", href: "/about" }];

// ---------------------------------------------------------------------------
// Footer (4 columns)
// ---------------------------------------------------------------------------
export const FOOTER_COLUMNS: NavGroup[] = [
  {
    key: "platform",
    label: "پلتفرم",
    links: [
      { label: "نمای کلی پلتفرم", href: "/platform" },
      { label: "برج کنترل", href: "/platform/control-tower" },
      { label: "رهگیری لحظه‌ای", href: "/platform/visibility" },
      { label: "مدیریت سفارش", href: "/platform/order-management" },
      { label: "اسناد و انطباق", href: "/platform/documents-compliance" },
    ],
  },
  {
    key: "freight",
    label: "خدمات حمل",
    links: [
      { label: "حمل جاده‌ای", href: "/freight/road" },
      { label: "حمل ریلی", href: "/freight/rail" },
      { label: "حمل دریایی", href: "/freight/ocean" },
      { label: "حمل هوایی", href: "/freight/air" },
      { label: "گمرک و ترخیص", href: "/value-added/customs" },
    ],
  },
  {
    key: "resources",
    label: "منابع",
    links: [
      { label: "کریدورها", href: "/corridors" },
      { label: "راهکارها", href: "/solutions/shippers" },
      { label: "توسعه‌دهندگان", href: "/developers" },
      { label: "وبلاگ", href: "/resources/blog" },
      { label: "سوالات متداول", href: "/resources/faq" },
    ],
  },
  {
    key: "company",
    label: "شرکت",
    links: [
      { label: "درباره ما", href: "/about" },
      { label: "تماس و همکاری", href: "/contact" },
      { label: "قوانین و مقررات", href: "/legal/terms" },
      { label: "حریم خصوصی", href: "/legal/privacy" },
    ],
  },
];

// ---------------------------------------------------------------------------
// Homepage grid selections
// ---------------------------------------------------------------------------
export const HOME_FREIGHT = pick(FREIGHT, ["road", "rail", "ocean", "air", "multimodal", "corridor-mgmt"]);
export const HOME_PLATFORM = pick(PLATFORM, [
  "control-tower",
  "visibility",
  "order-management",
  "documents-compliance",
  "integrations",
]).concat(pick(VALUE_ADDED, ["data-ai"]));
export const HOME_SOLUTIONS = pick(SOLUTIONS, [
  "shippers",
  "forwarders",
  "carriers",
  "logistics-hubs",
  "enterprise",
  "government",
]);
