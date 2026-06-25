// CC-57R / CC-60 — Shared eyebrow + title + intro composition for
// marketing sections. Server-renderable, pure presentational.
// CC-60 polish: bumped h2 sizes one step up (text-2xl → text-3xl base,
// sm → text-4xl) and gave the intro a slightly looser line-height for
// executive-grade Persian reading on long-form RTL paragraphs.

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
    <div className={`max-w-3xl space-y-4 ${alignClass} ${className}`}>
      <div
        className={`inline-flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.18em] ${eyebrowColor}`}
      >
        <span className="inline-block size-1.5 rounded-full bg-current" />
        {eyebrow}
      </div>
      <h2
        className={`text-3xl font-bold leading-snug tracking-tight sm:text-4xl ${titleColor}`}
      >
        {title}
      </h2>
      {intro ? (
        <p className={`text-base leading-8 sm:text-lg sm:leading-9 ${introColor}`}>
          {intro}
        </p>
      ) : null}
    </div>
  );
}
