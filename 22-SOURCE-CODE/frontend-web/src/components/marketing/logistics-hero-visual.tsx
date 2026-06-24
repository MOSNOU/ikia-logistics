// CC-57R — Cinematic logistics hero scene. Original inline SVG; depicts
// a stylized world horizon with route arcs connecting hubs, a truck on a
// ground route, a container ship on the sea line, and an airplane in
// flight. Glassmorphic shipment chip floats over the top right corner.
// Zero external assets, zero copied paths, server-renderable.

export function LogisticsHeroVisual({ className = "" }: { className?: string }) {
  return (
    <div className={`relative overflow-hidden rounded-3xl ${className}`}>
      <svg
        viewBox="0 0 720 540"
        role="img"
        aria-label="نمای ترکیبی شبکه حمل‌ونقل جاده‌ای، دریایی و هوایی iKIA"
        className="block h-full w-full"
        preserveAspectRatio="xMidYMid slice"
      >
        <defs>
          {/* Sky gradient — daylight horizon. */}
          <linearGradient id="hero-sky" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.96 0.02 240)" />
            <stop offset="55%" stopColor="oklch(0.92 0.05 230)" />
            <stop offset="100%" stopColor="oklch(0.84 0.08 220)" />
          </linearGradient>
          {/* Sea gradient. */}
          <linearGradient id="hero-sea" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.55 0.15 230)" />
            <stop offset="100%" stopColor="oklch(0.38 0.13 240)" />
          </linearGradient>
          {/* Land gradient. */}
          <linearGradient id="hero-land" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="oklch(0.93 0.02 100)" />
            <stop offset="100%" stopColor="oklch(0.84 0.04 90)" />
          </linearGradient>
          {/* Glow used for route arcs. */}
          <linearGradient id="hero-arc" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="oklch(0.55 0.18 250)" stopOpacity="0" />
            <stop offset="50%" stopColor="oklch(0.55 0.18 250)" stopOpacity="0.9" />
            <stop offset="100%" stopColor="oklch(0.7 0.15 230)" stopOpacity="0" />
          </linearGradient>
          <linearGradient id="hero-arc-2" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="oklch(0.65 0.18 145)" stopOpacity="0" />
            <stop offset="50%" stopColor="oklch(0.65 0.18 145)" stopOpacity="0.7" />
            <stop offset="100%" stopColor="oklch(0.65 0.18 145)" stopOpacity="0" />
          </linearGradient>
          <pattern
            id="hero-dot-grid"
            x="0"
            y="0"
            width="22"
            height="22"
            patternUnits="userSpaceOnUse"
          >
            <circle cx="2" cy="2" r="1.1" fill="oklch(0.48 0.18 250)" opacity="0.35" />
          </pattern>
        </defs>

        {/* Sky. */}
        <rect width="720" height="320" fill="url(#hero-sky)" />

        {/* World-map dot grid in the sky band. */}
        <rect width="720" height="320" fill="url(#hero-dot-grid)" opacity="0.55" />

        {/* Sea. */}
        <rect y="320" width="720" height="120" fill="url(#hero-sea)" />
        {/* Subtle sea waves. */}
        <g stroke="oklch(0.96 0.02 230)" strokeWidth="1.4" opacity="0.35" fill="none">
          <path d="M 0 360 Q 60 354 120 360 T 240 360 T 360 360 T 480 360 T 600 360 T 720 360" />
          <path d="M 0 388 Q 80 382 160 388 T 320 388 T 480 388 T 640 388 T 720 388" />
          <path d="M 0 414 Q 60 408 120 414 T 240 414 T 360 414 T 480 414 T 600 414 T 720 414" />
        </g>

        {/* Distant island silhouettes. */}
        <g fill="oklch(0.30 0.10 245)" opacity="0.55">
          <path d="M 70 318 Q 110 308 150 318 L 150 322 L 70 322 Z" />
          <path d="M 530 318 Q 600 304 670 318 L 670 322 L 530 322 Z" />
        </g>

        {/* Distant route arcs from west to east, threading hubs. */}
        <g fill="none" strokeWidth="2.2" strokeLinecap="round">
          <path d="M 50 200 C 200 80 480 80 670 180" stroke="url(#hero-arc)" />
          <path d="M 30 250 C 180 160 520 160 680 240" stroke="url(#hero-arc-2)" />
        </g>

        {/* Hub markers along the upper arc. */}
        <g>
          <circle cx="50" cy="200" r="5" fill="oklch(0.55 0.18 250)" />
          <circle cx="200" cy="118" r="5" fill="oklch(0.55 0.18 250)" />
          <circle cx="360" cy="92" r="6" fill="oklch(0.55 0.18 250)" />
          <circle cx="520" cy="118" r="5" fill="oklch(0.55 0.18 250)" />
          <circle cx="670" cy="180" r="5" fill="oklch(0.55 0.18 250)" />
        </g>

        {/* Airplane in flight along the upper arc — original simple shape. */}
        <g transform="translate(420 60) rotate(-12)">
          <path
            d="M 0 0 L 40 -2 L 50 0 L 40 2 Z"
            fill="oklch(0.20 0.04 250)"
          />
          <path
            d="M 18 -1 L 26 -10 L 30 -10 L 22 -1 Z"
            fill="oklch(0.20 0.04 250)"
          />
          <path
            d="M 18 1 L 26 10 L 30 10 L 22 1 Z"
            fill="oklch(0.20 0.04 250)"
          />
          {/* Contrail */}
          <path
            d="M 0 0 L -90 6"
            stroke="oklch(1 0 0)"
            strokeWidth="2"
            opacity="0.7"
            strokeLinecap="round"
          />
        </g>

        {/* Land strip (foreground horizon below sea? Actually we keep land=horizon top of road). */}
        <rect y="440" width="720" height="100" fill="url(#hero-land)" />

        {/* Road with dashed center line. */}
        <line
          x1="0"
          y1="480"
          x2="720"
          y2="480"
          stroke="oklch(0.96 0.02 90)"
          strokeWidth="22"
        />
        <line
          x1="0"
          y1="480"
          x2="720"
          y2="480"
          stroke="oklch(1 0 0)"
          strokeWidth="2"
          strokeDasharray="14 12"
        />

        {/* Truck silhouette on the road. */}
        <g transform="translate(180 442)">
          {/* Trailer */}
          <rect x="0" y="0" width="160" height="38" rx="4" fill="oklch(0.55 0.18 250)" />
          {/* Cab */}
          <rect x="160" y="6" width="44" height="32" rx="4" fill="oklch(0.40 0.18 250)" />
          {/* Window */}
          <rect x="166" y="10" width="20" height="14" rx="2" fill="oklch(0.85 0.06 230)" />
          {/* Wheels */}
          <circle cx="30" cy="42" r="9" fill="oklch(0.18 0.02 250)" />
          <circle cx="78" cy="42" r="9" fill="oklch(0.18 0.02 250)" />
          <circle cx="180" cy="42" r="9" fill="oklch(0.18 0.02 250)" />
          {/* Wheel hubs */}
          <circle cx="30" cy="42" r="3.5" fill="oklch(0.6 0.02 240)" />
          <circle cx="78" cy="42" r="3.5" fill="oklch(0.6 0.02 240)" />
          <circle cx="180" cy="42" r="3.5" fill="oklch(0.6 0.02 240)" />
        </g>

        {/* Container ship on the sea — simple deck with stacked containers. */}
        <g transform="translate(440 360)">
          {/* Hull */}
          <path
            d="M -130 30 L 130 30 L 110 56 L -110 56 Z"
            fill="oklch(0.20 0.04 250)"
          />
          {/* Deck */}
          <rect x="-126" y="14" width="252" height="18" fill="oklch(0.40 0.04 250)" />
          {/* Containers */}
          <g>
            {[
              { x: -120, c: "oklch(0.65 0.18 145)" },
              { x: -96, c: "oklch(0.55 0.18 250)" },
              { x: -72, c: "oklch(0.78 0.18 80)" },
              { x: -48, c: "oklch(0.55 0.18 250)" },
              { x: -24, c: "oklch(0.65 0.18 145)" },
              { x: 0, c: "oklch(0.55 0.18 250)" },
              { x: 24, c: "oklch(0.78 0.18 80)" },
              { x: 48, c: "oklch(0.65 0.18 145)" },
              { x: 72, c: "oklch(0.55 0.18 250)" },
              { x: 96, c: "oklch(0.78 0.18 80)" },
            ].map((b, i) => (
              <rect
                key={i}
                x={b.x}
                y="-4"
                width="22"
                height="18"
                fill={b.c}
              />
            ))}
          </g>
          {/* Bridge */}
          <rect x="80" y="-22" width="42" height="20" fill="oklch(0.96 0.02 230)" />
          <rect x="84" y="-18" width="34" height="10" fill="oklch(0.55 0.15 230)" />
        </g>
      </svg>

      {/* Glassmorphism shipment chip floating over the top-right. */}
      <div
        className="absolute right-4 top-4 hidden rounded-2xl border border-white/40 bg-white/70 p-3 text-right backdrop-blur-md shadow-elevated sm:block"
        aria-hidden
      >
        <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-brand-600">
          محموله فعال
        </div>
        <div className="mt-1 text-sm font-bold text-deep-navy">SH-204-A</div>
        <div className="mt-1 text-[11px] text-deep-navy-soft">
          تهران ↘ بندرعباس · در راه
        </div>
        <div className="mt-2 flex items-center gap-1.5 text-[10px] text-emerald-700">
          <span className="inline-block size-1.5 rounded-full bg-emerald-500" />
          به‌روز — ۲ دقیقه پیش
        </div>
      </div>

      {/* Glassmorphism KPI chip on bottom-left. */}
      <div
        className="absolute bottom-4 right-4 hidden rounded-2xl border border-white/40 bg-white/70 p-3 backdrop-blur-md shadow-elevated sm:block"
        aria-hidden
      >
        <div className="flex items-center gap-3">
          <div>
            <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-brand-600">
              نشست تله‌متری
            </div>
            <div className="mt-0.5 text-base font-bold text-deep-navy">
              ۱۹ فعال
            </div>
          </div>
          <div className="h-8 w-px bg-deep-navy/15" />
          <div>
            <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-emerald-700">
              تحویل امروز
            </div>
            <div className="mt-0.5 text-base font-bold text-deep-navy">۳۲</div>
          </div>
        </div>
      </div>
    </div>
  );
}
