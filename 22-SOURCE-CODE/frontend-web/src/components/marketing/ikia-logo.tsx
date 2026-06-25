import Image from "next/image";

// CC-58A — Official iKIA Logistics logo, sourced from the brand asset at
// /public/brand/ikia-logo-signature.png (911×395). Replaces the previous
// inline triangular/abstract mark. Server-renderable; no client state.
//
// Variants:
//   "header" — bare logo at compact height (h-9 / 36 px). Loaded with
//              priority so it lands on the first paint of every public
//              page.
//   "footer" — logo wrapped in a small white rounded card so it keeps
//              contrast on the deep-navy footer background.
//   "mark"   — tiny version for inline use (h-6 / 24 px).
//
// All variants preserve the official aspect ratio; the brand mark is
// never recreated, redrawn, or restyled via CSS/SVG.

const LOGO_SRC = "/brand/ikia-logo-signature.png";
const LOGO_WIDTH = 911;
const LOGO_HEIGHT = 395;
const LOGO_ALT = "iKIA Logistics";

interface Props {
  className?: string;
  variant?: "header" | "footer" | "mark";
}

export function IkiaLogo({ className = "", variant = "header" }: Props) {
  if (variant === "footer") {
    return (
      <div
        className={`inline-flex items-center rounded-xl bg-white px-3 py-2 shadow-sm ${className}`}
      >
        <Image
          src={LOGO_SRC}
          alt={LOGO_ALT}
          width={LOGO_WIDTH}
          height={LOGO_HEIGHT}
          sizes="220px"
          className="h-10 w-auto"
        />
      </div>
    );
  }

  if (variant === "mark") {
    return (
      <Image
        src={LOGO_SRC}
        alt={LOGO_ALT}
        width={LOGO_WIDTH}
        height={LOGO_HEIGHT}
        sizes="80px"
        className={`h-6 w-auto ${className}`}
      />
    );
  }

  // Default: header variant.
  return (
    <Image
      src={LOGO_SRC}
      alt={LOGO_ALT}
      width={LOGO_WIDTH}
      height={LOGO_HEIGHT}
      sizes="180px"
      priority
      className={`h-9 w-auto ${className}`}
    />
  );
}
