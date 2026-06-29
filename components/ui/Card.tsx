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
      className={`rounded-2xl border border-slate-200/80 bg-white p-7 shadow-[0_1px_3px_rgba(7,26,45,0.04)] ${
        hover ? "transition-all duration-200 hover:-translate-y-1 hover:border-brand-200 hover:shadow-[0_12px_40px_-12px_rgba(11,92,173,0.25)]" : ""
      } ${className}`}
    >
      {children}
    </div>
  );
}

// SaaS-style feature card: icon tile + title + description.
export function FeatureCard({ icon, title, desc }: { icon: string; title: string; desc: string }) {
  return (
    <Card className="group h-full">
      <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-xl bg-brand-50 text-brand-600 ring-1 ring-brand-100 transition-colors group-hover:bg-brand-600 group-hover:text-white">
        <Icon name={icon} className="h-6 w-6" />
      </div>
      <h3 className="mb-2 text-lg font-extrabold text-navy-900">{title}</h3>
      <p className="text-sm leading-7 text-slate-500">{desc}</p>
    </Card>
  );
}
