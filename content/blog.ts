export type BlogPost = {
  slug: string;
  title: string;
  date: string; // ISO
  excerpt: string;
  body: string[];
};

// Seed posts for the resources/blog placeholder. Replace with a CMS or MDX
// source later. Content is intentionally modest and honest about MVP stage.
export const BLOG_POSTS: BlogPost[] = [
  {
    slug: "why-ikia",
    title: "چرا iKIA را می‌سازیم",
    date: "2026-06-01",
    excerpt: "نگاهی به مشکلاتی که در حمل‌ونقل جاده‌ای می‌بینیم و رویکرد ما برای حل آن‌ها.",
    body: [
      "صنعت حمل‌ونقل جاده‌ای با چالش‌های آشنایی روبه‌روست: هزینه‌های واسطه‌گری، خالی‌برگشت کامیون‌ها و نبود شفافیت در قیمت‌گذاری.",
      "iKIA با تمرکز بر یک زیرساخت دیجیتال ساده و قابل اتکا تلاش می‌کند این فرایند را شفاف‌تر کند. ما در مرحله پیش‌بذری هستیم و گام‌به‌گام پیش می‌رویم.",
      "این یادداشت‌ها مسیر ساخت محصول را روایت می‌کنند؛ بدون اغراق و بر پایه واقعیت.",
    ],
  },
  {
    slug: "matching-basics",
    title: "تخصیص هوشمند بار به زبان ساده",
    date: "2026-06-15",
    excerpt: "تخصیص هوشمند یعنی چه و چطور به کاهش خالی‌برگشت کمک می‌کند.",
    body: [
      "تخصیص هوشمند یعنی رساندن هر بار به مناسب‌ترین ظرفیت بر اساس مسیر، نوع بار، قابلیت اتکا و قیمت.",
      "هدف، کاهش خالی‌برگشت و افزایش بهره‌وری ناوگان است؛ به‌گونه‌ای که هم صاحب بار و هم کریر منتفع شوند.",
      "این قابلیت در مسیر توسعه است و به‌مرور دقیق‌تر می‌شود.",
    ],
  },
];

export function getPost(slug: string): BlogPost | undefined {
  return BLOG_POSTS.find((p) => p.slug === slug);
}

export const faDate = (iso: string) =>
  new Date(iso).toLocaleDateString("fa-IR", { year: "numeric", month: "long", day: "numeric" });
