import type { ReactNode } from "react";

// CC-57R — Transport-mode service card. Photo panel on top + brief text +
// optional capability bullets.

interface Props {
  visual: ReactNode;
  title: string;
  description: string;
  tags: string[];
}

export function TransportServiceCard({
  visual,
  title,
  description,
  tags,
}: Props) {
  return (
    <article
      className="group flex h-full flex-col overflow-hidden rounded-3xl border border-border-soft bg-card text-right transition-shadow hover:shadow-elevated"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <div className="relative h-40 sm:h-44">{visual}</div>
      <div className="flex flex-1 flex-col gap-2 p-5">
        <h3 className="text-base font-bold tracking-tight text-deep-navy">
          {title}
        </h3>
        <p className="flex-1 text-xs leading-6 text-muted-foreground">
          {description}
        </p>
        <ul className="flex flex-wrap gap-1.5 pt-1">
          {tags.map((t) => (
            <li
              key={t}
              className="rounded-full border border-brand-100 bg-brand-50 px-2 py-0.5 text-[10px] font-medium text-brand-700"
            >
              {t}
            </li>
          ))}
        </ul>
      </div>
    </article>
  );
}
