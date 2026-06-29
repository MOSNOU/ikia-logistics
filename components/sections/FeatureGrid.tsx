import type { Capability } from "@/content/types";
import { FeatureCard } from "@/components/ui/Card";

export function FeatureGrid({ items }: { items: Capability[] }) {
  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
      {items.map((item) => (
        <FeatureCard key={item.title} icon={item.icon} title={item.title} desc={item.desc} />
      ))}
    </div>
  );
}
