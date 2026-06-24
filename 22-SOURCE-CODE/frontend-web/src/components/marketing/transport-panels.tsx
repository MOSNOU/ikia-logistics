// CC-57R — Five transport-mode photo-style panels (road / sea / rail /
// air / warehouse). Each panel renders a gradient sky+ground with a
// silhouette of the vehicle or asset. Original CSS+SVG geometry only.

interface PanelProps {
  className?: string;
}

export function RoadPanel({ className = "" }: PanelProps) {
  return (
    <div className={`relative h-full w-full overflow-hidden ${className}`}>
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="road-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.94 0.05 230)" />
            <stop offset="100%" stopColor="oklch(0.85 0.10 230)" />
          </linearGradient>
        </defs>
        <rect width="320" height="120" fill="url(#road-sky)" />
        <rect y="120" width="320" height="80" fill="oklch(0.30 0.05 245)" />
        <path d="M 0 120 L 80 100 L 160 108 L 240 92 L 320 110 L 320 120 Z" fill="oklch(0.40 0.06 240)" opacity="0.6" />
        <line x1="0" y1="160" x2="320" y2="160" stroke="oklch(1 0 0)" strokeWidth="2" strokeDasharray="14 12" opacity="0.75" />
        {/* Big truck centred. */}
        <g transform="translate(70 132)">
          <rect x="0" y="0" width="120" height="30" rx="3" fill="oklch(0.55 0.18 250)" />
          <rect x="120" y="6" width="38" height="24" rx="3" fill="oklch(0.34 0.18 250)" />
          <rect x="124" y="10" width="20" height="12" rx="2" fill="oklch(0.85 0.06 230)" />
          <circle cx="22" cy="34" r="6" fill="oklch(0.16 0.02 245)" />
          <circle cx="64" cy="34" r="6" fill="oklch(0.16 0.02 245)" />
          <circle cx="138" cy="34" r="6" fill="oklch(0.16 0.02 245)" />
        </g>
      </svg>
    </div>
  );
}

export function SeaPanel({ className = "" }: PanelProps) {
  return (
    <div className={`relative h-full w-full overflow-hidden ${className}`}>
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="sea-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.95 0.04 230)" />
            <stop offset="100%" stopColor="oklch(0.82 0.10 230)" />
          </linearGradient>
          <linearGradient id="sea-water" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.55 0.13 230)" />
            <stop offset="100%" stopColor="oklch(0.30 0.12 240)" />
          </linearGradient>
        </defs>
        <rect width="320" height="110" fill="url(#sea-sky)" />
        <rect y="110" width="320" height="90" fill="url(#sea-water)" />
        <g stroke="oklch(0.96 0.02 230)" strokeWidth="1.2" opacity="0.45" fill="none">
          <path d="M 0 140 Q 40 134 80 140 T 160 140 T 240 140 T 320 140" />
          <path d="M 0 170 Q 50 164 100 170 T 200 170 T 320 170" />
        </g>
        {/* Container ship */}
        <g transform="translate(60 100)">
          <path d="M -10 30 L 200 30 L 180 56 L 10 56 Z" fill="oklch(0.20 0.04 245)" />
          <rect x="-6" y="14" width="200" height="18" fill="oklch(0.36 0.04 245)" />
          {[0,1,2,3,4,5,6,7,8].map((i) => (
            <rect
              key={i}
              x={-2 + i * 22}
              y="-4"
              width="20"
              height="18"
              fill={
                i % 3 === 0
                  ? "oklch(0.65 0.18 145)"
                  : i % 3 === 1
                    ? "oklch(0.55 0.18 250)"
                    : "oklch(0.78 0.18 80)"
              }
            />
          ))}
          <rect x="140" y="-26" width="42" height="22" fill="oklch(0.96 0.02 230)" />
          <rect x="144" y="-22" width="34" height="12" fill="oklch(0.55 0.13 230)" />
        </g>
      </svg>
    </div>
  );
}

export function RailPanel({ className = "" }: PanelProps) {
  return (
    <div className={`relative h-full w-full overflow-hidden ${className}`}>
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="rail-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.93 0.04 240)" />
            <stop offset="100%" stopColor="oklch(0.80 0.06 240)" />
          </linearGradient>
        </defs>
        <rect width="320" height="120" fill="url(#rail-sky)" />
        <rect y="120" width="320" height="80" fill="oklch(0.40 0.04 250)" />
        {/* Distant mountains. */}
        <path d="M 0 120 L 50 96 L 90 108 L 160 78 L 220 100 L 320 80 L 320 120 Z" fill="oklch(0.34 0.04 240)" opacity="0.65" />
        {/* Rails. */}
        <g stroke="oklch(0.20 0.02 250)" strokeWidth="3">
          <line x1="0" y1="166" x2="320" y2="166" />
          <line x1="0" y1="178" x2="320" y2="178" />
        </g>
        {/* Sleepers. */}
        <g fill="oklch(0.30 0.04 90)">
          {Array.from({ length: 18 }).map((_, i) => (
            <rect key={i} x={i * 20} y="170" width="14" height="6" />
          ))}
        </g>
        {/* Train */}
        <g transform="translate(40 122)">
          {/* Locomotive */}
          <rect x="0" y="0" width="56" height="34" rx="3" fill="oklch(0.45 0.18 250)" />
          <rect x="40" y="-10" width="14" height="14" fill="oklch(0.45 0.18 250)" />
          <rect x="6" y="6" width="28" height="14" rx="2" fill="oklch(0.85 0.06 230)" />
          {/* Wagons */}
          {[0, 1, 2].map((i) => (
            <rect
              key={i}
              x={60 + i * 70}
              y="0"
              width="64"
              height="34"
              rx="3"
              fill={
                i % 2 === 0 ? "oklch(0.36 0.04 250)" : "oklch(0.30 0.04 250)"
              }
            />
          ))}
          {/* Wheels */}
          {[0,1,2,3,4,5,6,7,8,9,10,11].map((i) => (
            <circle key={i} cx={10 + i * 25} cy="42" r="5" fill="oklch(0.16 0.02 245)" />
          ))}
        </g>
      </svg>
    </div>
  );
}

export function AirPanel({ className = "" }: PanelProps) {
  return (
    <div className={`relative h-full w-full overflow-hidden ${className}`}>
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="air-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.65 0.16 230)" />
            <stop offset="100%" stopColor="oklch(0.92 0.06 230)" />
          </linearGradient>
        </defs>
        <rect width="320" height="200" fill="url(#air-sky)" />
        {/* Clouds. */}
        <g fill="oklch(1 0 0)" opacity="0.45">
          <ellipse cx="60" cy="80" rx="40" ry="10" />
          <ellipse cx="220" cy="56" rx="56" ry="12" />
          <ellipse cx="120" cy="160" rx="30" ry="8" />
          <ellipse cx="280" cy="138" rx="44" ry="10" />
        </g>
        {/* Airplane. */}
        <g transform="translate(100 100) rotate(-12)">
          <path d="M 0 0 L 90 -4 L 110 0 L 90 4 Z" fill="oklch(0.96 0.02 240)" />
          <path d="M 36 -2 L 56 -22 L 64 -22 L 46 -2 Z" fill="oklch(0.96 0.02 240)" />
          <path d="M 36 2 L 56 22 L 64 22 L 46 2 Z" fill="oklch(0.96 0.02 240)" />
          <path d="M 78 -2 L 90 -8 L 96 -6 L 90 -2 Z" fill="oklch(0.55 0.18 250)" />
          {/* Cockpit windows */}
          <rect x="92" y="-2" width="14" height="3" fill="oklch(0.30 0.05 245)" />
          {/* Contrail */}
          <path d="M 0 0 L -120 4" stroke="oklch(1 0 0)" strokeWidth="3" strokeLinecap="round" opacity="0.7" />
        </g>
      </svg>
    </div>
  );
}

export function WarehousePanel({ className = "" }: PanelProps) {
  return (
    <div className={`relative h-full w-full overflow-hidden ${className}`}>
      <svg viewBox="0 0 320 200" className="block h-full w-full" preserveAspectRatio="xMidYMid slice" aria-hidden>
        <defs>
          <linearGradient id="wh-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.92 0.04 230)" />
            <stop offset="100%" stopColor="oklch(0.80 0.06 230)" />
          </linearGradient>
        </defs>
        <rect width="320" height="120" fill="url(#wh-sky)" />
        <rect y="120" width="320" height="80" fill="oklch(0.35 0.04 245)" />
        {/* Warehouse building */}
        <g transform="translate(30 60)">
          <rect x="0" y="20" width="200" height="60" fill="oklch(0.96 0.02 230)" />
          <path d="M 0 20 L 100 0 L 200 20 Z" fill="oklch(0.55 0.18 250)" />
          <rect x="20" y="40" width="40" height="40" fill="oklch(0.20 0.04 245)" />
          <rect x="70" y="50" width="30" height="20" fill="oklch(0.85 0.06 230)" />
          <rect x="110" y="50" width="30" height="20" fill="oklch(0.85 0.06 230)" />
          <rect x="150" y="50" width="30" height="20" fill="oklch(0.85 0.06 230)" />
        </g>
        {/* Container stacks. */}
        <g transform="translate(230 110)">
          {[
            { y: 24, c: "oklch(0.55 0.18 250)" },
            { y: 24, x2: 30, c: "oklch(0.65 0.18 145)" },
            { y: 4, c: "oklch(0.78 0.18 80)" },
            { y: 4, x2: 30, c: "oklch(0.55 0.18 250)" },
            { y: -16, c: "oklch(0.65 0.18 145)" },
          ].map((b, i) => (
            <rect
              key={i}
              x={b.x2 ?? 0}
              y={b.y}
              width="26"
              height="18"
              fill={b.c}
            />
          ))}
        </g>
      </svg>
    </div>
  );
}
