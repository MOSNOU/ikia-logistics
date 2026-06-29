import type { Metadata } from "next";
import { PersonaLanding } from "@/components/sections/PersonaLanding";
import { CARRIERS } from "@/content/personas";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { PRODUCT_URLS } from "@/content/navigation";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({ ...CARRIERS.seo, path: "/carriers" });

export default function Page() {
  return (
    <>
      <PersonaLanding persona={CARRIERS} />

      {/* PWA explanation placeholder (carrier.ikialogistic.com target). */}
      <Section tone="surface">
        <SectionHeading
          eyebrow="اپ موبایل کریر"
          title="نسخه نصب‌شدنی (PWA) — در مسیر توسعه"
          subtitle="اپ کریر به‌صورت Progressive Web App طراحی می‌شود تا بدون نیاز به استور، مستقیم روی گوشی نصب شود."
        />
        <div className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-6 text-center">
          <p className="text-sm leading-8 text-slate-600">
            نسخه نهایی روی دامنه اختصاصی کریر ارائه خواهد شد:
            <span className="mx-1 font-black text-[#1e3a5f]" dir="ltr">
              carrier.ikialogistic.com
            </span>
            . تا آن زمان می‌توانید از طریق ورود کریر به پنل دسترسی داشته باشید.
          </p>
          <div className="mt-5 flex justify-center">
            <Button href={PRODUCT_URLS.login} variant="primary" size="md">
              ورود کریر
            </Button>
          </div>
        </div>
      </Section>
    </>
  );
}
