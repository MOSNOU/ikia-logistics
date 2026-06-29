import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { LegalDoc } from "@/components/sections/LegalDoc";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "قوانین و مقررات",
  description: "قوانین و مقررات استفاده از iKIA Logistics (پیش‌نویس مرحله پیش‌بذری).",
  path: "/legal/terms",
});

export default function TermsPage() {
  return (
    <>
      <PageHero eyebrow="حقوقی" title="قوانین و مقررات" />
      <LegalDoc
        updated="خرداد ۱۴۰۵"
        sections={[
          {
            heading: "۱) پذیرش شرایط",
            paragraphs: [
              "با استفاده از iKIA Logistics، شما این شرایط را می‌پذیرید. در صورت عدم موافقت، لطفاً از خدمات استفاده نکنید.",
            ],
          },
          {
            heading: "۲) ماهیت سرویس",
            paragraphs: [
              "iKIA در مرحله پیش‌بذری و اعتبارسنجی مفهوم است. برخی قابلیت‌ها در حال توسعه‌اند و ممکن است تغییر کنند.",
              "iKIA یک بستر اتصال میان صاحبان بار و حمل‌کنندگان است و در این مرحله خدمات پرداخت زنده ارائه نمی‌دهد.",
            ],
          },
          {
            heading: "۳) مسئولیت کاربران",
            paragraphs: [
              "کاربران مسئول صحت اطلاعات واردشده و رعایت قوانین حمل‌ونقل هستند.",
            ],
          },
          {
            heading: "۴) محدودیت مسئولیت",
            paragraphs: [
              "iKIA تلاش می‌کند خدمات قابل اتکا ارائه دهد، اما در مرحله فعلی هیچ تضمینی نسبت به در دسترس بودن دائمی سرویس داده نمی‌شود.",
            ],
          },
        ]}
      />
    </>
  );
}
