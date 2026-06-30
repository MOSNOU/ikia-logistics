import type { Metadata } from "next";
import { Hero } from "@/components/sections/Hero";
import { ProofStrip } from "@/components/sections/ProofStrip";
import { LogisticsOS } from "@/components/sections/LogisticsOS";
import { ControlTower } from "@/components/sections/ControlTower";
import { CorridorNetwork } from "@/components/sections/CorridorNetwork";
import { Industries } from "@/components/sections/Industries";
import { FinalCTA } from "@/components/sections/FinalCTA";
import { ModuleGrid } from "@/components/sections/ModuleGrid";
import { Section, SectionHeading } from "@/components/ui/Section";
import { Button } from "@/components/ui/Button";
import { HOME_PLATFORM, HOME_FREIGHT } from "@/content/siteArchitecture";
import { buildMetadata } from "@/lib/seo";

export const metadata: Metadata = buildMetadata({
  title: "iKIA Logistic | سیستم‌عامل دیجیتال لجستیک",
  description:
    "iKIA صاحبان بار، حمل‌کننده‌ها، مراکز لجستیک و سازمان‌ها را در یک زیرساخت واحد به هم وصل می‌کند: مدیریت سفارش، رهگیری لحظه‌ای، اسناد و انطباق، کریدورها و تسویه.",
  path: "/",
});

export default function HomePage() {
  return (
    <>
      <Hero />

      <ProofStrip />

      <LogisticsOS />

      {/* Platform modules */}
      <Section tone="light">
        <SectionHeading
          eyebrow="Platform"
          title="پلتفرمی که عملیات را یکپارچه می‌کند"
          subtitle="ماژول‌های iKIA روی یک هسته مشترک کار می‌کنند؛ از مدیریت سفارش و رهگیری تا اسناد، انطباق و اتصال سامانه‌ها."
        />
        <ModuleGrid modules={HOME_PLATFORM} featuredCount={1} />
        <div className="mt-12 text-center">
          <Button href="/platform" variant="outline" size="md">
            مشاهده کامل پلتفرم
          </Button>
        </div>
      </Section>

      <ControlTower />

      {/* Freight modes */}
      <Section tone="soft">
        <SectionHeading
          eyebrow="Freight"
          title="چهار شیوه حمل، یک جریان عملیاتی"
          subtitle="حمل جاده‌ای، ریلی، دریایی و هوایی به‌صورت چندوجهی و یکپارچه روی شبکه کریدورها."
        />
        <ModuleGrid modules={HOME_FREIGHT} />
        <div className="mt-12 text-center">
          <Button href="/freight" variant="outline" size="md">
            خدمات حمل
          </Button>
        </div>
      </Section>

      <CorridorNetwork />

      <Industries />

      <FinalCTA />
    </>
  );
}
