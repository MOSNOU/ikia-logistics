import type { Metadata } from "next";
import { PageHero } from "@/components/sections/PageHero";
import { Section } from "@/components/ui/Section";
import { ContactForm } from "@/components/sections/ContactForm";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "تماس با iKIA",
  description: "با تیم iKIA Logistics در ارتباط باشید؛ برای دمو، همکاری یا پرسش.",
  path: "/contact",
});

export default function ContactPage() {
  return (
    <>
      <PageHero
        eyebrow="تماس با ما"
        title="با تیم iKIA در ارتباط باشید"
        subtitle="برای درخواست دمو، همکاری یا هر پرسشی، پیام بگذارید."
      />
      <Section tone="light">
        <ContactForm />
      </Section>
    </>
  );
}
