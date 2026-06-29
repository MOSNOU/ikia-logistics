import type { Metadata } from "next";
import Link from "next/link";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { BLOG_POSTS, faDate } from "@/content/blog";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "وبلاگ iKIA",
  description: "یادداشت‌ها و اخبار iKIA درباره ساخت یک سیستم‌عامل دیجیتال لجستیک.",
  path: "/resources/blog",
});

export default function BlogPage() {
  return (
    <>
      <PageHero eyebrow="وبلاگ" title="یادداشت‌های iKIA" subtitle="روایت ساخت محصول، بدون اغراق." />
      <Section tone="light">
        <div className="mx-auto max-w-3xl space-y-4">
          {BLOG_POSTS.map((post) => (
            <Link
              key={post.slug}
              href={`/resources/blog/${post.slug}`}
              className="block rounded-2xl border border-slate-200 bg-white p-6 transition hover:border-[#06b6d4] hover:shadow-md"
            >
              <p className="text-xs text-slate-400">{faDate(post.date)}</p>
              <h2 className="mt-1 text-lg font-black text-[#1e3a5f]">{post.title}</h2>
              <p className="mt-2 text-sm leading-7 text-slate-500">{post.excerpt}</p>
              <span className="mt-3 inline-block text-sm font-extrabold text-[#0e7490]">ادامه مطلب ←</span>
            </Link>
          ))}
        </div>
      </Section>
    </>
  );
}
