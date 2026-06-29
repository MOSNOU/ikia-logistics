import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { LegalDoc } from "@/components/sections/LegalDoc";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "حریم خصوصی",
  description: "سیاست حریم خصوصی iKIA Logistics و نحوه محافظت از داده‌های کاربران (پیش‌نویس).",
  path: "/legal/privacy",
});

export default function PrivacyPage() {
  return (
    <>
      <PageHero eyebrow="حقوقی" title="حریم خصوصی" />
      <LegalDoc
        updated="خرداد ۱۴۰۵"
        sections={[
          {
            heading: "۱) داده‌هایی که جمع‌آوری می‌کنیم",
            paragraphs: [
              "اطلاعات حساب، مشخصات بار و حمل، و داده‌های لازم برای ارائه خدمات. تنها داده‌های ضروری جمع‌آوری می‌شود.",
            ],
          },
          {
            heading: "۲) نحوه استفاده از داده‌ها",
            paragraphs: [
              "داده‌ها برای ارائه و بهبود خدمات، تخصیص بار و پشتیبانی استفاده می‌شوند.",
            ],
          },
          {
            heading: "۳) دسترسی و امنیت",
            paragraphs: [
              "دسترسی به داده‌ها نقش‌محور است و سوابق برای انطباق و ممیزی نگه‌داری می‌شود.",
              "ما در مسیر تکمیل رویه‌های امنیتی و انطباق هستیم و این سیاست به‌مرور دقیق‌تر می‌شود.",
            ],
          },
          {
            heading: "۴) حقوق کاربران",
            paragraphs: [
              "کاربران می‌توانند برای اصلاح یا حذف داده‌های خود با ما تماس بگیرند.",
            ],
          },
        ]}
      />
    </>
  );
}
