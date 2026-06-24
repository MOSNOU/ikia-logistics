// CC-56 — Original abstract corridor map.
// Stylized geometric "compass" with Iran as the central hub and four
// directional routes labelled in Persian: north (آستارا), south
// (بندرعباس), east (مشهد/سرخس), west (تبریز/بازرگان). No accurate map
// outline is rendered. Pure inline SVG, server-renderable, original.

export function CorridorVisual({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 560 360"
      role="img"
      aria-label="نمای انتزاعی کریدورهای ترانزیتی ایران"
      className={className}
    >
      <defs>
        <pattern
          id="corridor-grid"
          x="0"
          y="0"
          width="32"
          height="32"
          patternUnits="userSpaceOnUse"
        >
          <path
            d="M 32 0 L 0 0 0 32"
            fill="none"
            stroke="oklch(0.94 0 0)"
            strokeWidth="1"
          />
        </pattern>
        <linearGradient id="corridor-line-active" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="oklch(0.55 0.18 250)" stopOpacity="0.4" />
          <stop offset="100%" stopColor="oklch(0.55 0.18 250)" stopOpacity="1" />
        </linearGradient>
      </defs>

      <rect width="560" height="360" fill="url(#corridor-grid)" opacity="0.6" />

      {/* Four corridors radiating from the center. */}
      <g stroke="url(#corridor-line-active)" strokeWidth="2" fill="none" strokeLinecap="round">
        <path d="M 280 180 L 90 80" />
        <path d="M 280 180 L 470 80" />
        <path d="M 280 180 L 90 280" />
        <path d="M 280 180 L 470 280" />
      </g>

      {/* Endpoint markers + labels. */}
      <g fontFamily="inherit" fontSize="13" fill="oklch(0.205 0 0)">
        <circle cx="90" cy="80" r="9" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <text x="56" y="62" textAnchor="middle">شمال — آستارا</text>

        <circle cx="470" cy="80" r="9" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <text x="490" y="62" textAnchor="middle">شرق — مشهد / سرخس</text>

        <circle cx="90" cy="280" r="9" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <text x="60" y="312" textAnchor="middle">غرب — تبریز / بازرگان</text>

        <circle cx="470" cy="280" r="9" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
        <text x="490" y="312" textAnchor="middle">جنوب — بندرعباس</text>
      </g>

      {/* Central hub — Iran control. */}
      <circle cx="280" cy="180" r="36" fill="oklch(1 0 0)" stroke="oklch(0.55 0.18 250)" strokeWidth="1.5" />
      <circle cx="280" cy="180" r="20" fill="oklch(0.55 0.18 250)" />
      <text
        x="280"
        y="184"
        textAnchor="middle"
        fontFamily="inherit"
        fontSize="11"
        fontWeight="600"
        fill="oklch(1 0 0)"
      >
        iKIA
      </text>
    </svg>
  );
}
