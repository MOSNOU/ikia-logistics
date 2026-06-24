// CC-57R — Shared eyebrow + title + intro composition for marketing
// sections. Server-renderable, pure presentational.

interface Props {
  eyebrow: string;
  title: string;
  intro?: string;
  tone?: "dark" | "light";
  align?: "start" | "center";
  className?: string;
}

export function PremiumSectionHeader({
  eyebrow,
  title,
  intro,
  tone = "light",
  align = "start",
  className = "",
}: Props) {
  const titleColor =
    tone === "dark" ? "text-night-text" : "text-deep-navy";
  const introColor =
    tone === "dark" ? "text-night-text-muted" : "text-muted-foreground";
  const eyebrowColor =
    tone === "dark" ? "text-brand-100" : "text-brand-600";
  const alignClass =
    align === "center" ? "text-center mx-auto" : "text-right";

  return (
    <div className={`max-w-2xl space-y-3 ${alignClass} ${className}`}>
      <div
        className={`inline-flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.18em] ${eyebrowColor}`}
      >
        <span className="inline-block size-1.5 rounded-full bg-current" />
        {eyebrow}
      </div>
      <h2
        className={`text-2xl font-bold leading-snug tracking-tight sm:text-3xl ${titleColor}`}
      >
        {title}
      </h2>
      {intro ? (
        <p className={`text-sm leading-7 sm:text-base ${introColor}`}>
          {intro}
        </p>
      ) : null}
    </div>
  );
}
