import type { ReactNode } from "react";
import { Icon } from "./icons";

export function Card({
  children,
  className = "",
  hover = true,
}: {
  children: ReactNode;
  className?: string;
  hover?: boolean;
}) {
  return (
    <div
      className={`rounded-3xl border border-line bg-white p-7 shadow-[0_1px_2px_rgba(6,26,47,0.04)] ${
        hover ? "transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_18px_44px_-20px_rgba(6,26,47,0.22)]" : ""
      } ${className}`}
    >
      {children}
    </div>
  );
}

// Refined, centered benefit/feature card: icon + title (17px) + body (14px).
export function FeatureCard({ icon, title, desc }: { icon: string; title: string; desc: string }) {
  return (
    <Card className="group flex h-full flex-col items-center text-center">
      <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-2xl bg-soft text-blue ring-1 ring-line transition-colors group-hover:bg-blue group-hover:text-white">
        <Icon name={icon} className="h-6 w-6" />
      </div>
      <h3 className="text-[17px] font-bold leading-snug text-ink">{title}</h3>
      <p className="mt-2.5 text-[14px] leading-7 text-muted">{desc}</p>
    </Card>
  );
}
