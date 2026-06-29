import { Factory, Fuel, Wheat, ShoppingCart, Construction, Globe } from "lucide-react";
import { Section, SectionHeading } from "@/components/ui/Section";

const INDUSTRIES = [
  { icon: Factory, label: "فولاد و معدن" },
  { icon: Fuel, label: "نفت و پتروشیمی" },
  { icon: Wheat, label: "کشاورزی و مواد غذایی" },
  { icon: ShoppingCart, label: "کالاهای مصرفی" },
  { icon: Construction, label: "پروژه‌های صنعتی" },
  { icon: Globe, label: "صادرات و واردات" },
];

export function Industries() {
  return (
    <Section tone="soft">
      <SectionHeading
        eyebrow="Industries"
        title="ساخته‌شده برای صنایع و بازرگانی"
        subtitle="iKIA برای جریان واقعی کالا در صنایع کلیدی و تجارت منطقه‌ای طراحی شده است."
      />
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {INDUSTRIES.map((it) => (
          <div
            key={it.label}
            className="flex flex-col items-center gap-3 rounded-2xl border border-line bg-white p-5 text-center transition-all hover:-translate-y-0.5 hover:border-blue/30 hover:shadow-[0_10px_30px_-12px_rgba(11,111,181,0.25)]"
          >
            <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-soft-2 text-blue ring-1 ring-line">
              <it.icon className="h-5 w-5" strokeWidth={1.75} aria-hidden />
            </span>
            <span className="text-sm font-bold text-ink">{it.label}</span>
          </div>
        ))}
      </div>
    </Section>
  );
}
