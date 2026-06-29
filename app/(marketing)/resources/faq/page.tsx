import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { FAQAccordion } from "@/components/sections/FAQAccordion";
import { FAQ_ITEMS } from "@/content/faq";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "سوالات متداول iKIA",
  description: "پاسخ پرسش‌های رایج درباره iKIA: کاربران، اپ کریر، پرداخت، مرحله MVP و حفاظت از داده‌ها.",
  path: "/resources/faq",
});

export default function FAQPage() {
  return (
    <>
      <PageHero eyebrow="سوالات متداول" title="پرسش‌های پرتکرار" subtitle="پاسخ کوتاه و شفاف به رایج‌ترین سوال‌ها." />
      <Section tone="light">
        <FAQAccordion items={FAQ_ITEMS} />
      </Section>
    </>
  );
}
