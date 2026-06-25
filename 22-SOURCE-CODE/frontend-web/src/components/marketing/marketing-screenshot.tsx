import Image from "next/image";

// CC-57RI — Elegant frame for the real marketing screenshots placed under
// /public/marketing/. Uses next/image so the browser receives an
// optimised WebP/AVIF at the right viewport size and lazy-loads the
// below-the-fold imagery automatically.
//
// All images are static assets — no client state, no fetches, no
// "use client". A figure/figcaption pair keeps the captions accessible
// to screen readers and search engines.

interface Props {
  /** Public path under /public, e.g. "/marketing/01-...png". */
  src: string;
  /** Persian alt text describing the screenshot. */
  alt: string;
  /** Natural pixel width — used by next/image to compute the aspect ratio. */
  width: number;
  /** Natural pixel height. */
  height: number;
  /** Optional Persian caption shown beneath the frame. */
  caption?: string;
  /** Set true for the above-the-fold hero image. Disables lazy-loading. */
  priority?: boolean;
  /** Optional sizes hint for the responsive srcset. */
  sizes?: string;
  className?: string;
  /**
   * CC-58A — optional overlay slot rendered absolutely on top of the
   * image but inside the rounded-border frame. Used for the official
   * iKIA logo branding patch on the hero truck.
   */
  children?: React.ReactNode;
}

export function MarketingScreenshot({
  src,
  alt,
  width,
  height,
  caption,
  priority = false,
  sizes,
  className = "",
  children,
}: Props) {
  return (
    <figure className={className}>
      <div
        className="relative overflow-hidden rounded-3xl border border-border-soft bg-card p-1.5 sm:p-2"
        style={{ boxShadow: "var(--shadow-elevated)" }}
      >
        <Image
          src={src}
          alt={alt}
          width={width}
          height={height}
          priority={priority}
          sizes={
            sizes ?? "(max-width: 768px) 100vw, (max-width: 1280px) 90vw, 1200px"
          }
          className="block h-auto w-full rounded-2xl"
        />
        {children}
      </div>
      {caption ? (
        <figcaption className="mt-3 text-center text-xs leading-6 text-deep-navy-soft">
          {caption}
        </figcaption>
      ) : null}
    </figure>
  );
}
