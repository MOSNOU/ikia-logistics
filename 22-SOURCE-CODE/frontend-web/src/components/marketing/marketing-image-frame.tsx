import type { ReactNode } from "react";

// CC-57 — Image slot for the public landing.
//
// Design contract:
//   * `src` is OPTIONAL. When omitted (or empty), the frame renders ONLY
//     the `fallback` slot — no <img> tag, no network request, no broken-
//     image icon. This is the default state in CC-57 because the public/
//     marketing/ image files do not yet exist in the repo.
//   * When a future contributor drops a real image into the canonical path
//     (see public/marketing/README.md), the caller passes `src` and the
//     frame renders an <img> overlay above the fallback. The fallback is
//     left in the DOM as a graceful degradation if the image is missing or
//     fails to load.
//
// This component is pure server-renderable React — no state, no effects,
// no "use client". Performance-friendly: lazy-load, async decode, intrinsic
// width/height implied via the wrapper aspect ratio.

interface Props {
  /** Public path under /public, e.g. "/marketing/hero-control-tower.webp". */
  src?: string | null;
  /** Persian alt text describing the image content. */
  alt?: string;
  /** Wrapper className — set aspect ratio + rounding here. */
  className?: string;
  /** Original CSS/SVG visual rendered when `src` is absent. */
  fallback: ReactNode;
}

export function MarketingImageFrame({
  src,
  alt = "",
  className = "",
  fallback,
}: Props) {
  return (
    <div className={`relative overflow-hidden ${className}`}>
      {/* Fallback always renders — supplies the visual when there is no
          image, and supplies a safety net behind the image when there is. */}
      <div className="absolute inset-0">{fallback}</div>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={src}
          alt={alt}
          loading="lazy"
          decoding="async"
          className="relative h-full w-full object-cover"
        />
      ) : null}
    </div>
  );
}
