import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Section } from "@/components/ui/Section";
import { BLOG_POSTS, getPost, faDate } from "@/content/blog";
import { buildMetadata } from "@/lib/seo";

export function generateStaticParams() {
  return BLOG_POSTS.map((p) => ({ slug: p.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getPost(slug);
  if (!post) return buildMetadata({ title: "نوشته یافت نشد", description: "این نوشته موجود نیست." });
  return buildMetadata({
    title: post.title,
    description: post.excerpt,
    path: `/resources/blog/${post.slug}`,
  });
}

export default async function BlogPostPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = getPost(slug);
  if (!post) notFound();

  return (
    <Section tone="light">
      <article className="mx-auto max-w-2xl">
        <Link href="/resources/blog" className="text-sm font-extrabold text-[#0e7490]">
          → بازگشت به وبلاگ
        </Link>
        <p className="mt-6 text-xs text-slate-400">{faDate(post.date)}</p>
        <h1 className="mt-1 text-2xl font-black leading-tight text-[#1e3a5f] sm:text-3xl">{post.title}</h1>
        <div className="mt-6 space-y-4">
          {post.body.map((para, i) => (
            <p key={i} className="text-sm leading-9 text-slate-600 sm:text-base">
              {para}
            </p>
          ))}
        </div>
      </article>
    </Section>
  );
}
