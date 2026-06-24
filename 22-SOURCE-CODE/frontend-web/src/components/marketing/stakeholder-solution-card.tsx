import type { ReactNode } from "react";

// CC-57R — Stakeholder solution card. Photo panel on top + content on
// the bottom. Used four times in the Solutions section.

interface Props {
  /** Photo-like panel component (StakeholderPanels.*) */
  visual: ReactNode;
  badge: string;
  title: string;
  description: string;
  bullets: string[];
}

export function StakeholderSolutionCard({
  visual,
  badge,
  title,
  description,
  bullets,
}: Props) {
  return (
    <article
      className="flex h-full flex-col overflow-hidden rounded-3xl border border-border-soft bg-card text-right transition-shadow hover:shadow-elevated"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <div className="relative h-44 sm:h-52">{visual}</div>
      <div className="flex flex-1 flex-col gap-3 p-5">
        <div className="inline-flex items-center self-end rounded-full bg-brand-50 px-3 py-1 text-[10px] font-semibold tracking-[0.15em] text-brand-700">
          {badge}
        </div>
        <h3 className="text-lg font-bold tracking-tight text-deep-navy">
          {title}
        </h3>
        <p className="text-sm leading-7 text-muted-foreground">{description}</p>
        <ul className="mt-auto space-y-1.5 text-sm text-deep-navy-soft">
          {bullets.map((b) => (
            <li key={b} className="flex gap-2">
              <span
                aria-hidden
                className="mt-2 inline-block size-1.5 shrink-0 rounded-full bg-brand-500"
              />
              <span>{b}</span>
            </li>
          ))}
        </ul>
      </div>
    </article>
  );
}
