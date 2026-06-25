"use client";

import { useEffect, useState } from "react";
import Image from "next/image";

// CC-66B — Auto-advancing service image slider. Client component because
// it owns interval/timer state and reacts to `prefers-reduced-motion`.
//
// Behavior:
//   • Each slide enters from the right edge and slides leftward across
//     the viewport (right-to-left motion). 700ms ease-out per step.
//   • Auto-advance every `intervalMs` (default 4 000 ms).
//   • Continuous loop with wrap-around — slide 0 follows the last slide
//     by computing the modular shortest-distance offset.
//   • Pauses on hover/focus-within so the user can read.
//   • Respects `prefers-reduced-motion: reduce` — shows slide 0 only and
//     skips the interval.
//
// No deps beyond React + next/image.

export interface ServiceSlide {
  image: string;
  alt: string;
  title: string;
  description: string;
  pills: string[];
  icon: React.ReactNode;
}

interface Props {
  slides: ServiceSlide[];
  /** Time between auto-advances, ms. */
  intervalMs?: number;
  /** Accessible label for the region. */
  ariaLabel?: string;
}

// Compute the signed shortest distance from `current` to `i`, with wrap.
// For 5 slides, distance is in {-2, -1, 0, 1, 2}. Active slide → 0,
// next → +1 (waiting at +100 %), previous → -1 (parked at -100 %).
function getOffset(i: number, current: number, total: number): number {
  const diff = i - current;
  const half = total / 2;
  if (diff > half) return diff - total;
  if (diff < -half) return diff + total;
  return diff;
}

export function ServiceImageSlider({
  slides,
  intervalMs = 4000,
  ariaLabel,
}: Props) {
  const [current, setCurrent] = useState(0);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [paused, setPaused] = useState(false);

  // Track the user's reduced-motion preference.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReducedMotion(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReducedMotion(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  // Auto-advance interval. Skipped under reduced-motion or while paused.
  useEffect(() => {
    if (reducedMotion || paused) return;
    const id = window.setInterval(
      () => setCurrent((c) => (c + 1) % slides.length),
      intervalMs,
    );
    return () => window.clearInterval(id);
  }, [intervalMs, paused, reducedMotion, slides.length]);

  return (
    <div
      role="region"
      aria-label={ariaLabel}
      aria-roledescription="carousel"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
      className="relative overflow-hidden rounded-[2rem] border border-white/20 shadow-2xl shadow-slate-950/20"
    >
      {/* Aspect ratio holder — taller portrait on mobile, cinematic on
          desktop. Slides fill this box absolutely. */}
      <div className="relative aspect-[4/5] w-full sm:aspect-[16/9] lg:aspect-[16/8]">
        {slides.map((slide, i) => {
          const offset = getOffset(i, current, slides.length);
          const isActive = offset === 0;
          // translateX is physical (left/right viewport pixels), so the
          // same value reads correctly under RTL document direction.
          const tx = `${offset * 100}%`;
          return (
            <div
              key={slide.image}
              role="group"
              aria-roledescription="slide"
              aria-label={`${i + 1} از ${slides.length}: ${slide.title}`}
              aria-hidden={!isActive}
              className="absolute inset-0 transition-transform duration-700 ease-out"
              style={{ transform: `translateX(${tx})` }}
            >
              <Image
                src={slide.image}
                alt={slide.alt}
                fill
                sizes="(max-width: 768px) 100vw, (max-width: 1280px) 90vw, 1200px"
                className="object-cover object-center"
                priority={i === 0}
              />
              {/* Premium overlay — bottom navy heavy, top mostly clear. */}
              <div
                aria-hidden
                className="absolute inset-0 bg-gradient-to-t from-slate-950/85 via-slate-900/35 to-slate-950/5"
              />
              {/* Centered content. */}
              <div
                dir="rtl"
                className="absolute inset-x-0 bottom-8 z-10 mx-auto flex max-w-4xl flex-col items-center px-4 text-center"
              >
                <div className="mb-4 inline-flex size-14 items-center justify-center rounded-2xl border border-sky-300/35 bg-slate-950/35 text-white shadow-lg shadow-sky-950/30 backdrop-blur-md">
                  {slide.icon}
                </div>
                <h3
                  className="text-2xl font-bold text-white sm:text-3xl lg:text-4xl"
                  style={{ textShadow: "0 2px 16px rgba(2, 6, 23, 0.6)" }}
                >
                  {slide.title}
                </h3>
                <p
                  className="mt-3 max-w-2xl text-sm leading-7 text-slate-100 sm:text-base"
                  style={{ textShadow: "0 1px 12px rgba(2, 6, 23, 0.5)" }}
                >
                  {slide.description}
                </p>
                <ul className="mt-5 flex flex-wrap justify-center gap-2">
                  {slide.pills.map((pill) => (
                    <li
                      key={pill}
                      className="rounded-2xl border border-sky-300/35 bg-slate-950/45 px-4 py-2 text-xs font-semibold text-white shadow-lg backdrop-blur-md sm:px-5 sm:py-2.5 sm:text-sm"
                    >
                      {pill}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          );
        })}
      </div>

      {/* Subtle slide indicator dots. */}
      <div
        aria-hidden
        className="absolute inset-x-0 bottom-3 z-20 flex justify-center gap-1.5"
      >
        {slides.map((_, i) => (
          <span
            key={i}
            className={`block h-1.5 rounded-full transition-all duration-300 ${
              i === current
                ? "w-6 bg-sky-300"
                : "w-1.5 bg-white/40"
            }`}
          />
        ))}
      </div>
    </div>
  );
}
