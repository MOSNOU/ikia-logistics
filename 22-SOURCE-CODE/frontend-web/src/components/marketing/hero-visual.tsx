// CC-56 — Original hero illustration for the iKIA Logistics public landing.
// Pure inline SVG, server-renderable, zero external assets. Depicts an
// abstract logistics-operating-system network: a central "control" node
// (Iran), four orbital hubs (corridor endpoints), connecting curves, and
// a highlighted active route. No Forto assets, paths, or visual motifs.

export function HeroVisual({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 560 420"
      role="img"
      aria-label="نمای انتزاعی شبکه عملیات لجستیک iKIA"
      className={className}
    >
      <defs>
        <radialGradient id="ikia-hero-bg" cx="50%" cy="40%" r="65%">
          <stop offset="0%" stopColor="oklch(0.95 0.04 250)" stopOpacity="1" />
          <stop offset="100%" stopColor="oklch(1 0 0)" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="ikia-hero-route" x1="0%" y1="50%" x2="100%" y2="50%">
          <stop offset="0%" stopColor="oklch(0.55 0.18 250)" stopOpacity="0.15" />
          <stop offset="100%" stopColor="oklch(0.55 0.18 250)" stopOpacity="1" />
        </linearGradient>
        <linearGradient id="ikia-hero-route-quiet" x1="0%" y1="50%" x2="100%" y2="50%">
          <stop offset="0%" stopColor="oklch(0.7 0.04 250)" stopOpacity="0.4" />
          <stop offset="100%" stopColor="oklch(0.7 0.04 250)" stopOpacity="0.2" />
        </linearGradient>
        <pattern
          id="ikia-hero-grid"
          x="0"
          y="0"
          width="40"
          height="40"
          patternUnits="userSpaceOnUse"
        >
          <path
            d="M 40 0 L 0 0 0 40"
            fill="none"
            stroke="oklch(0.94 0 0)"
            strokeWidth="1"
          />
        </pattern>
      </defs>

      <rect width="560" height="420" fill="url(#ikia-hero-bg)" />
      <rect width="560" height="420" fill="url(#ikia-hero-grid)" opacity="0.6" />

      {/* Quiet routes — three faded curves between orbital hubs. */}
      <path
        d="M 100 120 Q 280 30 460 130"
        fill="none"
        stroke="url(#ikia-hero-route-quiet)"
        strokeWidth="1.5"
        strokeDasharray="4 6"
      />
      <path
        d="M 90 290 Q 280 380 470 290"
        fill="none"
        stroke="url(#ikia-hero-route-quiet)"
        strokeWidth="1.5"
        strokeDasharray="4 6"
      />
      <path
        d="M 100 120 Q 70 210 90 290"
        fill="none"
        stroke="url(#ikia-hero-route-quiet)"
        strokeWidth="1.5"
        strokeDasharray="4 6"
      />
      <path
        d="M 460 130 Q 490 210 470 290"
        fill="none"
        stroke="url(#ikia-hero-route-quiet)"
        strokeWidth="1.5"
        strokeDasharray="4 6"
      />

      {/* Active route from a hub through the central control to another hub. */}
      <path
        d="M 100 120 Q 200 200 280 210 Q 380 220 470 290"
        fill="none"
        stroke="url(#ikia-hero-route)"
        strokeWidth="2.5"
        strokeLinecap="round"
      />

      {/* Central control node — iKIA operating system. */}
      <circle
        cx="280"
        cy="210"
        r="48"
        fill="oklch(1 0 0)"
        stroke="oklch(0.55 0.18 250)"
        strokeWidth="1.5"
      />
      <circle cx="280" cy="210" r="28" fill="oklch(0.55 0.18 250)" />
      <circle cx="280" cy="210" r="10" fill="oklch(1 0 0)" />

      {/* Orbital hubs — corridor endpoints. */}
      <g>
        <circle cx="100" cy="120" r="10" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <circle cx="460" cy="130" r="10" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <circle cx="90" cy="290" r="10" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <circle cx="470" cy="290" r="10" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
      </g>

      {/* Small marker dots along the active route. */}
      <g>
        <circle cx="180" cy="180" r="3.5" fill="oklch(0.55 0.18 250)" />
        <circle cx="380" cy="240" r="3.5" fill="oklch(0.55 0.18 250)" />
      </g>
    </svg>
  );
}
