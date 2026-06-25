import { Children } from "react";

// CC-65 — Server-renderable, dependency-free marquee track.
//
// Renders its children twice inside a flex track so a single CSS
// keyframe animation (`ikia-marquee` in globals.css) can translate the
// track by -50% and loop without a visible seam.
//
// Behaviors driven entirely from CSS:
//   • Continuous right-to-left motion (always physical, so it reads as
//     right→left under RTL document direction too).
//   • Pauses on hover / focus-within for accessibility.
//   • Honors `prefers-reduced-motion: reduce` — animation disabled and
//     the track stays put.
//
// No "use client", no JS state, no hydration risk. Cards keep their
// natural width via `cardWidthClassName` so the row doesn't collapse on
// narrow viewports.

interface Props {
  /** Cards (or any nodes) to render in the scrolling track. */
  children: React.ReactNode;
  /**
   * Tailwind width utility applied to each card slot (e.g.
   * `w-[280px] sm:w-[320px] lg:w-[360px]`). The marquee track is
   * `flex-nowrap`, so explicit widths prevent shrinkage.
   */
  cardWidthClassName?: string;
  /** Extra classes on the outer overflow-hidden viewport. */
  className?: string;
  /** Optional `aria-label` for the scrolling region. */
  ariaLabel?: string;
}

export function MarketingMarquee({
  children,
  cardWidthClassName = "w-[280px] sm:w-[320px] lg:w-[360px]",
  className = "",
  ariaLabel,
}: Props) {
  const items = Children.toArray(children);

  // Render the same set twice. The CSS animation moves the track by
  // exactly -50% so the second set lands where the first started,
  // producing a seamless loop.
  const renderTrackHalf = (keyPrefix: string) =>
    items.map((node, idx) => (
      <div
        key={`${keyPrefix}-${idx}`}
        className={`shrink-0 ${cardWidthClassName}`}
        aria-hidden={keyPrefix === "dup" ? true : undefined}
      >
        {node}
      </div>
    ));

  return (
    <div
      role="region"
      aria-label={ariaLabel}
      className={`relative overflow-hidden ${className}`}
    >
      <div
        className="ikia-marquee-track flex w-max flex-nowrap gap-5 will-change-transform"
        dir="ltr"
      >
        {renderTrackHalf("a")}
        {renderTrackHalf("dup")}
      </div>
    </div>
  );
}
