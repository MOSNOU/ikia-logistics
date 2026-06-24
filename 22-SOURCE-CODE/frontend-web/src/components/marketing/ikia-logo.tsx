// CC-57R — Original iKIA Logistics logo mark.
//
// Composition: triangular route/network symbol (3 connected nodes with
// inner pulse) + "iKIA" wordmark + small "LOGISTICS" descriptor + optional
// Persian sub-text «آی‌کیا لجستیک». Pure inline SVG, no external assets,
// no copied brand glyph. Works on white and on deep-navy backgrounds via
// the `tone` prop.

type Tone = "dark" | "light";

interface Props {
  tone?: Tone;
  /** Render the Persian sub-mark below the wordmark. Default: true. */
  withPersian?: boolean;
  /** Wrapper className for sizing. */
  className?: string;
}

export function IkiaLogo({
  tone = "dark",
  withPersian = true,
  className = "",
}: Props) {
  const ink = tone === "dark" ? "var(--color-deep-navy)" : "oklch(1 0 0)";
  const inkMuted =
    tone === "dark" ? "var(--color-deep-navy-soft)" : "var(--color-night-text-muted)";
  const accent = "var(--color-brand-500)";

  return (
    <div className={`flex items-center gap-2.5 ${className}`}>
      <svg
        viewBox="0 0 40 40"
        role="img"
        aria-label="نشانه iKIA Logistics"
        className="size-9 shrink-0"
      >
        {/* Outer triangle — abstract route network. */}
        <path
          d="M 20 4 L 36 32 L 4 32 Z"
          fill="none"
          stroke={accent}
          strokeWidth="2"
          strokeLinejoin="round"
        />
        {/* Inner pulse triangle. */}
        <path
          d="M 20 14 L 28 28 L 12 28 Z"
          fill={accent}
          opacity="0.18"
        />
        {/* Three corner nodes — the network endpoints. */}
        <circle cx="20" cy="4" r="2.5" fill={accent} />
        <circle cx="36" cy="32" r="2.5" fill={accent} />
        <circle cx="4" cy="32" r="2.5" fill={accent} />
        {/* Center node — control hub. */}
        <circle cx="20" cy="23" r="3" fill={ink} />
      </svg>
      <div className="flex flex-col leading-tight">
        <div className="flex items-baseline gap-1.5">
          <span
            className="text-[15px] font-bold tracking-tight"
            style={{ color: ink }}
          >
            iKIA
          </span>
          <span
            className="text-[10px] font-semibold tracking-[0.18em] uppercase"
            style={{ color: inkMuted }}
          >
            Logistics
          </span>
        </div>
        {withPersian ? (
          <span
            className="text-[10px] font-medium tracking-tight"
            style={{ color: inkMuted }}
          >
            آی‌کیا لجستیک
          </span>
        ) : null}
      </div>
    </div>
  );
}
